import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/data/backend_api_client.dart';
import '../../../core/data/supabase_client_provider.dart';
import '../../../core/models/drink_log.dart';
import '../../../core/models/nomo_avatar.dart';
import '../../../core/models/nomo_friend.dart';
import '../../../core/models/nomo_gender.dart';
import '../application/drink_log_daily_limit.dart';

final drinkLogRepositoryProvider = Provider<DrinkLogRepository>((ref) {
  return BackendDrinkLogRepository(
    ref.watch(backendApiClientProvider),
    ref.watch(supabaseClientProvider),
  );
});

abstract interface class DrinkLogRepository {
  Future<List<DrinkLog>> fetchLogs();
  Future<List<NomoFriend>> fetchFriends({DateTime? date});
  Future<DrinkLog> addLog(DrinkLog log);
  Future<void> deleteLog(String logId);
  Future<void> reportLog(String logId, {String reason = 'other'});
  Future<DrinkLogLikeState> setLike(String logId, {required bool liked});
  Future<void> setFriendFavorite(String friendId, {required bool isFavorite});
}

class DrinkLogLikeState {
  const DrinkLogLikeState({required this.likeCount, required this.likedByMe});

  final int likeCount;
  final bool likedByMe;
}

class BackendDrinkLogRepository implements DrinkLogRepository {
  const BackendDrinkLogRepository(this._client, this._supabase);

  static const _photoBucket = 'nomo-photos';

  final BackendApiClient _client;
  final SupabaseClient _supabase;

  @override
  Future<List<DrinkLog>> fetchLogs() async {
    final rows = await _client.getRows('/v1/drink-logs');
    return Future.wait(rows.map(_drinkLogFromRow));
  }

  @override
  Future<void> deleteLog(String logId) async {
    await _client.delete('/v1/drink-logs/$logId');
  }

  @override
  Future<void> reportLog(String logId, {String reason = 'other'}) async {
    await _client.post('/v1/drink-logs/$logId/report', {'reason': reason});
  }

  @override
  Future<DrinkLogLikeState> setLike(String logId, {required bool liked}) async {
    final response = liked
        ? await _client.put('/v1/drink-logs/$logId/like', const {})
        : await _client.delete('/v1/drink-logs/$logId/like');
    final row = BackendApiClient.mapFrom(response);
    return DrinkLogLikeState(
      likeCount: (row['like_count'] as num?)?.toInt() ?? 0,
      likedByMe: (row['liked_by_me'] as bool?) ?? liked,
    );
  }

  @override
  Future<List<NomoFriend>> fetchFriends({DateTime? date}) async {
    final userId = _client.currentUserId;
    if (userId == null || userId.isEmpty) {
      throw StateError('フレンズを読み込むにはログインが必要です。');
    }

    final rows = await _client.getRows(
      '/v1/friends',
      query: {'date': _isoDate(date ?? DateTime.now())},
    );

    return rows
        .map<NomoFriend>((row) {
          final other = row['user_a_id'] == userId
              ? row['user_b']
              : row['user_a'];
          if (other is! Map) {
            throw const FormatException('フレンズデータの形式が不正です。');
          }
          return _friendFromProfile(
            Map<String, dynamic>.from(other),
            isFavorite: (row['is_favorite'] as bool?) ?? false,
          );
        })
        .toList(growable: false);
  }

  @override
  Future<DrinkLog> addLog(DrinkLog log) async {
    final uploadedPhotoPath = await _uploadLocalPhotoIfNeeded(
      log.photoAssetPath,
    );
    final row = await _client.postRow('/v1/drink-logs', {
      'drank_at': log.date.toUtc().toIso8601String(),
      'drank_on': drinkLogLocalDateKey(log.date),
      'timezone_offset_minutes': log.date.timeZoneOffset.inMinutes,
      'place_name': log.place,
      'place_lat': log.placeLatitude,
      'place_lng': log.placeLongitude,
      'memo': log.memo,
      'caption_y': log.captionY.clamp(0.0, 1.0),
      'photo_path': uploadedPhotoPath ?? '',
      'marker_rarity': log.rarity.key,
      'friend_ids': log.friends
          .map((friend) => friend.id)
          .toList(growable: false),
    });

    return DrinkLog(
      id: row['id'] as String,
      date: DateTime.parse(row['drank_at'] as String).toLocal(),
      friends: log.friends,
      place: (row['place_name'] as String?) ?? '',
      placeLatitude: (row['place_lat'] as num?)?.toDouble(),
      placeLongitude: (row['place_lng'] as num?)?.toDouble(),
      memo: (row['memo'] as String?) ?? '',
      captionY: _captionYFromRow(row),
      photoAssetPath: await _displayPhotoPath(row['photo_path'] as String?),
      linkUrl: row['link_url'] as String?,
      rarity: DrinkLogRarity.fromKey(row['marker_rarity'] as String?),
      likeCount: 0,
      likedByMe: false,
      ownerUserId:
          (row['owner_user_id'] as String?) ?? _client.currentUserId ?? '',
      isOfficial: (row['is_official'] as bool?) ?? false,
    );
  }

  double _captionYFromRow(Map<String, dynamic> row) {
    final value = (row['caption_y'] as num?)?.toDouble() ?? .5;
    return value.clamp(0.0, 1.0);
  }

  Future<String?> _uploadLocalPhotoIfNeeded(String? path) async {
    final normalized = path?.trim();
    if (normalized == null || normalized.isEmpty) return null;
    if (!normalized.startsWith('/')) return normalized;

    final file = File(normalized);
    if (!await file.exists()) return normalized;

    final userId = _client.currentUserId;
    if (userId == null || userId.isEmpty) {
      throw StateError('写真をアップロードするにはログインが必要です。');
    }

    final extension = _safeExtension(normalized);
    final storagePath =
        'users/$userId/drink_logs/${DateTime.now().toUtc().microsecondsSinceEpoch}$extension';

    await _supabase.storage
        .from(_photoBucket)
        .upload(
          storagePath,
          file,
          fileOptions: FileOptions(
            cacheControl: '3600',
            contentType: _contentTypeForExtension(extension),
            upsert: false,
          ),
        );
    return storagePath;
  }

  Future<String?> _displayPhotoPath(String? path) async {
    final normalized = path?.trim();
    if (normalized == null || normalized.isEmpty) return null;
    if (normalized.startsWith('/') ||
        normalized.startsWith('http://') ||
        normalized.startsWith('https://') ||
        normalized.startsWith('assets/')) {
      return normalized;
    }

    try {
      return await _supabase.storage
          .from(_photoBucket)
          .createSignedUrl(normalized, 60 * 60);
    } catch (_) {
      return null;
    }
  }

  String _safeExtension(String path) {
    final name = path.split('/').last;
    final dot = name.lastIndexOf('.');
    if (dot < 0 || dot == name.length - 1) return '.jpg';
    final extension = name.substring(dot).toLowerCase();
    return switch (extension) {
      '.jpg' || '.jpeg' || '.png' || '.heic' || '.webp' => extension,
      _ => '.jpg',
    };
  }

  String _contentTypeForExtension(String extension) {
    return switch (extension) {
      '.png' => 'image/png',
      '.heic' => 'image/heic',
      '.webp' => 'image/webp',
      _ => 'image/jpeg',
    };
  }

  @override
  Future<void> setFriendFavorite(
    String friendId, {
    required bool isFavorite,
  }) async {
    await _client.put('/v1/friends/$friendId/favorite', {
      'is_favorite': isFavorite,
    });
  }

  Future<DrinkLog> _drinkLogFromRow(Map<String, dynamic> row) async {
    final rawFriends = row['drink_log_friends'] as List<dynamic>? ?? const [];
    final friends = rawFriends
        .map((item) => (item as Map<String, dynamic>)['profiles'])
        .whereType<Map>()
        .map(
          (profile) => _friendFromProfile(Map<String, dynamic>.from(profile)),
        )
        .toList(growable: false);

    final owner = row['owner'] is Map
        ? Map<String, dynamic>.from(row['owner'] as Map)
        : const <String, dynamic>{};

    return DrinkLog(
      id: row['id'] as String,
      date: DateTime.parse(row['drank_at'] as String).toLocal(),
      friends: friends,
      place: (row['place_name'] as String?) ?? '',
      placeLatitude: (row['place_lat'] as num?)?.toDouble(),
      placeLongitude: (row['place_lng'] as num?)?.toDouble(),
      memo: (row['memo'] as String?) ?? '',
      captionY: _captionYFromRow(row),
      photoAssetPath: await _displayPhotoPath(row['photo_path'] as String?),
      linkUrl: row['link_url'] as String?,
      rarity: DrinkLogRarity.fromKey(row['marker_rarity'] as String?),
      likeCount: (row['like_count'] as num?)?.toInt() ?? 0,
      likedByMe: (row['liked_by_me'] as bool?) ?? false,
      ownerUserId: (row['owner_user_id'] as String?) ?? '',
      ownerDisplayName: (owner['display_name'] as String?) ?? '',
      ownerAvatar: NomoAvatar.decode(owner['avatar_url'] as String?),
      isOfficial: (row['is_official'] as bool?) ?? false,
    );
  }

  NomoFriend _friendFromProfile(
    Map<String, dynamic> profile, {
    bool isFavorite = false,
  }) {
    return _friendFromProfileRow(profile, isFavorite: isFavorite);
  }
}

NomoFriend _friendFromProfileRow(
  Map<String, dynamic> profile, {
  bool isFavorite = false,
}) {
  final statusKey = switch (profile['status_key']) {
    String value when value.trim().isNotEmpty => value,
    _ => profile['status'] as String?,
  };
  return NomoFriend(
    id: profile['id'] as String,
    name: (profile['display_name'] as String?) ?? 'Tomola friend',
    avatarEmoji: '🍻',
    vibe: (profile['user_id'] as String?) ?? '',
    characterAssetPath: '',
    kind: NomiTomoKind.cloud,
    palette: _paletteFromKey(profile['palette'] as String?),
    gender: nomoGenderFromKey(profile['gender'] as String?),
    avatar: NomoAvatar.decode(profile['avatar_url'] as String?),
    isFavorite: isFavorite,
    statusKey: statusKey,
    totalDrinkCount: (profile['total_drink_count'] as num?)?.toInt(),
    lastDrinkAt: DateTime.tryParse((profile['last_drink_at'] as String?) ?? ''),
  );
}

NomiTomoPalette _paletteFromKey(String? key) {
  return switch (key) {
    'sky' => NomiTomoPalette.sky,
    'lavender' => NomiTomoPalette.lavender,
    'mint' => NomiTomoPalette.mint,
    'peach' => NomiTomoPalette.peach,
    'blush' => NomiTomoPalette.blush,
    _ => NomiTomoPalette.lemon,
  };
}

String _isoDate(DateTime date) {
  return '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}

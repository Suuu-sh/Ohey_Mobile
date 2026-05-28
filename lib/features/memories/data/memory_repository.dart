import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/data/backend_api_client.dart';
import '../../../core/data/supabase_client_provider.dart';
import '../../../core/models/memory.dart';
import '../../../core/models/tomo_avatar.dart';
import '../../../core/models/tomo_friend.dart';
import '../../../core/models/tomo_gender.dart';
import '../application/memory_daily_limit.dart';

final memoryRepositoryProvider = Provider<MemoryRepository>((ref) {
  return BackendMemoryRepository(
    ref.watch(backendApiClientProvider),
    ref.watch(supabaseClientProvider),
  );
});

abstract interface class MemoryRepository {
  Future<List<Memory>> fetchMemories();
  Future<List<Memory>> fetchHomeFeed();
  Future<MemoryPage> fetchHomeFeedPage({int limit = 20, String? cursor});
  Future<List<TomoFriend>> fetchFriends({DateTime? date});
  Future<Memory> addMemory(Memory memory);
  Future<void> deleteMemory(String memoryId);
  Future<void> reportMemory(String memoryId, {String reason = 'other'});
  Future<void> hideMemoryFromFeed(String memoryId);
  Future<void> muteUser(String userId);
  Future<void> blockUser(String userId);
  Future<MemoryLikeState> setLike(String memoryId, {required bool liked});
  Future<void> setFriendFavorite(String friendId, {required bool isFavorite});
}

class MemoryPage {
  const MemoryPage({required this.memories, this.nextCursor});

  final List<Memory> memories;
  final String? nextCursor;

  bool get hasMore => nextCursor != null && nextCursor!.trim().isNotEmpty;
}

class MemoryLikeState {
  const MemoryLikeState({required this.likeCount, required this.likedByMe});

  final int likeCount;
  final bool likedByMe;
}

class BackendMemoryRepository implements MemoryRepository {
  const BackendMemoryRepository(this._client, this._supabase);

  static const _photoBucket = 'tomo-photos';

  final BackendApiClient _client;
  final SupabaseClient _supabase;

  @override
  Future<List<Memory>> fetchMemories() async {
    final rows = await _client.getRows('/v1/memories');
    return Future.wait(rows.map(_memoryFromRow));
  }

  @override
  Future<List<Memory>> fetchHomeFeed() async {
    return (await fetchHomeFeedPage()).memories;
  }

  @override
  Future<MemoryPage> fetchHomeFeedPage({int limit = 20, String? cursor}) async {
    final query = <String, String>{'limit': limit.toString()};
    final cleanCursor = cursor?.trim();
    if (cleanCursor != null && cleanCursor.isNotEmpty) {
      query['cursor'] = cleanCursor;
    }
    final rows = await _client.getRows('/v1/home/feed', query: query);
    final memories = await Future.wait(rows.map(_memoryFromRow));
    final nextCursor = memories.isEmpty
        ? null
        : memories.last.feedCursor.trim();
    return MemoryPage(memories: memories, nextCursor: nextCursor);
  }

  @override
  Future<void> hideMemoryFromFeed(String memoryId) async {
    await _client.post('/v1/memory-hides', {'memory_id': memoryId});
  }

  @override
  Future<void> muteUser(String userId) async {
    await _client.post('/v1/user-mutes', {'target_user_id': userId});
  }

  @override
  Future<void> blockUser(String userId) async {
    await _client.post('/v1/user-blocks', {'target_user_id': userId});
  }

  @override
  Future<void> deleteMemory(String memoryId) async {
    await _client.delete('/v1/memories/$memoryId');
  }

  @override
  Future<void> reportMemory(String memoryId, {String reason = 'other'}) async {
    await _client.post('/v1/memories/$memoryId/report', {'reason': reason});
  }

  @override
  Future<MemoryLikeState> setLike(
    String memoryId, {
    required bool liked,
  }) async {
    final response = liked
        ? await _client.put('/v1/memories/$memoryId/like', const {})
        : await _client.delete('/v1/memories/$memoryId/like');
    final row = BackendApiClient.mapFrom(response);
    return MemoryLikeState(
      likeCount: (row['like_count'] as num?)?.toInt() ?? 0,
      likedByMe: (row['liked_by_me'] as bool?) ?? liked,
    );
  }

  @override
  Future<List<TomoFriend>> fetchFriends({DateTime? date}) async {
    final userId = _client.currentUserId;
    if (userId == null || userId.isEmpty) {
      throw StateError('フレンズを読み込むにはログインが必要です。');
    }

    final rows = await _client.getRows(
      '/v1/friends',
      query: {'date': _isoDate(date ?? DateTime.now())},
    );

    return rows
        .map<TomoFriend>((row) {
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
  Future<Memory> addMemory(Memory memory) async {
    final uploadedPhotoPath = await _uploadLocalPhotoIfNeeded(
      memory.photoAssetPath,
    );
    final row = await _client.postRow('/v1/memories', {
      'happened_at': memory.date.toUtc().toIso8601String(),
      'happened_on': memoryLocalDateKey(memory.date),
      'timezone_offset_minutes': memory.date.timeZoneOffset.inMinutes,
      'place_name': memory.place,
      'place_lat': memory.placeLatitude,
      'place_lng': memory.placeLongitude,
      'memo': memory.memo,
      'caption_y': memory.captionY.clamp(0.0, 1.0),
      'photo_path': uploadedPhotoPath ?? '',
      'friend_ids': memory.friends
          .map((friend) => friend.id)
          .toList(growable: false),
    });

    final feed = _feedFromRow(row);

    return Memory(
      id: row['id'] as String,
      date: DateTime.parse(row['happened_at'] as String).toLocal(),
      friends: memory.friends,
      place: (row['place_name'] as String?) ?? '',
      placeLatitude: (row['place_lat'] as num?)?.toDouble(),
      placeLongitude: (row['place_lng'] as num?)?.toDouble(),
      memo: (row['memo'] as String?) ?? '',
      captionY: _captionYFromRow(row),
      photoAssetPath: await _displayPhotoPath(row['photo_path'] as String?),
      linkUrl: row['link_url'] as String?,
      rarity: MemoryRarity.fromKey(row['marker_rarity'] as String?),
      likeCount: 0,
      likedByMe: false,
      ownerUserId:
          (row['owner_user_id'] as String?) ?? _client.currentUserId ?? '',
      isOfficial: (row['is_official'] as bool?) ?? false,
      feedAuthorName: (feed['author_name'] as String?) ?? '',
      feedPostKind: (feed['post_kind'] as String?) ?? '',
      feedDisplayable:
          (feed['displayable'] as bool?) ??
          (row['feed_displayable'] as bool?) ??
          true,
      feedCanReport:
          (feed['can_report'] as bool?) ??
          (row['feed_can_report'] as bool?) ??
          true,
      feedCanDelete:
          (feed['can_delete'] as bool?) ??
          (row['feed_can_delete'] as bool?) ??
          false,
      feedTilt:
          (feed['tilt'] as num?)?.toDouble() ??
          (row['feed_tilt'] as num?)?.toDouble(),
      feedCursor:
          (feed['feed_cursor'] as String?) ??
          (row['feed_cursor'] as String?) ??
          '',
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

    final extension = _safeExtension(normalized);
    final contentType = _contentTypeForExtension(extension);
    final upload = await _client.postRow('/v1/media/upload-url', {
      'kind': 'memory_photo',
      'file_extension': extension,
      'content_type': contentType,
    });
    final bucket = (upload['bucket'] as String?)?.trim();
    final storagePath = (upload['path'] as String?)?.trim();
    final token = (upload['token'] as String?)?.trim();
    final uploadContentType =
        (upload['content_type'] as String?)?.trim().isNotEmpty == true
        ? (upload['content_type'] as String).trim()
        : contentType;
    if (bucket == null ||
        bucket.isEmpty ||
        storagePath == null ||
        storagePath.isEmpty ||
        token == null ||
        token.isEmpty) {
      throw const FormatException('写真アップロードURLの形式が不正です。');
    }

    await _supabase.storage
        .from(bucket)
        .uploadToSignedUrl(
          storagePath,
          token,
          file,
          FileOptions(
            cacheControl: '3600',
            contentType: uploadContentType,
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
      final row = await _client.postRow('/v1/media/display-url', {
        'path': normalized,
      });
      return (row['signed_url'] as String?)?.trim();
    } catch (_) {
      try {
        return await _supabase.storage
            .from(_photoBucket)
            .createSignedUrl(normalized, 60 * 60);
      } catch (_) {
        return null;
      }
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

  Future<Memory> _memoryFromRow(Map<String, dynamic> row) async {
    final rawFriends = row['memory_tagged_users'] as List<dynamic>? ?? const [];
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

    final feed = _feedFromRow(row);

    return Memory(
      id: row['id'] as String,
      date: DateTime.parse(row['happened_at'] as String).toLocal(),
      friends: friends,
      place: (row['place_name'] as String?) ?? '',
      placeLatitude: (row['place_lat'] as num?)?.toDouble(),
      placeLongitude: (row['place_lng'] as num?)?.toDouble(),
      memo: (row['memo'] as String?) ?? '',
      captionY: _captionYFromRow(row),
      photoAssetPath: await _displayPhotoPath(row['photo_path'] as String?),
      linkUrl: row['link_url'] as String?,
      rarity: MemoryRarity.fromKey(row['marker_rarity'] as String?),
      likeCount: (row['like_count'] as num?)?.toInt() ?? 0,
      likedByMe: (row['liked_by_me'] as bool?) ?? false,
      ownerUserId: (row['owner_user_id'] as String?) ?? '',
      ownerDisplayName: (owner['display_name'] as String?) ?? '',
      ownerAvatar: TomoAvatar.decode(owner['avatar_url'] as String?),
      isOfficial: (row['is_official'] as bool?) ?? false,
      feedAuthorName: (feed['author_name'] as String?) ?? '',
      feedPostKind: (feed['post_kind'] as String?) ?? '',
      feedDisplayable:
          (feed['displayable'] as bool?) ??
          (row['feed_displayable'] as bool?) ??
          true,
      feedCanReport:
          (feed['can_report'] as bool?) ??
          (row['feed_can_report'] as bool?) ??
          true,
      feedCanDelete:
          (feed['can_delete'] as bool?) ??
          (row['feed_can_delete'] as bool?) ??
          false,
      feedTilt:
          (feed['tilt'] as num?)?.toDouble() ??
          (row['feed_tilt'] as num?)?.toDouble(),
      feedCursor:
          (feed['feed_cursor'] as String?) ??
          (row['feed_cursor'] as String?) ??
          '',
    );
  }

  Map<String, dynamic> _feedFromRow(Map<String, dynamic> row) {
    return row['feed_item'] is Map
        ? Map<String, dynamic>.from(row['feed_item'] as Map)
        : const <String, dynamic>{};
  }

  TomoFriend _friendFromProfile(
    Map<String, dynamic> profile, {
    bool isFavorite = false,
  }) {
    return _friendFromProfileRow(profile, isFavorite: isFavorite);
  }
}

TomoFriend _friendFromProfileRow(
  Map<String, dynamic> profile, {
  bool isFavorite = false,
}) {
  final statusKey = switch (profile['status_key']) {
    String value when value.trim().isNotEmpty => value,
    _ => profile['status'] as String?,
  };
  return TomoFriend(
    id: profile['id'] as String,
    name: (profile['display_name'] as String?) ?? 'Tomo friend',
    avatarEmoji: '🍻',
    vibe: (profile['user_id'] as String?) ?? '',
    characterAssetPath: '',
    kind: TomoFriendKind.cloud,
    palette: _paletteFromKey(profile['palette'] as String?),
    gender: tomoGenderFromKey(profile['gender'] as String?),
    avatar: TomoAvatar.decode(profile['avatar_url'] as String?),
    isFavorite: isFavorite,
    statusKey: statusKey,
    totalMemoryCount: (profile['total_memory_count'] as num?)?.toInt(),
    lastMemoryAt: DateTime.tryParse(
      (profile['last_memory_at'] as String?) ?? '',
    ),
  );
}

TomoFriendPalette _paletteFromKey(String? key) {
  return switch (key) {
    'sky' => TomoFriendPalette.sky,
    'lavender' => TomoFriendPalette.lavender,
    'mint' => TomoFriendPalette.mint,
    'peach' => TomoFriendPalette.peach,
    'blush' => TomoFriendPalette.blush,
    _ => TomoFriendPalette.lemon,
  };
}

String _isoDate(DateTime date) {
  return '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}

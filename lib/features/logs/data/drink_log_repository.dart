import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/data/backend_api_client.dart';
import '../../../core/data/supabase_client_provider.dart';
import '../../../core/models/drink_log.dart';
import '../../../core/models/nomo_avatar.dart';
import '../../../core/models/nomo_friend.dart';

final drinkLogRepositoryProvider = Provider<DrinkLogRepository>((ref) {
  return ResilientDrinkLogRepository(
    backend: BackendDrinkLogRepository(ref.watch(backendApiClientProvider)),
    fallback: SupabaseDrinkLogRepository(ref.watch(supabaseClientProvider)),
  );
});

abstract interface class DrinkLogRepository {
  Future<List<DrinkLog>> fetchLogs();
  Future<List<NomoFriend>> fetchFriends();
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

class ResilientDrinkLogRepository implements DrinkLogRepository {
  const ResilientDrinkLogRepository({
    required this.backend,
    required this.fallback,
  });

  final DrinkLogRepository backend;
  final SupabaseDrinkLogRepository fallback;

  @override
  Future<List<DrinkLog>> fetchLogs() async {
    try {
      return await backend.fetchLogs();
    } catch (_) {
      return fallback.fetchLogs();
    }
  }

  @override
  Future<List<NomoFriend>> fetchFriends() async {
    try {
      return await backend.fetchFriends();
    } catch (_) {
      return fallback.fetchFriends();
    }
  }

  @override
  Future<DrinkLog> addLog(DrinkLog log) async {
    try {
      return await backend.addLog(log);
    } catch (_) {
      return fallback.addLog(log);
    }
  }

  @override
  Future<void> deleteLog(String logId) async {
    try {
      return await backend.deleteLog(logId);
    } catch (_) {
      return fallback.deleteLog(logId);
    }
  }

  @override
  Future<void> reportLog(String logId, {String reason = 'other'}) async {
    try {
      return await backend.reportLog(logId, reason: reason);
    } catch (_) {
      return fallback.reportLog(logId, reason: reason);
    }
  }

  @override
  Future<DrinkLogLikeState> setLike(String logId, {required bool liked}) async {
    try {
      return await backend.setLike(logId, liked: liked);
    } catch (_) {
      return fallback.setLike(logId, liked: liked);
    }
  }

  @override
  Future<void> setFriendFavorite(
    String friendId, {
    required bool isFavorite,
  }) async {
    try {
      return await backend.setFriendFavorite(friendId, isFavorite: isFavorite);
    } catch (_) {
      return fallback.setFriendFavorite(friendId, isFavorite: isFavorite);
    }
  }
}

class BackendDrinkLogRepository implements DrinkLogRepository {
  const BackendDrinkLogRepository(this._client);

  final BackendApiClient _client;

  @override
  Future<List<DrinkLog>> fetchLogs() async {
    final response = await _client.get('/v1/drink-logs');
    final rows = (response as List<dynamic>? ?? const [])
        .whereType<Map>()
        .map((row) => Map<String, dynamic>.from(row))
        .toList(growable: false);

    return rows.map<DrinkLog>(_drinkLogFromRow).toList(growable: false);
  }

  @override
  Future<void> deleteLog(String logId) async {
    await _client.delete('/v1/drink-logs/$logId');
  }

  @override
  Future<void> reportLog(String logId, {String reason = 'other'}) async {
    throw UnimplementedError();
  }

  @override
  Future<DrinkLogLikeState> setLike(String logId, {required bool liked}) async {
    final response = liked
        ? await _client.put('/v1/drink-logs/$logId/like', const {})
        : await _client.delete('/v1/drink-logs/$logId/like');
    final row = Map<String, dynamic>.from(response as Map);
    return DrinkLogLikeState(
      likeCount: (row['like_count'] as num?)?.toInt() ?? 0,
      likedByMe: (row['liked_by_me'] as bool?) ?? liked,
    );
  }

  @override
  Future<List<NomoFriend>> fetchFriends() async {
    final userId = _client.currentUserId;
    if (userId == null || userId.isEmpty) {
      throw StateError('友達を読み込むにはログインが必要です。');
    }

    final response = await _client.get('/v1/friends');
    final rows = (response as List<dynamic>? ?? const [])
        .whereType<Map>()
        .map((row) => Map<String, dynamic>.from(row))
        .toList(growable: false);

    return rows
        .map<NomoFriend>((row) {
          final other = row['user_a_id'] == userId
              ? row['user_b']
              : row['user_a'];
          if (other is! Map) {
            throw const FormatException('友達データの形式が不正です。');
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
    final response = await _client.post('/v1/drink-logs', {
      'drank_at': log.date.toUtc().toIso8601String(),
      'place_name': log.place,
      'memo': log.memo,
      'photo_path': log.photoAssetPath ?? '',
      'friend_ids': log.friends
          .map((friend) => friend.id)
          .toList(growable: false),
    });
    final row = Map<String, dynamic>.from(response as Map);

    return DrinkLog(
      id: row['id'] as String,
      date: DateTime.parse(row['drank_at'] as String).toLocal(),
      friends: log.friends,
      place: (row['place_name'] as String?) ?? '',
      memo: (row['memo'] as String?) ?? '',
      photoAssetPath: row['photo_path'] as String?,
      likeCount: 0,
      likedByMe: false,
      ownerUserId:
          (row['owner_user_id'] as String?) ?? _client.currentUserId ?? '',
    );
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

  DrinkLog _drinkLogFromRow(Map<String, dynamic> row) {
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
      memo: (row['memo'] as String?) ?? '',
      photoAssetPath: row['photo_path'] as String?,
      likeCount: (row['like_count'] as num?)?.toInt() ?? 0,
      likedByMe: (row['liked_by_me'] as bool?) ?? false,
      ownerUserId: (row['owner_user_id'] as String?) ?? '',
      ownerDisplayName: (owner['display_name'] as String?) ?? '',
      ownerAvatar: NomoAvatar.decode(owner['avatar_url'] as String?),
    );
  }

  NomoFriend _friendFromProfile(
    Map<String, dynamic> profile, {
    bool isFavorite = false,
  }) {
    return _friendFromProfileRow(profile, isFavorite: isFavorite);
  }
}

class SupabaseDrinkLogRepository implements DrinkLogRepository {
  const SupabaseDrinkLogRepository(this._client);

  final SupabaseClient _client;

  String? get _userId => _client.auth.currentUser?.id;

  @override
  Future<List<DrinkLog>> fetchLogs() async {
    final userId = _userId;
    if (userId == null) return const [];

    final response = await _client
        .from('drink_logs')
        .select('''
          id,
          owner_user_id,
          drank_at,
          place_name,
          memo,
          photo_path,
          owner:profiles!drink_logs_owner_user_id_fkey(
            id,
            display_name,
            user_id,
            character_key,
            avatar_url
          ),
          drink_log_likes(user_id),
          drink_log_friends(
            profiles(
              id,
              display_name,
              user_id,
              character_key,
              avatar_url
            )
          )
        ''')
        .inFilter('owner_user_id', await _visibleFeedUserIds(userId))
        .order('drank_at', ascending: false);

    return response.map<DrinkLog>(_drinkLogFromRow).toList(growable: false);
  }

  @override
  Future<List<NomoFriend>> fetchFriends() async {
    final userId = _userId;
    if (userId == null) return const [];

    final response = await _client
        .from('friendships')
        .select('''
          user_a_id,
          user_b_id,
          is_favorite,
          user_a:profiles!friendships_user_a_id_fkey(
            id,
            display_name,
            user_id,
            character_key,
            avatar_url
          ),
          user_b:profiles!friendships_user_b_id_fkey(
            id,
            display_name,
            user_id,
            character_key,
            avatar_url
          )
        ''')
        .or('user_a_id.eq.$userId,user_b_id.eq.$userId')
        .order('created_at', ascending: false);

    return response
        .map<NomoFriend>((row) {
          final other = row['user_a_id'] == userId
              ? row['user_b']
              : row['user_a'];
          final isFavorite = (row['is_favorite'] as bool?) ?? false;
          return _friendFromProfileRow(
            Map<String, dynamic>.from(other as Map),
            isFavorite: isFavorite,
          );
        })
        .toList(growable: false);
  }

  @override
  Future<DrinkLogLikeState> setLike(String logId, {required bool liked}) async {
    final userId = _userId;
    if (userId == null) {
      throw StateError('いいねするにはログインが必要です。');
    }

    if (liked) {
      await _client.from('drink_log_likes').upsert({
        'drink_log_id': logId,
        'user_id': userId,
      }, onConflict: 'drink_log_id,user_id');
    } else {
      await _client
          .from('drink_log_likes')
          .delete()
          .eq('drink_log_id', logId)
          .eq('user_id', userId);
    }

    final likes = await _client
        .from('drink_log_likes')
        .select('user_id')
        .eq('drink_log_id', logId);
    return DrinkLogLikeState(
      likeCount: likes.length,
      likedByMe: likes.any((row) => row['user_id'] == userId),
    );
  }

  @override
  Future<void> deleteLog(String logId) async {
    final userId = _userId;
    if (userId == null) throw StateError('削除するにはログインが必要です。');
    await _client
        .from('drink_logs')
        .delete()
        .eq('id', logId)
        .eq('owner_user_id', userId);
  }

  @override
  Future<void> setFriendFavorite(
    String friendId, {
    required bool isFavorite,
  }) async {
    final userId = _userId;
    if (userId == null) {
      throw StateError('お気に入り設定にはログインが必要です。');
    }

    final filter =
        '(and(user_a_id.eq.$userId,user_b_id.eq.$friendId),and(user_b_id.eq.$userId,user_a_id.eq.$friendId))';
    final rows = await _client
        .from('friendships')
        .update({'is_favorite': isFavorite})
        .or(filter);
    if (rows.isEmpty) {
      throw StateError('フレンズの関係が見つかりませんでした。');
    }
  }

  @override
  Future<void> reportLog(String logId, {String reason = 'other'}) async {
    final userId = _userId;
    if (userId == null) throw StateError('報告するにはログインが必要です。');
    await _client.from('drink_log_reports').upsert({
      'drink_log_id': logId,
      'reporter_user_id': userId,
      'reason': reason,
    }, onConflict: 'drink_log_id,reporter_user_id');
  }

  Future<List<String>> _visibleFeedUserIds(String userId) async {
    final friendships = await _client
        .from('friendships')
        .select('user_a_id,user_b_id')
        .or('user_a_id.eq.$userId,user_b_id.eq.$userId');
    final ids = <String>{userId};
    for (final row in friendships) {
      final userA = row['user_a_id'] as String?;
      final userB = row['user_b_id'] as String?;
      if (userA != null) ids.add(userA);
      if (userB != null) ids.add(userB);
    }
    return ids.toList(growable: false);
  }

  @override
  Future<DrinkLog> addLog(DrinkLog log) async {
    final userId = _userId;
    if (userId == null) {
      throw StateError('飲みログを保存するにはログインが必要です。');
    }

    final inserted = await _client
        .from('drink_logs')
        .insert({
          'owner_user_id': userId,
          'drank_at': log.date.toIso8601String(),
          'place_name': log.place,
          'memo': log.memo,
          'photo_path': log.photoAssetPath,
        })
        .select('id, drank_at, place_name, memo, photo_path')
        .single();

    if (log.friends.isNotEmpty) {
      await _client.from('drink_log_friends').insert([
        for (final friend in log.friends)
          if (_isUuid(friend.id))
            {'drink_log_id': inserted['id'], 'friend_user_id': friend.id},
      ]);
    }

    return DrinkLog(
      id: inserted['id'] as String,
      date: DateTime.parse(inserted['drank_at'] as String).toLocal(),
      friends: log.friends,
      place: (inserted['place_name'] as String?) ?? '',
      memo: (inserted['memo'] as String?) ?? '',
      photoAssetPath: inserted['photo_path'] as String?,
      ownerUserId: userId,
    );
  }

  DrinkLog _drinkLogFromRow(Map<String, dynamic> row) {
    final rawFriends = row['drink_log_friends'] as List<dynamic>? ?? const [];
    final friends = rawFriends
        .map((item) => (item as Map<String, dynamic>)['profiles'])
        .whereType<Map>()
        .map(
          (profile) =>
              _friendFromProfileRow(Map<String, dynamic>.from(profile)),
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
      memo: (row['memo'] as String?) ?? '',
      photoAssetPath: row['photo_path'] as String?,
      likeCount: _likeCountFromRow(row),
      likedByMe: _likedByMeFromRow(row, _userId),
      ownerUserId: (row['owner_user_id'] as String?) ?? '',
      ownerDisplayName: (owner['display_name'] as String?) ?? '',
      ownerAvatar: NomoAvatar.decode(owner['avatar_url'] as String?),
    );
  }
}

int _likeCountFromRow(Map<String, dynamic> row) {
  final likeCount = row['like_count'];
  if (likeCount is num) return likeCount.toInt();
  final rawLikes = row['drink_log_likes'];
  if (rawLikes is List) return rawLikes.length;
  return 0;
}

bool _likedByMeFromRow(Map<String, dynamic> row, String? userId) {
  final likedByMe = row['liked_by_me'];
  if (likedByMe is bool) return likedByMe;
  if (userId == null) return false;
  final rawLikes = row['drink_log_likes'];
  if (rawLikes is! List) return false;
  return rawLikes.whereType<Map>().any((like) => like['user_id'] == userId);
}

NomoFriend _friendFromProfileRow(
  Map<String, dynamic> profile, {
  bool isFavorite = false,
}) {
  return NomoFriend(
    id: profile['id'] as String,
    name: (profile['display_name'] as String?) ?? 'Nomo friend',
    avatarEmoji: '🍻',
    vibe: (profile['user_id'] as String?) ?? '',
    characterAssetPath: '',
    kind: NomiTomoKind.cloud,
    palette: _paletteFromKey(profile['palette'] as String?),
    avatar: NomoAvatar.decode(profile['avatar_url'] as String?),
    isFavorite: isFavorite,
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

bool _isUuid(String value) {
  return RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
  ).hasMatch(value);
}

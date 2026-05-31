import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/backend_api_client.dart';
import '../../../core/models/memory.dart';
import '../../../core/models/ohey_avatar.dart';
import '../../../core/models/ohey_friend.dart';
import '../../../core/models/ohey_gender.dart';
import '../application/memory_daily_limit.dart';

final memoryRepositoryProvider = Provider<MemoryRepository>((ref) {
  return BackendMemoryRepository(ref.watch(backendApiClientProvider));
});

abstract interface class MemoryRepository {
  Future<List<Memory>> fetchMemories();
  Future<List<Memory>> fetchHomeFeed();
  Future<MemoryPage> fetchHomeFeedPage({int limit = 20, String? cursor});
  Future<List<OheyFriend>> fetchFriends({DateTime? date});
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
  const BackendMemoryRepository(this._client);

  final BackendApiClient _client;

  @override
  Future<List<Memory>> fetchMemories() async {
    final rows = await _client.getRows('/v1/memories');
    return rows.map(_memoryFromRow).toList(growable: false);
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
    final memories = rows.map(_memoryFromRow).toList(growable: false);
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
  Future<List<OheyFriend>> fetchFriends({DateTime? date}) async {
    final userId = _client.currentUserId;
    if (userId == null || userId.isEmpty) {
      throw StateError('フレンズを読み込むにはログインが必要です。');
    }

    final rows = await _client.getRows(
      '/v1/friends',
      query: {'date': _isoDate(date ?? DateTime.now())},
    );

    return rows
        .map<OheyFriend>((row) {
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
    final row = await _client.postRow('/v1/memories', {
      'happened_at': memory.date.toUtc().toIso8601String(),
      'happened_on': memoryLocalDateKey(memory.date),
      'timezone_offset_minutes': memory.date.timeZoneOffset.inMinutes,
      'place_name': memory.place,
      'place_lat': memory.placeLatitude,
      'place_lng': memory.placeLongitude,
      'memo': memory.memo,
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
      linkUrl: row['link_url'] as String?,
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

  @override
  Future<void> setFriendFavorite(
    String friendId, {
    required bool isFavorite,
  }) async {
    await _client.put('/v1/friends/$friendId/favorite', {
      'is_favorite': isFavorite,
    });
  }

  Memory _memoryFromRow(Map<String, dynamic> row) {
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
      linkUrl: row['link_url'] as String?,
      likeCount: (row['like_count'] as num?)?.toInt() ?? 0,
      likedByMe: (row['liked_by_me'] as bool?) ?? false,
      ownerUserId: (row['owner_user_id'] as String?) ?? '',
      ownerDisplayName: (owner['display_name'] as String?) ?? '',
      ownerAvatar: OheyAvatar.decode(owner['avatar_url'] as String?),
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

  OheyFriend _friendFromProfile(
    Map<String, dynamic> profile, {
    bool isFavorite = false,
  }) {
    return _friendFromProfileRow(profile, isFavorite: isFavorite);
  }
}

OheyFriend _friendFromProfileRow(
  Map<String, dynamic> profile, {
  bool isFavorite = false,
}) {
  final statusKey = switch (profile['status_key']) {
    String value when value.trim().isNotEmpty => value,
    _ => profile['status'] as String?,
  };
  return OheyFriend(
    id: profile['id'] as String,
    name: (profile['display_name'] as String?) ?? 'Ohey friend',
    avatarEmoji: '🍻',
    vibe: (profile['user_id'] as String?) ?? '',
    characterAssetPath: '',
    kind: OheyFriendKind.cloud,
    palette: _paletteFromKey(profile['palette'] as String?),
    gender: oheyGenderFromKey(profile['gender'] as String?),
    avatar: OheyAvatar.decode(profile['avatar_url'] as String?),
    isFavorite: isFavorite,
    statusKey: statusKey,
    totalMemoryCount: (profile['total_memory_count'] as num?)?.toInt(),
    lastMemoryAt: DateTime.tryParse(
      (profile['last_memory_at'] as String?) ?? '',
    ),
  );
}

OheyFriendPalette _paletteFromKey(String? key) {
  return switch (key) {
    'sky' => OheyFriendPalette.sky,
    'lavender' => OheyFriendPalette.lavender,
    'mint' => OheyFriendPalette.mint,
    'peach' => OheyFriendPalette.peach,
    'blush' => OheyFriendPalette.blush,
    _ => OheyFriendPalette.lemon,
  };
}

String _isoDate(DateTime date) {
  return '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}

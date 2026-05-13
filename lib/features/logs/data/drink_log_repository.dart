import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/data/backend_api_client.dart';
import '../../../core/models/drink_log.dart';
import '../../../core/models/nomo_friend.dart';

final drinkLogRepositoryProvider = Provider<DrinkLogRepository>((ref) {
  return BackendDrinkLogRepository(ref.watch(backendApiClientProvider));
});

abstract interface class DrinkLogRepository {
  Future<List<DrinkLog>> fetchLogs();
  Future<List<NomoFriend>> fetchFriends();
  Future<DrinkLog> addLog(DrinkLog log);
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
          return _friendFromProfile(Map<String, dynamic>.from(other));
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
    );
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

    return DrinkLog(
      id: row['id'] as String,
      date: DateTime.parse(row['drank_at'] as String).toLocal(),
      friends: friends,
      place: (row['place_name'] as String?) ?? '',
      memo: (row['memo'] as String?) ?? '',
      photoAssetPath: row['photo_path'] as String?,
    );
  }

  NomoFriend _friendFromProfile(Map<String, dynamic> profile) {
    return NomoFriend(
      id: profile['id'] as String,
      name: (profile['display_name'] as String?) ?? 'Nomo friend',
      avatarEmoji: '🍻',
      vibe: (profile['user_id'] as String?) ?? '',
      characterAssetPath: _assetPathForCharacter(
        profile['character_key'] as String?,
      ),
      kind: NomiTomoKind.cloud,
      palette: NomiTomoPalette.peach,
    );
  }

  String _assetPathForCharacter(String? key) {
    return switch (key) {
      'icon_wink' => 'assets/characters/nomo/icon_wink.png',
      'standing_beer' => 'assets/characters/nomo/standing_beer.png',
      'reaction_happy' => 'assets/characters/nomo/reaction_happy.png',
      _ => 'assets/characters/nomo/icon_smile.png',
    };
  }
}

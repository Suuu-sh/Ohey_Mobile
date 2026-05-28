import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/backend_api_client.dart';
import '../../../core/models/ohey_avatar.dart';

final userSafetyRepositoryProvider = Provider<UserSafetyRepository>((ref) {
  return UserSafetyRepository(ref.watch(backendApiClientProvider));
});

final blockedUsersProvider = FutureProvider<List<OheySafetyUser>>((ref) {
  return ref.watch(userSafetyRepositoryProvider).fetchBlockedUsers();
});

final mutedUsersProvider = FutureProvider<List<OheySafetyUser>>((ref) {
  return ref.watch(userSafetyRepositoryProvider).fetchMutedUsers();
});

class UserSafetyRepository {
  const UserSafetyRepository(this._client);

  final BackendApiClient _client;

  Future<void> blockUser(String userId) async {
    await _client.post('/v1/user-blocks', {'target_user_id': userId});
  }

  Future<void> muteUser(String userId) async {
    await _client.post('/v1/user-mutes', {'target_user_id': userId});
  }

  Future<void> reportUser(String userId, {String reason = 'other'}) async {
    await _client.post('/v1/user-reports', {
      'target_user_id': userId,
      'reason': reason,
    });
  }

  Future<List<OheySafetyUser>> fetchBlockedUsers() async {
    final rows = await _client.getRows('/v1/user-blocks');
    return rows.map(OheySafetyUser.fromRow).toList(growable: false);
  }

  Future<List<OheySafetyUser>> fetchMutedUsers() async {
    final rows = await _client.getRows('/v1/user-mutes');
    return rows.map(OheySafetyUser.fromRow).toList(growable: false);
  }

  Future<void> unblockUser(String userId) async {
    await _client.delete('/v1/user-blocks/${Uri.encodeComponent(userId)}');
  }

  Future<void> unmuteUser(String userId) async {
    await _client.delete('/v1/user-mutes/${Uri.encodeComponent(userId)}');
  }
}

class OheySafetyUser {
  const OheySafetyUser({
    required this.id,
    required this.userId,
    required this.displayName,
    required this.avatar,
    this.createdAt,
  });

  factory OheySafetyUser.fromRow(Map<String, dynamic> row) {
    final id = (row['target_user_id'] as String?)?.trim().isNotEmpty == true
        ? (row['target_user_id'] as String).trim()
        : (row['id'] as String?)?.trim() ?? '';
    final displayName = (row['display_name'] as String?)?.trim();
    final handle = (row['user_id'] as String?)?.trim();
    return OheySafetyUser(
      id: id,
      userId: handle ?? '',
      displayName: displayName == null || displayName.isEmpty
          ? 'Ohey friend'
          : displayName,
      avatar:
          OheyAvatar.decode(row['avatar_url'] as String?) ??
          OheyAvatar.defaultAvatar,
      createdAt: DateTime.tryParse((row['created_at'] as String?) ?? ''),
    );
  }

  final String id;
  final String userId;
  final String displayName;
  final OheyAvatar avatar;
  final DateTime? createdAt;
}

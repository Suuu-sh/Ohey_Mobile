import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/backend_api_client.dart';
import '../../../core/models/nomo_avatar.dart';

final friendRepositoryProvider = Provider<FriendRepository>((ref) {
  return FriendRepository(ref.watch(backendApiClientProvider));
});

class FriendRepository {
  const FriendRepository(this._client);

  final BackendApiClient _client;

  String? get currentUserId => _client.currentUserId;

  Future<NomoFriendProfile?> findProfileByUserId(String userId) async {
    final exactUserId = userId.trim();
    if (exactUserId.isEmpty) return null;
    try {
      final row = await _client.getRow(
        '/v1/profiles/by-user-id/${Uri.encodeComponent(exactUserId)}',
      );
      return NomoFriendProfile.fromRow(row);
    } on BackendApiException catch (error) {
      if (error.statusCode == 404) return null;
      rethrow;
    }
  }

  Future<NomoFriendRelationshipStatus> relationshipStatus(
    String friendId,
  ) async {
    final row = await _client.getRow(
      '/v1/friend-requests/status',
      query: {'friend_id': friendId},
    );
    return NomoFriendRelationshipStatus.fromRow(row);
  }

  Future<List<Map<String, dynamic>>> fetchFriendGroups() async {
    return _client.getRows('/v1/friend-groups');
  }

  Future<List<Map<String, dynamic>>> saveFriendGroups(
    List<Map<String, dynamic>> groups,
  ) async {
    final response = await _client.put('/v1/friend-groups', {'groups': groups});
    return BackendApiClient.rowsFrom(response);
  }

  Future<void> addFriend(String friendId) async {
    await _client.post('/v1/friends', {'friend_id': friendId});
  }

  Future<void> deleteFriend(String friendId) async {
    await _client.delete('/v1/friends/${Uri.encodeComponent(friendId)}');
  }

  Future<void> sendFriendRequest(String friendId) async {
    await _client.post('/v1/friend-requests', {'to_user_id': friendId});
  }

  Future<void> cancelFriendRequest(String requestId) async {
    await _client.patch(
      '/v1/friend-requests/${Uri.encodeComponent(requestId)}',
      {'status': 'cancelled'},
    );
  }
}

class NomoFriendProfile {
  const NomoFriendProfile({
    required this.id,
    required this.userId,
    required this.displayName,
    required this.avatar,
  });

  factory NomoFriendProfile.fromRow(Map<String, dynamic> row) {
    return NomoFriendProfile(
      id: row['id'] as String,
      userId: (row['user_id'] as String?) ?? '',
      displayName: (row['display_name'] as String?)?.trim().isNotEmpty == true
          ? (row['display_name'] as String).trim()
          : 'Nomo friend',
      avatar:
          NomoAvatar.decode(row['avatar_url'] as String?) ??
          NomoAvatar.defaultAvatar,
    );
  }

  final String id;
  final String userId;
  final String displayName;
  final NomoAvatar avatar;
}

enum NomoFriendRequestState { none, outgoing, incoming }

class NomoFriendRelationshipStatus {
  const NomoFriendRelationshipStatus({
    required this.alreadyFriend,
    required this.requestState,
    this.requestId,
  });

  factory NomoFriendRelationshipStatus.fromRow(Map<String, dynamic> row) {
    final requestState = switch (row['request_state'] as String?) {
      'outgoing' => NomoFriendRequestState.outgoing,
      'incoming' => NomoFriendRequestState.incoming,
      _ => NomoFriendRequestState.none,
    };
    return NomoFriendRelationshipStatus(
      alreadyFriend: (row['already_friend'] as bool?) ?? false,
      requestState: requestState,
      requestId: (row['request_id'] as String?)?.trim(),
    );
  }

  final bool alreadyFriend;
  final NomoFriendRequestState requestState;
  final String? requestId;
}

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/backend_api_client.dart';
import '../../../core/models/tomo_avatar.dart';

final friendRepositoryProvider = Provider<FriendRepository>((ref) {
  return FriendRepository(ref.watch(backendApiClientProvider));
});

final pendingFriendRequestsProvider =
    FutureProvider<List<TomoFriendRequestItem>>((ref) {
      return ref.watch(friendRepositoryProvider).fetchPendingFriendRequests();
    });

class FriendRepository {
  const FriendRepository(this._client);

  final BackendApiClient _client;

  String? get currentUserId => _client.currentUserId;

  Future<TomoFriendProfile?> findProfileByUserId(String userId) async {
    final exactUserId = userId.trim();
    if (exactUserId.isEmpty) return null;
    try {
      final row = await _client.getRow(
        '/v1/profiles/by-user-id/${Uri.encodeComponent(exactUserId)}',
      );
      return TomoFriendProfile.fromRow(row);
    } on BackendApiException catch (error) {
      if (error.statusCode == 404) return null;
      rethrow;
    }
  }

  Future<TomoFriendRelationshipStatus> relationshipStatus(
    String friendId,
  ) async {
    final row = await _client.getRow(
      '/v1/friend-requests/status',
      query: {'friend_id': friendId},
    );
    return TomoFriendRelationshipStatus.fromRow(row);
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

  Future<List<TomoFriendRequestItem>> fetchPendingFriendRequests({
    String direction = 'all',
  }) async {
    final rows = await _client.getRows(
      '/v1/friend-requests',
      query: {'direction': direction},
    );
    final currentUserId = _client.currentUserId ?? '';
    return rows
        .map((row) => TomoFriendRequestItem.fromRow(row, currentUserId))
        .toList(growable: false);
  }

  Future<void> updateFriendRequest(String requestId, String status) async {
    await _client.patch(
      '/v1/friend-requests/${Uri.encodeComponent(requestId)}',
      {'status': status},
    );
  }

  Future<void> cancelFriendRequest(String requestId) async {
    await updateFriendRequest(requestId, 'cancelled');
  }
}

class TomoFriendProfile {
  const TomoFriendProfile({
    required this.id,
    required this.userId,
    required this.displayName,
    required this.avatar,
  });

  factory TomoFriendProfile.fromRow(Map<String, dynamic> row) {
    return TomoFriendProfile(
      id: row['id'] as String,
      userId: (row['user_id'] as String?) ?? '',
      displayName: (row['display_name'] as String?)?.trim().isNotEmpty == true
          ? (row['display_name'] as String).trim()
          : 'Tomo friend',
      avatar:
          TomoAvatar.decode(row['avatar_url'] as String?) ??
          TomoAvatar.defaultAvatar,
    );
  }

  final String id;
  final String userId;
  final String displayName;
  final TomoAvatar avatar;
}

enum TomoFriendRequestState { none, outgoing, incoming }

class TomoFriendRelationshipStatus {
  const TomoFriendRelationshipStatus({
    required this.alreadyFriend,
    required this.requestState,
    this.requestId,
  });

  factory TomoFriendRelationshipStatus.fromRow(Map<String, dynamic> row) {
    final requestState = switch (row['request_state'] as String?) {
      'outgoing' => TomoFriendRequestState.outgoing,
      'incoming' => TomoFriendRequestState.incoming,
      _ => TomoFriendRequestState.none,
    };
    return TomoFriendRelationshipStatus(
      alreadyFriend: (row['already_friend'] as bool?) ?? false,
      requestState: requestState,
      requestId: (row['request_id'] as String?)?.trim(),
    );
  }

  final bool alreadyFriend;
  final TomoFriendRequestState requestState;
  final String? requestId;
}

enum TomoFriendRequestDirection { incoming, outgoing }

class TomoFriendRequestItem {
  const TomoFriendRequestItem({
    required this.id,
    required this.fromUserId,
    required this.toUserId,
    required this.direction,
    required this.otherUser,
    this.createdAt,
  });

  factory TomoFriendRequestItem.fromRow(
    Map<String, dynamic> row,
    String currentUserId,
  ) {
    final fromUserId = (row['from_user_id'] as String?)?.trim() ?? '';
    final toUserId = (row['to_user_id'] as String?)?.trim() ?? '';
    final isOutgoing = fromUserId == currentUserId;
    final rawOther = isOutgoing ? row['invitee'] : row['inviter'];
    final fallbackOtherId = isOutgoing ? toUserId : fromUserId;
    final otherRow = rawOther is Map
        ? Map<String, dynamic>.from(rawOther)
        : <String, dynamic>{'id': fallbackOtherId};
    otherRow.putIfAbsent('id', () => fallbackOtherId);

    return TomoFriendRequestItem(
      id: row['id'] as String,
      fromUserId: fromUserId,
      toUserId: toUserId,
      direction: isOutgoing
          ? TomoFriendRequestDirection.outgoing
          : TomoFriendRequestDirection.incoming,
      otherUser: TomoFriendProfile.fromRow(otherRow),
      createdAt: DateTime.tryParse((row['created_at'] as String?) ?? ''),
    );
  }

  final String id;
  final String fromUserId;
  final String toUserId;
  final TomoFriendRequestDirection direction;
  final TomoFriendProfile otherUser;
  final DateTime? createdAt;

  bool get isOutgoing => direction == TomoFriendRequestDirection.outgoing;
  bool get isIncoming => direction == TomoFriendRequestDirection.incoming;
}

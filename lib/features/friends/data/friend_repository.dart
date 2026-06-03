import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/contracts/ohey_api_paths.dart';
import '../../../core/contracts/ohey_api_values.dart';
import '../../../core/data/backend_api_client.dart';
import '../../../core/models/ohey_avatar.dart';

final friendRepositoryProvider = Provider<FriendRepository>((ref) {
  return FriendRepository(ref.watch(backendApiClientProvider));
});

final pendingFriendRequestsProvider =
    FutureProvider<List<OheyFriendRequestItem>>((ref) {
      return ref.watch(friendRepositoryProvider).fetchPendingFriendRequests();
    });

class FriendRepository {
  const FriendRepository(this._client);

  final BackendApiClient _client;

  String? get currentUserId => _client.currentUserId;

  Future<OheyFriendProfile?> findProfileByUserId(String userId) async {
    final exactUserId = userId.trim();
    if (exactUserId.isEmpty) return null;
    try {
      final row = await _client.getRow(
        OheyApiPaths.profileByUserId(exactUserId),
      );
      return OheyFriendProfile.fromRow(row);
    } on BackendApiException catch (error) {
      if (error.statusCode == 404) return null;
      rethrow;
    }
  }

  Future<OheyFriendRelationshipStatus> relationshipStatus(
    String friendId,
  ) async {
    final row = await _client.getRow(
      OheyApiPaths.friendRequestStatus,
      query: {'friend_id': friendId},
    );
    return OheyFriendRelationshipStatus.fromRow(row);
  }

  Future<List<Map<String, dynamic>>> fetchFriendGroups() async {
    return _client.getRows(OheyApiPaths.friendGroups);
  }

  Future<List<Map<String, dynamic>>> saveFriendGroups(
    List<Map<String, dynamic>> groups,
  ) async {
    final response = await _client.put(OheyApiPaths.friendGroups, {
      'groups': groups,
    });
    return BackendApiClient.rowsFrom(response);
  }

  Future<void> addFriend(String friendId) async {
    await _client.post(OheyApiPaths.friends, {'friend_id': friendId});
  }

  Future<void> deleteFriend(String friendId) async {
    await _client.delete(OheyApiPaths.friend(friendId));
  }

  Future<void> sendFriendRequest(String friendId) async {
    await _client.post(OheyApiPaths.friendRequests, {'to_user_id': friendId});
  }

  Future<List<OheyFriendRequestItem>> fetchPendingFriendRequests({
    String direction = OheyRequestDirectionKeys.all,
  }) async {
    final rows = await _client.getRows(
      OheyApiPaths.friendRequests,
      query: {'direction': direction},
    );
    final currentUserId = _client.currentUserId ?? '';
    return rows
        .map((row) => OheyFriendRequestItem.fromRow(row, currentUserId))
        .toList(growable: false);
  }

  Future<void> updateFriendRequest(String requestId, String status) async {
    await _client.patch(OheyApiPaths.friendRequest(requestId), {
      'status': status,
    });
  }

  Future<void> cancelFriendRequest(String requestId) async {
    await updateFriendRequest(requestId, OheyStatusKeys.cancelled);
  }
}

class OheyFriendProfile {
  const OheyFriendProfile({
    required this.id,
    required this.userId,
    required this.displayName,
    required this.avatar,
  });

  factory OheyFriendProfile.fromRow(Map<String, dynamic> row) {
    return OheyFriendProfile(
      id: row['id'] as String,
      userId: (row['user_id'] as String?) ?? '',
      displayName: (row['display_name'] as String?)?.trim().isNotEmpty == true
          ? (row['display_name'] as String).trim()
          : 'Ohey friend',
      avatar:
          OheyAvatar.decode(row['avatar_url'] as String?) ??
          OheyAvatar.defaultAvatar,
    );
  }

  final String id;
  final String userId;
  final String displayName;
  final OheyAvatar avatar;
}

enum OheyFriendRequestState { none, outgoing, incoming }

class OheyFriendRelationshipStatus {
  const OheyFriendRelationshipStatus({
    required this.alreadyFriend,
    required this.requestState,
    this.requestId,
  });

  factory OheyFriendRelationshipStatus.fromRow(Map<String, dynamic> row) {
    final requestState = switch (row['request_state'] as String?) {
      OheyRelationshipStateKeys.outgoing => OheyFriendRequestState.outgoing,
      OheyRelationshipStateKeys.incoming => OheyFriendRequestState.incoming,
      _ => OheyFriendRequestState.none,
    };
    return OheyFriendRelationshipStatus(
      alreadyFriend: (row['already_friend'] as bool?) ?? false,
      requestState: requestState,
      requestId: (row['request_id'] as String?)?.trim(),
    );
  }

  final bool alreadyFriend;
  final OheyFriendRequestState requestState;
  final String? requestId;
}

enum OheyFriendRequestDirection { incoming, outgoing }

class OheyFriendRequestItem {
  const OheyFriendRequestItem({
    required this.id,
    required this.fromUserId,
    required this.toUserId,
    required this.direction,
    required this.otherUser,
    this.createdAt,
  });

  factory OheyFriendRequestItem.fromRow(
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

    return OheyFriendRequestItem(
      id: row['id'] as String,
      fromUserId: fromUserId,
      toUserId: toUserId,
      direction: isOutgoing
          ? OheyFriendRequestDirection.outgoing
          : OheyFriendRequestDirection.incoming,
      otherUser: OheyFriendProfile.fromRow(otherRow),
      createdAt: DateTime.tryParse((row['created_at'] as String?) ?? ''),
    );
  }

  final String id;
  final String fromUserId;
  final String toUserId;
  final OheyFriendRequestDirection direction;
  final OheyFriendProfile otherUser;
  final DateTime? createdAt;

  bool get isOutgoing => direction == OheyFriendRequestDirection.outgoing;
  bool get isIncoming => direction == OheyFriendRequestDirection.incoming;
}

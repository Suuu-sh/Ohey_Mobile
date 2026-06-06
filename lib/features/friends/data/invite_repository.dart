import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/contracts/ohey_api_paths.dart';
import '../../../core/data/backend_api_client.dart';
import '../../../core/models/ohey_avatar.dart';
import '../../../core/models/ohey_invite.dart';
import '../../../core/models/ohey_friend.dart';

final inviteRepositoryProvider = Provider<InviteRepository>((ref) {
  return InviteRepository(ref.watch(backendApiClientProvider));
});

class InviteRepository {
  InviteRepository(this._client);

  final BackendApiClient _client;

  String? get _userId => _client.currentUserId;

  Future<void> sendTodayInvite(String friendId, {String? activityLabel}) =>
      sendInvite(
        friendId: friendId,
        date: DateTime.now(),
        activityLabel: activityLabel,
      );

  Future<void> sendInvite({
    required String friendId,
    required DateTime date,
    String? activityLabel,
  }) async {
    await sendInvites(
      friendIds: [friendId],
      date: date,
      activityLabel: activityLabel,
    );
  }

  Future<void> sendInvites({
    required Iterable<String> friendIds,
    required DateTime date,
    String? activityLabel,
  }) async {
    final userId = _userId;
    if (userId == null) throw StateError('誘うにはログインが必要です。');
    final ids = {
      for (final friendId in friendIds)
        if (friendId.trim().isNotEmpty && friendId != userId) friendId.trim(),
    }.toList(growable: false);
    if (ids.isEmpty) throw StateError('誘えるフレンズがいません。');

    final cleanActivityLabel = activityLabel?.trim();
    await Future.wait([
      for (final friendId in ids)
        _client.post(OheyApiPaths.invites, {
          'invitee_user_id': friendId,
          'scheduled_date': _isoDate(date),
          if (cleanActivityLabel != null && cleanActivityLabel.isNotEmpty)
            'activity_label': cleanActivityLabel,
        }),
    ]);
  }

  Future<void> respond({
    required String inviteId,
    required OheyInviteStatus status,
  }) async {
    final userId = _userId;
    if (userId == null) throw StateError('返信するにはログインが必要です。');
    if (!status.isResponseAction) {
      throw StateError('このステータスには変更できません。');
    }
    await _client.patch(OheyApiPaths.invite(inviteId), {'status': status.key});
  }

  Future<List<OheyInvite>> fetchTodayReservations() async {
    final userId = _userId;
    if (userId == null) return const [];
    final rows = await _client.getRows(
      OheyApiPaths.todayReservations,
      query: {'date': _todayIsoDate()},
    );
    return rows.map(_inviteFromRow).toList(growable: false);
  }

  Future<List<OheyInvite>> fetchIncomingPendingInvites() async {
    final userId = _userId;
    if (userId == null) return const [];
    final rows = await _client.getRows(
      OheyApiPaths.incomingPendingInvites,
      query: {'date': _todayIsoDate()},
    );
    return rows.map(_inviteFromRow).toList(growable: false);
  }

  Future<List<OheyInvite>> fetchOutgoingActiveInvites({DateTime? date}) async {
    final userId = _userId;
    if (userId == null) return const [];
    final rows = await _client.getRows(
      OheyApiPaths.outgoingActiveInvites,
      query: {'date': date == null ? _todayIsoDate() : _isoDate(date)},
    );
    return rows.map(_inviteFromRow).toList(growable: false);
  }

  OheyInvite _inviteFromRow(Map<String, dynamic> row) {
    return OheyInvite(
      id: row['id'] as String,
      inviterUserId: row['inviter_user_id'] as String,
      inviteeUserId: row['invitee_user_id'] as String,
      scheduledDate: DateTime.parse(row['scheduled_date'] as String),
      activityLabel: row['activity_label'] as String?,
      status: oheyInviteStatusFromKey(row['status'] as String?),
      inviter: _profileToFriend(
        Map<String, dynamic>.from(row['inviter'] as Map),
      ),
      invitee: _profileToFriend(
        Map<String, dynamic>.from(row['invitee'] as Map),
      ),
    );
  }

  OheyFriend _profileToFriend(Map<String, dynamic> profile) {
    return OheyFriend(
      id: profile['id'] as String,
      name: (profile['display_name'] as String?) ?? 'Ohey friend',
      avatarEmoji: '🍻',
      vibe: (profile['user_id'] as String?) ?? '',
      characterAssetPath: '',
      kind: OheyFriendKind.cloud,
      palette: OheyFriendPalette.mint,
      avatar: OheyAvatar.decode(profile['avatar_url'] as String?),
    );
  }
}

String _todayIsoDate() => _isoDate(DateTime.now());

String _isoDate(DateTime date) {
  return '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/backend_api_client.dart';
import '../../../core/models/nomo_avatar.dart';
import '../../../core/models/nomo_invite.dart';
import '../../../core/models/nomo_friend.dart';
import '../../../core/models/nomo_gender.dart';

final inviteRepositoryProvider = Provider<InviteRepository>((ref) {
  return InviteRepository(ref.watch(backendApiClientProvider));
});

class InviteRepository {
  InviteRepository(this._client);

  final BackendApiClient _client;

  String? get _userId => _client.currentUserId;

  Future<void> sendTodayInvite(String friendId) =>
      sendInvite(friendId: friendId, date: DateTime.now());

  Future<void> sendInvite({
    required String friendId,
    required DateTime date,
  }) async {
    await sendInvites(friendIds: [friendId], date: date);
  }

  Future<void> sendInvites({
    required Iterable<String> friendIds,
    required DateTime date,
  }) async {
    final userId = _userId;
    if (userId == null) throw StateError('誘うにはログインが必要です。');
    final ids = {
      for (final friendId in friendIds)
        if (friendId.trim().isNotEmpty && friendId != userId) friendId.trim(),
    }.toList(growable: false);
    if (ids.isEmpty) throw StateError('誘えるフレンズがいません。');

    await Future.wait([
      for (final friendId in ids)
        _client.post('/v1/invites', {
          'invitee_user_id': friendId,
          'scheduled_date': _isoDate(date),
        }),
    ]);
  }

  Future<void> respond({
    required String inviteId,
    required NomoInviteStatus status,
  }) async {
    final userId = _userId;
    if (userId == null) throw StateError('返信するにはログインが必要です。');
    if (status != NomoInviteStatus.accepted &&
        status != NomoInviteStatus.rejected) {
      throw StateError('このステータスには変更できません。');
    }
    await _client.patch('/v1/invites/$inviteId', {'status': status.key});
  }

  Future<List<NomoInvite>> fetchTodayReservations() async {
    final userId = _userId;
    if (userId == null) return const [];
    final rows = await _client.getRows(
      '/v1/invites/today-reservations',
      query: {'date': _todayIsoDate()},
    );
    return rows.map(_inviteFromRow).toList(growable: false);
  }

  Future<List<NomoInvite>> fetchIncomingPendingInvites() async {
    final userId = _userId;
    if (userId == null) return const [];
    final rows = await _client.getRows(
      '/v1/invites/incoming-pending',
      query: {'date': _todayIsoDate()},
    );
    return rows.map(_inviteFromRow).toList(growable: false);
  }

  Future<List<NomoInvite>> fetchOutgoingActiveInvites({DateTime? date}) async {
    final userId = _userId;
    if (userId == null) return const [];
    final rows = await _client.getRows(
      '/v1/invites/outgoing-active',
      query: {'date': date == null ? _todayIsoDate() : _isoDate(date)},
    );
    return rows.map(_inviteFromRow).toList(growable: false);
  }

  NomoInvite _inviteFromRow(Map<String, dynamic> row) {
    return NomoInvite(
      id: row['id'] as String,
      inviterUserId: row['inviter_user_id'] as String,
      inviteeUserId: row['invitee_user_id'] as String,
      scheduledDate: DateTime.parse(row['scheduled_date'] as String),
      status: nomoInviteStatusFromKey(row['status'] as String?),
      inviter: _profileToFriend(
        Map<String, dynamic>.from(row['inviter'] as Map),
      ),
      invitee: _profileToFriend(
        Map<String, dynamic>.from(row['invitee'] as Map),
      ),
    );
  }

  NomoFriend _profileToFriend(Map<String, dynamic> profile) {
    return NomoFriend(
      id: profile['id'] as String,
      name: (profile['display_name'] as String?) ?? 'Nomo friend',
      avatarEmoji: '🍻',
      vibe: (profile['user_id'] as String?) ?? '',
      characterAssetPath: '',
      kind: NomoFriendKind.cloud,
      palette: NomoFriendPalette.mint,
      gender: nomoGenderFromKey(profile['gender'] as String?),
      avatar: NomoAvatar.decode(profile['avatar_url'] as String?),
    );
  }
}

String _todayIsoDate() => _isoDate(DateTime.now());

String _isoDate(DateTime date) {
  return '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}

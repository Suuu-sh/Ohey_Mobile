import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/backend_api_client.dart';
import '../../../core/models/nomo_avatar.dart';
import '../../../core/models/nomo_drink_invite.dart';
import '../../../core/models/nomo_friend.dart';
import '../../../core/models/nomo_gender.dart';

final drinkInviteRepositoryProvider = Provider<DrinkInviteRepository>((ref) {
  return DrinkInviteRepository(ref.watch(backendApiClientProvider));
});

class DrinkInviteRepository {
  DrinkInviteRepository(this._client);

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
        _client.post('/v1/drink-invites', {
          'to_user_id': friendId,
          'invite_date': _isoDate(date),
        }),
    ]);
  }

  Future<void> respond({
    required String inviteId,
    required NomoDrinkInviteStatus status,
  }) async {
    final userId = _userId;
    if (userId == null) throw StateError('返信するにはログインが必要です。');
    if (status != NomoDrinkInviteStatus.accepted &&
        status != NomoDrinkInviteStatus.rejected) {
      throw StateError('このステータスには変更できません。');
    }
    await _client.patch('/v1/drink-invites/$inviteId', {'status': status.key});
  }

  Future<List<NomoDrinkInvite>> fetchTodayReservations() async {
    final userId = _userId;
    if (userId == null) return const [];
    final rows = await _client.getRows(
      '/v1/drink-invites/today-reservations',
      query: {'date': _todayIsoDate()},
    );
    return rows.map(_inviteFromRow).toList(growable: false);
  }

  Future<List<NomoDrinkInvite>> fetchIncomingPendingInvites() async {
    final userId = _userId;
    if (userId == null) return const [];
    final rows = await _client.getRows(
      '/v1/drink-invites/incoming-pending',
      query: {'date': _todayIsoDate()},
    );
    return rows.map(_inviteFromRow).toList(growable: false);
  }

  Future<List<NomoDrinkInvite>> fetchOutgoingActiveInvites({
    DateTime? date,
  }) async {
    final userId = _userId;
    if (userId == null) return const [];
    final rows = await _client.getRows(
      '/v1/drink-invites/outgoing-active',
      query: {'date': date == null ? _todayIsoDate() : _isoDate(date)},
    );
    return rows.map(_inviteFromRow).toList(growable: false);
  }

  NomoDrinkInvite _inviteFromRow(Map<String, dynamic> row) {
    return NomoDrinkInvite(
      id: row['id'] as String,
      fromUserId: row['from_user_id'] as String,
      toUserId: row['to_user_id'] as String,
      inviteDate: DateTime.parse(row['invite_date'] as String),
      status: nomoDrinkInviteStatusFromKey(row['status'] as String?),
      fromUser: _profileToFriend(
        Map<String, dynamic>.from(row['from_user'] as Map),
      ),
      toUser: _profileToFriend(
        Map<String, dynamic>.from(row['to_user'] as Map),
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
      kind: NomiTomoKind.cloud,
      palette: NomiTomoPalette.mint,
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

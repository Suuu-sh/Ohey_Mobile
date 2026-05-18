import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/backend_api_client.dart';
import '../../../core/models/nomo_avatar.dart';
import '../../../core/models/nomo_drink_invite.dart';
import '../../../core/models/nomo_friend.dart';

final drinkInviteRepositoryProvider = Provider<DrinkInviteRepository>((ref) {
  return DrinkInviteRepository(ref.watch(backendApiClientProvider));
});

final todayReservationsProvider = FutureProvider<List<NomoDrinkInvite>>((ref) {
  return ref.watch(drinkInviteRepositoryProvider).fetchTodayReservations();
});

final incomingDrinkInvitesProvider = FutureProvider<List<NomoDrinkInvite>>((
  ref,
) {
  return ref.watch(drinkInviteRepositoryProvider).fetchIncomingPendingInvites();
});

class DrinkInviteController {
  DrinkInviteController(this._ref);

  final Ref _ref;

  Future<void> sendTodayInvite(String friendId) async {
    await _ref.read(drinkInviteRepositoryProvider).sendTodayInvite(friendId);
    _invalidate();
  }

  Future<void> accept(String inviteId) async {
    await _ref
        .read(drinkInviteRepositoryProvider)
        .respond(inviteId: inviteId, status: NomoDrinkInviteStatus.accepted);
    _invalidate();
  }

  Future<void> reject(String inviteId) async {
    await _ref
        .read(drinkInviteRepositoryProvider)
        .respond(inviteId: inviteId, status: NomoDrinkInviteStatus.rejected);
    _invalidate();
  }

  void _invalidate() {
    _ref.invalidate(todayReservationsProvider);
    _ref.invalidate(incomingDrinkInvitesProvider);
  }
}

final drinkInviteControllerProvider = Provider<DrinkInviteController>((ref) {
  return DrinkInviteController(ref);
});

class DrinkInviteRepository {
  DrinkInviteRepository(this._client);

  final BackendApiClient _client;

  String? get _userId => _client.currentUserId;

  Future<void> sendTodayInvite(String friendId) async {
    final userId = _userId;
    if (userId == null) throw StateError('誘うにはログインが必要です。');
    if (userId == friendId) throw StateError('自分には送れません。');

    await _client.post('/v1/drink-invites', {
      'to_user_id': friendId,
      'invite_date': _todayIsoDate(),
    });
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
    final rows = await _client.get(
      '/v1/drink-invites/today-reservations',
      query: {'date': _todayIsoDate()},
    );
    return _inviteRows(rows);
  }

  Future<List<NomoDrinkInvite>> fetchIncomingPendingInvites() async {
    final userId = _userId;
    if (userId == null) return const [];
    final rows = await _client.get(
      '/v1/drink-invites/incoming-pending',
      query: {'date': _todayIsoDate()},
    );
    return _inviteRows(rows);
  }

  List<NomoDrinkInvite> _inviteRows(Object? value) {
    final rows = value is List ? value : const <Object?>[];
    return rows
        .whereType<Map>()
        .map((row) => _inviteFromRow(Map<String, dynamic>.from(row)))
        .toList(growable: false);
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
      avatar: NomoAvatar.decode(profile['avatar_url'] as String?),
    );
  }
}

String _todayIsoDate() {
  final now = DateTime.now();
  return '${now.year.toString().padLeft(4, '0')}-'
      '${now.month.toString().padLeft(2, '0')}-'
      '${now.day.toString().padLeft(2, '0')}';
}

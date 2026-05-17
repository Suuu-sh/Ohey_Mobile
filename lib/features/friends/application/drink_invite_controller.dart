import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/data/supabase_client_provider.dart';
import '../../../core/models/nomo_avatar.dart';
import '../../../core/models/nomo_drink_invite.dart';
import '../../../core/models/nomo_friend.dart';

final drinkInviteRepositoryProvider = Provider<DrinkInviteRepository>((ref) {
  return DrinkInviteRepository(ref.watch(supabaseClientProvider));
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

  final SupabaseClient _client;

  String? get _userId => _client.auth.currentUser?.id;

  Future<void> sendTodayInvite(String friendId) async {
    final userId = _userId;
    if (userId == null) throw StateError('誘うにはログインが必要です。');
    if (userId == friendId) throw StateError('自分には送れません。');

    final today = _todayIsoDate();
    final existing = await _client
        .from('drink_invites')
        .select('id,status')
        .eq('invite_date', today)
        .or(
          'and(from_user_id.eq.$userId,to_user_id.eq.$friendId),and(from_user_id.eq.$friendId,to_user_id.eq.$userId)',
        )
        .inFilter('status', ['pending', 'accepted'])
        .limit(1);
    if (existing.isNotEmpty) {
      final status = existing.first['status'] as String?;
      throw StateError(status == 'accepted' ? '今日はもう予約済みです。' : 'すでに招待中です。');
    }

    await _client.from('drink_invites').insert({
      'from_user_id': userId,
      'to_user_id': friendId,
      'invite_date': today,
      'status': NomoDrinkInviteStatus.pending.key,
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
    await _client
        .from('drink_invites')
        .update({
          'status': status.key,
          'responded_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', inviteId)
        .eq('to_user_id', userId)
        .eq('status', NomoDrinkInviteStatus.pending.key);
  }

  Future<List<NomoDrinkInvite>> fetchTodayReservations() async {
    final userId = _userId;
    if (userId == null) return const [];
    final rows = await _client
        .from('drink_invites')
        .select(_inviteSelect)
        .eq('invite_date', _todayIsoDate())
        .eq('status', NomoDrinkInviteStatus.accepted.key)
        .or('from_user_id.eq.$userId,to_user_id.eq.$userId')
        .order('responded_at', ascending: false);
    return rows.map<NomoDrinkInvite>(_inviteFromRow).toList(growable: false);
  }

  Future<List<NomoDrinkInvite>> fetchIncomingPendingInvites() async {
    final userId = _userId;
    if (userId == null) return const [];
    final rows = await _client
        .from('drink_invites')
        .select(_inviteSelect)
        .eq('invite_date', _todayIsoDate())
        .eq('to_user_id', userId)
        .eq('status', NomoDrinkInviteStatus.pending.key)
        .order('created_at', ascending: false);
    return rows.map<NomoDrinkInvite>(_inviteFromRow).toList(growable: false);
  }

  static const _inviteSelect = '''
    id,
    from_user_id,
    to_user_id,
    invite_date,
    status,
    from_user:profiles!drink_invites_from_user_id_fkey(
      id,
      display_name,
      user_id,
      avatar_url
    ),
    to_user:profiles!drink_invites_to_user_id_fkey(
      id,
      display_name,
      user_id,
      avatar_url
    )
  ''';

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

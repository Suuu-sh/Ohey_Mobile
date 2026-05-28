import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/application/optimistic_update.dart';
import '../../../core/models/nomo_invite.dart';
import '../data/invite_repository.dart';

final todayReservationsProvider = FutureProvider<List<NomoInvite>>((ref) {
  return ref.watch(inviteRepositoryProvider).fetchTodayReservations();
});

final incomingInvitesProvider = FutureProvider<List<NomoInvite>>((ref) {
  return ref.watch(inviteRepositoryProvider).fetchIncomingPendingInvites();
});

final outgoingActiveInvitesProvider =
    FutureProvider.family<List<NomoInvite>, DateTime?>((ref, date) {
      return ref
          .watch(inviteRepositoryProvider)
          .fetchOutgoingActiveInvites(date: date);
    });

class InviteController {
  InviteController(this._ref);

  final Ref _ref;

  Future<void> sendTodayInvite(String friendId) =>
      sendInvite(friendId: friendId, date: DateTime.now());

  Future<void> sendTodayInvites(Iterable<String> friendIds) =>
      sendInvites(friendIds: friendIds, date: DateTime.now());

  Future<void> sendInvite({
    required String friendId,
    required DateTime date,
  }) async {
    await runOptimistic<void>(
      apply: _invalidate,
      rollback: _invalidate,
      commit: () => _ref
          .read(inviteRepositoryProvider)
          .sendInvite(friendId: friendId, date: date),
      confirm: (_) => _invalidate(),
    );
  }

  Future<void> sendInvites({
    required Iterable<String> friendIds,
    required DateTime date,
  }) async {
    final ids = {
      for (final friendId in friendIds)
        if (friendId.trim().isNotEmpty) friendId.trim(),
    }.toList(growable: false);
    if (ids.isEmpty) return;
    await runOptimistic<void>(
      apply: _invalidate,
      rollback: _invalidate,
      commit: () => _ref
          .read(inviteRepositoryProvider)
          .sendInvites(friendIds: ids, date: date),
      confirm: (_) => _invalidate(),
    );
  }

  Future<void> accept(String inviteId) async {
    await _respondOptimistically(
      inviteId: inviteId,
      status: NomoInviteStatus.accepted,
    );
  }

  Future<void> reject(String inviteId) async {
    await _respondOptimistically(
      inviteId: inviteId,
      status: NomoInviteStatus.rejected,
    );
  }

  Future<void> _respondOptimistically({
    required String inviteId,
    required NomoInviteStatus status,
  }) async {
    await runOptimistic<void>(
      apply: _invalidate,
      rollback: _invalidate,
      commit: () => _ref
          .read(inviteRepositoryProvider)
          .respond(inviteId: inviteId, status: status),
      confirm: (_) => _invalidate(),
    );
  }

  void _invalidate() {
    _ref.invalidate(todayReservationsProvider);
    _ref.invalidate(incomingInvitesProvider);
    _ref.invalidate(outgoingActiveInvitesProvider);
  }
}

final inviteControllerProvider = Provider<InviteController>((ref) {
  return InviteController(ref);
});

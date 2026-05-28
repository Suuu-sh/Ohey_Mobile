import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/application/optimistic_update.dart';
import '../../../core/models/nomo_drink_invite.dart';
import '../data/drink_invite_repository.dart';

final todayReservationsProvider = FutureProvider<List<NomoDrinkInvite>>((ref) {
  return ref.watch(drinkInviteRepositoryProvider).fetchTodayReservations();
});

final incomingDrinkInvitesProvider = FutureProvider<List<NomoDrinkInvite>>((
  ref,
) {
  return ref.watch(drinkInviteRepositoryProvider).fetchIncomingPendingInvites();
});

final outgoingActiveDrinkInvitesProvider =
    FutureProvider.family<List<NomoDrinkInvite>, DateTime?>((ref, date) {
      return ref
          .watch(drinkInviteRepositoryProvider)
          .fetchOutgoingActiveInvites(date: date);
    });

class DrinkInviteController {
  DrinkInviteController(this._ref);

  final Ref _ref;

  Future<void> sendTodayInvite(String friendId) =>
      sendInvite(friendId: friendId, date: DateTime.now());

  Future<void> sendInvite({
    required String friendId,
    required DateTime date,
  }) async {
    await runOptimistic<void>(
      apply: _invalidate,
      rollback: _invalidate,
      commit: () => _ref
          .read(drinkInviteRepositoryProvider)
          .sendInvite(friendId: friendId, date: date),
      confirm: (_) => _invalidate(),
    );
  }

  Future<void> accept(String inviteId) async {
    await _respondOptimistically(
      inviteId: inviteId,
      status: NomoDrinkInviteStatus.accepted,
    );
  }

  Future<void> reject(String inviteId) async {
    await _respondOptimistically(
      inviteId: inviteId,
      status: NomoDrinkInviteStatus.rejected,
    );
  }

  Future<void> _respondOptimistically({
    required String inviteId,
    required NomoDrinkInviteStatus status,
  }) async {
    await runOptimistic<void>(
      apply: _invalidate,
      rollback: _invalidate,
      commit: () => _ref
          .read(drinkInviteRepositoryProvider)
          .respond(inviteId: inviteId, status: status),
      confirm: (_) => _invalidate(),
    );
  }

  void _invalidate() {
    _ref.invalidate(todayReservationsProvider);
    _ref.invalidate(incomingDrinkInvitesProvider);
    _ref.invalidate(outgoingActiveDrinkInvitesProvider);
  }
}

final drinkInviteControllerProvider = Provider<DrinkInviteController>((ref) {
  return DrinkInviteController(ref);
});

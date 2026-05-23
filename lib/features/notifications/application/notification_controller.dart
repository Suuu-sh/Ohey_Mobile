import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/application/optimistic_update.dart';

import 'os_notification_service.dart';
import '../data/notification_repository.dart';

final notificationControllerProvider =
    AsyncNotifierProvider<NotificationController, List<NomoNotification>>(
      NotificationController.new,
    );

final hasUnreadNotificationsProvider = Provider<bool>((ref) {
  final notifications = ref.watch(notificationControllerProvider).asData?.value;
  return notifications?.any((notification) => notification.isUnread) ?? false;
});

class NotificationController extends AsyncNotifier<List<NomoNotification>> {
  @override
  Future<List<NomoNotification>> build() async {
    final notifications = await ref
        .watch(notificationRepositoryProvider)
        .fetchNotifications();
    await ref
        .read(osNotificationServiceProvider)
        .showNewNotifications(notifications);
    return notifications;
  }

  Future<void> markAllRead() async {
    final current = state.asData?.value ?? const <NomoNotification>[];
    if (!current.any((notification) => notification.isUnread)) return;
    await runOptimistic<void>(
      apply: () => state = AsyncValue.data([
        for (final notification in current) notification.markRead(),
      ]),
      rollback: () => state = AsyncValue.data(current),
      commit: () => ref.read(notificationRepositoryProvider).markAllRead(),
      confirm: (_) => ref.invalidateSelf(),
    );
  }

  Future<void> acceptFriendRequest(String friendRequestId) async {
    await _respondToNotification(
      id: friendRequestId,
      update: () => ref
          .read(notificationRepositoryProvider)
          .updateFriendRequest(
            friendRequestId: friendRequestId,
            status: 'accepted',
          ),
    );
  }

  Future<void> rejectFriendRequest(String friendRequestId) async {
    await _respondToNotification(
      id: friendRequestId,
      update: () => ref
          .read(notificationRepositoryProvider)
          .updateFriendRequest(
            friendRequestId: friendRequestId,
            status: 'rejected',
          ),
    );
  }

  Future<void> acceptDrinkInvite(String drinkInviteId) async {
    await _respondToNotification(
      id: drinkInviteId,
      update: () => ref
          .read(notificationRepositoryProvider)
          .updateDrinkInvite(drinkInviteId: drinkInviteId, status: 'accepted'),
    );
  }

  Future<void> rejectDrinkInvite(String drinkInviteId) async {
    await _respondToNotification(
      id: drinkInviteId,
      update: () => ref
          .read(notificationRepositoryProvider)
          .updateDrinkInvite(drinkInviteId: drinkInviteId, status: 'rejected'),
    );
  }

  Future<void> _respondToNotification({
    required String id,
    required Future<void> Function() update,
  }) async {
    final previous = state.asData?.value ?? const <NomoNotification>[];
    await runOptimistic<void>(
      apply: () => state = AsyncValue.data([
        for (final notification in previous)
          if (notification.friendRequestId != id &&
              notification.drinkInviteId != id)
            notification,
      ]),
      rollback: () => state = AsyncValue.data(previous),
      commit: update,
      confirm: (_) => ref.invalidateSelf(),
    );
  }
}

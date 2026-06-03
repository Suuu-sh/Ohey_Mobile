import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/application/optimistic_update.dart';
import '../../../core/contracts/ohey_api_values.dart';

import 'os_notification_service.dart';
import '../data/notification_repository.dart';

final notificationControllerProvider =
    AsyncNotifierProvider<NotificationController, List<OheyNotification>>(
      NotificationController.new,
    );

final hasUnreadNotificationsProvider = Provider<bool>((ref) {
  final notifications = ref.watch(notificationControllerProvider).asData?.value;
  return notifications?.any((notification) => notification.isUnread) ?? false;
});

class NotificationController extends AsyncNotifier<List<OheyNotification>> {
  @override
  Future<List<OheyNotification>> build() async {
    final notifications = await ref
        .watch(notificationRepositoryProvider)
        .fetchNotifications();
    await ref
        .read(osNotificationServiceProvider)
        .showNewNotifications(notifications);
    return notifications;
  }

  Future<void> markAllRead() async {
    final current = state.asData?.value ?? const <OheyNotification>[];
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
            status: OheyStatusKeys.accepted,
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
            status: OheyStatusKeys.rejected,
          ),
    );
  }

  Future<void> acceptInvite(String inviteId) async {
    await _respondToNotification(
      id: inviteId,
      update: () => ref
          .read(notificationRepositoryProvider)
          .updateInvite(inviteId: inviteId, status: OheyStatusKeys.accepted),
    );
  }

  Future<void> rejectInvite(String inviteId) async {
    await _respondToNotification(
      id: inviteId,
      update: () => ref
          .read(notificationRepositoryProvider)
          .updateInvite(inviteId: inviteId, status: OheyStatusKeys.rejected),
    );
  }

  Future<void> _respondToNotification({
    required String id,
    required Future<void> Function() update,
  }) async {
    final previous = state.asData?.value ?? const <OheyNotification>[];
    await runOptimistic<void>(
      apply: () => state = AsyncValue.data([
        for (final notification in previous)
          if (notification.friendRequestId != id && notification.inviteId != id)
            notification,
      ]),
      rollback: () => state = AsyncValue.data(previous),
      commit: update,
      confirm: (_) => ref.invalidateSelf(),
    );
  }
}

import 'package:flutter_riverpod/flutter_riverpod.dart';

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
    await ref.read(notificationRepositoryProvider).markAllRead();
    ref.invalidateSelf();
  }

  Future<void> acceptFriendRequest(String friendRequestId) async {
    await ref
        .read(notificationRepositoryProvider)
        .updateFriendRequest(
          friendRequestId: friendRequestId,
          status: 'accepted',
        );
    ref.invalidateSelf();
  }

  Future<void> rejectFriendRequest(String friendRequestId) async {
    await ref
        .read(notificationRepositoryProvider)
        .updateFriendRequest(
          friendRequestId: friendRequestId,
          status: 'rejected',
        );
    ref.invalidateSelf();
  }
}

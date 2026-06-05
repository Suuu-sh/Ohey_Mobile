import 'package:flutter_test/flutter_test.dart';
import 'package:ohey/core/contracts/ohey_api_values.dart';
import 'package:ohey/features/notifications/data/notification_repository.dart';

void main() {
  OheyNotification reminder({
    required DateTime createdAt,
    DateTime? notificationDate,
  }) {
    return OheyNotification(
      id: 'notification-1',
      kind: OheyNotificationKindKeys.todayReservationReminder,
      title: '今日の予定があります',
      message: 'フレンズとの予定が今日あります。',
      createdAt: createdAt,
      isUnread: true,
      notificationDate: notificationDate,
    );
  }

  test('today reservation reminder expires after its notification date', () {
    final notification = reminder(
      createdAt: DateTime(2026, 6, 1, 8),
      notificationDate: DateTime(2026, 6, 1),
    );

    expect(
      notification.isExpiredTodayReservationReminder(DateTime(2026, 6, 2)),
      isTrue,
    );
  });

  test(
    'today reservation reminder remains visible on its notification date',
    () {
      final notification = reminder(
        createdAt: DateTime(2026, 6, 1, 8),
        notificationDate: DateTime(2026, 6, 1),
      );

      expect(
        notification.isExpiredTodayReservationReminder(
          DateTime(2026, 6, 1, 23, 59),
        ),
        isFalse,
      );
    },
  );

  test('non reminder notification does not expire by this rule', () {
    final notification = OheyNotification(
      id: 'notification-2',
      kind: OheyNotificationKindKeys.friendRequestAccepted,
      title: 'フレンズ申請が承認されました',
      message: 'フレンズになりました。',
      createdAt: DateTime(2026, 6, 1),
      isUnread: false,
    );

    expect(
      notification.isExpiredTodayReservationReminder(DateTime(2026, 6, 5)),
      isFalse,
    );
  });
}

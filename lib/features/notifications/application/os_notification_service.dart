import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/models/nomo_drink_invite.dart';
import '../data/notification_repository.dart';

final osNotificationServiceProvider = Provider<OsNotificationService>((ref) {
  return OsNotificationService();
});

class OsNotificationService {
  OsNotificationService();

  static const _channel = AndroidNotificationChannel(
    'nomo_notifications',
    'Tomola通知',
    description: 'フレンズ申請、飲み予定、いいねなどのTomola通知',
    importance: Importance.high,
  );
  static const _lastNotifiedKey = 'nomo_last_os_notification_created_at';

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> showNewNotifications(
    List<NomoNotification> notifications,
  ) async {
    if (notifications.isEmpty) return;
    await _initialize();

    final prefs = await SharedPreferences.getInstance();
    final lastNotifiedAt = DateTime.tryParse(
      prefs.getString(_lastNotifiedKey) ?? '',
    );
    final newest = notifications
        .map((notification) => notification.createdAt)
        .reduce((a, b) => a.isAfter(b) ? a : b);

    if (lastNotifiedAt == null) {
      await prefs.setString(_lastNotifiedKey, newest.toIso8601String());
      return;
    }

    final newUnread =
        notifications
            .where(
              (notification) =>
                  notification.isUnread &&
                  notification.createdAt.isAfter(lastNotifiedAt),
            )
            .toList(growable: false)
          ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

    for (final notification in newUnread) {
      await _plugin.show(
        id: notification.id.hashCode,
        title: notification.title,
        body: notification.message,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'nomo_notifications',
            'Tomola通知',
            channelDescription: 'フレンズ申請、飲み予定、いいねなどのTomola通知',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: notification.id,
      );
    }

    if (newest.isAfter(lastNotifiedAt)) {
      await prefs.setString(_lastNotifiedKey, newest.toIso8601String());
    }
  }

  Future<void> showDrinkInviteReceived(NomoDrinkInvite invite) async {
    await _initialize();

    final prefs = await SharedPreferences.getInstance();
    final notifiedKey = 'nomo_notified_drink_invite_${invite.id}';
    if (prefs.getBool(notifiedKey) ?? false) return;

    await _plugin.show(
      id: invite.id.hashCode,
      title: '${invite.fromUser.name}から飲みのお誘い',
      body: '今日飲みに行かない？アプリで返信できます。',
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'nomo_notifications',
          'Tomola通知',
          channelDescription: 'フレンズ申請、飲み予定、いいねなどのTomola通知',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: 'drink_invite:${invite.id}',
    );
    await prefs.setBool(notifiedKey, true);
  }

  Future<void> _initialize() async {
    if (_initialized) return;

    const initializationSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      ),
    );
    await _plugin.initialize(settings: initializationSettings);

    if (Platform.isAndroid) {
      final android = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      await android?.createNotificationChannel(_channel);
      await android?.requestNotificationsPermission();
    } else if (Platform.isIOS) {
      final ios = _plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >();
      await ios?.requestPermissions(alert: true, badge: true, sound: true);
    }

    _initialized = true;
  }
}

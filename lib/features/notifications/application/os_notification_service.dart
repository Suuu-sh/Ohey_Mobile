import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/models/ohey_invite.dart';
import '../../../core/models/yurubo.dart';
import '../../../core/models/ohey_friend_request_status.dart';
import '../data/notification_repository.dart';

final osNotificationServiceProvider = Provider<OsNotificationService>((ref) {
  return OsNotificationService();
});

class _NotificationDeliveryPolicy {
  const _NotificationDeliveryPolicy._();

  static const _osAllowedKinds = <String>{
    // Actionable and social-graph changing notifications only.
    'friend_request_received',
    'friend_request_accepted',
    'invite_received',
    'invite_accepted',
    'today_reservation_reminder',
  };

  static bool shouldShowOsNotification(OheyNotification notification) {
    if (!_osAllowedKinds.contains(notification.kind)) return false;
    if (notification.kind == 'friend_request_received') {
      return oheyFriendRequestStatusFromKey(
        notification.friendRequestStatus,
      ).isPending;
    }
    if (notification.kind == 'invite_received') {
      return oheyInviteStatusFromKey(notification.inviteStatus).isPending;
    }
    return true;
  }

  static List<OheyNotification> coalesce(List<OheyNotification> notifications) {
    if (notifications.length <= 2) return notifications;
    final actionable = notifications
        .where(
          (notification) =>
              notification.kind == 'friend_request_received' ||
              notification.kind == 'invite_received',
        )
        .take(2)
        .toList(growable: false);
    if (actionable.isNotEmpty) return actionable;
    return notifications.take(1).toList(growable: false);
  }
}

class OsNotificationService {
  OsNotificationService();

  static const _channel = AndroidNotificationChannel(
    'ohey_notifications',
    'Ohey通知',
    description: 'フレンズ申請、お誘い、ゆるぼなど厳選したOhey通知',
    importance: Importance.high,
  );
  static const _lastNotifiedKey = 'ohey_last_os_notification_created_at';

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> showNewNotifications(
    List<OheyNotification> notifications,
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
                  notification.createdAt.isAfter(lastNotifiedAt) &&
                  _NotificationDeliveryPolicy.shouldShowOsNotification(
                    notification,
                  ),
            )
            .toList(growable: false)
          ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

    final deliveryBatch = _NotificationDeliveryPolicy.coalesce(newUnread);
    for (final notification in deliveryBatch) {
      await _plugin.show(
        id: notification.id.hashCode,
        title: notification.displayTitle,
        body: notification.displayMessage,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'ohey_notifications',
            'Ohey通知',
            channelDescription: 'フレンズ申請、お誘い、ゆるぼなど厳選したOhey通知',
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

  Future<void> showYuruboParticipationRequest(
    Yurubo yurubo,
    YuruboParticipant participant,
  ) async {
    await _initialize();

    await _plugin.show(
      id: 'yurubo_request:${yurubo.id}:${participant.userId}'.hashCode,
      title: '${participant.name}さんから参加申請',
      body: '「${yurubo.title}」への参加申請が届いたよ。アプリで承認してね。',
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'ohey_notifications',
          'Ohey通知',
          channelDescription: 'フレンズ申請、お誘い、ゆるぼなど厳選したOhey通知',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: 'yurubo_request:${yurubo.id}:${participant.userId}',
    );
  }

  Future<void> showInviteReceived(OheyInvite invite) async {
    await _initialize();

    final prefs = await SharedPreferences.getInstance();
    final notifiedKey = 'ohey_notified_invite_${invite.id}';
    if (prefs.getBool(notifiedKey) ?? false) return;

    await _plugin.show(
      id: invite.id.hashCode,
      title: '${invite.inviter.name}からお誘い',
      body: '${invite.summary()}が届いたよ。アプリで返事してね。',
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'ohey_notifications',
          'Ohey通知',
          channelDescription: 'フレンズ申請、お誘い、ゆるぼなど厳選したOhey通知',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: 'invite:${invite.id}',
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

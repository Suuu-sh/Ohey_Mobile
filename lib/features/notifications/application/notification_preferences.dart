import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/contracts/ohey_api_values.dart';

final notificationPreferencesProvider =
    AsyncNotifierProvider<
      NotificationPreferencesController,
      NotificationPreferences
    >(NotificationPreferencesController.new);

class NotificationPreferences {
  const NotificationPreferences({
    this.friendRequests = true,
    this.invites = true,
    this.yurubos = true,
  });

  final bool friendRequests;
  final bool invites;
  final bool yurubos;

  bool allowsKind(String kind) {
    switch (kind) {
      case OheyNotificationKindKeys.friendRequestReceived:
      case OheyNotificationKindKeys.friendRequestAccepted:
        return friendRequests;
      case OheyNotificationKindKeys.inviteReceived:
      case OheyNotificationKindKeys.inviteAccepted:
      case OheyNotificationKindKeys.todayReservationReminder:
        return invites;
      case OheyNotificationKindKeys.yuruboCreated:
        return yurubos;
      default:
        return true;
    }
  }

  NotificationPreferences copyWith({
    bool? friendRequests,
    bool? invites,
    bool? yurubos,
  }) => NotificationPreferences(
    friendRequests: friendRequests ?? this.friendRequests,
    invites: invites ?? this.invites,
    yurubos: yurubos ?? this.yurubos,
  );
}

class NotificationPreferencesController
    extends AsyncNotifier<NotificationPreferences> {
  static const _friendRequestsKey = 'ohey_notify_friend_requests';
  static const _invitesKey = 'ohey_notify_invites';
  static const _yurubosKey = 'ohey_notify_yurubos';

  @override
  Future<NotificationPreferences> build() async {
    final prefs = await SharedPreferences.getInstance();
    return NotificationPreferences(
      friendRequests: prefs.getBool(_friendRequestsKey) ?? true,
      invites: prefs.getBool(_invitesKey) ?? true,
      yurubos: prefs.getBool(_yurubosKey) ?? true,
    );
  }

  Future<void> setFriendRequests(bool enabled) => _update(
    (value) => value.copyWith(friendRequests: enabled),
    _friendRequestsKey,
    enabled,
  );

  Future<void> setInvites(bool enabled) => _update(
    (value) => value.copyWith(invites: enabled),
    _invitesKey,
    enabled,
  );

  Future<void> setYurubos(bool enabled) => _update(
    (value) => value.copyWith(yurubos: enabled),
    _yurubosKey,
    enabled,
  );

  Future<void> _update(
    NotificationPreferences Function(NotificationPreferences) update,
    String key,
    bool value,
  ) async {
    final current = state.asData?.value ?? const NotificationPreferences();
    final next = update(current);
    state = AsyncValue.data(next);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }
}

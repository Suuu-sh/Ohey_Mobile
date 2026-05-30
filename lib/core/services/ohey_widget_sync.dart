import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/memories/application/memory_controller.dart';
import '../application/ohey_user_controller.dart';
import '../models/ohey_friend.dart';
import '../models/ohey_user.dart';

class OheyWidgetSnapshotSync extends ConsumerStatefulWidget {
  const OheyWidgetSnapshotSync({super.key});

  @override
  ConsumerState<OheyWidgetSnapshotSync> createState() =>
      _OheyWidgetSnapshotSyncState();
}

class _OheyWidgetSnapshotSyncState
    extends ConsumerState<OheyWidgetSnapshotSync> {
  String? _lastSnapshotKey;
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(oheyUserProvider);
    final friendsAsync = user == null ? null : ref.watch(friendsProvider);
    final friends =
        friendsAsync?.maybeWhen(
          data: (value) => value,
          orElse: () => const <OheyFriend>[],
        ) ??
        const <OheyFriend>[];

    final snapshot = _OheyWidgetSnapshot.from(user: user, friends: friends);
    if (snapshot.cacheKey != _lastSnapshotKey) {
      _lastSnapshotKey = snapshot.cacheKey;
      _scheduleUpdate(snapshot);
    }

    return const SizedBox.shrink();
  }

  void _scheduleUpdate(_OheyWidgetSnapshot snapshot) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      unawaited(_OheyWidgetSync.updateSnapshot(snapshot));
    });
  }
}

class _OheyWidgetSync {
  _OheyWidgetSync._();

  static const MethodChannel _channel = MethodChannel('ohey/widget_sync');

  static Future<void> updateSnapshot(_OheyWidgetSnapshot snapshot) async {
    try {
      await _channel.invokeMethod<void>('updateSnapshot', snapshot.payload);
    } on MissingPluginException {
      // Non-iOS platforms do not have a widget extension.
    } on PlatformException {
      // Widgets are a convenience surface; never block the app if native sync
      // fails because App Groups or WidgetKit are unavailable.
    }
  }
}

class _OheyWidgetSnapshot {
  const _OheyWidgetSnapshot({
    required this.statusKey,
    required this.statusLabel,
    required this.statusDescription,
    required this.availableFriendsCount,
    required this.availableFriendNames,
    required this.availableFriendStatusLabels,
  });

  factory _OheyWidgetSnapshot.from({
    required OheyUser? user,
    required List<OheyFriend> friends,
  }) {
    final status = user?.dailyStatus ?? OheyDailyStatus.unselected;
    final availableFriends = friends
        .where((friend) => oheyDailyStatusFromKey(friend.statusKey).isAvailable)
        .toList(growable: false);

    return _OheyWidgetSnapshot(
      statusKey: status.key,
      statusLabel: user == null ? '今日の気分は？' : status.label,
      statusDescription: user == null
          ? 'Oheyを開いて今日の予定感をセットしよう'
          : status.description,
      availableFriendsCount: availableFriends.length,
      availableFriendNames: [
        for (final friend in availableFriends.take(3)) friend.name,
      ],
      availableFriendStatusLabels: [
        for (final friend in availableFriends.take(3))
          oheyDailyStatusFromKey(friend.statusKey).label,
      ],
    );
  }

  final String statusKey;
  final String statusLabel;
  final String statusDescription;
  final int availableFriendsCount;
  final List<String> availableFriendNames;
  final List<String> availableFriendStatusLabels;

  String get cacheKey => Object.hashAll([
    statusKey,
    statusLabel,
    statusDescription,
    availableFriendsCount,
    ...availableFriendNames,
    ...availableFriendStatusLabels,
  ]).toString();

  Map<String, Object?> get payload => {
    'statusKey': statusKey,
    'statusLabel': statusLabel,
    'statusDescription': statusDescription,
    'availableFriendsCount': availableFriendsCount,
    'availableFriendNames': availableFriendNames,
    'availableFriendStatusLabels': availableFriendStatusLabels,
    'updatedAtMillis': DateTime.now().millisecondsSinceEpoch,
  };
}

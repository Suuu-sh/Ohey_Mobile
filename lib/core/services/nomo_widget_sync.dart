import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/memories/application/memory_controller.dart';
import '../application/nomo_user_controller.dart';
import '../models/nomo_friend.dart';
import '../models/nomo_user.dart';

class NomoWidgetSnapshotSync extends ConsumerStatefulWidget {
  const NomoWidgetSnapshotSync({super.key});

  @override
  ConsumerState<NomoWidgetSnapshotSync> createState() =>
      _NomoWidgetSnapshotSyncState();
}

class _NomoWidgetSnapshotSyncState
    extends ConsumerState<NomoWidgetSnapshotSync> {
  String? _lastSnapshotKey;
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(nomoUserProvider);
    final friendsAsync = user == null ? null : ref.watch(friendsProvider);
    final friends =
        friendsAsync?.maybeWhen(
          data: (value) => value,
          orElse: () => const <NomoFriend>[],
        ) ??
        const <NomoFriend>[];

    final snapshot = _NomoWidgetSnapshot.from(user: user, friends: friends);
    if (snapshot.cacheKey != _lastSnapshotKey) {
      _lastSnapshotKey = snapshot.cacheKey;
      _scheduleUpdate(snapshot);
    }

    return const SizedBox.shrink();
  }

  void _scheduleUpdate(_NomoWidgetSnapshot snapshot) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      unawaited(_NomoWidgetSync.updateSnapshot(snapshot));
    });
  }
}

class _NomoWidgetSync {
  _NomoWidgetSync._();

  static const MethodChannel _channel = MethodChannel('nomo/widget_sync');

  static Future<void> updateSnapshot(_NomoWidgetSnapshot snapshot) async {
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

class _NomoWidgetSnapshot {
  const _NomoWidgetSnapshot({
    required this.statusKey,
    required this.statusLabel,
    required this.statusDescription,
    required this.availableFriendsCount,
    required this.availableFriendNames,
    required this.availableFriendStatusLabels,
  });

  factory _NomoWidgetSnapshot.from({
    required NomoUser? user,
    required List<NomoFriend> friends,
  }) {
    final status = user?.dailyStatus ?? NomoDailyStatus.unselected;
    final availableFriends = friends
        .where((friend) => nomoDailyStatusFromKey(friend.statusKey).isAvailable)
        .toList(growable: false);

    return _NomoWidgetSnapshot(
      statusKey: status.key,
      statusLabel: user == null ? '今日の気分は？' : status.label,
      statusDescription: user == null
          ? 'Nomoを開いて今日の予定感をセットしよう'
          : status.description,
      availableFriendsCount: availableFriends.length,
      availableFriendNames: [
        for (final friend in availableFriends.take(3)) friend.name,
      ],
      availableFriendStatusLabels: [
        for (final friend in availableFriends.take(3))
          nomoDailyStatusFromKey(friend.statusKey).label,
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

part of 'home_screen.dart';

class _FeedNotificationsScreen extends ConsumerStatefulWidget {
  const _FeedNotificationsScreen();

  @override
  ConsumerState<_FeedNotificationsScreen> createState() =>
      _FeedNotificationsScreenState();
}

class _FeedNotificationsScreenState
    extends ConsumerState<_FeedNotificationsScreen> {
  bool _scheduledRead = false;

  @override
  Widget build(BuildContext context) {
    final notificationsAsync = ref.watch(notificationControllerProvider);
    final notifications = notificationsAsync.asData?.value
        .map(_FeedNotification.fromNotification)
        .toList(growable: false);

    if (!_scheduledRead &&
        (notificationsAsync.asData?.value.any(
              (notification) => notification.isUnread,
            ) ??
            false)) {
      _scheduledRead = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ref.read(notificationControllerProvider.notifier).markAllRead();
        }
      });
    }

    final isWhite = Theme.of(context).brightness == Brightness.light;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: isWhite ? Colors.white : AppColors.darkBackground,
      body: MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: const TextScaler.linear(1.0)),
        child: _FeedBackground(
          child: SafeArea(
            bottom: false,
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(22, 12, 22, 124),
                  sliver: SliverList.list(
                    children: [
                      Stack(
                        children: [
                          CupertinoButton(
                            minimumSize: const Size(44, 44),
                            padding: EdgeInsets.zero,
                            borderRadius: BorderRadius.circular(16),
                            onPressed: () => Navigator.of(context).maybePop(),
                            child: Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: isWhite
                                    ? const Color(0xFFF2F4F6)
                                    : Colors.white.withValues(alpha: .06),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isWhite
                                      ? const Color(0xFFD7DEE7)
                                      : Colors.white.withValues(alpha: .09),
                                ),
                              ),
                              child: Center(
                                child: Transform.translate(
                                  offset: const Offset(-1, -1),
                                  child: Text(
                                    '＜',
                                    textAlign: TextAlign.center,
                                    strutStyle: const StrutStyle(
                                      fontSize: 23,
                                      height: 1,
                                      forceStrutHeight: true,
                                    ),
                                    style: TextStyle(
                                      color: isWhite
                                          ? const Color(0xFF27313B)
                                          : Colors.white,
                                      fontSize: 23,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: -2,
                                      height: 1,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Positioned.fill(
                            child: Align(
                              alignment: Alignment.center,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 56,
                                ),
                                child: Text(
                                  'お知らせ',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: isWhite
                                        ? const Color(0xFF27313B)
                                        : Colors.white,
                                    fontSize: 23,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: -.8,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      if (notificationsAsync.isLoading && notifications == null)
                        const Padding(
                          padding: EdgeInsets.only(top: 42),
                          child: Center(child: CupertinoActivityIndicator()),
                        )
                      else if (notificationsAsync.hasError &&
                          notifications == null)
                        _FeedEmptyState(
                          icon: CupertinoIcons.exclamationmark_triangle,
                          isWhite: isWhite,
                          title: 'お知らせを読み込めませんでした',
                          message: 'あとでもう一度試してね。',
                          accent: const Color(0xFFFF75B5),
                        )
                      else if ((notifications ?? const []).isEmpty)
                        _NotificationEmptyState(isWhite: isWhite)
                      else
                        ..._buildNotificationSections(
                          notifications!,
                          isWhite: isWhite,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildNotificationSections(
    List<_FeedNotification> notifications, {
    required bool isWhite,
  }) {
    final actionItems = notifications
        .where((notification) => notification.requiresAction)
        .toList(growable: false);
    final recentItems = notifications
        .where((notification) => !notification.requiresAction)
        .toList(growable: false);

    return [
      if (actionItems.isNotEmpty) ...[
        _NotificationSectionHeader(
          title: '対応が必要',
          message: '飲み招待やフレンズ申請はここから返事できます',
          count: actionItems.length,
          accent: AppColors.primaryAction,
          isWhite: isWhite,
        ),
        ...actionItems.map(
          (notification) => _NotificationTile(
            notification: notification,
            isWhite: isWhite,
            priority: true,
            onTap: notification.canOpen
                ? () => _openNotification(notification)
                : null,
          ),
        ),
        const SizedBox(height: 12),
      ],
      _NotificationSectionHeader(
        title: '最近のお知らせ',
        message: actionItems.isEmpty ? '新しい反応や予定がここに届きます' : 'いいね・公式通知・返信済みはこちら',
        count: recentItems.length,
        accent: AppColors.invite,
        isWhite: isWhite,
      ),
      if (recentItems.isEmpty)
        _NotificationSectionEmptyNote(isWhite: isWhite)
      else
        ...recentItems.map(
          (notification) => _NotificationTile(
            notification: notification,
            isWhite: isWhite,
            onTap: notification.canOpen
                ? () => _openNotification(notification)
                : null,
          ),
        ),
    ];
  }

  Future<void> _openNotification(_FeedNotification notification) async {
    if (notification.kind == 'friend_request_received') {
      await _openFriendRequestNotification(notification);
      return;
    }
    if (notification.kind == 'drink_invite_received') {
      await _openDrinkInviteNotification(notification);
    }
  }

  Future<void> _openFriendRequestNotification(
    _FeedNotification notification,
  ) async {
    final friendRequestId = notification.friendRequestId;
    if (friendRequestId == null || friendRequestId.isEmpty) {
      NomoToast.show(context, 'この申請を開けませんでした。もう一度お試しください。');
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: .62),
      builder: (sheetContext) => _FriendRequestNotificationSheet(
        notification: notification,
        onAccept: () async {
          await ref
              .read(notificationControllerProvider.notifier)
              .acceptFriendRequest(friendRequestId);
          ref.invalidate(friendsProvider);
          ref.invalidate(drinkLogControllerProvider);
        },
        onReject: () async {
          await ref
              .read(notificationControllerProvider.notifier)
              .rejectFriendRequest(friendRequestId);
          ref.invalidate(notificationControllerProvider);
        },
      ),
    );
  }

  Future<void> _openDrinkInviteNotification(
    _FeedNotification notification,
  ) async {
    final drinkInviteId = notification.drinkInviteId;
    if (drinkInviteId == null || drinkInviteId.isEmpty) {
      NomoToast.show(context, 'この飲み予定を開けなかったよ。あとでもう一度試してね。');
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: .62),
      builder: (sheetContext) => _DrinkInviteNotificationSheet(
        notification: notification,
        onAccept: () async {
          await ref
              .read(notificationControllerProvider.notifier)
              .acceptDrinkInvite(drinkInviteId);
          ref.invalidate(todayReservationsProvider);
          ref.invalidate(incomingDrinkInvitesProvider);
        },
        onReject: () async {
          await ref
              .read(notificationControllerProvider.notifier)
              .rejectDrinkInvite(drinkInviteId);
          ref.invalidate(incomingDrinkInvitesProvider);
        },
      ),
    );
  }
}

class _NotificationSectionHeader extends StatelessWidget {
  const _NotificationSectionHeader({
    required this.title,
    required this.message,
    required this.count,
    required this.accent,
    required this.isWhite,
  });

  final String title;
  final String message;
  final int count;
  final Color accent;
  final bool isWhite;

  @override
  Widget build(BuildContext context) {
    final titleColor = isWhite ? const Color(0xFF27313B) : Colors.white;
    final messageColor = isWhite
        ? const Color(0xFF778393)
        : Colors.white.withValues(alpha: .58);
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 8, 2, 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: titleColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -.35,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: isWhite ? .14 : .20),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '$count',
                        style: TextStyle(
                          color: accent,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  message,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: messageColor,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationSectionEmptyNote extends StatelessWidget {
  const _NotificationSectionEmptyNote({required this.isWhite});

  final bool isWhite;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: isWhite
          ? const Color(0xFFF3F7FA)
          : Colors.white.withValues(alpha: .045),
      borderRadius: BorderRadius.circular(22),
      border: Border.all(
        color: isWhite
            ? const Color(0xFFE1E8F1)
            : Colors.white.withValues(alpha: .08),
      ),
    ),
    child: Text(
      '対応が必要なお知らせはありません。招待や申請が届いたら上に表示されます。',
      style: TextStyle(
        color: isWhite
            ? const Color(0xFF617281)
            : Colors.white.withValues(alpha: .62),
        fontSize: 12,
        fontWeight: FontWeight.w800,
        height: 1.35,
      ),
    ),
  );
}

class _NotificationEmptyState extends StatelessWidget {
  const _NotificationEmptyState({required this.isWhite});

  final bool isWhite;

  @override
  Widget build(BuildContext context) => _FeedEmptyState(
    icon: CupertinoIcons.bell,
    isWhite: isWhite,
    title: 'まだお知らせはありません',
    message: 'フレンズを追加したり飲みログを残すと、反応や招待がここに届きます。',
    action: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'まずはフレンズ追加か飲みログ作成から始めよう',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isWhite
                ? const Color(0xFF778393)
                : Colors.white.withValues(alpha: .56),
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    ),
  );
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({
    required this.notification,
    required this.isWhite,
    this.priority = false,
    this.onTap,
  });

  final _FeedNotification notification;
  final bool isWhite;
  final bool priority;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final resolved = notification.isResolvedAction;
    final cardColor = priority
        ? (isWhite ? const Color(0xFFFFF5F1) : const Color(0xFF2A1716))
        : isWhite
        ? (notification.unread
              ? const Color(0xFFEBF5F5)
              : const Color(0xFFEEF3FA))
        : notification.unread
        ? _FeedColors.card.withValues(alpha: .86)
        : _FeedColors.card.withValues(alpha: .52);
    final cardBorderColor = priority
        ? notification.accent.withValues(alpha: isWhite ? .36 : .30)
        : isWhite
        ? const Color(0xFFE1E8F1)
        : Colors.white.withValues(alpha: .11);
    final messageColor = isWhite
        ? const Color(0xFF617281)
        : Colors.white.withValues(alpha: .64);
    final titleColor = isWhite ? const Color(0xFF27313B) : Colors.white;
    final timeColor = isWhite ? const Color(0xFF8B96A3) : _FeedColors.sub;

    final tile = Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: _feedCardDecoration(radius: 22).copyWith(
        color: cardColor,
        border: Border.all(color: cardBorderColor, width: priority ? 1.5 : 1.2),
        boxShadow: priority
            ? [
                BoxShadow(
                  color: notification.accent.withValues(
                    alpha: isWhite ? .14 : .20,
                  ),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
              ]
            : null,
      ),
      child: Opacity(
        opacity: resolved ? .62 : 1,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            NomoPopIcon(
              icon: notification.icon,
              color: notification.accent,
              size: 38,
              iconSize: 21,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: titleColor,
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      if (notification.unread)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: _FeedColors.teal,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    notification.message,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: messageColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        notification.timeAgo,
                        style: TextStyle(
                          color: timeColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      if (notification.actionLabel != null) ...[
                        const SizedBox(width: 10),
                        Expanded(
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: notification.accent.withValues(
                                  alpha: isWhite ? .14 : .18,
                                ),
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(
                                  color: notification.accent.withValues(
                                    alpha: isWhite ? .24 : .30,
                                  ),
                                ),
                              ),
                              child: Text(
                                notification.actionLabel!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: notification.accent,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    if (onTap == null) return tile;
    return Semantics(
      button: true,
      label: '${notification.title}を開く',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          HapticFeedback.selectionClick();
          onTap!();
        },
        child: tile,
      ),
    );
  }
}

class _FriendRequestNotificationSheet extends StatefulWidget {
  const _FriendRequestNotificationSheet({
    required this.notification,
    required this.onAccept,
    required this.onReject,
  });

  final _FeedNotification notification;
  final Future<void> Function() onAccept;
  final Future<void> Function() onReject;

  @override
  State<_FriendRequestNotificationSheet> createState() =>
      _FriendRequestNotificationSheetState();
}

class _FriendRequestNotificationSheetState
    extends State<_FriendRequestNotificationSheet> {
  String? _busyAction;

  bool get _isPending =>
      widget.notification.friendRequestStatus == null ||
      widget.notification.friendRequestStatus == 'pending';

  Future<void> _submit({required bool accept}) async {
    if (_busyAction != null || !_isPending) return;
    final action = accept ? 'accept' : 'reject';
    setState(() => _busyAction = action);
    try {
      if (accept) {
        await widget.onAccept();
      } else {
        await widget.onReject();
      }
      if (!mounted) return;
      NomoToast.show(context, accept ? 'フレンズ申請を承認しました' : '申請を見送りました');
      Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) return;
      NomoToast.show(
        context,
        accept ? '承認できなかったよ。あとでもう一度試してね。' : '見送りできなかったよ。あとでもう一度試してね。',
      );
      setState(() => _busyAction = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusLabel = switch (widget.notification.friendRequestStatus) {
      'accepted' => '承認済み',
      'rejected' => '見送り済み',
      'cancelled' => '取り消し済み',
      _ => '承認待ち',
    };

    return SafeArea(
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
        decoration: BoxDecoration(
          color: const Color(0xFF071622),
          borderRadius: BorderRadius.circular(34),
          border: Border.all(color: Colors.white.withValues(alpha: .10)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: .32),
              blurRadius: 30,
              offset: const Offset(0, 18),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .22),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                NomoPopIcon(
                  icon: CupertinoIcons.person_badge_plus_fill,
                  color: const Color(0xFF58D6FF),
                  size: 54,
                  iconSize: 29,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.notification.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 19,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -.4,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF58D6FF).withValues(alpha: .14),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: const Color(
                              0xFF58D6FF,
                            ).withValues(alpha: .26),
                          ),
                        ),
                        child: Text(
                          statusLabel,
                          style: const TextStyle(
                            color: Color(0xFF58D6FF),
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                CupertinoButton(
                  minimumSize: const Size(42, 42),
                  padding: EdgeInsets.zero,
                  onPressed: () => Navigator.of(context).pop(),
                  child: Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: .08),
                      shape: BoxShape.circle,
                    ),
                    child: const NomoGeneratedIcon(
                      CupertinoIcons.xmark,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .045),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: Colors.white.withValues(alpha: .08)),
              ),
              child: Text(
                _isPending
                    ? widget.notification.message
                    : widget.notification.message,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: .78),
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  height: 1.45,
                ),
              ),
            ),
            const SizedBox(height: 18),
            if (_isPending) ...[
              Nomo3DButton(
                label: '承認してフレンズになる',
                icon: CupertinoIcons.checkmark_seal_fill,
                onTap: () => _submit(accept: true),
                isLoading: _busyAction == 'accept',
                enabled: _busyAction == null,
                height: 54,
                radius: 22,
                color: AppColors.success,
                shadowColor: AppColors.successShadow,
                fontSize: 15,
              ),
              const SizedBox(height: 10),
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: _busyAction == null
                    ? () => _submit(accept: false)
                    : null,
                child: Text(
                  _busyAction == 'reject' ? '見送り中...' : '今回は見送る',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: .60),
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ] else
              Nomo3DButton(
                label: '閉じる',
                icon: CupertinoIcons.checkmark_circle_fill,
                onTap: () => Navigator.of(context).pop(),
                height: 52,
                radius: 22,
                color: AppColors.invite,
                shadowColor: AppColors.inviteShadow,
                fontSize: 15,
              ),
          ],
        ),
      ),
    );
  }
}

class _DrinkInviteNotificationSheet extends StatefulWidget {
  const _DrinkInviteNotificationSheet({
    required this.notification,
    required this.onAccept,
    required this.onReject,
  });

  final _FeedNotification notification;
  final Future<void> Function() onAccept;
  final Future<void> Function() onReject;

  @override
  State<_DrinkInviteNotificationSheet> createState() =>
      _DrinkInviteNotificationSheetState();
}

class _DrinkInviteNotificationSheetState
    extends State<_DrinkInviteNotificationSheet> {
  String? _busyAction;

  bool get _isPending =>
      widget.notification.drinkInviteStatus == null ||
      widget.notification.drinkInviteStatus == 'pending';

  Future<void> _submit({required bool accept}) async {
    if (_busyAction != null || !_isPending) return;
    final action = accept ? 'accept' : 'reject';
    setState(() => _busyAction = action);
    try {
      if (accept) {
        await widget.onAccept();
      } else {
        await widget.onReject();
      }
      if (!mounted) return;
      NomoToast.show(context, accept ? '飲み予定を受け取りました' : '飲み予定を見送りました');
      Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) return;
      NomoToast.show(
        context,
        accept ? '承認できなかったよ。あとでもう一度試してね。' : '見送りできなかったよ。あとでもう一度試してね。',
      );
      setState(() => _busyAction = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusLabel = switch (widget.notification.drinkInviteStatus) {
      'accepted' => '参加予定',
      'rejected' => '見送り済み',
      'cancelled' => '取り消し済み',
      _ => '返信待ち',
    };

    return SafeArea(
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
        decoration: BoxDecoration(
          color: const Color(0xFF071622),
          borderRadius: BorderRadius.circular(34),
          border: Border.all(color: Colors.white.withValues(alpha: .10)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: .32),
              blurRadius: 30,
              offset: const Offset(0, 18),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .22),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                NomoPopIcon(
                  icon: CupertinoIcons.calendar_badge_plus,
                  color: const Color(0xFFC08BFF),
                  size: 54,
                  iconSize: 29,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.notification.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 19,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -.4,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFC08BFF).withValues(alpha: .14),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: const Color(
                              0xFFC08BFF,
                            ).withValues(alpha: .26),
                          ),
                        ),
                        child: Text(
                          statusLabel,
                          style: const TextStyle(
                            color: Color(0xFFC08BFF),
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                CupertinoButton(
                  minimumSize: const Size(42, 42),
                  padding: EdgeInsets.zero,
                  onPressed: () => Navigator.of(context).pop(),
                  child: Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: .08),
                      shape: BoxShape.circle,
                    ),
                    child: const NomoGeneratedIcon(
                      CupertinoIcons.xmark,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .045),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: Colors.white.withValues(alpha: .08)),
              ),
              child: Text(
                _isPending
                    ? widget.notification.message
                    : widget.notification.message,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: .78),
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  height: 1.45,
                ),
              ),
            ),
            const SizedBox(height: 18),
            if (_isPending) ...[
              Nomo3DButton(
                label: '承認して飲みに行く',
                icon: CupertinoIcons.checkmark_circle_fill,
                onTap: () => _submit(accept: true),
                isLoading: _busyAction == 'accept',
                enabled: _busyAction == null,
                height: 54,
                radius: 22,
                color: AppColors.success,
                shadowColor: AppColors.successShadow,
                fontSize: 15,
              ),
              const SizedBox(height: 10),
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: _busyAction == null
                    ? () => _submit(accept: false)
                    : null,
                child: Text(
                  _busyAction == 'reject' ? '見送り中...' : '今回は見送る',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: .60),
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ] else
              Nomo3DButton(
                label: '閉じる',
                icon: CupertinoIcons.checkmark_circle_fill,
                onTap: () => Navigator.of(context).pop(),
                height: 52,
                radius: 22,
                color: AppColors.invite,
                shadowColor: AppColors.inviteShadow,
                fontSize: 15,
              ),
          ],
        ),
      ),
    );
  }
}

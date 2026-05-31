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
      backgroundColor: isWhite ? AppColors.white : AppColors.darkBackground,
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
                                    ? AppColors.cFFF2F4F6
                                    : AppColors.white.withValues(alpha: .06),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isWhite
                                      ? AppColors.cFFD7DEE7
                                      : AppColors.white.withValues(alpha: .09),
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
                                          ? AppColors.cFF27313B
                                          : AppColors.white,
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
                                        ? AppColors.cFF27313B
                                        : AppColors.white,
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
                          accent: AppColors.cFFFF75B5,
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
          message: 'お返事まちだよ',
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
        message: actionItems.isEmpty ? '参加・ゆるぼ・予定が静かにまとまります' : '先にお返事しよっか',
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
    if (notification.kind == 'invite_received') {
      await _openInviteNotification(notification);
    }
  }

  Future<void> _openFriendRequestNotification(
    _FeedNotification notification,
  ) async {
    final friendRequestId = notification.friendRequestId;
    if (friendRequestId == null || friendRequestId.isEmpty) {
      OheyToast.show(context, 'この申請を開けませんでした。もう一度お試しください。');
      return;
    }

    await showOheyBottomSheet<void>(
      context: context,
      useSafeArea: true,
      barrierColor: AppColors.black.withValues(alpha: .62),
      builder: (sheetContext) => _FriendRequestNotificationSheet(
        notification: notification,
        onAccept: () async {
          await ref
              .read(notificationControllerProvider.notifier)
              .acceptFriendRequest(friendRequestId);
          ref.invalidate(friendsProvider);
          ref.invalidate(memoryControllerProvider);
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

  Future<void> _openInviteNotification(_FeedNotification notification) async {
    final inviteId = notification.inviteId;
    if (inviteId == null || inviteId.isEmpty) {
      OheyToast.show(context, 'この予定を開けなかったよ。あとでもう一度試してね。');
      return;
    }

    await showOheyBottomSheet<void>(
      context: context,
      useSafeArea: true,
      barrierColor: AppColors.black.withValues(alpha: .62),
      builder: (sheetContext) => _InviteNotificationSheet(
        notification: notification,
        onAccept: () async {
          await ref
              .read(notificationControllerProvider.notifier)
              .acceptInvite(inviteId);
          ref.invalidate(todayReservationsProvider);
          ref.invalidate(incomingInvitesProvider);
        },
        onReject: () async {
          await ref
              .read(notificationControllerProvider.notifier)
              .rejectInvite(inviteId);
          ref.invalidate(incomingInvitesProvider);
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
    final titleColor = isWhite ? AppColors.cFF27313B : AppColors.white;
    final messageColor = isWhite
        ? AppColors.cFF778393
        : AppColors.white.withValues(alpha: .58);
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
          ? AppColors.cFFF3F7FA
          : AppColors.white.withValues(alpha: .045),
      borderRadius: BorderRadius.circular(22),
      border: Border.all(
        color: isWhite
            ? AppColors.cFFE1E8F1
            : AppColors.white.withValues(alpha: .08),
      ),
    ),
    child: Text(
      '今はお返事まち、ないよ。',
      style: TextStyle(
        color: isWhite
            ? AppColors.cFF617281
            : AppColors.white.withValues(alpha: .62),
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
    title: 'まだ何も来てないよ',
    message: 'ここはOheyの連絡ポスト。いいね・お誘い・フレンズ申請が届いたら、キャラがそっと教えるね。',
    hints: const ['お誘い', 'いいね', 'フレンズ申請'],
    action: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'まずはゆるぼするか、フレンズを追加してみよう',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isWhite
                ? AppColors.cFF778393
                : AppColors.white.withValues(alpha: .56),
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
        ? (isWhite ? AppColors.cFFFFF5F1 : AppColors.cFF2A1716)
        : isWhite
        ? (notification.unread ? AppColors.cFFEBF5F5 : AppColors.cFFEEF3FA)
        : notification.unread
        ? _FeedColors.card.withValues(alpha: .86)
        : _FeedColors.card.withValues(alpha: .52);
    final cardBorderColor = priority
        ? notification.accent.withValues(alpha: isWhite ? .36 : .30)
        : isWhite
        ? AppColors.cFFE1E8F1
        : AppColors.white.withValues(alpha: .11);
    final messageColor = isWhite
        ? AppColors.cFF617281
        : AppColors.white.withValues(alpha: .64);
    final titleColor = isWhite ? AppColors.cFF27313B : AppColors.white;
    final timeColor = isWhite ? AppColors.cFF8B96A3 : _FeedColors.sub;

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
            OheyPopIcon(
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

  bool get _isPending => oheyFriendRequestStatusFromKey(
    widget.notification.friendRequestStatus,
  ).isPending;

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
      OheyToast.show(context, accept ? 'フレンズ申請を承認しました' : '申請を見送りました');
      Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) return;
      OheyToast.show(
        context,
        accept ? '承認できなかったよ。あとでもう一度試してね。' : '見送りできなかったよ。あとでもう一度試してね。',
      );
      setState(() => _busyAction = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusLabel = oheyFriendRequestStatusFromKey(
      widget.notification.friendRequestStatus,
    ).label;

    return SafeArea(
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
        decoration: BoxDecoration(
          color: AppColors.cFF071622,
          borderRadius: BorderRadius.circular(34),
          border: Border.all(color: AppColors.white.withValues(alpha: .10)),
          boxShadow: [
            BoxShadow(
              color: AppColors.black.withValues(alpha: .32),
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
                  color: AppColors.white.withValues(alpha: .22),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                OheyPopIcon(
                  icon: CupertinoIcons.person_badge_plus_fill,
                  color: AppColors.cFF58D6FF,
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
                          color: AppColors.white,
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
                          color: AppColors.cFF58D6FF.withValues(alpha: .14),
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
                            color: AppColors.cFF58D6FF,
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                OheyCloseButton(
                  onTap: () => Navigator.of(context).pop(),
                  iconColor: AppColors.white,
                  backgroundColor: AppColors.white.withValues(alpha: .08),
                  borderColor: AppColors.white.withValues(alpha: .10),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.white.withValues(alpha: .045),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: AppColors.white.withValues(alpha: .08),
                ),
              ),
              child: Text(
                _isPending
                    ? widget.notification.message
                    : widget.notification.message,
                style: TextStyle(
                  color: AppColors.white.withValues(alpha: .78),
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  height: 1.45,
                ),
              ),
            ),
            const SizedBox(height: 18),
            if (_isPending) ...[
              Ohey3DButton(
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
              Ohey3DButton.secondary(
                label: _busyAction == 'reject' ? '見送り中...' : '今回は見送る',
                icon: CupertinoIcons.xmark_circle_fill,
                onTap: _busyAction == null
                    ? () => _submit(accept: false)
                    : null,
                isLoading: _busyAction == 'reject',
                enabled: _busyAction == null,
                height: 48,
                radius: 21,
                color: AppColors.white.withValues(alpha: .07),
                foregroundColor: AppColors.white.withValues(alpha: .72),
                shadowColor: AppColors.cFF2D5E69.withValues(alpha: .72),
                fontSize: 14,
                useGradient: false,
              ),
            ] else
              Ohey3DButton(
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

class _InviteNotificationSheet extends StatefulWidget {
  const _InviteNotificationSheet({
    required this.notification,
    required this.onAccept,
    required this.onReject,
  });

  final _FeedNotification notification;
  final Future<void> Function() onAccept;
  final Future<void> Function() onReject;

  @override
  State<_InviteNotificationSheet> createState() =>
      _InviteNotificationSheetState();
}

class _InviteNotificationSheetState extends State<_InviteNotificationSheet> {
  String? _busyAction;

  bool get _isPending =>
      oheyInviteStatusFromKey(widget.notification.inviteStatus).isPending;

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
      OheyToast.show(context, accept ? '予定を受け取りました' : 'お誘いを見送りました');
      Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) return;
      OheyToast.show(
        context,
        accept ? '承認できなかったよ。あとでもう一度試してね。' : '見送りできなかったよ。あとでもう一度試してね。',
      );
      setState(() => _busyAction = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusLabel = oheyInviteStatusFromKey(
      widget.notification.inviteStatus,
    ).label;

    return SafeArea(
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
        decoration: BoxDecoration(
          color: AppColors.cFF071622,
          borderRadius: BorderRadius.circular(34),
          border: Border.all(color: AppColors.white.withValues(alpha: .10)),
          boxShadow: [
            BoxShadow(
              color: AppColors.black.withValues(alpha: .32),
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
                  color: AppColors.white.withValues(alpha: .22),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                OheyPopIcon(
                  icon: CupertinoIcons.calendar_badge_plus,
                  color: AppColors.cFFC08BFF,
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
                          color: AppColors.white,
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
                          color: AppColors.cFFC08BFF.withValues(alpha: .14),
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
                            color: AppColors.cFFC08BFF,
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                OheyCloseButton(
                  onTap: () => Navigator.of(context).pop(),
                  iconColor: AppColors.white,
                  backgroundColor: AppColors.white.withValues(alpha: .08),
                  borderColor: AppColors.white.withValues(alpha: .10),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.white.withValues(alpha: .045),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: AppColors.white.withValues(alpha: .08),
                ),
              ),
              child: Text(
                _isPending
                    ? widget.notification.message
                    : widget.notification.message,
                style: TextStyle(
                  color: AppColors.white.withValues(alpha: .78),
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  height: 1.45,
                ),
              ),
            ),
            const SizedBox(height: 18),
            if (_isPending) ...[
              Ohey3DButton(
                label: '承認して遊びに行く',
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
              Ohey3DButton.secondary(
                label: _busyAction == 'reject' ? '見送り中...' : '今回は見送る',
                icon: CupertinoIcons.xmark_circle_fill,
                onTap: _busyAction == null
                    ? () => _submit(accept: false)
                    : null,
                isLoading: _busyAction == 'reject',
                enabled: _busyAction == null,
                height: 48,
                radius: 21,
                color: AppColors.white.withValues(alpha: .07),
                foregroundColor: AppColors.white.withValues(alpha: .72),
                shadowColor: AppColors.cFF573D7A.withValues(alpha: .72),
                fontSize: 14,
                useGradient: false,
              ),
            ] else
              Ohey3DButton(
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

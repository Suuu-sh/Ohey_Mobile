part of 'friends_screen.dart';

enum _FriendProfileAction { remove, mute, block, report }

enum _FriendProfileReportReason {
  spam(OheyReportReasonKeys.spam, 'スパム・宣伝', '宣伝、詐欺、迷惑な勧誘'),
  harassment(OheyReportReasonKeys.harassment, '不快・いやがらせ', '攻撃的、差別的、嫌がらせに感じる内容'),
  inappropriate(OheyReportReasonKeys.inappropriate, '不適切な内容', '性的・過度に不快な表現'),
  violence(OheyReportReasonKeys.violence, '暴力・危険行為', '暴力、危険行為、自傷を助長する内容'),
  minorSafety(OheyReportReasonKeys.minorSafety, '未成年・危険', '未成年の安全に関わる懸念'),
  other(OheyReportReasonKeys.other, 'その他', '上記に当てはまらない問題');

  const _FriendProfileReportReason(this.value, this.label, this.description);

  final String value;
  final String label;
  final String description;
}

class _FriendCard extends StatelessWidget {
  const _FriendCard({
    required this.friend,
    required this.status,
    required this.onFavoriteToggle,
    required this.isInvited,
    required this.onInvite,
    required this.onInviteAnimationComplete,
    required this.onProfile,
  });

  final OheyFriend friend;
  final _FriendStatus status;
  final VoidCallback onFavoriteToggle;
  final bool isInvited;
  final Future<void> Function() onInvite;
  final VoidCallback onInviteAnimationComplete;
  final VoidCallback onProfile;

  @override
  Widget build(BuildContext context) => OheyFriendUserBlock(
    friend: friend,
    statusLabel: status.label,
    statusReason: status.reason,
    statusColor: _friendInviteButtonColor(status),
    statusEnabled: status.enabled,
    inviteSent: isInvited,
    fallbackAvatar: _fallbackAvatarForFriend(friend),
    showFavorite: true,
    showInvite: true,
    onFavoriteToggle: onFavoriteToggle,
    onInvite: onInvite,
    onInviteAnimationComplete: onInviteAnimationComplete,
    onTap: onProfile,
  );
}

Future<void> showOheyFriendProfileSheet(
  BuildContext context, {
  required OheyFriend friend,
  bool showActionMenu = true,
}) {
  return _showFriendProfileSheet(
    context,
    friend: friend,
    status: _statusForFriend(friend, 0),
    showActionMenu: showActionMenu,
  );
}

Future<void> _showFriendProfileSheet(
  BuildContext context, {
  required OheyFriend friend,
  required _FriendStatus status,
  bool showActionMenu = true,
}) {
  return showOheyBottomSheet<void>(
    context: context,
    useSafeArea: false,
    barrierColor: AppColors.black.withValues(alpha: .58),
    builder: (_) => _FriendProfileSheet(
      friend: friend,
      status: status,
      showActionMenu: showActionMenu,
    ),
  );
}

Future<bool?> _showFriendProfileConfirmSheet(
  BuildContext context, {
  required IconData icon,
  required Color color,
  required String title,
  required String message,
  required String actionLabel,
}) {
  return showOheyBottomSheet<bool>(
    context: context,
    useSafeArea: true,
    isScrollControlled: true,
    barrierColor: AppColors.black.withValues(alpha: .58),
    builder: (context) => _FriendProfileConfirmSheet(
      icon: icon,
      color: color,
      title: title,
      message: message,
      actionLabel: actionLabel,
    ),
  );
}

class _FriendProfileConfirmSheet extends StatelessWidget {
  const _FriendProfileConfirmSheet({
    required this.icon,
    required this.color,
    required this.title,
    required this.message,
    required this.actionLabel,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String message;
  final String actionLabel;

  @override
  Widget build(BuildContext context) {
    final isWhite = Theme.of(context).brightness == Brightness.light;
    final titleColor = isWhite ? AppColors.cFF101820 : AppColors.white;
    final subtitleColor = isWhite
        ? AppColors.cFF697684
        : AppColors.white.withValues(alpha: .58);
    return OheyBottomSheetShell(
      showBottomCloseButton: false,
      showHandle: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: OheyPopIcon(
              icon: icon,
              color: color,
              size: 64,
              iconSize: 34,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: titleColor,
              fontSize: 22,
              fontWeight: FontWeight.w900,
              letterSpacing: -.7,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: subtitleColor,
              fontSize: 13,
              fontWeight: FontWeight.w800,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _FriendProfileConfirmButton(
                  label: 'やめる',
                  onTap: () => Navigator.of(context).pop(false),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _FriendProfileConfirmButton(
                  label: actionLabel,
                  color: color,
                  onTap: () => Navigator.of(context).pop(true),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FriendProfileConfirmButton extends StatelessWidget {
  const _FriendProfileConfirmButton({
    required this.label,
    required this.onTap,
    this.color = AppColors.cFFC08BFF,
  });

  final String label;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        height: 56,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.darkBackgroundBottom,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.cFF2B3441),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 16,
            fontWeight: FontWeight.w900,
            letterSpacing: -.35,
          ),
        ),
      ),
    );
  }
}

class _FriendProfileSheet extends ConsumerStatefulWidget {
  const _FriendProfileSheet({
    required this.friend,
    required this.status,
    required this.showActionMenu,
  });

  final OheyFriend friend;
  final _FriendStatus status;
  final bool showActionMenu;

  @override
  ConsumerState<_FriendProfileSheet> createState() =>
      _FriendProfileSheetState();
}

class _FriendProfileSheetState extends ConsumerState<_FriendProfileSheet> {
  late _FriendStatus _selectedStatus = widget.status;
  _FriendProfileAction? _busyAction;

  void _handleSelectedStatusChanged(OheyDailyStatus status) {
    final nextStatus = _friendStatusForDailyStatus(status);
    if (_selectedStatus.label == nextStatus.label &&
        _selectedStatus.reason == nextStatus.reason &&
        _selectedStatus.enabled == nextStatus.enabled &&
        _selectedStatus.buttonColor == nextStatus.buttonColor) {
      return;
    }
    setState(() => _selectedStatus = nextStatus);
  }

  Future<void> _confirmRemoveFriend() async {
    if (_busyAction != null) return;
    final confirmed = await _showFriendProfileConfirmSheet(
      context,
      icon: CupertinoIcons.person_badge_minus_fill,
      color: AppColors.cFFFF5F8F,
      title: 'フレンズ解除しますか？',
      message: '${widget.friend.name}さんとのフレンズ関係を解除します。あとでまた申請できます。',
      actionLabel: '解除する',
    );
    if (confirmed != true || !mounted) return;
    setState(() => _busyAction = _FriendProfileAction.remove);
    try {
      final toastContext = Navigator.of(context, rootNavigator: true).context;
      await ref.read(friendRepositoryProvider).deleteFriend(widget.friend.id);
      ref.invalidate(friendsProvider);
      if (!mounted || !toastContext.mounted) return;
      Navigator.of(context).pop();
      OheyToast.show(
        toastContext,
        'フレンズを解除しました',
        icon: CupertinoIcons.person_badge_minus_fill,
      );
    } catch (_) {
      if (!mounted) return;
      OheyToast.show(
        context,
        '解除できませんでした。あとでもう一度試してね',
        icon: CupertinoIcons.exclamationmark_triangle_fill,
      );
    } finally {
      if (mounted) setState(() => _busyAction = null);
    }
  }

  Future<void> _openActionMenu() async {
    if (_busyAction != null) return;
    HapticFeedback.selectionClick();
    final action = await showOheyBottomSheet<_FriendProfileAction>(
      context: context,
      useSafeArea: true,
      barrierColor: AppColors.black.withValues(alpha: .58),
      builder: (_) => _FriendProfileActionSheet(friend: widget.friend),
    );
    if (!mounted || action == null) return;
    switch (action) {
      case _FriendProfileAction.remove:
        await _confirmRemoveFriend();
      case _FriendProfileAction.mute:
        await _confirmMuteFriend();
      case _FriendProfileAction.block:
        await _confirmBlockFriend();
      case _FriendProfileAction.report:
        await _reportFriend();
    }
  }

  Future<void> _confirmMuteFriend() async {
    if (_busyAction != null) return;
    final confirmed = await _showFriendProfileConfirmSheet(
      context,
      icon: CupertinoIcons.bell_slash_fill,
      color: AppColors.cFF88B8FF,
      title: 'ミュートしますか？',
      message: '${widget.friend.name}さんのゆるぼを一覧に表示しにくくします。あとで解除できます。',
      actionLabel: 'ミュートする',
    );
    if (confirmed == true && mounted) {
      await _muteFriend();
    }
  }

  Future<void> _muteFriend() async {
    if (_busyAction != null) return;
    setState(() => _busyAction = _FriendProfileAction.mute);
    try {
      final container = ProviderScope.containerOf(context, listen: false);
      final toastContext = Navigator.of(context, rootNavigator: true).context;
      await ref.read(userSafetyRepositoryProvider).muteUser(widget.friend.id);
      ref.invalidate(mutedUsersProvider);
      ref.invalidate(yuruboControllerProvider);
      if (!mounted || !toastContext.mounted) return;
      Navigator.of(context).pop();
      _showFriendSafetyUndoToast(
        toastContext,
        message: '${widget.friend.name}さんをミュートしました',
        onUndo: () async {
          await container
              .read(userSafetyRepositoryProvider)
              .unmuteUser(widget.friend.id);
          container.invalidate(mutedUsersProvider);
          container.invalidate(yuruboControllerProvider);
        },
      );
    } catch (_) {
      if (!mounted) return;
      OheyToast.show(
        context,
        'ミュートできませんでした。あとでもう一度試してね',
        icon: CupertinoIcons.exclamationmark_triangle_fill,
      );
    } finally {
      if (mounted) setState(() => _busyAction = null);
    }
  }

  Future<void> _confirmBlockFriend() async {
    if (_busyAction != null) return;
    final confirmed = await _showFriendProfileConfirmSheet(
      context,
      icon: CupertinoIcons.hand_raised_fill,
      color: AppColors.cFFFF5F8F,
      title: 'ブロックしますか？',
      message: '${widget.friend.name}さんとのフレンズ関係を解除し、ゆるぼ・申請・お誘いを制限します。',
      actionLabel: 'ブロックする',
    );
    if (confirmed == true && mounted) {
      await _blockFriend();
    }
  }

  Future<void> _blockFriend() async {
    if (_busyAction != null) return;
    setState(() => _busyAction = _FriendProfileAction.block);
    try {
      final container = ProviderScope.containerOf(context, listen: false);
      final toastContext = Navigator.of(context, rootNavigator: true).context;
      await ref.read(userSafetyRepositoryProvider).blockUser(widget.friend.id);
      ref.invalidate(blockedUsersProvider);
      ref.invalidate(friendsProvider);
      ref.invalidate(yuruboControllerProvider);
      if (!mounted || !toastContext.mounted) return;
      Navigator.of(context).pop();
      _showFriendSafetyUndoToast(
        toastContext,
        message: '${widget.friend.name}さんをブロックしました',
        onUndo: () async {
          await container
              .read(userSafetyRepositoryProvider)
              .unblockUser(widget.friend.id);
          await container
              .read(friendRepositoryProvider)
              .addFriend(widget.friend.id);
          container.invalidate(blockedUsersProvider);
          container.invalidate(friendsProvider);
          container.invalidate(yuruboControllerProvider);
        },
      );
    } catch (_) {
      if (!mounted) return;
      OheyToast.show(
        context,
        'ブロックできませんでした。あとでもう一度試してね',
        icon: CupertinoIcons.exclamationmark_triangle_fill,
      );
    } finally {
      if (mounted) setState(() => _busyAction = null);
    }
  }

  Future<void> _reportFriend() async {
    if (_busyAction != null) return;
    final reason = await _selectFriendReportReason(context);
    if (!mounted || reason == null) return;
    setState(() => _busyAction = _FriendProfileAction.report);
    try {
      await ref
          .read(userSafetyRepositoryProvider)
          .reportUser(widget.friend.id, reason: reason.value);
      if (!mounted) return;
      OheyToast.show(
        context,
        '「${reason.label}」として通報しました',
        icon: CupertinoIcons.exclamationmark_bubble_fill,
        accentColor: AppColors.cFFFFD166,
      );
    } catch (_) {
      if (!mounted) return;
      OheyToast.show(
        context,
        '通報できませんでした。あとでもう一度試してね',
        icon: CupertinoIcons.exclamationmark_triangle_fill,
      );
    } finally {
      if (mounted) setState(() => _busyAction = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final avatar =
        widget.friend.avatar ?? _fallbackAvatarForFriend(widget.friend);
    final statusColor = _friendInviteButtonColor(_selectedStatus);
    final handle = widget.friend.vibe.trim().isEmpty
        ? widget.friend.id
        : '@${widget.friend.vibe}';

    return OheyUserProfileSheet(
      avatar: avatar,
      label: '${widget.friend.name} ・ $handle',
      headerAction: widget.showActionMenu && _busyAction == null
          ? _FriendProfileActionIconButton(onTap: _openActionMenu)
          : null,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _FriendProfileStatusPanel(
            status: _selectedStatus,
            statusColor: statusColor,
          ),
          const SizedBox(height: 14),
          _FriendProfileWishItemsPanel(friend: widget.friend),
          const SizedBox(height: 14),
          Expanded(
            child: _FriendProfileCalendar(
              friend: widget.friend,
              status: widget.status,
              onSelectedStatusChanged: _handleSelectedStatusChanged,
            ),
          ),
        ],
      ),
    );
  }
}

void _showFriendSafetyUndoToast(
  BuildContext context, {
  required String message,
  required Future<void> Function() onUndo,
}) {
  OheyToast.show(
    context,
    message,
    icon: CupertinoIcons.checkmark_circle_fill,
    duration: const Duration(milliseconds: 5200),
    actionLabel: '元に戻す',
    onAction: () async {
      try {
        await onUndo();
        if (context.mounted) {
          OheyToast.show(
            context,
            '元に戻しました',
            icon: CupertinoIcons.arrow_uturn_left_circle_fill,
          );
        }
      } catch (_) {
        if (context.mounted) {
          OheyToast.show(
            context,
            '元に戻せませんでした。あとでもう一度試してね',
            icon: CupertinoIcons.exclamationmark_triangle_fill,
          );
        }
      }
    },
  );
}

class _FriendProfileActionSheet extends StatelessWidget {
  const _FriendProfileActionSheet({required this.friend});

  final OheyFriend friend;

  @override
  Widget build(BuildContext context) {
    final isWhite = Theme.of(context).brightness == Brightness.light;
    final sub = isWhite
        ? AppColors.cFF697684
        : AppColors.white.withValues(alpha: .58);

    return OheyBottomSheetShell(
      showBottomCloseButton: false,
      title: 'フレンズ管理',
      margin: const EdgeInsets.fromLTRB(14, 0, 14, 14),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
      radius: 30,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '${friend.name}さんへの操作を選んでください。',
            style: TextStyle(
              color: sub,
              fontSize: 13,
              fontWeight: FontWeight.w800,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 16),
          OheyActionTile(
            icon: CupertinoIcons.person_badge_minus,
            title: 'フレンズ解除',
            subtitle: '関係を解除して、あとで再申請できます',
            accent: AppColors.cFFFF8AA8,
            destructive: true,
            onTap: () => Navigator.of(context).pop(_FriendProfileAction.remove),
          ),
          const SizedBox(height: 10),
          OheyActionTile(
            icon: CupertinoIcons.bell_slash_fill,
            title: 'ミュート',
            subtitle: 'ゆるぼ一覧に出しません',
            accent: AppColors.cFF88B8FF,
            onTap: () => Navigator.of(context).pop(_FriendProfileAction.mute),
          ),
          const SizedBox(height: 10),
          OheyActionTile(
            icon: CupertinoIcons.hand_raised_fill,
            title: 'ブロック',
            subtitle: 'ゆるぼ・申請・お誘いを制限します',
            accent: AppColors.cFFFF5F8F,
            destructive: true,
            onTap: () => Navigator.of(context).pop(_FriendProfileAction.block),
          ),
          const SizedBox(height: 10),
          OheyActionTile(
            icon: CupertinoIcons.exclamationmark_bubble_fill,
            title: '通報',
            subtitle: '理由を選んで運営に送信します',
            accent: AppColors.cFFFFD166,
            onTap: () => Navigator.of(context).pop(_FriendProfileAction.report),
          ),
          const SizedBox(height: 12),
          _FriendProfileCancelButton(
            isWhite: isWhite,
            onTap: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}

class _FriendProfileCancelButton extends StatelessWidget {
  const _FriendProfileCancelButton({
    required this.isWhite,
    required this.onTap,
  });

  final bool isWhite;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final background = isWhite
        ? AppColors.cFFF2F6FA
        : AppColors.white.withValues(alpha: .06);
    final foreground = isWhite
        ? AppColors.cFF101820
        : AppColors.white.withValues(alpha: .82);
    return CupertinoButton(
      onPressed: onTap,
      minimumSize: Size.zero,
      padding: EdgeInsets.zero,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        height: 48,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.white.withValues(alpha: .18)),
        ),
        child: Text(
          'キャンセル',
          style: TextStyle(
            color: foreground,
            fontSize: 16,
            fontWeight: FontWeight.w900,
            letterSpacing: -.2,
          ),
        ),
      ),
    );
  }
}

Future<_FriendProfileReportReason?> _selectFriendReportReason(
  BuildContext context,
) {
  return showOheyBottomSheet<_FriendProfileReportReason>(
    context: context,
    useSafeArea: true,
    barrierColor: AppColors.black.withValues(alpha: .58),
    builder: (_) => const _FriendReportReasonSheet(),
  );
}

class _FriendReportReasonSheet extends StatelessWidget {
  const _FriendReportReasonSheet();

  @override
  Widget build(BuildContext context) {
    final isWhite = Theme.of(context).brightness == Brightness.light;
    final sub = isWhite
        ? AppColors.cFF697684
        : AppColors.white.withValues(alpha: .58);
    return OheyBottomSheetShell(
      title: '通報理由',
      margin: const EdgeInsets.fromLTRB(14, 0, 14, 14),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
      radius: 30,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '近い理由を選ぶと、運営が確認しやすくなります。',
            style: TextStyle(
              color: sub,
              fontSize: 13,
              fontWeight: FontWeight.w800,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 16),
          for (final reason in _FriendProfileReportReason.values) ...[
            OheyActionTile(
              icon: CupertinoIcons.exclamationmark_triangle_fill,
              title: reason.label,
              subtitle: reason.description,
              accent: AppColors.cFFFFD166,
              onTap: () => Navigator.of(context).pop(reason),
            ),
            if (reason != _FriendProfileReportReason.values.last)
              const SizedBox(height: 9),
          ],
          const SizedBox(height: 12),
          _FriendProfileCancelButton(
            isWhite: isWhite,
            onTap: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}

class _FriendProfileActionIconButton extends StatelessWidget {
  const _FriendProfileActionIconButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '操作メニュー',
      child: CupertinoButton(
        onPressed: onTap,
        minimumSize: const Size(48, 48),
        padding: EdgeInsets.zero,
        borderRadius: BorderRadius.circular(18),
        child: const SizedBox(
          width: 48,
          height: 48,
          child: Center(
            child: OheyGeneratedIcon(
              CupertinoIcons.gear_alt,
              color: AppColors.cFF101820,
              size: 38,
            ),
          ),
        ),
      ),
    );
  }
}

class _FriendProfileWishItemsPanel extends ConsumerWidget {
  const _FriendProfileWishItemsPanel({required this.friend});

  final OheyFriend friend;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wishItemsAsync = ref.watch(profileWishItemsProvider(friend.id));
    return wishItemsAsync.when(
      loading: () => const _FriendProfileWishItemsShell(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: Center(child: CupertinoActivityIndicator()),
        ),
      ),
      error: (_, _) => const SizedBox.shrink(),
      data: (wishItems) {
        if (wishItems.isEmpty) return const SizedBox.shrink();
        return _FriendProfileWishItemsShell(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Icon(
                    CupertinoIcons.sparkles,
                    color: AppColors.cFFC08BFF,
                    size: 18,
                  ),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      '${friend.name}さんのやりたいこと',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 74,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemCount: wishItems.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final wish = wishItems[index];
                    return _FriendProfileWishChip(wish: wish);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _FriendProfileWishItemsShell extends StatelessWidget {
  const _FriendProfileWishItemsShell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return OheyThemedPanel(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      accentColor: AppColors.cFFC08BFF,
      borderRadius: 22,
      backgroundColor: AppColors.cFF231A38.withValues(alpha: .92),
      borderAlpha: .42,
      glowAlpha: .10,
      glowBlur: 18,
      glowOffset: const Offset(0, 8),
      child: child,
    );
  }
}

class _FriendProfileWishChip extends StatelessWidget {
  const _FriendProfileWishChip({required this.wish});

  final WishItem wish;

  @override
  Widget build(BuildContext context) {
    final place = wish.placeText.trim();
    return Container(
      width: 168,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.cFFC08BFF.withValues(alpha: .18),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.cFFC08BFF.withValues(alpha: .34)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            wish.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.white,
              fontSize: 13,
              fontWeight: FontWeight.w900,
              height: 1.12,
            ),
          ),
          const Spacer(),
          Text(
            place.isEmpty ? '公開リスト' : place,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: AppColors.white.withValues(alpha: .56),
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _FriendProfileStatusPanel extends StatelessWidget {
  const _FriendProfileStatusPanel({
    required this.status,
    required this.statusColor,
  });

  final _FriendStatus status;
  final Color statusColor;

  @override
  Widget build(BuildContext context) {
    return OheyThemedPanel(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
      accentColor: statusColor,
      borderRadius: 22,
      backgroundColor: Color.lerp(
        AppColors.darkBackgroundBottom,
        statusColor,
        .34,
      )!.withValues(alpha: .90),
      borderAlpha: .56,
      glowAlpha: .16,
      glowBlur: 22,
      glowOffset: const Offset(0, 8),
      child: Row(
        children: [
          OheyPopIcon(
            icon: CupertinoIcons.cloud_fill,
            color: statusColor,
            size: 38,
            iconSize: 21,
            showBubble: false,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  status.label,
                  style: const TextStyle(
                    color: AppColors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  status.reason,
                  style: TextStyle(
                    color: AppColors.white.withValues(alpha: .70),
                    fontWeight: FontWeight.w800,
                    height: 1.35,
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

class _FriendProfileCalendar extends ConsumerStatefulWidget {
  const _FriendProfileCalendar({
    required this.friend,
    required this.status,
    required this.onSelectedStatusChanged,
  });

  final OheyFriend friend;
  final _FriendStatus status;
  final ValueChanged<OheyDailyStatus> onSelectedStatusChanged;

  @override
  ConsumerState<_FriendProfileCalendar> createState() =>
      _FriendProfileCalendarState();
}

class _FriendProfileCalendarState
    extends ConsumerState<_FriendProfileCalendar> {
  late DateTime _month;
  late DateTime _selectedDay;
  final Map<String, OheyDailyStatus> _statusByDate = {};
  final Set<String> _loadingStatusKeys = {};

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _month = DateTime(now.year, now.month);
    _selectedDay = _friendProfileDateOnly(now);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _loadStatusesForMonth(_month);
    });
  }

  void _moveMonth(int offset) {
    final nextMonth = DateTime(_month.year, _month.month + offset);
    final today = _friendProfileDateOnly(DateTime.now());
    setState(() {
      _month = nextMonth;
      _selectedDay = _friendProfileIsSameMonth(nextMonth, today)
          ? today
          : DateTime(nextMonth.year, nextMonth.month);
    });
    _loadStatusesForMonth(_month);
  }

  Future<void> _loadStatusesForMonth(DateTime month) async {
    final authUserId = ref.read(authIdentityProvider).currentUserId;
    if (authUserId != null && authUserId == widget.friend.id) {
      try {
        final statuses = await ref
            .read(userRepositoryProvider)
            .fetchDailyStatusesForMonth(month);
        if (!mounted) return;
        setState(() => _statusByDate.addAll(statuses));
        final selectedStatus =
            _statusByDate[_friendProfileDateKey(_selectedDay)];
        if (selectedStatus != null) {
          widget.onSelectedStatusChanged(selectedStatus);
        }
      } catch (_) {
        // Keep the existing unselected fallback when own monthly statuses cannot load.
      }
      return;
    }

    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final leadingEmptyCells = DateTime(month.year, month.month).weekday % 7;
    final totalCells = leadingEmptyCells + daysInMonth;
    final rows = (totalCells / 7).ceil();
    final targets = <DateTime>[];
    for (var index = 0; index < rows * 7; index++) {
      final dayNumber = index - leadingEmptyCells + 1;
      final date = DateTime(month.year, month.month, dayNumber);
      final key = _friendProfileDateKey(date);
      if (_statusByDate.containsKey(key) || !_loadingStatusKeys.add(key)) {
        continue;
      }
      targets.add(date);
    }
    if (targets.isEmpty) return;

    final entries = await Future.wait(
      targets.map((date) async {
        try {
          final friends = await ref.read(friendsForDateProvider(date).future);
          final friend = friends
              .where((candidate) => candidate.id == widget.friend.id)
              .firstOrNull;
          return MapEntry(
            _friendProfileDateKey(date),
            oheyDailyStatusFromKey(friend?.statusKey),
          );
        } catch (_) {
          return MapEntry(
            _friendProfileDateKey(date),
            OheyDailyStatus.unselected,
          );
        }
      }),
    );
    for (final date in targets) {
      _loadingStatusKeys.remove(_friendProfileDateKey(date));
    }
    if (!mounted) return;
    setState(() {
      for (final entry in entries) {
        _statusByDate[entry.key] = entry.value;
      }
    });
    final selectedStatus = _statusByDate[_friendProfileDateKey(_selectedDay)];
    if (selectedStatus != null) {
      widget.onSelectedStatusChanged(selectedStatus);
    }
  }

  void _handleMonthSwipe(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    if (velocity.abs() < 220) return;
    _moveMonth(velocity > 0 ? -1 : 1);
  }

  @override
  Widget build(BuildContext context) {
    final isWhite = Theme.of(context).brightness == Brightness.light;
    final ink = isWhite ? AppColors.cFF101820 : AppColors.white;

    return GestureDetector(
      onHorizontalDragEnd: _handleMonthSwipe,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _FriendProfileMonthHeader(
            month: _month,
            ink: ink,
            onMove: _moveMonth,
          ),
          const SizedBox(height: 10),
          Expanded(
            child: _FriendProfileMonthGrid(
              month: _month,
              selectedDay: _selectedDay,
              statusByDate: _statusByDate,
              onSelectDay: (day) {
                HapticFeedback.selectionClick();
                setState(() => _selectedDay = day);
                widget.onSelectedStatusChanged(
                  _statusByDate[_friendProfileDateKey(day)] ??
                      OheyDailyStatus.unselected,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _FriendProfileMonthHeader extends StatelessWidget {
  const _FriendProfileMonthHeader({
    required this.month,
    required this.ink,
    required this.onMove,
  });

  final DateTime month;
  final Color ink;
  final ValueChanged<int> onMove;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _FriendProfileMonthArrowButton(label: '<', onTap: () => onMove(-1)),
        Expanded(
          child: Text(
            '${month.year}/${month.month.toString().padLeft(2, '0')}',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: ink,
              fontWeight: FontWeight.w900,
              fontSize: 20,
              letterSpacing: -.4,
            ),
          ),
        ),
        _FriendProfileMonthArrowButton(label: '>', onTap: () => onMove(1)),
      ],
    );
  }
}

class _FriendProfileMonthArrowButton extends StatelessWidget {
  const _FriendProfileMonthArrowButton({
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.white.withValues(alpha: .12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.white.withValues(alpha: .10)),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: AppColors.white,
            fontSize: 24,
            height: .95,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _FriendProfileMonthGrid extends StatelessWidget {
  const _FriendProfileMonthGrid({
    required this.month,
    required this.selectedDay,
    required this.statusByDate,
    required this.onSelectDay,
  });

  final DateTime month;
  final DateTime selectedDay;
  final Map<String, OheyDailyStatus> statusByDate;
  final ValueChanged<DateTime> onSelectDay;

  @override
  Widget build(BuildContext context) {
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final leadingEmptyCells = DateTime(month.year, month.month).weekday % 7;
    final totalCells = leadingEmptyCells + daysInMonth;
    final rows = (totalCells / 7).ceil();
    final previousMonthDays = DateTime(month.year, month.month, 0).day;

    return Column(
      children: [
        Row(
          children: const ['日', '月', '火', '水', '木', '金', '土']
              .asMap()
              .entries
              .map(
                (entry) => Expanded(
                  child: Center(
                    child: Text(
                      entry.value,
                      style: TextStyle(
                        color: entry.key == 0
                            ? AppColors.cFFFF6FA6
                            : entry.key == 6
                            ? AppColors.cFF46C8FF
                            : AppColors.cFFB7C0CA,
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 7),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              const crossAxisSpacing = 6.0;
              const mainAxisSpacing = 5.0;
              final widthBasedExtent =
                  ((constraints.maxWidth - (crossAxisSpacing * 6)) / 7).clamp(
                    42.0,
                    54.0,
                  );
              final heightBasedExtent = rows <= 1
                  ? widthBasedExtent
                  : ((constraints.maxHeight - (mainAxisSpacing * (rows - 1))) /
                            rows)
                        .clamp(34.0, 54.0);
              final tileExtent = widthBasedExtent < heightBasedExtent
                  ? widthBasedExtent
                  : heightBasedExtent;
              final gridHeight =
                  (tileExtent * rows) + (mainAxisSpacing * (rows - 1));
              return Align(
                alignment: Alignment.topCenter,
                child: SizedBox(
                  height: gridHeight,
                  child: GridView.builder(
                    itemCount: rows * 7,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 7,
                      mainAxisSpacing: mainAxisSpacing,
                      crossAxisSpacing: crossAxisSpacing,
                      mainAxisExtent: tileExtent,
                    ),
                    itemBuilder: (context, index) {
                      final dayNumber = index - leadingEmptyCells + 1;
                      final inMonth =
                          dayNumber >= 1 && dayNumber <= daysInMonth;
                      final displayDay = inMonth
                          ? dayNumber
                          : (dayNumber < 1
                                ? previousMonthDays + dayNumber
                                : dayNumber - daysInMonth);
                      final day = DateTime(month.year, month.month, dayNumber);
                      final dailyStatus =
                          statusByDate[_friendProfileDateKey(day)] ??
                          OheyDailyStatus.unselected;
                      return _FriendProfileDayTile(
                        day: displayDay,
                        inMonth: inMonth,
                        dailyStatus: dailyStatus,
                        isToday:
                            inMonth &&
                            _friendProfileIsSameDate(DateTime.now(), day),
                        isSelected: _friendProfileIsSameDate(selectedDay, day),
                        column: index % 7,
                        tileExtent: tileExtent,
                        onTap: inMonth ? () => onSelectDay(day) : null,
                      );
                    },
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _FriendProfileDayTile extends StatelessWidget {
  const _FriendProfileDayTile({
    required this.day,
    required this.inMonth,
    required this.dailyStatus,
    required this.isToday,
    required this.isSelected,
    required this.column,
    required this.tileExtent,
    this.onTap,
  });

  final int day;
  final bool inMonth;
  final OheyDailyStatus dailyStatus;
  final bool isToday;
  final bool isSelected;
  final int column;
  final double tileExtent;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isWhite = Theme.of(context).brightness == Brightness.light;
    final hasStatus = dailyStatus != OheyDailyStatus.unselected;
    final statusAccent = oheyDailyStatusTileAccent(dailyStatus);
    final dayColor = hasStatus
        ? oheyDailyStatusTileForeground(dailyStatus, isWhite: isWhite)
        : !inMonth
        ? (isWhite
              ? AppColors.black.withValues(alpha: .20)
              : AppColors.white.withValues(alpha: .20))
        : column == 0
        ? AppColors.cFFFF6FA6
        : column == 6
        ? AppColors.cFF46C8FF
        : isWhite
        ? AppColors.cFF101820
        : AppColors.white;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        decoration: BoxDecoration(
          color: hasStatus
              ? oheyDailyStatusTileBackground(
                  dailyStatus,
                  isWhite: isWhite,
                  selected: isSelected,
                )
              : isWhite
              ? (isSelected ? AppColors.cFFEAF8FF : AppColors.white)
              : AppColors.darkBackground,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(
            color: hasStatus
                ? statusAccent.withValues(alpha: isSelected ? .90 : .52)
                : isSelected
                ? AppColors.cFF54D7FF
                : const Color(
                    0xFF20B9FF,
                  ).withValues(alpha: isWhite ? .34 : .24),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: hasStatus
                  ? statusAccent.withValues(alpha: isWhite ? .16 : .24)
                  : AppColors.black.withValues(alpha: isWhite ? .05 : .20),
              blurRadius: hasStatus ? 16 : 12,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Center(
          child: Text(
            '$day',
            style: TextStyle(
              color: isToday && !isWhite ? AppColors.white : dayColor,
              fontSize: tileExtent >= 42 ? 18 : 16,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }
}

String _friendProfileDateKey(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

DateTime _friendProfileDateOnly(DateTime date) =>
    DateTime(date.year, date.month, date.day);

bool _friendProfileIsSameMonth(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month;

bool _friendProfileIsSameDate(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

part of 'friends_screen.dart';

enum _FriendProfileAction { remove, mute, block, report }

enum _FriendProfileReportReason {
  spam('spam', 'スパム・宣伝', '宣伝、詐欺、迷惑な勧誘'),
  harassment('harassment', '不快・いやがらせ', '攻撃的、差別的、嫌がらせに感じる内容'),
  inappropriate('inappropriate', '不適切な内容', '性的・過度に不快な表現'),
  violence('violence', '暴力・危険行為', '暴力、危険行為、自傷を助長する内容'),
  minorSafety('minor_safety', '未成年・危険', '未成年の安全に関わる懸念'),
  other('other', 'その他', '上記に当てはまらない問題');

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
}) {
  return _showFriendProfileSheet(
    context,
    friend: friend,
    status: _statusForFriend(friend, 0),
  );
}

Future<void> _showFriendProfileSheet(
  BuildContext context, {
  required OheyFriend friend,
  required _FriendStatus status,
}) {
  return showOheyBottomSheet<void>(
    context: context,
    useSafeArea: false,
    barrierColor: Colors.black.withValues(alpha: .58),
    builder: (_) => _FriendProfileSheet(friend: friend, status: status),
  );
}

class _FriendProfileSheet extends ConsumerStatefulWidget {
  const _FriendProfileSheet({required this.friend, required this.status});

  final OheyFriend friend;
  final _FriendStatus status;

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
    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (dialogContext) => CupertinoAlertDialog(
        title: const Text('フレンズ解除しますか？'),
        content: Text('${widget.friend.name}さんとのフレンズ関係を解除します。あとでまた申請できます。'),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('キャンセル'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('解除する'),
          ),
        ],
      ),
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
      barrierColor: Colors.black.withValues(alpha: .58),
      builder: (_) => _FriendProfileActionSheet(friend: widget.friend),
    );
    if (!mounted || action == null) return;
    switch (action) {
      case _FriendProfileAction.remove:
        await _confirmRemoveFriend();
      case _FriendProfileAction.mute:
        await _muteFriend();
      case _FriendProfileAction.block:
        await _confirmBlockFriend();
      case _FriendProfileAction.report:
        await _reportFriend();
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
      ref.invalidate(homeFeedControllerProvider);
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
          container.invalidate(homeFeedControllerProvider);
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
    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (dialogContext) => CupertinoAlertDialog(
        title: const Text('ブロックしますか？'),
        content: Text('${widget.friend.name}さんとのフレンズ関係を解除し、ゆるぼ・申請・お誘いを制限します。'),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('キャンセル'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('ブロックする'),
          ),
        ],
      ),
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
      ref.invalidate(homeFeedControllerProvider);
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
          container.invalidate(homeFeedControllerProvider);
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
        accentColor: const Color(0xFFFFD166),
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
    final media = MediaQuery.of(context);
    final sheetContentHeight = media.size.height - media.padding.bottom;
    const bodyBackground = AppColors.darkBackgroundBottom;

    return OheyBottomSheetShell(
      padding: EdgeInsets.zero,
      radius: 0,
      maxHeightFactor: 1,
      followKeyboard: false,
      child: SizedBox(
        height: sheetContentHeight,
        child: ColoredBox(
          color: bodyBackground,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _FriendProfileTopBackdrop(
                friend: widget.friend,
                avatar: avatar,
                onActionMenu: _busyAction == null ? _openActionMenu : null,
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
                  child: Column(
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
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Ohey3DButton.secondary(
                  label: '閉じる',
                  onTap: () => Navigator.of(context).pop(),
                  height: 48,
                  radius: 22,
                  color: const Color(0xFF252044),
                  foregroundColor: const Color(0xFFC08BFF),
                  shadowColor: const Color(0xFF15142C),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
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
        ? const Color(0xFF697684)
        : Colors.white.withValues(alpha: .58);

    return OheyBottomSheetShell(
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
            accent: const Color(0xFFFF8AA8),
            destructive: true,
            onTap: () => Navigator.of(context).pop(_FriendProfileAction.remove),
          ),
          const SizedBox(height: 10),
          OheyActionTile(
            icon: CupertinoIcons.bell_slash_fill,
            title: 'ミュート',
            subtitle: 'ゆるぼをフィードに出しません',
            accent: const Color(0xFF88B8FF),
            onTap: () => Navigator.of(context).pop(_FriendProfileAction.mute),
          ),
          const SizedBox(height: 10),
          OheyActionTile(
            icon: CupertinoIcons.hand_raised_fill,
            title: 'ブロック',
            subtitle: 'ゆるぼ・申請・お誘いを制限します',
            accent: const Color(0xFFFF5F8F),
            destructive: true,
            onTap: () => Navigator.of(context).pop(_FriendProfileAction.block),
          ),
          const SizedBox(height: 10),
          OheyActionTile(
            icon: CupertinoIcons.exclamationmark_bubble_fill,
            title: '通報',
            subtitle: '理由を選んで運営に送信します',
            accent: const Color(0xFFFFD166),
            onTap: () => Navigator.of(context).pop(_FriendProfileAction.report),
          ),
          const SizedBox(height: 12),
          Ohey3DButton.secondary(
            label: 'キャンセル',
            onTap: () => Navigator.of(context).pop(),
            height: 48,
            radius: 20,
            color: isWhite
                ? const Color(0xFFF2F6FA)
                : Colors.white.withValues(alpha: .06),
            foregroundColor: isWhite
                ? const Color(0xFF101820)
                : Colors.white.withValues(alpha: .82),
            shadowColor: const Color(0xFF243240).withValues(alpha: .46),
            useGradient: false,
          ),
        ],
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
    barrierColor: Colors.black.withValues(alpha: .58),
    builder: (_) => const _FriendReportReasonSheet(),
  );
}

class _FriendReportReasonSheet extends StatelessWidget {
  const _FriendReportReasonSheet();

  @override
  Widget build(BuildContext context) {
    final isWhite = Theme.of(context).brightness == Brightness.light;
    final sub = isWhite
        ? const Color(0xFF697684)
        : Colors.white.withValues(alpha: .58);
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
              accent: const Color(0xFFFFD166),
              onTap: () => Navigator.of(context).pop(reason),
            ),
            if (reason != _FriendProfileReportReason.values.last)
              const SizedBox(height: 9),
          ],
          const SizedBox(height: 12),
          Ohey3DButton.secondary(
            label: 'キャンセル',
            onTap: () => Navigator.of(context).pop(),
            height: 48,
            radius: 20,
            color: isWhite
                ? const Color(0xFFF2F6FA)
                : Colors.white.withValues(alpha: .06),
            foregroundColor: isWhite
                ? const Color(0xFF101820)
                : Colors.white.withValues(alpha: .82),
            shadowColor: const Color(0xFF243240).withValues(alpha: .46),
            useGradient: false,
          ),
        ],
      ),
    );
  }
}

class _FriendProfileTopBackdrop extends StatelessWidget {
  const _FriendProfileTopBackdrop({
    required this.friend,
    required this.avatar,
    required this.onActionMenu,
  });

  final OheyFriend friend;
  final OheyAvatar avatar;
  final VoidCallback? onActionMenu;

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.viewPaddingOf(context).top;
    final headerHeight = topPadding + 318;
    return SizedBox(
      height: headerHeight,
      child: Stack(
        fit: StackFit.expand,
        children: [
          _FriendProfileHeaderBackdrop(avatar: avatar),
          Positioned(
            right: 16,
            top: topPadding + 8,
            child: Opacity(
              opacity: onActionMenu == null ? .42 : 1,
              child: OheyHeaderIconButton(
                icon: CupertinoIcons.gear_solid,
                semanticLabel: '操作メニュー',
                color: const Color(0xFF65D6FF),
                onTap: onActionMenu ?? () {},
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              OheyPageHeader.horizontalPadding,
              topPadding + 4,
              OheyPageHeader.horizontalPadding,
              6,
            ),
            child: Column(
              children: [
                const Spacer(),
                _FriendProfileHero(friend: friend, avatar: avatar),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FriendProfileHeaderBackdrop extends StatelessWidget {
  const _FriendProfileHeaderBackdrop({required this.avatar});

  final OheyAvatar avatar;

  @override
  Widget build(BuildContext context) {
    final imageBackdropAsset = OheyAvatar.imageBackdropAsset(avatar.background);
    if (imageBackdropAsset != null) {
      return ExcludeSemantics(
        child: Image.asset(
          imageBackdropAsset,
          fit: BoxFit.cover,
          alignment: Alignment.center,
        ),
      );
    }

    final backgroundColors =
        OheyAvatar.backgroundGradients[avatar.background %
            OheyAvatar.backgroundGradients.length];
    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: backgroundColors,
            ),
          ),
        ),
        Opacity(
          opacity: avatar.background == OheyAvatar.dreamRoomBackground
              ? .18
              : .10,
          child: ExcludeSemantics(
            child: Image.asset(
              'assets/images/profile_header_scene.png',
              fit: BoxFit.cover,
              alignment: Alignment.center,
            ),
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.white.withValues(alpha: .18),
                Colors.white.withValues(alpha: .36),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _FriendProfileHero extends StatelessWidget {
  const _FriendProfileHero({required this.friend, required this.avatar});

  final OheyFriend friend;
  final OheyAvatar avatar;

  @override
  Widget build(BuildContext context) {
    final handle = friend.vibe.trim().isEmpty ? friend.id : '@${friend.vibe}';
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(30)),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            height: 190,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: OheyAvatarView(avatar: avatar, size: 156),
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 9),
            color: AppColors.darkBackgroundBottom,
            child: Center(
              child: Text(
                '${friend.name} ・ $handle',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white.withValues(alpha: .72),
                  fontWeight: FontWeight.w900,
                  letterSpacing: -.4,
                ),
              ),
            ),
          ),
        ],
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
                    color: Color(0xFFC08BFF),
                    size: 18,
                  ),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      '${friend.name}さんのやりたいこと',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
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
      accentColor: const Color(0xFFC08BFF),
      borderRadius: 22,
      backgroundColor: const Color(0xFF231A38).withValues(alpha: .92),
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
        color: const Color(0xFFC08BFF).withValues(alpha: .18),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFC08BFF).withValues(alpha: .34),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            wish.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
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
              color: Colors.white.withValues(alpha: .56),
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
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  status.reason,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: .70),
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
    final ink = isWhite ? const Color(0xFF101820) : Colors.white;

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
          color: Colors.white.withValues(alpha: .12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: .10)),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
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
                            ? Color(0xFFFF6FA6)
                            : entry.key == 6
                            ? Color(0xFF46C8FF)
                            : Color(0xFFB7C0CA),
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
    final statusAccent = _friendProfileCalendarStatusTileAccent(dailyStatus);
    final dayColor = hasStatus
        ? _friendProfileCalendarStatusTileForeground(
            dailyStatus,
            isWhite: isWhite,
          )
        : !inMonth
        ? (isWhite
              ? Colors.black.withValues(alpha: .20)
              : Colors.white.withValues(alpha: .20))
        : column == 0
        ? const Color(0xFFFF6FA6)
        : column == 6
        ? const Color(0xFF46C8FF)
        : isWhite
        ? const Color(0xFF101820)
        : Colors.white;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        decoration: BoxDecoration(
          color: hasStatus
              ? _friendProfileCalendarStatusTileBackground(
                  dailyStatus,
                  isWhite: isWhite,
                  selected: isSelected,
                )
              : isWhite
              ? (isSelected ? const Color(0xFFEAF8FF) : Colors.white)
              : AppColors.darkBackground,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(
            color: hasStatus
                ? statusAccent.withValues(alpha: isSelected ? .90 : .52)
                : isSelected
                ? const Color(0xFF54D7FF)
                : const Color(
                    0xFF20B9FF,
                  ).withValues(alpha: isWhite ? .34 : .24),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: hasStatus
                  ? statusAccent.withValues(alpha: isWhite ? .16 : .24)
                  : Colors.black.withValues(alpha: isWhite ? .05 : .20),
              blurRadius: hasStatus ? 16 : 12,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Center(
          child: Text(
            '$day',
            style: TextStyle(
              color: isToday && !isWhite ? Colors.white : dayColor,
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

Color _friendProfileCalendarStatusTileAccent(OheyDailyStatus status) =>
    switch (status) {
      OheyDailyStatus.available => const Color(0xFFFF5EA8),
      OheyDailyStatus.maybeAvailable => const Color(0xFF20B9FF),
      OheyDailyStatus.dependsOnTime => const Color(0xFF8A62FF),
      OheyDailyStatus.hasPlans => const Color(0xFF738092),
      OheyDailyStatus.unselected => const Color(0xFF9AF21A),
    };

Color _friendProfileCalendarStatusTileBackground(
  OheyDailyStatus status, {
  required bool isWhite,
  required bool selected,
}) {
  if (status == OheyDailyStatus.hasPlans) {
    return isWhite
        ? const Color(0xFFE2E8F0)
        : const Color(0xFF2B3644).withValues(alpha: selected ? .92 : .76);
  }
  final color = _friendProfileCalendarStatusTileAccent(status);
  return color.withValues(
    alpha: isWhite ? (selected ? .34 : .22) : (selected ? .52 : .36),
  );
}

Color _friendProfileCalendarStatusTileForeground(
  OheyDailyStatus status, {
  required bool isWhite,
}) {
  if (status == OheyDailyStatus.hasPlans) {
    return isWhite ? const Color(0xFF111827) : Colors.white;
  }
  return const Color(0xFF06111D);
}

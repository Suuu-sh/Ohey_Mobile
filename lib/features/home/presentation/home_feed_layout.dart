part of 'home_screen.dart';

double _feedHeaderScrollInset(BuildContext context) {
  // Match the latest reference feed capture: header scene ends at y≈505 on
  // a 1200px-wide crop. Keeping this width ratio locks the visible image
  // crop to the reference instead of depending on safe-area heuristics.
  const referenceWidth = 1200.0;
  const referenceHeaderBottom = 505.0;
  return MediaQuery.sizeOf(context).width *
      referenceHeaderBottom /
      referenceWidth;
}

const _feedBottomPageInset = 124.0;
const _feedPrimaryActionColor = Color(0xFFC08BFF);
const _feedPrimaryActionShadowColor = Color(0xFF7F51C9);

Widget _buildFeedPage({
  required double topPadding,
  required List<_FeedItem> items,
  required bool isWhite,
  required bool isLoading,
  required bool showSwipeTutorial,
  required VoidCallback onSwipeTutorialDismissed,
  required ValueChanged<int> onPageChanged,
  required VoidCallback onCreateYuruboPressed,
  required ValueChanged<_FeedItem> onLikePressed,
  required ValueChanged<_FeedItem> onSharePressed,
  required ValueChanged<_FeedItem> onMorePressed,
  required ValueChanged<_FeedItem> onAuthorPressed,
}) {
  if (isLoading && items.isEmpty) {
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.only(top: topPadding, bottom: _feedBottomPageInset),
      children: const [
        Padding(
          padding: EdgeInsets.all(36),
          child: Center(child: CupertinoActivityIndicator()),
        ),
      ],
    );
  }

  if (items.isEmpty) {
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.only(top: topPadding, bottom: _feedBottomPageInset),
      children: [
        _FeedSectionEmptyState(
          isWhite: isWhite,
          onCreateYuruboPressed: onCreateYuruboPressed,
        ),
      ],
    );
  }

  return ListView.separated(
    physics: const BouncingScrollPhysics(),
    padding: EdgeInsets.fromLTRB(0, topPadding + 10, 0, _feedBottomPageInset),
    itemCount: items.length + (isLoading ? 1 : 0),
    separatorBuilder: (context, index) => const SizedBox(height: 12),
    itemBuilder: (context, index) {
      if (index >= items.length) {
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: 18),
          child: Center(child: CupertinoActivityIndicator()),
        );
      }
      if (index >= items.length - 3) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          onPageChanged(index);
        });
      }
      final item = items[index];
      return _YuruboPostListItem(
        item: item,
        isWhite: isWhite,
        onInterested: item.isLikeable ? () => onLikePressed(item) : null,
        onInvite: item.id.isEmpty ? null : () => onSharePressed(item),
        onMore: item.id.isEmpty ? null : () => onMorePressed(item),
        onAuthorTap: () => onAuthorPressed(item),
      );
    },
  );
}

class _YuruboPostListItem extends StatelessWidget {
  const _YuruboPostListItem({
    required this.item,
    required this.isWhite,
    this.onInterested,
    this.onInvite,
    this.onMore,
    this.onAuthorTap,
  });

  final _FeedItem item;
  final bool isWhite;
  final VoidCallback? onInterested;
  final VoidCallback? onInvite;
  final VoidCallback? onMore;
  final VoidCallback? onAuthorTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: _FeedPostCard(
        item: item,
        isWhite: isWhite,
        compactYurubo: true,
        onLike: onInterested,
        onShare: onInvite,
        onMore: onMore,
        onAuthorTap: onAuthorTap,
      ),
    );
  }
}

class _FeedSectionEmptyState extends StatelessWidget {
  const _FeedSectionEmptyState({
    required this.isWhite,
    required this.onCreateYuruboPressed,
  });

  final bool isWhite;
  final VoidCallback onCreateYuruboPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 28),
      child: _FeedEmptyState(
        icon: CupertinoIcons.plus_bubble_fill,
        isWhite: isWhite,
        title: '最初のゆるぼを出そう',
        message: 'ご飯・作業・サウナなど、LINEで送るほどでもない誘いを軽く置けます。',
        accent: _feedPrimaryActionColor,
        action: SizedBox(
          width: 240,
          child: Ohey3DButton(
            label: 'ゆるぼする',
            icon: CupertinoIcons.plus_bubble_fill,
            onTap: onCreateYuruboPressed,
            height: 50,
            radius: 22,
            color: _feedPrimaryActionColor,
            foregroundColor: const Color(0xFF101820),
            shadowColor: _feedPrimaryActionShadowColor,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

Future<void> _showFeedPostActions(
  BuildContext context,
  WidgetRef ref,
  _FeedItem item,
) async {
  final body = item.body.trim();
  HapticFeedback.selectionClick();
  final action = await showOheyBottomSheet<_FeedPostAction>(
    context: context,
    useSafeArea: true,
    isScrollControlled: true,
    barrierColor: Colors.black.withValues(alpha: .58),
    builder: (context) => _FeedPostActionsSheet(item: item, body: body),
  );
  if (!context.mounted || action == null) return;

  switch (action) {
    case _FeedPostAction.copy:
      await Clipboard.setData(ClipboardData(text: body));
      if (context.mounted) OheyToast.show(context, 'コメントをコピーしました');
    case _FeedPostAction.delete:
      final confirmed = await _confirmDeleteFeedPost(context);
      if (!confirmed || !context.mounted) return;
      try {
        await ref
            .read(homeFeedControllerProvider.notifier)
            .deleteMemory(item.id);
        ref.invalidate(homeFeedControllerProvider);
        if (context.mounted) OheyToast.show(context, 'ゆるぼを削除しました');
      } catch (error) {
        if (context.mounted) {
          OheyToast.show(context, '削除できなかったよ。あとでもう一度試してね');
        }
      }
    case _FeedPostAction.report:
      final reason = await _selectReportReason(context);
      if (!context.mounted || reason == null) return;
      try {
        await ref
            .read(homeFeedControllerProvider.notifier)
            .reportMemory(item.id, reason: reason.value);
        if (context.mounted) {
          OheyToast.show(context, '「${reason.label}」として報告しました');
        }
      } catch (error) {
        if (context.mounted) {
          OheyToast.show(context, '報告できなかったよ。あとでもう一度試してね');
        }
      }
    case _FeedPostAction.hide:
      try {
        await ref.read(homeFeedControllerProvider.notifier).hideMemory(item.id);
        if (context.mounted) OheyToast.show(context, 'フィードから非表示にしました');
      } catch (_) {
        if (context.mounted) {
          OheyToast.show(context, '非表示にできなかったよ。あとでもう一度試してね');
        }
      }
    case _FeedPostAction.muteUser:
      if (item.ownerUserId.trim().isEmpty) return;
      try {
        await ref
            .read(homeFeedControllerProvider.notifier)
            .muteUser(item.ownerUserId);
        if (context.mounted) {
          _showUserSafetyUndoToast(
            context,
            message: '${item.userName}さんをミュートしました',
            undoLabel: '元に戻す',
            onUndo: () async {
              await ref
                  .read(userSafetyRepositoryProvider)
                  .unmuteUser(item.ownerUserId);
              ref.invalidate(mutedUsersProvider);
              ref.invalidate(homeFeedControllerProvider);
            },
          );
        }
      } catch (_) {
        if (context.mounted) {
          OheyToast.show(context, 'ミュートできなかったよ。あとでもう一度試してね');
        }
      }
    case _FeedPostAction.blockUser:
      if (item.ownerUserId.trim().isEmpty) return;
      final confirmed = await _confirmUserSafetyAction(
        context,
        title: '${item.userName}さんをブロックしますか？',
        message: '相手のゆるぼやお誘いが表示されにくくなります。必要ならあとで解除できます。',
        actionLabel: 'ブロックする',
        color: const Color(0xFFFF5F8F),
      );
      if (!confirmed || !context.mounted) return;
      try {
        await ref
            .read(homeFeedControllerProvider.notifier)
            .blockUser(item.ownerUserId);
        if (context.mounted) {
          _showUserSafetyUndoToast(
            context,
            message: '${item.userName}さんをブロックしました',
            undoLabel: '元に戻す',
            onUndo: () async {
              await ref
                  .read(userSafetyRepositoryProvider)
                  .unblockUser(item.ownerUserId);
              ref.invalidate(blockedUsersProvider);
              ref.invalidate(friendsProvider);
              ref.invalidate(homeFeedControllerProvider);
            },
          );
        }
      } catch (_) {
        if (context.mounted) {
          OheyToast.show(context, 'ブロックできなかったよ。あとでもう一度試してね');
        }
      }
  }
}

void _showUserSafetyUndoToast(
  BuildContext context, {
  required String message,
  required String undoLabel,
  required Future<void> Function() onUndo,
}) {
  OheyToast.show(
    context,
    message,
    icon: CupertinoIcons.checkmark_circle_fill,
    duration: const Duration(milliseconds: 5200),
    actionLabel: undoLabel,
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

Future<bool> _confirmDeleteFeedPost(BuildContext context) async {
  final result = await showOheyBottomSheet<bool>(
    context: context,
    useSafeArea: true,
    isScrollControlled: true,
    barrierColor: Colors.black.withValues(alpha: .62),
    builder: (context) => const _FeedDeleteConfirmSheet(),
  );
  return result ?? false;
}

Future<_FeedReportReason?> _selectReportReason(BuildContext context) async {
  return showOheyBottomSheet<_FeedReportReason>(
    context: context,
    useSafeArea: true,
    isScrollControlled: true,
    barrierColor: Colors.black.withValues(alpha: .62),
    builder: (context) => const _FeedReportReasonSheet(),
  );
}

Future<bool> _confirmUserSafetyAction(
  BuildContext context, {
  required String title,
  required String message,
  required String actionLabel,
  required Color color,
}) async {
  final result = await showOheyBottomSheet<bool>(
    context: context,
    useSafeArea: true,
    isScrollControlled: true,
    barrierColor: Colors.black.withValues(alpha: .62),
    builder: (context) => _FeedUserSafetyConfirmSheet(
      title: title,
      message: message,
      actionLabel: actionLabel,
      color: color,
    ),
  );
  return result ?? false;
}

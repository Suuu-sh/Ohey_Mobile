part of 'home_screen.dart';

double _feedHeaderScrollInset(BuildContext context) {
  return NomoPageHeader.contentTopInset(context);
}

const _feedBottomPageInset = 124.0;

Widget _buildFeedPage({
  required double topPadding,
  required List<_FeedItem> items,
  required bool isWhite,
  required bool isLoading,
  required bool showSwipeTutorial,
  required VoidCallback onSwipeTutorialDismissed,
  required ValueChanged<int> onPageChanged,
  required VoidCallback onAddLogPressed,
  required ValueChanged<_FeedItem> onLikePressed,
  required ValueChanged<_FeedItem> onSharePressed,
  required ValueChanged<_FeedItem> onMorePressed,
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
          onAddLogPressed: onAddLogPressed,
        ),
      ],
    );
  }

  return PageView.builder(
    scrollDirection: Axis.vertical,
    onPageChanged: onPageChanged,
    physics: const PageScrollPhysics(parent: BouncingScrollPhysics()),
    itemCount: items.length,
    itemBuilder: (context, index) {
      final item = items[index];
      return _FeedPostPage(
        topPadding: topPadding,
        item: item,
        isWhite: isWhite,
        showSwipeHint: index < items.length - 1,
        showSwipeTutorial: showSwipeTutorial && index == 0,
        onSwipeTutorialDismissed: onSwipeTutorialDismissed,
        onLike: item.isLikeable ? () => onLikePressed(item) : null,
        onShare: item.id.isEmpty ? null : () => onSharePressed(item),
        onMore: item.id.isEmpty ? null : () => onMorePressed(item),
      );
    },
  );
}

class _FeedPostPage extends StatelessWidget {
  const _FeedPostPage({
    required this.topPadding,
    required this.item,
    required this.isWhite,
    required this.showSwipeHint,
    required this.showSwipeTutorial,
    required this.onSwipeTutorialDismissed,
    this.onLike,
    this.onShare,
    this.onMore,
  });

  final double topPadding;
  final _FeedItem item;
  final bool isWhite;
  final bool showSwipeHint;
  final bool showSwipeTutorial;
  final VoidCallback onSwipeTutorialDismissed;
  final VoidCallback? onLike;
  final VoidCallback? onShare;
  final VoidCallback? onMore;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Padding(
          padding: EdgeInsets.only(
            top: topPadding,
            bottom: _feedBottomPageInset,
          ),
          child: Align(
            alignment: Alignment.topCenter,
            child: _FeedPostCard(
              item: item,
              isWhite: isWhite,
              onLike: onLike,
              onShare: onShare,
              onMore: onMore,
            ),
          ),
        ),
        if (showSwipeHint)
          Positioned(
            left: 12,
            right: 12,
            bottom: _feedBottomPageInset + 4,
            child: _FeedSwipeHint(isWhite: isWhite),
          ),
        if (showSwipeTutorial)
          Positioned.fill(
            child: _FeedSwipeTutorialOverlay(
              isWhite: isWhite,
              onDismissed: onSwipeTutorialDismissed,
            ),
          ),
      ],
    );
  }
}

class _FeedSectionEmptyState extends StatelessWidget {
  const _FeedSectionEmptyState({
    required this.isWhite,
    required this.onAddLogPressed,
  });

  final bool isWhite;
  final VoidCallback onAddLogPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 28),
      child: _FeedEmptyState(
        icon: CupertinoIcons.photo_on_rectangle,
        isWhite: isWhite,
        title: '飲みログはまだありません',
        message: '今日の一杯から残してみよう。',
        accent: _FeedColors.teal,
        action: SizedBox(
          width: 220,
          child: Nomo3DButton(
            label: '最初の飲みログを残す',
            icon: CupertinoIcons.camera_fill,
            onTap: onAddLogPressed,
            height: 50,
            radius: 22,
            color: AppColors.primaryAction,
            shadowColor: AppColors.primaryActionShadow,
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
  final action = await showModalBottomSheet<_FeedPostAction>(
    context: context,
    useSafeArea: true,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: .58),
    builder: (context) => _FeedPostActionsSheet(item: item, body: body),
  );
  if (!context.mounted || action == null) return;

  switch (action) {
    case _FeedPostAction.copy:
      await Clipboard.setData(ClipboardData(text: body));
      if (context.mounted) NomoToast.show(context, 'コメントをコピーしました');
    case _FeedPostAction.delete:
      final confirmed = await _confirmDeleteFeedPost(context);
      if (!confirmed || !context.mounted) return;
      try {
        await ref.read(drinkLogControllerProvider.notifier).deleteLog(item.id);
        ref.invalidate(drinkLogControllerProvider);
        if (context.mounted) NomoToast.show(context, '飲みログを削除しました');
      } catch (error) {
        if (context.mounted) {
          NomoToast.show(context, '削除できなかったよ。あとでもう一度試してね');
        }
      }
    case _FeedPostAction.report:
      try {
        await ref.read(drinkLogControllerProvider.notifier).reportLog(item.id);
        if (context.mounted) NomoToast.show(context, '飲みログを報告しました');
      } catch (error) {
        if (context.mounted) {
          NomoToast.show(context, '報告できなかったよ。あとでもう一度試してね');
        }
      }
  }
}

Future<bool> _confirmDeleteFeedPost(BuildContext context) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    useSafeArea: true,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: .62),
    builder: (context) => const _FeedDeleteConfirmSheet(),
  );
  return result ?? false;
}

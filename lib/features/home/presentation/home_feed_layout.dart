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
  required VoidCallback onAddLogPressed,
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
        showSwipeTutorial: showSwipeTutorial && index == 0,
        onSwipeTutorialDismissed: onSwipeTutorialDismissed,
        onLike: item.isLikeable ? () => onLikePressed(item) : null,
        onShare: item.id.isEmpty ? null : () => onSharePressed(item),
        onMore: item.id.isEmpty ? null : () => onMorePressed(item),
        onAuthorTap: () => onAuthorPressed(item),
      );
    },
  );
}

class _FeedPostPage extends StatelessWidget {
  const _FeedPostPage({
    required this.topPadding,
    required this.item,
    required this.isWhite,
    required this.showSwipeTutorial,
    required this.onSwipeTutorialDismissed,
    this.onLike,
    this.onShare,
    this.onMore,
    this.onAuthorTap,
  });

  final double topPadding;
  final _FeedItem item;
  final bool isWhite;
  final bool showSwipeTutorial;
  final VoidCallback onSwipeTutorialDismissed;
  final VoidCallback? onLike;
  final VoidCallback? onShare;
  final VoidCallback? onMore;
  final VoidCallback? onAuthorTap;

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
              onAuthorTap: onAuthorTap,
            ),
          ),
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
        icon: CupertinoIcons.camera_fill,
        isWhite: isWhite,
        title: '最初の1枚を残そう',
        message: '今日の写真にひと言添えるだけで、ホームとアーカイブにかわいい思い出が並びます。',
        accent: _feedPrimaryActionColor,
        action: SizedBox(
          width: 240,
          child: Nomo3DButton(
            label: '写真を選んで投稿する',
            icon: CupertinoIcons.camera_fill,
            onTap: onAddLogPressed,
            height: 50,
            radius: 22,
            color: _feedPrimaryActionColor,
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
  final action = await showNomoBottomSheet<_FeedPostAction>(
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
      if (context.mounted) NomoToast.show(context, 'コメントをコピーしました');
    case _FeedPostAction.delete:
      final confirmed = await _confirmDeleteFeedPost(context);
      if (!confirmed || !context.mounted) return;
      try {
        await ref.read(drinkLogControllerProvider.notifier).deleteLog(item.id);
        ref.invalidate(drinkLogControllerProvider);
        if (context.mounted) NomoToast.show(context, '思い出を削除しました');
      } catch (error) {
        if (context.mounted) {
          NomoToast.show(context, '削除できなかったよ。あとでもう一度試してね');
        }
      }
    case _FeedPostAction.report:
      try {
        await ref.read(drinkLogControllerProvider.notifier).reportLog(item.id);
        if (context.mounted) NomoToast.show(context, '思い出を報告しました');
      } catch (error) {
        if (context.mounted) {
          NomoToast.show(context, '報告できなかったよ。あとでもう一度試してね');
        }
      }
  }
}

Future<bool> _confirmDeleteFeedPost(BuildContext context) async {
  final result = await showNomoBottomSheet<bool>(
    context: context,
    useSafeArea: true,
    isScrollControlled: true,
    barrierColor: Colors.black.withValues(alpha: .62),
    builder: (context) => const _FeedDeleteConfirmSheet(),
  );
  return result ?? false;
}

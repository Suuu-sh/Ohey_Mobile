part of 'home_screen.dart';

enum _FeedPostAction { copy, delete, report }

class _FeedPostActionsSheet extends StatelessWidget {
  const _FeedPostActionsSheet({required this.item, required this.body});

  final _FeedItem item;
  final String body;

  @override
  Widget build(BuildContext context) {
    final isWhite = Theme.of(context).brightness == Brightness.light;
    final titleColor = isWhite ? const Color(0xFF101820) : Colors.white;
    final subtitleColor = isWhite
        ? const Color(0xFF697684)
        : Colors.white.withValues(alpha: .58);
    return NomoBottomSheetShell(
      showHandle: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const NomoBottomSheetHandle(),
          const SizedBox(height: 18),
          Row(
            children: [
              _AvatarBubble(
                avatar: item.avatar,
                size: 46,
                glowColor: item.accent,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.userName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: titleColor,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      body.isEmpty ? '飲みログメニュー' : body,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: subtitleColor,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: NomoPopIcon(
                  icon: CupertinoIcons.xmark,
                  color: subtitleColor,
                  size: 34,
                  iconSize: 18,
                  shadow: false,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          if (body.isNotEmpty) ...[
            NomoActionTile(
              icon: CupertinoIcons.doc_on_clipboard_fill,
              title: 'コメントをコピー',
              subtitle: 'クリップボードに保存',
              accent: _FeedColors.teal,
              onTap: () => Navigator.of(context).pop(_FeedPostAction.copy),
            ),
            const SizedBox(height: 10),
          ],
          if (item.ownedByMe)
            NomoActionTile(
              icon: CupertinoIcons.trash_fill,
              title: '飲みログを削除',
              subtitle: 'この投稿をフィードから消す',
              accent: const Color(0xFFFF5F8F),
              destructive: true,
              onTap: () => Navigator.of(context).pop(_FeedPostAction.delete),
            )
          else
            NomoActionTile(
              icon: CupertinoIcons.exclamationmark_bubble_fill,
              title: '飲みログを報告',
              subtitle: '気になる投稿を運営に送る',
              accent: const Color(0xFFFFD166),
              onTap: () => Navigator.of(context).pop(_FeedPostAction.report),
            ),
          const SizedBox(height: 12),
          _FeedModalTextButton(
            label: 'キャンセル',
            onTap: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}

class _FeedDeleteConfirmSheet extends StatelessWidget {
  const _FeedDeleteConfirmSheet();

  @override
  Widget build(BuildContext context) {
    final isWhite = Theme.of(context).brightness == Brightness.light;
    final titleColor = isWhite ? const Color(0xFF101820) : Colors.white;
    final subtitleColor = isWhite
        ? const Color(0xFF697684)
        : Colors.white.withValues(alpha: .58);
    return NomoBottomSheetShell(
      showHandle: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const NomoBottomSheetHandle(),
          const SizedBox(height: 20),
          Center(
            child: NomoPopIcon(
              icon: CupertinoIcons.trash_fill,
              color: const Color(0xFFFF5F8F),
              size: 64,
              iconSize: 34,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '飲みログを削除しますか？',
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
            '削除した飲みログは元に戻せません。',
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
                child: _FeedModalTextButton(
                  label: 'やめる',
                  onTap: () => Navigator.of(context).pop(false),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _FeedModalTextButton(
                  label: '削除する',
                  color: const Color(0xFFFF5F8F),
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

class _FeedModalTextButton extends StatelessWidget {
  const _FeedModalTextButton({
    required this.label,
    required this.onTap,
    this.color = _FeedColors.teal,
  });

  final String label;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final isWhite = Theme.of(context).brightness == Brightness.light;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        height: 54,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: color.withValues(alpha: isWhite ? .13 : .10),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: .30)),
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

Future<void> _showFeedCompanionList(
  BuildContext context,
  List<_Companion> friends,
) async {
  if (friends.isEmpty) return;
  HapticFeedback.selectionClick();
  final selected = await showNomoBottomSheet<_Companion>(
    context: context,
    useSafeArea: true,
    isScrollControlled: true,
    barrierColor: Colors.black.withValues(alpha: .58),
    builder: (context) => _FeedCompanionListSheet(friends: friends),
  );
  if (!context.mounted || selected == null) return;
  HapticFeedback.selectionClick();
  await showNomoBottomSheet<void>(
    context: context,
    useSafeArea: true,
    isScrollControlled: true,
    barrierColor: Colors.black.withValues(alpha: .62),
    builder: (context) => _FeedCompanionProfileSheet(friend: selected),
  );
}

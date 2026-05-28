part of 'home_screen.dart';

enum _FeedPostAction { copy, delete, report, hide, muteUser, blockUser }

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
                      body.isEmpty ? '思い出メニュー' : body,
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
          if (item.canDelete || item.ownedByMe)
            NomoActionTile(
              icon: CupertinoIcons.trash_fill,
              title: '思い出を削除',
              subtitle: 'この投稿をフィードから消す',
              accent: const Color(0xFFFF5F8F),
              destructive: true,
              onTap: () => Navigator.of(context).pop(_FeedPostAction.delete),
            )
          else if (!item.isOfficial) ...[
            NomoActionTile(
              icon: CupertinoIcons.eye_slash_fill,
              title: 'この投稿を非表示',
              subtitle: '自分のフィードからだけ消す',
              accent: _FeedColors.teal,
              onTap: () => Navigator.of(context).pop(_FeedPostAction.hide),
            ),
            const SizedBox(height: 10),
            NomoActionTile(
              icon: CupertinoIcons.bell_slash_fill,
              title: '${item.userName}さんをミュート',
              subtitle: '投稿をフィードに出しにくくする',
              accent: const Color(0xFF88B8FF),
              onTap: () => Navigator.of(context).pop(_FeedPostAction.muteUser),
            ),
            const SizedBox(height: 10),
            NomoActionTile(
              icon: CupertinoIcons.hand_raised_fill,
              title: '${item.userName}さんをブロック',
              subtitle: '投稿・申請・お誘いを制限する',
              accent: const Color(0xFFFF5F8F),
              destructive: true,
              onTap: () => Navigator.of(context).pop(_FeedPostAction.blockUser),
            ),
            if (item.canReport) ...[
              const SizedBox(height: 10),
              NomoActionTile(
                icon: CupertinoIcons.exclamationmark_bubble_fill,
                title: '思い出を報告',
                subtitle: '気になる投稿を運営に送る',
                accent: const Color(0xFFFFD166),
                onTap: () => Navigator.of(context).pop(_FeedPostAction.report),
              ),
            ],
          ],
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
            '思い出を削除しますか？',
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
            '削除した思い出は元に戻せません。',
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

class _FeedUserSafetyConfirmSheet extends StatelessWidget {
  const _FeedUserSafetyConfirmSheet({
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.color,
  });

  final String title;
  final String message;
  final String actionLabel;
  final Color color;

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
              icon: CupertinoIcons.hand_raised_fill,
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
                child: _FeedModalTextButton(
                  label: 'やめる',
                  onTap: () => Navigator.of(context).pop(false),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _FeedModalTextButton(
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
    final surfaceColor = Color.lerp(
      isWhite ? Colors.white : AppColors.darkBackground,
      color,
      isWhite ? .16 : .22,
    )!;
    final bottomColor = nomo3DShadowColorFor(
      color,
      lightnessScale: isWhite ? .72 : .58,
    );
    return Nomo3DButtonSurface(
      onTap: onTap,
      height: 52,
      radius: 20,
      color: surfaceColor,
      bottomColor: bottomColor,
      padding: EdgeInsets.zero,
      useGradient: true,
      borderColor: color.withValues(alpha: isWhite ? .34 : .38),
      outerShadows: [
        BoxShadow(
          color: color.withValues(alpha: isWhite ? .12 : .20),
          blurRadius: 18,
          offset: const Offset(0, 8),
        ),
      ],
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 16,
          fontWeight: FontWeight.w900,
          letterSpacing: -.35,
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
  final repository = ProviderScope.containerOf(
    context,
    listen: false,
  ).read(friendRepositoryProvider);
  NomoFriendRelationshipStatus? relationship;
  if (selected.userId.trim().isNotEmpty) {
    try {
      relationship = await repository.relationshipStatus(selected.userId);
    } catch (_) {
      relationship = null;
    }
  }
  if (!context.mounted) return;

  if (relationship?.alreadyFriend == true) {
    await showNomoFriendProfileSheet(context, friend: selected.toNomoFriend());
    return;
  }

  await showNomoBottomSheet<void>(
    context: context,
    useSafeArea: true,
    isScrollControlled: true,
    barrierColor: Colors.black.withValues(alpha: .62),
    builder: (context) => _FeedCompanionProfileSheet(
      friend: selected,
      initialRelationship: relationship,
    ),
  );
}

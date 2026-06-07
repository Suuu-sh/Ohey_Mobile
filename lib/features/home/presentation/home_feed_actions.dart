part of 'home_screen.dart';

enum _FeedPostAction { edit, delete, muteUser, blockUser }

class _FeedPostActionsSheet extends StatelessWidget {
  const _FeedPostActionsSheet({required this.item, required this.body});

  final _FeedItem item;
  final String body;

  @override
  Widget build(BuildContext context) {
    final isWhite = Theme.of(context).brightness == Brightness.light;
    final titleColor = isWhite ? AppColors.cFF101820 : AppColors.white;
    final subtitleColor = isWhite
        ? AppColors.cFF697684
        : AppColors.white.withValues(alpha: .58);
    return OheyBottomSheetShell(
      showHandle: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
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
                      body.isEmpty ? 'ゆるぼメニュー' : body,
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
              const SizedBox.shrink(),
            ],
          ),
          const SizedBox(height: 18),
          if (item.ownedByMe) ...[
            OheyActionTile(
              icon: CupertinoIcons.pencil,
              title: 'ゆるぼを編集',
              subtitle: '内容・場所・いつを直す',
              accent: _FeedColors.teal,
              onTap: () => Navigator.of(context).pop(_FeedPostAction.edit),
            ),
            const SizedBox(height: 10),
          ],
          if (item.canDelete || item.ownedByMe)
            OheyActionTile(
              icon: CupertinoIcons.trash_fill,
              title: 'ゆるぼを削除',
              subtitle: 'このゆるぼを一覧から消す',
              accent: AppColors.cFFFF5F8F,
              destructive: true,
              onTap: () => Navigator.of(context).pop(_FeedPostAction.delete),
            )
          else if (!item.isOfficial) ...[
            OheyActionTile(
              icon: CupertinoIcons.bell_slash_fill,
              title: '${item.userName}さんをミュート',
              subtitle: 'ゆるぼを一覧に出さない',
              accent: AppColors.cFF88B8FF,
              onTap: () => Navigator.of(context).pop(_FeedPostAction.muteUser),
            ),
            const SizedBox(height: 10),
            OheyActionTile(
              icon: CupertinoIcons.hand_raised_fill,
              title: '${item.userName}さんをブロック',
              subtitle: 'ゆるぼ・申請・お誘いを制限する',
              accent: AppColors.cFFFF5F8F,
              destructive: true,
              showShadow: false,
              onTap: () => Navigator.of(context).pop(_FeedPostAction.blockUser),
            ),
          ],
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
              icon: CupertinoIcons.trash_fill,
              color: AppColors.cFFFF5F8F,
              size: 64,
              iconSize: 34,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'ゆるぼを削除しますか？',
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
            '削除したゆるぼは元に戻せません。',
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
                  color: AppColors.cFFFF5F8F,
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
    final surfaceColor = isWhite
        ? Color.lerp(AppColors.white, color, .24)!
        : AppColors.darkBackground;
    return CupertinoButton(
      onPressed: onTap,
      minimumSize: Size.zero,
      padding: EdgeInsets.zero,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        height: 52,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isWhite
                ? color.withValues(alpha: .34)
                : AppColors.white.withValues(alpha: .12),
          ),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: isWhite ? .10 : .16),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
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
  _FeedItem item,
) async {
  final friends = item.friends;
  if (friends.isEmpty) return;
  HapticFeedback.selectionClick();
  final selected = await showOheyBottomSheet<_Companion>(
    context: context,
    useSafeArea: true,
    isScrollControlled: true,
    barrierColor: AppColors.black.withValues(alpha: .58),
    builder: (context) => _FeedCompanionListSheet(item: item),
  );
  if (!context.mounted || selected == null) return;

  HapticFeedback.selectionClick();
  final container = ProviderScope.containerOf(context, listen: false);
  final repository = container.read(friendRepositoryProvider);
  final currentUserId = repository.currentUserId?.trim();
  if (currentUserId != null &&
      currentUserId.isNotEmpty &&
      selected.userId.trim() == currentUserId) {
    await showOheyFriendProfileSheet(
      context,
      friend: _companionFriendForCurrentUser(
        selected,
        container.read(oheyUserProvider),
        currentUserId,
      ),
      showActionMenu: false,
    );
    return;
  }

  OheyFriendRelationshipStatus? relationship;
  if (selected.userId.trim().isNotEmpty) {
    try {
      relationship = await repository.relationshipStatus(selected.userId);
    } catch (_) {
      relationship = null;
    }
  }
  if (!context.mounted) return;

  if (relationship?.alreadyFriend == true) {
    await showOheyFriendProfileSheet(context, friend: selected.toOheyFriend());
    return;
  }

  await showOheyBottomSheet<void>(
    context: context,
    useSafeArea: true,
    isScrollControlled: true,
    barrierColor: AppColors.black.withValues(alpha: .62),
    builder: (context) => _FeedCompanionProfileSheet(
      friend: selected,
      initialRelationship: relationship,
    ),
  );
}

OheyFriend _companionFriendForCurrentUser(
  _Companion companion,
  OheyUser? currentUser,
  String currentUserId,
) {
  final name = currentUser?.name.trim();
  final handle = currentUser?.userId.trim();
  return OheyFriend(
    id: currentUserId,
    name: name?.isNotEmpty == true ? name! : companion.name,
    avatarEmoji: '👤',
    vibe: handle?.isNotEmpty == true
        ? handle!
        : companion.handle.replaceFirst('@', ''),
    characterAssetPath: '',
    kind: OheyFriendKind.cloud,
    palette: OheyFriendPalette.lavender,
    avatar: currentUser?.avatar ?? companion.avatar,
    statusKey: currentUser?.dailyStatus.key ?? companion.statusKey,
  );
}

part of 'home_screen.dart';

class _FeedInviteBanner extends StatelessWidget {
  const _FeedInviteBanner({
    required this.isWhite,
    required this.invite,
    required this.reservation,
    required this.currentUserId,
    required this.onOpenNotifications,
  });

  final bool isWhite;
  final OheyInvite? invite;
  final OheyInvite? reservation;
  final String? currentUserId;
  final VoidCallback onOpenNotifications;

  @override
  Widget build(BuildContext context) {
    final hasInvite = invite != null;
    final target = hasInvite
        ? (currentUserId == null
              ? invite!.inviter
              : invite!.otherUser(currentUserId!))
        : reservation == null
        ? null
        : (currentUserId == null
              ? reservation!.inviter
              : reservation!.otherUser(currentUserId!));
    if (target == null) return const SizedBox.shrink();

    final accent = hasInvite ? AppColors.primaryAction : AppColors.success;
    final top = OheyPageHeader.contentTopInset(context) - 8;
    return Positioned(
      left: 18,
      right: 18,
      top: top,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onOpenNotifications,
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          decoration: BoxDecoration(
            color: isWhite
                ? Colors.white.withValues(alpha: .96)
                : const Color(0xFF0D1C2B).withValues(alpha: .96),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: accent.withValues(alpha: .42)),
            boxShadow: [
              BoxShadow(
                color: accent.withValues(alpha: .20),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Row(
            children: [
              OheyPopIcon(
                icon: hasInvite
                    ? CupertinoIcons.bell_fill
                    : CupertinoIcons.checkmark_seal_fill,
                color: accent,
                size: 42,
                iconSize: 22,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hasInvite ? '返信待ちのお誘い' : '今日の予定あり',
                      style: TextStyle(
                        color: accent,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      hasInvite
                          ? '${target.name}から${invite!.summary()}が届いています'
                          : '${target.name}と${reservation!.summary()}があります',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: isWhite ? const Color(0xFF17212B) : Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                hasInvite ? '確認' : '見る',
                style: TextStyle(
                  color: isWhite ? const Color(0xFF17212B) : Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
              OheyGeneratedIcon(
                CupertinoIcons.chevron_right,
                color: isWhite
                    ? const Color(0xFF98A3AF)
                    : Colors.white.withValues(alpha: .54),
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

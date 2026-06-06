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
                ? AppColors.white.withValues(alpha: .96)
                : AppColors.cFF0D1C2B.withValues(alpha: .96),
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
                        color: isWhite ? AppColors.cFF17212B : AppColors.white,
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
                  color: isWhite ? AppColors.cFF17212B : AppColors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
              OheyGeneratedIcon(
                CupertinoIcons.chevron_right,
                color: isWhite
                    ? AppColors.cFF98A3AF
                    : AppColors.white.withValues(alpha: .54),
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeedPlusBanner extends StatelessWidget {
  const _FeedPlusBanner({required this.isWhite, required this.onTap});

  final bool isWhite;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const accent = AppColors.cFFFF6FC5;
    final top = OheyPageHeader.contentTopInset(context) - 8;
    return Positioned(
      left: 18,
      right: 18,
      top: top,
      child: Semantics(
        button: true,
        label: 'Ohey Plusを開く',
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.fromLTRB(18, 16, 22, 16),
            decoration: BoxDecoration(
              color: isWhite
                  ? AppColors.white.withValues(alpha: .96)
                  : AppColors.cFF0D1C2B.withValues(alpha: .96),
              borderRadius: BorderRadius.circular(32),
              border: Border.all(
                color: accent.withValues(alpha: .74),
                width: 1.3,
              ),
              boxShadow: [
                BoxShadow(
                  color: accent.withValues(alpha: .22),
                  blurRadius: 28,
                  offset: const Offset(0, 13),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: accent,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'Ohey Plus',
                            style: TextStyle(
                              color: isWhite
                                  ? AppColors.cFF17212B
                                  : AppColors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.w900,
                              letterSpacing: .2,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 7),
                      Text(
                        '広告なしでゆるぼを見る',
                        style: TextStyle(
                          color: isWhite
                              ? AppColors.cFF52606B
                              : AppColors.white.withValues(alpha: .90),
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                Container(
                  height: 58,
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  decoration: BoxDecoration(
                    color: accent,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: const [
                      BoxShadow(
                        color: AppColors.cFFFF4FA3,
                        blurRadius: 0,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text(
                      '見る',
                      style: TextStyle(
                        color: AppColors.cFF101820,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OheyPlusPurchaseSheet extends StatelessWidget {
  const _OheyPlusPurchaseSheet();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 10, 22, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.white.withValues(alpha: .18),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          const SizedBox(height: 22),
          const OheyPopIcon(
            icon: CupertinoIcons.sparkles,
            color: AppColors.cFFFF6FC5,
            size: 58,
            iconSize: 30,
          ),
          const SizedBox(height: 16),
          const Text(
            'Ohey Plus',
            style: TextStyle(
              color: AppColors.white,
              fontSize: 26,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'まずは広告を消せるプランとして準備中です。購入機能が有効になったら、ここから申し込めます。',
            style: TextStyle(
              color: AppColors.white.withValues(alpha: .68),
              fontSize: 14,
              height: 1.55,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 18),
          _OheyPlusBenefitRow(
            icon: CupertinoIcons.eye_slash_fill,
            title: '広告を非表示',
            message: 'ゆるぼ一覧の広告ブロックを消して、投稿だけに集中できます。',
          ),
          const SizedBox(height: 20),
          Ohey3DButton(
            label: '購入準備中',
            icon: CupertinoIcons.lock_fill,
            onTap: () => Navigator.of(context).pop(),
            height: 54,
            radius: 24,
            color: AppColors.cFFFF6FC5,
            foregroundColor: AppColors.cFF101820,
            shadowColor: AppColors.cFFFF4FA3,
            fontSize: 15,
          ),
        ],
      ),
    );
  }
}

class _OheyPlusBenefitRow extends StatelessWidget {
  const _OheyPlusBenefitRow({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: .07),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.white.withValues(alpha: .10)),
      ),
      child: Row(
        children: [
          OheyPopIcon(
            icon: icon,
            color: AppColors.cFFFF6FC5,
            size: 42,
            iconSize: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  message,
                  style: TextStyle(
                    color: AppColors.white.withValues(alpha: .62),
                    fontSize: 12,
                    height: 1.35,
                    fontWeight: FontWeight.w700,
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

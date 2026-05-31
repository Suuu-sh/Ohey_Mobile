part of 'profile_screen.dart';

class _AvatarEditCard extends StatelessWidget {
  const _AvatarEditCard({required this.avatar, required this.onTap});

  final OheyAvatar avatar;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isWhite = Theme.of(context).brightness == Brightness.light;
    final ink = isWhite ? AppColors.cFF101820 : AppColors.white;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        height: 110,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: isWhite
              ? AppColors.cFFF6F8FA
              : AppColors.white.withValues(alpha: .06),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: isWhite ? AppColors.cFFDDE4EA : _ProfileColors.line,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 82,
              height: 82,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [AppColors.cFF223544, AppColors.cFF101B28],
                ),
              ),
              child: OheyAvatarView(avatar: avatar, size: 82),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '自分のアバター',
                    style: TextStyle(
                      color: ink,
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '肌・髪型・服・表情をカスタム',
                    style: TextStyle(
                      color: isWhite
                          ? AppColors.cFF687481
                          : AppColors.white.withValues(alpha: .58),
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const OheyGeneratedIcon(
              CupertinoIcons.chevron_forward,
              color: _ProfileColors.lime,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsSheetShell extends StatelessWidget {
  const _SettingsSheetShell({
    required this.user,
    required this.children,
    required this.onClose,
  });

  final OheyUser? user;
  final List<Widget> children;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final isWhite = Theme.of(context).brightness == Brightness.light;
    final ink = isWhite ? AppColors.cFF111820 : AppColors.white;

    return OheyBottomSheetShell(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      padding: EdgeInsets.zero,
      radius: 34,
      maxHeightFactor: .88,
      child: Flexible(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 48,
                  height: 5,
                  decoration: BoxDecoration(
                    color: isWhite
                        ? AppColors.cFFD8E0E8
                        : AppColors.white.withValues(alpha: .18),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '設定',
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(
                                color: ink,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -1.0,
                              ),
                        ),
                      ],
                    ),
                  ),
                  _SettingsCloseButton(onTap: onClose, color: ink),
                ],
              ),
              const SizedBox(height: 14),
              ...children,
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsCloseButton extends StatelessWidget {
  const _SettingsCloseButton({required this.onTap, required this.color});

  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.accent,
    required this.onTap,
    this.destructive = false,
    this.badgeCount = 0,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final Color accent;
  final VoidCallback onTap;
  final bool destructive;
  final int badgeCount;

  @override
  Widget build(BuildContext context) {
    final isWhite = Theme.of(context).brightness == Brightness.light;
    final ink = isWhite ? AppColors.cFF101820 : AppColors.white;
    final sub = isWhite
        ? AppColors.cFF71808E
        : AppColors.white.withValues(alpha: .58);
    final textColor = destructive ? _ProfileColors.pink : ink;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Semantics(
        button: true,
        label: label,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: Container(
            height: 72,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: OheyThemedPanel.surfaceColor(isWhite: isWhite),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: isWhite
                    ? AppColors.cFFE1E8EF
                    : AppColors.white.withValues(alpha: .12),
                width: 1.4,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        accent.withValues(alpha: destructive ? .22 : .28),
                        accent.withValues(alpha: destructive ? .12 : .16),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(17),
                  ),
                  child: Center(
                    child: OheyPopIcon(
                      icon: icon,
                      color: accent,
                      size: 28,
                      showBubble: false,
                    ),
                  ),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: textColor,
                                fontSize: 15,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -.2,
                              ),
                            ),
                          ),
                          if (badgeCount > 0) ...[
                            const SizedBox(width: 8),
                            _SettingsTileBadge(
                              count: badgeCount,
                              accent: AppColors.cFFFF5F8F,
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: destructive
                              ? accent.withValues(alpha: .76)
                              : sub,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: isWhite
                        ? AppColors.cFFF3F6F9
                        : AppColors.white.withValues(alpha: .07),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: OheyGeneratedIcon(
                      CupertinoIcons.chevron_forward,
                      color: _ProfileColors.sub,
                      size: 18,
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

class _SettingsTileBadge extends StatelessWidget {
  const _SettingsTileBadge({required this.count, required this.accent});

  final int count;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final label = count > 99 ? '99+' : count.toString();
    return Container(
      constraints: const BoxConstraints(minWidth: 24, minHeight: 20),
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: accent,
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: .26),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: AppColors.white,
          fontSize: 10,
          height: 1,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _SheetPrimaryButton extends StatelessWidget {
  const _SheetPrimaryButton({
    required this.label,
    required this.busy,
    required this.onTap,
  });
  final String label;
  final bool busy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Ohey3DButton(
    label: label,
    onTap: busy ? null : onTap,
    isLoading: busy,
    enabled: !busy,
    height: 54,
    radius: 22,
    color: AppColors.primaryAction,
    foregroundColor: AppColors.white,
    shadowColor: AppColors.primaryActionShadow,
  );
}

part of 'profile_screen.dart';

class _AvatarEditCard extends StatelessWidget {
  const _AvatarEditCard({required this.avatar, required this.onTap});

  final NomoAvatar avatar;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isWhite = Theme.of(context).brightness == Brightness.light;
    final ink = isWhite ? const Color(0xFF101820) : Colors.white;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isWhite
              ? const Color(0xFFF6F8FA)
              : Colors.white.withValues(alpha: .05),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: isWhite ? const Color(0xFFDDE4EA) : _ProfileColors.line,
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
                  colors: [Color(0xFF223544), Color(0xFF101B28)],
                ),
              ),
              child: NomoAvatarView(avatar: avatar, size: 82),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
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
                          ? const Color(0xFF687481)
                          : Colors.white.withValues(alpha: .58),
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const NomoGeneratedIcon(
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

  final NomoUser? user;
  final List<Widget> children;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final isWhite = Theme.of(context).brightness == Brightness.light;
    final ink = isWhite ? const Color(0xFF111820) : Colors.white;
    final sub = isWhite
        ? const Color(0xFF66727E)
        : Colors.white.withValues(alpha: .62);
    final avatar = user?.avatar ?? NomoAvatar.defaultAvatar;
    final name = user?.name.trim().isNotEmpty == true
        ? user!.name
        : 'Nomo user';
    final handle = user?.userId.trim().isNotEmpty == true
        ? '@${user!.userId}'
        : 'プロフィール未設定';

    final maxHeight = MediaQuery.sizeOf(context).height * .88;
    return SafeArea(
      top: false,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxHeight),
          child: Container(
            margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isWhite
                    ? const [Color(0xFFFFFFFF), Color(0xFFF8FBFF)]
                    : const [Color(0xFF102436), Color(0xFF07131F)],
              ),
              borderRadius: BorderRadius.circular(34),
              border: Border.all(
                color: isWhite
                    ? const Color(0xFFE4EAF0)
                    : Colors.white.withValues(alpha: .10),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isWhite ? .14 : .34),
                  blurRadius: 34,
                  offset: const Offset(0, 16),
                ),
              ],
            ),
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
                            ? const Color(0xFFD8E0E8)
                            : Colors.white.withValues(alpha: .18),
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
                            const SizedBox(height: 4),
                            Text(
                              'Nomoを自分好みに整えよう',
                              style: TextStyle(
                                color: sub,
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                      _SettingsCloseButton(onTap: onClose, color: ink),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isWhite
                          ? const Color(0xFFF3F7FA)
                          : Colors.white.withValues(alpha: .055),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: isWhite
                            ? const Color(0xFFE0E7EE)
                            : Colors.white.withValues(alpha: .09),
                      ),
                    ),
                    child: Row(
                      children: [
                        NomoAvatarView(avatar: avatar, size: 52),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: ink,
                                  fontSize: 17,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                handle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: sub,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  ...children,
                ],
              ),
            ),
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
  Widget build(BuildContext context) => GestureDetector(
    behavior: HitTestBehavior.opaque,
    onTap: onTap,
    child: Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: color.withValues(alpha: .08),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: NomoGeneratedIcon(CupertinoIcons.xmark, color: color, size: 25),
      ),
    ),
  );
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.accent,
    required this.onTap,
    this.destructive = false,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final Color accent;
  final VoidCallback onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final isWhite = Theme.of(context).brightness == Brightness.light;
    final ink = isWhite ? const Color(0xFF101820) : Colors.white;
    final sub = isWhite
        ? const Color(0xFF71808E)
        : Colors.white.withValues(alpha: .58);
    final textColor = destructive ? _ProfileColors.pink : ink;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
        decoration: BoxDecoration(
          color: isWhite ? Colors.white : Colors.white.withValues(alpha: .055),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: isWhite
                ? const Color(0xFFE1E8EF)
                : Colors.white.withValues(alpha: .10),
            width: 1.4,
          ),
          boxShadow: isWhite
              ? [
                  BoxShadow(
                    color: accent.withValues(alpha: .07),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ]
              : null,
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
                child: NomoPopIcon(
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
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
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: destructive ? accent.withValues(alpha: .76) : sub,
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
                    ? const Color(0xFFF3F6F9)
                    : Colors.white.withValues(alpha: .07),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: NomoGeneratedIcon(
                  CupertinoIcons.chevron_forward,
                  color: _ProfileColors.sub,
                  size: 18,
                ),
              ),
            ),
          ],
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
  Widget build(BuildContext context) => GestureDetector(
    onTap: busy ? null : onTap,
    child: Container(
      height: 54,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.primaryAction,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: Colors.white.withValues(alpha: .16),
          width: 1.2,
        ),
        boxShadow: const [
          BoxShadow(
            color: AppColors.primaryActionShadow,
            offset: Offset(0, 7),
            blurRadius: 0,
          ),
        ],
      ),
      child: busy
          ? const CupertinoActivityIndicator(color: Colors.white)
          : Text(
              label,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w900,
              ),
            ),
    ),
  );
}

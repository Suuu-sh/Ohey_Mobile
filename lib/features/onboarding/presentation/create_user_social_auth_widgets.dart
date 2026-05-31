part of 'create_user_dialog.dart';

class _SocialLoginButton extends StatelessWidget {
  const _SocialLoginButton({
    required this.label,
    required this.mark,
    required this.onTap,
    this.height = 64,
  });

  final String label;
  final Widget mark;
  final VoidCallback onTap;
  final double height;

  @override
  Widget build(BuildContext context) => _Auth3DPanelButton(
    onTap: onTap,
    height: height,
    radius: 18,
    topColor: AppColors.cFF52606B,
    bottomColor: AppColors.cFF35434D,
    borderColor: AppColors.white.withValues(alpha: .18),
    glowColor: AppColors.cFF52606B.withValues(alpha: .18),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(width: 34, child: Center(child: mark)),
        const SizedBox(width: 14),
        Text(
          label,
          style: TextStyle(
            color: AppColors.white.withValues(alpha: .88),
            fontSize: 16,
            fontWeight: FontWeight.w900,
            letterSpacing: .6,
          ),
        ),
      ],
    ),
  );
}

class _SocialAuthButtons extends StatelessWidget {
  const _SocialAuthButtons({
    required this.intent,
    required this.height,
    required this.gap,
    required this.onTap,
  });

  final _SocialAuthIntent intent;
  final double height;
  final double gap;
  final Future<void> Function(OAuthProvider provider, String providerLabel)
  onTap;

  String get _actionLabel => intent == _SocialAuthIntent.signup ? '登録' : 'ログイン';

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _SocialLoginButton(
        label: 'GOOGLEで$_actionLabel',
        height: height,
        mark: const _GoogleMark(),
        onTap: () => onTap(OAuthProvider.google, 'Google'),
      ),
      SizedBox(height: gap),
      _SocialLoginButton(
        label: 'APPLEで$_actionLabel',
        height: height,
        mark: const _AppleMark(),
        onTap: () => onTap(OAuthProvider.apple, 'Apple'),
      ),
    ],
  );
}

class _Auth3DPanelButton extends StatelessWidget {
  const _Auth3DPanelButton({
    required this.child,
    required this.onTap,
    required this.height,
    required this.radius,
    required this.topColor,
    required this.bottomColor,
    required this.borderColor,
    required this.glowColor,
  });

  final Widget child;
  final VoidCallback onTap;
  final double height;
  final double radius;
  final Color topColor;
  final Color bottomColor;
  final Color borderColor;
  final Color glowColor;

  @override
  Widget build(BuildContext context) => Ohey3DButtonSurface(
    onTap: onTap,
    height: height,
    radius: radius,
    color: topColor,
    bottomColor: bottomColor,
    useGradient: false,
    borderColor: borderColor,
    borderWidth: 2,
    outerShadows: [
      BoxShadow(color: glowColor, blurRadius: 24, offset: const Offset(0, 12)),
      BoxShadow(
        color: AppColors.black.withValues(alpha: .16),
        blurRadius: 18,
        offset: const Offset(0, 9),
      ),
    ],
    innerShadows: [
      BoxShadow(
        color: AppColors.white.withValues(alpha: .08),
        blurRadius: 0,
        spreadRadius: -4,
        offset: const Offset(0, -5),
      ),
    ],
    child: child,
  );
}

class _GoogleMark extends StatelessWidget {
  const _GoogleMark();

  @override
  Widget build(BuildContext context) => const Text(
    'G',
    style: TextStyle(
      color: AppColors.cFF4285F4,
      fontSize: 27,
      fontWeight: FontWeight.w900,
    ),
  );
}

class _AppleMark extends StatelessWidget {
  const _AppleMark();

  @override
  Widget build(BuildContext context) =>
      const Icon(Icons.apple, color: AppColors.white, size: 35);
}

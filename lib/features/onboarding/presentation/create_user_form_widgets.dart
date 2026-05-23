part of 'create_user_dialog.dart';

class _SignupProfileTextField extends StatelessWidget {
  const _SignupProfileTextField({
    required this.controller,
    required this.enabled,
    required this.icon,
    required this.hintText,
    required this.onChanged,
    this.height = 64,
    this.textInputAction,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final bool enabled;
  final IconData icon;
  final String hintText;
  final ValueChanged<String> onChanged;
  final double height;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: height,
    child: Row(
      children: [
        const SizedBox(width: 20),
        NomoGeneratedIcon(icon, color: Colors.white.withValues(alpha: .82)),
        const SizedBox(width: 14),
        Expanded(
          child: TextField(
            controller: controller,
            enabled: enabled,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
            cursorColor: const Color(0xFF12C9A4),
            textInputAction: textInputAction,
            onChanged: onChanged,
            onSubmitted: onSubmitted,
            decoration: InputDecoration(
              filled: false,
              fillColor: Colors.transparent,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              disabledBorder: InputBorder.none,
              hintText: hintText,
              hintStyle: TextStyle(
                color: Colors.white.withValues(alpha: .34),
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
        const SizedBox(width: 20),
      ],
    ),
  );
}

class _SignupGenderSelector extends StatelessWidget {
  const _SignupGenderSelector({
    required this.selectedGender,
    required this.enabled,
    required this.compact,
    required this.onChanged,
  });

  final NomoGender selectedGender;
  final bool enabled;
  final bool compact;
  final ValueChanged<NomoGender> onChanged;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      for (var i = 0; i < selectableNomoGenders.length; i++) ...[
        Expanded(
          child: _SignupGenderOption(
            gender: selectableNomoGenders[i],
            selected: selectedGender == selectableNomoGenders[i],
            enabled: enabled,
            compact: compact,
            onTap: () => onChanged(selectableNomoGenders[i]),
          ),
        ),
        if (i != selectableNomoGenders.length - 1) const SizedBox(width: 10),
      ],
    ],
  );
}

class _SignupGenderOption extends StatelessWidget {
  const _SignupGenderOption({
    required this.gender,
    required this.selected,
    required this.enabled,
    required this.compact,
    required this.onTap,
  });

  final NomoGender gender;
  final bool selected;
  final bool enabled;
  final bool compact;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = gender == NomoGender.male
        ? const Color(0xFF18AFFF)
        : const Color(0xFFFF5AA6);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: enabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOutCubic,
        height: compact ? 48 : 58,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: selected
              ? accent.withValues(alpha: .92)
              : const Color(0xFF132630).withValues(alpha: .74),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected
                ? Colors.white.withValues(alpha: .26)
                : Colors.white.withValues(alpha: .18),
            width: 2,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: accent.withValues(alpha: .28),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            NomoGeneratedIcon(
              gender == NomoGender.male
                  ? CupertinoIcons.person_fill
                  : CupertinoIcons.person_crop_circle_fill,
              color: Colors.white,
              size: compact ? 18 : 20,
            ),
            const SizedBox(width: 8),
            Text(
              gender.label,
              style: TextStyle(
                color: Colors.white,
                fontSize: compact ? 15 : 17,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlainLoginTextField extends StatelessWidget {
  const _PlainLoginTextField({
    required this.controller,
    required this.enabled,
    required this.hintText,
    required this.onChanged,
    this.height = 64,
    this.keyboardType,
    this.textInputAction,
    this.autofillHints,
    this.obscureText = false,
    this.onSubmitted,
    this.trailing,
  });

  final TextEditingController controller;
  final bool enabled;
  final String hintText;
  final ValueChanged<String> onChanged;
  final double height;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;
  final bool obscureText;
  final ValueChanged<String>? onSubmitted;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: height,
    child: Row(
      children: [
        const SizedBox(width: 26),
        Expanded(
          child: TextField(
            controller: controller,
            enabled: enabled,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 19,
              fontWeight: FontWeight.w800,
            ),
            cursorColor: _authPink,
            keyboardType: keyboardType,
            textInputAction: textInputAction,
            autofillHints: autofillHints,
            obscureText: obscureText,
            onChanged: onChanged,
            onSubmitted: onSubmitted,
            decoration: InputDecoration(
              filled: false,
              fillColor: Colors.transparent,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              disabledBorder: InputBorder.none,
              hintText: hintText,
              hintStyle: TextStyle(
                color: Colors.white.withValues(alpha: .29),
                fontSize: 19,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: 8),
          trailing!,
          const SizedBox(width: 14),
        ] else
          const SizedBox(width: 26),
      ],
    ),
  );
}

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
    topColor: const Color(0xFF52606B),
    bottomColor: const Color(0xFF35434D),
    borderColor: Colors.white.withValues(alpha: .18),
    glowColor: const Color(0xFF52606B).withValues(alpha: .18),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(width: 34, child: Center(child: mark)),
        const SizedBox(width: 14),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: .88),
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
  Widget build(BuildContext context) => Nomo3DButtonSurface(
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
        color: Colors.black.withValues(alpha: .16),
        blurRadius: 18,
        offset: const Offset(0, 9),
      ),
    ],
    innerShadows: [
      BoxShadow(
        color: Colors.white.withValues(alpha: .08),
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
      color: Color(0xFF4285F4),
      fontSize: 27,
      fontWeight: FontWeight.w900,
    ),
  );
}

class _AppleMark extends StatelessWidget {
  const _AppleMark();

  @override
  Widget build(BuildContext context) =>
      const Icon(Icons.apple, color: Colors.white, size: 35);
}

class _DarkMessageText extends StatelessWidget {
  const _DarkMessageText(this.text, {this.isError = false});

  final String text;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final color = isError ? AppColors.coral : _authPink;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: .24)),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w900,
          height: 1.45,
        ),
      ),
    );
  }
}

bool _isValidUserId(String value) =>
    RegExp(r'^[a-zA-Z0-9_]{3,24}$').hasMatch(value);

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
        OheyGeneratedIcon(icon, color: Colors.white.withValues(alpha: .82)),
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

  final OheyGender selectedGender;
  final bool enabled;
  final bool compact;
  final ValueChanged<OheyGender> onChanged;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      for (var i = 0; i < selectableOheyGenders.length; i++) ...[
        Expanded(
          child: _SignupGenderOption(
            gender: selectableOheyGenders[i],
            selected: selectedGender == selectableOheyGenders[i],
            enabled: enabled,
            compact: compact,
            onTap: () => onChanged(selectableOheyGenders[i]),
          ),
        ),
        if (i != selectableOheyGenders.length - 1) const SizedBox(width: 10),
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

  final OheyGender gender;
  final bool selected;
  final bool enabled;
  final bool compact;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = gender == OheyGender.male
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
            OheyGeneratedIcon(
              gender == OheyGender.male
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

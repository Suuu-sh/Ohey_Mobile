part of 'create_user_dialog.dart';

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

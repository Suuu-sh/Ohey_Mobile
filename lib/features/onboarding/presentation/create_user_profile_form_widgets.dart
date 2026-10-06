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
        OheyGeneratedIcon(icon, color: AppColors.cFF777777),
        const SizedBox(width: 14),
        Expanded(
          child: TextField(
            controller: controller,
            enabled: enabled,
            style: const TextStyle(
              color: AppColors.cFF3C3C3C,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
            cursorColor: AppColors.cFF00CD9C,
            textInputAction: textInputAction,
            onChanged: onChanged,
            onSubmitted: onSubmitted,
            decoration: InputDecoration(
              filled: false,
              fillColor: AppColors.transparent,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              disabledBorder: InputBorder.none,
              hintText: hintText,
              hintStyle: TextStyle(
                color: AppColors.cFFAFAFAF,
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

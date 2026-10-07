part of 'profile_screen.dart';

InputDecoration _profileInputDecoration(
  String hint, {
  required bool isWhite,
}) => InputDecoration(
  hintText: hint,
  hintStyle: TextStyle(
    color: isWhite
        ? AppColors.cFFAFAFAF
        : AppColors.white.withValues(alpha: .45),
    fontWeight: FontWeight.w800,
  ),
  filled: true,
  fillColor: isWhite ? AppColors.cFFF7F7F7 : AppColors.cFF202F36,
  border: OutlineInputBorder(
    borderRadius: BorderRadius.circular(16),
    borderSide: BorderSide(
      color: isWhite ? AppColors.chunkyBorderLight : AppColors.chunkyBorderDark,
      width: 2,
    ),
  ),
  enabledBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(16),
    borderSide: BorderSide(
      color: isWhite ? AppColors.chunkyBorderLight : AppColors.chunkyBorderDark,
      width: 2,
    ),
  ),
  focusedBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(16),
    borderSide: const BorderSide(color: _ProfileColors.lime, width: 2),
  ),
);

void _showSnack(BuildContext context, String message) {
  OheyToast.show(context, message);
}

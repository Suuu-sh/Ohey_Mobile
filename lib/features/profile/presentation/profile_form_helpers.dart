part of 'profile_screen.dart';

InputDecoration _profileInputDecoration(String hint, {required bool isWhite}) =>
    InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        color: isWhite
            ? AppColors.cFF8B96A3
            : AppColors.white.withValues(alpha: .45),
        fontWeight: FontWeight.w800,
      ),
      filled: true,
      fillColor: isWhite
          ? AppColors.cFFF6F8FA
          : AppColors.white.withValues(alpha: .06),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(
          color: isWhite ? AppColors.cFFDDE4EA : _ProfileColors.line,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(
          color: isWhite ? AppColors.cFFDDE4EA : _ProfileColors.line,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: _ProfileColors.lime),
      ),
    );

void _showSnack(BuildContext context, String message) {
  OheyToast.show(context, message);
}

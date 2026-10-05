part of 'create_user_dialog.dart';

class _AccountChoiceHeader extends StatelessWidget {
  const _AccountChoiceHeader({required this.onBack});

  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 48,
    child: Align(
      alignment: Alignment.centerLeft,
      child: IconButton(
        onPressed: onBack,
        icon: Icon(
          CupertinoIcons.arrow_left,
          color: AppColors.white.withValues(alpha: .72),
          size: 31,
        ),
      ),
    ),
  );
}

class _AccountChoicePrimaryButton extends StatelessWidget {
  const _AccountChoicePrimaryButton({
    required this.label,
    required this.onTap,
    this.height = 64,
  });

  final String label;
  final VoidCallback onTap;
  final double height;

  @override
  Widget build(BuildContext context) => Ohey3DButton(
    label: label,
    onTap: onTap,
    height: height,
    radius: 18,
    color: _authPink,
    shadowColor: _authPinkShadow,
    foregroundColor: _authPinkInk,
    fontSize: 20,
  );
}

class _AccountChoiceOutlineButton extends StatelessWidget {
  const _AccountChoiceOutlineButton({
    required this.label,
    required this.onTap,
    this.height = 64,
  });

  final String label;
  final VoidCallback onTap;
  final double height;

  @override
  Widget build(BuildContext context) => _Auth3DPanelButton(
    onTap: onTap,
    height: height,
    radius: 18,
    topColor: AppColors.darkBackground,
    bottomColor: AppColors.chunkyBorderDark,
    borderColor: AppColors.chunkyBorderDark,
    child: Text(
      label,
      style: const TextStyle(
        color: _authPink,
        fontSize: 20,
        fontWeight: FontWeight.w900,
        letterSpacing: -.2,
      ),
    ),
  );
}

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

import 'tomo_3d_button.dart';

class TomoPrimaryButton extends StatelessWidget {
  const TomoPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Tomo3DButton(
      label: label,
      icon: icon,
      isLoading: isLoading,
      enabled: onPressed != null,
      onTap: onPressed,
      height: 58,
      radius: 24,
      color: AppColors.primaryAction,
      shadowColor: AppColors.primaryActionShadow,
      fontSize: 16,
    );
  }
}

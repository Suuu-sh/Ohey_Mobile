import 'package:flutter/material.dart';

import 'nomo_3d_button.dart';

class NomoPrimaryButton extends StatelessWidget {
  const NomoPrimaryButton({
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
    return Nomo3DButton(
      label: label,
      icon: icon,
      isLoading: isLoading,
      enabled: onPressed != null,
      onTap: onPressed,
      height: 58,
      radius: 24,
      color: const Color(0xFF12C9A4),
      shadowColor: const Color(0xFF079078),
      fontSize: 16,
    );
  }
}

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'ohey_3d_button.dart';
import 'ohey_bottom_sheet.dart';

class OheyYuruboCreateSheetLayout extends StatelessWidget {
  const OheyYuruboCreateSheetLayout({
    super.key,
    required this.wishSection,
    required this.titleInput,
    required this.placeInput,
    required this.dateOption,
    required this.visibilitySelector,
    required this.groupSelector,
    required this.submitLabel,
    required this.onSubmit,
    this.title = 'ゆるぼする',
    this.submitIcon,
    this.submitEnabled = true,
    this.buttonColor = AppColors.cFFC08BFF,
    this.buttonShadowColor = AppColors.cFF7F51C9,
  });

  final String title;
  final Widget wishSection;
  final Widget titleInput;
  final Widget placeInput;
  final Widget dateOption;
  final Widget visibilitySelector;
  final Widget groupSelector;
  final String submitLabel;
  final IconData? submitIcon;
  final bool submitEnabled;
  final VoidCallback onSubmit;
  final Color buttonColor;
  final Color buttonShadowColor;

  @override
  Widget build(BuildContext context) {
    final isWhite = Theme.of(context).brightness == Brightness.light;
    final ink = isWhite ? AppColors.cFF17212B : AppColors.white;
    return OheyBottomSheetShell(
      margin: const EdgeInsets.fromLTRB(14, 0, 14, 14),
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
      radius: 32,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: ink,
              fontSize: 22,
              fontWeight: FontWeight.w900,
              letterSpacing: -.6,
            ),
          ),
          const SizedBox(height: 14),
          wishSection,
          titleInput,
          const SizedBox(height: 10),
          placeInput,
          const SizedBox(height: 10),
          dateOption,
          const SizedBox(height: 14),
          visibilitySelector,
          groupSelector,
          const SizedBox(height: 16),
          Ohey3DButton(
            label: submitLabel,
            icon: submitIcon,
            onTap: submitEnabled ? onSubmit : null,
            height: 50,
            radius: 22,
            color: buttonColor,
            foregroundColor: AppColors.cFF101820,
            shadowColor: buttonShadowColor,
          ),
        ],
      ),
    );
  }
}

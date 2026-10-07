import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Neutral color roles that follow the current light/dark theme.
class OheyTone {
  OheyTone.of(BuildContext context)
    : isWhite = Theme.of(context).brightness == Brightness.light;

  final bool isWhite;

  Color get ink => isWhite ? AppColors.cFF3C3C3C : AppColors.white;
  Color get muted => isWhite ? AppColors.cFF777777 : AppColors.cFFAFAFAF;
  Color get faint => isWhite ? AppColors.cFFAFAFAF : AppColors.cFF777777;
  Color get page => isWhite ? AppColors.white : AppColors.darkBackground;
  Color get field => isWhite ? AppColors.cFFF7F7F7 : AppColors.cFF202F36;
  Color get edge =>
      isWhite ? AppColors.chunkyBorderLight : AppColors.chunkyBorderDark;
}

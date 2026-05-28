import 'package:flutter/material.dart';

class AppColors {
  const AppColors._();

  static const background = Color(0xFFF8F9FD);
  static const surface = Color(0xFFFFFFFF);
  static const ink = Color(0xFF2E2A35);
  static const mutedInk = Color(0xFF837A89);
  static const blush = Color(0xFFFFDDE8);
  static const peach = Color(0xFFFFD9B8);
  static const coral = Color(0xFFFF8FAB);
  static const sky = Color(0xFFD9F0FF);
  static const mint = Color(0xFFDDF7E8);
  static const lavender = Color(0xFFE9E1FF);
  static const lemon = Color(0xFFFFF2B8);
  static const lilac = Color(0xFFCDBDFF);
  static const orange = Color(0xFFFFB86B);
  static const blue = Color(0xFF78C7E8);
  static const green = Color(0xFF8AD9A6);
  static const rose = Color(0xFFFFA3B9);
  static const navy = Color(0xFF101A43);
  static const deepNavy = Color(0xFF071038);
  static const softBlue = Color(0xFFF1F6FF);
  static const softGray = Color(0xFFF8F9FD);
  static const line = Color(0xFFE9ECF5);
  static const amber = Color(0xFFF5B84B);
  static const darkBackground = Color(0xFF071320);
  static const darkBackgroundTop = darkBackground;
  static const darkBackgroundMiddle = darkBackground;
  static const darkBackgroundBottom = darkBackground;

  // Semantic colors. Keep playful tab/accent colors, but use these for actions
  // so users can learn what each color means across screens.
  static const primaryAction = coral;
  static const primaryActionShadow = Color(0xFFD95F80);
  static const success = Color(0xFF5FCB74);
  static const successShadow = Color(0xFF31964B);
  static const invite = Color(0xFF22D7C5);
  static const inviteShadow = Color(0xFF109F91);
  static const info = blue;
  static const warning = amber;
  static const danger = Color(0xFFFF5F8F);
  static const dangerShadow = Color(0xFFC9416D);

  static const pastelGradient = [blush, peach, sky];
  static const warmGradient = [Color(0xFFFFE7D6), Color(0xFFFFDDE8)];
  static const coolGradient = [Color(0xFFE5F6FF), Color(0xFFEDE7FF)];
  static const darkBackgroundGradient = [
    darkBackgroundTop,
    darkBackgroundMiddle,
    darkBackgroundBottom,
  ];
}

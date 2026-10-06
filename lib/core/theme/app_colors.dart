import 'package:flutter/material.dart';

class AppColors {
  const AppColors._();

  // Base Material colors used directly by widgets.
  static const transparent = Colors.transparent;
  static const white = Colors.white;
  static const black = Colors.black;
  static const white70 = Colors.white70;
  static const white60 = Colors.white60;
  static const white12 = Colors.white12;
  static const black87 = Colors.black87;
  static const black45 = Colors.black45;
  static const black38 = Colors.black38;

  // Raw palette: every concrete color used by the app lives here so it can be changed in one place.
  // Values follow a Duolingo-inspired chunky palette (bright brand hues with
  // darker "lip" shades, pure greys in white mode, slate greys in dark mode).
  static const c1EFFFFFF = Color(0x1EFFFFFF);
  static const c99131F24 = Color(0x99131F24);
  static const c99D9609F = Color(0x99D9609F);
  static const cFF00A47C = Color(0xFF00A47C);
  static const cFF00CD9C = Color(0xFF00CD9C);
  static const cFF0B5E86 = Color(0xFF0B5E86);
  static const cFF131F24 = Color(0xFF131F24);
  static const cFF1899D6 = Color(0xFF1899D6);
  static const cFF1A272D = Color(0xFF1A272D);
  static const cFF1CB0F6 = Color(0xFF1CB0F6);
  static const cFF202F36 = Color(0xFF202F36);
  static const cFF2B3A41 = Color(0xFF2B3A41);
  static const cFF37464F = Color(0xFF37464F);
  static const cFF3C3C3C = Color(0xFF3C3C3C);
  static const cFF3DDCB6 = Color(0xFF3DDCB6);
  static const cFF49C0F8 = Color(0xFF49C0F8);
  static const cFF4B4B4B = Color(0xFF4B4B4B);
  static const cFF58A700 = Color(0xFF58A700);
  static const cFF58CC02 = Color(0xFF58CC02);
  static const cFF5E3A7A = Color(0xFF5E3A7A);
  static const cFF6B2850 = Color(0xFF6B2850);
  static const cFF6E1515 = Color(0xFF6E1515);
  static const cFF777777 = Color(0xFF777777);
  static const cFF84D8FF = Color(0xFF84D8FF);
  static const cFF89E219 = Color(0xFF89E219);
  static const cFF8BEBD3 = Color(0xFF8BEBD3);
  static const cFFA568CC = Color(0xFFA568CC);
  static const cFFA5ED6E = Color(0xFFA5ED6E);
  static const cFFAFAFAF = Color(0xFFAFAFAF);
  static const cFFCD7900 = Color(0xFFCD7900);
  static const cFFCDCDCD = Color(0xFFCDCDCD);
  static const cFFCE82FF = Color(0xFFCE82FF);
  static const cFFD9609F = Color(0xFFD9609F);
  static const cFFD7FFB8 = Color(0xFFD7FFB8);
  static const cFFD99CFF = Color(0xFFD99CFF);
  static const cFFDDF4FF = Color(0xFFDDF4FF);
  static const cFFE3BDFF = Color(0xFFE3BDFF);
  static const cFFE5E5E5 = Color(0xFFE5E5E5);
  static const cFFEA2B2B = Color(0xFFEA2B2B);
  static const cFFF3E2FF = Color(0xFFF3E2FF);
  static const cFFF7F7F7 = Color(0xFFF7F7F7);
  static const cFFD62F7E = Color(0xFFD62F7E);
  static const cFFFF4B4B = Color(0xFFFF4B4B);
  static const cFFFF4B9E = Color(0xFFFF4B9E);
  static const cFFFFE3F0 = Color(0xFFFFE3F0);
  static const cFFFF7878 = Color(0xFFFF7878);
  static const cFFFF86C8 = Color(0xFFFF86C8);
  static const cFFFF9600 = Color(0xFFFF9600);
  static const cFFFF9FD3 = Color(0xFFFF9FD3);
  static const cFFFFA3A3 = Color(0xFFFFA3A3);
  static const cFFFFAB33 = Color(0xFFFFAB33);
  static const cFFFFB8DD = Color(0xFFFFB8DD);
  static const cFFFFC56B = Color(0xFFFFC56B);
  static const cFFFFC800 = Color(0xFFFFC800);
  static const cFFFFD43B = Color(0xFFFFD43B);
  static const cFFFFE066 = Color(0xFFFFE066);
  static const cFFFFE5F3 = Color(0xFFFFE5F3);
  static const cFFFFF0D5 = Color(0xFFFFF0D5);
  static const cFFFFF5D3 = Color(0xFFFFF5D3);
  static const cFFFFFFFF = Color(0xFFFFFFFF);

  static const background = cFFFFFFFF;
  static const surface = cFFFFFFFF;
  static const ink = cFF4B4B4B;
  static const mutedInk = cFF777777;
  static const blush = cFFFFE5F3;
  static const peach = cFFFFF0D5;
  static const coral = cFFFF86C8;
  static const sky = cFFDDF4FF;
  static const mint = cFFD7FFB8;
  static const lavender = cFFF3E2FF;
  static const lemon = cFFFFF5D3;
  static const lilac = cFFE3BDFF;
  static const orange = cFFFF9600;
  static const blue = cFF1CB0F6;
  static const green = cFF58CC02;
  static const rose = cFFFF9FD3;
  static const navy = cFF131F24;
  static const deepNavy = cFF131F24;
  static const softBlue = cFFDDF4FF;
  static const softGray = cFFF7F7F7;
  static const line = cFFE5E5E5;
  static const amber = cFFFFC800;
  static const darkBackground = cFF131F24;
  static const darkBackgroundTop = darkBackground;
  static const darkBackgroundMiddle = darkBackground;
  static const darkBackgroundBottom = darkBackground;

  // Duolingo-style chunky surfaces: a 2pt hairline plus a solid bottom lip.
  static const chunkyBorderLight = cFFE5E5E5;
  static const chunkyBorderDark = cFF37464F;

  // Ohey brand pink: the one accent for primary actions, selection and
  // navigation on every tab. Other hues are reserved for data (status).
  static const brand = cFFFF4B9E;
  static const brandLip = cFFD62F7E;
  static const brandTint = cFFFFE3F0;

  // Semantic colors.
  static const primaryAction = brand;
  static const primaryActionShadow = brandLip;
  static const success = cFF58CC02;
  static const successShadow = cFF58A700;
  static const invite = cFF00CD9C;
  static const inviteShadow = cFF00A47C;
  static const info = blue;
  static const warning = amber;
  static const danger = cFFFF4B4B;
  static const dangerShadow = cFFEA2B2B;

  static const pastelGradient = [blush, peach, sky];
  static const warmGradient = [cFFFFF0D5, cFFFFE5F3];
  static const coolGradient = [cFFF7F7F7, cFFF7F7F7];
  static const darkBackgroundGradient = [
    darkBackgroundTop,
    darkBackgroundMiddle,
    darkBackgroundBottom,
  ];
}

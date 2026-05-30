import 'package:flutter_riverpod/flutter_riverpod.dart';

enum OheyThemeMode { dark, white }

final oheyThemeModeProvider =
    NotifierProvider<OheyThemeModeController, OheyThemeMode>(
      OheyThemeModeController.new,
    );

class OheyThemeModeController extends Notifier<OheyThemeMode> {
  @override
  OheyThemeMode build() => OheyThemeMode.dark;

  void setMode(OheyThemeMode mode) => state = mode;

  void toggle() =>
      state = state.isWhite ? OheyThemeMode.dark : OheyThemeMode.white;
}

extension OheyThemeModeX on OheyThemeMode {
  bool get isWhite => this == OheyThemeMode.white;
  String get label => isWhite ? 'ホワイト' : 'ダーク';
}

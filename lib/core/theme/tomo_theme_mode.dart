import 'package:flutter_riverpod/flutter_riverpod.dart';

enum TomoThemeMode { dark, white }

final tomoThemeModeProvider =
    NotifierProvider<TomoThemeModeController, TomoThemeMode>(
      TomoThemeModeController.new,
    );

class TomoThemeModeController extends Notifier<TomoThemeMode> {
  @override
  TomoThemeMode build() => TomoThemeMode.dark;

  void setMode(TomoThemeMode mode) => state = mode;

  void toggle() =>
      state = state.isWhite ? TomoThemeMode.dark : TomoThemeMode.white;
}

extension TomoThemeModeX on TomoThemeMode {
  bool get isWhite => this == TomoThemeMode.white;
  String get label => isWhite ? 'ホワイト' : 'ダーク';
}

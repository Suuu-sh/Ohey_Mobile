import 'package:flutter_riverpod/flutter_riverpod.dart';

enum NomoThemeMode { dark, white }

final nomoThemeModeProvider =
    NotifierProvider<NomoThemeModeController, NomoThemeMode>(
      NomoThemeModeController.new,
    );

class NomoThemeModeController extends Notifier<NomoThemeMode> {
  @override
  NomoThemeMode build() => NomoThemeMode.dark;

  void setMode(NomoThemeMode mode) => state = mode;

  void toggle() =>
      state = state.isWhite ? NomoThemeMode.dark : NomoThemeMode.white;
}

extension NomoThemeModeX on NomoThemeMode {
  bool get isWhite => this == NomoThemeMode.white;
  String get label => isWhite ? 'ホワイト' : 'ダーク';
}

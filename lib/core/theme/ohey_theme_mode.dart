import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum OheyThemeMode { dark, white }

final oheyThemeModeProvider =
    NotifierProvider<OheyThemeModeController, OheyThemeMode>(
      OheyThemeModeController.new,
    );

/// Light is the default; the user's choice is remembered on the device.
class OheyThemeModeController extends Notifier<OheyThemeMode> {
  static const _prefsKey = 'ohey_theme_mode';
  static OheyThemeMode _saved = OheyThemeMode.white;

  /// Reads the saved mode before the first frame so dark-mode users never
  /// see a white flash. Call once from `main`.
  static Future<void> preload() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getString(_prefsKey) == OheyThemeMode.dark.name) {
        _saved = OheyThemeMode.dark;
      }
    } catch (_) {
      // Keep the default when preferences are unavailable.
    }
  }

  @override
  OheyThemeMode build() => _saved;

  void setMode(OheyThemeMode mode) {
    state = mode;
    _saved = mode;
    SharedPreferences.getInstance()
        .then((prefs) => prefs.setString(_prefsKey, mode.name))
        .catchError((_) => false);
  }

  void toggle() =>
      setMode(state.isWhite ? OheyThemeMode.dark : OheyThemeMode.white);
}

extension OheyThemeModeX on OheyThemeMode {
  bool get isWhite => this == OheyThemeMode.white;
  String get label => isWhite ? 'ライト' : 'ダーク';
}

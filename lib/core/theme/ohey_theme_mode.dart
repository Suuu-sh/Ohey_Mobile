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

  @override
  OheyThemeMode build() {
    _restore();
    return OheyThemeMode.white;
  }

  Future<void> _restore() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getString(_prefsKey) == OheyThemeMode.dark.name) {
        state = OheyThemeMode.dark;
      }
    } catch (_) {
      // Keep the default when preferences are unavailable.
    }
  }

  void setMode(OheyThemeMode mode) {
    state = mode;
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

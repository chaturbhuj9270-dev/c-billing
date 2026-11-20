import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../theme/brand_accent.dart';

// Persists and broadcasts ThemeMode + light accent palette.
class ThemeService extends ChangeNotifier {
  static const String _themeKey = 'selected_theme_mode';
  static const String _accentKey = 'selected_light_accent';
  static ThemeService? _instance;

  ThemeMode _themeMode = ThemeMode.system;
  AppAccentPalette _accent = AppAccentPalette.green;

  ThemeService._();

  static ThemeService get instance {
    _instance ??= ThemeService._();
    return _instance!;
  }

  ThemeMode get themeMode => _themeMode;

  AppAccentPalette get accent => _accent;

  BrandAccent get accentColors => BrandAccent.forPalette(_accent);

  bool get isDark {
    if (_themeMode == ThemeMode.dark) return true;
    if (_themeMode == ThemeMode.light) return false;
    return WidgetsBinding.instance.platformDispatcher.platformBrightness ==
        Brightness.dark;
  }

  String get modeLabel {
    switch (_themeMode) {
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
      case ThemeMode.system:
        return 'System';
    }
  }

  String get accentLabel => _accent.label;

  /// Compact trailing for the flyout menu.
  String get preferencesTrailing {
    if (isDark) return modeLabel;
    return '$modeLabel · $accentLabel';
  }

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_themeKey);
    _themeMode = _fromStorage(stored);
    _accent = AppAccentPaletteX.fromStorage(prefs.getString(_accentKey));
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;
    _themeMode = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeKey, _toStorage(mode));
    notifyListeners();
  }

  Future<void> setAccent(AppAccentPalette accent) async {
    if (_accent == accent) return;
    _accent = accent;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_accentKey, accent.storageKey);
    notifyListeners();
  }

  Future<void> toggleLightDark() async {
    await setThemeMode(isDark ? ThemeMode.light : ThemeMode.dark);
  }

  static ThemeMode _fromStorage(String? value) {
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
      default:
        return ThemeMode.system;
    }
  }

  static String _toStorage(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
    }
  }
}

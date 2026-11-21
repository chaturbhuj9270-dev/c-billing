import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../theme/brand_accent.dart';

// Persists and broadcasts ThemeMode + light accent palette.
class ThemeService extends ChangeNotifier {
  static const String _themeKey = 'selected_theme_mode';
  static const String _accentKey = 'selected_light_accent';
  static const String _customAccentKey = 'selected_light_accent_custom';
  static ThemeService? _instance;

  ThemeMode _themeMode = ThemeMode.system;
  AppAccentPalette _accent = AppAccentPalette.green;
  Color _customPrimary = BrandAccent.violet.primary;

  ThemeService._();

  static ThemeService get instance {
    _instance ??= ThemeService._();
    return _instance!;
  }

  ThemeMode get themeMode => _themeMode;

  AppAccentPalette get accent => _accent;

  Color get customPrimary => _customPrimary;

  BrandAccent get accentColors => BrandAccent.forPalette(
        _accent,
        customPrimary: _customPrimary,
      );

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

  String get accentLabel => _accent == AppAccentPalette.custom
      ? 'Custom'
      : _accent.label;

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
    final customValue = prefs.getInt(_customAccentKey);
    if (customValue != null) {
      _customPrimary = Color(customValue);
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;
    _themeMode = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeKey, _toStorage(mode));
    notifyListeners();
  }

  Future<void> setAccent(
    AppAccentPalette accent, {
    Color? customPrimary,
  }) async {
    final nextCustom = customPrimary ?? _customPrimary;
    if (_accent == accent &&
        (accent != AppAccentPalette.custom || nextCustom == _customPrimary)) {
      return;
    }
    _accent = accent;
    if (customPrimary != null) {
      _customPrimary = customPrimary;
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_accentKey, accent.storageKey);
    if (accent == AppAccentPalette.custom) {
      await prefs.setInt(_customAccentKey, _customPrimary.toARGB32());
    }
    notifyListeners();
  }

  /// Apply mode + accent together (theme dialog Apply).
  Future<void> applyPreferences({
    required ThemeMode mode,
    required AppAccentPalette accent,
    Color? customPrimary,
  }) async {
    final nextCustom = customPrimary ?? _customPrimary;
    final modeChanged = _themeMode != mode;
    final accentChanged = _accent != accent ||
        (accent == AppAccentPalette.custom && nextCustom != _customPrimary);
    if (!modeChanged && !accentChanged) return;

    _themeMode = mode;
    _accent = accent;
    if (customPrimary != null) {
      _customPrimary = customPrimary;
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeKey, _toStorage(mode));
    await prefs.setString(_accentKey, accent.storageKey);
    if (accent == AppAccentPalette.custom) {
      await prefs.setInt(_customAccentKey, _customPrimary.toARGB32());
    }
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

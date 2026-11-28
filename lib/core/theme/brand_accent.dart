import 'package:flutter/material.dart';

/// Selectable light-theme brand accents. Dark mode keeps its fixed palette.
enum AppAccentPalette {
  green,
  yellow,
  maroon,
  violet,
  purple,
  pink,
  orange,
  custom,
}

extension AppAccentPaletteX on AppAccentPalette {
  String get label {
    switch (this) {
      case AppAccentPalette.green:
        return 'Green';
      case AppAccentPalette.yellow:
        return 'Yellow';
      case AppAccentPalette.maroon:
        return 'Maroon';
      case AppAccentPalette.violet:
        return 'Violet';
      case AppAccentPalette.purple:
        return 'Purple';
      case AppAccentPalette.pink:
        return 'Pink';
      case AppAccentPalette.orange:
        return 'Orange';
      case AppAccentPalette.custom:
        return 'Custom';
    }
  }

  String get storageKey {
    switch (this) {
      case AppAccentPalette.green:
        return 'green';
      case AppAccentPalette.yellow:
        return 'yellow';
      case AppAccentPalette.maroon:
        return 'maroon';
      case AppAccentPalette.violet:
        return 'violet';
      case AppAccentPalette.purple:
        return 'purple';
      case AppAccentPalette.pink:
        return 'pink';
      case AppAccentPalette.orange:
        return 'orange';
      case AppAccentPalette.custom:
        return 'custom';
    }
  }

  /// Preset swatches shown in the theme picker (excludes custom "+").
  static const List<AppAccentPalette> presets = [
    AppAccentPalette.green,
    AppAccentPalette.yellow,
    AppAccentPalette.maroon,
    AppAccentPalette.violet,
    AppAccentPalette.purple,
    AppAccentPalette.pink,
    AppAccentPalette.orange,
  ];

  static AppAccentPalette fromStorage(String? value) {
    switch (value) {
      case 'yellow':
        return AppAccentPalette.yellow;
      case 'maroon':
        return AppAccentPalette.maroon;
      case 'violet':
        return AppAccentPalette.violet;
      case 'purple':
        return AppAccentPalette.purple;
      case 'pink':
        return AppAccentPalette.pink;
      case 'orange':
        return AppAccentPalette.orange;
      case 'custom':
        return AppAccentPalette.custom;
      case 'green':
      default:
        return AppAccentPalette.green;
    }
  }
}

/// Light-theme brand colors: Primary, Header start → end, Container.
@immutable
class BrandAccent extends ThemeExtension<BrandAccent> {
  final AppAccentPalette palette;
  final Color primary;
  final Color headerStart;
  final Color headerEnd;
  final Color container;

  const BrandAccent({
    required this.palette,
    required this.primary,
    required this.headerStart,
    required this.headerEnd,
    required this.container,
  });

  /// Mid shade used by existing gradients / ColorScheme.secondary.
  Color get primaryLight => headerStart;

  /// Deeper shade used by existing multi-stop gradients.
  Color get primaryDark => Color.lerp(headerStart, headerEnd, 0.55)!;

  /// Spec green — Primary `#17694A`, Header `#1E5E46→#143F30`, Container `#DDF1E6`.
  static const green = BrandAccent(
    palette: AppAccentPalette.green,
    primary: Color(0xFF17694A),
    headerStart: Color(0xFF1E5E46),
    headerEnd: Color(0xFF143F30),
    container: Color(0xFFDDF1E6),
  );

  /// Spec yellow — Primary `#8A6410`, Header `#8A6A12→#4D3A08`, Container `#F6EBCB`.
  static const yellow = BrandAccent(
    palette: AppAccentPalette.yellow,
    primary: Color(0xFF8A6410),
    headerStart: Color(0xFF8A6A12),
    headerEnd: Color(0xFF4D3A08),
    container: Color(0xFFF6EBCB),
  );

  /// Spec maroon — Primary `#6B1D2E`, Header `#5A1727→#2B0E15`, Container `#F1E4E7`.
  static const maroon = BrandAccent(
    palette: AppAccentPalette.maroon,
    primary: Color(0xFF6B1D2E),
    headerStart: Color(0xFF5A1727),
    headerEnd: Color(0xFF2B0E15),
    container: Color(0xFFF1E4E7),
  );

  /// Spec violet — Primary `#4A2FB3`, Header `#4A2FB3→#2A1A6B`, Container `#E9E4F8`.
  static const violet = BrandAccent(
    palette: AppAccentPalette.violet,
    primary: Color(0xFF4A2FB3),
    headerStart: Color(0xFF4A2FB3),
    headerEnd: Color(0xFF2A1A6B),
    container: Color(0xFFE9E4F8),
  );

  /// Spec purple — Primary `#7B2D8E`, Header `#6A2480→#3A1248`, Container `#F1E3F5`.
  static const purple = BrandAccent(
    palette: AppAccentPalette.purple,
    primary: Color(0xFF7B2D8E),
    headerStart: Color(0xFF6A2480),
    headerEnd: Color(0xFF3A1248),
    container: Color(0xFFF1E3F5),
  );

  /// Spec pink — Primary `#B82A66`, Header `#A22360→#5C1236`, Container `#FBE4EE`.
  static const pink = BrandAccent(
    palette: AppAccentPalette.pink,
    primary: Color(0xFFB82A66),
    headerStart: Color(0xFFA22360),
    headerEnd: Color(0xFF5C1236),
    container: Color(0xFFFBE4EE),
  );

  /// Orange — same shade roles as the documented presets (swatch in theme UI).
  static const orange = BrandAccent(
    palette: AppAccentPalette.orange,
    primary: Color(0xFFB54A0F),
    headerStart: Color(0xFFA0420D),
    headerEnd: Color(0xFF5C2508),
    container: Color(0xFFFCE8D6),
  );

  /// Build a full accent stack from a custom primary (WCAG-minded darkening).
  factory BrandAccent.fromPrimary(
    Color primary, {
    AppAccentPalette palette = AppAccentPalette.custom,
  }) {
    final hsl = HSLColor.fromColor(primary);
    final headerStart = hsl
        .withLightness((hsl.lightness * 0.92).clamp(0.05, 0.55))
        .toColor();
    final headerEnd = hsl
        .withLightness((hsl.lightness * 0.42).clamp(0.04, 0.35))
        .toColor();
    final container = hsl
        .withSaturation((hsl.saturation * 0.4).clamp(0.0, 0.55))
        .withLightness(0.93)
        .toColor();
    return BrandAccent(
      palette: palette,
      primary: primary,
      headerStart: headerStart,
      headerEnd: headerEnd,
      container: container,
    );
  }

  static BrandAccent forPalette(
    AppAccentPalette palette, {
    Color? customPrimary,
  }) {
    switch (palette) {
      case AppAccentPalette.green:
        return green;
      case AppAccentPalette.yellow:
        return yellow;
      case AppAccentPalette.maroon:
        return maroon;
      case AppAccentPalette.violet:
        return violet;
      case AppAccentPalette.purple:
        return purple;
      case AppAccentPalette.pink:
        return pink;
      case AppAccentPalette.orange:
        return orange;
      case AppAccentPalette.custom:
        return BrandAccent.fromPrimary(
          customPrimary ?? violet.primary,
        );
    }
  }

  static BrandAccent of(BuildContext context) {
    return Theme.of(context).extension<BrandAccent>() ?? green;
  }

  @override
  BrandAccent copyWith({
    AppAccentPalette? palette,
    Color? primary,
    Color? headerStart,
    Color? headerEnd,
    Color? container,
  }) {
    return BrandAccent(
      palette: palette ?? this.palette,
      primary: primary ?? this.primary,
      headerStart: headerStart ?? this.headerStart,
      headerEnd: headerEnd ?? this.headerEnd,
      container: container ?? this.container,
    );
  }

  @override
  BrandAccent lerp(ThemeExtension<BrandAccent>? other, double t) {
    if (other is! BrandAccent) return this;
    return BrandAccent(
      palette: t < 0.5 ? palette : other.palette,
      primary: Color.lerp(primary, other.primary, t)!,
      headerStart: Color.lerp(headerStart, other.headerStart, t)!,
      headerEnd: Color.lerp(headerEnd, other.headerEnd, t)!,
      container: Color.lerp(container, other.container, t)!,
    );
  }
}

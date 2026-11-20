import 'package:flutter/material.dart';

/// Selectable light-theme brand accents. Dark mode keeps its fixed palette.
enum AppAccentPalette {
  green,
  yellow,
  maroon,
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
    }
  }

  static AppAccentPalette fromStorage(String? value) {
    switch (value) {
      case 'yellow':
        return AppAccentPalette.yellow;
      case 'maroon':
        return AppAccentPalette.maroon;
      case 'green':
      default:
        return AppAccentPalette.green;
    }
  }
}

/// Light-theme brand colors with the same shade roles as the current green stack.
@immutable
class BrandAccent extends ThemeExtension<BrandAccent> {
  final AppAccentPalette palette;
  final Color primary;
  final Color primaryLight;
  final Color primaryDark;
  final Color headerEnd;

  const BrandAccent({
    required this.palette,
    required this.primary,
    required this.primaryLight,
    required this.primaryDark,
    required this.headerEnd,
  });

  /// Current app green (default).
  static const green = BrandAccent(
    palette: AppAccentPalette.green,
    primary: Color(0xFF1B4D3E), // AppTheme.greenPrimary
    primaryLight: Color(0xFF2E7D5B), // AppTheme.greenPrimaryLight
    primaryDark: Color(0xFF0F3B2F), // AppTheme.greenPrimaryDark
    headerEnd: Color(0xFF134E3A), // AppTheme.greenHeaderEnd
  );

  /// Gold / yellow — same depth structure as green, from brand gold family.
  static const yellow = BrandAccent(
    palette: AppAccentPalette.yellow,
    primary: Color(0xFF8B6914),
    primaryLight: Color(0xFFC9A84C),
    primaryDark: Color(0xFF5C4509),
    headerEnd: Color(0xFF6B5210),
  );

  /// Maroon — same shade roles as the green theme stack.
  static const maroon = BrandAccent(
    palette: AppAccentPalette.maroon,
    primary: Color(0xFF5C1A2A),
    primaryLight: Color(0xFF8B3A4A),
    primaryDark: Color(0xFF3A0F1A),
    headerEnd: Color(0xFF4A1522),
  );

  static BrandAccent forPalette(AppAccentPalette palette) {
    switch (palette) {
      case AppAccentPalette.green:
        return green;
      case AppAccentPalette.yellow:
        return yellow;
      case AppAccentPalette.maroon:
        return maroon;
    }
  }

  static BrandAccent of(BuildContext context) {
    return Theme.of(context).extension<BrandAccent>() ?? green;
  }

  @override
  BrandAccent copyWith({
    AppAccentPalette? palette,
    Color? primary,
    Color? primaryLight,
    Color? primaryDark,
    Color? headerEnd,
  }) {
    return BrandAccent(
      palette: palette ?? this.palette,
      primary: primary ?? this.primary,
      primaryLight: primaryLight ?? this.primaryLight,
      primaryDark: primaryDark ?? this.primaryDark,
      headerEnd: headerEnd ?? this.headerEnd,
    );
  }

  @override
  BrandAccent lerp(ThemeExtension<BrandAccent>? other, double t) {
    if (other is! BrandAccent) return this;
    return BrandAccent(
      palette: t < 0.5 ? palette : other.palette,
      primary: Color.lerp(primary, other.primary, t)!,
      primaryLight: Color.lerp(primaryLight, other.primaryLight, t)!,
      primaryDark: Color.lerp(primaryDark, other.primaryDark, t)!,
      headerEnd: Color.lerp(headerEnd, other.headerEnd, t)!,
    );
  }
}

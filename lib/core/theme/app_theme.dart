import 'package:flutter/material.dart';
import 'package:c_billing/core/theme/app_theme.dart';
import 'package:flutter/services.dart';

/// Brand-aligned light / dark [ThemeData] for C-Billing.
///
/// Dark theme standard: proper black & white (neutral greys only).
/// Brand green is reserved for accents (app bar, FAB, primary actions).
class AppTheme {
  AppTheme._();

  static const Color primary = Color(0xFF1B4D3E);
  static const Color primaryLight = Color(0xFF2E7D5B);
  static const Color primaryDark = Color(0xFF0F3B2F);

  // Light
  static const Color lightScaffold = Color(0xFFF5F7F6);

  // Dark — neutral black / white (no green tint)
  static const Color darkScaffold = Color(0xFF000000);
  static const Color darkSurface = Color(0xFF111111);
  static const Color darkCard = Color(0xFF1A1A1A);
  static const Color darkElevated = Color(0xFF242424);
  static const Color darkBorder = Color(0xFF2E2E2E);
  static const Color darkTextPrimary = Color(0xFFFFFFFF);
  static const Color darkTextSecondary = Color(0xFFB3B3B3);
  static const Color darkTextMuted = Color(0xFF8A8A8A);

  static ThemeData get light {
    final scheme = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: Brightness.light,
      primary: primary,
      secondary: primaryLight,
      surface: Colors.white,
    );

    return _base(
      brightness: Brightness.light,
      scheme: scheme,
      scaffold: lightScaffold,
      card: Colors.white,
      divider: Colors.grey.shade200,
      overlayStyle: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: lightScaffold,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );
  }

  static ThemeData get dark {
    // Explicit neutral ColorScheme — avoids green-tinted surfaces from seed.
    const scheme = ColorScheme(
      brightness: Brightness.dark,
      primary: primaryLight,
      onPrimary: Colors.white,
      secondary: Color(0xFFE5E5E5),
      onSecondary: Colors.black,
      error: Color(0xFFEF5350),
      onError: Colors.white,
      surface: darkSurface,
      onSurface: darkTextPrimary,
      surfaceContainerHighest: darkElevated,
      outline: darkBorder,
      outlineVariant: Color(0xFF3A3A3A),
    );

    return _base(
      brightness: Brightness.dark,
      scheme: scheme,
      scaffold: darkScaffold,
      card: darkCard,
      divider: darkBorder,
      overlayStyle: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: darkScaffold,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );
  }

  static ThemeData _base({
    required Brightness brightness,
    required ColorScheme scheme,
    required Color scaffold,
    required Color card,
    required Color divider,
    required SystemUiOverlayStyle overlayStyle,
  }) {
    final isDark = brightness == Brightness.dark;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      fontFamily: 'Literata',
      colorScheme: scheme,
      scaffoldBackgroundColor: scaffold,
      canvasColor: scaffold,
      cardColor: card,
      dividerColor: divider,
      primaryColor: isDark ? primaryLight : primary,
      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: false,
        // Dark: black app bar for clean B&W; light keeps brand green.
        backgroundColor: isDark ? darkScaffold : primary,
        foregroundColor: Colors.white,
        systemOverlayStyle: overlayStyle,
        titleTextStyle: const TextStyle(
          fontFamily: 'Literata',
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      cardTheme: CardThemeData(
        color: card,
        elevation: isDark ? 0 : 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: isDark
              ? const BorderSide(color: darkBorder, width: 1)
              : BorderSide.none,
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: isDark ? darkElevated : card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: isDark ? darkElevated : card,
        modalBackgroundColor: isDark ? darkElevated : card,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: isDark ? darkElevated : primary,
        contentTextStyle: const TextStyle(
          fontFamily: 'Literata',
          color: Colors.white,
        ),
        behavior: SnackBarBehavior.floating,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: isDark ? Colors.white : primary,
        foregroundColor: isDark ? Colors.black : Colors.white,
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: isDark ? darkElevated : card,
        textStyle: TextStyle(
          fontFamily: 'Literata',
          color: isDark ? darkTextPrimary : const Color(0xFF1A1A1A),
        ),
      ),
      drawerTheme: DrawerThemeData(
        backgroundColor: isDark ? darkCard : card,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return isDark ? Colors.white : primaryLight;
          }
          return isDark ? Colors.grey.shade500 : Colors.grey.shade50;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return isDark
                ? Colors.white.withValues(alpha: 0.35)
                : primaryLight.withValues(alpha: 0.45);
          }
          return isDark ? Colors.white24 : Colors.black12;
        }),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: isDark ? darkTextSecondary : Colors.grey.shade700,
        textColor: isDark ? darkTextPrimary : Colors.black87,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? darkElevated : Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDark ? Colors.white : primary,
            width: 1.5,
          ),
        ),
      ),
      dividerTheme: DividerThemeData(color: divider, thickness: 1),
      iconTheme: IconThemeData(
        color: isDark ? darkTextSecondary : Colors.grey.shade700,
      ),
      textTheme: _textTheme(isDark),
    );
  }

  static TextTheme _textTheme(bool isDark) {
    final primaryText = isDark ? darkTextPrimary : const Color(0xFF1A1A1A);
    final secondaryText = isDark ? darkTextSecondary : Colors.grey.shade700;

    return TextTheme(
      bodyLarge: TextStyle(color: primaryText, fontFamily: 'Literata'),
      bodyMedium: TextStyle(color: primaryText, fontFamily: 'Literata'),
      bodySmall: TextStyle(color: secondaryText, fontFamily: 'Literata'),
      titleLarge: TextStyle(
        color: primaryText,
        fontFamily: 'Literata',
        fontWeight: FontWeight.w700,
      ),
      titleMedium: TextStyle(
        color: primaryText,
        fontFamily: 'Literata',
        fontWeight: FontWeight.w600,
      ),
      titleSmall: TextStyle(color: secondaryText, fontFamily: 'Literata'),
      labelLarge: TextStyle(color: primaryText, fontFamily: 'Literata'),
    );
  }
}

/// Convenience tokens that resolve from the current [BuildContext] theme.
class AppColors {
  AppColors._();

  static bool isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  static Color scaffold(BuildContext context) =>
      Theme.of(context).scaffoldBackgroundColor;

  static Color surface(BuildContext context) =>
      Theme.of(context).colorScheme.surface;

  static Color card(BuildContext context) => Theme.of(context).cardColor;

  static Color primaryText(BuildContext context) => isDark(context)
      ? AppTheme.darkTextPrimary
      : const Color(0xFF1A1A1A);

  static Color secondaryText(BuildContext context) => isDark(context)
      ? AppTheme.darkTextSecondary
      : Colors.grey.shade700;

  static Color mutedText(BuildContext context) =>
      isDark(context) ? AppTheme.darkTextMuted : Colors.grey.shade500;

  static Color border(BuildContext context) => isDark(context)
      ? AppTheme.darkBorder
      : Colors.grey.withValues(alpha: 0.2);

  static Color inputFill(BuildContext context) =>
      isDark(context) ? AppTheme.darkElevated : Colors.white;

  static Color chipFill(BuildContext context) => isDark(context)
      ? const Color(0xFF2A2A2A)
      : Colors.grey.withValues(alpha: 0.08);

  static Color glassFill(BuildContext context) => isDark(context)
      ? const Color(0xFF1A1A1A).withValues(alpha: 0.92)
      : Colors.white.withValues(alpha: 0.82);

  static Color glassFillSecondary(BuildContext context) => isDark(context)
      ? const Color(0xFF242424).withValues(alpha: 0.95)
      : const Color(0xFFE8F0F5).withValues(alpha: 0.72);

  static Color glassBorder(BuildContext context) => isDark(context)
      ? Colors.white.withValues(alpha: 0.14)
      : Colors.white.withValues(alpha: 0.85);

  static Color divider(BuildContext context) => Theme.of(context).dividerColor;

  static Color shadow(BuildContext context) =>
      Colors.black.withValues(alpha: isDark(context) ? 0.55 : 0.06);

  /// Page/section header gradient — brand green in light, pure B&W in dark.
  static List<Color> headerGradient(BuildContext context) => isDark(context)
      ? const [Color(0xFF000000), Color(0xFF1A1A1A), Color(0xFF000000)]
      : const [Color(0xFF1B4D3E), Color(0xFF0F3B2F), Color(0xFF134E3A)];

  /// Selected / primary chip fill in dark = white; light = brand green.
  static Color selectedFill(BuildContext context) =>
      isDark(context) ? Colors.white : AppTheme.primary;

  static Color selectedOnFill(BuildContext context) =>
      isDark(context) ? Colors.black : Colors.white;

  /// Icon / label accent — brand green in light, white in dark (B&W).
  static Color accent(BuildContext context) =>
      isDark(context) ? Colors.white : AppTheme.primary;

  /// Soft accent wash behind icons/chips.
  static Color accentSoft(BuildContext context, [double alpha = 0.12]) =>
      isDark(context)
          ? Colors.white.withValues(alpha: alpha)
          : AppTheme.primary.withValues(alpha: alpha);

  /// On-gradient / on-colored-card text (always light for contrast).
  static Color onAccent(BuildContext context) => Colors.white;

  /// Subtle on-gradient secondary text.
  static Color onAccentMuted(BuildContext context) =>
      Colors.white.withValues(alpha: isDark(context) ? 0.72 : 0.85);

  /// Neutral metric-card gradients for dark theme (pure greyscale).
  static List<Color> darkMetricGradient(int index) {
    const pairs = <List<Color>>[
      [Color(0xFF2E2E2E), Color(0xFF141414)],
      [Color(0xFF3A3A3A), Color(0xFF1A1A1A)],
      [Color(0xFF242424), Color(0xFF0D0D0D)],
      [Color(0xFF333333), Color(0xFF111111)],
    ];
    return pairs[index % pairs.length];
  }
}

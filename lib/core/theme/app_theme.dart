import 'package:flutter/material.dart';
import 'package:c_billing/core/theme/app_theme.dart';
import 'package:flutter/services.dart';

/// Shared palette from the billing / purchase screens.
///
/// Dark surfaces are green-charcoal. Mint is the action color.
/// Icon tones (blue, amber, rose) mark categories.
class AppTheme {
  AppTheme._();

  static const Color primary = Color(0xFF1B4D3E);
  static const Color primaryLight = Color(0xFF2E7D5B);
  static const Color primaryDark = Color(0xFF0F3B2F);

  /// Bright mint used for primary actions, selected tabs, and positive status.
  static const Color mint = Color(0xFF3DDC97);

  /// Text and icons that sit on [mint].
  static const Color onMint = Color(0xFF06281C);

  // Category icon tones from the reference screens.
  static const Color toneBlue = Color(0xFF7C8CFF);
  static const Color toneAmber = Color(0xFFE0A85C);
  static const Color toneRose = Color(0xFFE57373);
  static const Color toneViolet = Color(0xFFB388FF);
  static const Color toneCyan = Color(0xFF4DD0E1);

  // Light
  static const Color lightScaffold = Color(0xFFF3F6F4);

  // Dark — green charcoal, matching the billing and purchase screens.
  static const Color darkScaffold = Color(0xFF101412);
  static const Color darkSurface = Color(0xFF161C19);
  static const Color darkCard = Color(0xFF1A211E);
  static const Color darkElevated = Color(0xFF232B27);
  static const Color darkBorder = Color(0xFF2E3833);
  static const Color darkTextPrimary = Color(0xFFF4F7F5);
  static const Color darkTextSecondary = Color(0xFFA8B2AC);
  static const Color darkTextMuted = Color(0xFF7E8A84);

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
      primary: mint,
      onPrimary: onMint,
      secondary: toneBlue,
      onSecondary: Colors.white,
      error: Color(0xFFEF5350),
      onError: Colors.white,
      surface: darkSurface,
      onSurface: darkTextPrimary,
      surfaceContainerHighest: darkElevated,
      outline: darkBorder,
      outlineVariant: Color(0xFF3A4540),
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
      primaryColor: isDark ? mint : primary,
      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: false,
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
        backgroundColor: mint,
        foregroundColor: onMint,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: isDark ? mint : primary,
          foregroundColor: isDark ? onMint : Colors.white,
          disabledBackgroundColor: isDark ? darkElevated : Colors.grey.shade300,
          disabledForegroundColor: isDark
              ? darkTextMuted
              : Colors.grey.shade600,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: mint,
          foregroundColor: onMint,
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: isDark ? darkElevated : card,
        textStyle: TextStyle(
          fontFamily: 'Literata',
          color: isDark ? darkTextPrimary : const Color(0xFF1A1A1A),
        ),
      ),
      drawerTheme: DrawerThemeData(backgroundColor: isDark ? darkCard : card),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return isDark ? onMint : mint;
          }
          return isDark ? Colors.grey.shade500 : Colors.grey.shade50;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return isDark ? mint : primaryLight.withValues(alpha: 0.45);
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
          borderSide: BorderSide(color: isDark ? mint : primary, width: 1.5),
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

  static Color primaryText(BuildContext context) =>
      isDark(context) ? AppTheme.darkTextPrimary : const Color(0xFF1A1A1A);

  static Color secondaryText(BuildContext context) =>
      isDark(context) ? AppTheme.darkTextSecondary : Colors.grey.shade700;

  static Color mutedText(BuildContext context) =>
      isDark(context) ? AppTheme.darkTextMuted : Colors.grey.shade500;

  static Color border(BuildContext context) => isDark(context)
      ? AppTheme.darkBorder
      : Colors.grey.withValues(alpha: 0.2);

  static Color inputFill(BuildContext context) =>
      isDark(context) ? AppTheme.darkElevated : Colors.white;

  static Color chipFill(BuildContext context) => isDark(context)
      ? AppTheme.darkElevated
      : Colors.grey.withValues(alpha: 0.08);

  static Color glassFill(BuildContext context) => isDark(context)
      ? AppTheme.darkCard.withValues(alpha: 0.96)
      : Colors.white.withValues(alpha: 0.82);

  static Color glassFillSecondary(BuildContext context) => isDark(context)
      ? AppTheme.darkElevated.withValues(alpha: 0.96)
      : const Color(0xFFE8F0F5).withValues(alpha: 0.72);

  static Color glassBorder(BuildContext context) => isDark(context)
      ? Colors.white.withValues(alpha: 0.14)
      : Colors.white.withValues(alpha: 0.85);

  static Color divider(BuildContext context) => Theme.of(context).dividerColor;

  static Color shadow(BuildContext context) =>
      Colors.black.withValues(alpha: isDark(context) ? 0.55 : 0.06);

  /// Deep green bar. Dark enough for light labels, tinted to match the screens.
  static List<Color> headerGradient(BuildContext context) => isDark(context)
      ? const [Color(0xFF14352C), Color(0xFF0E241C), Color(0xFF10241C)]
      : const [Color(0xFF1B4D3E), Color(0xFF0F3B2F), Color(0xFF134E3A)];

  /// Selected chips and the active tab use mint in both themes.
  static Color selectedFill(BuildContext context) => AppTheme.mint;

  static Color selectedOnFill(BuildContext context) => AppTheme.onMint;

  /// Emphasis color. Dark titles stay light; actions use [mint].
  static Color accent(BuildContext context) =>
      isDark(context) ? AppTheme.darkTextPrimary : AppTheme.primary;

  /// Mint action color shared by buttons, tabs, and status labels.
  static Color mint(BuildContext context) => AppTheme.mint;

  static Color onMint(BuildContext context) => AppTheme.onMint;

  /// Soft accent wash behind icons/chips.
  static Color accentSoft(BuildContext context, [double alpha = 0.12]) =>
      isDark(context)
      ? AppTheme.mint.withValues(alpha: alpha)
      : AppTheme.primary.withValues(alpha: alpha);

  /// On-gradient / on-colored-card text (always light for contrast).
  static Color onAccent(BuildContext context) => Colors.white;

  /// Subtle on-gradient secondary text.
  static Color onAccentMuted(BuildContext context) =>
      Colors.white.withValues(alpha: isDark(context) ? 0.72 : 0.85);

  /// Metric-card gradients in the same green-charcoal family.
  static List<Color> darkMetricGradient(int index) {
    const pairs = <List<Color>>[
      [Color(0xFF24302B), Color(0xFF141A17)],
      [Color(0xFF1E2A32), Color(0xFF14181C)],
      [Color(0xFF2A261C), Color(0xFF16140F)],
      [Color(0xFF2A2228), Color(0xFF161214)],
    ];
    return pairs[index % pairs.length];
  }
}

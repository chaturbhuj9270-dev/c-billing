import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Shared palette from the billing / purchase screens.
///
/// Dark surfaces are green-charcoal. Primary green is the action color.
/// Icon tones (blue, amber, rose) mark categories.
class AppTheme {
  AppTheme._();

  static const Color primary = Color(0xFF1B4D3E);
  static const Color primaryLight = Color(0xFF2E7D5B);
  static const Color primaryDark = Color(0xFF0F3B2F);

  // Category icon tones from the reference screens.
  static const Color toneBlue = Color(0xFF7C8CFF);
  static const Color toneAmber = Color(0xFFE0A85C);
  static const Color toneRose = Color(0xFFE57373);
  static const Color toneViolet = Color(0xFFB388FF);
  static const Color toneCyan = Color(0xFF4DD0E1);

  // Light
  static const Color lightScaffold = Color(0xFFF3F6F4);

  // Dark — sampled from the Add purchase screen.
  // Page is near-black, cards sit one step above it, fields sink back to the page.
  static const Color darkScaffold = Color(0xFF080C0C);
  static const Color darkSurface = Color(0xFF101412);
  static const Color darkCard = Color(0xFF131715);
  static const Color darkElevated = Color(0xFF131715);
  static const Color darkBorder = Color(0xFF2A3330);
  static const Color darkTextPrimary = Color(0xFFF2F5F3);
  static const Color darkTextSecondary = Color(0xFF87928C);
  static const Color darkTextMuted = Color(0xFF6A756F);

  /// Filled buttons and selected chips in dark theme.
  static const Color darkAction = Color(0xFF3B6C4F);

  /// Icons and outline rings in dark theme (the green plus buttons).
  static const Color darkActionBright = Color(0xFF5CAF7F);

  // Shared palette. Every screen color is declared here.
  static const Color amber = Color(0xFFFFC107);
  static const Color amber200 = Color(0xFFFFE082);
  static const Color amber300 = Color(0xFFFFD54F);
  static const Color amber400 = Color(0xFFFFCA28);
  static const Color amber50 = Color(0xFFFFF8E1);
  static const Color amber600 = Color(0xFFFFB300);
  static const Color amber700 = Color(0xFFFFA000);
  static const Color amber800 = Color(0xFFFF8F00);
  static const Color amber900 = Color(0xFFFF6F00);
  static const Color black = Color(0xFF000000);
  static const Color black12 = Color(0x1F000000);
  static const Color black87 = Color(0xDD000000);
  static const Color blue = Color(0xFF2196F3);
  static const Color blue200 = Color(0xFF90CAF9);
  static const Color blue300 = Color(0xFF64B5F6);
  static const Color blue400 = Color(0xFF42A5F5);
  static const Color blue50 = Color(0xFFE3F2FD);
  static const Color blue600 = Color(0xFF1E88E5);
  static const Color blue700 = Color(0xFF1976D2);
  static const Color blue800 = Color(0xFF1565C0);
  static const Color blueGrey400 = Color(0xFF78909C);
  static const Color coral = Color(0xFFFF6B6B);
  static const Color cyan = Color(0xFF00BCD4);
  static const Color cyan400 = Color(0xFF26C6DA);
  static const Color cyan600 = Color(0xFF00ACC1);
  static const Color cyan700 = Color(0xFF0097A7);
  static const Color darkOutline = Color(0xFF2A3330);
  static const Color deepOrange = Color(0xFFFF5722);
  static const Color deepOrange300 = Color(0xFFFF8A65);
  static const Color deepOrange400 = Color(0xFFFF7043);
  static const Color deepPurple200 = Color(0xFFB39DDB);
  static const Color deepPurple300 = Color(0xFF9575CD);
  static const Color deepPurple400 = Color(0xFF7E57C2);
  static const Color deepPurple600 = Color(0xFF5E35B1);
  static const Color error = Color(0xFFEF5350);
  static const Color glassMist = Color(0xFFE8F0F5);
  static const Color green = Color(0xFF4CAF50);
  static const Color green100 = Color(0xFFC8E6C9);
  static const Color green200 = Color(0xFFA5D6A7);
  static const Color green300 = Color(0xFF81C784);
  static const Color green400 = Color(0xFF66BB6A);
  static const Color green50 = Color(0xFFE8F5E9);
  static const Color green600 = Color(0xFF43A047);
  static const Color green700 = Color(0xFF388E3C);
  static const Color green800 = Color(0xFF2E7D32);
  static const Color green900 = Color(0xFF1B5E20);
  static const Color greenAccent = Color(0xFF69F0AE);
  static const Color grey = Color(0xFF9E9E9E);
  static const Color grey100 = Color(0xFFF5F5F5);
  static const Color grey200 = Color(0xFFEEEEEE);
  static const Color grey300 = Color(0xFFE0E0E0);
  static const Color grey400 = Color(0xFFBDBDBD);
  static const Color grey50 = Color(0xFFFAFAFA);
  static const Color grey600 = Color(0xFF757575);
  static const Color grey700 = Color(0xFF616161);
  static const Color grey800 = Color(0xFF424242);
  static const Color grey900 = Color(0xFF212121);
  static const Color headerDarkEnd = Color(0xFF10241C);
  static const Color headerDarkMid = Color(0xFF0E241C);
  static const Color headerDarkStart = Color(0xFF14352C);
  static const Color headerLightEnd = Color(0xFF134E3A);
  static const Color indigo400 = Color(0xFF5C6BC0);
  static const Color ink = Color(0xFF1A1A2E);
  static const Color lightBlue300 = Color(0xFF4FC3F7);
  static const Color lightBlue800 = Color(0xFF0277BD);
  static const Color lightGreen = Color(0xFF8BC34A);
  static const Color lightText = Color(0xFF1A1A1A);
  static const Color metricAmberEnd = Color(0xFF16140F);
  static const Color metricAmberStart = Color(0xFF2A261C);
  static const Color metricBlueEnd = Color(0xFF14181C);
  static const Color metricBlueStart = Color(0xFF1E2A32);
  static const Color metricGreenEnd = Color(0xFF141A17);
  static const Color metricGreenStart = Color(0xFF24302B);
  static const Color metricRoseEnd = Color(0xFF161214);
  static const Color metricRoseStart = Color(0xFF2A2228);
  static const Color orange = Color(0xFFFF9800);
  static const Color orange100 = Color(0xFFFFE0B2);
  static const Color orange200 = Color(0xFFFFCC80);
  static const Color orange300 = Color(0xFFFFB74D);
  static const Color orange400 = Color(0xFFFFA726);
  static const Color orange50 = Color(0xFFFFF3E0);
  static const Color orange600 = Color(0xFFFB8C00);
  static const Color orange700 = Color(0xFFF57C00);
  static const Color orange800 = Color(0xFFEF6C00);
  static const Color orange900 = Color(0xFFE65100);
  static const Color orangeAccent = Color(0xFFFFAB40);
  static const Color pink = Color(0xFFE91E63);
  static const Color purple = Color(0xFF9C27B0);
  static const Color purple300 = Color(0xFFBA68C8);
  static const Color purple50 = Color(0xFFF3E5F5);
  static const Color purple700 = Color(0xFF7B1FA2);
  static const Color red = Color(0xFFF44336);
  static const Color red100 = Color(0xFFFFCDD2);
  static const Color red200 = Color(0xFFEF9A9A);
  static const Color red50 = Color(0xFFFFEBEE);
  static const Color red600 = Color(0xFFE53935);
  static const Color red700 = Color(0xFFD32F2F);
  static const Color red800 = Color(0xFFC62828);
  static const Color teal = Color(0xFF009688);
  static const Color teal400 = Color(0xFF26A69A);
  static const Color teal600 = Color(0xFF00897B);
  static const Color teal900 = Color(0xFF004D40);
  static const Color transparent = Color(0x00000000);
  static const Color white = Color(0xFFFFFFFF);
  static const Color white24 = Color(0x3DFFFFFF);
  static const Color white54 = Color(0x8AFFFFFF);
  static const Color white60 = Color(0x99FFFFFF);
  static const Color white70 = Color(0xB3FFFFFF);
  static const Color yellow900 = Color(0xFFF57F17);
  static const Color palette261B4D3E = Color(0x261B4D3E);
  static const Color palette33FFFFFF = Color(0x33FFFFFF);
  static const Color palette4D1B4D3E = Color(0x4D1B4D3E);
  static const Color paletteBFFFFFFF = Color(0xBFFFFFFF);
  static const Color paletteCCF8FFFC = Color(0xCCF8FFFC);
  static const Color paletteCCFFFFFF = Color(0xCCFFFFFF);
  static const Color paletteD9FFFFFF = Color(0xD9FFFFFF);
  static const Color paletteFF070908 = Color(0xFF070908);
  static const Color paletteFF0D2B20 = Color(0xFF0D2B20);
  static const Color paletteFF0E0E0E = Color(0xFF0E0E0E);
  static const Color paletteFF0E1C17 = Color(0xFF0E1C17);
  static const Color paletteFF121816 = Color(0xFF121816);
  static const Color paletteFF146B45 = Color(0xFF146B45);
  static const Color paletteFF161A18 = Color(0xFF161A18);
  static const Color paletteFF163028 = Color(0xFF163028);
  static const Color paletteFF16382C = Color(0xFF16382C);
  static const Color paletteFF171918 = Color(0xFF171918);
  static const Color paletteFF185C37 = Color(0xFF185C37);
  static const Color paletteFF1A1C1B = Color(0xFF1A1C1B);
  static const Color paletteFF1A1F1C = Color(0xFF1A1F1C);
  static const Color paletteFF1A2332 = Color(0xFF1A2332);
  static const Color paletteFF1A2438 = Color(0xFF1A2438);
  static const Color paletteFF1A3A30 = Color(0xFF1A3A30);
  static const Color paletteFF1A4034 = Color(0xFF1A4034);
  static const Color paletteFF1A5E52 = Color(0xFF1A5E52);
  static const Color paletteFF1B7A4A = Color(0xFF1B7A4A);
  static const Color paletteFF1C2420 = Color(0xFF1C2420);
  static const Color paletteFF1E2422 = Color(0xFF1E2422);
  static const Color paletteFF1E9A62 = Color(0xFF1E9A62);
  static const Color paletteFF217346 = Color(0xFF217346);
  static const Color paletteFF242826 = Color(0xFF242826);
  static const Color paletteFF25D366 = Color(0xFF25D366);
  static const Color paletteFF2A2A2A = Color(0xFF2A2A2A);
  static const Color paletteFF2A2E2C = Color(0xFF2A2E2C);
  static const Color paletteFF2A3330 = Color(0xFF2A3330);
  static const Color paletteFF2C322F = Color(0xFF2C322F);
  static const Color paletteFF2C6F5E = Color(0xFF2C6F5E);
  static const Color paletteFF2D3436 = Color(0xFF2D3436);
  static const Color paletteFF2D6A4F = Color(0xFF2D6A4F);
  static const Color paletteFF2D6B5A = Color(0xFF2D6B5A);
  static const Color paletteFF2E7D4A = Color(0xFF2E7D4A);
  static const Color paletteFF2E7D5A = Color(0xFF2E7D5A);
  static const Color paletteFF333333 = Color(0xFF333333);
  static const Color paletteFF3A2424 = Color(0xFF3A2424);
  static const Color paletteFF3A242C = Color(0xFF3A242C);
  static const Color paletteFF3A2E14 = Color(0xFF3A2E14);
  static const Color paletteFF3A3A3A = Color(0xFF3A3A3A);
  static const Color paletteFF3C4440 = Color(0xFF3C4440);
  static const Color paletteFF444444 = Color(0xFF444444);
  static const Color paletteFF4A5568 = Color(0xFF4A5568);
  static const Color paletteFF4A90E2 = Color(0xFF4A90E2);
  static const Color paletteFF5A6A72 = Color(0xFF5A6A72);
  static const Color paletteFF5E6B64 = Color(0xFF5E6B64);
  static const Color paletteFF667EEA = Color(0xFF667EEA);
  static const Color paletteFF6C63FF = Color(0xFF6C63FF);
  static const Color paletteFF6E7872 = Color(0xFF6E7872);
  static const Color paletteFF764BA2 = Color(0xFF764BA2);
  static const Color paletteFF7B68EE = Color(0xFF7B68EE);
  static const Color paletteFF7C8680 = Color(0xFF7C8680);
  static const Color paletteFF8B5CF6 = Color(0xFF8B5CF6);
  static const Color paletteFF8B7CFF = Color(0xFF8B7CFF);
  static const Color paletteFF8E9892 = Color(0xFF8E9892);
  static const Color paletteFF9AA39D = Color(0xFF9AA39D);
  static const Color paletteFF9B8DFF = Color(0xFF9B8DFF);
  static const Color paletteFF9CA3AF = Color(0xFF9CA3AF);
  static const Color paletteFFB4B4B4 = Color(0xFFB4B4B4);
  static const Color paletteFFC084FC = Color(0xFFC084FC);
  static const Color paletteFFC5CBC7 = Color(0xFFC5CBC7);
  static const Color paletteFFD3DDD7 = Color(0xFFD3DDD7);
  static const Color paletteFFD4D4D4 = Color(0xFFD4D4D4);
  static const Color paletteFFD7E0DB = Color(0xFFD7E0DB);
  static const Color paletteFFD7EDE3 = Color(0xFFD7EDE3);
  static const Color paletteFFD7F6E8 = Color(0xFFD7F6E8);
  static const Color paletteFFE3E8E4 = Color(0xFFE3E8E4);
  static const Color paletteFFE4E4E4 = Color(0xFFE4E4E4);
  static const Color paletteFFE4E9E5 = Color(0xFFE4E9E5);
  static const Color paletteFFE6ECE8 = Color(0xFFE6ECE8);
  static const Color paletteFFE7E6E6 = Color(0xFFE7E6E6);
  static const Color paletteFFE8E8E4 = Color(0xFFE8E8E4);
  static const Color paletteFFE8ECF0 = Color(0xFFE8ECF0);
  static const Color paletteFFE8EEEA = Color(0xFFE8EEEA);
  static const Color paletteFFEE5A24 = Color(0xFFEE5A24);
  static const Color paletteFFEE5A5A = Color(0xFFEE5A5A);
  static const Color paletteFFEEF0FF = Color(0xFFEEF0FF);
  static const Color paletteFFEEF6F2 = Color(0xFFEEF6F2);
  static const Color paletteFFF093FB = Color(0xFFF093FB);
  static const Color paletteFFF3F3F3 = Color(0xFFF3F3F3);
  static const Color paletteFFF4F7F4 = Color(0xFFF4F7F4);
  static const Color paletteFFF5576C = Color(0xFFF5576C);
  static const Color paletteFFF8F9FA = Color(0xFFF8F9FA);
  static const Color paletteFFFFF4E5 = Color(0xFFFFF4E5);

  // Print inks used by PDF generators.
  static const Color blue100 = Color(0xFFBBDEFB);

  static ThemeData get light {
    final scheme = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: Brightness.light,
      primary: primary,
      secondary: primaryLight,
      surface: AppTheme.white,
    );

    return _base(
      brightness: Brightness.light,
      scheme: scheme,
      scaffold: lightScaffold,
      card: AppTheme.white,
      divider: AppTheme.grey200,
      overlayStyle: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: AppTheme.transparent,
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
      primary: darkAction,
      onPrimary: AppTheme.white,
      secondary: toneBlue,
      onSecondary: AppTheme.white,
      error: AppTheme.error,
      onError: AppTheme.white,
      surface: darkSurface,
      onSurface: darkTextPrimary,
      surfaceContainerHighest: darkElevated,
      outline: darkBorder,
      outlineVariant: AppTheme.darkOutline,
    );

    return _base(
      brightness: Brightness.dark,
      scheme: scheme,
      scaffold: darkScaffold,
      card: darkCard,
      divider: darkBorder,
      overlayStyle: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: AppTheme.transparent,
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
      primaryColor: isDark ? darkAction : primary,
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: AppTheme.transparent,
        centerTitle: false,
        backgroundColor: isDark ? darkScaffold : primary,
        foregroundColor: AppTheme.white,
        systemOverlayStyle: overlayStyle,
        titleTextStyle: const TextStyle(
          fontFamily: 'Literata',
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: AppTheme.white,
        ),
        iconTheme: const IconThemeData(color: AppTheme.white),
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
        backgroundColor: isDark ? darkCard : card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: isDark ? darkCard : card,
        modalBackgroundColor: isDark ? darkCard : card,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: isDark ? darkCard : primary,
        contentTextStyle: const TextStyle(
          fontFamily: 'Literata',
          color: AppTheme.white,
        ),
        behavior: SnackBarBehavior.floating,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: isDark ? darkAction : primary,
        foregroundColor: AppTheme.white,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: isDark ? darkAction : primary,
          foregroundColor: AppTheme.white,
          disabledBackgroundColor: isDark ? darkCard : AppTheme.grey300,
          disabledForegroundColor: isDark
              ? darkTextMuted
              : AppTheme.grey600,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: isDark ? darkAction : primary,
          foregroundColor: AppTheme.white,
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: isDark ? darkCard : card,
        textStyle: TextStyle(
          fontFamily: 'Literata',
          color: isDark ? darkTextPrimary : AppTheme.lightText,
        ),
      ),
      drawerTheme: DrawerThemeData(backgroundColor: isDark ? darkCard : card),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppTheme.white;
          }
          return isDark ? AppTheme.grey : AppTheme.grey50;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return isDark ? darkAction : primary;
          }
          return isDark ? AppTheme.white24 : AppTheme.black12;
        }),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: isDark ? darkTextSecondary : AppTheme.grey700,
        textColor: isDark ? darkTextPrimary : AppTheme.black87,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? darkScaffold : AppTheme.white,
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
            color: isDark ? darkActionBright : primary,
            width: 1.5,
          ),
        ),
      ),
      dividerTheme: DividerThemeData(color: divider, thickness: 1),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return isDark ? darkAction : primary;
          }
          return null;
        }),
        checkColor: WidgetStateProperty.all(AppTheme.white),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return isDark ? darkAction : primary;
          }
          return null;
        }),
      ),
      iconTheme: IconThemeData(
        color: isDark ? darkTextSecondary : AppTheme.grey700,
      ),
      textTheme: _textTheme(isDark),
    );
  }

  static TextTheme _textTheme(bool isDark) {
    final primaryText = isDark ? darkTextPrimary : AppTheme.lightText;
    final secondaryText = isDark ? darkTextSecondary : AppTheme.grey700;

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
      isDark(context) ? AppTheme.darkTextPrimary : AppTheme.lightText;

  static Color secondaryText(BuildContext context) =>
      isDark(context) ? AppTheme.darkTextSecondary : AppTheme.grey700;

  static Color mutedText(BuildContext context) =>
      isDark(context) ? AppTheme.darkTextMuted : AppTheme.grey;

  static Color border(BuildContext context) => isDark(context)
      ? AppTheme.darkBorder
      : AppTheme.grey.withValues(alpha: 0.2);

  static Color inputFill(BuildContext context) =>
      isDark(context) ? AppTheme.darkScaffold : AppTheme.white;

  static Color chipFill(BuildContext context) => isDark(context)
      ? AppTheme.darkScaffold
      : AppTheme.grey.withValues(alpha: 0.08);

  /// Filled green. Light theme keeps [AppTheme.primary]; dark uses the purchase-screen green.
  static Color action(BuildContext context) =>
      isDark(context) ? AppTheme.darkAction : AppTheme.primary;

  /// Outline rings and green icons. Brighter on dark so they read on the black page.
  static Color actionBright(BuildContext context) =>
      isDark(context) ? AppTheme.darkActionBright : AppTheme.primary;

  static Color glassFill(BuildContext context) => isDark(context)
      ? AppTheme.darkCard.withValues(alpha: 0.96)
      : AppTheme.white.withValues(alpha: 0.82);

  static Color glassFillSecondary(BuildContext context) => isDark(context)
      ? AppTheme.darkElevated.withValues(alpha: 0.96)
      : AppTheme.glassMist.withValues(alpha: 0.72);

  static Color glassBorder(BuildContext context) => isDark(context)
      ? AppTheme.white.withValues(alpha: 0.14)
      : AppTheme.white.withValues(alpha: 0.85);

  static Color divider(BuildContext context) => Theme.of(context).dividerColor;

  static Color shadow(BuildContext context) =>
      AppTheme.black.withValues(alpha: isDark(context) ? 0.55 : 0.06);

  /// Solid top-bar color from [AppBarTheme]. The same color on every screen.
  static Color appBar(BuildContext context) =>
      Theme.of(context).appBarTheme.backgroundColor ??
      (isDark(context) ? AppTheme.darkScaffold : AppTheme.primary);

  /// Deep green bar. Dark enough for light labels, tinted to match the screens.
  static List<Color> headerGradient(BuildContext context) => isDark(context)
      ? const [AppTheme.headerDarkStart, AppTheme.headerDarkMid, AppTheme.headerDarkEnd]
      : const [AppTheme.primary, AppTheme.primaryDark, AppTheme.headerLightEnd];

  /// Selected chips and the active tab use the theme green in both themes.
  static Color selectedFill(BuildContext context) =>
      isDark(context) ? AppTheme.darkAction : AppTheme.primary;

  static Color selectedOnFill(BuildContext context) => AppTheme.white;

  /// Emphasis color. Dark titles stay light; actions use [primary].
  static Color accent(BuildContext context) =>
      isDark(context) ? AppTheme.darkTextPrimary : AppTheme.primary;

  /// Soft accent wash behind icons/chips.
  static Color accentSoft(BuildContext context, [double alpha = 0.12]) =>
      (isDark(context) ? AppTheme.darkActionBright : AppTheme.primary)
          .withValues(alpha: alpha);

  /// On-gradient / on-colored-card text (always light for contrast).
  static Color onAccent(BuildContext context) => AppTheme.white;

  /// Subtle on-gradient secondary text.
  static Color onAccentMuted(BuildContext context) =>
      AppTheme.white.withValues(alpha: isDark(context) ? 0.72 : 0.85);

  /// Metric-card gradients in the same green-charcoal family.
  static List<Color> darkMetricGradient(int index) {
    const pairs = <List<Color>>[
      [AppTheme.metricGreenStart, AppTheme.metricGreenEnd],
      [AppTheme.metricBlueStart, AppTheme.metricBlueEnd],
      [AppTheme.metricAmberStart, AppTheme.metricAmberEnd],
      [AppTheme.metricRoseStart, AppTheme.metricRoseEnd],
    ];
    return pairs[index % pairs.length];
  }
}

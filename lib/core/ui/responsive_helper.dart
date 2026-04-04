import 'package:flutter/material.dart';

/// Responsive breakpoints and helpers for adaptive layouts.
/// Mobile UI remains unchanged — desktop/tablet get enhanced layouts.
class ResponsiveHelper {
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 900;
  static const double desktopBreakpoint = 1200;

  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < mobileBreakpoint;

  static bool isTablet(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    return w >= mobileBreakpoint && w < desktopBreakpoint;
  }

  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= desktopBreakpoint;

  static bool isWide(BuildContext context) =>
      MediaQuery.of(context).size.width >= mobileBreakpoint;

  /// Returns the number of grid columns for the current screen width.
  static int gridColumns(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    if (w >= desktopBreakpoint) return 4;
    if (w >= tabletBreakpoint) return 3;
    if (w >= mobileBreakpoint) return 2;
    return 2; // mobile default (existing behavior)
  }

  /// Max content width for centering on very wide screens.
  static double maxContentWidth(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    if (w >= desktopBreakpoint) return 1100;
    if (w >= tabletBreakpoint) return 900;
    return double.infinity;
  }
}

/// Wraps child in a centered constrained box on wide screens.
/// On mobile, renders child as-is (no layout changes).
class ResponsiveContent extends StatelessWidget {
  final Widget child;
  final double? maxWidth;

  const ResponsiveContent({super.key, required this.child, this.maxWidth});

  @override
  Widget build(BuildContext context) {
    if (ResponsiveHelper.isMobile(context)) return child;
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: maxWidth ?? ResponsiveHelper.maxContentWidth(context),
        ),
        child: child,
      ),
    );
  }
}

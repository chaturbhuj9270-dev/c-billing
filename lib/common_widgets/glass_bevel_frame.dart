import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';

/// Raised glass rim: bright along the top, theme color through the middle,
/// and a darker edge along the bottom.
LinearGradient glassBevelGradient(bool isDark, Color themeColor) {
  return LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      AppTheme.white.withValues(alpha: isDark ? 0.72 : 0.98),
      Color.lerp(AppTheme.white, themeColor, isDark ? 0.25 : 0.4)!,
      themeColor.withValues(alpha: isDark ? 0.7 : 0.92),
      Color.lerp(themeColor, AppTheme.black, isDark ? 0.55 : 0.38)!,
    ],
    stops: const [0.0, 0.22, 0.62, 1.0],
  );
}

class GlassBevelBorderPainter extends CustomPainter {
  final bool isDark;
  final Color themeColor;
  final double radius;

  const GlassBevelBorderPainter({
    required this.isDark,
    required this.themeColor,
    required this.radius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final bounds = Offset.zero & size;
    final outer = RRect.fromRectAndRadius(
      bounds.deflate(1.15),
      Radius.circular(radius - 1.15),
    );

    final bevel = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..shader = glassBevelGradient(isDark, themeColor).createShader(bounds);
    canvas.drawRRect(outer, bevel);

    final shine = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.05
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          AppTheme.white.withValues(alpha: isDark ? 0.42 : 0.75),
          AppTheme.white.withValues(alpha: 0),
        ],
      ).createShader(bounds);
    canvas.drawRRect(outer.deflate(2.1), shine);
  }

  @override
  bool shouldRepaint(covariant GlassBevelBorderPainter oldDelegate) {
    return oldDelegate.isDark != isDark ||
        oldDelegate.themeColor != themeColor ||
        oldDelegate.radius != radius;
  }
}

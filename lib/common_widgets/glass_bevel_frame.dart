import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';

// Raised glass rim: bright along the top, theme color through the middle, and a darker edge along the bottom.
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
  final BorderRadius? borderRadius;
  final double strokeWidth;
  /// When false, skips the left edge (for flush-left drawers).
  final bool paintLeft;

  const GlassBevelBorderPainter({
    required this.isDark,
    required this.themeColor,
    required this.radius,
    this.borderRadius,
    this.strokeWidth = 0.7,
    this.paintLeft = true,
  });

  Path _openRightPath(RRect r) {
    final tr = r.trRadiusX;
    final br = r.brRadiusX;
    return Path()
      ..moveTo(r.left, r.top)
      ..lineTo(r.right - tr, r.top)
      ..arcToPoint(
        Offset(r.right, r.top + tr),
        radius: Radius.circular(tr),
      )
      ..lineTo(r.right, r.bottom - br)
      ..arcToPoint(
        Offset(r.right - br, r.bottom),
        radius: Radius.circular(br),
      )
      ..lineTo(r.left, r.bottom);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final bounds = Offset.zero & size;
    const inset = 0.45;
    final outer = borderRadius == null
        ? RRect.fromRectAndRadius(
            bounds.deflate(inset),
            Radius.circular((radius - inset).clamp(0.0, radius)),
          )
        : borderRadius!.resolve(TextDirection.ltr).toRRect(bounds).deflate(inset);

    final bevel = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..shader = glassBevelGradient(isDark, themeColor).createShader(bounds);

    final shine = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth * 0.5
      ..strokeCap = StrokeCap.round
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          AppTheme.white.withValues(alpha: isDark ? 0.28 : 0.5),
          AppTheme.white.withValues(alpha: 0),
        ],
      ).createShader(bounds);

    if (paintLeft) {
      canvas.drawRRect(outer, bevel);
      canvas.drawRRect(outer.deflate(0.85), shine);
    } else {
      final path = _openRightPath(outer);
      canvas.drawPath(path, bevel);
      canvas.drawPath(_openRightPath(outer.deflate(0.85)), shine);
    }
  }

  @override
  bool shouldRepaint(covariant GlassBevelBorderPainter oldDelegate) {
    return oldDelegate.isDark != isDark ||
        oldDelegate.themeColor != themeColor ||
        oldDelegate.radius != radius ||
        oldDelegate.borderRadius != borderRadius ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.paintLeft != paintLeft;
  }
}

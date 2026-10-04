import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Water-drop impact + expanding ripples for glass UI surfaces.
class WaterDropPainter extends CustomPainter {
  final Offset? origin;
  final double progress;
  final Color accentColor;

  static const _water = Color(0xFF4FC3F7);

  const WaterDropPainter({
    required this.origin,
    required this.progress,
    required this.accentColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (origin == null || progress <= 0 || progress >= 1) return;

    final center = origin!;
    final maxRadius = math.max(size.width, size.height) * 0.85;
    final tint = Color.lerp(_water, accentColor, 0.35)!;

    // ── 1) Drop impact flash (early phase) ──────────────────────────
    if (progress < 0.35) {
      final impactT = (progress / 0.35).clamp(0.0, 1.0);
      final impactRadius = 10 + 22 * Curves.easeOut.transform(impactT);
      final impactOpacity = (1.0 - impactT) * 0.55;

      final flash = Paint()
        ..shader = RadialGradient(
          colors: [
            Colors.white.withValues(alpha: impactOpacity),
            tint.withValues(alpha: impactOpacity * 0.55),
            tint.withValues(alpha: 0),
          ],
          stops: const [0.0, 0.45, 1.0],
        ).createShader(Rect.fromCircle(center: center, radius: impactRadius));
      canvas.drawCircle(center, impactRadius, flash);

      final coreOpacity = ((1.0 - impactT) * 0.8).clamp(0.0, 1.0);
      canvas.drawCircle(
        center,
        4.5 * (1.0 - impactT * 0.4),
        Paint()..color = Colors.white.withValues(alpha: coreOpacity),
      );
    }

    // ── 2) Expanding water rings ────────────────────────────────────
    for (var i = 0; i < 4; i++) {
      final delay = i * 0.10;
      final local = ((progress - delay) / (1.0 - delay)).clamp(0.0, 1.0);
      if (local <= 0) continue;

      final eased = Curves.easeOutCubic.transform(local);
      final radius = maxRadius * eased;
      final opacity = ((1.0 - local) * (0.65 - i * 0.1)).clamp(0.0, 1.0);
      final stroke = (3.2 - i * 0.45).clamp(1.0, 3.2);

      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke
          ..color = Color.lerp(Colors.white, tint, 0.4)!
              .withValues(alpha: opacity),
      );

      if (i == 0 && radius > 0) {
        canvas.drawCircle(
          center,
          radius,
          Paint()
            ..shader = RadialGradient(
              colors: [
                tint.withValues(alpha: opacity * 0.22),
                tint.withValues(alpha: opacity * 0.08),
                tint.withValues(alpha: 0),
              ],
              stops: const [0.0, 0.55, 1.0],
            ).createShader(Rect.fromCircle(center: center, radius: radius)),
        );
      }
    }

    // ── 3) Tiny secondary droplets flying outward ───────────────────
    if (progress < 0.55) {
      final t = (progress / 0.55).clamp(0.0, 1.0);
      final fly = Curves.easeOut.transform(t);
      final fade = (1.0 - t).clamp(0.0, 1.0);
      const angles = [-0.9, -0.35, 0.4, 0.95, 2.4, -2.5];

      for (var a = 0; a < angles.length; a++) {
        final dist = 18 + fly * (28 + a * 4);
        final p = Offset(
          center.dx + math.cos(angles[a]) * dist,
          center.dy + math.sin(angles[a]) * dist,
        );
        final r = (3.2 - a * 0.25) * (1.0 - fly * 0.5);
        canvas.drawCircle(
          p,
          r,
          Paint()
            ..color = Color.lerp(Colors.white, tint, 0.35)!
                .withValues(alpha: fade * 0.7),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant WaterDropPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.origin != origin ||
        oldDelegate.accentColor != accentColor;
  }
}

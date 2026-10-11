import 'package:flutter/material.dart';
import 'package:c_billing/core/theme/app_theme.dart';

/// Circular app logo with the splash ripple and pulse.
class AppLogoMark extends StatelessWidget {
  final bool isDark;
  final Animation<double> rings;
  final Animation<double> pulse;
  final double logoSize;

  const AppLogoMark({
    super.key,
    required this.isDark,
    required this.rings,
    required this.pulse,
    this.logoSize = 120,
  });

  @override
  Widget build(BuildContext context) {
    final scale = logoSize / 120;
    final canvas = 280 * scale;
    final ring = isDark ? AppTheme.mint : AppTheme.primary;
    return SizedBox(
      width: canvas,
      height: canvas,
      child: AnimatedBuilder(
        animation: rings,
        builder: (context, child) {
          return Stack(
            alignment: Alignment.center,
            children: [
              _ripple(0, ring, scale),
              _ripple(0.33, ring, scale),
              _ripple(0.66, ring, scale),
              child!,
            ],
          );
        },
        child: ScaleTransition(
          scale: pulse,
          child: Container(
            width: logoSize,
            height: logoSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppTheme.mint.withValues(alpha: isDark ? 0.35 : 0.28),
                  blurRadius: 28 * scale,
                  spreadRadius: 2 * scale,
                ),
              ],
            ),
            child: ClipOval(
              child: Image.asset(
                'assets/images/app_logo.png',
                width: logoSize,
                height: logoSize,
                fit: BoxFit.cover,
                gaplessPlayback: true,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _ripple(double phase, Color color, double scale) {
    final t = (rings.value + phase) % 1.0;
    final size = (118 + (t * 150)) * scale;
    final opacity = (1 - t) * (isDark ? 0.55 : 0.32);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: color.withValues(alpha: opacity),
          width: 1.6,
        ),
      ),
    );
  }
}

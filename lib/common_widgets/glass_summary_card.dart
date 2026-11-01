import 'dart:ui';

import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import 'glass_bevel_frame.dart';

class GlassSummaryStat {
  final String value;
  final String label;

  const GlassSummaryStat({required this.value, required this.label});
}

/// Raised frosted-glass summary card shared by Purchase / Customers / Stock.
class GlassSummaryCard extends StatelessWidget {
  final String title;
  final String amount;
  final List<GlassSummaryStat> stats;
  final Widget? trailing;
  final double radius;

  const GlassSummaryCard({
    super.key,
    required this.title,
    required this.amount,
    required this.stats,
    this.trailing,
    this.radius = 22,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final accent = AppColors.action(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: AppTheme.black.withValues(alpha: isDark ? 0.5 : 0.16),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
          BoxShadow(
            color: accent.withValues(alpha: isDark ? 0.22 : 0.1),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
          child: CustomPaint(
            foregroundPainter: GlassBevelBorderPainter(
              isDark: isDark,
              themeColor: accent,
              radius: radius,
              strokeWidth: 1.5,
            ),
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: glassBevelGradient(isDark, accent),
              ),
              child: Padding(
                padding: const EdgeInsets.all(1.6),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(radius - 1.6),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(radius - 1.6),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: isDark
                              ? [
                                  Color.lerp(
                                    accent,
                                    AppTheme.white,
                                    0.12,
                                  )!.withValues(alpha: 0.55),
                                  accent.withValues(alpha: 0.42),
                                  Color.lerp(
                                    accent,
                                    AppTheme.black,
                                    0.35,
                                  )!.withValues(alpha: 0.62),
                                ]
                              : [
                                  Color.lerp(
                                    accent,
                                    AppTheme.white,
                                    0.35,
                                  )!.withValues(alpha: 0.72),
                                  accent.withValues(alpha: 0.58),
                                  AppTheme.green800.withValues(alpha: 0.66),
                                ],
                          stops: const [0.0, 0.48, 1.0],
                        ),
                        border: Border.all(
                          color: AppTheme.white.withValues(
                            alpha: isDark ? 0.22 : 0.45,
                          ),
                          width: 0.8,
                        ),
                      ),
                      child: Stack(
                        children: [
                          Positioned(
                            left: 0,
                            right: 0,
                            top: 0,
                            height: 56,
                            child: IgnorePointer(
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      AppTheme.white.withValues(
                                        alpha: isDark ? 0.22 : 0.42,
                                      ),
                                      AppTheme.white.withValues(alpha: 0),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            left: -20,
                            top: -30,
                            child: IgnorePointer(
                              child: Transform.rotate(
                                angle: -0.4,
                                child: Container(
                                  width: 160,
                                  height: 70,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        AppTheme.white.withValues(
                                          alpha: isDark ? 0.12 : 0.28,
                                        ),
                                        AppTheme.white.withValues(alpha: 0),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        title.toUpperCase(),
                                        style: TextStyle(
                                          fontFamily: 'Literata',
                                          fontWeight: FontWeight.w600,
                                          fontSize: 11,
                                          letterSpacing: 0.8,
                                          color: AppTheme.white.withValues(
                                            alpha: 0.85,
                                          ),
                                        ),
                                      ),
                                    ),
                                    trailing ??
                                        Container(
                                          width: 34,
                                          height: 34,
                                          alignment: Alignment.center,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: AppTheme.white.withValues(
                                              alpha: isDark ? 0.16 : 0.28,
                                            ),
                                            border: Border.all(
                                              color: AppTheme.white.withValues(
                                                alpha: 0.45,
                                              ),
                                            ),
                                          ),
                                          child: const Text(
                                            '₹',
                                            style: TextStyle(
                                              fontFamily: 'Literata',
                                              fontWeight: FontWeight.w800,
                                              fontSize: 15,
                                              color: AppTheme.white,
                                            ),
                                          ),
                                        ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  amount,
                                  style: TextStyle(
                                    fontFamily: 'Literata',
                                    fontWeight: FontWeight.w800,
                                    fontSize: 30,
                                    color: AppTheme.white,
                                    height: 1.1,
                                    shadows: [
                                      Shadow(
                                        color: AppTheme.black.withValues(
                                          alpha: 0.22,
                                        ),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                ),
                                if (stats.isNotEmpty) ...[
                                  const SizedBox(height: 14),
                                  Container(
                                    height: 1,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          AppTheme.white.withValues(alpha: 0),
                                          AppTheme.white.withValues(alpha: 0.4),
                                          AppTheme.white.withValues(alpha: 0),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      for (var i = 0; i < stats.length; i++) ...[
                                        if (i > 0) _divider(),
                                        Expanded(
                                          child: Column(
                                            children: [
                                              Text(
                                                stats[i].value,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  fontFamily: 'Literata',
                                                  fontWeight: FontWeight.w800,
                                                  fontSize: 16,
                                                  color: AppTheme.white,
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                stats[i].label,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  fontFamily: 'Literata',
                                                  fontWeight: FontWeight.w500,
                                                  fontSize: 11,
                                                  color: AppTheme.white
                                                      .withValues(alpha: 0.7),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _divider() {
    return Container(
      width: 1,
      height: 28,
      margin: const EdgeInsets.symmetric(horizontal: 6),
      color: AppTheme.white.withValues(alpha: 0.2),
    );
  }
}

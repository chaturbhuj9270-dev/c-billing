import 'dart:ui';

import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import 'glass_bevel_frame.dart';

class GlassSummaryStat {
  final String value;
  final String label;

  const GlassSummaryStat({required this.value, required this.label});
}

/// Summary card styled like [AppTopBar] — frosted bar fill, no light reflections.
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
    final bar = AppColors.appBar(context);
    final themeColor = Theme.of(context).primaryColor;

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: AppTheme.black.withValues(alpha: isDark ? 0.45 : 0.22),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: CustomPaint(
            foregroundPainter: GlassBevelBorderPainter(
              isDark: isDark,
              themeColor: themeColor,
              radius: radius,
            ),
            child: DecoratedBox(
              decoration: BoxDecoration(
                // Same vertical fill as the top navbar.
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color.lerp(AppTheme.white, bar, isDark ? 0.78 : 0.55)!,
                    bar,
                    Color.lerp(bar, AppTheme.black, isDark ? 0.34 : 0.2)!,
                  ],
                  stops: const [0.0, 0.46, 1.0],
                ),
              ),
              child: Padding(
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
                              color: AppTheme.white.withValues(alpha: 0.75),
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
                                color: AppTheme.white.withValues(alpha: 0.15),
                                border: Border.all(
                                  color: AppTheme.white.withValues(alpha: 0.2),
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
                      style: const TextStyle(
                        fontFamily: 'Literata',
                        fontWeight: FontWeight.w800,
                        fontSize: 30,
                        color: AppTheme.white,
                        height: 1.1,
                      ),
                    ),
                    if (stats.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      Container(
                        height: 1,
                        color: AppTheme.white.withValues(alpha: 0.16),
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
                                      color: AppTheme.white.withValues(
                                        alpha: 0.7,
                                      ),
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

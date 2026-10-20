import 'dart:ui';

import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import 'glass_bevel_frame.dart';

// Round + button with the same frosted fill and 3D glass rim as the tabs.
class GlassIconFab extends StatelessWidget {
  final VoidCallback onPressed;
  final String tooltip;

  const GlassIconFab({
    super.key,
    required this.onPressed,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    const size = 60.0;

    return Tooltip(
      message: tooltip,
      child: SizedBox(
        width: size,
        height: size,
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppTheme.black.withValues(alpha: isDark ? 0.4 : 0.14),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: AppTheme.white.withValues(alpha: isDark ? 0.06 : 0.7),
                blurRadius: 0,
                offset: const Offset(0, -1),
              ),
            ],
          ),
          child: ClipOval(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
              child: Material(
                type: MaterialType.transparency,
                child: InkWell(
                  onTap: onPressed,
                  customBorder: const CircleBorder(),
                  child: CustomPaint(
                    foregroundPainter: const GlassBevelBorderPainter(
                      isDark: false,
                      themeColor: AppTheme.primary,
                      radius: size / 2,
                      strokeWidth: 1.4,
                    ),
                    child: Ink(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: isDark
                              ? [
                                  AppTheme.darkCard.withValues(alpha: 0.88),
                                  AppTheme.darkScaffold.withValues(alpha: 0.72),
                                ]
                              : [
                                  AppTheme.white.withValues(alpha: 0.96),
                                  AppTheme.white.withValues(alpha: 0.78),
                                ],
                        ),
                      ),
                      child: Icon(
                        Icons.add_rounded,
                        size: 30,
                        color: isDark ? AppTheme.white : AppColors.action(context),
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
}

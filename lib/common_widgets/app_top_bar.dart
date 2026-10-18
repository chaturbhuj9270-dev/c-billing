import 'dart:ui';

import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../core/ui/desktop_canvas.dart';
import 'glass_bevel_frame.dart';

/// Top bar used on the availability tab and every other screen.
class AppTopBar extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? leading;
  final List<Widget> actions;
  final bool showBack;
  final VoidCallback? onBack;
  final VoidCallback? onTitleTap;

  const AppTopBar({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.actions = const [],
    this.showBack = true,
    this.onBack,
    this.onTitleTap,
  });

  static Widget action({
    required IconData icon,
    required VoidCallback? onTap,
    bool isLoading = false,
  }) {
    return Builder(
      builder: (context) {
        final onDesktop = DesktopCanvas.isDesktopPlatform;
        final iconColor = onDesktop
            ? AppColors.primaryText(context)
            : AppTheme.white;
        return Material(
          color: AppTheme.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            splashColor: AppTheme.white.withValues(alpha: 0.15),
            highlightColor: AppTheme.white.withValues(alpha: 0.08),
            child: Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: onDesktop
                    ? AppColors.card(context)
                    : AppTheme.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: onDesktop
                      ? AppColors.border(context)
                      : AppTheme.white.withValues(alpha: 0.2),
                ),
              ),
              child: isLoading
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: iconColor,
                      ),
                    )
                  : Icon(icon, color: iconColor, size: 22),
            ),
          ),
        );
      },
    );
  }

  /// Foreground used by chips that sit in the page heading.
  static Color onBar(BuildContext context) =>
      DesktopCanvas.isDesktopPlatform
      ? AppColors.primaryText(context)
      : AppTheme.white;

  /// Chip fill used by badges that sit in the page heading.
  static Color chipFill(BuildContext context) =>
      DesktopCanvas.isDesktopPlatform
      ? AppColors.accentSoft(context, 0.12)
      : AppTheme.white.withValues(alpha: 0.15);

  static Color chipBorder(BuildContext context) =>
      DesktopCanvas.isDesktopPlatform
      ? AppColors.border(context)
      : AppTheme.white.withValues(alpha: 0.2);

  @override
  Widget build(BuildContext context) {
    if (DesktopCanvas.isDesktopPlatform) {
      if (actions.isEmpty) return const SizedBox.shrink();
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            for (var i = 0; i < actions.length; i++) ...[
              if (i > 0) const SizedBox(width: 8),
              actions[i],
            ],
          ],
        ),
      );
    }
    final isDark = AppColors.isDark(context);
    final bar = AppColors.appBar(context);
    const headerRadius = BorderRadius.vertical(bottom: Radius.circular(24));
    final leadingWidget = leading ??
        (showBack
            ? AppTopBar.action(
                icon: Icons.arrow_back_rounded,
                onTap: onBack ?? () => Navigator.maybePop(context),
              )
            : null);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: headerRadius,
          boxShadow: [
            BoxShadow(
              color: AppTheme.black.withValues(alpha: isDark ? 0.45 : 0.22),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: headerRadius,
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: CustomPaint(
              foregroundPainter: GlassBevelBorderPainter(
                isDark: isDark,
                themeColor: Theme.of(context).primaryColor,
                radius: 24,
                borderRadius: headerRadius,
              ),
              child: DecoratedBox(
                decoration: BoxDecoration(
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
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                    child: Row(
                      children: [
                        if (leadingWidget != null) ...[
                          leadingWidget,
                          const SizedBox(width: 12),
                        ],
                        Expanded(
                          child: GestureDetector(
                            onTap: onTitleTap,
                            behavior: HitTestBehavior.opaque,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: AppTheme.white,
                                    fontSize: 18,
                                    height: 1.15,
                                    fontWeight: FontWeight.w700,
                                    fontFamily: 'Literata',
                                    letterSpacing: -0.3,
                                  ),
                                ),
                                if (subtitle != null && subtitle!.isNotEmpty)
                                  Text(
                                    subtitle!,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: AppTheme.white.withValues(
                                        alpha: 0.7,
                                      ),
                                      fontSize: 11,
                                      height: 1.2,
                                      fontFamily: 'Literata',
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        for (var i = 0; i < actions.length; i++) ...[
                          if (i > 0) const SizedBox(width: 8),
                          actions[i],
                        ],
                      ],
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

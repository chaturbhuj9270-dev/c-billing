import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import 'glass_bevel_frame.dart';

// In-page tabs that use the same selected chip as the dashboard bottom bar. Light: frosted white pill, glassy green rim, green icon and label. Dark: transparent pill, glassy rim o...
class AppTabBar extends StatelessWidget {
  final TabController controller;
  final List<Widget> tabs;
  final EdgeInsetsGeometry margin;

  const AppTabBar({
    super.key,
    required this.controller,
    required this.tabs,
    this.margin = const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
  });

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    const radius = 16.0;

    return Padding(
      padding: margin,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: CustomPaint(
          foregroundPainter: const GlassBevelBorderPainter(
            isDark: false,
            themeColor: AppTheme.primary,
            radius: radius,
            strokeWidth: 1.4,
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(radius),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.card(context).withValues(alpha: isDark ? 0.62 : 0.78),
                  AppColors.card(context).withValues(alpha: isDark ? 0.82 : 0.92),
                ],
              ),
            ),
            padding: const EdgeInsets.all(4),
            child: TabBar(
              controller: controller,
              tabs: tabs,
              indicator: AppTabSelectionIndicator(isDark: isDark),
              indicatorSize: TabBarIndicatorSize.tab,
              indicatorPadding: const EdgeInsets.symmetric(vertical: 1),
              labelColor: isDark ? AppTheme.white : AppTheme.primary,
              unselectedLabelColor: AppColors.mutedText(context),
              labelStyle: const TextStyle(
                fontFamily: 'Literata',
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
              unselectedLabelStyle: const TextStyle(
                fontFamily: 'Literata',
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
              dividerColor: AppTheme.transparent,
              overlayColor: WidgetStateProperty.all(AppTheme.transparent),
              splashFactory: NoSplash.splashFactory,
            ),
          ),
        ),
      ),
    );
  }
}

class AppTabSelectionIndicator extends Decoration {
  final bool isDark;

  const AppTabSelectionIndicator({required this.isDark});

  @override
  BoxPainter createBoxPainter([VoidCallback? onChanged]) {
    return _AppTabSelectionPainter(isDark);
  }
}

class _AppTabSelectionPainter extends BoxPainter {
  final bool isDark;

  _AppTabSelectionPainter(this.isDark);

  @override
  void paint(Canvas canvas, Offset offset, ImageConfiguration configuration) {
    final size = configuration.size;
    if (size == null || size.isEmpty) return;

    const radius = 14.0;
    final rect = offset & size;
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(radius));

    if (isDark) {
      canvas.save();
      canvas.translate(offset.dx, offset.dy);
      const GlassBevelBorderPainter(
        isDark: false,
        themeColor: AppTheme.primary,
        radius: radius,
        strokeWidth: 1.4,
      ).paint(canvas, size);
      canvas.restore();
      return;
    }

    canvas.drawRRect(
      rrect.shift(const Offset(0, 3)),
      Paint()
        ..color = AppTheme.black.withValues(alpha: 0.10)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );

    canvas.drawRRect(
      rrect,
      Paint()
        ..shader = glassBevelGradient(false, AppTheme.primary).createShader(rect),
    );

    final inner = RRect.fromRectAndRadius(
      rect.deflate(1.4),
      const Radius.circular(radius - 1.4),
    );
    canvas.drawRRect(
      inner,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppTheme.white.withValues(alpha: 0.96),
            AppTheme.white.withValues(alpha: 0.78),
          ],
        ).createShader(rect),
    );
  }
}

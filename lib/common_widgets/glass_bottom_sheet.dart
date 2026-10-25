import 'dart:ui';

import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../core/ui/desktop_canvas.dart';
import 'glass_bevel_frame.dart';

// Side drawers fill the panel. Phone sheets keep their shorter height.
double drawerSheetSize(double mobile) =>
    DesktopCanvas.isDesktopPlatform ? 1 : mobile;

const BorderRadius kGlassSheetRadius = BorderRadius.vertical(
  top: Radius.circular(28),
);

/// Drag handle used at the top of mobile drawers.
class GlassSheetHandle extends StatelessWidget {
  const GlassSheetHandle({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 10),
        Center(
          child: Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.mutedText(context).withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
      ],
    );
  }
}

// Bottom drawer card with a raised green 3D glass rim (shared by all sheets).
class GlassSheetCard extends StatelessWidget {
  final Widget child;
  final bool showClose;
  final VoidCallback? onClose;

  const GlassSheetCard({
    super.key,
    required this.child,
    this.showClose = false,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final green = AppColors.actionBright(context);
    final card = AppColors.card(context);
    final tintedTop = Color.lerp(card, green, isDark ? 0.14 : 0.07)!;
    final tintedBottom = Color.lerp(card, green, isDark ? 0.06 : 0.03)!;

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: kGlassSheetRadius,
        boxShadow: [
          BoxShadow(
            color: green.withValues(alpha: isDark ? 0.22 : 0.14),
            blurRadius: 22,
            offset: const Offset(0, -4),
          ),
          BoxShadow(
            color: AppTheme.black.withValues(alpha: isDark ? 0.4 : 0.12),
            blurRadius: 28,
            offset: const Offset(0, -10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: kGlassSheetRadius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: CustomPaint(
            foregroundPainter: GlassBevelBorderPainter(
              isDark: isDark,
              themeColor: green,
              radius: 28,
              borderRadius: kGlassSheetRadius,
              strokeWidth: 1.7,
            ),
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color.lerp(AppTheme.white, tintedTop, isDark ? 0.85 : 0.55)!
                        .withValues(alpha: isDark ? 0.72 : 0.88),
                    tintedTop.withValues(alpha: isDark ? 0.78 : 0.92),
                    tintedBottom.withValues(alpha: isDark ? 0.9 : 0.96),
                  ],
                  stops: const [0.0, 0.35, 1.0],
                ),
              ),
              child: Material(
                type: MaterialType.transparency,
                child: Stack(
                  children: [
                    child,
                    if (showClose)
                      Positioned(
                        top: 4,
                        right: 4,
                        child: IconButton(
                          onPressed:
                              onClose ?? () => Navigator.of(context).maybePop(),
                          icon: Icon(
                            Icons.close_rounded,
                            color: AppColors.secondaryText(context),
                            size: 22,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Modal bottom sheet whose card uses [GlassSheetCard].
Future<T?> showAppBottomSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool isScrollControlled = false,
  Color? backgroundColor,
  bool useSafeArea = false,
  bool isDismissible = true,
  bool enableDrag = true,
  bool useRootNavigator = false,
  bool showClose = false,
  VoidCallback? onClose,
}) {
  if (DesktopCanvas.isDesktopPlatform) {
    return _showDesktopSideDrawer<T>(
      context: context,
      builder: builder,
      isDismissible: isDismissible,
      useRootNavigator: useRootNavigator,
    );
  }
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: isScrollControlled,
    useSafeArea: useSafeArea,
    isDismissible: isDismissible,
    enableDrag: enableDrag,
    useRootNavigator: useRootNavigator,
    backgroundColor: AppTheme.transparent,
    barrierColor: AppTheme.black.withValues(alpha: 0.45),
    elevation: 0,
    shape: const RoundedRectangleBorder(borderRadius: kGlassSheetRadius),
    clipBehavior: Clip.antiAlias,
    builder: (sheetContext) {
      final bottomInset = MediaQuery.viewInsetsOf(sheetContext).bottom;
      return Padding(
        padding: EdgeInsets.only(bottom: bottomInset),
        child: GlassSheetCard(
          showClose: showClose,
          onClose: onClose,
          child: SafeArea(
            top: false,
            child: builder(sheetContext),
          ),
        ),
      );
    },
  );
}

// Floating panel on the right. The page behind stays visible and dimmed.
Future<T?> _showDesktopSideDrawer<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  required bool isDismissible,
  required bool useRootNavigator,
  bool wide = false,
}) {
  return showGeneralDialog<T>(
    context: context,
    useRootNavigator: useRootNavigator,
    barrierDismissible: isDismissible,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: AppTheme.transparent,
    transitionDuration: const Duration(milliseconds: 260),
    pageBuilder: (dialogContext, animation, secondaryAnimation) {
      final media = MediaQuery.of(dialogContext);
      final fraction = wide ? 0.5 : 0.34;
      final minWidth = wide ? 520.0 : 360.0;
      final maxWidth = wide ? 760.0 : 440.0;
      final panelWidth = (media.size.width * fraction).clamp(minWidth, maxWidth);
      final width = panelWidth > media.size.width - 24
          ? media.size.width - 24
          : panelWidth;
      final height =
          media.size.height -
          media.padding.vertical -
          media.viewInsets.bottom -
          24;
      final isDark = AppColors.isDark(dialogContext);
      final green = AppColors.actionBright(dialogContext);
      return Padding(
        padding: EdgeInsets.only(
          top: media.padding.top + 12,
          right: 12,
          bottom: media.padding.bottom + media.viewInsets.bottom + 16,
        ),
        child: Align(
          alignment: Alignment.centerRight,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: green.withValues(alpha: isDark ? 0.2 : 0.12),
                  blurRadius: 18,
                  offset: const Offset(-4, 4),
                ),
                BoxShadow(
                  color: AppTheme.black.withValues(alpha: isDark ? 0.35 : 0.1),
                  blurRadius: 20,
                  offset: const Offset(-6, 8),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                child: CustomPaint(
                  foregroundPainter: GlassBevelBorderPainter(
                    isDark: isDark,
                    themeColor: green,
                    radius: 20,
                    strokeWidth: 1.5,
                  ),
                  child: Material(
                    color: AppColors.card(dialogContext).withValues(
                      alpha: isDark ? 0.92 : 0.96,
                    ),
                    child: SizedBox(
                      width: width,
                      height: height < 240 ? 240 : height,
                      child: Column(
                        children: [
                          Align(
                            alignment: Alignment.centerRight,
                            child: IconButton(
                              onPressed: isDismissible
                                  ? () =>
                                      Navigator.of(dialogContext).maybePop()
                                  : null,
                              tooltip: 'Close',
                              icon: Icon(
                                Icons.close_rounded,
                                size: 20,
                                color: AppColors.secondaryText(dialogContext),
                              ),
                            ),
                          ),
                          Expanded(child: builder(dialogContext)),
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
    },
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      final slide = Tween<Offset>(
        begin: const Offset(0.12, 0),
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic));
      return FadeTransition(
        opacity: animation,
        child: SlideTransition(position: slide, child: child),
      );
    },
  );
}

// Opens a full page. Phones push a route. Web, Windows, and macOS use the same right-hand drawer as the customer sheet, without a top navigation bar.
Future<T?> showAppPage<T>(BuildContext context, Widget page) {
  if (!DesktopCanvas.isDesktopPlatform) {
    return Navigator.of(context).push<T>(
      MaterialPageRoute<T>(builder: (_) => page),
    );
  }
  return _showDesktopSideDrawer<T>(
    context: context,
    builder: (_) => page,
    isDismissible: true,
    useRootNavigator: true,
    wide: true,
  );
}

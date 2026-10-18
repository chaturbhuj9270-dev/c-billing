import 'dart:ui';

import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../core/ui/desktop_canvas.dart';
import 'glass_bevel_frame.dart';

/// Side drawers fill the panel. Phone sheets keep their shorter height.
double drawerSheetSize(double mobile) =>
    DesktopCanvas.isDesktopPlatform ? 1 : mobile;

const BorderRadius _sheetRadius = BorderRadius.vertical(
  top: Radius.circular(28),
);

/// Bottom drawer card with the same raised glass rim as the bottom tabs.
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
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: _sheetRadius,
        boxShadow: [
          BoxShadow(
            color: AppTheme.black.withValues(alpha: isDark ? 0.35 : 0.12),
            blurRadius: 24,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: _sheetRadius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: CustomPaint(
            foregroundPainter: GlassBevelBorderPainter(
              isDark: isDark,
              themeColor: Theme.of(context).primaryColor,
              radius: 28,
              borderRadius: _sheetRadius,
            ),
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.card(context).withValues(
                      alpha: isDark ? 0.62 : 0.78,
                    ),
                    AppColors.card(context).withValues(
                      alpha: isDark ? 0.82 : 0.92,
                    ),
                  ],
                ),
              ),
              child: Material(
                type: MaterialType.transparency,
                child: Stack(
                  children: [
                    child,
                    if (showClose)
                      Positioned(
                        top: 0,
                        right: 0,
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

/// Modal bottom sheet whose card uses [GlassSheetCard].
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
    elevation: 0,
    shape: const RoundedRectangleBorder(borderRadius: _sheetRadius),
    clipBehavior: Clip.antiAlias,
    builder: (sheetContext) => GlassSheetCard(
      showClose: showClose,
      onClose: onClose,
      child: builder(sheetContext),
    ),
  );
}

/// Floating panel on the right. The page behind stays visible and dimmed.
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
      return Padding(
        padding: EdgeInsets.only(
          top: media.padding.top + 12,
          right: 12,
          bottom: media.padding.bottom + media.viewInsets.bottom + 16,
        ),
        child: Align(
          alignment: Alignment.centerRight,
          child: Material(
            color: AppColors.card(dialogContext),
            elevation: 8,
            shadowColor: AppTheme.black.withValues(alpha: 0.08),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(color: AppColors.border(dialogContext)),
            ),
            clipBehavior: Clip.antiAlias,
            child: SizedBox(
              width: width,
              height: height < 240 ? 240 : height,
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.centerRight,
                    child: IconButton(
                      onPressed: isDismissible
                          ? () => Navigator.of(dialogContext).maybePop()
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

/// Opens a full page. Phones push a route. Web, Windows, and macOS use the
/// same right-hand drawer as the customer sheet, without a top navigation bar.
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

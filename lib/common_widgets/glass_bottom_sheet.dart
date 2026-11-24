import 'dart:ui';

import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../core/ui/desktop_canvas.dart';
import 'glass_bevel_frame.dart';

// Side drawers fill the panel. Phone sheets keep their shorter height.
double drawerSheetSize(double mobile) =>
    DesktopCanvas.isDesktopPlatform ? 1 : mobile;

const BorderRadius _sheetRadius = BorderRadius.vertical(
  top: Radius.circular(28),
);

/// Drag handle shown at the top of phone bottom sheets.
class GlassSheetHandle extends StatelessWidget {
  const GlassSheetHandle({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 40,
        height: 4,
        margin: const EdgeInsets.only(top: 10, bottom: 8),
        decoration: BoxDecoration(
          color: AppColors.mutedText(context).withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(999),
        ),
      ),
    );
  }
}

// Bottom drawer card with the same raised glass rim as the bottom tabs.
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
                    // Keep glass translucent so the page behind stays visible.
                    AppColors.card(context).withValues(
                      alpha: isDark ? 0.55 : 0.72,
                    ),
                    AppColors.card(context).withValues(
                      alpha: isDark ? 0.78 : 0.88,
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

/// True bottom drawer sized to a fraction of the screen.
/// Return this from [showAppBottomSheet] builders (scroll-controlled).
class GlassDraggableSheet extends StatefulWidget {
  final ScrollableWidgetBuilder builder;
  final double initialChildSize;
  final double minChildSize;
  final double maxChildSize;
  final bool showClose;
  final VoidCallback? onClose;

  const GlassDraggableSheet({
    super.key,
    required this.builder,
    this.initialChildSize = 0.58,
    this.minChildSize = 0.38,
    this.maxChildSize = 0.92,
    this.showClose = false,
    this.onClose,
  });

  @override
  State<GlassDraggableSheet> createState() => _GlassDraggableSheetState();
}

class _GlassDraggableSheetState extends State<GlassDraggableSheet> {
  ScrollController? _desktopScroll;

  @override
  void initState() {
    super.initState();
    if (DesktopCanvas.isDesktopPlatform) {
      _desktopScroll = ScrollController();
    }
  }

  @override
  void dispose() {
    _desktopScroll?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (DesktopCanvas.isDesktopPlatform) {
      return widget.builder(context, _desktopScroll!);
    }

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: widget.initialChildSize,
      minChildSize: widget.minChildSize,
      maxChildSize: widget.maxChildSize,
      builder: (context, controller) {
        return GlassSheetCard(
          showClose: widget.showClose,
          onClose: widget.onClose,
          child: SafeArea(
            top: false,
            child: widget.builder(context, controller),
          ),
        );
      },
    );
  }
}

bool _isGlassDrawerRoot(Widget content) => content is GlassDraggableSheet;

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
    builder: (sheetContext) {
      final bottomInset = MediaQuery.viewInsetsOf(sheetContext).bottom;
      final content = builder(sheetContext);
      final Widget sheet;
      if (isScrollControlled && _isGlassDrawerRoot(content)) {
        sheet = content;
      } else {
        sheet = GlassSheetCard(
          showClose: showClose,
          onClose: onClose,
          child: SafeArea(top: false, child: content),
        );
      }
      return Padding(
        padding: EdgeInsets.only(bottom: bottomInset),
        child: sheet,
      );
    },
  );
}

// Floating panel on the right. Scrim dims the page behind; panel only covers
// the right strip so the previous UI stays visible (not replaced/blanked).
Future<T?> _showDesktopSideDrawer<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  required bool isDismissible,
  required bool useRootNavigator,
  bool wide = false,
}) {
  const scrim = Color(0x73000000); // ~0.45 black — matches mobile sheets
  return showGeneralDialog<T>(
    context: context,
    useRootNavigator: useRootNavigator,
    barrierDismissible: isDismissible,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: scrim,
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
      // Full-screen hit target is the barrier; page child is only the panel so
      // the dimmed back page remains visible around it.
      return SafeArea(
        child: Align(
          alignment: Alignment.centerRight,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(0, 12, 12, 16),
            child: Material(
              color: AppColors.card(dialogContext),
              elevation: 12,
              shadowColor: AppTheme.black.withValues(alpha: 0.18),
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
        ),
      );
    },
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      final slide = Tween<Offset>(
        begin: const Offset(0.08, 0),
        end: Offset.zero,
      ).animate(curved);
      // Slide/fade only the panel — barrier owns the dimming scrim.
      return SlideTransition(
        position: slide,
        child: FadeTransition(opacity: curved, child: child),
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

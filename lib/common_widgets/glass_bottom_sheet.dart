import 'dart:ui';

import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import 'glass_bevel_frame.dart';

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

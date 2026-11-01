import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/theme/app_theme.dart';
import 'glass_bevel_frame.dart';

// Item definition for [GlassyBottomNavBar].
class GlassyNavItem {
  final IconData icon;
  final String label;
  final bool isPrimary;

  const GlassyNavItem({
    required this.icon,
    required this.label,
    this.isPrimary = false,
  });
}

// Frosted bottom tab bar. Selected tab uses a glass pill that slides horizontally.
class GlassyBottomNavBar extends StatefulWidget {
  final int selectedIndex;
  final ValueChanged<int> onTap;
  final List<GlassyNavItem> items;
  final Color accentColor;

  const GlassyBottomNavBar({
    super.key,
    required this.selectedIndex,
    required this.onTap,
    required this.items,
    this.accentColor = AppTheme.primary,
  });

  @override
  State<GlassyBottomNavBar> createState() => _GlassyBottomNavBarState();
}

class _GlassyBottomNavBarState extends State<GlassyBottomNavBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _slide;
  late double _fromIndex;
  late double _toIndex;

  @override
  void initState() {
    super.initState();
    _fromIndex = widget.selectedIndex.toDouble();
    _toIndex = widget.selectedIndex.toDouble();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    _slide = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    _controller.value = 1;
  }

  @override
  void didUpdateWidget(GlassyBottomNavBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedIndex == widget.selectedIndex) return;

    // Continue from wherever the pill currently is (smooth mid-swipe redirects).
    final current =
        lerpDouble(_fromIndex, _toIndex, _slide.value) ?? _toIndex;
    _fromIndex = current;
    _toIndex = widget.selectedIndex.toDouble();
    _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double _chipLeft(double index, double slot, double chipWidth, double width) {
    const inset = 4.0;
    final ideal = (index * slot) + (slot - chipWidth) / 2;
    return ideal.clamp(inset, math.max(inset, width - chipWidth - inset));
  }

  Widget _glassChip({
    required double left,
    required double top,
    required double width,
    required double height,
    required bool isDark,
  }) {
    const radius = 14.0;
    return Positioned(
      left: left,
      top: top,
      width: width,
      height: height,
      child: IgnorePointer(
        child: isDark
            ? CustomPaint(
                foregroundPainter: const GlassBevelBorderPainter(
                  isDark: false,
                  themeColor: AppTheme.primary,
                  radius: radius,
                  strokeWidth: 1.4,
                ),
                child: const SizedBox.expand(),
              )
            : DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(radius),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.black.withValues(alpha: 0.10),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                    BoxShadow(
                      color: AppTheme.white.withValues(alpha: 0.8),
                      blurRadius: 0,
                      offset: const Offset(0, -1),
                    ),
                  ],
                ),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(radius),
                    gradient: glassBevelGradient(false, AppTheme.primary),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(1.4),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(radius - 1.4),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            AppTheme.white.withValues(alpha: 0.96),
                            AppTheme.white.withValues(alpha: 0.78),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  Widget _slidingGlassPill(double width, double height, bool isDark) {
    final count = widget.items.length;
    if (count == 0 || width <= 0 || height <= 0) {
      return const SizedBox.shrink();
    }
    const inset = 4.0;
    final slot = width / count;
    final chipWidth = math.max(0.0, slot - inset * 2);
    final chipHeight = math.max(0.0, height - 4);
    final restingTop = (height - chipHeight) / 2;

    return AnimatedBuilder(
      animation: _slide,
      builder: (context, _) {
        final index =
            lerpDouble(_fromIndex, _toIndex, _slide.value) ?? _toIndex;
        return Stack(
          clipBehavior: Clip.none,
          children: [
            _glassChip(
              left: _chipLeft(index, slot, chipWidth, width),
              top: restingTop,
              width: chipWidth,
              height: chipHeight,
              isDark: isDark,
            ),
          ],
        );
      },
    );
  }

  void _onItemTap(int index) {
    if (index != widget.selectedIndex) {
      HapticFeedback.lightImpact();
    }
    // Always forward the tap so callers can keep side-effects (e.g. session reset).
    widget.onTap(index);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    final isDark = AppColors.isDark(context);

    const barRadius = 18.0;
    final borderColor = isDark
        ? AppTheme.white.withValues(alpha: 0.28)
        : AppTheme.black.withValues(alpha: 0.14);
    final topEdgeColor = isDark
        ? AppTheme.white.withValues(alpha: 0.45)
        : AppTheme.white.withValues(alpha: 0.95);

    return Material(
      type: MaterialType.transparency,
      child: Padding(
        padding: EdgeInsets.fromLTRB(12, 8, 12, math.max(bottomInset, 8)),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(barRadius),
            boxShadow: [
              BoxShadow(
                color: AppTheme.black.withValues(alpha: isDark ? 0.35 : 0.12),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: AppTheme.black.withValues(alpha: isDark ? 0.2 : 0.06),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(barRadius),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
              child: CustomPaint(
                foregroundPainter: GlassBevelBorderPainter(
                  isDark: false,
                  themeColor: AppTheme.primary,
                  radius: barRadius,
                  strokeWidth: 1.35,
                ),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(barRadius),
                    // Uniform border only — Flutter rejects radius + non-uniform Border.
                    border: Border.all(color: borderColor, width: 1),
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
                  child: Stack(
                    alignment: Alignment.center,
                    clipBehavior: Clip.hardEdge,
                    children: [
                      // Stronger top edge highlight (visible rim).
                      Positioned(
                        left: 10,
                        right: 10,
                        top: 0.5,
                        child: IgnorePointer(
                          child: Container(
                            height: 1.4,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(2),
                              color: topEdgeColor,
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 6,
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Positioned.fill(
                              child: IgnorePointer(
                                child: LayoutBuilder(
                                  builder: (context, constraints) {
                                    return _slidingGlassPill(
                                      constraints.maxWidth,
                                      constraints.maxHeight,
                                      isDark,
                                    );
                                  },
                                ),
                              ),
                            ),
                            Row(
                              children: [
                                for (var i = 0; i < widget.items.length; i++)
                                  Expanded(
                                    child: _GlassyNavItemButton(
                                      item: widget.items[i],
                                      selected: widget.selectedIndex == i,
                                      onTap: () => _onItemTap(i),
                                    ),
                                  ),
                              ],
                            ),
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
    );
  }
}

class _GlassyNavItemButton extends StatelessWidget {
  final GlassyNavItem item;
  final bool selected;
  final VoidCallback onTap;

  const _GlassyNavItemButton({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final iconColor = selected
        ? (AppColors.isDark(context) ? AppTheme.white : AppTheme.primary)
        : AppColors.mutedText(context);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(item.icon, color: iconColor, size: 22),
            const SizedBox(height: 3),
            Text(
              item.label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: iconColor,
                fontSize: 10,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                fontFamily: 'Literata',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

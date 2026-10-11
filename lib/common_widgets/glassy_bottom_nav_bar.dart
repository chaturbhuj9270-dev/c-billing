import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/theme/app_theme.dart';

/// Item definition for [GlassyBottomNavBar].
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

/// Frosted bottom tab bar. The selected tab is a glass pill that slides
/// between items.
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
    this.accentColor = AppTheme.mint,
  });

  @override
  State<GlassyBottomNavBar> createState() => _GlassyBottomNavBarState();
}

class _GlassyBottomNavBarState extends State<GlassyBottomNavBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _slideController;
  late int _fromIndex;
  late int _toIndex;
  double _slideT = 1;

  @override
  void initState() {
    super.initState();
    _fromIndex = widget.selectedIndex;
    _toIndex = widget.selectedIndex;
    _slideController =
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 520),
        )..addListener(() {
          setState(() => _slideT = _slideController.value);
        });
  }

  @override
  void didUpdateWidget(GlassyBottomNavBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedIndex == widget.selectedIndex) return;
    final leaving = _slideT >= 1
        ? _toIndex
        : (_slideT < 0.45 ? _fromIndex : _toIndex);
    _fromIndex = leaving;
    _toIndex = widget.selectedIndex;
    _slideController.forward(from: 0);
  }

  @override
  void dispose() {
    _slideController.dispose();
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
    double opacity = 1,
  }) {
    const radius = 14.0;
    final themeColor = Theme.of(context).primaryColor;
    return Positioned(
      left: left,
      top: top,
      width: width,
      height: height,
      child: IgnorePointer(
        child: Opacity(
          opacity: opacity.clamp(0.0, 1.0),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(radius),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.28 : 0.10),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
                if (!isDark)
                  BoxShadow(
                    color: Colors.white.withValues(alpha: 0.8),
                    blurRadius: 0,
                    offset: const Offset(0, -1),
                  ),
              ],
            ),
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(radius),
                gradient: _glassBevelGradient(isDark, themeColor),
              ),
              child: Padding(
                padding: const EdgeInsets.all(1.4),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(radius - 1.4),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: isDark
                          ? [
                              Colors.white.withValues(alpha: 0.16),
                              Colors.white.withValues(alpha: 0.06),
                            ]
                          : [
                              Colors.white.withValues(alpha: 0.96),
                              Colors.white.withValues(alpha: 0.78),
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
    final moving = _slideT < 1 && _fromIndex != _toIndex;

    if (!moving) {
      return _glassChip(
        left: _chipLeft(_toIndex.toDouble(), slot, chipWidth, width),
        top: restingTop,
        width: chipWidth,
        height: chipHeight,
        isDark: isDark,
      );
    }

    final t = Curves.easeInOutCubic.transform(_slideT);
    final travelIndex =
        lerpDouble(_fromIndex.toDouble(), _toIndex.toDouble(), t) ??
        _toIndex.toDouble();
    final coverOpacity = 1 - Curves.easeIn.transform(t);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        _glassChip(
          left: _chipLeft(travelIndex, slot, chipWidth, width),
          top: restingTop + (1 - t) * 7,
          width: chipWidth,
          height: chipHeight,
          isDark: isDark,
        ),
        _glassChip(
          left: _chipLeft(_fromIndex.toDouble(), slot, chipWidth, width),
          top: restingTop,
          width: chipWidth,
          height: chipHeight,
          isDark: isDark,
          opacity: coverOpacity,
        ),
      ],
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

    return Material(
      type: MaterialType.transparency,
      child: Padding(
        padding: EdgeInsets.fromLTRB(12, 8, 12, math.max(bottomInset, 8)),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.12),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.06),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
              child: CustomPaint(
                foregroundPainter: _GlassBevelBorderPainter(
                  isDark: isDark,
                  themeColor: Theme.of(context).primaryColor,
                  radius: 28,
                ),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28),
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 6,
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    clipBehavior: Clip.none,
                    children: [
                      Positioned.fill(
                        child: IgnorePointer(
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              return Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  _slidingGlassPill(
                                    constraints.maxWidth,
                                    constraints.maxHeight,
                                    isDark,
                                  ),
                                ],
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
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Raised glass rim: bright along the top, theme color through the middle,
/// and a darker edge along the bottom.
LinearGradient _glassBevelGradient(bool isDark, Color themeColor) {
  return LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Colors.white.withValues(alpha: isDark ? 0.72 : 0.98),
      Color.lerp(Colors.white, themeColor, isDark ? 0.25 : 0.4)!,
      themeColor.withValues(alpha: isDark ? 0.7 : 0.92),
      Color.lerp(themeColor, Colors.black, isDark ? 0.55 : 0.38)!,
    ],
    stops: const [0.0, 0.22, 0.62, 1.0],
  );
}

class _GlassBevelBorderPainter extends CustomPainter {
  final bool isDark;
  final Color themeColor;
  final double radius;

  const _GlassBevelBorderPainter({
    required this.isDark,
    required this.themeColor,
    required this.radius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final bounds = Offset.zero & size;
    final outer = RRect.fromRectAndRadius(
      bounds.deflate(1.15),
      Radius.circular(radius - 1.15),
    );

    final bevel = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..shader = _glassBevelGradient(isDark, themeColor).createShader(bounds);
    canvas.drawRRect(outer, bevel);

    final shine = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.05
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.white.withValues(alpha: isDark ? 0.42 : 0.75),
          Colors.white.withValues(alpha: 0),
        ],
      ).createShader(bounds);
    canvas.drawRRect(outer.deflate(2.1), shine);
  }

  @override
  bool shouldRepaint(covariant _GlassBevelBorderPainter oldDelegate) {
    return oldDelegate.isDark != isDark ||
        oldDelegate.themeColor != themeColor ||
        oldDelegate.radius != radius;
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
        ? Theme.of(context).primaryColor
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

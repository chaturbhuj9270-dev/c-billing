import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
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
  double _slideFrom = 0;
  double _slideTo = 0;
  double _slideT = 1;

  double get _visualIndex {
    final t = Curves.easeInOutCubic.transform(_slideT);
    return lerpDouble(_slideFrom, _slideTo, t) ?? _slideTo;
  }

  @override
  void initState() {
    super.initState();
    _slideFrom = widget.selectedIndex.toDouble();
    _slideTo = _slideFrom;
    _slideController =
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 480),
        )..addListener(() {
          setState(() => _slideT = _slideController.value);
        });
  }

  @override
  void didUpdateWidget(GlassyBottomNavBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedIndex != widget.selectedIndex) {
      _slideFrom = _visualIndex;
      _slideTo = widget.selectedIndex.toDouble();
      _slideController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }

  double _labelWidth(int index) {
    final painter = TextPainter(
      text: TextSpan(
        text: widget.items[index].label,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          fontFamily: 'Literata',
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout();
    return painter.width;
  }

  /// Selected chip is at least a square, and wider when the label needs room.
  double _restingWidth(int index, double size) {
    const labelMargin = 22.0;
    return math.max(size, _labelWidth(index) + labelMargin);
  }

  double _widthAt(double index, double size, int count) {
    final start = index.floor().clamp(0, count - 1);
    final end = index.ceil().clamp(0, count - 1);
    final local = (index - start).clamp(0.0, 1.0);
    return lerpDouble(
          _restingWidth(start, size),
          _restingWidth(end, size),
          local,
        ) ??
        size;
  }

  Widget _slidingGlassPill(double width, double height, bool isDark) {
    final count = widget.items.length;
    if (count == 0 || width <= 0 || height <= 0) {
      return const SizedBox.shrink();
    }
    final slot = width / count;
    final size = math.min(slot - 8, height);
    final t = Curves.easeInOutCubic.transform(_slideT);
    final centerIndex = lerpDouble(_slideFrom, _slideTo, t) ?? _slideTo;
    final travel = (_slideTo - _slideFrom).abs();
    final stretch = math.sin(t * math.pi) * math.min(travel, 1.8) * slot * 0.72;
    final baseWidth = _widthAt(centerIndex, size, count);
    final pillWidth = math.min(baseWidth + stretch, width - 8);
    final idealLeft = (centerIndex * slot) + (slot - pillWidth) / 2;
    final left = idealLeft
        .clamp(4.0, math.max(4.0, width - pillWidth - 4))
        .toDouble();
    final top = (height - size) / 2;
    final radius = pillWidth > size + 1 ? size / 2 : 14.0;

    return Positioned(
      left: left,
      top: top,
      width: pillWidth,
      height: size,
      child: IgnorePointer(
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
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: isDark
                    ? [
                        Colors.white.withValues(alpha: 0.20),
                        AppTheme.mint.withValues(alpha: 0.16),
                      ]
                    : [
                        Colors.white.withValues(alpha: 0.96),
                        Colors.white.withValues(alpha: 0.78),
                      ],
              ),
              border: Border.all(
                color: Colors.white.withValues(alpha: isDark ? 0.32 : 0.95),
              ),
            ),
          ),
        ),
      ),
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
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                color: isDark ? AppTheme.darkCard : null,
                gradient: isDark
                    ? null
                    : LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppColors.glassFill(context),
                          AppColors.glassFillSecondary(context),
                          widget.accentColor.withValues(alpha: 0.10),
                        ],
                      ),
                border: Border.all(
                  color: isDark
                      ? AppTheme.darkBorder
                      : AppColors.glassBorder(context),
                  width: 1.1,
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
              child: Stack(
                alignment: Alignment.center,
                children: [
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
                  Positioned.fill(
                    child: IgnorePointer(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          return Stack(
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
                ],
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
    final inactiveColor = AppColors.mutedText(context);
    final iconColor = selected ? AppTheme.mint : inactiveColor;

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
            if (selected)
              OverflowBox(
                fit: OverflowBoxFit.deferToChild,
                alignment: Alignment.center,
                minWidth: 0,
                maxWidth: 140,
                minHeight: 0,
                maxHeight: 16,
                child: Text(
                  item.label,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  softWrap: false,
                  overflow: TextOverflow.visible,
                  style: TextStyle(
                    color: iconColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Literata',
                    height: 1,
                  ),
                ),
              )
            else
              Text(
                item.label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: iconColor,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Literata',
                ),
              ),
          ],
        ),
      ),
    );
  }
}

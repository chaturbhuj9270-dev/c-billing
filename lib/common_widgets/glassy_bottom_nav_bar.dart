import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/theme/app_theme.dart';
import 'water_drop_effect.dart';

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

/// iOS Control Center–style glassy bottom tab bar with a water-drop
/// splash animation when switching tabs.
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
  late final AnimationController _dropController;
  Offset? _dropOrigin;
  final GlobalKey _barKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _dropController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
  }

  @override
  void dispose() {
    _dropController.dispose();
    super.dispose();
  }

  void _triggerWaterDrop(Offset globalPosition) {
    final box = _barKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;

    final local = box.globalToLocal(globalPosition);
    setState(() => _dropOrigin = local);
    _dropController.forward(from: 0);
  }

  void _onItemTap(int index, Offset globalPosition) {
    _triggerWaterDrop(globalPosition);
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
            key: _barKey,
            borderRadius: BorderRadius.circular(28),
            child: Stack(
              children: [
                // Glass bar + tabs
                Container(
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      for (var i = 0; i < widget.items.length; i++)
                        Expanded(
                          child: _GlassyNavItemButton(
                            item: widget.items[i],
                            selected: widget.selectedIndex == i,
                            onTapDown: (details) =>
                                _onItemTap(i, details.globalPosition),
                          ),
                        ),
                    ],
                  ),
                ),
                // Water-drop splash drawn ON TOP so it is clearly visible.
                Positioned.fill(
                  child: IgnorePointer(
                    child: AnimatedBuilder(
                      animation: _dropController,
                      builder: (context, _) {
                        return CustomPaint(
                          painter: WaterDropPainter(
                            origin: _dropOrigin,
                            progress: _dropController.value,
                            accentColor: widget.accentColor,
                          ),
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
    );
  }
}

class _GlassyNavItemButton extends StatelessWidget {
  final GlassyNavItem item;
  final bool selected;
  final GestureTapDownCallback onTapDown;

  const _GlassyNavItemButton({
    required this.item,
    required this.selected,
    required this.onTapDown,
  });

  @override
  Widget build(BuildContext context) {
    final inactiveColor = AppColors.mutedText(context);
    final iconColor = selected ? AppTheme.onMint : inactiveColor;
    final labelColor = iconColor;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: onTapDown,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        margin: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: selected ? AppTheme.mint : null,
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: AppTheme.mint.withValues(alpha: 0.28),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedScale(
              scale: selected ? 1.08 : 1.0,
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              child: Icon(
                item.icon,
                color: iconColor,
                size: selected ? 22 : 20,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              item.label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: labelColor,
                fontSize: selected ? 9 : 8,
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

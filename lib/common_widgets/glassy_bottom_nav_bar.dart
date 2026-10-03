import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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

/// iOS Control Center–style glassy bottom tab bar with a water-ripple
/// animation when switching tabs.
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
    this.accentColor = const Color(0xFF1B4D3E),
  });

  @override
  State<GlassyBottomNavBar> createState() => _GlassyBottomNavBarState();
}

class _GlassyBottomNavBarState extends State<GlassyBottomNavBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _rippleController;
  Offset? _rippleOrigin;
  final GlobalKey _barKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _rippleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
  }

  @override
  void dispose() {
    _rippleController.dispose();
    super.dispose();
  }

  void _triggerRipple(Offset globalPosition) {
    final box = _barKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;

    final local = box.globalToLocal(globalPosition);
    setState(() => _rippleOrigin = local);
    _rippleController.forward(from: 0);
  }

  void _onItemTap(int index, Offset globalPosition) {
    _triggerRipple(globalPosition);
    if (index != widget.selectedIndex) {
      HapticFeedback.selectionClick();
    }
    // Always forward the tap so callers can keep side-effects (e.g. session reset).
    widget.onTap(index);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;

    return Material(
      type: MaterialType.transparency,
      child: Padding(
        padding: EdgeInsets.fromLTRB(12, 8, 12, math.max(bottomInset, 8)),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            key: _barKey,
            borderRadius: BorderRadius.circular(28),
            child: AnimatedBuilder(
              animation: _rippleController,
              builder: (context, child) {
                return CustomPaint(
                  painter: _WaterRipplePainter(
                    origin: _rippleOrigin,
                    progress: _rippleController.value,
                    accentColor: widget.accentColor,
                  ),
                  child: child,
                );
              },
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  // Frosted glass look without BackdropFilter ( Impeller-safe ).
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withValues(alpha: 0.82),
                      const Color(0xFFE8F0F5).withValues(alpha: 0.72),
                      widget.accentColor.withValues(alpha: 0.10),
                    ],
                  ),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.85),
                    width: 1.1,
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                child: Row(
                  children: [
                    for (var i = 0; i < widget.items.length; i++)
                      Expanded(
                        child: _GlassyNavItemButton(
                          item: widget.items[i],
                          selected: widget.selectedIndex == i,
                          accentColor: widget.accentColor,
                          onTapDown: (details) =>
                              _onItemTap(i, details.globalPosition),
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

class _GlassyNavItemButton extends StatelessWidget {
  final GlassyNavItem item;
  final bool selected;
  final Color accentColor;
  final GestureTapDownCallback onTapDown;

  const _GlassyNavItemButton({
    required this.item,
    required this.selected,
    required this.accentColor,
    required this.onTapDown,
  });

  @override
  Widget build(BuildContext context) {
    final inactiveColor = item.isPrimary
        ? accentColor.withValues(alpha: 0.85)
        : Colors.grey[700]!;
    final iconColor = selected ? Colors.white : inactiveColor;
    final labelColor = selected ? Colors.white : inactiveColor;

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
          gradient: selected
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    accentColor.withValues(alpha: 0.92),
                    const Color(0xFF2E7D5B).withValues(alpha: 0.88),
                  ],
                )
              : item.isPrimary
                  ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        accentColor.withValues(alpha: 0.10),
                        accentColor.withValues(alpha: 0.04),
                      ],
                    )
                  : null,
          border: Border.all(
            color: selected
                ? Colors.white.withValues(alpha: 0.35)
                : Colors.transparent,
            width: 1,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: accentColor.withValues(alpha: 0.35),
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

/// Expanding concentric rings that mimic a water ripple on the glass surface.
class _WaterRipplePainter extends CustomPainter {
  final Offset? origin;
  final double progress;
  final Color accentColor;

  _WaterRipplePainter({
    required this.origin,
    required this.progress,
    required this.accentColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (origin == null || progress <= 0 || progress >= 1) return;

    final maxRadius = math.sqrt(
          size.width * size.width + size.height * size.height,
        ) *
        0.75;

    // Three staggered ripples for a water-like feel.
    for (var i = 0; i < 3; i++) {
      final delay = i * 0.12;
      final localProgress = ((progress - delay) / (1.0 - delay)).clamp(0.0, 1.0);
      if (localProgress <= 0) continue;

      final radius = maxRadius * Curves.easeOut.transform(localProgress);
      final opacity = ((1.0 - localProgress) * (0.45 - i * 0.1)).clamp(0.0, 1.0);

      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2 - i * 0.4
        ..color = Color.lerp(
          Colors.white,
          accentColor,
          0.35,
        )!.withValues(alpha: opacity);

      canvas.drawCircle(origin!, radius, paint);

      // Soft filled wash behind the leading ring.
      if (i == 0 && radius > 0) {
        final fillPaint = Paint()
          ..style = PaintingStyle.fill
          ..shader = RadialGradient(
            colors: [
              Colors.white.withValues(alpha: opacity * 0.35),
              Colors.white.withValues(alpha: 0),
            ],
          ).createShader(Rect.fromCircle(center: origin!, radius: radius));
        canvas.drawCircle(origin!, radius, fillPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _WaterRipplePainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.origin != origin ||
        oldDelegate.accentColor != accentColor;
  }
}

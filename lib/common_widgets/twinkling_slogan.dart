import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';

/// Star-twinkle slogan: magenta/pink fill with metallic gold border
/// (same treatment as the Indira Gandhi reference lettering).
class TwinklingSlogan extends StatefulWidget {
  final String text;
  final TextStyle style;
  final TextAlign textAlign;

  /// Kept for call-site compatibility; glow stays golden.
  final Color? glowColor;

  // Gold border / edge (metallic bevel).
  static const Color goldHighlight = Color(0xFFFFF6D6);
  static const Color goldMid = Color(0xFFE8C76B);
  static const Color gold = Color(0xFFC9A84C);
  static const Color goldDeep = Color(0xFF8B6914);

  // Magenta / pink fill (reference lettering).
  static const Color magentaHighlight = Color(0xFFFF6BB5);
  static const Color magentaMid = Color(0xFFE6007E);
  static const Color magenta = Color(0xFFC2185B);
  static const Color magentaDeep = Color(0xFF8E0038);

  const TwinklingSlogan({
    super.key,
    required this.text,
    required this.style,
    this.textAlign = TextAlign.start,
    this.glowColor,
  });

  @override
  State<TwinklingSlogan> createState() => _TwinklingSloganState();
}

class _TwinklingSloganState extends State<TwinklingSlogan>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _twinkle;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _twinkle = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutSine,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Alignment get _stackAlignment => switch (widget.textAlign) {
        TextAlign.center => Alignment.center,
        TextAlign.end || TextAlign.right => Alignment.centerRight,
        _ => Alignment.centerLeft,
      };

  @override
  Widget build(BuildContext context) {
    final baseStyle = widget.style.copyWith(
      color: AppTheme.white,
      shadows: null,
    );

    return AnimatedBuilder(
      animation: _twinkle,
      builder: (context, _) {
        final t = _twinkle.value;
        final opacity = 0.55 + (0.45 * t);
        final glowBlur = 4.0 + (12.0 * t);
        final glowAlpha = 0.18 + (0.45 * t);

        // Soft gold outline ring around the magenta fill.
        const outlineOffsets = <Offset>[
          Offset(-1.4, 0),
          Offset(1.4, 0),
          Offset(0, -1.4),
          Offset(0, 1.4),
          Offset(-1.1, -1.1),
          Offset(1.1, -1.1),
          Offset(-1.1, 1.1),
          Offset(1.1, 1.1),
        ];

        final stack = Stack(
          alignment: _stackAlignment,
          children: [
            // Deep gold drop for 3D edge.
            Transform.translate(
              offset: const Offset(0.8, 1.3),
              child: Text(
                widget.text,
                textAlign: widget.textAlign,
                style: baseStyle.copyWith(
                  color: TwinklingSlogan.goldDeep.withValues(alpha: 0.8),
                ),
              ),
            ),
            // Gold border stroke (offset copies).
            for (final o in outlineOffsets)
              Transform.translate(
                offset: o,
                child: Text(
                  widget.text,
                  textAlign: widget.textAlign,
                  style: baseStyle.copyWith(
                    color: Color.lerp(
                      TwinklingSlogan.gold,
                      TwinklingSlogan.goldMid,
                      0.35 + 0.25 * t,
                    )!,
                  ),
                ),
              ),
            // Soft gold glow.
            Text(
              widget.text,
              textAlign: widget.textAlign,
              style: baseStyle.copyWith(
                color: TwinklingSlogan.gold.withValues(alpha: 0.01),
                shadows: [
                  Shadow(
                    color: TwinklingSlogan.gold.withValues(alpha: glowAlpha),
                    blurRadius: glowBlur,
                  ),
                  Shadow(
                    color: TwinklingSlogan.goldHighlight
                        .withValues(alpha: glowAlpha * 0.55),
                    blurRadius: glowBlur * 1.6,
                  ),
                ],
              ),
            ),
            // Magenta / pink fill (reference face color).
            ShaderMask(
              blendMode: BlendMode.srcIn,
              shaderCallback: (bounds) {
                return LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color.lerp(
                      TwinklingSlogan.magentaHighlight,
                      AppTheme.white,
                      0.2 + 0.15 * t,
                    )!,
                    TwinklingSlogan.magentaMid,
                    TwinklingSlogan.magenta,
                    Color.lerp(
                      TwinklingSlogan.magenta,
                      TwinklingSlogan.magentaDeep,
                      0.55,
                    )!,
                  ],
                  stops: const [0.0, 0.28, 0.62, 1.0],
                ).createShader(bounds);
              },
              child: Text(
                widget.text,
                textAlign: widget.textAlign,
                style: baseStyle,
              ),
            ),
          ],
        );

        return Opacity(
          opacity: opacity,
          child: widget.textAlign == TextAlign.center
              ? SizedBox(width: double.infinity, child: stack)
              : stack,
        );
      },
    );
  }
}

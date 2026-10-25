import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';

/// Star-twinkle slogan in golden 3D glass (highlight → gold → deep edge).
class TwinklingSlogan extends StatefulWidget {
  final String text;
  final TextStyle style;
  final TextAlign textAlign;

  /// Kept for call-site compatibility; glow is always golden.
  final Color? glowColor;

  static const Color goldHighlight = Color(0xFFFFF6D6);
  static const Color goldMid = Color(0xFFE8C76B);
  static const Color gold = Color(0xFFC9A84C);
  static const Color goldDeep = Color(0xFF8B6914);

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

        return Opacity(
          opacity: opacity,
          child: Stack(
            alignment: switch (widget.textAlign) {
              TextAlign.center => Alignment.center,
              TextAlign.end || TextAlign.right => Alignment.centerRight,
              _ => Alignment.centerLeft,
            },
            children: [
              Transform.translate(
                offset: const Offset(0.6, 1.1),
                child: Text(
                  widget.text,
                  textAlign: widget.textAlign,
                  style: baseStyle.copyWith(
                    color: TwinklingSlogan.goldDeep.withValues(alpha: 0.75),
                  ),
                ),
              ),
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
              ShaderMask(
                blendMode: BlendMode.srcIn,
                shaderCallback: (bounds) {
                  return LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color.lerp(
                        TwinklingSlogan.goldHighlight,
                        AppTheme.white,
                        0.35 + 0.25 * t,
                      )!,
                      TwinklingSlogan.goldMid,
                      TwinklingSlogan.gold,
                      Color.lerp(
                        TwinklingSlogan.gold,
                        TwinklingSlogan.goldDeep,
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
          ),
        );
      },
    );
  }
}

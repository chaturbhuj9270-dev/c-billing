import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:c_billing/common_widgets/glass_bevel_frame.dart';
import 'package:c_billing/core/theme/app_theme.dart';
import 'package:c_billing/core/ui/desktop_canvas.dart';

// Premium glass toast. Mobile: top banner. Web/desktop: top-right with a bold
// spring entrance, glow pulse, icon pop, lifetime bar, and sharp exit.
class GlassyToast {
  static OverlayEntry? _currentEntry;

  static void show(
    BuildContext context,
    String message, {
    bool isError = false,
    IconData? icon,
    Duration duration = const Duration(milliseconds: 2800),
  }) {
    dismiss();

    final overlay = Overlay.maybeOf(context, rootOverlay: true) ??
        Overlay.maybeOf(context);
    if (overlay == null) {
      debugPrint('[GlassyToast] No Overlay found; message="$message"');
      return;
    }
    final mediaQuery = MediaQuery.maybeOf(context) ??
        MediaQueryData.fromView(
          WidgetsBinding.instance.platformDispatcher.views.first,
        );

    final isDark = AppColors.isDark(context);
    final corner = DesktopCanvas.isDesktopPlatform;
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _GlassyToastWidget(
        message: message,
        isError: isError,
        isDark: isDark,
        icon: icon,
        duration: duration,
        topPadding: mediaQuery.padding.top,
        cornerStyle: corner,
        onDismiss: () {
          entry.remove();
          if (_currentEntry == entry) _currentEntry = null;
        },
      ),
    );

    _currentEntry = entry;
    overlay.insert(entry);
  }

  static void dismiss() {
    _currentEntry?.remove();
    _currentEntry = null;
  }
}

class _GlassyToastWidget extends StatefulWidget {
  final String message;
  final bool isError;
  final bool isDark;
  final IconData? icon;
  final Duration duration;
  final double topPadding;
  final bool cornerStyle;
  final VoidCallback onDismiss;

  const _GlassyToastWidget({
    required this.message,
    required this.isError,
    required this.isDark,
    this.icon,
    required this.duration,
    required this.topPadding,
    required this.cornerStyle,
    required this.onDismiss,
  });

  @override
  State<_GlassyToastWidget> createState() => _GlassyToastWidgetState();
}

class _GlassyToastWidgetState extends State<_GlassyToastWidget>
    with TickerProviderStateMixin {
  late final AnimationController _enter;
  late final AnimationController _glow;
  late final AnimationController _life;

  late final Animation<Offset> _slide;
  late final Animation<double> _fade;
  late final Animation<double> _scale;
  late final Animation<double> _tilt;
  late final Animation<double> _iconPop;
  late final Animation<double> _glowPulse;
  late final Animation<double> _blurReveal;

  bool _dismissed = false;

  @override
  void initState() {
    super.initState();

    _enter = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 720),
      reverseDuration: const Duration(milliseconds: 320),
    );
    _glow = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    _life = AnimationController(vsync: this, duration: widget.duration);

    final spring = CurvedAnimation(
      parent: _enter,
      curve: const ElasticOutCurve(0.78),
      reverseCurve: Curves.easeInCubic,
    );
    final soft = CurvedAnimation(
      parent: _enter,
      curve: const Interval(0.0, 0.45, curve: Curves.easeOut),
      reverseCurve: Curves.easeIn,
    );
    final iconCurve = CurvedAnimation(
      parent: _enter,
      curve: const Interval(0.28, 0.85, curve: Curves.elasticOut),
      reverseCurve: Curves.easeIn,
    );

    _slide = Tween<Offset>(
      begin: widget.cornerStyle
          ? const Offset(1.15, -0.15)
          : const Offset(0, -1.35),
      end: Offset.zero,
    ).animate(spring);

    _fade = Tween<double>(begin: 0, end: 1).animate(soft);

    _scale = Tween<double>(
      begin: widget.cornerStyle ? 0.72 : 0.88,
      end: 1,
    ).animate(spring);

    _tilt = Tween<double>(
      begin: widget.cornerStyle ? 0.06 : -0.04,
      end: 0,
    ).animate(spring);

    _iconPop = Tween<double>(begin: 0.2, end: 1).animate(iconCurve);

    _blurReveal = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _enter,
        curve: const Interval(0.0, 0.55, curve: Curves.easeOut),
      ),
    );

    _glowPulse = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 35),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.35), weight: 65),
    ]).animate(CurvedAnimation(parent: _glow, curve: Curves.easeOut));

    _enter.forward();
    _glow.forward();
    _life.forward().whenComplete(_autoDismiss);
  }

  void _autoDismiss() {
    if (_dismissed || !mounted) return;
    _dismissed = true;
    _life.stop();
    _enter.reverse().then((_) {
      if (mounted) widget.onDismiss();
    });
  }

  @override
  void dispose() {
    _enter.dispose();
    _glow.dispose();
    _life.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isError = widget.isError;
    final isDark = widget.isDark;
    final accent = isError ? AppTheme.red800 : AppColors.action(context);
    final accentLight =
        isError ? AppTheme.error : AppTheme.paletteFF2D6A4F;
    final iconData = widget.icon ??
        (isError ? Icons.error_outline_rounded : Icons.check_rounded);
    final radius = widget.cornerStyle ? 16.0 : 18.0;

    final card = AnimatedBuilder(
      animation: Listenable.merge([_enter, _glow, _life]),
      builder: (context, _) {
        final glow = _glowPulse.value;
        final life = 1.0 - _life.value;

        return Transform(
          alignment: widget.cornerStyle
              ? Alignment.centerRight
              : Alignment.topCenter,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.001)
            ..rotateZ(_tilt.value)
            ..scaleByDouble(_scale.value, _scale.value, 1, 1),
          child: Opacity(
            opacity: _fade.value.clamp(0.0, 1.0),
            // Material ancestor required — without it Flutter draws a yellow underline on Text.
            child: Material(
              color: AppTheme.transparent,
              elevation: 0,
              shadowColor: AppTheme.transparent,
              child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(radius),
                boxShadow: [
                  BoxShadow(
                    color: accent.withValues(
                      alpha: (isDark ? 0.22 : 0.14) + glow * 0.28,
                    ),
                    blurRadius: 18 + glow * 28,
                    spreadRadius: -2 + glow * 4,
                    offset: Offset(0, 6 + glow * 4),
                  ),
                  BoxShadow(
                    color: accent.withValues(alpha: glow * 0.18),
                    blurRadius: 40 + glow * 20,
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(radius),
                child: BackdropFilter(
                  filter: ImageFilter.blur(
                    sigmaX: 8 + _blurReveal.value * 20,
                    sigmaY: 8 + _blurReveal.value * 20,
                  ),
                  child: CustomPaint(
                    foregroundPainter: GlassBevelBorderPainter(
                      isDark: false,
                      themeColor: accent,
                      radius: radius,
                      strokeWidth: 1.4 + glow * 0.6,
                    ),
                    child: Stack(
                      children: [
                        DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: isDark
                                  ? const [
                                      AppTheme.darkElevated,
                                      AppTheme.darkCard,
                                    ]
                                  : isError
                                  ? [
                                      AppTheme.white.withValues(alpha: 0.72),
                                      AppTheme.red50.withValues(alpha: 0.5),
                                    ]
                                  : [
                                      AppTheme.white.withValues(alpha: 0.7),
                                      AppTheme.white.withValues(alpha: 0.38),
                                    ],
                            ),
                          ),
                          child: Padding(
                            padding: EdgeInsets.fromLTRB(
                              widget.cornerStyle ? 18 : 18,
                              widget.cornerStyle ? 16 : 14,
                              widget.cornerStyle ? 20 : 18,
                              widget.cornerStyle ? 16 : 14,
                            ),
                            child: Row(
                              children: [
                                Transform.scale(
                                  scale: _iconPop.value,
                                  child: Transform.rotate(
                                    angle: (1 - _iconPop.value) * -0.4,
                                    child: Container(
                                      width: widget.cornerStyle ? 42 : 40,
                                      height: widget.cornerStyle ? 42 : 40,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        gradient: LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors: [accentLight, accent],
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: accent.withValues(
                                              alpha: 0.3 + glow * 0.35,
                                            ),
                                            blurRadius: 10 + glow * 14,
                                            offset: const Offset(0, 3),
                                          ),
                                        ],
                                      ),
                                      child: Icon(
                                        iconData,
                                        color: AppTheme.white,
                                        size: widget.cornerStyle ? 22 : 22,
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(width: widget.cornerStyle ? 16 : 12),
                                Expanded(
                                  child: _ToastText(
                                    message: widget.message,
                                    color: isDark ? AppTheme.white : accent,
                                    size: widget.cornerStyle ? 15 : 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        // Lifetime progress rail
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 0,
                          child: IgnorePointer(
                            child: SizedBox(
                              height: 3,
                              child: FractionallySizedBox(
                                alignment: Alignment.centerLeft,
                                widthFactor: life.clamp(0.0, 1.0),
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        accentLight.withValues(alpha: 0.95),
                                        accent.withValues(alpha: 0.85),
                                      ],
                                    ),
                                    borderRadius: const BorderRadius.only(
                                      bottomLeft: Radius.circular(99),
                                      bottomRight: Radius.circular(99),
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: accent.withValues(alpha: 0.45),
                                        blurRadius: 6,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        // Soft shimmer sweep on entrance
                        Positioned.fill(
                          child: IgnorePointer(
                            child: Opacity(
                              opacity: (1 - softClamp(_enter.value * 1.4))
                                  .clamp(0.0, 0.35),
                              child: Transform.translate(
                                offset: Offset(
                                  -80 + _enter.value * 220,
                                  0,
                                ),
                                child: Transform.rotate(
                                  angle: -math.pi / 8,
                                  child: Container(
                                    width: 56,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          AppTheme.transparent,
                                          AppTheme.white.withValues(
                                            alpha: isDark ? 0.12 : 0.35,
                                          ),
                                          AppTheme.transparent,
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
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
          ),
        );
      },
    );

    final interactive = GestureDetector(
      onHorizontalDragUpdate: widget.cornerStyle
          ? (d) {
              if ((d.primaryDelta ?? 0) > 8) _autoDismiss();
            }
          : null,
      onVerticalDragUpdate: widget.cornerStyle
          ? null
          : (d) {
              if ((d.primaryDelta ?? 0) < -5) _autoDismiss();
            },
      onTap: _autoDismiss,
      child: SlideTransition(position: _slide, child: card),
    );

    if (widget.cornerStyle) {
      final screenW = MediaQuery.sizeOf(context).width;
      // Wide corner toast — solid horizontal presence on desktop/web.
      final toastW = screenW < 720
          ? (screenW - 40).clamp(280.0, 420.0)
          : (screenW * 0.32).clamp(380.0, 480.0);
      return Positioned(
        top: widget.topPadding + 18,
        right: 22,
        child: SizedBox(width: toastW, child: interactive),
      );
    }

    return Positioned(
      top: widget.topPadding + 8,
      left: 20,
      right: 20,
      child: interactive,
    );
  }

  double softClamp(double v) => v < 0 ? 0 : (v > 1 ? 1 : v);
}

class _ToastText extends StatelessWidget {
  final String message;
  final Color color;
  final double size;

  const _ToastText({
    required this.message,
    required this.color,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      message,
      style: TextStyle(
        fontFamily: 'Literata',
        fontSize: size,
        fontWeight: FontWeight.w700,
        color: color,
        letterSpacing: 0.15,
        height: 1.25,
        decoration: TextDecoration.none,
        decorationColor: AppTheme.transparent,
      ),
      maxLines: 3,
      overflow: TextOverflow.ellipsis,
    );
  }
}

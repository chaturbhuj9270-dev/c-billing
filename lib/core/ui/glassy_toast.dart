import 'package:flutter/material.dart';
import 'package:c_billing/core/theme/app_theme.dart';

/// Top pill toast: icon + title/subtitle + close + lifetime progress bar.
class GlassyToast {
  static OverlayEntry? _currentEntry;

  static void show(
    BuildContext context,
    String message, {
    String? subtitle,
    bool isError = false,
    IconData? icon,
    Duration duration = const Duration(milliseconds: 3200),
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
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _GlassyToastWidget(
        title: message,
        subtitle: subtitle,
        isError: isError,
        isDark: isDark,
        icon: icon,
        duration: duration,
        topPadding: mediaQuery.padding.top,
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
  final String title;
  final String? subtitle;
  final bool isError;
  final bool isDark;
  final IconData? icon;
  final Duration duration;
  final double topPadding;
  final VoidCallback onDismiss;

  const _GlassyToastWidget({
    required this.title,
    this.subtitle,
    required this.isError,
    required this.isDark,
    this.icon,
    required this.duration,
    required this.topPadding,
    required this.onDismiss,
  });

  @override
  State<_GlassyToastWidget> createState() => _GlassyToastWidgetState();
}

class _GlassyToastWidgetState extends State<_GlassyToastWidget>
    with TickerProviderStateMixin {
  late final AnimationController _enter;
  late final AnimationController _life;
  late final Animation<Offset> _slide;
  late final Animation<double> _fade;
  late final Animation<double> _scale;

  bool _dismissed = false;

  @override
  void initState() {
    super.initState();

    _enter = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
      reverseDuration: const Duration(milliseconds: 240),
    );
    _life = AnimationController(vsync: this, duration: widget.duration);

    final curve = CurvedAnimation(
      parent: _enter,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );

    _slide = Tween<Offset>(
      begin: const Offset(0, -0.35),
      end: Offset.zero,
    ).animate(curve);
    _fade = Tween<double>(begin: 0, end: 1).animate(curve);
    _scale = Tween<double>(begin: 0.94, end: 1).animate(curve);

    _enter.forward();
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
    _life.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isError = widget.isError;
    final isDark = widget.isDark;
    final accent = isError ? AppTheme.toneRose : AppColors.action(context);
    final iconBg = accent.withValues(alpha: isDark ? 0.22 : 0.12);
    final iconData = widget.icon ??
        (isError ? Icons.error_outline_rounded : Icons.check_rounded);
    final screenW = MediaQuery.sizeOf(context).width;
    final toastW = (screenW - 32).clamp(280.0, 420.0);

    final card = AnimatedBuilder(
      animation: Listenable.merge([_enter, _life]),
      builder: (context, _) {
        final life = 1.0 - _life.value;
        return FadeTransition(
          opacity: _fade,
          child: ScaleTransition(
            scale: _scale,
            child: Material(
              color: AppTheme.transparent,
              child: Container(
                width: toastW,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.card(context) : AppTheme.white,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: isDark
                        ? AppColors.border(context)
                        : AppTheme.black.withValues(alpha: 0.06),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.black.withValues(
                        alpha: isDark ? 0.35 : 0.10,
                      ),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 12, 8, 14),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: iconBg,
                            ),
                            child: Icon(iconData, color: accent, size: 22),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.title,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontFamily: 'Literata',
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    height: 1.2,
                                    color: AppColors.primaryText(context),
                                    decoration: TextDecoration.none,
                                  ),
                                ),
                                if (widget.subtitle != null &&
                                    widget.subtitle!.trim().isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    widget.subtitle!,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontFamily: 'Literata',
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w500,
                                      height: 1.25,
                                      color: AppColors.mutedText(context),
                                      decoration: TextDecoration.none,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: _autoDismiss,
                            visualDensity: VisualDensity.compact,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                              minWidth: 36,
                              minHeight: 36,
                            ),
                            icon: Icon(
                              Icons.close_rounded,
                              size: 18,
                              color: AppColors.mutedText(context),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      left: 14,
                      right: 14,
                      bottom: 0,
                      child: IgnorePointer(
                        child: SizedBox(
                          height: 3,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(99),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: FractionallySizedBox(
                                widthFactor: life.clamp(0.0, 1.0),
                                child: ColoredBox(color: accent),
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
        );
      },
    );

    return Positioned(
      top: widget.topPadding + 12,
      left: 0,
      right: 0,
      child: Align(
        alignment: Alignment.topCenter,
        child: SlideTransition(
          position: _slide,
          child: GestureDetector(
            onVerticalDragUpdate: (d) {
              if ((d.primaryDelta ?? 0) < -8) _autoDismiss();
            },
            child: card,
          ),
        ),
      ),
    );
  }
}

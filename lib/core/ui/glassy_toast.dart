import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:c_billing/common_widgets/glass_bevel_frame.dart';
import 'package:c_billing/core/theme/app_theme.dart';

// A premium glassmorphic toast overlay used throughout the app. Usage: GlassyToast.show(context, 'Message here'); // success GlassyToast.show(context, 'Error!', isError: true); //...
class GlassyToast {
  static OverlayEntry? _currentEntry;

  // Show a glassy toast overlay at the top of the screen, below the status bar. [context] - BuildContext (needs Overlay ancestor) [message] - The message to display [isError] - Whet...
  static void show(
    BuildContext context,
    String message, {
    bool isError = false,
    IconData? icon,
    Duration duration = const Duration(milliseconds: 2400),
  }) {
    // Dismiss any existing toast
    dismiss();

    // Prefer the root overlay so toasts still work when called from nested navigators / post-flyout contexts.
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
        message: message,
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

  // Dismiss the currently showing toast (if any).
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
  final VoidCallback onDismiss;

  const _GlassyToastWidget({
    required this.message,
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
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _slideAnim;
  late final Animation<double> _fadeAnim;
  bool _dismissed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, -1.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));
    _fadeAnim = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _controller.forward();

    Future.delayed(widget.duration, _autoDismiss);
  }

  void _autoDismiss() {
    if (_dismissed || !mounted) return;
    _dismissed = true;
    _controller.reverse().then((_) {
      if (mounted) widget.onDismiss();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isError = widget.isError;
    final isDark = widget.isDark;
    final accentColor = isError ? AppTheme.red800 : AppColors.action(context);
    final accentColorLight = isError
        ? AppTheme.error
        : AppTheme.paletteFF2D6A4F;
    final iconData =
        widget.icon ??
        (isError ? Icons.error_outline_rounded : Icons.check_rounded);

    return Positioned(
      top: widget.topPadding + 8,
      left: 20,
      right: 20,
      child: SlideTransition(
        position: _slideAnim,
        child: FadeTransition(
          opacity: _fadeAnim,
          child: GestureDetector(
            onVerticalDragUpdate: (details) {
              if (details.primaryDelta != null && details.primaryDelta! < -4) {
                _autoDismiss();
              }
            },
            child: Material(
              color: AppTheme.transparent,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: accentColor.withValues(alpha: isDark ? 0.28 : 0.16),
                      blurRadius: 28,
                      offset: const Offset(0, 8),
                      spreadRadius: -4,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                    child: CustomPaint(
                      foregroundPainter: GlassBevelBorderPainter(
                        isDark: false,
                        themeColor: accentColor,
                        radius: 18,
                        strokeWidth: 1.4,
                      ),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: isDark
                                ? const [
                                    AppTheme.darkElevated,
                                    AppTheme.darkCard,
                                  ]
                                : isError
                                ? [
                                    AppTheme.white.withValues(alpha: 0.60),
                                    AppTheme.red50.withValues(alpha: 0.45),
                                  ]
                                : [
                                    AppTheme.white.withValues(alpha: 0.55),
                                    AppTheme.white.withValues(alpha: 0.30),
                                  ],
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 14,
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [accentColorLight, accentColor],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: accentColor.withValues(alpha: 0.35),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  iconData,
                                  color: AppTheme.white,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Text(
                                  widget.message,
                                  style: TextStyle(
                                    fontFamily: 'Literata',
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: isDark ? AppTheme.white : accentColor,
                                    letterSpacing: 0.2,
                                  ),
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
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
            ),
          ),
        ),
      ),
    );
  }
}

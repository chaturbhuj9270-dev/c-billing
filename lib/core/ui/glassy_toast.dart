import 'dart:ui';
import 'package:flutter/material.dart';

/// A premium glassmorphic toast overlay used throughout the app.
///
/// Usage:
///   GlassyToast.show(context, 'Message here');                    // success
///   GlassyToast.show(context, 'Error!', isError: true);           // error
///   GlassyToast.show(context, 'Info', isError: false, icon: Icons.info); // custom icon
class GlassyToast {
  static OverlayEntry? _currentEntry;

  /// Show a glassy toast overlay at the bottom of the screen.
  ///
  /// [context] - BuildContext (needs Overlay ancestor)
  /// [message] - The message to display
  /// [isError] - Whether this is an error toast (red) or success (green)
  /// [icon] - Optional custom icon override
  /// [duration] - How long to show the toast before auto-dismiss
  static void show(
    BuildContext context,
    String message, {
    bool isError = false,
    IconData? icon,
    Duration duration = const Duration(milliseconds: 2400),
  }) {
    // Dismiss any existing toast
    dismiss();

    final overlay = Overlay.of(context);
    final mediaQuery = MediaQuery.of(context);

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _GlassyToastWidget(
        message: message,
        isError: isError,
        icon: icon,
        duration: duration,
        bottomPadding: mediaQuery.padding.bottom,
        onDismiss: () {
          entry.remove();
          if (_currentEntry == entry) _currentEntry = null;
        },
      ),
    );

    _currentEntry = entry;
    overlay.insert(entry);
  }

  /// Dismiss the currently showing toast (if any).
  static void dismiss() {
    _currentEntry?.remove();
    _currentEntry = null;
  }
}

class _GlassyToastWidget extends StatefulWidget {
  final String message;
  final bool isError;
  final IconData? icon;
  final Duration duration;
  final double bottomPadding;
  final VoidCallback onDismiss;

  const _GlassyToastWidget({
    required this.message,
    required this.isError,
    this.icon,
    required this.duration,
    required this.bottomPadding,
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
      begin: const Offset(0, 1.2),
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
    final accentColor = isError
        ? const Color(0xFFC62828)
        : const Color(0xFF1B4D3E);
    final accentColorLight = isError
        ? const Color(0xFFEF5350)
        : const Color(0xFF2D6A4F);
    final iconData =
        widget.icon ??
        (isError ? Icons.error_outline_rounded : Icons.check_rounded);

    return Positioned(
      bottom: widget.bottomPadding + 24,
      left: 20,
      right: 20,
      child: SlideTransition(
        position: _slideAnim,
        child: FadeTransition(
          opacity: _fadeAnim,
          child: GestureDetector(
            onVerticalDragUpdate: (details) {
              if (details.primaryDelta != null && details.primaryDelta! > 4) {
                _autoDismiss();
              }
            },
            child: Material(
              color: Colors.transparent,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: isError
                            ? [
                                Colors.white.withValues(alpha: 0.60),
                                const Color(0xFFFFEBEE).withValues(alpha: 0.45),
                              ]
                            : [
                                Colors.white.withValues(alpha: 0.55),
                                Colors.white.withValues(alpha: 0.30),
                              ],
                      ),
                      border: Border.all(
                        color: isError
                            ? const Color(0xFFEF9A9A).withValues(alpha: 0.5)
                            : Colors.white.withValues(alpha: 0.6),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: accentColor.withValues(alpha: 0.16),
                          blurRadius: 28,
                          offset: const Offset(0, 8),
                          spreadRadius: -4,
                        ),
                        BoxShadow(
                          color: Colors.white.withValues(alpha: 0.7),
                          blurRadius: 1,
                          offset: const Offset(0, -1),
                        ),
                      ],
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
                          child: Icon(iconData, color: Colors.white, size: 22),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            widget.message,
                            style: TextStyle(
                              fontFamily: 'Literata',
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: accentColor,
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
    );
  }
}

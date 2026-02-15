import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'package:c_billing/core/services/language_service.dart';
import 'package:c_billing/core/localization/app_localizations.dart';

/// World-class UI/UX Action Menu for settings, language, and bug reporting
/// Features:
/// - Smooth reveal animation with backdrop blur
/// - Icon + label design for each action
/// - Responsive positioning (top-right corner)
/// - Hover effects and smooth transitions
/// - Professional typography and spacing
/// - Glass morphism effect for modern look
class ActionMenu extends StatefulWidget {
  final VoidCallback? onSettingsTap;
  final VoidCallback? onLanguageTap;
  final VoidCallback? onBugReportTap;
  final Color menuColor;
  final Color iconColor;
  final double iconSize;

  const ActionMenu({
    super.key,
    this.onSettingsTap,
    this.onLanguageTap,
    this.onBugReportTap,
    this.menuColor = const Color(0xFF1B4D3E),
    this.iconColor = Colors.white,
    this.iconSize = 24,
  });

  @override
  State<ActionMenu> createState() => _ActionMenuState();
}

class _ActionMenuState extends State<ActionMenu>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _rotateAnimation;
  late Animation<double> _backdropOpacity;

  bool _isMenuOpen = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 350),
      vsync: this,
    );

    // Scale animation for menu appearance
    _scaleAnimation = Tween<double>(begin: 0.75, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    );

    // Opacity animation for smooth fade-in
    _opacityAnimation = Tween<double>(begin: 0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );

    // Slide animation from top-right
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.15, -0.15),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    );

    // Rotation animation for menu button
    _rotateAnimation = Tween<double>(begin: 0, end: 0.75).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    );

    // Backdrop opacity animation
    _backdropOpacity = Tween<double>(begin: 0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _toggleMenu() {
    if (_isMenuOpen) {
      _animController.reverse();
    } else {
      _animController.forward();
    }
    setState(() => _isMenuOpen = !_isMenuOpen);
  }

  void _closeMenu() {
    if (_isMenuOpen) {
      _animController.reverse();
      setState(() => _isMenuOpen = false);
    }
  }

  void _handleAction(VoidCallback? onTap) {
    _closeMenu();
    Future.delayed(const Duration(milliseconds: 200), () {
      onTap?.call();
    });
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(
      LanguageService.instance.currentLanguage,
    );

    return Stack(
      children: [
        // Animated backdrop overlay
        if (_isMenuOpen)
          Positioned.fill(
            child: GestureDetector(
              onTap: _closeMenu,
              child: FadeTransition(
                opacity: _backdropOpacity,
                child: Container(
                  color: Colors.black26,
                ),
              ),
            ),
          ),
        // Menu button and dropdown
        Positioned(
          right: 16,
          top: 8,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Menu trigger button with enhanced styling
              GestureDetector(
                onTap: _toggleMenu,
                child: _buildMenuButton(),
              ),
              const SizedBox(height: 12),
              // Animated dropdown menu
              ScaleTransition(
                scale: _scaleAnimation,
                alignment: Alignment.topRight,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: FadeTransition(
                    opacity: _opacityAnimation,
                    child: _buildDropdownMenu(localizations),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Build the menu trigger button with rotation animation
  Widget _buildMenuButton() {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: widget.menuColor,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: widget.menuColor.withValues(alpha: 0.4),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: widget.menuColor.withValues(alpha: 0.2),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _toggleMenu,
          borderRadius: BorderRadius.circular(24),
          child: Center(
            child: RotationTransition(
              turns: _rotateAnimation,
              child: Icon(
                Icons.more_vert_rounded,
                color: widget.iconColor,
                size: widget.iconSize,
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Build the dropdown menu with glass morphism effect
  Widget _buildDropdownMenu(AppLocalizations localizations) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.3),
              width: 1.5,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Menu header with icon
              Container(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      widget.menuColor.withValues(alpha: 0.08),
                      widget.menuColor.withValues(alpha: 0.03),
                    ],
                  ),
                  border: Border(
                    bottom: BorderSide(
                      color: Colors.grey[200]!,
                      width: 1,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.tune_rounded,
                      color: widget.menuColor,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      localizations.options,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: widget.menuColor,
                        fontFamily: 'Literata',
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
              // Menu items
              if (widget.onSettingsTap != null)
                _buildMenuItem(
                  icon: Icons.settings_rounded,
                  label: localizations.settings,
                  onTap: () => _handleAction(widget.onSettingsTap),
                  isFirst: true,
                ),
              if (widget.onLanguageTap != null)
                _buildMenuItem(
                  icon: Icons.language_rounded,
                  label: localizations.language,
                  onTap: () => _handleAction(widget.onLanguageTap),
                ),
              if (widget.onBugReportTap != null)
                _buildMenuItem(
                  icon: Icons.bug_report_rounded,
                  label: localizations.reportIssue,
                  onTap: () => _handleAction(widget.onBugReportTap),
                  isLast: true,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isFirst = false,
    bool isLast = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        hoverColor: widget.menuColor.withValues(alpha: 0.05),
        splashColor: widget.menuColor.withValues(alpha: 0.1),
        child: Container(
          decoration: BoxDecoration(
            border: isLast
                ? null
                : Border(
                    bottom: BorderSide(
                      color: Colors.grey[100]!,
                      width: 0.8,
                    ),
                  ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon with background - enhanced styling
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: widget.menuColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: widget.menuColor.withValues(alpha: 0.1),
                      width: 1,
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      icon,
                      color: widget.menuColor,
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Label with enhanced typography
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1B4D3E),
                    fontFamily: 'Literata',
                    letterSpacing: 0.2,
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

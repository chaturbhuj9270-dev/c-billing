import 'package:flutter/material.dart';
import 'package:c_billing/core/services/language_service.dart';
import 'package:c_billing/core/localization/app_localizations.dart';

/// World-class UI/UX Action Menu for settings, language, and bug reporting
/// Features:
/// - Smooth reveal animation with backdrop blur
/// - Icon + label design for each action
/// - Responsive positioning (top-right corner)
/// - Hover effects and smooth transitions
/// - Professional typography and spacing
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

  bool _isMenuOpen = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    );

    _opacityAnimation = Tween<double>(begin: 0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.2, -0.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
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
    onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(
      LanguageService.instance.currentLanguage,
    );

    return Stack(
      children: [
        // Backdrop - semi-transparent overlay to close menu
        if (_isMenuOpen)
          Positioned.fill(
            child: GestureDetector(
              onTap: _closeMenu,
              child: Container(
                color: Colors.transparent,
              ),
            ),
          ),
        // Menu button and dropdown
        Positioned(
          right: 0,
          top: 0,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Menu trigger button
              GestureDetector(
                onTap: _toggleMenu,
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: widget.menuColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: widget.menuColor.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Icon(
                      _isMenuOpen ? Icons.close : Icons.more_vert,
                      color: widget.iconColor,
                      size: widget.iconSize,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Dropdown menu with animation
              ScaleTransition(
                scale: _scaleAnimation,
                alignment: Alignment.topRight,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: FadeTransition(
                    opacity: _opacityAnimation,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Menu header with gradient
                            Container(
                              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    widget.menuColor.withValues(alpha: 0.05),
                                    widget.menuColor.withValues(alpha: 0.02),
                                  ],
                                ),
                                border: Border(
                                  bottom: BorderSide(
                                    color: Colors.grey[200]!,
                                    width: 0.5,
                                  ),
                                ),
                              ),
                              child: Text(
                                localizations.options,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey[600],
                                  fontFamily: 'Literata',
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            // Menu items
                            if (widget.onSettingsTap != null)
                              _buildMenuItem(
                                icon: Icons.settings_rounded,
                                label: localizations.settings,
                                onTap: () =>
                                    _handleAction(widget.onSettingsTap),
                                isFirst: true,
                              ),
                            if (widget.onLanguageTap != null)
                              _buildMenuItem(
                                icon: Icons.language_rounded,
                                label: localizations.language,
                                onTap: () =>
                                    _handleAction(widget.onLanguageTap),
                              ),
                            if (widget.onBugReportTap != null)
                              _buildMenuItem(
                                icon: Icons.bug_report_rounded,
                                label: localizations.reportIssue,
                                onTap: () =>
                                    _handleAction(widget.onBugReportTap),
                                isLast: true,
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
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
        child: Container(
          decoration: BoxDecoration(
            border: isLast
                ? null
                : Border(
                    bottom: BorderSide(
                      color: Colors.grey[100]!,
                      width: 0.5,
                    ),
                  ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon with background
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: widget.menuColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Icon(
                      icon,
                      color: widget.menuColor,
                      size: 18,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Label
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF1B4D3E),
                    fontFamily: 'Literata',
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

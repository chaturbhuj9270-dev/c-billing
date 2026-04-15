import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../core/auth/hotel_auth_service.dart';
import '../../../../core/services/biometric_service.dart';
import '../../../../core/services/language_service.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/services/error_logging_service.dart';
import '../../../authentication/presentation/pages/login.dart';
import '../../../authentication/presentation/pages/change_password_page.dart';
import 'package:c_billing/core/ui/glassy_toast.dart';

class HotelFlyoutMenu extends StatefulWidget {
  const HotelFlyoutMenu({super.key});

  @override
  State<HotelFlyoutMenu> createState() => _HotelFlyoutMenuState();
}

class _HotelFlyoutMenuState extends State<HotelFlyoutMenu>
    with TickerProviderStateMixin {
  final _firebaseAuth = FirebaseAuth.instance;
  final _auth = HotelAuthService.instance;
  late User? _currentUser;
  String _userName = 'User';
  String _selectedLanguage = 'English';
  bool _biometricLockEnabled = false;
  bool _canUseBiometrics = false;
  late AppLocalizations _localizations;

  // Animation controllers
  late AnimationController _slideController;
  late AnimationController _staggerController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  late List<Animation<Offset>> _menuItemAnimations;
  late List<Animation<double>> _menuItemFadeAnimations;

  // Menu items
  final List<_MenuItem> _menuItems = [
    const _MenuItem(
      icon: Icons.person_rounded,
      label: 'Profile',
      route: 'Profile',
      color: Color(0xFF2E7D32),
    ),
    const _MenuItem(
      icon: Icons.hotel_rounded,
      label: 'Hotel Details',
      route: 'HotelDetails',
      color: Color(0xFF1976D2),
    ),
    const _MenuItem(
      icon: Icons.lock_reset_rounded,
      label: 'Change Password',
      route: 'ChangePassword',
      color: Color(0xFFE65100),
    ),
    const _MenuItem(
      icon: Icons.language_rounded,
      label: 'Language',
      route: 'Language',
      color: Color(0xFFFF6F00),
    ),
  ];

  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _localizations = AppLocalizations(LanguageService.instance.currentLanguage);
    _currentUser = _firebaseAuth.currentUser;
    _userName = _currentUser?.displayName ?? 'User';
    _selectedLanguage = LanguageService.instance.currentLanguage;
    _loadBiometricStatus();

    // Main slide animation
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(-1, 0), end: Offset.zero).animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
        );

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _slideController,
        curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
      ),
    );

    // Staggered menu item animations
    _staggerController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _menuItemAnimations = List.generate(_menuItems.length, (index) {
      final start = index * 0.08;
      final end = start + 0.4;
      return Tween<Offset>(
        begin: const Offset(-0.5, 0),
        end: Offset.zero,
      ).animate(
        CurvedAnimation(
          parent: _staggerController,
          curve: Interval(
            start.clamp(0.0, 1.0),
            end.clamp(0.0, 1.0),
            curve: Curves.easeOutCubic,
          ),
        ),
      );
    });

    _menuItemFadeAnimations = List.generate(_menuItems.length, (index) {
      final start = index * 0.08;
      final end = start + 0.4;
      return Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(
          parent: _staggerController,
          curve: Interval(
            start.clamp(0.0, 1.0),
            end.clamp(0.0, 1.0),
            curve: Curves.easeOut,
          ),
        ),
      );
    });

    _slideController.forward();
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _staggerController.forward();
    });
  }

  @override
  void dispose() {
    _slideController.dispose();
    _staggerController.dispose();
    super.dispose();
  }

  Future<void> _loadBiometricStatus() async {
    try {
      final biometricService = BiometricService.instance;
      final canUse = await biometricService.canUseBiometrics();
      final isEnabled = await biometricService.isBiometricLockEnabled();
      if (mounted) {
        setState(() {
          _canUseBiometrics = canUse;
          _biometricLockEnabled = isEnabled;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _canUseBiometrics = false;
          _biometricLockEnabled = false;
        });
      }
    }
  }

  Future<void> _toggleBiometricLock(bool enabled) async {
    final biometricService = BiometricService.instance;
    await biometricService.setBiometricLockEnabled(enabled);
    if (mounted) {
      setState(() {
        _biometricLockEnabled = enabled;
      });
      GlassyToast.show(
        context,
        enabled
            ? _localizations.biometricEnabled
            : _localizations.biometricDisabled,
      );
    }
  }

  void _logout() {
    _auth.clearSession();
    _firebaseAuth.signOut();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPageV2()),
      (_) => false,
    );
  }

  void _navigateToPage(String pageName, int index) {
    setState(() {
      _selectedIndex = index;
    });

    Future.delayed(const Duration(milliseconds: 150), () {
      Navigator.pop(context);
      switch (pageName) {
        case 'Profile':
          GlassyToast.show(context, 'Profile page coming soon');
          break;
        case 'HotelDetails':
          GlassyToast.show(context, 'Hotel details coming soon');
          break;
        case 'ChangePassword':
          Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const ChangePasswordPage()));
          break;
        case 'Language':
          _showLanguageDialog();
          break;
      }
    });
  }

  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) => _LanguageDialog(
        currentLanguage: _selectedLanguage,
        onLanguageSelected: (language) async {
          await LanguageService.instance.setLanguage(language);
          if (mounted) {
            setState(() {
              _selectedLanguage = language;
            });
            GlassyToast.show(
              context,
              '${_localizations.languageChangedTo} $language',
            );
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final menuWidth = screenWidth >= 800
        ? (screenWidth * 0.35).clamp(350.0, 480.0)
        : screenWidth * 0.95;

    return SlideTransition(
      position: _slideAnimation,
      child: Container(
        width: menuWidth,
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 30,
              offset: const Offset(5, 0),
            ),
          ],
        ),
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: ListView(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  children: [
                    ...List.generate(_menuItems.length, (index) {
                      return SlideTransition(
                        position: _menuItemAnimations[index],
                        child: FadeTransition(
                          opacity: _menuItemFadeAnimations[index],
                          child: _buildMenuItem(
                            item: _menuItems[index],
                            index: index,
                            isSelected: _selectedIndex == index,
                          ),
                        ),
                      );
                    }),
                    if (_canUseBiometrics) _buildBiometricToggle(),
                  ],
                ),
              ),
            ),
            FadeTransition(
              opacity: _fadeAnimation,
              child: _buildBottomSection(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final isAdmin = _auth.isAdmin;
    final role = isAdmin ? null : _auth.currentSubUser?.role;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1B4D3E), Color(0xFF0F3B2F), Color(0xFF134E3A)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1B4D3E).withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Hotel logo avatar
                  Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFF4CAF50),
                          Color(0xFF81C784),
                          Color(0xFF4CAF50),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF4CAF50).withValues(alpha: 0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF1B4D3E),
                        border: Border.all(
                          color: const Color(0xFF1B4D3E),
                          width: 2,
                        ),
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          'assets/images/hotel_logo.png',
                          width: 30,
                          height: 30,
                          fit: BoxFit.contain,
                          errorBuilder: (_, _, _) => Text(
                            _userName.isNotEmpty
                                ? _userName[0].toUpperCase()
                                : 'H',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              fontFamily: 'Literata',
                              decoration: TextDecoration.none,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _userName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'Literata',
                            letterSpacing: 0.3,
                            decoration: TextDecoration.none,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Color(0xFF4CAF50),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    isAdmin
                                        ? 'Admin'
                                        : role?.name.toUpperCase() ?? 'Staff',
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                      fontFamily: 'Literata',
                                      decoration: TextDecoration.none,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required _MenuItem item,
    required int index,
    required bool isSelected,
  }) {
    return GestureDetector(
      onTap: () => _navigateToPage(item.route, index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? item.color.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: isSelected
              ? Border.all(color: item.color.withValues(alpha: 0.3))
              : null,
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: isSelected
                    ? LinearGradient(
                        colors: [item.color, item.color.withValues(alpha: 0.7)],
                      )
                    : null,
                color: isSelected ? null : item.color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: item.color.withValues(alpha: 0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: Icon(
                item.icon,
                color: isSelected ? Colors.white : item.color,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                item.label,
                style: TextStyle(
                  color: isSelected ? item.color : const Color(0xFF333333),
                  fontSize: 16,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  fontFamily: 'Literata',
                  decoration: TextDecoration.none,
                ),
              ),
            ),
            AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: isSelected ? 1.0 : 0.0,
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: item.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: item.color,
                  size: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBiometricToggle() {
    const biometricColor = Color(0xFF2E7D32);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: _biometricLockEnabled
            ? biometricColor.withValues(alpha: 0.1)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        border: _biometricLockEnabled
            ? Border.all(color: biometricColor.withValues(alpha: 0.3))
            : null,
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: _biometricLockEnabled
                  ? LinearGradient(
                      colors: [
                        biometricColor,
                        biometricColor.withValues(alpha: 0.7),
                      ],
                    )
                  : null,
              color: _biometricLockEnabled
                  ? null
                  : biometricColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              boxShadow: _biometricLockEnabled
                  ? [
                      BoxShadow(
                        color: biometricColor.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Icon(
              Icons.fingerprint,
              color: _biometricLockEnabled ? Colors.white : biometricColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _localizations.biometricLock,
              style: TextStyle(
                color: _biometricLockEnabled
                    ? biometricColor
                    : const Color(0xFF333333),
                fontSize: 14,
                fontWeight: _biometricLockEnabled
                    ? FontWeight.w600
                    : FontWeight.w500,
                fontFamily: 'Literata',
                decoration: TextDecoration.none,
              ),
            ),
          ),
          Transform.scale(
            scale: 0.8,
            child: Material(
              color: Colors.transparent,
              child: Switch(
                value: _biometricLockEnabled,
                onChanged: (value) => _toggleBiometricLock(value),
                activeTrackColor: biometricColor.withValues(alpha: 0.5),
                activeThumbColor: biometricColor,
                inactiveTrackColor: Colors.grey[300],
                inactiveThumbColor: Colors.grey[400],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomSection() {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                // Error Logs Button
                Expanded(
                  child: GestureDetector(
                    onTap: () => ErrorLoggingService.showLogsDialog(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.bug_report_outlined,
                            color: Colors.grey[600],
                            size: 18,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _localizations.logs,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              fontFamily: 'Literata',
                              decoration: TextDecoration.none,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // Logout Button
                Expanded(
                  flex: 2,
                  child: GestureDetector(
                    onTap: _logout,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFFD32F2F).withValues(alpha: 0.1),
                            const Color(0xFFD32F2F).withValues(alpha: 0.05),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: const Color(0xFFD32F2F).withValues(alpha: 0.2),
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.logout_rounded,
                            color: Color(0xFFD32F2F),
                            size: 18,
                          ),
                          SizedBox(width: 6),
                          Text(
                            'Logout',
                            style: TextStyle(
                              color: Color(0xFFD32F2F),
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Literata',
                              decoration: TextDecoration.none,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _localizations.version,
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 12,
                fontFamily: 'Literata',
                decoration: TextDecoration.none,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuItem {
  final IconData icon;
  final String label;
  final String route;
  final Color color;

  const _MenuItem({
    required this.icon,
    required this.label,
    required this.route,
    required this.color,
  });
}

class _LanguageDialog extends StatelessWidget {
  final String currentLanguage;
  final Function(String) onLanguageSelected;

  const _LanguageDialog({
    required this.currentLanguage,
    required this.onLanguageSelected,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFFF6F00).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.language_rounded,
              color: Color(0xFFFF6F00),
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            AppLocalizations(
              LanguageService.instance.currentLanguage,
            ).selectLanguage,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              fontFamily: 'Literata',
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildLanguageOption(context, 'English', '🇬🇧', 'English'),
          const SizedBox(height: 12),
          _buildLanguageOption(context, 'Hindi', '🇮🇳', 'हिंदी'),
          const SizedBox(height: 12),
          _buildLanguageOption(context, 'Marathi', '🇮🇳', 'मराठी'),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            AppLocalizations(LanguageService.instance.currentLanguage).cancel,
            style: const TextStyle(color: Colors.grey, fontFamily: 'Literata'),
          ),
        ),
      ],
    );
  }

  Widget _buildLanguageOption(
    BuildContext context,
    String language,
    String flag,
    String nativeName,
  ) {
    final isSelected = currentLanguage == language;

    return GestureDetector(
      onTap: () {
        Navigator.of(context).pop();
        onLanguageSelected(language);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFFF6F00).withValues(alpha: 0.1)
              : Colors.grey.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? const Color(0xFFFF6F00)
                : Colors.grey.withValues(alpha: 0.2),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Text(flag, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    language,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w500,
                      fontFamily: 'Literata',
                      color: isSelected
                          ? const Color(0xFFFF6F00)
                          : Colors.black87,
                    ),
                  ),
                  Text(
                    nativeName,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                      fontFamily: 'Literata',
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Color(0xFFFF6F00),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 16),
              ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/services/language_service.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/services/biometric_service.dart';
import '../../../../core/services/logout_service.dart';
import '../../../../features/authentication/presentation/pages/change_password_page.dart';
import '../../../../common_widgets/water_drop_effect.dart';
import 'profile_page.dart';
import '../../../supplier/presentation/pages/enhanced_supplier_page.dart';
import '../../../customer/presentation/pages/enhanced_customer_page.dart';
import '../../../company/presentation/pages/enhanced_company_page.dart';
import '../../../inventory_management/presentation/pages/enhanced_purchase_screen.dart';
import '../../../inventory_management/presentation/pages/enhanced_product_page.dart';
import '../../../shop/presentation/pages/shop_details_page.dart';
import '../../../expense/presentation/pages/expenses_page.dart';
import 'package:c_billing/core/ui/glassy_toast.dart';

class FlyoutMenu extends StatefulWidget {
  const FlyoutMenu({super.key});

  @override
  State<FlyoutMenu> createState() => _FlyoutMenuState();
}

class _FlyoutMenuState extends State<FlyoutMenu> with TickerProviderStateMixin {
  final _auth = FirebaseAuth.instance;
  late User? _currentUser;
  String _userName = 'User';
  String _selectedLanguage = 'English'; // Default language
  bool _biometricLockEnabled = false;
  bool _canUseBiometrics = false;
  late AppLocalizations _localizations;

  // Animation controllers
  late AnimationController _slideController;
  late AnimationController _staggerController;
  late AnimationController _dropController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  late List<Animation<Offset>> _menuItemAnimations;
  late List<Animation<double>> _menuItemFadeAnimations;
  Offset? _dropOrigin;
  final GlobalKey _panelKey = GlobalKey();
  static const _accent = Color(0xFF1B4D3E);

  // Menu items with icons and colors
  final List<_MenuItem> _menuItems = [
    _MenuItem(
      icon: Icons.person_rounded,
      label: 'Profile',
      route: 'Profile',
      color: const Color(0xFF2E7D32),
    ),
    _MenuItem(
      icon: Icons.store_rounded,
      label: 'Shop Details',
      route: 'ShopDetails',
      color: const Color(0xFF1976D2),
    ),
    _MenuItem(
      icon: Icons.account_balance_wallet_rounded,
      label: 'Expenses',
      route: 'Expenses',
      color: const Color(0xFFD32F2F),
    ),
    _MenuItem(
      icon: Icons.lock_reset_rounded,
      label: 'Change Password',
      route: 'ChangePassword',
      color: const Color(0xFFE65100),
    ),
    _MenuItem(
      icon: Icons.language_rounded,
      label: 'Language',
      route: 'Language',
      color: const Color(0xFFFF6F00),
    ),
  ];

  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _localizations = AppLocalizations(LanguageService.instance.currentLanguage);
    _currentUser = _auth.currentUser;
    _userName = _resolveUserName(_currentUser);
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

    _dropController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    // Start animations
    _slideController.forward();
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) {
        _staggerController.forward();
      }
    });
  }

  @override
  void dispose() {
    _slideController.dispose();
    _staggerController.dispose();
    _dropController.dispose();
    super.dispose();
  }

  void _triggerWaterDrop(Offset globalPosition) {
    final box = _panelKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;
    setState(() => _dropOrigin = box.globalToLocal(globalPosition));
    _dropController.forward(from: 0);
  }

  String _resolveUserName(User? user) {
    final displayName = user?.displayName?.trim();
    if (displayName != null && displayName.isNotEmpty) return displayName;
    final email = user?.email?.trim();
    if (email != null && email.isNotEmpty) {
      return email.contains('@') ? email.split('@').first : email;
    }
    return 'User';
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
      print('[ERROR] Failed to load biometric status: $e');
      // Default to not showing biometric option if there's an error
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
    // Use centralized logout service to ensure all local data is cleared
    LogoutService.instance.logout(context);
  }

  void _navigateToPage(String pageName, int index, {Offset? tapPosition}) {
    if (tapPosition != null) {
      HapticFeedback.lightImpact();
      _triggerWaterDrop(tapPosition);
    }
    setState(() {
      _selectedIndex = index;
    });

    // Slightly longer delay so the water-drop splash is visible before closing.
    Future.delayed(const Duration(milliseconds: 280), () {
      if (!mounted) return;
      Navigator.pop(context);
      switch (pageName) {
        case 'Home':
          break;
        case 'Invoices':
          GlassyToast.show(context, 'Invoices page coming soon');
          break;
        case 'Clients':
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const EnhancedCustomerPage()),
          );
          break;
        case 'Suppliers':
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const EnhancedSupplierPage()),
          );
          break;
        case 'Companies':
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const EnhancedCompanyPage()),
          );
          break;
        case 'Purchases':
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const EnhancedPurchaseScreen()),
          );
          break;
        case 'Inventory':
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const EnhancedProductPage()),
          );
          break;
        case 'Reports':
          GlassyToast.show(context, 'Reports page coming soon');
          break;
        case 'Profile':
          Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const ProfilePage()));
          break;
        case 'ShopDetails':
          Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const ShopDetailsPage()));
          break;
        case 'Expenses':
          Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const ExpensesPage()));
          break;
        case 'ChangePassword':
          Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const ChangePasswordPage()));
          break;
        case 'Language':
          _showLanguageDialog();
          break;
        case 'Settings':
          _showSettingsDialog();
          break;
      }
    });
  }

  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) => _SettingsDialog(
        biometricLockEnabled: _biometricLockEnabled,
        canUseBiometrics: _canUseBiometrics,
        onBiometricToggle: _toggleBiometricLock,
      ),
    );
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
    return SlideTransition(
      position: _slideAnimation,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 10, 0, 10),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.horizontal(
              right: Radius.circular(28),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.14),
                blurRadius: 28,
                offset: const Offset(6, 0),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 10,
                offset: const Offset(2, 0),
              ),
            ],
          ),
          child: ClipRRect(
            key: _panelKey,
            borderRadius: const BorderRadius.horizontal(
              right: Radius.circular(28),
            ),
            child: SizedBox(
              width: double.infinity,
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white.withValues(alpha: 0.92),
                          const Color(0xFFE8F0F5).withValues(alpha: 0.88),
                          _accent.withValues(alpha: 0.14),
                        ],
                      ),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.8),
                        width: 1.1,
                      ),
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
                  // Water-drop splash over the glass panel
                  Positioned.fill(
                    child: IgnorePointer(
                      child: AnimatedBuilder(
                        animation: _dropController,
                        builder: (context, _) {
                          return CustomPaint(
                            painter: WaterDropPainter(
                              origin: _dropOrigin,
                              progress: _dropController.value,
                              accentColor: _accent,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    // Keep the header opaque enough that white username text stays readable
    // on the glassy flyout panel.
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1B4D3E), Color(0xFF0F3B2F), Color(0xFF134E3A)],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Row(
            children: [
              // Premium Profile Avatar with ring
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
                  child: Center(
                    child: Text(
                      _userName.isNotEmpty ? _userName[0].toUpperCase() : 'U',
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
              const SizedBox(width: 12),
              // User Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _userName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Literata',
                        letterSpacing: 0.3,
                        decoration: TextDecoration.none,
                        shadows: [
                          Shadow(
                            color: Color(0x66000000),
                            blurRadius: 4,
                            offset: Offset(0, 1),
                          ),
                        ],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (_currentUser?.email != null &&
                        _currentUser!.email!.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        _currentUser!.email!,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          fontFamily: 'Literata',
                          decoration: TextDecoration.none,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
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
                            _localizations.online,
                            style: const TextStyle(
                              color: Colors.white,
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
      behavior: HitTestBehavior.opaque,
      onTapDown: (details) => _navigateToPage(
        item.route,
        index,
        tapPosition: details.globalPosition,
      ),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withValues(alpha: 0.55),
                    item.color.withValues(alpha: 0.18),
                  ],
                )
              : null,
          color: isSelected ? null : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? Colors.white.withValues(alpha: 0.65)
                : Colors.transparent,
            width: 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: item.color.withValues(alpha: 0.22),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: isSelected
                    ? LinearGradient(
                        colors: [item.color, item.color.withValues(alpha: 0.7)],
                      )
                    : null,
                color: isSelected
                    ? null
                    : item.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: Colors.white.withValues(alpha: isSelected ? 0.35 : 0.2),
                ),
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
                  color: item.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.4),
                  ),
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
        gradient: _biometricLockEnabled
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withValues(alpha: 0.45),
                  biometricColor.withValues(alpha: 0.14),
                ],
              )
            : null,
        color: _biometricLockEnabled ? null : Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _biometricLockEnabled
              ? Colors.white.withValues(alpha: 0.55)
              : Colors.transparent,
        ),
      ),
      child: Row(
        children: [
          // Icon with gradient background when enabled
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
          // Toggle Switch
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
      padding: const EdgeInsets.fromLTRB(14, 20, 14, 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white.withValues(alpha: 0.15),
            Colors.white.withValues(alpha: 0.35),
          ],
        ),
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.45)),
        ),
      ),
      child: SafeArea(
        top: false,
        minimum: const EdgeInsets.only(bottom: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            GestureDetector(
              onTapDown: (details) {
                _triggerWaterDrop(details.globalPosition);
                Future.delayed(const Duration(milliseconds: 220), () {
                  if (mounted) _logout();
                });
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFD32F2F),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFD32F2F).withValues(alpha: 0.35),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.logout_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                    SizedBox(width: 6),
                    Text(
                      'Logout',
                      style: TextStyle(
                        color: Colors.white,
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
            const SizedBox(height: 12),
            Text(
              _localizations.version,
              style: TextStyle(
                color: Colors.grey[500],
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

class _SettingsDialog extends StatefulWidget {
  final bool biometricLockEnabled;
  final bool canUseBiometrics;
  final Function(bool) onBiometricToggle;

  const _SettingsDialog({
    required this.biometricLockEnabled,
    required this.canUseBiometrics,
    required this.onBiometricToggle,
  });

  @override
  State<_SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends State<_SettingsDialog> {
  late bool _biometricEnabled;

  @override
  void initState() {
    super.initState();
    _biometricEnabled = widget.biometricLockEnabled;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF78909C).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.settings_rounded,
              color: Color(0xFF78909C),
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            AppLocalizations(LanguageService.instance.currentLanguage).settings,
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
          // Biometric Lock Toggle
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: widget.canUseBiometrics
                  ? (_biometricEnabled
                        ? const Color(0xFF2E7D32).withValues(alpha: 0.1)
                        : Colors.grey.withValues(alpha: 0.05))
                  : Colors.grey.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: widget.canUseBiometrics && _biometricEnabled
                    ? const Color(0xFF2E7D32)
                    : Colors.grey.withValues(alpha: 0.2),
                width: _biometricEnabled ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: widget.canUseBiometrics
                        ? const Color(0xFF2E7D32).withValues(alpha: 0.1)
                        : Colors.grey.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.fingerprint,
                    color: widget.canUseBiometrics
                        ? const Color(0xFF2E7D32)
                        : Colors.grey,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppLocalizations(
                          LanguageService.instance.currentLanguage,
                        ).biometricLock,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Literata',
                          color: widget.canUseBiometrics
                              ? Colors.black87
                              : Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.canUseBiometrics
                            ? AppLocalizations(
                                LanguageService.instance.currentLanguage,
                              ).unlockWithBiometric
                            : AppLocalizations(
                                LanguageService.instance.currentLanguage,
                              ).biometricsNotAvailable,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontFamily: 'Literata',
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: _biometricEnabled,
                  onChanged: widget.canUseBiometrics
                      ? (value) {
                          setState(() {
                            _biometricEnabled = value;
                          });
                          widget.onBiometricToggle(value);
                        }
                      : null,
                  activeThumbColor: const Color(0xFF2E7D32),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            AppLocalizations(LanguageService.instance.currentLanguage).close,
            style: const TextStyle(
              color: Color(0xFF78909C),
              fontFamily: 'Literata',
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

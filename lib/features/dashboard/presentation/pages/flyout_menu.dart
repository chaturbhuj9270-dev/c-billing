import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/services/language_service.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/services/biometric_service.dart';
import '../../../../core/services/logout_service.dart';
import '../../../../features/authentication/presentation/pages/change_password_page.dart';
import '../../../../common_widgets/water_drop_effect.dart';
import '../../../../core/services/theme_service.dart';
import '../../../../core/theme/app_theme.dart';
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
      color: AppTheme.mint,
    ),
    _MenuItem(
      icon: Icons.storefront_outlined,
      label: 'Shop details',
      route: 'ShopDetails',
      color: AppTheme.toneBlue,
    ),
    _MenuItem(
      icon: Icons.account_balance_wallet_outlined,
      label: 'Expenses',
      route: 'Expenses',
      color: AppTheme.toneRose,
    ),
    _MenuItem(
      icon: Icons.key_rounded,
      label: 'Change password',
      route: 'ChangePassword',
      color: AppTheme.toneAmber,
    ),
    _MenuItem(
      icon: Icons.language_rounded,
      label: 'Language',
      route: 'Language',
      color: AppTheme.toneCyan,
    ),
    _MenuItem(
      icon: Icons.dark_mode_outlined,
      label: 'Theme',
      route: 'Theme',
      color: AppTheme.toneViolet,
    ),
  ];

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
    if (index < 0) return;

    // Slightly longer delay so the water-drop splash is visible before closing.
    Future.delayed(const Duration(milliseconds: 280), () {
      if (!mounted) return;
      // Overlay is a *child* of Navigator — never use navigator.context for
      // showDialog / Overlay.of (that causes "No Overlay widget found").
      final navigator = Navigator.of(context, rootNavigator: true);
      final overlayContext = navigator.overlay?.context;
      Navigator.pop(context);

      void afterClose(void Function(BuildContext ctx) action) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final ctx = overlayContext;
          if (ctx == null || !ctx.mounted) return;
          action(ctx);
        });
      }

      switch (pageName) {
        case 'Home':
          break;
        case 'Invoices':
          afterClose(
            (ctx) => GlassyToast.show(ctx, 'Invoices page coming soon'),
          );
          break;
        case 'Clients':
          afterClose(
            (ctx) => Navigator.of(ctx).push(
              MaterialPageRoute(builder: (_) => const EnhancedCustomerPage()),
            ),
          );
          break;
        case 'Suppliers':
          afterClose(
            (ctx) => Navigator.of(ctx).push(
              MaterialPageRoute(builder: (_) => const EnhancedSupplierPage()),
            ),
          );
          break;
        case 'Companies':
          afterClose(
            (ctx) => Navigator.of(ctx).push(
              MaterialPageRoute(builder: (_) => const EnhancedCompanyPage()),
            ),
          );
          break;
        case 'Purchases':
          afterClose(
            (ctx) => Navigator.of(ctx).push(
              MaterialPageRoute(builder: (_) => const EnhancedPurchaseScreen()),
            ),
          );
          break;
        case 'Inventory':
          afterClose(
            (ctx) => Navigator.of(ctx).push(
              MaterialPageRoute(builder: (_) => const EnhancedProductPage()),
            ),
          );
          break;
        case 'Reports':
          afterClose(
            (ctx) => GlassyToast.show(ctx, 'Reports page coming soon'),
          );
          break;
        case 'Profile':
          afterClose(
            (ctx) => Navigator.of(
              ctx,
            ).push(MaterialPageRoute(builder: (_) => const ProfilePage())),
          );
          break;
        case 'ShopDetails':
          afterClose(
            (ctx) => Navigator.of(
              ctx,
            ).push(MaterialPageRoute(builder: (_) => const ShopDetailsPage())),
          );
          break;
        case 'Expenses':
          afterClose(
            (ctx) => Navigator.of(
              ctx,
            ).push(MaterialPageRoute(builder: (_) => const ExpensesPage())),
          );
          break;
        case 'ChangePassword':
          afterClose(
            (ctx) => Navigator.of(ctx).push(
              MaterialPageRoute(builder: (_) => const ChangePasswordPage()),
            ),
          );
          break;
        case 'Language':
          afterClose(_showLanguageDialog);
          break;
        case 'Theme':
          afterClose(_showThemeDialog);
          break;
        case 'Settings':
          afterClose(_showSettingsDialog);
          break;
      }
    });
  }

  void _showThemeDialog(BuildContext dialogContext) {
    showDialog(
      context: dialogContext,
      builder: (_) => _ThemeDialog(
        currentMode: ThemeService.instance.themeMode,
        onModeSelected: (mode) async {
          await ThemeService.instance.setThemeMode(mode);
          GlassyToast.show(
            dialogContext,
            'Theme set to ${ThemeService.instance.modeLabel}',
          );
        },
      ),
    );
  }

  void _showSettingsDialog(BuildContext dialogContext) {
    showDialog(
      context: dialogContext,
      builder: (_) => _SettingsDialog(
        biometricLockEnabled: _biometricLockEnabled,
        canUseBiometrics: _canUseBiometrics,
        onBiometricToggle: _toggleBiometricLock,
      ),
    );
  }

  void _showLanguageDialog(BuildContext dialogContext) {
    showDialog(
      context: dialogContext,
      builder: (_) => _LanguageDialog(
        currentLanguage: _selectedLanguage,
        onLanguageSelected: (language) async {
          await LanguageService.instance.setLanguage(language);
          _selectedLanguage = language;
          _localizations = AppLocalizations(language);
          GlassyToast.show(
            dialogContext,
            '${_localizations.languageChangedTo} $language',
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 16, 12, 16),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
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
            borderRadius: BorderRadius.circular(28),
            child: SizedBox(
              width: double.infinity,
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppColors.isDark(context)
                          ? AppTheme.darkCard
                          : AppColors.card(context),
                      border: Border.all(color: AppColors.border(context)),
                    ),
                    child: Column(
                      children: [
                        _buildHeader(),
                        Expanded(
                          child: FadeTransition(
                            opacity: _fadeAnimation,
                            child: ListView(
                              padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
                              children: [
                                _sectionLabel('Account'),
                                ...List.generate(3, (index) {
                                  return SlideTransition(
                                    position: _menuItemAnimations[index],
                                    child: FadeTransition(
                                      opacity: _menuItemFadeAnimations[index],
                                      child: _buildMenuItem(
                                        item: _menuItems[index],
                                        index: index,
                                      ),
                                    ),
                                  );
                                }),
                                _sectionLabel(_localizations.settings),
                                ...List.generate(3, (offset) {
                                  final index = offset + 3;
                                  return SlideTransition(
                                    position: _menuItemAnimations[index],
                                    child: FadeTransition(
                                      opacity: _menuItemFadeAnimations[index],
                                      child: _buildMenuItem(
                                        item: _menuItems[index],
                                        index: index,
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

  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          fontFamily: 'Literata',
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.1,
          color: AppColors.mutedText(context),
          decoration: TextDecoration.none,
        ),
      ),
    );
  }

  Widget _iconWell(IconData icon, Color color) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }

  Widget _buildHeader() {
    final initial = _userName.isNotEmpty ? _userName[0].toUpperCase() : 'U';
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 8, 4),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF14352C),
                border: Border.all(color: AppTheme.mint, width: 1.6),
              ),
              child: Text(
                initial,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.mint,
                  fontFamily: 'Literata',
                  decoration: TextDecoration.none,
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
                    style: TextStyle(
                      color: AppColors.primaryText(context),
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      fontFamily: 'Literata',
                      decoration: TextDecoration.none,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF14352C),
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
                            color: AppTheme.mint,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          _localizations.online,
                          style: const TextStyle(
                            color: AppTheme.mint,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
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
            IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: Icon(
                Icons.close_rounded,
                color: AppColors.secondaryText(context),
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem({required _MenuItem item, required int index}) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (details) => _navigateToPage(
        item.route,
        index,
        tapPosition: details.globalPosition,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Row(
          children: [
            _iconWell(item.icon, item.color),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                item.label,
                style: TextStyle(
                  color: AppColors.primaryText(context),
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Literata',
                  decoration: TextDecoration.none,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: AppColors.mutedText(context),
              size: 22,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBiometricToggle() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        children: [
          _iconWell(Icons.fingerprint_rounded, AppTheme.mint),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _localizations.biometricLock,
              style: TextStyle(
                color: AppColors.primaryText(context),
                fontSize: 15,
                fontWeight: FontWeight.w600,
                fontFamily: 'Literata',
                decoration: TextDecoration.none,
              ),
            ),
          ),
          Switch(
            value: _biometricLockEnabled,
            onChanged: _toggleBiometricLock,
            activeThumbColor: AppTheme.onMint,
            activeTrackColor: AppTheme.mint,
            inactiveThumbColor: AppColors.mutedText(context),
            inactiveTrackColor: AppColors.chipFill(context),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomSection() {
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTapDown: (details) {
                _triggerWaterDrop(details.globalPosition);
                Future.delayed(const Duration(milliseconds: 220), () {
                  if (mounted) _logout();
                });
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppTheme.toneRose.withValues(alpha: 0.7),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.logout_rounded,
                      color: AppTheme.toneRose,
                      size: 18,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Log out',
                      style: TextStyle(
                        color: AppTheme.toneRose,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Literata',
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              _localizations.version,
              style: TextStyle(
                color: AppColors.mutedText(context),
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

class _ThemeDialog extends StatelessWidget {
  final ThemeMode currentMode;
  final ValueChanged<ThemeMode> onModeSelected;

  const _ThemeDialog({required this.currentMode, required this.onModeSelected});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF5E35B1).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.brightness_6_rounded,
              color: Color(0xFF5E35B1),
              size: 24,
            ),
          ),
          SizedBox(width: 12),
          Text(
            'Theme',
            style: TextStyle(
              fontFamily: 'Literata',
              fontWeight: FontWeight.w700,
              color: AppColors.primaryText(context),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildThemeOption(
            context,
            mode: ThemeMode.light,
            icon: Icons.light_mode_rounded,
            title: 'Light',
            subtitle: 'Bright surfaces and green accents',
          ),
          const SizedBox(height: 12),
          _buildThemeOption(
            context,
            mode: ThemeMode.dark,
            icon: Icons.dark_mode_rounded,
            title: 'Dark',
            subtitle: 'Dim surfaces for low light',
          ),
          SizedBox(height: 12),
          _buildThemeOption(
            context,
            mode: ThemeMode.system,
            icon: Icons.settings_suggest_rounded,
            title: 'System',
            subtitle: 'Follow device light/dark setting',
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            AppLocalizations(LanguageService.instance.currentLanguage).cancel,
            style: TextStyle(
              color: AppColors.secondaryText(context),
              fontFamily: 'Literata',
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildThemeOption(
    BuildContext context, {
    required ThemeMode mode,
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    final isSelected = currentMode == mode;
    const accent = Color(0xFF5E35B1);

    return GestureDetector(
      onTap: () {
        Navigator.of(context).pop();
        onModeSelected(mode);
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected
              ? accent.withValues(alpha: 0.12)
              : AppColors.isDark(context)
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.grey.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? accent : AppColors.divider(context),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? accent : AppColors.secondaryText(context),
              size: 26,
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w500,
                      fontFamily: 'Literata',
                      color: isSelected
                          ? accent
                          : AppColors.primaryText(context),
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.secondaryText(context),
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
                  color: accent,
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

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/services/language_service.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/services/biometric_service.dart';
import '../../../../core/services/logout_service.dart';
import '../../../../features/authentication/presentation/pages/change_password_page.dart';
import '../../../../features/authentication/presentation/pages/two_step_verification_page.dart';
import '../../../../core/services/theme_service.dart';
import '../../../../core/services/two_step_verification_service.dart';
import '../../../../core/theme/app_theme.dart';
import 'profile_page.dart';
import 'web_shell.dart';
import '../../../../common_widgets/glass_bottom_sheet.dart';
import '../../../shop/presentation/pages/shop_details_page.dart';
import '../../../expense/presentation/pages/expenses_page.dart';
import '../../../reports/presentation/pages/unified_reports_page.dart';
import 'package:c_billing/common_widgets/glass_bevel_frame.dart';
import 'package:c_billing/core/ui/glassy_toast.dart';
import 'package:c_billing/core/access/access_control_service.dart';
import '../../../employee/presentation/pages/employees_page.dart';

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
  bool _twoStepEnabled = false;
  late AppLocalizations _localizations;

  // Animation controllers
  late AnimationController _slideController;
  late AnimationController _staggerController;
  late Animation<double> _fadeAnimation;
  late List<Animation<Offset>> _menuItemAnimations;
  late List<Animation<double>> _menuItemFadeAnimations;

  // Account / business / preference destinations — gated by access.
  // Primary day-to-day modules live in the side rail / bottom nav, not here.
  List<_MenuSection> get _menuSections {
    final access = AccessControlService.instance;
    final account = <_MenuItem>[
      if (access.canAccessShellIndex(WebShell.profile))
        _MenuItem(
          icon: Icons.person_rounded,
          label: _localizations.profile,
          route: 'Profile',
          color: AppTheme.primary,
        ),
      if (access.canAccessShellIndex(WebShell.password))
        _MenuItem(
          icon: Icons.lock_outline_rounded,
          label: _localizations.changePassword,
          route: 'ChangePassword',
          color: AppTheme.toneAmber,
        ),
      _MenuItem(
        icon: Icons.verified_user_outlined,
        label: _localizations.twoStepVerification,
        route: 'TwoStepVerification',
        color: AppTheme.toneCyan,
        trailing: _twoStepEnabled ? 'On' : 'Off',
      ),
    ];
    final business = <_MenuItem>[
      // Always show — kinds inside the hub are access-filtered.
      _MenuItem(
        icon: Icons.assessment_outlined,
        label: 'Business reports',
        route: 'Reports',
        color: AppTheme.primary,
      ),
      if (access.canAccessShellIndex(WebShell.shop))
        _MenuItem(
          icon: Icons.storefront_outlined,
          label: _localizations.shopDetails,
          route: 'ShopDetails',
          color: AppTheme.toneBlue,
        ),
      if (access.canAccessShellIndex(WebShell.expenses))
        _MenuItem(
          icon: Icons.account_balance_wallet_outlined,
          label: 'Expenses',
          route: 'Expenses',
          color: AppTheme.toneRose,
        ),
    ];
    // Employees live under Manage on the side rail; keep a flyout shortcut for phone.
    final manage = <_MenuItem>[
      if (access.isOwner)
        _MenuItem(
          icon: Icons.groups_rounded,
          label: 'Employees',
          route: 'Employees',
          color: AppTheme.toneViolet,
        ),
    ];
    final preferences = <_MenuItem>[
      _MenuItem(
        icon: Icons.language_rounded,
        label: _localizations.language,
        route: 'Language',
        color: AppTheme.toneCyan,
        trailing: _selectedLanguage,
      ),
      _MenuItem(
        icon: Icons.dark_mode_outlined,
        label: 'Theme',
        route: 'Theme',
        color: AppTheme.toneViolet,
        trailing: ThemeService.instance.modeLabel,
      ),
    ];
    return [
      if (account.isNotEmpty) _MenuSection(title: 'Account', items: account),
      _MenuSection(title: 'Business', items: business),
      if (manage.isNotEmpty) _MenuSection(title: 'Manage', items: manage),
      _MenuSection(title: _localizations.settings, items: preferences),
    ];
  }

  @override
  void initState() {
    super.initState();
    _localizations = AppLocalizations(LanguageService.instance.currentLanguage);
    _currentUser = _auth.currentUser;
    _userName = _resolveUserName(_currentUser);
    _selectedLanguage = LanguageService.instance.currentLanguage;
    _loadBiometricStatus();
    _loadTwoStepStatus();

    // Main slide animation
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _slideController,
        curve: const Interval(0.15, 1.0, curve: Curves.easeOut),
      ),
    );

    // Staggered menu item animations (max slots for filtered menu)
    _staggerController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    const maxMenuSlots = 12;
    _menuItemAnimations = List.generate(maxMenuSlots, (index) {
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

    _menuItemFadeAnimations = List.generate(maxMenuSlots, (index) {
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
    super.dispose();
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
      debugPrint('[ERROR] Failed to load biometric status: $e');
      // Default to not showing biometric option if there's an error
      if (mounted) {
        setState(() {
          _canUseBiometrics = false;
          _biometricLockEnabled = false;
        });
      }
    }
  }

  Future<void> _loadTwoStepStatus() async {
    try {
      final enabled =
          await TwoStepVerificationService.instance.isEnabledForCurrentUser();
      if (mounted) setState(() => _twoStepEnabled = enabled);
    } catch (e) {
      debugPrint('[ERROR] Failed to load 2-step status: $e');
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

  void _navigateToPage(String pageName) {
    HapticFeedback.lightImpact();

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
      case 'Profile':
        afterClose((ctx) {
          if (WebShell.open(WebShell.profile)) return;
          showAppPage(ctx, const ProfilePage());
        });
        break;
      case 'ShopDetails':
        afterClose((ctx) {
          if (WebShell.open(WebShell.shop)) return;
          showAppPage(ctx, const ShopDetailsPage());
        });
        break;
      case 'Expenses':
        afterClose((ctx) {
          if (WebShell.open(WebShell.expenses)) return;
          showAppPage(ctx, const ExpensesPage());
        });
        break;
      case 'Reports':
        afterClose((ctx) {
          if (WebShell.open(WebShell.reports)) return;
          showAppPage(ctx, const UnifiedReportsPage());
        });
        break;
      case 'Employees':
        afterClose((ctx) {
          if (WebShell.open(WebShell.employees)) return;
          showAppPage(ctx, const EmployeesPage());
        });
        break;
      case 'ChangePassword':
        afterClose((ctx) {
          if (WebShell.open(WebShell.password)) return;
          showAppPage(
            ctx,
            const _SelectedTheme(child: ChangePasswordPage()),
          );
        });
        break;
      case 'TwoStepVerification':
        afterClose((ctx) {
          showAppPage(
            ctx,
            const _SelectedTheme(child: TwoStepVerificationPage()),
          );
        });
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
  }

  void _showThemeDialog(BuildContext dialogContext) {
    showDialog(
      context: dialogContext,
      builder: (_) => _SelectedTheme(
        child: _ThemeDialog(
        currentMode: ThemeService.instance.themeMode,
        onModeSelected: (mode) async {
          await ThemeService.instance.setThemeMode(mode);
          if (!dialogContext.mounted) return;
          GlassyToast.show(
            dialogContext,
            'Theme set to ${ThemeService.instance.modeLabel}',
          );
        },
      ),
      ),
    );
  }

  void _showSettingsDialog(BuildContext dialogContext) {
    showDialog(
      context: dialogContext,
      builder: (_) => _SelectedTheme(
        child: _SettingsDialog(
          biometricLockEnabled: _biometricLockEnabled,
          canUseBiometrics: _canUseBiometrics,
          onBiometricToggle: _toggleBiometricLock,
        ),
      ),
    );
  }

  void _showLanguageDialog(BuildContext dialogContext) {
    showDialog(
      context: dialogContext,
      builder: (_) => _SelectedTheme(
        child: _LanguageDialog(
        currentLanguage: _selectedLanguage,
        onLanguageSelected: (language) async {
          await LanguageService.instance.setLanguage(language);
          if (!dialogContext.mounted) return;
          _selectedLanguage = language;
          _localizations = AppLocalizations(language);
          GlassyToast.show(
            dialogContext,
            '${_localizations.languageChangedTo} $language',
          );
        },
        ),
      ),
    );
  }

  static const Color _panelGold = Color(0xFFC9A84C);

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.instance.isDark;
    const radius = 28.0;
    const panelRadius = BorderRadius.only(
      topRight: Radius.circular(radius),
      bottomRight: Radius.circular(radius),
    );
    // Flush to the left edge; theme fill + golden 3D glass rim only.
    return FadeTransition(
      opacity: _fadeAnimation,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: panelRadius,
          boxShadow: [
            BoxShadow(
              color: _panelGold.withValues(alpha: isDark ? 0.22 : 0.16),
              blurRadius: 18,
              offset: const Offset(4, 0),
            ),
            BoxShadow(
              color: AppTheme.black.withValues(alpha: isDark ? 0.35 : 0.1),
              blurRadius: 16,
              offset: const Offset(6, 0),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: panelRadius,
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: CustomPaint(
              foregroundPainter: GlassBevelBorderPainter(
                isDark: isDark,
                themeColor: _panelGold,
                radius: radius,
                borderRadius: panelRadius,
                strokeWidth: 1.6,
                paintLeft: false,
              ),
              child: SizedBox(
                width: double.infinity,
                height: double.infinity,
                child: ColoredBox(
                  color: AppColors.scaffold(context),
                  child: Material(
                    type: MaterialType.transparency,
                    child: Column(
                      children: [
                        _buildHeader(),
                        Expanded(
                          child: ListView(
                            padding: const EdgeInsets.fromLTRB(10, 6, 10, 8),
                            physics: const BouncingScrollPhysics(),
                            children: [
                              ...() {
                                var animIndex = 0;
                                final widgets = <Widget>[];
                                for (final section in _menuSections) {
                                  widgets.add(_sectionLabel(section.title));
                                  for (final item in section.items) {
                                    final i = animIndex++;
                                    final slot = i.clamp(
                                      0,
                                      _menuItemAnimations.length - 1,
                                    );
                                    widgets.add(
                                      SlideTransition(
                                        position: _menuItemAnimations[slot],
                                        child: FadeTransition(
                                          opacity:
                                              _menuItemFadeAnimations[slot],
                                          child: _buildMenuItem(item: item),
                                        ),
                                      ),
                                    );
                                  }
                                }
                                if (_canUseBiometrics) {
                                  final i = animIndex.clamp(
                                    0,
                                    _menuItemAnimations.length - 1,
                                  );
                                  widgets.add(
                                    SlideTransition(
                                      position: _menuItemAnimations[i],
                                      child: FadeTransition(
                                        opacity: _menuItemFadeAnimations[i],
                                        child: _buildBiometricToggle(),
                                      ),
                                    ),
                                  );
                                }
                                return widgets;
                              }(),
                            ],
                          ),
                        ),
                        _buildBottomSection(),
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

  Widget _sectionLabel(String text) {
    final isDark = ThemeService.instance.isDark;
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 18, 14, 8),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          fontFamily: 'Literata',
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.35,
          color: isDark
              ? AppTheme.darkTextMuted
              : AppTheme.grey600.withValues(alpha: 0.85),
          decoration: TextDecoration.none,
        ),
      ),
    );
  }

  Widget _iconWell(IconData icon, Color color) {
    final isDark = ThemeService.instance.isDark;
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.22 : 0.14),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(
          color: color.withValues(alpha: isDark ? 0.28 : 0.12),
        ),
      ),
      child: Icon(icon, color: color, size: 21),
    );
  }

  Widget _buildHeader() {
    final isDark = AppColors.isDark(context);
    final bar = AppColors.appBar(context);
    final initial = _userName.isNotEmpty ? _userName[0].toUpperCase() : 'U';
    final role = AccessControlService.instance.isOwner ? 'Owner' : 'Staff';
    final email = _currentUser?.email?.trim();
    // Same green glass bar treatment as [AppTopBar].
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color.lerp(AppTheme.white, bar, isDark ? 0.78 : 0.55)!,
            bar,
            Color.lerp(bar, AppTheme.black, isDark ? 0.34 : 0.2)!,
          ],
          stops: const [0.0, 0.46, 1.0],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 12, 12, 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 56,
                height: 56,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.white.withValues(alpha: 0.15),
                  border: Border.all(
                    color: AppTheme.white.withValues(alpha: 0.35),
                    width: 1.6,
                  ),
                ),
                child: Text(
                  initial,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.white,
                    fontFamily: 'Literata',
                    decoration: TextDecoration.none,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _userName,
                      style: const TextStyle(
                        color: AppTheme.white,
                        fontSize: 17.5,
                        fontWeight: FontWeight.w800,
                        fontFamily: 'Literata',
                        height: 1.15,
                        decoration: TextDecoration.none,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (email != null && email.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        email,
                        style: TextStyle(
                          color: AppTheme.white.withValues(alpha: 0.72),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          fontFamily: 'Literata',
                          decoration: TextDecoration.none,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        _roleChip(role),
                        _onlineChip(_localizations.online),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              _closeButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _closeButton() {
    return Material(
      color: AppTheme.transparent,
      child: InkWell(
        onTap: () => Navigator.of(context).pop(),
        borderRadius: BorderRadius.circular(12),
        splashColor: AppTheme.white.withValues(alpha: 0.15),
        highlightColor: AppTheme.white.withValues(alpha: 0.08),
        child: Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppTheme.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppTheme.white.withValues(alpha: 0.2),
            ),
          ),
          child: const Icon(
            Icons.close_rounded,
            color: AppTheme.white,
            size: 20,
          ),
        ),
      ),
    );
  }

  Widget _roleChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppTheme.white,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          fontFamily: 'Literata',
          decoration: TextDecoration.none,
        ),
      ),
    );
  }

  Widget _onlineChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: const BoxDecoration(
              color: AppTheme.green300,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: AppTheme.white.withValues(alpha: 0.95),
              fontSize: 11,
              fontWeight: FontWeight.w700,
              fontFamily: 'Literata',
              decoration: TextDecoration.none,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({required _MenuItem item}) {
    final isDark = ThemeService.instance.isDark;
    final iconColor = item.color == AppTheme.primary
        ? AppColors.actionBright(context)
        : item.color;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Material(
        color: AppTheme.transparent,
        child: InkWell(
          onTap: () => _navigateToPage(item.route),
          borderRadius: BorderRadius.circular(16),
          splashColor: iconColor.withValues(alpha: 0.12),
          highlightColor: iconColor.withValues(alpha: 0.06),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
            child: Row(
              children: [
                _iconWell(item.icon, iconColor),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    item.label,
                    style: TextStyle(
                      color: AppColors.primaryText(context),
                      fontSize: 15.5,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Literata',
                      decoration: TextDecoration.none,
                    ),
                  ),
                ),
                if (item.trailing != null) ...[
                  Text(
                    item.trailing!,
                    style: TextStyle(
                      color: AppColors.mutedText(context),
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Literata',
                      decoration: TextDecoration.none,
                    ),
                  ),
                  const SizedBox(width: 6),
                ],
                Icon(
                  Icons.chevron_right_rounded,
                  color: isDark
                      ? AppTheme.darkTextMuted
                      : AppTheme.grey400,
                  size: 22,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBiometricToggle() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: Row(
        children: [
          _iconWell(Icons.fingerprint_rounded, AppColors.actionBright(context)),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              _localizations.biometricLock,
              style: TextStyle(
                color: AppColors.primaryText(context),
                fontSize: 15.5,
                fontWeight: FontWeight.w600,
                fontFamily: 'Literata',
                decoration: TextDecoration.none,
              ),
            ),
          ),
          Switch(
            value: _biometricLockEnabled,
            onChanged: _toggleBiometricLock,
            activeThumbColor: AppTheme.white,
            activeTrackColor: AppColors.action(context),
            inactiveThumbColor: AppColors.mutedText(context),
            inactiveTrackColor: AppColors.chipFill(context),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomSection() {
    final isDark = ThemeService.instance.isDark;
    final logoutColor = isDark ? AppTheme.toneRose : const Color(0xFFE57373);
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 6, 18, 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Material(
              color: AppTheme.transparent,
              child: InkWell(
                onTap: _logout,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: logoutColor.withValues(alpha: 0.75),
                      width: 1.4,
                    ),
                    color: logoutColor.withValues(alpha: isDark ? 0.08 : 0.04),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.logout_rounded,
                        color: logoutColor,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _localizations.logout,
                        style: TextStyle(
                          color: logoutColor,
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
            ),
            const SizedBox(height: 14),
            Text(
              _localizations.version,
              style: TextStyle(
                color: AppColors.mutedText(context),
                fontSize: 11.5,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.2,
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

// Forces a dialog or drawer onto the theme chosen in the app, including when that choice is not the device theme.
class _SelectedTheme extends StatelessWidget {
  final Widget child;

  const _SelectedTheme({required this.child});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ThemeService.instance,
      builder: (context, _) {
        return Theme(
          data: ThemeService.instance.isDark ? AppTheme.dark : AppTheme.light,
          child: child,
        );
      },
    );
  }
}

class _MenuSection {
  final String title;
  final List<_MenuItem> items;

  const _MenuSection({required this.title, required this.items});
}

class _MenuItem {
  final IconData icon;
  final String label;
  final String route;
  final Color color;
  final String? trailing;

  const _MenuItem({
    required this.icon,
    required this.label,
    required this.route,
    this.trailing,
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
              color: AppTheme.deepPurple600.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.brightness_6_rounded,
              color: AppTheme.deepPurple600,
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
    const accent = AppTheme.deepPurple600;

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
              ? AppTheme.white.withValues(alpha: 0.06)
              : AppTheme.grey.withValues(alpha: 0.05),
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
                child: const Icon(Icons.check, color: AppTheme.white, size: 16),
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
              color: AppTheme.amber900.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.language_rounded,
              color: AppTheme.amber900,
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
            style: const TextStyle(color: AppTheme.grey, fontFamily: 'Literata'),
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
              ? AppTheme.amber900.withValues(alpha: 0.1)
              : AppTheme.grey.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppTheme.amber900
                : AppTheme.grey.withValues(alpha: 0.2),
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
                          ? AppTheme.amber900
                          : AppTheme.black87,
                    ),
                  ),
                  Text(
                    nativeName,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppTheme.grey600,
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
                  color: AppTheme.amber900,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, color: AppTheme.white, size: 16),
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
    final isDark = ThemeService.instance.isDark;
    final loc = AppLocalizations(LanguageService.instance.currentLanguage);
    return Dialog(
      backgroundColor: AppTheme.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: CustomPaint(
            foregroundPainter: GlassBevelBorderPainter(
              isDark: isDark,
              themeColor: Theme.of(context).primaryColor,
              radius: 24,
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
                      : [
                          AppColors.card(context).withValues(alpha: 0.92),
                          AppColors.card(context).withValues(alpha: 0.98),
                        ],
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.action(context).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.settings_rounded,
                            color: AppColors.action(context),
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            loc.settings,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Literata',
                              color: AppColors.primaryText(context),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.chipFill(context),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.action(context).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.fingerprint,
                              color: widget.canUseBiometrics
                                  ? AppColors.action(context)
                                  : AppColors.mutedText(context),
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  loc.biometricLock,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    fontFamily: 'Literata',
                                    color: widget.canUseBiometrics
                                        ? AppColors.primaryText(context)
                                        : AppColors.mutedText(context),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  widget.canUseBiometrics
                                      ? loc.unlockWithBiometric
                                      : loc.biometricsNotAvailable,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.secondaryText(context),
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
                            activeThumbColor: AppTheme.white,
                            activeTrackColor: AppColors.action(context),
                          ),
                        ],
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text(
                          loc.close,
                          style: TextStyle(
                            color: AppColors.action(context),
                            fontFamily: 'Literata',
                            fontWeight: FontWeight.w600,
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
    );
  }
}

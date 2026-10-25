import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:c_billing/core/services/dashboard_refresh_service.dart';
import 'package:c_billing/core/services/language_service.dart';
import 'package:c_billing/core/localization/app_localizations.dart';
import 'package:c_billing/features/billing/domain/entities/bill_tax_settings.dart';
import 'package:c_billing/features/billing/presentation/pages/bill_report_settings_page.dart';
import 'package:c_billing/core/ui/glassy_toast.dart';
import 'package:c_billing/common_widgets/app_top_bar.dart';
import 'package:c_billing/common_widgets/glass_bottom_sheet.dart';
import 'package:c_billing/core/theme/app_theme.dart';

// Bill settings page for configuring billing preferences
class BillSettingsPage extends StatefulWidget {
  const BillSettingsPage({super.key});

  @override
  State<BillSettingsPage> createState() => _BillSettingsPageState();
}

class _BillSettingsPageState extends State<BillSettingsPage>
    with SingleTickerProviderStateMixin {
  static const String _keyShowCustomerOnBill = 'bill_show_customer_details';
  static const String _keyGenerateViaContact = 'bill_generate_via_contact';
  static const String _keyEnableEmployeeToken = 'bill_enable_employee_token';
  static const String _keyEnableHoldBill = 'bill_enable_hold';
  static const String _keyBillType = 'bill_type'; // 'pos' or 'normal'

  bool _showCustomerDetails = true;
  bool _generateViaContact = false;
  bool _enableEmployeeToken = false;
  bool _enableHoldBill = false;
  String _billType = 'pos'; // Default to POS printer
  bool _isLoading = true;
  late AppLocalizations _localizations;
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;

  // GST/Tax settings
  BillTaxSettings _taxSettings = BillTaxSettings.defaultSettings;
  final _cgstController = TextEditingController();
  final _sgstController = TextEditingController();
  final _igstController = TextEditingController();
  final _otherTaxNameController = TextEditingController();
  final _otherTaxPercentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _localizations = AppLocalizations(LanguageService.instance.currentLanguage);

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));

    _loadSettings();
  }

  @override
  void dispose() {
    _animController.dispose();
    _cgstController.dispose();
    _sgstController.dispose();
    _igstController.dispose();
    _otherTaxNameController.dispose();
    _otherTaxPercentController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final taxSettings = await BillTaxSettings.load();
    setState(() {
      _showCustomerDetails = prefs.getBool(_keyShowCustomerOnBill) ?? true;
      _generateViaContact = prefs.getBool(_keyGenerateViaContact) ?? false;
      _enableEmployeeToken = prefs.getBool(_keyEnableEmployeeToken) ?? false;
      _enableHoldBill = prefs.getBool(_keyEnableHoldBill) ?? false;
      _billType = prefs.getString(_keyBillType) ?? 'pos';
      _taxSettings = taxSettings;
      _cgstController.text = taxSettings.cgstPercent > 0
          ? taxSettings.cgstPercent.toString()
          : '';
      _sgstController.text = taxSettings.sgstPercent > 0
          ? taxSettings.sgstPercent.toString()
          : '';
      _igstController.text = taxSettings.igstPercent > 0
          ? taxSettings.igstPercent.toString()
          : '';
      _otherTaxNameController.text = taxSettings.otherTaxName;
      _otherTaxPercentController.text = taxSettings.otherTaxPercent > 0
          ? taxSettings.otherTaxPercent.toString()
          : '';
      _isLoading = false;
    });
    _animController.forward();
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyShowCustomerOnBill, _showCustomerDetails);
    await prefs.setBool(_keyGenerateViaContact, _generateViaContact);
    await prefs.setBool(_keyEnableEmployeeToken, _enableEmployeeToken);
    await prefs.setBool(_keyEnableHoldBill, _enableHoldBill);
    await prefs.setString(_keyBillType, _billType);
    await _taxSettings.save();

    // Notify billing page to reload settings immediately
    DashboardRefreshService.instance.notifyDataChanged(
      DataChangeType.billSettings,
    );

    if (mounted) {
      GlassyToast.show(context, _localizations.settingsSaved);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        Navigator.pop(context, true);
      },
      child: Scaffold(
        backgroundColor: AppColors.scaffold(context),
        body: _isLoading
            ? Center(
                child: CircularProgressIndicator(color: AppColors.accent(context)),
              )
            : Column(
                children: [
                  AppTopBar(
                    title: _localizations.billSettings,
                    subtitle: 'Customize your bill preferences',
                    onBack: () => Navigator.pop(context, true),
                    actions: [
                      AppTopBar.action(
                        icon: Icons.check_rounded,
                        onTap: () => Navigator.pop(context, true),
                      ),
                    ],
                  ),
                  Expanded(
                    child: CustomScrollView(
                slivers: [
                  // Main Content
                  SliverToBoxAdapter(
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Bill Type Section
                            _buildSectionCard(
                              icon: Icons.description_rounded,
                              iconColor: AppColors.action(context),
                              title: _localizations.billType,
                              subtitle: 'Choose your default bill format',
                              children: [_buildBillTypeSelector()],
                            ),
                            const SizedBox(height: 20),

                            // Billing Settings Section
                            _buildSectionCard(
                              icon: Icons.receipt_long_rounded,
                              iconColor: AppTheme.paletteFF7B68EE,
                              title: _localizations.billingSettings,
                              subtitle: 'Configure billing behavior',
                              children: [
                                _buildModernToggle(
                                  icon: Icons.contact_phone_rounded,
                                  iconColor: AppTheme.paletteFF7B68EE,
                                  title: _localizations.generateBillViaContact,
                                  subtitle: _localizations.requireContactNumber,
                                  value: _generateViaContact,
                                  onChanged: (value) async {
                                    setState(() {
                                      _generateViaContact = value;
                                    });
                                    await _saveSettings();
                                  },
                                ),
                                const SizedBox(height: 14),
                                _buildModernToggle(
                                  icon: Icons.pause_circle_outline_rounded,
                                  iconColor: AppTheme.orange700,
                                  title: 'Enable hold bill',
                                  subtitle:
                                      'Park a cart and resume later — no stock cut until Print',
                                  value: _enableHoldBill,
                                  onChanged: (value) async {
                                    setState(() {
                                      _enableHoldBill = value;
                                    });
                                    await _saveSettings();
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),

                            // Print Settings Section
                            _buildSectionCard(
                              icon: Icons.print_rounded,
                              iconColor: AppTheme.green,
                              title: _localizations.printSettings,
                              subtitle: 'Customize printed bill appearance',
                              children: [
                                _buildModernToggle(
                                  icon: Icons.person_rounded,
                                  iconColor: AppTheme.green,
                                  title:
                                      _localizations.showCustomerDetailsOnBill,
                                  subtitle:
                                      _localizations.displayCustomerOnBill,
                                  value: _showCustomerDetails,
                                  onChanged: (value) async {
                                    setState(() {
                                      _showCustomerDetails = value;
                                    });
                                    await _saveSettings();
                                  },
                                ),
                                const SizedBox(height: 14),
                                _buildNavigationTile(
                                  icon: Icons.view_column_rounded,
                                  iconColor: AppTheme.blue,
                                  title: 'Print Column Settings',
                                  subtitle:
                                      'Choose columns to show on printed bills',
                                  onTap: () async {
                                    await showAppPage(
                                      context,
                                      const BillReportSettingsPage(),
                                    );
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),

                            // GST / Tax Settings Section
                            _buildSectionCard(
                              icon: Icons.account_balance_rounded,
                              iconColor: AppTheme.coral,
                              title: _localizations.taxSettings,
                              subtitle: 'Configure tax calculation',
                              children: [
                                // CGST Toggle
                                _buildModernToggle(
                                  icon: Icons.percent_rounded,
                                  iconColor: AppTheme.coral,
                                  title: _localizations.enableCgst,
                                  subtitle: _localizations.cgstPercent,
                                  value: _taxSettings.enableCgst,
                                  onChanged: (value) async {
                                    setState(() {
                                      _taxSettings = _taxSettings.copyWith(
                                        enableCgst: value,
                                      );
                                    });
                                    await _saveSettings();
                                  },
                                ),
                                if (_taxSettings.enableCgst) ...[
                                  const SizedBox(height: 12),
                                  _buildPercentageInput(
                                    controller: _cgstController,
                                    label: _localizations.cgstPercent,
                                    onChanged: (val) async {
                                      final percent =
                                          double.tryParse(val) ?? 0.0;
                                      if (percent >= 0 && percent <= 100) {
                                        _taxSettings = _taxSettings.copyWith(
                                          cgstPercent: percent,
                                        );
                                        await _saveSettings();
                                      }
                                    },
                                  ),
                                ],
                                Container(
                                  margin: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  height: 1,
                                  color: AppTheme.grey.withValues(alpha: 0.1),
                                ),
                                // SGST Toggle
                                _buildModernToggle(
                                  icon: Icons.percent_rounded,
                                  iconColor: AppTheme.orange,
                                  title: _localizations.enableSgst,
                                  subtitle: _localizations.sgstPercent,
                                  value: _taxSettings.enableSgst,
                                  onChanged: (value) async {
                                    setState(() {
                                      _taxSettings = _taxSettings.copyWith(
                                        enableSgst: value,
                                      );
                                    });
                                    await _saveSettings();
                                  },
                                ),
                                if (_taxSettings.enableSgst) ...[
                                  const SizedBox(height: 12),
                                  _buildPercentageInput(
                                    controller: _sgstController,
                                    label: _localizations.sgstPercent,
                                    onChanged: (val) async {
                                      final percent =
                                          double.tryParse(val) ?? 0.0;
                                      if (percent >= 0 && percent <= 100) {
                                        _taxSettings = _taxSettings.copyWith(
                                          sgstPercent: percent,
                                        );
                                        await _saveSettings();
                                      }
                                    },
                                  ),
                                ],
                                Container(
                                  margin: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  height: 1,
                                  color: AppTheme.grey.withValues(alpha: 0.1),
                                ),
                                _buildModernToggle(
                                  icon: Icons.public_rounded,
                                  iconColor: AppTheme.toneBlue,
                                  title: 'Enable IGST',
                                  subtitle:
                                      'Interstate default (overrides CGST/SGST when on)',
                                  value: _taxSettings.enableIgst,
                                  onChanged: (value) async {
                                    setState(() {
                                      _taxSettings = _taxSettings.copyWith(
                                        enableIgst: value,
                                        enableCgst: value
                                            ? false
                                            : _taxSettings.enableCgst,
                                        enableSgst: value
                                            ? false
                                            : _taxSettings.enableSgst,
                                      );
                                    });
                                    await _saveSettings();
                                  },
                                ),
                                if (_taxSettings.enableIgst) ...[
                                  const SizedBox(height: 12),
                                  _buildPercentageInput(
                                    controller: _igstController,
                                    label: 'IGST %',
                                    onChanged: (val) async {
                                      final percent =
                                          double.tryParse(val) ?? 0.0;
                                      if (percent >= 0 && percent <= 100) {
                                        _taxSettings = _taxSettings.copyWith(
                                          igstPercent: percent,
                                        );
                                        await _saveSettings();
                                      }
                                    },
                                  ),
                                ],
                                Container(
                                  margin: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  height: 1,
                                  color: AppTheme.grey.withValues(alpha: 0.1),
                                ),
                                // Other Tax Toggle
                                _buildModernToggle(
                                  icon: Icons.add_circle_outline_rounded,
                                  iconColor: AppTheme.purple,
                                  title: _localizations.enableOtherTax,
                                  subtitle: _localizations.otherTaxPercent,
                                  value: _taxSettings.enableOtherTax,
                                  onChanged: (value) async {
                                    setState(() {
                                      _taxSettings = _taxSettings.copyWith(
                                        enableOtherTax: value,
                                      );
                                    });
                                    await _saveSettings();
                                  },
                                ),
                                if (_taxSettings.enableOtherTax) ...[
                                  const SizedBox(height: 12),
                                  _buildTextInput(
                                    controller: _otherTaxNameController,
                                    label: _localizations.otherTaxName,
                                    icon: Icons.label_outline_rounded,
                                    onChanged: (val) async {
                                      _taxSettings = _taxSettings.copyWith(
                                        otherTaxName: val,
                                      );
                                      await _saveSettings();
                                    },
                                  ),
                                  const SizedBox(height: 10),
                                  _buildPercentageInput(
                                    controller: _otherTaxPercentController,
                                    label: _localizations.otherTaxPercent,
                                    onChanged: (val) async {
                                      final percent =
                                          double.tryParse(val) ?? 0.0;
                                      if (percent >= 0 && percent <= 100) {
                                        _taxSettings = _taxSettings.copyWith(
                                          otherTaxPercent: percent,
                                        );
                                        await _saveSettings();
                                      }
                                    },
                                  ),
                                ],
                              ],
                            ),

                            if (_taxSettings.gstFeatureEnabled) ...[
                              const SizedBox(height: 20),
                              // Default GST Mode
                              _buildSectionCard(
                                icon: Icons.calculate_rounded,
                                iconColor: AppTheme.blue,
                                title: _localizations.defaultGstMode,
                                subtitle: 'Set how GST is applied by default',
                                children: [
                                  _buildGstModeOption(
                                    title: _localizations.includeGstInTotal,
                                    subtitle: _localizations.includeGstSubtitle,
                                    icon: Icons.arrow_downward_rounded,
                                    isSelected: _taxSettings.defaultIncludeTax,
                                    onTap: () async {
                                      setState(() {
                                        _taxSettings = _taxSettings.copyWith(
                                          defaultIncludeTax: true,
                                        );
                                      });
                                      await _saveSettings();
                                    },
                                  ),
                                  const SizedBox(height: 12),
                                  _buildGstModeOption(
                                    title: _localizations.excludeGstFromTotal,
                                    subtitle: _localizations.excludeGstSubtitle,
                                    icon: Icons.arrow_upward_rounded,
                                    isSelected: !_taxSettings.defaultIncludeTax,
                                    onTap: () async {
                                      setState(() {
                                        _taxSettings = _taxSettings.copyWith(
                                          defaultIncludeTax: false,
                                        );
                                      });
                                      await _saveSettings();
                                    },
                                  ),
                                ],
                              ),
                            ],

                            const SizedBox(height: 20),

                            // Extra charges (labour / loading / service)
                            _buildSectionCard(
                              icon: Icons.add_card_rounded,
                              iconColor: AppTheme.teal,
                              title: 'Other charges',
                              subtitle:
                                  'Labour, loading, service — show on Generate Invoice when enabled',
                              children: [
                                _buildModernToggle(
                                  icon: Icons.add_card_rounded,
                                  iconColor: AppTheme.teal,
                                  title: 'Enable other charges',
                                  subtitle:
                                      'Allow named charges on the bill (below items)',
                                  value: _taxSettings.enableExtraCharges,
                                  onChanged: (value) async {
                                    setState(() {
                                      _taxSettings = _taxSettings.copyWith(
                                        enableExtraCharges: value,
                                      );
                                    });
                                    await _saveSettings();
                                  },
                                ),
                              ],
                            ),

                            const SizedBox(height: 20),

                            // Employee token — same pattern as other charges
                            _buildSectionCard(
                              icon: Icons.confirmation_number_rounded,
                              iconColor: AppTheme.paletteFF7B68EE,
                              title: 'Employee token',
                              subtitle:
                                  'Per-item token on Generate Invoice when enabled',
                              children: [
                                _buildModernToggle(
                                  icon: Icons.confirmation_number_rounded,
                                  iconColor: AppTheme.paletteFF7B68EE,
                                  title: 'Enable employee token',
                                  subtitle:
                                      'Show Emp token on bill lines; 1 point per ₹1000 of that item’s sale',
                                  value: _enableEmployeeToken,
                                  onChanged: (value) async {
                                    setState(() {
                                      _enableEmployeeToken = value;
                                    });
                                    await _saveSettings();
                                  },
                                ),
                              ],
                            ),

                            const SizedBox(height: 24),

                            // Info card
                            _buildInfoCard(),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
                  ),
                ],
              ),
      ),
    );
  }

  // Info Card Widget
  Widget _buildInfoCard() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.action(context).withValues(alpha: 0.05),
            AppColors.action(context).withValues(alpha: 0.02),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.accentSoft(context, 0.1),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.accentSoft(context, 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.lightbulb_outline_rounded,
              color: AppColors.accent(context),
              size: 22,
            ),
          ),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pro Tip',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Literata',
                    color: AppColors.accent(context),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _localizations.contactNumberNote,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.grey600,
                    fontFamily: 'Literata',
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // GST Mode Option Widget
  Widget _buildGstModeOption({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [
                    AppColors.action(context).withValues(alpha: 0.1),
                    AppColors.action(context).withValues(alpha: 0.05),
                  ],
                )
              : null,
          color: isSelected ? null : AppColors.scaffold(context),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppColors.action(context) : AppTheme.grey300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.action(context) : AppColors.border(context),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: isSelected ? AppTheme.white : AppTheme.grey600,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontFamily: 'Literata',
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? AppColors.action(context)
                          : AppTheme.grey800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontFamily: 'Literata',
                      fontSize: 12,
                      color: AppTheme.grey600,
                    ),
                  ),
                ],
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected
                    ? AppColors.action(context)
                    : AppTheme.transparent,
                border: Border.all(
                  color: isSelected
                      ? AppColors.action(context)
                      : AppTheme.grey400,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Icon(
                      Icons.check_rounded,
                      color: AppTheme.white,
                      size: 16,
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.black.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Section Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  iconColor.withValues(alpha: 0.08),
                  iconColor.withValues(alpha: 0.02),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [iconColor, iconColor.withValues(alpha: 0.8)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: iconColor.withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(icon, color: AppTheme.white, size: 24),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Literata',
                          color: AppColors.accent(context),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 13,
                          color: AppTheme.grey,
                          fontFamily: 'Literata',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Section Content
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  // Modern toggle switch
  Widget _buildModernToggle({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: iconColor, size: 22),
        ),
        SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Literata',
                  color: AppColors.accent(context),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.grey,
                  fontFamily: 'Literata',
                ),
              ),
            ],
          ),
        ),
        Transform.scale(
          scale: 0.9,
          child: Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppTheme.white,
            activeTrackColor: AppColors.action(context),
            inactiveThumbColor: AppTheme.white,
            inactiveTrackColor: AppTheme.grey300,
            trackOutlineColor: WidgetStateProperty.all(AppTheme.transparent),
          ),
        ),
      ],
    );
  }

  // Navigation tile for linking to other pages
  Widget _buildNavigationTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Literata',
                      color: AppColors.accent(context),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.grey,
                      fontFamily: 'Literata',
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.arrow_forward_ios_rounded,
                color: iconColor,
                size: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBillTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _buildBillTypeOption(
                title: _localizations.posPrinter,
                subtitle: _localizations.thermalReceipt,
                icon: Icons.print_rounded,
                value: 'pos',
                isSelected: _billType == 'pos',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildBillTypeOption(
                title: _localizations.normalBill,
                subtitle: _localizations.pdfFormat,
                icon: Icons.picture_as_pdf_rounded,
                value: 'normal',
                isSelected: _billType == 'normal',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBillTypeOption({
    required String title,
    required String subtitle,
    required IconData icon,
    required String value,
    required bool isSelected,
  }) {
    return GestureDetector(
      onTap: () async {
        setState(() {
          _billType = value;
        });
        await _saveSettings();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [
                    AppColors.action(context).withValues(alpha: 0.1),
                    AppColors.action(context).withValues(alpha: 0.05),
                  ],
                )
              : null,
          color: isSelected ? null : AppColors.scaffold(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.action(context) : AppTheme.grey300,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.accentSoft(context, 0.15),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: isSelected
                    ? LinearGradient(
                        colors: AppColors.headerGradient(context),
                      )
                    : null,
                color: isSelected ? null : AppColors.border(context),
                shape: BoxShape.circle,
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: AppColors.accentSoft(context, 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ]
                    : null,
              ),
              child: Icon(
                icon,
                color: isSelected ? AppTheme.white : AppTheme.grey600,
                size: 26,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              style: TextStyle(
                fontFamily: 'Literata',
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: isSelected ? AppColors.action(context) : AppTheme.grey800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontFamily: 'Literata',
                fontSize: 11,
                color: AppTheme.grey600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                gradient: isSelected
                    ? LinearGradient(
                        colors: AppColors.headerGradient(context),
                      )
                    : null,
                color: isSelected ? null : AppTheme.transparent,
                borderRadius: BorderRadius.circular(20),
                border: isSelected
                    ? null
                    : Border.all(color: AppTheme.grey300),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isSelected)
                    const Icon(
                      Icons.check_rounded,
                      color: AppTheme.white,
                      size: 14,
                    ),
                  if (isSelected) const SizedBox(width: 4),
                  Text(
                    isSelected ? _localizations.selected : 'Select',
                    style: TextStyle(
                      fontFamily: 'Literata',
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? AppTheme.white : AppTheme.grey600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Builds a percentage input field for tax configuration
  Widget _buildPercentageInput({
    required TextEditingController controller,
    required String label,
    required ValueChanged<String> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(left: 56),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                fontFamily: 'Literata',
                fontSize: 13,
                color: AppTheme.grey600,
              ),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            flex: 1,
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.accentSoft(context, 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border(context)),
              ),
              child: TextField(
                controller: controller,
                keyboardType: TextInputType.numberWithOptions(
                  decimal: true,
                ),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Literata',
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.accent(context),
                ),
                decoration: InputDecoration(
                  suffixText: '%',
                  suffixStyle: TextStyle(
                    fontFamily: 'Literata',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.grey,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  border: InputBorder.none,
                ),
                onChanged: onChanged,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Builds a text input field (e.g., for other tax name)
  Widget _buildTextInput({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required ValueChanged<String> onChanged,
  }) {
    return Container(
      margin: EdgeInsets.only(left: 56),
      decoration: BoxDecoration(
        color: AppColors.scaffold(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: TextField(
        controller: controller,
        style: TextStyle(
          fontFamily: 'Literata',
          fontSize: 14,
          color: AppColors.accent(context),
        ),
        decoration: InputDecoration(
          hintText: label,
          hintStyle: TextStyle(
            fontFamily: 'Literata',
            fontSize: 13,
            color: AppTheme.grey400,
          ),
          prefixIcon: Icon(icon, color: AppTheme.grey400, size: 20),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 14,
          ),
          border: InputBorder.none,
        ),
        onChanged: onChanged,
      ),
    );
  }
}

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:c_billing/core/services/dashboard_refresh_service.dart';
import 'package:c_billing/core/services/language_service.dart';
import 'package:c_billing/core/localization/app_localizations.dart';
import 'package:c_billing/features/billing/domain/entities/bill_tax_settings.dart';
import 'package:c_billing/features/billing/presentation/pages/bill_report_settings_page.dart';

/// Bill settings page for configuring billing preferences
class BillSettingsPage extends StatefulWidget {
  const BillSettingsPage({super.key});

  @override
  State<BillSettingsPage> createState() => _BillSettingsPageState();
}

class _BillSettingsPageState extends State<BillSettingsPage>
    with SingleTickerProviderStateMixin {
  static const String _keyShowCustomerOnBill = 'bill_show_customer_details';
  static const String _keyGenerateViaContact = 'bill_generate_via_contact';
  static const String _keyBillType = 'bill_type'; // 'pos' or 'normal'

  bool _showCustomerDetails = true;
  bool _generateViaContact = false;
  String _billType = 'pos'; // Default to POS printer
  bool _isLoading = true;
  late AppLocalizations _localizations;
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;

  // GST/Tax settings
  BillTaxSettings _taxSettings = BillTaxSettings.defaultSettings;
  final _cgstController = TextEditingController();
  final _sgstController = TextEditingController();
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
      _billType = prefs.getString(_keyBillType) ?? 'pos';
      _taxSettings = taxSettings;
      _cgstController.text = taxSettings.cgstPercent > 0
          ? taxSettings.cgstPercent.toString()
          : '';
      _sgstController.text = taxSettings.sgstPercent > 0
          ? taxSettings.sgstPercent.toString()
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
    await prefs.setString(_keyBillType, _billType);
    await _taxSettings.save();

    // Notify billing page to reload settings immediately
    DashboardRefreshService.instance.notifyDataChanged(
      DataChangeType.billSettings,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _localizations.settingsSaved,
            style: const TextStyle(fontFamily: 'Literata'),
          ),
          backgroundColor: const Color(0xFF1B4D3E),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(
          context,
          true,
        ); // Return true to indicate settings changed
        return false;
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7F6),
        body: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF1B4D3E)),
              )
            : CustomScrollView(
                slivers: [
                  // Sticky Header with Glass Effect
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: _BillSettingsHeaderDelegate(
                      minHeight: 100,
                      maxHeight: 140,
                      title: _localizations.billSettings,
                      subtitle: 'Customize your bill preferences',
                      onBack: () => Navigator.pop(context, true),
                    ),
                  ),

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
                              iconColor: const Color(0xFF1B4D3E),
                              title: _localizations.billType,
                              subtitle: 'Choose your default bill format',
                              children: [_buildBillTypeSelector()],
                            ),
                            const SizedBox(height: 20),

                            // Billing Settings Section
                            _buildSectionCard(
                              icon: Icons.receipt_long_rounded,
                              iconColor: const Color(0xFF7B68EE),
                              title: _localizations.billingSettings,
                              subtitle: 'Configure billing behavior',
                              children: [
                                _buildModernToggle(
                                  icon: Icons.contact_phone_rounded,
                                  iconColor: const Color(0xFF7B68EE),
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
                              ],
                            ),
                            const SizedBox(height: 20),

                            // Print Settings Section
                            _buildSectionCard(
                              icon: Icons.print_rounded,
                              iconColor: const Color(0xFF4CAF50),
                              title: _localizations.printSettings,
                              subtitle: 'Customize printed bill appearance',
                              children: [
                                _buildModernToggle(
                                  icon: Icons.person_rounded,
                                  iconColor: const Color(0xFF4CAF50),
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
                                  iconColor: const Color(0xFF2196F3),
                                  title: 'Print Column Settings',
                                  subtitle: 'Choose columns to show on printed bills',
                                  onTap: () async {
                                    await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => const BillReportSettingsPage(),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),

                            // GST / Tax Settings Section
                            _buildSectionCard(
                              icon: Icons.account_balance_rounded,
                              iconColor: const Color(0xFFFF6B6B),
                              title: _localizations.taxSettings,
                              subtitle: 'Configure tax calculation',
                              children: [
                                // CGST Toggle
                                _buildModernToggle(
                                  icon: Icons.percent_rounded,
                                  iconColor: const Color(0xFFFF6B6B),
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
                                  color: Colors.grey.withOpacity(0.1),
                                ),
                                // SGST Toggle
                                _buildModernToggle(
                                  icon: Icons.percent_rounded,
                                  iconColor: const Color(0xFFFF9800),
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
                                  color: Colors.grey.withOpacity(0.1),
                                ),
                                // Other Tax Toggle
                                _buildModernToggle(
                                  icon: Icons.add_circle_outline_rounded,
                                  iconColor: const Color(0xFF9C27B0),
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

                            if (_taxSettings.hasAnyTaxEnabled) ...[
                              const SizedBox(height: 20),
                              // Default GST Mode
                              _buildSectionCard(
                                icon: Icons.calculate_rounded,
                                iconColor: const Color(0xFF2196F3),
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
    );
  }

  // Info Card Widget
  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF1B4D3E).withOpacity(0.05),
            const Color(0xFF1B4D3E).withOpacity(0.02),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1B4D3E).withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF1B4D3E).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.lightbulb_outline_rounded,
              color: Color(0xFF1B4D3E),
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Pro Tip',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Literata',
                    color: Color(0xFF1B4D3E),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _localizations.contactNumberNote,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
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
                    const Color(0xFF1B4D3E).withOpacity(0.1),
                    const Color(0xFF1B4D3E).withOpacity(0.05),
                  ],
                )
              : null,
          color: isSelected ? null : Colors.grey[50],
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? const Color(0xFF1B4D3E) : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF1B4D3E) : Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: isSelected ? Colors.white : Colors.grey[600],
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
                          ? const Color(0xFF1B4D3E)
                          : Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontFamily: 'Literata',
                      fontSize: 12,
                      color: Colors.grey[600],
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
                    ? const Color(0xFF1B4D3E)
                    : Colors.transparent,
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF1B4D3E)
                      : Colors.grey[400]!,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Icon(
                      Icons.check_rounded,
                      color: Colors.white,
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
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
                  iconColor.withOpacity(0.08),
                  iconColor.withOpacity(0.02),
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
                      colors: [iconColor, iconColor.withOpacity(0.8)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: iconColor.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(icon, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Literata',
                          color: Color(0xFF1B4D3E),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[500],
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
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: iconColor, size: 22),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Literata',
                  color: Color(0xFF1B4D3E),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[500],
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
            activeColor: Colors.white,
            activeTrackColor: const Color(0xFF1B4D3E),
            inactiveThumbColor: Colors.white,
            inactiveTrackColor: Colors.grey[300],
            trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
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
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Literata',
                      color: Color(0xFF1B4D3E),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
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
                color: iconColor.withOpacity(0.1),
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
                    const Color(0xFF1B4D3E).withOpacity(0.1),
                    const Color(0xFF1B4D3E).withOpacity(0.05),
                  ],
                )
              : null,
          color: isSelected ? null : Colors.grey[50],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? const Color(0xFF1B4D3E) : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF1B4D3E).withOpacity(0.15),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: isSelected
                    ? const LinearGradient(
                        colors: [Color(0xFF1B4D3E), Color(0xFF2D6A4F)],
                      )
                    : null,
                color: isSelected ? null : Colors.grey[200],
                shape: BoxShape.circle,
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: const Color(0xFF1B4D3E).withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ]
                    : null,
              ),
              child: Icon(
                icon,
                color: isSelected ? Colors.white : Colors.grey[600],
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
                color: isSelected ? const Color(0xFF1B4D3E) : Colors.grey[800],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontFamily: 'Literata',
                fontSize: 11,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                gradient: isSelected
                    ? const LinearGradient(
                        colors: [Color(0xFF1B4D3E), Color(0xFF2D6A4F)],
                      )
                    : null,
                color: isSelected ? null : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                border: isSelected
                    ? null
                    : Border.all(color: Colors.grey[300]!),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isSelected)
                    const Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 14,
                    ),
                  if (isSelected) const SizedBox(width: 4),
                  Text(
                    isSelected ? _localizations.selected : 'Select',
                    style: TextStyle(
                      fontFamily: 'Literata',
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white : Colors.grey[600],
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

  /// Builds a percentage input field for tax configuration
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
                color: Colors.grey[600],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 1,
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1B4D3E).withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: TextField(
                controller: controller,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Literata',
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1B4D3E),
                ),
                decoration: InputDecoration(
                  suffixText: '%',
                  suffixStyle: TextStyle(
                    fontFamily: 'Literata',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[500],
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

  /// Builds a text input field (e.g., for other tax name)
  Widget _buildTextInput({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required ValueChanged<String> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(left: 56),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: TextField(
        controller: controller,
        style: const TextStyle(
          fontFamily: 'Literata',
          fontSize: 14,
          color: Color(0xFF1B4D3E),
        ),
        decoration: InputDecoration(
          hintText: label,
          hintStyle: TextStyle(
            fontFamily: 'Literata',
            fontSize: 13,
            color: Colors.grey[400],
          ),
          prefixIcon: Icon(icon, color: Colors.grey[400], size: 20),
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

/// Header delegate for bill settings page
class _BillSettingsHeaderDelegate extends SliverPersistentHeaderDelegate {
  final double minHeight;
  final double maxHeight;
  final String title;
  final String subtitle;
  final VoidCallback onBack;

  _BillSettingsHeaderDelegate({
    required this.minHeight,
    required this.maxHeight,
    required this.title,
    required this.subtitle,
    required this.onBack,
  });

  @override
  double get minExtent => minHeight;

  @override
  double get maxExtent => maxHeight;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final progress = shrinkOffset / (maxHeight - minHeight);
    final isCollapsed = progress > 0.5;

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1B4D3E), Color(0xFF2D6A4F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1B4D3E).withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      // Back Button
                      GestureDetector(
                        onTap: onBack,
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.2),
                            ),
                          ),
                          child: const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Title
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              title,
                              style: TextStyle(
                                fontSize: isCollapsed ? 20 : 24,
                                fontWeight: FontWeight.w800,
                                fontFamily: 'Literata',
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                            if (!isCollapsed) ...[
                              const SizedBox(height: 4),
                              Text(
                                subtitle,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontFamily: 'Literata',
                                  color: Colors.white.withOpacity(0.8),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      // Done Button
                      GestureDetector(
                        onTap: onBack,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Text(
                            'Done',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'Literata',
                              color: Color(0xFF1B4D3E),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(_BillSettingsHeaderDelegate oldDelegate) {
    return maxHeight != oldDelegate.maxHeight ||
        minHeight != oldDelegate.minHeight ||
        title != oldDelegate.title ||
        subtitle != oldDelegate.subtitle;
  }
}

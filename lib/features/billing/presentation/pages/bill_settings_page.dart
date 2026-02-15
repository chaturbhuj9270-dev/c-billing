import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:c_billing/core/services/dashboard_refresh_service.dart';
import 'package:c_billing/core/services/language_service.dart';
import 'package:c_billing/core/localization/app_localizations.dart';
import 'package:c_billing/features/billing/domain/entities/bill_tax_settings.dart';

/// Bill settings page for configuring billing preferences
class BillSettingsPage extends StatefulWidget {
  const BillSettingsPage({super.key});

  @override
  State<BillSettingsPage> createState() => _BillSettingsPageState();
}

class _BillSettingsPageState extends State<BillSettingsPage> {
  static const String _keyShowCustomerOnBill = 'bill_show_customer_details';
  static const String _keyGenerateViaContact = 'bill_generate_via_contact';
  static const String _keyBillType = 'bill_type'; // 'pos' or 'normal'
  
  bool _showCustomerDetails = true;
  bool _generateViaContact = false;
  String _billType = 'pos'; // Default to POS printer
  bool _isLoading = true;
  late AppLocalizations _localizations;

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
    _loadSettings();
  }

  @override
  void dispose() {
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
      _cgstController.text = taxSettings.cgstPercent > 0 ? taxSettings.cgstPercent.toString() : '';
      _sgstController.text = taxSettings.sgstPercent > 0 ? taxSettings.sgstPercent.toString() : '';
      _otherTaxNameController.text = taxSettings.otherTaxName;
      _otherTaxPercentController.text = taxSettings.otherTaxPercent > 0 ? taxSettings.otherTaxPercent.toString() : '';
      _isLoading = false;
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyShowCustomerOnBill, _showCustomerDetails);
    await prefs.setBool(_keyGenerateViaContact, _generateViaContact);
    await prefs.setString(_keyBillType, _billType);
    await _taxSettings.save();
    
    // Notify billing page to reload settings immediately
    DashboardRefreshService.instance.notifyDataChanged(DataChangeType.billSettings);
    
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
        Navigator.pop(context, true); // Return true to indicate settings changed
        return false;
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        appBar: AppBar(
          backgroundColor: const Color(0xFF1B4D3E),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context, true), // Return true when back pressed
          ),
          title: Text(
            _localizations.billSettings,
            style: TextStyle(
              fontFamily: 'Literata',
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(
                _localizations.done,
                style: const TextStyle(
                  fontFamily: 'Literata',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Bill Type Section
                  _buildSectionCard(
                    title: _localizations.billType,
                    icon: Icons.description,
                    children: [
                      _buildBillTypeSelector(),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Billing Settings Section
                  _buildSectionCard(
                    title: _localizations.billingSettings,
                    icon: Icons.receipt_long,
                    children: [
                      _buildSettingTile(
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
                  const SizedBox(height: 16),
                  
                  // Print Settings Section
                  _buildSectionCard(
                    title: _localizations.printSettings,
                    icon: Icons.print,
                    children: [
                      _buildSettingTile(
                        title: _localizations.showCustomerDetailsOnBill,
                        subtitle: _localizations.displayCustomerOnBill,
                        value: _showCustomerDetails,
                        onChanged: (value) async {
                          setState(() {
                            _showCustomerDetails = value;
                          });
                          await _saveSettings();
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // ═══════════════════════════════════════
                  // GST / Tax Settings Section
                  // ═══════════════════════════════════════
                  _buildSectionCard(
                    title: _localizations.taxSettings,
                    icon: Icons.receipt_long_outlined,
                    children: [
                      // Tax Toggles
                      _buildSettingTile(
                        title: _localizations.enableCgst,
                        subtitle: _localizations.cgstPercent,
                        value: _taxSettings.enableCgst,
                        onChanged: (value) async {
                          setState(() {
                            _taxSettings = _taxSettings.copyWith(enableCgst: value);
                          });
                          await _saveSettings();
                        },
                      ),
                      if (_taxSettings.enableCgst)
                        _buildPercentageInput(
                          controller: _cgstController,
                          label: _localizations.cgstPercent,
                          onChanged: (val) async {
                            final percent = double.tryParse(val) ?? 0.0;
                            if (percent >= 0 && percent <= 100) {
                              _taxSettings = _taxSettings.copyWith(cgstPercent: percent);
                              await _saveSettings();
                            }
                          },
                        ),
                      const Divider(height: 1),
                      _buildSettingTile(
                        title: _localizations.enableSgst,
                        subtitle: _localizations.sgstPercent,
                        value: _taxSettings.enableSgst,
                        onChanged: (value) async {
                          setState(() {
                            _taxSettings = _taxSettings.copyWith(enableSgst: value);
                          });
                          await _saveSettings();
                        },
                      ),
                      if (_taxSettings.enableSgst)
                        _buildPercentageInput(
                          controller: _sgstController,
                          label: _localizations.sgstPercent,
                          onChanged: (val) async {
                            final percent = double.tryParse(val) ?? 0.0;
                            if (percent >= 0 && percent <= 100) {
                              _taxSettings = _taxSettings.copyWith(sgstPercent: percent);
                              await _saveSettings();
                            }
                          },
                        ),
                      const Divider(height: 1),
                      _buildSettingTile(
                        title: _localizations.enableOtherTax,
                        subtitle: _localizations.otherTaxPercent,
                        value: _taxSettings.enableOtherTax,
                        onChanged: (value) async {
                          setState(() {
                            _taxSettings = _taxSettings.copyWith(enableOtherTax: value);
                          });
                          await _saveSettings();
                        },
                      ),
                      if (_taxSettings.enableOtherTax) ...[
                        _buildTextInput(
                          controller: _otherTaxNameController,
                          label: _localizations.otherTaxName,
                          onChanged: (val) async {
                            _taxSettings = _taxSettings.copyWith(otherTaxName: val);
                            await _saveSettings();
                          },
                        ),
                        _buildPercentageInput(
                          controller: _otherTaxPercentController,
                          label: _localizations.otherTaxPercent,
                          onChanged: (val) async {
                            final percent = double.tryParse(val) ?? 0.0;
                            if (percent >= 0 && percent <= 100) {
                              _taxSettings = _taxSettings.copyWith(otherTaxPercent: percent);
                              await _saveSettings();
                            }
                          },
                        ),
                      ],
                    ],
                  ),
                  
                  if (_taxSettings.hasAnyTaxEnabled) ...[
                    const SizedBox(height: 16),
                    // Default GST Mode
                    _buildSectionCard(
                      title: _localizations.defaultGstMode,
                      icon: Icons.calculate_outlined,
                      children: [
                        _buildRadioTile(
                          title: _localizations.includeGstInTotal,
                          subtitle: _localizations.includeGstSubtitle,
                          value: true,
                          groupValue: _taxSettings.defaultIncludeTax,
                          onChanged: (val) async {
                            setState(() {
                              _taxSettings = _taxSettings.copyWith(defaultIncludeTax: val);
                            });
                            await _saveSettings();
                          },
                        ),
                        const Divider(height: 1),
                        _buildRadioTile(
                          title: _localizations.excludeGstFromTotal,
                          subtitle: _localizations.excludeGstSubtitle,
                          value: false,
                          groupValue: _taxSettings.defaultIncludeTax,
                          onChanged: (val) async {
                            setState(() {
                              _taxSettings = _taxSettings.copyWith(defaultIncludeTax: val);
                            });
                            await _saveSettings();
                          },
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 16),
                  
                  // Info card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue[200]!),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue[700], size: 24),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _localizations.contactNumberNote,
                            style: TextStyle(
                              fontFamily: 'Literata',
                              fontSize: 13,
                              color: Colors.blue[900],
                            ),
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

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1B4D3E).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: const Color(0xFF1B4D3E),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Literata',
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1B4D3E),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ...children,
        ],
      ),
    );
  }

  Widget _buildSettingTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Literata',
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1B4D3E),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontFamily: 'Literata',
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFF1B4D3E),
          ),
        ],
      ),
    );
  }

  Widget _buildBillTypeSelector() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _localizations.selectDefaultBillType,
            style: TextStyle(
              fontFamily: 'Literata',
              fontSize: 13,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildBillTypeOption(
                  title: _localizations.posPrinter,
                  subtitle: _localizations.thermalReceipt,
                  icon: Icons.print,
                  value: 'pos',
                  isSelected: _billType == 'pos',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildBillTypeOption(
                  title: _localizations.normalBill,
                  subtitle: _localizations.pdfFormat,
                  icon: Icons.picture_as_pdf,
                  value: 'normal',
                  isSelected: _billType == 'normal',
                ),
              ),
            ],
          ),
        ],
      ),
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
          color: isSelected 
              ? const Color(0xFF1B4D3E).withOpacity(0.1) 
              : Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected 
                ? const Color(0xFF1B4D3E) 
                : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected 
                    ? const Color(0xFF1B4D3E) 
                    : Colors.grey[200],
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isSelected ? Colors.white : Colors.grey[600],
                size: 24,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontFamily: 'Literata',
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isSelected 
                    ? const Color(0xFF1B4D3E) 
                    : Colors.grey[800],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontFamily: 'Literata',
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            if (isSelected)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF1B4D3E),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _localizations.selected,
                  style: const TextStyle(
                    fontFamily: 'Literata',
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                fontFamily: 'Literata',
                fontSize: 14,
                color: Colors.grey[700],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 1,
            child: TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Literata',
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1B4D3E),
              ),
              decoration: InputDecoration(
                suffixText: '%',
                suffixStyle: TextStyle(
                  fontFamily: 'Literata',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[600],
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                filled: true,
                fillColor: const Color(0xFF1B4D3E).withOpacity(0.05),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFF1B4D3E), width: 1.5),
                ),
              ),
              onChanged: onChanged,
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
    required ValueChanged<String> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: TextField(
        controller: controller,
        style: const TextStyle(
          fontFamily: 'Literata',
          fontSize: 14,
          color: Color(0xFF1B4D3E),
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            fontFamily: 'Literata',
            fontSize: 13,
            color: Colors.grey[600],
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          filled: true,
          fillColor: const Color(0xFF1B4D3E).withOpacity(0.05),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFF1B4D3E), width: 1.5),
          ),
        ),
        onChanged: onChanged,
      ),
    );
  }

  /// Builds a radio button tile for GST mode selection
  Widget _buildRadioTile<T>({
    required String title,
    required String subtitle,
    required T value,
    required T groupValue,
    required ValueChanged<T> onChanged,
  }) {
    final isSelected = value == groupValue;
    return InkWell(
      onTap: () => onChanged(value),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
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
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontFamily: 'Literata',
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF1B4D3E)
                      : Colors.grey[400]!,
                  width: isSelected ? 2 : 1.5,
                ),
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFF1B4D3E),
                        ),
                      ),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

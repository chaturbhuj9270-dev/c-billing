import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:c_billing/core/services/dashboard_refresh_service.dart';
import 'package:c_billing/core/services/language_service.dart';
import 'package:c_billing/core/services/signature_service.dart';
import 'package:c_billing/core/localization/app_localizations.dart';
import 'package:c_billing/common_widgets/signature_pad_screen.dart';

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

  // Signature state
  bool _hasSignature = false;
  Uint8List? _signatureBytes;

  @override
  void initState() {
    super.initState();
    _localizations = AppLocalizations(LanguageService.instance.currentLanguage);
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _showCustomerDetails = prefs.getBool(_keyShowCustomerOnBill) ?? true;
      _generateViaContact = prefs.getBool(_keyGenerateViaContact) ?? false;
      _billType = prefs.getString(_keyBillType) ?? 'pos';
      _isLoading = false;
    });
    await _loadSignature();
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyShowCustomerOnBill, _showCustomerDetails);
    await prefs.setBool(_keyGenerateViaContact, _generateViaContact);
    await prefs.setString(_keyBillType, _billType);
    
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

  Future<void> _loadSignature() async {
    final service = SignatureService();
    final has = await service.hasSignature();
    Uint8List? bytes;
    if (has) {
      bytes = await service.getSignatureBytes();
    }
    if (mounted) {
      setState(() {
        _hasSignature = has;
        _signatureBytes = bytes;
      });
    }
  }

  Future<void> _openSignaturePad() async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const SignaturePadScreen()),
    );
    if (saved == true) {
      await _loadSignature();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _localizations.signatureSaved,
              style: const TextStyle(fontFamily: 'Literata'),
            ),
            backgroundColor: const Color(0xFF1B4D3E),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  Future<void> _removeSignature() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          _localizations.removeSignature,
          style: const TextStyle(fontFamily: 'Literata', fontWeight: FontWeight.w600),
        ),
        content: Text(
          _localizations.removeSignatureConfirm,
          style: const TextStyle(fontFamily: 'Literata'),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              _localizations.cancel,
              style: const TextStyle(fontFamily: 'Literata', color: Colors.grey),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              _localizations.remove,
              style: const TextStyle(fontFamily: 'Literata', color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await SignatureService().removeSignature();
      await _loadSignature();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _localizations.signatureRemoved,
              style: const TextStyle(fontFamily: 'Literata'),
            ),
            backgroundColor: Colors.orange[700],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
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

                  // Owner Signature Section
                  _buildSectionCard(
                    title: _localizations.ownerSignature,
                    icon: Icons.draw,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            // Signature preview box
                            Container(
                              width: double.infinity,
                              height: 120,
                              decoration: BoxDecoration(
                                color: Colors.grey[50],
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey[300]!, width: 1),
                              ),
                              child: _hasSignature && _signatureBytes != null
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(11),
                                      child: Image.memory(
                                        _signatureBytes!,
                                        fit: BoxFit.contain,
                                      ),
                                    )
                                  : Center(
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.draw_outlined, size: 32, color: Colors.grey[400]),
                                          const SizedBox(height: 8),
                                          Text(
                                            _localizations.noSignatureAdded,
                                            style: TextStyle(
                                              fontFamily: 'Literata',
                                              fontSize: 13,
                                              color: Colors.grey[500],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                            ),
                            const SizedBox(height: 12),
                            // Action buttons
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: _openSignaturePad,
                                    icon: Icon(
                                      _hasSignature ? Icons.edit : Icons.add,
                                      size: 18,
                                    ),
                                    label: Text(
                                      _hasSignature
                                          ? _localizations.updateSignature
                                          : _localizations.addSignature,
                                      style: const TextStyle(
                                        fontFamily: 'Literata',
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF1B4D3E),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                  ),
                                ),
                                if (_hasSignature) ...[
                                  const SizedBox(width: 12),
                                  OutlinedButton.icon(
                                    onPressed: _removeSignature,
                                    icon: const Icon(Icons.delete_outline, size: 18),
                                    label: Text(
                                      _localizations.remove,
                                      style: const TextStyle(
                                        fontFamily: 'Literata',
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.red,
                                      side: const BorderSide(color: Colors.red),
                                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
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
}

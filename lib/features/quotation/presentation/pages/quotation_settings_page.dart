import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/services/language_service.dart';
import '../../../../core/ui/glassy_toast.dart';
import '../../data/services/quotation_format_settings.dart';

/// Quotation print/PDF settings (format matches billing: POS vs normal).
class QuotationSettingsPage extends StatefulWidget {
  const QuotationSettingsPage({super.key});

  @override
  State<QuotationSettingsPage> createState() => _QuotationSettingsPageState();
}

class _QuotationSettingsPageState extends State<QuotationSettingsPage> {
  static const _primary = Color(0xFF1B4D3E);
  static const _keyShowCustomerOnBill = 'bill_show_customer_details';

  late AppLocalizations _l10n;
  String _quotationType = 'pos';
  bool _showCustomerDetails = true;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _l10n = AppLocalizations.of(LanguageService.instance.currentLanguage);
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _quotationType =
          prefs.getString(QuotationFormatSettings.keyQuotationType) ?? 'pos';
      _showCustomerDetails = prefs.getBool(_keyShowCustomerOnBill) ?? true;
      _isLoading = false;
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      QuotationFormatSettings.keyQuotationType,
      _quotationType,
    );
    await prefs.setBool(_keyShowCustomerOnBill, _showCustomerDetails);

    if (mounted) {
      GlassyToast.show(context, _l10n.settingsSaved);
    }
  }

  @override
  Widget build(BuildContext context) {
    _l10n = AppLocalizations.of(LanguageService.instance.currentLanguage);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F6),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context, true),
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.arrow_back_ios_new,
              color: _primary,
              size: 18,
            ),
          ),
        ),
        title: Text(
          _l10n.quotationSettings,
          style: const TextStyle(
            fontFamily: 'Literata',
            fontWeight: FontWeight.w800,
            color: _primary,
            fontSize: 20,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: _primary),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
              children: [
                _sectionCard(
                  icon: Icons.description_rounded,
                  title: _l10n.quotationFormat,
                  subtitle: _l10n.chooseQuotationFormat,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _formatOption(
                            title: _l10n.posPrinter,
                            subtitle: _l10n.thermalReceipt,
                            icon: Icons.print_rounded,
                            value: 'pos',
                            isSelected: _quotationType == 'pos',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _formatOption(
                            title: _l10n.normalBill,
                            subtitle: _l10n.pdfFormat,
                            icon: Icons.picture_as_pdf_rounded,
                            value: 'normal',
                            isSelected: _quotationType == 'normal',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _sectionCard(
                  icon: Icons.print_rounded,
                  title: _l10n.printSettings,
                  subtitle: _l10n.customizePrintedQuotation,
                  children: [
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        _l10n.showCustomerDetailsOnBill,
                        style: const TextStyle(
                          fontFamily: 'Literata',
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      subtitle: Text(
                        _l10n.displayCustomerOnQuotation,
                        style: TextStyle(
                          fontFamily: 'Literata',
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      value: _showCustomerDetails,
                      activeThumbColor: _primary,
                      onChanged: (value) async {
                        setState(() => _showCustomerDetails = value);
                        await _saveSettings();
                      },
                    ),
                  ],
                ),
              ],
            ),
    );
  }

  Widget _sectionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: _primary, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontFamily: 'Literata',
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: Color(0xFF1A1A2E),
                      ),
                    ),
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
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _formatOption({
    required String title,
    required String subtitle,
    required IconData icon,
    required String value,
    required bool isSelected,
  }) {
    return GestureDetector(
      onTap: () async {
        setState(() => _quotationType = value);
        await _saveSettings();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [
                    _primary.withValues(alpha: 0.1),
                    _primary.withValues(alpha: 0.05),
                  ],
                )
              : null,
          color: isSelected ? null : Colors.grey[50],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? _primary : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? _primary : Colors.grey[500], size: 28),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Literata',
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: isSelected ? _primary : Colors.grey[800],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Literata',
                fontSize: 11,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:c_billing/common_widgets/glass_bottom_sheet.dart';
import 'package:c_billing/core/localization/app_localizations.dart';
import 'package:c_billing/core/services/dashboard_refresh_service.dart';
import 'package:c_billing/core/services/language_service.dart';
import 'package:c_billing/core/theme/app_theme.dart';
import 'package:c_billing/core/ui/glassy_toast.dart';
import '../../../company/data/services/company_sync_service.dart';
import '../../../company/offline/controllers/company_offline_controller.dart';
import '../../../supplier/data/services/supplier_sync_service.dart';
import '../../../supplier/offline/controllers/supplier_offline_controller.dart';
import '../../domain/utils/quick_add_party_logic.dart';

/// Result of a quick add: the picker item to auto-select and whether an
/// identical record already existed (in which case nothing new was created).
class QuickAddPartyResult {
  final Map<String, dynamic> pickerItem;
  final bool alreadyExisted;
  const QuickAddPartyResult(this.pickerItem, {this.alreadyExisted = false});
}

enum _PartyKind { company, supplier }

/// Compact "add company / add supplier" sheet used from the add product screen
/// so a new party can be created without leaving the form. It creates records
/// through the same offline controllers + sync services as the full forms.
class QuickAddPartySheet {
  QuickAddPartySheet._();

  static Future<QuickAddPartyResult?> company(BuildContext context) =>
      _open(context, _PartyKind.company);

  static Future<QuickAddPartyResult?> supplier(BuildContext context) =>
      _open(context, _PartyKind.supplier);

  static Future<QuickAddPartyResult?> _open(
    BuildContext context,
    _PartyKind kind,
  ) async {
    final result = await showAppBottomSheet<QuickAddPartyResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.transparent,
      builder: (sheetContext) => _QuickAddPartyBody(kind: kind),
    );
    if (result != null && context.mounted) {
      final l = AppLocalizations(LanguageService.instance.currentLanguage);
      GlassyToast.show(
        context,
        result.alreadyExisted
            ? l.partyAlreadyExistsSelected
            : (kind == _PartyKind.company
                  ? l.companyAddedSuccessfully
                  : l.supplierAddedSuccessfully),
      );
    }
    return result;
  }
}

class _QuickAddPartyBody extends StatefulWidget {
  final _PartyKind kind;
  const _QuickAddPartyBody({required this.kind});

  @override
  State<_QuickAddPartyBody> createState() => _QuickAddPartyBodyState();
}

class _QuickAddPartyBodyState extends State<_QuickAddPartyBody> {
  final _nameCtrl = TextEditingController(); // company name / first name
  final _lastNameCtrl = TextEditingController();
  final _contactCtrl = TextEditingController();
  final _gstCtrl = TextEditingController();
  bool _saving = false;

  late final AppLocalizations _l = AppLocalizations(
    LanguageService.instance.currentLanguage,
  );

  bool get _isCompany => widget.kind == _PartyKind.company;

  bool get _canSave {
    if (_nameCtrl.text.trim().isEmpty) return false;
    if (!_isCompany && _lastNameCtrl.text.trim().isEmpty) return false;
    return !_saving;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _lastNameCtrl.dispose();
    _contactCtrl.dispose();
    _gstCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_canSave) return;
    final contact = _contactCtrl.text.trim();
    if (!isValidOptionalMobile(contact)) {
      GlassyToast.show(context, _l.enterValid10DigitPhone, isError: true);
      return;
    }
    setState(() => _saving = true);
    try {
      final result = _isCompany
          ? await _saveCompany(contact)
          : await _saveSupplier(contact);
      if (mounted) Navigator.of(context).pop(result);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      GlassyToast.show(
        context,
        '${_isCompany ? _l.errorAddingCompany : _l.errorAddingSupplier}: $e',
        isError: true,
      );
    }
  }

  Future<QuickAddPartyResult> _saveCompany(String contact) async {
    final name = _nameCtrl.text.trim().replaceAll(RegExp(r'\s+'), ' ');
    final controller = CompanyOfflineController.instance;
    final existing = findPartyByName(
      await controller.getAllCompanies(),
      name,
      (c) => c.companyName,
    );
    if (existing != null) {
      return QuickAddPartyResult(
        companyPickerMap(
          id: existing.serverId ?? existing.id.toString(),
          companyName: existing.companyName,
        ),
        alreadyExisted: true,
      );
    }
    final created = await controller.addCompany(
      companyName: name,
      gstCode: _gstCtrl.text.trim(),
      contact: contact,
    );
    CompanySyncService.instance.syncNow();
    DashboardRefreshService.instance.notifyDataChanged(DataChangeType.company);
    return QuickAddPartyResult(
      companyPickerMap(
        id: created.serverId ?? created.id.toString(),
        companyName: created.companyName,
      ),
    );
  }

  Future<QuickAddPartyResult> _saveSupplier(String contact) async {
    final first = _nameCtrl.text.trim();
    final last = _lastNameCtrl.text.trim();
    final controller = SupplierOfflineController.instance;
    final existing = findPartyByName(
      await controller.getAllSuppliers(),
      '$first $last',
      (s) => '${s.firstName} ${s.lastName}',
    );
    if (existing != null) {
      return QuickAddPartyResult(
        supplierPickerMap(
          id: existing.serverId ?? existing.id.toString(),
          firstName: existing.firstName,
          lastName: existing.lastName,
        ),
        alreadyExisted: true,
      );
    }
    final created = await controller.addSupplier(
      firstName: first,
      lastName: last,
      supplierCode: '',
      contact: contact,
      gstNumber: _gstCtrl.text.trim(),
    );
    SupplierSyncService.instance.syncNow();
    DashboardRefreshService.instance.notifyDataChanged(DataChangeType.supplier);
    return QuickAddPartyResult(
      supplierPickerMap(
        id: created.serverId ?? created.id.toString(),
        firstName: created.firstName,
        lastName: created.lastName,
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool required = false,
    TextInputType? keyboardType,
    int? maxLength,
    List<TextInputFormatter>? formatters,
    TextCapitalization capitalization = TextCapitalization.words,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        maxLength: maxLength,
        inputFormatters: formatters,
        textCapitalization: capitalization,
        onChanged: (_) => setState(() {}),
        style: const TextStyle(fontFamily: 'Literata'),
        decoration: InputDecoration(
          labelText: required ? '$label *' : label,
          hintText: hint,
          counterText: '',
          prefixIcon: Icon(icon, color: AppTheme.grey600),
          filled: true,
          fillColor: AppColors.inputFill(context),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppColors.accent(context), width: 2),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 8,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const GlassSheetHandle(),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  _isCompany
                      ? Icons.business_rounded
                      : Icons.person_add_rounded,
                  color: AppColors.accent(context),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _isCompany ? _l.addNewCompany : _l.addNewSupplier,
                    style: TextStyle(
                      fontFamily: 'Literata',
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                      color: AppColors.accent(context),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: _saving ? null : () => Navigator.pop(context),
                  icon: Icon(Icons.close_rounded, color: AppTheme.grey600),
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (_isCompany)
              _field(
                controller: _nameCtrl,
                label: _l.companyName,
                hint: _l.enterCompanyName,
                icon: Icons.business_rounded,
                required: true,
              )
            else ...[
              _field(
                controller: _nameCtrl,
                label: _l.firstName,
                hint: _l.enterFirstName,
                icon: Icons.person_outline_rounded,
                required: true,
              ),
              _field(
                controller: _lastNameCtrl,
                label: _l.lastName,
                hint: _l.enterLastName,
                icon: Icons.person_outline_rounded,
                required: true,
              ),
            ],
            _field(
              controller: _contactCtrl,
              label: '${_l.contactNumber} (${_l.optional})',
              hint: _l.enterTenDigitNumber,
              icon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
              maxLength: 10,
              formatters: [FilteringTextInputFormatter.digitsOnly],
              capitalization: TextCapitalization.none,
            ),
            _field(
              controller: _gstCtrl,
              label: '${_l.gstNumber} (${_l.optional})',
              hint: _l.gstNumber,
              icon: Icons.receipt_long_outlined,
              capitalization: TextCapitalization.characters,
            ),
            const SizedBox(height: 4),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _canSave ? _save : null,
                icon: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.add_rounded, size: 20),
                label: Text(
                  _isCompany ? _l.addCompany : _l.addSupplier,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Literata',
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.action(context),
                  foregroundColor: AppTheme.white,
                  disabledBackgroundColor: AppTheme.grey300,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

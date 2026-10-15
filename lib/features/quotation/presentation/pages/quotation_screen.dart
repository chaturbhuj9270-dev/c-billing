import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/services/language_service.dart';
import '../../../../core/ui/glassy_toast.dart';
import '../../../event_order/domain/entities/order_item.dart';
import '../../../event_order/domain/entities/sub_event.dart';
import '../../../customer/offline/controllers/customer_offline_controller.dart';
import '../../../customer/offline/entities/customer_entity.dart';
import '../../data/services/quotation_print_service.dart';
import '../../domain/entities/quotation.dart';
import '../../offline/controllers/quotation_offline_controller.dart';
import '../widgets/quotation_products_panel.dart';
import 'package:c_billing/common_widgets/app_top_bar.dart';
import 'package:c_billing/core/theme/app_theme.dart';

class QuotationScreen extends StatefulWidget {
  final Quotation? existing;

  const QuotationScreen({super.key, this.existing});

  @override
  State<QuotationScreen> createState() => _QuotationScreenState();
}

class _QuotationScreenState extends State<QuotationScreen> {
  Color get _primary => AppColors.action(context);
  final _formKey = GlobalKey<FormState>();
  final _uuid = const Uuid();

  late AppLocalizations _l10n;
  QuotationType _type = QuotationType.product;
  String? _customerId;
  List<SubEvent> _subEvents = [];
  List<OrderItem> _orderItems = [];
  List<CustomerEntity> _customerSuggestions = [];
  bool _isLoading = false;
  bool _isPrinting = false;

  final _customerNameController = TextEditingController();
  final _customerContactController = TextEditingController();
  final _customerAddressController = TextEditingController();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _eventChargesController = TextEditingController(text: '0');
  final _discountController = TextEditingController(text: '0');
  final _notesController = TextEditingController();

  DateTime _referenceDate = DateTime.now().add(const Duration(days: 7));

  bool get _isEditing => widget.existing != null;
  bool get _showProducts =>
      _type == QuotationType.product || _type == QuotationType.hybrid;
  bool get _showEvents =>
      _type == QuotationType.event || _type == QuotationType.hybrid;

  @override
  void initState() {
    super.initState();
    _l10n = AppLocalizations.of(LanguageService.instance.currentLanguage);
    if (_isEditing) {
      _loadExisting();
    }
  }

  void _loadExisting() {
    final q = widget.existing!;
    _type = q.quotationType;
    _customerId = q.customerId;
    _customerNameController.text = q.customerName;
    _customerContactController.text = q.customerContact;
    _customerAddressController.text = q.customerAddress ?? '';
    _titleController.text = q.title;
    _descriptionController.text = q.description ?? '';
    _locationController.text = q.eventLocation ?? '';
    _eventChargesController.text = q.eventCharges.toStringAsFixed(0);
    _discountController.text = q.discountAmount.toStringAsFixed(0);
    _notesController.text = q.notes ?? '';
    _referenceDate = q.referenceDate;
    _subEvents = List.from(q.subEvents);
    _orderItems = List.from(q.items);
  }

  Future<void> _searchCustomers(String query) async {
    if (query.length < 2) {
      setState(() => _customerSuggestions = []);
      return;
    }
    final results = await CustomerOfflineController.instance.searchCustomers(
      query,
    );
    if (mounted) setState(() => _customerSuggestions = results);
  }

  void _selectCustomer(CustomerEntity customer) {
    setState(() {
      _customerId = customer.serverId ?? 'local_${customer.id}';
      _customerNameController.text = customer.name;
      _customerContactController.text = customer.mobile;
      _customerAddressController.text = customer.address ?? '';
      _customerSuggestions = [];
    });
  }

  double get _subEventsTotal =>
      _subEvents.fold(0.0, (sum, e) => sum + e.charges);

  double get _productsTotal =>
      _orderItems.fold(0.0, (sum, e) => sum + e.total);

  double get _eventCharges =>
      double.tryParse(_eventChargesController.text) ?? 0.0;

  double get _discountAmount => double.tryParse(_discountController.text) ?? 0;

  double get _totalAmount {
    var subtotal = 0.0;
    if (_type == QuotationType.product) {
      subtotal = _productsTotal;
    } else if (_type == QuotationType.event) {
      subtotal = _eventCharges + _subEventsTotal;
    } else {
      subtotal = _eventCharges + _subEventsTotal + _productsTotal;
    }
    return (subtotal - _discountAmount).clamp(0.0, double.infinity);
  }

  Future<void> _pickDate({
    required DateTime initial,
    required ValueChanged<DateTime> onPicked,
  }) async {
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (date != null) onPicked(date);
  }

  Future<void> _addSubEvent() async {
    final nameController = TextEditingController();
    final chargesController = TextEditingController(text: '0');
    DateTime subDate = _referenceDate;

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Add Sub Event',
          style: const TextStyle(fontFamily: 'Literata'),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: 'Sub Event Name',
                labelStyle: const TextStyle(fontFamily: 'Literata'),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: chargesController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Charges',
                labelStyle: const TextStyle(fontFamily: 'Literata'),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(_l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: _primary),
            child: Text(_l10n.add, style: const TextStyle(color: AppTheme.white)),
          ),
        ],
      ),
    );

    if (saved == true && nameController.text.trim().isNotEmpty) {
      setState(() {
        _subEvents.add(
          SubEvent(
            id: _uuid.v4(),
            name: nameController.text.trim(),
            date: subDate,
            charges: double.tryParse(chargesController.text) ?? 0,
          ),
        );
      });
    }
  }

  Quotation _quotationSnapshot() {
    final now = DateTime.now();
    final existing = widget.existing;
    return Quotation(
      id: existing?.id ?? 'draft',
      quotationNumber: existing?.quotationNumber ?? 'DRAFT',
      quotationType: _type,
      customerId: _customerId,
      customerName: _customerNameController.text.trim(),
      customerContact: _customerContactController.text.trim(),
      customerAddress: _customerAddressController.text.trim().isEmpty
          ? null
          : _customerAddressController.text.trim(),
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      referenceDate: _referenceDate,
      eventLocation: _locationController.text.trim().isEmpty
          ? null
          : _locationController.text.trim(),
      validUntil: _referenceDate,
      subEvents: List.from(_subEvents),
      items: List.from(_orderItems),
      eventCharges: _eventCharges,
      discountAmount: _discountAmount,
      totalAmount: _totalAmount,
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
      createdAt: existing?.createdAt ?? now,
      updatedAt: now,
    );
  }

  Future<void> _printQuotation() async {
    if (_titleController.text.trim().isEmpty) {
      GlassyToast.show(context, 'Please enter a title', isError: true);
      return;
    }
    if (_isPrinting) return;

    setState(() => _isPrinting = true);
    try {
      await QuotationPrintService.instance.showQuotationPdfPreview(
        context: context,
        quotation: _quotationSnapshot(),
        localizations: _l10n,
      );
    } finally {
      if (mounted) setState(() => _isPrinting = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_titleController.text.trim().isEmpty) {
      GlassyToast.show(context, 'Please enter a title', isError: true);
      return;
    }

    setState(() => _isLoading = true);
    try {
      final controller = QuotationOfflineController.instance;

      if (_isEditing) {
        final localId = widget.existing!.id.startsWith('local_')
            ? int.parse(widget.existing!.id.substring(6))
            : int.tryParse(widget.existing!.id) ?? 0;

        await controller.updateQuotation(
          id: localId,
          quotationType: _type,
          customerId: _customerId,
          customerName: _customerNameController.text.trim(),
          customerContact: _customerContactController.text.trim(),
          customerAddress: _customerAddressController.text.trim().isEmpty
              ? null
              : _customerAddressController.text.trim(),
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          referenceDate: _referenceDate,
          eventLocation: _locationController.text.trim().isEmpty
              ? null
              : _locationController.text.trim(),
          validUntil: _referenceDate,
          subEvents: _subEvents,
          items: _orderItems,
          eventCharges: _eventCharges,
          discountAmount: _discountAmount,
          notes: _notesController.text.trim().isEmpty
              ? null
              : _notesController.text.trim(),
        );
      } else {
        await controller.addQuotation(
          quotationType: _type,
          customerId: _customerId,
          customerName: _customerNameController.text.trim(),
          customerContact: _customerContactController.text.trim(),
          customerAddress: _customerAddressController.text.trim().isEmpty
              ? null
              : _customerAddressController.text.trim(),
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          referenceDate: _referenceDate,
          eventLocation: _locationController.text.trim().isEmpty
              ? null
              : _locationController.text.trim(),
          validUntil: _referenceDate,
          subEvents: _subEvents,
          items: _orderItems,
          eventCharges: _eventCharges,
          discountAmount: _discountAmount,
          notes: _notesController.text.trim().isEmpty
              ? null
              : _notesController.text.trim(),
        );
      }

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        GlassyToast.show(context, '${_l10n.error}: $e', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _customerNameController.dispose();
    _customerContactController.dispose();
    _customerAddressController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _eventChargesController.dispose();
    _discountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _l10n = AppLocalizations.of(LanguageService.instance.currentLanguage);
    final dateFormat = DateFormat('dd MMM yyyy');

    final isDark = AppColors.isDark(context);
    return Scaffold(
      backgroundColor: AppColors.scaffold(context),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                children: [
                  _sectionCard(
                    icon: Icons.category_outlined,
                    title: _l10n.quotation,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SegmentedButton<QuotationType>(
                        style: ButtonStyle(
                          backgroundColor: WidgetStateProperty.resolveWith((
                            states,
                          ) {
                            if (states.contains(WidgetState.selected)) {
                              return AppColors.action(context);
                            }
                            return isDark
                                ? AppTheme.darkScaffold
                                : AppTheme.grey100;
                          }),
                          foregroundColor: WidgetStateProperty.resolveWith((
                            states,
                          ) {
                            if (states.contains(WidgetState.selected)) {
                              return AppTheme.white;
                            }
                            return AppColors.primaryText(context);
                          }),
                          side: WidgetStateProperty.all(BorderSide.none),
                          shape: WidgetStateProperty.all(
                            RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          textStyle: WidgetStateProperty.all(
                            const TextStyle(
                              fontFamily: 'Literata',
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        segments: [
                          ButtonSegment(
                            value: QuotationType.product,
                            label: Text(_l10n.productsOnly),
                            icon: const Icon(Icons.inventory_2_outlined, size: 16),
                          ),
                          ButtonSegment(
                            value: QuotationType.event,
                            label: Text(_l10n.eventOnly),
                            icon: const Icon(Icons.celebration_outlined, size: 16),
                          ),
                          ButtonSegment(
                            value: QuotationType.hybrid,
                            label: Text(_l10n.eventAndProducts),
                            icon: const Icon(Icons.layers_outlined, size: 16),
                          ),
                        ],
                        selected: {_type},
                        onSelectionChanged: (value) {
                          setState(() => _type = value.first);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _sectionCard(
                    icon: Icons.person_outline_rounded,
                    title: _l10n.customerDetails,
                    child: Column(
                      children: [
                        _pillField(
                          controller: _customerNameController,
                          label: _l10n.customerName,
                          icon: Icons.person_outline_rounded,
                          onChanged: _searchCustomers,
                        ),
                        if (_customerSuggestions.isNotEmpty)
                          ..._customerSuggestions.map(
                            (c) => Material(
                              color: AppTheme.transparent,
                              child: ListTile(
                                dense: true,
                                contentPadding: EdgeInsets.zero,
                                title: Text(
                                  c.name,
                                  style: TextStyle(
                                    fontFamily: 'Literata',
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primaryText(context),
                                  ),
                                ),
                                subtitle: Text(
                                  c.mobile,
                                  style: TextStyle(
                                    fontFamily: 'Literata',
                                    color: AppColors.mutedText(context),
                                  ),
                                ),
                                onTap: () => _selectCustomer(c),
                              ),
                            ),
                          ),
                        const SizedBox(height: 14),
                        _pillField(
                          controller: _customerContactController,
                          label: _l10n.contact,
                          icon: Icons.phone_outlined,
                          keyboardType: TextInputType.phone,
                        ),
                        const SizedBox(height: 14),
                        _pillField(
                          controller: _customerAddressController,
                          label: _l10n.address,
                          icon: Icons.location_on_outlined,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _sectionCard(
                    icon: Icons.receipt_long_rounded,
                    title: _l10n.orderName,
                    child: Column(
                      children: [
                        _pillField(
                          controller: _titleController,
                          label: _l10n.orderName,
                          icon: Icons.title_rounded,
                        ),
                        const SizedBox(height: 14),
                        _pillField(
                          controller: _descriptionController,
                          label: _l10n.description,
                          icon: Icons.notes_rounded,
                          maxLines: 2,
                        ),
                        const SizedBox(height: 14),
                        _datePill(
                          label: _l10n.eventOrderDate,
                          value: dateFormat.format(_referenceDate),
                          onTap: () => _pickDate(
                            initial: _referenceDate,
                            onPicked: (d) => setState(() => _referenceDate = d),
                          ),
                        ),
                        if (_showEvents) ...[
                          const SizedBox(height: 14),
                          _pillField(
                            controller: _locationController,
                            label: _l10n.locationVenueOptional,
                            icon: Icons.location_on_outlined,
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (_showEvents) ...[
                    const SizedBox(height: 16),
                    _sectionCard(
                      icon: Icons.event_note_rounded,
                      title: _l10n.subEvents,
                      trailing: _circleAdd(onTap: _addSubEvent),
                      child: Column(
                        children: [
                          _pillField(
                            controller: _eventChargesController,
                            label: 'Event Charges',
                            icon: Icons.currency_rupee_rounded,
                            keyboardType: TextInputType.number,
                            onChanged: (_) => setState(() {}),
                          ),
                          ..._subEvents.map(
                            (e) => Material(
                              color: AppTheme.transparent,
                              child: ListTile(
                                contentPadding: EdgeInsets.zero,
                                title: Text(
                                  e.name,
                                  style: TextStyle(
                                    fontFamily: 'Literata',
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primaryText(context),
                                  ),
                                ),
                                subtitle: Text(
                                  dateFormat.format(e.date),
                                  style: TextStyle(
                                    fontFamily: 'Literata',
                                    color: AppColors.mutedText(context),
                                  ),
                                ),
                                trailing: Text(
                                  '₹${e.charges.toStringAsFixed(0)}',
                                  style: TextStyle(
                                    fontFamily: 'Literata',
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.primaryText(context),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (_showProducts) ...[
                    const SizedBox(height: 16),
                    _sectionCard(
                      icon: Icons.inventory_2_outlined,
                      title: _l10n.productsOnly,
                      child: QuotationProductsPanel(
                        items: _orderItems,
                        localizations: _l10n,
                        onItemsChanged: (items) {
                          setState(() => _orderItems = items);
                        },
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  _sectionCard(
                    icon: Icons.currency_rupee_rounded,
                    title: _l10n.totalAmount,
                    child: Column(
                      children: [
                        _pillField(
                          controller: _discountController,
                          label: _l10n.discount,
                          icon: Icons.percent_rounded,
                          keyboardType: TextInputType.number,
                          onChanged: (_) => setState(() {}),
                        ),
                        const SizedBox(height: 14),
                        _pillField(
                          controller: _notesController,
                          label: _l10n.notes,
                          icon: Icons.notes_rounded,
                          maxLines: 2,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _l10n.totalAmount,
                              style: TextStyle(
                                fontFamily: 'Literata',
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                                color: AppColors.primaryText(context),
                              ),
                            ),
                            Text(
                              '₹${_totalAmount.toStringAsFixed(0)}',
                              style: TextStyle(
                                fontFamily: 'Literata',
                                fontWeight: FontWeight.w800,
                                fontSize: 20,
                                color: _primary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            _buildSaveBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return AppTopBar(
      title: _isEditing ? _l10n.quotation : _l10n.newQuotation,
      subtitle: _isEditing
          ? 'Modify your quotation details'
          : 'Fill in the details below',
      actions: [
        AppTopBar.action(
          icon: Icons.print_rounded,
          onTap: (_isLoading || _isPrinting) ? null : _printQuotation,
          isLoading: _isPrinting,
        ),
      ],
    );
  }

  Widget _buildSaveBar() {
    final isDark = AppColors.isDark(context);
    return Container(
      color: AppColors.scaffold(context),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.action(context),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: AppColors.action(context).withValues(alpha: isDark ? 0.45 : 0.28),
              blurRadius: isDark ? 22 : 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: _isLoading ? null : _save,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.transparent,
            shadowColor: AppTheme.transparent,
            disabledBackgroundColor: AppTheme.transparent,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
            ),
          ),
          child: _isLoading
              ? const SizedBox(
                  height: 22,
                  width: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(AppTheme.white),
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.check_circle_rounded,
                      color: AppTheme.white,
                      size: 22,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      _l10n.saveChanges,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Literata',
                        color: AppTheme.white,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _circleAdd({required VoidCallback onTap}) {
    return Material(
      color: AppColors.isDark(context) ? AppTheme.darkElevated : AppTheme.white,
      shape: CircleBorder(
        side: BorderSide(
          color: AppColors.action(context).withValues(alpha: 0.85),
          width: 1.4,
        ),
      ),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(Icons.add, color: AppColors.action(context), size: 22),
        ),
      ),
    );
  }

  Widget _sectionHeading(IconData icon, String title) {
    final isDark = AppColors.isDark(context);
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.action(context).withValues(alpha: isDark ? 0.22 : 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.action(context), size: 18),
        ),
        const SizedBox(width: 10),
        Flexible(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              fontFamily: 'Literata',
              color: AppColors.primaryText(context),
            ),
          ),
        ),
      ],
    );
  }

  Widget _sectionCard({
    required IconData icon,
    required String title,
    required Widget child,
    Widget? trailing,
  }) {
    final isDark = AppColors.isDark(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkElevated : AppTheme.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? AppTheme.darkBorder : AppTheme.grey200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: _sectionHeading(icon, title)),
              if (trailing != null) ...[
                const SizedBox(width: 8),
                trailing,
              ],
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _pillField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
    ValueChanged<String>? onChanged,
  }) {
    final isDark = AppColors.isDark(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            fontFamily: 'Literata',
            color: AppColors.secondaryText(context),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          onChanged: onChanged,
          style: TextStyle(
            fontFamily: 'Literata',
            fontWeight: FontWeight.w500,
            fontSize: 14,
            color: AppColors.primaryText(context),
          ),
          decoration: InputDecoration(
            hintText: label,
            hintStyle: TextStyle(
              color: AppColors.mutedText(context),
              fontFamily: 'Literata',
              fontWeight: FontWeight.w500,
            ),
            prefixIcon: Icon(icon, color: AppColors.mutedText(context), size: 18),
            filled: true,
            fillColor: isDark ? AppTheme.darkScaffold : AppTheme.grey100,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: AppColors.action(context), width: 1.4),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 14,
            ),
          ),
        ),
      ],
    );
  }

  Widget _datePill({
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    final isDark = AppColors.isDark(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            fontFamily: 'Literata',
            color: AppColors.secondaryText(context),
          ),
        ),
        const SizedBox(height: 8),
        Material(
          color: isDark ? AppTheme.darkScaffold : AppTheme.grey100,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 16,
                    color: AppColors.mutedText(context),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Literata',
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.primaryText(context),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

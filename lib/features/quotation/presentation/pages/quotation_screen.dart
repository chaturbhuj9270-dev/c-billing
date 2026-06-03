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

class QuotationScreen extends StatefulWidget {
  final Quotation? existing;

  const QuotationScreen({super.key, this.existing});

  @override
  State<QuotationScreen> createState() => _QuotationScreenState();
}

class _QuotationScreenState extends State<QuotationScreen> {
  static const _primary = Color(0xFF1B4D3E);
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
  DateTime _validUntil = DateTime.now().add(const Duration(days: 15));

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
    _validUntil = q.validUntil;
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
            child: Text(_l10n.add, style: const TextStyle(color: Colors.white)),
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
      validUntil: _validUntil,
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
          validUntil: _validUntil,
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
          validUntil: _validUntil,
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

    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        title: Text(
          _isEditing ? _l10n.quotation : _l10n.newQuotation,
          style: const TextStyle(
            fontFamily: 'Literata',
            fontWeight: FontWeight.w800,
            color: _primary,
          ),
        ),
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2, color: _primary),
              ),
            )
          else ...[
            if (_isPrinting)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: _primary,
                  ),
                ),
              )
            else
              IconButton(
                onPressed: _printQuotation,
                tooltip: _l10n.quotation,
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.print_rounded,
                    color: _primary,
                    size: 20,
                  ),
                ),
              ),
            TextButton(
              onPressed: _save,
              child: Text(
                _l10n.saveChanges,
                style: const TextStyle(
                  fontFamily: 'Literata',
                  fontWeight: FontWeight.w700,
                  color: _primary,
                ),
              ),
            ),
          ],
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _sectionCard(
              child: SegmentedButton<QuotationType>(
                segments: [
                  ButtonSegment(
                    value: QuotationType.product,
                    label: Text(_l10n.productsOnly),
                  ),
                  ButtonSegment(
                    value: QuotationType.event,
                    label: Text(_l10n.eventOnly),
                  ),
                  ButtonSegment(
                    value: QuotationType.hybrid,
                    label: Text(_l10n.eventAndProducts),
                  ),
                ],
                selected: {_type},
                onSelectionChanged: (value) {
                  setState(() => _type = value.first);
                },
              ),
            ),
            const SizedBox(height: 12),
            _sectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _l10n.customerDetails,
                    style: const TextStyle(
                      fontFamily: 'Literata',
                      fontWeight: FontWeight.w700,
                      color: _primary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _customerNameController,
                    decoration: InputDecoration(
                      labelText: _l10n.customerName,
                      labelStyle: const TextStyle(fontFamily: 'Literata'),
                    ),
                    onChanged: _searchCustomers,
                  ),
                  if (_customerSuggestions.isNotEmpty)
                    ..._customerSuggestions.map(
                      (c) => Material(
                        color: Colors.transparent,
                        child: ListTile(
                          dense: true,
                          title: Text(c.name),
                          subtitle: Text(c.mobile),
                          onTap: () => _selectCustomer(c),
                        ),
                      ),
                    ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _customerContactController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: _l10n.contact,
                      labelStyle: const TextStyle(fontFamily: 'Literata'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _customerAddressController,
                    decoration: InputDecoration(
                      labelText: _l10n.address,
                      labelStyle: const TextStyle(fontFamily: 'Literata'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _sectionCard(
              child: Column(
                children: [
                  TextFormField(
                    controller: _titleController,
                    decoration: InputDecoration(
                      labelText: _l10n.orderName,
                      labelStyle: const TextStyle(fontFamily: 'Literata'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _descriptionController,
                    maxLines: 2,
                    decoration: InputDecoration(
                      labelText: _l10n.description,
                      labelStyle: const TextStyle(fontFamily: 'Literata'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Material(
                    color: Colors.transparent,
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        'Reference: ${dateFormat.format(_referenceDate)}',
                        style: const TextStyle(fontFamily: 'Literata'),
                      ),
                      trailing: const Icon(
                        Icons.calendar_today,
                        color: _primary,
                      ),
                      onTap: () => _pickDate(
                        initial: _referenceDate,
                        onPicked: (d) => setState(() => _referenceDate = d),
                      ),
                    ),
                  ),
                  Material(
                    color: Colors.transparent,
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        '${_l10n.validUntil}: ${dateFormat.format(_validUntil)}',
                        style: const TextStyle(fontFamily: 'Literata'),
                      ),
                      trailing: const Icon(Icons.event, color: _primary),
                      onTap: () => _pickDate(
                        initial: _validUntil,
                        onPicked: (d) => setState(() => _validUntil = d),
                      ),
                    ),
                  ),
                  if (_showEvents)
                    TextFormField(
                      controller: _locationController,
                      decoration: InputDecoration(
                        labelText: _l10n.locationVenueOptional,
                        labelStyle: const TextStyle(fontFamily: 'Literata'),
                      ),
                    ),
                ],
              ),
            ),
            if (_showEvents) ...[
              const SizedBox(height: 12),
              _sectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          _l10n.subEvents,
                          style: const TextStyle(
                            fontFamily: 'Literata',
                            fontWeight: FontWeight.w700,
                            color: _primary,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: _addSubEvent,
                          icon: const Icon(Icons.add_circle, color: _primary),
                        ),
                      ],
                    ),
                    TextFormField(
                      controller: _eventChargesController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Event Charges',
                        labelStyle: TextStyle(fontFamily: 'Literata'),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                    ..._subEvents.map(
                      (e) => Material(
                        color: Colors.transparent,
                        child: ListTile(
                          title: Text(e.name),
                          subtitle: Text(dateFormat.format(e.date)),
                          trailing: Text('₹${e.charges.toStringAsFixed(0)}'),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (_showProducts) ...[
              const SizedBox(height: 12),
              _sectionCard(
                child: QuotationProductsPanel(
                  items: _orderItems,
                  localizations: _l10n,
                  onItemsChanged: (items) {
                    setState(() => _orderItems = items);
                  },
                ),
              ),
            ],
            const SizedBox(height: 12),
            _sectionCard(
              child: Column(
                children: [
                  TextFormField(
                    controller: _discountController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: _l10n.discount,
                      labelStyle: const TextStyle(fontFamily: 'Literata'),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _notesController,
                    maxLines: 2,
                    decoration: InputDecoration(
                      labelText: _l10n.notes,
                      labelStyle: const TextStyle(fontFamily: 'Literata'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _l10n.totalAmount,
                        style: const TextStyle(
                          fontFamily: 'Literata',
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        '₹${_totalAmount.toStringAsFixed(0)}',
                        style: const TextStyle(
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
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _sectionCard({required Widget child}) {
    return Material(
      color: Colors.white,
      elevation: 0,
      shadowColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: child,
      ),
    );
  }
}

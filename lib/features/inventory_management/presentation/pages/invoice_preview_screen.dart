import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:c_billing/core/services/dashboard_refresh_service.dart';
import 'package:c_billing/core/services/inventory_integration_service.dart';

import '../../data/services/invoice_parser_service.dart';
import '../../data/services/purchase_sync_service.dart';
import '../../data/services/purchase_batch_sync_service.dart';
import '../../models/parsed_purchase_item.dart';
import '../../../product/offline/controllers/product_offline_controller.dart';
import '../../../supplier/offline/controllers/supplier_offline_controller.dart';

const _primaryColor = Color(0xFF1B4D3E);
const _secondaryColor = Color(0xFF0F3B2F);
const _bgColor = Color(0xFFF5F7F6);
const _fontFamily = 'Literata';

/// Screen to preview and edit parsed invoice items before saving as purchases.
class InvoicePreviewScreen extends StatefulWidget {
  final InvoiceParseResult parseResult;

  const InvoicePreviewScreen({super.key, required this.parseResult});

  @override
  State<InvoicePreviewScreen> createState() => _InvoicePreviewScreenState();
}

class _InvoicePreviewScreenState extends State<InvoicePreviewScreen>
    with SingleTickerProviderStateMixin {
  late List<ParsedPurchaseItem> _items;
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;

  // Supplier selection
  List<Map<String, dynamic>> _suppliers = [];
  String? _selectedSupplierId;
  String? _selectedSupplierName;

  // Invoice metadata
  late DateTime _invoiceDate;

  // Per-item text controllers
  final Map<int, _ItemControllers> _controllers = {};

  bool _isSaving = false;
  bool _isLoadingSuppliers = true;

  @override
  void initState() {
    super.initState();
    _items = List.from(widget.parseResult.items);
    _invoiceDate = widget.parseResult.invoiceDate ?? DateTime.now();

    _animController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );
    _animController.forward();

    _initControllers();
    _loadSuppliers();
  }

  void _initControllers() {
    for (int i = 0; i < _items.length; i++) {
      _createControllersForIndex(i);
    }
  }

  void _createControllersForIndex(int i) {
    final item = _items[i];
    _controllers[i] = _ItemControllers(
      nameController: TextEditingController(text: item.productName),
      qtyController: TextEditingController(text: item.quantity.toString()),
      purchasePriceController: TextEditingController(
        text: item.purchasePrice > 0 ? item.purchasePrice.toString() : '',
      ),
      salesPriceController: TextEditingController(
        text: item.salesPrice > 0 ? item.salesPrice.toString() : '',
      ),
    );
  }

  Future<void> _loadSuppliers() async {
    try {
      final suppliers =
          await SupplierOfflineController.instance.getAllSuppliers();
      if (mounted) {
        setState(() {
          _suppliers =
              suppliers
                  .where((s) => s.isActive)
                  .map(
                    (s) => {
                      'id': s.serverId ?? 'local_${s.id}',
                      'fullName': s.fullName,
                    },
                  )
                  .toList();
          _isLoadingSuppliers = false;
        });
      }
    } catch (e) {
      debugPrint('[InvoicePreview] Failed to load suppliers: $e');
      if (mounted) setState(() => _isLoadingSuppliers = false);
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  // Sync item data from controllers
  void _syncItemFromControllers(int index) {
    final c = _controllers[index];
    if (c == null || index >= _items.length) return;

    _items[index].productName = c.nameController.text;
    _items[index].quantity = int.tryParse(c.qtyController.text) ?? 0;
    _items[index].purchasePrice =
        double.tryParse(c.purchasePriceController.text) ?? 0;
    _items[index].salesPrice =
        double.tryParse(c.salesPriceController.text) ?? 0;
  }

  void _addItem() {
    setState(() {
      final newItem = ParsedPurchaseItem(
        productName: '',
        quantity: 1,
        purchasePrice: 0,
        salesPrice: 0,
        confidence: 1.0, // Manual entry = full confidence
      );
      _items.add(newItem);
      _createControllersForIndex(_items.length - 1);
    });
  }

  void _removeItem(int index) {
    setState(() {
      _items.removeAt(index);
      _controllers[index]?.dispose();

      // Re-index controllers: keys below index stay, keys above shift down by 1
      final newControllers = <int, _ItemControllers>{};
      for (final entry in _controllers.entries) {
        if (entry.key < index) {
          newControllers[entry.key] = entry.value;
        } else if (entry.key > index) {
          newControllers[entry.key - 1] = entry.value;
        }
      }
      _controllers
        ..clear()
        ..addAll(newControllers);
    });
  }

  void _clearMatch(int index) {
    setState(() {
      _items[index].matchedProductId = null;
      _items[index].matchedProductName = null;
      _items[index].matchedCompanyName = null;
      _items[index].matchedCategory = null;
      _items[index].existingSalesPrice = null;
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _invoiceDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: _primaryColor,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black87,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() => _invoiceDate = picked);
    }
  }

  int get _validSelectedCount =>
      _items.where((i) => i.isSelected && i.isValid).length;

  double get _grandTotal {
    double total = 0;
    for (int i = 0; i < _items.length; i++) {
      if (_items[i].isSelected) {
        _syncItemFromControllers(i);
        total += _items[i].total;
      }
    }
    return total;
  }

  int get _totalQuantity {
    int qty = 0;
    for (int i = 0; i < _items.length; i++) {
      if (_items[i].isSelected) {
        _syncItemFromControllers(i);
        qty += _items[i].quantity;
      }
    }
    return qty;
  }

  bool get _hasLowConfidence => _items.any((i) => i.confidence < 0.5);

  Future<void> _saveAllItems() async {
    // Sync all items from controllers
    for (int i = 0; i < _items.length; i++) {
      _syncItemFromControllers(i);
    }

    final selectedItems =
        _items.where((i) => i.isSelected && i.isValid).toList();
    if (selectedItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No valid items to save',
            style: TextStyle(fontFamily: _fontFamily),
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Validate sales prices
    final missingSalesPrices =
        selectedItems.where((i) => i.salesPrice <= 0).toList();
    if (missingSalesPrices.isNotEmpty) {
      final proceed = await _showConfirmDialog(
        'Missing Sales Prices',
        '${missingSalesPrices.length} item(s) have no sales price set. '
            'Products without a sales price will use 0. Continue?',
      );
      if (!proceed) return;
    }

    if (_selectedSupplierId == null) {
      final proceed = await _showConfirmDialog(
        'No Supplier Selected',
        'No supplier is selected for this purchase. Continue without supplier?',
      );
      if (!proceed) return;
    }

    setState(() => _isSaving = true);

    int savedCount = 0;
    int failedCount = 0;
    final errors = <String>[];

    for (final item in selectedItems) {
      try {
        // If no matched product, create a new one
        if (item.matchedProductId == null) {
          try {
            final newProduct = await ProductOfflineController.instance
                .addProduct(
                  name: item.productName.trim(),
                  companyName: item.matchedCompanyName ?? '',
                  category: item.matchedCategory ?? '',
                  purchasePrice: item.purchasePrice,
                  salesPrice: item.salesPrice,
                  currentStock: 0,
                  unit: item.unit,
                  hsnCode: item.hsnCode,
                  cgstPercent: item.cgstPercent ?? 0.0,
                  sgstPercent: item.sgstPercent ?? 0.0,
                );
            item.matchedProductId =
                newProduct.serverId ?? 'local_${newProduct.id}';
            item.matchedProductName = newProduct.name;
          } catch (e) {
            // Duplicate product - try to find existing
            debugPrint(
              '[InvoicePreview] addProduct failed (likely duplicate): $e',
            );
            final existing = await ProductOfflineController.instance
                .searchByName(item.productName.trim());
            if (existing.isNotEmpty) {
              final match = existing.first;
              item.matchedProductId =
                  match.serverId ?? 'local_${match.id}';
              item.matchedProductName = match.name;
            } else {
              throw Exception('Could not create or find product');
            }
          }
        }

        final result = await InventoryIntegrationService.instance
            .processPurchase(
              productId: item.matchedProductId!,
              productName: item.matchedProductName ?? item.productName,
              supplierId: _selectedSupplierId,
              supplierName: _selectedSupplierName,
              companyName: item.matchedCompanyName,
              quantity: item.quantity,
              unit: item.unit,
              purchasePrice: item.purchasePrice,
              salesPrice: item.salesPrice,
              notes: 'Scanned from invoice',
            );

        if (result.success) {
          savedCount++;
        } else {
          failedCount++;
          errors.add(
            '${item.productName}: ${result.errorMessage ?? "Unknown error"}',
          );
        }
      } catch (e) {
        failedCount++;
        errors.add('${item.productName}: $e');
        debugPrint(
          '[InvoicePreview] Failed to save item ${item.productName}: $e',
        );
      }
    }

    // Trigger all refreshes
    PurchaseSyncService.instance.syncNow();
    PurchaseBatchSyncService.instance.syncNow();
    DashboardRefreshService.instance.notifyDataChanged(
      DataChangeType.purchase,
    );
    DashboardRefreshService.instance.notifyDataChanged(
      DataChangeType.product,
    );

    setState(() => _isSaving = false);

    if (mounted) {
      final message =
          failedCount > 0
              ? 'Saved $savedCount items, $failedCount failed'
              : 'Successfully saved $savedCount items';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message, style: const TextStyle(fontFamily: _fontFamily)),
          backgroundColor: failedCount > 0 ? Colors.orange : _primaryColor,
          duration: const Duration(seconds: 3),
        ),
      );

      Navigator.pop(context, savedCount > 0);
    }
  }

  Future<bool> _showConfirmDialog(String title, String message) async {
    final result = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Text(
              title,
              style: const TextStyle(
                fontFamily: _fontFamily,
                fontWeight: FontWeight.w700,
                fontSize: 16,
                color: _primaryColor,
              ),
            ),
            content: Text(
              message,
              style: const TextStyle(fontFamily: _fontFamily, fontSize: 14),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(
                  'Cancel',
                  style: TextStyle(
                    fontFamily: _fontFamily,
                    color: Colors.grey[600],
                  ),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text(
                  'Continue',
                  style: TextStyle(fontFamily: _fontFamily, color: _primaryColor),
                ),
              ),
            ],
          ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            children: [
              _buildAppBar(),
              Expanded(
                child: _isSaving ? _buildSavingOverlay() : _buildBody(),
              ),
              _buildBottomBar(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.arrow_back_rounded,
                color: _primaryColor,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Invoice Preview',
                  style: TextStyle(
                    fontFamily: _fontFamily,
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                Text(
                  'Review and edit scanned items',
                  style: TextStyle(
                    fontFamily: _fontFamily,
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: _primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${_items.length} items',
              style: const TextStyle(
                fontFamily: _fontFamily,
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: _primaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (_hasLowConfidence) _buildWarningBanner(),
        _buildInvoiceInfoCard(),
        const SizedBox(height: 16),
        ..._buildItemCards(),
        const SizedBox(height: 8),
        _buildAddItemButton(),
        const SizedBox(height: 100), // Space for bottom bar
      ],
    );
  }

  Widget _buildWarningBanner() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: Colors.orange.shade700),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Some items have low scan confidence. Please verify the data before saving.',
              style: TextStyle(
                fontFamily: _fontFamily,
                fontSize: 13,
                color: Colors.orange.shade900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInvoiceInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Invoice Details',
            style: TextStyle(
              fontFamily: _fontFamily,
              fontWeight: FontWeight.w700,
              fontSize: 15,
              color: _primaryColor,
            ),
          ),
          const SizedBox(height: 16),

          // Supplier dropdown
          const Text(
            'Supplier',
            style: TextStyle(
              fontFamily: _fontFamily,
              fontWeight: FontWeight.w600,
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 6),
          _isLoadingSuppliers
              ? const LinearProgressIndicator(color: _primaryColor)
              : Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedSupplierId,
                      hint: const Text(
                        'Select supplier',
                        style: TextStyle(
                          fontFamily: _fontFamily,
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                      isExpanded: true,
                      icon: const Icon(
                        Icons.expand_more_rounded,
                        color: _primaryColor,
                      ),
                      items:
                          _suppliers.map((s) {
                            return DropdownMenuItem<String>(
                              value: s['id'] as String,
                              child: Text(
                                s['fullName'] as String,
                                style: const TextStyle(
                                  fontFamily: _fontFamily,
                                  fontSize: 14,
                                ),
                              ),
                            );
                          }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedSupplierId = value;
                          _selectedSupplierName =
                              _suppliers
                                  .firstWhere(
                                    (s) => s['id'] == value,
                                  )['fullName'] as String?;
                        });
                      },
                    ),
                  ),
                ),

          const SizedBox(height: 16),

          // Invoice date
          const Text(
            'Invoice Date',
            style: TextStyle(
              fontFamily: _fontFamily,
              fontWeight: FontWeight.w600,
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 6),
          GestureDetector(
            onTap: _pickDate,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.calendar_today_rounded,
                    size: 18,
                    color: _primaryColor,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    DateFormat('dd MMM yyyy').format(_invoiceDate),
                    style: const TextStyle(
                      fontFamily: _fontFamily,
                      fontSize: 14,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.edit_rounded,
                    size: 16,
                    color: Colors.grey.shade400,
                  ),
                ],
              ),
            ),
          ),

          // Invoice number (if detected)
          if (widget.parseResult.invoiceNumber != null) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                const Text(
                  'Invoice #: ',
                  style: TextStyle(
                    fontFamily: _fontFamily,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
                Text(
                  widget.parseResult.invoiceNumber!,
                  style: const TextStyle(
                    fontFamily: _fontFamily,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: _primaryColor,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  List<Widget> _buildItemCards() {
    final widgets = <Widget>[];
    for (int i = 0; i < _items.length; i++) {
      widgets.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildItemCard(i),
        ),
      );
    }
    return widgets;
  }

  Widget _buildItemCard(int index) {
    final item = _items[index];
    final c = _controllers[index];
    if (c == null) return const SizedBox.shrink();

    // Confidence colors
    Color cardBorder = Colors.grey.shade200;
    Color? cardBg = Colors.white;
    if (item.confidence < 0.4) {
      cardBorder = Colors.red.shade200;
      cardBg = Colors.red.shade50;
    } else if (item.confidence < 0.7) {
      cardBorder = Colors.orange.shade200;
      cardBg = Colors.orange.shade50;
    }

    // Validation
    final isNameEmpty = c.nameController.text.trim().isEmpty;
    final qty = int.tryParse(c.qtyController.text) ?? 0;

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row: checkbox, item number, delete
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
            child: Row(
              children: [
                SizedBox(
                  width: 32,
                  height: 32,
                  child: Checkbox(
                    value: item.isSelected,
                    activeColor: _primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                    onChanged: (v) {
                      setState(() => item.isSelected = v ?? true);
                    },
                  ),
                ),
                Text(
                  '#${index + 1}',
                  style: TextStyle(
                    fontFamily: _fontFamily,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: Colors.grey.shade600,
                  ),
                ),
                const Spacer(),
                // Confidence indicator
                _buildConfidenceChip(item.confidence),
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: () => _removeItem(index),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.close_rounded,
                      size: 16,
                      color: Colors.red.shade400,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product name
                TextField(
                  controller: c.nameController,
                  onChanged: (_) => setState(() {}),
                  style: const TextStyle(
                    fontFamily: _fontFamily,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Product Name',
                    labelStyle: TextStyle(
                      fontFamily: _fontFamily,
                      fontSize: 12,
                      color: Colors.grey.shade500,
                    ),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color:
                            isNameEmpty
                                ? Colors.red.shade300
                                : Colors.grey.shade300,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(
                        color: _primaryColor,
                        width: 2,
                      ),
                    ),
                  ),
                ),

                // Match indicator
                if (item.hasMatch) ...[
                  const SizedBox(height: 6),
                  GestureDetector(
                    onTap: () => _clearMatch(index),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _primaryColor.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.link_rounded,
                            size: 14,
                            color: _primaryColor,
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              'Matched: ${item.matchedProductName ?? ""}${item.matchedCompanyName != null && item.matchedCompanyName!.isNotEmpty ? " (${item.matchedCompanyName})" : ""}',
                              style: const TextStyle(
                                fontFamily: _fontFamily,
                                fontSize: 11,
                                color: _primaryColor,
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.close,
                            size: 12,
                            color: _primaryColor.withOpacity(0.5),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 10),

                // Qty, Purchase Price, Sales Price row
                Row(
                  children: [
                    // Quantity
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: c.qtyController,
                        keyboardType: TextInputType.number,
                        onChanged: (_) => setState(() {}),
                        style: const TextStyle(
                          fontFamily: _fontFamily,
                          fontSize: 13,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Qty',
                          labelStyle: TextStyle(
                            fontFamily: _fontFamily,
                            fontSize: 11,
                            color: Colors.grey.shade500,
                          ),
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 10,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color:
                                  qty <= 0
                                      ? Colors.red.shade300
                                      : Colors.grey.shade300,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: _primaryColor,
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Purchase Price
                    Expanded(
                      flex: 3,
                      child: TextField(
                        controller: c.purchasePriceController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        onChanged: (_) => setState(() {}),
                        style: const TextStyle(
                          fontFamily: _fontFamily,
                          fontSize: 13,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Purchase Price',
                          prefixText: '\u20B9 ',
                          prefixStyle: TextStyle(
                            fontFamily: _fontFamily,
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                          labelStyle: TextStyle(
                            fontFamily: _fontFamily,
                            fontSize: 11,
                            color: Colors.grey.shade500,
                          ),
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 10,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: _primaryColor,
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Sales Price
                    Expanded(
                      flex: 3,
                      child: TextField(
                        controller: c.salesPriceController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        onChanged: (_) => setState(() {}),
                        style: const TextStyle(
                          fontFamily: _fontFamily,
                          fontSize: 13,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Sales Price',
                          prefixText: '\u20B9 ',
                          prefixStyle: TextStyle(
                            fontFamily: _fontFamily,
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                          labelStyle: TextStyle(
                            fontFamily: _fontFamily,
                            fontSize: 11,
                            color: Colors.grey.shade500,
                          ),
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 10,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: _primaryColor,
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                // Line total
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    'Total: \u20B9${_formatNumber((int.tryParse(c.qtyController.text) ?? 0) * (double.tryParse(c.purchasePriceController.text) ?? 0))}',
                    style: TextStyle(
                      fontFamily: _fontFamily,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfidenceChip(double confidence) {
    Color color;
    String label;
    if (confidence >= 0.7) {
      color = Colors.green;
      label = 'High';
    } else if (confidence >= 0.4) {
      color = Colors.orange;
      label = 'Medium';
    } else {
      color = Colors.red;
      label = 'Low';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontFamily: _fontFamily,
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddItemButton() {
    return GestureDetector(
      onTap: _addItem,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _primaryColor.withOpacity(0.3),
            style: BorderStyle.solid,
          ),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_rounded, size: 20, color: _primaryColor),
            SizedBox(width: 8),
            Text(
              'Add Item Manually',
              style: TextStyle(
                fontFamily: _fontFamily,
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: _primaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Summary row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total Qty: $_totalQuantity',
                    style: TextStyle(
                      fontFamily: _fontFamily,
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '\u20B9${_formatNumber(_grandTotal)}',
                    style: const TextStyle(
                      fontFamily: _fontFamily,
                      fontWeight: FontWeight.w700,
                      fontSize: 20,
                      color: _primaryColor,
                    ),
                  ),
                ],
              ),
              Text(
                '$_validSelectedCount of ${_items.length} items',
                style: TextStyle(
                  fontFamily: _fontFamily,
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Save button
          GestureDetector(
            onTap: _isSaving ? null : _saveAllItems,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    _isSaving
                        ? Colors.grey.shade400
                        : _primaryColor,
                    _isSaving
                        ? Colors.grey.shade500
                        : _secondaryColor,
                  ],
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color:
                        _isSaving
                            ? Colors.grey.withOpacity(0.3)
                            : _primaryColor.withOpacity(0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  _isSaving
                      ? 'Saving...'
                      : 'Save $_validSelectedCount Items',
                  style: const TextStyle(
                    fontFamily: _fontFamily,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSavingOverlay() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 48,
            height: 48,
            child: CircularProgressIndicator(
              color: _primaryColor,
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Saving purchases...',
            style: TextStyle(
              fontFamily: _fontFamily,
              fontWeight: FontWeight.w600,
              fontSize: 16,
              color: _primaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Please do not close this screen',
            style: TextStyle(
              fontFamily: _fontFamily,
              fontSize: 13,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  String _formatNumber(double value) {
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }
    return value.toStringAsFixed(2);
  }
}

/// Helper class to manage TextEditingControllers for each item row.
class _ItemControllers {
  final TextEditingController nameController;
  final TextEditingController qtyController;
  final TextEditingController purchasePriceController;
  final TextEditingController salesPriceController;

  _ItemControllers({
    required this.nameController,
    required this.qtyController,
    required this.purchasePriceController,
    required this.salesPriceController,
  });

  void dispose() {
    nameController.dispose();
    qtyController.dispose();
    purchasePriceController.dispose();
    salesPriceController.dispose();
  }
}

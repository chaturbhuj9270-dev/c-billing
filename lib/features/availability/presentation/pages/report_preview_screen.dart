import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:c_billing/features/inventory_management/domain/entities/report_item.dart';
import 'package:c_billing/core/services/inventory_report_service.dart';
import 'package:c_billing/core/services/stock_report_settings_service.dart';
import 'package:c_billing/core/localization/app_localizations.dart';
import 'package:c_billing/core/services/language_service.dart';
import 'package:c_billing/common_widgets/file_preview_page.dart';
import 'package:intl/intl.dart';

class ReportPreviewScreen extends StatefulWidget {
  final List<ReportItem> reportItems;
  final ReportType reportType;
  final ReportFormat selectedFormat;
  final String reportTitle;

  const ReportPreviewScreen({
    super.key,
    required this.reportItems,
    required this.reportType,
    required this.selectedFormat,
    required this.reportTitle,
  });

  @override
  State<ReportPreviewScreen> createState() => _ReportPreviewScreenState();
}

class _ReportPreviewScreenState extends State<ReportPreviewScreen>
    with SingleTickerProviderStateMixin {
  late List<ReportItem> _editableItems;
  bool _isGenerating = false;
  final _reportService = InventoryReportService();
  late AnimationController _animationController;
  late AppLocalizations _localizations;

  // Controllers for order quantity text fields
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, FocusNode> _focusNodes = {};

  // Visible columns cache
  List<String> _visibleColumnIds = [];

  @override
  void initState() {
    super.initState();
    _localizations = AppLocalizations.of(
      LanguageService.instance.currentLanguage,
    );
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _animationController.forward();

    // All items are selected by default, order qty is null (shown as "-")
    _editableItems = widget.reportItems
        .map(
          (item) =>
              ReportItem.fromProduct(item.product, expiryDate: item.expiryDate),
        )
        .toList();

    // Initialize text controllers – empty means null / dash
    for (final item in _editableItems) {
      final key = item.product.id;
      _controllers[key] = TextEditingController();
      _focusNodes[key] = FocusNode();
    }

    // Cache visible columns
    _loadVisibleColumns();
  }

  void _loadVisibleColumns() {
    final settings = StockReportSettingsService.instance;
    final columnOrder = [
      'sr_no',
      'product_name',
      'category',
      'company',
      'hsn_code',
      'purchase_price',
      'selling_price',
      'stock',
      'stock_value',
      'status',
      'order_qty',
      'supplier',
      'cgst',
      'sgst',
    ];

    _visibleColumnIds = columnOrder
        .where((id) => settings.isColumnVisible(id))
        .toList();

    // Fallback
    if (_visibleColumnIds.isEmpty) {
      _visibleColumnIds = ['product_name', 'stock', 'order_qty'];
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    for (var c in _controllers.values) {
      c.dispose();
    }
    for (var f in _focusNodes.values) {
      f.dispose();
    }
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  int get _selectedCount => _editableItems.where((e) => e.isSelected).length;
  bool get _allSelected => _editableItems.every((e) => e.isSelected);
  bool get _noneSelected => _editableItems.every((e) => !e.isSelected);

  void _toggleSelectAll(bool value) {
    setState(() {
      for (final item in _editableItems) {
        item.isSelected = value;
      }
    });
  }

  void _toggleItem(int index) {
    setState(() {
      _editableItems[index].isSelected = !_editableItems[index].isSelected;
    });
  }

  void _updateOrderQuantity(int index, String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      _editableItems[index].updateOrderQuantity(null);
    } else {
      final qty = int.tryParse(trimmed);
      _editableItems[index].updateOrderQuantity(qty);
    }
  }

  // ---------------------------------------------------------------------------
  // Report generation – only checked rows
  // ---------------------------------------------------------------------------

  Future<void> _generateReport() async {
    final selected = _editableItems.where((e) => e.isSelected).toList();

    if (selected.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 12),
              Text(
                _localizations.pleaseSelectAtLeastOneItem,
                style: const TextStyle(fontFamily: 'Literata'),
              ),
            ],
          ),
          backgroundColor: Colors.orange[700],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
      return;
    }

    setState(() => _isGenerating = true);

    try {
      final products = selected.map((e) => e.product).toList();
      final orderQuantities = selected.map((e) => e.orderQuantity).toList();

      late final File file;
      if (widget.selectedFormat == ReportFormat.pdf) {
        file = await _reportService.generatePdfReportWithOrderQty(
          products: products,
          orderQuantities: orderQuantities,
          reportType: widget.reportType,
          customTitle: widget.reportTitle,
        );
      } else {
        file = await _reportService.generateCsvReportWithOrderQty(
          products: products,
          orderQuantities: orderQuantities,
          reportType: widget.reportType,
          customTitle: widget.reportTitle,
        );
      }

      // Navigate to file preview page
      if (mounted) {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => FilePreviewPage(
              file: file,
              fileName: widget.reportTitle,
              fileType: widget.selectedFormat == ReportFormat.pdf
                  ? FilePreviewType.pdf
                  : FilePreviewType.csv,
              subtitle:
                  '${selected.length} products • ${DateFormat('dd MMM yyyy').format(DateTime.now())}',
              onClose: () {
                // Pop back to availability page when preview is closed
                if (mounted) Navigator.of(context).pop();
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Error: $e',
                    style: const TextStyle(fontFamily: 'Literata'),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.red[700],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isGenerating = false);
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F5),
      body: SafeArea(
        child: Column(
          children: [
            // Custom Header
            _buildHeader(),

            // Selection Summary Bar
            _buildSelectionBar(),

            // Product List
            Expanded(
              child: _editableItems.isEmpty
                  ? _buildEmptyState()
                  : _buildProductList(),
            ),

            // Bottom action bar
            _buildBottomBar(),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Header
  // ---------------------------------------------------------------------------

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 12, 16, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Back button
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF1B4D3E).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Color(0xFF1B4D3E),
                size: 18,
              ),
            ),
          ),
          const SizedBox(width: 4),
          // Title
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _localizations.reportPreview,
                  style: const TextStyle(
                    color: Color(0xFF1B4D3E),
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'Literata',
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(
                      widget.selectedFormat == ReportFormat.pdf
                          ? Icons.picture_as_pdf_rounded
                          : Icons.table_chart_rounded,
                      size: 14,
                      color: const Color(0xFF1B4D3E).withOpacity(0.6),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        widget.reportTitle,
                        style: TextStyle(
                          color: const Color(0xFF1B4D3E).withOpacity(0.7),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          fontFamily: 'Literata',
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Format badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: widget.selectedFormat == ReportFormat.pdf
                    ? [const Color(0xFFE53935), const Color(0xFFC62828)]
                    : [const Color(0xFF43A047), const Color(0xFF2E7D32)],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color:
                      (widget.selectedFormat == ReportFormat.pdf
                              ? Colors.red
                              : Colors.green)
                          .withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              widget.selectedFormat == ReportFormat.pdf ? 'PDF' : 'CSV',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                fontFamily: 'Literata',
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Selection Bar
  // ---------------------------------------------------------------------------

  Widget _buildSelectionBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF1B4D3E).withOpacity(0.08),
            const Color(0xFF1B4D3E).withOpacity(0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1B4D3E).withOpacity(0.15)),
      ),
      child: Row(
        children: [
          // Select all checkbox
          GestureDetector(
            onTap: () => _toggleSelectAll(!_allSelected),
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: _allSelected ? const Color(0xFF1B4D3E) : Colors.white,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: _allSelected
                      ? const Color(0xFF1B4D3E)
                      : const Color(0xFF1B4D3E).withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: _allSelected
                  ? const Icon(Icons.check, color: Colors.white, size: 16)
                  : _noneSelected
                  ? null
                  : Container(
                      margin: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1B4D3E),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 12),
          // Selection text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _allSelected
                      ? _localizations.allSelected
                      : _localizations.selectAll,
                  style: const TextStyle(
                    fontFamily: 'Literata',
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: Color(0xFF1B4D3E),
                  ),
                ),
                Text(
                  _localizations.tapItemsToIncludeExclude,
                  style: TextStyle(
                    fontFamily: 'Literata',
                    fontSize: 11,
                    color: const Color(0xFF1B4D3E).withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
          // Count badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF1B4D3E),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$_selectedCount / ${_editableItems.length}',
              style: const TextStyle(
                fontFamily: 'Literata',
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Empty State
  // ---------------------------------------------------------------------------

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF1B4D3E).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.inventory_2_outlined,
              size: 48,
              color: const Color(0xFF1B4D3E).withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _localizations.noItemsToDisplay,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              fontFamily: 'Literata',
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _localizations.addProductsToGenerateReport,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[400],
              fontFamily: 'Literata',
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Product List
  // ---------------------------------------------------------------------------

  Widget _buildProductList() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      itemCount: _editableItems.length,
      itemBuilder: (context, index) {
        return SlideTransition(
          position: Tween<Offset>(begin: const Offset(0.3, 0), end: Offset.zero)
              .animate(
                CurvedAnimation(
                  parent: _animationController,
                  curve: Interval(
                    (index / _editableItems.length) * 0.5,
                    0.5 + (index / _editableItems.length) * 0.5,
                    curve: Curves.easeOutCubic,
                  ),
                ),
              ),
          child: FadeTransition(
            opacity: CurvedAnimation(
              parent: _animationController,
              curve: Interval(
                (index / _editableItems.length) * 0.5,
                0.5 + (index / _editableItems.length) * 0.5,
                curve: Curves.easeOut,
              ),
            ),
            child: _buildProductCard(index),
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Product Card
  // ---------------------------------------------------------------------------

  Widget _buildProductCard(int index) {
    final item = _editableItems[index];
    final product = item.product;
    final key = product.id;
    final controller = _controllers[key]!;
    final focusNode = _focusNodes[key]!;
    final isSelected = item.isSelected;
    final numberFormat = NumberFormat('#,##0.00');

    return GestureDetector(
      onTap: () => _toggleItem(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF1B4D3E).withOpacity(0.4)
                : Colors.grey.withOpacity(0.15),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? const Color(0xFF1B4D3E).withOpacity(0.08)
                  : Colors.black.withOpacity(0.03),
              blurRadius: isSelected ? 12 : 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: isSelected ? 1.0 : 0.6,
          child: Column(
            children: [
              // Card Header
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF1B4D3E).withOpacity(0.04)
                      : Colors.grey.withOpacity(0.02),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(15),
                  ),
                ),
                child: Row(
                  children: [
                    // Selection indicator
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF1B4D3E)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFF1B4D3E)
                              : Colors.grey.withOpacity(0.3),
                          width: 2,
                        ),
                      ),
                      child: isSelected
                          ? const Icon(
                              Icons.check_rounded,
                              color: Colors.white,
                              size: 18,
                            )
                          : null,
                    ),
                    const SizedBox(width: 12),
                    // Serial number
                    if (_visibleColumnIds.contains('sr_no'))
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1B4D3E).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '#${index + 1}',
                          style: const TextStyle(
                            fontFamily: 'Literata',
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                            color: Color(0xFF1B4D3E),
                          ),
                        ),
                      ),
                    if (_visibleColumnIds.contains('sr_no'))
                      const SizedBox(width: 10),
                    // Product name
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_visibleColumnIds.contains('product_name'))
                            Text(
                              product.name.isEmpty ? '-' : product.name,
                              style: const TextStyle(
                                fontFamily: 'Literata',
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                                color: Color(0xFF1B4D3E),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          if (_visibleColumnIds.contains('company') &&
                              product.companyName.isNotEmpty)
                            Text(
                              product.companyName,
                              style: TextStyle(
                                fontFamily: 'Literata',
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                    // Stock badge
                    if (_visibleColumnIds.contains('stock'))
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: _getStockColor(
                            item.availableQuantity,
                          ).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: _getStockColor(
                              item.availableQuantity,
                            ).withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.inventory_2_rounded,
                              size: 14,
                              color: _getStockColor(item.availableQuantity),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${item.availableQuantity}',
                              style: TextStyle(
                                fontFamily: 'Literata',
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                                color: _getStockColor(item.availableQuantity),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),

              // Card Body - Dynamic Fields
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 8, 14, 14),
                child: Column(
                  children: [
                    // Row 1: Category, HSN, Status
                    _buildInfoRow([
                      if (_visibleColumnIds.contains('category'))
                        _buildInfoChip(
                          Icons.category_rounded,
                          _localizations.category,
                          product.category.isEmpty ? '-' : product.category,
                        ),
                      if (_visibleColumnIds.contains('hsn_code'))
                        _buildInfoChip(
                          Icons.tag_rounded,
                          _localizations.hsn,
                          product.hsnCode?.isNotEmpty == true
                              ? product.hsnCode!
                              : '-',
                        ),
                      if (_visibleColumnIds.contains('status'))
                        _buildStatusChip(item.availableQuantity),
                    ]),

                    // Row 2: Prices
                    if (_visibleColumnIds.contains('purchase_price') ||
                        _visibleColumnIds.contains('selling_price') ||
                        _visibleColumnIds.contains('stock_value'))
                      Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: _buildInfoRow([
                          if (_visibleColumnIds.contains('purchase_price'))
                            _buildPriceChip(
                              'Purchase',
                              '₹${numberFormat.format(product.purchasePrice)}',
                              Colors.orange,
                            ),
                          if (_visibleColumnIds.contains('selling_price'))
                            _buildPriceChip(
                              'Selling',
                              '₹${numberFormat.format(product.salesPrice)}',
                              Colors.blue,
                            ),
                          if (_visibleColumnIds.contains('stock_value'))
                            _buildPriceChip(
                              'Value',
                              '₹${numberFormat.format(product.getStockValue())}',
                              const Color(0xFF1B4D3E),
                            ),
                        ]),
                      ),

                    // Row 3: Tax & Supplier
                    if (_visibleColumnIds.contains('cgst') ||
                        _visibleColumnIds.contains('sgst') ||
                        _visibleColumnIds.contains('supplier'))
                      Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: _buildInfoRow([
                          if (_visibleColumnIds.contains('cgst'))
                            _buildInfoChip(
                              Icons.percent_rounded,
                              'CGST',
                              '${product.cgstPercent}%',
                            ),
                          if (_visibleColumnIds.contains('sgst'))
                            _buildInfoChip(
                              Icons.percent_rounded,
                              'SGST',
                              '${product.sgstPercent}%',
                            ),
                          if (_visibleColumnIds.contains('supplier'))
                            _buildInfoChip(
                              Icons.local_shipping_rounded,
                              _localizations.supplier,
                              product.defaultSupplierName?.isNotEmpty == true
                                  ? product.defaultSupplierName!
                                  : '-',
                            ),
                        ]),
                      ),

                    // Order Quantity Input
                    if (_visibleColumnIds.contains('order_qty'))
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: _buildOrderQuantityInput(
                          controller,
                          focusNode,
                          isSelected,
                          index,
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

  Widget _buildInfoRow(List<Widget> children) {
    final validChildren = children
        .where((w) => w is! SizedBox || (w).width != 0)
        .toList();
    if (validChildren.isEmpty) return const SizedBox.shrink();

    return Wrap(spacing: 8, runSpacing: 8, children: validChildren);
  }

  Widget _buildInfoChip(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.grey[600]),
          const SizedBox(width: 6),
          Text(
            '$label: ',
            style: TextStyle(
              fontFamily: 'Literata',
              fontSize: 11,
              color: Colors.grey[500],
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'Literata',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF333333),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(int stock) {
    final status = _getStockStatus(stock);
    final color = _getStockColor(stock);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            status,
            style: TextStyle(
              fontFamily: 'Literata',
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              fontFamily: 'Literata',
              fontSize: 11,
              color: color.withOpacity(0.7),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Literata',
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderQuantityInput(
    TextEditingController controller,
    FocusNode focusNode,
    bool isSelected,
    int index,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1B4D3E).withOpacity(0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF1B4D3E).withOpacity(0.15)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF1B4D3E).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.shopping_cart_rounded,
              size: 18,
              color: Color(0xFF1B4D3E),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _localizations.orderQuantity,
                  style: const TextStyle(
                    fontFamily: 'Literata',
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF1B4D3E),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _localizations.enterQuantityToOrder,
                  style: TextStyle(
                    fontFamily: 'Literata',
                    fontSize: 10,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 100,
            height: 44,
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              enabled: isSelected,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontFamily: 'Literata',
                fontWeight: FontWeight.w700,
                color: Color(0xFF1B4D3E),
              ),
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFF1B4D3E)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                    color: const Color(0xFF1B4D3E).withOpacity(0.3),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(
                    color: Color(0xFF1B4D3E),
                    width: 2,
                  ),
                ),
                disabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                hintText: '-',
                hintStyle: TextStyle(
                  color: Colors.grey[400],
                  fontFamily: 'Literata',
                  fontWeight: FontWeight.w400,
                ),
              ),
              onChanged: (value) => _updateOrderQuantity(index, value),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Bottom action bar
  // ---------------------------------------------------------------------------

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Cancel button
            Expanded(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _isGenerating
                      ? null
                      : () => Navigator.of(context).pop(),
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: const Color(0xFF1B4D3E).withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.close_rounded,
                          color: Color(0xFF1B4D3E),
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _localizations.cancel,
                          style: const TextStyle(
                            fontFamily: 'Literata',
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                            color: Color(0xFF1B4D3E),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Generate button
            Expanded(
              flex: 2,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _isGenerating || _noneSelected
                      ? null
                      : _generateReport,
                  borderRadius: BorderRadius.circular(14),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      gradient: _isGenerating || _noneSelected
                          ? LinearGradient(
                              colors: [Colors.grey[400]!, Colors.grey[500]!],
                            )
                          : const LinearGradient(
                              colors: [Color(0xFF2E7D4A), Color(0xFF1B4D3E)],
                            ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: _isGenerating || _noneSelected
                          ? null
                          : [
                              BoxShadow(
                                color: const Color(0xFF1B4D3E).withOpacity(0.4),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (_isGenerating)
                          const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        else
                          Icon(
                            widget.selectedFormat == ReportFormat.pdf
                                ? Icons.picture_as_pdf_rounded
                                : Icons.table_chart_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        const SizedBox(width: 10),
                        Text(
                          _isGenerating
                              ? _localizations.generating
                              : '${_localizations.generate} ($_selectedCount)',
                          style: const TextStyle(
                            fontFamily: 'Literata',
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  String _getStockStatus(int stock) {
    if (stock == 0) return _localizations.outOfStock;
    if (stock <= 10) return _localizations.lowStock;
    return _localizations.inStock;
  }

  Color _getStockColor(int stock) {
    if (stock == 0) return const Color(0xFFE53935);
    if (stock <= 10) return const Color(0xFFFB8C00);
    return const Color(0xFF43A047);
  }
}

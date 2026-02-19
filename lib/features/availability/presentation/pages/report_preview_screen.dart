import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:c_billing/features/inventory_management/domain/entities/report_item.dart';
import 'package:c_billing/core/services/inventory_report_service.dart';
import 'package:c_billing/core/services/stock_report_settings_service.dart';
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

class _ReportPreviewScreenState extends State<ReportPreviewScreen> {
  late List<ReportItem> _editableItems;
  bool _isGenerating = false;
  final _reportService = InventoryReportService();

  // Controllers for order quantity text fields
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, FocusNode> _focusNodes = {};

  @override
  void initState() {
    super.initState();
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
  }

  @override
  void dispose() {
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

  void _toggleSelectAll(bool? value) {
    setState(() {
      final select = value ?? false;
      for (final item in _editableItems) {
        item.isSelected = select;
      }
    });
  }

  void _toggleItem(int index, bool? value) {
    setState(() {
      _editableItems[index].isSelected = value ?? false;
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
        const SnackBar(
          content: Text('Please select at least one item'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isGenerating = true);

    try {
      final products = selected.map((e) => e.product).toList();
      final orderQuantities = selected.map((e) => e.orderQuantity).toList();

      late final file;
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

      await _reportService.shareReport(file);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Report generated with ${selected.length} products'),
            backgroundColor: const Color(0xFF1B4D3E),
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating report: $e'),
            backgroundColor: Colors.red,
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
      backgroundColor: const Color(0xFFE6EDE7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 2,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1B4D3E)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Report Preview',
              style: TextStyle(
                color: Color(0xFF1B4D3E),
                fontSize: 18,
                fontWeight: FontWeight.w700,
                fontFamily: 'Literata',
              ),
            ),
            Text(
              widget.reportTitle,
              style: const TextStyle(
                color: Color(0xFF1B4D3E),
                fontSize: 12,
                fontWeight: FontWeight.w400,
                fontFamily: 'Literata',
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Center(
              child: Text(
                '$_selectedCount / ${_editableItems.length} selected',
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF1B4D3E),
                  fontFamily: 'Literata',
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Info banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1B4D3E).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF1B4D3E).withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.info_outline,
                  color: Color(0xFF1B4D3E),
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Uncheck items to exclude them from the report. '
                    'Tap order quantity to edit.',
                    style: TextStyle(
                      fontSize: 13,
                      color: const Color(0xFF1B4D3E).withOpacity(0.9),
                      fontFamily: 'Literata',
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Data table
          Expanded(
            child: _editableItems.isEmpty
                ? Center(
                    child: Text(
                      'No items to display',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                        fontFamily: 'Literata',
                      ),
                    ),
                  )
                : SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: _buildDataTable(),
                      ),
                    ),
                  ),
          ),

          // Bottom action bar
          _buildBottomBar(),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Data Table
  // ---------------------------------------------------------------------------

  Widget _buildDataTable() {
    const headerStyle = TextStyle(
      fontWeight: FontWeight.w700,
      fontSize: 13,
      color: Color(0xFF1B4D3E),
      fontFamily: 'Literata',
    );

    final settings = StockReportSettingsService.instance;
    
    // Build dynamic columns based on settings
    final columns = <DataColumn>[
      // Always show checkbox first
      DataColumn(
        label: Checkbox(
          value: _allSelected
              ? true
              : _noneSelected
              ? false
              : null,
          tristate: true,
          onChanged: _toggleSelectAll,
          activeColor: const Color(0xFF1B4D3E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
    ];
    
    // Track which columns to show (in order)
    final visibleColumnIds = <String>[];
    
    // Column config mapping
    final columnHeaders = {
      'sr_no': const DataColumn(label: Text('#', style: headerStyle)),
      'product_name': const DataColumn(label: Text('Product Name', style: headerStyle)),
      'category': const DataColumn(label: Text('Category', style: headerStyle)),
      'company': const DataColumn(label: Text('Company', style: headerStyle)),
      'hsn_code': const DataColumn(label: Text('HSN Code', style: headerStyle)),
      'purchase_price': const DataColumn(label: Text('Pur. Price', style: headerStyle), numeric: true),
      'selling_price': const DataColumn(label: Text('Sell Price', style: headerStyle), numeric: true),
      'stock': const DataColumn(label: Text('Stock', style: headerStyle), numeric: true),
      'stock_value': const DataColumn(label: Text('Stock Value', style: headerStyle), numeric: true),
      'status': const DataColumn(label: Text('Status', style: headerStyle)),
      'order_qty': const DataColumn(label: Text('Order Qty', style: headerStyle), numeric: true),
      'supplier': const DataColumn(label: Text('Supplier', style: headerStyle)),
      'cgst': const DataColumn(label: Text('CGST %', style: headerStyle), numeric: true),
      'sgst': const DataColumn(label: Text('SGST %', style: headerStyle), numeric: true),
    };
    
    // Add columns based on settings (order matters)
    final columnOrder = ['sr_no', 'product_name', 'category', 'company', 'hsn_code', 
                         'purchase_price', 'selling_price', 'stock', 'stock_value', 
                         'status', 'order_qty', 'supplier', 'cgst', 'sgst'];
    
    for (final colId in columnOrder) {
      if (settings.isColumnVisible(colId)) {
        columns.add(columnHeaders[colId]!);
        visibleColumnIds.add(colId);
      }
    }
    
    // Fallback: if no columns visible, show at least product name, stock, and order qty
    if (visibleColumnIds.isEmpty) {
      columns.addAll([
        columnHeaders['product_name']!,
        columnHeaders['stock']!,
        columnHeaders['order_qty']!,
      ]);
      visibleColumnIds.addAll(['product_name', 'stock', 'order_qty']);
    }

    return DataTable(
      headingRowColor: WidgetStateProperty.all(
        const Color(0xFF1B4D3E).withOpacity(0.1),
      ),
      headingRowHeight: 56,
      dataRowMinHeight: 56,
      dataRowMaxHeight: 80,
      columnSpacing: 16,
      horizontalMargin: 12,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      columns: columns,
      rows: List<DataRow>.generate(_editableItems.length, (index) {
        final item = _editableItems[index];
        final product = item.product;
        final key = product.id;
        final controller = _controllers[key]!;
        final focusNode = _focusNodes[key]!;
        final isSelected = item.isSelected;

        // Build cells based on visible columns
        final cells = <DataCell>[
          // Always show checkbox first
          DataCell(
            Checkbox(
              value: isSelected,
              onChanged: (val) => _toggleItem(index, val),
              activeColor: const Color(0xFF1B4D3E),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ];
        
        for (final colId in visibleColumnIds) {
          cells.add(_buildDataCell(colId, index, item, product, controller, focusNode, isSelected));
        }

        return DataRow(
          color: WidgetStateProperty.resolveWith<Color?>((states) {
            if (!isSelected) {
              return Colors.grey[50];
            }
            return null;
          }),
          cells: cells,
        );
      }),
    );
  }
  
  /// Build a data cell based on column ID
  DataCell _buildDataCell(String colId, int index, ReportItem item, dynamic product, 
                          TextEditingController controller, FocusNode focusNode, bool isSelected) {
    final numberFormat = NumberFormat('#,##0.00');
    
    switch (colId) {
      case 'sr_no':
        return DataCell(
          Opacity(
            opacity: isSelected ? 1.0 : 0.5,
            child: Text(
              '${index + 1}',
              style: const TextStyle(
                fontSize: 13,
                fontFamily: 'Literata',
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        );
        
      case 'product_name':
        return DataCell(
          Opacity(
            opacity: isSelected ? 1.0 : 0.5,
            child: SizedBox(
              width: 180,
              child: Text(
                product.name.isEmpty ? '-' : product.name,
                style: const TextStyle(
                  fontSize: 13,
                  fontFamily: 'Literata',
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        );
        
      case 'category':
        return DataCell(
          Opacity(
            opacity: isSelected ? 1.0 : 0.5,
            child: Text(
              product.category.isEmpty ? '-' : product.category,
              style: const TextStyle(
                fontSize: 13,
                fontFamily: 'Literata',
              ),
            ),
          ),
        );
        
      case 'company':
        return DataCell(
          Opacity(
            opacity: isSelected ? 1.0 : 0.5,
            child: Text(
              product.companyName.isEmpty ? '-' : product.companyName,
              style: TextStyle(
                fontSize: 13,
                fontFamily: 'Literata',
                color: Colors.grey[700],
              ),
            ),
          ),
        );
        
      case 'hsn_code':
        return DataCell(
          Opacity(
            opacity: isSelected ? 1.0 : 0.5,
            child: Text(
              product.hsnCode?.isNotEmpty == true ? product.hsnCode! : '-',
              style: const TextStyle(
                fontSize: 13,
                fontFamily: 'Literata',
              ),
            ),
          ),
        );
        
      case 'purchase_price':
        return DataCell(
          Opacity(
            opacity: isSelected ? 1.0 : 0.5,
            child: Text(
              '₹${numberFormat.format(product.purchasePrice)}',
              style: const TextStyle(
                fontSize: 13,
                fontFamily: 'Literata',
              ),
            ),
          ),
        );
        
      case 'selling_price':
        return DataCell(
          Opacity(
            opacity: isSelected ? 1.0 : 0.5,
            child: Text(
              '₹${numberFormat.format(product.salesPrice)}',
              style: const TextStyle(
                fontSize: 13,
                fontFamily: 'Literata',
              ),
            ),
          ),
        );
        
      case 'stock':
        return DataCell(
          Opacity(
            opacity: isSelected ? 1.0 : 0.5,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: _getStockColor(item.availableQuantity).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _getStockColor(item.availableQuantity).withOpacity(0.3),
                ),
              ),
              child: Text(
                '${item.availableQuantity}',
                style: TextStyle(
                  fontSize: 13,
                  fontFamily: 'Literata',
                  fontWeight: FontWeight.w600,
                  color: _getStockColor(item.availableQuantity),
                ),
              ),
            ),
          ),
        );
        
      case 'stock_value':
        return DataCell(
          Opacity(
            opacity: isSelected ? 1.0 : 0.5,
            child: Text(
              '₹${numberFormat.format(product.getStockValue())}',
              style: const TextStyle(
                fontSize: 13,
                fontFamily: 'Literata',
              ),
            ),
          ),
        );
        
      case 'status':
        return DataCell(
          Opacity(
            opacity: isSelected ? 1.0 : 0.5,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getStockColor(item.availableQuantity).withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                _getStockStatus(item.availableQuantity),
                style: TextStyle(
                  fontSize: 11,
                  fontFamily: 'Literata',
                  fontWeight: FontWeight.w600,
                  color: _getStockColor(item.availableQuantity),
                ),
              ),
            ),
          ),
        );
        
      case 'order_qty':
        return DataCell(
          Opacity(
            opacity: isSelected ? 1.0 : 0.5,
            child: SizedBox(
              width: 100,
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                enabled: isSelected,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  fontFamily: 'Literata',
                  fontWeight: FontWeight.w600,
                ),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: const Color(0xFF1B4D3E).withOpacity(0.05),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFF1B4D3E)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: const Color(0xFF1B4D3E).withOpacity(0.3),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(
                      color: Color(0xFF1B4D3E),
                      width: 2,
                    ),
                  ),
                  disabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  hintText: '-',
                  hintStyle: TextStyle(
                    color: Colors.grey[400],
                    fontFamily: 'Literata',
                  ),
                ),
                onChanged: (value) => _updateOrderQuantity(index, value),
              ),
            ),
          ),
        );
        
      case 'supplier':
        return DataCell(
          Opacity(
            opacity: isSelected ? 1.0 : 0.5,
            child: Text(
              product.defaultSupplierName?.isNotEmpty == true ? product.defaultSupplierName! : '-',
              style: const TextStyle(
                fontSize: 13,
                fontFamily: 'Literata',
              ),
            ),
          ),
        );
        
      case 'cgst':
        return DataCell(
          Opacity(
            opacity: isSelected ? 1.0 : 0.5,
            child: Text(
              '${product.cgstPercent}%',
              style: const TextStyle(
                fontSize: 13,
                fontFamily: 'Literata',
              ),
            ),
          ),
        );
        
      case 'sgst':
        return DataCell(
          Opacity(
            opacity: isSelected ? 1.0 : 0.5,
            child: Text(
              '${product.sgstPercent}%',
              style: const TextStyle(
                fontSize: 13,
                fontFamily: 'Literata',
              ),
            ),
          ),
        );
        
      default:
        return DataCell(
          Opacity(
            opacity: isSelected ? 1.0 : 0.5,
            child: const Text('-'),
          ),
        );
    }
  }
  
  String _getStockStatus(int stock) {
    if (stock == 0) return 'Out of Stock';
    if (stock <= 10) return 'Low Stock';
    return 'In Stock';
  }

  // ---------------------------------------------------------------------------
  // Bottom action bar
  // ---------------------------------------------------------------------------

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _isGenerating
                    ? null
                    : () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close),
                label: const Text('Cancel'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF1B4D3E),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: const BorderSide(color: Color(0xFF1B4D3E)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton.icon(
                onPressed: _isGenerating || _noneSelected
                    ? null
                    : _generateReport,
                icon: _isGenerating
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Icon(
                        widget.selectedFormat == ReportFormat.pdf
                            ? Icons.picture_as_pdf
                            : Icons.table_chart,
                      ),
                label: Text(
                  _isGenerating
                      ? 'Generating...'
                      : 'Generate ${widget.selectedFormat == ReportFormat.pdf ? 'PDF' : 'Excel'}'
                            ' ($_selectedCount)',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1B4D3E),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey[300],
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
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
  // Colour helper
  // ---------------------------------------------------------------------------

  Color _getStockColor(int stock) {
    if (stock == 0) return Colors.red;
    if (stock <= 10) return Colors.orange;
    return Colors.green;
  }
}

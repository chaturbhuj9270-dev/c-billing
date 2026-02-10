import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:c_billing/features/inventory_management/domain/entities/report_item.dart';
import 'package:c_billing/core/services/inventory_report_service.dart';

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
      columns: [
        // 1. Checkbox (Select All)
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
        // 2. Product Name
        const DataColumn(label: Text('Product Name', style: headerStyle)),
        // 3. Available Quantity
        const DataColumn(
          label: Text('Available Qty', style: headerStyle),
          numeric: true,
        ),
        // 4. Order Quantity (editable)
        const DataColumn(
          label: Text('Order Qty', style: headerStyle),
          numeric: true,
        ),
        // 5. Expiry Date
        const DataColumn(label: Text('Expiry Date', style: headerStyle)),
      ],
      rows: List<DataRow>.generate(_editableItems.length, (index) {
        final item = _editableItems[index];
        final product = item.product;
        final key = product.id;
        final controller = _controllers[key]!;
        final focusNode = _focusNodes[key]!;
        final isSelected = item.isSelected;

        return DataRow(
          color: WidgetStateProperty.resolveWith<Color?>((states) {
            if (!isSelected) {
              return Colors.grey[50];
            }
            return null;
          }),
          cells: [
            // 1. Checkbox
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
            // 2. Product Name + company subtitle
            DataCell(
              Opacity(
                opacity: isSelected ? 1.0 : 0.5,
                child: SizedBox(
                  width: 200,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        product.name,
                        style: const TextStyle(
                          fontSize: 13,
                          fontFamily: 'Literata',
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        product.companyName,
                        style: TextStyle(
                          fontSize: 11,
                          fontFamily: 'Literata',
                          color: Colors.grey[600],
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // 3. Available Quantity (read-only)
            DataCell(
              Opacity(
                opacity: isSelected ? 1.0 : 0.5,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _getStockColor(
                      item.availableQuantity,
                    ).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _getStockColor(
                        item.availableQuantity,
                      ).withOpacity(0.3),
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
            ),
            // 4. Order Quantity (editable, "-" when null/empty)
            DataCell(
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
            ),
            // 5. Expiry Date
            DataCell(
              Opacity(
                opacity: isSelected ? 1.0 : 0.5,
                child: Text(
                  item.expiryDateDisplay,
                  style: TextStyle(
                    fontSize: 13,
                    fontFamily: 'Literata',
                    fontWeight: FontWeight.w500,
                    color: item.expiryDate != null
                        ? Colors.black87
                        : Colors.grey[400],
                  ),
                ),
              ),
            ),
          ],
        );
      }),
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

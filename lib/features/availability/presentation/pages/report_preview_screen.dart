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
  
  // Controllers for text fields
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, FocusNode> _focusNodes = {};

  @override
  void initState() {
    super.initState();
    _editableItems = widget.reportItems
        .map((item) => ReportItem.fromProduct(
              item.product,
              initialOrderQty: item.getSuggestedReorderQuantity(),
            ))
        .toList();
    
    // Initialize controllers for each item
    for (var i = 0; i < _editableItems.length; i++) {
      final key = _editableItems[i].product.id;
      _controllers[key] = TextEditingController(
        text: _editableItems[i].orderQuantity.toString(),
      );
      _focusNodes[key] = FocusNode();
    }
  }

  @override
  void dispose() {
    // Dispose all controllers and focus nodes
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    for (var focusNode in _focusNodes.values) {
      focusNode.dispose();
    }
    super.dispose();
  }

  void _updateOrderQuantity(int index, String value) {
    final quantity = int.tryParse(value) ?? 0;
    setState(() {
      _editableItems[index].updateOrderQuantity(quantity);
    });
  }

  Future<void> _generateReport() async {
    setState(() => _isGenerating = true);

    try {
      final products = _editableItems.map((item) => item.product).toList();
      final orderQuantities = _editableItems.map((item) => item.orderQuantity).toList();

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
            content: Text('Report generated with ${_editableItems.length} products'),
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
                '${_editableItems.length} items',
                style: const TextStyle(
                  fontSize: 14,
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
                    'Review and edit order quantities before generating the report',
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
          
          // Action buttons
          Container(
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
                      onPressed: _isGenerating ? null : _generateReport,
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
                            : 'Generate ${widget.selectedFormat == ReportFormat.pdf ? 'PDF' : 'Excel'}',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1B4D3E),
                        foregroundColor: Colors.white,
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
          ),
        ],
      ),
    );
  }

  Widget _buildDataTable() {
    return DataTable(
      headingRowColor: WidgetStateProperty.all(
        const Color(0xFF1B4D3E).withOpacity(0.1),
      ),
      headingRowHeight: 56,
      dataRowMinHeight: 56,
      dataRowMaxHeight: 80,
      columnSpacing: 16,
      horizontalMargin: 16,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      columns: const [
        DataColumn(
          label: Text(
            '#',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 13,
              color: Color(0xFF1B4D3E),
              fontFamily: 'Literata',
            ),
          ),
        ),
        DataColumn(
          label: Text(
            'Product Name',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 13,
              color: Color(0xFF1B4D3E),
              fontFamily: 'Literata',
            ),
          ),
        ),
        DataColumn(
          label: Text(
            'Category',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 13,
              color: Color(0xFF1B4D3E),
              fontFamily: 'Literata',
            ),
          ),
        ),
        DataColumn(
          label: Text(
            'Available Qty',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 13,
              color: Color(0xFF1B4D3E),
              fontFamily: 'Literata',
            ),
          ),
          numeric: true,
        ),
        DataColumn(
          label: Text(
            'Order Qty',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 13,
              color: Color(0xFF1B4D3E),
              fontFamily: 'Literata',
            ),
          ),
          numeric: true,
        ),
      ],
      rows: _editableItems.asMap().entries.map((entry) {
        final index = entry.key;
        final item = entry.value;
        final product = item.product;
        final controller = _controllers[product.id]!;
        final focusNode = _focusNodes[product.id]!;

        return DataRow(
          cells: [
            DataCell(
              Text(
                '${index + 1}',
                style: const TextStyle(
                  fontSize: 13,
                  fontFamily: 'Literata',
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            DataCell(
              SizedBox(
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
            DataCell(
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF1B4D3E).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  product.category,
                  style: const TextStyle(
                    fontSize: 12,
                    fontFamily: 'Literata',
                    color: Color(0xFF1B4D3E),
                  ),
                ),
              ),
            ),
            DataCell(
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
            DataCell(
              SizedBox(
                width: 100,
                child: TextField(
                  controller: controller,
                  focusNode: focusNode,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
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
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    hintText: '0',
                    hintStyle: TextStyle(
                      color: Colors.grey[400],
                      fontFamily: 'Literata',
                    ),
                  ),
                  onChanged: (value) => _updateOrderQuantity(index, value),
                ),
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  Color _getStockColor(int stock) {
    if (stock == 0) {
      return Colors.red;
    } else if (stock <= 10) {
      return Colors.orange;
    }
    return Colors.green;
  }
}

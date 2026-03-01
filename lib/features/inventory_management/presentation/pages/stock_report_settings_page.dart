import 'package:flutter/material.dart';
import 'package:c_billing/core/services/stock_report_settings_service.dart';

/// Page for managing which columns appear in stock reports
class StockReportSettingsPage extends StatefulWidget {
  const StockReportSettingsPage({super.key});

  @override
  State<StockReportSettingsPage> createState() =>
      _StockReportSettingsPageState();
}

class _StockReportSettingsPageState extends State<StockReportSettingsPage> {
  late List<StockReportColumn> _columns;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadColumns();
  }

  Future<void> _loadColumns() async {
    await StockReportSettingsService.instance.init();
    await StockReportSettingsService.instance.refreshCustomColumns();
    setState(() {
      _columns = List.from(StockReportSettingsService.instance.columns);
      _isLoading = false;
    });
  }

  Future<void> _toggleColumn(String columnId, bool isVisible) async {
    await StockReportSettingsService.instance.setColumnVisibility(
      columnId,
      isVisible,
    );
    setState(() {
      final index = _columns.indexWhere((c) => c.id == columnId);
      if (index != -1) {
        _columns[index] = _columns[index].copyWith(isVisible: isVisible);
      }
    });
  }

  Future<void> _resetToDefaults() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Reset to Defaults',
          style: TextStyle(
            fontFamily: 'Literata',
            fontWeight: FontWeight.w700,
            color: Color(0xFF1B4D3E),
          ),
        ),
        content: const Text(
          'This will reset all column visibility settings to their default values. Continue?',
          style: TextStyle(fontFamily: 'Literata'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Cancel',
              style: TextStyle(fontFamily: 'Literata', color: Colors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1B4D3E),
            ),
            child: const Text(
              'Reset',
              style: TextStyle(fontFamily: 'Literata', color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await StockReportSettingsService.instance.resetToDefaults();
      await _loadColumns();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Settings reset to defaults',
              style: TextStyle(fontFamily: 'Literata'),
            ),
            backgroundColor: Color(0xFF1B4D3E),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE6EDE7),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF1B4D3E),
                      ),
                    )
                  : _buildColumnsList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.8),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.arrow_back_ios_rounded,
                size: 20,
                color: Color(0xFF1B4D3E),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Stock Report Settings',
                  style: TextStyle(
                    fontFamily: 'Literata',
                    fontWeight: FontWeight.w800,
                    fontSize: 22,
                    color: Color(0xFF1B4D3E),
                  ),
                ),
                Text(
                  'Choose columns to show in stock report',
                  style: TextStyle(
                    fontFamily: 'Literata',
                    fontWeight: FontWeight.w400,
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          TextButton.icon(
            onPressed: _resetToDefaults,
            icon: const Icon(Icons.restart_alt_rounded, size: 18),
            label: const Text('Reset'),
            style: TextButton.styleFrom(foregroundColor: Colors.grey[700]),
          ),
        ],
      ),
    );
  }

  Widget _buildColumnsList() {
    // Separate default and custom columns
    final defaultColumns = _columns.where((c) => c.isDefault).toList();
    final customColumns = _columns.where((c) => !c.isDefault).toList();

    // Count visible columns
    final visibleCount = _columns.where((c) => c.isVisible).length;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1B4D3E).withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1B4D3E),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.view_column_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$visibleCount of ${_columns.length} columns visible',
                        style: const TextStyle(
                          fontFamily: 'Literata',
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: Color(0xFF1B4D3E),
                        ),
                      ),
                      Text(
                        'Toggle columns to show/hide in stock report',
                        style: TextStyle(
                          fontFamily: 'Literata',
                          fontWeight: FontWeight.w400,
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Default columns section
          _buildSectionTitle('Default Columns', Icons.table_chart_rounded),
          const SizedBox(height: 12),
          ...defaultColumns.map((column) => _buildColumnTile(column)),

          // Custom columns section
          if (customColumns.isNotEmpty) ...[
            const SizedBox(height: 24),
            _buildSectionTitle('Custom Columns', Icons.tune_rounded),
            const SizedBox(height: 12),
            ...customColumns.map((column) => _buildColumnTile(column)),
          ],

          // Empty state for custom columns
          if (customColumns.isEmpty) ...[
            const SizedBox(height: 24),
            _buildSectionTitle('Custom Columns', Icons.tune_rounded),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    color: Colors.grey[400],
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'No custom columns defined. Add custom columns from Product Settings to include them in reports.',
                      style: TextStyle(
                        fontFamily: 'Literata',
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF1B4D3E)),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontFamily: 'Literata',
            fontWeight: FontWeight.w700,
            fontSize: 16,
            color: Color(0xFF1B4D3E),
          ),
        ),
      ],
    );
  }

  Widget _buildColumnTile(StockReportColumn column) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: column.isVisible
              ? const Color(0xFF1B4D3E).withOpacity(0.3)
              : Colors.grey[200]!,
          width: column.isVisible ? 1.5 : 1,
        ),
        boxShadow: column.isVisible
            ? [
                BoxShadow(
                  color: const Color(0xFF1B4D3E).withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: column.isVisible
                ? const Color(0xFF1B4D3E).withOpacity(0.1)
                : Colors.grey[100],
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            _getColumnIcon(column.id),
            color: column.isVisible
                ? const Color(0xFF1B4D3E)
                : Colors.grey[400],
            size: 20,
          ),
        ),
        title: Text(
          column.name,
          style: TextStyle(
            fontFamily: 'Literata',
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: column.isVisible ? Colors.black87 : Colors.grey[600],
          ),
        ),
        subtitle: Text(
          column.isDefault ? 'Default column' : 'Custom column',
          style: TextStyle(
            fontFamily: 'Literata',
            fontSize: 11,
            color: Colors.grey[500],
          ),
        ),
        trailing: Switch(
          value: column.isVisible,
          onChanged: (value) => _toggleColumn(column.id, value),
          activeThumbColor: const Color(0xFF1B4D3E),
          activeTrackColor: const Color(0xFF1B4D3E).withOpacity(0.3),
        ),
      ),
    );
  }

  IconData _getColumnIcon(String columnId) {
    switch (columnId) {
      case 'sr_no':
        return Icons.format_list_numbered_rounded;
      case 'product_name':
        return Icons.inventory_2_rounded;
      case 'category':
        return Icons.category_rounded;
      case 'company':
        return Icons.business_rounded;
      case 'hsn_code':
        return Icons.tag_rounded;
      case 'purchase_price':
        return Icons.currency_rupee_rounded;
      case 'selling_price':
        return Icons.sell_rounded;
      case 'stock':
        return Icons.warehouse_rounded;
      case 'stock_value':
        return Icons.attach_money_rounded;
      case 'status':
        return Icons.check_circle_outline_rounded;
      case 'order_qty':
        return Icons.shopping_cart_rounded;
      case 'supplier':
        return Icons.local_shipping_rounded;
      case 'cgst':
        return Icons.percent_rounded;
      case 'sgst':
        return Icons.percent_rounded;
      default:
        // Custom columns
        return Icons.tune_rounded;
    }
  }
}

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../offline/controllers/stock_ledger_offline_controller.dart';
import '../../offline/entities/stock_ledger_entity.dart';

/// Page showing stock movement history (ledger) for a product or batch
class StockLedgerPage extends StatefulWidget {
  final String? filterProductId;
  final String? filterProductName;
  final String? filterBatchId;
  final String? filterBatchNumber;

  const StockLedgerPage({
    super.key,
    this.filterProductId,
    this.filterProductName,
    this.filterBatchId,
    this.filterBatchNumber,
  });

  @override
  State<StockLedgerPage> createState() => _StockLedgerPageState();
}

class _StockLedgerPageState extends State<StockLedgerPage> {
  static const _primaryColor = Color(0xFF1B4D3E);
  final _dateFormat = DateFormat('dd MMM yyyy, hh:mm a');
  final _shortDateFormat = DateFormat('dd MMM');

  List<StockLedgerEntity> _transactions = [];
  bool _isLoading = true;
  String _selectedFilter = 'all'; // all, in, out
  DateTimeRange? _dateRange;

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    setState(() => _isLoading = true);
    try {
      final controller = StockLedgerOfflineController.instance;
      if (widget.filterBatchId != null) {
        _transactions = await controller.getTransactionsByBatch(widget.filterBatchId!);
      } else if (widget.filterProductId != null) {
        _transactions = await controller.getTransactionsByProduct(widget.filterProductId!);
      } else {
        _transactions = await controller.getAllTransactions();
      }
    } catch (e) {
      debugPrint('[StockLedgerPage] Error loading transactions: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<StockLedgerEntity> get _filteredTransactions {
    return _transactions.where((t) {
      // Type filter
      if (_selectedFilter == 'in' && !t.isInflow) return false;
      if (_selectedFilter == 'out' && !t.isOutflow) return false;

      // Date range filter
      if (_dateRange != null) {
        if (t.transactionDate.isBefore(_dateRange!.start) ||
            t.transactionDate.isAfter(_dateRange!.end.add(const Duration(days: 1)))) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _dateRange,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: _primaryColor),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _dateRange = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredTransactions;

    String title = 'Stock Ledger';
    if (widget.filterProductName != null) {
      title = 'Ledger: ${widget.filterProductName}';
    }
    if (widget.filterBatchNumber != null) {
      title = 'Ledger: ${widget.filterBatchNumber}';
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
        title: Text(
          title,
          style: const TextStyle(fontFamily: 'Literata', fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: _selectDateRange,
            tooltip: 'Filter by date',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadTransactions,
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter chips
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Row(
                  children: [
                    _buildFilterChip('All', 'all'),
                    const SizedBox(width: 8),
                    _buildFilterChip('Stock In', 'in'),
                    const SizedBox(width: 8),
                    _buildFilterChip('Stock Out', 'out'),
                    const Spacer(),
                    if (_dateRange != null)
                      GestureDetector(
                        onTap: () => setState(() => _dateRange = null),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.red[50],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${_shortDateFormat.format(_dateRange!.start)} - ${_shortDateFormat.format(_dateRange!.end)}',
                                style: TextStyle(fontFamily: 'Literata', fontSize: 10, color: Colors.red[700]),
                              ),
                              const SizedBox(width: 4),
                              Icon(Icons.close, size: 14, color: Colors.red[700]),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),

          // Summary bar
          Container(
            color: _primaryColor.withOpacity(0.05),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSummaryItem(
                  'Transactions',
                  '${filtered.length}',
                ),
                _buildSummaryItem(
                  'Total In',
                  '+${filtered.where((t) => t.isInflow).fold<double>(0, (sum, t) => sum + t.quantity.abs()).toStringAsFixed(0)}',
                ),
                _buildSummaryItem(
                  'Total Out',
                  '-${filtered.where((t) => t.isOutflow).fold<double>(0, (sum, t) => sum + t.quantity.abs()).toStringAsFixed(0)}',
                ),
              ],
            ),
          ),

          // Transactions list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: _primaryColor))
                : filtered.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey[300]),
                            const SizedBox(height: 16),
                            Text(
                              'No transactions found',
                              style: TextStyle(fontFamily: 'Literata', fontSize: 16, color: Colors.grey[500]),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadTransactions,
                        color: _primaryColor,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            return _buildTransactionCard(filtered[index]);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedFilter == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? _primaryColor : Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Literata',
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : Colors.grey[700],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontFamily: 'Literata',
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: _primaryColor,
          ),
        ),
        Text(
          label,
          style: TextStyle(fontFamily: 'Literata', fontSize: 11, color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildTransactionCard(StockLedgerEntity txn) {
    final isInflow = txn.isInflow;
    final color = isInflow ? Colors.green : Colors.red;
    final icon = isInflow ? Icons.arrow_downward : Icons.arrow_upward;
    final prefix = isInflow ? '+' : '';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          // Type icon
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 12),

          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  txn.transactionTypeLabel,
                  style: TextStyle(
                    fontFamily: 'Literata',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  txn.productName,
                  style: const TextStyle(
                    fontFamily: 'Literata',
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Batch: ${txn.batchNumber}',
                  style: TextStyle(fontFamily: 'Literata', fontSize: 11, color: Colors.grey[500]),
                ),
                if (txn.reference != null) ...[
                  Text(
                    'Ref: ${txn.reference}',
                    style: TextStyle(fontFamily: 'Literata', fontSize: 11, color: Colors.grey[500]),
                  ),
                ],
                Text(
                  _dateFormat.format(txn.transactionDate),
                  style: TextStyle(fontFamily: 'Literata', fontSize: 10, color: Colors.grey[400]),
                ),
              ],
            ),
          ),

          // Quantity and balance
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$prefix${txn.quantity.toStringAsFixed(0)}',
                style: TextStyle(
                  fontFamily: 'Literata',
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Balance: ${txn.balanceAfter.toStringAsFixed(0)}',
                style: TextStyle(fontFamily: 'Literata', fontSize: 11, color: Colors.grey[500]),
              ),
              Text(
                '₹${txn.pricePerUnit.toStringAsFixed(2)}',
                style: TextStyle(fontFamily: 'Literata', fontSize: 11, color: Colors.grey[400]),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

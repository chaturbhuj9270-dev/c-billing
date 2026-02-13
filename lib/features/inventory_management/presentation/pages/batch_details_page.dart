import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../offline/entities/product_batch_entity.dart';
import '../../offline/controllers/product_batch_offline_controller.dart';
import '../../offline/controllers/stock_ledger_offline_controller.dart';
import '../../offline/entities/stock_ledger_entity.dart';
import 'stock_ledger_page.dart';

/// Page showing detailed information about a single product batch
class BatchDetailsPage extends StatefulWidget {
  final ProductBatchEntity batch;

  const BatchDetailsPage({
    super.key,
    required this.batch,
  });

  @override
  State<BatchDetailsPage> createState() => _BatchDetailsPageState();
}

class _BatchDetailsPageState extends State<BatchDetailsPage> {
  static const _primaryColor = Color(0xFF1B4D3E);
  final _dateFormat = DateFormat('dd MMM yyyy');
  final _dateTimeFormat = DateFormat('dd MMM yyyy, hh:mm a');

  late ProductBatchEntity _batch;
  List<StockLedgerEntity> _ledgerEntries = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _batch = widget.batch;
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      // Refresh batch data
      final freshBatch = await ProductBatchOfflineController.instance.getBatchById(_batch.id);
      if (freshBatch != null) {
        _batch = freshBatch;
      }

      // Load recent ledger entries for this batch
      _ledgerEntries = await StockLedgerOfflineController.instance
          .getTransactionsByBatch(_batch.id.toString());
    } catch (e) {
      debugPrint('[BatchDetailsPage] Error loading data: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _batch.status == BatchStatus.active
        ? Colors.green
        : _batch.status == BatchStatus.expired
            ? Colors.red
            : Colors.grey;

    final stockPercent = _batch.initialQuantity > 0
        ? (_batch.currentQuantity / _batch.initialQuantity).clamp(0.0, 1.0)
        : 0.0;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
        title: const Text(
          'Batch Details',
          style: TextStyle(fontFamily: 'Literata', fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.receipt_long),
            tooltip: 'View Full Ledger',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => StockLedgerPage(
                    filterBatchId: _batch.id.toString(),
                    filterBatchNumber: _batch.batchNumber,
                  ),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _primaryColor))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Main info card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Product name and status
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                _batch.productName,
                                style: const TextStyle(
                                  fontFamily: 'Literata',
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: _primaryColor,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: statusColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                _batch.status.name.toUpperCase(),
                                style: TextStyle(
                                  fontFamily: 'Literata',
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: statusColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _batch.companyName,
                          style: TextStyle(fontFamily: 'Literata', fontSize: 14, color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 16),

                        // Batch number
                        _buildDetailRow('Batch #', _batch.batchNumber),
                        _buildDetailRow('Supplier', _batch.supplierName),
                        _buildDetailRow('Purchase Date', _dateFormat.format(_batch.purchaseDate)),
                        if (_batch.productionDate != null)
                          _buildDetailRow('Production Date', _dateFormat.format(_batch.productionDate!)),
                        if (_batch.expiryDate != null)
                          _buildDetailRow(
                            'Expiry Date',
                            _dateFormat.format(_batch.expiryDate!),
                            valueColor: _batch.isExpired ? Colors.red : null,
                          ),
                        if (_batch.warrantyMonths != null && _batch.warrantyMonths! > 0)
                          _buildDetailRow('Warranty', '${_batch.warrantyMonths} months'),
                        _buildDetailRow('Unit', _batch.unit),
                        if (_batch.notes != null && _batch.notes!.isNotEmpty)
                          _buildDetailRow('Notes', _batch.notes!),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Stock progress card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Stock Status',
                          style: TextStyle(
                            fontFamily: 'Literata',
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Progress bar
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: stockPercent,
                            backgroundColor: Colors.grey[200],
                            valueColor: AlwaysStoppedAnimation<Color>(
                              stockPercent > 0.3 ? Colors.green : Colors.orange,
                            ),
                            minHeight: 10,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${_batch.currentQuantity.toStringAsFixed(1)} remaining',
                              style: TextStyle(fontFamily: 'Literata', fontSize: 12, color: Colors.grey[600]),
                            ),
                            Text(
                              'of ${_batch.initialQuantity.toStringAsFixed(1)} ${_batch.unit}',
                              style: TextStyle(fontFamily: 'Literata', fontSize: 12, color: Colors.grey[600]),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${_batch.quantitySold.toStringAsFixed(1)} sold (${(stockPercent * 100).toStringAsFixed(0)}% remaining)',
                          style: TextStyle(fontFamily: 'Literata', fontSize: 11, color: Colors.grey[500]),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Price and value card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Pricing',
                          style: TextStyle(
                            fontFamily: 'Literata',
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            _buildPriceCard('Purchase', '₹${_batch.purchasePrice.toStringAsFixed(2)}', Colors.orange),
                            const SizedBox(width: 12),
                            _buildPriceCard('Sales', '₹${_batch.salesPrice.toStringAsFixed(2)}', Colors.green),
                            const SizedBox(width: 12),
                            _buildPriceCard('Margin', '${_batch.profitMargin.toStringAsFixed(1)}%', _primaryColor),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            _buildPriceCard('Stock Value', '₹${_batch.totalValue.toStringAsFixed(2)}', Colors.blue),
                            const SizedBox(width: 12),
                            _buildPriceCard('Sales Value', '₹${_batch.totalSalesValue.toStringAsFixed(2)}', Colors.green),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Recent ledger entries
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Recent Movements',
                              style: TextStyle(
                                fontFamily: 'Literata',
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (_ledgerEntries.isNotEmpty)
                              TextButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => StockLedgerPage(
                                        filterBatchId: _batch.id.toString(),
                                        filterBatchNumber: _batch.batchNumber,
                                      ),
                                    ),
                                  );
                                },
                                child: const Text(
                                  'View All',
                                  style: TextStyle(
                                    fontFamily: 'Literata',
                                    fontSize: 12,
                                    color: _primaryColor,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        if (_ledgerEntries.isEmpty)
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Text(
                                'No movements recorded yet',
                                style: TextStyle(
                                  fontFamily: 'Literata',
                                  fontSize: 13,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ),
                          )
                        else
                          ...(_ledgerEntries.take(5).map((txn) {
                            final isInflow = txn.isInflow;
                            final color = isInflow ? Colors.green : Colors.red;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                children: [
                                  Icon(
                                    isInflow ? Icons.arrow_downward : Icons.arrow_upward,
                                    size: 16,
                                    color: color,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          txn.transactionTypeLabel,
                                          style: TextStyle(
                                            fontFamily: 'Literata',
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                            color: color,
                                          ),
                                        ),
                                        Text(
                                          _dateTimeFormat.format(txn.transactionDate),
                                          style: TextStyle(
                                            fontFamily: 'Literata',
                                            fontSize: 10,
                                            color: Colors.grey[400],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    '${isInflow ? "+" : ""}${txn.quantity.toStringAsFixed(0)}',
                                    style: TextStyle(
                                      fontFamily: 'Literata',
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: color,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Bal: ${txn.balanceAfter.toStringAsFixed(0)}',
                                    style: TextStyle(
                                      fontFamily: 'Literata',
                                      fontSize: 11,
                                      color: Colors.grey[500],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          })),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Metadata
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Metadata',
                          style: TextStyle(
                            fontFamily: 'Literata',
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildMetaRow('Created', _dateTimeFormat.format(_batch.createdAt)),
                        _buildMetaRow('Updated', _dateTimeFormat.format(_batch.updatedAt)),
                        _buildMetaRow('Sync Status', _batch.syncStatus.name),
                        if (_batch.serverId != null)
                          _buildMetaRow('Server ID', _batch.serverId!),
                        if (_batch.purchaseId != null)
                          _buildMetaRow('Purchase Ref', _batch.purchaseId!),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(fontFamily: 'Literata', fontSize: 12, color: Colors.grey[500]),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontFamily: 'Literata',
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: valueColor ?? Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceCard(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(fontFamily: 'Literata', fontSize: 10, color: color.withOpacity(0.7)),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(fontFamily: 'Literata', fontSize: 14, fontWeight: FontWeight.w700, color: color),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetaRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: TextStyle(fontFamily: 'Literata', fontSize: 11, color: Colors.grey[500]),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontFamily: 'Literata', fontSize: 11, color: Colors.grey[600]),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

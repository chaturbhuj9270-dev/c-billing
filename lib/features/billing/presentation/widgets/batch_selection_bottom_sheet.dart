import 'package:flutter/material.dart';
import '../../../inventory_management/offline/entities/product_batch_entity.dart';
import 'package:intl/intl.dart';

/// Bottom sheet for selecting a specific product batch during billing
/// Shows all available batches with company, stock, price info
/// Highlights FIFO-recommended batch (oldest first)
class BatchSelectionBottomSheet extends StatefulWidget {
  final String productName;
  final List<ProductBatchEntity> availableBatches;

  const BatchSelectionBottomSheet({
    super.key,
    required this.productName,
    required this.availableBatches,
  });

  /// Show the bottom sheet and return the selected batch
  static Future<ProductBatchEntity?> show(
    BuildContext context, {
    required String productName,
    required List<ProductBatchEntity> availableBatches,
  }) {
    return showModalBottomSheet<ProductBatchEntity>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => BatchSelectionBottomSheet(
        productName: productName,
        availableBatches: availableBatches,
      ),
    );
  }

  @override
  State<BatchSelectionBottomSheet> createState() => _BatchSelectionBottomSheetState();
}

class _BatchSelectionBottomSheetState extends State<BatchSelectionBottomSheet> {
  static const _primaryColor = Color(0xFF1B4D3E);
  final _searchController = TextEditingController();
  List<ProductBatchEntity> _filteredBatches = [];
  ProductBatchEntity? _selectedBatch;

  @override
  void initState() {
    super.initState();
    _filteredBatches = List.from(widget.availableBatches);
    // Pre-select FIFO recommended batch (oldest first with stock)
    if (_filteredBatches.isNotEmpty) {
      _selectedBatch = _filteredBatches.first;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterBatches(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredBatches = List.from(widget.availableBatches);
      } else {
        _filteredBatches = widget.availableBatches
            .where((b) =>
                b.companyName.toLowerCase().contains(query.toLowerCase()) ||
                b.batchNumber.toLowerCase().contains(query.toLowerCase()) ||
                b.supplierName.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMM yyyy');
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      constraints: BoxConstraints(maxHeight: screenHeight * 0.75),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Text(
                  'Select Batch',
                  style: const TextStyle(
                    fontFamily: 'Literata',
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: _primaryColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.productName,
                  style: TextStyle(
                    fontFamily: 'Literata',
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${widget.availableBatches.length} batch${widget.availableBatches.length != 1 ? 'es' : ''} available',
                  style: TextStyle(
                    fontFamily: 'Literata',
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),

          // Search bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _searchController,
              onChanged: _filterBatches,
              decoration: InputDecoration(
                hintText: 'Search by company, batch number...',
                hintStyle: TextStyle(
                  fontFamily: 'Literata',
                  fontSize: 14,
                  color: Colors.grey[400],
                ),
                prefixIcon: const Icon(Icons.search, color: _primaryColor),
                filled: true,
                fillColor: Colors.grey[100],
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              style: const TextStyle(fontFamily: 'Literata', fontSize: 14),
            ),
          ),

          const SizedBox(height: 8),

          // FIFO info banner
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: _primaryColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _primaryColor.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, size: 16, color: _primaryColor.withOpacity(0.7)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'FIFO: Oldest batch is recommended (highlighted)',
                    style: TextStyle(
                      fontFamily: 'Literata',
                      fontSize: 11,
                      color: _primaryColor.withOpacity(0.8),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Batch list
          Expanded(
            child: _filteredBatches.isEmpty
                ? Center(
                    child: Text(
                      'No batches found',
                      style: TextStyle(
                        fontFamily: 'Literata',
                        fontSize: 14,
                        color: Colors.grey[500],
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _filteredBatches.length,
                    itemBuilder: (context, index) {
                      final batch = _filteredBatches[index];
                      final isSelected = _selectedBatch?.id == batch.id;
                      final isFifoRecommended = index == 0;

                      return GestureDetector(
                        onTap: () {
                          setState(() => _selectedBatch = batch);
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? _primaryColor.withOpacity(0.08)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? _primaryColor
                                  : Colors.grey[200]!,
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Top row: Company + FIFO badge
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      batch.companyName,
                                      style: TextStyle(
                                        fontFamily: 'Literata',
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: isSelected ? _primaryColor : Colors.black87,
                                      ),
                                    ),
                                  ),
                                  if (isFifoRecommended)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.orange[100],
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        'FIFO',
                                        style: TextStyle(
                                          fontFamily: 'Literata',
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.orange[800],
                                        ),
                                      ),
                                    ),
                                  if (isSelected) ...[
                                    const SizedBox(width: 6),
                                    Icon(Icons.check_circle,
                                        size: 20, color: _primaryColor),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 6),

                              // Batch number and date
                              Row(
                                children: [
                                  Icon(Icons.tag, size: 14, color: Colors.grey[500]),
                                  const SizedBox(width: 4),
                                  Text(
                                    batch.batchNumber,
                                    style: TextStyle(
                                      fontFamily: 'Literata',
                                      fontSize: 11,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  const Spacer(),
                                  Icon(Icons.calendar_today,
                                      size: 12, color: Colors.grey[500]),
                                  const SizedBox(width: 4),
                                  Text(
                                    dateFormat.format(batch.purchaseDate),
                                    style: TextStyle(
                                      fontFamily: 'Literata',
                                      fontSize: 11,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),

                              // Price and stock row
                              Row(
                                children: [
                                  _buildInfoChip(
                                    'Stock',
                                    '${batch.currentQuantity.toStringAsFixed(0)} ${batch.unit}',
                                    Colors.blue,
                                  ),
                                  const SizedBox(width: 8),
                                  _buildInfoChip(
                                    'Purchase',
                                    '₹${batch.purchasePrice.toStringAsFixed(2)}',
                                    Colors.orange,
                                  ),
                                  const SizedBox(width: 8),
                                  _buildInfoChip(
                                    'Sale',
                                    '₹${batch.salesPrice.toStringAsFixed(2)}',
                                    Colors.green,
                                  ),
                                ],
                              ),

                              // Expiry warning if applicable
                              if (batch.expiryDate != null) ...[
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Icon(
                                      batch.isExpired
                                          ? Icons.warning
                                          : Icons.schedule,
                                      size: 14,
                                      color: batch.isExpired
                                          ? Colors.red
                                          : Colors.amber[700],
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      batch.isExpired
                                          ? 'Expired: ${dateFormat.format(batch.expiryDate!)}'
                                          : 'Expires: ${dateFormat.format(batch.expiryDate!)}',
                                      style: TextStyle(
                                        fontFamily: 'Literata',
                                        fontSize: 11,
                                        color: batch.isExpired
                                            ? Colors.red
                                            : Colors.amber[700],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),

          // Confirm button
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _selectedBatch != null
                    ? () => Navigator.of(context).pop(_selectedBatch)
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  _selectedBatch != null
                      ? 'Select Batch (${_selectedBatch!.companyName} - ${_selectedBatch!.currentQuantity.toStringAsFixed(0)} ${_selectedBatch!.unit})'
                      : 'Select a batch',
                  style: const TextStyle(
                    fontFamily: 'Literata',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),

          // Safe area padding for bottom
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }

  Widget _buildInfoChip(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Literata',
                fontSize: 10,
                color: color.withOpacity(0.7),
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontFamily: 'Literata',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../offline/controllers/product_batch_offline_controller.dart';
import '../../offline/entities/product_batch_entity.dart';
import 'batch_details_page.dart';

/// Page showing all product batches with filtering options
class BatchListPage extends StatefulWidget {
  final String? filterProductId;
  final String? filterProductName;

  const BatchListPage({
    super.key,
    this.filterProductId,
    this.filterProductName,
  });

  @override
  State<BatchListPage> createState() => _BatchListPageState();
}

class _BatchListPageState extends State<BatchListPage> {
  static const _primaryColor = Color(0xFF1B4D3E);
  final _searchController = TextEditingController();
  final _dateFormat = DateFormat('dd MMM yyyy');

  List<ProductBatchEntity> _allBatches = [];
  List<ProductBatchEntity> _filteredBatches = [];
  bool _isLoading = true;
  String _selectedFilter = 'all'; // all, active, exhausted, expired

  @override
  void initState() {
    super.initState();
    _loadBatches();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadBatches() async {
    setState(() => _isLoading = true);
    try {
      final controller = ProductBatchOfflineController.instance;
      if (widget.filterProductId != null) {
        _allBatches = await controller.getAllBatchesForProduct(widget.filterProductId!);
      } else {
        _allBatches = await controller.getAllBatches();
      }
      _applyFilters();
    } catch (e) {
      debugPrint('[BatchListPage] Error loading batches: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _applyFilters() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredBatches = _allBatches.where((batch) {
        // Status filter
        bool matchesStatus = true;
        switch (_selectedFilter) {
          case 'active':
            matchesStatus = batch.status == BatchStatus.active && batch.currentQuantity > 0;
            break;
          case 'exhausted':
            matchesStatus = batch.status == BatchStatus.exhausted || batch.currentQuantity <= 0;
            break;
          case 'expired':
            matchesStatus = batch.isExpired;
            break;
        }

        // Search filter
        bool matchesSearch = query.isEmpty ||
            batch.productName.toLowerCase().contains(query) ||
            batch.companyName.toLowerCase().contains(query) ||
            batch.batchNumber.toLowerCase().contains(query) ||
            batch.supplierName.toLowerCase().contains(query);

        return matchesStatus && matchesSearch;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
        title: Text(
          widget.filterProductName != null
              ? 'Batches: ${widget.filterProductName}'
              : 'All Batches',
          style: const TextStyle(fontFamily: 'Literata', fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadBatches,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and filter bar
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  onChanged: (_) => _applyFilters(),
                  decoration: InputDecoration(
                    hintText: 'Search batches...',
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
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('All', 'all'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Active', 'active'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Exhausted', 'exhausted'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Expired', 'expired'),
                    ],
                  ),
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
                _buildSummaryItem('Total', '${_filteredBatches.length}'),
                _buildSummaryItem(
                  'Active',
                  '${_filteredBatches.where((b) => b.status == BatchStatus.active && b.currentQuantity > 0).length}',
                ),
                _buildSummaryItem(
                  'Stock Value',
                  '₹${_filteredBatches.fold<double>(0, (sum, b) => sum + b.totalValue).toStringAsFixed(0)}',
                ),
              ],
            ),
          ),

          // Batch list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: _primaryColor))
                : _filteredBatches.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey[300]),
                            const SizedBox(height: 16),
                            Text(
                              'No batches found',
                              style: TextStyle(
                                fontFamily: 'Literata',
                                fontSize: 16,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadBatches,
                        color: _primaryColor,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: _filteredBatches.length,
                          itemBuilder: (context, index) {
                            return _buildBatchCard(_filteredBatches[index]);
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
      onTap: () {
        setState(() => _selectedFilter = value);
        _applyFilters();
      },
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
          style: TextStyle(
            fontFamily: 'Literata',
            fontSize: 11,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildBatchCard(ProductBatchEntity batch) {
    final statusColor = batch.status == BatchStatus.active
        ? Colors.green
        : batch.status == BatchStatus.expired
            ? Colors.red
            : Colors.grey;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => BatchDetailsPage(batch: batch),
          ),
        ).then((_) => _loadBatches());
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product name + status badge
            Row(
              children: [
                Expanded(
                  child: Text(
                    batch.productName,
                    style: const TextStyle(
                      fontFamily: 'Literata',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    batch.status.name.toUpperCase(),
                    style: TextStyle(
                      fontFamily: 'Literata',
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),

            // Company and supplier
            Text(
              '${batch.companyName} • ${batch.supplierName}',
              style: TextStyle(
                fontFamily: 'Literata',
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),

            // Batch number and date
            Row(
              children: [
                Icon(Icons.tag, size: 14, color: Colors.grey[400]),
                const SizedBox(width: 4),
                Text(
                  batch.batchNumber,
                  style: TextStyle(fontFamily: 'Literata', fontSize: 11, color: Colors.grey[500]),
                ),
                const Spacer(),
                Icon(Icons.calendar_today, size: 12, color: Colors.grey[400]),
                const SizedBox(width: 4),
                Text(
                  _dateFormat.format(batch.purchaseDate),
                  style: TextStyle(fontFamily: 'Literata', fontSize: 11, color: Colors.grey[500]),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Stock, purchase price, sales price
            Row(
              children: [
                _buildInfoPill('Stock', '${batch.currentQuantity.toStringAsFixed(0)}/${batch.initialQuantity.toStringAsFixed(0)}', Colors.blue),
                const SizedBox(width: 8),
                _buildInfoPill('Buy', '₹${batch.purchasePrice.toStringAsFixed(0)}', Colors.orange),
                const SizedBox(width: 8),
                _buildInfoPill('Sell', '₹${batch.salesPrice.toStringAsFixed(0)}', Colors.green),
                const SizedBox(width: 8),
                _buildInfoPill('Value', '₹${batch.totalValue.toStringAsFixed(0)}', _primaryColor),
              ],
            ),

            // Expiry warning
            if (batch.expiryDate != null) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(
                    batch.isExpired ? Icons.warning : Icons.schedule,
                    size: 14,
                    color: batch.isExpired ? Colors.red : Colors.amber[700],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    batch.isExpired
                        ? 'Expired: ${_dateFormat.format(batch.expiryDate!)}'
                        : 'Expires: ${_dateFormat.format(batch.expiryDate!)}',
                    style: TextStyle(
                      fontFamily: 'Literata',
                      fontSize: 11,
                      color: batch.isExpired ? Colors.red : Colors.amber[700],
                    ),
                  ),
                ],
              ),
            ],

            // Sync status indicator
            if (batch.needsSync) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.sync, size: 12, color: Colors.orange[400]),
                  const SizedBox(width: 4),
                  Text(
                    'Pending sync',
                    style: TextStyle(fontFamily: 'Literata', fontSize: 10, color: Colors.orange[400]),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoPill(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(fontFamily: 'Literata', fontSize: 9, color: color.withOpacity(0.7)),
            ),
            Text(
              value,
              style: TextStyle(fontFamily: 'Literata', fontSize: 11, fontWeight: FontWeight.w600, color: color),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../../product/offline/entities/product_entity.dart';

/// Summary widget for product statistics
/// Displays: Total products, Total stock, Out of stock, Sync status
class ProductSummaryWidget extends StatelessWidget {
  final List<ProductEntity> products;
  final String searchQuery;

  const ProductSummaryWidget({
    super.key,
    required this.products,
    this.searchQuery = '',
  });

  List<ProductEntity> get _filteredProducts {
    if (searchQuery.isEmpty) return products;
    
    final query = searchQuery.toLowerCase();
    return products.where((p) {
      final name = p.name.toLowerCase();
      final company = p.companyName.toLowerCase();
      final category = p.category.toLowerCase();
      return name.contains(query) ||
          company.contains(query) ||
          category.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredProducts;
    final totalStock = filtered.fold<int>(0, (sum, p) => sum + p.currentStock);
    final outOfStock = filtered.where((p) => p.currentStock == 0).length;
    final unsyncedCount = filtered.where((p) => p.syncStatus != SyncStatus.synced).length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF1B4D3E),
            const Color(0xFF1B4D3E).withOpacity(0.85),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1B4D3E).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildStatItem(
            icon: Icons.inventory_2_rounded,
            label: 'Products',
            value: '${filtered.length}',
          ),
          _buildDivider(),
          _buildStatItem(
            icon: Icons.widgets_rounded,
            label: 'Total Stock',
            value: '$totalStock',
          ),
          _buildDivider(),
          _buildStatItem(
            icon: Icons.warning_amber_rounded,
            label: 'Out of Stock',
            value: '$outOfStock',
            valueColor: outOfStock > 0 ? Colors.red[300] : null,
          ),
          _buildDivider(),
          Expanded(
            child: _buildStatItem(
              icon: unsyncedCount > 0
                  ? Icons.cloud_upload_rounded
                  : Icons.cloud_done_rounded,
              label: unsyncedCount > 0 ? 'Pending' : 'Synced',
              value: unsyncedCount > 0 ? '$unsyncedCount' : '✓',
              valueColor: unsyncedCount > 0 ? Colors.orange[300] : Colors.green[300],
              isExpanded: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
    bool isExpanded = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: Colors.white.withOpacity(0.8),
            size: 18,
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Literata',
              fontWeight: FontWeight.w800,
              fontSize: 15,
              color: valueColor ?? Colors.white,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Literata',
              fontWeight: FontWeight.w400,
              fontSize: 10,
              color: Colors.white.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      width: 1,
      height: 40,
      color: Colors.white.withOpacity(0.2),
    );
  }
}

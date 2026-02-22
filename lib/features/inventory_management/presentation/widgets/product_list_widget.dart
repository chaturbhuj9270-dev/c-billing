import 'package:flutter/material.dart';
import 'package:c_billing/features/product/offline/entities/product_entity.dart';
import 'product_filter_widget.dart';

/// Enhanced list widget for displaying products
/// Features: Shimmer loading, Enhanced cards, Stock badges, Sync icons, Empty states
class ProductListWidget extends StatelessWidget {
  final List<ProductEntity> products;
  final bool isLoading;
  final String searchQuery;
  final ProductSortField sortField;
  final bool sortAscending;
  final String? selectedCategory;
  final Future<void> Function() onRefresh;
  final void Function(ProductEntity) onProductTap;
  final void Function(ProductEntity)? onProductLongPress;
  
  // Labels
  final String emptyTitle;
  final String emptySubtitle;
  final String noResultsTitle;
  final String noResultsSubtitle;

  const ProductListWidget({
    super.key,
    required this.products,
    required this.isLoading,
    required this.searchQuery,
    required this.sortField,
    required this.sortAscending,
    this.selectedCategory,
    required this.onRefresh,
    required this.onProductTap,
    this.onProductLongPress,
    this.emptyTitle = 'No products yet',
    this.emptySubtitle = 'Add your first product to get started',
    this.noResultsTitle = 'No results found',
    this.noResultsSubtitle = 'Try a different search term',
  });

  List<ProductEntity> get _filteredAndSortedProducts {
    var filtered = products.where((p) => p.isActive).toList();

    // Apply category filter
    if (selectedCategory != null && selectedCategory!.isNotEmpty) {
      filtered = filtered.where((p) => 
        p.category.toLowerCase() == selectedCategory!.toLowerCase()
      ).toList();
    }

    // Apply search filter
    if (searchQuery.isNotEmpty) {
      final query = searchQuery.toLowerCase();
      filtered = filtered.where((p) {
        final name = p.name.toLowerCase();
        final company = p.companyName.toLowerCase();
        final category = p.category.toLowerCase();
        final barcode = (p.barcode ?? '').toLowerCase();
        final productCode = p.indexNo.toString();
        return name.contains(query) ||
            company.contains(query) ||
            category.contains(query) ||
            barcode.contains(query) ||
            productCode.contains(query);
      }).toList();
    }

    // Apply sort
    filtered.sort((a, b) {
      int result;
      switch (sortField) {
        case ProductSortField.name:
          result = a.name.toLowerCase().compareTo(b.name.toLowerCase());
          break;
        case ProductSortField.stock:
          result = a.currentStock.compareTo(b.currentStock);
          break;
        case ProductSortField.price:
          result = a.salesPrice.compareTo(b.salesPrice);
          break;
        case ProductSortField.category:
          result = a.category.toLowerCase().compareTo(b.category.toLowerCase());
          break;
      }
      return sortAscending ? result : -result;
    });

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    // Show shimmer while loading
    if (isLoading && products.isEmpty) {
      return _buildShimmerList();
    }

    // Empty state - no products at all
    if (products.isEmpty) {
      return _buildEmptyState(
        icon: Icons.inventory_2_outlined,
        title: emptyTitle,
        subtitle: emptySubtitle,
      );
    }

    final filtered = _filteredAndSortedProducts;

    // Empty state - no search results
    if (filtered.isEmpty) {
      return _buildEmptyState(
        icon: Icons.search_off_rounded,
        title: noResultsTitle,
        subtitle: noResultsSubtitle,
      );
    }

    return RefreshIndicator(
      color: const Color(0xFF1B4D3E),
      onRefresh: onRefresh,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: const EdgeInsets.only(top: 8, bottom: 100),
        itemCount: filtered.length,
        itemBuilder: (context, index) {
          return RepaintBoundary(
            child: _ProductCard(
              product: filtered[index],
              onTap: () => onProductTap(filtered[index]),
              onLongPress: onProductLongPress != null
                  ? () => onProductLongPress!(filtered[index])
                  : null,
            ),
          );
        },
      ),
    );
  }

  Widget _buildShimmerList() {
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.only(top: 8),
      itemCount: 6,
      itemBuilder: (context, index) {
        return const _ShimmerCard();
      },
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: const Color(0xFF1B4D3E).withOpacity(0.1),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(
                icon,
                size: 48,
                color: const Color(0xFF1B4D3E).withOpacity(0.4),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: TextStyle(
                fontFamily: 'Literata',
                fontWeight: FontWeight.w700,
                fontSize: 18,
                color: Colors.grey[700],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: TextStyle(
                fontFamily: 'Literata',
                fontWeight: FontWeight.w400,
                fontSize: 14,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Enhanced product card widget
class _ProductCard extends StatelessWidget {
  final ProductEntity product;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const _ProductCard({
    required this.product,
    required this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final isSynced = product.syncStatus == SyncStatus.synced;
    final isLowStock = product.currentStock <= (product.minStockLevel ?? 5);
    final isOutOfStock = product.currentStock <= 0;

    const accentColors = [
      Color(0xFF1B4D3E),
      Color(0xFF0F3B2F),
      Color(0xFF2C6F5E),
      Color(0xFF1A5E52),
    ];
    final accentColor = accentColors[product.name.hashCode.abs() % 4];
    final initials = product.name.isNotEmpty 
        ? product.name[0].toUpperCase() 
        : 'P';

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
            BoxShadow(
              color: accentColor.withOpacity(0.08),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Row: Avatar + Info + Stock/Arrow
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Avatar with gradient and low stock indicator
                  Stack(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: isOutOfStock
                                ? [Colors.red[400]!, Colors.red[300]!]
                                : isLowStock
                                    ? [Colors.orange[400]!, Colors.orange[300]!]
                                    : [accentColor, accentColor.withOpacity(0.7)],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: isOutOfStock
                                  ? Colors.red.withOpacity(0.3)
                                  : isLowStock
                                      ? Colors.orange.withOpacity(0.3)
                                      : accentColor.withOpacity(0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Center(
                          child: product.imageUrl != null && product.imageUrl!.isNotEmpty
                              ? ClipOval(
                                  child: Image.network(
                                    product.imageUrl!,
                                    width: 52,
                                    height: 52,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Text(
                                      initials,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 20,
                                        fontWeight: FontWeight.w700,
                                        fontFamily: 'Literata',
                                      ),
                                    ),
                                  ),
                                )
                              : Text(
                                  initials,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                    fontFamily: 'Literata',
                                  ),
                                ),
                        ),
                      ),
                      // Low stock indicator dot
                      if (isOutOfStock || isLowStock)
                        Positioned(
                          top: 0,
                          right: 0,
                          child: Container(
                            width: 14,
                            height: 14,
                            decoration: BoxDecoration(
                              color: isOutOfStock ? Colors.red : Colors.orange,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: Center(
                              child: Icon(
                                isOutOfStock
                                    ? Icons.close_rounded
                                    : Icons.warning_rounded,
                                size: 8,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  // Name + Company + Category
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            // Product Code Badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              margin: const EdgeInsets.only(right: 8),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [accentColor, accentColor.withOpacity(0.8)],
                                ),
                                borderRadius: BorderRadius.circular(6),
                                boxShadow: [
                                  BoxShadow(
                                    color: accentColor.withOpacity(0.2),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Text(
                                '#${product.indexNo}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                  fontFamily: 'Literata',
                                ),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                product.name,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF1B4D3E),
                                  fontFamily: 'Literata',
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            // Sync status icon - always show (green for synced, orange for pending)
                            Padding(
                              padding: const EdgeInsets.only(left: 6),
                              child: Icon(
                                isSynced
                                    ? Icons.cloud_done_rounded
                                    : Icons.cloud_upload_rounded,
                                size: 16,
                                color: isSynced
                                    ? Colors.green
                                    : Colors.orange,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        // Company name
                        if (product.companyName.isNotEmpty) ...[
                          Row(
                            children: [
                              Icon(
                                Icons.business_rounded,
                                size: 13,
                                color: Colors.grey[500],
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  product.companyName,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey[600],
                                    fontFamily: 'Literata',
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                        // Category tag
                        if (product.category.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1B4D3E).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              product.category,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF1B4D3E),
                                fontFamily: 'Literata',
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Stock badge
                  _buildStockBadge(isOutOfStock, isLowStock),
                ],
              ),
              // Price row
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Purchase price
                    _buildPriceItem(
                      icon: Icons.shopping_cart_outlined,
                      label: 'Purchase',
                      value: '₹${product.purchasePrice.toStringAsFixed(0)}',
                      color: Colors.grey[700]!,
                    ),
                    Container(
                      width: 1,
                      height: 28,
                      color: Colors.grey[300],
                    ),
                    // Sales price
                    _buildPriceItem(
                      icon: Icons.sell_outlined,
                      label: 'Sale',
                      value: '₹${product.salesPrice.toStringAsFixed(0)}',
                      color: Colors.green[700]!,
                    ),
                    Container(
                      width: 1,
                      height: 28,
                      color: Colors.grey[300],
                    ),
                    // Stock
                    _buildPriceItem(
                      icon: Icons.inventory_rounded,
                      label: 'Stock',
                      value: '${product.currentStock}',
                      color: isOutOfStock
                          ? Colors.red[700]!
                          : isLowStock
                              ? Colors.orange[700]!
                              : const Color(0xFF1B4D3E),
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

  Widget _buildStockBadge(bool isOutOfStock, bool isLowStock) {
    if (isOutOfStock) {
      return Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          color: Colors.red[50],
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: Colors.red[100]!,
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.warning_rounded,
              size: 16,
              color: Colors.red[700],
            ),
            const SizedBox(height: 2),
            Text(
              'Out',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: Colors.red[700],
                fontFamily: 'Literata',
              ),
            ),
          ],
        ),
      );
    } else if (isLowStock) {
      return Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          color: Colors.orange[50],
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: Colors.orange[100]!,
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${product.currentStock}',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Colors.orange[700],
                fontFamily: 'Literata',
              ),
            ),
            Text(
              'low',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w500,
                color: Colors.orange[400],
                fontFamily: 'Literata',
              ),
            ),
          ],
        ),
      );
    } else {
      return Icon(
        Icons.chevron_right_rounded,
        size: 24,
        color: Colors.grey[400],
      );
    }
  }

  Widget _buildPriceItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: Colors.grey[500]),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[500],
                fontFamily: 'Literata',
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: color,
            fontFamily: 'Literata',
          ),
        ),
      ],
    );
  }
}

/// Shimmer loading card for product list
class _ShimmerCard extends StatefulWidget {
  const _ShimmerCard();

  @override
  State<_ShimmerCard> createState() => _ShimmerCardState();
}

class _ShimmerCardState extends State<_ShimmerCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();

    _animation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _buildShimmerCircle(52),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildShimmerBox(height: 16, width: double.infinity),
                        const SizedBox(height: 8),
                        _buildShimmerBox(height: 12, width: 120),
                        const SizedBox(height: 6),
                        _buildShimmerBox(height: 14, width: 60),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildShimmerBox(height: 44, width: 44),
                ],
              ),
              const SizedBox(height: 10),
              _buildShimmerBox(height: 50, width: double.infinity),
            ],
          ),
        );
      },
    );
  }

  Widget _buildShimmerBox({required double height, required double width}) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        gradient: LinearGradient(
          begin: Alignment(_animation.value - 1, 0),
          end: Alignment(_animation.value, 0),
          colors: [
            Colors.grey[200]!,
            Colors.grey[100]!,
            Colors.grey[200]!,
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerCircle(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment(_animation.value - 1, 0),
          end: Alignment(_animation.value, 0),
          colors: [
            Colors.grey[200]!,
            Colors.grey[100]!,
            Colors.grey[200]!,
          ],
        ),
      ),
    );
  }
}

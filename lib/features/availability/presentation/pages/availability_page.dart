import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:c_billing/core/services/inventory_service.dart';
import 'package:c_billing/features/inventory_management/data/repositories/firebase_product_repository.dart';
import 'package:c_billing/features/inventory_management/data/repositories/firebase_stock_repository.dart';
import 'package:c_billing/features/inventory_management/data/repositories/firebase_purchase_repository.dart';
import 'package:c_billing/features/inventory_management/domain/entities/product.dart';

class AvailabilityPage extends StatefulWidget {
  final bool isEmbedded;

  const AvailabilityPage({super.key, this.isEmbedded = false});

  @override
  State<AvailabilityPage> createState() => _AvailabilityPageState();
}

class _AvailabilityPageState extends State<AvailabilityPage> {
  late InventoryService _inventoryService;
  late FirebaseFirestore _firestore;
  final _auth = FirebaseAuth.instance;
  List<Product> _products = [];
  List<Product> _filteredProducts = [];
  bool _isLoading = false;
  String _searchQuery = '';
  final _searchController = TextEditingController();

  // Filter states
  String _stockFilter = 'all'; // all, in_stock, low_stock, out_of_stock

  @override
  void initState() {
    super.initState();
    _firestore = FirebaseFirestore.instance;
    _inventoryService = InventoryService(
      productRepository: FirebaseProductRepository(
        firestore: _firestore,
        auth: _auth,
      ),
      stockRepository: FirebaseStockRepository(
        firestore: _firestore,
        auth: _auth,
      ),
      purchaseRepository: FirebasePurchaseRepository(
        firestore: _firestore,
        auth: _auth,
      ),
    );
    _loadProducts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    try {
      setState(() => _isLoading = true);
      final products = await _inventoryService.getAllProducts();
      if (mounted) {
        setState(() {
          _products = products;
          _applyFilters();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading products: $e')));
      }
    }
  }

  void _applyFilters() {
    _filteredProducts = _products.where((product) {
      // Search filter
      if (_searchQuery.isNotEmpty &&
          !product.name.toLowerCase().contains(_searchQuery.toLowerCase()) &&
          !product.category.toLowerCase().contains(
            _searchQuery.toLowerCase(),
          ) &&
          !product.indexNo.toString().contains(_searchQuery)) {
        return false;
      }

      // Stock filter
      switch (_stockFilter) {
        case 'in_stock':
          return product.currentStock > 10;
        case 'low_stock':
          return product.currentStock > 0 && product.currentStock <= 10;
        case 'out_of_stock':
          return product.currentStock == 0;
        default:
          return true;
      }
    }).toList();

    // Sort by stock level (critical first)
    _filteredProducts.sort((a, b) {
      if (a.currentStock == 0 && b.currentStock > 0) return -1;
      if (b.currentStock == 0 && a.currentStock > 0) return 1;
      if (a.currentStock <= 10 && b.currentStock > 10) return -1;
      if (b.currentStock <= 10 && a.currentStock > 10) return 1;
      return a.name.compareTo(b.name);
    });
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
      _applyFilters();
    });
  }

  void _onStockFilterChanged(String filter) {
    setState(() {
      _stockFilter = filter;
      _applyFilters();
    });
  }

  Widget _buildStatsCards() {
    final totalProducts = _products.length;
    final inStock = _products.where((p) => p.currentStock > 10).length;
    final lowStock = _products
        .where((p) => p.currentStock > 0 && p.currentStock <= 10)
        .length;
    final outOfStock = _products.where((p) => p.currentStock == 0).length;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              title: 'Total Products',
              value: totalProducts,
              icon: Icons.inventory_2,
              iconColor: const Color(0xFF1B4D3E),
              backgroundColor: const Color(0xFF1B4D3E).withOpacity(0.1),
            ),
          ),
          Expanded(
            child: _buildStatCard(
              title: 'In Stock',
              value: inStock,
              icon: Icons.check_circle,
              iconColor: Colors.green,
              backgroundColor: Colors.green.withOpacity(0.1),
            ),
          ),
          Expanded(
            child: _buildStatCard(
              title: 'Low Stock',
              value: lowStock,
              icon: Icons.warning,
              iconColor: Colors.orange,
              backgroundColor: Colors.orange.withOpacity(0.1),
            ),
          ),
          Expanded(
            child: _buildStatCard(
              title: 'Out of Stock',
              value: outOfStock,
              icon: Icons.error,
              iconColor: Colors.red,
              backgroundColor: Colors.red.withOpacity(0.1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required int value,
    required IconData icon,
    required Color iconColor,
    required Color backgroundColor,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: iconColor, size: 16),
            const SizedBox(height: 4),
            Text(
              value.toString(),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                fontFamily: 'Literata',
              ),
            ),
            const SizedBox(height: 2),
            Text(
              title,
              style: TextStyle(
                fontSize: 9,
                color: Colors.grey[600],
                fontFamily: 'Literata',
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // Search bar
          TextField(
            controller: _searchController,
            onChanged: _onSearchChanged,
            style: const TextStyle(fontFamily: 'Literata', fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Search products...',
              hintStyle: TextStyle(color: Colors.grey[500]),
              prefixIcon: const Icon(Icons.search, color: Color(0xFF1B4D3E)),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 20),
                      onPressed: () {
                        _searchController.clear();
                        _onSearchChanged('');
                      },
                    )
                  : null,
              filled: true,
              fillColor: const Color(0xFFF5F5F5),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Stock filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('All', 'all'),
                const SizedBox(width: 8),
                _buildFilterChip('In Stock', 'in_stock'),
                const SizedBox(width: 8),
                _buildFilterChip('Low Stock', 'low_stock'),
                const SizedBox(width: 8),
                _buildFilterChip('Out of Stock', 'out_of_stock'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _stockFilter == value;
    return FilterChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontFamily: 'Literata',
          fontWeight: FontWeight.w500,
          color: isSelected ? Colors.white : const Color(0xFF1B4D3E),
        ),
      ),
      selected: isSelected,
      onSelected: (_) => _onStockFilterChanged(value),
      backgroundColor: Colors.transparent,
      selectedColor: const Color(0xFF1B4D3E),
      checkmarkColor: Colors.white,
      side: BorderSide(
        color: isSelected ? const Color(0xFF1B4D3E) : Colors.grey[300]!,
      ),
    );
  }

  Widget _buildProductsList() {
    if (_filteredProducts.isEmpty) {
      return Expanded(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.inventory_2_outlined,
                size: 64,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                _searchQuery.isEmpty
                    ? 'No products found'
                    : 'No products match your search',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey[600],
                  fontFamily: 'Literata',
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Expanded(
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _filteredProducts.length,
        itemBuilder: (context, index) {
          final product = _filteredProducts[index];
          final stockLevel = _getStockLevel(product.currentStock);

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // Product index badge
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: stockLevel['color'] as Color,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            product.indexNo > 0 ? '${product.indexNo}' : '#',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                              fontFamily: 'Literata',
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              product.name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                fontFamily: 'Literata',
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              product.category,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                                fontFamily: 'Literata',
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: (stockLevel['color'] as Color).withOpacity(
                            0.1,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          stockLevel['label'] as String,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: stockLevel['color'] as Color,
                            fontFamily: 'Literata',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Current Stock',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey[600],
                                fontFamily: 'Literata',
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${product.currentStock} units',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: stockLevel['color'] as Color,
                                fontFamily: 'Literata',
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'Stock Value',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey[600],
                                fontFamily: 'Literata',
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '₹${product.getStockValue().toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1B4D3E),
                                fontFamily: 'Literata',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (product.currentStock <= 10)
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: product.currentStock == 0
                            ? Colors.red.withOpacity(0.1)
                            : Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            product.currentStock == 0
                                ? Icons.error_outline
                                : Icons.warning_amber,
                            color: product.currentStock == 0
                                ? Colors.red
                                : Colors.orange,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              product.currentStock == 0
                                  ? 'This product is out of stock and needs to be restocked immediately.'
                                  : 'This product is running low on stock. Consider restocking soon.',
                              style: TextStyle(
                                fontSize: 10,
                                color: product.currentStock == 0
                                    ? Colors.red[700]
                                    : Colors.orange[700],
                                fontFamily: 'Literata',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Map<String, dynamic> _getStockLevel(int stock) {
    if (stock == 0) {
      return {'label': 'OUT OF STOCK', 'color': Colors.red};
    } else if (stock <= 10) {
      return {'label': 'LOW STOCK', 'color': Colors.orange};
    } else {
      return {'label': 'IN STOCK', 'color': Colors.green};
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF1B4D3E)),
            )
          : Column(
              children: [
                _buildStatsCards(),
                _buildSearchAndFilters(),
                const SizedBox(height: 12),
                _buildProductsList(),
              ],
            ),
    );
  }
}

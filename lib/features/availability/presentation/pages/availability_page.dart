import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:c_billing/core/services/inventory_service.dart';
import 'package:c_billing/core/services/inventory_report_service.dart';
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

  final _reportService = InventoryReportService();

  void _showReportBottomSheet() {
    Set<ReportType> selectedTypes = {ReportType.outOfStock};
    ReportFormat selectedFormat = ReportFormat.pdf;
    bool isGenerating = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) => Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1B4D3E).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.description_outlined,
                        color: Color(0xFF1B4D3E),
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Generate Report',
                            style: TextStyle(
                              fontFamily: 'Literata',
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1B4D3E),
                            ),
                          ),
                          Text(
                            'Export inventory data as PDF or CSV',
                            style: TextStyle(
                              fontFamily: 'Literata',
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // Report Type Selection
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Report Type',
                      style: TextStyle(
                        fontFamily: 'Literata',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1B4D3E),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Select one or more report types',
                      style: TextStyle(
                        fontFamily: 'Literata',
                        fontSize: 11,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildReportTypeCheckbox(
                      'Out of Stock Products',
                      'Products with 0 quantity',
                      Icons.error_outline,
                      Colors.red,
                      ReportType.outOfStock,
                      selectedTypes,
                      (type, isChecked) => setSheetState(() {
                        if (isChecked) {
                          selectedTypes.add(type);
                        } else {
                          selectedTypes.remove(type);
                        }
                      }),
                    ),
                    const SizedBox(height: 8),
                    _buildReportTypeCheckbox(
                      'Low Stock Products',
                      'Products with quantity ≤ 10',
                      Icons.warning_amber,
                      Colors.orange,
                      ReportType.lowStock,
                      selectedTypes,
                      (type, isChecked) => setSheetState(() {
                        if (isChecked) {
                          selectedTypes.add(type);
                        } else {
                          selectedTypes.remove(type);
                        }
                      }),
                    ),
                    const SizedBox(height: 8),
                    _buildReportTypeCheckbox(
                      'All Products',
                      'Complete inventory list',
                      Icons.inventory_2,
                      const Color(0xFF1B4D3E),
                      ReportType.allProducts,
                      selectedTypes,
                      (type, isChecked) => setSheetState(() {
                        if (isChecked) {
                          selectedTypes.add(type);
                        } else {
                          selectedTypes.remove(type);
                        }
                      }),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // Format Selection
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Export Format',
                      style: TextStyle(
                        fontFamily: 'Literata',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1B4D3E),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildFormatOption(
                            'PDF',
                            Icons.picture_as_pdf,
                            Colors.red,
                            ReportFormat.pdf,
                            selectedFormat,
                            (format) =>
                                setSheetState(() => selectedFormat = format),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildFormatOption(
                            'CSV (Excel)',
                            Icons.table_chart,
                            Colors.green,
                            ReportFormat.csv,
                            selectedFormat,
                            (format) =>
                                setSheetState(() => selectedFormat = format),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Generate Button
              Padding(
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  bottom: MediaQuery.of(context).padding.bottom + 16,
                  top: 8,
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isGenerating || selectedTypes.isEmpty
                        ? null
                        : () async {
                            setSheetState(() => isGenerating = true);
                            await _generateReportMultiple(
                              selectedTypes,
                              selectedFormat,
                            );
                            if (mounted) {
                              Navigator.pop(context);
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1B4D3E),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: isGenerating
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Generate & Share',
                            style: TextStyle(
                              fontFamily: 'Literata',
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReportTypeCheckbox(
    String title,
    String subtitle,
    IconData icon,
    Color iconColor,
    ReportType type,
    Set<ReportType> selectedTypes,
    Function(ReportType, bool) onToggle,
  ) {
    final isSelected = selectedTypes.contains(type);
    return InkWell(
      onTap: () => onToggle(type, !isSelected),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF1B4D3E).withOpacity(0.1)
              : Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF1B4D3E) : Colors.grey[200]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontFamily: 'Literata',
                      fontSize: 14,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w500,
                      color: isSelected
                          ? const Color(0xFF1B4D3E)
                          : Colors.black87,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontFamily: 'Literata',
                      fontSize: 11,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Checkbox(
              value: isSelected,
              onChanged: (value) => onToggle(type, value ?? false),
              activeColor: const Color(0xFF1B4D3E),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormatOption(
    String label,
    IconData icon,
    Color color,
    ReportFormat format,
    ReportFormat selectedFormat,
    Function(ReportFormat) onSelect,
  ) {
    final isSelected = format == selectedFormat;
    return InkWell(
      onTap: () => onSelect(format),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : Colors.grey[200]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Literata',
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? color : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _generateReportMultiple(
    Set<ReportType> reportTypes,
    ReportFormat format,
  ) async {
    try {
      // Combine products from all selected types (avoiding duplicates)
      final Set<String> addedProductIds = {};
      final List<Product> combinedProducts = [];

      for (final reportType in reportTypes) {
        final filteredProducts = _reportService.filterProducts(
          _products,
          reportType,
        );
        for (final product in filteredProducts) {
          if (!addedProductIds.contains(product.id)) {
            addedProductIds.add(product.id);
            combinedProducts.add(product);
          }
        }
      }

      if (combinedProducts.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No products found for selected report types'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      // Generate combined report title
      final typeLabels = reportTypes
          .map((t) => _reportService.getReportTypeLabel(t))
          .join(', ');

      late final file;
      if (format == ReportFormat.pdf) {
        file = await _reportService.generatePdfReport(
          products: combinedProducts,
          reportType: reportTypes.length == 1
              ? reportTypes.first
              : ReportType.allProducts,
          customTitle: reportTypes.length > 1 ? 'Combined Report' : null,
          customSubtitle: reportTypes.length > 1 ? typeLabels : null,
        );
      } else {
        file = await _reportService.generateCsvReport(
          products: combinedProducts,
          reportType: reportTypes.length == 1
              ? reportTypes.first
              : ReportType.allProducts,
          customTitle: reportTypes.length > 1 ? 'Combined Report' : null,
        );
      }

      await _reportService.shareReport(file);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Report generated with ${combinedProducts.length} products',
            ),
            backgroundColor: const Color(0xFF1B4D3E),
          ),
        );
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
    }
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
                _buildPageHeader(),
                _buildStatsCards(),
                _buildSearchAndFilters(),
                const SizedBox(height: 12),
                _buildProductsList(),
              ],
            ),
    );
  }

  Widget _buildPageHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Stock Overview',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1B4D3E),
              fontFamily: 'Literata',
            ),
          ),
          IconButton(
            onPressed: _showReportBottomSheet,
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF1B4D3E).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.summarize_outlined,
                color: Color(0xFF1B4D3E),
                size: 20,
              ),
            ),
            tooltip: 'Generate Report',
          ),
        ],
      ),
    );
  }
}

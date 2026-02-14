import 'dart:async';
import 'package:flutter/material.dart';
import 'package:c_billing/core/services/inventory_report_service.dart';
import 'package:c_billing/core/services/dashboard_refresh_service.dart';
import 'package:c_billing/core/localization/app_localizations.dart';
import 'package:c_billing/core/services/language_service.dart';
import 'package:c_billing/features/product/offline/controllers/product_offline_controller.dart';
import 'package:c_billing/features/product/data/services/product_sync_service.dart';
import 'package:c_billing/features/inventory_management/domain/entities/product.dart';
import 'package:c_billing/features/inventory_management/domain/entities/report_item.dart';
import 'package:c_billing/features/inventory_management/domain/entities/grouped_product.dart';
import 'package:c_billing/features/inventory_management/offline/controllers/purchase_batch_offline_controller.dart';
import 'package:c_billing/features/inventory_management/offline/entities/purchase_batch_entity.dart';
import 'package:c_billing/features/availability/presentation/pages/report_preview_screen.dart';

class AvailabilityPage extends StatefulWidget {
  final bool isEmbedded;

  const AvailabilityPage({super.key, this.isEmbedded = false});

  @override
  State<AvailabilityPage> createState() => _AvailabilityPageState();
}

class _AvailabilityPageState extends State<AvailabilityPage> {
  late AppLocalizations _localizations;
  List<Product> _products = [];
  List<Product> _filteredProducts = [];
  bool _isLoading = false;
  String _searchQuery = '';
  final _searchController = TextEditingController();
  
  // Data refresh subscription
  StreamSubscription<void>? _productRefreshSubscription;
  StreamSubscription<void>? _purchaseRefreshSubscription;

  // Filter states
  String _stockFilter = 'all'; // all, in_stock, low_stock, out_of_stock

  // Batch-level data for grouped view
  List<PurchaseBatchEntity> _allBatches = [];
  List<GroupedProduct> _groupedProducts = [];
  List<GroupedProduct> _filteredGroupedProducts = [];
  StreamSubscription<List<PurchaseBatchEntity>>? _batchStreamSubscription;

  @override
  void initState() {
    super.initState();
    _localizations = AppLocalizations.of(LanguageService.instance.currentLanguage);
    
    // Listen for language changes
    LanguageService.instance.addListener(_onLanguageChanged);
    
    // Listen for product changes from other screens (purchase page, product management, etc.)
    _productRefreshSubscription = DashboardRefreshService.instance.onProductChanged.listen((_) {
      if (mounted) _loadProducts();
    });
    
    // Also listen for purchase changes which affect stock
    _purchaseRefreshSubscription = DashboardRefreshService.instance.onPurchaseChanged.listen((_) {
      if (mounted) _loadProducts();
    });
    
    // Listen for changes from ProductOfflineController
    ProductOfflineController.instance.addListener(_onProductsChanged);
    
    _loadProducts();
    _setupBatchStream();
    
    // Trigger sync in background
    ProductSyncService.instance.syncNow();
  }

  /// Setup batch stream for real-time updates
  void _setupBatchStream() {
    final batchController = PurchaseBatchOfflineController.instance;
    _batchStreamSubscription = batchController
        .watchAllBatches(includeConsumed: false)
        .listen(
      (batches) {
        if (mounted) {
          _allBatches = batches;
          _rebuildGroupedProducts();
        }
      },
      onError: (e) {
        print('[ERROR] Batch stream error: $e');
      },
    );
  }

  /// Rebuild grouped product list from batches + products
  void _rebuildGroupedProducts() {
    // Products with no batches
    final batchProductIds = _allBatches.map((b) => b.productId).toSet();
    final productsWithoutBatches = _products.where(
      (p) => !batchProductIds.contains(p.id),
    ).toList();

    _groupedProducts = GroupedProduct.buildFromBatches(
      _allBatches,
      productsWithoutBatches: productsWithoutBatches,
    );

    _applyGroupedFilters();
    if (mounted) setState(() {});
  }

  void _applyGroupedFilters() {
    _filteredGroupedProducts = _groupedProducts.where((group) {
      // Search filter
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final nameMatch = group.productName.toLowerCase().contains(query);
        final companyMatch = group.companies.any(
          (c) => c.toLowerCase().contains(query),
        );
        if (!nameMatch && !companyMatch) return false;
      }

      // Stock filter
      switch (_stockFilter) {
        case 'in_stock':
          return group.totalStock > 10;
        case 'low_stock':
          return group.totalStock > 0 && group.totalStock <= 10;
        case 'out_of_stock':
          return group.totalStock == 0;
        default:
          return true;
      }
    }).toList();

    // Sort: critical first
    _filteredGroupedProducts.sort((a, b) {
      if (a.totalStock == 0 && b.totalStock > 0) return -1;
      if (b.totalStock == 0 && a.totalStock > 0) return 1;
      if (a.totalStock <= 10 && b.totalStock > 10) return -1;
      if (b.totalStock <= 10 && a.totalStock > 10) return 1;
      return a.productName.compareTo(b.productName);
    });
  }
  
  void _onProductsChanged() {
    if (mounted) _loadProducts();
  }

  void _onLanguageChanged() {
    if (mounted) {
      setState(() {
        _localizations = AppLocalizations.of(LanguageService.instance.currentLanguage);
      });
    }
  }

  @override
  void dispose() {
    _productRefreshSubscription?.cancel();
    _purchaseRefreshSubscription?.cancel();
    _batchStreamSubscription?.cancel();
    ProductOfflineController.instance.removeListener(_onProductsChanged);
    LanguageService.instance.removeListener(_onLanguageChanged);
    _searchController.dispose();
    super.dispose();
  }

  final _reportService = InventoryReportService();

  void _showReportBottomSheet() {
    Set<ReportType> selectedTypes = {ReportType.outOfStock};
    ReportFormat selectedFormat = ReportFormat.pdf;

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
                        color: const Color(0xFF1B4D3E).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.description_outlined,
                        color: Color(0xFF1B4D3E),
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _localizations.generateReport,
                            style: const TextStyle(
                              fontFamily: 'Literata',
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1B4D3E),
                            ),
                          ),
                          Text(
                            _localizations.exportInventory,
                            style: const TextStyle(
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
                    Text(
                      _localizations.reportType,
                      style: const TextStyle(
                        fontFamily: 'Literata',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1B4D3E),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _localizations.selectReportTypes,
                      style: TextStyle(
                        fontFamily: 'Literata',
                        fontSize: 11,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildReportTypeCheckbox(
                      _localizations.outOfStockProducts,
                      _localizations.productsWithZero,
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
                      _localizations.lowStockProducts,
                      _localizations.productsWithLow,
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
                      _localizations.allProducts,
                      _localizations.completeInventory,
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
                    Text(
                      _localizations.exportFormat,
                      style: const TextStyle(
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
                    onPressed: selectedTypes.isEmpty
                        ? null
                        : () async {
                            Navigator.pop(context);
                            await _openPreviewScreen(
                              selectedTypes,
                              selectedFormat,
                            );
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1B4D3E),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.preview, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Preview & Generate',
                          style: const TextStyle(
                            fontFamily: 'Literata',
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
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
              ? const Color(0xFF1B4D3E).withValues(alpha: 0.1)
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
                color: iconColor.withValues(alpha: 0.1),
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
          color: isSelected ? color.withValues(alpha: 0.1) : Colors.grey[50],
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

  Future<void> _openPreviewScreen(
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

      // Convert to ReportItems
      final reportItems = combinedProducts
          .map((product) => ReportItem.fromProduct(product))
          .toList();

      // Generate combined report title
      final typeLabels = reportTypes
          .map((t) => _reportService.getReportTypeLabel(t))
          .join(', ');

      final reportTitle = reportTypes.length == 1
          ? _reportService.getReportTypeLabel(reportTypes.first)
          : 'Combined Report: $typeLabels';

      // Navigate to preview screen
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ReportPreviewScreen(
            reportItems: reportItems,
            reportType: reportTypes.length == 1
                ? reportTypes.first
                : ReportType.allProducts,
            selectedFormat: format,
            reportTitle: reportTitle,
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening preview: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _loadProducts() async {
    try {
      setState(() => _isLoading = true);
      
      // Load products from offline-first Isar storage
      final productEntities = await ProductOfflineController.instance.getAllProducts();
      
      // Convert ProductEntity to Product domain model
      final products = productEntities
          .map((entity) => Product.fromProductEntity(entity))
          .toList();
      
      if (mounted) {
        setState(() {
          _products = products;
          _applyFilters();
          _rebuildGroupedProducts();
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
      _applyGroupedFilters();
    });
  }

  void _onStockFilterChanged(String filter) {
    setState(() {
      _stockFilter = filter;
      _applyFilters();
      _applyGroupedFilters();
    });
  }

  Widget _buildStatsCards() {
    final totalProducts = _groupedProducts.length;
    final totalBatches = _allBatches.length;
    final inStock = _groupedProducts.where((g) => g.totalStock > 10).length;
    final lowStock = _groupedProducts
        .where((g) => g.totalStock > 0 && g.totalStock <= 10)
        .length;
    final outOfStock = _groupedProducts.where((g) => g.totalStock == 0).length;
    // Count batches with low stock (<=5 qty remaining)
    final lowBatches = _allBatches.where((b) => b.quantityRemaining > 0 && b.quantityRemaining <= 5).length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  title: _localizations.totalProducts,
                  value: totalProducts,
                  icon: Icons.inventory_2_rounded,
                  iconColor: const Color(0xFF1B4D3E),
                  backgroundColor: const Color(0xFF1B4D3E).withValues(alpha: 0.08),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatCard(
                  title: _localizations.inStock,
                  value: inStock,
                  icon: Icons.check_circle_rounded,
                  iconColor: Colors.green,
                  backgroundColor: Colors.green.withValues(alpha: 0.08),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatCard(
                  title: _localizations.lowStock,
                  value: lowStock,
                  icon: Icons.warning_rounded,
                  iconColor: Colors.orange,
                  backgroundColor: Colors.orange.withValues(alpha: 0.08),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatCard(
                  title: _localizations.outOfStock,
                  value: outOfStock,
                  icon: Icons.error_rounded,
                  iconColor: Colors.red,
                  backgroundColor: Colors.red.withValues(alpha: 0.08),
                ),
              ),
            ],
          ),
          if (totalBatches > 0 || lowBatches > 0) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: lowBatches > 0
                    ? Colors.orange.withValues(alpha: 0.06)
                    : const Color(0xFF1B4D3E).withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: lowBatches > 0
                      ? Colors.orange.withValues(alpha: 0.2)
                      : Colors.grey.withValues(alpha: 0.1),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.layers_rounded,
                    size: 16,
                    color: const Color(0xFF1B4D3E).withValues(alpha: 0.7),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '$totalBatches ${_localizations.batch}',
                    style: const TextStyle(
                      fontFamily: 'Literata',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1B4D3E),
                    ),
                  ),
                  if (lowBatches > 0) ...[
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.warning_amber_rounded, size: 13, color: Colors.orange),
                          const SizedBox(width: 4),
                          Text(
                            '$lowBatches ${_localizations.lowStock}',
                            style: const TextStyle(
                              fontFamily: 'Literata',
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.orange,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
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
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: iconColor.withValues(alpha: 0.12),
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: iconColor, size: 18),
          const SizedBox(height: 6),
          Text(
            value.toString(),
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              fontFamily: 'Literata',
              color: iconColor,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            title,
            style: TextStyle(
              fontSize: 9,
              color: Colors.grey[700],
              fontFamily: 'Literata',
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
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
              hintText: _localizations.searchProducts,
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
                _buildFilterChip(_localizations.all, 'all'),
                const SizedBox(width: 8),
                _buildFilterChip(_localizations.inStock, 'in_stock'),
                const SizedBox(width: 8),
                _buildFilterChip(_localizations.lowStock, 'low_stock'),
                const SizedBox(width: 8),
                _buildFilterChip(_localizations.outOfStock, 'out_of_stock'),
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
    if (_filteredGroupedProducts.isEmpty) {
      return Expanded(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.inventory_2_outlined,
                  size: 56,
                  color: Colors.grey[400],
                ),
              ),
              const SizedBox(height: 20),
              Text(
                _searchQuery.isEmpty
                    ? _localizations.noProductsFound
                    : _localizations.noProductsMatch,
                style: TextStyle(
                  fontSize: 17,
                  color: Colors.grey[600],
                  fontFamily: 'Literata',
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Expanded(
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        itemCount: _filteredGroupedProducts.length,
        itemBuilder: (context, index) {
          final group = _filteredGroupedProducts[index];
          return _buildGroupedProductCard(group);
        },
      ),
    );
  }

  Widget _buildGroupedProductCard(GroupedProduct group) {
    final stockLevel = _getStockLevel(group.totalStock);
    final stockColor = stockLevel['color'] as Color;
    final stockLabel = stockLevel['label'] as String;
    final hasMultipleBatches = group.hasMultipleVariants;
    // Count low-stock batches in this group
    final lowBatchCount = group.subEntries.where((e) => e.stockQuantity > 0 && e.stockQuantity <= 5).length;
    final outBatchCount = group.subEntries.where((e) => e.stockQuantity == 0).length;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: group.totalStock == 0
              ? Colors.red.withValues(alpha: 0.25)
              : group.totalStock <= 10
                  ? Colors.orange.withValues(alpha: 0.2)
                  : Colors.grey.withValues(alpha: 0.1),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          childrenPadding: EdgeInsets.zero,
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          collapsedShape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          leading: Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  stockColor,
                  stockColor.withValues(alpha: 0.7),
                ],
              ),
              borderRadius: BorderRadius.circular(13),
              boxShadow: [
                BoxShadow(
                  color: stockColor.withValues(alpha: 0.25),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Center(
              child: Text(
                '${group.totalStock}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  fontFamily: 'Literata',
                ),
              ),
            ),
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  group.productName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Literata',
                    color: Color(0xFF1B4D3E),
                    height: 1.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                // Stock status badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: stockColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: stockColor.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Text(
                    stockLabel,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: stockColor,
                      fontFamily: 'Literata',
                    ),
                  ),
                ),
                // Batch count badge
                if (hasMultipleBatches)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.blue.withValues(alpha: 0.15),
                      ),
                    ),
                    child: Text(
                      '${group.variantCount} ${_localizations.batch}',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Colors.blue[700],
                        fontFamily: 'Literata',
                      ),
                    ),
                  ),
                // Low batch warning badge
                if (lowBatchCount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.orange.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.warning_amber_rounded, size: 11, color: Colors.orange),
                        const SizedBox(width: 3),
                        Text(
                          '$lowBatchCount ${_localizations.lowStock}',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Colors.orange,
                            fontFamily: 'Literata',
                          ),
                        ),
                      ],
                    ),
                  ),
                // Out of stock batch badge
                if (outBatchCount > 0 && group.totalStock > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.red.withValues(alpha: 0.15),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline, size: 11, color: Colors.red),
                        const SizedBox(width: 3),
                        Text(
                          '$outBatchCount empty',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Colors.red,
                            fontFamily: 'Literata',
                          ),
                        ),
                      ],
                    ),
                  ),
                // Company names
                if (group.companies.isNotEmpty)
                  Text(
                    group.companies.join(', '),
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[500],
                      fontFamily: 'Literata',
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          children: [
            // Summary bar with stock value & price range
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: const Color(0xFF1B4D3E).withValues(alpha: 0.04),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildInfoChip(
                    Icons.shopping_cart_outlined,
                    group.purchasePriceRange,
                    'Purchase',
                  ),
                  Container(
                    width: 1,
                    height: 28,
                    color: Colors.grey.withValues(alpha: 0.2),
                  ),
                  _buildInfoChip(
                    Icons.sell_outlined,
                    group.salesPriceRange,
                    'Sell',
                  ),
                  Container(
                    width: 1,
                    height: 28,
                    color: Colors.grey.withValues(alpha: 0.2),
                  ),
                  _buildInfoChip(
                    Icons.account_balance_wallet_outlined,
                    '₹${group.totalStockValue.toStringAsFixed(0)}',
                    _localizations.stockValue,
                  ),
                ],
              ),
            ),
            // Batch header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                border: Border(
                  bottom: BorderSide(color: Colors.grey[300]!),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Text(
                      _localizations.company,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Literata',
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      _localizations.date,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Literata',
                        color: Colors.grey[700],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      '${_localizations.sellPrice} ₹',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Literata',
                        color: Colors.grey[700],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const Expanded(
                    flex: 2,
                    child: Text(
                      'Qty',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Literata',
                        color: Color(0xFF1B4D3E),
                      ),
                      textAlign: TextAlign.end,
                    ),
                  ),
                ],
              ),
            ),
            // Batch rows
            ...group.subEntries.asMap().entries.map((mapEntry) {
              final i = mapEntry.key;
              final entry = mapEntry.value;
              final isEven = i % 2 == 0;
              final isLowBatch = entry.stockQuantity > 0 && entry.stockQuantity <= 5;
              final isOutBatch = entry.stockQuantity == 0;

              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isOutBatch
                      ? Colors.red.withValues(alpha: 0.04)
                      : isLowBatch
                          ? Colors.orange.withValues(alpha: 0.04)
                          : isEven
                              ? Colors.white
                              : Colors.grey[50],
                  border: Border(
                    bottom: BorderSide(
                      color: Colors.grey.withValues(alpha: 0.12),
                      width: 0.5,
                    ),
                    left: BorderSide(
                      color: isOutBatch
                          ? Colors.red
                          : isLowBatch
                              ? Colors.orange
                              : Colors.transparent,
                      width: isOutBatch || isLowBatch ? 3 : 0,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            entry.companyName.isNotEmpty ? entry.companyName : '—',
                            style: const TextStyle(
                              fontSize: 12,
                              fontFamily: 'Literata',
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (isLowBatch || isOutBatch)
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    isOutBatch ? Icons.error_outline : Icons.warning_amber_rounded,
                                    size: 10,
                                    color: isOutBatch ? Colors.red : Colors.orange,
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    isOutBatch ? _localizations.outOfStock : _localizations.lowStock,
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w600,
                                      fontFamily: 'Literata',
                                      color: isOutBatch ? Colors.red : Colors.orange,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        entry.formattedDate,
                        style: TextStyle(
                          fontSize: 11,
                          fontFamily: 'Literata',
                          color: Colors.grey[700],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        '₹${entry.salesPrice.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 12,
                          fontFamily: 'Literata',
                          fontWeight: FontWeight.w600,
                          color: Colors.green[700],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (isLowBatch || isOutBatch)
                            Container(
                              width: 6,
                              height: 6,
                              margin: const EdgeInsets.only(right: 5),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isOutBatch ? Colors.red : Colors.orange,
                              ),
                            ),
                          Text(
                            '${entry.stockQuantity}',
                            style: TextStyle(
                              fontSize: 13,
                              fontFamily: 'Literata',
                              fontWeight: FontWeight.w800,
                              color: isOutBatch
                                  ? Colors.red
                                  : isLowBatch
                                      ? Colors.orange
                                      : Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
            // Low stock alert banner at bottom of expanded card
            if (group.totalStock == 0)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.06),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(15),
                    bottomRight: Radius.circular(15),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _localizations.outOfStockMessage,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.red[700],
                          fontFamily: 'Literata',
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else if (group.totalStock <= 10)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.06),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(15),
                    bottomRight: Radius.circular(15),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _localizations.lowStockMessage,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.orange[700],
                          fontFamily: 'Literata',
                          fontWeight: FontWeight.w500,
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
  }

  Widget _buildInfoChip(IconData icon, String value, String label) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: const Color(0xFF1B4D3E)),
            const SizedBox(width: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                fontFamily: 'Literata',
                color: Color(0xFF1B4D3E),
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontFamily: 'Literata',
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Map<String, dynamic> _getStockLevel(int stock) {
    if (stock == 0) {
      return {'label': _localizations.outOfStock.toUpperCase(), 'color': Colors.red};
    } else if (stock <= 10) {
      return {'label': _localizations.lowStock.toUpperCase(), 'color': Colors.orange};
    } else {
      return {'label': _localizations.inStock.toUpperCase(), 'color': Colors.green};
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
          Text(
            _localizations.stockOverview,
            style: const TextStyle(
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
                color: const Color(0xFF1B4D3E).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.summarize_outlined,
                color: Color(0xFF1B4D3E),
                size: 20,
              ),
            ),
            tooltip: _localizations.generateReport,
          ),
        ],
      ),
    );
  }
}

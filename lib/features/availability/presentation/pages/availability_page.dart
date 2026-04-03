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
import 'package:c_billing/core/ui/glassy_toast.dart';

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
  String _stockFilter =
      'all'; // all, in_stock, low_stock, out_of_stock, expired

  // Batch-level data for grouped view
  List<PurchaseBatchEntity> _allBatches = [];
  List<GroupedProduct> _groupedProducts = [];
  List<GroupedProduct> _filteredGroupedProducts = [];
  StreamSubscription<List<PurchaseBatchEntity>>? _batchStreamSubscription;

  @override
  void initState() {
    super.initState();
    _localizations = AppLocalizations.of(
      LanguageService.instance.currentLanguage,
    );

    // Listen for language changes
    LanguageService.instance.addListener(_onLanguageChanged);

    // Listen for product changes from other screens (purchase page, product management, etc.)
    _productRefreshSubscription = DashboardRefreshService
        .instance
        .onProductChanged
        .listen((_) {
          if (mounted) _loadProducts();
        });

    // Also listen for purchase changes which affect stock
    _purchaseRefreshSubscription = DashboardRefreshService
        .instance
        .onPurchaseChanged
        .listen((_) {
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
    final productsWithoutBatches = _products
        .where((p) => !batchProductIds.contains(p.id))
        .toList();

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
        case 'expired':
          return group.hasExpiredStock;
        default:
          return true;
      }
    }).toList();

    // Sort: critical first (expired, then out of stock, then low stock)
    _filteredGroupedProducts.sort((a, b) {
      // Expired products first
      if (a.hasExpiredStock && !b.hasExpiredStock) return -1;
      if (b.hasExpiredStock && !a.hasExpiredStock) return 1;
      // Then out of stock
      if (a.totalStock == 0 && b.totalStock > 0) return -1;
      if (b.totalStock == 0 && a.totalStock > 0) return 1;
      // Then low stock
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
        _localizations = AppLocalizations.of(
          LanguageService.instance.currentLanguage,
        );
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

  void _showReportBottomSheet() {
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
              // Filter info banner
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF1B4D3E).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF1B4D3E).withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _getFilterIcon(),
                      color: const Color(0xFF1B4D3E),
                      size: 22,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${_localizations.exporting} ${_getFilterLabel()}',
                            style: const TextStyle(
                              fontFamily: 'Literata',
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1B4D3E),
                            ),
                          ),
                          Text(
                            '${_filteredGroupedProducts.length} ${_localizations.productsWillBeIncluded}',
                            style: TextStyle(
                              fontFamily: 'Literata',
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
                    onPressed: _filteredGroupedProducts.isEmpty
                        ? null
                        : () async {
                            Navigator.pop(context);
                            await _openPreviewScreen(selectedFormat);
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
                          _localizations.previewAndGenerate,
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

  Future<void> _openPreviewScreen(ReportFormat format) async {
    try {
      if (_filteredGroupedProducts.isEmpty) {
        GlassyToast.show(context, _localizations.noProductsForFilter);
        return;
      }

      // Convert GroupedProducts to Products for ReportItems
      final List<Product> productsForReport = [];
      for (final group in _filteredGroupedProducts) {
        // Use the first sub-entry to create a Product representation
        if (group.subEntries.isNotEmpty) {
          final firstEntry = group.subEntries.first;
          productsForReport.add(
            Product(
              id: firstEntry.productId,
              indexNo: 0,
              name: group.productName,
              companyName: group.companies.isNotEmpty
                  ? group.companies.first
                  : '',
              category: '',
              purchasePrice: group.minPurchasePrice,
              salesPrice: group.minSalesPrice,
              currentStock: group.totalStock,
              createdAt: firstEntry.purchaseDate,
              updatedAt: firstEntry.purchaseDate,
              defaultSupplierName: firstEntry.supplierName,
            ),
          );
        }
      }

      // Convert to ReportItems
      final reportItems = productsForReport
          .map((product) => ReportItem.fromProduct(product))
          .toList();

      // Generate report title based on current filter
      final reportTitle = '${_getFilterLabel()} Report';

      // Determine report type based on filter
      ReportType reportType;
      switch (_stockFilter) {
        case 'out_of_stock':
          reportType = ReportType.outOfStock;
          break;
        case 'low_stock':
          reportType = ReportType.lowStock;
          break;
        default:
          reportType = ReportType.allProducts;
      }

      // Navigate to preview screen
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ReportPreviewScreen(
            reportItems: reportItems,
            reportType: reportType,
            selectedFormat: format,
            reportTitle: reportTitle,
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        GlassyToast.show(context, '${_localizations.errorOpeningPreview}: $e', isError: true);
      }
    }
  }

  String _getFilterLabel() {
    switch (_stockFilter) {
      case 'in_stock':
        return _localizations.inStock;
      case 'low_stock':
        return _localizations.lowStock;
      case 'out_of_stock':
        return _localizations.outOfStock;
      case 'expired':
        return _localizations.expiredProducts;
      default:
        return _localizations.allProducts;
    }
  }

  IconData _getFilterIcon() {
    switch (_stockFilter) {
      case 'in_stock':
        return Icons.check_circle_rounded;
      case 'low_stock':
        return Icons.warning_rounded;
      case 'out_of_stock':
        return Icons.error_rounded;
      case 'expired':
        return Icons.event_busy_rounded;
      default:
        return Icons.inventory_2_rounded;
    }
  }

  Future<void> _loadProducts() async {
    try {
      setState(() => _isLoading = true);

      // Load products from offline-first Isar storage
      final productEntities = await ProductOfflineController.instance
          .getAllProducts();

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
        GlassyToast.show(context, 'Error loading products: $e');
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
    final inStock = _groupedProducts.where((g) => g.totalStock > 10).length;
    final lowStock = _groupedProducts
        .where((g) => g.totalStock > 0 && g.totalStock <= 10)
        .length;
    final outOfStock = _groupedProducts.where((g) => g.totalStock == 0).length;
    final expired = _groupedProducts.where((g) => g.hasExpiredStock).length;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: constraints.maxWidth),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildModernStatCard(
                    title: _localizations.totalProducts,
                    value: totalProducts,
                    icon: Icons.inventory_2_rounded,
                    gradient: const [Color(0xFF1B4D3E), Color(0xFF2D6B5A)],
                    isActive: _stockFilter == 'all',
                    onTap: () => _onStockFilterChanged('all'),
                  ),
                  const SizedBox(width: 10),
                  _buildModernStatCard(
                    title: _localizations.inStock,
                    value: inStock,
                    icon: Icons.check_circle_rounded,
                    gradient: const [Color(0xFF4CAF50), Color(0xFF66BB6A)],
                    isActive: _stockFilter == 'in_stock',
                    onTap: () => _onStockFilterChanged('in_stock'),
                  ),
                  const SizedBox(width: 10),
                  _buildModernStatCard(
                    title: _localizations.lowStock,
                    value: lowStock,
                    icon: Icons.warning_rounded,
                    gradient: const [Color(0xFFFF9800), Color(0xFFFFB74D)],
                    isActive: _stockFilter == 'low_stock',
                    onTap: () => _onStockFilterChanged('low_stock'),
                  ),
                  const SizedBox(width: 10),
                  _buildModernStatCard(
                    title: _localizations.outOfStock,
                    value: outOfStock,
                    icon: Icons.error_rounded,
                    gradient: const [Color(0xFFF44336), Color(0xFFEF5350)],
                    isActive: _stockFilter == 'out_of_stock',
                    onTap: () => _onStockFilterChanged('out_of_stock'),
                  ),
                  const SizedBox(width: 10),
                  _buildModernStatCard(
                    title: _localizations.expiredProducts,
                    value: expired,
                    icon: Icons.event_busy_rounded,
                    gradient: const [Color(0xFF9C27B0), Color(0xFFBA68C8)],
                    isActive: _stockFilter == 'expired',
                    onTap: () => _onStockFilterChanged('expired'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildModernStatCard({
    required String title,
    required int value,
    required IconData icon,
    required List<Color> gradient,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 72,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          gradient: isActive
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: gradient,
                )
              : null,
          color: isActive ? null : Colors.grey[50],
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isActive
                ? Colors.transparent
                : gradient[0].withValues(alpha: 0.2),
            width: 1.5,
          ),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: gradient[0].withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Column(
          children: [
            Icon(icon, color: isActive ? Colors.white : gradient[0], size: 20),
            const SizedBox(height: 8),
            Text(
              value.toString(),
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                fontFamily: 'Literata',
                color: isActive ? Colors.white : gradient[0],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 9,
                color: isActive
                    ? Colors.white.withValues(alpha: 0.85)
                    : Colors.grey[600],
                fontFamily: 'Literata',
                fontWeight: FontWeight.w600,
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
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        children: [
          // Search bar with modern styling
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              style: const TextStyle(fontFamily: 'Literata', fontSize: 14),
              decoration: InputDecoration(
                hintText: _localizations.searchProducts,
                hintStyle: TextStyle(
                  color: Colors.grey[400],
                  fontFamily: 'Literata',
                ),
                prefixIcon: Container(
                  padding: const EdgeInsets.all(12),
                  child: Icon(
                    Icons.search_rounded,
                    color: _searchQuery.isNotEmpty
                        ? const Color(0xFF1B4D3E)
                        : Colors.grey[400],
                  ),
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            size: 16,
                            color: Colors.grey,
                          ),
                        ),
                        onPressed: () {
                          _searchController.clear();
                          _onSearchChanged('');
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: Colors.grey.withValues(alpha: 0.1),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(
                    color: Color(0xFF1B4D3E),
                    width: 1.5,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Result count and sort info
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF1B4D3E).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.list_alt_rounded,
                      size: 14,
                      color: Color(0xFF1B4D3E),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${_filteredGroupedProducts.length} items',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Literata',
                        color: Color(0xFF1B4D3E),
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              if (_stockFilter != 'all')
                GestureDetector(
                  onTap: () => _onStockFilterChanged('all'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.filter_alt_off_rounded,
                          size: 14,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _localizations.clearFilter,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            fontFamily: 'Literata',
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProductsSliver() {
    if (_filteredGroupedProducts.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.inventory_2_outlined,
                  size: 64,
                  color: Colors.grey[400],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                _searchQuery.isEmpty
                    ? _localizations.noProductsFound
                    : _localizations.noProductsMatch,
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey[600],
                  fontFamily: 'Literata',
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _searchQuery.isEmpty
                    ? _localizations.addProductsToSeeInventory
                    : _localizations.tryDifferentSearchTerm,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[400],
                  fontFamily: 'Literata',
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          final group = _filteredGroupedProducts[index];
          return _buildGroupedProductCard(group);
        }, childCount: _filteredGroupedProducts.length),
      ),
    );
  }

  Widget _buildGroupedProductCard(GroupedProduct group) {
    final stockLevel = _getStockLevel(group.totalStock);
    final stockColor = stockLevel['color'] as Color;
    final stockLabel = stockLevel['label'] as String;
    final hasMultipleBatches = group.hasMultipleVariants;
    // Count low-stock batches in this group
    final lowBatchCount = group.subEntries
        .where((e) => e.stockQuantity > 0 && e.stockQuantity <= 5)
        .length;
    final outBatchCount = group.subEntries
        .where((e) => e.stockQuantity == 0)
        .length;
    final expiredBatchCount = group.expiredBatchCount;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: group.hasExpiredStock
              ? const Color(0xFF9C27B0).withValues(alpha: 0.25)
              : group.totalStock == 0
              ? Colors.red.withValues(alpha: 0.2)
              : group.totalStock <= 10
              ? Colors.orange.withValues(alpha: 0.15)
              : Colors.transparent,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          childrenPadding: EdgeInsets.zero,
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          collapsedShape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.zero,
          ),
          leading: Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [stockColor, stockColor.withValues(alpha: 0.75)],
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: stockColor.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${group.totalStock}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'Literata',
                    height: 1,
                  ),
                ),
                Text(
                  _localizations.units,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 8,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Literata',
                  ),
                ),
              ],
            ),
          ),
          title: Text(
            group.productName,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              fontFamily: 'Literata',
              color: Color(0xFF1B4D3E),
              height: 1.2,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Badges row
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    // Stock status badge
                    _buildBadge(
                      label: stockLabel,
                      color: stockColor,
                      icon: group.totalStock == 0
                          ? Icons.error_outline
                          : group.totalStock <= 10
                          ? Icons.warning_outlined
                          : Icons.check_circle_outline,
                    ),
                    // Batch count badge
                    if (hasMultipleBatches)
                      _buildBadge(
                        label: '${group.variantCount} ${_localizations.batch}',
                        color: const Color(0xFF2196F3),
                        icon: Icons.layers_outlined,
                      ),
                    // Low batch warning badge
                    if (lowBatchCount > 0)
                      _buildBadge(
                        label: '$lowBatchCount ${_localizations.lowStock}',
                        color: Colors.orange,
                        icon: Icons.warning_amber_rounded,
                      ),
                    // Out of stock batch badge
                    if (outBatchCount > 0 && group.totalStock > 0)
                      _buildBadge(
                        label: '$outBatchCount ${_localizations.emptyBatch}',
                        color: Colors.red,
                        icon: Icons.error_outline,
                      ),
                    // Expired batch badge
                    if (expiredBatchCount > 0)
                      _buildBadge(
                        label:
                            '$expiredBatchCount ${_localizations.expired.toLowerCase()}',
                        color: const Color(0xFF9C27B0),
                        icon: Icons.event_busy_rounded,
                      ),
                  ],
                ),
                // Company names
                if (group.companies.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        Icons.business_outlined,
                        size: 12,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          group.companies.join(' • '),
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[500],
                            fontFamily: 'Literata',
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          children: [
            // Summary bar with stock value & price range
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF1B4D3E).withValues(alpha: 0.06),
                    const Color(0xFF1B4D3E).withValues(alpha: 0.02),
                  ],
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildInfoChip(
                    Icons.shopping_cart_outlined,
                    group.purchasePriceRange,
                    _localizations.purchase,
                  ),
                  Container(
                    width: 1,
                    height: 32,
                    color: Colors.grey.withValues(alpha: 0.15),
                  ),
                  _buildInfoChip(
                    Icons.sell_outlined,
                    group.salesPriceRange,
                    _localizations.sell,
                  ),
                  Container(
                    width: 1,
                    height: 32,
                    color: Colors.grey.withValues(alpha: 0.15),
                  ),
                  _buildInfoChip(
                    Icons.account_balance_wallet_outlined,
                    '₹${_formatCompactNumber(group.totalStockValue)}',
                    _localizations.stockValue,
                  ),
                ],
              ),
            ),
            // Batch header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Text(
                      _localizations.company,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Literata',
                        color: Colors.grey[600],
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      _localizations.date,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Literata',
                        color: Colors.grey[600],
                        letterSpacing: 0.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      '${_localizations.sellPrice} ₹',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Literata',
                        color: Colors.grey[600],
                        letterSpacing: 0.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      _localizations.qty,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Literata',
                        color: Color(0xFF1B4D3E),
                        letterSpacing: 0.5,
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
              final isLowBatch =
                  entry.stockQuantity > 0 && entry.stockQuantity <= 5;
              final isOutBatch = entry.stockQuantity == 0;
              final isExpired = entry.isExpired;
              final isExpiringSoon = entry.isExpiringSoon;

              // Determine color priority: expired > out > low
              Color? rowColor;
              Color? borderColor;
              if (isExpired) {
                rowColor = const Color(0xFF9C27B0).withValues(alpha: 0.06);
                borderColor = const Color(0xFF9C27B0);
              } else if (isOutBatch) {
                rowColor = Colors.red.withValues(alpha: 0.04);
                borderColor = Colors.red;
              } else if (isLowBatch) {
                rowColor = Colors.orange.withValues(alpha: 0.04);
                borderColor = Colors.orange;
              }

              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: rowColor ?? (isEven ? Colors.white : Colors.grey[50]),
                  border: Border(
                    bottom: BorderSide(
                      color: Colors.grey.withValues(alpha: 0.1),
                      width: 0.5,
                    ),
                    left: BorderSide(
                      color: borderColor ?? Colors.transparent,
                      width: borderColor != null ? 3 : 0,
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
                            entry.companyName.isNotEmpty
                                ? entry.companyName
                                : '—',
                            style: const TextStyle(
                              fontSize: 12,
                              fontFamily: 'Literata',
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          // Status badges (can show multiple)
                          if (isExpired ||
                              isExpiringSoon ||
                              isLowBatch ||
                              isOutBatch)
                            Padding(
                              padding: const EdgeInsets.only(top: 3),
                              child: Wrap(
                                spacing: 4,
                                runSpacing: 4,
                                children: [
                                  if (isExpired)
                                    _buildMicroBadge(
                                      label: _localizations.expired,
                                      color: const Color(0xFF9C27B0),
                                      icon: Icons.event_busy_rounded,
                                    ),
                                  if (isExpiringSoon && !isExpired)
                                    _buildMicroBadge(
                                      label: _localizations.expiringSoon,
                                      color: const Color(0xFFFF5722),
                                      icon: Icons.schedule,
                                    ),
                                  if (isOutBatch)
                                    _buildMicroBadge(
                                      label: _localizations.outOfStock,
                                      color: Colors.red,
                                      icon: Icons.error_outline,
                                    ),
                                  if (isLowBatch && !isOutBatch)
                                    _buildMicroBadge(
                                      label: _localizations.lowStock,
                                      color: Colors.orange,
                                      icon: Icons.warning_amber_rounded,
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
                          color: Colors.grey[600],
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
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: isExpired
                                  ? const Color(
                                      0xFF9C27B0,
                                    ).withValues(alpha: 0.1)
                                  : isOutBatch
                                  ? Colors.red.withValues(alpha: 0.1)
                                  : isLowBatch
                                  ? Colors.orange.withValues(alpha: 0.1)
                                  : const Color(
                                      0xFF1B4D3E,
                                    ).withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${entry.stockQuantity}',
                              style: TextStyle(
                                fontSize: 13,
                                fontFamily: 'Literata',
                                fontWeight: FontWeight.w800,
                                color: isExpired
                                    ? const Color(0xFF9C27B0)
                                    : isOutBatch
                                    ? Colors.red
                                    : isLowBatch
                                    ? Colors.orange
                                    : const Color(0xFF1B4D3E),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
            // Alert banner at bottom
            if (group.hasExpiredStock)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF9C27B0).withValues(alpha: 0.08),
                      const Color(0xFF9C27B0).withValues(alpha: 0.04),
                    ],
                  ),
                  borderRadius: group.totalStock == 0 || group.totalStock <= 10
                      ? BorderRadius.zero
                      : const BorderRadius.only(
                          bottomLeft: Radius.circular(17),
                          bottomRight: Radius.circular(17),
                        ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF9C27B0).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.event_busy_rounded,
                        color: Color(0xFF9C27B0),
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '${group.expiredBatchCount} ${_localizations.batch}${group.expiredBatchCount > 1 ? 's' : ''} ${_localizations.batchExpiredRemove}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF7B1FA2),
                          fontFamily: 'Literata',
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            if (group.totalStock == 0)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.red.withValues(alpha: 0.08),
                      Colors.red.withValues(alpha: 0.04),
                    ],
                  ),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(17),
                    bottomRight: Radius.circular(17),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.error_outline,
                        color: Colors.red,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _localizations.outOfStockMessage,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.red[700],
                          fontFamily: 'Literata',
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else if (group.totalStock <= 10 && !group.hasExpiredStock)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.orange.withValues(alpha: 0.08),
                      Colors.orange.withValues(alpha: 0.04),
                    ],
                  ),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(17),
                    bottomRight: Radius.circular(17),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.warning_amber_rounded,
                        color: Colors.orange,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _localizations.lowStockMessage,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.orange[800],
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

  Widget _buildBadge({
    required String label,
    required Color color,
    IconData? icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 11, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: color,
              fontFamily: 'Literata',
            ),
          ),
        ],
      ),
    );
  }

  /// Smaller badge for batch row status indicators
  Widget _buildMicroBadge({
    required String label,
    required Color color,
    IconData? icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 9, color: color),
            const SizedBox(width: 3),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 8,
              fontWeight: FontWeight.w600,
              fontFamily: 'Literata',
              color: color,
            ),
          ),
        ],
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
            const SizedBox(width: 6),
            Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                fontFamily: 'Literata',
                color: Color(0xFF1B4D3E),
              ),
            ),
          ],
        ),
        const SizedBox(height: 3),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontFamily: 'Literata',
            color: Colors.grey[500],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Map<String, dynamic> _getStockLevel(int stock) {
    if (stock == 0) {
      return {
        'label': _localizations.outOfStock.toUpperCase(),
        'color': Colors.red,
      };
    } else if (stock <= 10) {
      return {
        'label': _localizations.lowStock.toUpperCase(),
        'color': Colors.orange,
      };
    } else {
      return {
        'label': _localizations.inStock.toUpperCase(),
        'color': Colors.green,
      };
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F6),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF1B4D3E)),
            )
          : CustomScrollView(
              slivers: [
                // Modern gradient header
                SliverToBoxAdapter(child: _buildPageHeader()),
                // Stats cards
                SliverToBoxAdapter(child: _buildStatsCards()),
                // Search and filters
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _SearchHeaderDelegate(
                    child: _buildSearchAndFilters(),
                    height: 120,
                  ),
                ),
                // Products list
                _buildProductsSliver(),
              ],
            ),
    );
  }

  /// Modern gradient header
  Widget _buildPageHeader() {
    final totalStock = _groupedProducts.fold<int>(
      0,
      (sum, g) => sum + g.totalStock,
    );
    final totalValue = _groupedProducts.fold<double>(
      0,
      (sum, g) => sum + g.totalStockValue,
    );

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1B4D3E), Color(0xFF0F3B2F)],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1B4D3E).withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          // Title row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.inventory_2_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _localizations.stockOverview,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Literata',
                      ),
                    ),
                    Text(
                      '${_groupedProducts.length} ${_localizations.products} • $totalStock ${_localizations.units}',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 12,
                        fontFamily: 'Literata',
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: _showReportBottomSheet,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.summarize_outlined,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Summary stats in header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildHeaderStat(
                    Icons.account_balance_wallet_rounded,
                    '₹${_formatCompactNumber(totalValue)}',
                    _localizations.stockValue,
                  ),
                ),
                Container(
                  width: 1,
                  height: 36,
                  color: Colors.white.withValues(alpha: 0.2),
                ),
                Expanded(
                  child: _buildHeaderStat(
                    Icons.layers_rounded,
                    '${_allBatches.length}',
                    _localizations.batch,
                  ),
                ),
                Container(
                  width: 1,
                  height: 36,
                  color: Colors.white.withValues(alpha: 0.2),
                ),
                Expanded(
                  child: _buildHeaderStat(
                    Icons.warning_amber_rounded,
                    '${_groupedProducts.where((g) => g.totalStock <= 10 && g.totalStock > 0).length}',
                    _localizations.lowStock,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderStat(IconData icon, String value, String label) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white.withValues(alpha: 0.8), size: 16),
            const SizedBox(width: 6),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w800,
                fontFamily: 'Literata',
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.6),
            fontSize: 10,
            fontFamily: 'Literata',
          ),
        ),
      ],
    );
  }

  String _formatCompactNumber(double number) {
    if (number >= 10000000) {
      return '${(number / 10000000).toStringAsFixed(1)}Cr';
    } else if (number >= 100000) {
      return '${(number / 100000).toStringAsFixed(1)}L';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toStringAsFixed(0);
  }
}

/// Delegate for sticky search header
class _SearchHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  final double height;

  _SearchHeaderDelegate({required this.child, required this.height});

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(color: const Color(0xFFF5F7F6), child: child);
  }

  @override
  double get maxExtent => height;

  @override
  double get minExtent => height;

  @override
  bool shouldRebuild(covariant _SearchHeaderDelegate oldDelegate) {
    return child != oldDelegate.child || height != oldDelegate.height;
  }
}

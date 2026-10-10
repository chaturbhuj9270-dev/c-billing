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
import 'package:c_billing/core/theme/app_theme.dart';

/// Lets the dashboard download button open the stock report.
class AvailabilityScreenActions {
  static final List<VoidCallback> _downloads = [];

  static void register(VoidCallback onDownload) => _downloads.add(onDownload);

  static void unregister(VoidCallback onDownload) =>
      _downloads.remove(onDownload);

  static void download() {
    if (_downloads.isEmpty) return;
    _downloads.last();
  }
}

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
    AvailabilityScreenActions.register(_showReportBottomSheet);

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
    AvailabilityScreenActions.unregister(_showReportBottomSheet);
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
          decoration: BoxDecoration(
            color: AppColors.card(context),
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
                padding: EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.accentSoft(context, 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.description_outlined,
                        color: AppColors.accent(context),
                        size: 22,
                      ),
                    ),
                    SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _localizations.generateReport,
                            style: TextStyle(
                              fontFamily: 'Literata',
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppColors.accent(context),
                            ),
                          ),
                          Text(
                            _localizations.exportInventory,
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
              Divider(height: 1),
              // Filter info banner
              Container(
                margin: EdgeInsets.all(16),
                padding: EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.accentSoft(context, 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.accentSoft(context, 0.2)),
                ),
                child: Row(
                  children: [
                    Icon(
                      _getFilterIcon(),
                      color: AppColors.accent(context),
                      size: 22,
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${_localizations.exporting} ${_getFilterLabel()}',
                            style: TextStyle(
                              fontFamily: 'Literata',
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.accent(context),
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
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _localizations.exportFormat,
                      style: TextStyle(
                        fontFamily: 'Literata',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.accent(context),
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
        padding: EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: 0.1)
              : AppColors.scaffold(context),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : AppColors.border(context)!,
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
        GlassyToast.show(
          context,
          '${_localizations.errorOpeningPreview}: $e',
          isError: true,
        );
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
    final isOut = group.totalStock == 0;
    final isLow = group.totalStock > 0 && group.totalStock <= 10;
    final tileBackground = isOut
        ? const Color(0xFF3A2424)
        : isLow
        ? const Color(0xFF3A2E14)
        : const Color(0xFF14352C);
    final tileForeground = isOut
        ? const Color(0xFFEF5350)
        : isLow
        ? AppTheme.toneAmber
        : AppTheme.mint;
    final statusLabel = isLow
        ? '${_localizations.lowStock.toUpperCase()} · ${group.variantCount} ${_localizations.batch.toUpperCase()}'
        : stockLevel['label'] as String;
    final expiredBatchCount = group.expiredBatchCount;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          childrenPadding: EdgeInsets.zero,
          iconColor: AppColors.mutedText(context),
          collapsedIconColor: AppColors.mutedText(context),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(18)),
          ),
          collapsedShape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(18)),
          ),
          leading: Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: tileBackground,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${group.totalStock}',
                  style: TextStyle(
                    color: tileForeground,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'Literata',
                    height: 1,
                  ),
                ),
                Text(
                  _localizations.units.toLowerCase(),
                  style: TextStyle(
                    color: tileForeground,
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Literata',
                  ),
                ),
              ],
            ),
          ),
          title: Text(
            group.productName,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              fontFamily: 'Literata',
              color: AppColors.primaryText(context),
              height: 1.2,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _buildBadge(
                      label: statusLabel,
                      color: isOut
                          ? const Color(0xFFEF5350)
                          : isLow
                          ? AppTheme.toneAmber
                          : AppTheme.mint,
                      icon: isOut
                          ? Icons.error_outline
                          : isLow
                          ? Icons.warning_amber_rounded
                          : Icons.check_circle_outline,
                    ),
                    if (expiredBatchCount > 0)
                      _buildBadge(
                        label:
                            '$expiredBatchCount ${_localizations.expired.toLowerCase()}',
                        color: const Color(0xFFB388FF),
                        icon: Icons.event_busy_rounded,
                      ),
                  ],
                ),
                if (group.companies.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        Icons.apartment_outlined,
                        size: 13,
                        color: AppColors.mutedText(context),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          group.companies.first,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.mutedText(context),
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
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.chipFill(context),
                border: Border(
                  bottom: BorderSide(color: AppColors.border(context)!),
                ),
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
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Literata',
                        color: AppColors.accent(context),
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
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color:
                      rowColor ??
                      (isEven ? Colors.white : AppColors.scaffold(context)),
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
            Icon(icon, size: 14, color: AppColors.accent(context)),
            SizedBox(width: 6),
            Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                fontFamily: 'Literata',
                color: AppColors.accent(context),
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
      backgroundColor: AppColors.scaffold(context),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: AppTheme.mint))
          : CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: _buildPageHeader()),
                SliverToBoxAdapter(child: _buildFilterChips()),
                SliverToBoxAdapter(child: _buildSearchField()),
                _buildProductsSliver(),
              ],
            ),
    );
  }

  Widget _buildPageHeader() {
    final totalStock = _groupedProducts.fold<int>(
      0,
      (sum, group) => sum + group.totalStock,
    );
    final totalValue = _groupedProducts.fold<double>(
      0,
      (sum, group) => sum + group.totalStockValue,
    );
    final lowStock = _groupedProducts
        .where((group) => group.totalStock > 0 && group.totalStock <= 10)
        .length;

    return Padding(
      padding: EdgeInsets.fromLTRB(16, widget.isEmbedded ? 8 : 16, 16, 4),
      child: _sectionCard(
            child: Column(
              children: [
                Row(
                  children: [
                    _iconWell(
                      icon: Icons.inventory_2_outlined,
                      background: const Color(0xFF14352C),
                      foreground: AppTheme.mint,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _localizations.stockOverview,
                            style: TextStyle(
                              fontFamily: 'Literata',
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                              color: AppColors.primaryText(context),
                            ),
                          ),
                          Text(
                            '${_groupedProducts.length} ${_localizations.products.toLowerCase()} · $totalStock ${_localizations.units.toLowerCase()}',
                            style: TextStyle(
                              fontFamily: 'Literata',
                              fontSize: 12,
                              color: AppColors.mutedText(context),
                            ),
                          ),
                        ],
                      ),
                    ),
                    _outlineIconButton(
                      icon: Icons.file_download_outlined,
                      onTap: _showReportBottomSheet,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _overviewStat(
                      '₹${_formatCompactNumber(totalValue)}',
                      _localizations.stockValue,
                      AppColors.primaryText(context),
                    ),
                    _overviewStat(
                      '${_allBatches.length}',
                      _localizations.batch,
                      AppColors.primaryText(context),
                    ),
                    _overviewStat(
                      '$lowStock',
                      _localizations.lowStock,
                      AppTheme.toneAmber,
                    ),
                  ],
                ),
              ],
            ),
          ),
    );
  }

  Widget _sectionCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: child,
    );
  }

  Widget _iconWell({
    required IconData icon,
    required Color background,
    required Color foreground,
  }) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(icon, color: foreground, size: 20),
    );
  }

  Widget _outlineIconButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border(context)),
          ),
          child: Icon(icon, size: 18, color: AppColors.secondaryText(context)),
        ),
      ),
    );
  }

  Widget _overviewStat(String value, String label, Color valueColor) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Literata',
              fontWeight: FontWeight.w800,
              fontSize: 20,
              color: valueColor,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Literata',
              fontSize: 11,
              color: AppColors.mutedText(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    final total = _groupedProducts.length;
    final inStock = _groupedProducts
        .where((group) => group.totalStock > 10)
        .length;
    final lowStock = _groupedProducts
        .where((group) => group.totalStock > 0 && group.totalStock <= 10)
        .length;
    final outOfStock = _groupedProducts
        .where((group) => group.totalStock == 0)
        .length;
    final expired = _groupedProducts
        .where((group) => group.hasExpiredStock)
        .length;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: [
          _filterChip(
            label: _localizations.all,
            count: total,
            color: AppTheme.mint,
            selected: _stockFilter == 'all',
            onTap: () => _onStockFilterChanged('all'),
          ),
          const SizedBox(width: 8),
          _filterChip(
            label: _localizations.inStock,
            count: inStock,
            color: AppTheme.mint,
            selected: _stockFilter == 'in_stock',
            onTap: () => _onStockFilterChanged('in_stock'),
          ),
          const SizedBox(width: 8),
          _filterChip(
            label: _localizations.lowStock,
            count: lowStock,
            color: AppTheme.toneAmber,
            selected: _stockFilter == 'low_stock',
            onTap: () => _onStockFilterChanged('low_stock'),
          ),
          const SizedBox(width: 8),
          _filterChip(
            label: _localizations.outOfStock,
            count: outOfStock,
            color: const Color(0xFFEF5350),
            selected: _stockFilter == 'out_of_stock',
            onTap: () => _onStockFilterChanged('out_of_stock'),
          ),
          const SizedBox(width: 8),
          _filterChip(
            label: _localizations.expired,
            count: expired,
            color: const Color(0xFFB388FF),
            selected: _stockFilter == 'expired',
            onTap: () => _onStockFilterChanged('expired'),
          ),
        ],
      ),
    );
  }

  Widget _filterChip({
    required String label,
    required int count,
    required Color color,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? color.withValues(alpha: 0.7)
                : AppColors.border(context),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            Text(
              '$label  $count',
              style: TextStyle(
                fontFamily: 'Literata',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: selected
                    ? AppColors.primaryText(context)
                    : AppColors.secondaryText(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchField() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: TextField(
        controller: _searchController,
        onChanged: _onSearchChanged,
        style: TextStyle(
          fontFamily: 'Literata',
          fontSize: 14,
          color: AppColors.primaryText(context),
        ),
        decoration: InputDecoration(
          hintText: _localizations.searchProducts,
          hintStyle: TextStyle(
            color: AppColors.mutedText(context),
            fontFamily: 'Literata',
          ),
          prefixIcon: Icon(
            Icons.search_rounded,
            color: AppColors.mutedText(context),
          ),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: Icon(
                    Icons.close_rounded,
                    size: 18,
                    color: AppColors.mutedText(context),
                  ),
                  onPressed: () {
                    _searchController.clear();
                    _onSearchChanged('');
                  },
                )
              : null,
          filled: true,
          fillColor: AppColors.card(context),
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: AppColors.border(context)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: AppColors.border(context)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: AppTheme.mint, width: 1.4),
          ),
        ),
      ),
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

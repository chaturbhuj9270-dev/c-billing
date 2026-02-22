import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/services/language_service.dart';
import '../../../../core/services/dashboard_refresh_service.dart';
import '../../../../core/services/product_settings_service.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../product/offline/controllers/product_offline_controller.dart';
import '../../../product/offline/entities/product_entity.dart';
import '../../../product/data/services/product_sync_service.dart';
import '../../../supplier/offline/controllers/supplier_offline_controller.dart';
import '../../../company/offline/controllers/company_offline_controller.dart';
import '../../domain/entities/product.dart';
import '../../domain/entities/grouped_product.dart';
import '../../offline/controllers/purchase_batch_offline_controller.dart';
import '../../offline/entities/purchase_batch_entity.dart';
import '../widgets/product_summary_widget.dart';
import '../widgets/product_filter_widget.dart';
import '../widgets/product_list_widget.dart';
import 'product_settings_page.dart';

class EnhancedProductPage extends StatefulWidget {
  final bool isEmbedded;

  const EnhancedProductPage({super.key, this.isEmbedded = false});

  @override
  State<EnhancedProductPage> createState() => _EnhancedProductPageState();
}

class _EnhancedProductPageState extends State<EnhancedProductPage>
    with SingleTickerProviderStateMixin {
  // Animation
  late AnimationController _animController;
  late Animation<Offset> _offsetAnimation;
  late Animation<double> _opacityAnimation;

  // State
  bool _isLoading = true;
  List<ProductEntity> _products = [];
  String _searchQuery = '';
  ProductSortField _sortField = ProductSortField.name;
  bool _sortAscending = true;
  String? _selectedCategory;
  bool _isNavigatingAway = false;
  int _unsyncedCount = 0;

  // Grouped view support
  bool _isGroupedView = false;
  List<GroupedProduct> _groupedProducts = [];
  List<PurchaseBatchEntity> _allBatches = [];

  // Isar stream for real-time updates
  StreamSubscription<List<ProductEntity>>? _productStreamSub;
  // Firestore stream for cross-device real-time sync
  StreamSubscription<QuerySnapshot>? _firestoreStreamSub;
  // Batch stream for grouped view
  StreamSubscription<List<PurchaseBatchEntity>>? _batchStreamSub;
  // Cross-page refresh subscriptions
  StreamSubscription<void>? _purchaseChangeSubscription;
  StreamSubscription<void>? _productChangeSubscription;

  // Services
  final _auth = FirebaseAuth.instance;
  late final FirebaseFirestore _firestore;
  late AppLocalizations _localizations;

  @override
  void initState() {
    super.initState();
    _firestore = FirebaseFirestore.instance;
    _localizations = AppLocalizations.of(
      LanguageService.instance.currentLanguage,
    );
    LanguageService.instance.addListener(_onLanguageChanged);

    // Setup animations
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    ));
    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    ));

    _checkUserAuthentication();
    _setupIsarStream();
    _setupBatchStream();
    _setupFirestoreStream();
    _setupCrossPageRefresh();

    // Start animation after frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _animController.forward();
    });
  }

  @override
  void dispose() {
    _isNavigatingAway = true;
    _animController.dispose();
    _productStreamSub?.cancel();
    _firestoreStreamSub?.cancel();
    _batchStreamSub?.cancel();
    _purchaseChangeSubscription?.cancel();
    _productChangeSubscription?.cancel();
    LanguageService.instance.removeListener(_onLanguageChanged);
    super.dispose();
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

  void _checkUserAuthentication() {
    if (_auth.currentUser == null) {
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    }
  }

  // ━━━ DATA: Isar Stream (offline-first, real-time) ━━━

  void _setupIsarStream() {
    final offlineCtrl = ProductOfflineController.instance;
    _productStreamSub = offlineCtrl.watchAllProducts().listen(
      (entities) {
        if (!mounted || _isNavigatingAway) return;
        setState(() {
          _products = entities.where((e) => e.isActive).toList();
          _isLoading = false;
        });
        _updateUnsyncedCount();
        _rebuildGroupedProducts();
        debugPrint('[EnhancedProduct] Isar stream: ${entities.length} products');
      },
      onError: (e) {
        debugPrint('[EnhancedProduct] Isar stream error: $e');
        if (mounted) setState(() => _isLoading = false);
      },
    );
  }

  /// Setup batch stream for grouped view
  void _setupBatchStream() {
    final batchController = PurchaseBatchOfflineController.instance;
    _batchStreamSub = batchController
        .watchAllBatches(includeConsumed: false)
        .listen(
      (batches) {
        if (mounted) {
          _allBatches = batches;
          _rebuildGroupedProducts();
        }
      },
      onError: (e) {
        debugPrint('[EnhancedProduct] Batch stream error: $e');
      },
    );
  }

  /// Listen for purchase/product changes from other pages
  void _setupCrossPageRefresh() {
    _purchaseChangeSubscription = DashboardRefreshService.instance.onPurchaseChanged.listen((_) {
      if (mounted) _reloadFromIsar();
    });
    _productChangeSubscription = DashboardRefreshService.instance.onProductChanged.listen((_) {
      if (mounted) _reloadFromIsar();
    });
  }

  Future<void> _reloadFromIsar() async {
    try {
      final entities = await ProductOfflineController.instance.getAllProducts();
      if (mounted) {
        setState(() {
          _products = entities.where((e) => e.isActive).toList();
        });
        _updateUnsyncedCount();
        _rebuildGroupedProducts();
      }
    } catch (e) {
      debugPrint('[EnhancedProduct] Failed to reload from Isar: $e');
    }
  }

  Future<void> _updateUnsyncedCount() async {
    final count = await ProductOfflineController.instance.getUnsyncedCount();
    if (mounted && count != _unsyncedCount) {
      setState(() => _unsyncedCount = count);
    }
  }

  /// Rebuild grouped product list from batches + products
  void _rebuildGroupedProducts() {
    // Find products that have NO batches (e.g., only initial stock)
    final productIdsInBatches = _allBatches.map((b) => b.productId).toSet();
    final productsWithoutBatches = _products.where(
      (p) => !productIdsInBatches.contains(p.serverId ?? p.id.toString()),
    ).map((e) => Product.fromProductEntity(e)).toList();

    final grouped = GroupedProduct.buildFromBatches(
      _allBatches,
      productsWithoutBatches: productsWithoutBatches,
    );

    setState(() {
      _groupedProducts = grouped;
    });
  }

  // ━━━ DATA: Firebase Stream for cross-device sync ━━━

  void _setupFirestoreStream() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    _firestoreStreamSub = _firestore
        .collection('users')
        .doc(currentUser.uid)
        .collection('products')
        .snapshots()
        .listen(
      (snapshot) async {
        if (!mounted || _isNavigatingAway) return;

        debugPrint('[EnhancedProduct] Firestore stream: ${snapshot.docs.length} docs');

        final serverProducts = snapshot.docs.map((doc) {
          final data = doc.data();
          return <String, dynamic>{
            'id': doc.id,
            ...data,
          };
        }).toList();

        // Import to Isar — the Isar stream listener auto-updates the UI
        await ProductOfflineController.instance.importFromServer(serverProducts);

        // Trigger sync for any local-only changes
        ProductSyncService.instance.syncNow();
      },
      onError: (e) {
        debugPrint('[EnhancedProduct] Firestore stream error: $e');
      },
    );
  }

  // ━━━ CATEGORY HELPERS ━━━

  List<String> get _allCategories {
    final categories = <String>{};
    for (final product in _products) {
      if (product.category.isNotEmpty) {
        categories.add(product.category);
      }
    }
    return categories.toList()..sort();
  }

  // ━━━ REFRESH ━━━

  Future<void> _onRefresh() async {
    await _reloadFromIsar();
    ProductSyncService.instance.syncNow();
  }

  // ━━━ BUILD ━━━

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isWide = size.width > 600;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: widget.isEmbedded ? null : _buildAppBar(),
      body: SafeArea(
        child: SlideTransition(
          position: _offsetAnimation,
          child: FadeTransition(
            opacity: _opacityAnimation,
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isWide ? 24 : 16,
                vertical: 8,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Summary widget
                  ProductSummaryWidget(products: _products),
                  const SizedBox(height: 16),

                  // Filter widget
                  ProductFilterWidget(
                    searchQuery: _searchQuery,
                    sortField: _sortField,
                    sortAscending: _sortAscending,
                    selectedCategory: _selectedCategory,
                    categories: _allCategories,
                    onSearchChanged: (value) {
                      setState(() => _searchQuery = value);
                    },
                    onSortFieldChanged: (field) {
                      setState(() => _sortField = field);
                    },
                    onSortDirectionToggle: () {
                      setState(() => _sortAscending = !_sortAscending);
                    },
                    onCategoryChanged: (category) {
                      setState(() => _selectedCategory = category);
                    },
                    searchHint: _localizations.searchProducts,
                    sortByNameLabel: _localizations.name,
                    sortByStockLabel: _localizations.stock,
                    sortByPriceLabel: _localizations.price,
                  ),
                  const SizedBox(height: 16),

                  // View mode toggle
                  _buildViewModeToggle(),
                  const SizedBox(height: 8),

                  // Product list or grouped view
                  Expanded(
                    child: _isGroupedView
                        ? _buildGroupedProductList()
                        : ProductListWidget(
                            products: _products,
                            isLoading: _isLoading,
                            searchQuery: _searchQuery,
                            sortField: _sortField,
                            sortAscending: _sortAscending,
                            selectedCategory: _selectedCategory,
                            onRefresh: _onRefresh,
                            onProductTap: _showProductDetails,
                            onProductLongPress: _showProductContextMenu,
                            emptyTitle: _localizations.noProductsFound,
                            emptySubtitle: 'Add your first product to get started',
                            noResultsTitle: _localizations.noResultsFound,
                            noResultsSubtitle: 'Try a different search term',
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF1B4D3E),
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: Text(
          _localizations.addProduct,
          style: const TextStyle(
            fontFamily: 'Literata',
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        onPressed: _showAddProductSheet,
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.grey[50],
      elevation: 0,
      title: Text(
        _localizations.products,
        style: const TextStyle(
          fontFamily: 'Literata',
          fontWeight: FontWeight.w700,
          color: Color(0xFF1B4D3E),
        ),
      ),
      actions: [
        // Sync indicator
        if (_unsyncedCount > 0)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => ProductSyncService.instance.syncNow(),
              child: Chip(
                backgroundColor: Colors.orange[50],
                avatar: Icon(
                  Icons.cloud_upload_rounded,
                  size: 16,
                  color: Colors.orange[700],
                ),
                label: Text(
                  '$_unsyncedCount',
                  style: TextStyle(
                    fontFamily: 'Literata',
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                    color: Colors.orange[700],
                  ),
                ),
              ),
            ),
          ),
        // Settings
        IconButton(
          icon: const Icon(
            Icons.settings_outlined,
            color: Color(0xFF1B4D3E),
          ),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const ProductSettingsPage(),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildViewModeToggle() {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _isGroupedView = false),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: !_isGroupedView
                    ? const Color(0xFF1B4D3E)
                    : Colors.grey[100],
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(10),
                ),
                border: Border.all(
                  color: !_isGroupedView
                      ? const Color(0xFF1B4D3E)
                      : Colors.grey[300]!,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.view_list_rounded,
                    size: 18,
                    color: !_isGroupedView ? Colors.white : Colors.grey[600],
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Flat View',
                    style: TextStyle(
                      fontFamily: 'Literata',
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: !_isGroupedView ? Colors.white : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _isGroupedView = true),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: _isGroupedView
                    ? const Color(0xFF1B4D3E)
                    : Colors.grey[100],
                borderRadius: const BorderRadius.horizontal(
                  right: Radius.circular(10),
                ),
                border: Border.all(
                  color: _isGroupedView
                      ? const Color(0xFF1B4D3E)
                      : Colors.grey[300]!,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.account_tree_rounded,
                    size: 18,
                    color: _isGroupedView ? Colors.white : Colors.grey[600],
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Grouped View',
                    style: TextStyle(
                      fontFamily: 'Literata',
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: _isGroupedView ? Colors.white : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ━━━ GROUPED VIEW ━━━

  Widget _buildGroupedProductList() {
    // Apply filters
    var filteredGroups = _groupedProducts.toList();

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filteredGroups = filteredGroups.where((group) {
        return group.productName.toLowerCase().contains(query) ||
            group.companies.any((c) => c.toLowerCase().contains(query));
      }).toList();
    }

    // Apply category filter
    if (_selectedCategory != null && _selectedCategory!.isNotEmpty) {
      // Grouped products don't have category, so we filter by product name match
      filteredGroups = filteredGroups.where((group) {
        return _products.any((p) =>
            p.name.toLowerCase() == group.productName.toLowerCase() &&
            p.category.toLowerCase() == _selectedCategory!.toLowerCase());
      }).toList();
    }

    // Apply sort
    filteredGroups.sort((a, b) {
      int result;
      switch (_sortField) {
        case ProductSortField.name:
          result = a.productName.toLowerCase().compareTo(b.productName.toLowerCase());
          break;
        case ProductSortField.stock:
          result = a.totalStock.compareTo(b.totalStock);
          break;
        case ProductSortField.price:
          result = a.maxSalesPrice.compareTo(b.maxSalesPrice);
          break;
        case ProductSortField.category:
          result = a.productName.toLowerCase().compareTo(b.productName.toLowerCase());
          break;
      }
      return _sortAscending ? result : -result;
    });

    if (filteredGroups.isEmpty) {
      return Center(
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
                _searchQuery.isNotEmpty
                    ? Icons.search_off_rounded
                    : Icons.inventory_2_outlined,
                size: 48,
                color: const Color(0xFF1B4D3E).withOpacity(0.4),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              _searchQuery.isNotEmpty
                  ? _localizations.noResultsFound
                  : _localizations.noProductsFound,
              style: TextStyle(
                fontFamily: 'Literata',
                fontWeight: FontWeight.w700,
                fontSize: 18,
                color: Colors.grey[700],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: const Color(0xFF1B4D3E),
      onRefresh: _onRefresh,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: const EdgeInsets.only(bottom: 100),
        itemCount: filteredGroups.length,
        itemBuilder: (context, index) {
          return _buildGroupedProductCard(filteredGroups[index]);
        },
      ),
    );
  }

  Widget _buildGroupedProductCard(GroupedProduct group) {
    final isLow = group.totalStock <= 5;

    return Container(
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
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
        ),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          childrenPadding: EdgeInsets.zero,
          leading: CircleAvatar(
            radius: 22,
            backgroundColor: isLow
                ? Colors.red.withOpacity(0.15)
                : const Color(0xFF1B4D3E).withOpacity(0.15),
            child: Icon(
              Icons.inventory_2_rounded,
              color: isLow ? Colors.red : const Color(0xFF1B4D3E),
              size: 20,
            ),
          ),
          title: Text(
            group.productName,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              fontFamily: 'Literata',
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: isLow
                        ? Colors.red.withOpacity(0.15)
                        : Colors.green.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Stock: ${group.totalStock}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Literata',
                      color: isLow ? Colors.red : Colors.green[700],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                if (group.hasMultipleVariants)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${group.variantCount} batches',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'Literata',
                        color: Colors.blue[700],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          children: [
            // Summary bar
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: const Color(0xFF1B4D3E).withOpacity(0.06),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildGroupInfoChip(
                    Icons.shopping_cart_outlined,
                    group.purchasePriceRange,
                    'Purchase',
                  ),
                  _buildGroupInfoChip(
                    Icons.sell_outlined,
                    group.salesPriceRange,
                    'Sell',
                  ),
                  _buildGroupInfoChip(
                    Icons.account_balance_wallet_outlined,
                    '₹${group.totalStockValue.toStringAsFixed(0)}',
                    'Value',
                  ),
                ],
              ),
            ),
            // Batch rows
            ...group.subEntries.asMap().entries.map((mapEntry) {
              final i = mapEntry.key;
              final entry = mapEntry.value;
              final isEven = i % 2 == 0;

              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: isEven ? Colors.white : Colors.grey[50],
                  border: Border(
                    bottom: BorderSide(color: Colors.grey[200]!, width: 0.5),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Text(
                        entry.companyName.isNotEmpty ? entry.companyName : '—',
                        style: const TextStyle(
                          fontSize: 12,
                          fontFamily: 'Literata',
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        '₹${entry.purchasePrice.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontFamily: 'Literata',
                          fontWeight: FontWeight.w500,
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
                      flex: 1,
                      child: Text(
                        '${entry.stockQuantity}',
                        style: TextStyle(
                          fontSize: 12,
                          fontFamily: 'Literata',
                          fontWeight: FontWeight.w700,
                          color: entry.stockQuantity <= 5
                              ? Colors.red
                              : Colors.black87,
                        ),
                        textAlign: TextAlign.end,
                      ),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupInfoChip(IconData icon, String value, String label) {
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
                fontFamily: 'Literata',
                fontWeight: FontWeight.w600,
                fontSize: 12,
                color: Color(0xFF1B4D3E),
              ),
            ),
          ],
        ),
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Literata',
            fontSize: 10,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  // ━━━ PRODUCT DETAILS SHEET ━━━

  void _showProductDetails(ProductEntity product) {
    final isSynced = product.syncStatus == SyncStatus.synced;
    final isLowStock = product.currentStock <= (product.minStockLevel ?? 5);
    final isOutOfStock = product.currentStock <= 0;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Container(
          height: MediaQuery.of(context).size.height * 0.75,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    // Avatar
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: isOutOfStock
                              ? [Colors.red[400]!, Colors.red[300]!]
                              : isLowStock
                                  ? [Colors.orange[400]!, Colors.orange[300]!]
                                  : [
                                      const Color(0xFF1B4D3E),
                                      const Color(0xFF1B4D3E).withOpacity(0.7),
                                    ],
                        ),
                      ),
                      child: Center(
                        child: Text(
                          product.name.isNotEmpty
                              ? product.name[0].toUpperCase()
                              : 'P',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'Literata',
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Name + Sync status
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product.name,
                            style: const TextStyle(
                              fontFamily: 'Literata',
                              fontWeight: FontWeight.w700,
                              fontSize: 20,
                              color: Color(0xFF1B4D3E),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          // Sync status badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: isSynced
                                  ? Colors.green[50]
                                  : Colors.orange[50],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isSynced
                                      ? Icons.cloud_done_rounded
                                      : Icons.cloud_upload_rounded,
                                  size: 14,
                                  color: isSynced
                                      ? Colors.green[700]
                                      : Colors.orange[700],
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  isSynced
                                      ? 'Synced'
                                      : 'Pending Sync',
                                  style: TextStyle(
                                    fontFamily: 'Literata',
                                    fontWeight: FontWeight.w600,
                                    fontSize: 11,
                                    color: isSynced
                                        ? Colors.green[700]
                                        : Colors.orange[700],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Close button
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(Icons.close_rounded, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Stock status
                      if (isOutOfStock)
                        _buildWarningBanner(
                          icon: Icons.error_outline_rounded,
                          color: Colors.red,
                          message: _localizations.outOfStock,
                        )
                      else if (isLowStock)
                        _buildWarningBanner(
                          icon: Icons.warning_amber_rounded,
                          color: Colors.orange,
                          message: _localizations.lowStock,
                        ),

                      // Info cards
                      _buildInfoCard(
                        icon: Icons.business_rounded,
                        label: _localizations.company,
                        value: product.companyName.isNotEmpty
                            ? product.companyName
                            : '—',
                      ),
                      _buildInfoCard(
                        icon: Icons.category_rounded,
                        label: _localizations.category,
                        value: product.category.isNotEmpty
                            ? product.category
                            : '—',
                      ),
                      _buildInfoCard(
                        icon: Icons.qr_code_rounded,
                        label: 'Barcode',
                        value: product.barcode ?? '—',
                      ),

                      const SizedBox(height: 16),
                      // Price row
                      Row(
                        children: [
                          Expanded(
                            child: _buildPriceCard(
                              label: _localizations.purchasePrice,
                              value: '₹${product.purchasePrice.toStringAsFixed(2)}',
                              color: Colors.grey[700]!,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildPriceCard(
                              label: _localizations.salesPrice,
                              value: '₹${product.salesPrice.toStringAsFixed(2)}',
                              color: Colors.green[700]!,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Stock and GST row
                      Row(
                        children: [
                          Expanded(
                            child: _buildPriceCard(
                              label: _localizations.currentStock,
                              value: '${product.currentStock}',
                              color: isOutOfStock
                                  ? Colors.red[700]!
                                  : isLowStock
                                      ? Colors.orange[700]!
                                      : const Color(0xFF1B4D3E),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildPriceCard(
                              label: 'GST',
                              value: '${(product.cgstPercent + product.sgstPercent).toStringAsFixed(1)}%',
                              color: Colors.blue[700]!,
                            ),
                          ),
                        ],
                      ),

                      // HSN Code
                      if (product.hsnCode != null && product.hsnCode!.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        _buildInfoCard(
                          icon: Icons.tag_rounded,
                          label: 'HSN Code',
                          value: product.hsnCode!,
                        ),
                      ],

                      // Description
                      if (product.description != null && product.description!.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Text(
                          _localizations.description,
                          style: TextStyle(
                            fontFamily: 'Literata',
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            product.description!,
                            style: const TextStyle(
                              fontFamily: 'Literata',
                              fontSize: 14,
                              color: Colors.black87,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],

                      const SizedBox(height: 24),
                      // Action buttons
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                Navigator.pop(context);
                                _showEditProductSheet(product);
                              },
                              icon: const Icon(Icons.edit_rounded),
                              label: Text(_localizations.edit),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF1B4D3E),
                                side: const BorderSide(color: Color(0xFF1B4D3E)),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.pop(context);
                                _showDeleteConfirmation(product);
                              },
                              icon: const Icon(Icons.delete_outline_rounded),
                              label: Text(_localizations.delete),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWarningBanner({
    required IconData icon,
    required Color color,
    required String message,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Text(
            message,
            style: TextStyle(
              fontFamily: 'Literata',
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF1B4D3E).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: const Color(0xFF1B4D3E), size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontFamily: 'Literata',
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontFamily: 'Literata',
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceCard({
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Literata',
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Literata',
              fontWeight: FontWeight.w700,
              fontSize: 18,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // ━━━ CONTEXT MENU ━━━

  void _showProductContextMenu(ProductEntity product) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  product.name,
                  style: const TextStyle(
                    fontFamily: 'Literata',
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: Color(0xFF1B4D3E),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.visibility_rounded, color: Color(0xFF1B4D3E)),
                title: Text(
                  'View Details',
                  style: const TextStyle(fontFamily: 'Literata'),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _showProductDetails(product);
                },
              ),
              ListTile(
                leading: const Icon(Icons.edit_rounded, color: Color(0xFF1B4D3E)),
                title: Text(
                  _localizations.edit,
                  style: const TextStyle(fontFamily: 'Literata'),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _showEditProductSheet(product);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                title: Text(
                  _localizations.delete,
                  style: const TextStyle(
                    fontFamily: 'Literata',
                    color: Colors.red,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _showDeleteConfirmation(product);
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  // ━━━ DELETE CONFIRMATION ━━━

  void _showDeleteConfirmation(ProductEntity product) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          _localizations.deleteProduct,
          style: const TextStyle(
            fontFamily: 'Literata',
            fontWeight: FontWeight.w700,
            color: Color(0xFF1B4D3E),
          ),
        ),
        content: Text(
          '${_localizations.deleteConfirmation} "${product.name}"?\n\n${_localizations.actionCannotBeUndone}',
          style: const TextStyle(fontFamily: 'Literata'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              _localizations.cancel,
              style: const TextStyle(
                fontFamily: 'Literata',
                color: Colors.grey,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteProduct(product);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(
              _localizations.delete,
              style: const TextStyle(
                fontFamily: 'Literata',
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteProduct(ProductEntity product) async {
    try {
      await ProductOfflineController.instance.deleteProduct(product.id);
      DashboardRefreshService.instance.notifyDataChanged(DataChangeType.product);
      ProductSyncService.instance.syncNow();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _localizations.productDeletedSuccessfully,
              style: const TextStyle(fontFamily: 'Literata'),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${_localizations.error}: $e',
              style: const TextStyle(fontFamily: 'Literata'),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ━━━ ADD PRODUCT SHEET ━━━

  void _showAddProductSheet() {
    final nameController = TextEditingController();
    final categoryController = TextEditingController();
    final purchasePriceController = TextEditingController();
    final salesPriceController = TextEditingController();
    final initialStockController = TextEditingController(text: '0');
    final cgstController = TextEditingController(text: '0');
    final sgstController = TextEditingController(text: '0');
    final hsnController = TextEditingController();

    // Company and supplier state
    Map<String, dynamic>? dialogSelectedCompany;
    Map<String, dynamic>? dialogSelectedSupplier;
    List<Map<String, dynamic>> dialogCompanies = [];
    List<Map<String, dynamic>> dialogSuppliers = [];

    // Custom fields
    final customColumns = ProductSettingsService.instance.activeCustomColumns;
    final Map<String, TextEditingController> customTextControllers = {};
    final Map<String, dynamic> customFieldValues = {};

    // Initialize custom field controllers
    for (final column in customColumns) {
      if (column.type == CustomColumnType.text ||
          column.type == CustomColumnType.number ||
          column.type == CustomColumnType.decimal) {
        customTextControllers[column.id] = TextEditingController(
          text: column.defaultValue ?? '',
        );
      } else if (column.type == CustomColumnType.boolean) {
        customFieldValues[column.id] = column.defaultValue == 'true';
      } else if (column.type == CustomColumnType.dropdown) {
        customFieldValues[column.id] = column.defaultValue ??
            ((column.dropdownOptions?.isNotEmpty ?? false)
                ? column.dropdownOptions!.first
                : '');
      } else if (column.type == CustomColumnType.date) {
        customFieldValues[column.id] = column.defaultValue;
      }
    }

    // Load companies and suppliers
    loadCompaniesAndSuppliers() async {
      final companyEntities = await CompanyOfflineController.instance.getAllCompanies();
      dialogCompanies = companyEntities.map((e) => {
        'id': e.serverId ?? e.id.toString(),
        'companyName': e.companyName,
      }).toList();

      final supplierEntities = await SupplierOfflineController.instance.getAllSuppliers();
      dialogSuppliers = supplierEntities.map((e) => {
        'id': e.serverId ?? e.id.toString(),
        'firstName': e.firstName,
        'lastName': e.lastName,
        'fullName': '${e.firstName} ${e.lastName}'.trim(),
      }).toList();
    }

    loadCompaniesAndSuppliers();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Container(
            height: MediaQuery.of(context).size.height * 0.85,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                // Handle bar
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(top: 12),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                // Header
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Text(
                        _localizations.addNewProduct,
                        style: const TextStyle(
                          fontFamily: 'Literata',
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                          color: Color(0xFF1B4D3E),
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(Icons.close_rounded, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                // Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildTextField(
                          controller: nameController,
                          label: _localizations.productName,
                          icon: Icons.inventory_2_outlined,
                        ),
                        const SizedBox(height: 12),
                        // Company selector
                        _buildSelectorField(
                          label: _localizations.selectCompany,
                          value: dialogSelectedCompany?['companyName'],
                          icon: Icons.business_rounded,
                          onTap: () async {
                            final company = await _showCompanyPickerDialog(
                              context,
                              dialogCompanies,
                            );
                            if (company != null) {
                              setDialogState(() => dialogSelectedCompany = company);
                            }
                          },
                        ),
                        const SizedBox(height: 12),
                        // Supplier selector
                        _buildSelectorField(
                          label: _localizations.selectSupplier,
                          value: dialogSelectedSupplier?['fullName'],
                          icon: Icons.person_rounded,
                          onTap: () async {
                            final supplier = await _showSupplierPickerDialog(
                              context,
                              dialogSuppliers,
                            );
                            if (supplier != null) {
                              setDialogState(() => dialogSelectedSupplier = supplier);
                            }
                          },
                        ),
                        const SizedBox(height: 12),
                        _buildTextField(
                          controller: categoryController,
                          label: _localizations.category,
                          icon: Icons.category_outlined,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _buildTextField(
                                controller: purchasePriceController,
                                label: _localizations.purchasePrice,
                                icon: Icons.shopping_cart_outlined,
                                keyboardType: TextInputType.number,
                                prefix: '₹ ',
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildTextField(
                                controller: salesPriceController,
                                label: _localizations.salesPrice,
                                icon: Icons.sell_outlined,
                                keyboardType: TextInputType.number,
                                prefix: '₹ ',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildTextField(
                          controller: initialStockController,
                          label: _localizations.initialStock,
                          icon: Icons.inventory_rounded,
                          keyboardType: TextInputType.number,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _buildTextField(
                                controller: cgstController,
                                label: 'CGST %',
                                keyboardType: TextInputType.number,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildTextField(
                                controller: sgstController,
                                label: 'SGST %',
                                keyboardType: TextInputType.number,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildTextField(
                          controller: hsnController,
                          label: 'HSN Code',
                          icon: Icons.tag_rounded,
                          keyboardType: TextInputType.number,
                          maxLength: 8,
                        ),
                        // Custom fields
                        if (customColumns.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          const Text(
                            'Custom Fields',
                            style: TextStyle(
                              fontFamily: 'Literata',
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: Color(0xFF1B4D3E),
                            ),
                          ),
                          const SizedBox(height: 12),
                          ...customColumns.map((column) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _buildCustomFieldWidget(
                              column,
                              customTextControllers[column.id],
                              customFieldValues,
                              setDialogState,
                            ),
                          )),
                        ],
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
                // Actions
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.grey[700],
                              side: BorderSide(color: Colors.grey[300]!),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: Text(
                              _localizations.cancel,
                              style: const TextStyle(fontFamily: 'Literata'),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            onPressed: () => _saveNewProduct(
                              nameController: nameController,
                              categoryController: categoryController,
                              purchasePriceController: purchasePriceController,
                              salesPriceController: salesPriceController,
                              initialStockController: initialStockController,
                              cgstController: cgstController,
                              sgstController: sgstController,
                              hsnController: hsnController,
                              selectedCompany: dialogSelectedCompany,
                              selectedSupplier: dialogSelectedSupplier,
                              customColumns: customColumns,
                              customTextControllers: customTextControllers,
                              customFieldValues: customFieldValues,
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1B4D3E),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: const Text(
                              'Save',
                              style: TextStyle(
                                fontFamily: 'Literata',
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _saveNewProduct({
    required TextEditingController nameController,
    required TextEditingController categoryController,
    required TextEditingController purchasePriceController,
    required TextEditingController salesPriceController,
    required TextEditingController initialStockController,
    required TextEditingController cgstController,
    required TextEditingController sgstController,
    required TextEditingController hsnController,
    Map<String, dynamic>? selectedCompany,
    Map<String, dynamic>? selectedSupplier,
    required List<CustomColumn> customColumns,
    required Map<String, TextEditingController> customTextControllers,
    required Map<String, dynamic> customFieldValues,
  }) async {
    // Validate
    final name = nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Product name is required',
            style: TextStyle(fontFamily: 'Literata'),
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final purchasePrice = double.tryParse(purchasePriceController.text) ?? 0.0;
    final salesPrice = double.tryParse(salesPriceController.text) ?? 0.0;
    final initialStock = int.tryParse(initialStockController.text) ?? 0;
    final cgstVal = double.tryParse(cgstController.text) ?? 0.0;
    final sgstVal = double.tryParse(sgstController.text) ?? 0.0;
    final hsnVal = hsnController.text.trim();

    // Validate HSN: required if CGST or SGST > 0
    if ((cgstVal > 0 || sgstVal > 0) && hsnVal.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'HSN Code is required when GST is applied',
            style: TextStyle(fontFamily: 'Literata'),
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Collect custom field values
    final Map<String, dynamic> finalCustomFields = {};
    for (final column in customColumns) {
      String? value;
      if (column.type == CustomColumnType.text ||
          column.type == CustomColumnType.number ||
          column.type == CustomColumnType.decimal) {
        value = customTextControllers[column.id]?.text.trim();
      } else if (column.type == CustomColumnType.boolean) {
        value = (customFieldValues[column.id] ?? false).toString();
      } else if (column.type == CustomColumnType.dropdown ||
                 column.type == CustomColumnType.date) {
        value = customFieldValues[column.id]?.toString();
      }
      if (value != null && value.isNotEmpty) {
        finalCustomFields[column.id] = value;
      }
    }

    String? customFieldsJson;
    if (finalCustomFields.isNotEmpty) {
      customFieldsJson = jsonEncode(finalCustomFields);
    }

    try {
      final newProduct = await ProductOfflineController.instance.addProduct(
        name: name,
        companyName: selectedCompany?['companyName'] ?? '',
        category: categoryController.text.trim(),
        purchasePrice: purchasePrice,
        salesPrice: salesPrice,
        currentStock: initialStock,
        cgstPercent: cgstVal,
        sgstPercent: sgstVal,
        hsnCode: hsnVal.isNotEmpty ? hsnVal : null,
        defaultSupplierId: selectedSupplier?['id'],
        defaultSupplierName: selectedSupplier?['fullName'],
        customFieldsJson: customFieldsJson,
      );

      DashboardRefreshService.instance.notifyDataChanged(DataChangeType.product);
      ProductSyncService.instance.syncNow();

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '#${newProduct.indexNo}',
                    style: const TextStyle(
                      fontFamily: 'Literata',
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '${_localizations.productAddedSuccessfully} - $name',
                    style: const TextStyle(fontFamily: 'Literata'),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF1B4D3E),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${_localizations.error}: $e',
              style: const TextStyle(fontFamily: 'Literata'),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ━━━ EDIT PRODUCT SHEET ━━━

  void _showEditProductSheet(ProductEntity product) {
    final nameController = TextEditingController(text: product.name);
    final categoryController = TextEditingController(text: product.category);
    final companyController = TextEditingController(text: product.companyName);
    final purchasePriceController = TextEditingController(text: product.purchasePrice.toString());
    final salesPriceController = TextEditingController(text: product.salesPrice.toString());
    final cgstController = TextEditingController(text: product.cgstPercent.toString());
    final sgstController = TextEditingController(text: product.sgstPercent.toString());
    final hsnController = TextEditingController(text: product.hsnCode ?? '');

    // Custom fields
    final customColumns = ProductSettingsService.instance.activeCustomColumns;
    final Map<String, TextEditingController> customTextControllers = {};
    final Map<String, dynamic> customFieldValues = {};

    // Parse existing custom fields
    Map<String, dynamic> existingCustomFields = {};
    if (product.customFieldsJson != null && product.customFieldsJson!.isNotEmpty) {
      try {
        existingCustomFields = jsonDecode(product.customFieldsJson!) as Map<String, dynamic>;
      } catch (_) {}
    }

    // Initialize controllers
    for (final column in customColumns) {
      final existingValue = existingCustomFields[column.id]?.toString();
      if (column.type == CustomColumnType.text ||
          column.type == CustomColumnType.number ||
          column.type == CustomColumnType.decimal) {
        customTextControllers[column.id] = TextEditingController(
          text: existingValue ?? column.defaultValue ?? '',
        );
      } else if (column.type == CustomColumnType.boolean) {
        customFieldValues[column.id] = existingValue == 'true' ||
            (existingValue == null && column.defaultValue == 'true');
      } else if (column.type == CustomColumnType.dropdown) {
        customFieldValues[column.id] = existingValue ?? column.defaultValue ??
            ((column.dropdownOptions?.isNotEmpty ?? false)
                ? column.dropdownOptions!.first
                : '');
      } else if (column.type == CustomColumnType.date) {
        customFieldValues[column.id] = existingValue ?? column.defaultValue;
      }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Container(
            height: MediaQuery.of(context).size.height * 0.85,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                // Handle bar
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(top: 12),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                // Header
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Text(
                        _localizations.editProduct,
                        style: const TextStyle(
                          fontFamily: 'Literata',
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                          color: Color(0xFF1B4D3E),
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(Icons.close_rounded, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                // Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildTextField(
                          controller: nameController,
                          label: _localizations.productName,
                          icon: Icons.inventory_2_outlined,
                        ),
                        const SizedBox(height: 12),
                        _buildTextField(
                          controller: companyController,
                          label: _localizations.companyName,
                          icon: Icons.business_rounded,
                        ),
                        const SizedBox(height: 12),
                        _buildTextField(
                          controller: categoryController,
                          label: _localizations.category,
                          icon: Icons.category_outlined,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _buildTextField(
                                controller: purchasePriceController,
                                label: _localizations.purchasePrice,
                                icon: Icons.shopping_cart_outlined,
                                keyboardType: TextInputType.number,
                                prefix: '₹ ',
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildTextField(
                                controller: salesPriceController,
                                label: _localizations.salesPrice,
                                icon: Icons.sell_outlined,
                                keyboardType: TextInputType.number,
                                prefix: '₹ ',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _buildTextField(
                                controller: cgstController,
                                label: 'CGST %',
                                keyboardType: TextInputType.number,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildTextField(
                                controller: sgstController,
                                label: 'SGST %',
                                keyboardType: TextInputType.number,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildTextField(
                          controller: hsnController,
                          label: 'HSN Code',
                          icon: Icons.tag_rounded,
                          keyboardType: TextInputType.number,
                          maxLength: 8,
                        ),
                        const SizedBox(height: 12),
                        // Current stock (read-only)
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.inventory_rounded, color: Colors.grey[600], size: 20),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _localizations.currentStock,
                                      style: TextStyle(
                                        fontFamily: 'Literata',
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    Text(
                                      '${product.currentStock} (Read Only)',
                                      style: const TextStyle(
                                        fontFamily: 'Literata',
                                        fontWeight: FontWeight.w600,
                                        fontSize: 15,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Custom fields
                        if (customColumns.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          const Text(
                            'Custom Fields',
                            style: TextStyle(
                              fontFamily: 'Literata',
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: Color(0xFF1B4D3E),
                            ),
                          ),
                          const SizedBox(height: 12),
                          ...customColumns.map((column) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _buildCustomFieldWidget(
                              column,
                              customTextControllers[column.id],
                              customFieldValues,
                              setDialogState,
                            ),
                          )),
                        ],
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
                // Actions
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.grey[700],
                              side: BorderSide(color: Colors.grey[300]!),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: Text(
                              _localizations.cancel,
                              style: const TextStyle(fontFamily: 'Literata'),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            onPressed: () => _updateProduct(
                              product: product,
                              nameController: nameController,
                              companyController: companyController,
                              categoryController: categoryController,
                              purchasePriceController: purchasePriceController,
                              salesPriceController: salesPriceController,
                              cgstController: cgstController,
                              sgstController: sgstController,
                              hsnController: hsnController,
                              customColumns: customColumns,
                              customTextControllers: customTextControllers,
                              customFieldValues: customFieldValues,
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1B4D3E),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: Text(
                              _localizations.update,
                              style: const TextStyle(
                                fontFamily: 'Literata',
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _updateProduct({
    required ProductEntity product,
    required TextEditingController nameController,
    required TextEditingController companyController,
    required TextEditingController categoryController,
    required TextEditingController purchasePriceController,
    required TextEditingController salesPriceController,
    required TextEditingController cgstController,
    required TextEditingController sgstController,
    required TextEditingController hsnController,
    required List<CustomColumn> customColumns,
    required Map<String, TextEditingController> customTextControllers,
    required Map<String, dynamic> customFieldValues,
  }) async {
    // Validate
    final name = nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Product name is required',
            style: TextStyle(fontFamily: 'Literata'),
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final purchasePrice = double.tryParse(purchasePriceController.text) ?? 0.0;
    final salesPrice = double.tryParse(salesPriceController.text) ?? 0.0;
    final cgstVal = double.tryParse(cgstController.text) ?? 0.0;
    final sgstVal = double.tryParse(sgstController.text) ?? 0.0;
    final hsnVal = hsnController.text.trim();

    // Validate HSN
    if ((cgstVal > 0 || sgstVal > 0) && hsnVal.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'HSN Code is required when GST is applied',
            style: TextStyle(fontFamily: 'Literata'),
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Collect custom field values
    final Map<String, dynamic> finalCustomFields = {};
    for (final column in customColumns) {
      String? value;
      if (column.type == CustomColumnType.text ||
          column.type == CustomColumnType.number ||
          column.type == CustomColumnType.decimal) {
        value = customTextControllers[column.id]?.text.trim();
      } else if (column.type == CustomColumnType.boolean) {
        value = (customFieldValues[column.id] ?? false).toString();
      } else if (column.type == CustomColumnType.dropdown ||
                 column.type == CustomColumnType.date) {
        value = customFieldValues[column.id]?.toString();
      }
      if (value != null && value.isNotEmpty) {
        finalCustomFields[column.id] = value;
      }
    }

    String? customFieldsJson;
    if (finalCustomFields.isNotEmpty) {
      customFieldsJson = jsonEncode(finalCustomFields);
    }

    try {
      await ProductOfflineController.instance.updateProduct(
        id: product.id,
        name: name,
        companyName: companyController.text.trim(),
        category: categoryController.text.trim(),
        purchasePrice: purchasePrice,
        salesPrice: salesPrice,
        cgstPercent: cgstVal,
        sgstPercent: sgstVal,
        hsnCode: hsnVal.isNotEmpty ? hsnVal : null,
        customFieldsJson: customFieldsJson,
      );

      DashboardRefreshService.instance.notifyDataChanged(DataChangeType.product);
      ProductSyncService.instance.syncNow();

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _localizations.productUpdatedSuccessfully,
              style: const TextStyle(fontFamily: 'Literata'),
            ),
            backgroundColor: const Color(0xFF1B4D3E),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${_localizations.error}: $e',
              style: const TextStyle(fontFamily: 'Literata'),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ━━━ HELPER WIDGETS ━━━

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    IconData? icon,
    TextInputType? keyboardType,
    String? prefix,
    int? maxLength,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLength: maxLength,
      decoration: InputDecoration(
        labelText: label,
        prefixText: prefix,
        prefixIcon: icon != null
            ? Icon(icon, color: const Color(0xFF1B4D3E), size: 20)
            : null,
        counterText: '',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF1B4D3E), width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      style: const TextStyle(fontFamily: 'Literata'),
    );
  }

  Widget _buildSelectorField({
    required String label,
    String? value,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final hasValue = value != null && value.isNotEmpty;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          border: Border.all(
            color: hasValue ? const Color(0xFF1B4D3E) : Colors.grey[400]!,
            width: hasValue ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: hasValue ? const Color(0xFF1B4D3E) : Colors.grey, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                hasValue ? value! : label,
                style: TextStyle(
                  fontFamily: 'Literata',
                  color: hasValue ? Colors.black87 : Colors.grey[600],
                  fontSize: 14,
                ),
              ),
            ),
            Icon(Icons.arrow_drop_down, color: Colors.grey[600]),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomFieldWidget(
    CustomColumn column,
    TextEditingController? textController,
    Map<String, dynamic> fieldValues,
    StateSetter setDialogState,
  ) {
    switch (column.type) {
      case CustomColumnType.text:
        return TextField(
          controller: textController,
          decoration: InputDecoration(
            labelText: column.name,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF1B4D3E), width: 2),
            ),
          ),
          style: const TextStyle(fontFamily: 'Literata'),
        );

      case CustomColumnType.number:
        return TextField(
          controller: textController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: column.name,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF1B4D3E), width: 2),
            ),
          ),
          style: const TextStyle(fontFamily: 'Literata'),
        );

      case CustomColumnType.decimal:
        return TextField(
          controller: textController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: column.name,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF1B4D3E), width: 2),
            ),
          ),
          style: const TextStyle(fontFamily: 'Literata'),
        );

      case CustomColumnType.boolean:
        return Row(
          children: [
            Expanded(
              child: Text(
                column.name,
                style: const TextStyle(
                  fontFamily: 'Literata',
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Switch(
              value: fieldValues[column.id] ?? false,
              activeColor: const Color(0xFF1B4D3E),
              onChanged: (value) {
                setDialogState(() => fieldValues[column.id] = value);
              },
            ),
          ],
        );

      case CustomColumnType.dropdown:
        return DropdownButtonFormField<String>(
          value: fieldValues[column.id],
          decoration: InputDecoration(
            labelText: column.name,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF1B4D3E), width: 2),
            ),
          ),
          items: (column.dropdownOptions ?? []).map((option) {
            return DropdownMenuItem(value: option, child: Text(option));
          }).toList(),
          onChanged: (value) {
            setDialogState(() => fieldValues[column.id] = value);
          },
        );

      case CustomColumnType.date:
        return InkWell(
          onTap: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: DateTime.now(),
              firstDate: DateTime(2000),
              lastDate: DateTime(2100),
            );
            if (date != null) {
              setDialogState(() {
                fieldValues[column.id] = date.toIso8601String().split('T').first;
              });
            }
          },
          child: InputDecorator(
            decoration: InputDecoration(
              labelText: column.name,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(
              fieldValues[column.id] ?? 'Select Date',
              style: TextStyle(
                fontFamily: 'Literata',
                color: fieldValues[column.id] != null
                    ? Colors.black87
                    : Colors.grey[600],
              ),
            ),
          ),
        );
    }
  }

  // ━━━ PICKER DIALOGS ━━━

  Future<Map<String, dynamic>?> _showCompanyPickerDialog(
    BuildContext context,
    List<Map<String, dynamic>> companies,
  ) async {
    return showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  _localizations.selectCompany,
                  style: const TextStyle(
                    fontFamily: 'Literata',
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: Color(0xFF1B4D3E),
                  ),
                ),
              ),
              const Divider(height: 1),
              Flexible(
                child: companies.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Text(
                            'No companies found',
                            style: TextStyle(
                              fontFamily: 'Literata',
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        itemCount: companies.length,
                        itemBuilder: (context, index) {
                          final company = companies[index];
                          return ListTile(
                            leading: const Icon(
                              Icons.business_rounded,
                              color: Color(0xFF1B4D3E),
                            ),
                            title: Text(
                              company['companyName'] ?? '',
                              style: const TextStyle(fontFamily: 'Literata'),
                            ),
                            onTap: () => Navigator.pop(context, company),
                          );
                        },
                      ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Future<Map<String, dynamic>?> _showSupplierPickerDialog(
    BuildContext context,
    List<Map<String, dynamic>> suppliers,
  ) async {
    return showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  _localizations.selectSupplier,
                  style: const TextStyle(
                    fontFamily: 'Literata',
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: Color(0xFF1B4D3E),
                  ),
                ),
              ),
              const Divider(height: 1),
              Flexible(
                child: suppliers.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Text(
                            'No suppliers found',
                            style: TextStyle(
                              fontFamily: 'Literata',
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        itemCount: suppliers.length,
                        itemBuilder: (context, index) {
                          final supplier = suppliers[index];
                          return ListTile(
                            leading: const Icon(
                              Icons.person_rounded,
                              color: Color(0xFF1B4D3E),
                            ),
                            title: Text(
                              supplier['fullName'] ?? '',
                              style: const TextStyle(fontFamily: 'Literata'),
                            ),
                            onTap: () => Navigator.pop(context, supplier),
                          );
                        },
                      ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

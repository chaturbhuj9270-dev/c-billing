import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'dart:ui';
import 'dart:async';
import 'package:c_billing/core/services/inventory_service.dart';
import 'package:c_billing/core/services/language_service.dart';
import 'package:c_billing/core/services/dashboard_refresh_service.dart';
import 'package:c_billing/core/services/purchase_settings_service.dart';
import 'package:c_billing/core/localization/app_localizations.dart';
import '../../data/repositories/firebase_product_repository.dart';
import '../../data/repositories/firebase_stock_repository.dart';
import '../../data/repositories/firebase_purchase_repository.dart';
import '../../data/datasources/product_cache_datasource.dart';
import '../../domain/entities/product.dart';
import '../../domain/entities/grouped_product.dart';
import '../../offline/controllers/purchase_batch_offline_controller.dart';
import '../../offline/entities/purchase_batch_entity.dart';
import '../../../product/offline/controllers/product_offline_controller.dart';
import '../../../product/offline/entities/product_entity.dart';
import '../../../product/data/services/product_sync_service.dart';
import '../../../supplier/offline/controllers/supplier_offline_controller.dart';
import '../../../company/offline/controllers/company_offline_controller.dart';

class ProductManagementPage extends StatefulWidget {
  final bool isEmbedded;

  const ProductManagementPage({super.key, this.isEmbedded = false});

  @override
  State<ProductManagementPage> createState() => _ProductManagementPageState();
}

class _ProductManagementPageState extends State<ProductManagementPage> {
  late InventoryService _inventoryService;
  late FirebaseFirestore _firestore;
  final _auth = FirebaseAuth.instance;
  final _cacheDataSource = ProductCacheDataSource();
  List<Product> _products = [];
  List<Product> _filteredProducts = [];
  List<Product> _displayedProducts = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  int _pageSize = 20;
  late ScrollController _scrollController;
  
  // Offline-first support
  StreamSubscription<List<ProductEntity>>? _productStreamSubscription;
  int _unsyncedCount = 0;
  
  // Latest purchase info for each product
  Map<String, Map<String, dynamic>> _latestPurchases = {};

  // Grouped view mode
  bool _isGroupedView = true;
  List<GroupedProduct> _groupedProducts = [];
  List<GroupedProduct> _filteredGroupedProducts = [];
  List<PurchaseBatchEntity> _allBatches = [];
  StreamSubscription<List<PurchaseBatchEntity>>? _batchStreamSubscription;

  // Localization variables
  late AppLocalizations _localizations;

  // Filter variables
  String _filterName = '';
  String _filterCategory = '';
  double? _filterMinPrice;
  double? _filterMaxPrice;
  int? _filterMinStock;
  int? _filterMaxStock;

  @override
  void initState() {
    super.initState();
    _localizations = AppLocalizations(LanguageService.instance.currentLanguage);
    LanguageService.instance.addListener(_onLanguageChanged);

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
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
    _checkUserAuthentication();
    _setupInitialData();
    _setupOfflineStream();
    _setupBatchStream();
  }

  void _onLanguageChanged() {
    setState(() {
      _localizations = AppLocalizations(
        LanguageService.instance.currentLanguage,
      );
    });
  }

  @override
  void dispose() {
    LanguageService.instance.removeListener(_onLanguageChanged);
    _productStreamSubscription?.cancel();
    _batchStreamSubscription?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 500) {
      _loadMoreProducts();
    }
  }

  void _loadMoreProducts() {
    if (!_isLoadingMore &&
        _displayedProducts.length < _filteredProducts.length) {
      setState(() => _isLoadingMore = true);
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          final startIndex = _displayedProducts.length;
          final endIndex = (startIndex + _pageSize).clamp(
            0,
            _filteredProducts.length,
          );
          setState(() {
            _displayedProducts.addAll(
              _filteredProducts.sublist(startIndex, endIndex),
            );
            _isLoadingMore = false;
          });
        }
      });
    }
  }

  void _checkUserAuthentication() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      print('[ERROR] No authenticated user - redirecting to login');
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    } else {
      print('[DEBUG] User authenticated: ${currentUser.uid}');
    }
  }

  Future<void> _setupInitialData() async {
    // 1. Load from cache immediately for < 0.5s loading
    final cached = await _cacheDataSource.getCachedProducts();
    if (cached != null && mounted) {
      setState(() {
        _products = cached;
        _applyFilters();
        _displayedProducts = _filteredProducts.take(_pageSize).toList();
      });
      print('[DEBUG] Loaded ${_products.length} products from cache');
    }

    // 2. Fetch from Firestore in background
    _loadProducts();
  }

  /// Setup offline stream for real-time Isar updates
  void _setupOfflineStream() {
    final offlineController = ProductOfflineController.instance;
    
    // Listen to Isar changes for instant UI updates
    _productStreamSubscription = offlineController.watchAllProducts().listen(
      (entities) {
        if (mounted) {
          // Convert entities to Product domain objects
          final products = entities.map((e) => Product(
            id: e.serverId ?? 'local_${e.id}',
            indexNo: e.indexNo,
            name: e.name,
            companyName: e.companyName,
            category: e.category,
            purchasePrice: e.purchasePrice,
            salesPrice: e.salesPrice,
            currentStock: e.currentStock,
            createdAt: e.createdAt,
            updatedAt: e.updatedAt,
            defaultSupplierId: e.defaultSupplierId,
            defaultSupplierName: e.defaultSupplierName,
          )).toList();
          
          setState(() {
            _products = products;
            _applyFilters();
            _displayedProducts = _filteredProducts.take(_pageSize).toList();
          });
          
          // Update unsynced count
          _updateUnsyncedCount();
        }
      },
      onError: (e) {
        print('[ERROR] Isar stream error: $e');
      },
    );
    
    // Initial unsynced count
    _updateUnsyncedCount();
  }
  
  Future<void> _updateUnsyncedCount() async {
    final count = await ProductOfflineController.instance.getUnsyncedCount();
    if (mounted && count != _unsyncedCount) {
      setState(() => _unsyncedCount = count);
    }
  }

  /// Setup batch stream for real-time grouped view updates
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
    // Find products that have NO batches (e.g., only initial stock)
    final productIdsInBatches = _allBatches.map((b) => b.productId).toSet();
    final productsWithoutBatches = _products.where(
      (p) => !productIdsInBatches.contains(p.id),
    ).toList();

    final grouped = GroupedProduct.buildFromBatches(
      _allBatches,
      productsWithoutBatches: productsWithoutBatches,
    );

    setState(() {
      _groupedProducts = grouped;
      _applyGroupedFilters();
    });
  }

  /// Apply filters to grouped products
  void _applyGroupedFilters() {
    _filteredGroupedProducts = _groupedProducts.where((group) {
      // Name filter
      if (_filterName.isNotEmpty &&
          !group.productName.toLowerCase().contains(_filterName.toLowerCase())) {
        return false;
      }

      // Price range filter (check if any sub-entry matches)
      if (_filterMinPrice != null && group.maxPurchasePrice < _filterMinPrice!) {
        return false;
      }
      if (_filterMaxPrice != null && group.minPurchasePrice > _filterMaxPrice!) {
        return false;
      }

      // Stock range filter
      if (_filterMinStock != null && group.totalStock < _filterMinStock!) {
        return false;
      }
      if (_filterMaxStock != null && group.totalStock > _filterMaxStock!) {
        return false;
      }

      return true;
    }).toList();
  }

  Future<void> _loadProducts() async {
    try {
      // Only show loader if we have no cached data
      if (_products.isEmpty) {
        setState(() => _isLoading = true);
      }

      print('[DEBUG] Loading products from Firestore...');
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        print('[ERROR] No authenticated user - cannot load products');
        setState(() => _isLoading = false);
        return;
      }

      print('[DEBUG] Fetching products for user: ${currentUser.uid}');
      final products = await _inventoryService.getAllProducts();
      print('[DEBUG] Loaded ${products.length} products from Firestore');

      if (mounted) {
        setState(() {
          _products = products;
          _applyFilters();
          _displayedProducts = _filteredProducts.take(_pageSize).toList();
          _isLoading = false;
        });
        // Save to cache for next time
        _cacheDataSource.saveProducts(products);
        
        // Import products to Isar for offline-first support
        _importProductsToIsar(products);
        
        // Load latest purchase info for each product
        _loadLatestPurchases(products);
      }
    } catch (e) {
      print('[ERROR] Failed to load products: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading products: $e')));
      }
    }
  }
  
  /// Import products from Firestore to Isar for offline support
  Future<void> _importProductsToIsar(List<Product> products) async {
    try {
      final serverProducts = products.map((p) => {
        'id': p.id,
        'indexNo': p.indexNo,
        'name': p.name,
        'companyName': p.companyName,
        'category': p.category,
        'purchasePrice': p.purchasePrice,
        'salesPrice': p.salesPrice,
        'currentStock': p.currentStock,
        'createdAt': p.createdAt.toIso8601String(),
        'updatedAt': p.updatedAt.toIso8601String(),
      }).toList();
      
      final imported = await ProductOfflineController.instance.importFromServer(serverProducts);
      print('[DEBUG] Imported $imported products to Isar');
    } catch (e) {
      print('[ERROR] Failed to import products to Isar: $e');
    }
  }
  
  Future<void> _loadLatestPurchases(List<Product> products) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return;
      
      final purchasesRef = _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('purchases');
      
      Map<String, Map<String, dynamic>> latestPurchases = {};
      
      // Load latest purchase for each product
      for (final product in products) {
        final querySnapshot = await purchasesRef
            .where('productId', isEqualTo: product.id)
            .orderBy('createdAt', descending: true)
            .limit(1)
            .get();
        
        if (querySnapshot.docs.isNotEmpty) {
          latestPurchases[product.id] = querySnapshot.docs.first.data();
        }
      }
      
      if (mounted) {
        setState(() {
          _latestPurchases = latestPurchases;
        });
      }
    } catch (e) {
      print('[DEBUG] Error loading latest purchases: $e');
    }
  }

  void _applyFilters() {
    _filteredProducts = _products.where((product) {
      // Name filter (case-insensitive)
      if (_filterName.isNotEmpty &&
          !product.name.toLowerCase().contains(_filterName.toLowerCase())) {
        return false;
      }

      // Category filter (case-insensitive)
      if (_filterCategory.isNotEmpty &&
          !product.category.toLowerCase().contains(
            _filterCategory.toLowerCase(),
          )) {
        return false;
      }

      // Purchase price range filter
      if (_filterMinPrice != null && product.purchasePrice < _filterMinPrice!) {
        return false;
      }
      if (_filterMaxPrice != null && product.purchasePrice > _filterMaxPrice!) {
        return false;
      }

      // Stock quantity range filter
      if (_filterMinStock != null && product.currentStock < _filterMinStock!) {
        return false;
      }
      if (_filterMaxStock != null && product.currentStock > _filterMaxStock!) {
        return false;
      }

      return true;
    }).toList();

    // Also rebuild grouped filters when flat filters change
    _applyGroupedFilters();
  }

  void _clearFilters() {
    setState(() {
      _filterName = '';
      _filterCategory = '';
      _filterMinPrice = null;
      _filterMaxPrice = null;
      _filterMinStock = null;
      _filterMaxStock = null;
      _applyFilters();
    });
  }

  List<String> _getAllCategories() {
    final categories = <String>{};
    for (var product in _products) {
      if (product.category.isNotEmpty) {
        categories.add(product.category);
      }
    }
    return categories.toList()..sort();
  }

  void _showEditProductDialog(Product product) {
    final nameController = TextEditingController(text: product.name);
    final categoryController = TextEditingController(text: product.category);

    showDialog(
      context: context,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: AlertDialog(
          backgroundColor: Colors.white.withValues(alpha: 0.95),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: Colors.white.withValues(alpha: 0.3),
              width: 1.5,
            ),
          ),
          title: Text(
            _localizations.editProduct,
            style: const TextStyle(
              fontFamily: 'Literata',
              fontWeight: FontWeight.w700,
              color: Color(0xFF1B4D3E),
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: _localizations.productName,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Color(0xFF1B4D3E),
                        width: 2,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: categoryController,
                  decoration: InputDecoration(
                    labelText: _localizations.category,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Color(0xFF1B4D3E),
                        width: 2,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Purchase Price - Read Only (Updated from Purchase Page)
                TextField(
                  controller: TextEditingController(
                    text: product.purchasePrice.toString(),
                  ),
                  enabled: false,
                  decoration: InputDecoration(
                    labelText: _localizations.purchasePriceReadOnly,
                    hintText: _localizations.updatedFromPurchasePage,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    disabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Colors.grey[300]!,
                        width: 1,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Sales Price - Read Only (Updated from Purchase Page)
                TextField(
                  controller: TextEditingController(
                    text: product.salesPrice.toString(),
                  ),
                  enabled: false,
                  decoration: InputDecoration(
                    labelText: _localizations.salesPriceReadOnly,
                    hintText: _localizations.updatedFromPurchasePage,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    disabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Colors.grey[300]!,
                        width: 1,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Current Stock - Read Only
                TextField(
                  controller: TextEditingController(
                    text: product.currentStock.toString(),
                  ),
                  enabled: false,
                  decoration: InputDecoration(
                    labelText: _localizations.currentStockReadOnly,
                    hintText: _localizations.updatedFromPurchasePage,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    disabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Colors.grey[300]!,
                        width: 1,
                      ),
                    ),
                  ),
                ),
              ],
            ),
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
                try {
                  // Offline-first: Update in Isar
                  final offlineController = ProductOfflineController.instance;
                  
                  // Find local ID by server ID
                  final existing = await offlineController.getProductByServerId(product.id);
                  
                  if (existing != null) {
                    await offlineController.updateProduct(
                      id: existing.id,
                      name: nameController.text,
                      category: categoryController.text,
                    );
                  } else {
                    // Fallback to Firebase direct update if not in Isar
                    await _inventoryService.updateProduct(product.copyWith(
                      name: nameController.text,
                      category: categoryController.text,
                      updatedAt: DateTime.now(),
                    ));
                  }
                  
                  // Notify dashboard to refresh
                  DashboardRefreshService.instance.notifyDataChanged(DataChangeType.product);
                  
                  // Trigger background sync if online
                  ProductSyncService.instance.syncNow();
                  
                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          _localizations.productUpdatedSuccessfully,
                        ),
                        backgroundColor: const Color(0xFF1B4D3E),
                      ),
                    );
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${_localizations.error}: $e')),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1B4D3E),
              ),
              child: Text(
                _localizations.update,
                style: const TextStyle(
                  fontFamily: 'Literata',
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _deleteProduct(Product product) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_localizations.deleteProduct),
        content: Text(
          '${_localizations.deleteConfirmation} "${product.name}"?\n\n${_localizations.actionCannotBeUndone}.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(_localizations.cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                // Offline-first: Delete from Isar
                final offlineController = ProductOfflineController.instance;
                
                // Find local ID by server ID
                final existing = await offlineController.getProductByServerId(product.id);
                
                if (existing != null) {
                  await offlineController.deleteProduct(existing.id);
                } else {
                  // Fallback to Firebase direct delete if not in Isar
                  await _inventoryService.deleteProduct(product.id);
                }
                
                // Notify dashboard to refresh
                DashboardRefreshService.instance.notifyDataChanged(DataChangeType.product);
                
                // Trigger background sync if online
                ProductSyncService.instance.syncNow();
                
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(_localizations.productDeletedSuccessfully),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${_localizations.error}: $e')),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(_localizations.delete),
          ),
        ],
      ),
    );
  }

  void _showFilterDialog() {
    final nameController = TextEditingController(text: _filterName);
    final minPriceController = TextEditingController(
      text: _filterMinPrice?.toString() ?? '',
    );
    final maxPriceController = TextEditingController(
      text: _filterMaxPrice?.toString() ?? '',
    );
    final minStockController = TextEditingController(
      text: _filterMinStock?.toString() ?? '',
    );
    final maxStockController = TextEditingController(
      text: _filterMaxStock?.toString() ?? '',
    );
    String? selectedCategory = _filterCategory.isEmpty ? null : _filterCategory;
    final allCategories = _getAllCategories();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: AlertDialog(
            backgroundColor: Colors.white.withValues(alpha: 0.95),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(
                color: Colors.white.withValues(alpha: 0.3),
                width: 1.5,
              ),
            ),
            title: Text(
              _localizations.filterProducts,
              style: const TextStyle(
                fontFamily: 'Literata',
                fontWeight: FontWeight.w700,
                color: Color(0xFF1B4D3E),
              ),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: _localizations.productName,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Color(0xFF1B4D3E),
                          width: 2,
                        ),
                      ),
                      prefixIcon: const Icon(Icons.search),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[400]!),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DropdownButton<String>(
                      isExpanded: true,
                      underline: const SizedBox(),
                      value: selectedCategory,
                      hint: Text(_localizations.selectCategory),
                      items: [
                        DropdownMenuItem(
                          value: null,
                          child: Text(_localizations.allCategories),
                        ),
                        ...allCategories.map((category) {
                          return DropdownMenuItem(
                            value: category,
                            child: Text(category),
                          );
                        }),
                      ],
                      onChanged: (value) {
                        setState(() {
                          selectedCategory = value;
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '${_localizations.priceRange} (₹)',
                    style: const TextStyle(
                      fontFamily: 'Literata',
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: minPriceController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: _localizations.minPrice,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Color(0xFF1B4D3E),
                                width: 2,
                              ),
                            ),
                            prefixIcon: const Icon(Icons.trending_down),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: maxPriceController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: _localizations.maxPrice,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Color(0xFF1B4D3E),
                                width: 2,
                              ),
                            ),
                            prefixIcon: const Icon(Icons.trending_up),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '${_localizations.stockRange} (${_localizations.units})',
                    style: const TextStyle(
                      fontFamily: 'Literata',
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: minStockController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: _localizations.minStock,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Color(0xFF1B4D3E),
                                width: 2,
                              ),
                            ),
                            prefixIcon: const Icon(Icons.inventory_2),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: maxStockController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: _localizations.maxStock,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Color(0xFF1B4D3E),
                                width: 2,
                              ),
                            ),
                            prefixIcon: const Icon(Icons.inventory),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  _clearFilters();
                  Navigator.pop(context);
                },
                child: Text(
                  _localizations.clearFilters,
                  style: const TextStyle(
                    fontFamily: 'Literata',
                    color: Colors.red,
                  ),
                ),
              ),
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
                onPressed: () {
                  this.setState(() {
                    _filterName = nameController.text;
                    _filterCategory = selectedCategory ?? '';
                    _filterMinPrice = double.tryParse(minPriceController.text);
                    _filterMaxPrice = double.tryParse(maxPriceController.text);
                    _filterMinStock = int.tryParse(minStockController.text);
                    _filterMaxStock = int.tryParse(maxStockController.text);
                    _applyFilters();
                  });
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1B4D3E),
                ),
                child: Text(
                  _localizations.apply,
                  style: const TextStyle(
                    fontFamily: 'Literata',
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddProductDialog() {
    final nameController = TextEditingController();
    final categoryController = TextEditingController();
    final purchasePriceController = TextEditingController();
    final salesPriceController = TextEditingController();
    final initialStockController = TextEditingController(text: '0');
    Map<String, dynamic>? dialogSelectedCompany;
    Map<String, dynamic>? dialogSelectedSupplier;
    List<Map<String, dynamic>> dialogCompanies = [];
    List<Map<String, dynamic>> dialogSuppliers = [];

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

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: AlertDialog(
            backgroundColor: Colors.white.withValues(alpha: 0.95),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(
                color: Colors.white.withValues(alpha: 0.3),
                width: 1.5,
              ),
            ),
            title: Text(
              _localizations.addNewProduct,
              style: const TextStyle(
                fontFamily: 'Literata',
                fontWeight: FontWeight.w700,
                color: Color(0xFF1B4D3E),
              ),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: _localizations.productName,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Color(0xFF1B4D3E),
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Company selector
                  InkWell(
                    onTap: () async {
                      final company = await _showCompanyPickerDialog(context, dialogCompanies);
                      if (company != null) {
                        setDialogState(() {
                          dialogSelectedCompany = company;
                        });
                      }
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: dialogSelectedCompany != null ? const Color(0xFF1B4D3E) : Colors.grey[400]!,
                          width: dialogSelectedCompany != null ? 2 : 1,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.business, color: dialogSelectedCompany != null ? const Color(0xFF1B4D3E) : Colors.grey, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              dialogSelectedCompany?['companyName'] ?? _localizations.selectCompany,
                              style: TextStyle(
                                fontFamily: 'Literata',
                                color: dialogSelectedCompany != null ? Colors.black87 : Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                          ),
                          Icon(Icons.arrow_drop_down, color: Colors.grey[600]),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Supplier selector
                  InkWell(
                    onTap: () async {
                      final supplier = await _showSupplierPickerDialog(context, dialogSuppliers);
                      if (supplier != null) {
                        setDialogState(() {
                          dialogSelectedSupplier = supplier;
                        });
                      }
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: dialogSelectedSupplier != null ? const Color(0xFF1B4D3E) : Colors.grey[400]!,
                          width: dialogSelectedSupplier != null ? 2 : 1,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.person, color: dialogSelectedSupplier != null ? const Color(0xFF1B4D3E) : Colors.grey, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              dialogSelectedSupplier?['fullName'] ?? _localizations.selectSupplier,
                              style: TextStyle(
                                fontFamily: 'Literata',
                                color: dialogSelectedSupplier != null ? Colors.black87 : Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                          ),
                          Icon(Icons.arrow_drop_down, color: Colors.grey[600]),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: categoryController,
                    decoration: InputDecoration(
                      labelText: _localizations.category,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Color(0xFF1B4D3E),
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: purchasePriceController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: _localizations.purchasePrice,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Color(0xFF1B4D3E),
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: salesPriceController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: _localizations.salesPrice,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Color(0xFF1B4D3E),
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: initialStockController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: _localizations.initialStock,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Color(0xFF1B4D3E),
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
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
                  try {
                    // Offline-first: Save to Isar immediately
                    final offlineController = ProductOfflineController.instance;
                    await offlineController.addProduct(
                      name: nameController.text,
                      companyName: dialogSelectedCompany?['companyName'] ?? '',
                      category: categoryController.text,
                      purchasePrice: double.parse(purchasePriceController.text),
                      salesPrice: double.parse(salesPriceController.text),
                      currentStock: int.parse(initialStockController.text),
                      defaultSupplierId: dialogSelectedSupplier?['id'],
                      defaultSupplierName: dialogSelectedSupplier?['fullName'],
                    );
                    
                    // Notify dashboard to refresh
                    DashboardRefreshService.instance.notifyDataChanged(DataChangeType.product);
                    
                    // Trigger background sync if online
                    ProductSyncService.instance.syncNow();
                    
                    if (mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(_localizations.productAddedSuccessfully),
                          backgroundColor: const Color(0xFF1B4D3E),
                        ),
                      );
                    }
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('${_localizations.error}: $e')),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1B4D3E),
                ),
                child: Text(
                  _localizations.add,
                  style: TextStyle(fontFamily: 'Literata', color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Company picker dialog for product creation
  Future<Map<String, dynamic>?> _showCompanyPickerDialog(BuildContext parentContext, List<Map<String, dynamic>> companies) async {
    return await showDialog<Map<String, dynamic>>(
      context: parentContext,
      builder: (context) {
        var filtered = companies.toList();
        return StatefulBuilder(
          builder: (context, setPickerState) => AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text(_localizations.selectCompany, style: const TextStyle(fontFamily: 'Literata', fontWeight: FontWeight.w700, color: Color(0xFF1B4D3E), fontSize: 16)),
            content: SizedBox(
              width: double.maxFinite,
              height: 300,
              child: Column(
                children: [
                  TextField(
                    decoration: InputDecoration(
                      hintText: _localizations.searchByCompany,
                      prefixIcon: const Icon(Icons.search, size: 20),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      isDense: true,
                    ),
                    onChanged: (q) {
                      setPickerState(() {
                        filtered = companies.where((c) =>
                          (c['companyName'] as String? ?? '').toLowerCase().contains(q.toLowerCase())
                        ).toList();
                      });
                    },
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: filtered.isEmpty
                      ? Center(child: Text(_localizations.noCompaniesFound, style: TextStyle(color: Colors.grey[500], fontFamily: 'Literata')))
                      : ListView.builder(
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            final company = filtered[index];
                            return ListTile(
                              dense: true,
                              leading: const Icon(Icons.business, color: Color(0xFF1B4D3E), size: 20),
                              title: Text(company['companyName'] ?? '', style: const TextStyle(fontFamily: 'Literata', fontSize: 14)),
                              onTap: () => Navigator.pop(context, company),
                            );
                          },
                        ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// Supplier picker dialog for product creation
  Future<Map<String, dynamic>?> _showSupplierPickerDialog(BuildContext parentContext, List<Map<String, dynamic>> suppliers) async {
    return await showDialog<Map<String, dynamic>>(
      context: parentContext,
      builder: (context) {
        var filtered = suppliers.toList();
        return StatefulBuilder(
          builder: (context, setPickerState) => AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text(_localizations.selectSupplier, style: const TextStyle(fontFamily: 'Literata', fontWeight: FontWeight.w700, color: Color(0xFF1B4D3E), fontSize: 16)),
            content: SizedBox(
              width: double.maxFinite,
              height: 300,
              child: Column(
                children: [
                  TextField(
                    decoration: InputDecoration(
                      hintText: _localizations.searchBySupplier,
                      prefixIcon: const Icon(Icons.search, size: 20),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      isDense: true,
                    ),
                    onChanged: (q) {
                      setPickerState(() {
                        filtered = suppliers.where((s) =>
                          (s['fullName'] as String? ?? '').toLowerCase().contains(q.toLowerCase())
                        ).toList();
                      });
                    },
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: filtered.isEmpty
                      ? Center(child: Text(_localizations.noSuppliersFound, style: TextStyle(color: Colors.grey[500], fontFamily: 'Literata')))
                      : ListView.builder(
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            final supplier = filtered[index];
                            return ListTile(
                              dense: true,
                              leading: const Icon(Icons.person, color: Color(0xFF1B4D3E), size: 20),
                              title: Text(supplier['fullName'] ?? '', style: const TextStyle(fontFamily: 'Literata', fontSize: 14)),
                              onTap: () => Navigator.pop(context, supplier),
                            );
                          },
                        ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatsCards() {
    if (_isGroupedView) {
      final totalGroups = _filteredGroupedProducts.length;
      final totalStock = _filteredGroupedProducts.fold<int>(
          0, (sum, g) => sum + g.totalStock);
      final outOfStockGroups =
          _filteredGroupedProducts.where((g) => g.totalStock == 0).length;

      return Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: _buildStatCard(
                title: _localizations.totalProducts,
                value: totalGroups,
                icon: Icons.inventory_2,
                iconColor: const Color(0xFF1B4D3E),
                backgroundColor: const Color(0xFF1B4D3E).withOpacity(0.1),
              ),
            ),
            Expanded(
              child: _buildStatCard(
                title: 'Total Stock',
                value: totalStock,
                icon: Icons.widgets_rounded,
                iconColor: Colors.blue,
                backgroundColor: Colors.blue.withOpacity(0.1),
              ),
            ),
            Expanded(
              child: _buildStatCard(
                title: _localizations.outOfStock,
                value: outOfStockGroups,
                icon: Icons.warning_amber,
                iconColor: Colors.red,
                backgroundColor: Colors.red.withOpacity(0.1),
              ),
            ),
          ],
        ),
      );
    }

    final outOfStockCount = _products.where((p) => p.currentStock == 0).length;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              title: _localizations.totalProducts,
              value: _products.length,
              icon: Icons.inventory_2,
              iconColor: const Color(0xFF1B4D3E),
              backgroundColor: const Color(0xFF1B4D3E).withOpacity(0.1),
            ),
          ),
          Expanded(
            child: _buildStatCard(
              title: _localizations.outOfStock,
              value: outOfStockCount,
              icon: Icons.warning_amber,
              iconColor: Colors.red,
              backgroundColor: Colors.red.withOpacity(0.1),
            ),
          ),
          if (_unsyncedCount > 0)
            Expanded(
              child: _buildStatCard(
                title: 'Pending Sync',
                value: _unsyncedCount,
                icon: Icons.cloud_upload_outlined,
                iconColor: Colors.orange,
                backgroundColor: Colors.orange.withOpacity(0.1),
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
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: iconColor, size: 20),
            const SizedBox(height: 4),
            Text(
              value.toString(),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                fontFamily: 'Literata',
              ),
            ),
            const SizedBox(height: 2),
            Text(
              title,
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[600],
                fontFamily: 'Literata',
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: !widget.isEmbedded,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          _localizations.productManagement,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            fontFamily: 'Literata',
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF1B4D3E),
        centerTitle: false,
        titleSpacing: 12,
        actions: [
          // View toggle button
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: IconButton(
              onPressed: () {
                setState(() {
                  _isGroupedView = !_isGroupedView;
                  if (_isGroupedView) {
                    _rebuildGroupedProducts();
                  }
                });
              },
              icon: Icon(
                _isGroupedView ? Icons.view_list_rounded : Icons.layers_rounded,
                size: 22,
              ),
              tooltip: _isGroupedView ? 'Flat View' : 'Grouped View',
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Center(
              child: IconButton(
                onPressed: _showFilterDialog,
                icon: Stack(
                  alignment: Alignment.topRight,
                  children: [
                    const Icon(Icons.filter_list_rounded),
                    if (_filterName.isNotEmpty ||
                        _filterCategory.isNotEmpty ||
                        _filterMinPrice != null ||
                        _filterMaxPrice != null ||
                        _filterMinStock != null ||
                        _filterMaxStock != null)
                      Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
                tooltip: _localizations.filters,
              ),
            ),
          ),
        ],
      ),
      backgroundColor: Colors.white,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _products.isEmpty
          ? Center(
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
                    _localizations.noProductsFound,
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                      fontFamily: 'Literata',
                    ),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                _buildStatsCards(),
                Expanded(
                  child: _isGroupedView
                      ? _buildGroupedProductList()
                      : _filteredProducts.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.search_off,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _localizations.noProductsMatchFilter,
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey[600],
                                  fontFamily: 'Literata',
                                ),
                              ),
                              const SizedBox(height: 12),
                              ElevatedButton(
                                onPressed: _clearFilters,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF1B4D3E),
                                ),
                                child: Text(_localizations.clearFilters),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filteredProducts.length,
                          itemBuilder: (context, index) {
                            final product = _filteredProducts[index];
                            final isLowStock = product.isLowStock();

                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              elevation: 2,
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            product.name,
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.w700,
                                              fontFamily: 'Literata',
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: isLowStock
                                                ? Colors.red.withValues(
                                                    alpha: 0.2,
                                                  )
                                                : Colors.green.withValues(
                                                    alpha: 0.2,
                                                  ),
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                          ),
                                          child: Text(
                                            isLowStock
                                                ? _localizations.lowStock
                                                : _localizations.inStock,
                                            style: TextStyle(
                                              color: isLowStock
                                                  ? Colors.red
                                                  : Colors.green,
                                              fontWeight: FontWeight.w600,
                                              fontFamily: 'Literata',
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Category',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey[600],
                                                fontFamily: 'Literata',
                                              ),
                                            ),
                                            Text(
                                              product.category,
                                              style: const TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                                fontFamily: 'Literata',
                                              ),
                                            ),
                                          ],
                                        ),
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.end,
                                          children: [
                                            Text(
                                              _localizations.currentStock,
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey[600],
                                                fontFamily: 'Literata',
                                              ),
                                            ),
                                            Text(
                                              '${product.currentStock} ${_localizations.units}',
                                              style: const TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                                fontFamily: 'Literata',
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              _localizations.purchasePrice,
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey[600],
                                                fontFamily: 'Literata',
                                              ),
                                            ),
                                            Text(
                                              '₹${product.purchasePrice.toStringAsFixed(2)}',
                                              style: const TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                                fontFamily: 'Literata',
                                              ),
                                            ),
                                          ],
                                        ),
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.end,
                                          children: [
                                            Text(
                                              _localizations.salesPrice,
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey[600],
                                                fontFamily: 'Literata',
                                              ),
                                            ),
                                            Text(
                                              '₹${product.salesPrice.toStringAsFixed(2)}',
                                              style: const TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                                fontFamily: 'Literata',
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.blue.withValues(
                                          alpha: 0.1,
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            _localizations.stockValue,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[600],
                                              fontFamily: 'Literata',
                                            ),
                                          ),
                                          Text(
                                            '₹${product.getStockValue().toStringAsFixed(2)}',
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w700,
                                              fontFamily: 'Literata',
                                              color: Colors.blue,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    // Latest Purchase Info Section
                                    _buildLatestPurchaseInfo(product.id),
                                    const SizedBox(height: 12),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        IconButton(
                                          onPressed: () =>
                                              _showEditProductDialog(product),
                                          icon: const Icon(Icons.edit),
                                          color: Colors.blue,
                                          iconSize: 20,
                                          padding: const EdgeInsets.all(4),
                                          constraints: const BoxConstraints(),
                                        ),
                                        const SizedBox(width: 4),
                                        IconButton(
                                          onPressed: () =>
                                              _deleteProduct(product),
                                          icon: const Icon(Icons.delete),
                                          color: Colors.red,
                                          iconSize: 20,
                                          padding: const EdgeInsets.all(4),
                                          constraints: const BoxConstraints(),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1B4D3E), Color(0xFF2E7D32)],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1B4D3E).withOpacity(0.4),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
            BoxShadow(
              color: const Color(0xFF1B4D3E).withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          child: InkWell(
            onTap: _showAddProductDialog,
            borderRadius: BorderRadius.circular(20),
            splashColor: Colors.white.withOpacity(0.2),
            highlightColor: Colors.white.withOpacity(0.1),
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: const Icon(
                Icons.add_rounded,
                color: Colors.white,
                size: 28,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGroupedProductList() {
    if (_filteredGroupedProducts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              _localizations.noProductsMatchFilter,
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontFamily: 'Literata',
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _clearFilters,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1B4D3E),
              ),
              child: Text(_localizations.clearFilters),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredGroupedProducts.length,
      itemBuilder: (context, index) {
        final group = _filteredGroupedProducts[index];
        final isLow = group.isLowStock();

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          clipBehavior: Clip.antiAlias,
          child: Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              tilePadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              childrenPadding: EdgeInsets.zero,
              leading: CircleAvatar(
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
                  fontSize: 16,
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
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
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
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
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
                    const Spacer(),
                    if (group.companies.isNotEmpty)
                      Flexible(
                        child: Text(
                          group.companies.join(', '),
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600],
                            fontFamily: 'Literata',
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                ),
              ),
              children: [
                // Summary bar
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
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
                // Batch details table header
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    border: Border(
                      bottom: BorderSide(color: Colors.grey[300]!),
                    ),
                  ),
                  child: const Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Text(
                          'Company',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'Literata',
                            color: Color(0xFF1B4D3E),
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          'Date',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'Literata',
                            color: Color(0xFF1B4D3E),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          'Price',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'Literata',
                            color: Color(0xFF1B4D3E),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          'Sell ₹',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'Literata',
                            color: Color(0xFF1B4D3E),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      Expanded(
                        flex: 1,
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

                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: isEven ? Colors.white : Colors.grey[50],
                      border: Border(
                        bottom: BorderSide(
                          color: Colors.grey[200]!,
                          width: 0.5,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: Text(
                            entry.companyName.isNotEmpty
                                ? entry.companyName
                                : '—',
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
      },
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

  Widget _buildLatestPurchaseInfo(String productId) {
    final purchaseData = _latestPurchases[productId];
    if (purchaseData == null) return const SizedBox.shrink();
    
    final unit = purchaseData['unit'] as String?;
    final warrantyMonths = purchaseData['warrantyMonths'] as int?;
    final productionDate = purchaseData['productionDate'];
    final expiryDate = purchaseData['expiryDate'];
    
    // Check if any data exists to show
    final hasUnit = unit != null && unit.isNotEmpty;
    final hasWarranty = warrantyMonths != null && warrantyMonths > 0;
    final hasProductionDate = productionDate != null;
    final hasExpiryDate = expiryDate != null;
    
    if (!hasUnit && !hasWarranty && !hasProductionDate && !hasExpiryDate) {
      return const SizedBox.shrink();
    }
    
    final dateFormat = DateFormat('dd MMM yyyy');
    
    // Parse dates
    DateTime? parsedProductionDate;
    DateTime? parsedExpiryDate;
    
    if (hasProductionDate) {
      if (productionDate is Timestamp) {
        parsedProductionDate = productionDate.toDate();
      } else if (productionDate is String) {
        parsedProductionDate = DateTime.tryParse(productionDate);
      }
    }
    
    if (hasExpiryDate) {
      if (expiryDate is Timestamp) {
        parsedExpiryDate = expiryDate.toDate();
      } else if (expiryDate is String) {
        parsedExpiryDate = DateTime.tryParse(expiryDate);
      }
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.purple.withOpacity(0.08),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.purple.withOpacity(0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.receipt_long_rounded, size: 16, color: Colors.purple[700]),
                  const SizedBox(width: 6),
                  Text(
                    'Last Purchase Info',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Literata',
                      color: Colors.purple[700],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 16,
                runSpacing: 8,
                children: [
                  if (hasUnit)
                    _buildPurchaseInfoChip(
                      Icons.straighten_rounded,
                      'Unit',
                      unit,
                      Colors.teal,
                    ),
                  if (hasWarranty)
                    _buildPurchaseInfoChip(
                      Icons.verified_user_rounded,
                      'Warranty',
                      PurchaseSettingsService.instance.getWarrantyLabel(warrantyMonths),
                      Colors.deepPurple,
                    ),
                  if (parsedProductionDate != null)
                    _buildPurchaseInfoChip(
                      Icons.factory_rounded,
                      'Mfg Date',
                      dateFormat.format(parsedProductionDate),
                      Colors.orange,
                    ),
                  if (parsedExpiryDate != null)
                    _buildPurchaseInfoChip(
                      Icons.event_busy_rounded,
                      'Exp Date',
                      dateFormat.format(parsedExpiryDate),
                      _isExpired(parsedExpiryDate) ? Colors.red : Colors.green,
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildPurchaseInfoChip(IconData icon, String label, String value, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[600],
                fontFamily: 'Literata',
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                fontFamily: 'Literata',
                color: color,
              ),
            ),
          ],
        ),
      ],
    );
  }
  
  bool _isExpired(DateTime expiryDate) {
    return expiryDate.isBefore(DateTime.now());
  }
}

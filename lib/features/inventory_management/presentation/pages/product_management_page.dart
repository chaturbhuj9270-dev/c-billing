import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:ui';
import 'package:c_billing/core/services/inventory_service.dart';
import '../../data/repositories/firebase_product_repository.dart';
import '../../data/repositories/firebase_stock_repository.dart';
import '../../data/repositories/firebase_purchase_repository.dart';
import '../../data/datasources/product_cache_datasource.dart';
import '../../domain/entities/product.dart';

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
  }

  @override
  void dispose() {
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
          title: const Text(
            'Edit Product',
            style: TextStyle(
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
                    labelText: 'Product Name',
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
                    labelText: 'Category',
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
                    labelText: 'Purchase Price (Read-Only)',
                    hintText: 'Updated from Purchase Page',
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
                    labelText: 'Sales Price (Read-Only)',
                    hintText: 'Updated from Purchase Page',
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
                    labelText: 'Current Stock (Read-Only)',
                    hintText: 'Updated from Purchase Page',
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
              child: const Text(
                'Cancel',
                style: TextStyle(fontFamily: 'Literata', color: Colors.grey),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  final updatedProduct = product.copyWith(
                    name: nameController.text,
                    companyName: product.companyName,
                    category: categoryController.text,
                    purchasePrice: product.purchasePrice,
                    salesPrice: product.salesPrice,
                    currentStock: product.currentStock,
                    updatedAt: DateTime.now(),
                  );

                  // Optimistic update
                  final index = _products.indexWhere((p) => p.id == product.id);
                  if (index != -1) {
                    setState(() {
                      _products[index] = updatedProduct;
                      _applyFilters();
                      _displayedProducts = _filteredProducts
                          .take(_pageSize)
                          .toList();
                    });
                    _cacheDataSource.saveProducts(_products);
                  }

                  await _inventoryService.updateProduct(updatedProduct);
                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Product updated successfully'),
                      ),
                    );
                  }
                } catch (e) {
                  // Reload on error to revert optimistic update
                  _loadProducts();
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1B4D3E),
              ),
              child: const Text(
                'Update',
                style: TextStyle(fontFamily: 'Literata', color: Colors.white),
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
        title: const Text('Delete Product'),
        content: Text(
          'Are you sure you want to delete "${product.name}"?\n\nThis action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                // Optimistic delete
                setState(() {
                  _products.removeWhere((p) => p.id == product.id);
                  _applyFilters();
                  _displayedProducts = _filteredProducts
                      .take(_pageSize)
                      .toList();
                });
                _cacheDataSource.saveProducts(_products);

                await _inventoryService.deleteProduct(product.id);
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Product deleted successfully'),
                    ),
                  );
                }
              } catch (e) {
                // Reload on error to revert optimistic delete
                _loadProducts();
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text('Error: $e')));
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
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
            title: const Text(
              'Filter Products',
              style: TextStyle(
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
                      labelText: 'Product Name',
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
                      hint: const Text('Select Category'),
                      items: [
                        const DropdownMenuItem(
                          value: null,
                          child: Text('All Categories'),
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
                  const Text(
                    'Price Range (₹)',
                    style: TextStyle(
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
                            labelText: 'Min',
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
                            labelText: 'Max',
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
                  const Text(
                    'Stock Range (Units)',
                    style: TextStyle(
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
                            labelText: 'Min',
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
                            labelText: 'Max',
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
                child: const Text(
                  'Clear All',
                  style: TextStyle(fontFamily: 'Literata', color: Colors.red),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Cancel',
                  style: TextStyle(fontFamily: 'Literata', color: Colors.grey),
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
                child: const Text(
                  'Apply',
                  style: TextStyle(fontFamily: 'Literata', color: Colors.white),
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
          title: const Text(
            'Add New Product',
            style: TextStyle(
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
                    labelText: 'Product Name',
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
                    labelText: 'Category',
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
                    labelText: 'Purchase Price',
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
                    labelText: 'Sales Price',
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
                    labelText: 'Initial Stock',
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
              child: const Text(
                'Cancel',
                style: TextStyle(fontFamily: 'Literata', color: Colors.grey),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  final newProduct = Product(
                    id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
                    indexNo: 0, // Will be generated by the service
                    name: nameController.text,
                    companyName: '',
                    category: '', // Category is optional, set to empty
                    purchasePrice: double.parse(purchasePriceController.text),
                    salesPrice: double.parse(salesPriceController.text),
                    currentStock: int.parse(initialStockController.text),
                    createdAt: DateTime.now(),
                    updatedAt: DateTime.now(),
                  );

                  // Optimistic add
                  setState(() {
                    _products.insert(0, newProduct);
                    _applyFilters();
                    _displayedProducts = _filteredProducts
                        .take(_pageSize)
                        .toList();
                  });
                  _cacheDataSource.saveProducts(_products);

                  await _inventoryService.createProduct(
                    name: nameController.text,
                    companyName: '',
                    category: '', // Category is optional
                    purchasePrice: double.parse(purchasePriceController.text),
                    salesPrice: double.parse(salesPriceController.text),
                    initialStock: int.parse(initialStockController.text),
                  );
                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Product added successfully'),
                      ),
                    );
                  }
                } catch (e) {
                  // Reload on error to revert optimistic add
                  _loadProducts();
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1B4D3E),
              ),
              child: const Text(
                'Add',
                style: TextStyle(fontFamily: 'Literata', color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCards() {
    final outOfStockCount = _products.where((p) => p.currentStock == 0).length;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              title: 'Total Products',
              value: _products.length,
              icon: Icons.inventory_2,
              iconColor: const Color(0xFF1B4D3E),
              backgroundColor: const Color(0xFF1B4D3E).withOpacity(0.1),
            ),
          ),
          Expanded(
            child: _buildStatCard(
              title: 'Out of Stock',
              value: outOfStockCount,
              icon: Icons.warning_amber,
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
        title: const Text(
          'Product Management',
          style: TextStyle(
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
                tooltip: 'Filters',
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
                    'No products found',
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
                  child: _filteredProducts.isEmpty
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
                                'No products match your filters',
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
                                child: const Text('Clear Filters'),
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
                                                ? 'Low Stock'
                                                : 'In Stock',
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
                                              'Current Stock',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey[600],
                                                fontFamily: 'Literata',
                                              ),
                                            ),
                                            Text(
                                              '${product.currentStock} units',
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
                                              'Purchase Price',
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
                                              'Sales Price',
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
                                            'Stock Value',
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
}

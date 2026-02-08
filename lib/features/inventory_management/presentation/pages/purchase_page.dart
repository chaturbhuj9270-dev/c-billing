import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:ui';
import 'package:c_billing/core/services/inventory_service.dart';
import 'package:c_billing/core/services/language_service.dart';
import 'package:c_billing/core/localization/app_localizations.dart';
import '../../data/repositories/firebase_product_repository.dart';
import '../../data/repositories/firebase_stock_repository.dart';
import '../../data/repositories/firebase_purchase_repository.dart';
import '../../data/datasources/purchase_cache_datasource.dart';
import '../../domain/entities/product.dart';

class PurchasePage extends StatefulWidget {
  final bool isEmbedded;

  const PurchasePage({super.key, this.isEmbedded = false});

  @override
  State<PurchasePage> createState() => _PurchasePageState();
}

class _PurchasePageState extends State<PurchasePage>
    with SingleTickerProviderStateMixin {
  late InventoryService _inventoryService;
  late FirebaseFirestore _firestore;
  late AnimationController _animController;
  late Animation<Offset> _offsetAnimation;
  late Animation<double> _opacityAnimation;
  late AppLocalizations _localizations;
  final _cacheDataSource = PurchaseCacheDataSource();

  Product? _selectedProduct;
  Map<String, dynamic>? _selectedSupplier;
  Map<String, dynamic>? _selectedCompany;
  DateTime? _productionDate;
  DateTime? _expiryDate;

  final _quantityController = TextEditingController();
  final _priceController = TextEditingController();
  final _salesPriceController = TextEditingController();
  final _notesController = TextEditingController();
  final _productSearchController = TextEditingController();
  final _supplierSearchController = TextEditingController();
  final _companySearchController = TextEditingController();

  // For adding new supplier/company
  final _newSupplierFirstNameController = TextEditingController();
  final _newSupplierLastNameController = TextEditingController();
  final _newSupplierContactController = TextEditingController();
  final _newSupplierAddressController = TextEditingController();

  final _newCompanyNameController = TextEditingController();
  final _newCompanyContactController = TextEditingController();
  final _newCompanyAddressController = TextEditingController();

  bool _isLoading = false;
  List<Product> _products = [];
  List<Product> _filteredProducts = [];
  List<Map<String, dynamic>> _suppliers = [];
  List<Map<String, dynamic>> _filteredSuppliers = [];
  List<Map<String, dynamic>> _companies = [];
  List<Map<String, dynamic>> _filteredCompanies = [];

  @override
  void initState() {
    super.initState();
    _firestore = FirebaseFirestore.instance;
    _localizations = AppLocalizations.of(
      LanguageService.instance.currentLanguage,
    );

    // Listen for language changes
    LanguageService.instance.addListener(_onLanguageChanged);

    _inventoryService = InventoryService(
      productRepository: FirebaseProductRepository(firestore: _firestore),
      stockRepository: FirebaseStockRepository(firestore: _firestore),
      purchaseRepository: FirebasePurchaseRepository(firestore: _firestore),
    );

    // Initialize animations
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeIn));
    Future.delayed(
      const Duration(milliseconds: 150),
      () => _animController.forward(),
    );

    _setupInitialData();
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

  Future<void> _setupInitialData() async {
    // Load from cache immediately for < 0.5s loading
    final cachedProducts = await _cacheDataSource.getCachedProducts();
    final cachedSuppliers = await _cacheDataSource.getCachedSuppliers();
    final cachedCompanies = await _cacheDataSource.getCachedCompanies();

    if (mounted) {
      setState(() {
        if (cachedProducts != null) _products = cachedProducts;
        if (cachedSuppliers != null) _suppliers = cachedSuppliers;
        if (cachedCompanies != null) _companies = cachedCompanies;
      });
      print(
        '[DEBUG] Loaded from cache: ${_products.length} products, ${_suppliers.length} suppliers, ${_companies.length} companies',
      );
    }

    // Fetch from Firestore in background
    _loadProducts();
    _loadSuppliers();
    _loadCompanies();
  }

  Future<void> _loadProducts() async {
    try {
      print('[DEBUG] Loading products from Firestore...');
      final products = await _inventoryService.getAllProducts();
      if (mounted) {
        setState(() {
          _products = products;
        });
        // Save to cache for next time
        _cacheDataSource.saveProducts(products);
        print('[DEBUG] Loaded ${products.length} products from Firestore');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${_localizations.errorLoadingProducts}: $e')),
        );
      }
    }
  }

  Future<void> _loadSuppliers() async {
    try {
      print('[DEBUG] Loading suppliers from Firestore...');
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      final snapshot = await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('suppliers')
          .get();

      final freshSuppliers = snapshot.docs
          .map(
            (doc) => {
              'id': doc.id,
              'firstName': doc['firstName'] ?? '',
              'lastName': doc['lastName'] ?? '',
              'fullName': '${doc['firstName'] ?? ''} ${doc['lastName'] ?? ''}'
                  .trim(),
            },
          )
          .toList();

      if (mounted) {
        setState(() {
          _suppliers = freshSuppliers;
        });
        // Save to cache for next time
        _cacheDataSource.saveSuppliers(freshSuppliers);
        print(
          '[DEBUG] Loaded ${freshSuppliers.length} suppliers from Firestore',
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_localizations.errorLoadingSuppliers}: $e'),
          ),
        );
      }
    }
  }

  Future<void> _loadCompanies() async {
    try {
      print('[DEBUG] Loading companies from Firestore...');
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      final snapshot = await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('companies')
          .get();

      final freshCompanies = snapshot.docs
          .map((doc) => {'id': doc.id, 'companyName': doc['companyName'] ?? ''})
          .toList();

      if (mounted) {
        setState(() {
          _companies = freshCompanies;
        });
        // Save to cache for next time
        _cacheDataSource.saveCompanies(freshCompanies);
        print(
          '[DEBUG] Loaded ${freshCompanies.length} companies from Firestore',
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_localizations.errorLoadingCompanies}: $e'),
          ),
        );
      }
    }
  }

  Future<void> _addNewProduct() async {
    final nameController = TextEditingController();
    final purchasePriceController = TextEditingController();
    final salesPriceController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            _localizations.addNewProduct,
            style: const TextStyle(
              fontFamily: 'Literata',
              fontWeight: FontWeight.w700,
              color: Color(0xFF1B4D3E),
              fontSize: 18,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  onChanged: (_) => setDialogState(() {}),
                  decoration: InputDecoration(
                    labelText: _localizations.productName,
                    hintText: _localizations.enterProductName,
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
              onPressed: nameController.text.trim().isEmpty
                  ? null
                  : () async {
                      final dialogContext = context;
                      try {
                        await _inventoryService.createProduct(
                          name: nameController.text.trim(),
                          companyName: '', // No company selection
                          category: '', // No category required
                          purchasePrice: double.parse(
                            purchasePriceController.text,
                          ),
                          salesPrice: double.parse(salesPriceController.text),
                          initialStock: 0,
                        );
                        if (mounted) {
                          if (dialogContext.mounted) {
                            Navigator.pop(dialogContext);
                          }
                          await _loadProducts();
                          // Select the newly added product (last one in list)
                          if (_products.isNotEmpty) {
                            setState(() {
                              _selectedProduct = _products.last;
                              _priceController.text = _selectedProduct!
                                  .purchasePrice
                                  .toString();
                              _salesPriceController.text = _selectedProduct!
                                  .salesPrice
                                  .toString();
                            });
                          }
                          if (mounted) {
                            ScaffoldMessenger.of(dialogContext).showSnackBar(
                              SnackBar(
                                content: Text(
                                  _localizations.productAddedSuccessfully,
                                ),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        }
                      } catch (e) {
                        if (mounted && dialogContext.mounted) {
                          ScaffoldMessenger.of(dialogContext).showSnackBar(
                            SnackBar(
                              content: Text('${_localizations.error}: $e'),
                            ),
                          );
                        }
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: nameController.text.trim().isEmpty
                    ? Colors.grey[400]
                    : const Color(0xFF1B4D3E),
              ),
              child: Text(
                _localizations.addProduct,
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

  void _filterProducts(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredProducts = _products;
      } else {
        _filteredProducts = _products
            .where(
              (product) =>
                  product.name.toLowerCase().contains(query.toLowerCase()) ||
                  product.companyName.toLowerCase().contains(
                    query.toLowerCase(),
                  ) ||
                  product.category.toLowerCase().contains(query.toLowerCase()),
            )
            .toList();
      }
    });
  }

  void _filterSuppliers(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredSuppliers = _suppliers;
      } else {
        _filteredSuppliers = _suppliers
            .where(
              (supplier) =>
                  supplier['fullName'].toLowerCase().contains(
                    query.toLowerCase(),
                  ) ||
                  supplier['firstName'].toLowerCase().contains(
                    query.toLowerCase(),
                  ) ||
                  supplier['lastName'].toLowerCase().contains(
                    query.toLowerCase(),
                  ),
            )
            .toList();
      }
    });
  }

  void _filterCompanies(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredCompanies = _companies;
      } else {
        _filteredCompanies = _companies
            .where(
              (company) => company['companyName'].toLowerCase().contains(
                query.toLowerCase(),
              ),
            )
            .toList();
      }
    });
  }

  void _showProductSelectionBottomSheet() {
    _productSearchController.clear();
    _filteredProducts = _products;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
              height: MediaQuery.of(context).size.height * 0.75,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.92),
                border: Border(
                  top: BorderSide(
                    color: Colors.white.withOpacity(0.5),
                    width: 1.5,
                  ),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _localizations.selectProduct,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Literata',
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _productSearchController,
                    decoration: InputDecoration(
                      hintText: _localizations.searchByProduct,
                      prefixIcon: const Icon(Icons.search_rounded),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    onChanged: (query) {
                      _filterProducts(query);
                      setModalState(() {});
                    },
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: _filteredProducts.isEmpty
                        ? Center(
                            child: Text(
                              _productSearchController.text.isEmpty
                                  ? _localizations.noProductsAvailable
                                  : _localizations.noProductsFound,
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                          )
                        : ListView.builder(
                            itemCount: _filteredProducts.length,
                            itemBuilder: (context, index) {
                              final product = _filteredProducts[index];
                              return ListTile(
                                leading: const Icon(
                                  Icons.inventory_2_rounded,
                                  color: Color(0xFF1B4D3E),
                                ),
                                title: Text(
                                  product.name,
                                  style: const TextStyle(
                                    fontFamily: 'Literata',
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                subtitle: Text(
                                  '${product.companyName} • ${_localizations.stock}: ${product.currentStock}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                trailing: Text(
                                  '₹${product.purchasePrice}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF1B4D3E),
                                  ),
                                ),
                                onTap: () {
                                  setState(() {
                                    _selectedProduct = product;
                                    _priceController.text = product
                                        .purchasePrice
                                        .toString();
                                  });
                                  Navigator.pop(context);
                                },
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showSupplierSelectionBottomSheet() {
    _supplierSearchController.clear();
    _filteredSuppliers = _suppliers;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            child: Container(
              padding: const EdgeInsets.all(16),
              height: MediaQuery.of(context).size.height * 0.75,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.92),
                border: Border(
                  top: BorderSide(
                    color: Colors.white.withOpacity(0.5),
                    width: 1.5,
                  ),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _localizations.selectSupplier,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Literata',
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _supplierSearchController,
                    decoration: InputDecoration(
                      hintText: _localizations.searchBySupplier,
                      prefixIcon: const Icon(Icons.search_rounded),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    onChanged: (query) {
                      _filterSuppliers(query);
                      setModalState(() {});
                    },
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: _filteredSuppliers.isEmpty
                        ? Center(
                            child: Text(
                              _supplierSearchController.text.isEmpty
                                  ? _localizations.noSuppliersAvailable
                                  : _localizations.noSuppliersFound,
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                          )
                        : ListView.builder(
                            itemCount: _filteredSuppliers.length,
                            itemBuilder: (context, index) {
                              final supplier = _filteredSuppliers[index];
                              return ListTile(
                                leading: const Icon(
                                  Icons.person_rounded,
                                  color: Color(0xFF1B4D3E),
                                ),
                                title: Text(
                                  supplier['fullName'],
                                  style: const TextStyle(
                                    fontFamily: 'Literata',
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                onTap: () {
                                  setState(() {
                                    _selectedSupplier = supplier;
                                  });
                                  Navigator.pop(context);
                                },
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showCompanySelectionBottomSheet() {
    _companySearchController.clear();
    _filteredCompanies = _companies;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            child: Container(
              padding: const EdgeInsets.all(16),
              height: MediaQuery.of(context).size.height * 0.75,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.92),
                border: Border(
                  top: BorderSide(
                    color: Colors.white.withOpacity(0.5),
                    width: 1.5,
                  ),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _localizations.selectCompany,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Literata',
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _companySearchController,
                    decoration: InputDecoration(
                      hintText: _localizations.searchByCompany,
                      prefixIcon: const Icon(Icons.search_rounded),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    onChanged: (query) {
                      _filterCompanies(query);
                      setModalState(() {});
                    },
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: _filteredCompanies.isEmpty
                        ? Center(
                            child: Text(
                              _companySearchController.text.isEmpty
                                  ? _localizations.noCompaniesAvailable
                                  : _localizations.noCompaniesFound,
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                          )
                        : ListView.builder(
                            itemCount: _filteredCompanies.length,
                            itemBuilder: (context, index) {
                              final company = _filteredCompanies[index];
                              return ListTile(
                                leading: const Icon(
                                  Icons.business_rounded,
                                  color: Color(0xFF1B4D3E),
                                ),
                                title: Text(
                                  company['companyName'],
                                  style: const TextStyle(
                                    fontFamily: 'Literata',
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                onTap: () {
                                  setState(() {
                                    _selectedCompany = company;
                                  });
                                  Navigator.pop(context);
                                },
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _calculateTotal() {
    // Total is calculated and displayed in the UI
    setState(() {});
  }

  Future<void> _processPurchase() async {
    if (_selectedProduct == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_localizations.pleaseSelectProduct)),
      );
      return;
    }

    if (_selectedSupplier == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_localizations.pleaseSelectSupplier)),
      );
      return;
    }

    if (_selectedCompany == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_localizations.pleaseSelectCompany)),
      );
      return;
    }

    if (_productionDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a production date')),
      );
      return;
    }

    if (_expiryDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an expiry date')),
      );
      return;
    }

    if (_expiryDate!.isBefore(_productionDate!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Expiry date must be after production date'),
        ),
      );
      return;
    }

    final quantity = int.tryParse(_quantityController.text);
    final price = double.tryParse(_priceController.text);
    final salesPrice = double.tryParse(_salesPriceController.text);

    if (quantity == null || quantity <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_localizations.pleaseEnterValidQuantity)),
      );
      return;
    }

    if (price == null || price < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_localizations.pleaseEnterValidPurchasePrice)),
      );
      return;
    }

    if (salesPrice == null || salesPrice < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_localizations.pleaseEnterValidSalesPrice)),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Save purchase to Firestore with supplier and company info
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) throw Exception('User not authenticated');

      await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('purchases')
          .add({
            'productId': _selectedProduct!.id,
            'productName': _selectedProduct!.name,
            'supplierId': _selectedSupplier!['id'],
            'supplierName': _selectedSupplier!['fullName'],
            'companyId': _selectedCompany!['id'],
            'companyName': _selectedCompany!['companyName'],
            'quantity': quantity,
            'purchasePrice': price,
            'salesPrice': salesPrice,
            'totalAmount': quantity * price,
            'productionDate': _productionDate,
            'expiryDate': _expiryDate,
            'notes': _notesController.text.isNotEmpty
                ? _notesController.text
                : null,
            'createdAt': FieldValue.serverTimestamp(),
          });

      // Also process through inventory service for stock update
      await _inventoryService.processPurchase(
        productId: _selectedProduct!.id,
        quantity: quantity,
        purchasePrice: price,
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
      );

      // Update product's purchase price (rate) in products collection
      await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('products')
          .doc(_selectedProduct!.id)
          .update({'purchasePrice': price, 'salesPrice': salesPrice});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_localizations.purchaseRecorded),
            backgroundColor: Colors.green,
          ),
        );

        // Reset form
        setState(() {
          _selectedProduct = null;
          _selectedSupplier = null;
          _selectedCompany = null;
          _productionDate = null;
          _expiryDate = null;
          _quantityController.clear();
          _priceController.clear();
          _salesPriceController.clear();
          _notesController.clear();
        });

        // Reload products to show updated stock
        _loadProducts();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('${_localizations.error}: $e')));
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    LanguageService.instance.removeListener(_onLanguageChanged);
    _animController.dispose();
    _quantityController.dispose();
    _priceController.dispose();
    _salesPriceController.dispose();
    _notesController.dispose();
    _productSearchController.dispose();
    _supplierSearchController.dispose();
    _companySearchController.dispose();
    _newSupplierFirstNameController.dispose();
    _newSupplierLastNameController.dispose();
    _newSupplierContactController.dispose();
    _newSupplierAddressController.dispose();
    _newCompanyNameController.dispose();
    _newCompanyContactController.dispose();
    _newCompanyAddressController.dispose();
    super.dispose();
  }

  void _showAddOptionsBottomSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _localizations.addNewItems,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                fontFamily: 'Literata',
                color: Color(0xFF1B4D3E),
              ),
            ),
            const SizedBox(height: 24),
            // Add Product
            _buildAddOptionTile(
              icon: Icons.inventory_2_rounded,
              title: _localizations.addProduct,
              subtitle: _localizations.createNewProduct,
              color: const Color(0xFFf093fb),
              onTap: () {
                Navigator.pop(context);
                _addNewProduct();
              },
            ),
            const SizedBox(height: 12),
            // Add Supplier
            _buildAddOptionTile(
              icon: Icons.person_add_rounded,
              title: _localizations.addSupplier,
              subtitle: _localizations.addNewSupplier,
              color: const Color(0xFFFF6B6B),
              onTap: () {
                Navigator.pop(context);
                _showAddSupplierDialog();
              },
            ),
            const SizedBox(height: 12),
            // Add Company
            _buildAddOptionTile(
              icon: Icons.business_rounded,
              title: _localizations.addCompany,
              subtitle: _localizations.addNewCompany,
              color: const Color(0xFF7B68EE),
              onTap: () {
                Navigator.pop(context);
                _showAddCompanyDialog();
              },
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildAddOptionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: color.withValues(alpha: 0.2)),
            borderRadius: BorderRadius.circular(14),
            color: color.withValues(alpha: 0.05),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Literata',
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        fontFamily: 'Literata',
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: Colors.grey[400],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddSupplierDialog() {
    _newSupplierFirstNameController.clear();
    _newSupplierLastNameController.clear();
    _newSupplierContactController.clear();
    _newSupplierAddressController.clear();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            _localizations.addNewSupplier,
            style: const TextStyle(
              fontFamily: 'Literata',
              fontWeight: FontWeight.w700,
              color: Color(0xFF1B4D3E),
              fontSize: 18,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _newSupplierFirstNameController,
                  onChanged: (_) => setDialogState(() {}),
                  decoration: InputDecoration(
                    labelText: _localizations.firstName,
                    hintText: _localizations.enterFirstName,
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
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.red, width: 2),
                    ),
                    errorText: _newSupplierFirstNameController.text.isEmpty
                        ? _localizations.firstNameRequired
                        : null,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _newSupplierLastNameController,
                  onChanged: (_) => setDialogState(() {}),
                  decoration: InputDecoration(
                    labelText: _localizations.lastName,
                    hintText: _localizations.enterLastName,
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
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.red, width: 2),
                    ),
                    errorText: _newSupplierLastNameController.text.isEmpty
                        ? _localizations.lastNameRequired
                        : null,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _newSupplierContactController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: _localizations.contactNumber,
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
                  controller: _newSupplierAddressController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: _localizations.address,
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
              child: Text(_localizations.cancel),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    (_newSupplierFirstNameController.text.trim().isEmpty ||
                        _newSupplierLastNameController.text.trim().isEmpty)
                    ? Colors.grey[400]
                    : const Color(0xFF1B4D3E),
              ),
              onPressed:
                  (_newSupplierFirstNameController.text.trim().isEmpty ||
                      _newSupplierLastNameController.text.trim().isEmpty)
                  ? null
                  : () => _saveNewSupplier(context),
              child: Text(
                _localizations.addSupplier,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveNewSupplier(BuildContext dialogContext) async {
    final firstName = _newSupplierFirstNameController.text.trim();
    final lastName = _newSupplierLastNameController.text.trim();
    final contact = _newSupplierContactController.text.trim();

    if (firstName.isEmpty || lastName.isEmpty) {
      if (dialogContext.mounted) {
        ScaffoldMessenger.of(dialogContext).showSnackBar(
          SnackBar(content: Text(_localizations.firstLastNameRequired)),
        );
      }
      return;
    }

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) throw Exception('User not authenticated');

      final supplierId = _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('suppliers')
          .doc()
          .id;

      await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('suppliers')
          .doc(supplierId)
          .set({
            'id': supplierId,
            'firstName': firstName,
            'lastName': lastName,
            'contact': contact,
            'address': _newSupplierAddressController.text.trim(),
            'createdAt': FieldValue.serverTimestamp(),
          });

      if (dialogContext.mounted) {
        Navigator.pop(dialogContext);
      }

      await _loadSuppliers();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_localizations.supplierAddedSuccessfully),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${_localizations.errorAddingSupplier}: $e')),
        );
      }
    }
  }

  void _showAddCompanyDialog() {
    _newCompanyNameController.clear();
    _newCompanyContactController.clear();
    _newCompanyAddressController.clear();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            _localizations.addNewCompany,
            style: const TextStyle(
              fontFamily: 'Literata',
              fontWeight: FontWeight.w700,
              color: Color(0xFF1B4D3E),
              fontSize: 18,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _newCompanyNameController,
                  onChanged: (_) => setDialogState(() {}),
                  decoration: InputDecoration(
                    labelText: _localizations.companyName,
                    hintText: _localizations.enterCompanyName,
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
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.red, width: 2),
                    ),
                    errorText: _newCompanyNameController.text.isEmpty
                        ? _localizations.companyNameRequired
                        : null,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _newCompanyContactController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: _localizations.contactNumber,
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
                  controller: _newCompanyAddressController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: _localizations.address,
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
              child: Text(_localizations.cancel),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _newCompanyNameController.text.trim().isEmpty
                    ? Colors.grey[400]
                    : const Color(0xFF1B4D3E),
              ),
              onPressed: _newCompanyNameController.text.trim().isEmpty
                  ? null
                  : () => _saveNewCompany(context),
              child: Text(
                _localizations.addCompany,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveNewCompany(BuildContext dialogContext) async {
    final companyName = _newCompanyNameController.text.trim();

    if (companyName.isEmpty) {
      if (dialogContext.mounted) {
        ScaffoldMessenger.of(dialogContext).showSnackBar(
          SnackBar(content: Text(_localizations.companyNameIsRequired)),
        );
      }
      return;
    }

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) throw Exception('User not authenticated');

      final companyId = _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('companies')
          .doc()
          .id;

      await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('companies')
          .doc(companyId)
          .set({
            'id': companyId,
            'companyName': companyName,
            'contact': _newCompanyContactController.text.trim(),
            'address': _newCompanyAddressController.text.trim(),
            'createdAt': FieldValue.serverTimestamp(),
          });

      if (dialogContext.mounted) {
        Navigator.pop(dialogContext);
      }

      await _loadCompanies();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Company added successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error adding company: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE6EDE7),
      floatingActionButton: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF1B4D3E).withOpacity(0.4),
                  const Color(0xFF1B4D3E).withOpacity(0.2),
                ],
              ),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF1B4D3E).withOpacity(0.25),
                  blurRadius: 25,
                  offset: const Offset(0, 10),
                  spreadRadius: 2,
                ),
                BoxShadow(
                  color: Colors.white.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(-5, -5),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _showAddOptionsBottomSheet,
                splashColor: Colors.white.withOpacity(0.2),
                highlightColor: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(22),
                child: Center(
                  child: Icon(
                    Icons.add_rounded,
                    size: 36,
                    color: Colors.white.withOpacity(0.95),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      body: SafeArea(
        top: !widget
            .isEmbedded, // SafeArea already handled by common header when embedded
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: 20.0,
              vertical: widget.isEmbedded ? 12.0 : 20.0,
            ),
            child: Column(
              children: [
                // Header with back button - only show if not embedded
                if (!widget.isEmbedded) ...[
                  const SizedBox(height: 20),
                  SlideTransition(
                    position: _offsetAnimation,
                    child: FadeTransition(
                      opacity: _opacityAnimation,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: const Icon(
                              Icons.arrow_back_ios_rounded,
                              size: 22,
                              color: Color(0xFF1B4D3E),
                            ),
                          ),
                          // Header text
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  'Purchase Records',
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.w800,
                                        color: const Color(0xFF1B4D3E),
                                        letterSpacing: 0.5,
                                        fontSize: 24,
                                      ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Track and manage your purchases',
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(
                                        color: Colors.black45,
                                        fontWeight: FontWeight.w400,
                                        fontSize: 12,
                                      ),
                                ),
                              ],
                            ),
                          ),
                          // Spacer to balance layout
                          const SizedBox(width: 22),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
                // Form content with animation
                SlideTransition(
                  position: _offsetAnimation,
                  child: FadeTransition(
                    opacity: _opacityAnimation,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Product Selection
                        const Text(
                          'Select Product',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'Literata',
                          ),
                        ),
                        const SizedBox(height: 12),
                        GestureDetector(
                          onTap: _showProductSelectionBottomSheet,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: _selectedProduct != null
                                    ? const Color(0xFF1B4D3E)
                                    : Colors.grey[300]!,
                                width: _selectedProduct != null ? 2 : 1,
                              ),
                              borderRadius: BorderRadius.circular(12),
                              color: _selectedProduct != null
                                  ? const Color(
                                      0xFF1B4D3E,
                                    ).withValues(alpha: 0.05)
                                  : Colors.white,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _selectedProduct?.name ??
                                            'Select a product',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          fontFamily: 'Literata',
                                          color: _selectedProduct != null
                                              ? Colors.black87
                                              : Colors.grey[500],
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      if (_selectedProduct != null)
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            top: 4,
                                          ),
                                          child: Text(
                                            'Stock: ${_selectedProduct!.currentStock}',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Icon(
                                  Icons.arrow_forward_ios_rounded,
                                  size: 16,
                                  color: Colors.grey[400],
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (_selectedProduct != null) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.green.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: Colors.green.withValues(alpha: 0.2),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.check_circle_rounded,
                                  color: Colors.green[600],
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    '${_selectedProduct!.name} (${_selectedProduct!.category})',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      fontFamily: 'Literata',
                                      color: Colors.green[700],
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 24),

                        // Supplier Selection
                        const Text(
                          'Select Supplier',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'Literata',
                          ),
                        ),
                        const SizedBox(height: 12),
                        GestureDetector(
                          onTap: _showSupplierSelectionBottomSheet,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: _selectedSupplier != null
                                    ? const Color(0xFF1B4D3E)
                                    : Colors.grey[300]!,
                                width: _selectedSupplier != null ? 2 : 1,
                              ),
                              borderRadius: BorderRadius.circular(12),
                              color: _selectedSupplier != null
                                  ? const Color(
                                      0xFF1B4D3E,
                                    ).withValues(alpha: 0.05)
                                  : Colors.white,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    _selectedSupplier?['fullName'] ??
                                        'Select a supplier',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      fontFamily: 'Literata',
                                      color: _selectedSupplier != null
                                          ? Colors.black87
                                          : Colors.grey[500],
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Icon(
                                  Icons.arrow_forward_ios_rounded,
                                  size: 16,
                                  color: Colors.grey[400],
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Company Selection
                        const Text(
                          'Select Company',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'Literata',
                          ),
                        ),
                        const SizedBox(height: 12),
                        GestureDetector(
                          onTap: _showCompanySelectionBottomSheet,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: _selectedCompany != null
                                    ? const Color(0xFF1B4D3E)
                                    : Colors.grey[300]!,
                                width: _selectedCompany != null ? 2 : 1,
                              ),
                              borderRadius: BorderRadius.circular(12),
                              color: _selectedCompany != null
                                  ? const Color(
                                      0xFF1B4D3E,
                                    ).withValues(alpha: 0.05)
                                  : Colors.white,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    _selectedCompany?['companyName'] ??
                                        'Select a company',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      fontFamily: 'Literata',
                                      color: _selectedCompany != null
                                          ? Colors.black87
                                          : Colors.grey[500],
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Icon(
                                  Icons.arrow_forward_ios_rounded,
                                  size: 16,
                                  color: Colors.grey[400],
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Production Date Picker
                        const Text(
                          'Production Date',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'Literata',
                          ),
                        ),
                        const SizedBox(height: 12),
                        GestureDetector(
                          onTap: () async {
                            final selectedDate = await showDatePicker(
                              context: context,
                              initialDate: _productionDate ?? DateTime.now(),
                              firstDate: DateTime(2000),
                              lastDate: DateTime.now(),
                              builder: (context, child) {
                                return Theme(
                                  data: Theme.of(context).copyWith(
                                    colorScheme: ColorScheme.light(
                                      primary: const Color(0xFF1B4D3E),
                                      onPrimary: Colors.white,
                                      surface: Colors.white,
                                      onSurface: Colors.black,
                                      secondary: const Color(0xFF1B4D3E),
                                      onSecondary: Colors.white,
                                    ),
                                    useMaterial3: true,
                                    buttonTheme: ButtonThemeData(
                                      buttonColor: const Color(0xFF1B4D3E),
                                      textTheme: ButtonTextTheme.primary,
                                    ),
                                  ),
                                  child: child!,
                                );
                              },
                            );
                            if (selectedDate != null) {
                              setState(() {
                                _productionDate = selectedDate;
                              });
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey[300]!),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _productionDate == null
                                      ? 'Select production date'
                                      : '${_productionDate!.day}/${_productionDate!.month}/${_productionDate!.year}',
                                  style: TextStyle(
                                    color: _productionDate == null
                                        ? Colors.grey[600]
                                        : Colors.black,
                                    fontFamily: 'Literata',
                                  ),
                                ),
                                Icon(
                                  Icons.calendar_today,
                                  color: Colors.grey[600],
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Expiry Date Picker
                        const Text(
                          'Expiry Date',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'Literata',
                          ),
                        ),
                        const SizedBox(height: 12),
                        GestureDetector(
                          onTap: () async {
                            final selectedDate = await showDatePicker(
                              context: context,
                              initialDate:
                                  _expiryDate ??
                                  DateTime.now().add(const Duration(days: 30)),
                              firstDate: DateTime.now(),
                              lastDate: DateTime(2100),
                              builder: (context, child) {
                                return Theme(
                                  data: Theme.of(context).copyWith(
                                    colorScheme: ColorScheme.light(
                                      primary: const Color(0xFF1B4D3E),
                                      onPrimary: Colors.white,
                                      surface: Colors.white,
                                      onSurface: Colors.black,
                                      secondary: const Color(0xFF1B4D3E),
                                      onSecondary: Colors.white,
                                    ),
                                    useMaterial3: true,
                                    buttonTheme: ButtonThemeData(
                                      buttonColor: const Color(0xFF1B4D3E),
                                      textTheme: ButtonTextTheme.primary,
                                    ),
                                  ),
                                  child: child!,
                                );
                              },
                            );
                            if (selectedDate != null) {
                              setState(() {
                                _expiryDate = selectedDate;
                              });
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey[300]!),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _expiryDate == null
                                      ? 'Select expiry date'
                                      : '${_expiryDate!.day}/${_expiryDate!.month}/${_expiryDate!.year}',
                                  style: TextStyle(
                                    color: _expiryDate == null
                                        ? Colors.grey[600]
                                        : Colors.black,
                                    fontFamily: 'Literata',
                                  ),
                                ),
                                Icon(
                                  Icons.calendar_today,
                                  color: Colors.grey[600],
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 28),

                        // Quantity Input
                        const Text(
                          'Purchase Quantity',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'Literata',
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _quantityController,
                          keyboardType: TextInputType.number,
                          onChanged: (_) => _calculateTotal(),
                          decoration: InputDecoration(
                            hintText: 'Enter quantity',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            prefixIcon: const Icon(Icons.shopping_cart_rounded),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Price Input
                        const Text(
                          'Purchase Price per Unit',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'Literata',
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _priceController,
                          keyboardType: TextInputType.number,
                          onChanged: (_) => _calculateTotal(),
                          decoration: InputDecoration(
                            hintText: 'Enter purchase price',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            prefixIcon: const Icon(
                              Icons.currency_rupee_rounded,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Sales Price Input
                        const Text(
                          'Sales Price per Unit',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'Literata',
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _salesPriceController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            hintText: 'Enter sales price',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            prefixIcon: const Icon(
                              Icons.currency_rupee_rounded,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Total Amount
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.green.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Total Amount',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: 'Literata',
                                ),
                              ),
                              Text(
                                '₹${((int.tryParse(_quantityController.text) ?? 0) * (double.tryParse(_priceController.text) ?? 0)).toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  fontFamily: 'Literata',
                                  color: Colors.green,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Notes Input
                        const Text(
                          'Notes (Optional)',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'Literata',
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _notesController,
                          maxLines: 3,
                          decoration: InputDecoration(
                            hintText: 'Add any notes about this purchase',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        const SizedBox(height: 28),

                        // Submit Button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _processPurchase,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1B4D3E),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              disabledBackgroundColor: Colors.grey[400],
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                : const Text(
                                    'Record Purchase',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      fontFamily: 'Literata',
                                      color: Colors.white,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 20),
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
}

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:c_billing/core/services/billing_service.dart';
import 'package:c_billing/core/services/customer_transaction_service.dart';
import 'package:c_billing/core/services/dashboard_refresh_service.dart';
import 'package:c_billing/features/billing/data/repositories/firebase_bill_repository.dart';
import 'package:c_billing/features/billing/domain/entities/bill.dart';
import 'package:c_billing/features/billing/domain/entities/bill_item.dart';
import 'package:c_billing/features/inventory_management/data/repositories/firebase_product_repository.dart';
import 'package:c_billing/features/inventory_management/data/repositories/firebase_stock_repository.dart';
import 'package:c_billing/features/inventory_management/domain/entities/product.dart';
import 'package:c_billing/features/billing/data/datasources/bill_cache_datasource.dart';
import 'package:c_billing/core/printing/printing.dart';
import 'package:printing/printing.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:c_billing/common_widgets/printer_selection_widget.dart';
import 'package:c_billing/features/shop/data/repositories/shop_repository.dart';
import 'package:c_billing/features/customer/data/repositories/customer_repository.dart';
import 'package:c_billing/features/customer/data/repositories/customer_transaction_repository.dart';
import 'package:c_billing/core/services/language_service.dart';
import 'package:c_billing/core/localization/app_localizations.dart';
import 'package:c_billing/features/billing/presentation/pages/bill_settings_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:c_billing/features/billing/offline/entities/bill_entity.dart';
import 'package:c_billing/features/billing/data/services/bill_sync_service.dart';
import 'package:c_billing/features/product/offline/controllers/product_offline_controller.dart';
import 'package:c_billing/features/product/data/services/product_sync_service.dart';
import 'package:c_billing/core/services/inventory_integration_service.dart';
import 'package:c_billing/features/inventory_management/offline/controllers/purchase_batch_offline_controller.dart';
import 'package:c_billing/features/inventory_management/offline/entities/purchase_batch_entity.dart';

class BillingPage extends StatefulWidget {
  final bool isEmbedded;

  const BillingPage({super.key, this.isEmbedded = false});

  @override
  State<BillingPage> createState() => _BillingPageState();
}

class _BillingPageState extends State<BillingPage> {
  // ignore: unused_field
  late BillingService _billingService;
  late FirebaseFirestore _firestore;
  late ShopRepository _shopRepository;
  late FirebaseCustomerRepository _customerRepository;
  late AppLocalizations _localizations;

  // Data refresh subscriptions
  StreamSubscription<void>? _productRefreshSubscription;
  StreamSubscription<void>? _customerRefreshSubscription;
  StreamSubscription<void>? _billSettingsSubscription;

  // Printing services
  final _printerService = PosPrinterService();
  final _pdfService = PdfBillService();

  final _customerNameController = TextEditingController();
  final _customerContactController = TextEditingController();
  final _notesController = TextEditingController();
  final _discountController = TextEditingController();
  final _receivedAmountController = TextEditingController();

  List<BillItem> _billItems = [];
  List<Product> _products = [];
  bool _isLoading = false;
  bool _isSavingBill = false;

  // Discount state
  bool _isPercentageDiscount = true;
  double _discountValue = 0.0;

  // Payment state
  double _receivedAmount = 0.0;
  bool _isFullPayment = true;

  Map<String, dynamic>? _selectedCustomer;
  List<Map<String, dynamic>> _customers = [];

  // Quick add by index number
  final _indexNoController = TextEditingController();
  final _indexNoFocusNode = FocusNode();
  Timer? _debounceTimer;
  Map<int, Product> _productByIndexNo = {};
  
  // FIFO batch data for billing
  List<PurchaseBatchEntity> _availableBatches = [];
  
  // Customer phone search debounce
  Timer? _phoneSearchDebounceTimer;
  bool _isSearchingCustomer = false;
  String? _autoFoundCustomerName;
  bool _hasPhoneText = false;
  
  // Bill settings
  bool _showCustomerOnBill = true;
  bool _generateBillViaContact = false;
  String _billType = 'pos'; // 'pos' or 'normal'

  @override
  void initState() {
    super.initState();
    _firestore = FirebaseFirestore.instance;
    _shopRepository = ShopRepository(firestore: _firestore);
    _localizations = AppLocalizations.of(
      LanguageService.instance.currentLanguage,
    );

    // Listen for language changes
    LanguageService.instance.addListener(_onLanguageChanged);

    // Initialize customer repository
    _customerRepository = FirebaseCustomerRepository(firestore: _firestore);
    final customerTransactionRepository = FirebaseCustomerTransactionRepository(
      firestore: _firestore,
    );
    final customerTransactionService = CustomerTransactionService(
      firestore: _firestore,
      customerRepository: _customerRepository,
      transactionRepository: customerTransactionRepository,
    );

    _billingService = BillingService(
      billRepository: FirebaseBillRepository(firestore: _firestore),
      productRepository: FirebaseProductRepository(firestore: _firestore),
      stockRepository: FirebaseStockRepository(firestore: _firestore),
      customerTransactionService: customerTransactionService,
    );
    
    // Listen for customer phone number changes
    _customerContactController.addListener(_onPhoneNumberChanged);
    
    // Listen for product changes from other screens
    _productRefreshSubscription = DashboardRefreshService.instance.onProductChanged.listen((_) {
      if (mounted) _loadProducts(showLoader: false);
    });
    
    // Listen for customer changes from other screens
    _customerRefreshSubscription = DashboardRefreshService.instance.onCustomerChanged.listen((_) {
      if (mounted) _loadCustomers();
    });
    
    // Listen for bill settings changes from settings page
    _billSettingsSubscription = DashboardRefreshService.instance.onBillSettingsChanged.listen((_) {
      if (mounted) _loadBillSettings();
    });
    
    _loadProducts();
    _loadCustomers();
    _loadBillSettings();
  }
  
  Future<void> _loadBillSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _showCustomerOnBill = prefs.getBool('bill_show_customer_details') ?? true;
        _generateBillViaContact = prefs.getBool('bill_generate_via_contact') ?? false;
        _billType = prefs.getString('bill_type') ?? 'pos';
      });
    }
  }

  @override
  void dispose() {
    _productRefreshSubscription?.cancel();
    _customerRefreshSubscription?.cancel();
    _billSettingsSubscription?.cancel();
    LanguageService.instance.removeListener(_onLanguageChanged);
    _debounceTimer?.cancel();
    _phoneSearchDebounceTimer?.cancel();
    _customerContactController.removeListener(_onPhoneNumberChanged);
    _indexNoController.dispose();
    _indexNoFocusNode.dispose();
    _customerNameController.dispose();
    _customerContactController.dispose();
    _notesController.dispose();
    _discountController.dispose();
    _receivedAmountController.dispose();
    _printerService.dispose();
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

  Future<void> _loadProducts({bool showLoader = true}) async {
    try {
      if (showLoader) setState(() => _isLoading = true);
      
      // Use offline-first controller to get products with stock > 0
      var allProducts = await ProductOfflineController.instance.getAllProducts();
      
      // If no products locally, try to sync from Firebase
      if (allProducts.isEmpty) {
        debugPrint('[BillingPage] No local products, syncing from Firebase...');
        await ProductSyncService.instance.forceFullRefresh();
        allProducts = await ProductOfflineController.instance.getAllProducts();
        debugPrint('[BillingPage] After sync: ${allProducts.length} products');
      }
      
      // Filter products with available stock
      final availableProducts = allProducts
          .map((entity) => Product.fromProductEntity(entity))
          .where((p) => p.currentStock > 0)
          .toList();
      
      // Load FIFO batch data for billing
      final batches = await PurchaseBatchOfflineController.instance
          .getAllBatches(includeConsumed: false);
      
      debugPrint('[BillingPage] Total products: ${allProducts.length}, with stock > 0: ${availableProducts.length}, batches: ${batches.length}');
      
      if (mounted) {
        setState(() {
          _products = availableProducts;
          _availableBatches = batches
              .where((b) => b.quantityRemaining > 0)
              .toList()
            ..sort((a, b) => a.purchaseDate.compareTo(b.purchaseDate)); // FIFO order
          // Build index lookup map for fast product search
          _productByIndexNo = {
            for (final product in _products)
              if (product.indexNo > 0) product.indexNo: product,
          };
          if (showLoader) _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('[BillingPage] Error loading products: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        _showSnackbar(
          '${_localizations.errorLoadingProducts}: $e',
          isError: true,
        );
      }
    }
  }

  Future<void> _loadCustomers() async {
    try {
      final billRepo = FirebaseBillRepository(firestore: _firestore);
      final snapshot = await _firestore
          .collection('users')
          .doc(billRepo.userId)
          .collection('customers')
          .get();
      setState(() {
        _customers = snapshot.docs.map((doc) {
          return {
            'id': doc.id,
            'firstName': doc['firstName'] ?? '',
            'lastName': doc['lastName'] ?? '',
            'contact': doc['contact'] ?? '',
            'fullName': '${doc['firstName'] ?? ''} ${doc['lastName'] ?? ''}'
                .trim(),
          };
        }).toList();
      });
    } catch (e) {
      debugPrint('[DEBUG] Error loading customers: $e');
    }
  }

  /// Listener for phone number changes - implements debounced search
  void _onPhoneNumberChanged() {
    if (!mounted) return;
    final phoneNumber = _customerContactController.text.trim();
    
    // Cancel previous timer
    _phoneSearchDebounceTimer?.cancel();
    
    // Update phone text state
    setState(() {
      _hasPhoneText = phoneNumber.isNotEmpty;
    });
    
    // Clear auto-found customer name if phone number is cleared
    if (phoneNumber.isEmpty) {
      setState(() {
        _autoFoundCustomerName = null;
        _selectedCustomer = null;
      });
      return;
    }
    
    // Validate phone number length (at least 10 digits)
    if (phoneNumber.length < 10) {
      setState(() {
        _autoFoundCustomerName = null;
      });
      return;
    }
    
    // Start new debounce timer (600ms)
    _phoneSearchDebounceTimer = Timer(const Duration(milliseconds: 600), () {
      _searchCustomerByPhone(phoneNumber);
    });
  }

  /// Search for customer by phone number
  Future<void> _searchCustomerByPhone(String phoneNumber) async {
    if (!mounted) return;
    
    setState(() {
      _isSearchingCustomer = true;
      _autoFoundCustomerName = null;
    });
    
    try {
      // Normalize phone number - remove spaces, dashes, and country code for comparison
      final normalizedPhone = phoneNumber.replaceAll(RegExp(r'[\s\-\(\)\+]'), '');
      
      // Try exact match first
      var customer = await _customerRepository.getCustomerByContact(phoneNumber);
      
      // If not found, try normalized search (last 10 digits)
      if (customer == null && normalizedPhone.length >= 10) {
        final last10Digits = normalizedPhone.substring(normalizedPhone.length - 10);
        
        try {
          // Search through all customers and match last 10 digits
          final allCustomers = await _customerRepository.getAllCustomers();
          for (final c in allCustomers) {
            final customerNormalized = c.contact.replaceAll(RegExp(r'[\s\-\(\)\+]'), '');
            if (customerNormalized.length >= 10) {
              final customerLast10 = customerNormalized.substring(customerNormalized.length - 10);
              if (customerLast10 == last10Digits) {
                customer = c;
                break;
              }
            }
          }
        } catch (e) {
          // If getAllCustomers fails, just continue without fuzzy matching
          debugPrint('[DEBUG] Could not fetch all customers for fuzzy match: $e');
        }
      }
      
      if (!mounted) return;
      
      if (customer != null) {
        // Customer found - auto-attach to bill
        setState(() {
          _selectedCustomer = {
            'id': customer!.id,
            'firstName': customer.firstName,
            'lastName': customer.lastName,
            'contact': customer.contact,
            'fullName': '${customer.firstName} ${customer.lastName}'.trim(),
          };
          _autoFoundCustomerName = _selectedCustomer!['fullName'];
          _customerNameController.text = _autoFoundCustomerName!;
          _isSearchingCustomer = false;
        });
        
        _showSnackbar(
          'Customer found: ${_autoFoundCustomerName}',
          isError: false,
        );
      } else {
        // Customer not found - just clear the search state, don't show dialog
        setState(() {
          _isSearchingCustomer = false;
          _autoFoundCustomerName = null;
        });
      }
    } catch (e) {
      if (!mounted) return;
      
      setState(() {
        _isSearchingCustomer = false;
      });
      
      debugPrint('[DEBUG] Error searching customer: $e');
      _showSnackbar(
        'Error searching customer: ${e.toString()}',
        isError: true,
      );
    }
  }

  /// Show dialog to add new customer with optional phone number
  void _showAddCustomerDialog(String phoneNumber) {
    final firstNameController = TextEditingController();
    final lastNameController = TextEditingController();
    final phoneController = TextEditingController(text: phoneNumber);
    final formKey = GlobalKey<FormState>();
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF1B4D3E).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.person_add,
                color: Color(0xFF1B4D3E),
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Add New Customer',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1B4D3E),
                fontFamily: 'Literata',
              ),
            ),
          ],
        ),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (phoneNumber.isNotEmpty)
                  Text(
                    'Customer not found for $phoneNumber',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                      fontFamily: 'Literata',
                    ),
                  ),
                if (phoneNumber.isNotEmpty) const SizedBox(height: 20),
                TextFormField(
                  controller: firstNameController,
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: 'First Name *',
                    prefixIcon: const Icon(Icons.person_outline),
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
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'First name is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: lastNameController,
                  decoration: InputDecoration(
                    labelText: 'Last Name *',
                    prefixIcon: const Icon(Icons.person_outline),
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
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Last name is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: 'Phone Number (Optional)',
                    prefixIcon: const Icon(Icons.phone_outlined),
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
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
            },
            child: Text(
              'Cancel',
              style: TextStyle(
                color: Colors.grey[600],
                fontFamily: 'Literata',
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              // Continue without customer - just keep the phone number
              _showSnackbar(
                'Continuing without customer',
                isError: false,
              );
            },
            child: const Text(
              'Skip',
              style: TextStyle(
                color: Color(0xFF1B4D3E),
                fontFamily: 'Literata',
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                // Extract values before closing dialog
                final firstName = firstNameController.text.trim();
                final lastName = lastNameController.text.trim();
                final phone = phoneController.text.trim();
                
                // Close dialog first
                Navigator.pop(ctx);
                
                // Save customer with extracted values
                await _saveNewCustomer(
                  firstName: firstName,
                  lastName: lastName,
                  phoneNumber: phone,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1B4D3E),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              'Save & Attach',
              style: TextStyle(
                color: Colors.white,
                fontFamily: 'Literata',
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Save new customer and auto-attach to current bill
  Future<void> _saveNewCustomer({
    required String firstName,
    required String lastName,
    required String phoneNumber,
  }) async {
    try {
      final billRepo = FirebaseBillRepository(firestore: _firestore);
      final docRef = await _firestore
          .collection('users')
          .doc(billRepo.userId)
          .collection('customers')
          .add({
        'firstName': firstName,
        'lastName': lastName,
        'middleName': '',
        'contact': phoneNumber,
        'address': '',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'isActive': true,
        'pendingBalance': 0.0,
        'totalPurchaseAmount': 0.0,
        'totalPaidAmount': 0.0,
      });

      // Auto-attach customer to bill
      final fullName = '$firstName $lastName'.trim();
      if (mounted) {
        setState(() {
          _selectedCustomer = {
            'id': docRef.id,
            'firstName': firstName,
            'lastName': lastName,
            'contact': phoneNumber,
            'fullName': fullName,
          };
          _autoFoundCustomerName = fullName;
          _customerNameController.text = fullName;
          if (phoneNumber.isNotEmpty) {
            _customerContactController.text = phoneNumber;
            _hasPhoneText = true;
          }
        });
      }

      // Refresh customer list
      await _loadCustomers();
      
      // Notify other screens
      DashboardRefreshService.instance.notifyDataChanged(DataChangeType.customer);

      if (mounted) {
        _showSnackbar(
          'Customer added: $fullName',
          isError: false,
        );
      }
    } catch (e) {
      debugPrint('[DEBUG] Error saving customer: $e');
      if (mounted) {
        _showSnackbar(
          'Error saving customer: $e',
          isError: true,
        );
      }
    }
  }

  void _showAddItemsPopup() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _AddItemsBottomSheet(
        products: _products,
        billItems: _billItems,
        availableBatches: _availableBatches,
        localizations: _localizations,
        onBatchItemAdded: (productId, productName, companyName, batchLocalId, sellingPrice, purchasePrice, quantity, maxStock) {
          // Use a unique key: productId + batchLocalId (or just productId if no batch)
          final uniqueKey = batchLocalId != null ? '${productId}_batch_$batchLocalId' : productId;
          final existingIndex = _billItems.indexWhere(
            (item) => item.productId == uniqueKey,
          );
          setState(() {
            if (existingIndex != -1) {
              _billItems[existingIndex] = BillItem.create(
                productId: uniqueKey,
                productName: companyName.isNotEmpty ? '$productName ($companyName)' : productName,
                sellingPrice: sellingPrice,
                purchasePrice: purchasePrice,
                quantity: quantity,
              );
            } else {
              _billItems.add(
                BillItem.create(
                  productId: uniqueKey,
                  productName: companyName.isNotEmpty ? '$productName ($companyName)' : productName,
                  sellingPrice: sellingPrice,
                  purchasePrice: purchasePrice,
                  quantity: quantity,
                ),
              );
            }
          });
        },
        onItemRemoved: (uniqueKey) {
          setState(() {
            _billItems.removeWhere((item) => item.productId == uniqueKey);
          });
        },
        showSnackbar: _showSnackbar,
      ),
    );
  }

  double get _totalAmount =>
      _billItems.fold(0.0, (sum, item) => sum + item.subtotal);

  int get _totalQuantity =>
      _billItems.fold(0, (sum, item) => sum + item.quantity);

  double get _discountAmount {
    if (_isPercentageDiscount) {
      return (_totalAmount * _discountValue / 100);
    }
    return _discountValue;
  }

  double get _discountPercent {
    if (_isPercentageDiscount) {
      return _discountValue;
    }
    if (_totalAmount > 0) {
      return (_discountValue / _totalAmount * 100);
    }
    return 0.0;
  }

  double get _finalAmount => _totalAmount - _discountAmount;

  // Computed pending amount based on received amount
  double get _pendingAmount {
    if (_isFullPayment) return 0.0;
    return (_finalAmount - _receivedAmount).clamp(0.0, _finalAmount);
  }

  Future<void> _saveBill() async {
    if (_billItems.isEmpty) {
      _showSnackbar(_localizations.pleaseAddAtLeastOneItem, isError: true);
      return;
    }

    // Validate contact number if generate via contact is enabled
    if (_generateBillViaContact) {
      final contact = _customerContactController.text.trim();
      if (contact.isEmpty || contact.length < 10) {
        _showSnackbar(
          'Please enter a valid customer contact number to generate bill',
          isError: true,
        );
        return;
      }
    }

    setState(() => _isSavingBill = true);

    try {
      // === INTEGRATED OFFLINE-FIRST APPROACH (FIFO) ===
      // 1. Calculate payment status
      final actualPaidAmount = _isFullPayment ? _finalAmount : _receivedAmount;
      final calculatedPendingAmount = _finalAmount - actualPaidAmount;
      BillPaymentStatus paymentStatus;
      if (calculatedPendingAmount <= 0) {
        paymentStatus = BillPaymentStatus.paid;
      } else if (actualPaidAmount > 0) {
        paymentStatus = BillPaymentStatus.partiallyPaid;
      } else {
        paymentStatus = BillPaymentStatus.pending;
      }

      // 2. Use InventoryIntegrationService for unified processing:
      // Creates BillEntity + FIFO batch deductions + StockLedger entries + updates Product stock
      // Transform bill items: extract real productId from batch-specific keys (e.g., "prodId_batch_123" → "prodId")
      final processableItems = _billItems.map((item) {
        final realProductId = item.productId.split('_batch_').first;
        return BillItem.create(
          productId: realProductId,
          productName: item.productName,
          sellingPrice: item.sellingPrice,
          purchasePrice: item.purchasePrice,
          quantity: item.quantity,
        );
      }).toList();

      final integrationResult = await InventoryIntegrationService.instance.processBill(
        customerId: _selectedCustomer?['id'],
        customerName: _customerNameController.text.trim().isNotEmpty
            ? _customerNameController.text.trim()
            : _selectedCustomer?['fullName'],
        customerContact: _customerContactController.text.trim().isNotEmpty
            ? _customerContactController.text.trim()
            : _selectedCustomer?['contact'],
        items: processableItems,
        totalQuantity: _totalQuantity,
        totalAmount: _totalAmount,
        discountAmount: _discountAmount,
        discountPercent: _discountPercent,
        finalAmount: _finalAmount,
        notes: _notesController.text.trim().isNotEmpty
            ? _notesController.text.trim()
            : null,
        paymentStatus: paymentStatus,
        paidAmount: actualPaidAmount > 0 ? actualPaidAmount : 0,
        pendingAmount: calculatedPendingAmount > 0 ? calculatedPendingAmount : 0,
      );

      if (!integrationResult.success) {
        throw Exception(integrationResult.errorMessage ?? 'Bill processing failed');
      }

      debugPrint('[Billing] Bill processed with FIFO: COGS=${integrationResult.totalCOGS}, Profit=${integrationResult.totalProfit}');

      // 3. Trigger background sync
      unawaited(BillSyncService.instance.syncNow());

      setState(() => _isSavingBill = false);

      // Clear bills list cache so it reloads fresh data next time
      unawaited(BillCacheDataSource().clearCache());

      // Keep a copy of items to update local stock display
      final savedItems = List<BillItem>.from(_billItems);

      // Convert to domain Bill for print/share dialog
      final createdBill = Bill.fromBillEntity(integrationResult.billEntity!);

      _clearBill();

      // Update local stock display
      _updateLocalStock(savedItems);

      // Background reload to ensure sync without blocking UI
      _loadProducts(showLoader: false);
      
      // Notify dashboard to refresh (bill count and products count may change)
      DashboardRefreshService.instance.notifyDataChanged(DataChangeType.bill);

      // Show success dialog with print/share options
      if (mounted) {
        _showBillSuccessDialog(createdBill);
      }
    } catch (e) {
      setState(() => _isSavingBill = false);
      _showSnackbar('${_localizations.error}: $e', isError: true);
    }
  }

  void _updateLocalStock(List<BillItem> savedItems) {
    setState(() {
      for (final item in savedItems) {
        // Extract real productId from batch-specific key
        final realProductId = item.productId.split('_batch_').first;
        final index = _products.indexWhere((p) => p.id == realProductId);
        if (index != -1) {
          final p = _products[index];
          final newStock = p.currentStock - item.quantity;
          if (newStock > 0) {
            _products[index] = p.copyWith(currentStock: newStock);
          } else {
            _products.removeAt(index);
          }
        }
      }
    });
  }

  void _clearBill() {
    setState(() {
      _billItems.clear();
      _customerNameController.clear();
      _customerContactController.clear();
      _notesController.clear();
      _discountController.clear();
      _receivedAmountController.clear();
      _discountValue = 0.0;
      _isPercentageDiscount = true;
      _selectedCustomer = null;
      _autoFoundCustomerName = null;
      _receivedAmount = 0.0;
      _isFullPayment = true;
    });
  }

  /// Create PrintBillData with customer's total due amount
  Future<PrintBillData> _createPrintBillData(Bill bill) async {
    double? totalDueAmount;

    // Get customer's total pending balance if customer ID exists
    if (bill.customerId != null && bill.customerId!.isNotEmpty) {
      try {
        final customer = await _customerRepository.getCustomerById(
          bill.customerId!,
        );
        if (customer != null) {
          totalDueAmount = customer.currentPendingAmount;
        }
      } catch (e) {
        print('[DEBUG] Error fetching customer pending balance: $e');
      }
    }

    return PrintBillData.fromBill(bill, totalDueAmount: totalDueAmount);
  }

  void _showSnackbar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontFamily: 'Literata')),
        backgroundColor: isError ? Colors.red[600] : Colors.green[600],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showBillSuccessDialog(Bill bill) {
    final dateFormat = DateFormat('dd MMM yyyy, hh:mm a');

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400, maxHeight: 650),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Success Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: Color(0xFF1B4D3E),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_circle,
                        color: Colors.white,
                        size: 40,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _localizations.billSavedSuccessfully,
                      style: const TextStyle(
                        fontFamily: 'Literata',
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      bill.billNumber,
                      style: TextStyle(
                        fontFamily: 'Literata',
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),
              // Bill Summary
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSuccessDialogRow(
                        _localizations.date,
                        dateFormat.format(bill.billDate),
                      ),
                      if (bill.hasCustomerInfo) ...[
                        const Divider(height: 16),
                        _buildSuccessDialogRow(
                          _localizations.customer,
                          bill.customerName ?? _localizations.na,
                        ),
                      ],
                      const Divider(height: 16),
                      _buildSuccessDialogRow(
                        _localizations.items,
                        '${bill.items.length} ${_localizations.items.toLowerCase()} (${bill.totalQuantity} ${_localizations.qty.toLowerCase()})',
                      ),
                      const Divider(height: 16),
                      _buildSuccessDialogRow(
                        _localizations.subtotal,
                        '₹${bill.totalAmount.toStringAsFixed(2)}',
                      ),
                      if (bill.discountAmount > 0) ...[
                        const SizedBox(height: 4),
                        _buildSuccessDialogRow(
                          _localizations.discount,
                          '-₹${bill.discountAmount.toStringAsFixed(2)}',
                          valueColor: Colors.green,
                        ),
                      ],
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _localizations.total,
                            style: const TextStyle(
                              fontFamily: 'Literata',
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1B4D3E),
                            ),
                          ),
                          Text(
                            '₹${bill.finalAmount.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontFamily: 'Literata',
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1B4D3E),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              // Actions
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(16),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Primary action based on bill type
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          if (_billType == 'pos') {
                            _printBillToPOS(bill);
                          } else {
                            _printNormalBill(bill);
                          }
                        },
                        icon: Icon(
                          _billType == 'pos' ? Icons.print : Icons.print_outlined,
                          size: 18,
                        ),
                        label: Text(
                          _billType == 'pos' 
                              ? _localizations.printToPOS 
                              : 'Print Bill',
                          style: const TextStyle(fontFamily: 'Literata'),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1B4D3E),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Secondary actions row
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              _shareBillAsPdf(bill);
                            },
                            icon: const Icon(Icons.share, size: 18),
                            label: Text(
                              _localizations.share,
                              style: const TextStyle(fontFamily: 'Literata'),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF1B4D3E),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              side: const BorderSide(color: Color(0xFF1B4D3E)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              _saveBillAsPdf(bill);
                            },
                            icon: const Icon(Icons.picture_as_pdf, size: 18),
                            label: Text(
                              _localizations.savePdf,
                              style: const TextStyle(fontFamily: 'Literata'),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF1B4D3E),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              side: const BorderSide(color: Color(0xFF1B4D3E)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Done button
                    SizedBox(
                      width: double.infinity,
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          _localizations.done,
                          style: TextStyle(
                            fontFamily: 'Literata',
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
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

  Widget _buildSuccessDialogRow(
    String label,
    String value, {
    Color? valueColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Literata',
            fontSize: 13,
            color: Colors.grey[600],
          ),
        ),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontFamily: 'Literata',
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: valueColor ?? Colors.black87,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _shareBillAsPdf(Bill bill) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1B4D3E)),
          ),
        ),
      );

      final shop = await _shopRepository.getShopDetails();
      final printData = await _createPrintBillData(bill);

      // Dismiss loader before showing share sheet
      if (mounted) Navigator.pop(context);

      // Share — this opens the system share sheet
      await _pdfService.shareBillAsPdf(billData: printData, shopDetails: shop);
    } catch (e) {
      // Only pop if the dialog is still showing (guard against double-pop)
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      if (mounted) {
        _showSnackbar('${_localizations.errorSharingBill}: $e', isError: true);
      }
    }
  }

  Future<void> _saveBillAsPdf(Bill bill) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1B4D3E)),
          ),
        ),
      );

      final shop = await _shopRepository.getShopDetails();
      final printData = await _createPrintBillData(bill);

      // Dismiss loader before opening system share/save dialog
      if (mounted) Navigator.pop(context);

      // Use Printing.sharePdf which opens native preview + save dialog
      final pw.Document pdf;
      final prefs = await SharedPreferences.getInstance();
      final billType = prefs.getString('bill_type') ?? 'pos';
      if (billType == 'normal') {
        pdf = await _pdfService.generateNormalBillPdf(
          billData: printData,
          shopDetails: shop,
        );
      } else {
        pdf = await _pdfService.generateBillPdf(
          billData: printData,
          shopDetails: shop,
        );
      }

      final bytes = await pdf.save();
      await Printing.sharePdf(
        bytes: bytes,
        filename: 'bill_${bill.id.replaceAll('/', '_')}.pdf',
      );
    } catch (e) {
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      if (mounted) {
        _showSnackbar('${_localizations.errorSavingPdf}: $e', isError: true);
      }
    }
  }

  Future<void> _printBillToPOS(Bill bill) async {
    final selectedPrinter = await PrinterSelectionWidget.show(context);
    if (selectedPrinter == null || !mounted) return;

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1B4D3E)),
          ),
        ),
      );

      final connectResult = await _printerService.connectPrinter(
        selectedPrinter,
      );
      if (!connectResult.success) {
        if (mounted) Navigator.pop(context);
        _showSnackbar(
          '${_localizations.failedToConnect}: ${connectResult.message}',
          isError: true,
        );
        return;
      }

      final shop = await _shopRepository.getShopDetails();
      final printData = await _createPrintBillData(bill);

      final printResult = await _printerService.printBill(
        billData: printData,
        shopDetails: shop,
      );

      if (mounted) Navigator.pop(context);

      _showSnackbar(
        printResult.success
            ? _localizations.billPrintedSuccessfully
            : '${_localizations.printFailed}: ${printResult.message}',
        isError: !printResult.success,
      );
    } catch (e) {
      if (mounted) Navigator.pop(context);
      _showSnackbar('${_localizations.errorPrinting}: $e', isError: true);
    } finally {
      await _printerService.disconnectPrinter();
    }
  }

  /// Print normal bill via system print dialog (for regular printers)
  Future<void> _printNormalBill(Bill bill) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1B4D3E)),
          ),
        ),
      );

      final shop = await _shopRepository.getShopDetails();
      final printData = await _createPrintBillData(bill);

      if (mounted) Navigator.pop(context);

      // Use system print dialog
      await _pdfService.previewAndPrintPdf(
        billData: printData,
        shopDetails: shop,
      );
    } catch (e) {
      if (mounted) Navigator.pop(context);
      _showSnackbar('${_localizations.errorPrinting}: $e', isError: true);
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
          : widget.isEmbedded
          ? SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  // Header with settings button for embedded view
                  _buildEmbeddedHeader(),
                  if (_showCustomerOnBill || _generateBillViaContact) _buildCustomerSection(),
                  _buildAddItemsSection(),
                  if (_billItems.isNotEmpty) _buildBillItemsSection(),
                  if (_billItems.isNotEmpty) _buildDiscountSection(),
                  if (_billItems.isNotEmpty) _buildPaymentSection(),
                  const SizedBox(height: 100),
                ],
              ),
            )
          : CustomScrollView(
              slivers: [
                _buildSliverAppBar(),
                if (_showCustomerOnBill || _generateBillViaContact) 
                  SliverToBoxAdapter(child: _buildCustomerSection()),
                SliverToBoxAdapter(child: _buildAddItemsSection()),
                if (_billItems.isNotEmpty)
                  SliverToBoxAdapter(child: _buildBillItemsSection()),
                if (_billItems.isNotEmpty)
                  SliverToBoxAdapter(child: _buildDiscountSection()),
                if (_billItems.isNotEmpty)
                  SliverToBoxAdapter(child: _buildPaymentSection()),
                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 0,
      floating: true,
      pinned: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      automaticallyImplyLeading: false,
      flexibleSpace: PreferredSize(
        preferredSize: const Size.fromHeight(70),
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1B4D3E), Color(0xFF0F3B2F)],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1B4D3E).withOpacity(0.2),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _localizations.createBill,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'Literata',
                            height: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_billItems.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${_billItems.length} ${_localizations.items.toLowerCase()}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Literata',
                        ),
                      ),
                    ),
                  const SizedBox(width: 8),
                  // Settings button
                  IconButton(
                    icon: const Icon(Icons.settings, color: Colors.white, size: 24),
                    onPressed: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const BillSettingsPage(),
                        ),
                      );
                      // Reload settings when returning if settings changed
                      if (result == true) {
                        _loadBillSettings();
                      }
                    },
                    tooltip: 'Bill Settings',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Header widget for embedded view
  Widget _buildEmbeddedHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Text(
            _localizations.createBill,
            style: const TextStyle(
              color: Color(0xFF1B4D3E),
              fontSize: 22,
              fontWeight: FontWeight.w700,
              fontFamily: 'Literata',
            ),
          ),
          if (_billItems.isNotEmpty) ...[
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF1B4D3E).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${_billItems.length} ${_localizations.items.toLowerCase()}',
                style: const TextStyle(
                  color: Color(0xFF1B4D3E),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Literata',
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCustomerSection() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF1B4D3E).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.person_outline,
                  color: Color(0xFF1B4D3E),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                _generateBillViaContact
                    ? 'Phone Number'
                    : _localizations.customerOptional,
                style: const TextStyle(
                  fontFamily: 'Literata',
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  color: Color(0xFF1B4D3E),
                ),
              ),
              const Spacer(),
              // Add Customer button (only when not in generate via contact mode)
              if (!_generateBillViaContact)
                IconButton(
                  icon: const Icon(Icons.person_add, color: Color(0xFF1B4D3E)),
                  onPressed: () {
                    final phone = _customerContactController.text.trim();
                    _showAddCustomerDialog(phone);
                  },
                  tooltip: 'Add New Customer',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (_generateBillViaContact) ...[
            // Show only phone number field when generate via contact is enabled
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _customerContactController,
                  keyboardType: TextInputType.phone,
                  style: const TextStyle(fontFamily: 'Literata', fontSize: 14),
                  decoration: InputDecoration(
                    labelText: 'Enter Phone Number *',
                    hintText: 'Enter customer phone number',
                    hintStyle: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 13,
                    ),
                    labelStyle: const TextStyle(
                      color: Color(0xFF1B4D3E),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                    prefixIcon: const Icon(
                      Icons.phone_outlined,
                      color: Color(0xFF1B4D3E),
                      size: 20,
                    ),
                    suffixIcon: _isSearchingCustomer
                        ? const Padding(
                            padding: EdgeInsets.all(12.0),
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Color(0xFF1B4D3E),
                              ),
                            ),
                          )
                        : _hasPhoneText
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 20),
                                onPressed: () {
                                  _customerContactController.clear();
                                  setState(() {
                                    _autoFoundCustomerName = null;
                                    _selectedCustomer = null;
                                    _hasPhoneText = false;
                                  });
                                },
                                color: Colors.grey[600],
                                tooltip: 'Clear phone number',
                              )
                            : null,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 14,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF1B4D3E)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: const Color(0xFF1B4D3E).withOpacity(0.5)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Color(0xFF1B4D3E),
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
                if (_autoFoundCustomerName != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 6, left: 4),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.check_circle,
                          size: 14,
                          color: Colors.green,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            'Customer: $_autoFoundCustomerName',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.green,
                              fontFamily: 'Literata',
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ] else ...[
            // Normal customer section with all fields
            if (_customers.isNotEmpty) ...[
              GestureDetector(
                onTap: _showCustomerPicker,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.search, color: Colors.grey[500], size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _selectedCustomer != null
                              ? _selectedCustomer!['fullName']
                              : _localizations.searchExistingCustomer,
                          style: TextStyle(
                            fontFamily: 'Literata',
                            color: _selectedCustomer != null
                                ? Colors.black87
                                : Colors.grey[500],
                          ),
                        ),
                      ),
                      if (_selectedCustomer != null)
                        GestureDetector(
                          onTap: () => setState(() {
                            _selectedCustomer = null;
                            _customerNameController.clear();
                            _customerContactController.clear();
                          }),
                          child: Icon(
                            Icons.close,
                            color: Colors.grey[500],
                            size: 18,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _customerNameController,
                    style: const TextStyle(fontFamily: 'Literata', fontSize: 14),
                    decoration: InputDecoration(
                      labelText: _localizations.name,
                      labelStyle: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 13,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Color(0xFF1B4D3E),
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: _customerContactController,
                        keyboardType: TextInputType.phone,
                        style: const TextStyle(fontFamily: 'Literata', fontSize: 14),
                        decoration: InputDecoration(
                          labelText: _localizations.phone,
                          labelStyle: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 13,
                          ),
                          suffixIcon: _isSearchingCustomer
                              ? const Padding(
                                  padding: EdgeInsets.all(12.0),
                                  child: SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Color(0xFF1B4D3E),
                                    ),
                                  ),
                                )
                              : _hasPhoneText
                                  ? IconButton(
                                      icon: const Icon(Icons.clear, size: 20),
                                      onPressed: () {
                                        _customerContactController.clear();
                                        setState(() {
                                          _autoFoundCustomerName = null;
                                          _selectedCustomer = null;
                                          _hasPhoneText = false;
                                        });
                                      },
                                      color: Colors.grey[600],
                                      tooltip: 'Clear phone number',
                                    )
                                  : null,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFF1B4D3E),
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                      if (_autoFoundCustomerName != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 6, left: 4),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.check_circle,
                                size: 14,
                                color: Colors.green,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  'Customer: $_autoFoundCustomerName',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.green,
                                    fontFamily: 'Literata',
                                    fontWeight: FontWeight.w600,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  /// Add product by index number directly from the Create Bill page
  /// Uses FIFO: picks the oldest batch's selling price automatically
  void _addProductByIndexNoOnPage() {
    final indexText = _indexNoController.text.trim();
    if (indexText.isEmpty) return;

    final indexNo = int.tryParse(indexText);
    if (indexNo == null) {
      _showSnackbar(_localizations.pleaseEnterValidNumber, isError: true);
      _indexNoController.clear();
      return;
    }

    final product = _productByIndexNo[indexNo];
    if (product == null) {
      _showSnackbar(
        '${_localizations.productNotFound} #$indexNo',
        isError: true,
      );
      _indexNoController.clear();
      return;
    }

    // Check FIFO batch stock first
    final productBatches = _availableBatches
        .where((b) => b.productId == product.id && b.quantityRemaining > 0)
        .toList()
      ..sort((a, b) => a.purchaseDate.compareTo(b.purchaseDate));
    final batchStock = productBatches.fold<int>(0, (s, b) => s + b.quantityRemaining);
    final effectiveStock = batchStock > 0 ? batchStock : product.currentStock;

    if (effectiveStock <= 0) {
      _showSnackbar(
        '${product.name} ${_localizations.outOfStock}',
        isError: true,
      );
      _indexNoController.clear();
      return;
    }

    // Show batch selection for all products with batches
    if (productBatches.isNotEmpty) {
      _indexNoController.clear();
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (ctx) => _BatchSelectionSheet(
          productName: product.name,
          productCode: product.indexNo,
          batches: productBatches,
          localizations: _localizations,
          existingBillItems: _billItems,
          onBatchSelected: (batch, quantity) {
            final uniqueKey = '${product.id}_batch_${batch.id}';
            final existingIndex = _billItems.indexWhere(
              (item) => item.productId == uniqueKey,
            );
            setState(() {
              final displayName = batch.companyName.isNotEmpty
                  ? '${product.name} (${batch.companyName})'
                  : product.name;
              if (existingIndex != -1) {
                _billItems[existingIndex] = BillItem.create(
                  productId: uniqueKey,
                  productName: displayName,
                  sellingPrice: batch.sellingPrice,
                  purchasePrice: batch.purchasePrice,
                  quantity: quantity,
                );
              } else {
                _billItems.add(
                  BillItem.create(
                    productId: uniqueKey,
                    productName: displayName,
                    sellingPrice: batch.sellingPrice,
                    purchasePrice: batch.purchasePrice,
                    quantity: quantity,
                  ),
                );
              }
            });
            Navigator.pop(ctx);
            _showSnackbar('${_localizations.added}: ${product.name}', isError: false);
          },
        ),
      );
      _indexNoFocusNode.requestFocus();
      return;
    }

    // No batches — fallback to product-level data
    final fifoPrice = product.salesPrice;
    final fifoPurchasePrice = product.purchasePrice;
    final uniqueKey = product.id;
    final displayName = product.companyName.isNotEmpty
        ? '${product.name} (${product.companyName})'
        : product.name;

    // Add product — increment quantity if already in cart
    final existingIndex = _billItems.indexWhere(
      (item) => item.productId == uniqueKey,
    );
    setState(() {
      if (existingIndex != -1) {
        final existing = _billItems[existingIndex];
        if (existing.quantity < effectiveStock) {
          _billItems[existingIndex] = BillItem.create(
            productId: uniqueKey,
            productName: displayName,
            sellingPrice: existing.sellingPrice,
            purchasePrice: fifoPurchasePrice,
            quantity: existing.quantity + 1,
          );
        } else {
          _showSnackbar(
            '${_localizations.maxStock}: $effectiveStock',
            isError: true,
          );
          _indexNoController.clear();
          return;
        }
      } else {
        _billItems.add(
          BillItem.create(
            productId: uniqueKey,
            productName: displayName,
            sellingPrice: fifoPrice,
            purchasePrice: fifoPurchasePrice,
            quantity: 1,
          ),
        );
      }
    });

    _showSnackbar('${_localizations.added}: ${product.name}', isError: false);

    // Clear input and keep focus for next entry
    _indexNoController.clear();
    _indexNoFocusNode.requestFocus();
  }

  void _onPageIndexNoChanged() {
    _debounceTimer?.cancel();
    if (_indexNoController.text.trim().isEmpty) return;
    _debounceTimer = Timer(const Duration(milliseconds: 800), () {
      _addProductByIndexNoOnPage();
    });
  }

  Widget _buildAddItemsSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          // Quick add by index number
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF1B4D3E).withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF1B4D3E).withOpacity(0.2),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1B4D3E),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.flash_on,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _indexNoController,
                    focusNode: _indexNoFocusNode,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(
                      fontFamily: 'Literata',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    decoration: InputDecoration(
                      hintText: _localizations.enterProductCode,
                      hintStyle: TextStyle(
                        color: Colors.grey[500],
                        fontWeight: FontWeight.w400,
                        fontSize: 14,
                      ),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    onChanged: (_) => _onPageIndexNoChanged(),
                    onSubmitted: (_) => _addProductByIndexNoOnPage(),
                  ),
                ),
                Material(
                  color: const Color(0xFF1B4D3E),
                  borderRadius: BorderRadius.circular(8),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: _addProductByIndexNoOnPage,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Text(
                        _localizations.add,
                        style: const TextStyle(
                          fontFamily: 'Literata',
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          // Search product button — opens bottom sheet
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _showAddItemsPopup,
              icon: const Icon(Icons.search, size: 20),
              label: Text(
                _localizations.searchProduct,
                style: const TextStyle(
                  fontFamily: 'Literata',
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF1B4D3E),
                side: const BorderSide(color: Color(0xFF1B4D3E), width: 1.5),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBillItemsSection() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1B4D3E).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.receipt_long,
                    color: Color(0xFF1B4D3E),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  _localizations.billItems,
                  style: const TextStyle(
                    fontFamily: 'Literata',
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: Color(0xFF1B4D3E),
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1B4D3E),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_billItems.length} ${_localizations.items.toLowerCase()}',
                    style: const TextStyle(
                      fontFamily: 'Literata',
                      fontSize: 11,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _billItems.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final item = _billItems[index];
              // Parse batch-specific key to find the real product
              final realProductId = item.productId.split('_batch_').first;
              final product = _products.firstWhere(
                (p) => p.id == realProductId,
                orElse: () => Product(
                  id: realProductId,
                  indexNo: 0,
                  name: item.productName,
                  companyName: '',
                  category: '',
                  purchasePrice: 0,
                  salesPrice: item.sellingPrice,
                  currentStock: 999,
                  createdAt: DateTime.now(),
                  updatedAt: DateTime.now(),
                ),
              );
              return Dismissible(
                key: Key('${item.productId}_$index'),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  color: Colors.red[400],
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                onDismissed: (_) => setState(() => _billItems.removeAt(index)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.productName,
                              style: const TextStyle(
                                fontFamily: 'Literata',
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '₹${item.sellingPrice.toStringAsFixed(0)} each',
                              style: TextStyle(
                                fontFamily: 'Literata',
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Quantity controls
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F5F5),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildQtyButton(
                              icon: Icons.remove,
                              onPressed: () {
                                if (item.quantity > 1) {
                                  setState(() {
                                    _billItems[index] = BillItem.create(
                                      productId: item.productId,
                                      productName: item.productName,
                                      sellingPrice: item.sellingPrice,
                                      quantity: item.quantity - 1,
                                    );
                                  });
                                } else {
                                  setState(() => _billItems.removeAt(index));
                                }
                              },
                            ),
                            Container(
                              constraints: const BoxConstraints(minWidth: 36),
                              alignment: Alignment.center,
                              child: Text(
                                '${item.quantity}',
                                style: const TextStyle(
                                  fontFamily: 'Literata',
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            _buildQtyButton(
                              icon: Icons.add,
                              onPressed: () {
                                // Parse batch-specific key: productId_batch_localId
                                final parts = item.productId.split('_batch_');
                                final realProductId = parts.first;
                                final batchLocalId = parts.length > 1 ? int.tryParse(parts.last) : null;
                                
                                int maxStock;
                                if (batchLocalId != null) {
                                  // Specific batch — use that batch's remaining quantity
                                  final batch = _availableBatches.cast<PurchaseBatchEntity?>().firstWhere(
                                    (b) => b!.id == batchLocalId && b.quantityRemaining > 0,
                                    orElse: () => null,
                                  );
                                  maxStock = batch?.quantityRemaining ?? 0;
                                } else {
                                  // No batch info — use total batch stock or product stock
                                  final batchStock = _availableBatches
                                      .where((b) => b.productId == realProductId && b.quantityRemaining > 0)
                                      .fold<int>(0, (s, b) => s + b.quantityRemaining);
                                  maxStock = batchStock > 0 ? batchStock : product.currentStock;
                                }
                                
                                if (item.quantity < maxStock) {
                                  setState(() {
                                    _billItems[index] = BillItem.create(
                                      productId: item.productId,
                                      productName: item.productName,
                                      sellingPrice: item.sellingPrice,
                                      quantity: item.quantity + 1,
                                    );
                                  });
                                } else {
                                  _showSnackbar(
                                    '${_localizations.maxStock}: $maxStock',
                                    isError: true,
                                  );
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Subtotal
                      SizedBox(
                        width: 65,
                        child: Text(
                          '₹${item.subtotal.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontFamily: 'Literata',
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: Color(0xFF1B4D3E),
                          ),
                          textAlign: TextAlign.right,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Delete button
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(8),
                          onTap: () =>
                              setState(() => _billItems.removeAt(index)),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            child: Icon(
                              Icons.delete_outline,
                              size: 20,
                              color: Colors.red[600],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDiscountSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.discount_outlined,
                  color: Color(0xFF1B4D3E),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                _localizations.discount,
                style: const TextStyle(
                  fontFamily: 'Literata',
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  color: Color(0xFF1B4D3E),
                ),
              ),
              const Spacer(),
              if (_discountAmount > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '-₹${_discountAmount.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontFamily: 'Literata',
                      fontSize: 12,
                      color: Colors.green[700],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              // Discount type toggle
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildDiscountTypeButton(
                      label: '%',
                      isSelected: _isPercentageDiscount,
                      onTap: () {
                        setState(() {
                          _isPercentageDiscount = true;
                          _updateDiscount(_discountController.text);
                        });
                      },
                    ),
                    _buildDiscountTypeButton(
                      label: '₹',
                      isSelected: !_isPercentageDiscount,
                      onTap: () {
                        setState(() {
                          _isPercentageDiscount = false;
                          _updateDiscount(_discountController.text);
                        });
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Discount input
              Expanded(
                child: TextField(
                  controller: _discountController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  style: const TextStyle(fontFamily: 'Literata', fontSize: 14),
                  onChanged: _updateDiscount,
                  decoration: InputDecoration(
                    hintText: _isPercentageDiscount
                        ? _localizations.enterPercent
                        : _localizations.enterAmount,
                    hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Color(0xFF1B4D3E),
                        width: 1.5,
                      ),
                    ),
                    suffixIcon: _discountController.text.isNotEmpty
                        ? IconButton(
                            icon: Icon(
                              Icons.clear,
                              size: 18,
                              color: Colors.grey[500],
                            ),
                            onPressed: () {
                              _discountController.clear();
                              _updateDiscount('');
                            },
                          )
                        : null,
                  ),
                ),
              ),
            ],
          ),
          // Quick discount buttons
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildQuickDiscountChip('5%', 5, true),
              _buildQuickDiscountChip('10%', 10, true),
              _buildQuickDiscountChip('15%', 15, true),
              _buildQuickDiscountChip('20%', 20, true),
            ],
          ),
          // Summary
          if (_discountAmount > 0) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _localizations.subtotal,
                        style: TextStyle(
                          fontFamily: 'Literata',
                          fontSize: 13,
                          color: Colors.grey[700],
                        ),
                      ),
                      Text(
                        '₹${_totalAmount.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontFamily: 'Literata',
                          fontSize: 13,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Discount (${_discountPercent.toStringAsFixed(1)}%)',
                        style: TextStyle(
                          fontFamily: 'Literata',
                          fontSize: 13,
                          color: Colors.green[700],
                        ),
                      ),
                      Text(
                        '-₹${_discountAmount.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontFamily: 'Literata',
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.green[700],
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _localizations.finalTotal,
                        style: const TextStyle(
                          fontFamily: 'Literata',
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1B4D3E),
                        ),
                      ),
                      Text(
                        '₹${_finalAmount.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontFamily: 'Literata',
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1B4D3E),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPaymentSection() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF1B4D3E).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.payments_outlined,
                  color: Color(0xFF1B4D3E),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                _localizations.payment,
                style: const TextStyle(
                  fontFamily: 'Literata',
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1B4D3E),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Payment type toggle
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildPaymentTypeButton(
                    label: _localizations.fullPayment,
                    isSelected: _isFullPayment,
                    onTap: () {
                      setState(() {
                        _isFullPayment = true;
                        _receivedAmount = _finalAmount;
                        _receivedAmountController.text = _finalAmount
                            .toStringAsFixed(2);
                      });
                    },
                  ),
                ),
                Expanded(
                  child: _buildPaymentTypeButton(
                    label: _localizations.partialPayment,
                    isSelected: !_isFullPayment,
                    onTap: () {
                      setState(() {
                        _isFullPayment = false;
                        _receivedAmount = 0.0;
                        _receivedAmountController.clear();
                      });
                    },
                  ),
                ),
              ],
            ),
          ),

          // Received amount input (only show for partial payment)
          if (!_isFullPayment) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _localizations.receivedAmount,
                        style: TextStyle(
                          fontFamily: 'Literata',
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.grey[200]!),
                        ),
                        child: TextField(
                          controller: _receivedAmountController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          style: const TextStyle(
                            fontFamily: 'Literata',
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1B4D3E),
                          ),
                          decoration: InputDecoration(
                            prefixText: '₹ ',
                            prefixStyle: TextStyle(
                              fontFamily: 'Literata',
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[600],
                            ),
                            hintText: '0.00',
                            hintStyle: TextStyle(
                              fontFamily: 'Literata',
                              color: Colors.grey[400],
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                          ),
                          onChanged: (value) {
                            final parsed = double.tryParse(value) ?? 0.0;
                            setState(() {
                              // Cap received amount at final amount
                              _receivedAmount = parsed.clamp(0.0, _finalAmount);
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _localizations.pendingAmount,
                        style: TextStyle(
                          fontFamily: 'Literata',
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: _pendingAmount > 0
                              ? Colors.orange[50]
                              : Colors.green[50],
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: _pendingAmount > 0
                                ? Colors.orange[200]!
                                : Colors.green[200]!,
                          ),
                        ),
                        child: Text(
                          '₹ ${_pendingAmount.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontFamily: 'Literata',
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: _pendingAmount > 0
                                ? Colors.orange[700]
                                : Colors.green[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Quick amount buttons
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildQuickAmountChip('25%', _finalAmount * 0.25),
                _buildQuickAmountChip('50%', _finalAmount * 0.50),
                _buildQuickAmountChip('75%', _finalAmount * 0.75),
                _buildQuickAmountChip('Full', _finalAmount),
              ],
            ),
          ],

          // Customer requirement notice for pending payment
          if (!_isFullPayment &&
              _pendingAmount > 0 &&
              _selectedCustomer == null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.amber[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 18, color: Colors.amber[700]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _localizations.selectCustomerForPending,
                      style: TextStyle(
                        fontFamily: 'Literata',
                        fontSize: 12,
                        color: Colors.amber[800],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Summary for partial payment
          if (!_isFullPayment && _receivedAmount > 0) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF1B4D3E).withOpacity(0.05),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  _buildPaymentSummaryRow(
                    _localizations.billTotal,
                    '₹${_finalAmount.toStringAsFixed(2)}',
                  ),
                  const SizedBox(height: 6),
                  _buildPaymentSummaryRow(
                    _localizations.received,
                    '₹${_receivedAmount.toStringAsFixed(2)}',
                    color: Colors.green[700],
                  ),
                  const Divider(height: 16),
                  _buildPaymentSummaryRow(
                    _localizations.pending,
                    '₹${_pendingAmount.toStringAsFixed(2)}',
                    color: _pendingAmount > 0
                        ? Colors.orange[700]
                        : Colors.green[700],
                    isBold: true,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPaymentTypeButton({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1B4D3E) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'Literata',
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : Colors.grey[600],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickAmountChip(String label, double amount) {
    final isSelected = _receivedAmount == amount;
    return GestureDetector(
      onTap: () {
        setState(() {
          _receivedAmount = amount;
          _receivedAmountController.text = amount.toStringAsFixed(2);
          if (amount >= _finalAmount) {
            _isFullPayment = true;
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1B4D3E) : Colors.grey[100],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF1B4D3E) : Colors.grey[300]!,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Literata',
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: isSelected ? Colors.white : Colors.grey[700],
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentSummaryRow(
    String label,
    String value, {
    Color? color,
    bool isBold = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Literata',
            fontSize: 13,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.normal,
            color: Colors.grey[700],
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontFamily: 'Literata',
            fontSize: isBold ? 15 : 13,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w600,
            color: color ?? Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildDiscountTypeButton({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1B4D3E) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Literata',
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : Colors.grey[600],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickDiscountChip(String label, double value, bool isPercent) {
    final isSelected =
        _isPercentageDiscount == isPercent && _discountValue == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _isPercentageDiscount = isPercent;
          _discountValue = value;
          _discountController.text = value.toStringAsFixed(0);
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1B4D3E) : Colors.grey[100],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF1B4D3E) : Colors.grey[300]!,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Literata',
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: isSelected ? Colors.white : Colors.grey[700],
          ),
        ),
      ),
    );
  }

  void _updateDiscount(String value) {
    setState(() {
      if (value.isEmpty) {
        _discountValue = 0.0;
      } else {
        final parsed = double.tryParse(value) ?? 0.0;
        if (_isPercentageDiscount) {
          // Cap percentage at 100%
          _discountValue = parsed.clamp(0.0, 100.0);
        } else {
          // Cap flat discount at total amount
          _discountValue = parsed.clamp(0.0, _totalAmount);
        }
      }
    });
  }

  Widget _buildBottomBar() {
    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).padding.bottom + 16,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$_totalQuantity ${_localizations.items.toLowerCase()}',
                  style: TextStyle(
                    fontFamily: 'Literata',
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 2),
                if (_discountAmount > 0) ...[
                  Text(
                    '₹${_totalAmount.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontFamily: 'Literata',
                      fontSize: 13,
                      color: Colors.grey[500],
                      decoration: TextDecoration.lineThrough,
                    ),
                  ),
                  Row(
                    children: [
                      Text(
                        '₹${_finalAmount.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontFamily: 'Literata',
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1B4D3E),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green[50],
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '-${_discountPercent.toStringAsFixed(0)}%',
                          style: TextStyle(
                            fontFamily: 'Literata',
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Colors.green[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                ] else
                  Text(
                    '₹${_totalAmount.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontFamily: 'Literata',
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1B4D3E),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: _isSavingBill || _billItems.isEmpty ? null : _saveBill,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1B4D3E),
                disabledBackgroundColor: Colors.grey[300],
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              child: _isSavingBill
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(Colors.white),
                      ),
                    )
                  : Text(
                      _localizations.saveBill,
                      style: const TextStyle(
                        fontFamily: 'Literata',
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQtyButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(6),
        onTap: onPressed,
        child: Container(
          padding: const EdgeInsets.all(6),
          child: Icon(icon, size: 18, color: const Color(0xFF1B4D3E)),
        ),
      ),
    );
  }

  void _showCustomerPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _CustomerPickerBottomSheet(
        customers: _customers,
        localizations: _localizations,
        onCustomerSelected: (customer) {
          setState(() {
            _selectedCustomer = customer;
            _customerNameController.text = customer['fullName'] ?? '';
            _customerContactController.text = customer['contact'] ?? '';
          });
          Navigator.pop(ctx);
        },
      ),
    );
  }
}

/// Bottom sheet widget for adding multiple items to the bill
/// Step 1: Shows products grouped by name with total stock
/// Step 2: When tapping a product, shows batch selection for specific stock entry
class _AddItemsBottomSheet extends StatefulWidget {
  final List<Product> products;
  final List<BillItem> billItems;
  final List<PurchaseBatchEntity> availableBatches;
  final Function(String productId, String productName, String companyName, int? batchLocalId, double sellingPrice, double purchasePrice, int quantity, int maxStock) onBatchItemAdded;
  final Function(String uniqueKey) onItemRemoved;
  final Function(String message, {bool isError}) showSnackbar;
  final AppLocalizations localizations;

  const _AddItemsBottomSheet({
    required this.products,
    required this.billItems,
    required this.availableBatches,
    required this.onBatchItemAdded,
    required this.onItemRemoved,
    required this.showSnackbar,
    required this.localizations,
  });

  @override
  State<_AddItemsBottomSheet> createState() => _AddItemsBottomSheetState();
}

class _AddItemsBottomSheetState extends State<_AddItemsBottomSheet> {
  late List<_GroupedBillingProduct> _allGroupedProducts;
  late List<_GroupedBillingProduct> _filteredGroups;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _buildGroupedProducts();
  }

  /// Build grouped products: group by product name (lowercase), aggregate all batches
  void _buildGroupedProducts() {
    final Map<String, _GroupedBillingProduct> groups = {};
    final productIdsWithBatches = <String>{};

    // Group batches by product name (normalized)
    for (final batch in widget.availableBatches) {
      if (batch.quantityRemaining <= 0) continue;
      productIdsWithBatches.add(batch.productId);

      final normalizedName = batch.productName.trim().toLowerCase();
      if (groups.containsKey(normalizedName)) {
        groups[normalizedName]!.batches.add(batch);
      } else {
        // Find matching product for indexNo
        final product = widget.products.cast<Product?>().firstWhere(
          (p) => p!.id == batch.productId,
          orElse: () => null,
        );
        groups[normalizedName] = _GroupedBillingProduct(
          productName: batch.productName.trim(),
          indexNo: product?.indexNo ?? 0,
          category: product?.category ?? batch.category,
          batches: [batch],
        );
      }
    }

    // Add products that have no batch entries (fallback to product-level data)
    for (final product in widget.products) {
      if (!productIdsWithBatches.contains(product.id) && product.currentStock > 0) {
        final normalizedName = product.name.trim().toLowerCase();
        if (!groups.containsKey(normalizedName)) {
          groups[normalizedName] = _GroupedBillingProduct(
            productName: product.name.trim(),
            indexNo: product.indexNo,
            category: product.category,
            batches: [],
            fallbackProduct: product,
          );
        }
      }
    }

    final items = groups.values.toList()
      ..sort((a, b) => a.productName.toLowerCase().compareTo(b.productName.toLowerCase()));

    _allGroupedProducts = items;
    _filteredGroups = items;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterProducts(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredGroups = _allGroupedProducts;
      } else {
        final lowerQuery = query.toLowerCase();
        final indexNo = int.tryParse(query);
        _filteredGroups = _allGroupedProducts
            .where(
              (item) =>
                  item.productName.toLowerCase().contains(lowerQuery) ||
                  item.category.toLowerCase().contains(lowerQuery) ||
                  item.allCompanyNames.any((c) => c.toLowerCase().contains(lowerQuery)) ||
                  (indexNo != null && item.indexNo == indexNo),
            )
            .toList();
      }
    });
  }

  /// Count total items added to bill
  int get _totalItems {
    int count = 0;
    for (final item in widget.billItems) {
      count += item.quantity;
    }
    return count;
  }

  /// Check if any batch from this product group is already in the bill
  int _getGroupQuantityInBill(_GroupedBillingProduct group) {
    int total = 0;
    for (final billItem in widget.billItems) {
      // Check if bill item belongs to this product group
      for (final batch in group.batches) {
        final uniqueKey = '${batch.productId}_batch_${batch.id}';
        if (billItem.productId == uniqueKey) {
          total += billItem.quantity;
        }
      }
      // Also check fallback product
      if (group.fallbackProduct != null && billItem.productId == group.fallbackProduct!.id) {
        total += billItem.quantity;
      }
    }
    return total;
  }

  void _showBatchSelection(_GroupedBillingProduct group) {
    // Fallback product with no batches — add directly
    if (group.batches.isEmpty && group.fallbackProduct != null) {
      final product = group.fallbackProduct!;
      final existingQty = widget.billItems
          .where((item) => item.productId == product.id)
          .fold<int>(0, (s, item) => s + item.quantity);
      
      if (existingQty < product.currentStock) {
        widget.onBatchItemAdded(
          product.id,
          product.name,
          product.companyName,
          null,
          product.salesPrice,
          product.purchasePrice,
          existingQty + 1,
          product.currentStock,
        );
        setState(() {});
        widget.showSnackbar('${widget.localizations.added}: ${product.name}', isError: false);
      } else {
        widget.showSnackbar(
          '${widget.localizations.maxStock}: ${product.currentStock}',
          isError: true,
        );
      }
      return;
    }

    // Has batches (1 or more) — always show batch selection bottom sheet
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _BatchSelectionSheet(
        productName: group.productName,
        productCode: group.indexNo,
        batches: group.batches,
        localizations: widget.localizations,
        existingBillItems: widget.billItems,
        onBatchSelected: (batch, quantity) {
          widget.onBatchItemAdded(
            batch.productId,
            batch.productName,
            batch.companyName,
            batch.id,
            batch.sellingPrice,
            batch.purchasePrice,
            quantity,
            batch.quantityRemaining,
          );
          setState(() {});
          Navigator.pop(ctx);
          widget.showSnackbar('${widget.localizations.added}: ${batch.productName}', isError: false);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (_, controller) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
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
                      Icons.add_shopping_cart,
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
                          widget.localizations.addItems,
                          style: const TextStyle(
                            fontFamily: 'Literata',
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1B4D3E),
                          ),
                        ),
                        Text(
                          widget.localizations.tapToAddItems,
                          style: const TextStyle(
                            fontFamily: 'Literata',
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_totalItems > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1B4D3E),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '$_totalItems ${widget.localizations.items.toLowerCase()}',
                        style: const TextStyle(
                          fontFamily: 'Literata',
                          fontSize: 13,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // Search bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                controller: _searchController,
                onChanged: _filterProducts,
                style: const TextStyle(fontFamily: 'Literata', fontSize: 14),
                decoration: InputDecoration(
                  hintText: widget.localizations.searchProducts,
                  hintStyle: TextStyle(color: Colors.grey[500]),
                  prefixIcon: const Icon(
                    Icons.search,
                    color: Color(0xFF1B4D3E),
                  ),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 20),
                          onPressed: () {
                            _searchController.clear();
                            _filterProducts('');
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
            ),
            const SizedBox(height: 12),
            // Grouped products list (Step 1)
            Expanded(
              child: _filteredGroups.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.inventory_2_outlined,
                            size: 48,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            widget.localizations.noProductsFound,
                            style: TextStyle(
                              fontFamily: 'Literata',
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      controller: controller,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _filteredGroups.length,
                      itemBuilder: (context, index) {
                        final group = _filteredGroups[index];
                        final qtyInBill = _getGroupQuantityInBill(group);
                        final isAdded = qtyInBill > 0;
                        final hasMultipleBatches = group.batches.length > 1;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: isAdded
                                ? const Color(0xFFE8F5E9)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isAdded
                                  ? const Color(0xFF1B4D3E)
                                  : Colors.grey[200]!,
                              width: isAdded ? 1.5 : 1,
                            ),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () => _showBatchSelection(group),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Row(
                                  children: [
                                    // Product index number badge
                                    Container(
                                      width: 44,
                                      height: 44,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF1B4D3E),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Center(
                                        child: Text(
                                          group.indexNo > 0
                                              ? '${group.indexNo}'
                                              : '#',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 14,
                                            fontFamily: 'Literata',
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    // Product details
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            group.productName,
                                            style: const TextStyle(
                                              fontFamily: 'Literata',
                                              fontWeight: FontWeight.w600,
                                              fontSize: 14,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 3),
                                          // Company names (show unique companies)
                                          if (group.allCompanyNames.isNotEmpty) ...[
                                            Text(
                                              group.allCompanyNames.join(', '),
                                              style: TextStyle(
                                                fontFamily: 'Literata',
                                                fontSize: 11,
                                                color: Colors.grey[600],
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 3),
                                          ],
                                          Row(
                                            children: [
                                              // Price range
                                              Text(
                                                group.priceRangeDisplay,
                                                style: const TextStyle(
                                                  fontFamily: 'Literata',
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 13,
                                                  color: Color(0xFF1B4D3E),
                                                ),
                                              ),
                                              // Variant count badge
                                              if (hasMultipleBatches) ...[
                                                const SizedBox(width: 6),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(
                                                    horizontal: 6,
                                                    vertical: 2,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: Colors.blue.withValues(alpha: 0.1),
                                                    borderRadius: BorderRadius.circular(4),
                                                  ),
                                                  child: Text(
                                                    '${group.batches.length} ${widget.localizations.variants}',
                                                    style: TextStyle(
                                                      fontFamily: 'Literata',
                                                      fontSize: 9,
                                                      fontWeight: FontWeight.w700,
                                                      color: Colors.blue[700],
                                                    ),
                                                  ),
                                                ),
                                              ],
                                              const SizedBox(width: 6),
                                              // Total stock badge
                                              Container(
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: 6,
                                                  vertical: 2,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: group.totalStock > 10
                                                      ? Colors.green[50]
                                                      : group.totalStock > 0
                                                      ? Colors.orange[50]
                                                      : Colors.red[50],
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: Text(
                                                  '${group.totalStock} left',
                                                  style: TextStyle(
                                                    fontFamily: 'Literata',
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.w600,
                                                    color: group.totalStock > 10
                                                        ? Colors.green[700]
                                                        : group.totalStock > 0
                                                        ? Colors.orange[700]
                                                        : Colors.red[700],
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    // Action area
                                    if (isAdded)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF1B4D3E),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(
                                              Icons.check,
                                              color: Colors.white,
                                              size: 16,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              '$qtyInBill',
                                              style: const TextStyle(
                                                fontFamily: 'Literata',
                                                color: Colors.white,
                                                fontWeight: FontWeight.w700,
                                                fontSize: 13,
                                              ),
                                            ),
                                          ],
                                        ),
                                      )
                                    else
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: hasMultipleBatches
                                              ? Colors.blue[50]
                                              : const Color(0xFF1B4D3E).withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Icon(
                                          hasMultipleBatches
                                              ? Icons.expand_more
                                              : Icons.add,
                                          color: hasMultipleBatches
                                              ? Colors.blue[700]
                                              : const Color(0xFF1B4D3E),
                                          size: 20,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
            // Done button
            Container(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 16,
                bottom: MediaQuery.of(context).padding.bottom + 16,
              ),
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
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1B4D3E),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    _totalItems > 0
                        ? '${widget.localizations.done} ($_totalItems ${widget.localizations.items.toLowerCase()})'
                        : widget.localizations.done,
                    style: const TextStyle(
                      fontFamily: 'Literata',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Bottom sheet widget for customer selection with search
class _CustomerPickerBottomSheet extends StatefulWidget {
  final List<Map<String, dynamic>> customers;
  final Function(Map<String, dynamic> customer) onCustomerSelected;
  final AppLocalizations localizations;

  const _CustomerPickerBottomSheet({
    required this.customers,
    required this.onCustomerSelected,
    required this.localizations,
  });

  @override
  State<_CustomerPickerBottomSheet> createState() =>
      _CustomerPickerBottomSheetState();
}

class _CustomerPickerBottomSheetState
    extends State<_CustomerPickerBottomSheet> {
  late List<Map<String, dynamic>> _filteredCustomers;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _filteredCustomers = widget.customers;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterCustomers(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredCustomers = widget.customers;
      } else {
        final lowerQuery = query.toLowerCase();
        _filteredCustomers = widget.customers
            .where(
              (c) =>
                  (c['fullName'] as String).toLowerCase().contains(
                    lowerQuery,
                  ) ||
                  (c['contact'] as String).toLowerCase().contains(lowerQuery),
            )
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      maxChildSize: 0.9,
      minChildSize: 0.4,
      builder: (_, controller) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
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
                      Icons.person_outline,
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
                          widget.localizations.selectCustomer,
                          style: const TextStyle(
                            fontFamily: 'Literata',
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1B4D3E),
                          ),
                        ),
                        Text(
                          widget.localizations.chooseFromExistingCustomers,
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
            // Search bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                controller: _searchController,
                onChanged: _filterCustomers,
                style: const TextStyle(fontFamily: 'Literata', fontSize: 14),
                decoration: InputDecoration(
                  hintText: widget.localizations.searchByNameOrPhone,
                  hintStyle: TextStyle(color: Colors.grey[500]),
                  prefixIcon: const Icon(
                    Icons.search,
                    color: Color(0xFF1B4D3E),
                  ),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 20),
                          onPressed: () {
                            _searchController.clear();
                            _filterCustomers('');
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
            ),
            const SizedBox(height: 12),
            // Customers list
            Expanded(
              child: _filteredCustomers.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.person_outline,
                            size: 48,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            widget.localizations.noCustomersFound,
                            style: TextStyle(
                              fontFamily: 'Literata',
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      controller: controller,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _filteredCustomers.length,
                      itemBuilder: (context, index) {
                        final customer = _filteredCustomers[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.grey[200]!,
                              width: 1,
                            ),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () => widget.onCustomerSelected(customer),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      backgroundColor: const Color(0xFF1B4D3E),
                                      child: Text(
                                        (customer['fullName'] as String)
                                                .isNotEmpty
                                            ? (customer['fullName']
                                                      as String)[0]
                                                  .toUpperCase()
                                            : '?',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            customer['fullName'] ?? '',
                                            style: const TextStyle(
                                              fontFamily: 'Literata',
                                              fontWeight: FontWeight.w600,
                                              fontSize: 15,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            customer['contact'] ?? '',
                                            style: TextStyle(
                                              fontFamily: 'Literata',
                                              color: Colors.grey[600],
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Icon(
                                      Icons.chevron_right,
                                      color: Colors.grey[400],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Represents a billable item in the Add Items sheet.
/// Wraps product data with FIFO batch information.
/// Groups products by name, aggregating all batches across companies/prices.
class _GroupedBillingProduct {
  final String productName;
  final int indexNo;
  final String category;
  final List<PurchaseBatchEntity> batches; // All batches for this product name (FIFO sorted)
  final Product? fallbackProduct; // For products without batch data

  _GroupedBillingProduct({
    required this.productName,
    required this.indexNo,
    required this.category,
    required this.batches,
    this.fallbackProduct,
  }) {
    // Sort batches FIFO (oldest first)
    batches.sort((a, b) => a.purchaseDate.compareTo(b.purchaseDate));
  }

  /// Total stock across all batches
  int get totalStock {
    if (batches.isNotEmpty) {
      return batches.fold<int>(0, (s, b) => s + b.quantityRemaining);
    }
    return fallbackProduct?.currentStock ?? 0;
  }

  /// All unique company names across batches
  List<String> get allCompanyNames {
    final names = <String>{};
    for (final batch in batches) {
      if (batch.companyName.isNotEmpty) {
        names.add(batch.companyName);
      }
    }
    if (names.isEmpty && fallbackProduct != null && fallbackProduct!.companyName.isNotEmpty) {
      names.add(fallbackProduct!.companyName);
    }
    return names.toList();
  }

  /// Price range display: single price or range
  String get priceRangeDisplay {
    if (batches.isEmpty) {
      return '₹${fallbackProduct?.salesPrice.toStringAsFixed(0) ?? '0'}';
    }
    final prices = batches.map((b) => b.sellingPrice).toSet().toList()..sort();
    if (prices.length == 1) {
      return '₹${prices.first.toStringAsFixed(0)}';
    }
    return '₹${prices.first.toStringAsFixed(0)} - ₹${prices.last.toStringAsFixed(0)}';
  }
}

/// Bottom sheet for selecting a specific batch/stock entry from a product
/// Step 2 of the billing flow: shows all available stock entries
class _BatchSelectionSheet extends StatefulWidget {
  final String productName;
  final int productCode;
  final List<PurchaseBatchEntity> batches;
  final AppLocalizations localizations;
  final List<BillItem> existingBillItems;
  final Function(PurchaseBatchEntity batch, int quantity) onBatchSelected;

  const _BatchSelectionSheet({
    required this.productName,
    this.productCode = 0,
    required this.batches,
    required this.localizations,
    required this.existingBillItems,
    required this.onBatchSelected,
  });

  @override
  State<_BatchSelectionSheet> createState() => _BatchSelectionSheetState();
}

class _BatchSelectionSheetState extends State<_BatchSelectionSheet> {
  int? _selectedBatchIndex;
  final _qtyController = TextEditingController(text: '1');
  final _batchSearchController = TextEditingController();
  String? _qtyError;
  late List<PurchaseBatchEntity> _filteredBatches;

  @override
  void initState() {
    super.initState();
    _filteredBatches = widget.batches;
  }

  @override
  void dispose() {
    _qtyController.dispose();
    _batchSearchController.dispose();
    super.dispose();
  }

  void _filterBatches(String query) {
    setState(() {
      _selectedBatchIndex = null;
      if (query.isEmpty) {
        _filteredBatches = widget.batches;
      } else {
        final lowerQuery = query.toLowerCase();
        _filteredBatches = widget.batches.where((batch) {
          return batch.companyName.toLowerCase().contains(lowerQuery) ||
              batch.sellingPrice.toStringAsFixed(0).contains(lowerQuery) ||
              batch.purchasePrice.toStringAsFixed(0).contains(lowerQuery) ||
              DateFormat('dd MMM yyyy').format(batch.purchaseDate).toLowerCase().contains(lowerQuery) ||
              (batch.supplierName?.toLowerCase().contains(lowerQuery) ?? false);
        }).toList();
      }
    });
  }

  int _getExistingQtyForBatch(PurchaseBatchEntity batch) {
    final uniqueKey = '${batch.productId}_batch_${batch.id}';
    return widget.existingBillItems
        .where((item) => item.productId == uniqueKey)
        .fold<int>(0, (s, item) => s + item.quantity);
  }

  void _validateQuantity() {
    if (_selectedBatchIndex == null) return;
    final batch = widget.batches[_selectedBatchIndex!];
    final existingQty = _getExistingQtyForBatch(batch);
    final maxAvailable = batch.quantityRemaining - existingQty;
    final qty = int.tryParse(_qtyController.text) ?? 0;
    
    setState(() {
      if (qty <= 0) {
        _qtyError = widget.localizations.pleaseEnterValidNumber;
      } else if (qty > maxAvailable) {
        _qtyError = '${widget.localizations.quantityExceedsStock} ($maxAvailable)';
      } else {
        _qtyError = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      maxChildSize: 0.9,
      minChildSize: 0.4,
      builder: (_, controller) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
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
                  // Product code badge
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1B4D3E),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        widget.productCode > 0 ? '${widget.productCode}' : '#',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          fontFamily: 'Literata',
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.productName,
                          style: const TextStyle(
                            fontFamily: 'Literata',
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1B4D3E),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Row(
                          children: [
                            Text(
                              widget.localizations.chooseSpecificBatch,
                              style: const TextStyle(
                                fontFamily: 'Literata',
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                            if (widget.productCode > 0) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1B4D3E).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '#${widget.productCode}',
                                  style: const TextStyle(
                                    fontFamily: 'Literata',
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF1B4D3E),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Search bar for batches
            if (widget.batches.length > 1)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: TextField(
                  controller: _batchSearchController,
                  onChanged: _filterBatches,
                  style: const TextStyle(fontFamily: 'Literata', fontSize: 14),
                  decoration: InputDecoration(
                    hintText: widget.localizations.searchBatches,
                    hintStyle: TextStyle(color: Colors.grey[500]),
                    prefixIcon: const Icon(
                      Icons.search,
                      color: Color(0xFF1B4D3E),
                      size: 20,
                    ),
                    suffixIcon: _batchSearchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _batchSearchController.clear();
                              _filterBatches('');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: const Color(0xFFF5F5F5),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
            // Available entries label
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Row(
                children: [
                  Text(
                    widget.localizations.availableEntries,
                    style: TextStyle(
                      fontFamily: 'Literata',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1B4D3E).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${_filteredBatches.length}',
                      style: const TextStyle(
                        fontFamily: 'Literata',
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1B4D3E),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            // Batch entries list
            Expanded(
              child: _filteredBatches.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.search_off, size: 48, color: Colors.grey[400]),
                          const SizedBox(height: 12),
                          Text(
                            widget.localizations.noBatchesFound,
                            style: TextStyle(
                              fontFamily: 'Literata',
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                controller: controller,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _filteredBatches.length,
                itemBuilder: (context, index) {
                  final batch = _filteredBatches[index];
                  final isSelected = _selectedBatchIndex == index;
                  // Check if this is the oldest batch (FIFO recommended)
                  final isOldest = widget.batches.isNotEmpty && batch.id == widget.batches.first.id;
                  final existingQty = _getExistingQtyForBatch(batch);
                  final alreadyInBill = existingQty > 0;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFFE3F2FD)
                          : alreadyInBill
                              ? const Color(0xFFE8F5E9)
                              : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected
                            ? Colors.blue
                            : alreadyInBill
                                ? const Color(0xFF1B4D3E)
                                : Colors.grey[200]!,
                        width: isSelected || alreadyInBill ? 1.5 : 1,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: Colors.blue.withOpacity(0.15),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () {
                          setState(() {
                            _selectedBatchIndex = index;
                            // Set default quantity
                            final maxAvailable = batch.quantityRemaining - existingQty;
                            _qtyController.text = maxAvailable > 0 ? '1' : '0';
                            _qtyError = null;
                          });
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Top row: Company + badges
                              Row(
                                children: [
                                  // Company icon
                                  Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF1B4D3E).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Center(
                                      child: Text(
                                        batch.companyName.isNotEmpty
                                            ? batch.companyName[0].toUpperCase()
                                            : '?',
                                        style: const TextStyle(
                                          fontFamily: 'Literata',
                                          fontWeight: FontWeight.w700,
                                          fontSize: 14,
                                          color: Color(0xFF1B4D3E),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          batch.companyName.isNotEmpty
                                              ? batch.companyName
                                              : '—',
                                          style: const TextStyle(
                                            fontFamily: 'Literata',
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        Text(
                                          '${widget.localizations.purchasedOn}: ${DateFormat('dd MMM yyyy').format(batch.purchaseDate)}',
                                          style: TextStyle(
                                            fontFamily: 'Literata',
                                            fontSize: 11,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Badges
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      if (isOldest)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.amber[50],
                                            borderRadius: BorderRadius.circular(4),
                                            border: Border.all(color: Colors.amber[300]!),
                                          ),
                                          child: Text(
                                            widget.localizations.fifoRecommended,
                                            style: TextStyle(
                                              fontFamily: 'Literata',
                                              fontSize: 9,
                                              fontWeight: FontWeight.w700,
                                              color: Colors.amber[800],
                                            ),
                                          ),
                                        ),
                                      if (alreadyInBill) ...[
                                        const SizedBox(height: 4),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.green[50],
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            '✓ $existingQty in bill',
                                            style: TextStyle(
                                              fontFamily: 'Literata',
                                              fontSize: 9,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.green[700],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              // Price row + Stock
                              Row(
                                children: [
                                  // Sell price
                                  _buildBatchInfoChip(
                                    label: widget.localizations.sellPrice,
                                    value: '₹${batch.sellingPrice.toStringAsFixed(0)}',
                                    color: const Color(0xFF1B4D3E),
                                  ),
                                  const SizedBox(width: 8),
                                  // Cost price
                                  _buildBatchInfoChip(
                                    label: widget.localizations.costPrice,
                                    value: '₹${batch.purchasePrice.toStringAsFixed(0)}',
                                    color: Colors.grey[700]!,
                                  ),
                                  const SizedBox(width: 8),
                                  // Stock
                                  _buildBatchInfoChip(
                                    label: widget.localizations.stock,
                                    value: '${batch.quantityRemaining} ${batch.unit}',
                                    color: batch.quantityRemaining > 10
                                        ? Colors.green[700]!
                                        : Colors.orange[700]!,
                                  ),
                                ],
                              ),
                              // Quantity input + Add button (shown when selected)
                              if (isSelected) ...[
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.blue[50],
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Column(
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: TextField(
                                              controller: _qtyController,
                                              keyboardType: TextInputType.number,
                                              onChanged: (_) => _validateQuantity(),
                                              style: const TextStyle(
                                                fontFamily: 'Literata',
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                              ),
                                              decoration: InputDecoration(
                                                labelText: widget.localizations.enterQuantity,
                                                labelStyle: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey[600],
                                                ),
                                                errorText: _qtyError,
                                                errorStyle: const TextStyle(fontSize: 10),
                                                contentPadding: const EdgeInsets.symmetric(
                                                  horizontal: 12,
                                                  vertical: 10,
                                                ),
                                                border: OutlineInputBorder(
                                                  borderRadius: BorderRadius.circular(8),
                                                  borderSide: BorderSide(color: Colors.grey[300]!),
                                                ),
                                                focusedBorder: OutlineInputBorder(
                                                  borderRadius: BorderRadius.circular(8),
                                                  borderSide: const BorderSide(
                                                    color: Color(0xFF1B4D3E),
                                                    width: 1.5,
                                                  ),
                                                ),
                                                filled: true,
                                                fillColor: Colors.white,
                                                suffixText: '/ ${batch.quantityRemaining - existingQty}',
                                                suffixStyle: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey[500],
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          ElevatedButton.icon(
                                            onPressed: _qtyError == null &&
                                                    _qtyController.text.isNotEmpty &&
                                                    (int.tryParse(_qtyController.text) ?? 0) > 0
                                                ? () {
                                                    final qty = int.parse(_qtyController.text);
                                                    widget.onBatchSelected(batch, existingQty + qty);
                                                  }
                                                : null,
                                            icon: const Icon(Icons.add_shopping_cart, size: 18),
                                            label: Text(
                                              widget.localizations.addToBill,
                                              style: const TextStyle(
                                                fontFamily: 'Literata',
                                                fontWeight: FontWeight.w600,
                                                fontSize: 13,
                                              ),
                                            ),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: const Color(0xFF1B4D3E),
                                              foregroundColor: Colors.white,
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 16,
                                                vertical: 12,
                                              ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(10),
                                              ),
                                              elevation: 0,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBatchInfoChip({
    required String label,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Literata',
                fontSize: 9,
                color: Colors.grey[600],
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontFamily: 'Literata',
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

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
import 'package:c_billing/common_widgets/action_menu.dart';
import 'package:c_billing/features/shop/data/repositories/shop_repository.dart';
import 'package:c_billing/features/shop/domain/entities/shop.dart';
import 'package:c_billing/features/customer/data/repositories/customer_repository.dart';
import 'package:c_billing/features/customer/data/repositories/customer_transaction_repository.dart';
import 'package:c_billing/core/services/language_service.dart';
import 'package:c_billing/core/localization/app_localizations.dart';
import 'package:c_billing/features/billing/presentation/pages/bill_settings_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:c_billing/features/billing/offline/entities/bill_entity.dart';
import 'package:c_billing/features/billing/data/services/bill_sync_service.dart';
import 'package:c_billing/features/product/offline/controllers/product_offline_controller.dart';
import 'package:c_billing/features/product/offline/entities/product_entity.dart';
import 'package:c_billing/features/product/data/services/product_sync_service.dart';
import 'package:c_billing/core/services/app_logger.dart';
import 'package:c_billing/core/services/inventory_integration_service.dart';
import 'package:c_billing/features/inventory_management/offline/controllers/purchase_batch_offline_controller.dart';
import 'package:c_billing/features/inventory_management/offline/entities/purchase_batch_entity.dart';
import 'package:c_billing/features/customer/offline/controllers/customer_offline_controller.dart';
import 'package:c_billing/features/customer/offline/entities/customer_entity.dart';
import 'package:c_billing/features/billing/domain/entities/bill_tax_settings.dart';
import 'package:c_billing/features/dashboard/data/repositories/dashboard_offline_repository.dart';
import 'package:c_billing/features/billing/presentation/pages/bills_list_page.dart';
import 'package:c_billing/features/inventory_management/presentation/pages/enhanced_product_page.dart';
import 'package:c_billing/features/supplier/presentation/pages/enhanced_supplier_page.dart';
import 'package:c_billing/features/company/presentation/pages/enhanced_company_page.dart';
import 'package:c_billing/features/purchase_return/presentation/pages/purchase_return_screen.dart';
import 'package:c_billing/features/reports/presentation/pages/report_page.dart';
import 'package:c_billing/features/dashboard/data/models/dashboard_data.dart';

class BillingPage extends StatefulWidget {
  final bool isEmbedded;

  const BillingPage({super.key, this.isEmbedded = false});

  @override
  State<BillingPage> createState() => _BillingPageState();
}

class _BillingPageState extends State<BillingPage> {
  // ignore: unused_field
  late BillingService _billingService;
  late CustomerTransactionService _customerTransactionService;
  late FirebaseFirestore _firestore;
  late ShopRepository _shopRepository;
  late FirebaseCustomerRepository _customerRepository;
  late AppLocalizations _localizations;

  // Real-time Isar stream subscriptions
  StreamSubscription<List<ProductEntity>>? _productStreamSubscription;
  StreamSubscription<List<CustomerEntity>>? _customerStreamSubscription;
  StreamSubscription<void>? _billSettingsSubscription;

  // Printing services
  final _printerService = PosPrinterService();
  final _pdfService = PdfBillService();
  final _appLogger = AppLogger();

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
  
  // Customer loading state
  bool _isLoadingCustomers = false;
  
  // Customer phone search debounce
  Timer? _phoneSearchDebounceTimer;
  bool _isSearchingCustomer = false;
  String? _autoFoundCustomerName;
  bool _hasPhoneText = false;
  bool _showAddCustomerPrompt = false;
  
  // Bill settings
  bool _showCustomerOnBill = true;
  bool _generateBillViaContact = false;
  String _billType = 'pos'; // 'pos' or 'normal'

  // Quick Stats data
  final DashboardOfflineRepository _dashboardRepo = DashboardOfflineRepository.instance;
  DashboardData? _quickStatsData;
  bool _isLoadingQuickStats = true;
  bool _showQuickStats = false;

  // GST/Tax settings
  BillTaxSettings _taxSettings = BillTaxSettings.defaultSettings;
  GstMode _gstMode = GstMode.noGst;

  /// Computed tax breakdown based on current subtotal and GST mode
  TaxBreakdown? get _taxBreakdown {
    if (_gstMode == GstMode.noGst || !_taxSettings.hasAnyTaxEnabled) {
      return null;
    }
    return _taxSettings.calculateTax(
      subtotal: _totalAmount,
      gstMode: _gstMode,
    );
  }

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
    _customerTransactionService = CustomerTransactionService(
      firestore: _firestore,
      customerRepository: _customerRepository,
      transactionRepository: customerTransactionRepository,
    );

    _billingService = BillingService(
      billRepository: FirebaseBillRepository(firestore: _firestore),
      productRepository: FirebaseProductRepository(firestore: _firestore),
      stockRepository: FirebaseStockRepository(firestore: _firestore),
      customerTransactionService: _customerTransactionService,
    );
    
    // Listen for customer phone number changes
    _customerContactController.addListener(_onPhoneNumberChanged);
    
    // Setup real-time Isar streams for instant data updates
    _setupProductStream();
    _setupCustomerStream();
    
    // Listen for bill settings changes from settings page
    _billSettingsSubscription = DashboardRefreshService.instance.onBillSettingsChanged.listen((_) {
      if (mounted) _loadBillSettings();
    });
    
    _loadBillSettings();
  }
  
  Future<void> _loadBillSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final taxSettings = await BillTaxSettings.load();
    if (mounted) {
      setState(() {
        _showCustomerOnBill = prefs.getBool('bill_show_customer_details') ?? true;
        _generateBillViaContact = prefs.getBool('bill_generate_via_contact') ?? false;
        _billType = prefs.getString('bill_type') ?? 'pos';
        _taxSettings = taxSettings;
        _gstMode = taxSettings.defaultGstMode;
      });
    }
  }

  @override
  void dispose() {
    _productStreamSubscription?.cancel();
    _customerStreamSubscription?.cancel();
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

  /// Setup real-time product stream from Isar — auto-refreshes on any product/stock change
  void _setupProductStream() {
    _productStreamSubscription = ProductOfflineController.instance.watchAllProducts().listen(
      (entities) {
        if (!mounted) return;
        _loadProducts(showLoader: false);
      },
      onError: (e) => debugPrint('[Billing] Product stream error: $e'),
    );
    // Also do an initial load (stream fires immediately but we need batch data too)
    _loadProducts();
  }

  /// Setup real-time customer stream from Isar — auto-refreshes on any customer change
  void _setupCustomerStream() {
    _customerStreamSubscription = CustomerOfflineController.instance.watchAllCustomers().listen(
      (entities) {
        if (!mounted) return;
        // Convert entities directly from stream for instant update
        final customers = entities.map((entity) {
          final nameParts = entity.name.split(' ');
          final firstName = nameParts.isNotEmpty ? nameParts.first : '';
          final lastName = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';
          return <String, dynamic>{
            'id': entity.serverId ?? 'local_${entity.id}',
            'localId': entity.id,
            'firstName': firstName,
            'lastName': lastName,
            'contact': entity.mobile,
            'fullName': entity.name,
            'pendingBalance': entity.currentPendingAmount,
            'totalPurchases': entity.totalPurchases,
          };
        }).toList();
        setState(() {
          _customers = customers;
          _isLoadingCustomers = false;
        });
        debugPrint('[Billing] Customer stream: ${customers.length} customers');
      },
      onError: (e) => debugPrint('[Billing] Customer stream error: $e'),
    );
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
    if (!mounted) return;
    setState(() => _isLoadingCustomers = true);
    
    try {
      // Step 1: Load from local Isar DB first (instant)
      final localCustomers = await CustomerOfflineController.instance.getAllCustomers();
      if (localCustomers.isNotEmpty && mounted) {
        setState(() {
          _customers = localCustomers.map((entity) {
            // Parse name parts from entity.name
            final nameParts = entity.name.split(' ');
            final firstName = nameParts.isNotEmpty ? nameParts.first : '';
            final lastName = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';
            return {
              'id': entity.serverId ?? 'local_${entity.id}',
              'localId': entity.id,
              'firstName': firstName,
              'lastName': lastName,
              'contact': entity.mobile,
              'fullName': entity.name,
              'pendingBalance': entity.currentPendingAmount,
              'totalPurchases': entity.totalPurchases,
            };
          }).toList();
        });
        debugPrint('[Billing] Loaded ${localCustomers.length} customers from Isar');
      }
      
      // Step 2: Also fetch from Firebase to get latest data
      try {
        final billRepo = FirebaseBillRepository(firestore: _firestore);
        final snapshot = await _firestore
            .collection('users')
            .doc(billRepo.userId)
            .collection('customers')
            .get();
        
        final firebaseCustomers = snapshot.docs
            .where((doc) {
              final data = doc.data();
              final isActive = data['isActive'];
              return isActive != false;
            })
            .map((doc) {
              final data = doc.data();
              return {
                'id': doc.id,
                'firstName': data['firstName'] ?? '',
                'lastName': data['lastName'] ?? '',
                'contact': data['contact'] ?? '',
                'fullName': '${data['firstName'] ?? ''} ${data['lastName'] ?? ''}'.trim(),
                'pendingBalance': ((data['currentPendingAmount'] ?? data['pendingBalance'] ?? 0) as num).toDouble(),
                'totalPurchases': ((data['totalPurchaseAmount'] ?? 0) as num).toDouble(),
              };
            }).toList();
        
        if (firebaseCustomers.isNotEmpty && mounted) {
          setState(() {
            _customers = firebaseCustomers;
          });
          debugPrint('[Billing] Loaded ${firebaseCustomers.length} customers from Firebase');
        }
      } catch (e) {
        debugPrint('[Billing] Firebase customer fetch failed (using local): $e');
      }
    } catch (e) {
      debugPrint('[Billing] Error loading customers: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoadingCustomers = false);
      }
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
        _showAddCustomerPrompt = false;
      });
      return;
    }
    
    // Validate phone number length (exactly 10 digits for search)
    if (phoneNumber.length < 10) {
      setState(() {
        _autoFoundCustomerName = null;
        _showAddCustomerPrompt = false;
      });
      return;
    }
    
    // Start new debounce timer (500ms)
    _phoneSearchDebounceTimer = Timer(const Duration(milliseconds: 500), () {
      _searchCustomerByPhone(phoneNumber);
    });
  }

  /// Search for customer by phone number using local _customers list
  Future<void> _searchCustomerByPhone(String phoneNumber) async {
    if (!mounted) return;
    
    setState(() {
      _isSearchingCustomer = true;
      _autoFoundCustomerName = null;
    });
    
    try {
      // Normalize phone number - remove spaces, dashes, and country code for comparison
      final normalizedPhone = phoneNumber.replaceAll(RegExp(r'[\s\-\(\)\+]'), '');
      final last10Digits = normalizedPhone.length >= 10
          ? normalizedPhone.substring(normalizedPhone.length - 10)
          : normalizedPhone;
      
      // Search through local _customers list (already loaded from Firestore)
      Map<String, dynamic>? foundCustomer;
      
      for (final c in _customers) {
        final customerContact = (c['contact'] ?? '').toString();
        
        // Try exact match first
        if (customerContact == phoneNumber) {
          foundCustomer = c;
          break;
        }
        
        // Try normalized match (last 10 digits)
        final customerNormalized = customerContact.replaceAll(RegExp(r'[\s\-\(\)\+]'), '');
        if (customerNormalized.length >= 10 && last10Digits.length >= 10) {
          final customerLast10 = customerNormalized.substring(customerNormalized.length - 10);
          if (customerLast10 == last10Digits) {
            foundCustomer = c;
            break;
          }
        }
      }
      
      // If not found locally, try Firestore repository as fallback
      if (foundCustomer == null) {
        try {
          final customer = await _customerRepository.getCustomerByContact(phoneNumber);
          if (customer != null) {
            foundCustomer = {
              'id': customer.id,
              'firstName': customer.firstName,
              'lastName': customer.lastName,
              'contact': customer.contact,
              'fullName': '${customer.firstName} ${customer.lastName}'.trim(),
            };
          }
        } catch (e) {
          debugPrint('[DEBUG] Firestore customer search fallback failed: $e');
        }
      }
      
      if (!mounted) return;
      
      if (foundCustomer != null) {
        // Ensure fullName is populated
        final fullName = foundCustomer['fullName'] ?? 
            '${foundCustomer['firstName'] ?? ''} ${foundCustomer['lastName'] ?? ''}'.trim();
        
        // Customer found - auto-attach to bill
        setState(() {
          _selectedCustomer = {
            'id': foundCustomer!['id'],
            'firstName': foundCustomer['firstName'] ?? '',
            'lastName': foundCustomer['lastName'] ?? '',
            'contact': foundCustomer['contact'] ?? '',
            'fullName': fullName,
          };
          _autoFoundCustomerName = fullName;
          _customerNameController.text = fullName;
          _isSearchingCustomer = false;
        });
        
        _showSnackbar(
          'Customer found: $fullName',
          isError: false,
        );
      } else {
        // Customer not found - show "Add Customer?" prompt (never auto-create)
        setState(() {
          _isSearchingCustomer = false;
          _autoFoundCustomerName = null;
          _showAddCustomerPrompt = true;
        });
      }
    } catch (e) {
      if (!mounted) return;
      
      setState(() {
        _isSearchingCustomer = false;
        _showAddCustomerPrompt = false;
      });
      
      debugPrint('[DEBUG] Error searching customer: $e');
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
            Text(
              _localizations.addNewCustomer,
              style: const TextStyle(
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
                    '${_localizations.customerNotFoundFor} $phoneNumber',
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
                    labelText: '${_localizations.firstName} *',
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
                      return _localizations.firstNameRequired2;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: lastNameController,
                  decoration: InputDecoration(
                    labelText: '${_localizations.lastName} *',
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
                      return _localizations.lastNameRequired2;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: _localizations.phoneNumberOptional,
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
              _localizations.cancel,
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
                _localizations.continuingWithoutCustomer,
                isError: false,
              );
            },
            child: Text(
              _localizations.skip,
              style: const TextStyle(
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
            child: Text(
              _localizations.saveAndAttach,
              style: const TextStyle(
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
      // Save to Isar via offline controller — syncs to Firestore in background
      final offlineCtrl = CustomerOfflineController.instance;
      final entity = await offlineCtrl.addCustomer(
        name: '$firstName $lastName'.trim(),
        mobile: phoneNumber,
      );

      // Auto-attach customer to bill
      final fullName = '$firstName $lastName'.trim();
      if (mounted) {
        setState(() {
          _selectedCustomer = {
            'id': 'local_${entity.id}',
            'localId': entity.id,
            'firstName': firstName,
            'lastName': lastName,
            'contact': phoneNumber,
            'fullName': fullName,
            'pendingBalance': 0.0,
          };
          _autoFoundCustomerName = fullName;
          _customerNameController.text = fullName;
          _showAddCustomerPrompt = false;
          if (phoneNumber.isNotEmpty) {
            _customerContactController.text = phoneNumber;
            _hasPhoneText = true;
          }
        });
      }
      
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
        onBatchItemAdded: (productId, productName, companyName, batchLocalId, sellingPrice, purchasePrice, quantity, maxStock, cgstPercent, sgstPercent, hsnCode) {
          // Use a unique key: productId + batchLocalId (or just productId if no batch)
          final uniqueKey = batchLocalId != null ? '${productId}_batch_$batchLocalId' : productId;
          final existingIndex = _billItems.indexWhere(
            (item) => item.productId == uniqueKey,
          );
          setState(() {
            if (existingIndex != -1) {
              _billItems[existingIndex] = BillItem.create(
                productId: uniqueKey,
                productName: productName,
                companyName: companyName.isNotEmpty ? companyName : null,
                sellingPrice: sellingPrice,
                purchasePrice: purchasePrice,
                quantity: quantity,
                cgstPercent: cgstPercent,
                sgstPercent: sgstPercent,
                hsnCode: hsnCode,
              );
            } else {
              _billItems.add(
                BillItem.create(
                  productId: uniqueKey,
                  productName: productName,
                  companyName: companyName.isNotEmpty ? companyName : null,
                  sellingPrice: sellingPrice,
                  purchasePrice: purchasePrice,
                  quantity: quantity,
                  cgstPercent: cgstPercent,
                  sgstPercent: sgstPercent,
                  hsnCode: hsnCode,
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

  double get _finalAmount {
    final subtotalAfterDiscount = _totalAmount - _discountAmount;
    // For exclusive GST, tax is added on top
    if (_gstMode == GstMode.excludeGst && _taxBreakdown != null) {
      return subtotalAfterDiscount + _taxBreakdown!.totalTaxAmount;
    }
    // For inclusive GST or no GST, price already contains tax or no tax
    return subtotalAfterDiscount;
  }

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
          _localizations.pleaseEnterValidContact,
          isError: true,
        );
        return;
      }
    }

    // Validate customer details are required for partial payment
    if (!_isFullPayment && _selectedCustomer == null) {
      final customerName = _customerNameController.text.trim();
      final customerContact = _customerContactController.text.trim();
      if (customerName.isEmpty || customerContact.isEmpty || customerContact.length < 10) {
        _showSnackbar(
          'Customer details (name & phone) are required for partial payment',
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
          companyName: item.companyName,
          sellingPrice: item.sellingPrice,
          purchasePrice: item.purchasePrice,
          quantity: item.quantity,
          cgstPercent: item.cgstPercent,
          sgstPercent: item.sgstPercent,
          hsnCode: item.hsnCode,
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
        isGstApplied: _taxBreakdown != null && _gstMode != GstMode.noGst,
        isTaxInclusive: _gstMode == GstMode.includeGst,
        cgstPercent: _taxBreakdown?.cgstPercent ?? 0.0,
        sgstPercent: _taxBreakdown?.sgstPercent ?? 0.0,
        otherTaxPercent: _taxBreakdown?.otherTaxPercent ?? 0.0,
        otherTaxName: _taxBreakdown?.otherTaxName,
        cgstAmount: _taxBreakdown?.cgstAmount ?? 0.0,
        sgstAmount: _taxBreakdown?.sgstAmount ?? 0.0,
        otherTaxAmount: _taxBreakdown?.otherTaxAmount ?? 0.0,
        totalTaxAmount: _taxBreakdown?.totalTaxAmount ?? 0.0,
      );

      if (!integrationResult.success) {
        throw Exception(integrationResult.errorMessage ?? _localizations.billProcessingFailed);
      }

      debugPrint('[Billing] Bill processed with FIFO: COGS=${integrationResult.totalCOGS}, Profit=${integrationResult.totalProfit}');

      // 3. Create ledger/transaction entry for partial payments
      if (calculatedPendingAmount > 0 && _selectedCustomer != null) {
        try {
          final customerId = _selectedCustomer!['id'] as String;
          final billId = integrationResult.billEntity?.serverId ?? 'local_${integrationResult.billEntity?.id}';
          
          // Create ledger entry via CustomerTransactionService
          final transactionResult = await _customerTransactionService.recordBillGenerated(
            customerId: customerId,
            billId: billId,
            billNumber: billId,
            billAmount: calculatedPendingAmount,
          );
          
          if (transactionResult.success) {
            debugPrint('[Billing] Ledger entry created for pending amount: $calculatedPendingAmount');
          } else {
            debugPrint('[Billing] Ledger entry failed: ${transactionResult.errorMessage}');
          }
        } catch (e) {
          debugPrint('[Billing] Ledger entry error (non-blocking): $e');
        }
      }

      // 4. Trigger background sync
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
      _showAddCustomerPrompt = false;
      _hasPhoneText = false;
      // Reset GST mode to default from settings
      _gstMode = _taxSettings.defaultGstMode;
    });
  }

  /// Create PrintBillData from bill — no network calls, uses bill data directly
  PrintBillData _createPrintBillData(Bill bill) {
    // Use bill's own pending amount as totalDueAmount (already computed at bill creation time)
    final double? totalDueAmount = bill.pendingAmount > 0 ? bill.pendingAmount : null;
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
      builder: (dialogContext) => Dialog(
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
                      if (bill.isGstApplied && bill.totalTaxAmount > 0) ...[
                        const Divider(height: 12),
                        if (bill.cgstAmount > 0)
                          _buildSuccessDialogRow(
                            '${_localizations.cgst} (${bill.cgstPercent.toStringAsFixed(1)}%)',
                            '₹${bill.cgstAmount.toStringAsFixed(2)}',
                            valueColor: Colors.orange[700],
                          ),
                        if (bill.sgstAmount > 0)
                          _buildSuccessDialogRow(
                            '${_localizations.sgst} (${bill.sgstPercent.toStringAsFixed(1)}%)',
                            '₹${bill.sgstAmount.toStringAsFixed(2)}',
                            valueColor: Colors.orange[700],
                          ),
                        if (bill.otherTaxAmount > 0)
                          _buildSuccessDialogRow(
                            '${bill.otherTaxName.isNotEmpty ? bill.otherTaxName : _localizations.totalTax} (${bill.otherTaxPercent.toStringAsFixed(1)}%)',
                            '₹${bill.otherTaxAmount.toStringAsFixed(2)}',
                            valueColor: Colors.orange[700],
                          ),
                        _buildSuccessDialogRow(
                          _localizations.totalTax,
                          '₹${bill.totalTaxAmount.toStringAsFixed(2)}',
                          valueColor: Colors.orange[800],
                        ),
                        if (bill.isTaxInclusive)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              _localizations.pricesInclusiveOfGst,
                              style: TextStyle(
                                fontFamily: 'Literata',
                                fontSize: 11,
                                fontStyle: FontStyle.italic,
                                color: Colors.grey[500],
                              ),
                            ),
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
                          Navigator.pop(dialogContext);
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
                              : _localizations.printBill,
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
                              Navigator.pop(dialogContext);
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
                              Navigator.pop(dialogContext);
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
                        onPressed: () => Navigator.pop(dialogContext),
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
      _appLogger.info('PDF_SHARE', 'Starting share for bill: ${bill.billNumber}, type: $_billType');

      // 1. Get shop details with timeout
      final shop = await _shopRepository.getShopDetails().timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          _appLogger.warning('PDF_SHARE', 'Shop details timeout — using empty shop');
          return Shop.empty;
        },
      );

      // 2. Create print data (synchronous — no network calls)
      final printData = _createPrintBillData(bill);
      _appLogger.debug('PDF_SHARE', 'Print data: ${printData.items.length} items, total: ${printData.grandTotal}');

      // 3. Generate PDF
      final pw.Document pdf;
      if (_billType == 'normal') {
        pdf = await _pdfService.generateNormalBillPdf(billData: printData, shopDetails: shop);
      } else {
        pdf = await _pdfService.generateBillPdf(billData: printData, shopDetails: shop);
      }
      final bytes = await pdf.save();
      _appLogger.info('PDF_SHARE', 'PDF generated: ${bytes.length} bytes');

      if (!mounted) return;

      // 4. Share via native share sheet
      await Printing.sharePdf(
        bytes: bytes,
        filename: 'bill_${bill.billNumber.replaceAll(RegExp(r'[^a-zA-Z0-9\-_]'), '_')}.pdf',
      );
      _appLogger.info('PDF_SHARE', 'Share completed');
    } catch (e, stackTrace) {
      _appLogger.error('PDF_SHARE', 'Share failed: $e', error: e, stackTrace: stackTrace);
      if (mounted) {
        _showSnackbar('Error sharing bill: $e', isError: true);
      }
    }
  }

  Future<void> _saveBillAsPdf(Bill bill) async {
    try {
      _appLogger.info('PDF_SAVE', 'Starting save for bill: ${bill.billNumber}, type: $_billType');

      // 1. Get shop details with timeout
      final shop = await _shopRepository.getShopDetails().timeout(
        const Duration(seconds: 5),
        onTimeout: () => Shop.empty,
      );

      // 2. Create print data (synchronous)
      final printData = _createPrintBillData(bill);

      // 3. Generate PDF
      final pw.Document pdf;
      if (_billType == 'normal') {
        pdf = await _pdfService.generateNormalBillPdf(billData: printData, shopDetails: shop);
      } else {
        pdf = await _pdfService.generateBillPdf(billData: printData, shopDetails: shop);
      }
      final bytes = await pdf.save();
      _appLogger.info('PDF_SAVE', 'PDF generated: ${bytes.length} bytes');

      if (!mounted) return;

      // 4. Open native save/share dialog
      await Printing.sharePdf(
        bytes: bytes,
        filename: 'bill_${bill.id.replaceAll(RegExp(r'[^a-zA-Z0-9\-_]'), '_')}.pdf',
      );
      _appLogger.info('PDF_SAVE', 'Save completed');
    } catch (e, stackTrace) {
      _appLogger.error('PDF_SAVE', 'Save failed: $e', error: e, stackTrace: stackTrace);
      if (mounted) {
        _showSnackbar('Error saving PDF: $e', isError: true);
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
      final printData = _createPrintBillData(bill);

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
      final shop = await _shopRepository.getShopDetails().timeout(
        const Duration(seconds: 5),
        onTimeout: () => Shop.empty,
      );
      final printData = _createPrintBillData(bill);

      if (!mounted) return;

      // Use system print dialog
      await _pdfService.previewAndPrintPdf(
        billData: printData,
        shopDetails: shop,
      );
    } catch (e) {
      if (mounted) {
        _showSnackbar('${_localizations.errorPrinting}: $e', isError: true);
      }
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
          ? Stack(
              children: [
                // Main billing content
                SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    children: [
                      _buildEmbeddedHeader(),
                      if (_showCustomerOnBill || _generateBillViaContact) _buildCustomerSection(),
                      _buildAddItemsSection(),
                      if (_billItems.isNotEmpty) _buildBillItemsSection(),
                      if (_billItems.isNotEmpty) _buildDiscountSection(),
                      if (_billItems.isNotEmpty && _taxSettings.hasAnyTaxEnabled) _buildGstModeSection(),
                      if (_billItems.isNotEmpty) _buildPaymentSection(),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
                // Quick Stats overlay (z-index above everything)
                if (_showQuickStats) _buildQuickStatsOverlay(),
                // FAB — always on top
                Positioned(
                  right: 16,
                  top: 8,
                  child: _buildQuickStatsFAB(),
                ),
              ],
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
                if (_billItems.isNotEmpty && _taxSettings.hasAnyTaxEnabled)
                  SliverToBoxAdapter(child: _buildGstModeSection()),
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
                  // Action Menu (Settings, Language, Bug Report)
                  ActionMenu(
                    menuColor: const Color(0xFF1B4D3E),
                    iconColor: Colors.white,
                    onSettingsTap: () async {
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
                    onLanguageTap: () {
                      // Will be implemented by dashboard's language switching
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Language change is available in Dashboard'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                    onBugReportTap: () {
                      // Will be implemented with bug reporting service
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Bug report feature coming soon'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
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
    // Determine if customer is required (partial payment selected)
    final isCustomerRequired = !_isFullPayment;
    
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isCustomerRequired && _selectedCustomer == null
            ? Border.all(color: Colors.red[300]!, width: 1.5)
            : null,
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
              Expanded(
                child: Text(
                  _generateBillViaContact
                      ? _localizations.phoneNumber
                      : isCustomerRequired
                          ? '${_localizations.customerOptional.replaceAll('(Optional)', '')}(Required)'
                          : _localizations.customerOptional,
                  style: TextStyle(
                    fontFamily: 'Literata',
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: isCustomerRequired && _selectedCustomer == null
                        ? Colors.red[700]!
                        : const Color(0xFF1B4D3E),
                  ),
                ),
              ),
              // Loading indicator for customer list
              if (_isLoadingCustomers)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Color(0xFF1B4D3E),
                  ),
                ),
              // Add Customer button
              if (!_generateBillViaContact && !_isLoadingCustomers)
                IconButton(
                  icon: const Icon(Icons.person_add, color: Color(0xFF1B4D3E)),
                  onPressed: () {
                    final phone = _customerContactController.text.trim();
                    _showAddCustomerDialog(phone);
                  },
                  tooltip: _localizations.addNewCustomer,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Show selected customer info card (bold name + balance)
          if (_selectedCustomer != null && !_generateBillViaContact) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF1B4D3E).withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF1B4D3E).withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: const Color(0xFF1B4D3E),
                    radius: 20,
                    child: Text(
                      (_selectedCustomer!['fullName'] as String? ?? '?')[0].toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _selectedCustomer!['fullName'] ?? '-',
                          style: const TextStyle(
                            fontFamily: 'Literata',
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: Color(0xFF1B4D3E),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _selectedCustomer!['contact'] ?? '-',
                          style: TextStyle(
                            fontFamily: 'Literata',
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                        if ((_selectedCustomer!['pendingBalance'] as num?)?.toDouble() != null &&
                            (_selectedCustomer!['pendingBalance'] as num).toDouble() > 0) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.account_balance_wallet_outlined, size: 14, color: Colors.orange[700]),
                              const SizedBox(width: 4),
                              Text(
                                'Pending: ₹${(_selectedCustomer!['pendingBalance'] as num).toDouble().toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontFamily: 'Literata',
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.orange[700],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => setState(() {
                      _selectedCustomer = null;
                      _customerNameController.clear();
                      _customerContactController.clear();
                      _showAddCustomerPrompt = false;
                    }),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.close, color: Colors.grey[600], size: 16),
                    ),
                  ),
                ],
              ),
            ),
          ] else if (_generateBillViaContact) ...[
            // Show only phone number field when generate via contact is enabled
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _customerContactController,
                  keyboardType: TextInputType.phone,
                  style: const TextStyle(fontFamily: 'Literata', fontSize: 14),
                  decoration: InputDecoration(
                    labelText: '${_localizations.enterPhoneNumber} *',
                    hintText: _localizations.enterCustomerPhone,
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
                                tooltip: _localizations.clearPhoneNumber,
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
                            '${_localizations.customerColon} $_autoFoundCustomerName',
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
                // "Add Customer?" prompt when phone not found (via contact mode)
                if (_showAddCustomerPrompt && !_isSearchingCustomer)
                  Padding(
                    padding: const EdgeInsets.only(top: 6, left: 4),
                    child: GestureDetector(
                      onTap: () {
                        final phone = _customerContactController.text.trim();
                        _showAddCustomerDialog(phone);
                      },
                      child: Row(
                        children: [
                          Icon(Icons.person_add, size: 14, color: Colors.orange[700]),
                          const SizedBox(width: 4),
                          Text(
                            'Customer not found. Add new?',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.orange[700],
                              fontFamily: 'Literata',
                              fontWeight: FontWeight.w600,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ] else ...[
            // Normal customer section — tap to pick or enter manually
            GestureDetector(
              onTap: _showCustomerPicker,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: isCustomerRequired
                        ? Colors.red[300]!
                        : Colors.grey[300]!,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.grey[50],
                ),
                child: Row(
                  children: [
                    Icon(Icons.search, color: Colors.grey[500], size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _localizations.searchExistingCustomer,
                        style: TextStyle(
                          fontFamily: 'Literata',
                          color: Colors.grey[500],
                          fontSize: 14,
                        ),
                      ),
                    ),
                    Icon(Icons.chevron_right, color: Colors.grey[400], size: 20),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
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
                                          _showAddCustomerPrompt = false;
                                        });
                                      },
                                      color: Colors.grey[600],
                                      tooltip: _localizations.clearPhoneNumber,
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
                                  '${_localizations.customerColon} $_autoFoundCustomerName',
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
                      // "Add Customer?" prompt when phone not found
                      if (_showAddCustomerPrompt && !_isSearchingCustomer)
                        Padding(
                          padding: const EdgeInsets.only(top: 6, left: 4),
                          child: GestureDetector(
                            onTap: () {
                              final phone = _customerContactController.text.trim();
                              _showAddCustomerDialog(phone);
                            },
                            child: Row(
                              children: [
                                Icon(Icons.person_add, size: 14, color: Colors.orange[700]),
                                const SizedBox(width: 4),
                                Text(
                                  'Customer not found. Add new?',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.orange[700],
                                    fontFamily: 'Literata',
                                    fontWeight: FontWeight.w600,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ],
                            ),
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
              if (existingIndex != -1) {
                _billItems[existingIndex] = BillItem.create(
                  productId: uniqueKey,
                  productName: product.name,
                  companyName: batch.companyName.isNotEmpty ? batch.companyName : null,
                  sellingPrice: batch.sellingPrice,
                  purchasePrice: batch.purchasePrice,
                  quantity: quantity,
                  hsnCode: product.hsnCode,
                );
              } else {
                _billItems.add(
                  BillItem.create(
                    productId: uniqueKey,
                    productName: product.name,
                    companyName: batch.companyName.isNotEmpty ? batch.companyName : null,
                    sellingPrice: batch.sellingPrice,
                    purchasePrice: batch.purchasePrice,
                    quantity: quantity,
                    hsnCode: product.hsnCode,
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
            productName: product.name,
            companyName: product.companyName.isNotEmpty ? product.companyName : null,
            sellingPrice: existing.sellingPrice,
            purchasePrice: fifoPurchasePrice,
            quantity: existing.quantity + 1,
            hsnCode: product.hsnCode,
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
            productName: product.name,
            companyName: product.companyName.isNotEmpty ? product.companyName : null,
            sellingPrice: fifoPrice,
            purchasePrice: fifoPurchasePrice,
            quantity: 1,
            hsnCode: product.hsnCode,
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
                            if (item.cgstPercent > 0 || item.sgstPercent > 0)
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Text(
                                  'CGST: ${item.cgstPercent}% (₹${item.cgstAmount.toStringAsFixed(2)})  SGST: ${item.sgstPercent}% (₹${item.sgstAmount.toStringAsFixed(2)})',
                                  style: TextStyle(
                                    fontFamily: 'Literata',
                                    fontSize: 10,
                                    color: Colors.orange[800],
                                  ),
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
                                      companyName: item.companyName,
                                      sellingPrice: item.sellingPrice,
                                      purchasePrice: item.purchasePrice,
                                      quantity: item.quantity - 1,
                                      cgstPercent: item.cgstPercent,
                                      sgstPercent: item.sgstPercent,
                                      hsnCode: item.hsnCode,
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
                                      companyName: item.companyName,
                                      sellingPrice: item.sellingPrice,
                                      purchasePrice: item.purchasePrice,
                                      quantity: item.quantity + 1,
                                      cgstPercent: item.cgstPercent,
                                      sgstPercent: item.sgstPercent,
                                      hsnCode: item.hsnCode,
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
          if (_discountAmount > 0 || _taxBreakdown != null) ...[
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
                  if (_discountAmount > 0) ...[
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${_localizations.discountWithPercent} (${_discountPercent.toStringAsFixed(1)}%)',
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
                  ],
                  // GST breakdown
                  if (_taxBreakdown != null) ...[
                    const Divider(height: 16),
                    if (_gstMode == GstMode.includeGst)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Text(
                          _localizations.pricesInclusiveOfGst,
                          style: TextStyle(
                            fontFamily: 'Literata',
                            fontSize: 11,
                            fontStyle: FontStyle.italic,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                    if (_taxBreakdown!.cgstPercent > 0)
                      _buildTaxRow(
                        '${_localizations.cgst} (${_taxBreakdown!.cgstPercent.toStringAsFixed(1)}%)',
                        _taxBreakdown!.cgstAmount,
                      ),
                    if (_taxBreakdown!.sgstPercent > 0)
                      _buildTaxRow(
                        '${_localizations.sgst} (${_taxBreakdown!.sgstPercent.toStringAsFixed(1)}%)',
                        _taxBreakdown!.sgstAmount,
                      ),
                    if (_taxBreakdown!.otherTaxPercent > 0)
                      _buildTaxRow(
                        '${_taxBreakdown!.otherTaxName.isNotEmpty ? _taxBreakdown!.otherTaxName : _localizations.totalTax} (${_taxBreakdown!.otherTaxPercent.toStringAsFixed(1)}%)',
                        _taxBreakdown!.otherTaxAmount,
                      ),
                    const SizedBox(height: 4),
                    _buildTaxRow(
                      _localizations.totalTax,
                      _taxBreakdown!.totalTaxAmount,
                      isBold: true,
                    ),
                    if (_gstMode == GstMode.excludeGst)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          _localizations.gstExtra,
                          style: TextStyle(
                            fontFamily: 'Literata',
                            fontSize: 11,
                            fontStyle: FontStyle.italic,
                            color: Colors.orange[700],
                          ),
                        ),
                      ),
                  ],
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

  /// Helper widget for displaying a tax row in the summary
  Widget _buildTaxRow(String label, double amount, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Literata',
              fontSize: 13,
              fontWeight: isBold ? FontWeight.w600 : FontWeight.normal,
              color: Colors.orange[800],
            ),
          ),
          Text(
            '₹${amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontFamily: 'Literata',
              fontSize: 13,
              fontWeight: isBold ? FontWeight.w600 : FontWeight.normal,
              color: Colors.orange[800],
            ),
          ),
        ],
      ),
    );
  }

  /// GST mode selection section
  Widget _buildGstModeSection() {
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.receipt_long_outlined,
                  color: Colors.orange[800],
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                _localizations.gstCalculationMode,
                style: const TextStyle(
                  fontFamily: 'Literata',
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1B4D3E),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // GST Mode chips
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildGstModeChip(
                label: _localizations.billWithoutGst,
                mode: GstMode.noGst,
                icon: Icons.money_off,
              ),
              _buildGstModeChip(
                label: _localizations.includeGstInTotal,
                mode: GstMode.includeGst,
                icon: Icons.arrow_downward,
              ),
              _buildGstModeChip(
                label: _localizations.excludeGstFromTotal,
                mode: GstMode.excludeGst,
                icon: Icons.arrow_upward,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGstModeChip({
    required String label,
    required GstMode mode,
    required IconData icon,
  }) {
    final isSelected = _gstMode == mode;
    return GestureDetector(
      onTap: () {
        setState(() {
          _gstMode = mode;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.orange.withOpacity(0.15)
              : Colors.grey[100],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.orange : Colors.grey[300]!,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.orange[800] : Colors.grey[600],
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Literata',
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? Colors.orange[800] : Colors.grey[700],
              ),
            ),
          ],
        ),
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
                      // Prompt user to select customer if not already selected
                      if (_selectedCustomer == null && 
                          _customerNameController.text.trim().isEmpty &&
                          !_generateBillViaContact) {
                        _showCustomerPicker();
                      }
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
                _buildQuickAmountChip(_localizations.full, _finalAmount),
              ],
            ),
          ],

          // Customer requirement notice for pending payment
          if (!_isFullPayment &&
              _pendingAmount > 0 &&
              _selectedCustomer == null) ...[
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () {
                if (_generateBillViaContact) {
                  // Focus the phone field
                } else {
                  _showCustomerPicker();
                }
              },
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, size: 18, color: Colors.red[700]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Customer details required for partial payment. Tap to select.',
                        style: TextStyle(
                          fontFamily: 'Literata',
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.red[800],
                        ),
                      ),
                    ),
                    Icon(Icons.arrow_forward_ios, size: 14, color: Colors.red[700]),
                  ],
                ),
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

  // ============ QUICK STATS FAB + OVERLAY ============

  Future<void> _loadQuickStats() async {
    try {
      final data = await _dashboardRepo.fetchDashboardData();
      if (mounted) {
        setState(() {
          _quickStatsData = data;
          _isLoadingQuickStats = false;
        });
      }
    } catch (e) {
      debugPrint('[BillingPage] Error loading quick stats: $e');
      if (mounted) setState(() => _isLoadingQuickStats = false);
    }
  }

  void _toggleQuickStats() {
    setState(() {
      _showQuickStats = !_showQuickStats;
    });
    // Load data on first open
    if (_showQuickStats && _quickStatsData == null) {
      _loadQuickStats();
    }
  }

  Widget _buildQuickStatsFAB() {
    return GestureDetector(
      onTap: _toggleQuickStats,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        width: _showQuickStats ? 44 : 48,
        height: _showQuickStats ? 44 : 48,
        decoration: BoxDecoration(
          gradient: _showQuickStats
              ? const LinearGradient(
                  colors: [Color(0xFFEF5350), Color(0xFFE53935)],
                )
              : const LinearGradient(
                  colors: [Color(0xFF1B4D3E), Color(0xFF2E7D5B)],
                ),
          borderRadius: BorderRadius.circular(_showQuickStats ? 12 : 14),
          boxShadow: [
            BoxShadow(
              color: (_showQuickStats
                      ? const Color(0xFFE53935)
                      : const Color(0xFF1B4D3E))
                  .withValues(alpha: 0.35),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
          child: Icon(
            _showQuickStats ? Icons.close_rounded : Icons.grid_view_rounded,
            key: ValueKey(_showQuickStats),
            color: Colors.white,
            size: 22,
          ),
        ),
      ),
    );
  }

  Widget _buildQuickStatsOverlay() {
    return Positioned(
      left: 16,
      right: 16,
      top: 56,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        builder: (context, value, child) {
          return Transform.translate(
            offset: Offset(0, -12 * (1 - value)),
            child: Opacity(
              opacity: value,
              child: child,
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: const Color(0xFF1B4D3E).withValues(alpha: 0.06),
                blurRadius: 40,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
               // Stats grid
              SizedBox(
                height: 84,
                child: _isLoadingQuickStats
                    ? _buildQuickStatsShimmer()
                    : ListView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        children: [
                          _buildQuickStatChip(
                            icon: Icons.receipt_long_outlined,
                            value: '${_quickStatsData?.invoicesCount ?? 0}',
                            label: _localizations.invoices,
                            color: const Color(0xFF667eea),
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const BillsListPage()),
                            ).then((_) { _loadQuickStats(); }),
                          ),
                          const SizedBox(width: 8),
                          _buildQuickStatChip(
                            icon: Icons.inventory_2_outlined,
                            value: '${_quickStatsData?.productsCount ?? 0}',
                            label: _localizations.products,
                            color: const Color(0xFFf093fb),
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const EnhancedProductPage()),
                            ).then((_) { _loadQuickStats(); }),
                          ),
                          const SizedBox(width: 8),
                          _buildQuickStatChip(
                            icon: Icons.local_shipping_outlined,
                            value: '${_quickStatsData?.suppliersCount ?? 0}',
                            label: _localizations.suppliers,
                            color: const Color(0xFFFF6B6B),
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const EnhancedSupplierPage()),
                            ).then((_) { _loadQuickStats(); }),
                          ),
                          const SizedBox(width: 8),
                          _buildQuickStatChip(
                            icon: Icons.business_outlined,
                            value: '${_quickStatsData?.companiesCount ?? 0}',
                            label: _localizations.companies,
                            color: const Color(0xFF9C27B0),
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const EnhancedCompanyPage()),
                            ).then((_) { _loadQuickStats(); }),
                          ),
                          const SizedBox(width: 8),
                          _buildQuickStatChip(
                            icon: Icons.keyboard_return_rounded,
                            value: '${_quickStatsData?.totalReturnedItems ?? 0}',
                            label: 'P. Return',
                            color: const Color(0xFFE65100),
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const PurchaseReturnScreen()),
                            ).then((_) { _loadQuickStats(); }),
                          ),
                          const SizedBox(width: 8),
                          _buildQuickStatChip(
                            icon: Icons.assessment_outlined,
                            value: '\u2014',
                            label: 'Reports',
                            color: const Color(0xFF0277BD),
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const ReportPage()),
                            ).then((_) { _loadQuickStats(); }),
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

  Widget _buildQuickStatsShimmer() {
    return ListView.separated(
      scrollDirection: Axis.horizontal,
      itemCount: 5,
      separatorBuilder: (_, __) => const SizedBox(width: 8),
      itemBuilder: (_, __) => Container(
        width: 80,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }

  Widget _buildQuickStatChip({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 80,
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withValues(alpha: 0.12),
              color.withValues(alpha: 0.04),
            ],
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: color.withValues(alpha: 0.15),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 16),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                color: Color(0xFF1B4D3E),
                fontSize: 13,
                fontWeight: FontWeight.w800,
                fontFamily: 'Literata',
              ),
            ),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: const Color(0xFF1B4D3E).withValues(alpha: 0.6),
                fontSize: 8,
                fontFamily: 'Literata',
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
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
    // Refresh customers before showing picker
    _loadCustomers();
    
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
            _showAddCustomerPrompt = false;
            _autoFoundCustomerName = customer['fullName'];
          });
          Navigator.pop(ctx);
        },
        onAddNew: () {
          Navigator.pop(ctx);
          final phone = _customerContactController.text.trim();
          _showAddCustomerDialog(phone);
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
  final Function(String productId, String productName, String companyName, int? batchLocalId, double sellingPrice, double purchasePrice, int quantity, int maxStock, double cgstPercent, double sgstPercent, String? hsnCode) onBatchItemAdded;
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
          cgstPercent: product?.cgstPercent ?? 0.0,
          sgstPercent: product?.sgstPercent ?? 0.0,
          hsnCode: product?.hsnCode,
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
            cgstPercent: product.cgstPercent,
            sgstPercent: product.sgstPercent,
            hsnCode: product.hsnCode,
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
          group.cgstPercent,
          group.sgstPercent,
          group.hsnCode,
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
            group.cgstPercent,
            group.sgstPercent,
            group.hsnCode,
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
  final VoidCallback? onAddNew;
  final AppLocalizations localizations;

  const _CustomerPickerBottomSheet({
    required this.customers,
    required this.onCustomerSelected,
    this.onAddNew,
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
            // Add New Customer button
            if (widget.onAddNew != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: GestureDetector(
                  onTap: widget.onAddNew,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFF1B4D3E), width: 1.5),
                      borderRadius: BorderRadius.circular(12),
                      color: const Color(0xFF1B4D3E).withOpacity(0.05),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.person_add, color: Color(0xFF1B4D3E), size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Add New Customer',
                          style: TextStyle(
                            fontFamily: 'Literata',
                            color: Color(0xFF1B4D3E),
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            if (widget.onAddNew != null)
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
                          if (widget.onAddNew != null) ...[
                            const SizedBox(height: 16),
                            TextButton.icon(
                              onPressed: widget.onAddNew,
                              icon: const Icon(Icons.person_add, size: 18),
                              label: const Text(
                                'Add New Customer',
                                style: TextStyle(fontFamily: 'Literata'),
                              ),
                              style: TextButton.styleFrom(
                                foregroundColor: const Color(0xFF1B4D3E),
                              ),
                            ),
                          ],
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
                                              fontWeight: FontWeight.w700,
                                              fontSize: 15,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            customer['contact'] ?? '—',
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
                                    // Show pending balance if > 0
                                    if ((customer['pendingBalance'] as num?)?.toDouble() != null &&
                                        (customer['pendingBalance'] as num).toDouble() > 0)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.red[50],
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          '₹${(customer['pendingBalance'] as num).toDouble().toStringAsFixed(0)}',
                                          style: TextStyle(
                                            fontFamily: 'Literata',
                                            color: Colors.red[700],
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    const SizedBox(width: 4),
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
  final double cgstPercent;
  final double sgstPercent;
  final String? hsnCode;

  _GroupedBillingProduct({
    required this.productName,
    required this.indexNo,
    required this.category,
    required this.batches,
    this.fallbackProduct,
    this.cgstPercent = 0.0,
    this.sgstPercent = 0.0,
    this.hsnCode,
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
                          // Add item directly with quantity 1
                          final maxAvailable = batch.quantityRemaining - existingQty;
                          if (maxAvailable > 0) {
                            widget.onBatchSelected(batch, 1);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  '${widget.localizations.quantityExceedsStock} (0)',
                                  style: const TextStyle(fontFamily: 'Literata'),
                                ),
                                backgroundColor: Colors.red[600],
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
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

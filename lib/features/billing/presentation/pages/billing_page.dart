import 'dart:async';
import 'dart:ui';

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
import 'package:c_billing/features/shop/data/repositories/shop_repository.dart';
import 'package:c_billing/features/shop/domain/entities/shop.dart';
import 'package:c_billing/features/customer/data/repositories/customer_repository.dart';
import 'package:c_billing/features/customer/data/repositories/customer_transaction_repository.dart';
import 'package:c_billing/core/services/language_service.dart';
import 'package:c_billing/core/localization/app_localizations.dart';
import 'package:c_billing/features/billing/presentation/pages/bill_settings_page.dart';
import 'package:c_billing/features/billing/presentation/pages/bill_report_settings_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:c_billing/features/billing/offline/entities/bill_entity.dart';
import 'package:c_billing/features/billing/data/services/bill_sync_service.dart';
import 'package:c_billing/features/product/offline/controllers/product_offline_controller.dart';
import 'package:c_billing/features/product/offline/entities/product_entity.dart';
import 'package:c_billing/features/product/data/services/product_sync_service.dart';
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
import 'package:c_billing/features/event_order/presentation/pages/event_order_list_page.dart';
import 'package:c_billing/features/reports/presentation/pages/report_page.dart';
import 'package:c_billing/features/dashboard/data/models/dashboard_data.dart';
import 'package:c_billing/features/inventory_management/presentation/pages/barcode_management_page.dart';
import 'package:c_billing/common_widgets/file_preview_page.dart';

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

  // Quick Stats data
  final DashboardOfflineRepository _dashboardRepo =
      DashboardOfflineRepository.instance;
  DashboardData? _quickStatsData;
  bool _isLoadingQuickStats = false;
  bool _showQuickStats = false;

  // GST/Tax settings
  BillTaxSettings _taxSettings = BillTaxSettings.defaultSettings;
  GstMode _gstMode = GstMode.noGst;

  /// Computed tax breakdown based on current subtotal and GST mode
  TaxBreakdown? get _taxBreakdown {
    if (_gstMode == GstMode.noGst || !_taxSettings.hasAnyTaxEnabled) {
      return null;
    }
    return _taxSettings.calculateTax(subtotal: _totalAmount, gstMode: _gstMode);
  }

  /// Responsive sizing helpers for mobile screens
  bool get _isCompactMobile {
    final width = MediaQuery.of(context).size.width;
    return width < 380;
  }

  double get _sectionIconSize => _isCompactMobile ? 36.0 : 44.0;
  double get _sectionIconInnerSize => _isCompactMobile ? 18.0 : 22.0;
  double get _sectionPadding => _isCompactMobile ? 12.0 : 16.0;
  double get _sectionSpacing => _isCompactMobile ? 10.0 : 14.0;
  double get _sectionTitleSize => _isCompactMobile ? 14.0 : 16.0;
  double get _sectionSubtitleSize => _isCompactMobile ? 11.0 : 12.0;
  double get _sectionBorderRadius => _isCompactMobile ? 10.0 : 12.0;

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
    _billSettingsSubscription = DashboardRefreshService
        .instance
        .onBillSettingsChanged
        .listen((_) {
          if (mounted) _loadBillSettings();
        });

    _loadBillSettings();
  }

  Future<void> _loadBillSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final taxSettings = await BillTaxSettings.load();
    if (mounted) {
      setState(() {
        _showCustomerOnBill =
            prefs.getBool('bill_show_customer_details') ?? true;
        _generateBillViaContact =
            prefs.getBool('bill_generate_via_contact') ?? false;
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
    _productStreamSubscription = ProductOfflineController.instance
        .watchAllProducts()
        .listen((entities) {
          if (!mounted) return;
          _loadProducts(showLoader: false);
        }, onError: (e) => debugPrint('[Billing] Product stream error: $e'));
    // Also do an initial load (stream fires immediately but we need batch data too)
    _loadProducts();
  }

  /// Setup real-time customer stream from Isar — auto-refreshes on any customer change
  void _setupCustomerStream() {
    _customerStreamSubscription = CustomerOfflineController.instance
        .watchAllCustomers()
        .listen((entities) {
          if (!mounted) return;
          // Convert entities directly from stream for instant update
          final customers = entities.map((entity) {
            final nameParts = entity.name.split(' ');
            final firstName = nameParts.isNotEmpty ? nameParts.first : '';
            final lastName = nameParts.length > 1
                ? nameParts.sublist(1).join(' ')
                : '';
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
          debugPrint(
            '[Billing] Customer stream: ${customers.length} customers',
          );
        }, onError: (e) => debugPrint('[Billing] Customer stream error: $e'));
  }

  Future<void> _loadProducts({bool showLoader = true}) async {
    try {
      if (showLoader) setState(() => _isLoading = true);

      // Use offline-first controller to get products with stock > 0
      var allProducts = await ProductOfflineController.instance
          .getAllProducts();

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

      debugPrint(
        '[BillingPage] Total products: ${allProducts.length}, with stock > 0: ${availableProducts.length}, batches: ${batches.length}',
      );

      if (mounted) {
        setState(() {
          _products = availableProducts;
          _availableBatches =
              batches.where((b) => b.quantityRemaining > 0).toList()..sort(
                (a, b) => a.purchaseDate.compareTo(b.purchaseDate),
              ); // FIFO order
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
      final localCustomers = await CustomerOfflineController.instance
          .getAllCustomers();
      if (localCustomers.isNotEmpty && mounted) {
        setState(() {
          _customers = localCustomers.map((entity) {
            // Parse name parts from entity.name
            final nameParts = entity.name.split(' ');
            final firstName = nameParts.isNotEmpty ? nameParts.first : '';
            final lastName = nameParts.length > 1
                ? nameParts.sublist(1).join(' ')
                : '';
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
        debugPrint(
          '[Billing] Loaded ${localCustomers.length} customers from Isar',
        );
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
                'fullName':
                    '${data['firstName'] ?? ''} ${data['lastName'] ?? ''}'
                        .trim(),
                'pendingBalance':
                    ((data['currentPendingAmount'] ??
                                data['pendingBalance'] ??
                                0)
                            as num)
                        .toDouble(),
                'totalPurchases': ((data['totalPurchaseAmount'] ?? 0) as num)
                    .toDouble(),
              };
            })
            .toList();

        if (firebaseCustomers.isNotEmpty && mounted) {
          setState(() {
            _customers = firebaseCustomers;
          });
          debugPrint(
            '[Billing] Loaded ${firebaseCustomers.length} customers from Firebase',
          );
        }
      } catch (e) {
        debugPrint(
          '[Billing] Firebase customer fetch failed (using local): $e',
        );
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
      final normalizedPhone = phoneNumber.replaceAll(
        RegExp(r'[\s\-\(\)\+]'),
        '',
      );
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
        final customerNormalized = customerContact.replaceAll(
          RegExp(r'[\s\-\(\)\+]'),
          '',
        );
        if (customerNormalized.length >= 10 && last10Digits.length >= 10) {
          final customerLast10 = customerNormalized.substring(
            customerNormalized.length - 10,
          );
          if (customerLast10 == last10Digits) {
            foundCustomer = c;
            break;
          }
        }
      }

      // If not found locally, try Firestore repository as fallback
      if (foundCustomer == null) {
        try {
          final customer = await _customerRepository.getCustomerByContact(
            phoneNumber,
          );
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
        final fullName =
            foundCustomer['fullName'] ??
            '${foundCustomer['firstName'] ?? ''} ${foundCustomer['lastName'] ?? ''}'
                .trim();

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

        _showSnackbar('Customer found: $fullName', isError: false);
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
              style: TextStyle(color: Colors.grey[600], fontFamily: 'Literata'),
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
      DashboardRefreshService.instance.notifyDataChanged(
        DataChangeType.customer,
      );

      if (mounted) {
        _showSnackbar('Customer added: $fullName', isError: false);
      }
    } catch (e) {
      debugPrint('[DEBUG] Error saving customer: $e');
      if (mounted) {
        _showSnackbar('Error saving customer: $e', isError: true);
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
        onBatchItemAdded:
            (
              productId,
              productName,
              companyName,
              batchLocalId,
              sellingPrice,
              purchasePrice,
              quantity,
              maxStock,
              cgstPercent,
              sgstPercent,
              hsnCode,
            ) {
              // Use a unique key: productId + batchLocalId (or just productId if no batch)
              final uniqueKey = batchLocalId != null
                  ? '${productId}_batch_$batchLocalId'
                  : productId;
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
        _showSnackbar(_localizations.pleaseEnterValidContact, isError: true);
        return;
      }
    }

    // Validate customer details are required for partial payment
    if (!_isFullPayment && _selectedCustomer == null) {
      final customerName = _customerNameController.text.trim();
      final customerContact = _customerContactController.text.trim();
      if (customerName.isEmpty ||
          customerContact.isEmpty ||
          customerContact.length < 10) {
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

      final integrationResult = await InventoryIntegrationService.instance
          .processBill(
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
            pendingAmount: calculatedPendingAmount > 0
                ? calculatedPendingAmount
                : 0,
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
        throw Exception(
          integrationResult.errorMessage ?? _localizations.billProcessingFailed,
        );
      }

      debugPrint(
        '[Billing] Bill processed with FIFO: COGS=${integrationResult.totalCOGS}, Profit=${integrationResult.totalProfit}',
      );

      // 3. Create ledger/transaction entry for partial payments
      if (calculatedPendingAmount > 0 && _selectedCustomer != null) {
        try {
          final customerId = _selectedCustomer!['id'] as String;
          final billId =
              integrationResult.billEntity?.serverId ??
              'local_${integrationResult.billEntity?.id}';

          // Create ledger entry via CustomerTransactionService
          final transactionResult = await _customerTransactionService
              .recordBillGenerated(
                customerId: customerId,
                billId: billId,
                billNumber: billId,
                billAmount: calculatedPendingAmount,
              );

          if (transactionResult.success) {
            debugPrint(
              '[Billing] Ledger entry created for pending amount: $calculatedPendingAmount',
            );
          } else {
            debugPrint(
              '[Billing] Ledger entry failed: ${transactionResult.errorMessage}',
            );
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

      // Show bill PDF preview with print/share options (like purchase report)
      if (mounted) {
        await _showBillPdfPreview(createdBill);
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
    final double? totalDueAmount = bill.pendingAmount > 0
        ? bill.pendingAmount
        : null;
    return PrintBillData.fromBill(bill, totalDueAmount: totalDueAmount);
  }

  /// Show bill PDF preview with share/print options (like purchase report)
  static bool _pdfGenerationInProgress = false;
  
  Future<void> _showBillPdfPreview(Bill bill) async {
    // Prevent multiple simultaneous PDF generations globally
    if (_pdfGenerationInProgress) {
      debugPrint('[BillingPage] PDF generation already in progress globally, ignoring request');
      return;
    }

    try {
      debugPrint('[BillingPage] Starting PDF preview for bill: ${bill.billNumber}');
      _pdfGenerationInProgress = true;
      
      // Show loading snackbar (non-blocking like purchase page)
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  _localizations.preparingPdf,
                  style: const TextStyle(fontFamily: 'Literata'),
                ),
              ],
            ),
            duration: const Duration(seconds: 60),
            backgroundColor: const Color(0xFF1B4D3E),
          ),
        );
      }
      
      debugPrint('[BillingPage] Creating print data...');
      final printData = _createPrintBillData(bill);
      debugPrint('[BillingPage] Print data created: ${printData.items.length} items');
      
      debugPrint('[BillingPage] Getting shop details...');
      final shop = await _shopRepository.getShopDetails().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          debugPrint('[BillingPage] Shop details timeout, using empty shop');
          return Shop.empty;
        },
      );
      debugPrint('[BillingPage] Shop: ${shop.shopName}');
      
      debugPrint('[BillingPage] Generating PDF file...');
      final file = await _pdfService.savePdfToFile(
        billData: printData,
        shopDetails: shop,
      ).timeout(
        const Duration(seconds: 90),
        onTimeout: () => throw Exception('PDF generation timed out after 90 seconds'),
      );
      
      // Validate file creation
      if (!file.existsSync()) {
        throw Exception('PDF file was not created successfully');
      }
      
      final fileSize = file.lengthSync();
      if (fileSize == 0) {
        throw Exception('PDF file is empty');
      }
      
      debugPrint('[BillingPage] PDF saved to: ${file.path}');
      debugPrint('[BillingPage] File size: ${fileSize} bytes');
      
      // Hide loading snackbar
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
      }
      
      if (!mounted) {
        debugPrint('[BillingPage] Widget not mounted, aborting');
        return;
      }
      
      // Navigate to PDF preview
      debugPrint('[BillingPage] Navigating to FilePreviewPage...');
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => FilePreviewPage(
            file: file,
            fileName: '${_localizations.bills} - ${bill.billNumber}',
            fileType: FilePreviewType.pdf,
            subtitle: DateFormat('dd MMM yyyy, hh:mm a').format(bill.billDate),
          ),
        ),
      );
      debugPrint('[BillingPage] Returned from FilePreviewPage');
      
    } catch (e, stack) {
      debugPrint('[BillingPage] ERROR generating PDF preview: $e');
      debugPrint('[BillingPage] Stack trace: $stack');
      
      // Hide loading snackbar
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
      }
      
      // Small delay before showing error
      await Future.delayed(const Duration(milliseconds: 300));
      
      if (mounted) {
        _showSnackbar(
          'Failed to generate PDF: ${e.toString()}', 
          isError: true,
          action: SnackBarAction(
            label: 'Retry',
            textColor: Colors.white,
            onPressed: () => _showBillPdfPreview(bill),
          ),
        );
      }
    } finally {
      debugPrint('[BillingPage] Resetting PDF generation state');
      _pdfGenerationInProgress = false;
    }
  }

  void _showSnackbar(String message, {bool isError = false, SnackBarAction? action}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontFamily: 'Literata')),
        backgroundColor: isError ? Colors.red[600] : Colors.green[600],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
        duration: Duration(seconds: isError ? 6 : 4),
        action: action,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F6),
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
                      // Quick Stats inline bar at top
                      _buildQuickStatsInlineBar(),
                      if (_showCustomerOnBill || _generateBillViaContact)
                        _buildCustomerSection(),
                      _buildAddItemsSection(),
                      if (_billItems.isNotEmpty) _buildBillItemsSection(),
                      if (_billItems.isNotEmpty) _buildDiscountSection(),
                      if (_billItems.isNotEmpty &&
                          _taxSettings.hasAnyTaxEnabled)
                        _buildGstModeSection(),
                      if (_billItems.isNotEmpty) _buildPaymentSection(),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
                // Quick Stats Premium Panel (z-index above everything)
                if (_showQuickStats) _buildQuickStatsPremiumPanel(),
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
    final minH = _isCompactMobile ? 40.0 : 70.0;
    final maxH = _isCompactMobile ? 700.0 : 120.0;
    return SliverPersistentHeader(
      pinned: true,
      delegate: _BillingHeaderDelegate(
        minHeight: minH,
        maxHeight: maxH,
        billItemsCount: _billItems.length,
        localizations: _localizations,
        isCompact: _isCompactMobile,
        onSettingsTap: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const BillSettingsPage()),
          );
          if (result == true) {
            _loadBillSettings();
          }
        },
        onReportSettingsTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const BillReportSettingsPage()),
          );
        },
      ),
    );
  }

  Widget _buildCustomerSection() {
    // Determine if customer is required (partial payment selected)
    final isCustomerRequired = !_isFullPayment;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: isCustomerRequired && _selectedCustomer == null
            ? Border.all(color: Colors.red[300]!, width: 2)
            : Border.all(color: Colors.grey.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header
          Container(
            padding: EdgeInsets.all(_sectionPadding),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFFFF6B6B).withOpacity(0.1),
                  const Color(0xFFFF6B6B).withOpacity(0.05),
                ],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: _sectionIconSize,
                  height: _sectionIconSize,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFFFF6B6B),
                        const Color(0xFFFF6B6B).withOpacity(0.8),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(_sectionBorderRadius),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFF6B6B).withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.person_rounded,
                    color: Colors.white,
                    size: _sectionIconInnerSize,
                  ),
                ),
                SizedBox(width: _sectionSpacing),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _generateBillViaContact
                            ? _localizations.phoneNumber
                            : isCustomerRequired
                            ? '${_localizations.customerOptional.replaceAll('(Optional)', '')}(Required)'
                            : _localizations.customerOptional,
                        style: TextStyle(
                          fontFamily: 'Literata',
                          fontWeight: FontWeight.w700,
                          fontSize: _sectionTitleSize,
                          color: isCustomerRequired && _selectedCustomer == null
                              ? Colors.red[700]!
                              : const Color(0xFF1B4D3E),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _generateBillViaContact
                            ? 'Auto-link customer by phone'
                            : 'Link a customer to this bill',
                        style: TextStyle(
                          fontFamily: 'Literata',
                          fontSize: _sectionSubtitleSize,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                // Loading indicator for customer list
                if (_isLoadingCustomers)
                  Container(
                    width: 36,
                    height: 36,
                    padding: const EdgeInsets.all(8),
                    child: const CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xFF1B4D3E),
                    ),
                  ),
                // Add Customer button
                if (!_generateBillViaContact && !_isLoadingCustomers)
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        final phone = _customerContactController.text.trim();
                        _showAddCustomerDialog(phone);
                      },
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1B4D3E).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.person_add_rounded,
                          color: Color(0xFF1B4D3E),
                          size: 20,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Content Section
          Padding(
            padding: EdgeInsets.all(_sectionPadding),
            child: Column(
              children: [
                // Show selected customer info card (bold name + balance)
                if (_selectedCustomer != null && !_generateBillViaContact) ...[
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF1B4D3E).withOpacity(0.08),
                          const Color(0xFF1B4D3E).withOpacity(0.03),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFF1B4D3E).withOpacity(0.15),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF1B4D3E), Color(0xFF2D6A4F)],
                            ),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Center(
                            child: Text(
                              (_selectedCustomer!['fullName'] as String? ??
                                      '?')[0]
                                  .toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 20,
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
                                _selectedCustomer!['fullName'] ?? '-',
                                style: const TextStyle(
                                  fontFamily: 'Literata',
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                  color: Color(0xFF1B4D3E),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(
                                    Icons.phone_rounded,
                                    size: 14,
                                    color: Colors.grey[500],
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    _selectedCustomer!['contact'] ?? '-',
                                    style: TextStyle(
                                      fontFamily: 'Literata',
                                      fontSize: 13,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                              if ((_selectedCustomer!['pendingBalance'] as num?)
                                          ?.toDouble() !=
                                      null &&
                                  (_selectedCustomer!['pendingBalance'] as num)
                                          .toDouble() >
                                      0) ...[
                                const SizedBox(height: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.account_balance_wallet_rounded,
                                        size: 14,
                                        color: Colors.orange[700],
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Due: ₹${(_selectedCustomer!['pendingBalance'] as num).toDouble().toStringAsFixed(2)}',
                                        style: TextStyle(
                                          fontFamily: 'Literata',
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.orange[700],
                                        ),
                                      ),
                                    ],
                                  ),
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
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.close_rounded,
                              color: Colors.red[400],
                              size: 18,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else if (_generateBillViaContact) ...[
                  // Show only phone number field when generate via contact is enabled
                  _buildPhoneInputField(),
                ] else ...[
                  // Normal customer section — tap to pick or enter manually
                  _buildCustomerPickerSection(isCustomerRequired),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Phone input field for generate via contact mode
  Widget _buildPhoneInputField() {
    final containerPad = _isCompactMobile ? 6.0 : 8.0;
    final iconContainerSize = _isCompactMobile ? 28.0 : 34.0;
    final iconSize = _isCompactMobile ? 14.0 : 18.0;
    final fontSize = _isCompactMobile ? 13.0 : 15.0;
    final labelSize = _isCompactMobile ? 11.0 : 13.0;
    final hintSize = _isCompactMobile ? 11.0 : 13.0;
    final verticalPad = _isCompactMobile ? 10.0 : 16.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(_isCompactMobile ? 10 : 14),
            border: Border.all(color: const Color(0xFF1B4D3E).withOpacity(0.2)),
          ),
          child: TextField(
            controller: _customerContactController,
            keyboardType: TextInputType.phone,
            style: TextStyle(fontFamily: 'Literata', fontSize: fontSize),
            decoration: InputDecoration(
              labelText: '${_localizations.enterPhoneNumber} *',
              hintText: _localizations.enterCustomerPhone,
              hintStyle: TextStyle(color: Colors.grey[400], fontSize: hintSize),
              labelStyle: TextStyle(
                color: const Color(0xFF1B4D3E),
                fontSize: labelSize,
                fontWeight: FontWeight.w600,
              ),
              prefixIcon: Container(
                margin: EdgeInsets.all(containerPad),
                width: iconContainerSize,
                height: iconContainerSize,
                decoration: BoxDecoration(
                  color: const Color(0xFF1B4D3E).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(_isCompactMobile ? 6 : 8),
                ),
                child: Icon(
                  Icons.phone_rounded,
                  color: const Color(0xFF1B4D3E),
                  size: iconSize,
                ),
              ),
              suffixIcon: _isSearchingCustomer
                  ? Padding(
                      padding: EdgeInsets.all(_isCompactMobile ? 8.0 : 12.0),
                      child: SizedBox(
                        width: _isCompactMobile ? 16 : 20,
                        height: _isCompactMobile ? 16 : 20,
                        child: const CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFF1B4D3E),
                        ),
                      ),
                    )
                  : _hasPhoneText
                  ? IconButton(
                      icon: Icon(Icons.clear_rounded, size: _isCompactMobile ? 16 : 20),
                      onPressed: () {
                        _customerContactController.clear();
                        setState(() {
                          _autoFoundCustomerName = null;
                          _selectedCustomer = null;
                          _hasPhoneText = false;
                        });
                      },
                      color: Colors.grey[600],
                    )
                  : null,
              contentPadding: EdgeInsets.symmetric(
                horizontal: _isCompactMobile ? 10 : 16,
                vertical: verticalPad,
              ),
              isDense: _isCompactMobile,
              border: InputBorder.none,
            ),
          ),
        ),
        if (_autoFoundCustomerName != null) _buildCustomerFoundBadge(),
        if (_showAddCustomerPrompt && !_isSearchingCustomer)
          _buildAddCustomerPrompt(),
      ],
    );
  }

  // Customer found badge
  Widget _buildCustomerFoundBadge() {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.green.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.green.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.check_circle_rounded,
              size: 16,
              color: Colors.green,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                '${_localizations.customerColon} $_autoFoundCustomerName',
                style: const TextStyle(
                  fontSize: 13,
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
    );
  }

  // Add customer prompt
  Widget _buildAddCustomerPrompt() {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: GestureDetector(
        onTap: () {
          final phone = _customerContactController.text.trim();
          _showAddCustomerDialog(phone);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.orange.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.orange.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.person_add_rounded,
                size: 16,
                color: Colors.orange[700],
              ),
              const SizedBox(width: 8),
              Text(
                'Customer not found. Add new?',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.orange[700],
                  fontFamily: 'Literata',
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 12,
                color: Colors.orange[700],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Customer picker section (normal mode)
  Widget _buildCustomerPickerSection(bool isCustomerRequired) {
    final containerPad = _isCompactMobile ? 5.0 : 7.0;
    final iconPad = _isCompactMobile ? 6.0 : 8.0;
    final iconSize = _isCompactMobile ? 16.0 : 18.0;
    final fontSize = _isCompactMobile ? 12.0 : 14.0;
    final spacing = _isCompactMobile ? 8.0 : 12.0;
    return Column(
      children: [
        // Search existing customer button
        GestureDetector(
          onTap: _showCustomerPicker,
          child: Container(
            padding: EdgeInsets.all(containerPad),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(_isCompactMobile ? 10 : 14),
              border: Border.all(
                color: isCustomerRequired
                    ? Colors.red[200]!
                    : Colors.grey[200]!,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(iconPad),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1B4D3E).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(_isCompactMobile ? 6 : 8),
                  ),
                  child: Icon(
                    Icons.search_rounded,
                    color: const Color(0xFF1B4D3E).withOpacity(0.7),
                    size: iconSize,
                  ),
                ),
                SizedBox(width: spacing),
                Expanded(
                  child: Text(
                    _localizations.searchExistingCustomer,
                    style: TextStyle(
                      fontFamily: 'Literata',
                      color: Colors.grey[500],
                      fontSize: fontSize,
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.grey[400],
                  size: _isCompactMobile ? 18 : 22,
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: _isCompactMobile ? 10 : 14),
        // Manual input fields
        Row(
          children: [
            Expanded(
              child: _buildInputField(
                controller: _customerNameController,
                label: _localizations.name,
                icon: Icons.person_outline_rounded,
              ),
            ),
            SizedBox(width: _isCompactMobile ? 8 : 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInputField(
                    controller: _customerContactController,
                    label: _localizations.phone,
                    icon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                    suffixIcon: _isSearchingCustomer
                        ? Padding(
                            padding: EdgeInsets.all(_isCompactMobile ? 8.0 : 12.0),
                            child: SizedBox(
                              width: _isCompactMobile ? 14 : 18,
                              height: _isCompactMobile ? 14 : 18,
                              child: const CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Color(0xFF1B4D3E),
                              ),
                            ),
                          )
                        : _hasPhoneText
                        ? IconButton(
                            icon: Icon(Icons.clear_rounded, size: _isCompactMobile ? 14 : 18),
                            onPressed: () {
                              _customerContactController.clear();
                              setState(() {
                                _autoFoundCustomerName = null;
                                _selectedCustomer = null;
                                _hasPhoneText = false;
                                _showAddCustomerPrompt = false;
                              });
                            },
                            color: Colors.grey[500],
                          )
                        : null,
                  ),
                  if (_autoFoundCustomerName != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 6, left: 4),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.check_circle_rounded,
                            size: 14,
                            color: Colors.green,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              _autoFoundCustomerName!,
                              style: const TextStyle(
                                fontSize: 11,
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
                            Icon(
                              Icons.person_add_rounded,
                              size: 12,
                              color: Colors.orange[700],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Add new?',
                              style: TextStyle(
                                fontSize: 11,
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
    );
  }

  // Reusable input field widget
  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    Widget? suffixIcon,
  }) {
    final verticalPad = _isCompactMobile ? 4.0 : 6.0;
    final horizontalPad = _isCompactMobile ? 7.0 : 14.0;
    final fontSize = _isCompactMobile ? 13.0 : 14.0;
    final labelSize = _isCompactMobile ? 11.0 : 13.0;
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(_isCompactMobile ? 10 : 12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: TextStyle(fontFamily: 'Literata', fontSize: fontSize),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.grey[600], fontSize: labelSize),
          contentPadding: EdgeInsets.symmetric(
            horizontal: horizontalPad,
            vertical: verticalPad,
          ),
          isDense: _isCompactMobile,
          border: InputBorder.none,
          suffixIcon: suffixIcon,
        ),
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
    final productBatches =
        _availableBatches
            .where((b) => b.productId == product.id && b.quantityRemaining > 0)
            .toList()
          ..sort((a, b) => a.purchaseDate.compareTo(b.purchaseDate));
    final batchStock = productBatches.fold<int>(
      0,
      (s, b) => s + b.quantityRemaining,
    );
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
          cgstPercent: product.cgstPercent,
          sgstPercent: product.sgstPercent,
          hsnCode: product.hsnCode,
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
                  companyName: batch.companyName.isNotEmpty
                      ? batch.companyName
                      : null,
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
                    companyName: batch.companyName.isNotEmpty
                        ? batch.companyName
                        : null,
                    sellingPrice: batch.sellingPrice,
                    purchasePrice: batch.purchasePrice,
                    quantity: quantity,
                    hsnCode: product.hsnCode,
                  ),
                );
              }
            });
            Navigator.pop(ctx);
            _showSnackbar(
              '${_localizations.added}: ${product.name}',
              isError: false,
            );
          },
          onItemRemoved: (uniqueKey) {
            setState(() {
              _billItems.removeWhere((item) => item.productId == uniqueKey);
            });
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
            companyName: product.companyName.isNotEmpty
                ? product.companyName
                : null,
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
            companyName: product.companyName.isNotEmpty
                ? product.companyName
                : null,
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
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Section Header
          Container(
            padding: EdgeInsets.all(_sectionPadding),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF1B4D3E).withOpacity(0.1),
                  const Color(0xFF1B4D3E).withOpacity(0.05),
                ],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: _sectionIconSize,
                  height: _sectionIconSize,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF1B4D3E),
                        const Color(0xFF1B4D3E).withOpacity(0.8),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(_sectionBorderRadius),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF1B4D3E).withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.add_shopping_cart_rounded,
                    color: Colors.white,
                    size: _sectionIconInnerSize,
                  ),
                ),
                SizedBox(width: _sectionSpacing),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _localizations.addItems,
                        style: TextStyle(
                          fontFamily: 'Literata',
                          fontWeight: FontWeight.w700,
                          fontSize: _sectionTitleSize,
                          color: const Color(0xFF1B4D3E),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Quick add by code or search',
                        style: TextStyle(
                          fontFamily: 'Literata',
                          fontSize: _sectionSubtitleSize,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Content
          Padding(
            padding: EdgeInsets.all(_sectionPadding),
            child: Column(
              children: [
                // Quick add by index number
                Container(
                  padding: EdgeInsets.all(_isCompactMobile ? 10 : 14),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.amber.withOpacity(0.1),
                        Colors.amber.withOpacity(0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(_isCompactMobile ? 10 : 14),
                    border: Border.all(color: Colors.amber.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(_isCompactMobile ? 6 : 10),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.amber[700]!, Colors.amber[600]!],
                          ),
                          borderRadius: BorderRadius.circular(_isCompactMobile ? 8 : 10),
                        ),
                        child: Icon(
                          Icons.flash_on_rounded,
                          color: Colors.white,
                          size: _isCompactMobile ? 14 : 18,
                        ),
                      ),
                      SizedBox(width: _isCompactMobile ? 8 : 12),
                      Expanded(
                        child: TextField(
                          controller: _indexNoController,
                          focusNode: _indexNoFocusNode,
                          keyboardType: TextInputType.number,
                          style: TextStyle(
                            fontFamily: 'Literata',
                            fontSize: _isCompactMobile ? 14 : 16,
                            fontWeight: FontWeight.w600,
                          ),
                          decoration: InputDecoration(
                            hintText: _localizations.enterProductCode,
                            hintStyle: TextStyle(
                              color: Colors.grey[500],
                              fontWeight: FontWeight.w400,
                              fontSize: _isCompactMobile ? 12 : 14,
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
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(_isCompactMobile ? 8 : 10),
                          onTap: _addProductByIndexNoOnPage,
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: _isCompactMobile ? 12 : 16,
                              vertical: _isCompactMobile ? 6 : 10,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  const Color(0xFF1B4D3E),
                                  const Color(0xFF2D6A4F),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(_isCompactMobile ? 8 : 10),
                            ),
                            child: Text(
                              _localizations.add,
                              style: TextStyle(
                                fontFamily: 'Literata',
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: _isCompactMobile ? 12 : 14,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: _isCompactMobile ? 10 : 14),
                // Search product button
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(_isCompactMobile ? 10 : 14),
                    onTap: _showAddItemsPopup,
                    child: Container(
                      padding: EdgeInsets.all(_isCompactMobile ? 10 : 14),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(_isCompactMobile ? 10 : 14),
                        border: Border.all(
                          color: const Color(0xFF1B4D3E).withOpacity(0.2),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: EdgeInsets.all(_isCompactMobile ? 6 : 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1B4D3E).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(_isCompactMobile ? 6 : 8),
                            ),
                            child: Icon(
                              Icons.search_rounded,
                              color: const Color(0xFF1B4D3E),
                              size: _isCompactMobile ? 16 : 20,
                            ),
                          ),
                          SizedBox(width: _isCompactMobile ? 8 : 12),
                          Text(
                            _localizations.searchProduct,
                            style: TextStyle(
                              fontFamily: 'Literata',
                              fontWeight: FontWeight.w600,
                              fontSize: _isCompactMobile ? 13 : 15,
                              color: const Color(0xFF1B4D3E),
                            ),
                          ),
                          const Spacer(),
                          Icon(
                            Icons.arrow_forward_ios_rounded,
                            color: Colors.grey[400],
                            size: _isCompactMobile ? 14 : 18,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBillItemsSection() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header with enhanced design
          Container(
            padding: EdgeInsets.all(_sectionPadding),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF7B68EE).withValues(alpha: 0.12),
                  const Color(0xFF7B68EE).withValues(alpha: 0.04),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: _sectionIconSize,
                  height: _sectionIconSize,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF7B68EE), Color(0xFF9B8DFF)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(_sectionBorderRadius),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF7B68EE).withValues(alpha: 0.35),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.shopping_cart_rounded,
                    color: Colors.white,
                    size: _sectionIconInnerSize,
                  ),
                ),
                SizedBox(width: _sectionSpacing),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _localizations.billItems,
                        style: TextStyle(
                          fontFamily: 'Literata',
                          fontWeight: FontWeight.w700,
                          fontSize: _sectionTitleSize + 1,
                          color: const Color(0xFF1A1A2E),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Tap quantity to edit • Swipe to remove',
                        style: TextStyle(
                          fontFamily: 'Literata',
                          fontSize: _sectionSubtitleSize - 1,
                          color: Colors.grey[500],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: _isCompactMobile ? 10 : 14,
                    vertical: _isCompactMobile ? 5 : 7,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1B4D3E), Color(0xFF2D6A4F)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF1B4D3E).withValues(alpha: 0.25),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    '${_billItems.length} ${_localizations.items.toLowerCase()}',
                    style: const TextStyle(
                      fontFamily: 'Literata',
                      fontSize: 12,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Enhanced Items List
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _billItems.length,
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

              // Calculate max stock for this item
              int maxStock;
              final parts = item.productId.split('_batch_');
              final batchLocalId =
                  parts.length > 1 ? int.tryParse(parts.last) : null;
              if (batchLocalId != null) {
                final batch = _availableBatches.cast<PurchaseBatchEntity?>().firstWhere(
                      (b) => b!.id == batchLocalId && b.quantityRemaining > 0,
                      orElse: () => null,
                    );
                maxStock = batch?.quantityRemaining ?? 0;
              } else {
                final batchStock = _availableBatches
                    .where((b) =>
                        b.productId == realProductId && b.quantityRemaining > 0)
                    .fold<int>(0, (s, b) => s + b.quantityRemaining);
                maxStock = batchStock > 0 ? batchStock : product.currentStock;
              }

              final isLastItem = index == _billItems.length - 1;

              return Dismissible(
                key: Key('${item.productId}_$index'),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.red[300]!, Colors.red[500]!],
                    ),
                    borderRadius: isLastItem
                        ? const BorderRadius.only(
                            bottomLeft: Radius.circular(20),
                            bottomRight: Radius.circular(20),
                          )
                        : null,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        _localizations.delete,
                        style: const TextStyle(
                          fontFamily: 'Literata',
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.delete_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ],
                  ),
                ),
                confirmDismiss: (direction) async {
                  // Optional: Add haptic feedback
                  return true;
                },
                onDismissed: (_) => setState(() => _billItems.removeAt(index)),
                child: Container(
                  margin: EdgeInsets.only(
                    left: 12,
                    right: 12,
                    top: index == 0 ? 12 : 6,
                    bottom: isLastItem ? 12 : 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.grey.withValues(alpha: 0.12),
                      width: 1,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Product info - Left side
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Product name with delete button
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      item.productName,
                                      style: const TextStyle(
                                        fontFamily: 'Literata',
                                        fontWeight: FontWeight.w700,
                                        fontSize: 14,
                                        color: Color(0xFF1A1A2E),
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  // Delete button
                                  Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(8),
                                      onTap: () {
                                        setState(() => _billItems.removeAt(index));
                                        _showSnackbar(
                                          '${item.productName} ${_localizations.delete}d',
                                          isError: false,
                                        );
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: Colors.red[50],
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Icon(
                                          Icons.close_rounded,
                                          size: 16,
                                          color: Colors.red[400],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              // Price and GST info
                              Wrap(
                                spacing: 6,
                                runSpacing: 4,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF1B4D3E).withValues(alpha: 0.08),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      '₹${item.sellingPrice.toStringAsFixed(0)}/unit',
                                      style: const TextStyle(
                                        fontFamily: 'Literata',
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF1B4D3E),
                                      ),
                                    ),
                                  ),
                                  if (item.cgstPercent > 0 || item.sgstPercent > 0)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.orange[50],
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        'GST ${(item.cgstPercent + item.sgstPercent).toStringAsFixed(0)}%',
                                        style: TextStyle(
                                          fontFamily: 'Literata',
                                          fontSize: 10,
                                          color: Colors.orange[800],
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.blue[50],
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      '${_localizations.stock}: $maxStock',
                                      style: TextStyle(
                                        fontFamily: 'Literata',
                                        fontSize: 10,
                                        color: Colors.blue[700],
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Quantity and Total - Right side
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            // Quantity controls with editable field
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(0xFF1B4D3E).withValues(alpha: 0.2),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.04),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Minus button
                                  Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      borderRadius: const BorderRadius.only(
                                        topLeft: Radius.circular(11),
                                        bottomLeft: Radius.circular(11),
                                      ),
                                      onTap: () {
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
                                      child: Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF1B4D3E).withValues(alpha: 0.08),
                                          borderRadius: const BorderRadius.only(
                                            topLeft: Radius.circular(11),
                                            bottomLeft: Radius.circular(11),
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.remove_rounded,
                                          size: 18,
                                          color: Color(0xFF1B4D3E),
                                        ),
                                      ),
                                    ),
                                  ),
                                  // Editable Quantity input - inline
                                  SizedBox(
                                    width: 48,
                                    child: TextField(
                                      controller: TextEditingController(text: '${item.quantity}'),
                                      keyboardType: TextInputType.number,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        fontFamily: 'Literata',
                                        fontWeight: FontWeight.w800,
                                        fontSize: 15,
                                        color: Color(0xFF1B4D3E),
                                      ),
                                      decoration: InputDecoration(
                                        isDense: true,
                                        contentPadding: const EdgeInsets.symmetric(
                                          horizontal: 4,
                                          vertical: 10,
                                        ),
                                        border: InputBorder.none,
                                        enabledBorder: InputBorder.none,
                                        focusedBorder: UnderlineInputBorder(
                                          borderSide: BorderSide(
                                            color: const Color(0xFF1B4D3E).withValues(alpha: 0.5),
                                            width: 2,
                                          ),
                                        ),
                                      ),
                                      onSubmitted: (value) {
                                        final qty = int.tryParse(value) ?? item.quantity;
                                        if (qty <= 0) {
                                          setState(() => _billItems.removeAt(index));
                                        } else if (qty > maxStock) {
                                          _showSnackbar(
                                            '${_localizations.maxStock}: $maxStock',
                                            isError: true,
                                          );
                                        } else {
                                          setState(() {
                                            _billItems[index] = BillItem.create(
                                              productId: item.productId,
                                              productName: item.productName,
                                              companyName: item.companyName,
                                              sellingPrice: item.sellingPrice,
                                              purchasePrice: item.purchasePrice,
                                              quantity: qty,
                                              cgstPercent: item.cgstPercent,
                                              sgstPercent: item.sgstPercent,
                                              hsnCode: item.hsnCode,
                                            );
                                          });
                                        }
                                      },
                                    ),
                                  ),
                                  // Plus button
                                  Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      borderRadius: const BorderRadius.only(
                                        topRight: Radius.circular(11),
                                        bottomRight: Radius.circular(11),
                                      ),
                                      onTap: () {
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
                                      child: Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: item.quantity < maxStock
                                              ? const Color(0xFF1B4D3E).withValues(alpha: 0.08)
                                              : Colors.grey[100],
                                          borderRadius: const BorderRadius.only(
                                            topRight: Radius.circular(11),
                                            bottomRight: Radius.circular(11),
                                          ),
                                        ),
                                        child: Icon(
                                          Icons.add_rounded,
                                          size: 18,
                                          color: item.quantity < maxStock
                                              ? const Color(0xFF1B4D3E)
                                              : Colors.grey[400],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            // Subtotal with enhanced styling
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF1B4D3E), Color(0xFF2D6A4F)],
                                ),
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF1B4D3E).withValues(alpha: 0.2),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Text(
                                '₹${item.subtotal.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  fontFamily: 'Literata',
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  /// Show dialog to edit quantity for a bill item
  void _showBillItemQuantityDialog({
    required int index,
    required BillItem item,
    required int maxStock,
  }) {
    final qtyController = TextEditingController(text: item.quantity.toString());
    String? errorText;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          void validateQty() {
            final qty = int.tryParse(qtyController.text) ?? 0;
            setDialogState(() {
              if (qty <= 0) {
                errorText = _localizations.pleaseEnterValidNumber;
              } else if (qty > maxStock) {
                errorText = '${_localizations.maxStock}: $maxStock';
              } else {
                errorText = null;
              }
            });
          }

          return AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF7B68EE), Color(0xFF9B8DFF)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF7B68EE).withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.edit_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _localizations.enterQuantity,
                        style: const TextStyle(
                          fontFamily: 'Literata',
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1A1A2E),
                        ),
                      ),
                      Text(
                        item.productName,
                        style: TextStyle(
                          fontFamily: 'Literata',
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Info row
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _localizations.price,
                            style: TextStyle(
                              fontFamily: 'Literata',
                              fontSize: 11,
                              color: Colors.grey[500],
                            ),
                          ),
                          Text(
                            '₹${item.sellingPrice.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontFamily: 'Literata',
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                              color: Color(0xFF1B4D3E),
                            ),
                          ),
                        ],
                      ),
                      Container(
                        width: 1,
                        height: 36,
                        color: Colors.grey[200],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            _localizations.stock,
                            style: TextStyle(
                              fontFamily: 'Literata',
                              fontSize: 11,
                              color: Colors.grey[500],
                            ),
                          ),
                          Text(
                            '$maxStock',
                            style: TextStyle(
                              fontFamily: 'Literata',
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                              color: Colors.blue[700],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                // Quantity input with +/- buttons
                Row(
                  children: [
                    // Minus button
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () {
                          final current = int.tryParse(qtyController.text) ?? 0;
                          if (current > 1) {
                            qtyController.text = (current - 1).toString();
                            validateQty();
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.red.withValues(alpha: 0.2)),
                          ),
                          child: Icon(Icons.remove_rounded, color: Colors.red[700], size: 24),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Quantity field
                    Expanded(
                      child: TextField(
                        controller: qtyController,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        onChanged: (_) => validateQty(),
                        style: const TextStyle(
                          fontFamily: 'Literata',
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1B4D3E),
                        ),
                        decoration: InputDecoration(
                          errorText: errorText,
                          errorStyle: const TextStyle(fontSize: 11),
                          filled: true,
                          fillColor: Colors.grey[50],
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                              color: Color(0xFF7B68EE),
                              width: 2,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(color: Colors.grey[200]!),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Plus button
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () {
                          final current = int.tryParse(qtyController.text) ?? 0;
                          if (current < maxStock) {
                            qtyController.text = (current + 1).toString();
                            validateQty();
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.green[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.green.withValues(alpha: 0.2)),
                          ),
                          child: Icon(Icons.add_rounded, color: Colors.green[700], size: 24),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Quick quantity buttons
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: [1, 5, 10, 25, 50, 100]
                      .where((q) => q <= maxStock)
                      .map(
                        (qty) => Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(8),
                            onTap: () {
                              qtyController.text = qty.toString();
                              validateQty();
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Colors.grey.withValues(alpha: 0.2),
                                ),
                              ),
                              child: Text(
                                '$qty',
                                style: TextStyle(
                                  fontFamily: 'Literata',
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ],
            ),
            actions: [
              // Delete button
              TextButton.icon(
                onPressed: () {
                  setState(() => _billItems.removeAt(index));
                  Navigator.pop(ctx);
                  _showSnackbar(
                    '${item.productName} ${_localizations.delete}d',
                    isError: false,
                  );
                },
                icon: Icon(Icons.delete_outline_rounded, color: Colors.red[600], size: 20),
                label: Text(
                  _localizations.delete,
                  style: TextStyle(
                    fontFamily: 'Literata',
                    color: Colors.red[600],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Spacer(),
              // Cancel button
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(
                  _localizations.cancel,
                  style: TextStyle(
                    fontFamily: 'Literata',
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Update button
              ElevatedButton(
                onPressed: errorText == null
                    ? () {
                        final qty = int.tryParse(qtyController.text) ?? 0;
                        if (qty > 0 && qty <= maxStock) {
                          setState(() {
                            _billItems[index] = BillItem.create(
                              productId: item.productId,
                              productName: item.productName,
                              companyName: item.companyName,
                              sellingPrice: item.sellingPrice,
                              purchasePrice: item.purchasePrice,
                              quantity: qty,
                              cgstPercent: item.cgstPercent,
                              sgstPercent: item.sgstPercent,
                              hsnCode: item.hsnCode,
                            );
                          });
                          Navigator.pop(ctx);
                        }
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1B4D3E),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  elevation: 0,
                ),
                child: Text(
                  _localizations.update,
                  style: const TextStyle(
                    fontFamily: 'Literata',
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDiscountSection() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header
          Container(
            padding: EdgeInsets.all(_sectionPadding),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.green.withOpacity(0.1),
                  Colors.green.withOpacity(0.05),
                ],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: _sectionIconSize,
                  height: _sectionIconSize,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.green[600]!, Colors.green[500]!],
                    ),
                    borderRadius: BorderRadius.circular(_sectionBorderRadius),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.green.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.discount_rounded,
                    color: Colors.white,
                    size: _sectionIconInnerSize,
                  ),
                ),
                SizedBox(width: _sectionSpacing),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _localizations.discount,
                        style: TextStyle(
                          fontFamily: 'Literata',
                          fontWeight: FontWeight.w700,
                          fontSize: _sectionTitleSize,
                          color: const Color(0xFF1B4D3E),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Apply discount to this bill',
                        style: TextStyle(
                          fontFamily: 'Literata',
                          fontSize: _sectionSubtitleSize,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                if (_discountAmount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.green[200]!),
                    ),
                    child: Text(
                      '-₹${_discountAmount.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontFamily: 'Literata',
                        fontSize: 13,
                        color: Colors.green[700],
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          // Content
          Padding(
            padding: EdgeInsets.all(_sectionPadding),
            child: Column(
              children: [
                Row(
                  children: [
                    // Discount type toggle
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(_isCompactMobile ? 10 : 12),
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
                    const SizedBox(width: 14),
                    // Discount input
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[200]!),
                        ),
                        child: TextField(
                          controller: _discountController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          style: const TextStyle(
                            fontFamily: 'Literata',
                            fontSize: 15,
                          ),
                          onChanged: _updateDiscount,
                          decoration: InputDecoration(
                            hintText: _isPercentageDiscount
                                ? _localizations.enterPercent
                                : _localizations.enterAmount,
                            hintStyle: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 13,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 14,
                            ),
                            border: InputBorder.none,
                            suffixIcon: _discountController.text.isNotEmpty
                                ? IconButton(
                                    icon: Icon(
                                      Icons.clear_rounded,
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
                    ),
                  ],
                ),
                // Quick discount buttons
                const SizedBox(height: 14),
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
                  _buildBillSummaryCard(),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Bill summary card
  Widget _buildBillSummaryCard() {
    return Container(
      padding: EdgeInsets.all(_sectionPadding),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF1B4D3E).withOpacity(0.08),
            const Color(0xFF1B4D3E).withOpacity(0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1B4D3E).withOpacity(0.15)),
      ),
      child: Column(
        children: [
          _buildSummaryRow(
            _localizations.subtotal,
            '₹${_totalAmount.toStringAsFixed(2)}',
          ),
          if (_discountAmount > 0) ...[
            const SizedBox(height: 8),
            _buildSummaryRow(
              '${_localizations.discountWithPercent} (${_discountPercent.toStringAsFixed(1)}%)',
              '-₹${_discountAmount.toStringAsFixed(2)}',
              valueColor: Colors.green[700],
            ),
          ],
          // GST breakdown
          if (_taxBreakdown != null) ...[
            const SizedBox(height: 10),
            Divider(color: Colors.grey[300], height: 1),
            const SizedBox(height: 10),
            if (_gstMode == GstMode.includeGst)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
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
          const SizedBox(height: 12),
          Divider(color: Colors.grey[300], height: 1),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _localizations.finalTotal,
                style: const TextStyle(
                  fontFamily: 'Literata',
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1B4D3E),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [const Color(0xFF1B4D3E), const Color(0xFF2D6A4F)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '₹${_finalAmount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontFamily: 'Literata',
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Summary row helper
  Widget _buildSummaryRow(String label, String value, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Literata',
            fontSize: 13,
            color: Colors.grey[700],
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontFamily: 'Literata',
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: valueColor ?? Colors.black87,
          ),
        ),
      ],
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
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header
          Container(
            padding: EdgeInsets.all(_sectionPadding),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.orange.withOpacity(0.1),
                  Colors.orange.withOpacity(0.05),
                ],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: _sectionIconSize,
                  height: _sectionIconSize,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.orange[700]!, Colors.orange[500]!],
                    ),
                    borderRadius: BorderRadius.circular(_sectionBorderRadius),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.orange.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.receipt_long_rounded,
                    color: Colors.white,
                    size: _sectionIconInnerSize,
                  ),
                ),
                SizedBox(width: _sectionSpacing),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _localizations.gstCalculationMode,
                        style: TextStyle(
                          fontFamily: 'Literata',
                          fontWeight: FontWeight.w700,
                          fontSize: _sectionTitleSize,
                          color: const Color(0xFF1B4D3E),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Select tax calculation method',
                        style: TextStyle(
                          fontFamily: 'Literata',
                          fontSize: _sectionSubtitleSize,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                // Current mode indicator
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.orange[200]!),
                  ),
                  child: Text(
                    _gstMode == GstMode.noGst
                        ? 'No GST'
                        : _gstMode == GstMode.includeGst
                        ? 'Incl.'
                        : 'Excl.',
                    style: TextStyle(
                      fontFamily: 'Literata',
                      fontSize: 11,
                      color: Colors.orange[800],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Content
          Padding(
            padding: EdgeInsets.all(_sectionPadding),
            child: Wrap(
              spacing: _isCompactMobile ? 8 : 10,
              runSpacing: _isCompactMobile ? 8 : 10,
              children: [
                _buildGstModeChip(
                  label: _localizations.billWithoutGst,
                  mode: GstMode.noGst,
                  icon: Icons.money_off_rounded,
                ),
                _buildGstModeChip(
                  label: _localizations.includeGstInTotal,
                  mode: GstMode.includeGst,
                  icon: Icons.arrow_downward_rounded,
                ),
                _buildGstModeChip(
                  label: _localizations.excludeGstFromTotal,
                  mode: GstMode.excludeGst,
                  icon: Icons.arrow_upward_rounded,
                ),
              ],
            ),
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
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [Colors.orange[600]!, Colors.orange[500]!],
                )
              : null,
          color: isSelected ? null : Colors.grey[50],
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: isSelected ? Colors.transparent : Colors.grey[300]!,
            width: 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.orange.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withOpacity(0.2)
                    : Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                size: 14,
                color: isSelected ? Colors.white : Colors.grey[600],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Literata',
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? Colors.white : Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentSection() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Container(
            padding: EdgeInsets.all(_sectionPadding),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF1B4D3E).withOpacity(0.1),
                  const Color(0xFF1B4D3E).withOpacity(0.05),
                ],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: _sectionIconSize,
                  height: _sectionIconSize,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1B4D3E), Color(0xFF2D6A4F)],
                    ),
                    borderRadius: BorderRadius.circular(_sectionBorderRadius),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF1B4D3E).withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.payments_rounded,
                    color: Colors.white,
                    size: _sectionIconInnerSize,
                  ),
                ),
                SizedBox(width: _sectionSpacing),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _localizations.payment,
                        style: TextStyle(
                          fontFamily: 'Literata',
                          fontWeight: FontWeight.w700,
                          fontSize: _sectionTitleSize,
                          color: const Color(0xFF1B4D3E),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Select payment method',
                        style: TextStyle(
                          fontFamily: 'Literata',
                          fontSize: _sectionSubtitleSize,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                // Payment status badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: _isFullPayment
                        ? Colors.green[50]
                        : Colors.orange[50],
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _isFullPayment
                          ? Colors.green[200]!
                          : Colors.orange[200]!,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _isFullPayment
                            ? Icons.check_circle_rounded
                            : Icons.schedule_rounded,
                        size: 14,
                        color: _isFullPayment
                            ? Colors.green[700]
                            : Colors.orange[700],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _isFullPayment ? 'Full' : 'Partial',
                        style: TextStyle(
                          fontFamily: 'Literata',
                          fontSize: 11,
                          color: _isFullPayment
                              ? Colors.green[700]
                              : Colors.orange[700],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Content
          Padding(
            padding: EdgeInsets.all(_sectionPadding),
            child: Column(
              children: [
                // Payment type toggle
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildPaymentTypeButton(
                          label: _localizations.fullPayment,
                          isSelected: _isFullPayment,
                          icon: Icons.check_circle_outline_rounded,
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
                          icon: Icons.schedule_rounded,
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
                  const SizedBox(height: 18),
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
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[700],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.grey[50],
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey[200]!),
                              ),
                              child: TextField(
                                controller: _receivedAmountController,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                style: const TextStyle(
                                  fontFamily: 'Literata',
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF1B4D3E),
                                ),
                                decoration: InputDecoration(
                                  prefixText: '₹ ',
                                  prefixStyle: TextStyle(
                                    fontFamily: 'Literata',
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.grey[500],
                                  ),
                                  hintText: '0.00',
                                  hintStyle: TextStyle(
                                    fontFamily: 'Literata',
                                    color: Colors.grey[400],
                                  ),
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 14,
                                  ),
                                ),
                                onChanged: (value) {
                                  final parsed = double.tryParse(value) ?? 0.0;
                                  setState(() {
                                    // Cap received amount at final amount
                                    _receivedAmount = parsed.clamp(
                                      0.0,
                                      _finalAmount,
                                    );
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _localizations.pendingAmount,
                              style: TextStyle(
                                fontFamily: 'Literata',
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[700],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 15,
                              ),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: _pendingAmount > 0
                                      ? [
                                          Colors.orange[50]!,
                                          Colors.orange[100]!.withOpacity(0.5),
                                        ]
                                      : [
                                          Colors.green[50]!,
                                          Colors.green[100]!.withOpacity(0.5),
                                        ],
                                ),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: _pendingAmount > 0
                                      ? Colors.orange[300]!
                                      : Colors.green[300]!,
                                ),
                              ),
                              child: Text(
                                '₹ ${_pendingAmount.toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontFamily: 'Literata',
                                  fontSize: 18,
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
                  const SizedBox(height: 14),
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
                  const SizedBox(height: 14),
                  GestureDetector(
                    onTap: () {
                      if (_generateBillViaContact) {
                        // Focus the phone field
                      } else {
                        _showCustomerPicker();
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.red[50]!,
                            Colors.red[100]!.withOpacity(0.5),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.red[300]!),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: Colors.red[100],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.warning_amber_rounded,
                              size: 18,
                              color: Colors.red[700],
                            ),
                          ),
                          const SizedBox(width: 10),
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
                          Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 14,
                            color: Colors.red[700],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],

                // Summary for partial payment
                if (!_isFullPayment && _receivedAmount > 0) ...[
                  const SizedBox(height: 18),
                  Container(
                    padding: EdgeInsets.all(_sectionPadding),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF1B4D3E).withOpacity(0.08),
                          const Color(0xFF1B4D3E).withOpacity(0.04),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFF1B4D3E).withOpacity(0.15),
                      ),
                    ),
                    child: Column(
                      children: [
                        _buildPaymentSummaryRow(
                          _localizations.billTotal,
                          '₹${_finalAmount.toStringAsFixed(2)}',
                        ),
                        const SizedBox(height: 8),
                        _buildPaymentSummaryRow(
                          _localizations.received,
                          '₹${_receivedAmount.toStringAsFixed(2)}',
                          color: Colors.green[700],
                        ),
                        const SizedBox(height: 10),
                        Divider(color: Colors.grey[300], height: 1),
                        const SizedBox(height: 10),
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
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentTypeButton({
    required String label,
    required bool isSelected,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(
                  colors: [Color(0xFF1B4D3E), Color(0xFF2D6A4F)],
                )
              : null,
          color: isSelected ? null : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF1B4D3E).withOpacity(0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.white : Colors.grey[600],
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Literata',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : Colors.grey[600],
              ),
            ),
          ],
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
      setState(() => _isLoadingQuickStats = true);
      _loadQuickStats();
    }
  }

  /// Premium inline Quick Stats bar - replaces FAB for better UX
  Widget _buildQuickStatsInlineBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: GestureDetector(
        onTap: _toggleQuickStats,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: _showQuickStats
                  ? [const Color(0xFF1B4D3E), const Color(0xFF2D6A4F)]
                  : [Colors.white, Colors.white],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _showQuickStats
                  ? Colors.transparent
                  : const Color(0xFF1B4D3E).withOpacity(0.15),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: _showQuickStats
                    ? const Color(0xFF1B4D3E).withOpacity(0.25)
                    : Colors.black.withOpacity(0.06),
                blurRadius: _showQuickStats ? 16 : 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              // Icon with animated background
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: _showQuickStats
                        ? [Colors.white.withOpacity(0.2), Colors.white.withOpacity(0.1)]
                        : [const Color(0xFF1B4D3E), const Color(0xFF2D6A4F)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  _showQuickStats ? Icons.close_rounded : Icons.analytics_rounded,
                  color: _showQuickStats ? Colors.white : Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              // Text content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _showQuickStats ? 'Hide Quick Stats' : 'Quick Stats',
                      style: TextStyle(
                        fontFamily: 'Literata',
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: _showQuickStats ? Colors.white : const Color(0xFF1B4D3E),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _showQuickStats 
                          ? 'Tap to close panel'
                          : 'View invoices, products & more',
                      style: TextStyle(
                        fontFamily: 'Literata',
                        fontSize: 11,
                        color: _showQuickStats
                            ? Colors.white.withOpacity(0.8)
                            : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              // Stats preview chips (only when collapsed)
              if (!_showQuickStats && !_isLoadingQuickStats) ...[
                _buildMiniStatChip(
                  Icons.receipt_long_rounded,
                  '${_quickStatsData?.invoicesCount ?? 0}',
                  const Color(0xFF667eea),
                ),
                const SizedBox(width: 6),
                _buildMiniStatChip(
                  Icons.inventory_2_rounded,
                  '${_quickStatsData?.productsCount ?? 0}',
                  const Color(0xFFf093fb),
                ),
              ],
              if (!_showQuickStats && _isLoadingQuickStats)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Color(0xFF1B4D3E),
                  ),
                ),
              const SizedBox(width: 8),
              // Arrow indicator
              AnimatedRotation(
                turns: _showQuickStats ? 0.5 : 0,
                duration: const Duration(milliseconds: 300),
                child: Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: _showQuickStats ? Colors.white : const Color(0xFF1B4D3E),
                  size: 24,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Mini stat chip for the inline bar preview
  Widget _buildMiniStatChip(IconData icon, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Literata',
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  /// Premium glass-morphism Quick Stats Panel
  Widget _buildQuickStatsPremiumPanel() {
    return Positioned.fill(
      child: GestureDetector(
        onTap: _toggleQuickStats, // Tap outside to close
        child: Container(
          color: Colors.black.withOpacity(0.3),
          child: GestureDetector(
            onTap: () {}, // Prevent closing when tapping panel
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) {
                return Transform.translate(
                  offset: Offset(0, 30 * (1 - value)),
                  child: Opacity(opacity: value, child: child),
                );
              },
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 80, 16, 16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Premium Panel Card
                      ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Colors.white.withOpacity(0.95),
                                  Colors.white.withOpacity(0.88),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.5),
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF1B4D3E).withOpacity(0.15),
                                  blurRadius: 30,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Header
                                Row(
                                  children: [
                                    Container(
                                      width: 44,
                                      height: 44,
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          colors: [Color(0xFF1B4D3E), Color(0xFF2D6A4F)],
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color(0xFF1B4D3E).withOpacity(0.3),
                                            blurRadius: 8,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: const Icon(
                                        Icons.analytics_rounded,
                                        color: Colors.white,
                                        size: 22,
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Quick Stats',
                                            style: TextStyle(
                                              fontFamily: 'Literata',
                                              fontWeight: FontWeight.w800,
                                              fontSize: 18,
                                              color: Color(0xFF1B4D3E),
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            'Overview of your business',
                                            style: TextStyle(
                                              fontFamily: 'Literata',
                                              fontSize: 12,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    // Close button
                                    GestureDetector(
                                      onTap: _toggleQuickStats,
                                      child: Container(
                                        width: 36,
                                        height: 36,
                                        decoration: BoxDecoration(
                                          color: Colors.grey[100],
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: const Icon(
                                          Icons.close_rounded,
                                          color: Color(0xFF1B4D3E),
                                          size: 20,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 20),
                                // Stats Grid - 2x3 layout
                                _isLoadingQuickStats
                                    ? _buildQuickStatsPremiumShimmer()
                                    : _buildQuickStatsGrid(),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Premium 2x3 stats grid
  Widget _buildQuickStatsGrid() {
    final stats = [
      _QuickStatItem(
        icon: Icons.receipt_long_rounded,
        value: '${_quickStatsData?.invoicesCount ?? 0}',
        label: _localizations.invoices,
        color: const Color(0xFF667eea),
        gradient: [const Color(0xFF667eea), const Color(0xFF764ba2)],
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const BillsListPage()),
        ).then((_) => _loadQuickStats()),
      ),
      _QuickStatItem(
        icon: Icons.inventory_2_rounded,
        value: '${_quickStatsData?.productsCount ?? 0}',
        label: _localizations.products,
        color: const Color(0xFFf093fb),
        gradient: [const Color(0xFFf093fb), const Color(0xFFf5576c)],
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const EnhancedProductPage()),
        ).then((_) => _loadQuickStats()),
      ),
      _QuickStatItem(
        icon: Icons.local_shipping_rounded,
        value: '${_quickStatsData?.suppliersCount ?? 0}',
        label: _localizations.suppliers,
        color: const Color(0xFFFF6B6B),
        gradient: [const Color(0xFFFF6B6B), const Color(0xFFee5a24)],
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const EnhancedSupplierPage()),
        ).then((_) => _loadQuickStats()),
      ),
      _QuickStatItem(
        icon: Icons.business_rounded,
        value: '${_quickStatsData?.companiesCount ?? 0}',
        label: _localizations.companies,
        color: const Color(0xFF9C27B0),
        gradient: [const Color(0xFF9C27B0), const Color(0xFF7B1FA2)],
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const EnhancedCompanyPage()),
        ).then((_) => _loadQuickStats()),
      ),
      _QuickStatItem(
        icon: Icons.keyboard_return_rounded,
        value: '${_quickStatsData?.totalReturnedItems ?? 0}',
        label: 'P. Return',
        color: const Color(0xFFE65100),
        gradient: [const Color(0xFFE65100), const Color(0xFFFF8F00)],
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const PurchaseReturnScreen()),
        ).then((_) => _loadQuickStats()),
      ),
      _QuickStatItem(
        icon: Icons.celebration_rounded,
        value: 'Events',
        label: 'Events/Orders',
        color: const Color(0xFF6C63FF),
        gradient: [const Color(0xFF6C63FF), const Color(0xFF8B5CF6)],
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const EventOrderListPage()),
        ).then((_) => _loadQuickStats()),
      ),
      _QuickStatItem(
        icon: Icons.qr_code_rounded,
        value: 'Barcode',
        label: 'Barcode Mgmt',
        color: const Color(0xFF00897B),
        gradient: [const Color(0xFF00897B), const Color(0xFF26A69A)],
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const BarcodeManagementPage()),
        ).then((_) => _loadQuickStats()),
      ),
    ];

    return Column(
      children: [
        // First row
        Row(
          children: [
            Expanded(child: _buildPremiumStatCard(stats[0])),
            const SizedBox(width: 12),
            Expanded(child: _buildPremiumStatCard(stats[1])),
            const SizedBox(width: 12),
            Expanded(child: _buildPremiumStatCard(stats[2])),
          ],
        ),
        const SizedBox(height: 12),
        // Second row
        Row(
          children: [
            Expanded(child: _buildPremiumStatCard(stats[3])),
            const SizedBox(width: 12),
            Expanded(child: _buildPremiumStatCard(stats[4])),
            const SizedBox(width: 12),
            Expanded(child: _buildPremiumStatCard(stats[5])),
          ],
        ),
        const SizedBox(height: 12),
        // Third row - Barcode Management centered
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: MediaQuery.of(context).size.width * 0.35,
              child: _buildPremiumStatCard(stats[6]),
            ),
          ],
        ),
      ],
    );
  }

  /// Premium stat card with gradient and animation
  Widget _buildPremiumStatCard(_QuickStatItem stat) {
    return GestureDetector(
      onTap: stat.onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              stat.color.withOpacity(0.12),
              stat.color.withOpacity(0.04),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: stat.color.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            // Icon with gradient background
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: stat.gradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: stat.color.withOpacity(0.35),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Icon(stat.icon, color: Colors.white, size: 20),
            ),
            const SizedBox(height: 10),
            // Value
            Text(
              stat.value,
              style: const TextStyle(
                fontFamily: 'Literata',
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1B4D3E),
              ),
            ),
            const SizedBox(height: 2),
            // Label
            Text(
              stat.label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'Literata',
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Premium shimmer loading for stats grid
  Widget _buildQuickStatsPremiumShimmer() {
    return Column(
      children: [
        Row(
          children: List.generate(3, (index) => Expanded(
            child: Padding(
              padding: EdgeInsets.only(left: index == 0 ? 0 : 6, right: index == 2 ? 0 : 6),
              child: Container(
                height: 110,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          )),
        ),
        const SizedBox(height: 12),
        Row(
          children: List.generate(3, (index) => Expanded(
            child: Padding(
              padding: EdgeInsets.only(left: index == 0 ? 0 : 6, right: index == 2 ? 0 : 6),
              child: Container(
                height: 110,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          )),
        ),
      ],
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
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 25,
            offset: const Offset(0, -8),
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
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1B4D3E).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '$_totalQuantity ${_localizations.items.toLowerCase()}',
                        style: const TextStyle(
                          fontFamily: 'Literata',
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1B4D3E),
                        ),
                      ),
                    ),
                    if (!_isFullPayment && _pendingAmount > 0) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange[50],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.schedule_rounded,
                              size: 12,
                              color: Colors.orange[700],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Partial',
                              style: TextStyle(
                                fontFamily: 'Literata',
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: Colors.orange[700],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 6),
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
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1B4D3E),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.green[500]!, Colors.green[400]!],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '-${_discountPercent.toStringAsFixed(0)}%',
                          style: const TextStyle(
                            fontFamily: 'Literata',
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ] else
                  Text(
                    '₹${_finalAmount.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontFamily: 'Literata',
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1B4D3E),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                gradient: _isSavingBill || _billItems.isEmpty
                    ? null
                    : const LinearGradient(
                        colors: [Color(0xFF1B4D3E), Color(0xFF2D6A4F)],
                      ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: _isSavingBill || _billItems.isEmpty
                    ? null
                    : [
                        BoxShadow(
                          color: const Color(0xFF1B4D3E).withOpacity(0.35),
                          blurRadius: 12,
                          offset: const Offset(0, 5),
                        ),
                      ],
              ),
              child: ElevatedButton(
                onPressed: _isSavingBill || _billItems.isEmpty
                    ? null
                    : _saveBill,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  disabledBackgroundColor: Colors.grey[300],
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: _isSavingBill
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation(Colors.white),
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.check_circle_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _localizations.saveBill,
                            style: const TextStyle(
                              fontFamily: 'Literata',
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
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
  final Function(
    String productId,
    String productName,
    String companyName,
    int? batchLocalId,
    double sellingPrice,
    double purchasePrice,
    int quantity,
    int maxStock,
    double cgstPercent,
    double sgstPercent,
    String? hsnCode,
  )
  onBatchItemAdded;
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
      if (!productIdsWithBatches.contains(product.id) &&
          product.currentStock > 0) {
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
      ..sort(
        (a, b) =>
            a.productName.toLowerCase().compareTo(b.productName.toLowerCase()),
      );

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
                  item.allCompanyNames.any(
                    (c) => c.toLowerCase().contains(lowerQuery),
                  ) ||
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
      if (group.fallbackProduct != null &&
          billItem.productId == group.fallbackProduct!.id) {
        total += billItem.quantity;
      }
    }
    return total;
  }

  /// Show dialog to adjust quantity or remove a product
  void _showProductQuantityDialog({
    required String productId,
    required String productName,
    required String companyName,
    required int? batchLocalId,
    required double sellingPrice,
    required double purchasePrice,
    required int currentQty,
    required int maxStock,
    required double cgstPercent,
    required double sgstPercent,
    required String? hsnCode,
  }) {
    final qtyController = TextEditingController(text: currentQty.toString());
    String? errorText;
    
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          void validateQty() {
            final qty = int.tryParse(qtyController.text) ?? 0;
            setDialogState(() {
              if (qty < 0) {
                errorText = widget.localizations.pleaseEnterValidNumber;
              } else if (qty > maxStock) {
                errorText = '${widget.localizations.maxStock}: $maxStock';
              } else {
                errorText = null;
              }
            });
          }
          
          return AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1B4D3E).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.edit,
                    color: Color(0xFF1B4D3E),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        productName,
                        style: const TextStyle(
                          fontFamily: 'Literata',
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1A1A2E),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (companyName.isNotEmpty)
                        Text(
                          companyName,
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
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Price info
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Price: ₹${sellingPrice.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontFamily: 'Literata',
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1B4D3E),
                        ),
                      ),
                      Text(
                        '${widget.localizations.stock}: $maxStock',
                        style: TextStyle(
                          fontFamily: 'Literata',
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Quantity input with +/- buttons
                Row(
                  children: [
                    // Minus button
                    IconButton(
                      onPressed: () {
                        final current = int.tryParse(qtyController.text) ?? 0;
                        if (current > 0) {
                          qtyController.text = (current - 1).toString();
                          validateQty();
                        }
                      },
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.red[50],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.remove, color: Colors.red[700], size: 20),
                      ),
                    ),
                    // Quantity field
                    Expanded(
                      child: TextField(
                        controller: qtyController,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        onChanged: (_) => validateQty(),
                        style: const TextStyle(
                          fontFamily: 'Literata',
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                        decoration: InputDecoration(
                          errorText: errorText,
                          errorStyle: const TextStyle(fontSize: 11),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
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
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Plus button
                    IconButton(
                      onPressed: () {
                        final current = int.tryParse(qtyController.text) ?? 0;
                        if (current < maxStock) {
                          qtyController.text = (current + 1).toString();
                          validateQty();
                        }
                      },
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.green[50],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.add, color: Colors.green[700], size: 20),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              // Remove button
              TextButton.icon(
                onPressed: () {
                  final uniqueKey = batchLocalId != null
                      ? '${productId}_batch_$batchLocalId'
                      : productId;
                  widget.onItemRemoved(uniqueKey);
                  setState(() {});
                  Navigator.pop(ctx);
                  widget.showSnackbar(
                    '$productName ${widget.localizations.delete}d',
                    isError: false,
                  );
                },
                icon: Icon(Icons.delete_outline, color: Colors.red[700], size: 20),
                label: Text(
                  widget.localizations.delete,
                  style: TextStyle(
                    fontFamily: 'Literata',
                    color: Colors.red[700],
                  ),
                ),
              ),
              const Spacer(),
              // Cancel button
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(
                  widget.localizations.cancel,
                  style: TextStyle(
                    fontFamily: 'Literata',
                    color: Colors.grey[600],
                  ),
                ),
              ),
              // Update button
              ElevatedButton(
                onPressed: errorText == null
                    ? () {
                        final qty = int.tryParse(qtyController.text) ?? 0;
                        if (qty == 0) {
                          // Remove item
                          final uniqueKey = batchLocalId != null
                              ? '${productId}_batch_$batchLocalId'
                              : productId;
                          widget.onItemRemoved(uniqueKey);
                          setState(() {});
                          Navigator.pop(ctx);
                          widget.showSnackbar(
                            '$productName ${widget.localizations.delete}d',
                            isError: false,
                          );
                        } else {
                          // Update quantity
                          widget.onBatchItemAdded(
                            productId,
                            productName,
                            companyName,
                            batchLocalId,
                            sellingPrice,
                            purchasePrice,
                            qty,
                            maxStock,
                            cgstPercent,
                            sgstPercent,
                            hsnCode,
                          );
                          setState(() {});
                          Navigator.pop(ctx);
                          widget.showSnackbar(
                            '$productName ${widget.localizations.update}d',
                            isError: false,
                          );
                        }
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1B4D3E),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  widget.localizations.update,
                  style: const TextStyle(
                    fontFamily: 'Literata',
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showBatchSelection(_GroupedBillingProduct group) {
    // Fallback product with no batches — toggle add/remove
    if (group.batches.isEmpty && group.fallbackProduct != null) {
      final product = group.fallbackProduct!;
      final existingQty = widget.billItems
          .where((item) => item.productId == product.id)
          .fold<int>(0, (s, item) => s + item.quantity);

      // If already in bill, show quantity adjustment dialog
      if (existingQty > 0) {
        _showProductQuantityDialog(
          productId: product.id,
          productName: product.name,
          companyName: product.companyName,
          batchLocalId: null,
          sellingPrice: product.salesPrice,
          purchasePrice: product.purchasePrice,
          currentQty: existingQty,
          maxStock: product.currentStock,
          cgstPercent: group.cgstPercent,
          sgstPercent: group.sgstPercent,
          hsnCode: group.hsnCode,
        );
        return;
      }

      // Not in bill — add with quantity 1
      if (existingQty < product.currentStock) {
        widget.onBatchItemAdded(
          product.id,
          product.name,
          product.companyName,
          null,
          product.salesPrice,
          product.purchasePrice,
          1,
          product.currentStock,
          group.cgstPercent,
          group.sgstPercent,
          group.hsnCode,
        );
        setState(() {});
        widget.showSnackbar(
          '${widget.localizations.added}: ${product.name}',
          isError: false,
        );
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
        cgstPercent: group.cgstPercent,
        sgstPercent: group.sgstPercent,
        hsnCode: group.hsnCode,
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
          widget.showSnackbar(
            '${widget.localizations.added}: ${batch.productName}',
            isError: false,
          );
        },
        onItemRemoved: (uniqueKey) {
          widget.onItemRemoved(uniqueKey);
          setState(() {});
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
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
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
                                          if (group
                                              .allCompanyNames
                                              .isNotEmpty) ...[
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
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 6,
                                                        vertical: 2,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color: Colors.blue
                                                        .withValues(alpha: 0.1),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          4,
                                                        ),
                                                  ),
                                                  child: Text(
                                                    '${group.batches.length} ${widget.localizations.variants}',
                                                    style: TextStyle(
                                                      fontFamily: 'Literata',
                                                      fontSize: 9,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      color: Colors.blue[700],
                                                    ),
                                                  ),
                                                ),
                                              ],
                                              const SizedBox(width: 6),
                                              // Total stock badge
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 6,
                                                      vertical: 2,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: group.totalStock > 10
                                                      ? Colors.green[50]
                                                      : group.totalStock > 0
                                                      ? Colors.orange[50]
                                                      : Colors.red[50],
                                                  borderRadius:
                                                      BorderRadius.circular(4),
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
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
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
                                              : const Color(
                                                  0xFF1B4D3E,
                                                ).withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
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
                      border: Border.all(
                        color: const Color(0xFF1B4D3E),
                        width: 1.5,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      color: const Color(0xFF1B4D3E).withOpacity(0.05),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.person_add,
                          color: Color(0xFF1B4D3E),
                          size: 20,
                        ),
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
            if (widget.onAddNew != null) const SizedBox(height: 12),
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
                                    if ((customer['pendingBalance'] as num?)
                                                ?.toDouble() !=
                                            null &&
                                        (customer['pendingBalance'] as num)
                                                .toDouble() >
                                            0)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.red[50],
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
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
  final List<PurchaseBatchEntity>
  batches; // All batches for this product name (FIFO sorted)
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
    if (names.isEmpty &&
        fallbackProduct != null &&
        fallbackProduct!.companyName.isNotEmpty) {
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
  final Function(String uniqueKey) onItemRemoved;
  final double cgstPercent;
  final double sgstPercent;
  final String? hsnCode;

  const _BatchSelectionSheet({
    required this.productName,
    this.productCode = 0,
    required this.batches,
    required this.localizations,
    required this.existingBillItems,
    required this.onBatchSelected,
    required this.onItemRemoved,
    this.cgstPercent = 0.0,
    this.sgstPercent = 0.0,
    this.hsnCode,
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
              DateFormat(
                'dd MMM yyyy',
              ).format(batch.purchaseDate).toLowerCase().contains(lowerQuery) ||
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
        _qtyError =
            '${widget.localizations.quantityExceedsStock} ($maxAvailable)';
      } else {
        _qtyError = null;
      }
    });
  }

  /// Show dialog to adjust quantity or remove a batch item
  void _showBatchQuantityDialog({
    required PurchaseBatchEntity batch,
    required int existingQty,
  }) {
    final qtyController = TextEditingController(text: existingQty.toString());
    final maxStock = batch.quantityRemaining;
    String? errorText;
    
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          void validateQty() {
            final qty = int.tryParse(qtyController.text) ?? 0;
            setDialogState(() {
              if (qty < 0) {
                errorText = widget.localizations.pleaseEnterValidNumber;
              } else if (qty > maxStock) {
                errorText = '${widget.localizations.maxStock}: $maxStock';
              } else {
                errorText = null;
              }
            });
          }
          
          return AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1B4D3E).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.edit,
                    color: Color(0xFF1B4D3E),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        batch.productName,
                        style: const TextStyle(
                          fontFamily: 'Literata',
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1A1A2E),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (batch.companyName.isNotEmpty)
                        Text(
                          batch.companyName,
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
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Price info
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Price: ₹${batch.sellingPrice.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontFamily: 'Literata',
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1B4D3E),
                        ),
                      ),
                      Text(
                        '${widget.localizations.stock}: $maxStock',
                        style: TextStyle(
                          fontFamily: 'Literata',
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Quantity input with +/- buttons
                Row(
                  children: [
                    // Minus button
                    IconButton(
                      onPressed: () {
                        final current = int.tryParse(qtyController.text) ?? 0;
                        if (current > 0) {
                          qtyController.text = (current - 1).toString();
                          validateQty();
                        }
                      },
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.red[50],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.remove, color: Colors.red[700], size: 20),
                      ),
                    ),
                    // Quantity field
                    Expanded(
                      child: TextField(
                        controller: qtyController,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        onChanged: (_) => validateQty(),
                        style: const TextStyle(
                          fontFamily: 'Literata',
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                        decoration: InputDecoration(
                          errorText: errorText,
                          errorStyle: const TextStyle(fontSize: 11),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
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
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Plus button
                    IconButton(
                      onPressed: () {
                        final current = int.tryParse(qtyController.text) ?? 0;
                        if (current < maxStock) {
                          qtyController.text = (current + 1).toString();
                          validateQty();
                        }
                      },
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.green[50],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.add, color: Colors.green[700], size: 20),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              // Remove button
              TextButton.icon(
                onPressed: () {
                  final uniqueKey = '${batch.productId}_batch_${batch.id}';
                  widget.onItemRemoved(uniqueKey);
                  setState(() {});
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        '${batch.productName} ${widget.localizations.delete}d',
                        style: const TextStyle(fontFamily: 'Literata'),
                      ),
                      backgroundColor: Colors.green[600],
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                icon: Icon(Icons.delete_outline, color: Colors.red[700], size: 20),
                label: Text(
                  widget.localizations.delete,
                  style: TextStyle(
                    fontFamily: 'Literata',
                    color: Colors.red[700],
                  ),
                ),
              ),
              const Spacer(),
              // Cancel button
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(
                  widget.localizations.cancel,
                  style: TextStyle(
                    fontFamily: 'Literata',
                    color: Colors.grey[600],
                  ),
                ),
              ),
              // Update button
              ElevatedButton(
                onPressed: errorText == null
                    ? () {
                        final qty = int.tryParse(qtyController.text) ?? 0;
                        if (qty == 0) {
                          // Remove item
                          final uniqueKey = '${batch.productId}_batch_${batch.id}';
                          widget.onItemRemoved(uniqueKey);
                          setState(() {});
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                '${batch.productName} ${widget.localizations.delete}d',
                                style: const TextStyle(fontFamily: 'Literata'),
                              ),
                              backgroundColor: Colors.green[600],
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        } else {
                          // Update quantity
                          widget.onBatchSelected(batch, qty);
                          setState(() {});
                          Navigator.pop(ctx);
                        }
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1B4D3E),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  widget.localizations.update,
                  style: const TextStyle(
                    fontFamily: 'Literata',
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
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
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 1,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFF1B4D3E,
                                  ).withValues(alpha: 0.1),
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
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
                          Icon(
                            Icons.search_off,
                            size: 48,
                            color: Colors.grey[400],
                          ),
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
                        final isOldest =
                            widget.batches.isNotEmpty &&
                            batch.id == widget.batches.first.id;
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
                                // If already in bill, show edit dialog
                                if (alreadyInBill) {
                                  _showBatchQuantityDialog(
                                    batch: batch,
                                    existingQty: existingQty,
                                  );
                                  return;
                                }
                                // Add item directly with quantity 1
                                final maxAvailable =
                                    batch.quantityRemaining - existingQty;
                                if (maxAvailable > 0) {
                                  widget.onBatchSelected(batch, existingQty + 1);
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        '${widget.localizations.quantityExceedsStock} (0)',
                                        style: const TextStyle(
                                          fontFamily: 'Literata',
                                        ),
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
                                            color: const Color(
                                              0xFF1B4D3E,
                                            ).withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: Center(
                                            child: Text(
                                              batch.companyName.isNotEmpty
                                                  ? batch.companyName[0]
                                                        .toUpperCase()
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
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
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
                                          crossAxisAlignment:
                                              CrossAxisAlignment.end,
                                          children: [
                                            if (isOldest)
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 6,
                                                      vertical: 2,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: Colors.amber[50],
                                                  borderRadius:
                                                      BorderRadius.circular(4),
                                                  border: Border.all(
                                                    color: Colors.amber[300]!,
                                                  ),
                                                ),
                                                child: Text(
                                                  widget
                                                      .localizations
                                                      .fifoRecommended,
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
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 6,
                                                      vertical: 2,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: Colors.green[50],
                                                  borderRadius:
                                                      BorderRadius.circular(4),
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
                                          value:
                                              '₹${batch.sellingPrice.toStringAsFixed(0)}',
                                          color: const Color(0xFF1B4D3E),
                                        ),
                                        const SizedBox(width: 8),
                                        // Cost price
                                        _buildBatchInfoChip(
                                          label: widget.localizations.costPrice,
                                          value:
                                              '₹${batch.purchasePrice.toStringAsFixed(0)}',
                                          color: Colors.grey[700]!,
                                        ),
                                        const SizedBox(width: 8),
                                        // Stock
                                        _buildBatchInfoChip(
                                          label: widget.localizations.stock,
                                          value:
                                              '${batch.quantityRemaining} ${batch.unit}',
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
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                        child: Column(
                                          children: [
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: TextField(
                                                    controller: _qtyController,
                                                    keyboardType:
                                                        TextInputType.number,
                                                    onChanged: (_) =>
                                                        _validateQuantity(),
                                                    style: const TextStyle(
                                                      fontFamily: 'Literata',
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                    decoration: InputDecoration(
                                                      labelText: widget
                                                          .localizations
                                                          .enterQuantity,
                                                      labelStyle: TextStyle(
                                                        fontSize: 12,
                                                        color: Colors.grey[600],
                                                      ),
                                                      errorText: _qtyError,
                                                      errorStyle:
                                                          const TextStyle(
                                                            fontSize: 10,
                                                          ),
                                                      contentPadding:
                                                          const EdgeInsets.symmetric(
                                                            horizontal: 12,
                                                            vertical: 10,
                                                          ),
                                                      border: OutlineInputBorder(
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              8,
                                                            ),
                                                        borderSide: BorderSide(
                                                          color:
                                                              Colors.grey[300]!,
                                                        ),
                                                      ),
                                                      focusedBorder:
                                                          OutlineInputBorder(
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  8,
                                                                ),
                                                            borderSide:
                                                                const BorderSide(
                                                                  color: Color(
                                                                    0xFF1B4D3E,
                                                                  ),
                                                                  width: 1.5,
                                                                ),
                                                          ),
                                                      filled: true,
                                                      fillColor: Colors.white,
                                                      suffixText:
                                                          '/ ${batch.quantityRemaining - existingQty}',
                                                      suffixStyle: TextStyle(
                                                        fontSize: 12,
                                                        color: Colors.grey[500],
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 12),
                                                ElevatedButton.icon(
                                                  onPressed:
                                                      _qtyError == null &&
                                                          _qtyController
                                                              .text
                                                              .isNotEmpty &&
                                                          (int.tryParse(
                                                                    _qtyController
                                                                        .text,
                                                                  ) ??
                                                                  0) >
                                                              0
                                                      ? () {
                                                          final qty = int.parse(
                                                            _qtyController.text,
                                                          );
                                                          widget
                                                              .onBatchSelected(
                                                                batch,
                                                                existingQty +
                                                                    qty,
                                                              );
                                                        }
                                                      : null,
                                                  icon: const Icon(
                                                    Icons.add_shopping_cart,
                                                    size: 18,
                                                  ),
                                                  label: Text(
                                                    widget
                                                        .localizations
                                                        .addToBill,
                                                    style: const TextStyle(
                                                      fontFamily: 'Literata',
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      fontSize: 13,
                                                    ),
                                                  ),
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor:
                                                        const Color(0xFF1B4D3E),
                                                    foregroundColor:
                                                        Colors.white,
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 16,
                                                          vertical: 12,
                                                        ),
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            10,
                                                          ),
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

/// Data class for Quick Stat items
class _QuickStatItem {
  final IconData icon;
  final String value;
  final String label;
  final Color color;
  final List<Color> gradient;
  final VoidCallback? onTap;

  const _QuickStatItem({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
    required this.gradient,
    this.onTap,
  });
}

// Sticky Header Delegate for Billing Page
class _BillingHeaderDelegate extends SliverPersistentHeaderDelegate {
  final double minHeight;
  final double maxHeight;
  final int billItemsCount;
  final AppLocalizations localizations;
  final VoidCallback onSettingsTap;
  final VoidCallback onReportSettingsTap;
  final bool isCompact;

  _BillingHeaderDelegate({
    required this.minHeight,
    required this.maxHeight,
    required this.billItemsCount,
    required this.localizations,
    required this.onSettingsTap,
    required this.onReportSettingsTap,
    this.isCompact = false,
  });

  @override
  double get minExtent => minHeight;

  @override
  double get maxExtent => maxHeight;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final progress = (shrinkOffset / (maxExtent - minExtent)).clamp(0.0, 1.0);
    final isCollapsed = progress > 0.5;
    final iconSize = isCompact ? 40.0 : 48.0;
    final titleSize = isCompact ? (isCollapsed ? 16.0 : 20.0) : (isCollapsed ? 20.0 : 24.0);
    final horizontalPadding = isCompact ? 14.0 : 20.0;
    final actionIconSize = isCompact ? 36.0 : 44.0;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF1B4D3E),
            const Color(0xFF2D6A4F),
            const Color(0xFF1B4D3E).withOpacity(0.9),
          ],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(isCompact ? 20 : 28),
          bottomRight: Radius.circular(isCompact ? 20 : 28),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1B4D3E).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(isCompact ? 20 : 28),
          bottomRight: Radius.circular(isCompact ? 20 : 28),
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      // Receipt Icon
                      Container(
                        width: iconSize,
                        height: iconSize,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(isCompact ? 10 : 14),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.2),
                          ),
                        ),
                        child: Icon(
                          Icons.receipt_long_rounded,
                          color: Colors.white,
                          size: isCompact ? 20 : 24,
                        ),
                      ),
                      SizedBox(width: isCompact ? 12 : 16),
                      // Title
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              localizations.createBill,
                              style: TextStyle(
                                fontSize: titleSize,
                                fontWeight: FontWeight.w800,
                                fontFamily: 'Literata',
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                            if (!isCollapsed) ...[
                              const SizedBox(height: 4),
                              Text(
                                'Create and print invoices',
                                style: TextStyle(
                                  fontSize: isCompact ? 11 : 13,
                                  fontFamily: 'Literata',
                                  color: Colors.white.withOpacity(0.8),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      // Items badge
                      if (billItemsCount > 0)
                        Container(
                          margin: EdgeInsets.only(right: isCompact ? 8 : 12),
                          padding: EdgeInsets.symmetric(
                            horizontal: isCompact ? 8 : 12,
                            vertical: isCompact ? 4 : 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.shopping_cart_rounded,
                                color: const Color(0xFF1B4D3E),
                                size: isCompact ? 14 : 16,
                              ),
                              SizedBox(width: isCompact ? 4 : 6),
                              Text(
                                '$billItemsCount',
                                style: TextStyle(
                                  color: const Color(0xFF1B4D3E),
                                  fontSize: isCompact ? 12 : 14,
                                  fontWeight: FontWeight.w700,
                                  fontFamily: 'Literata',
                                ),
                              ),
                            ],
                          ),
                        ),
                      // Settings Menu Button
                      PopupMenuButton<String>(
                        icon: Container(
                          width: actionIconSize,
                          height: actionIconSize,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(isCompact ? 10 : 14),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.2),
                            ),
                          ),
                          child: Icon(
                            Icons.more_vert_rounded,
                            color: Colors.white,
                            size: isCompact ? 18 : 22,
                          ),
                        ),
                        offset: Offset(0, isCompact ? 40 : 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 8,
                        color: Colors.white,
                        onSelected: (value) {
                          if (value == 'settings') {
                            onSettingsTap();
                          } else if (value == 'report_settings') {
                            onReportSettingsTap();
                          }
                        },
                        itemBuilder: (context) => [
                          PopupMenuItem<String>(
                            value: 'settings',
                            child: Row(
                              children: [
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1B4D3E).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(
                                    Icons.settings_rounded,
                                    color: Color(0xFF1B4D3E),
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  localizations.settings,
                                  style: const TextStyle(
                                    fontFamily: 'Literata',
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          PopupMenuItem<String>(
                            value: 'report_settings',
                            child: Row(
                              children: [
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF2196F3).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(
                                    Icons.view_column_rounded,
                                    color: Color(0xFF2196F3),
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Text(
                                  'Print Column Settings',
                                  style: TextStyle(
                                    fontFamily: 'Literata',
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(_BillingHeaderDelegate oldDelegate) {
    return maxHeight != oldDelegate.maxHeight ||
        minHeight != oldDelegate.minHeight ||
        billItemsCount != oldDelegate.billItemsCount;
  }
}

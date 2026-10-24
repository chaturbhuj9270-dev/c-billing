import 'dart:async';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:c_billing/core/services/customer_transaction_service.dart';
import 'package:c_billing/core/services/dashboard_refresh_service.dart';
import 'package:c_billing/features/billing/data/repositories/firebase_bill_repository.dart';
import 'package:c_billing/features/billing/domain/entities/bill.dart';
import 'package:c_billing/features/billing/domain/entities/bill_item.dart';
import 'package:c_billing/features/billing/domain/entities/bill_extra_charge.dart';
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
import 'package:c_billing/core/services/barcode_service.dart';
import 'package:c_billing/core/ui/desktop_canvas.dart';
import 'package:c_billing/features/employee/data/repositories/employee_repository.dart';
import 'package:c_billing/features/inventory_management/offline/controllers/purchase_batch_offline_controller.dart';
import 'package:c_billing/features/inventory_management/offline/entities/purchase_batch_entity.dart';
import 'package:c_billing/features/customer/offline/controllers/customer_offline_controller.dart';
import 'package:c_billing/features/customer/offline/entities/customer_entity.dart';
import 'package:c_billing/features/event_order/domain/entities/event_order.dart';
import 'package:c_billing/features/event_order/offline/controllers/event_order_offline_controller.dart';
import 'package:c_billing/features/event_order/offline/entities/event_order_entity.dart';
import 'package:c_billing/features/billing/domain/entities/bill_tax_settings.dart';
import 'package:c_billing/features/dashboard/data/repositories/dashboard_offline_repository.dart';
import 'package:c_billing/features/billing/presentation/pages/bills_list_page.dart';
import 'package:c_billing/features/inventory_management/presentation/pages/enhanced_product_page.dart';
import 'package:c_billing/features/supplier/presentation/pages/enhanced_supplier_page.dart';
import 'package:c_billing/features/company/presentation/pages/enhanced_company_page.dart';
import 'package:c_billing/features/purchase_return/presentation/pages/purchase_return_screen.dart';
import 'package:c_billing/features/event_order/presentation/pages/event_order_list_page.dart';
import 'package:c_billing/features/dashboard/data/models/dashboard_data.dart';
import 'package:c_billing/common_widgets/file_preview_page.dart';
import 'package:c_billing/features/inventory_management/presentation/pages/barcode_generator_page.dart';
import 'package:c_billing/features/customer/presentation/pages/enhanced_customer_page.dart';
import 'package:c_billing/features/quotation/presentation/pages/quotation_list_page.dart';
import 'package:c_billing/features/dashboard/presentation/pages/web_shell.dart';
import 'package:c_billing/features/billing/presentation/widgets/barcode_scanner_sheet.dart';
import 'package:c_billing/features/billing/presentation/widgets/billing_add_items_widgets.dart';
import 'package:c_billing/features/customer/offline/controllers/customer_transaction_offline_controller.dart';
import 'package:c_billing/features/customer/domain/entities/customer_transaction.dart';
import 'package:c_billing/features/billing/offline/held_bill_store.dart';
import 'package:c_billing/core/ui/glassy_toast.dart';
import 'package:c_billing/common_widgets/app_top_bar.dart';
import 'package:c_billing/core/theme/app_theme.dart';
import 'package:c_billing/common_widgets/app_pill_button.dart';
import 'package:c_billing/common_widgets/glass_bottom_sheet.dart';

class BillingPage extends StatefulWidget {
  final bool isEmbedded;

  const BillingPage({super.key, this.isEmbedded = false});

  @override
  State<BillingPage> createState() => _BillingPageState();
}

class _BillingPageState extends State<BillingPage> {
  late CustomerTransactionService _customerTransactionService;
  late FirebaseFirestore _firestore;
  late ShopRepository _shopRepository;
  late FirebaseCustomerRepository _customerRepository;
  late AppLocalizations _localizations;

  // Real-time local stream subscriptions
  StreamSubscription<List<ProductEntity>>? _productStreamSubscription;
  StreamSubscription<List<CustomerEntity>>? _customerStreamSubscription;
  StreamSubscription<List<EventOrderEntity>>? _eventPendingSubscription;
  StreamSubscription<void>? _billSettingsSubscription;
  List<CustomerEntity> _watchedCustomers = [];
  Map<String, double> _eventPendingByCustomer = {};

  // Printing services
  final _printerService = PosPrinterService();
  final _pdfService = PdfBillService();

  final _customerNameController = TextEditingController();
  final _customerContactController = TextEditingController();
  final _notesController = TextEditingController();
  final _discountController = TextEditingController();
  final _receivedAmountController = TextEditingController();

  final List<BillItem> _billItems = [];
  List<Product> _products = [];
  List<Product> _allProducts =
      []; // All products including zero-stock (for code lookup)
  bool _isLoading = false;
  bool _isSavingBill = false;

  // Discount state
  bool _isPercentageDiscount = true;
  double _discountValue = 0.0;

  // Extra charges (labour / service / etc.)
  bool _extraChargesEnabled = false;
  final List<_ExtraChargeDraft> _extraChargeDrafts = [];

  // Payment state
  double _receivedAmount = 0.0;
  bool _isFullPayment = true;
  PaymentMode _billPaymentMode = PaymentMode.cash;

  Map<String, dynamic>? _selectedCustomer;
  List<Map<String, dynamic>> _customers = [];

  // Quick add by index number / barcode (USB wedge scanners type into this field)
  final _indexNoController = TextEditingController();
  final _indexNoFocusNode = FocusNode();
  bool _addItemsSearchHovered = false;
  Timer? _debounceTimer;
  Map<int, Product> _productByIndexNo = {};
  Map<String, Product> _productByBarcode = {};
  bool _isResolvingScan = false;

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
  bool _enableEmployeeToken = false;
  bool _enableHoldBill = false;
  int _heldBillCount = 0;
  final _employeeRepo = EmployeeRepository();
  // Per-line employee token inputs (keyed by bill item productId).
  final Map<String, TextEditingController> _itemTokenControllers = {};
  final Map<String, FocusNode> _itemTokenFocusNodes = {};
  final Map<String, String?> _itemTokenNames = {};

  // Quick Stats data
  final DashboardOfflineRepository _dashboardRepo =
      DashboardOfflineRepository.instance;
  DashboardData? _quickStatsData;
  bool _isLoadingQuickStats = false;
  bool _showQuickStats = false;

  // GST/Tax settings
  BillTaxSettings _taxSettings = BillTaxSettings.defaultSettings;
  GstMode _gstMode = GstMode.noGst;

  // Product master tax (CGST/SGST saved at purchase) present on any line item
  bool get _hasItemLevelTax =>
      _billItems.any((i) => i.cgstPercent > 0 || i.sgstPercent > 0);

  // GST / Other charges only when turned on in Bill Settings.
  bool get _showGstOnBill => _taxSettings.gstFeatureEnabled;
  bool get _showExtraChargesOnBill => _taxSettings.enableExtraCharges;

  // Prefer per-product rates from purchase; fall back to flat Bill Settings rates.
  // Never apply GST unless Bill Settings has GST enabled.
  TaxBreakdown? get _taxBreakdown {
    if (!_showGstOnBill || _gstMode == GstMode.noGst) return null;

    if (_hasItemLevelTax) {
      final breakdown = BillTaxSettings.fromItemTaxes(
        items: _billItems
            .map(
              (i) => (
                subtotal: i.subtotal,
                cgstPercent: i.cgstPercent,
                sgstPercent: i.sgstPercent,
              ),
            )
            .toList(),
        discountAmount: _discountAmount,
        gstMode: _gstMode,
      );
      return breakdown.hasAnyTax ? breakdown : null;
    }

    if (!_taxSettings.hasAnyTaxEnabled) return null;
    return _taxSettings.calculateTax(
      subtotal: _totalAmount,
      gstMode: _gstMode,
    );
  }

  // When a purchased product carries CGST/SGST, auto-enable sale tax only if GST is on in Bill Settings
  void _ensureGstModeForProductTax({
    required double cgstPercent,
    required double sgstPercent,
  }) {
    if (!_showGstOnBill) return;
    if (_gstMode != GstMode.noGst) return;
    if (cgstPercent <= 0 && sgstPercent <= 0) return;
    _gstMode = _taxSettings.defaultIncludeTax
        ? GstMode.includeGst
        : GstMode.excludeGst;
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

    // Listen for customer phone number changes
    _customerContactController.addListener(_onPhoneNumberChanged);
    _indexNoFocusNode.addListener(_onAddItemsFocusChanged);

    // Setup real-time local streams for instant data updates
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
    if (!mounted) return;
    final clearExtra = !taxSettings.enableExtraCharges;
    final tokenOn = prefs.getBool('bill_enable_employee_token') ?? false;
    setState(() {
      _showCustomerOnBill =
          prefs.getBool('bill_show_customer_details') ?? true;
      _generateBillViaContact =
          prefs.getBool('bill_generate_via_contact') ?? false;
      _enableEmployeeToken = tokenOn;
      _enableHoldBill = prefs.getBool('bill_enable_hold') ?? false;
      _taxSettings = taxSettings;
      _gstMode = taxSettings.gstFeatureEnabled
          ? taxSettings.defaultGstMode
          : GstMode.noGst;
      if (clearExtra) {
        _extraChargesEnabled = false;
      }
      if (!tokenOn && _billItems.isNotEmpty) {
        for (var i = 0; i < _billItems.length; i++) {
          if (_billItems[i].employeeToken != null) {
            _billItems[i] = _billItems[i].copyWith(employeeToken: null);
          }
        }
        _itemTokenNames.clear();
      }
    });
    if (clearExtra) {
      _disposeExtraChargeDrafts();
    }
    if (!tokenOn) {
      _disposeItemTokenInputs();
    }
    await _refreshHeldBillCount();
  }

  Future<void> _refreshHeldBillCount() async {
    final n = await HeldBillStore.count();
    if (mounted) setState(() => _heldBillCount = n);
  }

  TextEditingController _tokenControllerFor(String productId, int? token) {
    final existing = _itemTokenControllers[productId];
    if (existing != null) return existing;
    final ctrl = TextEditingController(
      text: (token != null && token > 0) ? '$token' : '',
    );
    _itemTokenControllers[productId] = ctrl;
    return ctrl;
  }

  FocusNode _tokenFocusFor(String productId) {
    return _itemTokenFocusNodes.putIfAbsent(productId, FocusNode.new);
  }

  void _disposeItemTokenInputs([String? productId]) {
    if (productId != null) {
      _itemTokenControllers.remove(productId)?.dispose();
      _itemTokenFocusNodes.remove(productId)?.dispose();
      _itemTokenNames.remove(productId);
      return;
    }
    for (final c in _itemTokenControllers.values) {
      c.dispose();
    }
    for (final f in _itemTokenFocusNodes.values) {
      f.dispose();
    }
    _itemTokenControllers.clear();
    _itemTokenFocusNodes.clear();
    _itemTokenNames.clear();
  }

  Future<void> _onItemTokenChanged(int index, String productId) async {
    if (index < 0 || index >= _billItems.length) return;
    final raw = _itemTokenControllers[productId]?.text.trim() ?? '';
    if (raw.isEmpty) {
      setState(() {
        _billItems[index] = _billItems[index].copyWith(
          clearEmployeeToken: true,
        );
        _itemTokenNames[productId] = null;
      });
      return;
    }
    final token = int.tryParse(raw);
    if (token == null || token <= 0) {
      setState(() => _itemTokenNames[productId] = null);
      return;
    }
    setState(() {
      _billItems[index] = _billItems[index].copyWith(employeeToken: token);
    });
    final emp = await _employeeRepo.findByToken(token);
    if (!mounted) return;
    if (_itemTokenControllers[productId]?.text.trim() != raw) return;
    setState(() => _itemTokenNames[productId] = emp?.displayName);
  }

  // After adding a product: focus that line's token if empty (only when enabled in Bill Settings).
  void _focusAfterProductAdded([String? productId]) {
    final id =
        productId ??
        (_billItems.isNotEmpty ? _billItems.last.productId : null);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || id == null) return;
      if (!_enableEmployeeToken) {
        _indexNoFocusNode.requestFocus();
        return;
      }
      BillItem? item;
      for (final i in _billItems) {
        if (i.productId == id) {
          item = i;
          break;
        }
      }
      if (item == null ||
          item.employeeToken == null ||
          item.employeeToken! <= 0) {
        _tokenFocusFor(id).requestFocus();
      } else {
        _indexNoFocusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _productStreamSubscription?.cancel();
    _customerStreamSubscription?.cancel();
    _eventPendingSubscription?.cancel();
    _billSettingsSubscription?.cancel();
    LanguageService.instance.removeListener(_onLanguageChanged);
    _debounceTimer?.cancel();
    _phoneSearchDebounceTimer?.cancel();
    _customerContactController.removeListener(_onPhoneNumberChanged);
    _indexNoFocusNode.removeListener(_onAddItemsFocusChanged);
    _disposeItemTokenInputs();
    _indexNoController.dispose();
    _indexNoFocusNode.dispose();
    _customerNameController.dispose();
    _customerContactController.dispose();
    _notesController.dispose();
    _discountController.dispose();
    _receivedAmountController.dispose();
    _disposeExtraChargeDrafts();
    _printerService.dispose();
    super.dispose();
  }

  void _disposeExtraChargeDrafts() {
    for (final draft in _extraChargeDrafts) {
      draft.dispose();
    }
    _extraChargeDrafts.clear();
  }

  List<BillExtraCharge> get _validExtraCharges {
    if (!_showExtraChargesOnBill || !_extraChargesEnabled) return const [];
    return _extraChargeDrafts
        .map((d) => d.toCharge())
        .where((c) => c.isValid)
        .toList();
  }

  double get _extraChargesTotal =>
      _validExtraCharges.fold(0.0, (total, c) => total + c.amount);

  void _addExtraChargeRow() {
    setState(() {
      _extraChargeDrafts.add(_ExtraChargeDraft());
    });
  }

  void _removeExtraChargeRow(String id) {
    setState(() {
      final idx = _extraChargeDrafts.indexWhere((d) => d.id == id);
      if (idx >= 0) {
        _extraChargeDrafts[idx].dispose();
        _extraChargeDrafts.removeAt(idx);
      }
    });
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

  void _onAddItemsFocusChanged() {
    if (mounted) setState(() {});
  }

  // Setup real-time product stream from the local database - auto-refreshes on any product/stock change
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

  // Setup real-time customer stream from the local database - auto-refreshes on any customer change
  void _setupCustomerStream() {
    _customerStreamSubscription = CustomerOfflineController.instance
        .watchAllCustomers()
        .listen((entities) {
          _watchedCustomers = entities;
          _publishBillingCustomers();
        }, onError: (e) => debugPrint('[Billing] Customer stream error: $e'));
    _eventPendingSubscription = EventOrderOfflineController.instance
        .watchAllEventOrders()
        .listen((orders) {
          final pending = <String, double>{};
          for (final order in orders) {
            if (order.status == OrderStatus.cancelled.index ||
                order.status == OrderStatus.convertedToBill.index) {
              continue;
            }
            final customerId = order.customerId;
            if (customerId == null || customerId.isEmpty) continue;
            pending[customerId] =
                (pending[customerId] ?? 0) + order.remainingAmount;
          }
          _eventPendingByCustomer = pending;
          _publishBillingCustomers();
        }, onError: (e) => debugPrint('[Billing] Event pending stream error: $e'));
  }

  void _publishBillingCustomers() {
    if (!mounted || _watchedCustomers.isEmpty) return;
    final customers = _watchedCustomers.map((entity) {
      final nameParts = entity.name.split(' ');
      final firstName = nameParts.isNotEmpty ? nameParts.first : '';
      final lastName = nameParts.length > 1
          ? nameParts.sublist(1).join(' ')
          : '';
      final eventDue =
          (_eventPendingByCustomer[entity.serverId ?? ''] ?? 0) +
          (_eventPendingByCustomer['local_${entity.id}'] ?? 0);
      return <String, dynamic>{
        'id': entity.serverId ?? 'local_${entity.id}',
        'localId': entity.id,
        'firstName': firstName,
        'lastName': lastName,
        'contact': entity.mobile,
        'fullName': entity.name,
        'pendingBalance': entity.currentPendingAmount + eventDue,
        'totalPurchases': entity.totalPurchases,
      };
    }).toList();
    setState(() {
      _customers = customers;
      _isLoadingCustomers = false;
      final selectedId = _selectedCustomer?['id'];
      if (selectedId != null) {
        for (final customer in customers) {
          if (customer['id'] == selectedId) {
            _selectedCustomer = customer;
            break;
          }
        }
      }
    });
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

      // Map all products (including zero-stock) for product code lookup
      final allMappedProducts = allProducts
          .map((entity) => Product.fromProductEntity(entity))
          .toList();

      // Filter products with available stock for display
      final availableProducts = allMappedProducts
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
          _allProducts = allMappedProducts;
          _products = availableProducts;
          _availableBatches =
              batches.where((b) => b.quantityRemaining > 0).toList()..sort(
                (a, b) => a.purchaseDate.compareTo(b.purchaseDate),
              ); // FIFO order
          // Build index + barcode lookup maps from ALL products so code/barcode search works even when currentStock=0 but batches have stock
          _productByIndexNo = {
            for (final product in allMappedProducts)
              if (product.indexNo > 0) product.indexNo: product,
          };
          _productByBarcode = {};
          for (final product in allMappedProducts) {
            final code = (product.barcode ?? '').trim();
            if (code.isEmpty) continue;
            _productByBarcode[code] = product;
            _productByBarcode[code.toLowerCase()] = product;
          }
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
      // Step 1: Load from local DB first (instant)
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
          '[Billing] Loaded ${localCustomers.length} customers from the local database',
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

        if (localCustomers.isEmpty &&
            firebaseCustomers.isNotEmpty &&
            mounted) {
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

  // Listener for phone number changes - implements debounced search
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

  // Search for customer by phone number using local _customers list
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

  // Show dialog to add new customer with optional phone number
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
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.accentSoft(context, 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.person_add,
                color: AppColors.accent(context),
                size: 24,
              ),
            ),
            SizedBox(width: 12),
            Text(
              _localizations.addNewCustomer,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.accent(context),
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
                      color: AppTheme.grey600,
                      fontFamily: 'Literata',
                    ),
                  ),
                if (phoneNumber.isNotEmpty) const SizedBox(height: 20),
                TextFormField(
                  controller: firstNameController,
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: '${_localizations.firstName} *',
                    prefixIcon: Icon(Icons.person_outline),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: AppColors.accent(context),
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
                SizedBox(height: 16),
                TextFormField(
                  controller: lastNameController,
                  decoration: InputDecoration(
                    labelText: '${_localizations.lastName} *',
                    prefixIcon: Icon(Icons.person_outline),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: AppColors.accent(context),
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
                  maxLength: 10,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(10),
                  ],
                  decoration: InputDecoration(
                    labelText: _localizations.phoneNumberOptional,
                    hintText: '10 digit number',
                    counterText: '',
                    prefixIcon: Icon(Icons.phone_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: AppColors.accent(context),
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
              style: TextStyle(color: AppTheme.grey600, fontFamily: 'Literata'),
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
              style: TextStyle(
                color: AppColors.accent(context),
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
              backgroundColor: AppColors.action(context),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              _localizations.saveAndAttach,
              style: const TextStyle(
                color: AppTheme.white,
                fontFamily: 'Literata',
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Save new customer and auto-attach to current bill
  Future<void> _saveNewCustomer({
    required String firstName,
    required String lastName,
    required String phoneNumber,
  }) async {
    try {
      // Save to the local database via offline controller - syncs to Firestore in background
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
    showAppBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.transparent,
      builder: (ctx) => AddItemsBottomSheet(
        products: _products,
        allProducts: _allProducts,
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
              unit,
              sellUnit,
            ) {
              // Use a unique key: productId + batchLocalId (or just productId if no batch)
              final uniqueKey = batchLocalId != null
                  ? '${productId}_batch_$batchLocalId'
                  : productId;
              final existingIndex = _billItems.indexWhere(
                (item) => item.productId == uniqueKey,
              );
              setState(() {
                _ensureGstModeForProductTax(
                  cgstPercent: cgstPercent,
                  sgstPercent: sgstPercent,
                );
                if (existingIndex != -1) {
                  final prev = _billItems[existingIndex];
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
                    unit: unit,
                    sellUnit: sellUnit,
                    employeeToken: prev.employeeToken,
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
                      unit: unit,
                      sellUnit: sellUnit,
                    ),
                  );
                }
              });
              _focusAfterProductAdded(uniqueKey);
            },
        onItemRemoved: (uniqueKey) {
          _disposeItemTokenInputs(uniqueKey);
          setState(() {
            _billItems.removeWhere((item) => item.productId == uniqueKey);
          });
        },
        showSnackbar: _showSnackbar,
      ),
    );
  }

  // Show the barcode scanner bottom sheet for fast billing
  void _showBarcodeScannerSheet() {
    BarcodeScannerSheet.show(
      context,
      onProductScanned: (productData) {
        _addScannedProductToBill(productData);
      },
      onProductRemoved: (productKey) {
        _removeScannedProductFromBill(productKey);
      },
    );
  }

  // Remove a scanned product from the bill
  void _removeScannedProductFromBill(String productKey) {
    setState(() {
      _billItems.removeWhere((item) => item.productId == productKey);
    });
  }

  // Add a scanned product to the bill
  void _addScannedProductToBill(Map<String, dynamic> productData) {
    final productId = productData['productId'] as String;
    final batchId = productData['batchId'] as String?;
    final productName = productData['productName'] as String;
    final companyName = productData['companyName'] as String?;
    final unitPrice = (productData['unitPrice'] as num?)?.toDouble() ?? 0.0;
    final purchasePrice =
        (productData['purchasePrice'] as num?)?.toDouble() ?? 0.0;
    final availableStock =
        (productData['availableStock'] as num?)?.toDouble() ?? 0.0;
    final cgst = (productData['cgst'] as num?)?.toDouble() ?? 0.0;
    final sgst = (productData['sgst'] as num?)?.toDouble() ?? 0.0;
    final hsnCode = productData['hsnCode'] as String?;
    final unit = productData['unit'] as String? ?? 'pcs';

    // Create unique key with batch
    final uniqueKey = batchId != null
        ? '${productId}_batch_$batchId'
        : productId;

    setState(() {
      _ensureGstModeForProductTax(cgstPercent: cgst, sgstPercent: sgst);
      final existingIndex = _billItems.indexWhere(
        (item) => item.productId == uniqueKey,
      );

      if (existingIndex != -1) {
        // Update existing item - preserve existing unit/sellUnit
        final existing = _billItems[existingIndex];
        // Determine step based on current sellUnit
        final step = (existing.sellUnit == 'gm' || existing.sellUnit == 'ml')
            ? 0.1
            : 1.0;
        if (existing.quantity + step <= availableStock) {
          _billItems[existingIndex] = BillItem.create(
            productId: uniqueKey,
            productName: productName,
            companyName: companyName,
            sellingPrice: existing.sellingPrice,
            purchasePrice: purchasePrice,
            quantity: existing.quantity + step,
            cgstPercent: cgst,
            sgstPercent: sgst,
            hsnCode: hsnCode,
            unit: existing.unit ?? unit,
            sellUnit: existing.sellUnit ?? unit,
            employeeToken: existing.employeeToken,
          );
        } else {
          _showSnackbar(
            '${_localizations.maxStock}: ${availableStock.toInt()}',
            isError: true,
          );
          return;
        }
      } else {
        // Add new item with base unit
        _billItems.add(
          BillItem.create(
            productId: uniqueKey,
            productName: productName,
            companyName: companyName,
            sellingPrice: unitPrice,
            purchasePrice: purchasePrice,
            quantity: 1,
            cgstPercent: cgst,
            sgstPercent: sgst,
            hsnCode: hsnCode,
            unit: unit,
            sellUnit: unit,
          ),
        );
      }
    });
    _focusAfterProductAdded(uniqueKey);
  }

  double get _totalAmount =>
      _billItems.fold(0.0, (total, item) => total + item.subtotal);

  double get _totalQuantity =>
      _billItems.fold(0.0, (total, item) => total + item.quantity);

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
    double amount;
    // For exclusive GST, tax is added on top
    if (_gstMode == GstMode.excludeGst && _taxBreakdown != null) {
      amount = subtotalAfterDiscount + _taxBreakdown!.totalTaxAmount;
    } else {
      // For inclusive GST or no GST, price already contains tax or no tax
      amount = subtotalAfterDiscount;
    }
    // Extra charges (labour / service) always add on top
    amount += _extraChargesTotal;
    // Round up to nearest rupee
    return amount.ceilToDouble();
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

    // Each product line needs its own employee token when enabled
    if (_enableEmployeeToken) {
      for (final item in _billItems) {
        final token = item.employeeToken;
        if (token == null || token <= 0) {
          _showSnackbar(
            'Enter employee token for "${item.productName}"',
            isError: true,
          );
          _focusAfterProductAdded(item.productId);
          return;
        }
        final tokenEmp = await _employeeRepo.findByToken(token);
        if (tokenEmp == null) {
          _showSnackbar(
            'No active employee for token $token (${item.productName})',
            isError: true,
          );
          _focusAfterProductAdded(item.productId);
          return;
        }
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
      // === INTEGRATED OFFLINE-FIRST APPROACH (FIFO) === 1. Calculate payment status
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

      // 2. Use InventoryIntegrationService for unified processing: Creates BillEntity + FIFO batch deductions + StockLedger entries + updates Product stock Transform bill items: extract...
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
          unit: item.unit,
          sellUnit: item.sellUnit,
          employeeToken: item.employeeToken,
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
            totalQuantity: _totalQuantity.round(),
            totalAmount: _totalAmount,
            discountAmount: _discountAmount,
            discountPercent: _discountPercent,
            finalAmount: _finalAmount,
            notes: _billNotesText(),
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
            extraCharges: _validExtraCharges,
            paymentMode: _billPaymentMode.value,
          );

      if (!integrationResult.success) {
        throw Exception(
          integrationResult.errorMessage ?? _localizations.billProcessingFailed,
        );
      }

      debugPrint(
        '[Billing] Bill processed with FIFO: COGS=${integrationResult.totalCOGS}, Profit=${integrationResult.totalProfit}',
      );

      // 3. Create ledger/transaction entries for customer transactions
      if (_selectedCustomer != null) {
        try {
          final customerId = _selectedCustomer!['id'] as String;
          final customerName =
              _selectedCustomer!['fullName'] as String? ??
              '${_selectedCustomer!['firstName'] ?? ''} ${_selectedCustomer!['lastName'] ?? ''}'
                  .trim();
          final billId =
              integrationResult.billEntity?.serverId ??
              'local_${integrationResult.billEntity?.id}';

          // 3a. Record bill creation transaction (adds to pending amount) - Offline
          final chargeSummary = _validExtraCharges.isEmpty
              ? ''
              : '; Extra: ${_validExtraCharges.map((c) => '${c.label} ₹${c.amount.toStringAsFixed(0)}').join(', ')}';
          await CustomerTransactionOfflineController.instance
              .addBillTransaction(
                customerId: customerId,
                customerName: customerName,
                amount: _finalAmount,
                billId: billId,
                description: 'Bill #$billId$chargeSummary',
              );
          debugPrint(
            '[Billing] Bill transaction recorded offline: $_finalAmount',
          );

          // 3b. Record payment received during billing (if any) - Offline
          if (actualPaidAmount > 0) {
            await CustomerTransactionOfflineController.instance
                .addPaymentTransaction(
                  customerId: customerId,
                  customerName: customerName,
                  amount: actualPaidAmount,
                  paymentMethod: _billPaymentMode.displayName,
                  description:
                      'Payment for Bill #$billId (${_isFullPayment ? 'Full' : 'Partial'})',
                );
            debugPrint(
              '[Billing] Payment transaction recorded offline: $actualPaidAmount',
            );
          }

          // 3c. Sync to Firebase - Record full bill amount first
          final billRecordResult = await _customerTransactionService
              .recordBillGenerated(
                customerId: customerId,
                billId: billId,
                billNumber: billId,
                billAmount: _finalAmount,
              );

          if (billRecordResult.success) {
            debugPrint(
              '[Billing] Firebase: Bill recorded with amount: $_finalAmount',
            );

            // 3d. Then record payment received to Firebase (if any)
            if (actualPaidAmount > 0) {
              final paymentResult = await _customerTransactionService
                  .receivePayment(
                    customerId: customerId,
                    amount: actualPaidAmount,
                    paymentMode: _billPaymentMode,
                    billId: billId,
                    billNumber: billId,
                    notes:
                        'Payment during billing - ${_isFullPayment ? _localizations.full : _localizations.partial} (${_billPaymentMode.displayName})',
                  );

              if (paymentResult.success) {
                debugPrint(
                  '[Billing] Firebase: Payment recorded: $actualPaidAmount',
                );
              } else {
                debugPrint(
                  '[Billing] Firebase: Payment failed: ${paymentResult.errorMessage}',
                );
              }
            }
          } else {
            debugPrint(
              '[Billing] Firebase: Bill record failed: ${billRecordResult.errorMessage}',
            );
          }
        } catch (e) {
          debugPrint('[Billing] Transaction entry error (non-blocking): $e');
        }
      }

      // 4. Award points per employee token from each product's sale price
      if (_enableEmployeeToken) {
        final pointsByToken = <int, double>{};
        for (final item in _billItems) {
          final token = item.employeeToken;
          if (token == null || token <= 0) continue;
          pointsByToken[token] =
              (pointsByToken[token] ?? 0) +
              (item.sellingPrice * item.quantity);
        }
        for (final entry in pointsByToken.entries) {
          try {
            await _employeeRepo.addSalesPoints(
              tokenNumber: entry.key,
              salesAmount: entry.value,
            );
          } catch (e) {
            debugPrint(
              '[Billing] Points for token ${entry.key} failed (non-blocking): $e',
            );
          }
        }
      }

      // 5. Trigger background sync
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

      // Show bill PDF preview with print/share options (token is never printed)
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
          final newStock = (p.currentStock - item.quantity).round();
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
    _disposeItemTokenInputs();
    _disposeExtraChargeDrafts();
    setState(() {
      _billItems.clear();
      _customerNameController.clear();
      _customerContactController.clear();
      _notesController.clear();
      _discountController.clear();
      _receivedAmountController.clear();
      _discountValue = 0.0;
      _isPercentageDiscount = true;
      _extraChargesEnabled = false;
      _selectedCustomer = null;
      _autoFoundCustomerName = null;
      _receivedAmount = 0.0;
      _isFullPayment = true;
      _billPaymentMode = PaymentMode.cash;
      _showAddCustomerPrompt = false;
      _hasPhoneText = false;
      // Reset GST mode to default from settings
      _gstMode = _taxSettings.defaultGstMode;
    });
  }

  PaymentMode _paymentModeFromValue(String raw) {
    return PaymentModeExtension.fromString(raw);
  }

  Future<void> _holdCurrentBill() async {
    if (!_enableHoldBill || _billItems.isEmpty || _isSavingBill) return;
    final draft = HeldBillDraft(
      id: 'hold_${DateTime.now().microsecondsSinceEpoch}',
      heldAt: DateTime.now(),
      customerId: _selectedCustomer?['id'] as String?,
      customerName: _customerNameController.text.trim().isEmpty
          ? (_selectedCustomer?['fullName'] as String?)
          : _customerNameController.text.trim(),
      customerContact: _customerContactController.text.trim().isEmpty
          ? (_selectedCustomer?['contact'] as String?)
          : _customerContactController.text.trim(),
      items: List<BillItem>.from(_billItems),
      discountValue: _discountValue,
      isPercentageDiscount: _isPercentageDiscount,
      extraChargesEnabled: _extraChargesEnabled,
      extraCharges: _extraChargeDrafts
          .map(
            (d) => {
              'label': d.labelController.text.trim(),
              'amount':
                  double.tryParse(d.amountController.text.trim()) ?? 0.0,
            },
          )
          .where(
            (m) =>
                (m['label'] as String).isNotEmpty ||
                ((m['amount'] as double) > 0),
          )
          .toList(),
      gstMode: _gstMode,
      isFullPayment: _isFullPayment,
      receivedAmount: _receivedAmount,
      paymentMode: _billPaymentMode.value,
      notes: _billNotesText(),
    );
    try {
      await HeldBillStore.add(draft);
      if (!mounted) return;
      _clearBill();
      await _refreshHeldBillCount();
      _showSnackbar(
        'Bill held · $_heldBillCount parked',
        isError: false,
      );
    } catch (e) {
      if (!mounted) return;
      _showSnackbar('Could not hold bill: $e', isError: true);
    }
  }

  Future<void> _showHeldBillsSheet() async {
    if (!_enableHoldBill) return;
    final drafts = await HeldBillStore.loadAll();
    if (!mounted) return;
    if (drafts.isEmpty) {
      _showSnackbar('No held bills', isError: false);
      await _refreshHeldBillCount();
      return;
    }
    await showAppBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.transparent,
      builder: (ctx) {
        final side = DesktopCanvas.isDesktopPlatform;
        return DraggableScrollableSheet(
          initialChildSize: drawerSheetSize(0.58),
          minChildSize: drawerSheetSize(0.4),
          maxChildSize: drawerSheetSize(0.92),
          builder: (_, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: AppColors.card(context),
                borderRadius: side
                    ? BorderRadius.zero
                    : const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (!side) ...[
                    const SizedBox(height: 12),
                    Center(
                      child: Container(
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.mutedText(context)
                              .withValues(alpha: 0.45),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ] else
                    const SizedBox(height: 8),
                  // Title only — desktop drawer already has the close control
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      20,
                      side ? 12 : 16,
                      side ? 52 : 20,
                      8,
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.accentSoft(context, 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.pause_circle_outline_rounded,
                            color: AppColors.action(context),
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Held bills (${drafts.length})',
                                style: TextStyle(
                                  fontFamily: 'Literata',
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.primaryText(context),
                                ),
                              ),
                              Text(
                                'Continue to restore, or discard',
                                style: TextStyle(
                                  fontFamily: 'Literata',
                                  fontSize: 12,
                                  color: AppColors.mutedText(context),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.separated(
                      controller: scrollController,
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      itemCount: drafts.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (_, i) {
                        final d = drafts[i];
                        final when = DateFormat(
                          'dd MMM, hh:mm a',
                        ).format(d.heldAt);
                        return Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.inputFill(context),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: AppColors.border(context),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      d.displayTitle,
                                      style: TextStyle(
                                        fontFamily: 'Literata',
                                        fontWeight: FontWeight.w700,
                                        fontSize: 15,
                                        color: AppColors.primaryText(context),
                                      ),
                                    ),
                                  ),
                                  Text(
                                    '₹${d.itemsTotal.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      fontFamily: 'Literata',
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.action(context),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${d.items.length} items · $when',
                                style: TextStyle(
                                  fontFamily: 'Literata',
                                  fontSize: 12,
                                  color: AppColors.mutedText(context),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: () async {
                                        Navigator.pop(ctx);
                                        await _discardHeldBill(d.id);
                                      },
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: AppTheme.toneRose,
                                        side: BorderSide(
                                          color: AppTheme.toneRose.withValues(
                                            alpha: 0.5,
                                          ),
                                        ),
                                      ),
                                      child: const Text('Discard'),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: FilledButton(
                                      onPressed: () async {
                                        Navigator.pop(ctx);
                                        await _resumeHeldBill(d);
                                      },
                                      style: FilledButton.styleFrom(
                                        backgroundColor: AppColors.action(
                                          context,
                                        ),
                                      ),
                                      child: const Text('Continue'),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
    await _refreshHeldBillCount();
  }

  Future<void> _discardHeldBill(String id) async {
    await HeldBillStore.remove(id);
    await _refreshHeldBillCount();
    if (mounted) {
      _showSnackbar('Held bill discarded', isError: false);
    }
  }

  Future<void> _resumeHeldBill(HeldBillDraft draft) async {
    if (_billItems.isNotEmpty) {
      final replace = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Replace current bill?'),
          content: const Text(
            'Your open cart has items. Continuing a held bill will replace them.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Replace'),
            ),
          ],
        ),
      );
      if (replace != true) return;
    }

    _disposeItemTokenInputs();
    _disposeExtraChargeDrafts();

    Map<String, dynamic>? customer;
    final cid = draft.customerId;
    if (cid != null && cid.isNotEmpty) {
      for (final c in _customers) {
        if (c['id'] == cid) {
          customer = c;
          break;
        }
      }
      customer ??= {
        'id': cid,
        'fullName': draft.customerName ?? '',
        'contact': draft.customerContact ?? '',
      };
    }

    final restoredCharges = <_ExtraChargeDraft>[];
    for (final m in draft.extraCharges) {
      restoredCharges.add(
        _ExtraChargeDraft.restored(
          label: (m['label'] ?? '').toString(),
          amount: (m['amount'] as num?)?.toDouble() ?? 0,
        ),
      );
    }

    setState(() {
      _billItems
        ..clear()
        ..addAll(draft.items);
      _selectedCustomer = customer;
      _customerNameController.text = draft.customerName ?? '';
      _customerContactController.text = draft.customerContact ?? '';
      _autoFoundCustomerName = draft.customerName;
      _showAddCustomerPrompt = false;
      _hasPhoneText = (draft.customerContact ?? '').trim().isNotEmpty;
      _discountValue = draft.discountValue;
      _isPercentageDiscount = draft.isPercentageDiscount;
      _discountController.text = draft.discountValue > 0
          ? (draft.isPercentageDiscount
                ? draft.discountValue.toStringAsFixed(
                    draft.discountValue == draft.discountValue.roundToDouble()
                        ? 0
                        : 1,
                  )
                : draft.discountValue.toStringAsFixed(2))
          : '';
      _extraChargesEnabled =
          draft.extraChargesEnabled && _taxSettings.enableExtraCharges;
      if (_extraChargesEnabled) {
        _extraChargeDrafts.addAll(restoredCharges);
      } else {
        for (final c in restoredCharges) {
          c.dispose();
        }
      }
      _gstMode = _taxSettings.gstFeatureEnabled
          ? draft.gstMode
          : GstMode.noGst;
      _isFullPayment = draft.isFullPayment;
      _receivedAmount = draft.receivedAmount;
      _receivedAmountController.text = draft.receivedAmount > 0
          ? draft.receivedAmount.toStringAsFixed(2)
          : '';
      _billPaymentMode = _paymentModeFromValue(draft.paymentMode);
      _notesController.text = draft.notes ?? '';
    });

    if (_enableEmployeeToken) {
      for (final item in draft.items) {
        if (item.employeeToken != null) {
          _tokenControllerFor(item.productId, item.employeeToken);
        }
      }
    }

    await HeldBillStore.remove(draft.id);
    await _refreshHeldBillCount();
    if (mounted) {
      _showSnackbar('Held bill restored — continue & Print when ready');
    }
  }

  Widget _holdActionsRow({bool compact = false}) {
    if (!_enableHoldBill) return const SizedBox.shrink();
    final showHold = _billItems.isNotEmpty;
    final showHeld = _heldBillCount > 0;
    if (!showHold && !showHeld) return const SizedBox.shrink();
    final action = AppColors.action(context);
    return Row(
      children: [
        if (showHold)
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _isSavingBill ? null : _holdCurrentBill,
              icon: const Icon(Icons.pause_circle_outline_rounded, size: 18),
              label: Text(
                compact ? 'Hold' : 'Hold bill',
                style: const TextStyle(
                  fontFamily: 'Literata',
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primaryText(context),
                side: BorderSide(color: AppColors.border(context)),
                padding: EdgeInsets.symmetric(vertical: compact ? 12 : 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        if (showHold && showHeld) const SizedBox(width: 8),
        if (showHeld)
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _showHeldBillsSheet,
              icon: Icon(Icons.inbox_outlined, size: 18, color: action),
              label: Text(
                'Held ($_heldBillCount)',
                style: TextStyle(
                  fontFamily: 'Literata',
                  fontWeight: FontWeight.w700,
                  color: action,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: action,
                side: BorderSide(color: action.withValues(alpha: 0.45)),
                padding: EdgeInsets.symmetric(vertical: compact ? 12 : 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
      ],
    );
  }

  String? _billNotesText() {
    final typed = _notesController.text.trim();
    return typed.isNotEmpty ? typed : null;
  }

  // Create PrintBillData from bill - no network calls, uses bill data directly
  // Employee token is intentionally omitted from printed bills.
  PrintBillData _createPrintBillData(Bill bill) {
    // Use bill's own pending amount as totalDueAmount (already computed at bill creation time)
    final double? totalDueAmount = bill.pendingAmount > 0
        ? bill.pendingAmount
        : null;
    return PrintBillData.fromBill(
      bill,
      totalDueAmount: totalDueAmount,
      employeeToken: null,
    );
  }

  // Show bill PDF preview with share/print options (like purchase report)
  static bool _pdfGenerationInProgress = false;

  Future<void> _showBillPdfPreview(Bill bill) async {
    // Prevent multiple simultaneous PDF generations globally
    if (_pdfGenerationInProgress) {
      debugPrint(
        '[BillingPage] PDF generation already in progress globally, ignoring request',
      );
      return;
    }

    try {
      debugPrint(
        '[BillingPage] Starting PDF preview for bill: ${bill.billNumber}',
      );
      _pdfGenerationInProgress = true;

      // Show loading toast (non-blocking like purchase page)
      if (mounted) {
        GlassyToast.show(
          context,
          _localizations.preparingPdf,
          icon: Icons.hourglass_top_rounded,
        );
      }

      debugPrint('[BillingPage] Creating print data...');
      final printData = _createPrintBillData(bill);
      debugPrint(
        '[BillingPage] Print data created: ${printData.items.length} items',
      );

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
      if (kIsWeb) {
        final bytes = await _pdfService
            .buildPdfBytes(billData: printData, shopDetails: shop)
            .timeout(
              const Duration(seconds: 90),
              onTimeout: () =>
                  throw Exception('PDF generation timed out after 90 seconds'),
            );
        if (mounted) GlassyToast.dismiss();
        if (!mounted) return;
        await FilePreviewPage.open(
          context,
          bytes: bytes,
          fileName: '${_localizations.bills} - ${bill.billNumber}',
          fileType: FilePreviewType.pdf,
          subtitle: DateFormat('dd MMM yyyy, hh:mm a').format(bill.billDate),
          customerPhone: bill.customerContact,
          details: FilePreviewDetails(
            title: 'Bill preview',
            documentNo: bill.billNumber,
            dateLabel:
                DateFormat('dd MMM yyyy, hh:mm a').format(bill.billDate),
            customer: (bill.customerName?.trim().isNotEmpty ?? false)
                ? bill.customerName!.trim()
                : 'Walk-in customer',
            itemsQty: '${bill.items.length} · ${bill.totalQuantity}',
            amount: '₹${bill.finalAmount.toStringAsFixed(2)}',
          ),
        );
        return;
      }
      final file = await _pdfService
          .savePdfToFile(billData: printData, shopDetails: shop)
          .timeout(
            const Duration(seconds: 90),
            onTimeout: () =>
                throw Exception('PDF generation timed out after 90 seconds'),
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
      debugPrint('[BillingPage] File size: $fileSize bytes');

      // Hide loading snackbar
      if (mounted) {
        GlassyToast.dismiss();
      }

      if (!mounted) {
        debugPrint('[BillingPage] Widget not mounted, aborting');
        return;
      }

      // Navigate to PDF preview
      debugPrint('[BillingPage] Navigating to FilePreviewPage...');
      await FilePreviewPage.open(
        context,
        file: file,
        fileName: '${_localizations.bills} - ${bill.billNumber}',
        fileType: FilePreviewType.pdf,
        subtitle: DateFormat('dd MMM yyyy, hh:mm a').format(bill.billDate),
        customerPhone: bill.customerContact,
        details: FilePreviewDetails(
          title: 'Bill preview',
          documentNo: bill.billNumber,
          dateLabel: DateFormat('dd MMM yyyy, hh:mm a').format(bill.billDate),
          customer: (bill.customerName?.trim().isNotEmpty ?? false)
              ? bill.customerName!.trim()
              : 'Walk-in customer',
          itemsQty: '${bill.items.length} · ${bill.totalQuantity}',
          amount: '₹${bill.finalAmount.toStringAsFixed(2)}',
        ),
      );
      debugPrint('[BillingPage] Returned from FilePreviewPage');
    } catch (e, stack) {
      debugPrint('[BillingPage] ERROR generating PDF preview: $e');
      debugPrint('[BillingPage] Stack trace: $stack');

      // Hide loading snackbar
      if (mounted) {
        GlassyToast.dismiss();
      }

      // Small delay before showing error
      await Future.delayed(const Duration(milliseconds: 300));

      if (mounted) {
        _showSnackbar(
          '${_localizations.failedToGeneratePdf}: ${e.toString()}',
          isError: true,
          action: SnackBarAction(
            label: _localizations.retry,
            textColor: AppTheme.white,
            onPressed: () => _showBillPdfPreview(bill),
          ),
        );
      }
    } finally {
      debugPrint('[BillingPage] Resetting PDF generation state');
      _pdfGenerationInProgress = false;
    }
  }

  void _showSnackbar(
    String message, {
    bool isError = false,
    SnackBarAction? action,
  }) {
    if (!mounted) return;
    GlassyToast.show(context, message, isError: isError);
  }

  bool get _desktopBill =>
      widget.isEmbedded && DesktopCanvas.wide(context);

  @override
  Widget build(BuildContext context) {
    final extras = _billExtras();
    if (_desktopBill) {
      return Scaffold(
        backgroundColor: AppColors.scaffold(context),
        body: _buildDesktopBill(),
      );
    }
    return Scaffold(
      backgroundColor: AppColors.scaffold(context),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: AppColors.accent(context),
              ),
            )
          : widget.isEmbedded
          ? Stack(
              children: [
                SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(children: [_buildBillComposer(), ...extras]),
                ),
                if (_showQuickStats) _buildQuickStatsPremiumPanel(),
              ],
            )
          : Column(
              children: [
                AppTopBar(
                  title: _localizations.createBill,
                  subtitle: _localizations.createAndPrintInvoices,
                  actions: [
                    if (_billItems.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppTopBar.chipFill(context),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${_billItems.length}',
                          style: TextStyle(
                            color: AppTopBar.onBar(context),
                            fontWeight: FontWeight.w700,
                            fontFamily: 'Literata',
                          ),
                        ),
                      ),
                    if (_enableHoldBill && _heldBillCount > 0)
                      Material(
                        color: AppTheme.transparent,
                        child: InkWell(
                          onTap: _showHeldBillsSheet,
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppTopBar.chipFill(context),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: AppTopBar.chipBorder(context),
                              ),
                            ),
                            child: Text(
                              'Held $_heldBillCount',
                              style: TextStyle(
                                color: AppTopBar.onBar(context),
                                fontWeight: FontWeight.w700,
                                fontFamily: 'Literata',
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                      ),
                    AppTopBar.action(
                      icon: Icons.settings_rounded,
                      onTap: () async {
                        final result = await showAppPage<bool>(
                          context,
                          const BillSettingsPage(),
                        );
                        if (result == true) {
                          _loadBillSettings();
                        }
                      },
                    ),
                    AppTopBar.action(
                      icon: Icons.tune_rounded,
                      onTap: () {
                        showAppPage(
                          context,
                          const BillReportSettingsPage(),
                        );
                      },
                    ),
                  ],
                ),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      children: [_buildBillComposer(), ...extras],
                    ),
                  ),
                ),
              ],
            ),
      bottomNavigationBar: _billItems.isEmpty ? null : _buildBottomBar(),
    );
  }

  Widget _buildDesktopBill() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 3,
            child: _billItems.isEmpty
                ? Column(
                    children: [
                      if (_showCustomerOnBill || _generateBillViaContact)
                        _buildCustomerSection(),
                      _buildAddItemsSection(),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
                          child: _buildDesktopEmptyBill(),
                        ),
                      ),
                    ],
                  )
                : SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      children: [
                        if (_showCustomerOnBill || _generateBillViaContact)
                          _buildCustomerSection(),
                        _buildAddItemsSection(),
                        _buildBillItemsSection(),
                        if (_showExtraChargesOnBill)
                          _buildExtraChargesSection(compact: false),
                        if (_showGstOnBill) _buildGstModeSection(),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
          ),
          const SizedBox(width: 16),
          SizedBox(
            width: 320,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  if (_billItems.isNotEmpty)
                    _buildDiscountSection(showNestedSummary: false),
                  _buildDesktopSummaryCard(),
                  if (_billItems.isNotEmpty && !_isFullPayment)
                    _buildPaymentSection(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopSummaryCard() {
    final action = AppColors.action(context);
    final muted = AppColors.mutedText(context);
    final base = _totalAmount - _discountAmount;
    final taxed = _gstMode == GstMode.excludeGst && _taxBreakdown != null
        ? base + _taxBreakdown!.totalTaxAmount
        : base;
    final withCharges = taxed + _extraChargesTotal;
    final roundOff = _finalAmount - withCharges;
    final tax = _taxBreakdown;
    Widget line(String label, String value, {Color? valueColor}) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontFamily: 'Literata',
                  fontSize: 13,
                  color: muted,
                ),
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontFamily: 'Literata',
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: valueColor ?? AppColors.primaryText(context),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Bill summary',
            style: TextStyle(
              fontFamily: 'Literata',
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.primaryText(context),
            ),
          ),
          const SizedBox(height: 10),
          line('Items', '${_billItems.length}'),
          line('Subtotal', '₹${_totalAmount.toStringAsFixed(2)}'),
          if (_discountAmount > 0)
            line(
              _isPercentageDiscount
                  ? 'Discount (${_discountValue.toStringAsFixed(0)}%)'
                  : 'Discount',
              '-₹${_discountAmount.toStringAsFixed(2)}',
              valueColor: AppTheme.toneRose,
            ),
          if (tax != null && tax.hasAnyTax) ...[
            if (tax.cgstAmount > 0)
              line(
                tax.cgstPercent > 0
                    ? 'CGST (${tax.cgstPercent.toStringAsFixed(1)}%)'
                    : 'CGST',
                '₹${tax.cgstAmount.toStringAsFixed(2)}',
              ),
            if (tax.sgstAmount > 0)
              line(
                tax.sgstPercent > 0
                    ? 'SGST (${tax.sgstPercent.toStringAsFixed(1)}%)'
                    : 'SGST',
                '₹${tax.sgstAmount.toStringAsFixed(2)}',
              ),
            if (tax.otherTaxAmount > 0)
              line(
                tax.otherTaxName.isNotEmpty ? tax.otherTaxName : 'Tax',
                '₹${tax.otherTaxAmount.toStringAsFixed(2)}',
              ),
            line(
              'Total tax',
              '₹${tax.totalTaxAmount.toStringAsFixed(2)}',
            ),
          ],
          if (_extraChargesTotal > 0) ...[
            for (final charge in _validExtraCharges)
              line(charge.label, '₹${charge.amount.toStringAsFixed(2)}'),
          ],
          if (roundOff.abs() >= 0.01)
            line('Round off', '₹${roundOff.toStringAsFixed(2)}'),
          Divider(height: 20, color: AppColors.border(context)),
          Row(
            children: [
              Text(
                'Total',
                style: TextStyle(
                  fontFamily: 'Literata',
                  fontSize: 14,
                  color: muted,
                ),
              ),
              const Spacer(),
              Text(
                '₹${_finalAmount.toStringAsFixed(2)}',
                style: TextStyle(
                  fontFamily: 'Literata',
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryText(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Text(
                _localizations.payment,
                style: TextStyle(
                  fontFamily: 'Literata',
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryText(context),
                ),
              ),
              const Spacer(),
              _summaryPayChip(
                label: _localizations.full,
                selected: _isFullPayment,
                onTap: () {
                  setState(() {
                    _isFullPayment = true;
                    _receivedAmount = _finalAmount;
                    _receivedAmountController.text = _finalAmount
                        .toStringAsFixed(2);
                  });
                },
              ),
              const SizedBox(width: 8),
              _summaryPayChip(
                label: _localizations.partialPayment,
                selected: !_isFullPayment,
                onTap: () {
                  setState(() {
                    _isFullPayment = false;
                    _receivedAmount = 0;
                    _receivedAmountController.clear();
                  });
                  if (_selectedCustomer == null &&
                      _customerNameController.text.trim().isEmpty &&
                      !_generateBillViaContact) {
                    _showCustomerPicker();
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Paid via',
              style: TextStyle(
                fontFamily: 'Literata',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: muted,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final mode in const [
                PaymentMode.cash,
                PaymentMode.upi,
                PaymentMode.card,
                PaymentMode.online,
                PaymentMode.cheque,
              ])
                _summaryPayChip(
                  label: mode.displayName,
                  selected: _billPaymentMode == mode,
                  onTap: () => setState(() => _billPaymentMode = mode),
                ),
            ],
          ),
          const SizedBox(height: 14),
          if (_enableHoldBill &&
              (_billItems.isNotEmpty || _heldBillCount > 0)) ...[
            _holdActionsRow(),
            const SizedBox(height: 10),
          ],
          FilledButton.icon(
            onPressed: _isSavingBill || _billItems.isEmpty ? null : _saveBill,
            style: FilledButton.styleFrom(
              backgroundColor: action,
              foregroundColor: AppTheme.white,
              disabledBackgroundColor: action.withValues(alpha: 0.4),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.check_rounded, size: 18),
            label: Text(
              _localizations.printBill,
              style: const TextStyle(
                fontFamily: 'Literata',
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryPayChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final dark = AppColors.isDark(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? (dark ? AppTheme.darkAction : AppTheme.paletteFFD7EDE3)
              : AppColors.chipFill(context),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? AppTheme.transparent
                : AppColors.border(context),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Literata',
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: selected
                ? (dark ? AppTheme.white : AppColors.action(context))
                : AppColors.secondaryText(context),
          ),
        ),
      ),
    );
  }

  List<Widget> _billExtras() {
    return [
      if (_billItems.isNotEmpty) _buildBillItemsSection(),
      if (_billItems.isNotEmpty && _showExtraChargesOnBill)
        _buildExtraChargesSection(compact: false),
      if (_billItems.isNotEmpty) _buildDiscountSection(),
      if (_billItems.isNotEmpty && _showGstOnBill) _buildGstModeSection(),
      if (_billItems.isNotEmpty) _buildPaymentSection(),
      if (_billItems.isNotEmpty) const SizedBox(height: 16),
    ];
  }

  Widget _buildBillComposer() {
    return Column(
      children: [
        if (_showCustomerOnBill || _generateBillViaContact)
          _buildCustomerSection(),
        _buildAddItemsSection(),
        if (_billItems.isEmpty) ...[
          const SizedBox(height: 28),
          _buildEmptyBillState(),
        ],
      ],
    );
  }

  Widget _buildDesktopEmptyBill() {
    final muted = AppColors.mutedText(context);
    final dark = AppColors.isDark(context);
    return CustomPaint(
      painter: _DashedRRectPainter(
        muted.withValues(alpha: dark ? 0.55 : 0.4),
        radius: 20,
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.card(context),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border(context)),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.black.withValues(alpha: dark ? 0.28 : 0.06),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.receipt_long_outlined,
                  color: muted,
                  size: 26,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Your bill is empty',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Literata',
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  color: AppColors.primaryText(context),
                ),
              ),
              const SizedBox(height: 6),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 260),
                child: Text(
                  'Scan a barcode or type a product code to add the first item.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Literata',
                    fontSize: 13,
                    height: 1.4,
                    color: muted,
                  ),
                ),
              ),
              if (_enableHoldBill && _heldBillCount > 0) ...[
                const SizedBox(height: 16),
                TextButton.icon(
                  onPressed: _showHeldBillsSheet,
                  icon: const Icon(Icons.inbox_outlined, size: 18),
                  label: Text('Continue held bill ($_heldBillCount)'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyBillState() {
    final muted = AppColors.mutedText(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          CustomPaint(
            painter: _DashedRRectPainter(muted.withValues(alpha: 0.55)),
            child: SizedBox(
              width: 72,
              height: 72,
              child: Icon(Icons.receipt_long_outlined, color: muted, size: 28),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Your bill is empty',
            style: TextStyle(
              fontFamily: 'Literata',
              fontWeight: FontWeight.w800,
              fontSize: 16,
              color: AppColors.primaryText(context),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Scan a barcode or type a product code to add the first item.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Literata',
              fontSize: 13,
              height: 1.4,
              color: muted,
            ),
          ),
          if (_enableHoldBill && _heldBillCount > 0) ...[
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: _showHeldBillsSheet,
              icon: const Icon(Icons.inbox_outlined, size: 18),
              label: Text('Continue held bill ($_heldBillCount)'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCustomerSection({bool nested = false}) {
    // Determine if customer is required (partial payment selected)
    final isCustomerRequired = !_isFullPayment;

    return Container(
      margin: nested
          ? EdgeInsets.zero
          : const EdgeInsets.fromLTRB(16, 6, 16, 6),
      decoration: BoxDecoration(
        color: nested ? AppColors.scaffold(context) : AppColors.card(context),
        borderRadius: BorderRadius.circular(16),
        border: isCustomerRequired && _selectedCustomer == null
            ? Border.all(color: AppTheme.toneRose, width: 2)
            : Border.all(color: AppColors.border(context)),
        boxShadow: nested
            ? null
            : [
                BoxShadow(
                  color: AppTheme.black.withValues(alpha: 0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 3),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header
          Container(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppTheme.headerDarkStart,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.person_rounded,
                    color: AppTheme.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          _generateBillViaContact
                              ? _localizations.phoneNumber
                              : isCustomerRequired
                              ? '${_localizations.customerOptional.replaceAll('(Optional)', '')}(Required)'
                              : 'Customer',
                          style: TextStyle(
                            fontFamily: 'Literata',
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color:
                                isCustomerRequired && _selectedCustomer == null
                                ? AppTheme.error
                                : AppColors.primaryText(context),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _generateBillViaContact
                            ? _localizations.autoLinkByPhone
                            : isCustomerRequired
                            ? ''
                            : 'Optional',
                        style: TextStyle(
                          fontFamily: 'Literata',
                          fontSize: 13,
                          color: AppColors.mutedText(context),
                        ),
                      ),
                    ],
                  ),
                ),
                if (!_generateBillViaContact && !_isLoadingCustomers)
                  GestureDetector(
                    onTap: () {
                      final phone = _customerContactController.text.trim();
                      _showAddCustomerDialog(phone);
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add, color: AppColors.action(context), size: 18),
                        SizedBox(width: 2),
                        Text(
                          'Add',
                          style: TextStyle(
                            fontFamily: 'Literata',
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.action(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                if (_isLoadingCustomers)
                  SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.accent(context),
                    ),
                  ),
              ],
            ),
          ),

          // Content Section
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                // Show selected customer info card (bold name + balance)
                if (_selectedCustomer != null && !_generateBillViaContact) ...[
                  Container(
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.action(context).withValues(alpha: 0.08),
                          AppColors.action(context).withValues(alpha: 0.03),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.accentSoft(context, 0.15),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: AppColors.headerGradient(context),
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Center(
                            child: Text(
                              (_selectedCustomer!['fullName'] as String? ??
                                      '?')[0]
                                  .toUpperCase(),
                              style: TextStyle(
                                color: AppTheme.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                                fontFamily: 'Literata',
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _selectedCustomer!['fullName'] ?? '-',
                                style: TextStyle(
                                  fontFamily: 'Literata',
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                  color: AppColors.accent(context),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  Icon(
                                    Icons.phone_rounded,
                                    size: 12,
                                    color: AppTheme.grey,
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    _selectedCustomer!['contact'] ?? '-',
                                    style: TextStyle(
                                      fontFamily: 'Literata',
                                      fontSize: 12,
                                      color: AppTheme.grey600,
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
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppTheme.orange.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.account_balance_wallet_rounded,
                                        size: 12,
                                        color: AppTheme.orange700,
                                      ),
                                      const SizedBox(width: 3),
                                      Text(
                                        'Due: ₹${(_selectedCustomer!['pendingBalance'] as num).toDouble().toStringAsFixed(2)}',
                                        style: TextStyle(
                                          fontFamily: 'Literata',
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: AppTheme.orange700,
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
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AppTheme.red.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.close_rounded,
                              color: AppTheme.error,
                              size: 16,
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
                  // Normal customer section - tap to pick or enter manually
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: AppColors.scaffold(context),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.accentSoft(context, 0.2)),
          ),
          child: TextField(
            controller: _customerContactController,
            keyboardType: TextInputType.phone,
            maxLength: 10,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(10),
            ],
            style: TextStyle(fontFamily: 'Literata', fontSize: 12),
            decoration: InputDecoration(
              labelText: '${_localizations.enterPhoneNumber} *',
              hintText: '10 digit number',
              hintStyle: TextStyle(color: AppTheme.grey400, fontSize: 11),
              counterText: '',
              labelStyle: TextStyle(
                color: AppColors.accent(context),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
              prefixIcon: Container(
                margin: EdgeInsets.all(4),
                padding: EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.accentSoft(context, 0.1),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Icon(
                  Icons.phone_rounded,
                  color: AppColors.accent(context),
                  size: 14,
                ),
              ),
              suffixIcon: _isSearchingCustomer
                  ? Padding(
                      padding: EdgeInsets.all(8.0),
                      child: SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.accent(context),
                        ),
                      ),
                    )
                  : _hasPhoneText
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded, size: 16),
                      onPressed: () {
                        _customerContactController.clear();
                        setState(() {
                          _autoFoundCustomerName = null;
                          _selectedCustomer = null;
                          _hasPhoneText = false;
                        });
                      },
                      color: AppTheme.grey600,
                    )
                  : null,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 6,
              ),
              border: InputBorder.none,
              isDense: true,
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
      padding: const EdgeInsets.only(top: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppTheme.green.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppTheme.green.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.check_circle_rounded,
              size: 14,
              color: AppTheme.green,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                '${_localizations.customerColon} $_autoFoundCustomerName',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.green,
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
      padding: const EdgeInsets.only(top: 8),
      child: GestureDetector(
        onTap: () {
          final phone = _customerContactController.text.trim();
          _showAddCustomerDialog(phone);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: AppTheme.orange.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppTheme.orange.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.person_add_rounded,
                size: 14,
                color: AppTheme.orange700,
              ),
              const SizedBox(width: 6),
              Text(
                'Customer not found. Add new?',
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.orange700,
                  fontFamily: 'Literata',
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 3),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 10,
                color: AppTheme.orange700,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Customer picker section (normal mode)
  Widget _buildCustomerPickerSection(bool isCustomerRequired) {
    return Column(
      children: [
        // Search existing customer button
        GestureDetector(
          onTap: _showCustomerPicker,
          child: Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: AppColors.inputFill(context),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isCustomerRequired
                    ? AppTheme.red200
                    : AppColors.border(context),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _localizations.searchExistingCustomer,
                    style: TextStyle(
                      fontFamily: 'Literata',
                      color: AppColors.mutedText(context),
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Icon(
                  Icons.search_rounded,
                  color: AppColors.mutedText(context),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
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
            const SizedBox(width: 10),
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
                            padding: EdgeInsets.all(10.0),
                            child: SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.accent(context),
                              ),
                            ),
                          )
                        : _hasPhoneText
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 18),
                            onPressed: () {
                              _customerContactController.clear();
                              setState(() {
                                _autoFoundCustomerName = null;
                                _selectedCustomer = null;
                                _hasPhoneText = false;
                                _showAddCustomerPrompt = false;
                              });
                            },
                            color: AppTheme.grey,
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
                            color: AppTheme.green,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              _autoFoundCustomerName!,
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppTheme.green,
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
                              color: AppTheme.orange700,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Add new?',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppTheme.orange700,
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
    final isPhone = keyboardType == TextInputType.phone;
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.inputFill(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        maxLength: isPhone ? 10 : null,
        inputFormatters: isPhone
            ? [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(10),
              ]
            : null,
        style: TextStyle(
          fontFamily: 'Literata',
          fontSize: 14,
          color: AppColors.primaryText(context),
        ),
        decoration: InputDecoration(
          hintText: label,
          hintStyle: TextStyle(
            color: AppColors.mutedText(context),
            fontSize: 14,
          ),
          counterText: '',
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 12,
          ),
          filled: false,
          isDense: true,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          disabledBorder: InputBorder.none,
          errorBorder: InputBorder.none,
          focusedErrorBorder: InputBorder.none,
          suffixIcon: suffixIcon,
        ),
      ),
    );
  }

  // Add product by product code, manufacturer barcode, or app barcode. USB barcode readers type into the Add Items field and send Enter.
  Future<void> _addProductByIndexNoOnPage() async {
    final indexText = _indexNoController.text.trim();
    if (indexText.isEmpty || _isResolvingScan) return;
    _debounceTimer?.cancel();

    Product? product = _productByBarcode[indexText] ??
        _productByBarcode[indexText.toLowerCase()];

    final indexNo = int.tryParse(indexText);
    if (product == null && indexNo != null) {
      product = _productByIndexNo[indexNo];
    }

    // Fall back to full barcode service (manufacturer variants, generated EAN, etc.)
    final resolved = product;
    if (resolved == null) {
      _isResolvingScan = true;
      try {
        final scanned = await BarcodeService.instance.scanForBilling(indexText);
        if (!mounted) return;
        if (scanned != null) {
          _indexNoController.clear();
          _addScannedProductToBill(scanned);
          return;
        }
      } finally {
        _isResolvingScan = false;
      }

      _showSnackbar(
        indexNo != null
            ? '${_localizations.productNotFound} #$indexNo'
            : '${_localizations.productNotFound}: $indexText',
        isError: true,
      );
      _indexNoController.clear();
      _indexNoFocusNode.requestFocus();
      return;
    }

    // Check FIFO batch stock first
    final productBatches =
        _availableBatches
            .where((b) => b.productId == resolved.id && b.quantityRemaining > 0)
            .toList()
          ..sort((a, b) => a.purchaseDate.compareTo(b.purchaseDate));
    final batchStock = productBatches.fold<int>(
      0,
      (s, b) => s + b.quantityRemaining,
    );
    final effectiveStock = batchStock > 0 ? batchStock : resolved.currentStock;

    if (effectiveStock <= 0) {
      _showSnackbar(
        '${resolved.name} ${_localizations.outOfStock}',
        isError: true,
      );
      _indexNoController.clear();
      return;
    }

    // Show batch selection for all products with batches
    if (productBatches.isNotEmpty) {
      _indexNoController.clear();
      showAppBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: AppTheme.transparent,
        builder: (ctx) => BatchSelectionSheet(
          productName: resolved.name,
          productCode: resolved.indexNo,
          batches: productBatches,
          localizations: _localizations,
          existingBillItems: _billItems,
          cgstPercent: resolved.cgstPercent,
          sgstPercent: resolved.sgstPercent,
          hsnCode: resolved.hsnCode,
          unit: resolved.unit,
          onBatchSelected: (batch, quantity, sellUnit) {
            final uniqueKey = '${resolved.id}_batch_${batch.id}';
            final existingIndex = _billItems.indexWhere(
              (item) => item.productId == uniqueKey,
            );
            setState(() {
              _ensureGstModeForProductTax(
                cgstPercent: resolved.cgstPercent,
                sgstPercent: resolved.sgstPercent,
              );
              if (existingIndex != -1) {
                final prev = _billItems[existingIndex];
                _billItems[existingIndex] = BillItem.create(
                  productId: uniqueKey,
                  productName: resolved.name,
                  companyName: batch.companyName.isNotEmpty
                      ? batch.companyName
                      : null,
                  sellingPrice: batch.sellingPrice,
                  purchasePrice: batch.purchasePrice,
                  quantity: quantity,
                  cgstPercent: resolved.cgstPercent,
                  sgstPercent: resolved.sgstPercent,
                  hsnCode: resolved.hsnCode,
                  unit: resolved.unit,
                  sellUnit: sellUnit,
                  employeeToken: prev.employeeToken,
                );
              } else {
                _billItems.add(
                  BillItem.create(
                    productId: uniqueKey,
                    productName: resolved.name,
                    companyName: batch.companyName.isNotEmpty
                        ? batch.companyName
                        : null,
                    sellingPrice: batch.sellingPrice,
                    purchasePrice: batch.purchasePrice,
                    quantity: quantity,
                    cgstPercent: resolved.cgstPercent,
                    sgstPercent: resolved.sgstPercent,
                    hsnCode: resolved.hsnCode,
                    unit: resolved.unit,
                    sellUnit: sellUnit,
                  ),
                );
              }
            });
            Navigator.pop(ctx);
            _showSnackbar(
              '${_localizations.added}: ${resolved.name}',
              isError: false,
            );
            _focusAfterProductAdded(uniqueKey);
          },
          onItemRemoved: (uniqueKey) {
            _disposeItemTokenInputs(uniqueKey);
            setState(() {
              _billItems.removeWhere((item) => item.productId == uniqueKey);
            });
          },
        ),
      );
      return;
    }

    // No batches - fallback to product-level data
    final fifoPrice = resolved.salesPrice;
    final fifoPurchasePrice = resolved.purchasePrice;
    final uniqueKey = resolved.id;

    // Add product - increment quantity if already in cart
    final existingIndex = _billItems.indexWhere(
      (item) => item.productId == uniqueKey,
    );
    setState(() {
      _ensureGstModeForProductTax(
        cgstPercent: resolved.cgstPercent,
        sgstPercent: resolved.sgstPercent,
      );
      if (existingIndex != -1) {
        final existing = _billItems[existingIndex];
        // Determine step based on current sellUnit
        final step = (existing.sellUnit == 'gm' || existing.sellUnit == 'ml')
            ? 0.1
            : 1.0;
        if (existing.quantity + step <= effectiveStock) {
          _billItems[existingIndex] = BillItem.create(
            productId: uniqueKey,
            productName: resolved.name,
            companyName: resolved.companyName.isNotEmpty
                ? resolved.companyName
                : null,
            sellingPrice: existing.sellingPrice,
            purchasePrice: fifoPurchasePrice,
            quantity: existing.quantity + step,
            cgstPercent: resolved.cgstPercent,
            sgstPercent: resolved.sgstPercent,
            hsnCode: resolved.hsnCode,
            unit: existing.unit ?? resolved.unit,
            sellUnit: existing.sellUnit ?? resolved.unit,
            employeeToken: existing.employeeToken,
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
            productName: resolved.name,
            companyName: resolved.companyName.isNotEmpty
                ? resolved.companyName
                : null,
            sellingPrice: fifoPrice,
            purchasePrice: fifoPurchasePrice,
            quantity: 1,
            cgstPercent: resolved.cgstPercent,
            sgstPercent: resolved.sgstPercent,
            hsnCode: resolved.hsnCode,
            unit: resolved.unit,
            sellUnit: resolved.unit,
          ),
        );
      }
    });

    _showSnackbar('${_localizations.added}: ${resolved.name}', isError: false);

    // Clear input; focus this line's token (if needed) or index for next entry
    _indexNoController.clear();
    _focusAfterProductAdded(uniqueKey);
  }

  void _onPageIndexNoChanged() {
    _debounceTimer?.cancel();
    final text = _indexNoController.text.trim();
    if (text.isEmpty) return;
    // Short codes = product index (wait for typing). Longer = likely barcode wedge (fast pause).
    final delayMs = text.length >= 8 ? 200 : 800;
    _debounceTimer = Timer(Duration(milliseconds: delayMs), () {
      _addProductByIndexNoOnPage();
    });
  }

  Widget _buildAddItemsSection({bool nested = false}) {
    // Hover and focus share the same highlight so the field never “flashes” a different color.
    final highlighted =
        _indexNoFocusNode.hasFocus || _addItemsSearchHovered;
    final accent = AppColors.actionBright(context);
    return Container(
      margin: nested
          ? EdgeInsets.zero
          : const EdgeInsets.fromLTRB(16, 6, 16, 6),
      decoration: BoxDecoration(
        color: nested ? AppColors.scaffold(context) : AppColors.card(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppTheme.headerDarkStart,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.shopping_cart_outlined,
                    color: AppTheme.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _localizations.addItems,
                        style: TextStyle(
                          fontFamily: 'Literata',
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: AppColors.primaryText(context),
                        ),
                      ),
                      Text(
                        _localizations.quickAddByCodeOrSearch,
                        style: TextStyle(
                          fontFamily: 'Literata',
                          fontSize: 12,
                          color: AppColors.mutedText(context),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            child: Row(
              children: [
                Expanded(
                  child: MouseRegion(
                    cursor: SystemMouseCursors.text,
                    onEnter: (_) {
                      if (!_addItemsSearchHovered) {
                        setState(() => _addItemsSearchHovered = true);
                      }
                    },
                    onExit: (_) {
                      if (_addItemsSearchHovered) {
                        setState(() => _addItemsSearchHovered = false);
                      }
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 120),
                      curve: Curves.easeOut,
                      height: 48,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: highlighted
                            ? accent.withValues(alpha: 0.08)
                            : AppColors.inputFill(context),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: highlighted
                              ? accent
                              : AppColors.border(context),
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.qr_code_2_rounded,
                            size: 18,
                            color: highlighted
                                ? accent
                                : AppColors.mutedText(context),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: _indexNoController,
                              focusNode: _indexNoFocusNode,
                              keyboardType: TextInputType.text,
                              cursorColor: accent,
                              mouseCursor: SystemMouseCursors.text,
                              style: TextStyle(
                                fontFamily: 'Literata',
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primaryText(context),
                              ),
                              decoration: InputDecoration(
                                hintText: DesktopCanvas.isDesktopPlatform
                                    ? 'Scan barcode or enter product code'
                                    : 'Product code or barcode',
                                hintStyle: TextStyle(
                                  color: AppColors.mutedText(context),
                                  fontWeight: FontWeight.w400,
                                  fontSize: 14,
                                ),
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                hoverColor: AppTheme.transparent,
                                fillColor: AppTheme.transparent,
                                filled: true,
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                              ),
                              onChanged: (_) => _onPageIndexNoChanged(),
                              onSubmitted: (_) =>
                                  _addProductByIndexNoOnPage(),
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: _showAddItemsPopup,
                            child: Icon(
                              Icons.search_rounded,
                              color: highlighted
                                  ? accent
                                  : AppColors.mutedText(context),
                              size: 20,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Material(
                  color: AppColors.action(context),
                  borderRadius: BorderRadius.circular(14),
                  child: InkWell(
                    onTap: _showBarcodeScannerSheet,
                    borderRadius: BorderRadius.circular(14),
                    child: const SizedBox(
                      width: 48,
                      height: 48,
                      child: Icon(
                        Icons.qr_code_scanner_rounded,
                        color: AppTheme.white,
                        size: 22,
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
      margin: const EdgeInsets.fromLTRB(16, 6, 16, 6),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 8, 4),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppTheme.paletteFF1A2438,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.receipt_long_outlined,
                    color: AppTheme.toneBlue,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _localizations.billItems,
                        style: TextStyle(
                          fontFamily: 'Literata',
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: AppColors.primaryText(context),
                        ),
                      ),
                      Text(
                        '${_billItems.length} ${_localizations.items.toLowerCase()} added',
                        style: TextStyle(
                          fontFamily: 'Literata',
                          fontSize: 12,
                          color: AppColors.mutedText(context),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () {
                    setState(() => _billItems.clear());
                  },
                  icon: Icon(
                    Icons.delete_outline_rounded,
                    color: AppColors.mutedText(context),
                    size: 22,
                  ),
                ),
              ],
            ),
          ),
          // Compact Items List
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(vertical: 6),
            itemCount: _billItems.length,
            separatorBuilder: (_, _) => Divider(
              height: 1,
              thickness: 0.5,
              indent: 12,
              endIndent: 12,
              color: AppTheme.grey.withValues(alpha: 0.12),
            ),
            itemBuilder: (context, index) {
              final item = _billItems[index];
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

              int maxStock;
              final parts = item.productId.split('_batch_');
              final batchLocalId = parts.length > 1
                  ? int.tryParse(parts.last)
                  : null;
              if (batchLocalId != null) {
                final batch = _availableBatches
                    .cast<PurchaseBatchEntity?>()
                    .firstWhere(
                      (b) => b!.id == batchLocalId && b.quantityRemaining > 0,
                      orElse: () => null,
                    );
                maxStock = batch?.quantityRemaining ?? 0;
              } else {
                final batchStock = _availableBatches
                    .where(
                      (b) =>
                          b.productId == realProductId &&
                          b.quantityRemaining > 0,
                    )
                    .fold<int>(0, (s, b) => s + b.quantityRemaining);
                maxStock = batchStock > 0 ? batchStock : product.currentStock;
              }

              return Dismissible(
                key: Key('${item.productId}_$index'),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 16),
                  color: AppTheme.error,
                  child: const Icon(
                    Icons.delete_outline_rounded,
                    color: AppTheme.white,
                    size: 20,
                  ),
                ),
                onDismissed: (_) {
                  _disposeItemTokenInputs(item.productId);
                  setState(() => _billItems.removeAt(index));
                },
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: AppColors.inputFill(context),
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              '${index + 1}',
                              style: TextStyle(
                                fontFamily: 'Literata',
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.secondaryText(context),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  item.productName,
                                  style: TextStyle(
                                    fontFamily: 'Literata',
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                    color: AppColors.primaryText(context),
                                    height: 1.2,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                GestureDetector(
                                  onTap: () => _showEditSellPriceDialog(
                                    index: index,
                                    item: item,
                                  ),
                                  child: Row(
                                    children: [
                                      Text(
                                        '₹${item.sellingPrice.toStringAsFixed(0)} / ${item.displayUnit.isEmpty ? 'unit' : item.displayUnit}',
                                        style: TextStyle(
                                          fontFamily: 'Literata',
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.action(context),
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Icon(
                                        Icons.edit_outlined,
                                        size: 12,
                                        color: AppColors.mutedText(context),
                                      ),
                                      if (item.cgstPercent > 0 ||
                                          item.sgstPercent > 0) ...[
                                        const SizedBox(width: 6),
                                        Text(
                                          '${(item.cgstPercent + item.sgstPercent).toStringAsFixed(0)}%',
                                          style: const TextStyle(
                                            fontFamily: 'Literata',
                                            fontSize: 11,
                                            color: AppTheme.toneAmber,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '₹${item.subtotal.toStringAsFixed(0)}',
                            style: TextStyle(
                              fontFamily: 'Literata',
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                              color: AppColors.primaryText(context),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          GestureDetector(
                            onTap: () {
                              final step =
                                  (item.sellUnit == 'gm' ||
                                      item.sellUnit == 'ml')
                                  ? 0.1
                                  : 1.0;
                              if (item.quantity > step) {
                                setState(() {
                                  _billItems[index] = BillItem.create(
                                    productId: item.productId,
                                    productName: item.productName,
                                    companyName: item.companyName,
                                    sellingPrice: item.sellingPrice,
                                    purchasePrice: item.purchasePrice,
                                    quantity: item.quantity - step,
                                    cgstPercent: item.cgstPercent,
                                    sgstPercent: item.sgstPercent,
                                    hsnCode: item.hsnCode,
                                    unit: item.unit,
                                    sellUnit: item.sellUnit,
                                    employeeToken: item.employeeToken,
                                  );
                                });
                              } else {
                                _disposeItemTokenInputs(item.productId);
                                setState(() => _billItems.removeAt(index));
                              }
                            },
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppColors.border(context),
                                ),
                              ),
                              child: Icon(
                                Icons.remove,
                                size: 16,
                                color: AppColors.primaryText(context),
                              ),
                            ),
                          ),
                          _InlineQuantityField(
                            item: item,
                            maxStock: maxStock,
                            onQuantityChanged: (newQty) {
                              setState(() {
                                _billItems[index] = BillItem.create(
                                  productId: item.productId,
                                  productName: item.productName,
                                  companyName: item.companyName,
                                  sellingPrice: item.sellingPrice,
                                  purchasePrice: item.purchasePrice,
                                  quantity: newQty,
                                  cgstPercent: item.cgstPercent,
                                  sgstPercent: item.sgstPercent,
                                  hsnCode: item.hsnCode,
                                  unit: item.unit,
                                  sellUnit: item.sellUnit,
                                  employeeToken: item.employeeToken,
                                );
                              });
                            },
                            onRemoveItem: () {
                              _disposeItemTokenInputs(item.productId);
                              setState(() => _billItems.removeAt(index));
                            },
                          ),
                          GestureDetector(
                            onTap: () {
                              final step =
                                  (item.sellUnit == 'gm' ||
                                      item.sellUnit == 'ml')
                                  ? 0.1
                                  : 1.0;
                              if (item.quantity + step <= maxStock) {
                                setState(() {
                                  _billItems[index] = BillItem.create(
                                    productId: item.productId,
                                    productName: item.productName,
                                    companyName: item.companyName,
                                    sellingPrice: item.sellingPrice,
                                    purchasePrice: item.purchasePrice,
                                    quantity: item.quantity + step,
                                    cgstPercent: item.cgstPercent,
                                    sgstPercent: item.sgstPercent,
                                    hsnCode: item.hsnCode,
                                    unit: item.unit,
                                    sellUnit: item.sellUnit,
                                  employeeToken: item.employeeToken,
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
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: item.quantity < maxStock
                                    ? AppColors.action(context)
                                    : AppColors.chipFill(context),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.add,
                                size: 16,
                                color: item.quantity < maxStock
                                    ? AppTheme.white
                                    : AppColors.mutedText(context),
                              ),
                            ),
                          ),
                        ],
                      ),
                      // Inline unit selector for kg/ltr products
                      if (item.unit?.toLowerCase() == 'kg' ||
                          item.unit?.toLowerCase() == 'ltr')
                        _buildInlineUnitSelector(
                          index: index,
                          item: item,
                          maxStock: maxStock,
                        ),
                      if (_enableEmployeeToken) ...[
                        const SizedBox(height: 8),
                        _buildItemEmployeeTokenField(index, item),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
          // Footer with total
          Container(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: AppColors.border(context)),
              ),
            ),
            child: Row(
              children: [
                Text(
                  '$_totalQuantity ${_localizations.items.toLowerCase()}',
                  style: TextStyle(
                    fontFamily: 'Literata',
                    fontSize: 13,
                    color: AppColors.secondaryText(context),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                Text(
                  '${_localizations.subtotal}  ₹${_totalAmount.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontFamily: 'Literata',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryText(context),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemEmployeeTokenField(int index, BillItem item) {
    final ctrl = _tokenControllerFor(item.productId, item.employeeToken);
    final focus = _tokenFocusFor(item.productId);
    final name = _itemTokenNames[item.productId];
    // ₹1000 sales = 1 point
    final linePts =
        ((item.sellingPrice * item.quantity) / 1000).toStringAsFixed(2);
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      decoration: BoxDecoration(
        color: AppColors.action(context).withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.confirmation_number_outlined,
                size: 16,
                color: AppColors.action(context),
              ),
              const SizedBox(width: 6),
              Text(
                'Emp token',
                style: TextStyle(
                  fontFamily: 'Literata',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryText(context),
                ),
              ),
              const Spacer(),
              Text(
                '+$linePts pts',
                style: TextStyle(
                  fontFamily: 'Literata',
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.mutedText(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          TextField(
            controller: ctrl,
            focusNode: focus,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.next,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged: (_) => _onItemTokenChanged(index, item.productId),
            decoration: InputDecoration(
              hintText: 'Token #',
              isDense: true,
              filled: true,
              fillColor: AppColors.card(context),
              prefixIcon: const Icon(Icons.tag_rounded, size: 18),
              suffixIcon: name != null
                  ? const Icon(
                      Icons.check_circle_rounded,
                      color: AppTheme.green,
                      size: 18,
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 10,
              ),
            ),
          ),
          if (name != null) ...[
            const SizedBox(height: 4),
            Text(
              name,
              style: const TextStyle(
                fontFamily: 'Literata',
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppTheme.green,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Build inline unit selector chips for kg/ltr products
  Widget _buildInlineUnitSelector({
    required int index,
    required BillItem item,
    required int maxStock,
  }) {
    final unit = item.unit?.toLowerCase() ?? '';
    final isKg = unit == 'kg';
    final subUnit = isKg ? 'gm' : 'ml';
    final unitLabel = isKg ? 'kg' : 'ltr';

    // Quick options in grams/ml
    final quickOptions = [250, 500, 750];

    // Current quantity in grams/ml
    final currentInSubUnit = (item.quantity * 1000).round();

    // Check if current is a custom value (not one of quick options and not whole kg/ltr)
    final isCustomValue =
        !quickOptions.contains(currentInSubUnit) &&
        currentInSubUnit % 1000 != 0;

    return Padding(
      padding: const EdgeInsets.only(top: 6, left: 30),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            // Quick option chips
            ...quickOptions.map((grams) {
              final isSelected = currentInSubUnit == grams;
              final qtyInBase = grams / 1000.0; // Convert to kg/ltr
              final isAvailable = qtyInBase <= maxStock;

              return Padding(
                padding: const EdgeInsets.only(right: 6),
                child: GestureDetector(
                  onTap: isAvailable
                      ? () {
                          setState(() {
                            _billItems[index] = BillItem.create(
                              productId: item.productId,
                              productName: item.productName,
                              companyName: item.companyName,
                              sellingPrice: item.sellingPrice,
                              purchasePrice: item.purchasePrice,
                              quantity: qtyInBase,
                              cgstPercent: item.cgstPercent,
                              sgstPercent: item.sgstPercent,
                              hsnCode: item.hsnCode,
                              unit: item.unit,
                              sellUnit: subUnit,
                            employeeToken: item.employeeToken,
                            );
                          });
                        }
                      : null,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.action(context)
                          : isAvailable
                          ? AppColors.action(context).withValues(alpha: 0.08)
                          : AppColors.border(context),
                      borderRadius: BorderRadius.circular(6),
                      border: isSelected
                          ? null
                          : Border.all(
                              color: isAvailable
                                  ? AppColors.action(context).withValues(alpha: 0.2)
                                  : AppTheme.grey300,
                            ),
                    ),
                    child: Text(
                      '$grams$subUnit',
                      style: TextStyle(
                        fontFamily: 'Literata',
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? AppTheme.white
                            : isAvailable
                            ? AppColors.action(context)
                            : AppTheme.grey,
                      ),
                    ),
                  ),
                ),
              );
            }),
            // 1 kg/ltr option
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: GestureDetector(
                onTap: maxStock >= 1
                    ? () {
                        setState(() {
                          _billItems[index] = BillItem.create(
                            productId: item.productId,
                            productName: item.productName,
                            companyName: item.companyName,
                            sellingPrice: item.sellingPrice,
                            purchasePrice: item.purchasePrice,
                            quantity: 1.0,
                            cgstPercent: item.cgstPercent,
                            sgstPercent: item.sgstPercent,
                            hsnCode: item.hsnCode,
                            unit: item.unit,
                            sellUnit: unit,
                          employeeToken: item.employeeToken,
                          );
                        });
                      }
                    : null,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color:
                        item.quantity == 1.0 &&
                            (item.sellUnit == 'kg' || item.sellUnit == 'ltr')
                        ? AppColors.action(context)
                        : maxStock >= 1
                        ? AppColors.action(context).withValues(alpha: 0.08)
                        : AppColors.border(context),
                    borderRadius: BorderRadius.circular(6),
                    border:
                        item.quantity == 1.0 &&
                            (item.sellUnit == 'kg' || item.sellUnit == 'ltr')
                        ? null
                        : Border.all(
                            color: maxStock >= 1
                                ? AppColors.action(context).withValues(alpha: 0.2)
                                : AppTheme.grey300,
                          ),
                  ),
                  child: Text(
                    '1$unitLabel',
                    style: TextStyle(
                      fontFamily: 'Literata',
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color:
                          item.quantity == 1.0 &&
                              (item.sellUnit == 'kg' || item.sellUnit == 'ltr')
                          ? AppTheme.white
                          : maxStock >= 1
                          ? AppColors.action(context)
                          : AppTheme.grey,
                    ),
                  ),
                ),
              ),
            ),
            // Custom entry button
            GestureDetector(
              onTap: () => _showCustomUnitDialog(
                index: index,
                item: item,
                maxStock: maxStock,
              ),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isCustomValue
                      ? AppTheme.paletteFF7B68EE
                      : AppColors.chipFill(context),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isCustomValue
                        ? AppTheme.paletteFF7B68EE
                        : AppTheme.grey300,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.edit_rounded,
                      size: 10,
                      color: isCustomValue ? AppTheme.white : AppTheme.grey600,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      isCustomValue ? '$currentInSubUnit$subUnit' : subUnit,
                      style: TextStyle(
                        fontFamily: 'Literata',
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: isCustomValue ? AppTheme.white : AppTheme.grey600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Show custom unit entry dialog
  void _showCustomUnitDialog({
    required int index,
    required BillItem item,
    required int maxStock,
  }) {
    final unit = item.unit?.toLowerCase() ?? '';
    final isKg = unit == 'kg';
    final subUnit = isKg ? 'gm' : 'ml';

    // Current quantity in grams/ml
    final currentInSubUnit = (item.quantity * 1000).round();
    final controller = TextEditingController(text: currentInSubUnit.toString());
    String? errorText;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          void validate() {
            final value = int.tryParse(controller.text) ?? 0;
            final maxInSubUnit = maxStock * 1000;
            setDialogState(() {
              if (value <= 0) {
                errorText = _localizations.enterValidAmount;
              } else if (value > maxInSubUnit) {
                errorText = '${_localizations.maxStock}: $maxInSubUnit$subUnit';
              } else {
                errorText = null;
              }
            });
          }

          return AlertDialog(
            backgroundColor: AppColors.card(context),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Text(
              'Enter $subUnit',
              style: TextStyle(
                fontFamily: 'Literata',
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryText(context),
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  autofocus: true,
                  onChanged: (_) => validate(),
                  style: TextStyle(
                    fontFamily: 'Literata',
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.accent(context),
                  ),
                  decoration: InputDecoration(
                    errorText: errorText,
                    suffixText: subUnit,
                    suffixStyle: TextStyle(
                      fontFamily: 'Literata',
                      fontSize: 14,
                      color: AppTheme.grey600,
                    ),
                    filled: true,
                    fillColor: AppColors.scaffold(context),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: AppColors.accent(context),
                        width: 2,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Max: ${maxStock * 1000}$subUnit ($maxStock${isKg ? 'kg' : 'ltr'})',
                  style: TextStyle(
                    fontFamily: 'Literata',
                    fontSize: 11,
                    color: AppTheme.grey,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(
                  _localizations.cancel,
                  style: TextStyle(
                    fontFamily: 'Literata',
                    color: AppTheme.grey600,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: errorText == null
                    ? () {
                        final value = int.tryParse(controller.text) ?? 0;
                        if (value > 0) {
                          final qtyInBase = value / 1000.0;
                          setState(() {
                            _billItems[index] = BillItem.create(
                              productId: item.productId,
                              productName: item.productName,
                              companyName: item.companyName,
                              sellingPrice: item.sellingPrice,
                              purchasePrice: item.purchasePrice,
                              quantity: qtyInBase,
                              cgstPercent: item.cgstPercent,
                              sgstPercent: item.sgstPercent,
                              hsnCode: item.hsnCode,
                              unit: item.unit,
                              sellUnit: subUnit,
                            employeeToken: item.employeeToken,
                            );
                          });
                          Navigator.pop(ctx);
                        }
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.action(context),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  _localizations.done,
                  style: const TextStyle(
                    fontFamily: 'Literata',
                    color: AppTheme.white,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // Show dialog to edit sell price for a bill item
  void _showEditSellPriceDialog({required int index, required BillItem item}) {
    final priceController = TextEditingController(
      text: item.sellingPrice.toStringAsFixed(2),
    );
    String? errorText;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          void validatePrice() {
            final price = double.tryParse(priceController.text) ?? 0;
            setDialogState(() {
              if (price <= 0) {
                errorText = _localizations.pleaseEnterValidPrice;
              } else {
                errorText = null;
              }
            });
          }

          return AlertDialog(
            backgroundColor: AppColors.card(context),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            title: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: AppColors.headerGradient(context),
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.accentSoft(context, 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.currency_rupee_rounded,
                    color: AppTheme.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${_localizations.edit} ${_localizations.price}',
                        style: TextStyle(
                          fontFamily: 'Literata',
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryText(context),
                        ),
                      ),
                      Text(
                        item.productName,
                        style: TextStyle(
                          fontFamily: 'Literata',
                          fontSize: 12,
                          color: AppTheme.grey600,
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
                // Info row showing current quantity and subtotal
                Container(
                  padding: EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.scaffold(context),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppTheme.grey.withValues(alpha: 0.1),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _localizations.quantity,
                            style: TextStyle(
                              fontFamily: 'Literata',
                              fontSize: 11,
                              color: AppTheme.grey,
                            ),
                          ),
                          Text(
                            '${item.quantity}',
                            style: TextStyle(
                              fontFamily: 'Literata',
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                              color: AppColors.accent(context),
                            ),
                          ),
                        ],
                      ),
                      Container(
                        width: 1,
                        height: 36,
                        color: AppColors.border(context),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            _localizations.subtotal,
                            style: TextStyle(
                              fontFamily: 'Literata',
                              fontSize: 11,
                              color: AppTheme.grey,
                            ),
                          ),
                          Text(
                            '₹${((double.tryParse(priceController.text) ?? item.sellingPrice) * item.quantity).toStringAsFixed(0)}',
                            style: TextStyle(
                              fontFamily: 'Literata',
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                              color: AppTheme.blue700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                // Price input field
                TextField(
                  controller: priceController,
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  textAlign: TextAlign.center,
                  autofocus: true,
                  onChanged: (_) => validatePrice(),
                  style: TextStyle(
                    fontFamily: 'Literata',
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: AppColors.accent(context),
                  ),
                  decoration: InputDecoration(
                    prefixText: '₹ ',
                    prefixStyle: TextStyle(
                      fontFamily: 'Literata',
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: AppColors.accent(context),
                    ),
                    errorText: errorText,
                    errorStyle: TextStyle(fontSize: 11),
                    filled: true,
                    fillColor: AppColors.scaffold(context),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: AppTheme.grey300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(
                        color: AppColors.accent(context),
                        width: 2,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: AppColors.border(context)),
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              // Reset to original button
              TextButton.icon(
                onPressed: () {
                  // Find original product price
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
                      currentStock: 0,
                      createdAt: DateTime.now(),
                      updatedAt: DateTime.now(),
                    ),
                  );
                  priceController.text = product.salesPrice.toStringAsFixed(2);
                  validatePrice();
                },
                icon: Icon(
                  Icons.refresh_rounded,
                  color: AppTheme.orange700,
                  size: 20,
                ),
                label: Text(
                  _localizations.reset,
                  style: TextStyle(
                    fontFamily: 'Literata',
                    color: AppTheme.orange700,
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
                    color: AppTheme.grey600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Update button
              ElevatedButton(
                onPressed: errorText == null
                    ? () {
                        final price =
                            double.tryParse(priceController.text) ?? 0;
                        if (price > 0) {
                          setState(() {
                            _billItems[index] = BillItem.create(
                              productId: item.productId,
                              productName: item.productName,
                              companyName: item.companyName,
                              sellingPrice: price,
                              purchasePrice: item.purchasePrice,
                              quantity: item.quantity,
                              cgstPercent: item.cgstPercent,
                              sgstPercent: item.sgstPercent,
                              hsnCode: item.hsnCode,
                            unit: item.unit,
                            sellUnit: item.sellUnit,
                            employeeToken: item.employeeToken,
                            );
                          });
                          Navigator.pop(ctx);
                          _showSnackbar(
                            'Price updated to ₹${price.toStringAsFixed(0)}',
                            isError: false,
                          );
                        }
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.action(context),
                  foregroundColor: AppTheme.white,
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
                  style: TextStyle(
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

  Widget _buildExtraChargesSection({bool compact = false}) {
    final action = AppColors.action(context);
    return Container(
      margin: compact
          ? const EdgeInsets.fromLTRB(0, 0, 0, 12)
          : const EdgeInsets.fromLTRB(16, 6, 16, 6),
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 8, 8),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppTheme.headerDarkStart,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.add_card_rounded,
                    color: AppTheme.white,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Other charges',
                        style: TextStyle(
                          fontFamily: 'Literata',
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: AppColors.primaryText(context),
                        ),
                      ),
                      Text(
                        'Labour, loading, service…',
                        style: TextStyle(
                          fontFamily: 'Literata',
                          fontSize: 12,
                          color: AppColors.mutedText(context),
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: _extraChargesEnabled,
                  onChanged: (v) {
                    setState(() {
                      _extraChargesEnabled = v;
                      if (v && _extraChargeDrafts.isEmpty) {
                        _extraChargeDrafts.add(_ExtraChargeDraft());
                      }
                      if (!v) {
                        _disposeExtraChargeDrafts();
                      }
                    });
                  },
                  activeThumbColor: AppTheme.white,
                  activeTrackColor: action,
                  inactiveThumbColor: AppColors.isDark(context)
                      ? AppTheme.grey
                      : AppTheme.white,
                  inactiveTrackColor: AppColors.isDark(context)
                      ? AppTheme.white24
                      : AppTheme.grey300,
                  trackOutlineColor: WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.selected)) {
                      return AppTheme.transparent;
                    }
                    return AppColors.border(context);
                  }),
                ),
              ],
            ),
          ),
          if (_extraChargesEnabled) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Column(
                children: [
                  for (final draft in _extraChargeDrafts) ...[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 3,
                          child: TextField(
                            controller: draft.labelController,
                            style: TextStyle(
                              fontFamily: 'Literata',
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primaryText(context),
                            ),
                            decoration: InputDecoration(
                              hintText: 'Charge name',
                              hintStyle: TextStyle(
                                fontFamily: 'Literata',
                                fontSize: 12,
                                color: AppColors.mutedText(context),
                              ),
                              filled: true,
                              fillColor: AppColors.inputFill(context),
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 10,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: AppColors.border(context),
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: AppColors.border(context),
                                ),
                              ),
                            ),
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 2,
                          child: TextField(
                            controller: draft.amountController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                RegExp(r'^\d*\.?\d{0,2}'),
                              ),
                            ],
                            style: TextStyle(
                              fontFamily: 'Literata',
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primaryText(context),
                            ),
                            decoration: InputDecoration(
                              hintText: '0.00',
                              prefixText: '₹ ',
                              hintStyle: TextStyle(
                                fontFamily: 'Literata',
                                fontSize: 12,
                                color: AppColors.mutedText(context),
                              ),
                              filled: true,
                              fillColor: AppColors.inputFill(context),
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 10,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: AppColors.border(context),
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: AppColors.border(context),
                                ),
                              ),
                            ),
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                        IconButton(
                          onPressed: _extraChargeDrafts.length <= 1
                              ? null
                              : () => _removeExtraChargeRow(draft.id),
                          icon: Icon(
                            Icons.close_rounded,
                            size: 18,
                            color: AppColors.mutedText(context),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: _addExtraChargeRow,
                      icon: Icon(Icons.add_rounded, size: 18, color: action),
                      label: Text(
                        'Add charge',
                        style: TextStyle(
                          fontFamily: 'Literata',
                          fontWeight: FontWeight.w700,
                          color: action,
                        ),
                      ),
                    ),
                  ),
                  if (_extraChargesTotal > 0)
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        'Other charges: ₹${_extraChargesTotal.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontFamily: 'Literata',
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                          color: AppColors.primaryText(context),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDiscountSection({bool showNestedSummary = true}) {
    return Container(
      margin: showNestedSummary
          ? const EdgeInsets.fromLTRB(16, 6, 16, 6)
          : const EdgeInsets.fromLTRB(0, 0, 0, 12),
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppTheme.headerDarkStart,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.local_offer_outlined,
                    color: AppTheme.white,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _localizations.discount,
                        style: TextStyle(
                          fontFamily: 'Literata',
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: AppColors.primaryText(context),
                        ),
                      ),
                      Text(
                        _localizations.applyDiscountToBill,
                        style: TextStyle(
                          fontFamily: 'Literata',
                          fontSize: 12,
                          color: AppColors.mutedText(context),
                        ),
                      ),
                    ],
                  ),
                ),
                if (_discountAmount > 0)
                  Text(
                    '-₹${_discountAmount.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontFamily: 'Literata',
                      fontSize: 14,
                      color: AppColors.action(context),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
              ],
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Row(
                  children: [
                    // Discount type toggle
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppColors.chipFill(context),
                        borderRadius: BorderRadius.circular(24),
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
                    const SizedBox(width: 10),
                    // Discount input
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.inputFill(context),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.border(context)),
                        ),
                        child: TextField(
                          controller: _discountController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          style: TextStyle(
                            fontFamily: 'Literata',
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryText(context),
                          ),
                          onChanged: _updateDiscount,
                          decoration: InputDecoration(
                            hintText: _isPercentageDiscount
                                ? _localizations.enterPercent
                                : _localizations.enterAmount,
                            hintStyle: TextStyle(
                              color: AppTheme.grey400,
                              fontSize: 12,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 10,
                            ),
                            border: InputBorder.none,
                            suffixIcon: _discountController.text.isNotEmpty
                                ? IconButton(
                                    icon: Icon(
                                      Icons.clear_rounded,
                                      size: 16,
                                      color: AppTheme.grey,
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
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _buildQuickDiscountChip('5%', 5, true),
                    _buildQuickDiscountChip('10%', 10, true),
                    _buildQuickDiscountChip('15%', 15, true),
                    _buildQuickDiscountChip('20%', 20, true),
                  ],
                ),
                // Nested summary (mobile layout only - desktop already has Bill summary)
                if (showNestedSummary &&
                    (_discountAmount > 0 || _taxBreakdown != null)) ...[
                  const SizedBox(height: 12),
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
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.inputFill(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border(context)),
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
              valueColor: AppColors.action(context),
            ),
          ],
          // GST breakdown
          if (_taxBreakdown != null) ...[
            const SizedBox(height: 10),
            Divider(color: AppTheme.grey300, height: 1),
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
                    color: AppTheme.grey600,
                  ),
                ),
              ),
            if (_taxBreakdown!.cgstAmount > 0)
              _buildTaxRow(
                _taxBreakdown!.cgstPercent > 0
                    ? '${_localizations.cgst} (${_taxBreakdown!.cgstPercent.toStringAsFixed(1)}%)'
                    : _localizations.cgst,
                _taxBreakdown!.cgstAmount,
              ),
            if (_taxBreakdown!.sgstAmount > 0)
              _buildTaxRow(
                _taxBreakdown!.sgstPercent > 0
                    ? '${_localizations.sgst} (${_taxBreakdown!.sgstPercent.toStringAsFixed(1)}%)'
                    : _localizations.sgst,
                _taxBreakdown!.sgstAmount,
              ),
            if (_taxBreakdown!.otherTaxAmount > 0)
              _buildTaxRow(
                _taxBreakdown!.otherTaxPercent > 0
                    ? '${_taxBreakdown!.otherTaxName.isNotEmpty ? _taxBreakdown!.otherTaxName : _localizations.totalTax} (${_taxBreakdown!.otherTaxPercent.toStringAsFixed(1)}%)'
                    : (_taxBreakdown!.otherTaxName.isNotEmpty
                          ? _taxBreakdown!.otherTaxName
                          : _localizations.totalTax),
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
                    color: AppTheme.orange700,
                  ),
                ),
              ),
          ],
          if (_extraChargesTotal > 0) ...[
            const SizedBox(height: 10),
            for (final charge in _validExtraCharges) ...[
              _buildSummaryRow(
                charge.label,
                '₹${charge.amount.toStringAsFixed(2)}',
              ),
              const SizedBox(height: 6),
            ],
          ],
          SizedBox(height: 12),
          Divider(color: AppTheme.grey300, height: 1),
          SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _localizations.finalTotal,
                style: TextStyle(
                  fontFamily: 'Literata',
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.accent(context),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: AppColors.headerGradient(context),
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '₹${_finalAmount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontFamily: 'Literata',
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.white,
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
            color: AppColors.secondaryText(context),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontFamily: 'Literata',
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: valueColor ?? AppColors.primaryText(context),
          ),
        ),
      ],
    );
  }

  // Helper widget for displaying a tax row in the summary
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
              color: AppTheme.orange800,
            ),
          ),
          Text(
            '₹${amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontFamily: 'Literata',
              fontSize: 13,
              fontWeight: isBold ? FontWeight.w600 : FontWeight.normal,
              color: AppTheme.orange800,
            ),
          ),
        ],
      ),
    );
  }

  // GST mode selection section
  Widget _buildGstModeSection() {
    return Container(
      margin: EdgeInsets.fromLTRB(16, 8, 16, 8),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.grey.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.black.withValues(alpha: 0.04),
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
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.orange.withValues(alpha: 0.1),
                  AppTheme.orange.withValues(alpha: 0.05),
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
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppTheme.orange700, AppTheme.orange],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.orange.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.receipt_long_rounded,
                    color: AppTheme.white,
                    size: 22,
                  ),
                ),
                SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _localizations.gstCalculationMode,
                        style: TextStyle(
                          fontFamily: 'Literata',
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: AppColors.accent(context),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _localizations.selectTaxMethod,
                        style: TextStyle(
                          fontFamily: 'Literata',
                          fontSize: 12,
                          color: AppTheme.grey600,
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
                    color: AppTheme.orange50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.orange200),
                  ),
                  child: Text(
                    _gstMode == GstMode.noGst
                        ? _localizations.noGst
                        : _gstMode == GstMode.includeGst
                        ? _localizations.incl
                        : _localizations.excl,
                    style: TextStyle(
                      fontFamily: 'Literata',
                      fontSize: 11,
                      color: AppTheme.orange800,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
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
        padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [AppTheme.orange600, AppTheme.orange],
                )
              : null,
          color: isSelected ? null : AppColors.scaffold(context),
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: isSelected ? AppTheme.transparent : AppTheme.grey300,
            width: 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppTheme.orange.withValues(alpha: 0.3),
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
                    ? AppTheme.white.withValues(alpha: 0.2)
                    : AppColors.border(context),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                size: 14,
                color: isSelected ? AppTheme.white : AppTheme.grey600,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Literata',
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? AppTheme.white : AppTheme.grey700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentSection() {
    return Container(
      margin: EdgeInsets.fromLTRB(12, 6, 12, 6),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.grey.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.action(context).withValues(alpha: 0.1),
                  AppColors.action(context).withValues(alpha: 0.05),
                ],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: AppColors.headerGradient(context),
                    ),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.accentSoft(context, 0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.payments_rounded,
                    color: AppTheme.white,
                    size: 18,
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _localizations.payment,
                        style: TextStyle(
                          fontFamily: 'Literata',
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: AppColors.accent(context),
                        ),
                      ),
                      Text(
                        _localizations.selectPaymentMethod,
                        style: TextStyle(
                          fontFamily: 'Literata',
                          fontSize: 11,
                          color: AppTheme.grey600,
                        ),
                      ),
                    ],
                  ),
                ),
                // Payment status badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _isFullPayment
                        ? AppTheme.green50
                        : AppTheme.orange50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _isFullPayment
                          ? AppTheme.green200
                          : AppTheme.orange200,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _isFullPayment
                            ? Icons.check_circle_rounded
                            : Icons.schedule_rounded,
                        size: 12,
                        color: _isFullPayment
                            ? AppTheme.green700
                            : AppTheme.orange700,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        _isFullPayment
                            ? _localizations.full
                            : _localizations.partial,
                        style: TextStyle(
                          fontFamily: 'Literata',
                          fontSize: 10,
                          color: _isFullPayment
                              ? AppTheme.green700
                              : AppTheme.orange700,
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
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                // Payment type toggle
                Container(
                  padding: EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: AppColors.chipFill(context),
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

                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Paid via',
                    style: TextStyle(
                      fontFamily: 'Literata',
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.secondaryText(context),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final mode in const [
                      PaymentMode.cash,
                      PaymentMode.upi,
                      PaymentMode.card,
                      PaymentMode.online,
                      PaymentMode.cheque,
                    ])
                      _summaryPayChip(
                        label: mode.displayName,
                        selected: _billPaymentMode == mode,
                        onTap: () => setState(() => _billPaymentMode = mode),
                      ),
                  ],
                ),

                // Received amount input (only show for partial payment)
                if (!_isFullPayment) ...[
                  const SizedBox(height: 12),
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
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.secondaryText(context),
                              ),
                            ),
                            SizedBox(height: 6),
                            Container(
                              decoration: BoxDecoration(
                                color: AppColors.scaffold(context),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: AppColors.border(context),
                                ),
                              ),
                              child: TextField(
                                controller: _receivedAmountController,
                                keyboardType: TextInputType.numberWithOptions(
                                  decimal: true,
                                ),
                                style: TextStyle(
                                  fontFamily: 'Literata',
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.accent(context),
                                ),
                                decoration: InputDecoration(
                                  prefixText: '₹ ',
                                  prefixStyle: TextStyle(
                                    fontFamily: 'Literata',
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.grey,
                                  ),
                                  hintText: '0.00',
                                  hintStyle: TextStyle(
                                    fontFamily: 'Literata',
                                    color: AppTheme.grey400,
                                  ),
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 10,
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
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _localizations.pendingAmount,
                              style: TextStyle(
                                fontFamily: 'Literata',
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.secondaryText(context),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: _pendingAmount > 0
                                      ? [
                                          AppTheme.orange50,
                                          AppTheme.orange100.withValues(
                                            alpha: 0.5,
                                          ),
                                        ]
                                      : [
                                          AppTheme.green50,
                                          AppTheme.green100.withValues(
                                            alpha: 0.5,
                                          ),
                                        ],
                                ),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: _pendingAmount > 0
                                      ? AppTheme.orange300
                                      : AppTheme.green300,
                                ),
                              ),
                              child: Text(
                                '₹ ${_pendingAmount.toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontFamily: 'Literata',
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: _pendingAmount > 0
                                      ? AppTheme.orange700
                                      : AppTheme.green700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  // Quick amount buttons
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
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
                            AppTheme.red50,
                            AppTheme.red100.withValues(alpha: 0.5),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.toneRose),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: AppTheme.red100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.warning_amber_rounded,
                              size: 18,
                              color: AppTheme.red700,
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
                                color: AppTheme.red800,
                              ),
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 14,
                            color: AppTheme.red700,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],

                // Summary for partial payment
                if (!_isFullPayment && _receivedAmount > 0) ...[
                  SizedBox(height: 18),
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.action(context).withValues(alpha: 0.08),
                          AppColors.action(context).withValues(alpha: 0.04),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.accentSoft(context, 0.15),
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
                          color: AppTheme.green700,
                        ),
                        const SizedBox(height: 10),
                        Divider(color: AppTheme.grey300, height: 1),
                        const SizedBox(height: 10),
                        _buildPaymentSummaryRow(
                          _localizations.pending,
                          '₹${_pendingAmount.toStringAsFixed(2)}',
                          color: _pendingAmount > 0
                              ? AppTheme.orange700
                              : AppTheme.green700,
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
        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(colors: AppColors.headerGradient(context))
              : null,
          color: isSelected ? null : AppTheme.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.accentSoft(context, 0.3),
                    blurRadius: 4,
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
              size: 14,
              color: isSelected ? AppTheme.white : AppTheme.grey600,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Literata',
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isSelected ? AppTheme.white : AppTheme.grey600,
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
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.action(context) : AppColors.chipFill(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.action(context) : AppTheme.grey300,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Literata',
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: isSelected ? AppTheme.white : AppTheme.grey700,
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
            fontSize: 12,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.normal,
            color: AppColors.secondaryText(context),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontFamily: 'Literata',
            fontSize: isBold ? 13 : 12,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w600,
            color: color ?? AppColors.primaryText(context),
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
        width: 40,
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? AppColors.action(context) : AppTheme.transparent,
          shape: BoxShape.circle,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Literata',
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: isSelected ? AppTheme.white : AppColors.secondaryText(context),
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
          color: isSelected ? AppColors.action(context) : AppTheme.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.action(context) : AppColors.border(context),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Literata',
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: isSelected
                ? AppTheme.white
                : AppColors.secondaryText(context),
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

  // Premium glass-morphism Quick Stats Panel
  Widget _buildQuickStatsPremiumPanel() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      bottom: 0,
      child: GestureDetector(
        onTap: _toggleQuickStats, // Tap outside to close
        child: Container(
          color: AppTheme.black.withValues(alpha: 0.3),
          child: SafeArea(
            bottom: false,
            child: Column(
              children: [
                // Small spacing from top
                const SizedBox(height: 8),
                // Panel content - aligned to top
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, child) {
                    return Transform.translate(
                      offset: Offset(0, -20 * (1 - value)),
                      child: Opacity(
                        opacity: value.clamp(0.0, 1.0),
                        child: child,
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: GestureDetector(
                      onTap: () {}, // Prevent closing when tapping panel
                      child: _buildGlassyQuickStatsCard(),
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

  // Glassy card with shining border
  Widget _buildGlassyQuickStatsCard() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.palette33FFFFFF,
            AppTheme.white60,
            AppTheme.palette4D1B4D3E,
            AppTheme.white60,
            AppTheme.palette33FFFFFF,
          ],
          stops: [0.0, 0.25, 0.5, 0.75, 1.0],
        ),
      ),
      padding: const EdgeInsets.all(2),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppTheme.paletteD9FFFFFF,
                  AppTheme.paletteBFFFFFFF,
                  AppTheme.paletteCCF8FFFC,
                ],
              ),
              borderRadius: BorderRadius.circular(26),
              border: Border.all(width: 1.5, color: AppTheme.paletteCCFFFFFF),
              boxShadow: const [
                BoxShadow(
                  color: AppTheme.palette261B4D3E,
                  blurRadius: 40,
                  spreadRadius: 5,
                  offset: Offset(0, 15),
                ),
                BoxShadow(
                  color: AppTheme.paletteCCFFFFFF,
                  blurRadius: 20,
                  spreadRadius: -5,
                  offset: Offset(-5, -5),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Compact Header
                _buildCompactHeader(),
                const SizedBox(height: 14),
                // Stats Grid - Compact 4 columns
                _isLoadingQuickStats
                    ? _buildQuickStatsPremiumShimmer()
                    : _buildQuickStatsGrid(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Compact header for Quick Stats
  Widget _buildCompactHeader() {
    return Row(
      children: [
        // Animated icon container
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: AppColors.headerGradient(context),
            ),
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: AppColors.accentSoft(context, 0.4),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(
            Icons.dashboard_customize_rounded,
            color: AppTheme.white,
            size: 18,
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: Text(
            _localizations.quickActions,
            style: TextStyle(
              fontFamily: 'Literata',
              fontWeight: FontWeight.w800,
              fontSize: 16,
              color: AppColors.accent(context),
              letterSpacing: -0.3,
            ),
          ),
        ),
        // Close button with glass effect
        GestureDetector(
          onTap: _toggleQuickStats,
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.accentSoft(context, 0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.accentSoft(context, 0.15)),
            ),
            child: Icon(
              Icons.close_rounded,
              color: AppColors.accent(context),
              size: 18,
            ),
          ),
        ),
      ],
    );
  }

  void _openSection(Widget page, int index) {
    if (WebShell.open(index)) {
      _loadQuickStats();
      return;
    }
    showAppPage(context, page).then((_) => _loadQuickStats());
  }

  // Premium compact 4-column stats grid (icon + name only)
  Widget _buildQuickStatsGrid() {
    final stats = [
      _QuickStatItem(
        icon: Icons.receipt_long_rounded,
        value: '',
        label: _localizations.invoices,
        color: AppTheme.paletteFF667EEA,
        gradient: [AppTheme.paletteFF667EEA, AppTheme.paletteFF764BA2],
        onTap: () {
          _toggleQuickStats();
          _openSection(const BillsListPage(), WebShell.invoices);
        },
      ),
      _QuickStatItem(
        icon: Icons.inventory_2_rounded,
        value: '',
        label: _localizations.products,
        color: AppTheme.paletteFFF093FB,
        gradient: [AppTheme.paletteFFF093FB, AppTheme.paletteFFF5576C],
        onTap: () {
          _toggleQuickStats();
          _openSection(const EnhancedProductPage(), WebShell.products);
        },
      ),
      _QuickStatItem(
        icon: Icons.local_shipping_rounded,
        value: '',
        label: _localizations.suppliers,
        color: AppTheme.coral,
        gradient: [AppTheme.coral, AppTheme.paletteFFEE5A24],
        onTap: () {
          _toggleQuickStats();
          _openSection(const EnhancedSupplierPage(), WebShell.suppliers);
        },
      ),
      _QuickStatItem(
        icon: Icons.business_rounded,
        value: '',
        label: _localizations.companies,
        color: AppTheme.purple,
        gradient: [AppTheme.purple, AppTheme.purple700],
        onTap: () {
          _toggleQuickStats();
          _openSection(const EnhancedCompanyPage(), WebShell.companies);
        },
      ),
      _QuickStatItem(
        icon: Icons.keyboard_return_rounded,
        value: '',
        label: 'P. Return',
        color: AppTheme.orange900,
        gradient: [AppTheme.orange900, AppTheme.amber800],
        onTap: () {
          _toggleQuickStats();
          _openSection(
            const PurchaseReturnScreen(),
            WebShell.purchaseReturn,
          );
        },
      ),
      _QuickStatItem(
        icon: Icons.celebration_rounded,
        value: '',
        label: _localizations.events,
        color: AppTheme.paletteFF6C63FF,
        gradient: [AppTheme.paletteFF6C63FF, AppTheme.paletteFF8B5CF6],
        onTap: () {
          _toggleQuickStats();
          _openSection(const EventOrderListPage(), WebShell.events);
        },
      ),
      _QuickStatItem(
        icon: Icons.request_quote_rounded,
        value: '',
        label: _localizations.quotations,
        color: AppTheme.blue800,
        gradient: [AppTheme.blue800, AppTheme.blue400],
        onTap: () {
          _toggleQuickStats();
          _openSection(const QuotationListPage(), WebShell.quotations);
        },
      ),
      _QuickStatItem(
        icon: Icons.qr_code_2_rounded,
        value: '',
        label: _localizations.barcode,
        color: AppTheme.teal600,
        gradient: [AppTheme.teal600, AppTheme.teal900],
        onTap: () {
          _toggleQuickStats();
          _openSection(const BarcodeGeneratorPage(), WebShell.barcode);
        },
      ),
      _QuickStatItem(
        icon: Icons.people_alt_rounded,
        value: '',
        label: _localizations.customers,
        color: AppColors.action(context),
        gradient: [AppColors.action(context), AppTheme.primaryDark],
        onTap: () {
          _toggleQuickStats();
          _openSection(const EnhancedCustomerPage(), WebShell.customers);
        },
      ),
    ];

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      alignment: WrapAlignment.center,
      children: stats
          .asMap()
          .entries
          .map((entry) => _buildCompactStatChip(entry.value, entry.key))
          .toList(),
    );
  }

  // Compact stat chip with glass effect and shining border
  Widget _buildCompactStatChip(_QuickStatItem stat, int index) {
    return GestureDetector(
      onTap: stat.onTap,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: Duration(milliseconds: 400 + (index * 50).clamp(0, 350)),
        curve: Curves.easeOutCubic,
        builder: (context, value, child) {
          return Transform.scale(scale: value, child: child);
        },
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppTheme.white.withValues(alpha: 0.7),
                    AppTheme.white.withValues(alpha: 0.4),
                    stat.color.withValues(alpha: 0.15),
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
                border: Border.all(
                  color: AppTheme.white.withValues(alpha: 0.5),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: stat.color.withValues(alpha: 0.15),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                  BoxShadow(
                    color: AppTheme.white.withValues(alpha: 0.6),
                    blurRadius: 6,
                    spreadRadius: -2,
                    offset: const Offset(-2, -2),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Icon with gradient glow
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: stat.gradient,
                      ),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: stat.color.withValues(alpha: 0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Icon(stat.icon, color: AppTheme.white, size: 16),
                  ),
                  const SizedBox(height: 6),
                  // Label
                  Text(
                    stat.label,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Literata',
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: stat.color,
                      letterSpacing: -0.2,
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

  // Premium shimmer loading for compact stats grid
  Widget _buildQuickStatsPremiumShimmer() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      alignment: WrapAlignment.center,
      children: List.generate(
        8,
        (index) => Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: AppColors.chipFill(context),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.grey200),
          ),
          child: Center(
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.border(context),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    final isDark = AppColors.isDark(context);
    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 16,
        top: 14,
        bottom: widget.isEmbedded
            ? 12
            : MediaQuery.of(context).padding.bottom + 16,
      ),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.black.withValues(alpha: isDark ? 0.4 : 0.08),
            blurRadius: 18,
            offset: const Offset(0, -6),
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
                    fontSize: 13,
                    color: AppColors.mutedText(context),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '₹${_finalAmount.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontFamily: 'Literata',
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primaryText(context),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          if (_enableHoldBill) ...[
            Material(
              color: AppTheme.transparent,
              child: InkWell(
                onTap: _isSavingBill ? null : _holdCurrentBill,
                borderRadius: BorderRadius.circular(28),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: AppColors.border(context)),
                    color: AppColors.inputFill(context),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.pause_circle_outline_rounded,
                        size: 18,
                        color: AppColors.primaryText(context),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Hold',
                        style: TextStyle(
                          fontFamily: 'Literata',
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryText(context),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          AppPillButton(
            label: _localizations.print,
            icon: Icons.print_rounded,
            loading: _isSavingBill,
            onPressed: _isSavingBill ? null : _saveBill,
          ),
        ],
      ),
    );
  }

  void _showCustomerPicker() {
    // Refresh customers before showing picker
    _loadCustomers();

    showAppBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.transparent,
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

class _DashedRRectPainter extends CustomPainter {
  final Color color;
  final double radius;

  const _DashedRRectPainter(this.color, {this.radius = 18});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    final inset = paint.strokeWidth / 2;
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            inset,
            inset,
            size.width - paint.strokeWidth,
            size.height - paint.strokeWidth,
          ),
          Radius.circular(radius),
        ),
      );
    const dash = 5.0;
    const gap = 4.0;
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = (distance + dash).clamp(0, metric.length).toDouble();
        canvas.drawPath(metric.extractPath(distance, next), paint);
        distance += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedRRectPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.radius != radius;
}

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
      initialChildSize: drawerSheetSize(0.6),
      maxChildSize: drawerSheetSize(0.9),
      minChildSize: drawerSheetSize(0.4),
      builder: (_, controller) => Container(
        decoration: BoxDecoration(
          color: AppColors.card(context),
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
                color: AppTheme.grey300,
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
                      Icons.person_outline,
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
                          widget.localizations.selectCustomer,
                          style: TextStyle(
                            fontFamily: 'Literata',
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: AppColors.accent(context),
                          ),
                        ),
                        Text(
                          widget.localizations.chooseFromExistingCustomers,
                          style: TextStyle(
                            fontFamily: 'Literata',
                            fontSize: 12,
                            color: AppTheme.grey,
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
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                controller: _searchController,
                onChanged: _filterCustomers,
                style: TextStyle(fontFamily: 'Literata', fontSize: 14),
                decoration: InputDecoration(
                  hintText: widget.localizations.searchByNameOrPhone,
                  hintStyle: TextStyle(color: AppTheme.grey),
                  prefixIcon: Icon(
                    Icons.search,
                    color: AppColors.accent(context),
                  ),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear, size: 20),
                          onPressed: () {
                            _searchController.clear();
                            _filterCustomers('');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: AppColors.scaffold(context),
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
            SizedBox(height: 12),
            // Add New Customer button
            if (widget.onAddNew != null)
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: GestureDetector(
                  onTap: widget.onAddNew,
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: AppColors.accent(context),
                        width: 1.5,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      color: AppColors.accentSoft(context, 0.05),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.person_add,
                          color: AppColors.accent(context),
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Add New Customer',
                          style: TextStyle(
                            fontFamily: 'Literata',
                            color: AppColors.accent(context),
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
                            color: AppTheme.grey400,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            widget.localizations.noCustomersFound,
                            style: TextStyle(
                              fontFamily: 'Literata',
                              color: AppTheme.grey600,
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
                                foregroundColor: AppColors.action(context),
                              ),
                            ),
                          ],
                        ],
                      ),
                    )
                  : ListView.builder(
                      controller: controller,
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _filteredCustomers.length,
                      itemBuilder: (context, index) {
                        final customer = _filteredCustomers[index];
                        return Container(
                          margin: EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: AppColors.card(context),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.border(context),
                              width: 1,
                            ),
                          ),
                          child: Material(
                            color: AppTheme.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () => widget.onCustomerSelected(customer),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      backgroundColor: AppColors.action(context),
                                      child: Text(
                                        (customer['fullName'] as String)
                                                .isNotEmpty
                                            ? (customer['fullName']
                                                      as String)[0]
                                                  .toUpperCase()
                                            : '?',
                                        style: const TextStyle(
                                          color: AppTheme.white,
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
                                            customer['contact'] ?? '-',
                                            style: TextStyle(
                                              fontFamily: 'Literata',
                                              color: AppTheme.grey600,
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
                                          color: AppTheme.red50,
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Text(
                                          '₹${(customer['pendingBalance'] as num).toDouble().toStringAsFixed(0)}',
                                          style: TextStyle(
                                            fontFamily: 'Literata',
                                            color: AppTheme.red700,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    const SizedBox(width: 4),
                                    Icon(
                                      Icons.chevron_right,
                                      color: AppTheme.grey400,
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

// Data class for Quick Stat items
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

// Inline editable quantity field for bill items
class _InlineQuantityField extends StatefulWidget {
  final BillItem item;
  final int maxStock;
  final ValueChanged<double> onQuantityChanged;
  final VoidCallback onRemoveItem;

  const _InlineQuantityField({
    required this.item,
    required this.maxStock,
    required this.onQuantityChanged,
    required this.onRemoveItem,
  });

  @override
  State<_InlineQuantityField> createState() => _InlineQuantityFieldState();
}

class _InlineQuantityFieldState extends State<_InlineQuantityField> {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  bool _isEditing = false;
  bool _hasSubmitted = false; // Guard against double submission

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: _getDisplayValue());
    _focusNode = FocusNode();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void didUpdateWidget(_InlineQuantityField oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Update controller text if quantity changed externally (e.g., via +/- buttons)
    if (!_isEditing && oldWidget.item.quantity != widget.item.quantity) {
      _controller.text = _getDisplayValue();
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (_focusNode.hasFocus) {
      setState(() {
        _isEditing = true;
        _hasSubmitted = false; // Reset guard when gaining focus
      });
      // Select all text when focused for easy replacement
      _controller.selection = TextSelection(
        baseOffset: 0,
        extentOffset: _controller.text.length,
      );
    } else {
      setState(() => _isEditing = false);
      // Only validate if not already submitted (via Enter key)
      if (!_hasSubmitted) {
        _validateAndSubmit();
      }
    }
  }

  // Get the display value based on unit conversion
  String _getDisplayValue() {
    final item = widget.item;
    double displayQty = item.quantity;

    // Convert to display unit if needed
    if (item.sellUnit == 'gm' && item.unit == 'kg') {
      displayQty = item.quantity * 1000;
    } else if (item.sellUnit == 'ml' && item.unit == 'ltr') {
      displayQty = item.quantity * 1000;
    }

    // Format nicely - remove decimals if whole number
    if (displayQty == displayQty.roundToDouble()) {
      return displayQty.toInt().toString();
    }
    return displayQty.toStringAsFixed(2);
  }

  // Get the unit suffix for display
  String _getUnitSuffix() {
    final item = widget.item;
    return item.sellUnit ?? item.unit ?? '';
  }

  // Convert display value back to base unit quantity
  double _convertToBaseUnit(double displayQty) {
    final item = widget.item;
    if (item.sellUnit == 'gm' && item.unit == 'kg') {
      return displayQty / 1000;
    } else if (item.sellUnit == 'ml' && item.unit == 'ltr') {
      return displayQty / 1000;
    }
    return displayQty;
  }

  // Get max stock in display units
  double _getMaxStockInDisplayUnit() {
    final item = widget.item;
    if (item.sellUnit == 'gm' && item.unit == 'kg') {
      return widget.maxStock * 1000.0;
    } else if (item.sellUnit == 'ml' && item.unit == 'ltr') {
      return widget.maxStock * 1000.0;
    }
    return widget.maxStock.toDouble();
  }

  void _validateAndSubmit() {
    _hasSubmitted = true; // Mark as submitted to prevent double calls

    final text = _controller.text.trim();
    final displayQty = double.tryParse(text);

    if (displayQty == null || displayQty <= 0) {
      // Invalid input - revert to original value
      _controller.text = _getDisplayValue();
      _focusNode.unfocus();
      return;
    }

    final maxDisplayStock = _getMaxStockInDisplayUnit();
    if (displayQty > maxDisplayStock) {
      // Exceeds stock - cap at max and show feedback
      final baseQty = _convertToBaseUnit(maxDisplayStock);
      widget.onQuantityChanged(baseQty);
      _focusNode.unfocus();
      return;
    }

    // Valid quantity - convert and update
    final baseQty = _convertToBaseUnit(displayQty);

    // Check if quantity would be effectively zero (removed)
    if (baseQty < 0.001) {
      widget.onRemoveItem();
      return;
    }

    widget.onQuantityChanged(baseQty);
    _focusNode.unfocus();
  }

  // Update quantity in real-time as user types (without validation side effects)
  void _onTextChanged(String text) {
    final displayQty = double.tryParse(text.trim());

    // Only update if it's a valid positive number
    if (displayQty == null || displayQty <= 0) {
      return; // Don't update for invalid input, let them keep typing
    }

    final maxDisplayStock = _getMaxStockInDisplayUnit();
    // Cap at max stock silently while typing
    final effectiveDisplayQty = displayQty > maxDisplayStock
        ? maxDisplayStock
        : displayQty;

    final baseQty = _convertToBaseUnit(effectiveDisplayQty);

    // Don't remove item while typing - that's too aggressive
    if (baseQty >= 0.001) {
      widget.onQuantityChanged(baseQty);
    }
  }

  @override
  Widget build(BuildContext context) {
    final unitSuffix = _getUnitSuffix();

    return Container(
      constraints: const BoxConstraints(minWidth: 64, maxWidth: 96),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Flexible(
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Literata',
                fontWeight: FontWeight.w700,
                fontSize: 15,
                color: AppColors.primaryText(context),
              ),
              decoration: const InputDecoration(
                isDense: true,
                contentPadding: EdgeInsets.symmetric(
                  vertical: 4,
                  horizontal: 2,
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
              ),
              onChanged: _onTextChanged,
              onSubmitted: (_) => _validateAndSubmit(),
            ),
          ),
          if (unitSuffix.isNotEmpty)
            Text(
              unitSuffix,
              style: TextStyle(
                fontFamily: 'Literata',
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: AppColors.secondaryText(context),
              ),
            ),
        ],
      ),
    );
  }
}

class _ExtraChargeDraft {
  final String id;
  final TextEditingController labelController;
  final TextEditingController amountController;

  _ExtraChargeDraft()
    : id = 'chg_${DateTime.now().microsecondsSinceEpoch}',
      labelController = TextEditingController(),
      amountController = TextEditingController();

  _ExtraChargeDraft.restored({required String label, required double amount})
    : id = 'chg_${DateTime.now().microsecondsSinceEpoch}',
      labelController = TextEditingController(text: label),
      amountController = TextEditingController(
        text: amount > 0 ? amount.toStringAsFixed(2) : '',
      );

  BillExtraCharge toCharge() {
    return BillExtraCharge(
      id: id,
      label: labelController.text.trim(),
      amount: double.tryParse(amountController.text.trim()) ?? 0.0,
    );
  }

  void dispose() {
    labelController.dispose();
    amountController.dispose();
  }
}

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
import 'package:c_billing/common_widgets/printer_selection_widget.dart';
import 'package:c_billing/features/shop/data/repositories/shop_repository.dart';
import 'package:c_billing/features/customer/data/repositories/customer_repository.dart';
import 'package:c_billing/features/customer/data/repositories/customer_transaction_repository.dart';
import 'package:c_billing/core/services/language_service.dart';
import 'package:c_billing/core/localization/app_localizations.dart';
import 'package:c_billing/features/billing/presentation/pages/bill_settings_page.dart';

class BillingPage extends StatefulWidget {
  final bool isEmbedded;

  const BillingPage({super.key, this.isEmbedded = false});

  @override
  State<BillingPage> createState() => _BillingPageState();
}

class _BillingPageState extends State<BillingPage> {
  late BillingService _billingService;
  late FirebaseFirestore _firestore;
  late ShopRepository _shopRepository;
  late FirebaseCustomerRepository _customerRepository;
  late AppLocalizations _localizations;

  // Data refresh subscriptions
  StreamSubscription<void>? _productRefreshSubscription;
  StreamSubscription<void>? _customerRefreshSubscription;

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
  
  // Customer phone search debounce
  Timer? _phoneSearchDebounceTimer;
  bool _isSearchingCustomer = false;
  String? _autoFoundCustomerName;
  bool _isAddCustomerDialogOpen = false;

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
    
    _loadProducts();
    _loadCustomers();
  }

  @override
  void dispose() {
    _productRefreshSubscription?.cancel();
    _customerRefreshSubscription?.cancel();
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
      final products = await _billingService.getAvailableProducts();
      if (mounted) {
        setState(() {
          _products = products;
          // Build index lookup map for fast product search
          _productByIndexNo = {
            for (final product in products)
              if (product.indexNo > 0) product.indexNo: product,
          };
          if (showLoader) _isLoading = false;
        });
      }
    } catch (e) {
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
    final phoneNumber = _customerContactController.text.trim();
    
    // Cancel previous timer
    _phoneSearchDebounceTimer?.cancel();
    
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
        // Customer not found - show add customer dialog
        setState(() {
          _isSearchingCustomer = false;
        });
        // Only show dialog if not already open
        if (!_isAddCustomerDialogOpen) {
          _showAddCustomerDialog(phoneNumber);
        }
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

  /// Show dialog to add new customer with pre-filled phone number
  void _showAddCustomerDialog(String phoneNumber) {
    _isAddCustomerDialogOpen = true;
    final firstNameController = TextEditingController();
    final lastNameController = TextEditingController();
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
                Text(
                  'Customer not found for $phoneNumber',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                    fontFamily: 'Literata',
                  ),
                ),
                const SizedBox(height: 20),
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
                  initialValue: phoneNumber,
                  readOnly: true,
                  decoration: InputDecoration(
                    labelText: 'Phone Number',
                    prefixIcon: const Icon(Icons.phone_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey[100],
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              _isAddCustomerDialogOpen = false;
              firstNameController.dispose();
              lastNameController.dispose();
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
              _isAddCustomerDialogOpen = false;
              firstNameController.dispose();
              lastNameController.dispose();
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
                _isAddCustomerDialogOpen = false;
                Navigator.pop(ctx);
                firstNameController.dispose();
                lastNameController.dispose();
                await _saveNewCustomer(
                  firstName: firstNameController.text.trim(),
                  lastName: lastNameController.text.trim(),
                  phoneNumber: phoneNumber,
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
        localizations: _localizations,
        onItemAdded: (product, quantity, price) {
          final existingIndex = _billItems.indexWhere(
            (item) => item.productId == product.id,
          );
          setState(() {
            if (existingIndex != -1) {
              _billItems[existingIndex] = BillItem.create(
                productId: product.id,
                productName: product.name,
                sellingPrice: price,
                quantity: quantity,
              );
            } else {
              _billItems.add(
                BillItem.create(
                  productId: product.id,
                  productName: product.name,
                  sellingPrice: price,
                  quantity: quantity,
                ),
              );
            }
          });
        },
        onItemRemoved: (productId) {
          setState(() {
            _billItems.removeWhere((item) => item.productId == productId);
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

    setState(() => _isSavingBill = true);

    try {
      final result = await _billingService.processBill(
        items: _billItems,
        customerId: _selectedCustomer?['id'],
        customerName: _customerNameController.text.trim().isNotEmpty
            ? _customerNameController.text.trim()
            : _selectedCustomer?['fullName'],
        customerContact: _customerContactController.text.trim().isNotEmpty
            ? _customerContactController.text.trim()
            : _selectedCustomer?['contact'],
        notes: _notesController.text.trim().isNotEmpty
            ? _notesController.text.trim()
            : null,
        discountAmount: _discountAmount,
        discountPercent: _discountPercent,
        paidAmount: _isFullPayment ? null : _receivedAmount,
      );

      setState(() => _isSavingBill = false);

      if (result.success) {
        // Clear bills list cache so it reloads fresh data next time
        unawaited(BillCacheDataSource().clearCache());

        // Keep a copy of items to update local stock
        final savedItems = List<BillItem>.from(_billItems);

        // Fetch the created bill for print/share options
        Bill? createdBill;
        if (result.billId != null) {
          createdBill = await _billingService.getBillById(result.billId!);
        }

        _clearBill();

        // Optimization: Update local stock immediately instead of full reload from server
        _updateLocalStock(savedItems);

        // Background reload to ensure sync without blocking UI
        _loadProducts(showLoader: false);
        
        // Notify dashboard to refresh (bill count and products count may change)
        DashboardRefreshService.instance.notifyDataChanged(DataChangeType.bill);

        // Show success dialog with print/share options
        if (mounted && createdBill != null) {
          _showBillSuccessDialog(createdBill);
        } else {
          _showSnackbar(_localizations.billSavedSuccessfully);
        }
      } else {
        _showSnackbar(
          result.errorMessage ?? _localizations.errorSavingBill,
          isError: true,
        );
      }
    } catch (e) {
      setState(() => _isSavingBill = false);
      _showSnackbar('${_localizations.error}: $e', isError: true);
    }
  }

  void _updateLocalStock(List<BillItem> savedItems) {
    setState(() {
      for (final item in savedItems) {
        final index = _products.indexWhere((p) => p.id == item.productId);
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
      _isAddCustomerDialogOpen = false;
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
                    // First row - Share and Save PDF
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
                    // Second row - Print POS
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _printBillToPOS(bill);
                        },
                        icon: const Icon(Icons.print, size: 18),
                        label: Text(
                          _localizations.printToPOS,
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
        Text(
          value,
          style: TextStyle(
            fontFamily: 'Literata',
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: valueColor ?? Colors.black87,
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

      if (mounted) Navigator.pop(context);

      await _pdfService.shareBillAsPdf(billData: printData, shopDetails: shop);
    } catch (e) {
      if (mounted) Navigator.pop(context);
      _showSnackbar('${_localizations.errorSharingBill}: $e', isError: true);
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

      final file = await _pdfService.savePdfToFile(
        billData: printData,
        shopDetails: shop,
      );

      if (mounted) Navigator.pop(context);

      _showSnackbar('${_localizations.pdfSaved}: ${file.path.split('/').last}');
    } catch (e) {
      if (mounted) Navigator.pop(context);
      _showSnackbar('${_localizations.errorSavingPdf}: $e', isError: true);
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
                  _buildCustomerSection(),
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
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const BillSettingsPage(),
                        ),
                      );
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
                _localizations.customerOptional,
                style: const TextStyle(
                  fontFamily: 'Literata',
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  color: Color(0xFF1B4D3E),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
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
      ),
    );
  }

  /// Add product by index number directly from the Create Bill page
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

    if (product.currentStock <= 0) {
      _showSnackbar(
        '${product.name} ${_localizations.outOfStock}',
        isError: true,
      );
      _indexNoController.clear();
      return;
    }

    // Add product — increment quantity if already in cart
    final existingIndex = _billItems.indexWhere(
      (item) => item.productId == product.id,
    );
    setState(() {
      if (existingIndex != -1) {
        final existing = _billItems[existingIndex];
        if (existing.quantity < product.currentStock) {
          _billItems[existingIndex] = BillItem.create(
            productId: product.id,
            productName: product.name,
            sellingPrice: existing.sellingPrice,
            quantity: existing.quantity + 1,
          );
        } else {
          _showSnackbar(
            '${_localizations.maxStock}: ${product.currentStock}',
            isError: true,
          );
          _indexNoController.clear();
          return;
        }
      } else {
        _billItems.add(
          BillItem.create(
            productId: product.id,
            productName: product.name,
            sellingPrice: product.salesPrice,
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
              final product = _products.firstWhere(
                (p) => p.id == item.productId,
                orElse: () => Product(
                  id: item.productId,
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
                                if (item.quantity < product.currentStock) {
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
                                    '${_localizations.maxStock}: ${product.currentStock}',
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
class _AddItemsBottomSheet extends StatefulWidget {
  final List<Product> products;
  final List<BillItem> billItems;
  final Function(Product product, int quantity, double price) onItemAdded;
  final Function(String productId) onItemRemoved;
  final Function(String message, {bool isError}) showSnackbar;
  final AppLocalizations localizations;

  const _AddItemsBottomSheet({
    required this.products,
    required this.billItems,
    required this.onItemAdded,
    required this.onItemRemoved,
    required this.showSnackbar,
    required this.localizations,
  });

  @override
  State<_AddItemsBottomSheet> createState() => _AddItemsBottomSheetState();
}

class _AddItemsBottomSheetState extends State<_AddItemsBottomSheet> {
  late List<Product> _filteredProducts;
  final _searchController = TextEditingController();

  // Track quantities for each product in this session
  Map<String, int> _quantities = {};
  Map<String, double> _prices = {};

  @override
  void initState() {
    super.initState();
    _filteredProducts = widget.products;

    // Initialize with existing bill items
    for (final item in widget.billItems) {
      _quantities[item.productId] = item.quantity;
      _prices[item.productId] = item.sellingPrice;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterProducts(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredProducts = widget.products;
      } else {
        final lowerQuery = query.toLowerCase();
        // Also allow searching by index number
        final indexNo = int.tryParse(query);
        _filteredProducts = widget.products
            .where(
              (p) =>
                  p.name.toLowerCase().contains(lowerQuery) ||
                  p.companyName.toLowerCase().contains(lowerQuery) ||
                  p.category.toLowerCase().contains(lowerQuery) ||
                  (indexNo != null && p.indexNo == indexNo),
            )
            .toList();
      }
    });
  }

  void _incrementQuantity(Product product) {
    final currentQty = _quantities[product.id] ?? 0;
    if (currentQty < product.currentStock) {
      setState(() {
        _quantities[product.id] = currentQty + 1;
        _prices[product.id] ??= product.salesPrice;
      });
      widget.onItemAdded(
        product,
        _quantities[product.id]!,
        _prices[product.id]!,
      );
    } else {
      widget.showSnackbar(
        '${widget.localizations.maxStock}: ${product.currentStock}',
        isError: true,
      );
    }
  }

  void _decrementQuantity(Product product) {
    final currentQty = _quantities[product.id] ?? 0;
    if (currentQty > 1) {
      setState(() {
        _quantities[product.id] = currentQty - 1;
      });
      widget.onItemAdded(
        product,
        _quantities[product.id]!,
        _prices[product.id]!,
      );
    } else if (currentQty == 1) {
      setState(() {
        _quantities.remove(product.id);
        _prices.remove(product.id);
      });
      widget.onItemRemoved(product.id);
    }
  }

  int get _totalItems => _quantities.values.fold(0, (sum, qty) => sum + qty);

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
            // Products list
            Expanded(
              child: _filteredProducts.isEmpty
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
                      itemCount: _filteredProducts.length,
                      itemBuilder: (context, index) {
                        final product = _filteredProducts[index];
                        final qty = _quantities[product.id] ?? 0;
                        final isAdded = qty > 0;

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
                                      product.indexNo > 0
                                          ? '${product.indexNo}'
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
                                        product.name,
                                        style: const TextStyle(
                                          fontFamily: 'Literata',
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 2),
                                      Row(
                                        children: [
                                          Text(
                                            '₹${product.salesPrice.toStringAsFixed(0)}',
                                            style: const TextStyle(
                                              fontFamily: 'Literata',
                                              fontWeight: FontWeight.w700,
                                              fontSize: 13,
                                              color: Color(0xFF1B4D3E),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: product.currentStock > 10
                                                  ? Colors.green[50]
                                                  : product.currentStock > 0
                                                  ? Colors.orange[50]
                                                  : Colors.red[50],
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              '${product.currentStock} left',
                                              style: TextStyle(
                                                fontFamily: 'Literata',
                                                fontSize: 10,
                                                fontWeight: FontWeight.w600,
                                                color: product.currentStock > 10
                                                    ? Colors.green[700]
                                                    : product.currentStock > 0
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
                                // Quantity controls
                                if (isAdded)
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: const Color(
                                          0xFF1B4D3E,
                                        ).withOpacity(0.3),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        _buildControlButton(
                                          icon: Icons.remove,
                                          onTap: () =>
                                              _decrementQuantity(product),
                                        ),
                                        Container(
                                          constraints: const BoxConstraints(
                                            minWidth: 32,
                                          ),
                                          alignment: Alignment.center,
                                          child: Text(
                                            '$qty',
                                            style: const TextStyle(
                                              fontFamily: 'Literata',
                                              fontWeight: FontWeight.w700,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ),
                                        _buildControlButton(
                                          icon: Icons.add,
                                          onTap: () =>
                                              _incrementQuantity(product),
                                        ),
                                      ],
                                    ),
                                  )
                                else
                                  Material(
                                    color: const Color(0xFF1B4D3E),
                                    borderRadius: BorderRadius.circular(8),
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(8),
                                      onTap: product.currentStock > 0
                                          ? () => _incrementQuantity(product)
                                          : null,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 14,
                                          vertical: 8,
                                        ),
                                        child: const Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.add,
                                              color: Colors.white,
                                              size: 18,
                                            ),
                                            SizedBox(width: 4),
                                            Text(
                                              'Add',
                                              style: TextStyle(
                                                fontFamily: 'Literata',
                                                color: Colors.white,
                                                fontWeight: FontWeight.w600,
                                                fontSize: 13,
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

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(6),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(6),
          child: Icon(icon, size: 18, color: const Color(0xFF1B4D3E)),
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

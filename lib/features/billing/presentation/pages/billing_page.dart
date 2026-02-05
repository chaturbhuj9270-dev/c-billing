import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:c_billing/core/services/billing_service.dart';
import 'package:c_billing/features/billing/data/repositories/firebase_bill_repository.dart';
import 'package:c_billing/features/billing/domain/entities/bill_item.dart';
import 'package:c_billing/features/inventory_management/data/repositories/firebase_product_repository.dart';
import 'package:c_billing/features/inventory_management/data/repositories/firebase_stock_repository.dart';
import 'package:c_billing/features/inventory_management/domain/entities/product.dart';

class BillingPage extends StatefulWidget {
  const BillingPage({super.key});

  @override
  State<BillingPage> createState() => _BillingPageState();
}

class _BillingPageState extends State<BillingPage> {
  late BillingService _billingService;
  late FirebaseFirestore _firestore;

  final _customerNameController = TextEditingController();
  final _customerContactController = TextEditingController();
  final _notesController = TextEditingController();
  final _discountController = TextEditingController();

  List<BillItem> _billItems = [];
  List<Product> _products = [];
  bool _isLoading = false;
  bool _isSavingBill = false;

  // Discount state
  bool _isPercentageDiscount = true;
  double _discountValue = 0.0;

  Map<String, dynamic>? _selectedCustomer;
  List<Map<String, dynamic>> _customers = [];

  @override
  void initState() {
    super.initState();
    _firestore = FirebaseFirestore.instance;
    _billingService = BillingService(
      billRepository: FirebaseBillRepository(firestore: _firestore),
      productRepository: FirebaseProductRepository(firestore: _firestore),
      stockRepository: FirebaseStockRepository(firestore: _firestore),
    );
    _loadProducts();
    _loadCustomers();
  }

  @override
  void dispose() {
    _customerNameController.dispose();
    _customerContactController.dispose();
    _notesController.dispose();
    _discountController.dispose();
    super.dispose();
  }

  Future<void> _loadProducts({bool showLoader = true}) async {
    try {
      if (showLoader) setState(() => _isLoading = true);
      final products = await _billingService.getAvailableProducts();
      if (mounted) {
        setState(() {
          _products = products;
          if (showLoader) _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showSnackbar('Error loading products: $e', isError: true);
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

  void _showAddItemsPopup() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _AddItemsBottomSheet(
        products: _products,
        billItems: _billItems,
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

  Future<void> _saveBill() async {
    if (_billItems.isEmpty) {
      _showSnackbar('Please add at least one item', isError: true);
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
      );

      setState(() => _isSavingBill = false);

      if (result.success) {
        _showSnackbar('Bill saved successfully!');
        // Keep a copy of items to update local stock
        final savedItems = List<BillItem>.from(_billItems);
        _clearBill();
        
        // Optimization: Update local stock immediately instead of full reload from server
        _updateLocalStock(savedItems);
        
        // Background reload to ensure sync without blocking UI
        _loadProducts(showLoader: false);
      } else {
        _showSnackbar(
          result.errorMessage ?? 'Error saving bill',
          isError: true,
        );
      }
    } catch (e) {
      setState(() => _isSavingBill = false);
      _showSnackbar('Error: $e', isError: true);
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
      _discountValue = 0.0;
      _isPercentageDiscount = true;
      _selectedCustomer = null;
    });
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF1B4D3E)),
            )
          : CustomScrollView(
              slivers: [
                _buildSliverAppBar(),
                SliverToBoxAdapter(child: _buildCustomerSection()),
                SliverToBoxAdapter(child: _buildAddItemsButton()),
                if (_billItems.isNotEmpty)
                  SliverToBoxAdapter(child: _buildBillItemsSection()),
                if (_billItems.isNotEmpty)
                  SliverToBoxAdapter(child: _buildDiscountSection()),
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
                  GestureDetector(
                    onTap: () {
                      if (_billItems.isNotEmpty) {
                        showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text(
                              'Discard Bill?',
                              style: TextStyle(fontFamily: 'Literata'),
                            ),
                            content: const Text(
                              'You have unsaved items.',
                              style: TextStyle(fontFamily: 'Literata'),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(ctx);
                                  Navigator.pop(context);
                                },
                                child: const Text(
                                  'Discard',
                                  style: TextStyle(color: Colors.red),
                                ),
                              ),
                            ],
                          ),
                        );
                      } else {
                        Navigator.pop(context);
                      }
                    },
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.arrow_back,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Create Bill',
                          style: TextStyle(
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
                        '${_billItems.length} items',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Literata',
                        ),
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
              const Text(
                'Customer (Optional)',
                style: TextStyle(
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
                            : 'Search existing customer...',
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
                    labelText: 'Name',
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
                child: TextField(
                  controller: _customerContactController,
                  keyboardType: TextInputType.phone,
                  style: const TextStyle(fontFamily: 'Literata', fontSize: 14),
                  decoration: InputDecoration(
                    labelText: 'Phone',
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
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAddItemsButton() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: ElevatedButton.icon(
        onPressed: _showAddItemsPopup,
        icon: const Icon(Icons.add_shopping_cart, size: 20),
        label: const Text(
          'Add Items to Bill',
          style: TextStyle(
            fontFamily: 'Literata',
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1B4D3E),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
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
                const Text(
                  'Bill Items',
                  style: TextStyle(
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
                    '${_billItems.length} items',
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
                                    'Max stock: ${product.currentStock}',
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
              const Text(
                'Discount',
                style: TextStyle(
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
                        ? 'Enter %'
                        : 'Enter amount',
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
                        'Subtotal',
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
                      const Text(
                        'Final Total',
                        style: TextStyle(
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
                  '$_totalQuantity items',
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
                  : const Text(
                      'Save Bill',
                      style: TextStyle(
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

  const _AddItemsBottomSheet({
    required this.products,
    required this.billItems,
    required this.onItemAdded,
    required this.onItemRemoved,
    required this.showSnackbar,
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
        _filteredProducts = widget.products
            .where(
              (p) =>
                  p.name.toLowerCase().contains(lowerQuery) ||
                  p.companyName.toLowerCase().contains(lowerQuery) ||
                  p.category.toLowerCase().contains(lowerQuery),
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
      widget.showSnackbar('Max stock: ${product.currentStock}', isError: true);
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
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Add Items',
                          style: TextStyle(
                            fontFamily: 'Literata',
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1B4D3E),
                          ),
                        ),
                        Text(
                          'Tap + to add multiple items',
                          style: TextStyle(
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
                        '$_totalItems items',
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
                  hintText: 'Search products...',
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
                            'No products found',
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
                                // Product icon
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: const Color(
                                      0xFF1B4D3E,
                                    ).withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(
                                    Icons.inventory_2,
                                    color: Color(0xFF1B4D3E),
                                    size: 20,
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
                    _totalItems > 0 ? 'Done ($_totalItems items)' : 'Done',
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

  const _CustomerPickerBottomSheet({
    required this.customers,
    required this.onCustomerSelected,
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
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Select Customer',
                          style: TextStyle(
                            fontFamily: 'Literata',
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1B4D3E),
                          ),
                        ),
                        Text(
                          'Choose from existing customers',
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
            // Search bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                controller: _searchController,
                onChanged: _filterCustomers,
                style: const TextStyle(fontFamily: 'Literata', fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Search by name or phone...',
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
                            'No customers found',
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

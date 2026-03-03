import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:c_billing/core/localization/app_localizations.dart';
import 'package:c_billing/core/services/language_service.dart';
import '../../../../core/services/session_manager.dart';
import '../../../../core/services/dashboard_refresh_service.dart';
import '../../data/services/purchase_return_service.dart';
import '../../domain/entities/purchase_return.dart';

// ──────────────────────────────────────────────────────────
// A premium Purchase Return screen with:
//  - Tab bar: New Return | Return History
//  - Searchable supplier dropdown
//  - Date picker
//  - Product data table with real-time validation
//  - Return mode toggle (Full Batch / Partial)
//  - Batch breakdown bottom sheet
//  - Analytics impact preview
//  - Swipe-to-remove
//  - Sticky "Process Return" button
// ──────────────────────────────────────────────────────────

class PurchaseReturnScreen extends StatefulWidget {
  const PurchaseReturnScreen({super.key});

  @override
  State<PurchaseReturnScreen> createState() => _PurchaseReturnScreenState();
}

class _PurchaseReturnScreenState extends State<PurchaseReturnScreen>
    with SingleTickerProviderStateMixin {
  // ── Localization ──
  late AppLocalizations _localizations;

  // ── Tab ──
  late TabController _tabController;

  // ── Services ──
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  final _service = PurchaseReturnService.instance;
  final _sessionManager = SessionManager();

  // ── Supplier ──
  List<Map<String, dynamic>> _suppliers = [];
  Map<String, dynamic>? _selectedSupplier;
  bool _isLoadingSuppliers = true;

  // ── Date ──
  DateTime _returnDate = DateTime.now();

  // ── Products ──
  List<ReturnableBatchInfo> _products = [];
  bool _isLoadingProducts = false;
  final Map<String, TextEditingController> _qtyControllers = {};
  final Map<String, int> _returnQuantities = {};
  final Map<String, bool> _qtyErrors = {};

  // ── Search ──
  final _supplierSearchCtrl = TextEditingController();
  final _productSearchCtrl = TextEditingController();
  Timer? _searchDebounce;

  // ── Reason ──
  final _reasonCtrl = TextEditingController();

  // ── Return Mode ──
  bool _isPartialMode = true; // true = Partial, false = Full Batch

  // ── Processing ──
  bool _isProcessing = false;

  // ── History ──
  List<PurchaseReturn> _returnHistory = [];
  bool _isLoadingHistory = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.index == 1 && _returnHistory.isEmpty) {
        _loadReturnHistory();
      }
    });
    _loadSuppliers();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _supplierSearchCtrl.dispose();
    _productSearchCtrl.dispose();
    _reasonCtrl.dispose();
    _searchDebounce?.cancel();
    for (final c in _qtyControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  // ━━━━━━━━━━━━ DATA LOADING ━━━━━━━━━━━━

  Future<void> _loadSuppliers() async {
    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) return;
      final snap = await _firestore
          .collection('users')
          .doc(uid)
          .collection('suppliers')
          .get();
      final list = snap.docs.map((d) {
        final data = d.data();
        // Firebase stores firstName/middleName/lastName, not a single "name"
        final firstName = (data['firstName'] ?? '').toString().trim();
        final middleName = (data['middleName'] ?? '').toString().trim();
        final lastName = (data['lastName'] ?? '').toString().trim();
        final fullName = [
          firstName,
          middleName,
          lastName,
        ].where((s) => s.isNotEmpty).join(' ');
        return <String, dynamic>{
          'id': d.id,
          'name': fullName.isNotEmpty
              ? fullName
              : (data['name'] ?? data['supplierName'] ?? 'Unknown'),
          'contact': data['contact'] ?? data['mobile'] ?? '',
          'address': data['address'] ?? '',
          'companyName': data['companyName'] ?? '',
        };
      }).toList();
      list.sort((a, b) => (a['name'] as String).compareTo(b['name'] as String));
      if (mounted) {
        setState(() {
          _suppliers = list;
          _isLoadingSuppliers = false;
        });
      }
    } catch (e) {
      debugPrint('[PurchaseReturn] Load suppliers error: $e');
      if (mounted) setState(() => _isLoadingSuppliers = false);
    }
  }

  Future<void> _loadProductsForSupplier(String supplierId) async {
    setState(() => _isLoadingProducts = true);
    try {
      final products = await _service.getReturnableProductsForSupplier(
        supplierId,
      );
      // Clear old controllers
      for (final c in _qtyControllers.values) {
        c.dispose();
      }
      _qtyControllers.clear();
      _returnQuantities.clear();
      _qtyErrors.clear();

      for (final p in products) {
        _qtyControllers[p.productId] = TextEditingController(text: '0');
        _returnQuantities[p.productId] = 0;
        _qtyErrors[p.productId] = false;
      }

      if (mounted) {
        setState(() {
          _products = products;
          _isLoadingProducts = false;
        });
      }
    } catch (e) {
      debugPrint('[PurchaseReturn] Load products error: $e');
      if (mounted) setState(() => _isLoadingProducts = false);
    }
  }

  Future<void> _loadReturnHistory() async {
    setState(() => _isLoadingHistory = true);
    try {
      final history = await _service.getReturnHistory();
      if (mounted) {
        setState(() {
          _returnHistory = history;
          _isLoadingHistory = false;
        });
      }
    } catch (e) {
      debugPrint('[PurchaseReturn] Load history error: $e');
      if (mounted) setState(() => _isLoadingHistory = false);
    }
  }

  // ━━━━━━━━━━━━ ACTIONS ━━━━━━━━━━━━

  void _onSupplierSelected(Map<String, dynamic> supplier) {
    setState(() {
      _selectedSupplier = supplier;
    });
    _loadProductsForSupplier(supplier['id'] as String);
    Navigator.pop(context); // close bottom sheet
  }

  void _onQtyChanged(String productId, String value, int maxQty) {
    final qty = int.tryParse(value) ?? 0;
    setState(() {
      _returnQuantities[productId] = qty;
      _qtyErrors[productId] = qty < 0 || qty > maxQty;
    });
  }

  void _setFullBatchQty(String productId, int maxQty) {
    _qtyControllers[productId]?.text = maxQty.toString();
    _onQtyChanged(productId, maxQty.toString(), maxQty);
  }

  List<ReturnableBatchInfo> get _filteredProducts {
    final q = _productSearchCtrl.text.toLowerCase().trim();
    if (q.isEmpty) return _products;
    return _products.where((p) {
      return p.productName.toLowerCase().contains(q) ||
          p.companyName.toLowerCase().contains(q) ||
          p.modelName.toLowerCase().contains(q);
    }).toList();
  }

  int get _totalReturnQty => _returnQuantities.values.fold(0, (s, v) => s + v);
  int get _totalItemsWithQty =>
      _returnQuantities.values.where((v) => v > 0).length;
  double get _totalReturnAmount {
    double total = 0;
    for (final p in _products) {
      final qty = _returnQuantities[p.productId] ?? 0;
      if (qty > 0) total += p.purchasePrice * qty;
    }
    return total;
  }

  bool get _hasErrors => _qtyErrors.values.any((v) => v);
  bool get _canProcess =>
      _selectedSupplier != null && _totalItemsWithQty > 0 && !_hasErrors;

  // ━━━━━━━━━━━━ PROCESS ━━━━━━━━━━━━

  Future<void> _showConfirmationDialog() async {
    if (!_canProcess) {
      _showSnackbar('Fix errors before processing', true);
      return;
    }

    // Build items for preview
    final items = <PurchaseReturnItem>[];
    for (final p in _products) {
      final qty = _returnQuantities[p.productId] ?? 0;
      if (qty <= 0) continue;
      items.add(
        PurchaseReturnItem(
          id: '',
          productId: p.productId,
          productName: p.productName,
          companyName: p.companyName,
          modelName: p.modelName,
          batchId: p.batchId,
          localBatchId: p.localBatchId,
          quantity: qty,
          rate: p.purchasePrice,
          amount: p.purchasePrice * qty,
        ),
      );
    }

    // Get impact preview
    final impact = await _service.previewReturnImpact(items);

    if (!mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => _buildConfirmationDialog(ctx, items, impact),
    );

    if (confirmed == true) {
      _processReturn(items);
    }
  }

  Future<void> _processReturn(List<PurchaseReturnItem> items) async {
    setState(() => _isProcessing = true);
    try {
      final result = await _service.processReturn(
        supplierId: _selectedSupplier!['id'] as String,
        supplierName: _selectedSupplier!['name'] as String,
        returnDate: _returnDate,
        reason: _reasonCtrl.text.trim(),
        items: items,
      );

      if (result.success) {
        _showSnackbar(_localizations.returnProcessedSuccessfully, false);
        _resetForm();
        // Notify dashboard to refresh data
        DashboardRefreshService.instance.notifyDataChanged(
          DataChangeType.purchaseReturn,
        );
        // Refresh history
        _loadReturnHistory();
      } else {
        _showSnackbar(result.errorMessage ?? 'Failed', true);
      }
    } catch (e) {
      _showSnackbar('Error: $e', true);
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _resetForm() {
    setState(() {
      _selectedSupplier = null;
      _products = [];
      for (final c in _qtyControllers.values) {
        c.dispose();
      }
      _qtyControllers.clear();
      _returnQuantities.clear();
      _qtyErrors.clear();
      _reasonCtrl.clear();
      _productSearchCtrl.clear();
      _returnDate = DateTime.now();
    });
  }

  void _removeProduct(String productId) {
    setState(() {
      _products.removeWhere((p) => p.productId == productId);
      _qtyControllers[productId]?.dispose();
      _qtyControllers.remove(productId);
      _returnQuantities.remove(productId);
      _qtyErrors.remove(productId);
    });
  }

  void _showSnackbar(String msg, bool isError) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontFamily: 'Literata')),
        backgroundColor: isError ? Colors.red : const Color(0xFF1B4D3E),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  // ━━━━━━━━━━━━ BUILD ━━━━━━━━━━━━

  @override
  Widget build(BuildContext context) {
    _localizations = AppLocalizations.of(
      LanguageService.instance.currentLanguage,
    );
    _sessionManager.resetSession();
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: _buildAppBar(),
      body: TabBarView(
        controller: _tabController,
        children: [_buildNewReturnTab(), _buildHistoryTab()],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(110),
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
          child: Column(
            children: [
              // Title row
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Icon(
                        Icons.arrow_back_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _localizations.purchaseReturn,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'Literata',
                            ),
                          ),
                          Text(
                            _localizations.returnStockToSupplier,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                              fontFamily: 'Literata',
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Return mode toggle
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _isPartialMode
                                ? Icons.tune_rounded
                                : Icons.all_inclusive_rounded,
                            color: Colors.white,
                            size: 14,
                          ),
                          const SizedBox(width: 6),
                          GestureDetector(
                            onTap: () => setState(
                              () => _isPartialMode = !_isPartialMode,
                            ),
                            child: Text(
                              _isPartialMode
                                  ? _localizations.partial
                                  : _localizations.fullBatch,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                fontFamily: 'Literata',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Tab bar
              TabBar(
                controller: _tabController,
                indicatorColor: Colors.white,
                indicatorWeight: 3,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white54,
                labelStyle: const TextStyle(
                  fontFamily: 'Literata',
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
                tabs: [
                  Tab(text: _localizations.newReturn),
                  Tab(text: _localizations.returnHistory),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────── NEW RETURN TAB ───────────

  Widget _buildNewReturnTab() {
    return Stack(
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 180),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTopSection(),
              const SizedBox(height: 16),
              if (_selectedSupplier != null) ...[
                _buildProductSearch(),
                const SizedBox(height: 12),
                _buildProductTable(),
                const SizedBox(height: 16),
                _buildReasonField(),
                const SizedBox(height: 16),
                _buildSummaryCard(),
              ],
            ],
          ),
        ),
        // Sticky bottom button
        if (_selectedSupplier != null)
          Positioned(bottom: 0, left: 0, right: 0, child: _buildStickyButton()),
      ],
    );
  }

  // ─── TOP SECTION: Supplier + Date ───

  Widget _buildTopSection() {
    return Container(
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
          const Text(
            'Return Details',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              fontFamily: 'Literata',
              color: Color(0xFF1B4D3E),
            ),
          ),
          const SizedBox(height: 14),
          // Supplier selector
          GestureDetector(
            onTap: _showSupplierPicker,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.local_shipping_outlined,
                    color: Colors.grey[600],
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _selectedSupplier != null
                          ? _selectedSupplier!['name'] as String
                          : '${_localizations.selectSupplier} *',
                      style: TextStyle(
                        fontFamily: 'Literata',
                        fontSize: 14,
                        color: _selectedSupplier != null
                            ? const Color(0xFF1B4D3E)
                            : Colors.grey[500],
                        fontWeight: _selectedSupplier != null
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                  Icon(Icons.keyboard_arrow_down, color: Colors.grey[600]),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Date picker
          GestureDetector(
            onTap: _pickDate,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_today_outlined,
                    color: Colors.grey[600],
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    DateFormat('dd MMM yyyy').format(_returnDate),
                    style: const TextStyle(
                      fontFamily: 'Literata',
                      fontSize: 14,
                      color: Color(0xFF1B4D3E),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _returnDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: Color(0xFF1B4D3E)),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _returnDate = picked);
  }

  // ─── SUPPLIER PICKER BOTTOM SHEET ───

  void _showSupplierPicker() {
    _supplierSearchCtrl.clear();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _buildSupplierPickerSheet(),
    );
  }

  Widget _buildSupplierPickerSheet() {
    return StatefulBuilder(
      builder: (ctx, setSheetState) {
        final q = _supplierSearchCtrl.text.toLowerCase().trim();
        final filtered = q.isEmpty
            ? _suppliers
            : _suppliers
                  .where(
                    (s) =>
                        (s['name'] as String).toLowerCase().contains(q) ||
                        (s['contact'] as String).toLowerCase().contains(q),
                  )
                  .toList();

        return Container(
          height: MediaQuery.of(context).size.height * 0.7,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Handle
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              // Title + search
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _localizations.selectSupplier,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Literata',
                        color: Color(0xFF1B4D3E),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: TextField(
                        controller: _supplierSearchCtrl,
                        style: const TextStyle(
                          fontFamily: 'Literata',
                          fontSize: 14,
                        ),
                        decoration: InputDecoration(
                          hintText: _localizations.searchSupplier,
                          hintStyle: TextStyle(color: Colors.grey[400]),
                          prefixIcon: Icon(
                            Icons.search,
                            color: Colors.grey[600],
                            size: 20,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 12,
                          ),
                        ),
                        onChanged: (_) => setSheetState(() {}),
                      ),
                    ),
                  ],
                ),
              ),
              // List
              Expanded(
                child: _isLoadingSuppliers
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF1B4D3E),
                        ),
                      )
                    : filtered.isEmpty
                    ? Center(
                        child: Text(
                          _localizations.noSuppliersFound,
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontFamily: 'Literata',
                          ),
                        ),
                      )
                    : ListView.separated(
                        itemCount: filtered.length,
                        separatorBuilder: (_, _) =>
                            Divider(height: 1, color: Colors.grey[200]),
                        itemBuilder: (_, i) {
                          final s = filtered[i];
                          final isSelected =
                              _selectedSupplier?['id'] == s['id'];
                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 4,
                            ),
                            leading: CircleAvatar(
                              backgroundColor: isSelected
                                  ? const Color(0xFF1B4D3E)
                                  : Colors.grey[200],
                              child: Text(
                                (s['name'] as String).isNotEmpty
                                    ? (s['name'] as String)[0].toUpperCase()
                                    : 'S',
                                style: TextStyle(
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.grey[700],
                                  fontWeight: FontWeight.w700,
                                  fontFamily: 'Literata',
                                ),
                              ),
                            ),
                            title: Text(
                              s['name'] as String,
                              style: TextStyle(
                                fontFamily: 'Literata',
                                fontWeight: FontWeight.w600,
                                color: isSelected
                                    ? const Color(0xFF1B4D3E)
                                    : Colors.black87,
                              ),
                            ),
                            subtitle: Text(
                              s['contact'] as String,
                              style: TextStyle(
                                fontFamily: 'Literata',
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                            trailing: isSelected
                                ? const Icon(
                                    Icons.check_circle,
                                    color: Color(0xFF1B4D3E),
                                  )
                                : null,
                            onTap: () => _onSupplierSelected(s),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ─── PRODUCT SEARCH ───

  Widget _buildProductSearch() {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _productSearchCtrl,
        style: const TextStyle(fontFamily: 'Literata', fontSize: 14),
        decoration: InputDecoration(
          hintText: _localizations.searchProducts,
          hintStyle: TextStyle(color: Colors.grey[400]),
          prefixIcon: Icon(Icons.search, color: Colors.grey[600], size: 20),
          suffixIcon: _productSearchCtrl.text.isNotEmpty
              ? GestureDetector(
                  onTap: () {
                    _productSearchCtrl.clear();
                    setState(() {});
                  },
                  child: Icon(Icons.close, color: Colors.grey[600], size: 18),
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
        onChanged: (_) => setState(() {}),
      ),
    );
  }

  // ─── PRODUCT TABLE ───

  Widget _buildProductTable() {
    if (_isLoadingProducts) {
      return const Padding(
        padding: EdgeInsets.all(40),
        child: Center(
          child: CircularProgressIndicator(color: Color(0xFF1B4D3E)),
        ),
      );
    }

    final filtered = _filteredProducts;

    if (filtered.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.inventory_2_outlined,
                size: 48,
                color: Colors.grey[300],
              ),
              const SizedBox(height: 12),
              Text(
                _products.isEmpty
                    ? _localizations.noReturnableProducts
                    : _localizations.noProductsMatchSearch,
                style: TextStyle(
                  color: Colors.grey[500],
                  fontFamily: 'Literata',
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Container(
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
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Row(
              children: [
                Text(
                  _localizations.productsLabel,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Literata',
                    color: Color(0xFF1B4D3E),
                  ),
                ),
                const Spacer(),
                Text(
                  '${filtered.length} ${_localizations.itemsLabel}',
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 12,
                    fontFamily: 'Literata',
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Product rows
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: filtered.length,
            separatorBuilder: (_, _) =>
                Divider(height: 1, color: Colors.grey[100]),
            itemBuilder: (_, i) => _buildProductRow(filtered[i]),
          ),
        ],
      ),
    );
  }

  Widget _buildProductRow(ReturnableBatchInfo product) {
    final qty = _returnQuantities[product.productId] ?? 0;
    final hasError = _qtyErrors[product.productId] ?? false;
    final amount = product.purchasePrice * qty;
    final ctrl = _qtyControllers[product.productId];

    return Dismissible(
      key: Key(product.productId),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.red[50],
        child: Icon(Icons.delete_outline, color: Colors.red[400]),
      ),
      onDismissed: (_) => _removeProduct(product.productId),
      child: GestureDetector(
        onTap: () => _showBatchBreakdown(product),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product name + company
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.productName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            fontFamily: 'Literata',
                            color: Color(0xFF1B4D3E),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (product.companyName.isNotEmpty)
                          Text(
                            product.companyName,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[600],
                              fontFamily: 'Literata',
                            ),
                          ),
                      ],
                    ),
                  ),
                  // Batch info icon
                  GestureDetector(
                    onTap: () => _showBatchBreakdown(product),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1B4D3E).withOpacity(0.08),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(
                        Icons.layers_outlined,
                        size: 16,
                        color: Color(0xFF1B4D3E),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // Stats row
              Row(
                children: [
                  // Available
                  _buildMiniTag(
                    'Avail: ${product.quantityRemaining}',
                    Colors.blue[50]!,
                    Colors.blue[700]!,
                  ),
                  const SizedBox(width: 8),
                  // Purchase rate
                  _buildMiniTag(
                    '₹${product.purchasePrice.toStringAsFixed(0)}/unit',
                    Colors.green[50]!,
                    Colors.green[700]!,
                  ),
                  const Spacer(),
                  // Amount
                  if (qty > 0)
                    Text(
                      '₹${amount.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        fontFamily: 'Literata',
                        color: Color(0xFF1B4D3E),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              // Quantity input row
              Row(
                children: [
                  const Text(
                    'Return Qty:',
                    style: TextStyle(
                      fontSize: 12,
                      fontFamily: 'Literata',
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Minus button
                  _buildQtyButton(Icons.remove, () {
                    if (qty > 0) {
                      ctrl?.text = (qty - 1).toString();
                      _onQtyChanged(
                        product.productId,
                        ctrl?.text ?? '0',
                        product.quantityRemaining,
                      );
                    }
                  }),
                  const SizedBox(width: 6),
                  // Qty input
                  SizedBox(
                    width: 60,
                    height: 36,
                    child: TextField(
                      controller: ctrl,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Literata',
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: hasError ? Colors.red : const Color(0xFF1B4D3E),
                      ),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: hasError ? Colors.red[50] : Colors.grey[50],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: hasError ? Colors.red : Colors.grey[300]!,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: hasError ? Colors.red : Colors.grey[300]!,
                          ),
                        ),
                        contentPadding: EdgeInsets.zero,
                        isDense: true,
                      ),
                      onChanged: (v) => _onQtyChanged(
                        product.productId,
                        v,
                        product.quantityRemaining,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  // Plus button
                  _buildQtyButton(Icons.add, () {
                    if (qty < product.quantityRemaining) {
                      ctrl?.text = (qty + 1).toString();
                      _onQtyChanged(
                        product.productId,
                        ctrl?.text ?? '0',
                        product.quantityRemaining,
                      );
                    }
                  }),
                  const SizedBox(width: 10),
                  // Full batch button (non-partial mode)
                  if (!_isPartialMode)
                    GestureDetector(
                      onTap: () => _setFullBatchQty(
                        product.productId,
                        product.quantityRemaining,
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1B4D3E).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'All',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'Literata',
                            color: Color(0xFF1B4D3E),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              // Error message
              if (hasError)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    'Max qty: ${product.quantityRemaining}',
                    style: const TextStyle(
                      color: Colors.red,
                      fontSize: 11,
                      fontFamily: 'Literata',
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMiniTag(String text, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          fontFamily: 'Literata',
          color: fg,
        ),
      ),
    );
  }

  Widget _buildQtyButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Icon(icon, size: 16, color: const Color(0xFF1B4D3E)),
      ),
    );
  }

  // ─── BATCH BREAKDOWN BOTTOM SHEET ───

  void _showBatchBreakdown(ReturnableBatchInfo product) async {
    final batches = await _service.getBatchBreakdownForProduct(
      product.productId,
      _selectedSupplier!['id'] as String,
    );

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.6,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.productName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'Literata',
                            color: Color(0xFF1B4D3E),
                          ),
                        ),
                        Text(
                          '${batches.length} batches available',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                            fontFamily: 'Literata',
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.all(16),
                itemCount: batches.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (_, i) {
                  final b = batches[i];
                  // Risk indicator: compare purchase price
                  final priceDiffers = product.purchasePrice != b.purchasePrice;
                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: priceDiffers ? Colors.amber[50] : Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: priceDiffers
                            ? Colors.amber[300]!
                            : Colors.grey[200]!,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Batch #${i + 1}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                                fontFamily: 'Literata',
                                color: Color(0xFF1B4D3E),
                              ),
                            ),
                            if (priceDiffers) ...[
                              const SizedBox(width: 6),
                              Icon(
                                Icons.warning_amber_rounded,
                                size: 16,
                                color: Colors.amber[700],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Price differs',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.amber[800],
                                  fontFamily: 'Literata',
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                            const Spacer(),
                            Text(
                              DateFormat('dd MMM yy').format(b.purchaseDate),
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[600],
                                fontFamily: 'Literata',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            _buildMiniTag(
                              'Qty: ${b.quantityRemaining}',
                              Colors.blue[50]!,
                              Colors.blue[700]!,
                            ),
                            const SizedBox(width: 8),
                            _buildMiniTag(
                              '₹${b.purchasePrice.toStringAsFixed(0)}',
                              Colors.green[50]!,
                              Colors.green[700]!,
                            ),
                            const SizedBox(width: 8),
                            _buildMiniTag(
                              'Sell: ₹${b.sellingPrice.toStringAsFixed(0)}',
                              Colors.purple[50]!,
                              Colors.purple[700]!,
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
      ),
    );
  }

  // ─── REASON FIELD ───

  Widget _buildReasonField() {
    return Container(
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
          const Text(
            'Return Reason',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              fontFamily: 'Literata',
              color: Color(0xFF1B4D3E),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _reasonCtrl,
            maxLines: 3,
            style: const TextStyle(fontFamily: 'Literata', fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Enter reason for return (optional)',
              hintStyle: TextStyle(color: Colors.grey[400]),
              filled: true,
              fillColor: Colors.grey[50],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              enabledBorder: OutlineInputBorder(
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
        ],
      ),
    );
  }

  // ─── SUMMARY CARD ───

  Widget _buildSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF1B4D3E).withOpacity(0.08),
            const Color(0xFF1B4D3E).withOpacity(0.03),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1B4D3E).withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Return Summary',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              fontFamily: 'Literata',
              color: Color(0xFF1B4D3E),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildSummaryStat(
                'Items',
                '$_totalItemsWithQty',
                Icons.inventory_outlined,
              ),
              _buildSummaryStat('Total Qty', '$_totalReturnQty', Icons.numbers),
              _buildSummaryStat(
                'Amount',
                '₹${_totalReturnAmount.toStringAsFixed(0)}',
                Icons.currency_rupee,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryStat(String label, String value, IconData icon) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 20, color: const Color(0xFF1B4D3E)),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              fontFamily: 'Literata',
              color: Color(0xFF1B4D3E),
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[600],
              fontFamily: 'Literata',
            ),
          ),
        ],
      ),
    );
  }

  // ─── STICKY BUTTON ───

  Widget _buildStickyButton() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: _canProcess && !_isProcessing
                ? _showConfirmationDialog
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1B4D3E),
              disabledBackgroundColor: Colors.grey[300],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 0,
            ),
            child: _isProcessing
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(Colors.white),
                    ),
                  )
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.keyboard_return_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                      SizedBox(width: 10),
                      Text(
                        'Process Return',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Literata',
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  // ─── CONFIRMATION DIALOG ───

  Widget _buildConfirmationDialog(
    BuildContext ctx,
    List<PurchaseReturnItem> items,
    ReturnImpactPreview impact,
  ) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1B4D3E).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.fact_check_outlined,
                      color: Color(0xFF1B4D3E),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Confirm Purchase Return',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Literata',
                        color: Color(0xFF1B4D3E),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Items list
              ...items.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.productName,
                          style: const TextStyle(
                            fontFamily: 'Literata',
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Text(
                        '${item.quantity} × ₹${item.rate.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontFamily: 'Literata',
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        '₹${item.amount.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontFamily: 'Literata',
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1B4D3E),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Divider(),
              // Impact preview
              const Text(
                'Impact Preview',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Literata',
                  color: Color(0xFF1B4D3E),
                ),
              ),
              const SizedBox(height: 8),
              _buildImpactRow(
                'Supplier Credit',
                '₹${impact.supplierCreditAdjustment.toStringAsFixed(0)}',
                Colors.blue[700]!,
              ),
              _buildImpactRow(
                'Inventory Value',
                '${impact.inventoryValueChange >= 0 ? '+' : ''}₹${impact.inventoryValueChange.toStringAsFixed(0)}',
                impact.inventoryValueChange >= 0
                    ? Colors.green[700]!
                    : Colors.red[700]!,
              ),
              // Stock after return
              if (impact.stockAfterReturn.isNotEmpty) ...[
                const SizedBox(height: 6),
                ...impact.stockAfterReturn.entries.map((e) {
                  final productName = items
                      .firstWhere(
                        (i) => i.productId == e.key,
                        orElse: () => items.first,
                      )
                      .productName;
                  return _buildImpactRow(
                    productName,
                    'Stock: ${e.value}',
                    Colors.grey[700]!,
                  );
                }),
              ],
              const SizedBox(height: 16),
              // Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          fontFamily: 'Literata',
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1B4D3E),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1B4D3E),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        'Confirm Return',
                        style: TextStyle(
                          fontFamily: 'Literata',
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
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
  }

  Widget _buildImpactRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Literata',
              fontSize: 12,
              color: Colors.grey[600],
            ),
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Literata',
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // ─────────── HISTORY TAB ───────────

  Widget _buildHistoryTab() {
    if (_isLoadingHistory) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF1B4D3E)),
      );
    }
    if (_returnHistory.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF1B4D3E).withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                Icons.history,
                size: 48,
                color: const Color(0xFF1B4D3E).withOpacity(0.3),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _localizations.noReturnsYet,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                fontFamily: 'Literata',
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _localizations.processFirstReturn,
              style: TextStyle(
                fontSize: 13,
                fontFamily: 'Literata',
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadReturnHistory,
      color: const Color(0xFF1B4D3E),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _returnHistory.length,
        itemBuilder: (_, i) => _buildHistoryCard(_returnHistory[i]),
      ),
    );
  }

  Widget _buildHistoryCard(PurchaseReturn ret) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
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
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.keyboard_return_rounded,
                  color: Color(0xFF1B4D3E),
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ret.supplierName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        fontFamily: 'Literata',
                        color: Color(0xFF1B4D3E),
                      ),
                    ),
                    Text(
                      DateFormat('dd MMM yyyy').format(ret.returnDate),
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[600],
                        fontFamily: 'Literata',
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '₹${ret.totalAmount.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      fontFamily: 'Literata',
                      color: Color(0xFF1B4D3E),
                    ),
                  ),
                  _buildMiniTag(
                    '${ret.totalItems} items',
                    Colors.blue[50]!,
                    Colors.blue[700]!,
                  ),
                ],
              ),
            ],
          ),
          if (ret.reason.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.comment_outlined,
                    size: 14,
                    color: Colors.grey[500],
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      ret.reason,
                      style: TextStyle(
                        fontSize: 12,
                        fontFamily: 'Literata',
                        color: Colors.grey[700],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
          // Items list
          if (ret.items.isNotEmpty) ...[
            const SizedBox(height: 8),
            ...ret.items
                .take(3)
                .map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        Text(
                          '• ${item.productName}',
                          style: TextStyle(
                            fontSize: 12,
                            fontFamily: 'Literata',
                            color: Colors.grey[700],
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${item.quantity} × ₹${item.rate.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontSize: 11,
                            fontFamily: 'Literata',
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            if (ret.items.length > 3)
              Text(
                '+${ret.items.length - 3} more items',
                style: TextStyle(
                  fontSize: 11,
                  fontFamily: 'Literata',
                  color: Colors.grey[500],
                  fontStyle: FontStyle.italic,
                ),
              ),
          ],
        ],
      ),
    );
  }
}

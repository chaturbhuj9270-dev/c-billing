import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:c_billing/core/services/billing_service.dart';
import 'package:c_billing/features/billing/data/repositories/firebase_bill_repository.dart';
import 'package:c_billing/features/billing/domain/entities/bill.dart';
import 'package:c_billing/features/inventory_management/data/repositories/firebase_product_repository.dart';
import 'package:c_billing/features/inventory_management/data/repositories/firebase_stock_repository.dart';

class BillsListPage extends StatefulWidget {
  const BillsListPage({super.key});

  @override
  State<BillsListPage> createState() => _BillsListPageState();
}

class _BillsListPageState extends State<BillsListPage>
    with SingleTickerProviderStateMixin {
  late BillingService _billingService;
  late FirebaseFirestore _firestore;
  late AnimationController _animController;
  late Animation<Offset> _offsetAnimation;
  late Animation<double> _opacityAnimation;

  List<Bill> _bills = [];
  List<Bill> _filteredBills = [];
  bool _isLoading = false;
  final _searchController = TextEditingController();

  // Filter options
  DateTime? _startDate;
  DateTime? _endDate;
  String _sortOrder = 'newest';

  // Stats
  double _totalSales = 0.0;
  int _totalBillsCount = 0;

  @override
  void initState() {
    super.initState();
    _firestore = FirebaseFirestore.instance;

    _billingService = BillingService(
      billRepository: FirebaseBillRepository(firestore: _firestore),
      productRepository: FirebaseProductRepository(firestore: _firestore),
      stockRepository: FirebaseStockRepository(firestore: _firestore),
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

    _loadBills();
  }

  @override
  void dispose() {
    _animController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadBills() async {
    try {
      setState(() => _isLoading = true);

      List<Bill> bills;
      if (_startDate != null && _endDate != null) {
        bills = await _billingService.getBillsByDateRange(
          _startDate!,
          _endDate!,
        );
      } else {
        bills = await _billingService.getAllBills();
      }

      // Calculate stats (use finalAmount to account for discounts)
      _totalSales = bills.fold(0.0, (sum, bill) => sum + bill.finalAmount);
      _totalBillsCount = bills.length;

      setState(() {
        _bills = bills;
        _filteredBills = bills;
        _applySorting();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading bills: $e')));
      }
    }
  }

  void _filterBills(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredBills = _bills;
      } else {
        _filteredBills = _bills.where((bill) {
          final customerName = bill.customerName?.toLowerCase() ?? '';
          final customerContact = bill.customerContact?.toLowerCase() ?? '';
          final billId = bill.id.toLowerCase();
          final searchQuery = query.toLowerCase();

          return customerName.contains(searchQuery) ||
              customerContact.contains(searchQuery) ||
              billId.contains(searchQuery);
        }).toList();
      }
      _applySorting();
    });
  }

  void _applySorting() {
    _filteredBills.sort((a, b) {
      switch (_sortOrder) {
        case 'newest':
          return b.billDate.compareTo(a.billDate);
        case 'oldest':
          return a.billDate.compareTo(b.billDate);
        case 'highest':
          return b.totalAmount.compareTo(a.totalAmount);
        case 'lowest':
          return a.totalAmount.compareTo(b.totalAmount);
        default:
          return b.billDate.compareTo(a.billDate);
      }
    });
  }

  void _showDateFilterDialog() async {
    final result = await showDialog<Map<String, DateTime?>>(
      context: context,
      builder: (context) => _DateRangePickerDialog(
        initialStartDate: _startDate,
        initialEndDate: _endDate,
      ),
    );

    if (result != null) {
      setState(() {
        _startDate = result['startDate'];
        _endDate = result['endDate'];
      });
      _loadBills();
    }
  }

  void _clearDateFilter() {
    setState(() {
      _startDate = null;
      _endDate = null;
    });
    _loadBills();
  }

  void _showBillDetails(Bill bill) {
    showDialog(
      context: context,
      builder: (context) => _BillDetailsDialog(bill: bill),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),
      appBar: PreferredSize(
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
                    onTap: () => Navigator.pop(context),
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
                          'Bills History',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'Literata',
                            height: 1.2,
                          ),
                        ),
                        Text(
                          'View all transactions',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 11,
                            fontFamily: 'Literata',
                            height: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: _loadBills,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.refresh,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : FadeTransition(
              opacity: _opacityAnimation,
              child: SlideTransition(
                position: _offsetAnimation,
                child: Column(
                  children: [
                    // Stats cards
                    _buildStatsSection(),
                    // Search and filter
                    _buildSearchAndFilterSection(),
                    // Bills list
                    Expanded(child: _buildBillsList()),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildStatsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              'Total Sales',
              '₹${_formatAmount(_totalSales)}',
              Icons.currency_rupee,
              const Color(0xFF1B4D3E),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              'Total Bills',
              '$_totalBillsCount',
              Icons.receipt_long,
              const Color(0xFF2196F3),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              'Avg. Bill',
              _totalBillsCount > 0
                  ? '₹${_formatAmount(_totalSales / _totalBillsCount)}'
                  : '₹0',
              Icons.analytics,
              const Color(0xFFFF9800),
            ),
          ),
        ],
      ),
    );
  }

  String _formatAmount(double amount) {
    if (amount >= 100000) {
      return '${(amount / 100000).toStringAsFixed(1)}L';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(1)}K';
    }
    return amount.toStringAsFixed(0);
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      constraints: const BoxConstraints(minHeight: 100),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, Colors.white.withOpacity(0.95)],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.15), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.12),
            blurRadius: 16,
            offset: const Offset(0, 6),
            spreadRadius: 2,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [color.withOpacity(0.2), color.withOpacity(0.08)],
              ),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: color.withOpacity(0.25), width: 1),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Literata',
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: color,
              letterSpacing: -0.5,
              height: 1.1,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontFamily: 'Literata',
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Colors.grey[700],
              letterSpacing: 0.2,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilterSection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // Search bar
          TextField(
            controller: _searchController,
            onChanged: _filterBills,
            decoration: InputDecoration(
              hintText: 'Search bills...',
              hintStyle: TextStyle(
                fontFamily: 'Literata',
                fontSize: 14,
                color: Colors.grey[500],
              ),
              prefixIcon: const Icon(
                Icons.search,
                color: Color(0xFF1B4D3E),
                size: 20,
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(
                  color: Color(0xFF1B4D3E),
                  width: 1.5,
                ),
              ),
            ),
            style: const TextStyle(fontFamily: 'Literata', fontSize: 14),
          ),
          const SizedBox(height: 10),
          // Filter row - responsive
          LayoutBuilder(
            builder: (context, constraints) {
              return Row(
                children: [
                  // Date filter button - flexible
                  Flexible(
                    child: GestureDetector(
                      onTap: _showDateFilterDialog,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: _startDate != null
                              ? const Color(0xFF1B4D3E)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _startDate != null
                                ? const Color(0xFF1B4D3E)
                                : Colors.grey[300]!,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.date_range,
                              size: 16,
                              color: _startDate != null
                                  ? Colors.white
                                  : Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                _startDate != null
                                    ? '${DateFormat('dd/MM').format(_startDate!)} - ${DateFormat('dd/MM').format(_endDate!)}'
                                    : 'Date',
                                style: TextStyle(
                                  fontFamily: 'Literata',
                                  fontSize: 11,
                                  color: _startDate != null
                                      ? Colors.white
                                      : Colors.grey[600],
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                            if (_startDate != null) ...[
                              const SizedBox(width: 2),
                              GestureDetector(
                                onTap: _clearDateFilter,
                                child: const Icon(
                                  Icons.close,
                                  size: 14,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Sort dropdown - constrained
                  Container(
                    constraints: BoxConstraints(
                      maxWidth: constraints.maxWidth * 0.45,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _sortOrder,
                        isDense: true,
                        isExpanded: true,
                        icon: const Icon(Icons.keyboard_arrow_down, size: 18),
                        items: const [
                          DropdownMenuItem(
                            value: 'newest',
                            child: Text(
                              'Newest',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'oldest',
                            child: Text(
                              'Oldest',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'highest',
                            child: Text(
                              'Highest ₹',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'lowest',
                            child: Text(
                              'Lowest ₹',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _sortOrder = value;
                              _applySorting();
                            });
                          }
                        },
                        style: const TextStyle(
                          fontFamily: 'Literata',
                          fontSize: 12,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _buildBillsList() {
    if (_filteredBills.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No bills found',
              style: TextStyle(
                fontFamily: 'Literata',
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            if (_searchController.text.isNotEmpty || _startDate != null)
              TextButton(
                onPressed: () {
                  _searchController.clear();
                  _clearDateFilter();
                },
                child: const Text(
                  'Clear filters',
                  style: TextStyle(
                    fontFamily: 'Literata',
                    color: Color(0xFF1B4D3E),
                  ),
                ),
              ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _filteredBills.length,
      itemBuilder: (context, index) {
        final bill = _filteredBills[index];
        return _buildBillCard(bill);
      },
    );
  }

  Widget _buildBillCard(Bill bill) {
    final dateFormat = DateFormat('dd MMM, hh:mm a');

    return GestureDetector(
      onTap: () => _showBillDetails(bill),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row - bill number and date
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1B4D3E).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      bill.billNumber,
                      style: const TextStyle(
                        fontFamily: 'Literata',
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1B4D3E),
                      ),
                    ),
                  ),
                  const Spacer(),
                  Flexible(
                    child: Text(
                      dateFormat.format(bill.billDate),
                      style: TextStyle(
                        fontFamily: 'Literata',
                        fontSize: 11,
                        color: Colors.grey[600],
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // Customer info - responsive
              if (bill.hasCustomerInfo) ...[
                Row(
                  children: [
                    Icon(
                      Icons.person_outline,
                      size: 14,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        bill.customerName ?? 'Unknown',
                        style: const TextStyle(
                          fontFamily: 'Literata',
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                    if (bill.customerContact != null) ...[
                      const SizedBox(width: 8),
                      Icon(
                        Icons.phone_outlined,
                        size: 12,
                        color: Colors.grey[500],
                      ),
                      const SizedBox(width: 2),
                      Text(
                        bill.customerContact!,
                        style: TextStyle(
                          fontFamily: 'Literata',
                          fontSize: 11,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 8),
              ],
              // Items count and total - responsive
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${bill.items.length} items • ${bill.totalQuantity} qty',
                      style: TextStyle(
                        fontFamily: 'Literata',
                        fontSize: 11,
                        color: Colors.grey[600],
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (bill.discountAmount > 0) ...[
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
                        '-${bill.discountPercent.toStringAsFixed(0)}%',
                        style: TextStyle(
                          fontFamily: 'Literata',
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Colors.green[700],
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                  ],
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      '₹${bill.finalAmount.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontFamily: 'Literata',
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1B4D3E),
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
}

class _DateRangePickerDialog extends StatefulWidget {
  final DateTime? initialStartDate;
  final DateTime? initialEndDate;

  const _DateRangePickerDialog({this.initialStartDate, this.initialEndDate});

  @override
  State<_DateRangePickerDialog> createState() => _DateRangePickerDialogState();
}

class _DateRangePickerDialogState extends State<_DateRangePickerDialog> {
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _startDate = widget.initialStartDate;
    _endDate = widget.initialEndDate;
  }

  Future<void> _selectStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _startDate = picked;
        if (_endDate != null && _endDate!.isBefore(picked)) {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _selectEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? DateTime.now(),
      firstDate: _startDate ?? DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _endDate = DateTime(picked.year, picked.month, picked.day, 23, 59, 59);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMM yyyy');

    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text(
        'Select Date Range',
        style: TextStyle(
          fontFamily: 'Literata',
          fontWeight: FontWeight.w700,
          color: Color(0xFF1B4D3E),
          fontSize: 18,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Quick filters
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildQuickFilter('Today', () {
                final now = DateTime.now();
                setState(() {
                  _startDate = DateTime(now.year, now.month, now.day);
                  _endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
                });
              }),
              _buildQuickFilter('This Week', () {
                final now = DateTime.now();
                final startOfWeek = now.subtract(
                  Duration(days: now.weekday - 1),
                );
                setState(() {
                  _startDate = DateTime(
                    startOfWeek.year,
                    startOfWeek.month,
                    startOfWeek.day,
                  );
                  _endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
                });
              }),
              _buildQuickFilter('This Month', () {
                final now = DateTime.now();
                setState(() {
                  _startDate = DateTime(now.year, now.month, 1);
                  _endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
                });
              }),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),
          // Date pickers
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: _selectStartDate,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Start Date',
                          style: TextStyle(
                            fontFamily: 'Literata',
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _startDate != null
                              ? dateFormat.format(_startDate!)
                              : 'Select',
                          style: const TextStyle(
                            fontFamily: 'Literata',
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Icon(Icons.arrow_forward, color: Colors.grey),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: _selectEndDate,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'End Date',
                          style: TextStyle(
                            fontFamily: 'Literata',
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _endDate != null
                              ? dateFormat.format(_endDate!)
                              : 'Select',
                          style: const TextStyle(
                            fontFamily: 'Literata',
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
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
          onPressed: _startDate != null && _endDate != null
              ? () {
                  Navigator.pop(context, {
                    'startDate': _startDate,
                    'endDate': _endDate,
                  });
                }
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1B4D3E),
          ),
          child: const Text(
            'Apply',
            style: TextStyle(fontFamily: 'Literata', color: Colors.white),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickFilter(String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF1B4D3E).withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontFamily: 'Literata',
            fontSize: 12,
            color: Color(0xFF1B4D3E),
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _BillDetailsDialog extends StatelessWidget {
  final Bill bill;

  const _BillDetailsDialog({required this.bill});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMM yyyy, hh:mm a');

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
      child: Stack(
        children: [
          // Glassy background
          Container(color: Colors.black.withOpacity(0.3)),
          // Main content
          Scaffold(
            backgroundColor: Colors.transparent,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: const Icon(Icons.arrow_back, color: Colors.white),
                ),
                onPressed: () => Navigator.pop(context),
              ),
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Bill Details',
                    style: TextStyle(
                      fontFamily: 'Literata',
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    bill.billNumber,
                    style: TextStyle(
                      fontFamily: 'Literata',
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
              centerTitle: false,
            ),
            body: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Date card
                  _buildGlassyCard(
                    _buildDetailRow(
                      'Date',
                      dateFormat.format(bill.billDate),
                      Icons.calendar_today,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Customer info section
                  if (bill.hasCustomerInfo) ...[
                    _buildGlassyCard(
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildDetailRow(
                            'Customer',
                            bill.customerName ?? 'N/A',
                            Icons.person,
                          ),
                          if (bill.customerContact != null) ...[
                            const SizedBox(height: 12),
                            Container(
                              height: 1,
                              color: Colors.white.withOpacity(0.1),
                            ),
                            const SizedBox(height: 12),
                            _buildDetailRow(
                              'Contact',
                              bill.customerContact!,
                              Icons.phone,
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  // Items section
                  _buildGlassyCard(
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Items',
                          style: TextStyle(
                            fontFamily: 'Literata',
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ...bill.items.map(
                          (item) => Column(
                            children: [
                              _buildItemRow(item),
                              if (bill.items.last != item) ...[
                                const SizedBox(height: 8),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Notes section
                  if (bill.notes != null && bill.notes!.isNotEmpty) ...[
                    _buildGlassyCard(
                      _buildDetailRow('Notes', bill.notes!, Icons.note),
                    ),
                    const SizedBox(height: 12),
                  ],
                  // Totals section
                  _buildGlassyCard(
                    Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Total Quantity:',
                              style: TextStyle(
                                fontFamily: 'Literata',
                                fontSize: 14,
                                color: Colors.white.withOpacity(0.8),
                              ),
                            ),
                            Text(
                              '${bill.totalQuantity} items',
                              style: const TextStyle(
                                fontFamily: 'Literata',
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(
                          height: 1,
                          color: Colors.white.withOpacity(0.1),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Subtotal:',
                              style: TextStyle(
                                fontFamily: 'Literata',
                                fontSize: 14,
                                color: Colors.white.withOpacity(0.8),
                              ),
                            ),
                            Text(
                              '₹${bill.totalAmount.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontFamily: 'Literata',
                                fontSize: 14,
                                color: Colors.white.withOpacity(0.9),
                              ),
                            ),
                          ],
                        ),
                        if (bill.discountAmount > 0) ...[
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Discount (${bill.discountPercent.toStringAsFixed(1)}%):',
                                style: TextStyle(
                                  fontFamily: 'Literata',
                                  fontSize: 14,
                                  color: Colors.greenAccent.withOpacity(0.9),
                                ),
                              ),
                              Text(
                                '-₹${bill.discountAmount.toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontFamily: 'Literata',
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.greenAccent,
                                ),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 12),
                        Container(
                          height: 1,
                          color: Colors.white.withOpacity(0.1),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Final Amount:',
                              style: TextStyle(
                                fontFamily: 'Literata',
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white.withOpacity(0.9),
                              ),
                            ),
                            Text(
                              '₹${bill.finalAmount.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontFamily: 'Literata',
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassyCard(Widget child) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.2), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: child,
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.white.withOpacity(0.7)),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            fontFamily: 'Literata',
            fontSize: 14,
            color: Colors.white.withOpacity(0.7),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontFamily: 'Literata',
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildItemRow(item) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
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
                    color: Colors.white,
                  ),
                ),
                Text(
                  '₹${item.sellingPrice.toStringAsFixed(2)} × ${item.quantity}',
                  style: TextStyle(
                    fontFamily: 'Literata',
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
          Text(
            '₹${item.subtotal.toStringAsFixed(2)}',
            style: const TextStyle(
              fontFamily: 'Literata',
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

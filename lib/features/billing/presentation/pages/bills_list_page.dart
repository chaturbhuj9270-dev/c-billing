import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:c_billing/core/services/billing_service.dart';
import 'package:c_billing/features/billing/data/repositories/firebase_bill_repository.dart';
import 'package:c_billing/features/billing/domain/entities/bill.dart';
import 'package:c_billing/features/inventory_management/data/repositories/firebase_product_repository.dart';
import 'package:c_billing/features/inventory_management/data/repositories/firebase_stock_repository.dart';
import 'package:c_billing/features/billing/data/datasources/bill_cache_datasource.dart';
import 'package:c_billing/features/billing/presentation/pages/return_bill_page.dart';
import 'package:c_billing/core/printing/printing.dart';
import 'package:c_billing/common_widgets/printer_selection_widget.dart';
import 'package:c_billing/features/shop/data/repositories/shop_repository.dart';
import 'package:c_billing/features/customer/data/repositories/customer_repository.dart';

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
  final _cacheDataSource = BillCacheDataSource();

  // Printing
  final _printerService = PosPrinterService();
  final _pdfService = PdfBillService();
  late ShopRepository _shopRepository;
  late FirebaseCustomerRepository _customerRepository;
  String? _printingBillId; // Track which bill is being printed

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
    _shopRepository = ShopRepository(firestore: _firestore);
    _customerRepository = FirebaseCustomerRepository(firestore: _firestore);

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

    _setupInitialData();
  }

  Future<void> _setupInitialData() async {
    // 1. Load from cache immediately
    final cached = await _cacheDataSource.getCachedBills();
    if (cached != null && mounted) {
      setState(() {
        _bills = cached;
        _filteredBills = cached;
        _totalSales = _bills.fold(0.0, (sum, bill) => sum + bill.finalAmount);
        _totalBillsCount = _bills.length;
        _applySorting();
      });
      print('[DEBUG] Loaded ${_bills.length} bills from cache');
    }

    // 2. Load from Firestore in background
    _loadBills();
  }

  @override
  void dispose() {
    _animController.dispose();
    _searchController.dispose();
    _printerService.dispose();
    super.dispose();
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

  Future<void> _printBill(Bill bill) async {
    // Show bill preview dialog first
    final shouldPrint = await _showPrintPreviewDialog(bill);
    if (shouldPrint != true || !mounted) return;

    // Show printer selection
    final selectedPrinter = await PrinterSelectionWidget.show(context);
    if (selectedPrinter == null || !mounted) return;

    setState(() => _printingBillId = bill.id);

    try {
      // Connect to printer
      final connectResult = await _printerService.connectPrinter(
        selectedPrinter,
      );
      if (!connectResult.success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to connect: ${connectResult.message}'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Get shop details
      final shop = await _shopRepository.getShopDetails();

      // Create print data from bill
      final printData = await _createPrintBillData(bill);

      // Print the bill
      final printResult = await _printerService.printBill(
        billData: printData,
        shopDetails: shop,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              printResult.success
                  ? 'Bill printed successfully!'
                  : 'Print failed: ${printResult.message}',
            ),
            backgroundColor: printResult.success ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error printing: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _printingBillId = null);
      }
      await _printerService.disconnectPrinter();
    }
  }

  Future<bool?> _showPrintPreviewDialog(Bill bill) {
    final dateFormat = DateFormat('dd MMM yyyy, hh:mm a');

    return showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400, maxHeight: 600),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Color(0xFF1B4D3E),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.receipt_long,
                      color: Colors.white,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Print Preview',
                            style: TextStyle(
                              fontFamily: 'Literata',
                              fontSize: 18,
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
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context, false),
                    ),
                  ],
                ),
              ),
              // Bill Content
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Date
                      _buildPreviewRow(
                        'Date',
                        dateFormat.format(bill.billDate),
                      ),
                      const Divider(height: 24),
                      // Customer Info
                      if (bill.hasCustomerInfo) ...[
                        _buildPreviewRow(
                          'Customer',
                          bill.customerName ?? 'N/A',
                        ),
                        if (bill.customerContact != null)
                          _buildPreviewRow('Phone', bill.customerContact!),
                        const Divider(height: 24),
                      ],
                      // Items Header
                      const Text(
                        'Items',
                        style: TextStyle(
                          fontFamily: 'Literata',
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1B4D3E),
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Items List
                      ...bill.items.map(
                        (item) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 2,
                                child: Text(
                                  item.productName,
                                  style: const TextStyle(
                                    fontFamily: 'Literata',
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: 50,
                                child: Text(
                                  '${item.quantity}x',
                                  style: TextStyle(
                                    fontFamily: 'Literata',
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              SizedBox(
                                width: 70,
                                child: Text(
                                  '₹${item.subtotal.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontFamily: 'Literata',
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  textAlign: TextAlign.right,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const Divider(height: 24),
                      // Totals
                      _buildPreviewRow(
                        'Subtotal',
                        '₹${bill.totalAmount.toStringAsFixed(2)}',
                      ),
                      if (bill.discountAmount > 0)
                        _buildPreviewRow(
                          'Discount (${bill.discountPercent.toStringAsFixed(0)}%)',
                          '-₹${bill.discountAmount.toStringAsFixed(2)}',
                          valueColor: Colors.green,
                        ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Total',
                            style: TextStyle(
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
                              fontSize: 18,
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
                            label: const Text(
                              'Share',
                              style: TextStyle(fontFamily: 'Literata'),
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
                            label: const Text(
                              'Save PDF',
                              style: TextStyle(fontFamily: 'Literata'),
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
                    // Second row - Cancel and Print
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context, false),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              side: BorderSide(color: Colors.grey[400]!),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(
                              'Cancel',
                              style: TextStyle(
                                fontFamily: 'Literata',
                                color: Colors.grey[600],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => Navigator.pop(context, true),
                            icon: const Icon(Icons.print, size: 18),
                            label: const Text(
                              'Print',
                              style: TextStyle(fontFamily: 'Literata'),
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
                      ],
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

  Widget _buildPreviewRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
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
      ),
    );
  }

  Future<void> _shareBillAsPdf(Bill bill) async {
    try {
      // Show loading indicator
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

      // Close loading indicator
      if (mounted) Navigator.pop(context);

      await _pdfService.shareBillAsPdf(billData: printData, shopDetails: shop);
    } catch (e) {
      // Close loading indicator if still showing
      if (mounted) Navigator.pop(context);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sharing bill: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _saveBillAsPdf(Bill bill) async {
    try {
      // Show loading indicator
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

      // Close loading indicator
      if (mounted) Navigator.pop(context);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('PDF saved: ${file.path.split('/').last}'),
            backgroundColor: Colors.green,
            action: SnackBarAction(
              label: 'Open',
              textColor: Colors.white,
              onPressed: () {
                _pdfService.previewAndPrintPdf(
                  billData: printData,
                  shopDetails: shop,
                );
              },
            ),
          ),
        );
      }
    } catch (e) {
      // Close loading indicator if still showing
      if (mounted) Navigator.pop(context);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _loadBills() async {
    try {
      if (_bills.isEmpty) {
        setState(() => _isLoading = true);
      }

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

      // Save to cache
      _cacheDataSource.saveBills(bills);
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
      builder: (context) => _BillDetailsDialog(
        bill: bill,
        onBillReturned: () {
          // Refresh the bills list after a return
          _loadBills();
        },
      ),
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
                  // Print button
                  _printingBillId == bill.id
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Color(0xFF1B4D3E),
                            ),
                          ),
                        )
                      : GestureDetector(
                          onTap: () => _printBill(bill),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            child: Icon(
                              Icons.print_outlined,
                              size: 18,
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                  const SizedBox(width: 8),
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

class _BillDetailsDialog extends StatefulWidget {
  final Bill bill;
  final VoidCallback? onBillReturned;

  const _BillDetailsDialog({required this.bill, this.onBillReturned});

  @override
  State<_BillDetailsDialog> createState() => _BillDetailsDialogState();
}

class _BillDetailsDialogState extends State<_BillDetailsDialog> {
  late Bill _bill;

  @override
  void initState() {
    super.initState();
    _bill = widget.bill;
  }

  void _navigateToReturnBill() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => ReturnBillPage(initialBill: _bill),
      ),
    );

    if (result == true && mounted) {
      // Bill was returned successfully
      setState(() {
        _bill = _bill.copyWith(returnStatus: true, returnDate: DateTime.now());
      });
      widget.onBillReturned?.call();
    }
  }

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
                  Row(
                    children: [
                      Text(
                        _bill.billNumber,
                        style: TextStyle(
                          fontFamily: 'Literata',
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.7),
                        ),
                      ),
                      if (_bill.returnStatus) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.orange.withOpacity(0.5),
                            ),
                          ),
                          child: const Text(
                            'Returned',
                            style: TextStyle(
                              fontFamily: 'Literata',
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Colors.orange,
                            ),
                          ),
                        ),
                      ],
                    ],
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
                      dateFormat.format(_bill.billDate),
                      Icons.calendar_today,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Customer info section
                  if (_bill.hasCustomerInfo) ...[
                    _buildGlassyCard(
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildDetailRow(
                            'Customer',
                            _bill.customerName ?? 'N/A',
                            Icons.person,
                          ),
                          if (_bill.customerContact != null) ...[
                            const SizedBox(height: 12),
                            Container(
                              height: 1,
                              color: Colors.white.withOpacity(0.1),
                            ),
                            const SizedBox(height: 12),
                            _buildDetailRow(
                              'Contact',
                              _bill.customerContact!,
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
                        ..._bill.items.map(
                          (item) => Column(
                            children: [
                              _buildItemRow(item),
                              if (_bill.items.last != item) ...[
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
                  if (_bill.notes != null && _bill.notes!.isNotEmpty) ...[
                    _buildGlassyCard(
                      _buildDetailRow('Notes', _bill.notes!, Icons.note),
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
                              '${_bill.totalQuantity} items',
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
                              '₹${_bill.totalAmount.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontFamily: 'Literata',
                                fontSize: 14,
                                color: Colors.white.withOpacity(0.9),
                              ),
                            ),
                          ],
                        ),
                        if (_bill.discountAmount > 0) ...[
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Discount (${_bill.discountPercent.toStringAsFixed(1)}%):',
                                style: TextStyle(
                                  fontFamily: 'Literata',
                                  fontSize: 14,
                                  color: Colors.greenAccent.withOpacity(0.9),
                                ),
                              ),
                              Text(
                                '-₹${_bill.discountAmount.toStringAsFixed(2)}',
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
                              '₹${_bill.finalAmount.toStringAsFixed(2)}',
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
                  const SizedBox(height: 16),
                  // Return Bill Button
                  if (!_bill.returnStatus)
                    _buildReturnBillButton()
                  else
                    _buildReturnedInfoCard(),
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

  Widget _buildReturnBillButton() {
    return GestureDetector(
      onTap: _navigateToReturnBill,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.orange.withOpacity(0.3),
              Colors.orange.withOpacity(0.2),
            ],
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.orange.withOpacity(0.4), width: 1.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.assignment_return, color: Colors.orange[300], size: 22),
            const SizedBox(width: 10),
            Text(
              'Return This Bill',
              style: TextStyle(
                fontFamily: 'Literata',
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.orange[300],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReturnedInfoCard() {
    final dateFormat = DateFormat('dd MMM yyyy, hh:mm a');
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.15),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.orange.withOpacity(0.3), width: 1.5),
      ),
      child: Row(
        children: [
          Icon(Icons.assignment_return, color: Colors.orange[300], size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bill Returned',
                  style: TextStyle(
                    fontFamily: 'Literata',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.orange[300],
                  ),
                ),
                if (_bill.returnDate != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    dateFormat.format(_bill.returnDate!),
                    style: TextStyle(
                      fontFamily: 'Literata',
                      fontSize: 12,
                      color: Colors.orange[200],
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
}

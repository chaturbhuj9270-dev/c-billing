import 'dart:async';
import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:c_billing/core/services/billing_service.dart';
import 'package:c_billing/features/billing/data/repositories/firebase_bill_repository.dart';
import 'package:c_billing/features/billing/domain/entities/bill.dart';
import 'package:c_billing/features/billing/domain/entities/bill_item.dart';
import 'package:c_billing/features/inventory_management/data/repositories/firebase_product_repository.dart';
import 'package:c_billing/features/inventory_management/data/repositories/firebase_stock_repository.dart';
import 'package:c_billing/features/billing/data/datasources/bill_cache_datasource.dart';
import 'package:c_billing/features/billing/presentation/pages/return_bill_page.dart';
import 'package:c_billing/core/printing/printing.dart';
import 'package:c_billing/common_widgets/printer_selection_widget.dart';
import 'package:c_billing/features/shop/data/repositories/shop_repository.dart';
import 'package:c_billing/features/shop/domain/entities/shop.dart';
import 'package:c_billing/features/customer/data/repositories/customer_repository.dart';
import 'package:c_billing/core/services/language_service.dart';
import 'package:c_billing/core/localization/app_localizations.dart';
import 'package:c_billing/features/billing/offline/controllers/bill_offline_controller.dart';
import 'package:c_billing/features/billing/offline/entities/bill_entity.dart';
import 'package:c_billing/features/billing/data/services/bill_sync_service.dart';

class BillsListPage extends StatefulWidget {
  const BillsListPage({super.key});

  @override
  State<BillsListPage> createState() => _BillsListPageState();
}

class _BillsListPageState extends State<BillsListPage>
    with SingleTickerProviderStateMixin {
  // ignore: unused_field
  late BillingService _billingService;
  late FirebaseFirestore _firestore;
  final _auth = FirebaseAuth.instance;
  late AnimationController _animController;
  late Animation<Offset> _offsetAnimation;
  late Animation<double> _opacityAnimation;
  // ignore: unused_field
  final _cacheDataSource = BillCacheDataSource();

  // Localization
  late AppLocalizations _localizations;

  // Printing
  final _printerService = PosPrinterService();
  final _pdfService = PdfBillService();
  late ShopRepository _shopRepository;
  // ignore: unused_field
  late FirebaseCustomerRepository _customerRepository;
  String? _printingBillId; // Track which bill is being printed
  bool _isProcessingPdf = false; // Track PDF generation/share/save operations

  List<Bill> _bills = [];
  List<Bill> _filteredBills = [];
  bool _isLoading = false;
  final _searchController = TextEditingController();

  // Filter options
  DateTime? _startDate;
  DateTime? _endDate;
  String _sortOrder = 'newest';
  bool _showReturnedOnly = false;
  bool _showTodayOnly = true;

  // Stats
  double _totalSales = 0.0;
  int _totalBillsCount = 0;
  int _returnedBillsCount = 0;

  // Offline-first stream subscription
  StreamSubscription<List<BillEntity>>? _billsSubscription;
  // Firestore stream for cross-device real-time sync
  StreamSubscription<QuerySnapshot>? _firestoreStreamSubscription;

  @override
  void initState() {
    super.initState();
    _firestore = FirebaseFirestore.instance;
    _shopRepository = ShopRepository(firestore: _firestore);
    _customerRepository = FirebaseCustomerRepository(firestore: _firestore);

    // Initialize localization
    _localizations = AppLocalizations(LanguageService.instance.currentLanguage);
    LanguageService.instance.addListener(_onLanguageChanged);

    _billingService = BillingService(
      billRepository: FirebaseBillRepository(firestore: _firestore),
      productRepository: FirebaseProductRepository(firestore: _firestore),
      stockRepository: FirebaseStockRepository(firestore: _firestore),
    );

    // Subscribe to bills stream for reactive updates
    _billsSubscription = BillOfflineController.instance.watchAllBills().listen((entities) {
      if (mounted) {
        final bills = entities.map((e) => Bill.fromBillEntity(e)).toList();
        setState(() {
          _bills = bills;
          _totalSales = bills.fold(0.0, (sum, bill) => sum + bill.finalAmount);
          _totalBillsCount = bills.length;
          _returnedBillsCount = bills.where((b) => b.returnStatus).length;
          _filterBills(_searchController.text);
        });
      }
    });

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
    _setupFirestoreStream();
  }

  /// Setup real-time Firestore stream for cross-device bill synchronization
  void _setupFirestoreStream() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    _firestoreStreamSubscription = _firestore
        .collection('users')
        .doc(currentUser.uid)
        .collection('bills')
        .orderBy('billDate', descending: true)
        .snapshots()
        .listen(
      (snapshot) async {
        if (!mounted) return;

        debugPrint('[Bills] Firestore stream: ${snapshot.docs.length} docs (${snapshot.docChanges.length} changes)');

        final serverBills = snapshot.docs.map((doc) {
          return <String, dynamic>{
            'id': doc.id,
            ...doc.data(),
          };
        }).toList();

        // Import to Isar — the Isar stream listener auto-updates the UI
        await BillOfflineController.instance.importFromServer(serverBills);
      },
      onError: (e) {
        debugPrint('[ERROR] Firestore bills stream error: $e');
      },
    );
  }

  Future<void> _setupInitialData() async {
    // Load from Isar (offline-first) - data comes through stream subscription
    // Initial data is already loaded via watchAllBills() in initState
    
    // Trigger background sync to fetch latest from server
    BillSyncService.instance.syncNow();
  }

  @override
  void dispose() {
    _billsSubscription?.cancel();
    _firestoreStreamSubscription?.cancel();
    _animController.dispose();
    _searchController.dispose();
    _printerService.dispose();
    LanguageService.instance.removeListener(_onLanguageChanged);
    super.dispose();
  }

  void _onLanguageChanged() {
    _localizations = AppLocalizations(LanguageService.instance.currentLanguage);
    setState(() {}); // Rebuild UI with new language
  }

  /// Create PrintBillData from bill — no network calls, uses bill data directly
  PrintBillData _createPrintBillData(Bill bill) {
    final double? totalDueAmount = bill.pendingAmount > 0 ? bill.pendingAmount : null;
    return PrintBillData.fromBill(bill, totalDueAmount: totalDueAmount);
  }

  Future<void> _printBill(Bill bill) async {
    // Show bill preview dialog first
    final action = await _showPrintPreviewDialog(bill);
    if (!mounted || action == null || action == 'cancel') return;

    // Handle share/save actions from preview dialog
    if (action == 'share') {
      _shareBillAsPdf(bill);
      return;
    }
    if (action == 'save') {
      _saveBillAsPdf(bill);
      return;
    }

    // action == 'print' → proceed with POS printer selection
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
              content: Text(
                '${_localizations.failedToConnect}: ${connectResult.message}',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Get shop details
      final shop = await _shopRepository.getShopDetails();

      // Create print data from bill
      final printData = _createPrintBillData(bill);

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
                  ? _localizations.billPrintedSuccessfully
                  : '${_localizations.printFailed}: ${printResult.message}',
            ),
            backgroundColor: printResult.success ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_localizations.errorPrinting}: $e'),
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

  Future<String?> _showPrintPreviewDialog(Bill bill) {
    final dateFormat = DateFormat('dd MMM yyyy, hh:mm a');

    return showDialog<String>(
      context: context,
      builder: (dialogContext) => Dialog(
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
                          Text(
                            _localizations.printPreview,
                            style: const TextStyle(
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
                      onPressed: () => Navigator.pop(dialogContext),
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
                        _localizations.date,
                        dateFormat.format(bill.billDate),
                      ),
                      const Divider(height: 24),
                      // Customer Info
                      if (bill.hasCustomerInfo) ...[
                        _buildPreviewRow(
                          _localizations.customerName,
                          bill.customerName ?? 'N/A',
                        ),
                        if (bill.customerContact != null)
                          _buildPreviewRow(_localizations.mobile, bill.customerContact!),
                        const Divider(height: 24),
                      ],
                      // Items Header
                      Text(
                        _localizations.items,
                        style: const TextStyle(
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
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
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
                              // Show returned quantity if any
                              if (item.returnedQuantity > 0)
                                Padding(
                                  padding: const EdgeInsets.only(
                                    top: 4,
                                    left: 4,
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.assignment_return,
                                        size: 14,
                                        color: Colors.orange[700],
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${_localizations.returnedLabel}: ${item.returnedQuantity} ${_localizations.quantity}',
                                        style: TextStyle(
                                          fontFamily: 'Literata',
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.orange[700],
                                        ),
                                      ),
                                      const Spacer(),
                                      Text(
                                        '-₹${(item.sellingPrice * item.returnedQuantity).toStringAsFixed(2)}',
                                        style: TextStyle(
                                          fontFamily: 'Literata',
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.orange[700],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      // Returns summary before totals
                      if (bill.hasAnyReturns) ...[
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.orange.withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${_localizations.totalReturns} (${bill.totalReturnedQuantity} ${_localizations.quantity})',
                                style: TextStyle(
                                  fontFamily: 'Literata',
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.orange[800],
                                ),
                              ),
                              Text(
                                '-₹${bill.totalReturnedAmount.toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontFamily: 'Literata',
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.orange[800],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const Divider(height: 24),
                      // Totals
                      _buildPreviewRow(
                        _localizations.subtotal,
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
                              Navigator.pop(dialogContext, 'share');
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
                              Navigator.pop(dialogContext, 'save');
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
                    // Second row - Cancel and Print
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(dialogContext, 'cancel'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              side: BorderSide(color: Colors.grey[400]!),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(
                              _localizations.cancel,
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
                            onPressed: () => Navigator.pop(dialogContext, 'print'),
                            icon: const Icon(Icons.print, size: 18),
                            label: Text(
                              _localizations.print,
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
    setState(() => _isProcessingPdf = true);
    try {
      final shop = await _shopRepository.getShopDetails().timeout(
        const Duration(seconds: 5),
        onTimeout: () => Shop.empty,
      );
      final printData = _createPrintBillData(bill);
      if (!mounted) return;

      // Use PdfBillService.shareBillAsPdf which uses Share.shareXFiles (native share sheet)
      await _pdfService.shareBillAsPdf(billData: printData, shopDetails: shop);
    } catch (e) {
      debugPrint('[BillsListPage] ERROR in _shareBillAsPdf: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_localizations.errorSharingBillGeneric}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessingPdf = false);
    }
  }

  Future<void> _saveBillAsPdf(Bill bill) async {
    setState(() => _isProcessingPdf = true);
    try {
      final shop = await _shopRepository.getShopDetails().timeout(
        const Duration(seconds: 5),
        onTimeout: () => Shop.empty,
      );
      final printData = _createPrintBillData(bill);
      if (!mounted) return;

      // Save to Documents/Bills/ directory
      final file = await _pdfService.savePdfToFile(billData: printData, shopDetails: shop);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_localizations.pdfSaved}: ${file.path.split('/').last}'),
            backgroundColor: const Color(0xFF1B4D3E),
            duration: const Duration(seconds: 3),
            action: SnackBarAction(
              label: _localizations.share,
              textColor: Colors.white,
              onPressed: () async {
                await Share.shareXFiles(
                  [XFile(file.path)],
                  text: 'Bill ${bill.billNumber}',
                );
              },
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('[BillsListPage] ERROR in _saveBillAsPdf: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_localizations.errorSavingPdfGeneric}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessingPdf = false);
    }
  }

  Future<void> _loadBills() async {
    try {
      if (_bills.isEmpty) {
        setState(() => _isLoading = true);
      }

      // Use offline-first controller
      List<BillEntity> entities;
      if (_startDate != null && _endDate != null) {
        entities = await BillOfflineController.instance.getBillsByDateRange(
          _startDate!,
          _endDate!,
        );
      } else {
        entities = await BillOfflineController.instance.getAllBills();
      }

      // Convert to domain Bills
      final bills = entities.map((e) => Bill.fromBillEntity(e)).toList();

      // Calculate stats (use finalAmount to account for discounts)
      _totalSales = bills.fold(0.0, (sum, bill) => sum + bill.finalAmount);
      _totalBillsCount = bills.length;

      setState(() {
        _bills = bills;
        _filteredBills = bills;
        _applySorting();
        _isLoading = false;
      });

      // Trigger background sync
      BillSyncService.instance.syncNow();
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('${_localizations.errorLoadingBills}: $e')));
      }
    }
  }

  void _filterBills(String query) {
    setState(() {
      // Start with all bills
      var bills = _bills.toList();
      
      // Apply Today filter
      if (_showTodayOnly) {
        final now = DateTime.now();
        final todayStart = DateTime(now.year, now.month, now.day);
        final todayEnd = todayStart.add(const Duration(days: 1));
        bills = bills.where((bill) => 
            bill.billDate.isAfter(todayStart.subtract(const Duration(seconds: 1))) && 
            bill.billDate.isBefore(todayEnd)).toList();
      }
      
      // Apply return filter
      if (_showReturnedOnly) {
        bills = bills.where((bill) => bill.returnStatus).toList();
      }
      
      // Apply search query
      if (query.isEmpty) {
        _filteredBills = bills;
      } else {
        _filteredBills = bills.where((bill) {
          final customerName = bill.customerName?.toLowerCase() ?? '';
          final customerContact = bill.customerContact?.toLowerCase() ?? '';
          final billId = bill.id.toLowerCase();
          final billNumber = bill.billNumber.toLowerCase();
          final searchQuery = query.toLowerCase();

          return customerName.contains(searchQuery) ||
              customerContact.contains(searchQuery) ||
              billId.contains(searchQuery) ||
              billNumber.contains(searchQuery);
        }).toList();
      }
      _applySorting();
    });
  }

  void _toggleTodayFilter() {
    setState(() {
      _showTodayOnly = !_showTodayOnly;
    });
    _filterBills(_searchController.text);
  }

  void _toggleReturnFilter() {
    setState(() {
      _showReturnedOnly = !_showReturnedOnly;
    });
    _filterBills(_searchController.text);
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

  void _showBillDetails(Bill bill) async {
    final result = await showDialog<_BillDialogResult>(
      context: context,
      builder: (dialogContext) => _BillDetailsDialog(bill: bill),
    );

    if (!mounted || result == null) return;

    switch (result.action) {
      case _BillDialogAction.share:
        if (result.printData != null) {
          _shareBillAsPdfWithData(result.printData!);
        }
        break;
      case _BillDialogAction.savePdf:
        if (result.printData != null) {
          _saveBillAsPdfWithData(result.printData!);
        }
        break;
      case _BillDialogAction.print:
        if (result.printData != null) {
          _printBillWithData(result.printData!);
        }
        break;
      case _BillDialogAction.billReturned:
        _loadBills();
        break;
    }
  }

  /// Share bill as PDF using pre-built PrintBillData (called from bill details dialog)
  Future<void> _shareBillAsPdfWithData(PrintBillData printData) async {
    setState(() => _isProcessingPdf = true);
    try {
      final shop = await _shopRepository.getShopDetails().timeout(
        const Duration(seconds: 5),
        onTimeout: () => Shop.empty,
      );
      if (!mounted) return;

      // Use PdfBillService.shareBillAsPdf which uses Share.shareXFiles (native share sheet)
      await _pdfService.shareBillAsPdf(billData: printData, shopDetails: shop);
    } catch (e) {
      debugPrint('[BillsListPage] ERROR in _shareBillAsPdfWithData: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${_localizations.errorSharingBillGeneric}: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessingPdf = false);
    }
  }

  /// Save bill as PDF locally using pre-built PrintBillData (called from bill details dialog)
  Future<void> _saveBillAsPdfWithData(PrintBillData printData) async {
    setState(() => _isProcessingPdf = true);
    try {
      final shop = await _shopRepository.getShopDetails().timeout(
        const Duration(seconds: 5),
        onTimeout: () => Shop.empty,
      );
      if (!mounted) return;

      // Save to Documents directory
      final file = await _pdfService.savePdfToFile(billData: printData, shopDetails: shop);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_localizations.pdfSaved}: ${file.path.split('/').last}'),
            backgroundColor: const Color(0xFF1B4D3E),
            duration: const Duration(seconds: 3),
            action: SnackBarAction(
              label: _localizations.share,
              textColor: Colors.white,
              onPressed: () async {
                await Share.shareXFiles(
                  [XFile(file.path)],
                  text: 'Bill ${printData.billNumber}',
                );
              },
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('[BillsListPage] ERROR in _saveBillAsPdfWithData: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${_localizations.errorSavingPdfGeneric}: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessingPdf = false);
    }
  }

  /// Print bill using pre-built PrintBillData (called from bill details dialog)
  Future<void> _printBillWithData(PrintBillData printData) async {
    setState(() => _isProcessingPdf = true);
    try {
      final shop = await _shopRepository.getShopDetails().timeout(
        const Duration(seconds: 5),
        onTimeout: () => Shop.empty,
      );
      if (!mounted) return;
      await _pdfService.previewAndPrintPdf(billData: printData, shopDetails: shop);
    } catch (e) {
      debugPrint('[BillsListPage] ERROR in _printBillWithData: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${_localizations.errorPrintingBill}: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessingPdf = false);
    }
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
                        Text(
                          _localizations.billsHistory,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'Literata',
                            height: 1.2,
                          ),
                        ),
                        Text(
                          _localizations.viewAllTransactions,
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
      body: Stack(
        children: [
          _isLoading
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
          // Loading overlay for PDF operations
          if (_isProcessingPdf)
            Container(
              color: Colors.black.withValues(alpha: 0.3),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(
                        width: 40,
                        height: 40,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1B4D3E)),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '${_localizations.preparingPdf}...',
                        style: const TextStyle(
                          fontFamily: 'Literata',
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1B4D3E),
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

  Widget _buildStatsSection() {
    // Calculate today's stats
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = todayStart.add(const Duration(days: 1));
    final todayBills = _bills.where((b) => 
        b.billDate.isAfter(todayStart.subtract(const Duration(seconds: 1))) && 
        b.billDate.isBefore(todayEnd)).toList();
    final todaySales = todayBills.fold(0.0, (sum, bill) => sum + bill.finalAmount);
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Main Stats Row
          Row(
            children: [
              // Total Sales - Featured Card
              Expanded(
                flex: 2,
                child: _buildFeaturedStatCard(
                  title: _localizations.totalSales,
                  value: '₹${_formatAmount(_totalSales)}',
                  icon: Icons.account_balance_wallet_rounded,
                  gradient: const [Color(0xFF1B4D3E), Color(0xFF2E7D5B)],
                ),
              ),
              const SizedBox(width: 12),
              // Secondary Stats Column
              Expanded(
                flex: 1,
                child: Column(
                  children: [
                    _buildMiniStatCard(
                      title: _localizations.totalBills,
                      value: '$_totalBillsCount',
                      icon: Icons.receipt_long_rounded,
                      color: const Color(0xFF2196F3),
                    ),
                    const SizedBox(height: 8),
                    _buildMiniStatCard(
                      title: _localizations.returns,
                      value: '$_returnedBillsCount',
                      icon: Icons.assignment_return_rounded,
                      color: Colors.orange,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Today's Sales Banner
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFF9C27B0).withOpacity(0.15),
                      const Color(0xFF673AB7).withOpacity(0.08),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFF9C27B0).withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF9C27B0), Color(0xFF673AB7)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.today_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${_localizations.today}\'s ${_localizations.totalSales}',
                            style: TextStyle(
                              fontFamily: 'Literata',
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[700],
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${todayBills.length} bills',
                            style: TextStyle(
                              fontFamily: 'Literata',
                              fontSize: 10,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '₹${_formatAmount(todaySales)}',
                      style: const TextStyle(
                        fontFamily: 'Literata',
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF9C27B0),
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

  Widget _buildFeaturedStatCard({
    required String title,
    required String value,
    required IconData icon,
    required List<Color> gradient,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradient,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: gradient[0].withOpacity(0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: Colors.white, size: 22),
              ),
              Icon(
                Icons.trending_up_rounded,
                color: Colors.white.withOpacity(0.6),
                size: 28,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'Literata',
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontFamily: 'Literata',
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.white.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.15), width: 1),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontFamily: 'Literata',
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'Literata',
                    fontSize: 9,
                    color: Colors.grey[600],
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
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
    Color color, {
    double? width,
  }) {
    return Container(
      width: width,
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
    final hasDateFilter = _startDate != null;
    final hasActiveFilters = hasDateFilter || _showReturnedOnly || _showTodayOnly;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // ── Enhanced Search bar with glassmorphism ──
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withOpacity(0.9),
                      Colors.white.withOpacity(0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.5),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF1B4D3E).withOpacity(0.08),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: _filterBills,
                  decoration: InputDecoration(
                    hintText: _localizations.searchBills,
                    hintStyle: TextStyle(
                      fontFamily: 'Literata',
                      fontSize: 14,
                      color: Colors.grey[400],
                    ),
                    prefixIcon: Container(
                      padding: const EdgeInsets.all(12),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF1B4D3E), Color(0xFF2E7D5B)],
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.search_rounded,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? GestureDetector(
                            onTap: () {
                              _searchController.clear();
                              _filterBills('');
                            },
                            child: Container(
                              margin: const EdgeInsets.all(12),
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.grey[300],
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close_rounded,
                                color: Colors.white,
                                size: 14,
                              ),
                            ),
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.transparent,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  style: const TextStyle(fontFamily: 'Literata', fontSize: 14),
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          
          // Filter section header
          if (hasActiveFilters)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Icon(Icons.filter_list_rounded, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 6),
                  Text(
                    'Active Filters',
                    style: TextStyle(
                      fontFamily: 'Literata',
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[600],
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _showTodayOnly = false;
                        _showReturnedOnly = false;
                        _startDate = null;
                        _endDate = null;
                      });
                      _filterBills(_searchController.text);
                    },
                    child: Text(
                      _localizations.clearFilters,
                      style: const TextStyle(
                        fontFamily: 'Literata',
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1B4D3E),
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // ── Filter chips row ──
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              children: [
                // Today filter chip
                _buildFilterChip(
                  icon: Icons.today_rounded,
                  label: _localizations.today,
                  isActive: _showTodayOnly,
                  onTap: _toggleTodayFilter,
                  onClear: _showTodayOnly ? _toggleTodayFilter : null,
                ),
                const SizedBox(width: 8),
                // Date range chip
                _buildFilterChip(
                  icon: Icons.date_range_rounded,
                  label: hasDateFilter
                      ? '${DateFormat('dd MMM').format(_startDate!)} – ${DateFormat('dd MMM').format(_endDate!)}'
                      : _localizations.date,
                  isActive: hasDateFilter,
                  onTap: _showDateFilterDialog,
                  onClear: hasDateFilter ? _clearDateFilter : null,
                ),
                const SizedBox(width: 8),
                // Sales Return filter chip
                _buildFilterChip(
                  icon: Icons.assignment_return_rounded,
                  label: _localizations.returns,
                  isActive: _showReturnedOnly,
                  onTap: _toggleReturnFilter,
                  onClear: _showReturnedOnly ? _toggleReturnFilter : null,
                ),
                const SizedBox(width: 8),
                // Sort chips
                _buildSortChip('newest', _localizations.newest, Icons.arrow_downward_rounded),
                const SizedBox(width: 8),
                _buildSortChip('oldest', _localizations.oldest, Icons.arrow_upward_rounded),
                const SizedBox(width: 8),
                _buildSortChip('highest', _localizations.highest, Icons.trending_up_rounded),
                const SizedBox(width: 8),
                _buildSortChip('lowest', _localizations.lowest, Icons.trending_down_rounded),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
    VoidCallback? onClear,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          gradient: isActive 
              ? const LinearGradient(
                  colors: [Color(0xFF1B4D3E), Color(0xFF2E7D5B)],
                )
              : null,
          color: isActive ? null : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isActive
                ? Colors.transparent
                : Colors.grey[200]!,
            width: 1.5,
          ),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: const Color(0xFF1B4D3E).withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 15,
              color: isActive ? Colors.white : Colors.grey[600],
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Literata',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isActive ? Colors.white : Colors.grey[700],
              ),
            ),
            if (onClear != null) ...[
              const SizedBox(width: 6),
              GestureDetector(
                onTap: onClear,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.25),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close_rounded,
                    size: 10,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSortChip(String value, String label, IconData icon) {
    final isActive = _sortOrder == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _sortOrder = value;
          _applySorting();
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: isActive
              ? const Color(0xFF1B4D3E).withOpacity(0.12)
              : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive
                ? const Color(0xFF1B4D3E)
                : Colors.grey[300]!,
            width: isActive ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isActive
                  ? const Color(0xFF1B4D3E)
                  : Colors.grey[500],
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Literata',
                fontSize: 12,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                color: isActive
                    ? const Color(0xFF1B4D3E)
                    : Colors.grey[600],
              ),
            ),
          ],
        ),
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
              _localizations.noBillsFound,
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
                child: Text(
                  _localizations.clearFilters,
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
    final isReturned = bill.returnStatus;
    final isToday = _isToday(bill.billDate);

    return GestureDetector(
      onTap: () => _showBillDetails(bill),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isReturned 
                ? [Colors.orange.withOpacity(0.03), Colors.white]
                : [Colors.white, Colors.grey.shade50],
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isReturned 
                ? Colors.orange.withOpacity(0.4)
                : Colors.grey.withOpacity(0.12),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: isReturned 
                  ? Colors.orange.withOpacity(0.12)
                  : Colors.black.withOpacity(0.06),
              blurRadius: 16,
              offset: const Offset(0, 4),
              spreadRadius: isReturned ? 2 : 0,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(17),
          child: Stack(
            children: [
              // Left accent bar
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                child: Container(
                  width: 4,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: isReturned 
                          ? [Colors.orange, Colors.orange.shade300]
                          : [const Color(0xFF1B4D3E), const Color(0xFF2E7D5B)],
                    ),
                  ),
                ),
              ),
              // Content
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header row - bill number, badges, and date
                    Row(
                      children: [
                        // Bill number badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            gradient: isReturned 
                                ? LinearGradient(
                                    colors: [Colors.orange.withOpacity(0.2), Colors.orange.withOpacity(0.1)],
                                  )
                                : LinearGradient(
                                    colors: [const Color(0xFF1B4D3E).withOpacity(0.15), const Color(0xFF1B4D3E).withOpacity(0.08)],
                                  ),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isReturned 
                                  ? Colors.orange.withOpacity(0.3)
                                  : const Color(0xFF1B4D3E).withOpacity(0.2),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.receipt_outlined,
                                size: 12,
                                color: isReturned ? Colors.orange[700] : const Color(0xFF1B4D3E),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                bill.billNumber,
                                style: TextStyle(
                                  fontFamily: 'Literata',
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: isReturned ? Colors.orange[800] : const Color(0xFF1B4D3E),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isReturned) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Colors.orange, Color(0xFFFF7043)],
                              ),
                              borderRadius: BorderRadius.circular(6),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.orange.withOpacity(0.3),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.assignment_return_rounded,
                                  size: 11,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _localizations.returnedLabel,
                                  style: const TextStyle(
                                    fontFamily: 'Literata',
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        if (isToday && !isReturned) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2196F3).withOpacity(0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              _localizations.today,
                              style: const TextStyle(
                                fontFamily: 'Literata',
                                fontSize: 8,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF2196F3),
                              ),
                            ),
                          ),
                        ],
                        const Spacer(),
                        // Date and Print
                        Row(
                          children: [
                            Icon(
                              Icons.schedule_rounded,
                              size: 12,
                              color: Colors.grey[500],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              dateFormat.format(bill.billDate),
                              style: TextStyle(
                                fontFamily: 'Literata',
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(width: 10),
                            // Print button
                            _printingBillId == bill.id
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
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
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: Colors.grey[100],
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(
                                        Icons.print_rounded,
                                        size: 16,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Customer info
                    if (bill.hasCustomerInfo) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.grey.withOpacity(0.1)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1B4D3E).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Icon(
                                Icons.person_rounded,
                                size: 14,
                                color: const Color(0xFF1B4D3E),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    bill.customerName ?? _localizations.unknown,
                                    style: const TextStyle(
                                      fontFamily: 'Literata',
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF1A1A1A),
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (bill.customerContact != null)
                                    Text(
                                      bill.customerContact!,
                                      style: TextStyle(
                                        fontFamily: 'Literata',
                                        fontSize: 11,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            if (bill.customerContact != null)
                              Icon(
                                Icons.phone_rounded,
                                size: 14,
                                color: Colors.grey[400],
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                    // Footer row - Items count, discount and total
                    Row(
                      children: [
                        // Items info
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.shopping_bag_outlined, size: 12, color: Colors.grey[600]),
                              const SizedBox(width: 4),
                              Text(
                                '${bill.items.length} items',
                                style: TextStyle(
                                  fontFamily: 'Literata',
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.inventory_2_outlined, size: 12, color: Colors.grey[600]),
                              const SizedBox(width: 4),
                              Text(
                                '${bill.totalQuantity} qty',
                                style: TextStyle(
                                  fontFamily: 'Literata',
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        // Discount badge
                        if (bill.discountAmount > 0) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Colors.green.withOpacity(0.15), Colors.green.withOpacity(0.08)],
                              ),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: Colors.green.withOpacity(0.2)),
                            ),
                            child: Text(
                              '-${bill.discountPercent.toStringAsFixed(0)}%',
                              style: TextStyle(
                                fontFamily: 'Literata',
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: Colors.green[700],
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                        ],
                        // Total amount
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: isReturned 
                                  ? [Colors.orange.withOpacity(0.15), Colors.orange.withOpacity(0.08)]
                                  : [const Color(0xFF1B4D3E).withOpacity(0.12), const Color(0xFF1B4D3E).withOpacity(0.06)],
                            ),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isReturned 
                                  ? Colors.orange.withOpacity(0.2)
                                  : const Color(0xFF1B4D3E).withOpacity(0.15),
                            ),
                          ),
                          child: Text(
                            '₹${bill.finalAmount.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontFamily: 'Literata',
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: isReturned ? Colors.orange[800] : const Color(0xFF1B4D3E),
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

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
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
      title: Text(
        AppLocalizations(LanguageService.instance.currentLanguage).selectDateRange,
        style: const TextStyle(
          fontFamily: 'Literata',
          fontWeight: FontWeight.w700,
          color: Color(0xFF1B4D3E),
          fontSize: 18,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
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
                          AppLocalizations(LanguageService.instance.currentLanguage).startDate,
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
                          AppLocalizations(LanguageService.instance.currentLanguage).endDate,
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
          child: Text(
            AppLocalizations(LanguageService.instance.currentLanguage).cancel,
            style: const TextStyle(fontFamily: 'Literata', color: Colors.grey),
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
          child: Text(
            AppLocalizations(LanguageService.instance.currentLanguage).apply,
            style: const TextStyle(fontFamily: 'Literata', color: Colors.white),
          ),
        ),
      ],
    );
  }
}

/// Actions that can be triggered from the bill details dialog
enum _BillDialogAction { share, savePdf, print, billReturned }

/// Result returned from the bill details dialog
class _BillDialogResult {
  final _BillDialogAction action;
  final PrintBillData? printData;

  const _BillDialogResult({required this.action, this.printData});
}

class _BillDetailsDialog extends StatefulWidget {
  final Bill bill;

  const _BillDetailsDialog({
    required this.bill,
  });

  @override
  State<_BillDetailsDialog> createState() => _BillDetailsDialogState();
}

class _BillDetailsDialogState extends State<_BillDetailsDialog> {
  late Bill _bill;
  bool _includeReturnsInPrint = true;
  late AppLocalizations _localizations;

  @override
  void initState() {
    super.initState();
    _bill = widget.bill;
    _localizations = AppLocalizations(LanguageService.instance.currentLanguage);
  }

  void _navigateToReturnBill() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => ReturnBillPage(initialBill: _bill),
      ),
    );

    if (result == true && mounted) {
      setState(() {
        _bill = _bill.copyWith(returnStatus: true, returnDate: DateTime.now());
      });
      Navigator.pop(context, const _BillDialogResult(action: _BillDialogAction.billReturned));
    }
  }

  PrintBillData _createPrintData() {
    final double? totalDueAmount = _bill.pendingAmount > 0 ? _bill.pendingAmount : null;

    if (_includeReturnsInPrint) {
      // Include return data as-is from stored bill items
      return PrintBillData.fromBill(_bill, totalDueAmount: totalDueAmount);
    } else {
      // Zero out return quantities for printing without returns
      final cleanBill = _bill.copyWith(
        items: _bill.items.map((item) => BillItem(
          id: item.id,
          billId: item.billId,
          productId: item.productId,
          productName: item.productName,
          purchasePrice: item.purchasePrice,
          sellingPrice: item.sellingPrice,
          quantity: item.quantity,
          subtotal: item.subtotal,
          returnedQuantity: 0,
        )).toList(),
      );
      return PrintBillData.fromBill(cleanBill, totalDueAmount: totalDueAmount);
    }
  }

  /// Calculated totals for display
  double get _returnDeduction => _bill.totalReturnedAmount;
  double get _finalPayable => (_bill.finalAmount - _returnDeduction).clamp(0.0, double.infinity);
  bool get _isFullyReturned => _bill.isFullyReturned;

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMM yyyy, hh:mm a');

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
      child: Stack(
        children: [
          Container(color: Colors.black.withOpacity(0.3)),
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
                    border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
                  ),
                  child: const Icon(Icons.arrow_back, color: Colors.white),
                ),
                onPressed: () => Navigator.pop(context),
              ),
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _localizations.billDetails,
                    style: const TextStyle(
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
                      if (_bill.hasAnyReturns) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: _isFullyReturned
                                ? Colors.red.withOpacity(0.3)
                                : Colors.orange.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: _isFullyReturned
                                  ? Colors.red.withOpacity(0.5)
                                  : Colors.orange.withOpacity(0.5),
                            ),
                          ),
                          child: Text(
                            _isFullyReturned ? _localizations.fullyReturned : _localizations.partialReturn,
                            style: TextStyle(
                              fontFamily: 'Literata',
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: _isFullyReturned ? Colors.red[300] : Colors.orange,
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
                  // ══════════ Bill Info ══════════
                  _buildGlassyCard(
                    Column(
                      children: [
                        _buildDetailRow(_localizations.billNo, _bill.billNumber, Icons.receipt_long),
                        const SizedBox(height: 12),
                        Container(height: 1, color: Colors.white.withOpacity(0.1)),
                        const SizedBox(height: 12),
                        _buildDetailRow(_localizations.date, dateFormat.format(_bill.billDate), Icons.calendar_today),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // ══════════ Customer Info ══════════
                  if (_bill.hasCustomerInfo) ...[
                    _buildGlassyCard(
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildDetailRow(_localizations.customerName, _bill.customerName ?? 'N/A', Icons.person),
                          if (_bill.customerContact != null) ...[
                            const SizedBox(height: 12),
                            Container(height: 1, color: Colors.white.withOpacity(0.1)),
                            const SizedBox(height: 12),
                            _buildDetailRow(_localizations.mobile, _bill.customerContact!, Icons.phone),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // ══════════ Items Section ══════════
                  _buildGlassyCard(
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _localizations.soldItems,
                              style: const TextStyle(
                                fontFamily: 'Literata',
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              '${_bill.items.length} items',
                              style: TextStyle(
                                fontFamily: 'Literata',
                                fontSize: 12,
                                color: Colors.white.withOpacity(0.6),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Items table header
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: Text(_localizations.product, style: TextStyle(
                                  fontFamily: 'Literata', fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white.withOpacity(0.7),
                                )),
                              ),
                              SizedBox(
                                width: 40,
                                child: Text(_localizations.quantity, textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontFamily: 'Literata', fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white.withOpacity(0.7),
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: 55,
                                child: Text(_localizations.rate, textAlign: TextAlign.right,
                                  style: TextStyle(
                                    fontFamily: 'Literata', fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white.withOpacity(0.7),
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: 65,
                                child: Text(_localizations.amount, textAlign: TextAlign.right,
                                  style: TextStyle(
                                    fontFamily: 'Literata', fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white.withOpacity(0.7),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Items list
                        ..._bill.items.map((item) => _buildItemRow(item)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // ══════════ Notes ══════════
                  if (_bill.notes != null && _bill.notes!.isNotEmpty) ...[
                    _buildGlassyCard(
                      _buildDetailRow(_localizations.notes, _bill.notes!, Icons.note),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // ══════════ Totals Section ══════════
                  _buildGlassyCard(
                    Column(
                      children: [
                        // Total Quantity
                        _buildTotalDisplayRow(
                          _localizations.totalQuantity,
                          '${_bill.totalQuantity} ${_localizations.items}',
                        ),
                        _buildDivider(),
                        // Subtotal (Gross Total)
                        _buildTotalDisplayRow(
                          _localizations.subtotal,
                          '₹${_bill.totalAmount.toStringAsFixed(2)}',
                        ),
                        // Discount
                        if (_bill.discountAmount > 0) ...[
                          const SizedBox(height: 8),
                          _buildTotalDisplayRow(
                            'Discount (${_bill.discountPercent.toStringAsFixed(1)}%)',
                            '-₹${_bill.discountAmount.toStringAsFixed(2)}',
                            valueColor: Colors.greenAccent,
                          ),
                        ],
                        _buildDivider(),
                        // Bill Total (before returns)
                        _buildTotalDisplayRow(
                          _localizations.billTotalLabel,
                          '₹${_bill.finalAmount.toStringAsFixed(2)}',
                          isBold: true,
                        ),
                        // Return Deduction (if any returns)
                        if (_bill.hasAnyReturns) ...[
                          _buildDivider(),
                          _buildTotalDisplayRow(
                            '${_localizations.returnDeduction} (${_bill.totalReturnedQuantity} ${_localizations.quantity})',
                            '-₹${_returnDeduction.toStringAsFixed(2)}',
                            valueColor: Colors.orange,
                          ),
                          _buildDivider(),
                          // Final Payable
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _isFullyReturned ? _localizations.finalPayable : _localizations.finalPayable,
                                style: TextStyle(
                                  fontFamily: 'Literata',
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: _isFullyReturned ? Colors.red[300] : Colors.white,
                                ),
                              ),
                              Text(
                                _isFullyReturned ? '₹0.00' : '₹${_finalPayable.toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontFamily: 'Literata',
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  color: _isFullyReturned ? Colors.red[300] : Colors.white,
                                ),
                              ),
                            ],
                          ),
                          if (_isFullyReturned) ...[
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.red.withOpacity(0.3)),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.info_outline, size: 14, color: Colors.red[300]),
                                  const SizedBox(width: 6),
                                  Text(
                                    _localizations.statusFullyReturned,
                                    style: TextStyle(
                                      fontFamily: 'Literata',
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.red[300],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                        // Show final amount when no returns
                        if (!_bill.hasAnyReturns) ...[
                          _buildDivider(),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _localizations.finalAmount,
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
                        // Payment info
                        if (_bill.paidAmount > 0 || _bill.pendingAmount > 0) ...[
                          _buildDivider(),
                          _buildTotalDisplayRow(
                            _localizations.paidAmount,
                            '₹${_bill.paidAmount.toStringAsFixed(2)}',
                            valueColor: Colors.greenAccent,
                          ),
                          if (_bill.pendingAmount > 0) ...[
                            const SizedBox(height: 8),
                            _buildTotalDisplayRow(
                              _localizations.pendingAmount,
                              '₹${_bill.pendingAmount.toStringAsFixed(2)}',
                              valueColor: Colors.orange,
                            ),
                          ],
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ══════════ Include Returns Toggle ══════════
                  if (_bill.hasAnyReturns) ...[
                    _buildGlassyCard(
                      Row(
                        children: [
                          Icon(Icons.assignment_return, size: 20, color: Colors.orange[300]),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _localizations.includeReturnedItemsInPrint,
                              style: TextStyle(
                                fontFamily: 'Literata',
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.white.withOpacity(0.9),
                              ),
                            ),
                          ),
                          Transform.scale(
                            scale: 0.85,
                            child: Switch(
                              value: _includeReturnsInPrint,
                              onChanged: (v) => setState(() => _includeReturnsInPrint = v),
                              activeColor: Colors.orange,
                              activeTrackColor: Colors.orange.withOpacity(0.3),
                              inactiveThumbColor: Colors.grey[400],
                              inactiveTrackColor: Colors.grey.withOpacity(0.3),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // ══════════ Action Buttons ══════════
                  // Share & Save PDF row
                  Row(
                    children: [
                      Expanded(
                        child: _buildActionButton(
                          icon: Icons.share,
                          label: _localizations.share,
                          color: const Color(0xFF1B4D3E),
                          onTap: () {
                            final printData = _createPrintData();
                            Navigator.pop(context, _BillDialogResult(
                              action: _BillDialogAction.share,
                              printData: printData,
                            ));
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildActionButton(
                          icon: Icons.picture_as_pdf,
                          label: _localizations.savePdf,
                          color: const Color(0xFF1B4D3E),
                          onTap: () {
                            final printData = _createPrintData();
                            Navigator.pop(context, _BillDialogResult(
                              action: _BillDialogAction.savePdf,
                              printData: printData,
                            ));
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Print button
                  _buildActionButton(
                    icon: Icons.print,
                    label: _localizations.printBill,
                    color: const Color(0xFF1B4D3E),
                    filled: true,
                    onTap: () {
                      final printData = _createPrintData();
                      Navigator.pop(context, _BillDialogResult(
                        action: _BillDialogAction.print,
                        printData: printData,
                      ));
                    },
                  ),
                  const SizedBox(height: 10),

                  // Return Bill Button
                  if (!_bill.returnStatus && _bill.hasReturnableItems)
                    _buildReturnBillButton()
                  else if (_bill.returnStatus)
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

  Widget _buildDivider() {
    return Column(
      children: [
        const SizedBox(height: 12),
        Container(height: 1, color: Colors.white.withOpacity(0.1)),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildTotalDisplayRow(String label, String value, {Color? valueColor, bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Literata',
            fontSize: 14,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.normal,
            color: valueColor ?? Colors.white.withOpacity(0.8),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontFamily: 'Literata',
            fontSize: isBold ? 16 : 14,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w600,
            color: valueColor ?? Colors.white.withOpacity(0.9),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    bool filled = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
        decoration: BoxDecoration(
          color: filled ? color.withOpacity(0.4) : Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: filled ? color.withOpacity(0.6) : Colors.white.withOpacity(0.2),
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: filled ? Colors.white : Colors.white.withOpacity(0.8), size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Literata',
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: filled ? Colors.white : Colors.white.withOpacity(0.8),
              ),
            ),
          ],
        ),
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

  Widget _buildItemRow(BillItem item) {
    final bool hasReturn = item.returnedQuantity > 0;
    final bool isFullReturn = item.isFullyReturned;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(isFullReturn ? 0.04 : 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: hasReturn
                ? Colors.orange.withOpacity(0.3)
                : Colors.white.withOpacity(0.1),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sold line
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text(
                    item.productName,
                    style: TextStyle(
                      fontFamily: 'Literata',
                      fontWeight: FontWeight.w600,
                      color: isFullReturn ? Colors.white.withOpacity(0.4) : Colors.white,
                      decoration: isFullReturn ? TextDecoration.lineThrough : null,
                      decorationColor: Colors.orange.withOpacity(0.7),
                      decorationThickness: 2,
                    ),
                  ),
                ),
                SizedBox(
                  width: 40,
                  child: Text(
                    '${item.quantity}',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Literata',
                      fontSize: 13,
                      color: isFullReturn ? Colors.white.withOpacity(0.4) : Colors.white.withOpacity(0.8),
                      decoration: isFullReturn ? TextDecoration.lineThrough : null,
                      decorationColor: Colors.orange.withOpacity(0.7),
                      decorationThickness: 2,
                    ),
                  ),
                ),
                SizedBox(
                  width: 55,
                  child: Text(
                    '₹${item.sellingPrice.toStringAsFixed(0)}',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontFamily: 'Literata',
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.6),
                    ),
                  ),
                ),
                SizedBox(
                  width: 65,
                  child: Text(
                    '₹${item.subtotal.toStringAsFixed(2)}',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontFamily: 'Literata',
                      fontWeight: FontWeight.w700,
                      color: isFullReturn ? Colors.white.withOpacity(0.4) : Colors.white,
                      decoration: isFullReturn ? TextDecoration.lineThrough : null,
                      decorationColor: Colors.orange.withOpacity(0.7),
                      decorationThickness: 2,
                    ),
                  ),
                ),
              ],
            ),
            // Return line (if any)
            if (hasReturn) ...[
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.orange.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.assignment_return, size: 13, color: Colors.orange[300]),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '${_localizations.returnLabel}: ${item.returnedQuantity} ${_localizations.quantity}',
                        style: TextStyle(
                          fontFamily: 'Literata',
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.orange[300],
                          decoration: TextDecoration.lineThrough,
                          decorationColor: Colors.orange.withOpacity(0.5),
                          decorationThickness: 1.5,
                        ),
                      ),
                    ),
                    Text(
                      '(-₹${(item.sellingPrice * item.returnedQuantity).toStringAsFixed(2)})',
                      style: TextStyle(
                        fontFamily: 'Literata',
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.orange[300],
                        decoration: TextDecoration.lineThrough,
                        decorationColor: Colors.orange.withOpacity(0.5),
                        decorationThickness: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
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
              _localizations.returnThisBill,
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
                  _localizations.billReturned,
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

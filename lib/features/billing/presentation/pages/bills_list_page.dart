import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
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
import 'package:c_billing/features/billing/data/services/bill_report_pdf_generator.dart';
import 'package:c_billing/common_widgets/file_preview_page.dart';
import 'package:c_billing/features/billing/presentation/pages/bill_report_settings_page.dart';

/// Quick date filter options for bill history
enum _BillDateFilter { none, today, thisWeek, thisMonth, thisYear, custom }

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
  bool _isGeneratingReport = false; // Track bill report generation

  List<Bill> _bills = [];
  List<Bill> _filteredBills = [];
  bool _isLoading = false;
  final _searchController = TextEditingController();

  // Filter options
  DateTime? _startDate;
  DateTime? _endDate;
  String _sortOrder = 'newest';
  bool _showReturnedOnly = false;
  _BillDateFilter _dateFilter = _BillDateFilter.today;

  // Filtered stats (based on applied filters)
  double _filteredSales = 0.0;
  double _filteredProfit = 0.0;
  int _filteredBillsCount = 0;
  int _filteredReturnedCount = 0;

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
    // Prevent multiple simultaneous print operations
    if (_printingBillId != null || _isProcessingPdf) return;
    
    // Set the printing bill ID to show loading indicator on that specific card
    setState(() {
      _printingBillId = bill.id;
      _isProcessingPdf = true;
    });
    
    try {
      debugPrint('[BillsListPage] Starting PDF preview for bill: ${bill.billNumber}');
      final printData = _createPrintBillData(bill);
      
      debugPrint('[BillsListPage] Fetching shop details...');
      final shop = await _shopRepository.getShopDetails().timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          debugPrint('[BillsListPage] Shop details timeout, using empty shop');
          return Shop.empty;
        },
      );
      debugPrint('[BillsListPage] Got shop: ${shop.shopName}');
      
      debugPrint('[BillsListPage] Generating PDF file...');
      final file = await _pdfService.savePdfToFile(
        billData: printData,
        shopDetails: shop,
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () => throw Exception('PDF generation timed out'),
      );
      debugPrint('[BillsListPage] PDF saved to: ${file.path}');
      
      if (!mounted) {
        debugPrint('[BillsListPage] Widget not mounted, returning');
        return;
      }
      
      // Hide loading before navigation
      setState(() {
        _printingBillId = null;
        _isProcessingPdf = false;
      });
      
      debugPrint('[BillsListPage] Navigating to FilePreviewPage...');
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
      debugPrint('[BillsListPage] Returned from FilePreviewPage');
    } catch (e, stack) {
      debugPrint('[BillsListPage] ERROR generating PDF preview: $e');
      debugPrint('[BillsListPage] Stack trace: $stack');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      debugPrint('[BillsListPage] Finally block - resetting state');
      if (mounted) {
        setState(() {
          _printingBillId = null;
          _isProcessingPdf = false;
        });
      }
    }
  }

  /// Show PDF preview for a bill using FilePreviewPage (alias for _printBill)
  Future<void> _showBillPdfPreview(Bill bill) async {
    await _printBill(bill);
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

  // ── Generate & show bill report ──
  Future<void> _generateBillReport() async {
    debugPrint('[BillReport] Button tapped! _isGeneratingReport=$_isGeneratingReport');
    
    if (_isGeneratingReport) {
      debugPrint('[BillReport] Already generating, returning');
      return;
    }
    
    final filtered = _filteredBills;
    debugPrint('[BillReport] Filtered bills: ${filtered.length}');
    
    if (filtered.isEmpty) {
      debugPrint('[BillReport] No data - showing snackbar');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No bill data to generate report'),
            duration: Duration(seconds: 2),
          ),
        );
      }
      return;
    }

    _isGeneratingReport = true;

    // Show loading indicator
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
              SizedBox(width: 12),
              Text('Generating bill report...'),
            ],
          ),
          duration: Duration(seconds: 30),
        ),
      );
    }

    try {
      debugPrint('[BillReport] Generating PDF for ${filtered.length} bills...');
      
      final pdfBytes = await BillReportPdfGenerator.generate(
        bills: filtered,
        filterDescription: _buildFilterDescription(),
      );
      
      debugPrint('[BillReport] PDF generated: ${pdfBytes.length} bytes');
      
      // Save to temporary file for preview
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final tempFile = File('${tempDir.path}/bill_report_$timestamp.pdf');
      await tempFile.writeAsBytes(pdfBytes);
      
      // Dismiss loading snackbar
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
      }

      if (!mounted) {
        _isGeneratingReport = false;
        return;
      }

      // Navigate to file preview page
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => FilePreviewPage(
            file: tempFile,
            fileName: 'Bill Report',
            fileType: FilePreviewType.pdf,
            subtitle: '${filtered.length} bills • ${DateFormat('dd MMM yyyy').format(DateTime.now())}',
          ),
        ),
      );
      
      _isGeneratingReport = false;
    } catch (e, stack) {
      debugPrint('[BillReport] Error: $e');
      debugPrint('[BillReport] Stack: $stack');
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to generate report: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      _isGeneratingReport = false;
    }
  }

  /// Build filter description for report header
  String _buildFilterDescription() {
    final parts = <String>[];
    
    switch (_dateFilter) {
      case _BillDateFilter.today:
        parts.add('Today');
        break;
      case _BillDateFilter.thisWeek:
        parts.add('This Week');
        break;
      case _BillDateFilter.thisMonth:
        parts.add('This Month');
        break;
      case _BillDateFilter.thisYear:
        parts.add('This Year');
        break;
      case _BillDateFilter.custom:
        if (_startDate != null && _endDate != null) {
          final fmt = DateFormat('dd MMM yyyy');
          parts.add('${fmt.format(_startDate!)} - ${fmt.format(_endDate!)}');
        }
        break;
      case _BillDateFilter.none:
        parts.add('All Time');
        break;
    }
    
    if (_showReturnedOnly) {
      parts.add('Returned Bills Only');
    }
    
    if (_searchController.text.isNotEmpty) {
      parts.add('Search: "${_searchController.text}"');
    }
    
    return parts.join(' | ');
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

      setState(() {
        _bills = bills;
        _isLoading = false;
      });
      
      // Apply filters and calculate stats
      _filterBills(_searchController.text);

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
      
      // Apply date filter based on selected filter type
      final now = DateTime.now();
      switch (_dateFilter) {
        case _BillDateFilter.today:
          final todayStart = DateTime(now.year, now.month, now.day);
          final todayEnd = todayStart.add(const Duration(days: 1));
          bills = bills.where((bill) => 
              bill.billDate.isAfter(todayStart.subtract(const Duration(seconds: 1))) && 
              bill.billDate.isBefore(todayEnd)).toList();
          break;
        case _BillDateFilter.thisWeek:
          final weekStart = now.subtract(Duration(days: now.weekday - 1));
          final weekStartDate = DateTime(weekStart.year, weekStart.month, weekStart.day);
          final weekEnd = weekStartDate.add(const Duration(days: 7));
          bills = bills.where((bill) => 
              bill.billDate.isAfter(weekStartDate.subtract(const Duration(seconds: 1))) && 
              bill.billDate.isBefore(weekEnd)).toList();
          break;
        case _BillDateFilter.thisMonth:
          final monthStart = DateTime(now.year, now.month, 1);
          final monthEnd = DateTime(now.year, now.month + 1, 1);
          bills = bills.where((bill) => 
              bill.billDate.isAfter(monthStart.subtract(const Duration(seconds: 1))) && 
              bill.billDate.isBefore(monthEnd)).toList();
          break;
        case _BillDateFilter.thisYear:
          final yearStart = DateTime(now.year, 1, 1);
          final yearEnd = DateTime(now.year + 1, 1, 1);
          bills = bills.where((bill) => 
              bill.billDate.isAfter(yearStart.subtract(const Duration(seconds: 1))) && 
              bill.billDate.isBefore(yearEnd)).toList();
          break;
        case _BillDateFilter.custom:
          // Custom filter uses _startDate and _endDate - handled separately
          break;
        case _BillDateFilter.none:
          // No date filter - show all
          break;
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
      
      // Calculate filtered stats
      _calculateFilteredStats();
    });
  }

  void _calculateFilteredStats() {
    _filteredSales = _filteredBills.fold(0.0, (sum, bill) => sum + bill.finalAmount);
    _filteredProfit = _filteredBills.where((b) => !b.returnStatus).fold(0.0, (sum, bill) =>
        sum + bill.items.fold(0.0, (s, item) => s + item.itemProfit) - bill.discountAmount);
    _filteredBillsCount = _filteredBills.length;
    _filteredReturnedCount = _filteredBills.where((b) => b.returnStatus).length;
  }

  void _setDateFilter(_BillDateFilter filter) {
    setState(() {
      // Toggle off if already selected
      if (_dateFilter == filter) {
        _dateFilter = _BillDateFilter.none;
      } else {
        _dateFilter = filter;
      }
    });
    _filterBills(_searchController.text);
  }

  void _toggleReturnFilter() {
    setState(() {
      _showReturnedOnly = !_showReturnedOnly;
      // Disable date filter when viewing returns to show all returned bills
      if (_showReturnedOnly) {
        _dateFilter = _BillDateFilter.none;
      }
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

    if (result.action == _BillDialogAction.billReturned) {
      _loadBills();
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
                  // Report button
                  GestureDetector(
                    onTap: _generateBillReport,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.description_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Refresh button
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
                  const SizedBox(width: 8),
                  // Settings menu
                  PopupMenuButton<String>(
                    icon: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.settings_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    onSelected: (value) async {
                      if (value == 'report_settings') {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const BillReportSettingsPage(),
                          ),
                        );
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem<String>(
                        value: 'report_settings',
                        child: Row(
                          children: [
                            Icon(Icons.tune_rounded, 
                                color: Colors.grey[700], size: 20),
                            const SizedBox(width: 12),
                            const Text(
                              'Report Settings',
                              style: TextStyle(
                                fontFamily: 'Literata',
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
    // Use filtered stats to show calculations based on applied filters
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Filter indicator badge
          if (_dateFilter != _BillDateFilter.none || _showReturnedOnly || _searchController.text.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF2196F3).withOpacity(0.15),
                    const Color(0xFF1976D2).withOpacity(0.08),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF2196F3).withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.filter_alt_rounded,
                    size: 14,
                    color: Color(0xFF2196F3),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _getFilterDescription(),
                    style: const TextStyle(
                      fontFamily: 'Literata',
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2196F3),
                    ),
                  ),
                ],
              ),
            ),
          // Main Stats Row - Sales and Profit (based on filtered bills)
          Row(
            children: [
              // Total Sales - Featured Card
              Expanded(
                child: _buildFeaturedStatCard(
                  title: _localizations.totalSales,
                  value: '₹${_formatAmount(_filteredSales)}',
                  icon: Icons.account_balance_wallet_rounded,
                  gradient: const [Color(0xFF1B4D3E), Color(0xFF2E7D5B)],
                ),
              ),
              const SizedBox(width: 10),
              // Net Profit - Featured Card
              Expanded(
                child: _buildFeaturedStatCard(
                  title: _localizations.netProfit,
                  value: '₹${_formatAmount(_filteredProfit)}',
                  icon: Icons.trending_up_rounded,
                  gradient: const [Color(0xFF4CAF50), Color(0xFF81C784)],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Secondary Stats Row - Bills and Returns (based on filtered bills)
          Row(
            children: [
              Expanded(
                child: _buildMiniStatCard(
                  title: _localizations.totalBills,
                  value: '$_filteredBillsCount',
                  icon: Icons.receipt_long_rounded,
                  color: const Color(0xFF2196F3),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildMiniStatCard(
                  title: _localizations.returns,
                  value: '$_filteredReturnedCount',
                  icon: Icons.assignment_return_rounded,
                  color: Colors.orange,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getFilterDescription() {
    List<String> filters = [];
    
    if (_dateFilter != _BillDateFilter.none) {
      switch (_dateFilter) {
        case _BillDateFilter.today:
          filters.add('Today');
          break;
        case _BillDateFilter.thisWeek:
          filters.add('This Week');
          break;
        case _BillDateFilter.thisMonth:
          filters.add('This Month');
          break;
        case _BillDateFilter.thisYear:
          filters.add('This Year');
          break;
        case _BillDateFilter.custom:
          filters.add('Custom Range');
          break;
        case _BillDateFilter.none:
          break;
      }
    }
    
    if (_showReturnedOnly) {
      filters.add('Returns Only');
    }
    
    if (_searchController.text.isNotEmpty) {
      filters.add('Search: \"${_searchController.text}\"');
    }
    
    return filters.isEmpty ? 'Filtered' : filters.join(' • ');
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
    final hasActiveFilters = hasDateFilter || _showReturnedOnly || _dateFilter != _BillDateFilter.none;
    
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
                        _dateFilter = _BillDateFilter.none;
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
                  isActive: _dateFilter == _BillDateFilter.today,
                  onTap: () => _setDateFilter(_BillDateFilter.today),
                  onClear: _dateFilter == _BillDateFilter.today ? () => _setDateFilter(_BillDateFilter.today) : null,
                ),
                const SizedBox(width: 8),
                // This Week filter chip
                _buildFilterChip(
                  icon: Icons.view_week_rounded,
                  label: _localizations.thisWeek,
                  isActive: _dateFilter == _BillDateFilter.thisWeek,
                  onTap: () => _setDateFilter(_BillDateFilter.thisWeek),
                  onClear: _dateFilter == _BillDateFilter.thisWeek ? () => _setDateFilter(_BillDateFilter.thisWeek) : null,
                ),
                const SizedBox(width: 8),
                // This Month filter chip
                _buildFilterChip(
                  icon: Icons.calendar_month_rounded,
                  label: _localizations.thisMonth,
                  isActive: _dateFilter == _BillDateFilter.thisMonth,
                  onTap: () => _setDateFilter(_BillDateFilter.thisMonth),
                  onClear: _dateFilter == _BillDateFilter.thisMonth ? () => _setDateFilter(_BillDateFilter.thisMonth) : null,
                ),
                const SizedBox(width: 8),
                // This Year filter chip
                _buildFilterChip(
                  icon: Icons.calendar_today_rounded,
                  label: _localizations.thisYear,
                  isActive: _dateFilter == _BillDateFilter.thisYear,
                  onTap: () => _setDateFilter(_BillDateFilter.thisYear),
                  onClear: _dateFilter == _BillDateFilter.thisYear ? () => _setDateFilter(_BillDateFilter.thisYear) : null,
                ),
                const SizedBox(width: 8),
                // Date range chip
                _buildFilterChip(
                  icon: Icons.date_range_rounded,
                  label: hasDateFilter
                      ? '${DateFormat('dd MMM').format(_startDate!)} – ${DateFormat('dd MMM').format(_endDate!)}'
                      : _localizations.custom,
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
    final isFullyReturned = bill.returnStatus;
    final hasPartialReturn = bill.hasAnyReturns && !bill.returnStatus;
    final hasAnyReturn = bill.hasAnyReturns;
    final isToday = _isToday(bill.billDate);

    return GestureDetector(
      onTap: () => _showBillDetails(bill),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isFullyReturned 
                ? [Colors.red.withOpacity(0.03), Colors.white]
                : hasPartialReturn
                    ? [Colors.orange.withOpacity(0.03), Colors.white]
                    : [Colors.white, Colors.grey.shade50],
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isFullyReturned 
                ? Colors.red.withOpacity(0.4)
                : hasPartialReturn
                    ? Colors.orange.withOpacity(0.4)
                    : Colors.grey.withOpacity(0.12),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: isFullyReturned 
                  ? Colors.red.withOpacity(0.12)
                  : hasPartialReturn
                      ? Colors.orange.withOpacity(0.12)
                      : Colors.black.withOpacity(0.06),
              blurRadius: 16,
              offset: const Offset(0, 4),
              spreadRadius: hasAnyReturn ? 2 : 0,
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
                      colors: isFullyReturned 
                          ? [Colors.red, Colors.red.shade300]
                          : hasPartialReturn
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
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              gradient: isFullyReturned 
                                  ? LinearGradient(
                                      colors: [Colors.red.withOpacity(0.2), Colors.red.withOpacity(0.1)],
                                    )
                                  : hasPartialReturn
                                      ? LinearGradient(
                                          colors: [Colors.orange.withOpacity(0.2), Colors.orange.withOpacity(0.1)],
                                        )
                                      : LinearGradient(
                                          colors: [const Color(0xFF1B4D3E).withOpacity(0.15), const Color(0xFF1B4D3E).withOpacity(0.08)],
                                        ),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isFullyReturned 
                                    ? Colors.red.withOpacity(0.3)
                                    : hasPartialReturn
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
                                  color: isFullyReturned 
                                      ? Colors.red[700] 
                                      : hasPartialReturn 
                                          ? Colors.orange[700] 
                                          : const Color(0xFF1B4D3E),
                                ),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    bill.billNumber,
                                    style: TextStyle(
                                      fontFamily: 'Literata',
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: isFullyReturned 
                                          ? Colors.red[800] 
                                          : hasPartialReturn 
                                              ? Colors.orange[800] 
                                              : const Color(0xFF1B4D3E),
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (hasAnyReturn) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: isFullyReturned
                                    ? [Colors.red, Colors.red.shade400]
                                    : [Colors.orange, const Color(0xFFFF7043)],
                              ),
                              borderRadius: BorderRadius.circular(6),
                              boxShadow: [
                                BoxShadow(
                                  color: isFullyReturned 
                                      ? Colors.red.withOpacity(0.3) 
                                      : Colors.orange.withOpacity(0.3),
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
                                  size: 10,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  isFullyReturned 
                                      ? _localizations.returnedLabel 
                                      : _localizations.partialReturn,
                                  style: const TextStyle(
                                    fontFamily: 'Literata',
                                    fontSize: 8,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        if (isToday && !hasAnyReturn) ...[
                          const SizedBox(width: 6),
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
                        const SizedBox(width: 8),
                        // Date and Print
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.schedule_rounded,
                              size: 11,
                              color: Colors.grey[500],
                            ),
                            const SizedBox(width: 3),
                            Text(
                              dateFormat.format(bill.billDate),
                              style: TextStyle(
                                fontFamily: 'Literata',
                                fontSize: 9,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(width: 8),
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
                              colors: isFullyReturned 
                                  ? [Colors.red.withOpacity(0.15), Colors.red.withOpacity(0.08)]
                                  : hasPartialReturn
                                      ? [Colors.orange.withOpacity(0.15), Colors.orange.withOpacity(0.08)]
                                      : [const Color(0xFF1B4D3E).withOpacity(0.12), const Color(0xFF1B4D3E).withOpacity(0.06)],
                            ),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isFullyReturned 
                                  ? Colors.red.withOpacity(0.2)
                                  : hasPartialReturn
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
                              color: isFullyReturned 
                                  ? Colors.red[800] 
                                  : hasPartialReturn 
                                      ? Colors.orange[800] 
                                      : const Color(0xFF1B4D3E),
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
enum _BillDialogAction { billReturned }

/// Result returned from the bill details dialog
class _BillDialogResult {
  final _BillDialogAction action;

  const _BillDialogResult({required this.action});
}

class _BillDetailsDialog extends StatefulWidget {
  final Bill bill;

  const _BillDetailsDialog({
    required this.bill,
  });

  @override
  State<_BillDetailsDialog> createState() => _BillDetailsDialogState();
}

class _BillDetailsDialogState extends State<_BillDetailsDialog> 
    with SingleTickerProviderStateMixin {
  late Bill _bill;
  bool _includeReturnsInPrint = true;
  bool _isGeneratingPdf = false;
  late AppLocalizations _localizations;
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  final _pdfService = PdfBillService();
  final _shopRepository = ShopRepository();

  @override
  void initState() {
    super.initState();
    _bill = widget.bill;
    _localizations = AppLocalizations(LanguageService.instance.currentLanguage);
    
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _navigateToReturnBill() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => ReturnBillPage(initialBill: _bill),
      ),
    );

    if (result == true && mounted) {
      // Don't update local state - let the list page refresh from data source
      // which will correctly reflect partial vs full return status
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

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F6),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ══════════ Premium Header ══════════
          SliverAppBar(
            expandedHeight: 120,
            pinned: true,
            stretch: true,
            backgroundColor: const Color(0xFF1B4D3E),
            leading: Padding(
              padding: const EdgeInsets.all(8),
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.arrow_back_ios_new_rounded, 
                    color: Colors.white, size: 20),
                ),
              ),
            ),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.receipt_long_rounded, 
                    color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _localizations.billDetails,
                        style: const TextStyle(
                          fontFamily: 'Literata',
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        _bill.billNumber,
                        style: TextStyle(
                          fontFamily: 'Literata',
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF1B4D3E), Color(0xFF0D2B24)],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 60, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (_bill.hasAnyReturns)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: _isFullyReturned
                                  ? Colors.red.withValues(alpha: 0.2)
                                  : Colors.orange.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: _isFullyReturned
                                    ? Colors.red.withValues(alpha: 0.4)
                                    : Colors.orange.withValues(alpha: 0.4),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.assignment_return_rounded,
                                  size: 14,
                                  color: _isFullyReturned ? Colors.red[200] : Colors.orange[200],
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _isFullyReturned ? _localizations.fullyReturned : _localizations.partialReturn,
                                  style: TextStyle(
                                    fontFamily: 'Literata',
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: _isFullyReturned ? Colors.red[200] : Colors.orange[200],
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          
          // ══════════ Content ══════════
          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ══════════ Bill & Customer Info Row ══════════
                      Row(
                        children: [
                          Expanded(
                            child: _buildInfoCard(
                              icon: Icons.calendar_today_rounded,
                              iconColor: const Color(0xFF1B4D3E),
                              title: _localizations.date,
                              value: dateFormat.format(_bill.billDate),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildInfoCard(
                              icon: Icons.person_rounded,
                              iconColor: const Color(0xFF2196F3),
                              title: _localizations.customerName,
                              value: _bill.customerName ?? 'Walk-in',
                            ),
                          ),
                        ],
                      ),
                      if (_bill.customerContact != null) ...[
                        const SizedBox(height: 12),
                        _buildInfoCard(
                          icon: Icons.phone_rounded,
                          iconColor: const Color(0xFF4CAF50),
                          title: _localizations.mobile,
                          value: _bill.customerContact!,
                          fullWidth: true,
                        ),
                      ],
                      const SizedBox(height: 20),

                      // ══════════ Items Section ══════════
                      _buildSectionHeader(_localizations.soldItems, '${_bill.items.length} ${_localizations.items}'),
                      const SizedBox(height: 12),
                      _buildItemsCard(),
                      const SizedBox(height: 20),

                      // ══════════ Notes Section ══════════
                      if (_bill.notes != null && _bill.notes!.isNotEmpty) ...[
                        _buildSectionHeader(_localizations.notes, null),
                        const SizedBox(height: 12),
                        _buildNotesCard(),
                        const SizedBox(height: 20),
                      ],

                      // ══════════ Payment Summary ══════════
                      _buildSectionHeader(_localizations.billTotal, null),
                      const SizedBox(height: 12),
                      _buildPaymentSummaryCard(),
                      const SizedBox(height: 20),

                      // ══════════ Include Returns Toggle ══════════
                      if (_bill.hasAnyReturns) ...[
                        _buildReturnToggleCard(),
                        const SizedBox(height: 20),
                      ],

                      // ══════════ Action Buttons ══════════
                      _buildActionButtonsSection(),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, String? subtitle) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontFamily: 'Literata',
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1B4D3E),
          ),
        ),
        if (subtitle != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF1B4D3E).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              subtitle,
              style: TextStyle(
                fontFamily: 'Literata',
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1B4D3E).withValues(alpha: 0.8),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
    bool fullWidth = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'Literata',
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[500],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontFamily: 'Literata',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2D3436),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemsCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Table Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF1B4D3E).withValues(alpha: 0.05),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 4,
                  child: Text(
                    _localizations.product,
                    style: TextStyle(
                      fontFamily: 'Literata',
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
                SizedBox(
                  width: 40,
                  child: Text(
                    _localizations.quantity,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Literata',
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
                SizedBox(
                  width: 60,
                  child: Text(
                    _localizations.rate,
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontFamily: 'Literata',
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
                SizedBox(
                  width: 70,
                  child: Text(
                    _localizations.amount,
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontFamily: 'Literata',
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Items List
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _bill.items.length,
            separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey[100]),
            itemBuilder: (context, index) => _buildItemRow(_bill.items[index]),
          ),
        ],
      ),
    );
  }

  Widget _buildNotesCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.amber.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.note_rounded, color: Colors.amber[700], size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _bill.notes!,
              style: TextStyle(
                fontFamily: 'Literata',
                fontSize: 13,
                color: Colors.grey[700],
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentSummaryCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Quantity
                _buildSummaryRow(
                  _localizations.totalQuantity,
                  '${_bill.totalQuantity} ${_localizations.items}',
                ),
                const SizedBox(height: 10),
                // Subtotal
                _buildSummaryRow(
                  _localizations.subtotal,
                  '₹${_bill.totalAmount.toStringAsFixed(2)}',
                ),
                // Discount
                if (_bill.discountAmount > 0) ...[
                  const SizedBox(height: 10),
                  _buildSummaryRow(
                    'Discount (${_bill.discountPercent.toStringAsFixed(1)}%)',
                    '-₹${_bill.discountAmount.toStringAsFixed(2)}',
                    valueColor: const Color(0xFF4CAF50),
                  ),
                ],
                // Tax info
                if (_bill.isGstApplied && _bill.totalTaxAmount > 0) ...[
                  const SizedBox(height: 10),
                  _buildSummaryRow(
                    'Tax',
                    '₹${_bill.totalTaxAmount.toStringAsFixed(2)}',
                    valueColor: Colors.blue,
                  ),
                ],
                const SizedBox(height: 10),
                Container(height: 1, color: Colors.grey[200]),
                const SizedBox(height: 10),
                // Bill Total
                _buildSummaryRow(
                  _localizations.billTotalLabel,
                  '₹${_bill.finalAmount.toStringAsFixed(2)}',
                  isBold: true,
                  valueSize: 16,
                ),
                // Returns
                if (_bill.hasAnyReturns) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.orange.withValues(alpha: 0.2)),
                    ),
                    child: Column(
                      children: [
                        _buildSummaryRow(
                          '${_localizations.returnDeduction} (${_bill.totalReturnedQuantity} ${_localizations.quantity})',
                          '-₹${_returnDeduction.toStringAsFixed(2)}',
                          valueColor: Colors.orange,
                        ),
                        const SizedBox(height: 8),
                        Container(height: 1, color: Colors.orange.withValues(alpha: 0.2)),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _localizations.finalPayable,
                              style: TextStyle(
                                fontFamily: 'Literata',
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: _isFullyReturned ? Colors.red : const Color(0xFF2D3436),
                              ),
                            ),
                            Text(
                              _isFullyReturned ? '₹0.00' : '₹${_finalPayable.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontFamily: 'Literata',
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: _isFullyReturned ? Colors.red : const Color(0xFF1B4D3E),
                              ),
                            ),
                          ],
                        ),
                        if (_isFullyReturned) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.red.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.info_outline, size: 14, color: Colors.red[700]),
                                const SizedBox(width: 6),
                                Text(
                                  _localizations.statusFullyReturned,
                                  style: TextStyle(
                                    fontFamily: 'Literata',
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.red[700],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
                // Payment Status
                if (_bill.paidAmount > 0 || _bill.pendingAmount > 0) ...[
                  const SizedBox(height: 12),
                  Container(height: 1, color: Colors.grey[200]),
                  const SizedBox(height: 12),
                  _buildSummaryRow(
                    _localizations.paidAmount,
                    '₹${_bill.paidAmount.toStringAsFixed(2)}',
                    valueColor: const Color(0xFF4CAF50),
                  ),
                  if (_bill.pendingAmount > 0) ...[
                    const SizedBox(height: 10),
                    _buildSummaryRow(
                      _localizations.pendingAmount,
                      '₹${_bill.pendingAmount.toStringAsFixed(2)}',
                      valueColor: Colors.orange,
                    ),
                  ],
                ],
              ],
            ),
          ),
          // Final Amount Banner (when no returns)
          if (!_bill.hasAnyReturns)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF1B4D3E), Color(0xFF2E7D5B)],
                ),
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _localizations.finalAmount,
                    style: const TextStyle(
                      fontFamily: 'Literata',
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
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
            ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {
    Color? valueColor,
    bool isBold = false,
    double valueSize = 14,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Literata',
            fontSize: 13,
            fontWeight: isBold ? FontWeight.w600 : FontWeight.w500,
            color: Colors.grey[600],
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontFamily: 'Literata',
            fontSize: valueSize,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w600,
            color: valueColor ?? const Color(0xFF2D3436),
          ),
        ),
      ],
    );
  }

  Widget _buildReturnToggleCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.assignment_return_rounded, 
              color: Colors.orange[700], size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _localizations.includeReturnedItemsInPrint,
              style: TextStyle(
                fontFamily: 'Literata',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
          ),
          Transform.scale(
            scale: 0.85,
            child: Switch(
              value: _includeReturnsInPrint,
              onChanged: (v) => setState(() => _includeReturnsInPrint = v),
              activeColor: Colors.orange,
              activeTrackColor: Colors.orange.withValues(alpha: 0.3),
              inactiveThumbColor: Colors.grey[400],
              inactiveTrackColor: Colors.grey.withValues(alpha: 0.3),
            ),
          ),
        ],
      ),
    );
  }

  static bool _globalPdfGenerationInProgress = false;
  
  Future<void> _showPdfPreview() async {
    // Prevent multiple simultaneous PDF generations globally
    if (_globalPdfGenerationInProgress || _isGeneratingPdf) {
      debugPrint('[BillDetailsDialog] PDF generation already in progress, ignoring request');
      return;
    }
    
    debugPrint('[BillDetailsDialog] Starting PDF preview for bill: ${_bill.billNumber}');
    _globalPdfGenerationInProgress = true;
    setState(() => _isGeneratingPdf = true);
    
    try {
      debugPrint('[BillDetailsDialog] Creating print data...');
      final printData = _createPrintData();
      
      debugPrint('[BillDetailsDialog] Fetching shop details...');
      final shop = await _shopRepository.getShopDetails().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          debugPrint('[BillDetailsDialog] Shop details timeout, using empty shop');
          return Shop.empty;
        },
      );
      debugPrint('[BillDetailsDialog] Got shop: ${shop.shopName}');
      
      debugPrint('[BillDetailsDialog] Generating PDF file...');
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
      
      debugPrint('[BillDetailsDialog] PDF saved to: ${file.path}');
      debugPrint('[BillDetailsDialog] File size: ${fileSize} bytes');
      
      if (!mounted) {
        debugPrint('[BillDetailsDialog] Widget not mounted, returning');
        return;
      }
      
      // Reset state before navigation
      setState(() => _isGeneratingPdf = false);
      
      // Small delay to ensure state is updated
      await Future.delayed(const Duration(milliseconds: 100));
      
      debugPrint('[BillDetailsDialog] Navigating to FilePreviewPage...');
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => FilePreviewPage(
            file: file,
            fileName: '${_localizations.bills} - ${_bill.billNumber}',
            fileType: FilePreviewType.pdf,
            subtitle: DateFormat('dd MMM yyyy, hh:mm a').format(_bill.billDate),
          ),
        ),
      );
      debugPrint('[BillDetailsDialog] Returned from FilePreviewPage');
      
    } catch (e, stack) {
      debugPrint('[BillDetailsDialog] ERROR generating PDF: $e');
      debugPrint('[BillDetailsDialog] Stack trace: $stack');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to generate PDF: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 6),
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: () => _showPdfPreview(),
            ),
          ),
        );
      }
    } finally {
      debugPrint('[BillDetailsDialog] Finally block - resetting state');
      _globalPdfGenerationInProgress = false;
      if (mounted) setState(() => _isGeneratingPdf = false);
    }
  }

  Widget _buildActionButtonsSection() {
    return Column(
      children: [
        // Preview Bill Button (Primary)
        _buildPremiumButton(
          icon: _isGeneratingPdf ? Icons.hourglass_empty_rounded : Icons.preview_rounded,
          label: _isGeneratingPdf ? 'Generating...' : 'Preview Bill',
          isPrimary: true,
          onTap: _isGeneratingPdf ? () {} : _showPdfPreview,
        ),
        const SizedBox(height: 10),
        // Return Bill Button
        if (!_bill.returnStatus && _bill.hasReturnableItems)
          _buildReturnBillButton()
        else if (_bill.returnStatus)
          _buildReturnedInfoCard(),
      ],
    );
  }

  Widget _buildPremiumButton({
    required IconData icon,
    required String label,
    required bool isPrimary,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
        decoration: BoxDecoration(
          gradient: isPrimary
              ? const LinearGradient(
                  colors: [Color(0xFF1B4D3E), Color(0xFF2E7D5B)],
                )
              : null,
          color: isPrimary ? null : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: isPrimary 
              ? null 
              : Border.all(color: const Color(0xFF1B4D3E).withValues(alpha: 0.3)),
          boxShadow: isPrimary
              ? [
                  BoxShadow(
                    color: const Color(0xFF1B4D3E).withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 20,
              color: isPrimary ? Colors.white : const Color(0xFF1B4D3E),
            ),
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Literata',
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isPrimary ? Colors.white : const Color(0xFF1B4D3E),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemRow(BillItem item) {
    final bool hasReturn = item.returnedQuantity > 0;
    final bool isFullReturn = item.isFullyReturned;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: hasReturn 
          ? Colors.orange.withValues(alpha: 0.03)
          : Colors.transparent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Main item row
          Row(
            children: [
              Expanded(
                flex: 4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.productName,
                      style: TextStyle(
                        fontFamily: 'Literata',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isFullReturn 
                            ? Colors.grey[400] 
                            : const Color(0xFF2D3436),
                        decoration: isFullReturn 
                            ? TextDecoration.lineThrough 
                            : null,
                        decorationColor: Colors.orange,
                        decorationThickness: 2,
                      ),
                    ),
                    if (hasReturn)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Row(
                          children: [
                            Icon(Icons.assignment_return_rounded, 
                              size: 11, color: Colors.orange[600]),
                            const SizedBox(width: 3),
                            Text(
                              '${item.returnedQuantity} returned',
                              style: TextStyle(
                                fontFamily: 'Literata',
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                color: Colors.orange[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
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
                    fontWeight: FontWeight.w500,
                    color: isFullReturn ? Colors.grey[400] : Colors.grey[700],
                    decoration: isFullReturn 
                        ? TextDecoration.lineThrough 
                        : null,
                  ),
                ),
              ),
              SizedBox(
                width: 60,
                child: Text(
                  '₹${item.sellingPrice.toStringAsFixed(0)}',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontFamily: 'Literata',
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                ),
              ),
              SizedBox(
                width: 70,
                child: Text(
                  '₹${item.subtotal.toStringAsFixed(2)}',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontFamily: 'Literata',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isFullReturn 
                        ? Colors.grey[400] 
                        : const Color(0xFF1B4D3E),
                    decoration: isFullReturn 
                        ? TextDecoration.lineThrough 
                        : null,
                    decorationColor: Colors.orange,
                    decorationThickness: 2,
                  ),
                ),
              ),
            ],
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
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.orange.withValues(alpha: 0.5), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.orange.withValues(alpha: 0.15),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.assignment_return_rounded, 
                color: Colors.orange[700], size: 20),
            ),
            const SizedBox(width: 12),
            Text(
              _localizations.returnThisBill,
              style: TextStyle(
                fontFamily: 'Literata',
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Colors.orange[700],
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.arrow_forward_ios_rounded, 
              color: Colors.orange[400], size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildReturnedInfoCard() {
    final dateFormat = DateFormat('dd MMM yyyy, hh:mm a');
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.assignment_return_rounded, 
              color: Colors.orange[700], size: 22),
          ),
          const SizedBox(width: 14),
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
                    color: Colors.orange[700],
                  ),
                ),
                if (_bill.returnDate != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    dateFormat.format(_bill.returnDate!),
                    style: TextStyle(
                      fontFamily: 'Literata',
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ],
            ),
          ),
          Icon(Icons.check_circle_rounded, color: Colors.orange[400], size: 24),
        ],
      ),
    );
  }
}

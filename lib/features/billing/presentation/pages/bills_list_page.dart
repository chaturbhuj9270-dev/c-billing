import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
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
import 'package:c_billing/features/shop/data/repositories/shop_repository.dart';
import 'package:c_billing/features/shop/domain/entities/shop.dart';
import 'package:c_billing/features/customer/data/repositories/customer_repository.dart';
import 'package:c_billing/common_widgets/range_calendar_sheet.dart';
import 'package:c_billing/core/services/language_service.dart';
import 'package:c_billing/core/localization/app_localizations.dart';
import 'package:c_billing/features/billing/offline/controllers/bill_offline_controller.dart';
import 'package:c_billing/features/billing/offline/entities/bill_entity.dart';
import 'package:c_billing/features/billing/data/services/bill_sync_service.dart';
import 'package:c_billing/features/billing/data/services/bill_report_pdf_generator.dart';
import 'package:c_billing/common_widgets/file_preview_page.dart';
import 'package:c_billing/features/billing/presentation/pages/bill_report_settings_page.dart';
import 'package:c_billing/core/ui/glassy_toast.dart';
import 'package:c_billing/common_widgets/app_top_bar.dart';
import 'package:c_billing/core/theme/app_theme.dart';

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
    _billsSubscription = BillOfflineController.instance.watchAllBills().listen((
      entities,
    ) {
      if (mounted) {
        debugPrint(
          '[BillsListPage] Bills stream fired with ${entities.length} bills',
        );
        final bills = entities.map((e) {
          final bill = Bill.fromBillEntity(e);
          debugPrint(
            '[BillsListPage] Bill ${e.id}: syncStatus=${e.syncStatus.name}, isSynced=${bill.isSynced}',
          );
          return bill;
        }).toList();
        setState(() {
          _bills = bills;
          _filterBills(_searchController.text);
        });
      }
    });

    // Also listen to BillSyncService to force refresh when sync completes
    BillSyncService.instance.addListener(_onSyncStatusChanged);

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

            debugPrint(
              '[Bills] Firestore stream: ${snapshot.docs.length} docs (${snapshot.docChanges.length} changes)',
            );

            final serverBills = snapshot.docs.map((doc) {
              return <String, dynamic>{...doc.data(), 'id': doc.id};
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
    BillSyncService.instance.removeListener(_onSyncStatusChanged);
    super.dispose();
  }

  /// Called when sync status changes - forces UI refresh
  void _onSyncStatusChanged() {
    debugPrint(
      '[BillsListPage] Sync status changed: ${BillSyncService.instance.status}',
    );
    if (mounted &&
        BillSyncService.instance.status == BillSyncServiceStatus.success) {
      // Force reload bills to pick up sync status changes
      _loadBills();
    }
  }

  void _onLanguageChanged() {
    _localizations = AppLocalizations(LanguageService.instance.currentLanguage);
    setState(() {}); // Rebuild UI with new language
  }

  /// Create PrintBillData from bill — no network calls, uses bill data directly
  PrintBillData _createPrintBillData(Bill bill) {
    final double? totalDueAmount = bill.pendingAmount > 0
        ? bill.pendingAmount
        : null;
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
      debugPrint(
        '[BillsListPage] Starting PDF preview for bill: ${bill.billNumber}',
      );
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
      final file = await _pdfService
          .savePdfToFile(billData: printData, shopDetails: shop)
          .timeout(
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
            customerPhone: bill.customerContact,
          ),
        ),
      );
      debugPrint('[BillsListPage] Returned from FilePreviewPage');
    } catch (e, stack) {
      debugPrint('[BillsListPage] ERROR generating PDF preview: $e');
      debugPrint('[BillsListPage] Stack trace: $stack');
      if (mounted) {
        GlassyToast.show(context, '${_localizations.errorGeneratingPdf}: $e', isError: true);
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
        GlassyToast.show(context, '${_localizations.errorSharingBillGeneric}: $e', isError: true);
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
      final file = await _pdfService.savePdfToFile(
        billData: printData,
        shopDetails: shop,
      );

      if (mounted) {
        GlassyToast.show(context, '${_localizations.pdfSaved}: ${file.path.split('/').last}');
      }
    } catch (e) {
      debugPrint('[BillsListPage] ERROR in _saveBillAsPdf: $e');
      if (mounted) {
        GlassyToast.show(context, '${_localizations.errorSavingPdfGeneric}: $e', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isProcessingPdf = false);
    }
  }

  // ── Generate & show bill report ──
  Future<void> _generateBillReport() async {
    debugPrint(
      '[BillReport] Button tapped! _isGeneratingReport=$_isGeneratingReport',
    );

    if (_isGeneratingReport) {
      debugPrint('[BillReport] Already generating, returning');
      return;
    }

    final filtered = _filteredBills;
    debugPrint('[BillReport] Filtered bills: ${filtered.length}');

    if (filtered.isEmpty) {
      debugPrint('[BillReport] No data - showing snackbar');
      if (mounted) {
        GlassyToast.show(context, _localizations.noBillDataForReport);
      }
      return;
    }

    _isGeneratingReport = true;

    // Show loading indicator
    if (mounted) {
      GlassyToast.show(context, _localizations.generatingBillReport);
    }

    try {
      debugPrint('[BillReport] Generating PDF for ${filtered.length} bills...');

      final pdfBytes =
          await BillReportPdfGenerator.generate(
            bills: filtered,
            filterDescription: _buildFilterDescription(),
          ).timeout(
            const Duration(seconds: 60),
            onTimeout: () {
              throw Exception(
                'Report generation timed out. Try with fewer bills.',
              );
            },
          );

      debugPrint('[BillReport] PDF generated: ${pdfBytes.length} bytes');

      // Save to temporary file for preview
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final tempFile = File('${tempDir.path}/bill_report_$timestamp.pdf');
      await tempFile.writeAsBytes(pdfBytes);

      // Dismiss loading snackbar
      if (mounted) {
        GlassyToast.dismiss();
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
            fileName: _localizations.billReport,
            fileType: FilePreviewType.pdf,
            subtitle:
                '${filtered.length} bills • ${DateFormat('dd MMM yyyy').format(DateTime.now())}',
          ),
        ),
      );

      _isGeneratingReport = false;
    } catch (e, stack) {
      debugPrint('[BillReport] Error: $e');
      debugPrint('[BillReport] Stack: $stack');
      if (mounted) {
        GlassyToast.dismiss();
        GlassyToast.show(context, '${_localizations.failedToGenerateReport}: $e');
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
        parts.add(_localizations.today);
        break;
      case _BillDateFilter.thisWeek:
        parts.add(_localizations.thisWeek);
        break;
      case _BillDateFilter.thisMonth:
        parts.add(_localizations.thisMonth);
        break;
      case _BillDateFilter.thisYear:
        parts.add(_localizations.thisYear);
        break;
      case _BillDateFilter.custom:
        if (_startDate != null && _endDate != null) {
          final fmt = DateFormat('dd MMM yyyy');
          parts.add('${fmt.format(_startDate!)} - ${fmt.format(_endDate!)}');
        }
        break;
      case _BillDateFilter.none:
        parts.add(_localizations.allTime);
        break;
    }

    if (_showReturnedOnly) {
      parts.add(_localizations.returnedBillsOnly);
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
        GlassyToast.show(context, '${_localizations.errorLoadingBills}: $e');
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
          bills = bills
              .where(
                (bill) =>
                    bill.billDate.isAfter(
                      todayStart.subtract(const Duration(seconds: 1)),
                    ) &&
                    bill.billDate.isBefore(todayEnd),
              )
              .toList();
          break;
        case _BillDateFilter.thisWeek:
          final weekStart = now.subtract(Duration(days: now.weekday - 1));
          final weekStartDate = DateTime(
            weekStart.year,
            weekStart.month,
            weekStart.day,
          );
          final weekEnd = weekStartDate.add(const Duration(days: 7));
          bills = bills
              .where(
                (bill) =>
                    bill.billDate.isAfter(
                      weekStartDate.subtract(const Duration(seconds: 1)),
                    ) &&
                    bill.billDate.isBefore(weekEnd),
              )
              .toList();
          break;
        case _BillDateFilter.thisMonth:
          final monthStart = DateTime(now.year, now.month, 1);
          final monthEnd = DateTime(now.year, now.month + 1, 1);
          bills = bills
              .where(
                (bill) =>
                    bill.billDate.isAfter(
                      monthStart.subtract(const Duration(seconds: 1)),
                    ) &&
                    bill.billDate.isBefore(monthEnd),
              )
              .toList();
          break;
        case _BillDateFilter.thisYear:
          final yearStart = DateTime(now.year, 1, 1);
          final yearEnd = DateTime(now.year + 1, 1, 1);
          bills = bills
              .where(
                (bill) =>
                    bill.billDate.isAfter(
                      yearStart.subtract(const Duration(seconds: 1)),
                    ) &&
                    bill.billDate.isBefore(yearEnd),
              )
              .toList();
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
    _filteredSales = _filteredBills.fold(
      0.0,
      (sum, bill) => sum + bill.finalAmount,
    );
    _filteredProfit = _filteredBills
        .where((b) => !b.returnStatus)
        .fold(
          0.0,
          (sum, bill) =>
              sum +
              bill.items.fold(0.0, (s, item) => s + item.itemProfit) -
              bill.discountAmount,
        );
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
    final now = DateTime.now();
    final picked = await showAppRangeCalendar(
      context: context,
      firstDate: DateTime(2020),
      lastDate: now,
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = DateTime(
          picked.end.year,
          picked.end.month,
          picked.end.day,
          23,
          59,
          59,
        );
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
        GlassyToast.show(context, '${_localizations.errorSharingBillGeneric}: $e', isError: true);
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
      final file = await _pdfService.savePdfToFile(
        billData: printData,
        shopDetails: shop,
      );

      if (mounted) {
        GlassyToast.show(context, '${_localizations.pdfSaved}: ${file.path.split('/').last}');
      }
    } catch (e) {
      debugPrint('[BillsListPage] ERROR in _saveBillAsPdfWithData: $e');
      if (mounted) {
        GlassyToast.show(context, '${_localizations.errorSavingPdfGeneric}: $e', isError: true);
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
        Duration(seconds: 5),
        onTimeout: () => Shop.empty,
      );
      if (!mounted) return;
      await _pdfService.previewAndPrintPdf(
        billData: printData,
        shopDetails: shop,
      );
    } catch (e) {
      debugPrint('[BillsListPage] ERROR in _printBillWithData: $e');
      if (mounted) {
        GlassyToast.show(context, '${_localizations.errorPrintingBill}: $e', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isProcessingPdf = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffold(context),
      body: Column(
        children: [
          AppTopBar(
            title: _localizations.billsHistory,
            subtitle: _localizations.viewAllTransactions,
            actions: [
              AppTopBar.action(
                icon: Icons.description_rounded,
                onTap: _generateBillReport,
              ),
              AppTopBar.action(
                icon: Icons.settings_rounded,
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const BillReportSettingsPage(),
                    ),
                  );
                },
              ),
            ],
          ),
          Expanded(
            child: Stack(
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
              color: AppTheme.black.withValues(alpha: 0.3),
              child: Center(
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 24,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.card(context),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.black.withValues(alpha: 0.15),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 40,
                        height: 40,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.action(context),
                          ),
                        ),
                      ),
                      SizedBox(height: 16),
                      Text(
                        '${_localizations.preparingPdf}...',
                        style: TextStyle(
                          fontFamily: 'Literata',
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.accent(context),
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
        ],
      ),
    );
  }

  Color _brandColor(BuildContext context) => AppColors.actionBright(context);

  Widget _buildStatsSection() {
    final brand = _brandColor(context);
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 0),
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Row(
        children: [
          _buildStatColumn(
            '₹${_formatAmount(_filteredSales)}',
            _localizations.totalSales,
            brand,
          ),
          _statDivider(),
          _buildStatColumn(
            '₹${_formatAmount(_filteredProfit)}',
            _localizations.netProfit,
            brand,
          ),
          _statDivider(),
          _buildStatColumn('$_filteredBillsCount', _localizations.bills, brand),
          _statDivider(),
          _buildStatColumn(
            '$_filteredReturnedCount',
            _localizations.returns,
            brand,
          ),
        ],
      ),
    );
  }

  Widget _statDivider() {
    return Container(width: 1, height: 36, color: AppColors.border(context));
  }

  Widget _buildStatColumn(String value, String label, Color valueColor) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'Literata',
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: valueColor,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Literata',
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppColors.mutedText(context),
            ),
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
          filters.add(_localizations.today);
          break;
        case _BillDateFilter.thisWeek:
          filters.add(_localizations.thisWeek);
          break;
        case _BillDateFilter.thisMonth:
          filters.add(_localizations.thisMonth);
          break;
        case _BillDateFilter.thisYear:
          filters.add(_localizations.thisYear);
          break;
        case _BillDateFilter.custom:
          filters.add(_localizations.customRange);
          break;
        case _BillDateFilter.none:
          break;
      }
    }

    if (_showReturnedOnly) {
      filters.add(_localizations.returnsOnly);
    }

    if (_searchController.text.isNotEmpty) {
      filters.add('${_localizations.searchBill}: "${_searchController.text}"');
    }

    return filters.isEmpty ? _localizations.filtered : filters.join(' • ');
  }

  String _formatAmount(double amount) {
    if (amount >= 100000) {
      return '${(amount / 100000).toStringAsFixed(1)}L';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(1)}K';
    }
    return amount.toStringAsFixed(0);
  }

  bool get _hasActiveFilters =>
      _startDate != null ||
      _showReturnedOnly ||
      _dateFilter != _BillDateFilter.none;

  String _historySummary() {
    final count = '$_filteredBillsCount ${_localizations.bills}';
    final searching = _searchController.text.isNotEmpty;
    if (!_hasActiveFilters && !searching) return count;
    return '$count · ${_getFilterDescription()}';
  }

  Widget _buildSearchAndFilterSection() {
    final hasDateFilter = _startDate != null;
    final brand = _brandColor(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: Column(
        children: [
          Container(
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.inputFill(context),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border(context)),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: _filterBills,
              style: TextStyle(
                fontFamily: 'Literata',
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.primaryText(context),
              ),
              decoration: InputDecoration(
                hintText: _localizations.searchBills,
                hintStyle: TextStyle(
                  fontFamily: 'Literata',
                  fontSize: 14,
                  color: AppColors.mutedText(context),
                ),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: AppColors.mutedText(context),
                  size: 20,
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        onPressed: () {
                          _searchController.clear();
                          _filterBills('');
                        },
                        icon: Icon(
                          Icons.close_rounded,
                          color: AppColors.mutedText(context),
                          size: 18,
                        ),
                      )
                    : null,
                filled: true,
                fillColor: AppTheme.transparent,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildFilterChip(
                  label: _localizations.today,
                  isActive: _dateFilter == _BillDateFilter.today,
                  onTap: () => _setDateFilter(_BillDateFilter.today),
                  onClear: _dateFilter == _BillDateFilter.today
                      ? () => _setDateFilter(_BillDateFilter.today)
                      : null,
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  label: _localizations.thisWeek,
                  isActive: _dateFilter == _BillDateFilter.thisWeek,
                  onTap: () => _setDateFilter(_BillDateFilter.thisWeek),
                  onClear: _dateFilter == _BillDateFilter.thisWeek
                      ? () => _setDateFilter(_BillDateFilter.thisWeek)
                      : null,
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  label: _localizations.thisMonth,
                  isActive: _dateFilter == _BillDateFilter.thisMonth,
                  onTap: () => _setDateFilter(_BillDateFilter.thisMonth),
                  onClear: _dateFilter == _BillDateFilter.thisMonth
                      ? () => _setDateFilter(_BillDateFilter.thisMonth)
                      : null,
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  label: _localizations.thisYear,
                  isActive: _dateFilter == _BillDateFilter.thisYear,
                  onTap: () => _setDateFilter(_BillDateFilter.thisYear),
                  onClear: _dateFilter == _BillDateFilter.thisYear
                      ? () => _setDateFilter(_BillDateFilter.thisYear)
                      : null,
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  icon: Icons.calendar_today_rounded,
                  label: hasDateFilter
                      ? '${DateFormat('dd MMM').format(_startDate!)} – ${DateFormat('dd MMM').format(_endDate!)}'
                      : _localizations.custom,
                  isActive: hasDateFilter,
                  onTap: _showDateFilterDialog,
                  onClear: hasDateFilter ? _clearDateFilter : null,
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  icon: Icons.assignment_return_rounded,
                  label: _localizations.returns,
                  isActive: _showReturnedOnly,
                  onTap: _toggleReturnFilter,
                  onClear: _showReturnedOnly ? _toggleReturnFilter : null,
                ),
                const SizedBox(width: 8),
                _buildSortChip(
                  'newest',
                  _localizations.newest,
                  Icons.arrow_downward_rounded,
                ),
                const SizedBox(width: 8),
                _buildSortChip(
                  'oldest',
                  _localizations.oldest,
                  Icons.arrow_upward_rounded,
                ),
                const SizedBox(width: 8),
                _buildSortChip(
                  'highest',
                  _localizations.highest,
                  Icons.trending_up_rounded,
                ),
                const SizedBox(width: 8),
                _buildSortChip(
                  'lowest',
                  _localizations.lowest,
                  Icons.trending_down_rounded,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  _historySummary(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Literata',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: brand,
                  ),
                ),
              ),
              if (_hasActiveFilters) ...[
                const SizedBox(width: 12),
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
                    style: TextStyle(
                      fontFamily: 'Literata',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: brand,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isActive,
    required VoidCallback onTap,
    VoidCallback? onClear,
    IconData? icon,
  }) {
    final brand = _brandColor(context);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.only(left: icon == null ? 14 : 10, right: 12),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isActive ? brand : AppColors.chipFill(context),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? brand : AppColors.border(context),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 14,
                color: isActive ? AppTheme.white : AppColors.mutedText(context),
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Literata',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isActive
                    ? AppTheme.white
                    : AppColors.secondaryText(context),
              ),
            ),
            if (onClear != null) ...[
              const SizedBox(width: 6),
              GestureDetector(
                onTap: onClear,
                child: const Icon(
                  Icons.close_rounded,
                  size: 14,
                  color: AppTheme.white,
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
    final brand = _brandColor(context);
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
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.chipFill(context),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? brand : AppColors.border(context),
            width: isActive ? 1.4 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isActive ? brand : AppColors.mutedText(context),
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Literata',
                fontSize: 12,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: isActive ? brand : AppColors.secondaryText(context),
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
              color: AppColors.mutedText(context),
            ),
            const SizedBox(height: 16),
            Text(
              _localizations.noBillsFound,
              style: TextStyle(
                fontFamily: 'Literata',
                fontSize: 16,
                color: AppColors.secondaryText(context),
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
                    color: _brandColor(context),
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
    final brand = _brandColor(context);
    final accent = isFullyReturned
        ? AppTheme.red
        : hasPartialReturn
        ? AppTheme.orange
        : brand;
    final customerName = (bill.customerName?.trim().isNotEmpty ?? false)
        ? bill.customerName!.trim()
        : _localizations.walkInCustomer;
    final isNamed = bill.customerName?.trim().isNotEmpty ?? false;
    final initial = customerName.characters.first.toUpperCase();

    return GestureDetector(
      onTap: () => _showBillDetails(bill),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.card(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border(context)),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                child: Container(width: 3, color: accent),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Row(
                            children: [
                              Flexible(
                                child: Text(
                                  bill.billNumber,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontFamily: 'Literata',
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.2,
                                    color: accent,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                bill.isSynced
                                    ? Icons.check_circle_rounded
                                    : Icons.cloud_upload_rounded,
                                size: 14,
                                color: bill.isSynced
                                    ? AppTheme.green
                                    : AppTheme.orange,
                              ),
                              if (hasAnyReturn) ...[
                                const SizedBox(width: 6),
                                Text(
                                  isFullyReturned
                                      ? _localizations.returnedLabel
                                      : _localizations.partialReturn,
                                  style: TextStyle(
                                    fontFamily: 'Literata',
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: isFullyReturned
                                        ? AppTheme.red
                                        : AppTheme.orange,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.schedule_rounded,
                          size: 12,
                          color: AppColors.mutedText(context),
                        ),
                        const SizedBox(width: 3),
                        Text(
                          dateFormat.format(bill.billDate),
                          style: TextStyle(
                            fontFamily: 'Literata',
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: AppColors.mutedText(context),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _printingBillId == bill.id
                            ? SizedBox(
                                width: 34,
                                height: 34,
                                child: Center(
                                  child: SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        AppColors.action(context),
                                      ),
                                    ),
                                  ),
                                ),
                              )
                            : GestureDetector(
                                onTap: () => _printBill(bill),
                                child: Container(
                                  width: 34,
                                  height: 34,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: AppColors.border(context),
                                    ),
                                  ),
                                  child: Icon(
                                    Icons.print_rounded,
                                    size: 16,
                                    color: AppColors.secondaryText(context),
                                  ),
                                ),
                              ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.inputFill(context),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border(context)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: brand.withValues(alpha: 0.16),
                              shape: BoxShape.circle,
                            ),
                            child: isNamed
                                ? Text(
                                    initial,
                                    style: TextStyle(
                                      fontFamily: 'Literata',
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: brand,
                                    ),
                                  )
                                : Icon(
                                    Icons.person_rounded,
                                    size: 16,
                                    color: brand,
                                  ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  customerName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontFamily: 'Literata',
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primaryText(context),
                                  ),
                                ),
                                if (bill.customerContact != null &&
                                    bill.customerContact!.isNotEmpty)
                                  Text(
                                    bill.customerContact!,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontFamily: 'Literata',
                                      fontSize: 12,
                                      color: AppColors.mutedText(context),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          if (bill.customerContact != null &&
                              bill.customerContact!.isNotEmpty)
                            Icon(
                              Icons.phone_rounded,
                              size: 16,
                              color: AppColors.mutedText(context),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _buildBillMeta(
                          Icons.shopping_bag_outlined,
                          '${bill.items.length} ${_localizations.itemsLabel}',
                        ),
                        const SizedBox(width: 6),
                        _buildBillMeta(
                          Icons.inventory_2_outlined,
                          '${bill.totalQuantity} ${_localizations.qtyLabel}',
                        ),
                        if (bill.discountAmount > 0) ...[
                          const SizedBox(width: 6),
                          Text(
                            '-${bill.discountPercent.toStringAsFixed(0)}%',
                            style: TextStyle(
                              fontFamily: 'Literata',
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: brand,
                            ),
                          ),
                        ],
                        const Spacer(),
                        Text(
                          '₹${bill.finalAmount.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontFamily: 'Literata',
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: accent,
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

  Widget _buildBillMeta(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.chipFill(context),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AppColors.mutedText(context)),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Literata',
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppColors.secondaryText(context),
            ),
          ),
        ],
      ),
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

  const _BillDetailsDialog({required this.bill});

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
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
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
      Navigator.pop(
        context,
        const _BillDialogResult(action: _BillDialogAction.billReturned),
      );
    }
  }

  PrintBillData _createPrintData() {
    final double? totalDueAmount = _bill.pendingAmount > 0
        ? _bill.pendingAmount
        : null;

    if (_includeReturnsInPrint) {
      // Include return data as-is from stored bill items
      return PrintBillData.fromBill(_bill, totalDueAmount: totalDueAmount);
    } else {
      // Zero out return quantities for printing without returns
      final cleanBill = _bill.copyWith(
        items: _bill.items
            .map(
              (item) => BillItem(
                id: item.id,
                billId: item.billId,
                productId: item.productId,
                productName: item.productName,
                purchasePrice: item.purchasePrice,
                sellingPrice: item.sellingPrice,
                quantity: item.quantity,
                subtotal: item.subtotal,
                returnedQuantity: 0,
              ),
            )
            .toList(),
      );
      return PrintBillData.fromBill(cleanBill, totalDueAmount: totalDueAmount);
    }
  }

  /// Calculated totals for display
  double get _returnDeduction => _bill.totalReturnedAmount;
  double get _finalPayable =>
      (_bill.finalAmount - _returnDeduction).clamp(0.0, double.infinity);
  bool get _isFullyReturned => _bill.isFullyReturned;

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMM yyyy, hh:mm a');

    return Scaffold(
      backgroundColor: AppColors.scaffold(context),
      body: Column(
        children: [
          AppTopBar(
            title: _localizations.billDetails,
            subtitle: _bill.billNumber,
          ),
          Expanded(
            child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
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
                              iconColor: AppColors.action(context),
                              title: _localizations.date,
                              value: dateFormat.format(_bill.billDate),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildInfoCard(
                              icon: Icons.person_rounded,
                              iconColor: AppColors.action(context),
                              title: _localizations.customerName,
                              value:
                                  _bill.customerName ??
                                  _localizations.walkInCustomer,
                            ),
                          ),
                        ],
                      ),
                      if (_bill.customerContact != null) ...[
                        const SizedBox(height: 12),
                        _buildInfoCard(
                          icon: Icons.phone_rounded,
                          iconColor: AppTheme.green,
                          title: _localizations.mobile,
                          value: _bill.customerContact!,
                          fullWidth: true,
                        ),
                      ],
                      const SizedBox(height: 20),

                      // ══════════ Items Section ══════════
                      _buildSectionHeader(
                        _localizations.soldItems,
                        '${_bill.items.length} ${_localizations.items}',
                      ),
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
          style: TextStyle(
            fontFamily: 'Literata',
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.accent(context),
          ),
        ),
        if (subtitle != null)
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.accentSoft(context, 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              subtitle,
              style: TextStyle(
                fontFamily: 'Literata',
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.accentSoft(context, 0.8),
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
      padding: EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.black.withValues(alpha: 0.04),
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
                    color: AppTheme.grey,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontFamily: 'Literata',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.paletteFF2D3436,
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
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Table Header
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.accentSoft(context, 0.05),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
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
                      color: AppTheme.grey600,
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
                      color: AppTheme.grey600,
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
                      color: AppTheme.grey600,
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
                      color: AppTheme.grey600,
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
            separatorBuilder: (_, _) =>
                Divider(height: 1, color: AppColors.chipFill(context)),
            itemBuilder: (context, index) => _buildItemRow(_bill.items[index]),
          ),
        ],
      ),
    );
  }

  Widget _buildNotesCard() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.amber.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.black.withValues(alpha: 0.04),
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
              color: AppTheme.amber.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.note_rounded, color: AppTheme.amber700, size: 18),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              _bill.notes!,
              style: TextStyle(
                fontFamily: 'Literata',
                fontSize: 13,
                color: AppTheme.grey700,
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
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.black.withValues(alpha: 0.04),
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
                    valueColor: AppTheme.green,
                  ),
                ],
                // Tax info
                if (_bill.isGstApplied && _bill.totalTaxAmount > 0) ...[
                  const SizedBox(height: 10),
                  _buildSummaryRow(
                    'Tax',
                    '₹${_bill.totalTaxAmount.toStringAsFixed(2)}',
                    valueColor: AppTheme.blue,
                  ),
                ],
                SizedBox(height: 10),
                Container(height: 1, color: AppColors.border(context)),
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
                      color: AppTheme.orange.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppTheme.orange.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Column(
                      children: [
                        _buildSummaryRow(
                          '${_localizations.returnDeduction} (${_bill.totalReturnedQuantity} ${_localizations.quantity})',
                          '-₹${_returnDeduction.toStringAsFixed(2)}',
                          valueColor: AppTheme.orange,
                        ),
                        const SizedBox(height: 8),
                        Container(
                          height: 1,
                          color: AppTheme.orange.withValues(alpha: 0.2),
                        ),
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
                                color: _isFullyReturned
                                    ? AppTheme.red
                                    : AppTheme.paletteFF2D3436,
                              ),
                            ),
                            Text(
                              _isFullyReturned
                                  ? '₹0.00'
                                  : '₹${_finalPayable.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontFamily: 'Literata',
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: _isFullyReturned
                                    ? AppTheme.red
                                    : AppColors.action(context),
                              ),
                            ),
                          ],
                        ),
                        if (_isFullyReturned) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.red.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  size: 14,
                                  color: AppTheme.red700,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  _localizations.statusFullyReturned,
                                  style: TextStyle(
                                    fontFamily: 'Literata',
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.red700,
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
                  SizedBox(height: 12),
                  Container(height: 1, color: AppColors.border(context)),
                  const SizedBox(height: 12),
                  _buildSummaryRow(
                    _localizations.paidAmount,
                    '₹${_bill.paidAmount.toStringAsFixed(2)}',
                    valueColor: AppTheme.green,
                  ),
                  if (_bill.pendingAmount > 0) ...[
                    const SizedBox(height: 10),
                    _buildSummaryRow(
                      _localizations.pendingAmount,
                      '₹${_bill.pendingAmount.toStringAsFixed(2)}',
                      valueColor: AppTheme.orange,
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
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: AppColors.headerGradient(context),
                ),
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(16),
                ),
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
                      color: AppTheme.white,
                    ),
                  ),
                  Text(
                    '₹${_bill.finalAmount.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontFamily: 'Literata',
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.white,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(
    String label,
    String value, {
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
            color: AppTheme.grey600,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontFamily: 'Literata',
            fontSize: valueSize,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w600,
            color: valueColor ?? AppTheme.paletteFF2D3436,
          ),
        ),
      ],
    );
  }

  Widget _buildReturnToggleCard() {
    return Container(
      padding: EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.orange.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.black.withValues(alpha: 0.04),
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
              color: AppTheme.orange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.assignment_return_rounded,
              color: AppTheme.orange700,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _localizations.includeReturnedItemsInPrint,
              style: TextStyle(
                fontFamily: 'Literata',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.grey700,
              ),
            ),
          ),
          Transform.scale(
            scale: 0.85,
            child: Switch(
              value: _includeReturnsInPrint,
              onChanged: (v) => setState(() => _includeReturnsInPrint = v),
              activeThumbColor: AppTheme.orange,
              activeTrackColor: AppTheme.orange.withValues(alpha: 0.3),
              inactiveThumbColor: AppTheme.grey400,
              inactiveTrackColor: AppTheme.grey.withValues(alpha: 0.3),
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
      debugPrint(
        '[BillDetailsDialog] PDF generation already in progress, ignoring request',
      );
      return;
    }

    debugPrint(
      '[BillDetailsDialog] Starting PDF preview for bill: ${_bill.billNumber}',
    );
    _globalPdfGenerationInProgress = true;
    setState(() => _isGeneratingPdf = true);

    try {
      debugPrint('[BillDetailsDialog] Creating print data...');
      final printData = _createPrintData();

      debugPrint('[BillDetailsDialog] Fetching shop details...');
      final shop = await _shopRepository.getShopDetails().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          debugPrint(
            '[BillDetailsDialog] Shop details timeout, using empty shop',
          );
          return Shop.empty;
        },
      );
      debugPrint('[BillDetailsDialog] Got shop: ${shop.shopName}');

      debugPrint('[BillDetailsDialog] Generating PDF file...');
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

      debugPrint('[BillDetailsDialog] PDF saved to: ${file.path}');
      debugPrint('[BillDetailsDialog] File size: $fileSize bytes');

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
            customerPhone: _bill.customerContact,
          ),
        ),
      );
      debugPrint('[BillDetailsDialog] Returned from FilePreviewPage');
    } catch (e, stack) {
      debugPrint('[BillDetailsDialog] ERROR generating PDF: $e');
      debugPrint('[BillDetailsDialog] Stack trace: $stack');

      if (mounted) {
        GlassyToast.show(context, '${_localizations.failedToGeneratePdf}: ${e.toString()}');
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
          icon: _isGeneratingPdf
              ? Icons.hourglass_empty_rounded
              : Icons.preview_rounded,
          label: _isGeneratingPdf
              ? _localizations.generatingLabel
              : _localizations.previewBill,
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
        padding: EdgeInsets.symmetric(vertical: 14, horizontal: 20),
        decoration: BoxDecoration(
          gradient: isPrimary
              ? LinearGradient(
                  colors: AppColors.headerGradient(context),
                )
              : null,
          color: isPrimary ? null : AppTheme.white,
          borderRadius: BorderRadius.circular(14),
          border: isPrimary
              ? null
              : Border.all(
                  color: AppColors.accentSoft(context, 0.3),
                ),
          boxShadow: isPrimary
              ? [
                  BoxShadow(
                    color: AppColors.accentSoft(context, 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [
                  BoxShadow(
                    color: AppTheme.black.withValues(alpha: 0.04),
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
              color: isPrimary ? AppTheme.white : AppColors.action(context),
            ),
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Literata',
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isPrimary ? AppTheme.white : AppColors.action(context),
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
          ? AppTheme.orange.withValues(alpha: 0.03)
          : AppTheme.transparent,
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
                            ? AppTheme.grey400
                            : AppTheme.paletteFF2D3436,
                        decoration: isFullReturn
                            ? TextDecoration.lineThrough
                            : null,
                        decorationColor: AppTheme.orange,
                        decorationThickness: 2,
                      ),
                    ),
                    if (hasReturn)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Row(
                          children: [
                            Icon(
                              Icons.assignment_return_rounded,
                              size: 11,
                              color: AppTheme.orange600,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              '${item.returnedQuantity} ${_localizations.returnedCount}',
                              style: TextStyle(
                                fontFamily: 'Literata',
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                color: AppTheme.orange600,
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
                  item.displayQuantity,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Literata',
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: isFullReturn ? AppTheme.grey400 : AppTheme.grey700,
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
                    color: AppTheme.grey,
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
                        ? AppTheme.grey400
                        : AppColors.action(context),
                    decoration: isFullReturn
                        ? TextDecoration.lineThrough
                        : null,
                    decorationColor: AppTheme.orange,
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
        padding: EdgeInsets.symmetric(vertical: 14, horizontal: 20),
        decoration: BoxDecoration(
          color: AppColors.card(context),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppTheme.orange.withValues(alpha: 0.5),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.orange.withValues(alpha: 0.15),
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
                color: AppTheme.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.assignment_return_rounded,
                color: AppTheme.orange700,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              _localizations.returnThisBill,
              style: TextStyle(
                fontFamily: 'Literata',
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppTheme.orange700,
              ),
            ),
            SizedBox(width: 8),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: AppTheme.orange400,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReturnedInfoCard() {
    final dateFormat = DateFormat('dd MMM yyyy, hh:mm a');
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.orange.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.black.withValues(alpha: 0.04),
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
              color: AppTheme.orange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.assignment_return_rounded,
              color: AppTheme.orange700,
              size: 22,
            ),
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
                    color: AppTheme.orange700,
                  ),
                ),
                if (_bill.returnDate != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    dateFormat.format(_bill.returnDate!),
                    style: TextStyle(
                      fontFamily: 'Literata',
                      fontSize: 12,
                      color: AppTheme.grey,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Icon(Icons.check_circle_rounded, color: AppTheme.orange400, size: 24),
        ],
      ),
    );
  }
}

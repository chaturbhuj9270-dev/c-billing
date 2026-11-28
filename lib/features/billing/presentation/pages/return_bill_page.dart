import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:c_billing/core/services/billing_service.dart';
import 'package:c_billing/core/printing/printing.dart';
import 'package:printing/printing.dart' as printing_pkg;
import 'package:pdf/widgets.dart' as pw;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:c_billing/features/billing/data/repositories/firebase_bill_repository.dart';
import 'package:c_billing/features/billing/domain/entities/bill.dart';
import 'package:c_billing/features/billing/domain/entities/bill_item.dart';
import 'package:c_billing/features/inventory_management/data/repositories/firebase_product_repository.dart';
import 'package:c_billing/features/inventory_management/data/repositories/firebase_stock_repository.dart';
import 'package:c_billing/features/shop/data/repositories/shop_repository.dart';
import 'package:c_billing/features/shop/domain/entities/shop.dart';
import 'package:c_billing/common_widgets/printer_selection_widget.dart';
import 'package:c_billing/features/billing/offline/controllers/bill_offline_controller.dart';
import 'package:c_billing/features/billing/offline/entities/bill_entity.dart';
import 'package:c_billing/core/services/inventory_integration_service.dart';
import 'package:c_billing/core/services/language_service.dart';
import 'package:c_billing/core/localization/app_localizations.dart';
import 'package:c_billing/core/ui/glassy_toast.dart';
import 'package:c_billing/common_widgets/app_top_bar.dart';
import 'package:c_billing/core/theme/app_theme.dart';
import 'package:c_billing/core/ui/desktop_canvas.dart';

// Return Bill Page for processing bill returns Allows searching by bill number or customer mobile and processing returns
class ReturnBillPage extends StatefulWidget {
  final Bill? initialBill;

  const ReturnBillPage({super.key, this.initialBill});

  @override
  State<ReturnBillPage> createState() => _ReturnBillPageState();
}

class _ReturnBillPageState extends State<ReturnBillPage>
    with SingleTickerProviderStateMixin {
  late BillingService _billingService;
  late FirebaseFirestore _firestore;
  late AnimationController _animController;
  late Animation<double> _opacityAnimation;

  // Printer service for bill printing
  final PosPrinterService _printerService = PosPrinterService();
  final PdfBillService _pdfService = PdfBillService();
  final ShopRepository _shopRepository = ShopRepository();
  bool _isPrinting = false;

  final _searchController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  Bill? _currentBill;
  bool _isSearching = false;
  bool _isProcessing = false;
  String? _errorMessage;
  String? _successMessage;
  bool _hasReturnProcessed =
      false; // Track if any return was successfully processed

  // Track return quantities for each item (itemId -> quantity to return) Changed to double to support fractional quantities (e.g., 0.5 kg)
  Map<String, double> _returnQuantities = {};
  late AppLocalizations _localizations;

  @override
  void initState() {
    super.initState();
    _localizations = AppLocalizations(LanguageService.instance.currentLanguage);
    _firestore = FirebaseFirestore.instance;

    _billingService = BillingService(
      billRepository: FirebaseBillRepository(firestore: _firestore),
      productRepository: FirebaseProductRepository(firestore: _firestore),
      stockRepository: FirebaseStockRepository(firestore: _firestore),
    );

    // Initialize animations
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeIn));

    Future.delayed(
      const Duration(milliseconds: 100),
      () => _animController.forward(),
    );

    // If initial bill is provided, set it
    if (widget.initialBill != null) {
      _currentBill = widget.initialBill;
      _searchController.text = widget.initialBill!.billNumber;
      _initializeReturnQuantities(widget.initialBill!);
    }
  }

  void _initializeReturnQuantities(Bill bill) {
    _returnQuantities = {};
    for (final item in bill.items) {
      // Default to 0 - user selects what to return
      _returnQuantities[item.id] = 0.0;
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // Get total quantity selected for return
  double get _totalReturnQuantity {
    return _returnQuantities.values.fold(0.0, (total, qty) => total + qty);
  }

  // Get total refund amount based on selected quantities (after discount/tax ratio)
  double get _totalRefundAmount {
    if (_currentBill == null) return 0.0;
    double listTotal = 0.0;
    for (final item in _currentBill!.items) {
      final returnQty = _returnQuantities[item.id] ?? 0.0;
      listTotal += item.sellingPrice * returnQty;
    }
    return _currentBill!.chargedRefundFor(listTotal);
  }

  // Check if any items are selected for return
  bool get _hasItemsToReturn =>
      _totalReturnQuantity > 0.001; // Small tolerance for floats

  Future<void> _searchBill() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSearching = true;
      _errorMessage = null;
      _successMessage = null;
      _currentBill = null;
      _returnQuantities = {};
    });

    try {
      final query = _searchController.text.trim();

      // Use offline controller for searching
      final results = await BillOfflineController.instance.searchBills(query);

      if (mounted) {
        setState(() {
          _isSearching = false;
          if (results.isNotEmpty) {
            // Take the first matching bill
            final billEntity = results.first;
            _currentBill = Bill.fromBillEntity(billEntity);
            _initializeReturnQuantities(_currentBill!);
          } else {
            _errorMessage = _localizations.billNotFound;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSearching = false;
          _errorMessage = '${_localizations.errorSearchingBill}: $e';
        });
      }
    }
  }

  void _updateReturnQuantity(String itemId, double quantity) {
    if (_currentBill == null) return;

    // Find the item to validate quantity
    final item = _currentBill!.items.firstWhere(
      (i) => i.id == itemId,
      orElse: () => _currentBill!.items.first,
    );

    // Validate: quantity cannot be negative
    if (quantity < 0) {
      quantity = 0.0;
    }

    // Validate: quantity cannot exceed remaining (sold - already returned)
    final maxReturnableQty = item.remainingQuantity;
    if (quantity > maxReturnableQty + 0.001) {
      // Small tolerance for floats
      quantity = maxReturnableQty;
      // Show a message if user tries to exceed
      final displayMax = maxReturnableQty == maxReturnableQty.roundToDouble()
          ? maxReturnableQty.toInt().toString()
          : maxReturnableQty.toStringAsFixed(2);
      GlassyToast.show(
        context,
        'Cannot return more than $displayMax units (sold qty: ${item.quantity.toStringAsFixed(item.quantity == item.quantity.roundToDouble() ? 0 : 2)})',
      );
    }

    setState(() {
      _returnQuantities[itemId] = quantity;
    });
  }

  void _selectAllItems() {
    if (_currentBill == null) return;
    setState(() {
      for (final item in _currentBill!.items) {
        _returnQuantities[item.id] = item.remainingQuantity;
      }
    });
  }

  void _clearAllItems() {
    if (_currentBill == null) return;
    setState(() {
      for (final item in _currentBill!.items) {
        _returnQuantities[item.id] = 0.0;
      }
    });
  }

  Future<void> _showReturnConfirmationDialog() async {
    if (_currentBill == null || !_hasItemsToReturn) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => _ReturnConfirmationDialog(
        bill: _currentBill!,
        returnQuantities: _returnQuantities,
        totalRefundAmount: _totalRefundAmount,
      ),
    );

    if (confirmed == true) {
      await _processReturn();
    }
  }

  Future<BillEntity?> _resolveLocalBill(Bill bill) async {
    final localBills = await BillOfflineController.instance.getAllBills();
    for (final b in localBills) {
      if (b.serverId == bill.id || b.id.toString() == bill.id) {
        return b;
      }
    }
    for (final b in localBills) {
      if (b.serverId != null &&
          bill.billNumber.toLowerCase().contains(b.serverId!.toLowerCase())) {
        return b;
      }
    }
    return null;
  }

  Future<void> _processReturn() async {
    if (_currentBill == null || !_hasItemsToReturn) {
      debugPrint(
        '[ReturnBill] Cannot process: currentBill=${_currentBill != null}, hasItems=$_hasItemsToReturn',
      );
      return;
    }

    // Validate all return quantities before processing
    for (final item in _currentBill!.items) {
      final returnQty = _returnQuantities[item.id] ?? 0.0;
      if (returnQty > item.remainingQuantity + 0.001) {
        setState(() {
          _errorMessage =
              'Cannot return more than sold quantity for "${item.productName}". '
              'Sold: ${item.quantity.toStringAsFixed(item.quantity == item.quantity.roundToDouble() ? 0 : 2)}, Already returned: ${item.returnedQuantity.toStringAsFixed(item.returnedQuantity == item.returnedQuantity.roundToDouble() ? 0 : 2)}, '
              'Max returnable: ${item.remainingQuantity.toStringAsFixed(item.remainingQuantity == item.remainingQuantity.roundToDouble() ? 0 : 2)}';
        });
        GlassyToast.show(context, _errorMessage!);
        return;
      }
      if (returnQty < 0) {
        setState(() {
          _errorMessage =
              'Return quantity cannot be negative for "${item.productName}"';
        });
        return;
      }
    }

    debugPrint(
      '[ReturnBill] Starting offline-first return for bill: ${_currentBill!.id}',
    );

    setState(() {
      _isProcessing = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final localBill = await _resolveLocalBill(_currentBill!);
      if (localBill == null) {
        if (mounted) {
          setState(() {
            _isProcessing = false;
            _errorMessage =
                'Could not find this bill in local records. Open it from Bills list and try again.';
          });
          GlassyToast.show(context, _errorMessage!, isError: true);
        }
        return;
      }

      final returnItemDetails = <ReturnItemDetail>[];
      for (final item in _currentBill!.items) {
        final returnQty = _returnQuantities[item.id] ?? 0.0;
        // Exact qty (fractional kg/ltr stock is supported end to end).
        if (returnQty > 0.001) {
          returnItemDetails.add(
            ReturnItemDetail(
              productId: item.productId,
              productName: item.productName,
              returnQuantity: returnQty,
              costPrice: item.purchasePrice,
              sellingPrice: item.sellingPrice,
              batchId: 'BILL_${_currentBill!.id}_${item.productId}',
              itemId: item.id,
            ),
          );
        }
      }

      if (returnItemDetails.isEmpty) {
        if (mounted) {
          setState(() {
            _isProcessing = false;
            _errorMessage = _localizations.selectItemsToReturn;
          });
        }
        return;
      }

      // Local FIFO + bill + customer ledger is the source of truth (same as create bill).
      final localResult = await InventoryIntegrationService.instance
          .processReturn(
            billId: _currentBill!.id,
            billLocalId: localBill.id,
            returnItems: returnItemDetails,
            notes: 'Return for bill: ${_currentBill!.billNumber}',
          );

      if (!localResult.success) {
        if (mounted) {
          setState(() {
            _isProcessing = false;
            _errorMessage =
                localResult.errorMessage ?? _localizations.failedToProcessReturn;
          });
          GlassyToast.show(context, _errorMessage!, isError: true);
        }
        return;
      }

      // Best-effort cloud sync only when the bill already has a server id.
      final serverId = localBill.serverId;
      if (serverId != null && serverId.isNotEmpty) {
        try {
          final firebaseItems = <String, double>{};
          for (final item in _currentBill!.items) {
            final qty = _returnQuantities[item.id] ?? 0.0;
            if (qty > 0.001) {
              firebaseItems[item.id.isNotEmpty ? item.id : item.productId] = qty;
            }
          }
          await _billingService.processReturn(
            billId: serverId,
            returnItems: firebaseItems,
          );
        } catch (e) {
          debugPrint('[ReturnBill] Firebase sync skipped/failed: $e');
        }
      }

      if (!mounted) return;

      final refundAmount = localResult.refundAmount > 0
          ? localResult.refundAmount
          : _totalRefundAmount;

      // Reload from local DB so UI matches ledger / FIFO updates exactly.
      final refreshed = await BillOfflineController.instance.getBillById(
        localBill.id,
      );
      final nextBill = refreshed != null
          ? Bill.fromBillEntity(refreshed)
          : _currentBill!.copyWith(
              items: _currentBill!.items.map((item) {
                final returnQty = _returnQuantities[item.id] ?? 0.0;
                return item.copyWith(
                  returnedQuantity: item.returnedQuantity + returnQty,
                );
              }).toList(),
              returnStatus: _currentBill!.items.every((item) {
                final returnQty = _returnQuantities[item.id] ?? 0.0;
                return (item.returnedQuantity + returnQty) >=
                    item.quantity - 0.001;
              }),
              returnDate: DateTime.now(),
            );

      if (!mounted) return;
      setState(() {
        _isProcessing = false;
        _hasReturnProcessed = true;
        _successMessage =
            'Return processed successfully! Refund: ₹${refundAmount.toStringAsFixed(2)}';
        _currentBill = nextBill;
        _initializeReturnQuantities(_currentBill!);
      });

      GlassyToast.show(
        context,
        'Return processed! Print or share the receipt before leaving.',
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _errorMessage = '${_localizations.errorProcessingReturn}: $e';
        });
        GlassyToast.show(context, _errorMessage!, isError: true);
      }
    }
  }

  // Create PrintBillData with proper return bill context
  PrintBillData _createReturnPrintData() {
    final bill = _currentBill!;
    final hasReturns = bill.hasAnyReturns;
    return PrintBillData.fromBill(
      bill,
      isReturn: hasReturns,
      refund: hasReturns ? bill.totalReturnedAmount : null,
    );
  }

  // Handle printing the bill
  Future<void> _handlePrintBill() async {
    if (_currentBill == null) return;

    // Check if printer is connected
    if (!_printerService.isConnected) {
      final selectedPrinter = await PrinterSelectionWidget.show(context);
      if (selectedPrinter == null || !mounted) return;
    }

    setState(() => _isPrinting = true);

    try {
      // Get shop details
      final shop = await _shopRepository.getShopDetails();
      if (!mounted) return;

      // Create print bill data with return context
      final printData = _createReturnPrintData();

      // Print the bill
      final result = await _printerService.printBill(
        billData: printData,
        shopDetails: shop,
      );

      if (mounted) {
        setState(() => _isPrinting = false);

        GlassyToast.show(context, result.message ?? 'Error', isError: true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isPrinting = false);
        GlassyToast.show(
          context,
          '${_localizations.errorPrintingBill}: $e',
          isError: true,
        );
      }
    }
  }

  // Handle sharing the bill as PDF
  Future<void> _handleShareBill() async {
    if (_currentBill == null) return;

    try {
      // 1. Get shop details with timeout
      final shop = await _shopRepository.getShopDetails().timeout(
        const Duration(seconds: 5),
        onTimeout: () => Shop.empty,
      );

      // 2. Create return print data (synchronous)
      final printData = _createReturnPrintData();

      // 3. Generate PDF based on bill type setting
      final prefs = await SharedPreferences.getInstance();
      final billType = prefs.getString('bill_type') ?? 'pos';
      final pw.Document pdf;
      if (billType == 'normal') {
        pdf = await _pdfService.generateNormalBillPdf(
          billData: printData,
          shopDetails: shop,
        );
      } else {
        pdf = await _pdfService.generateBillPdf(
          billData: printData,
          shopDetails: shop,
        );
      }

      final bytes = await pdf.save();
      if (!mounted) return;

      // 4. Share via native share sheet
      await printing_pkg.Printing.sharePdf(
        bytes: bytes,
        filename:
            'return_bill_${_currentBill!.billNumber.replaceAll(RegExp(r'[^a-zA-Z0-9\-_]'), '_')}.pdf',
      );
    } catch (e) {
      // Close loading indicator only if still showing
      if (mounted) {
        GlassyToast.show(
          context,
          '${_localizations.shareErrorLabel}: $e',
          isError: true,
        );
      }
    }
  }

  bool get _desktopReturn => DesktopCanvas.wide(context);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffold(context),
      body: Column(
        children: [
          _buildAppBar(),
          Expanded(
            child: FadeTransition(
              opacity: _opacityAnimation,
              child: _desktopReturn
                  ? _buildDesktopReturn()
                  : _buildMobileReturn(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileReturn() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.initialBill == null) _buildSearchSection(),
          if (_errorMessage != null) _buildErrorMessage(),
          if (_successMessage != null) _buildSuccessMessage(),
          if (_currentBill != null) ...[
            const SizedBox(height: 16),
            _buildBillDetails(),
            const SizedBox(height: 24),
            _buildReturnButton(),
          ],
        ],
      ),
    );
  }

  Widget _buildDesktopReturn() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 3,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.initialBill == null) ...[
                    _buildSearchSection(),
                    const SizedBox(height: 12),
                  ],
                  if (_errorMessage != null) _buildErrorMessage(),
                  if (_successMessage != null) _buildSuccessMessage(),
                  if (_currentBill != null)
                    _buildBillDetails()
                  else
                    _buildDesktopEmptyState(),
                ],
              ),
            ),
          ),
          const SizedBox(width: 16),
          SizedBox(
            width: 320,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: _buildDesktopSummaryCard(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopEmptyState() {
    final muted = AppColors.mutedText(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 48),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Column(
        children: [
          Icon(
            Icons.assignment_return_outlined,
            size: 48,
            color: AppColors.accent(context).withValues(alpha: 0.55),
          ),
          const SizedBox(height: 14),
          Text(
            _localizations.searchBill,
            style: TextStyle(
              fontFamily: 'Literata',
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.primaryText(context),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _localizations.enterBillOrMobile,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Literata',
              fontSize: 13,
              color: muted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopSummaryCard() {
    final action = AppColors.action(context);
    final muted = AppColors.mutedText(context);
    final bill = _currentBill;
    final selectedLines = bill == null
        ? 0
        : bill.items
            .where((i) => (_returnQuantities[i.id] ?? 0) > 0.001)
            .length;

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
            _localizations.returnBill,
            style: TextStyle(
              fontFamily: 'Literata',
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.accent(context),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            bill?.billNumber ?? _localizations.processBillReturns,
            style: TextStyle(
              fontFamily: 'Literata',
              fontSize: 12,
              color: muted,
            ),
          ),
          const SizedBox(height: 14),
          Container(
            height: 1,
            color: AppColors.border(context),
          ),
          const SizedBox(height: 10),
          line('Lines selected', '$selectedLines'),
          line(
            'Qty to return',
            _totalReturnQuantity == _totalReturnQuantity.roundToDouble()
                ? _totalReturnQuantity.toInt().toString()
                : _totalReturnQuantity.toStringAsFixed(2),
          ),
          line(
            'Bill amount',
            bill == null
                ? '—'
                : '₹${bill.finalAmount.toStringAsFixed(2)}',
          ),
          const SizedBox(height: 6),
          line(
            'Refund',
            '₹${_totalRefundAmount.toStringAsFixed(2)}',
            valueColor: action,
          ),
          const SizedBox(height: 16),
          if (bill != null && bill.hasReturnableItems) ...[
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _selectAllItems,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.accent(context),
                      side: BorderSide(color: AppColors.border(context)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'All',
                      style: TextStyle(
                        fontFamily: 'Literata',
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: _clearAllItems,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: muted,
                      side: BorderSide(color: AppColors.border(context)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Clear',
                      style: TextStyle(
                        fontFamily: 'Literata',
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
          _buildReturnButton(),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return AppTopBar(
      title: _localizations.returnBill,
      subtitle: _localizations.processBillReturns,
      onBack: () => Navigator.pop(context, _hasReturnProcessed),
      actions: [
        if (_currentBill != null) ...[
          AppTopBar.action(
            icon: Icons.share_rounded,
            onTap: _handleShareBill,
          ),
          AppTopBar.action(
            icon: Icons.print_rounded,
            onTap: _isPrinting ? null : _handlePrintBill,
            isLoading: _isPrinting,
          ),
        ],
      ],
    );
  }

  Widget _buildSearchSection() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _localizations.searchBill,
              style: TextStyle(
                fontFamily: 'Literata',
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.accent(context),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _localizations.enterBillOrMobile,
              style: TextStyle(
                fontFamily: 'Literata',
                fontSize: 12,
                color: AppTheme.grey600,
              ),
            ),
            SizedBox(height: 16),
            TextFormField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: _localizations.billOrMobileHint,
                hintStyle: TextStyle(
                  fontFamily: 'Literata',
                  fontSize: 13,
                  color: AppTheme.grey400,
                ),
                prefixIcon: Icon(
                  Icons.search,
                  color: AppColors.accent(context),
                  size: 20,
                ),
                filled: true,
                fillColor: AppColors.scaffold(context),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: AppColors.accent(context),
                    width: 1.5,
                  ),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppTheme.red, width: 1.5),
                ),
              ),
              style: const TextStyle(fontFamily: 'Literata', fontSize: 14),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return _localizations.pleaseEnterBillOrMobile;
                }
                return null;
              },
              onFieldSubmitted: (_) => _searchBill(),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSearching ? null : _searchBill,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.action(context),
                  foregroundColor: AppTheme.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  disabledBackgroundColor: AppColors.action(context).withValues(alpha: 0.5),
                ),
                child: _isSearching
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppTheme.white,
                          ),
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.search, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            _localizations.searchAndValidate,
                            style: const TextStyle(
                              fontFamily: 'Literata',
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
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

  Widget _buildErrorMessage() {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.red50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.red200),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: AppTheme.red700, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _errorMessage!,
              style: TextStyle(
                fontFamily: 'Literata',
                fontSize: 13,
                color: AppTheme.red700,
              ),
            ),
          ),
          GestureDetector(
            onTap: () => setState(() => _errorMessage = null),
            child: Icon(Icons.close, color: AppTheme.red700, size: 18),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessMessage() {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.green50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.green200),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle_outline, color: AppTheme.green700, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _successMessage!,
              style: TextStyle(
                fontFamily: 'Literata',
                fontSize: 13,
                color: AppTheme.green700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBillDetails() {
    final bill = _currentBill!;
    final dateFormat = DateFormat('dd MMM yyyy, hh:mm a');

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with bill number and status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bill Details',
                      style: TextStyle(
                        fontFamily: 'Literata',
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.accent(context),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      bill.billNumber,
                      style: TextStyle(
                        fontFamily: 'Literata',
                        fontSize: 12,
                        color: AppTheme.grey600,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: bill.returnStatus
                      ? AppTheme.orange50
                      : AppTheme.green50,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: bill.returnStatus
                        ? AppTheme.orange200
                        : AppTheme.green200,
                  ),
                ),
                child: Text(
                  bill.returnStatus
                      ? _localizations.returnedLabel
                      : _localizations.active,
                  style: TextStyle(
                    fontFamily: 'Literata',
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: bill.returnStatus
                        ? AppTheme.orange700
                        : AppTheme.green700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),

          // Bill Date
          _buildDetailRow(
            Icons.calendar_today,
            _localizations.billDate,
            dateFormat.format(bill.billDate),
          ),

          // Customer Info
          if (bill.hasCustomerInfo) ...[
            const SizedBox(height: 12),
            _buildDetailRow(
              Icons.person,
              _localizations.customerName,
              bill.customerName ?? 'N/A',
            ),
            if (bill.customerContact != null) ...[
              const SizedBox(height: 12),
              _buildDetailRow(
                Icons.phone,
                _localizations.contact,
                bill.customerContact!,
              ),
            ],
          ],

          const SizedBox(height: 16),
          const Divider(height: 1),
          SizedBox(height: 16),

          // Items Section Header with Select All/Clear All
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _localizations.selectItemsToReturn,
                style: TextStyle(
                  fontFamily: 'Literata',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.accent(context),
                ),
              ),
              if (bill.hasReturnableItems)
                Row(
                  children: [
                    GestureDetector(
                      onTap: _selectAllItems,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.accentSoft(context, 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          _localizations.selectAll,
                          style: TextStyle(
                            fontFamily: 'Literata',
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.accent(context),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: _clearAllItems,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.border(context),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          _localizations.clear,
                          style: TextStyle(
                            fontFamily: 'Literata',
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.grey700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 12),
          ...bill.items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _buildItemRowWithQuantitySelector(item),
            ),
          ),

          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),

          // Return Summary
          if (_hasItemsToReturn) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.orange50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.orange200),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${_localizations.itemsToReturn}:',
                        style: TextStyle(
                          fontFamily: 'Literata',
                          fontSize: 13,
                          color: AppTheme.orange800,
                        ),
                      ),
                      Text(
                        '$_totalReturnQuantity ${_localizations.quantity}',
                        style: TextStyle(
                          fontFamily: 'Literata',
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.orange800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${_localizations.refundAmount}:',
                        style: TextStyle(
                          fontFamily: 'Literata',
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.orange800,
                        ),
                      ),
                      Text(
                        '₹${_totalRefundAmount.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontFamily: 'Literata',
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.orange800,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Original Bill Totals
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${_localizations.originalQuantity}:',
                style: TextStyle(
                  fontFamily: 'Literata',
                  fontSize: 13,
                  color: AppTheme.grey600,
                ),
              ),
              Text(
                '${bill.totalQuantity} items',
                style: TextStyle(
                  fontFamily: 'Literata',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
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
                  'Subtotal:',
                  style: TextStyle(
                    fontFamily: 'Literata',
                    fontSize: 13,
                    color: AppTheme.grey600,
                  ),
                ),
                Text(
                  '₹${bill.totalAmount.toStringAsFixed(2)}',
                  style: const TextStyle(fontFamily: 'Literata', fontSize: 13),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Discount (${bill.discountPercent.toStringAsFixed(1)}%):',
                  style: TextStyle(
                    fontFamily: 'Literata',
                    fontSize: 13,
                    color: AppTheme.green700,
                  ),
                ),
                Text(
                  '-₹${bill.discountAmount.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontFamily: 'Literata',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.green700,
                  ),
                ),
              ],
            ),
          ],
          SizedBox(height: 12),
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.accentSoft(context, 0.05),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Final Amount:',
                  style: TextStyle(
                    fontFamily: 'Literata',
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.accent(context),
                  ),
                ),
                Text(
                  '₹${bill.finalAmount.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontFamily: 'Literata',
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.accent(context),
                  ),
                ),
              ],
            ),
          ),

          // Return Date (if returned)
          if (bill.returnStatus && bill.returnDate != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.orange50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.orange200),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.assignment_return,
                    color: AppTheme.orange700,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _localizations.returnedOn,
                          style: TextStyle(
                            fontFamily: 'Literata',
                            fontSize: 11,
                            color: AppTheme.orange700,
                          ),
                        ),
                        Text(
                          dateFormat.format(bill.returnDate!),
                          style: TextStyle(
                            fontFamily: 'Literata',
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.orange800,
                          ),
                        ),
                      ],
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

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppTheme.grey),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            fontFamily: 'Literata',
            fontSize: 13,
            color: AppTheme.grey600,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontFamily: 'Literata',
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildItemRowWithQuantitySelector(BillItem item) {
    final double remainingQty = item.remainingQuantity;
    final double returnQty = _returnQuantities[item.id] ?? 0.0;
    final bool isFullyReturned = item.isFullyReturned;
    final bool isPartiallyReturned = item.isPartiallyReturned;

    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isFullyReturned
            ? AppColors.border(context)
            : returnQty >
                  0.001 // Tolerance for floats
            ? AppTheme.orange50
            : AppColors.scaffold(context),
        borderRadius: BorderRadius.circular(10),
        border: returnQty > 0.001
            ? Border.all(color: AppTheme.orange300, width: 1.5)
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.productName,
                            style: TextStyle(
                              fontFamily: 'Literata',
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isFullyReturned
                                  ? AppTheme.grey
                                  : AppTheme.black,
                              decoration: isFullyReturned
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                          ),
                        ),
                        if (isFullyReturned)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.grey400,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              _localizations.returnedLabel,
                              style: const TextStyle(
                                fontFamily: 'Literata',
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.white,
                              ),
                            ),
                          ),
                        if (isPartiallyReturned && !isFullyReturned)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.orange400,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '${item.returnedQuantity} ${_localizations.returnedLabel}',
                              style: const TextStyle(
                                fontFamily: 'Literata',
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.white,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // Show sold quantity and what's returnable
                    Row(
                      children: [
                        Text(
                          '₹${item.sellingPrice.toStringAsFixed(2)} × ${item.quantity} sold',
                          style: TextStyle(
                            fontFamily: 'Literata',
                            fontSize: 11,
                            color: AppTheme.grey600,
                          ),
                        ),
                        if (item.returnedQuantity > 0) ...[
                          Text(
                            ' • ',
                            style: TextStyle(
                              fontFamily: 'Literata',
                              fontSize: 11,
                              color: AppTheme.grey400,
                            ),
                          ),
                          Text(
                            '${item.returnedQuantity} returned',
                            style: TextStyle(
                              fontFamily: 'Literata',
                              fontSize: 11,
                              color: AppTheme.orange600,
                            ),
                          ),
                        ],
                        Text(
                          ' • ',
                          style: TextStyle(
                            fontFamily: 'Literata',
                            fontSize: 11,
                            color: AppTheme.grey400,
                          ),
                        ),
                        Text(
                          '$remainingQty returnable',
                          style: TextStyle(
                            fontFamily: 'Literata',
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: remainingQty > 0
                                ? AppColors.action(context)
                                : AppTheme.grey,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Text(
                '₹${item.subtotal.toStringAsFixed(2)}',
                style: TextStyle(
                  fontFamily: 'Literata',
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: isFullyReturned
                      ? AppTheme.grey400
                      : AppColors.action(context),
                ),
              ),
            ],
          ),
          if (!isFullyReturned) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Text(
                  'Return Qty:',
                  style: TextStyle(
                    fontFamily: 'Literata',
                    fontSize: 12,
                    color: AppTheme.grey700,
                  ),
                ),
                SizedBox(width: 12),
                // Decrease button
                GestureDetector(
                  onTap: returnQty > 0
                      ? () => _updateReturnQuantity(item.id, returnQty - 1)
                      : null,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: returnQty > 0
                          ? AppTheme.orange100
                          : AppColors.border(context),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.remove,
                      size: 18,
                      color: returnQty > 0
                          ? AppTheme.orange700
                          : AppTheme.grey400,
                    ),
                  ),
                ),
                // Quantity display
                Container(
                  width: 50,
                  alignment: Alignment.center,
                  child: Text(
                    '$returnQty',
                    style: TextStyle(
                      fontFamily: 'Literata',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: returnQty > 0
                          ? AppTheme.orange700
                          : AppTheme.grey600,
                    ),
                  ),
                ),
                // Increase button
                GestureDetector(
                  onTap: returnQty < remainingQty
                      ? () => _updateReturnQuantity(item.id, returnQty + 1)
                      : null,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: returnQty < remainingQty
                          ? AppTheme.orange100
                          : AppColors.border(context),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.add,
                      size: 18,
                      color: returnQty < remainingQty
                          ? AppTheme.orange700
                          : AppTheme.grey400,
                    ),
                  ),
                ),
                const Spacer(),
                // Quick action: Return all
                if (remainingQty > 0)
                  GestureDetector(
                    onTap: () => _updateReturnQuantity(item.id, remainingQty),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.orange100,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'All ($remainingQty)',
                        style: TextStyle(
                          fontFamily: 'Literata',
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.orange700,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            if (returnQty > 0) ...[
              const SizedBox(height: 8),
              Text(
                '${_localizations.refund}: ₹${(item.sellingPrice * returnQty).toStringAsFixed(2)}',
                style: TextStyle(
                  fontFamily: 'Literata',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.orange700,
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildReturnButton() {
    final bill = _currentBill!;

    // Check if all items are fully returned
    if (bill.isFullyReturned) {
      return Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.chipFill(context),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.info_outline, color: AppTheme.grey600, size: 20),
            const SizedBox(width: 8),
            Text(
              _localizations.allItemsReturned,
              style: TextStyle(
                fontFamily: 'Literata',
                fontSize: 14,
                color: AppTheme.grey600,
              ),
            ),
          ],
        ),
      );
    }

    // Check if no items selected
    if (!_hasItemsToReturn) {
      return Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.chipFill(context),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.touch_app_outlined, color: AppTheme.grey600, size: 20),
            const SizedBox(width: 8),
            Text(
              _localizations.selectItemsToReturn,
              style: TextStyle(
                fontFamily: 'Literata',
                fontSize: 14,
                color: AppTheme.grey600,
              ),
            ),
          ],
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isProcessing ? null : _showReturnConfirmationDialog,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.orange600,
          foregroundColor: AppTheme.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          disabledBackgroundColor: AppTheme.orange300,
        ),
        child: _isProcessing
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(AppTheme.white),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _localizations.processingReturn,
                    style: const TextStyle(
                      fontFamily: 'Literata',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.assignment_return, size: 22),
                  const SizedBox(width: 10),
                  Text(
                    _localizations.processReturn,
                    style: const TextStyle(
                      fontFamily: 'Literata',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

// Confirmation Dialog for Return Bill
class _ReturnConfirmationDialog extends StatelessWidget {
  final Bill bill;
  final Map<String, double> returnQuantities; // Changed to double
  final double totalRefundAmount;

  const _ReturnConfirmationDialog({
    required this.bill,
    required this.returnQuantities,
    required this.totalRefundAmount,
  });

  AppLocalizations get _localizations =>
      AppLocalizations(LanguageService.instance.currentLanguage);

  double get _totalReturnQuantity {
    return returnQuantities.values.fold(0.0, (total, qty) => total + qty);
  }

  List<MapEntry<String, double>> get _itemsToReturn {
    return returnQuantities.entries.where((e) => e.value > 0.001).toList();
  }

  @override
  Widget build(BuildContext context) {
    final itemsToReturnList = bill.items.where((item) {
      final qty = returnQuantities[item.id] ?? 0.0;
      return qty > 0.001;
    }).toList();

    return AlertDialog(
      backgroundColor: AppColors.card(context),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.orange50,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.warning_amber_rounded,
              color: AppTheme.orange700,
              size: 24,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              _localizations.confirmReturn,
              style: TextStyle(
                fontFamily: 'Literata',
                fontWeight: FontWeight.w700,
                color: AppColors.accent(context),
                fontSize: 18,
              ),
            ),
          ),
        ],
      ),
      content: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.5,
          maxWidth: MediaQuery.of(context).size.width * 0.9,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _localizations.confirmReturnMessage,
                style: TextStyle(
                  fontFamily: 'Literata',
                  fontSize: 14,
                  color: AppTheme.grey700,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.scaffold(context),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            '${_localizations.billNo}:',
                            style: TextStyle(
                              fontFamily: 'Literata',
                              fontSize: 12,
                              color: AppTheme.grey600,
                            ),
                          ),
                        ),
                        Flexible(
                          child: Text(
                            bill.billNumber,
                            style: const TextStyle(
                              fontFamily: 'Literata',
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Divider(height: 1),
                    const SizedBox(height: 8),
                    // List of items being returned
                    ...itemsToReturnList.map((item) {
                      final qty = returnQuantities[item.id] ?? 0.0;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: Text(
                                item.productName,
                                style: const TextStyle(
                                  fontFamily: 'Literata',
                                  fontSize: 11,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '×$qty',
                              style: TextStyle(
                                fontFamily: 'Literata',
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.orange700,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '₹${(item.sellingPrice * qty).toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontFamily: 'Literata',
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                    const SizedBox(height: 8),
                    const Divider(height: 1),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            '${_localizations.itemsToReturn}:',
                            style: TextStyle(
                              fontFamily: 'Literata',
                              fontSize: 12,
                              color: AppTheme.grey600,
                            ),
                          ),
                        ),
                        Flexible(
                          child: Text(
                            '${_itemsToReturn.length} items ($_totalReturnQuantity qty)',
                            style: const TextStyle(
                              fontFamily: 'Literata',
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            '${_localizations.refundAmount}:',
                            style: TextStyle(
                              fontFamily: 'Literata',
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.orange700,
                            ),
                          ),
                        ),
                        Flexible(
                          child: Text(
                            '₹${totalRefundAmount.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontFamily: 'Literata',
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.orange700,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.blue50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.blue200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: AppTheme.blue700, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _localizations.restoreToInventory,
                        style: TextStyle(
                          fontFamily: 'Literata',
                          fontSize: 11,
                          color: AppTheme.blue700,
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
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(
            _localizations.cancel,
            style: TextStyle(fontFamily: 'Literata', color: AppTheme.grey600),
          ),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.orange600,
            foregroundColor: AppTheme.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: Text(
            _localizations.confirmReturn,
            style: const TextStyle(
              fontFamily: 'Literata',
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:c_billing/core/services/billing_service.dart';
import 'package:c_billing/core/printing/printing.dart';
import 'package:c_billing/features/billing/data/repositories/firebase_bill_repository.dart';
import 'package:c_billing/features/billing/domain/entities/bill.dart';
import 'package:c_billing/features/inventory_management/data/repositories/firebase_product_repository.dart';
import 'package:c_billing/features/inventory_management/data/repositories/firebase_stock_repository.dart';
import 'package:c_billing/features/shop/data/repositories/shop_repository.dart';
import 'package:c_billing/common_widgets/printer_selection_widget.dart';
import 'package:c_billing/features/billing/offline/controllers/bill_offline_controller.dart';
import 'package:c_billing/core/services/inventory_integration_service.dart';

/// Return Bill Page for processing bill returns
/// Allows searching by bill number or customer mobile and processing returns
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

  // Track return quantities for each item (itemId -> quantity to return)
  Map<String, int> _returnQuantities = {};

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
      _returnQuantities[item.id] = 0;
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  /// Get total quantity selected for return
  int get _totalReturnQuantity {
    return _returnQuantities.values.fold(0, (sum, qty) => sum + qty);
  }

  /// Get total refund amount based on selected quantities
  double get _totalRefundAmount {
    if (_currentBill == null) return 0.0;
    double total = 0.0;
    for (final item in _currentBill!.items) {
      final returnQty = _returnQuantities[item.id] ?? 0;
      total += item.sellingPrice * returnQty;
    }
    return total;
  }

  /// Check if any items are selected for return
  bool get _hasItemsToReturn => _totalReturnQuantity > 0;

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
            _errorMessage = 'Bill not found';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSearching = false;
          _errorMessage = 'Error searching bill: $e';
        });
      }
    }
  }

  void _updateReturnQuantity(String itemId, int quantity) {
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
        _returnQuantities[item.id] = 0;
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

  Future<void> _processReturn() async {
    if (_currentBill == null || !_hasItemsToReturn) return;

    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    try {
      // Process return via old BillingService (Firebase transactions for stock/bill updates)
      final result = await _billingService.processReturn(
        billId: _currentBill!.id,
        returnItems: _returnQuantities,
      );

      // Also process via FIFO Integration (restore batches + ledger entries + local stock)
      if (result.success) {
        try {
          final returnItemDetails = <ReturnItemDetail>[];
          for (final item in _currentBill!.items) {
            final returnQty = _returnQuantities[item.id] ?? 0;
            if (returnQty > 0) {
              returnItemDetails.add(ReturnItemDetail(
                productId: item.productId,
                productName: item.productName,
                returnQuantity: returnQty,
                costPrice: item.purchasePrice,
                sellingPrice: item.sellingPrice,
                batchId: 'BILL_${_currentBill!.id}_${item.productId}',
              ));
            }
          }

          if (returnItemDetails.isNotEmpty) {
            // Find the local bill ID for updating the local entity
            final localBills = await BillOfflineController.instance.getAllBills();
            final localBill = localBills.firstWhere(
              (b) => b.serverId == _currentBill!.id,
              orElse: () => localBills.first,
            );

            await InventoryIntegrationService.instance.processReturn(
              billId: _currentBill!.id,
              billLocalId: localBill.id,
              returnItems: returnItemDetails,
              notes: 'Return for bill: ${_currentBill!.billNumber}',
            );
            debugPrint('[ReturnBill] FIFO return processed successfully');
          }
        } catch (e) {
          debugPrint('[ReturnBill] FIFO return processing failed (Firebase return succeeded): $e');
          // Don't fail the whole return - Firebase already processed it
        }
      }

      if (mounted) {
        if (result.success) {
          final refundAmount = result.refundAmount ?? _totalRefundAmount;
          setState(() {
            _isProcessing = false;
            _successMessage =
                'Return processed successfully! Refund: ₹${refundAmount.toStringAsFixed(2)}';

            // Update local bill state
            final updatedItems = _currentBill!.items.map((item) {
              final returnQty = _returnQuantities[item.id] ?? 0;
              return item.copyWith(
                returnedQuantity: item.returnedQuantity + returnQty,
              );
            }).toList();

            _currentBill = _currentBill!.copyWith(
              items: updatedItems,
              returnStatus: updatedItems.every((item) => item.isFullyReturned),
              returnDate: DateTime.now(),
            );

            // Reset return quantities
            _initializeReturnQuantities(_currentBill!);
          });

          // Show success snackbar
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text('Return processed! Print or share the receipt before leaving.'),
                  ),
                ],
              ),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 4),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        } else {
          setState(() {
            _isProcessing = false;
            _errorMessage = result.errorMessage ?? 'Failed to process return';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _errorMessage = 'Error processing return: $e';
        });
      }
    }
  }

  /// Create PrintBillData with proper return bill context
  PrintBillData _createReturnPrintData() {
    final bill = _currentBill!;
    final hasReturns = bill.hasAnyReturns;
    return PrintBillData.fromBill(
      bill,
      isReturn: hasReturns,
      refund: hasReturns ? bill.totalReturnedAmount : null,
    );
  }

  /// Handle printing the bill
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

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  result.success ? Icons.check_circle : Icons.error_outline,
                  color: Colors.white,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    result.message ??
                        (result.success
                            ? 'Bill printed successfully!'
                            : 'Failed to print bill'),
                  ),
                ),
              ],
            ),
            backgroundColor: result.success ? Colors.green : Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isPrinting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text('Print error: $e')),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }

  /// Handle sharing the bill as PDF
  Future<void> _handleShareBill() async {
    if (_currentBill == null) return;

    bool loadingDialogShowing = false;
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        ),
      );
      loadingDialogShowing = true;

      final shop = await _shopRepository.getShopDetails();
      final printData = _createReturnPrintData();

      // Close loading indicator
      if (mounted && loadingDialogShowing) {
        Navigator.pop(context);
        loadingDialogShowing = false;
      }

      await _pdfService.shareBillAsPdf(
        billData: printData,
        shopDetails: shop,
      );
    } catch (e) {
      // Close loading indicator only if still showing
      if (mounted && loadingDialogShowing) {
        Navigator.pop(context);
        loadingDialogShowing = false;
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text('Share error: $e')),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),
      appBar: _buildAppBar(),
      body: FadeTransition(
        opacity: _opacityAnimation,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Search Section
              if (widget.initialBill == null) _buildSearchSection(),

              // Error Message
              if (_errorMessage != null) _buildErrorMessage(),

              // Success Message
              if (_successMessage != null) _buildSuccessMessage(),

              // Bill Details
              if (_currentBill != null) ...[
                const SizedBox(height: 16),
                _buildBillDetails(),
                const SizedBox(height: 24),
                _buildReturnButton(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return PreferredSize(
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
                        'Return Bill',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Literata',
                          height: 1.2,
                        ),
                      ),
                      Text(
                        'Process bill returns',
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
                // Share & Print buttons - only show when bill is loaded
                if (_currentBill != null) ...[
                  // Share button
                  GestureDetector(
                    onTap: _handleShareBill,
                    child: Container(
                      width: 40,
                      height: 40,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.share_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                  // Print button
                  GestureDetector(
                    onTap: _isPrinting ? null : _handlePrintBill,
                    child: Container(
                      width: 40,
                      height: 40,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: _isPrinting
                          ? const Center(
                              child: SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              ),
                            )
                          : const Icon(
                              Icons.print_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                    ),
                  ),
                ],
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.assignment_return,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
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
            const Text(
              'Search Bill',
              style: TextStyle(
                fontFamily: 'Literata',
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1B4D3E),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Enter Bill Number or Customer Mobile Number',
              style: TextStyle(
                fontFamily: 'Literata',
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'e.g., BILL-20260205-ABC123 or 9876543210',
                hintStyle: TextStyle(
                  fontFamily: 'Literata',
                  fontSize: 13,
                  color: Colors.grey[400],
                ),
                prefixIcon: const Icon(
                  Icons.search,
                  color: Color(0xFF1B4D3E),
                  size: 20,
                ),
                filled: true,
                fillColor: const Color(0xFFF5F6F8),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color(0xFF1B4D3E),
                    width: 1.5,
                  ),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.red, width: 1.5),
                ),
              ),
              style: const TextStyle(fontFamily: 'Literata', fontSize: 14),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a bill number or mobile number';
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
                  backgroundColor: const Color(0xFF1B4D3E),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  disabledBackgroundColor: const Color(
                    0xFF1B4D3E,
                  ).withOpacity(0.5),
                ),
                child: _isSearching
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.search, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Search & Validate',
                            style: TextStyle(
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
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red[200]!),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red[700], size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _errorMessage!,
              style: TextStyle(
                fontFamily: 'Literata',
                fontSize: 13,
                color: Colors.red[700],
              ),
            ),
          ),
          GestureDetector(
            onTap: () => setState(() => _errorMessage = null),
            child: Icon(Icons.close, color: Colors.red[700], size: 18),
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
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green[200]!),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle_outline, color: Colors.green[700], size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _successMessage!,
              style: TextStyle(
                fontFamily: 'Literata',
                fontSize: 13,
                color: Colors.green[700],
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
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
                    const Text(
                      'Bill Details',
                      style: TextStyle(
                        fontFamily: 'Literata',
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1B4D3E),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      bill.billNumber,
                      style: TextStyle(
                        fontFamily: 'Literata',
                        fontSize: 12,
                        color: Colors.grey[600],
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
                      ? Colors.orange[50]
                      : Colors.green[50],
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: bill.returnStatus
                        ? Colors.orange[200]!
                        : Colors.green[200]!,
                  ),
                ),
                child: Text(
                  bill.returnStatus ? 'Returned' : 'Active',
                  style: TextStyle(
                    fontFamily: 'Literata',
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: bill.returnStatus
                        ? Colors.orange[700]
                        : Colors.green[700],
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
            'Bill Date',
            dateFormat.format(bill.billDate),
          ),

          // Customer Info
          if (bill.hasCustomerInfo) ...[
            const SizedBox(height: 12),
            _buildDetailRow(
              Icons.person,
              'Customer',
              bill.customerName ?? 'N/A',
            ),
            if (bill.customerContact != null) ...[
              const SizedBox(height: 12),
              _buildDetailRow(Icons.phone, 'Contact', bill.customerContact!),
            ],
          ],

          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),

          // Items Section Header with Select All/Clear All
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Select Items to Return',
                style: TextStyle(
                  fontFamily: 'Literata',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1B4D3E),
                ),
              ),
              if (bill.hasReturnableItems)
                Row(
                  children: [
                    GestureDetector(
                      onTap: _selectAllItems,
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
                          'Select All',
                          style: TextStyle(
                            fontFamily: 'Literata',
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1B4D3E),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: _clearAllItems,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Clear',
                          style: TextStyle(
                            fontFamily: 'Literata',
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[700],
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
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.orange[200]!),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Items to Return:',
                        style: TextStyle(
                          fontFamily: 'Literata',
                          fontSize: 13,
                          color: Colors.orange[800],
                        ),
                      ),
                      Text(
                        '$_totalReturnQuantity qty',
                        style: TextStyle(
                          fontFamily: 'Literata',
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.orange[800],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Refund Amount:',
                        style: TextStyle(
                          fontFamily: 'Literata',
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.orange[800],
                        ),
                      ),
                      Text(
                        '₹${_totalRefundAmount.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontFamily: 'Literata',
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Colors.orange[800],
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
                'Original Quantity:',
                style: TextStyle(
                  fontFamily: 'Literata',
                  fontSize: 13,
                  color: Colors.grey[600],
                ),
              ),
              Text(
                '${bill.totalQuantity} items',
                style: const TextStyle(
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
                    color: Colors.grey[600],
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
                    color: Colors.green[700],
                  ),
                ),
                Text(
                  '-₹${bill.discountAmount.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontFamily: 'Literata',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.green[700],
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF1B4D3E).withOpacity(0.05),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Final Amount:',
                  style: TextStyle(
                    fontFamily: 'Literata',
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1B4D3E),
                  ),
                ),
                Text(
                  '₹${bill.finalAmount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontFamily: 'Literata',
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1B4D3E),
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
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.orange[200]!),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.assignment_return,
                    color: Colors.orange[700],
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Returned on',
                          style: TextStyle(
                            fontFamily: 'Literata',
                            fontSize: 11,
                            color: Colors.orange[700],
                          ),
                        ),
                        Text(
                          dateFormat.format(bill.returnDate!),
                          style: TextStyle(
                            fontFamily: 'Literata',
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.orange[800],
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
        Icon(icon, size: 18, color: Colors.grey[500]),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            fontFamily: 'Literata',
            fontSize: 13,
            color: Colors.grey[600],
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

  Widget _buildItemRowWithQuantitySelector(item) {
    final int remainingQty = item.remainingQuantity;
    final int returnQty = _returnQuantities[item.id] ?? 0;
    final bool isFullyReturned = item.isFullyReturned;
    final bool isPartiallyReturned = item.isPartiallyReturned;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isFullyReturned
            ? Colors.grey[200]
            : returnQty > 0
            ? Colors.orange[50]
            : const Color(0xFFF5F6F8),
        borderRadius: BorderRadius.circular(10),
        border: returnQty > 0
            ? Border.all(color: Colors.orange[300]!, width: 1.5)
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
                                  ? Colors.grey[500]
                                  : Colors.black,
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
                              color: Colors.grey[400],
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'Returned',
                              style: TextStyle(
                                fontFamily: 'Literata',
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
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
                              color: Colors.orange[400],
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '${item.returnedQuantity} returned',
                              style: const TextStyle(
                                fontFamily: 'Literata',
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '₹${item.sellingPrice.toStringAsFixed(2)} × ${item.quantity} qty (${remainingQty} available)',
                      style: TextStyle(
                        fontFamily: 'Literata',
                        fontSize: 11,
                        color: Colors.grey[600],
                      ),
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
                      ? Colors.grey[400]
                      : const Color(0xFF1B4D3E),
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
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(width: 12),
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
                          ? Colors.orange[100]
                          : Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.remove,
                      size: 18,
                      color: returnQty > 0
                          ? Colors.orange[700]
                          : Colors.grey[400],
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
                          ? Colors.orange[700]
                          : Colors.grey[600],
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
                          ? Colors.orange[100]
                          : Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.add,
                      size: 18,
                      color: returnQty < remainingQty
                          ? Colors.orange[700]
                          : Colors.grey[400],
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
                        color: Colors.orange[100],
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'All ($remainingQty)',
                        style: TextStyle(
                          fontFamily: 'Literata',
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Colors.orange[700],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            if (returnQty > 0) ...[
              const SizedBox(height: 8),
              Text(
                'Refund: ₹${(item.sellingPrice * returnQty).toStringAsFixed(2)}',
                style: TextStyle(
                  fontFamily: 'Literata',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.orange[700],
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
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.info_outline, color: Colors.grey[600], size: 20),
            const SizedBox(width: 8),
            Text(
              'All items have been returned',
              style: TextStyle(
                fontFamily: 'Literata',
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    // Check if no items selected
    if (!_hasItemsToReturn) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.touch_app_outlined, color: Colors.grey[600], size: 20),
            const SizedBox(width: 8),
            Text(
              'Select items to return',
              style: TextStyle(
                fontFamily: 'Literata',
                fontSize: 14,
                color: Colors.grey[600],
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
          backgroundColor: Colors.orange[600],
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          disabledBackgroundColor: Colors.orange[300],
        ),
        child: _isProcessing
            ? const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  SizedBox(width: 12),
                  Text(
                    'Processing Return...',
                    style: TextStyle(
                      fontFamily: 'Literata',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.assignment_return, size: 22),
                  SizedBox(width: 10),
                  Text(
                    'Process Return',
                    style: TextStyle(
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

/// Confirmation Dialog for Return Bill
class _ReturnConfirmationDialog extends StatelessWidget {
  final Bill bill;
  final Map<String, int> returnQuantities;
  final double totalRefundAmount;

  const _ReturnConfirmationDialog({
    required this.bill,
    required this.returnQuantities,
    required this.totalRefundAmount,
  });

  int get _totalReturnQuantity {
    return returnQuantities.values.fold(0, (sum, qty) => sum + qty);
  }

  List<MapEntry<String, int>> get _itemsToReturn {
    return returnQuantities.entries.where((e) => e.value > 0).toList();
  }

  @override
  Widget build(BuildContext context) {
    final itemsToReturnList = bill.items.where((item) {
      final qty = returnQuantities[item.id] ?? 0;
      return qty > 0;
    }).toList();

    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.orange[50],
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.warning_amber_rounded,
              color: Colors.orange[700],
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Confirm Return',
              style: TextStyle(
                fontFamily: 'Literata',
                fontWeight: FontWeight.w700,
                color: Color(0xFF1B4D3E),
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
                'Are you sure you want to return the selected items?',
                style: TextStyle(
                  fontFamily: 'Literata',
                  fontSize: 14,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F6F8),
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
                            'Bill Number:',
                            style: TextStyle(
                              fontFamily: 'Literata',
                              fontSize: 12,
                              color: Colors.grey[600],
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
                    // List of items being returned - constrained height
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 150),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: itemsToReturnList.length,
                        itemBuilder: (context, index) {
                          final item = itemsToReturnList[index];
                          final qty = returnQuantities[item.id] ?? 0;
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
                                    color: Colors.orange[700],
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
                        },
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Divider(height: 1),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            'Items to return:',
                            style: TextStyle(
                              fontFamily: 'Literata',
                              fontSize: 12,
                              color: Colors.grey[600],
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
                            'Refund Amount:',
                            style: TextStyle(
                              fontFamily: 'Literata',
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.orange[700],
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
                              color: Colors.orange[700],
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
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue[700], size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'This will restore the items back to inventory.',
                        style: TextStyle(
                          fontFamily: 'Literata',
                          fontSize: 11,
                          color: Colors.blue[700],
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
            'Cancel',
            style: TextStyle(fontFamily: 'Literata', color: Colors.grey[600]),
          ),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange[600],
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: const Text(
            'Confirm Return',
            style: TextStyle(
              fontFamily: 'Literata',
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

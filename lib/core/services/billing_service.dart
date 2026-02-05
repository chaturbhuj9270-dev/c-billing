import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:c_billing/features/billing/domain/entities/bill.dart';
import 'package:c_billing/features/billing/domain/entities/bill_item.dart';
import 'package:c_billing/features/billing/data/repositories/firebase_bill_repository.dart';
import 'package:c_billing/features/inventory_management/domain/entities/product.dart';
import 'package:c_billing/features/inventory_management/domain/entities/stock.dart';
import 'package:c_billing/features/inventory_management/domain/repositories/product_repository.dart';
import 'package:c_billing/features/inventory_management/domain/repositories/stock_repository.dart';

/// Result class for billing operations
class BillingResult {
  final bool success;
  final String? billId;
  final String? errorMessage;
  final List<String>? failedProducts;

  BillingResult({
    required this.success,
    this.billId,
    this.errorMessage,
    this.failedProducts,
  });

  factory BillingResult.success(String billId) {
    return BillingResult(success: true, billId: billId);
  }

  factory BillingResult.failure(
    String message, {
    List<String>? failedProducts,
  }) {
    return BillingResult(
      success: false,
      errorMessage: message,
      failedProducts: failedProducts,
    );
  }
}

/// Result class for return bill operations
class ReturnBillResult {
  final bool success;
  final String? billId;
  final String? errorMessage;
  final Bill? bill;

  ReturnBillResult({
    required this.success,
    this.billId,
    this.errorMessage,
    this.bill,
  });

  factory ReturnBillResult.success(String billId, {Bill? bill}) {
    return ReturnBillResult(success: true, billId: billId, bill: bill);
  }

  factory ReturnBillResult.failure(String message) {
    return ReturnBillResult(success: false, errorMessage: message);
  }

  factory ReturnBillResult.notFound() {
    return ReturnBillResult(success: false, errorMessage: 'Bill not found');
  }

  factory ReturnBillResult.alreadyReturned() {
    return ReturnBillResult(
      success: false,
      errorMessage: 'This bill has already been returned',
    );
  }
}

/// Service class for handling billing operations with transaction support
class BillingService {
  final FirebaseBillRepository _billRepository;
  final ProductRepository _productRepository;
  final StockRepository _stockRepository;

  BillingService({
    required FirebaseBillRepository billRepository,
    required ProductRepository productRepository,
    required StockRepository stockRepository,
  }) : _billRepository = billRepository,
       _productRepository = productRepository,
       _stockRepository = stockRepository;

  /// Calculate subtotal for a bill item
  double calculateSubtotal(double sellingPrice, int quantity) {
    return sellingPrice * quantity;
  }

  /// Calculate total quantity from bill items
  int calculateTotalQuantity(List<BillItem> items) {
    return items.fold(0, (sum, item) => sum + item.quantity);
  }

  /// Calculate total amount from bill items
  double calculateTotalAmount(List<BillItem> items) {
    return items.fold(0.0, (sum, item) => sum + item.subtotal);
  }

  /// Validate stock availability for all items
  Future<Map<String, String>> validateStock(List<BillItem> items) async {
    final errors = <String, String>{};

    // Optimization: Parallelize stock checks to avoid sequential network calls
    final productFutures = items.map(
      (item) => _productRepository.getProductById(item.productId),
    );
    final products = await Future.wait(productFutures);

    for (int i = 0; i < items.length; i++) {
      final item = items[i];
      final product = products[i];

      if (product == null) {
        errors[item.productId] = 'Product "${item.productName}" not found';
        continue;
      }

      if (product.currentStock < item.quantity) {
        errors[item.productId] =
            '${item.productName}: Insufficient stock. Available: ${product.currentStock}, Requested: ${item.quantity}';
      }
    }

    return errors;
  }

  /// Get current stock for a product
  Future<int> getProductStock(String productId) async {
    final product = await _productRepository.getProductById(productId);
    return product?.currentStock ?? 0;
  }

  /// Create a bill item from a product
  BillItem createBillItem({
    required Product product,
    required int quantity,
    double? customPrice,
  }) {
    final sellingPrice = customPrice ?? product.salesPrice;
    return BillItem.create(
      productId: product.id,
      productName: product.name,
      sellingPrice: sellingPrice,
      quantity: quantity,
    );
  }

  /// Process and save a bill with transaction support
  /// This method ensures that either all operations succeed or all are rolled back
  Future<BillingResult> processBill({
    required List<BillItem> items,
    String? customerId,
    String? customerName,
    String? customerContact,
    String? notes,
    double discountAmount = 0.0,
    double discountPercent = 0.0,
  }) async {
    // Validate that there are items
    if (items.isEmpty) {
      return BillingResult.failure('Cannot create a bill with no items');
    }

    // Use Firestore transaction to ensure atomicity
    try {
      final firestore = _billRepository.firestore;
      final userId = _billRepository.userId;

      final result = await firestore.runTransaction<String>((
        transaction,
      ) async {
        // Step 1: Verify and get current stock and purchase price for all products in parallel
        final productStocks = <String, int>{};
        final productPurchasePrices = <String, double>{};
        final productRefsMap = <String, DocumentReference>{};

        // Get unique product IDs to avoid redundant fetches
        final uniqueProductIds = items.map((e) => e.productId).toSet().toList();

        final productDocFutures = uniqueProductIds.map((productId) {
          final ref = firestore
              .collection('users')
              .doc(userId)
              .collection('products')
              .doc(productId);
          productRefsMap[productId] = ref;
          return transaction.get(ref);
        }).toList();

        final productSnapshots = await Future.wait(productDocFutures);
        final productDocsMap = Map.fromIterables(
          uniqueProductIds,
          productSnapshots,
        );

        for (final item in items) {
          final productDoc = productDocsMap[item.productId]!;

          if (!productDoc.exists) {
            throw Exception('Product ${item.productName} not found');
          }

          final data = productDoc.data() as Map<String, dynamic>?;
          final currentStock = (data?['currentStock'] ?? 0) as int;
          final purchasePrice = ((data?['purchasePrice'] ?? 0) as num)
              .toDouble();

          if (currentStock < item.quantity) {
            throw Exception(
              '${item.productName}: Insufficient stock. Available: $currentStock, Requested: ${item.quantity}',
            );
          }

          // Use the latest data for all items of this product
          productStocks[item.productId] = currentStock;
          productPurchasePrices[item.productId] = purchasePrice;
        }

        // Step 2: Create the bill document
        final now = DateTime.now();
        final billRef = firestore
            .collection('users')
            .doc(userId)
            .collection('bills')
            .doc();

        final totalQuantity = calculateTotalQuantity(items);
        final totalAmount = calculateTotalAmount(items);

        // Calculate final amount after discount
        final finalAmount = totalAmount - discountAmount;

        // Update items with the bill ID and purchase price for profit tracking
        final updatedItems = items
            .map(
              (item) => item.copyWith(
                id: '${billRef.id}_${item.productId}',
                billId: billRef.id,
                purchasePrice: productPurchasePrices[item.productId] ?? 0.0,
              ),
            )
            .toList();

        final bill = Bill(
          id: billRef.id,
          customerId: customerId,
          customerName: customerName,
          customerContact: customerContact,
          items: updatedItems,
          totalQuantity: totalQuantity,
          totalAmount: totalAmount,
          discountAmount: discountAmount,
          discountPercent: discountPercent,
          finalAmount: finalAmount,
          billDate: now,
          createdAt: now,
          updatedAt: now,
          notes: notes,
        );

        transaction.set(billRef, bill.toJson());

        // Step 3: Update stock for each product and create stock entries
        // Track new balances for products that might appear multiple times in the bill
        final productNewBalances = Map<String, int>.from(productStocks);

        for (final item in items) {
          final currentBalance = productNewBalances[item.productId]!;
          final newStock = currentBalance - item.quantity;
          productNewBalances[item.productId] = newStock;

          // Update product stock with the final accumulated new balance
          // Note: We'll set the update call outside this loop per unique product to be more efficient
        }

        // Apply product updates once per unique product
        for (final productId in uniqueProductIds) {
          final newStock = productNewBalances[productId]!;
          final productRef = productRefsMap[productId]!;

          transaction.update(productRef, {
            'currentStock': newStock,
            'updatedAt': now.toIso8601String(),
          });
        }

        // Still need individual stock entries for each line item (or summarized per bill)
        // Usually stock history is per line item or per bill. Keeping it per line item as before.
        for (final item in items) {
          final stockRef = firestore
              .collection('users')
              .doc(userId)
              .collection('stock')
              .doc();

          final stockEntry = Stock(
            id: stockRef.id,
            productId: item.productId,
            quantityIn: 0,
            quantityOut: item.quantity,
            balanceQuantity:
                productNewBalances[item
                    .productId]!, // Note: this is the overall balance after all items
            referenceType: ReferenceType.SALE,
            referenceId: billRef.id,
            createdAt: now,
          );

          transaction.set(stockRef, stockEntry.toJson());
        }

        return billRef.id;
      });

      return BillingResult.success(result);
    } catch (e) {
      print('[ERROR] Failed to process bill: $e');
      return BillingResult.failure('Failed to process bill: ${e.toString()}');
    }
  }

  /// Get all products for selection
  Future<List<Product>> getAllProducts() async {
    return await _productRepository.getAllProducts();
  }

  /// Get products with available stock
  Future<List<Product>> getAvailableProducts() async {
    final products = await _productRepository.getAllProducts();
    return products.where((p) => p.currentStock > 0).toList();
  }

  /// Get all bills
  Future<List<Bill>> getAllBills() async {
    return await _billRepository.getAllBills();
  }

  /// Get today's bills
  Future<List<Bill>> getTodaysBills() async {
    return await _billRepository.getTodaysBills();
  }

  /// Get bill by ID
  Future<Bill?> getBillById(String billId) async {
    return await _billRepository.getBillById(billId);
  }

  /// Get bills by date range
  Future<List<Bill>> getBillsByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    return await _billRepository.getBillsByDateRange(startDate, endDate);
  }

  /// Search bills
  Future<List<Bill>> searchBills(String query) async {
    return await _billRepository.searchBills(query);
  }

  /// Get total sales amount
  Future<double> getTotalSalesAmount({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    return await _billRepository.getTotalSalesAmount(
      startDate: startDate,
      endDate: endDate,
    );
  }

  /// Get total bills count
  Future<int> getTotalBillsCount({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    return await _billRepository.getTotalBillsCount(
      startDate: startDate,
      endDate: endDate,
    );
  }

  /// Get daily sales summary
  Future<Map<String, dynamic>> getDailySalesSummary() async {
    final todaysBills = await getTodaysBills();
    final totalAmount = todaysBills.fold(
      0.0,
      (sum, bill) => sum + bill.totalAmount,
    );
    final totalItems = todaysBills.fold(
      0,
      (sum, bill) => sum + bill.totalQuantity,
    );

    return {
      'billCount': todaysBills.length,
      'totalAmount': totalAmount,
      'totalItems': totalItems,
      'bills': todaysBills,
    };
  }

  /// Get stock history for a product
  Future<List<Stock>> getProductStockHistory(String productId) async {
    return await _stockRepository.getStockByProductId(productId);
  }

  /// Get current stock balance for a product from stock repository
  Future<int> getStockBalance(String productId) async {
    return await _stockRepository.getCurrentBalance(productId);
  }

  /// Validate if a bill can be returned
  /// Returns the bill if valid, or a failure result
  Future<ReturnBillResult> validateBillForReturn(String billId) async {
    try {
      final bill = await _billRepository.getBillById(billId);

      if (bill == null) {
        return ReturnBillResult.notFound();
      }

      if (bill.returnStatus) {
        return ReturnBillResult.alreadyReturned();
      }

      return ReturnBillResult.success(billId, bill: bill);
    } catch (e) {
      print('[ERROR] Failed to validate bill for return: $e');
      return ReturnBillResult.failure(
        'Failed to validate bill: ${e.toString()}',
      );
    }
  }

  /// Search for a bill by bill number or customer mobile for return
  Future<ReturnBillResult> searchBillForReturn(String query) async {
    try {
      final bills = await _billRepository.searchBills(query);

      if (bills.isEmpty) {
        return ReturnBillResult.notFound();
      }

      // Find exact match first (by bill ID)
      final exactMatch = bills
          .where(
            (b) =>
                b.id.toLowerCase() == query.toLowerCase() ||
                b.billNumber.toLowerCase() == query.toLowerCase(),
          )
          .toList();

      if (exactMatch.isNotEmpty) {
        final bill = exactMatch.first;
        if (bill.returnStatus) {
          return ReturnBillResult.alreadyReturned();
        }
        return ReturnBillResult.success(bill.id, bill: bill);
      }

      // If no exact match, check if any bill in results hasn't been returned
      final unreturned = bills.where((b) => !b.returnStatus).toList();
      if (unreturned.isEmpty) {
        return ReturnBillResult.alreadyReturned();
      }

      // Return the first unreturned bill (most recent due to ordering)
      final bill = unreturned.first;
      return ReturnBillResult.success(bill.id, bill: bill);
    } catch (e) {
      print('[ERROR] Failed to search bill for return: $e');
      return ReturnBillResult.failure('Failed to search bill: ${e.toString()}');
    }
  }

  /// Process a bill return with atomic transaction
  /// This method ensures inventory is updated and bill is marked as returned atomically
  Future<ReturnBillResult> processReturn({required String billId}) async {
    try {
      final firestore = _billRepository.firestore;
      final userId = _billRepository.userId;

      final result = await firestore.runTransaction<Map<String, dynamic>>((
        transaction,
      ) async {
        // Step 1: Get the bill and verify it's not already returned
        final billRef = firestore
            .collection('users')
            .doc(userId)
            .collection('bills')
            .doc(billId);

        final billDoc = await transaction.get(billRef);

        if (!billDoc.exists) {
          throw Exception('Bill not found');
        }

        final billData = billDoc.data() as Map<String, dynamic>;
        final bill = Bill.fromJson(billData);

        if (bill.returnStatus) {
          throw Exception('Bill has already been returned');
        }

        // Step 2: Get current stock for all products in the bill
        final productStocks = <String, int>{};
        final productRefsMap = <String, DocumentReference>{};
        final uniqueProductIds = bill.items
            .map((e) => e.productId)
            .toSet()
            .toList();

        final productDocFutures = uniqueProductIds.map((productId) {
          final ref = firestore
              .collection('users')
              .doc(userId)
              .collection('products')
              .doc(productId);
          productRefsMap[productId] = ref;
          return transaction.get(ref);
        }).toList();

        final productSnapshots = await Future.wait(productDocFutures);
        final productDocsMap = Map.fromIterables(
          uniqueProductIds,
          productSnapshots,
        );

        for (final productId in uniqueProductIds) {
          final productDoc = productDocsMap[productId]!;
          if (productDoc.exists) {
            final data = productDoc.data() as Map<String, dynamic>?;
            productStocks[productId] = (data?['currentStock'] ?? 0) as int;
          } else {
            // Product might have been deleted, still allow return
            productStocks[productId] = 0;
          }
        }

        // Step 3: Calculate new stock quantities (add back returned quantities)
        final productNewBalances = Map<String, int>.from(productStocks);
        for (final item in bill.items) {
          productNewBalances[item.productId] =
              (productNewBalances[item.productId] ?? 0) + item.quantity;
        }

        // Step 4: Update product stocks
        final now = DateTime.now();
        for (final productId in uniqueProductIds) {
          final productRef = productRefsMap[productId]!;
          final productDoc = productDocsMap[productId]!;

          if (productDoc.exists) {
            transaction.update(productRef, {
              'currentStock': productNewBalances[productId],
              'updatedAt': now.toIso8601String(),
            });
          }
        }

        // Step 5: Create stock entries for each returned item
        for (final item in bill.items) {
          final stockRef = firestore
              .collection('users')
              .doc(userId)
              .collection('stock')
              .doc();

          final stockEntry = Stock(
            id: stockRef.id,
            productId: item.productId,
            quantityIn: item.quantity, // Return adds stock back
            quantityOut: 0,
            balanceQuantity: productNewBalances[item.productId]!,
            referenceType: ReferenceType.RETURN,
            referenceId: billId,
            createdAt: now,
          );

          transaction.set(stockRef, stockEntry.toJson());
        }

        // Step 6: Mark the bill as returned
        transaction.update(billRef, {
          'returnStatus': true,
          'returnDate': now.toIso8601String(),
          'updatedAt': now.toIso8601String(),
        });

        return {'billId': billId, 'returnDate': now.toIso8601String()};
      });

      return ReturnBillResult.success(result['billId'] as String);
    } catch (e) {
      print('[ERROR] Failed to process return: $e');
      return ReturnBillResult.failure(
        'Failed to process return: ${e.toString()}',
      );
    }
  }
}

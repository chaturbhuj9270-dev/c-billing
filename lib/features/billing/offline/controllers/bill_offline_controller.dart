import 'package:flutter/foundation.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/database/local_store.dart';
import '../../../../core/services/dashboard_refresh_service.dart';
import '../../../../core/services/local_database.dart';
import '../../../customer/offline/controllers/customer_transaction_offline_controller.dart';
import '../../domain/entities/bill_extra_charge.dart';
import '../entities/bill_entity.dart';

// Offline-first controller for Bill CRUD operations. All operations go to the local database first, then sync in the background.
class BillOfflineController extends ChangeNotifier {
  static BillOfflineController? _instance;

  final AppDatabase _db;

  BillOfflineController._(this._db);

  // Get the singleton instance
  static BillOfflineController get instance {
    _instance ??= BillOfflineController._(LocalDatabase.instance.db);
    return _instance!;
  }

  // Reset instance (for testing)
  @visibleForTesting
  static void resetInstance() {
    _instance = null;
  }

  // ==================== CREATE ====================

  // Add a new bill locally Sets syncStatus to NEW for background sync
  Future<BillEntity> addBill({
    String? customerId,
    String? customerName,
    String? customerContact,
    required List<BillItemEmbedded> items,
    required int totalQuantity,
    required double totalAmount,
    double discountAmount = 0.0,
    double discountPercent = 0.0,
    required double finalAmount,
    DateTime? billDate,
    String? notes,
    BillPaymentStatus paymentStatus = BillPaymentStatus.paid,
    double paidAmount = 0.0,
    double pendingAmount = 0.0,
    bool isGstApplied = false,
    bool isTaxInclusive = false,
    double cgstPercent = 0.0,
    double sgstPercent = 0.0,
    double igstPercent = 0.0,
    double otherTaxPercent = 0.0,
    String? otherTaxName,
    double cgstAmount = 0.0,
    double sgstAmount = 0.0,
    double igstAmount = 0.0,
    double otherTaxAmount = 0.0,
    double totalTaxAmount = 0.0,
    String? customerGstin,
    String? placeOfSupply,
    bool isInterstate = false,
    List<BillExtraCharge> extraCharges = const [],
    String paymentMode = 'CASH',
  }) async {
    final bill = BillEntity.create(
      customerId: customerId,
      customerName: customerName,
      customerContact: customerContact,
      items: items,
      totalQuantity: totalQuantity,
      totalAmount: totalAmount,
      discountAmount: discountAmount,
      discountPercent: discountPercent,
      finalAmount: finalAmount,
      billDate: billDate,
      notes: notes,
      paymentStatus: paymentStatus,
      paidAmount: paidAmount,
      pendingAmount: pendingAmount,
      isGstApplied: isGstApplied,
      isTaxInclusive: isTaxInclusive,
      cgstPercent: cgstPercent,
      sgstPercent: sgstPercent,
      igstPercent: igstPercent,
      otherTaxPercent: otherTaxPercent,
      otherTaxName: otherTaxName,
      cgstAmount: cgstAmount,
      sgstAmount: sgstAmount,
      igstAmount: igstAmount,
      otherTaxAmount: otherTaxAmount,
      totalTaxAmount: totalTaxAmount,
      customerGstin: customerGstin,
      placeOfSupply: placeOfSupply,
      isInterstate: isInterstate,
      extraCharges: extraCharges,
      paymentMode: paymentMode,
      syncStatus: BillSyncStatus.newRecord,
    );

    await _db.saveBill(bill);

    debugPrint(
      '[BillOffline] Bill added: ${bill.id}, customer: ${bill.customerName}, status: NEW',
    );
    notifyListeners();
    return bill;
  }

  // ==================== READ ====================

  // Get all bills (excluding deleted)
  Future<List<BillEntity>> getAllBills() async {
    final bills = (await _db.loadBills())
        .where((bill) => bill.syncStatus != BillSyncStatus.deleted)
        .toList();
    bills.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return bills;
  }

  // Watch all bills for real-time updates (excluding deleted)
  Stream<List<BillEntity>> watchAllBills() {
    return _db.watchBills().map((rows) {
      final bills = rows
          .where((bill) => bill.syncStatus != BillSyncStatus.deleted)
          .toList();
      bills.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return bills;
    });
  }

  // Get bill by local id
  Future<BillEntity?> getBillById(int id) async {
    for (final bill in await _db.loadBills()) {
      if (bill.id == id) return bill;
    }
    return null;
  }

  // Get bill by server ID
  Future<BillEntity?> getBillByServerId(String serverId) async {
    for (final bill in await _db.loadBills()) {
      if (bill.serverId == serverId) return bill;
    }
    return null;
  }

  // Get bills by customer ID
  Future<List<BillEntity>> getBillsByCustomerId(String customerId) async {
    final bills = (await _db.loadBills()).where((bill) {
      return bill.customerId == customerId &&
          bill.syncStatus != BillSyncStatus.deleted;
    }).toList();
    bills.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return bills;
  }

  // Get bills by date range
  Future<List<BillEntity>> getBillsByDateRange(
    DateTime start,
    DateTime end,
  ) async {
    final bills = (await _db.loadBills()).where((bill) {
      if (bill.syncStatus == BillSyncStatus.deleted) return false;
      return !bill.billDate.isBefore(start) && !bill.billDate.isAfter(end);
    }).toList();
    bills.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return bills;
  }

  // Get today's bills
  Future<List<BillEntity>> getTodaysBills() async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    return getBillsByDateRange(startOfDay, endOfDay);
  }

  // Get pending payment bills
  Future<List<BillEntity>> getPendingPaymentBills() async {
    final bills = (await _db.loadBills()).where((bill) {
      if (bill.syncStatus == BillSyncStatus.deleted) return false;
      return bill.paymentStatus == BillPaymentStatus.pending ||
          bill.paymentStatus == BillPaymentStatus.partiallyPaid;
    }).toList();
    bills.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return bills;
  }

  // Search bills by customer name or contact
  Future<List<BillEntity>> searchBills(String query) async {
    if (query.isEmpty) return getAllBills();

    final needle = query.toLowerCase();
    final bills = (await _db.loadBills()).where((bill) {
      if (bill.syncStatus == BillSyncStatus.deleted) return false;
      return (bill.customerName?.toLowerCase().contains(needle) ?? false) ||
          (bill.customerContact?.toLowerCase().contains(needle) ?? false);
    }).toList();
    bills.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return bills;
  }

  // ==================== UPDATE ====================

  // Update an existing bill
  Future<BillEntity?> updateBill({
    required int id,
    String? customerId,
    String? customerName,
    String? customerContact,
    List<BillItemEmbedded>? items,
    int? totalQuantity,
    double? totalAmount,
    double? discountAmount,
    double? discountPercent,
    double? finalAmount,
    DateTime? billDate,
    String? notes,
    bool? returnStatus,
    DateTime? returnDate,
    BillPaymentStatus? paymentStatus,
    double? paidAmount,
    double? pendingAmount,
  }) async {
    final existing = await getBillById(id);
    if (existing == null) {
      debugPrint('[BillOffline] Bill not found for update: $id');
      return null;
    }

    // Determine new sync status
    BillSyncStatus newSyncStatus;
    if (existing.syncStatus == BillSyncStatus.newRecord) {
      // Still new, hasn't been synced yet
      newSyncStatus = BillSyncStatus.newRecord;
    } else if (existing.syncStatus == BillSyncStatus.deleted) {
      // Don't update deleted records
      debugPrint('[BillOffline] Cannot update deleted bill: $id');
      return null;
    } else {
      // Mark as updated for sync
      newSyncStatus = BillSyncStatus.updated;
    }

    final updated = existing.copyWith(
      customerId: customerId,
      customerName: customerName,
      customerContact: customerContact,
      items: items,
      totalQuantity: totalQuantity,
      totalAmount: totalAmount,
      discountAmount: discountAmount,
      discountPercent: discountPercent,
      finalAmount: finalAmount,
      billDate: billDate,
      notes: notes,
      returnStatus: returnStatus,
      returnDate: returnDate,
      paymentStatus: paymentStatus,
      paidAmount: paidAmount,
      pendingAmount: pendingAmount,
      syncStatus: newSyncStatus,
    );

    await _db.saveBill(updated);

    debugPrint(
      '[BillOffline] Bill updated: $id, status: ${newSyncStatus.name}',
    );
    notifyListeners();
    return updated;
  }

  // Update payment for a bill
  Future<BillEntity?> updatePayment({
    required int id,
    required double paidAmount,
    required BillPaymentStatus paymentStatus,
  }) async {
    final existing = await getBillById(id);
    if (existing == null) return null;

    final pendingAmount = existing.finalAmount - paidAmount;

    return updateBill(
      id: id,
      paidAmount: paidAmount,
      pendingAmount: pendingAmount > 0 ? pendingAmount : 0,
      paymentStatus: paymentStatus,
    );
  }

  // Mark bill as returned
  Future<BillEntity?> markAsReturned(int id) async {
    return updateBill(id: id, returnStatus: true, returnDate: DateTime.now());
  }

  // ==================== DELETE ====================

  // Soft delete a bill (marks for deletion, syncs then removes)
  Future<bool> deleteBill(int id) async {
    final existing = await getBillById(id);
    if (existing == null) {
      debugPrint('[BillOffline] Bill not found for delete: $id');
      return false;
    }

    // Keep customer receivable in sync with the removed invoice.
    final billKey = existing.serverId ?? 'local_${existing.id}';
    try {
      await CustomerTransactionOfflineController.instance
          .reverseTransactionsForBill(billKey);
      if (existing.serverId != null) {
        await CustomerTransactionOfflineController.instance
            .reverseTransactionsForBill('local_${existing.id}');
      }
    } catch (e) {
      debugPrint('[BillOffline] Ledger reverse on delete failed: $e');
    }

    if (existing.syncStatus == BillSyncStatus.newRecord) {
      // Never synced, just remove locally
      await _db.deleteBillById(id);
      debugPrint(
        '[BillOffline] Bill permanently deleted (was never synced): $id',
      );
    } else {
      // Mark for deletion, will be synced then removed
      final deleted = existing.copyWith(syncStatus: BillSyncStatus.deleted);
      await _db.saveBill(deleted);
      debugPrint('[BillOffline] Bill marked for deletion: $id');
    }

    notifyListeners();
    DashboardRefreshService.instance.notifyDataChanged(DataChangeType.bill);
    return true;
  }

  // ==================== SYNC HELPERS ====================

  // Get all bills that need to be synced
  Future<List<BillEntity>> getUnsyncedBills() async {
    final bills = (await _db.loadBills())
        .where((bill) => bill.syncStatus != BillSyncStatus.synced)
        .toList();
    debugPrint(
      '[BillOffline] getUnsyncedBills: Found ${bills.length} unsynced bills',
    );
    for (final bill in bills) {
      debugPrint(
        '[BillOffline] - Bill ${bill.id}: syncStatus=${bill.syncStatus.name}, serverId=${bill.serverId}',
      );
    }
    return bills;
  }

  // Get count of unsynced bills
  Future<int> getUnsyncedCount() async {
    return (await _db.loadBills())
        .where((bill) => bill.syncStatus != BillSyncStatus.synced)
        .length;
  }

  // Mark a bill as synced with server ID
  Future<void> markAsSynced(int localId, String serverId) async {
    final existing = await getBillById(localId);
    if (existing == null) return;

    final synced = existing.copyWith(
      serverId: serverId,
      syncStatus: BillSyncStatus.synced,
    );

    await _db.saveBill(synced);

    debugPrint('[BillOffline] Bill marked as synced: $localId -> $serverId');
    notifyListeners();
  }

  // Remove a bill after successful server deletion
  Future<void> removeAfterServerDelete(int id) async {
    await _db.deleteBillById(id);
    debugPrint('[BillOffline] Bill removed after server delete: $id');
    notifyListeners();
  }

  // Import bills from server (for initial sync or refresh)
  Future<void> importFromServer(List<Map<String, dynamic>> serverBills) async {
    await _db.transaction(() async {
      for (final billData in serverBills) {
        final serverId = billData['id'] as String?;
        if (serverId == null) continue;

        // Check if exists locally by serverId
        BillEntity? existing;
        for (final bill in await _db.loadBills()) {
          if (bill.serverId == serverId) {
            existing = bill;
            break;
          }
        }

        if (existing != null) {
          // Only update if not locally modified AND server is newer
          if (existing.syncStatus == BillSyncStatus.synced) {
            final serverUpdatedAt = DateTime.tryParse(
              billData['updatedAt']?.toString() ?? '',
            );
            if (serverUpdatedAt != null &&
                serverUpdatedAt.isAfter(existing.updatedAt)) {
              final updated = BillEntity.fromServer(billData);
              updated.id = existing.id;
              await _db.saveBill(updated);
            }
          }
        } else {
          // Create new
          final newBill = BillEntity.fromServer(billData);
          await _db.saveBill(newBill);
        }
      }
    });

    notifyListeners();
    debugPrint(
      '[BillOffline] Imported ${serverBills.length} bills from server',
    );
  }

  // ==================== STATISTICS ====================

  // Get total bill count
  Future<int> getTotalCount() async {
    return (await _db.loadBills())
        .where((bill) => bill.syncStatus != BillSyncStatus.deleted)
        .length;
  }

  // Get total sales amount for a date range
  Future<double> getTotalSales({DateTime? startDate, DateTime? endDate}) async {
    final bills = (await _db.loadBills()).where((bill) {
      if (bill.syncStatus == BillSyncStatus.deleted) return false;
      if (startDate != null && !bill.billDate.isAfter(startDate)) return false;
      if (endDate != null && !bill.billDate.isBefore(endDate)) return false;
      return true;
    });
    return bills.fold<double>(0.0, (total, b) => total + b.finalAmount);
  }

  // Get total pending amount
  Future<double> getTotalPendingAmount() async {
    final bills = (await _db.loadBills()).where((bill) {
      if (bill.syncStatus == BillSyncStatus.deleted) return false;
      return bill.paymentStatus == BillPaymentStatus.pending ||
          bill.paymentStatus == BillPaymentStatus.partiallyPaid;
    });

    return bills.fold<double>(0.0, (total, b) => total + b.pendingAmount);
  }

  // Get bills with pending payment (for dashboard)
  Future<List<BillEntity>> getPendingBills() async {
    final bills = (await _db.loadBills()).where((bill) {
      return bill.syncStatus != BillSyncStatus.deleted &&
          bill.pendingAmount > 0;
    }).toList();
    bills.sort((a, b) => b.pendingAmount.compareTo(a.pendingAmount));
    return bills;
  }

  // Get bill count
  Future<int> getBillCount() async {
    return (await _db.loadBills())
        .where((bill) => bill.syncStatus != BillSyncStatus.deleted)
        .length;
  }

  // Clear all local bills (use with caution)
  Future<void> clearAll() async {
    await _db.clearBills();
    debugPrint('[BillOffline] All bills cleared');
    notifyListeners();
  }
}

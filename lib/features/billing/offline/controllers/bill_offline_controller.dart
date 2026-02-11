import 'package:flutter/foundation.dart';
import 'package:isar_community/isar.dart';
import '../../../../core/services/isar_service.dart';
import '../entities/bill_entity.dart';

/// Offline-first controller for Bill CRUD operations
/// All operations go to local Isar first, then sync in background
class BillOfflineController extends ChangeNotifier {
  static BillOfflineController? _instance;
  
  final Isar _isar;

  BillOfflineController._(this._isar);

  /// Get the singleton instance
  static BillOfflineController get instance {
    if (_instance == null) {
      final isar = IsarService.instance.isar;
      _instance = BillOfflineController._(isar);
    }
    return _instance!;
  }

  /// Reset instance (for testing)
  @visibleForTesting
  static void resetInstance() {
    _instance = null;
  }

  // ==================== CREATE ====================

  /// Add a new bill locally
  /// Sets syncStatus to NEW for background sync
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
      syncStatus: BillSyncStatus.newRecord,
    );

    await _isar.writeTxn(() async {
      await _isar.billEntitys.put(bill);
    });

    debugPrint('[BillOffline] Bill added: ${bill.id}, customer: ${bill.customerName}, status: NEW');
    notifyListeners();
    return bill;
  }

  // ==================== READ ====================

  /// Get all bills (excluding deleted)
  Future<List<BillEntity>> getAllBills() async {
    return await _isar.billEntitys
        .filter()
        .not()
        .syncStatusEqualTo(BillSyncStatus.deleted)
        .sortByCreatedAtDesc()
        .findAll();
  }

  /// Watch all bills for real-time updates (excluding deleted)
  Stream<List<BillEntity>> watchAllBills() {
    return _isar.billEntitys
        .filter()
        .not()
        .syncStatusEqualTo(BillSyncStatus.deleted)
        .sortByCreatedAtDesc()
        .watch(fireImmediately: true);
  }

  /// Get bill by local Isar ID
  Future<BillEntity?> getBillById(Id id) async {
    return await _isar.billEntitys.get(id);
  }

  /// Get bill by server ID
  Future<BillEntity?> getBillByServerId(String serverId) async {
    return await _isar.billEntitys
        .filter()
        .serverIdEqualTo(serverId)
        .findFirst();
  }

  /// Get bills by customer ID
  Future<List<BillEntity>> getBillsByCustomerId(String customerId) async {
    return await _isar.billEntitys
        .filter()
        .customerIdEqualTo(customerId)
        .not()
        .syncStatusEqualTo(BillSyncStatus.deleted)
        .sortByCreatedAtDesc()
        .findAll();
  }

  /// Get bills by date range
  Future<List<BillEntity>> getBillsByDateRange(DateTime start, DateTime end) async {
    return await _isar.billEntitys
        .filter()
        .billDateBetween(start, end)
        .not()
        .syncStatusEqualTo(BillSyncStatus.deleted)
        .sortByCreatedAtDesc()
        .findAll();
  }

  /// Get today's bills
  Future<List<BillEntity>> getTodaysBills() async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    return getBillsByDateRange(startOfDay, endOfDay);
  }

  /// Get pending payment bills
  Future<List<BillEntity>> getPendingPaymentBills() async {
    return await _isar.billEntitys
        .filter()
        .not()
        .syncStatusEqualTo(BillSyncStatus.deleted)
        .group((q) => q
            .paymentStatusEqualTo(BillPaymentStatus.pending)
            .or()
            .paymentStatusEqualTo(BillPaymentStatus.partiallyPaid))
        .sortByCreatedAtDesc()
        .findAll();
  }

  /// Search bills by customer name or contact
  Future<List<BillEntity>> searchBills(String query) async {
    if (query.isEmpty) return getAllBills();
    
    final lowerQuery = query.toLowerCase();
    return await _isar.billEntitys
        .filter()
        .not()
        .syncStatusEqualTo(BillSyncStatus.deleted)
        .group((q) => q
            .customerNameContains(lowerQuery, caseSensitive: false)
            .or()
            .customerContactContains(lowerQuery, caseSensitive: false))
        .sortByCreatedAtDesc()
        .findAll();
  }

  // ==================== UPDATE ====================

  /// Update an existing bill
  Future<BillEntity?> updateBill({
    required Id id,
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
    final existing = await _isar.billEntitys.get(id);
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

    await _isar.writeTxn(() async {
      await _isar.billEntitys.put(updated);
    });

    debugPrint('[BillOffline] Bill updated: $id, status: ${newSyncStatus.name}');
    notifyListeners();
    return updated;
  }

  /// Update payment for a bill
  Future<BillEntity?> updatePayment({
    required Id id,
    required double paidAmount,
    required BillPaymentStatus paymentStatus,
  }) async {
    final existing = await _isar.billEntitys.get(id);
    if (existing == null) return null;

    final pendingAmount = existing.finalAmount - paidAmount;
    
    return updateBill(
      id: id,
      paidAmount: paidAmount,
      pendingAmount: pendingAmount > 0 ? pendingAmount : 0,
      paymentStatus: paymentStatus,
    );
  }

  /// Mark bill as returned
  Future<BillEntity?> markAsReturned(Id id) async {
    return updateBill(
      id: id,
      returnStatus: true,
      returnDate: DateTime.now(),
    );
  }

  // ==================== DELETE ====================

  /// Soft delete a bill (marks for deletion, syncs then removes)
  Future<bool> deleteBill(Id id) async {
    final existing = await _isar.billEntitys.get(id);
    if (existing == null) {
      debugPrint('[BillOffline] Bill not found for delete: $id');
      return false;
    }

    if (existing.syncStatus == BillSyncStatus.newRecord) {
      // Never synced, just remove locally
      await _isar.writeTxn(() async {
        await _isar.billEntitys.delete(id);
      });
      debugPrint('[BillOffline] Bill permanently deleted (was never synced): $id');
    } else {
      // Mark for deletion, will be synced then removed
      final deleted = existing.copyWith(
        syncStatus: BillSyncStatus.deleted,
      );
      await _isar.writeTxn(() async {
        await _isar.billEntitys.put(deleted);
      });
      debugPrint('[BillOffline] Bill marked for deletion: $id');
    }

    notifyListeners();
    return true;
  }

  // ==================== SYNC HELPERS ====================

  /// Get all bills that need to be synced
  Future<List<BillEntity>> getUnsyncedBills() async {
    return await _isar.billEntitys
        .filter()
        .not()
        .syncStatusEqualTo(BillSyncStatus.synced)
        .findAll();
  }

  /// Get count of unsynced bills
  Future<int> getUnsyncedCount() async {
    return await _isar.billEntitys
        .filter()
        .not()
        .syncStatusEqualTo(BillSyncStatus.synced)
        .count();
  }

  /// Mark a bill as synced with server ID
  Future<void> markAsSynced(Id localId, String serverId) async {
    final existing = await _isar.billEntitys.get(localId);
    if (existing == null) return;

    final synced = existing.copyWith(
      serverId: serverId,
      syncStatus: BillSyncStatus.synced,
    );

    await _isar.writeTxn(() async {
      await _isar.billEntitys.put(synced);
    });

    debugPrint('[BillOffline] Bill marked as synced: $localId -> $serverId');
  }

  /// Remove a bill after successful server deletion
  Future<void> removeAfterServerDelete(Id id) async {
    await _isar.writeTxn(() async {
      await _isar.billEntitys.delete(id);
    });
    debugPrint('[BillOffline] Bill removed after server delete: $id');
    notifyListeners();
  }

  /// Import bills from server (for initial sync or refresh)
  Future<void> importFromServer(List<Map<String, dynamic>> serverBills) async {
    await _isar.writeTxn(() async {
      for (final billData in serverBills) {
        final serverId = billData['id'] as String?;
        if (serverId == null) continue;

        // Check if exists locally by serverId
        final existing = await _isar.billEntitys
            .filter()
            .serverIdEqualTo(serverId)
            .findFirst();

        if (existing != null) {
          // Only update if not locally modified AND server is newer
          if (existing.syncStatus == BillSyncStatus.synced) {
            final serverUpdatedAt = DateTime.tryParse(
              billData['updatedAt']?.toString() ?? '',
            );
            if (serverUpdatedAt != null && serverUpdatedAt.isAfter(existing.updatedAt)) {
              final updated = BillEntity.fromServer(billData);
              updated.id = existing.id;
              await _isar.billEntitys.put(updated);
            }
          }
        } else {
          // Create new
          final newBill = BillEntity.fromServer(billData);
          await _isar.billEntitys.put(newBill);
        }
      }
    });

    notifyListeners();
    debugPrint('[BillOffline] Imported ${serverBills.length} bills from server');
  }

  // ==================== STATISTICS ====================

  /// Get total sales amount for a date range
  Future<double> getTotalSales({DateTime? startDate, DateTime? endDate}) async {
    var query = _isar.billEntitys
        .filter()
        .not()
        .syncStatusEqualTo(BillSyncStatus.deleted);

    if (startDate != null) {
      query = query.billDateGreaterThan(startDate);
    }
    if (endDate != null) {
      query = query.billDateLessThan(endDate);
    }

    final bills = await query.findAll();
    return bills.fold<double>(0.0, (sum, b) => sum + b.finalAmount);
  }

  /// Get total pending amount
  Future<double> getTotalPendingAmount() async {
    final bills = await _isar.billEntitys
        .filter()
        .not()
        .syncStatusEqualTo(BillSyncStatus.deleted)
        .group((q) => q
            .paymentStatusEqualTo(BillPaymentStatus.pending)
            .or()
            .paymentStatusEqualTo(BillPaymentStatus.partiallyPaid))
        .findAll();

    return bills.fold<double>(0.0, (sum, b) => sum + b.pendingAmount);
  }

  /// Get bill count
  Future<int> getBillCount() async {
    return await _isar.billEntitys
        .filter()
        .not()
        .syncStatusEqualTo(BillSyncStatus.deleted)
        .count();
  }

  /// Clear all local bills (use with caution)
  Future<void> clearAll() async {
    await _isar.writeTxn(() async {
      await _isar.billEntitys.clear();
    });
    debugPrint('[BillOffline] All bills cleared');
    notifyListeners();
  }
}

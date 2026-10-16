import 'package:flutter/foundation.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/database/local_store.dart';
import '../../../../core/services/local_database.dart';
import '../entities/purchase_entity.dart';

/// Offline-first controller for Purchase CRUD operations.
/// All operations go to the local database first, then sync in the background.
class PurchaseOfflineController extends ChangeNotifier {
  static PurchaseOfflineController? _instance;

  final AppDatabase _db;

  PurchaseOfflineController._(this._db);

  static PurchaseOfflineController get instance {
    _instance ??= PurchaseOfflineController._(LocalDatabase.instance.db);
    return _instance!;
  }

  @visibleForTesting
  static void resetInstance() {
    _instance = null;
  }

  List<PurchaseEntity> _newestFirst(Iterable<PurchaseEntity> purchases) {
    final list = purchases.toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  Future<PurchaseEntity?> _findById(int id) async {
    for (final purchase in await _db.loadPurchases()) {
      if (purchase.id == id) return purchase;
    }
    return null;
  }

  Future<PurchaseEntity> addPurchase({
    required String productId,
    required String productName,
    String? supplierId,
    String? supplierName,
    String? companyId,
    String? companyName,
    required int quantity,
    required String unit,
    required double purchasePrice,
    required double salesPrice,
    DateTime? productionDate,
    DateTime? expiryDate,
    int? warrantyMonths,
    String? notes,
  }) async {
    final purchase = PurchaseEntity.create(
      productId: productId,
      productName: productName,
      supplierId: supplierId,
      supplierName: supplierName,
      companyId: companyId,
      companyName: companyName,
      quantity: quantity,
      unit: unit,
      purchasePrice: purchasePrice,
      salesPrice: salesPrice,
      productionDate: productionDate,
      expiryDate: expiryDate,
      warrantyMonths: warrantyMonths,
      notes: notes,
      syncStatus: PurchaseSyncStatus.newRecord,
    );

    await _db.savePurchase(purchase);

    debugPrint(
      '[PurchaseOffline] Purchase added: ${purchase.id}, product: ${purchase.productName}, status: NEW',
    );
    notifyListeners();
    return purchase;
  }

  Future<List<PurchaseEntity>> getAllPurchases() async {
    return _newestFirst(
      (await _db.loadPurchases()).where(
        (purchase) => purchase.syncStatus != PurchaseSyncStatus.deleted,
      ),
    );
  }

  Stream<List<PurchaseEntity>> watchAllPurchases() {
    return _db.watchPurchases().map(
      (rows) => _newestFirst(
        rows.where(
          (purchase) => purchase.syncStatus != PurchaseSyncStatus.deleted,
        ),
      ),
    );
  }

  Future<PurchaseEntity?> getPurchaseById(int id) => _findById(id);

  Future<PurchaseEntity?> getPurchaseByServerId(String serverId) async {
    for (final purchase in await _db.loadPurchases()) {
      if (purchase.serverId == serverId) return purchase;
    }
    return null;
  }

  Future<List<PurchaseEntity>> getPurchasesByProductId(String productId) async {
    return _newestFirst(
      (await _db.loadPurchases()).where(
        (purchase) =>
            purchase.productId == productId &&
            purchase.syncStatus != PurchaseSyncStatus.deleted,
      ),
    );
  }

  Future<List<PurchaseEntity>> getPurchasesBySupplierId(
    String supplierId,
  ) async {
    return _newestFirst(
      (await _db.loadPurchases()).where(
        (purchase) =>
            purchase.supplierId == supplierId &&
            purchase.syncStatus != PurchaseSyncStatus.deleted,
      ),
    );
  }

  Future<List<PurchaseEntity>> getPurchasesByCompanyId(String companyId) async {
    return _newestFirst(
      (await _db.loadPurchases()).where(
        (purchase) =>
            purchase.companyId == companyId &&
            purchase.syncStatus != PurchaseSyncStatus.deleted,
      ),
    );
  }

  Future<List<PurchaseEntity>> getRecentPurchases({int limit = 50}) async {
    return (await getAllPurchases()).take(limit).toList();
  }

  Future<PurchaseEntity?> updatePurchase({
    required int id,
    int? quantity,
    String? unit,
    double? purchasePrice,
    double? salesPrice,
    DateTime? productionDate,
    DateTime? expiryDate,
    int? warrantyMonths,
    String? notes,
  }) async {
    final existing = await _findById(id);
    if (existing == null) {
      debugPrint('[PurchaseOffline] Purchase not found: $id');
      return null;
    }

    final PurchaseSyncStatus newSyncStatus;
    switch (existing.syncStatus) {
      case PurchaseSyncStatus.newRecord:
        newSyncStatus = PurchaseSyncStatus.newRecord;
        break;
      case PurchaseSyncStatus.synced:
      case PurchaseSyncStatus.updated:
        newSyncStatus = PurchaseSyncStatus.updated;
        break;
      case PurchaseSyncStatus.deleted:
        newSyncStatus = PurchaseSyncStatus.deleted;
        break;
    }

    final newQuantity = quantity ?? existing.quantity;
    final newPrice = purchasePrice ?? existing.purchasePrice;
    final newTotal = newQuantity * newPrice;

    final updated = existing.copyWith(
      quantity: quantity,
      unit: unit,
      purchasePrice: purchasePrice,
      salesPrice: salesPrice,
      totalAmount: newTotal,
      productionDate: productionDate,
      expiryDate: expiryDate,
      warrantyMonths: warrantyMonths,
      notes: notes,
      syncStatus: newSyncStatus,
      updatedAt: DateTime.now(),
    );

    await _db.savePurchase(updated);

    debugPrint(
      '[PurchaseOffline] Purchase updated: ${updated.id}, syncStatus: ${updated.syncStatus}',
    );
    notifyListeners();
    return updated;
  }

  Future<void> deletePurchase(int id) async {
    final existing = await _findById(id);
    if (existing == null) {
      debugPrint('[PurchaseOffline] Purchase not found for delete: $id');
      return;
    }

    if (existing.syncStatus == PurchaseSyncStatus.newRecord) {
      await _db.deletePurchaseById(id);
      debugPrint(
        '[PurchaseOffline] Purchase hard deleted (was never synced): $id',
      );
    } else {
      final deleted = existing.copyWith(
        syncStatus: PurchaseSyncStatus.deleted,
        updatedAt: DateTime.now(),
      );
      await _db.savePurchase(deleted);
      debugPrint('[PurchaseOffline] Purchase marked for deletion: $id');
    }

    notifyListeners();
  }

  Future<void> permanentlyDelete(int id) async {
    await _db.deletePurchaseById(id);
    debugPrint('[PurchaseOffline] Purchase permanently deleted: $id');
    notifyListeners();
  }

  Future<List<PurchaseEntity>> getPurchasesNeedingSync() async {
    return (await _db.loadPurchases())
        .where((purchase) => purchase.syncStatus != PurchaseSyncStatus.synced)
        .toList();
  }

  Future<int> getUnsyncedCount() async {
    return (await getPurchasesNeedingSync()).length;
  }

  Future<void> markAsSynced(int id, String serverId) async {
    final existing = await _findById(id);
    if (existing == null) return;

    final synced = existing.copyWith(
      serverId: serverId,
      syncStatus: PurchaseSyncStatus.synced,
    );

    await _db.savePurchase(synced);

    debugPrint('[PurchaseOffline] Purchase marked as synced: $id -> $serverId');
  }

  Future<void> importFromServer(
    List<Map<String, dynamic>> serverPurchases,
  ) async {
    await _db.transaction(() async {
      for (final data in serverPurchases) {
        final serverId = data['id'] as String?;
        if (serverId == null) continue;

        final all = await _db.loadPurchases();
        PurchaseEntity? existing;
        for (final purchase in all) {
          if (purchase.serverId == serverId) {
            existing = purchase;
            break;
          }
        }

        if (existing == null) {
          final productId = data['productId'] as String? ?? '';
          final quantity = (data['quantity'] as num?)?.toInt() ?? 0;
          final purchasePrice =
              (data['purchasePrice'] as num?)?.toDouble() ?? 0.0;

          if (productId.isNotEmpty) {
            for (final purchase in all) {
              if (purchase.productId == productId &&
                  purchase.quantity == quantity &&
                  purchase.purchasePrice == purchasePrice) {
                existing = purchase;
                break;
              }
            }

            if (existing != null && existing.serverId == null) {
              existing.serverId = serverId;
              existing.syncStatus = PurchaseSyncStatus.synced;
              await _db.savePurchase(existing);
              continue;
            }
          }
        }

        if (existing == null) {
          final purchase = PurchaseEntity.fromServer(data);
          await _db.savePurchase(purchase);
        } else if (existing.syncStatus == PurchaseSyncStatus.synced) {
          final updated = PurchaseEntity.fromServer(data);
          updated.id = existing.id;
          await _db.savePurchase(updated);
        }
      }
    });

    debugPrint(
      '[PurchaseOffline] Imported ${serverPurchases.length} purchases from server',
    );
    notifyListeners();
  }

  Future<int> getTotalCount() async {
    return (await _db.loadPurchases())
        .where((purchase) => purchase.syncStatus != PurchaseSyncStatus.deleted)
        .length;
  }

  Future<List<PurchaseEntity>> getPurchasesByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    return (await _db.loadPurchases()).where((purchase) {
      return purchase.syncStatus != PurchaseSyncStatus.deleted &&
          !purchase.createdAt.isBefore(startDate) &&
          !purchase.createdAt.isAfter(endDate);
    }).toList();
  }

  Future<double> getTotalPurchaseAmount({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final purchases = (await _db.loadPurchases()).where((purchase) {
      if (purchase.syncStatus == PurchaseSyncStatus.deleted) return false;
      if (startDate != null && !purchase.createdAt.isAfter(startDate)) {
        return false;
      }
      if (endDate != null && !purchase.createdAt.isBefore(endDate)) {
        return false;
      }
      return true;
    });
    return purchases.fold<double>(
      0.0,
      (total, purchase) => total + purchase.totalAmount,
    );
  }

  Future<void> clearAll() async {
    await _db.clearPurchases();
    debugPrint('[PurchaseOffline] All purchases cleared');
    notifyListeners();
  }
}

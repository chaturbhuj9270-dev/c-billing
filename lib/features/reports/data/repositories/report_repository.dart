import '../../../../core/database/local_store.dart';
import '../../../../core/services/local_database.dart';
import '../../../inventory_management/offline/entities/purchase_batch_entity.dart';
import '../../../inventory_management/offline/entities/stock_ledger_entity.dart';
import '../../../product/offline/entities/product_entity.dart';
import '../../../supplier/offline/entities/supplier_entity.dart';
import '../../domain/models/report_filter_model.dart';

// Repository for report queries against the local database.
class ReportRepository {
  ReportRepository._();

  static ReportRepository? _instance;
  static ReportRepository get instance {
    _instance ??= ReportRepository._();
    return _instance!;
  }

  bool _inRange(DateTime value, DateTime start, DateTime end) {
    return !value.isBefore(start) && !value.isAfter(end);
  }

  Future<List<PurchaseBatchEntity>> getBatches(ReportFilterModel filter) async {
    return (await LocalDatabase.instance.db.loadBatches()).where((batch) {
      if (batch.syncStatus == BatchSyncStatus.deleted) return false;
      if (!_inRange(batch.purchaseDate, filter.startDate, filter.endDate)) {
        return false;
      }
      if (filter.productId != null && batch.productId != filter.productId) {
        return false;
      }
      if (filter.supplierId != null && batch.supplierId != filter.supplierId) {
        return false;
      }
      if (filter.minPrice != null &&
          batch.purchasePrice <= filter.minPrice! - 0.01) {
        return false;
      }
      if (filter.maxPrice != null &&
          batch.purchasePrice >= filter.maxPrice! + 0.01) {
        return false;
      }
      return true;
    }).toList();
  }

  Future<List<PurchaseBatchEntity>> getAllActiveBatches({
    String? productId,
    String? supplierId,
  }) async {
    return (await LocalDatabase.instance.db.loadBatches()).where((batch) {
      if (batch.syncStatus == BatchSyncStatus.deleted) return false;
      if (productId != null && batch.productId != productId) return false;
      if (supplierId != null && batch.supplierId != supplierId) return false;
      return true;
    }).toList();
  }

  Future<List<PurchaseBatchEntity>> getExpiredBatches() async {
    final now = DateTime.now();
    return (await LocalDatabase.instance.db.loadBatches()).where((batch) {
      final expiry = batch.expiryDate;
      return batch.syncStatus != BatchSyncStatus.deleted &&
          expiry != null &&
          expiry.isBefore(now) &&
          batch.quantityRemaining > 0;
    }).toList();
  }

  Future<List<PurchaseBatchEntity>> getBatchesExpiringThisWeek() async {
    final now = DateTime.now();
    final weekEnd = now.add(Duration(days: 7 - now.weekday));
    final endOfWeek = DateTime(
      weekEnd.year,
      weekEnd.month,
      weekEnd.day,
      23,
      59,
      59,
    );
    return (await LocalDatabase.instance.db.loadBatches()).where((batch) {
      final expiry = batch.expiryDate;
      return batch.syncStatus != BatchSyncStatus.deleted &&
          expiry != null &&
          _inRange(expiry, now, endOfWeek) &&
          batch.quantityRemaining > 0;
    }).toList();
  }

  Future<List<StockLedgerEntity>> getLedgerEntries(
    ReportFilterModel filter, {
    LedgerTransactionType? type,
  }) async {
    return (await LocalDatabase.instance.db.loadLedger()).where((entry) {
      if (entry.syncStatus == LedgerSyncStatus.deleted) return false;
      if (!_inRange(entry.transactionDate, filter.startDate, filter.endDate)) {
        return false;
      }
      if (type != null && entry.ledgerType != type) return false;
      if (filter.productId != null && entry.productId != filter.productId) {
        return false;
      }
      return true;
    }).toList();
  }

  Future<List<StockLedgerEntity>> getLedgerByType(
    LedgerTransactionType type,
    DateTime startDate,
    DateTime endDate, {
    String? productId,
  }) async {
    return (await LocalDatabase.instance.db.loadLedger()).where((entry) {
      if (entry.syncStatus == LedgerSyncStatus.deleted) return false;
      if (entry.ledgerType != type) return false;
      if (!_inRange(entry.transactionDate, startDate, endDate)) return false;
      if (productId != null && entry.productId != productId) return false;
      return true;
    }).toList();
  }

  Future<Set<String>> getReturnedProductIds(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final saleReturns = await getLedgerByType(
      LedgerTransactionType.SALE_RETURN,
      startDate,
      endDate,
    );
    final purchaseReturns = await getLedgerByType(
      LedgerTransactionType.PURCHASE_RETURN,
      startDate,
      endDate,
    );

    final ids = <String>{};
    for (final entry in saleReturns) {
      ids.add(entry.productId);
    }
    for (final entry in purchaseReturns) {
      ids.add(entry.productId);
    }
    return ids;
  }

  Future<List<ProductEntity>> getProducts({
    String? productId,
    bool lowStockOnly = false,
    int lowStockThreshold = 5,
  }) async {
    final results = (await LocalDatabase.instance.db.loadProducts()).where((
      product,
    ) {
      if (!product.isActive || product.syncStatus == SyncStatus.deleted) {
        return false;
      }
      if (productId != null && product.serverId != productId) return false;
      return true;
    }).toList();

    if (lowStockOnly) {
      return results
          .where((product) => product.currentStock <= lowStockThreshold)
          .toList();
    }
    return results;
  }

  Future<List<ProductEntity>> searchProducts(String query) async {
    final active = (await LocalDatabase.instance.db.loadProducts()).where(
      (product) =>
          product.isActive && product.syncStatus != SyncStatus.deleted,
    );
    final needle = query.toLowerCase();
    final matches = active.where((product) {
      if (query.isEmpty) return true;
      return product.name.toLowerCase().contains(needle);
    }).toList()..sort((a, b) => a.name.compareTo(b.name));
    return matches.take(50).toList();
  }

  Future<List<SupplierEntity>> getSuppliers() async {
    final suppliers = (await LocalDatabase.instance.db.loadSuppliers())
        .where(
          (supplier) =>
              supplier.isActive &&
              supplier.syncStatus != SupplierSyncStatus.deleted,
        )
        .toList();
    suppliers.sort((a, b) => a.firstName.compareTo(b.firstName));
    return suppliers;
  }
}

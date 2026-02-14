import 'package:isar_community/isar.dart';
import '../../../../core/services/isar_service.dart';
import '../../../inventory_management/offline/entities/purchase_batch_entity.dart';
import '../../../inventory_management/offline/entities/stock_ledger_entity.dart';
import '../../../product/offline/entities/product_entity.dart';
import '../../../supplier/offline/entities/supplier_entity.dart';
import '../../domain/models/report_filter_model.dart';

/// Repository for querying Isar with optimized, query-level filtering.
/// Never loads full database into memory — uses Isar where + filter.
class ReportRepository {
  final Isar _isar;

  ReportRepository._() : _isar = IsarService.instance.isar;

  static ReportRepository? _instance;
  static ReportRepository get instance {
    _instance ??= ReportRepository._();
    return _instance!;
  }

  // ─────────── PURCHASE BATCHES ───────────

  /// Get purchase batches filtered by date range + optional product/supplier.
  Future<List<PurchaseBatchEntity>> getBatches(ReportFilterModel filter) async {
    var query = _isar.purchaseBatchEntitys
        .filter()
        .not()
        .syncStatusEqualTo(BatchSyncStatus.deleted)
        .purchaseDateBetween(filter.startDate, filter.endDate);

    if (filter.productId != null) {
      query = query.productIdEqualTo(filter.productId!);
    }
    if (filter.supplierId != null) {
      query = query.supplierIdEqualTo(filter.supplierId!);
    }
    if (filter.minPrice != null) {
      query = query.purchasePriceGreaterThan(filter.minPrice! - 0.01);
    }
    if (filter.maxPrice != null) {
      query = query.purchasePriceLessThan(filter.maxPrice! + 0.01);
    }

    return await query.findAll();
  }

  /// Get ALL non-deleted batches (for current stock / expiry calculations).
  Future<List<PurchaseBatchEntity>> getAllActiveBatches({
    String? productId,
    String? supplierId,
  }) async {
    var query = _isar.purchaseBatchEntitys
        .filter()
        .not()
        .syncStatusEqualTo(BatchSyncStatus.deleted);

    if (productId != null) {
      query = query.productIdEqualTo(productId);
    }
    if (supplierId != null) {
      query = query.supplierIdEqualTo(supplierId);
    }

    return await query.findAll();
  }

  /// Get expired batches (expiryDate < now, quantityRemaining > 0).
  Future<List<PurchaseBatchEntity>> getExpiredBatches() async {
    final now = DateTime.now();
    return await _isar.purchaseBatchEntitys
        .filter()
        .not()
        .syncStatusEqualTo(BatchSyncStatus.deleted)
        .expiryDateIsNotNull()
        .expiryDateLessThan(now)
        .quantityRemainingGreaterThan(0)
        .findAll();
  }

  /// Get batches expiring this week.
  Future<List<PurchaseBatchEntity>> getBatchesExpiringThisWeek() async {
    final now = DateTime.now();
    final weekEnd = now.add(Duration(days: 7 - now.weekday));
    final endOfWeek = DateTime(weekEnd.year, weekEnd.month, weekEnd.day, 23, 59, 59);
    return await _isar.purchaseBatchEntitys
        .filter()
        .not()
        .syncStatusEqualTo(BatchSyncStatus.deleted)
        .expiryDateIsNotNull()
        .expiryDateBetween(now, endOfWeek)
        .quantityRemainingGreaterThan(0)
        .findAll();
  }

  // ─────────── STOCK LEDGER ───────────

  /// Get ledger entries filtered by date range, type, and optional product.
  Future<List<StockLedgerEntity>> getLedgerEntries(
    ReportFilterModel filter, {
    LedgerTransactionType? type,
  }) async {
    var query = _isar.stockLedgerEntitys
        .filter()
        .not()
        .syncStatusEqualTo(LedgerSyncStatus.deleted)
        .transactionDateBetween(filter.startDate, filter.endDate);

    if (type != null) {
      query = query.ledgerTypeEqualTo(type);
    }
    if (filter.productId != null) {
      query = query.productIdEqualTo(filter.productId!);
    }

    return await query.findAll();
  }

  /// Get ledger entries by type for date range.
  Future<List<StockLedgerEntity>> getLedgerByType(
    LedgerTransactionType type,
    DateTime startDate,
    DateTime endDate, {
    String? productId,
  }) async {
    var query = _isar.stockLedgerEntitys
        .filter()
        .not()
        .syncStatusEqualTo(LedgerSyncStatus.deleted)
        .ledgerTypeEqualTo(type)
        .transactionDateBetween(startDate, endDate);

    if (productId != null) {
      query = query.productIdEqualTo(productId);
    }

    return await query.findAll();
  }

  /// Get product IDs that have return entries (SALE_RETURN or PURCHASE_RETURN).
  Future<Set<String>> getReturnedProductIds(
      DateTime startDate, DateTime endDate) async {
    final saleReturns = await getLedgerByType(
        LedgerTransactionType.SALE_RETURN, startDate, endDate);
    final purchaseReturns = await getLedgerByType(
        LedgerTransactionType.PURCHASE_RETURN, startDate, endDate);

    final ids = <String>{};
    for (final e in saleReturns) {
      ids.add(e.productId);
    }
    for (final e in purchaseReturns) {
      ids.add(e.productId);
    }
    return ids;
  }

  // ─────────── PRODUCTS ───────────

  /// Get all active products, optionally filtered.
  Future<List<ProductEntity>> getProducts({
    String? productId,
    bool lowStockOnly = false,
    int lowStockThreshold = 5,
  }) async {
    var query = _isar.productEntitys
        .filter()
        .isActiveEqualTo(true)
        .not()
        .syncStatusEqualTo(SyncStatus.deleted);

    if (productId != null) {
      query = query.serverIdEqualTo(productId);
    }

    final results = await query.findAll();

    if (lowStockOnly) {
      return results
          .where((p) => p.currentStock <= lowStockThreshold)
          .toList();
    }

    return results;
  }

  /// Search products by name (for dropdown).
  Future<List<ProductEntity>> searchProducts(String query) async {
    if (query.isEmpty) {
      return await _isar.productEntitys
          .filter()
          .isActiveEqualTo(true)
          .not()
          .syncStatusEqualTo(SyncStatus.deleted)
          .sortByName()
          .limit(50)
          .findAll();
    }
    return await _isar.productEntitys
        .filter()
        .isActiveEqualTo(true)
        .not()
        .syncStatusEqualTo(SyncStatus.deleted)
        .nameContains(query, caseSensitive: false)
        .sortByName()
        .limit(50)
        .findAll();
  }

  // ─────────── SUPPLIERS ───────────

  /// Get all active suppliers (for dropdown).
  Future<List<SupplierEntity>> getSuppliers() async {
    return await _isar.supplierEntitys
        .filter()
        .isActiveEqualTo(true)
        .not()
        .syncStatusEqualTo(SupplierSyncStatus.deleted)
        .sortByFirstName()
        .findAll();
  }
}

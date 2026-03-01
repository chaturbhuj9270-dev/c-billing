import 'package:flutter/foundation.dart';
import '../../../inventory_management/offline/entities/purchase_batch_entity.dart';
import '../../../inventory_management/offline/entities/stock_ledger_entity.dart';
import '../../domain/models/report_filter_model.dart';
import '../../domain/models/report_result_model.dart';
import '../repositories/report_repository.dart';

/// Service handling all report business logic and calculations.
/// Uses optimized queries from ReportRepository — no full-table scans.
class ReportService {
  final ReportRepository _repo;

  ReportService._() : _repo = ReportRepository.instance;

  static ReportService? _instance;
  static ReportService get instance {
    _instance ??= ReportService._();
    return _instance!;
  }

  /// Generate a complete report based on filters.
  /// Uses parallel queries + aggregation for performance.
  Future<ReportResultModel> generateReport(ReportFilterModel filter) async {
    try {
      // ── 1. Parallel data fetch ──
      final results = await Future.wait([
        _repo.getLedgerEntries(filter, type: LedgerTransactionType.PURCHASE),
        _repo.getLedgerEntries(filter, type: LedgerTransactionType.SALE),
        _repo.getLedgerEntries(filter, type: LedgerTransactionType.SALE_RETURN),
        _repo.getLedgerEntries(
          filter,
          type: LedgerTransactionType.PURCHASE_RETURN,
        ),
        _repo.getAllActiveBatches(
          productId: filter.productId,
          supplierId: filter.supplierId,
        ),
      ]);

      final purchaseLedgers = results[0] as List<StockLedgerEntity>;
      final saleLedgers = results[1] as List<StockLedgerEntity>;
      final saleReturnLedgers = results[2] as List<StockLedgerEntity>;
      final purchaseReturnLedgers = results[3] as List<StockLedgerEntity>;
      final allBatches = results[4] as List<PurchaseBatchEntity>;

      // ── 2. Collect all product IDs ──
      final productIds = <String>{};
      for (final e in purchaseLedgers) {
        productIds.add(e.productId);
      }
      for (final e in saleLedgers) {
        productIds.add(e.productId);
      }
      for (final e in saleReturnLedgers) {
        productIds.add(e.productId);
      }
      for (final e in purchaseReturnLedgers) {
        productIds.add(e.productId);
      }

      // Include ALL batch products (not just remaining > 0) so that:
      // - Products with zero stock still appear when they had transactions
      // - Advanced filters (expired, low stock, etc.) work on all products
      // - Product/supplier-specific filters show complete data
      for (final b in allBatches) {
        productIds.add(b.productId);
      }

      // If still no data from ledger or batches, try loading products directly
      // This handles cases where filters are set but no ledger/batch data exists yet
      if (productIds.isEmpty && filter.hasAdvancedFilters) {
        final products = await _repo.getProducts(
          productId: filter.productId,
          lowStockOnly: filter.lowStockOnly,
          lowStockThreshold: filter.lowStockThreshold,
        );
        for (final p in products) {
          if (p.serverId != null) productIds.add(p.serverId!);
        }
      }

      if (productIds.isEmpty) {
        return ReportResultModel(
          rows: [],
          totalPurchaseAmount: 0,
          totalSalesAmount: 0,
          totalProfit: 0,
          totalLoss: 0,
          expiredStockValue: 0,
          returnedStockValue: 0,
          totalProducts: 0,
          generatedAt: DateTime.now(),
          filterSummary: filter.filterSummary,
        );
      }

      // ── 3. Aggregate by product ──
      final purchaseMap = _aggregateByProduct(purchaseLedgers);
      final saleMap = _aggregateByProduct(saleLedgers);
      final saleReturnMap = _aggregateByProduct(saleReturnLedgers);
      final purchaseReturnMap = _aggregateByProduct(purchaseReturnLedgers);

      // ── 4. Build product info from batches ──
      final productInfo = <String, _ProductInfo>{};
      // Track which products belong to the filtered supplier
      final supplierProductIds = <String>{};
      for (final b in allBatches) {
        final info = productInfo.putIfAbsent(b.productId, () => _ProductInfo());
        info.productName = b.productName;
        info.companyName = b.companyName;
        info.supplierName = b.supplierName ?? '';
        info.totalRemaining += b.quantityRemaining;
        info.latestPurchasePrice = b.purchasePrice;
        info.latestSellingPrice = b.sellingPrice;
        supplierProductIds.add(b.productId);
        // Track expiry
        if (b.expiryDate != null && b.quantityRemaining > 0) {
          final now = DateTime.now();
          if (b.expiryDate!.isBefore(now)) {
            info.isExpired = true;
            info.expiredValue += b.purchasePrice * b.quantityRemaining;
            info.earliestExpiry ??= b.expiryDate;
            if (b.expiryDate!.isBefore(info.earliestExpiry!)) {
              info.earliestExpiry = b.expiryDate;
            }
          } else {
            // Check expiring this week
            final weekEnd = now.add(Duration(days: 7 - now.weekday));
            final endOfWeek = DateTime(
              weekEnd.year,
              weekEnd.month,
              weekEnd.day,
              23,
              59,
              59,
            );
            if (b.expiryDate!.isBefore(endOfWeek)) {
              info.isExpiringThisWeek = true;
            }
            info.earliestExpiry ??= b.expiryDate;
            if (b.expiryDate!.isBefore(info.earliestExpiry!)) {
              info.earliestExpiry = b.expiryDate;
            }
          }
        }
      }

      // If supplier filter is active, restrict productIds to only supplier's products
      // (ledger entries don't have supplierId, so we cross-reference with batches)
      if (filter.supplierId != null && supplierProductIds.isNotEmpty) {
        productIds.retainAll(supplierProductIds);
        // Also re-add supplier's products in case they had no ledger entries in range
        productIds.addAll(supplierProductIds);
      }

      // ── 5. Build rows ──
      final now = DateTime.now();
      final rows = <ReportProductRow>[];

      // Get returned product IDs for filtering
      final returnedProductIds = <String>{};
      for (final e in saleReturnLedgers) {
        returnedProductIds.add(e.productId);
      }
      for (final e in purchaseReturnLedgers) {
        returnedProductIds.add(e.productId);
      }

      for (final pid in productIds) {
        final pInfo = productInfo[pid];
        final pAgg = purchaseMap[pid];
        final sAgg = saleMap[pid];
        final srAgg = saleReturnMap[pid];
        final prAgg = purchaseReturnMap[pid];

        final purchaseQty = pAgg?.totalQty ?? 0;
        final soldQty = sAgg?.totalQty ?? 0;
        final saleReturnQty = srAgg?.totalQty ?? 0;
        final purchaseReturnQty = prAgg?.totalQty ?? 0;
        final returnedQty = saleReturnQty + purchaseReturnQty;
        final currentStock = pInfo?.totalRemaining ?? 0;
        final purchasePrice =
            pInfo?.latestPurchasePrice ?? pAgg?.avgCostPrice ?? 0.0;
        final sellingPrice =
            pInfo?.latestSellingPrice ?? sAgg?.avgSellingPrice ?? 0.0;
        final totalPurchaseAmt = pAgg?.totalCost ?? 0.0;
        final totalSalesAmt = sAgg?.totalRevenue ?? 0.0;
        final profit = (sAgg?.totalProfit ?? 0.0) + (srAgg?.totalProfit ?? 0.0);
        final isExpired = pInfo?.isExpired ?? false;
        final isExpiringThisWeek = pInfo?.isExpiringThisWeek ?? false;

        // ── Apply advanced filters ──
        if (filter.expiredOnly && !isExpired) continue;
        if (filter.expiringThisWeek && !isExpiringThisWeek && !isExpired)
          continue;
        if (filter.returnedOnly && !returnedProductIds.contains(pid)) continue;
        if (filter.lowStockOnly && currentStock > filter.lowStockThreshold)
          continue;
        if (filter.minPrice != null && purchasePrice < filter.minPrice!)
          continue;
        if (filter.maxPrice != null && purchasePrice > filter.maxPrice!)
          continue;

        rows.add(
          ReportProductRow(
            productId: pid,
            productName: pInfo?.productName ?? pAgg?.productName ?? 'Unknown',
            companyName: pInfo?.companyName ?? pAgg?.companyName ?? '',
            supplierName: pInfo?.supplierName ?? '',
            purchaseQty: purchaseQty,
            soldQty: soldQty,
            returnedQty: returnedQty,
            saleReturnQty: saleReturnQty,
            purchaseReturnQty: purchaseReturnQty,
            currentStock: currentStock,
            purchasePrice: purchasePrice,
            sellingPrice: sellingPrice,
            totalPurchaseAmount: totalPurchaseAmt,
            totalSalesAmount: totalSalesAmt,
            profitOrLoss: profit,
            expiryDate: pInfo?.earliestExpiry,
            isExpired: isExpired,
            isExpiringThisWeek: isExpiringThisWeek,
            isLowStock: currentStock <= filter.lowStockThreshold,
          ),
        );
      }

      // Sort by product name
      rows.sort((a, b) => a.productName.compareTo(b.productName));

      // ── 6. Calculate summary ──
      double totalPurchaseAmount = 0;
      double totalSalesAmount = 0;
      double totalProfit = 0;
      double totalLoss = 0;
      double expiredStockValue = 0;
      double returnedStockValue = 0;
      int expiredCount = 0;
      int expiringThisWeekCount = 0;
      int lowStockCount = 0;
      int returnedCount = 0;

      for (final r in rows) {
        totalPurchaseAmount += r.totalPurchaseAmount;
        totalSalesAmount += r.totalSalesAmount;
        if (r.profitOrLoss >= 0) {
          totalProfit += r.profitOrLoss;
        } else {
          totalLoss += r.profitOrLoss.abs();
        }
        if (r.isExpired) {
          expiredCount++;
          expiredStockValue += r.purchasePrice * r.currentStock;
        }
        if (r.isExpiringThisWeek) expiringThisWeekCount++;
        if (r.isLowStock) lowStockCount++;
        if (r.returnedQty > 0) {
          returnedCount++;
          returnedStockValue += r.purchasePrice * r.returnedQty;
        }
      }

      return ReportResultModel(
        rows: rows,
        totalPurchaseAmount: totalPurchaseAmount,
        totalSalesAmount: totalSalesAmount,
        totalProfit: totalProfit,
        totalLoss: totalLoss,
        expiredStockValue: expiredStockValue,
        returnedStockValue: returnedStockValue,
        totalProducts: rows.length,
        expiredCount: expiredCount,
        expiringThisWeekCount: expiringThisWeekCount,
        lowStockCount: lowStockCount,
        returnedCount: returnedCount,
        generatedAt: now,
        filterSummary: filter.filterSummary,
      );
    } catch (e) {
      debugPrint('[ReportService] Error generating report: $e');
      rethrow;
    }
  }

  /// Aggregate ledger entries by productId
  Map<String, _LedgerAgg> _aggregateByProduct(List<StockLedgerEntity> entries) {
    final map = <String, _LedgerAgg>{};
    for (final e in entries) {
      final agg = map.putIfAbsent(e.productId, () => _LedgerAgg());
      agg.totalQty += e.quantity;
      agg.totalCost += e.totalCost;
      agg.totalRevenue += e.totalRevenue;
      agg.totalProfit += e.profit;
      agg.productName = e.productName;
      agg.companyName = e.companyName;
      agg._costPriceSum += e.costPrice;
      agg._sellingPriceSum += e.sellingPrice;
      agg._count++;
    }
    return map;
  }
}

/// Internal aggregation helper
class _LedgerAgg {
  int totalQty = 0;
  double totalCost = 0;
  double totalRevenue = 0;
  double totalProfit = 0;
  String productName = '';
  String companyName = '';
  double _costPriceSum = 0;
  double _sellingPriceSum = 0;
  int _count = 0;

  double get avgCostPrice => _count > 0 ? _costPriceSum / _count : 0;
  double get avgSellingPrice => _count > 0 ? _sellingPriceSum / _count : 0;
}

/// Internal product info helper
class _ProductInfo {
  String productName = '';
  String companyName = '';
  String supplierName = '';
  int totalRemaining = 0;
  double latestPurchasePrice = 0;
  double latestSellingPrice = 0;
  bool isExpired = false;
  bool isExpiringThisWeek = false;
  double expiredValue = 0;
  DateTime? earliestExpiry;
}

import 'package:intl/intl.dart';

import '../../../../core/services/pack_unit_conversion.dart';

// Represents a single batch/variant entry for a grouped product Each sub-entry has distinct company, price, sell price, purchase date, etc.
class ProductSubEntry {
  final String productId;
  final String productName;
  final String companyName;
  final double purchasePrice;
  final double salesPrice;
  final double stockQuantity;
  final DateTime purchaseDate;
  final String? supplierName;
  final String? modelName;
  final int? batchId;
  final DateTime? expiryDate;
  /// Stock / base unit (Kg, Tablet, Pcs…).
  final String? unit;
  /// Pack container when bulk buy is configured (Bag, Strip, Box).
  final String? packUnit;
  final int unitsPerPack;

  const ProductSubEntry({
    required this.productId,
    required this.productName,
    required this.companyName,
    required this.purchasePrice,
    required this.salesPrice,
    required this.stockQuantity,
    required this.purchaseDate,
    this.supplierName,
    this.modelName,
    this.batchId,
    this.expiryDate,
    this.unit,
    this.packUnit,
    this.unitsPerPack = 1,
  });

  String get unitLabel {
    final u = unit?.trim();
    if (u != null && u.isNotEmpty) return u;
    return 'pcs';
  }

  String get stockQtyText {
    final v = stockQuantity;
    if (v == v.roundToDouble()) return v.toInt().toString();
    return v.toStringAsFixed(2);
  }

  /// Compact pack hint for UI, e.g. "1 Bag" (null when not packed).
  String? get packHint {
    if (!PackUnitConversion.hasPack(
      packUnit: packUnit,
      unitsPerPack: unitsPerPack,
    )) {
      return null;
    }
    final n = PackUnitConversion.normalizeUnitsPerPack(unitsPerPack);
    final packs = (stockQuantity / n).floor();
    final loose = stockQuantity - (packs * n);
    final pack = packUnit!.trim();
    if (loose.abs() < 1e-9) return '$packs $pack';
    final looseText = loose == loose.roundToDouble()
        ? loose.toInt().toString()
        : loose.toStringAsFixed(1);
    return '$packs $pack + $looseText';
  }

  /// e.g. "100 Kg" or "100 Kg (2 Bag)".
  String get stockWithUnit => PackUnitConversion.formatStockLabel(
        baseStock: stockQuantity,
        baseUnit: unitLabel,
        packUnit: packUnit,
        unitsPerPack: unitsPerPack,
      );

  String get formattedDate => DateFormat('dd MMM yyyy').format(purchaseDate);

  // Check if this batch is expired
  bool get isExpired {
    if (expiryDate == null) return false;
    return expiryDate!.isBefore(DateTime.now());
  }

  // Check if this batch is expiring soon (within 30 days)
  bool get isExpiringSoon {
    if (expiryDate == null) return false;
    final now = DateTime.now();
    final thirtyDaysFromNow = now.add(const Duration(days: 30));
    return expiryDate!.isAfter(now) && expiryDate!.isBefore(thirtyDaysFromNow);
  }
}

// Represents a group of products that share the same name but differ in company, price, batch, etc.
class GroupedProduct {
  // The common product name (grouping key)
  final String productName;

  // All individual sub-entries (batches/variants) for this product name
  final List<ProductSubEntry> subEntries;

  const GroupedProduct({
    required this.productName,
    required this.subEntries,
  });

  // Grand total stock across all sub-entries
  double get totalStock =>
      subEntries.fold<double>(0.0, (total, e) => total + e.stockQuantity);

  /// Dominant stock unit for the group (first non-empty).
  String get unitLabel {
    for (final e in subEntries) {
      final u = e.unit?.trim();
      if (u != null && u.isNotEmpty) return u;
    }
    return 'pcs';
  }

  String? get packUnit {
    for (final e in subEntries) {
      final p = e.packUnit?.trim();
      if (p != null && p.isNotEmpty && e.unitsPerPack > 1) return p;
    }
    return null;
  }

  int get unitsPerPack {
    for (final e in subEntries) {
      if (e.packUnit != null &&
          e.packUnit!.trim().isNotEmpty &&
          e.unitsPerPack > 1) {
        return e.unitsPerPack;
      }
    }
    return 1;
  }

  String get totalStockQtyText {
    final v = totalStock;
    if (v == v.roundToDouble()) return v.toInt().toString();
    return v.toStringAsFixed(2);
  }

  String? get packHint {
    if (!PackUnitConversion.hasPack(
      packUnit: packUnit,
      unitsPerPack: unitsPerPack,
    )) {
      return null;
    }
    final n = PackUnitConversion.normalizeUnitsPerPack(unitsPerPack);
    final packs = (totalStock / n).floor();
    final loose = totalStock - (packs * n);
    final pack = packUnit!.trim();
    if (loose.abs() < 1e-9) return '$packs $pack';
    final looseText = loose == loose.roundToDouble()
        ? loose.toInt().toString()
        : loose.toStringAsFixed(1);
    return '$packs $pack + $looseText';
  }

  /// e.g. "100 Kg (2 Bag)" for sugar bought in bags.
  String get totalStockWithUnit => PackUnitConversion.formatStockLabel(
        baseStock: totalStock,
        baseUnit: unitLabel,
        packUnit: packUnit,
        unitsPerPack: unitsPerPack,
      );

  // Number of distinct variants/batches
  int get variantCount => subEntries.length;

  // Whether this group has multiple distinct sub-entries
  bool get hasMultipleVariants => subEntries.length > 1;

  // Lowest purchase price among all sub-entries
  double get minPurchasePrice =>
      subEntries.map((e) => e.purchasePrice).reduce((a, b) => a < b ? a : b);

  // Highest purchase price among all sub-entries
  double get maxPurchasePrice =>
      subEntries.map((e) => e.purchasePrice).reduce((a, b) => a > b ? a : b);

  // Lowest sales price among all sub-entries
  double get minSalesPrice =>
      subEntries.map((e) => e.salesPrice).reduce((a, b) => a < b ? a : b);

  // Highest sales price among all sub-entries
  double get maxSalesPrice =>
      subEntries.map((e) => e.salesPrice).reduce((a, b) => a > b ? a : b);

  // Total stock value across all sub-entries (based on purchase price)
  double get totalStockValue => subEntries.fold<double>(
      0.0, (total, e) => total + (e.stockQuantity * e.purchasePrice));

  // Unique company names
  Set<String> get companies =>
      subEntries.map((e) => e.companyName).where((c) => c.isNotEmpty).toSet();

  // Price range display string for purchase price
  String get purchasePriceRange {
    if (minPurchasePrice == maxPurchasePrice) {
      return '₹${minPurchasePrice.toStringAsFixed(2)}';
    }
    return '₹${minPurchasePrice.toStringAsFixed(0)} - ₹${maxPurchasePrice.toStringAsFixed(0)}';
  }

  // Price range display string for sales price
  String get salesPriceRange {
    if (minSalesPrice == maxSalesPrice) {
      return '₹${minSalesPrice.toStringAsFixed(2)}';
    }
    return '₹${minSalesPrice.toStringAsFixed(0)} - ₹${maxSalesPrice.toStringAsFixed(0)}';
  }

  // Check if low stock (total)
  bool isLowStock({int threshold = 10}) => totalStock <= threshold;

  // Count of expired batches with remaining stock
  int get expiredBatchCount =>
      subEntries.where((e) => e.isExpired && e.stockQuantity > 0).length;

  // Total expired stock quantity
  double get expiredStockCount =>
      subEntries.where((e) => e.isExpired).fold<double>(
            0.0,
            (total, e) => total + e.stockQuantity,
          );

  // Count of batches expiring soon (within 30 days)
  int get expiringSoonBatchCount =>
      subEntries.where((e) => e.isExpiringSoon && e.stockQuantity > 0).length;

  // Check if any batch has expired stock
  bool get hasExpiredStock => expiredBatchCount > 0;

  // Build grouped products from a flat list of products + batch data. Groups by normalized product name (lowercase, trimmed). Products without batch data appear as single-entry groups.
  /// [productById] enriches batch rows with product unit / pack (Bag→Kg, Strip→Tablet).
  static List<GroupedProduct> buildFromBatches(
    List<dynamic> batches, {
    List<dynamic>? productsWithoutBatches,
    Map<String, dynamic>? productById,
  }) {
    final Map<String, List<ProductSubEntry>> groups = {};

    for (final batch in batches) {
      final name = (batch.productName as String).trim();
      final normalizedName = name.toLowerCase();
      final productId = batch.productId as String;
      final product = productById?[productId];

      final batchUnit = (batch.unit as String?)?.trim();
      final productUnit = (product?.unit as String?)?.trim();
      final productPack = (product?.packUnit as String?)?.trim();
      final productUpp = (product?.unitsPerPack as int?) ?? 1;
      final resolvedUnit = (batchUnit != null && batchUnit.isNotEmpty)
          ? batchUnit
          : ((productUnit != null && productUnit.isNotEmpty)
              ? productUnit
              : null);

      final entry = ProductSubEntry(
        productId: productId,
        productName: name,
        companyName: (batch.companyName as String?) ?? '',
        purchasePrice: (batch.purchasePrice as double?) ?? 0.0,
        salesPrice: (batch.sellingPrice as double?) ?? 0.0,
        stockQuantity:
            (batch.quantityRemaining as num?)?.toDouble() ?? 0.0,
        purchaseDate: batch.purchaseDate as DateTime,
        supplierName: batch.supplierName as String?,
        modelName: (batch.modelName as String?)?.isNotEmpty == true
            ? batch.modelName as String
            : null,
        batchId: batch.id as int?,
        expiryDate: batch.expiryDate as DateTime?,
        unit: resolvedUnit,
        packUnit: (productPack != null && productPack.isNotEmpty)
            ? productPack
            : null,
        unitsPerPack: productUpp < 1 ? 1 : productUpp,
      );

      groups.putIfAbsent(normalizedName, () => []).add(entry);
    }

    // Add products that have no batch entries (e.g., initial stock only)
    if (productsWithoutBatches != null) {
      for (final product in productsWithoutBatches) {
        final name = (product.name as String).trim();
        final normalizedName = name.toLowerCase();

        if (!groups.containsKey(normalizedName)) {
          final productUnit = (product.unit as String?)?.trim();
          final productPack = (product.packUnit as String?)?.trim();
          final productUpp =
              (product.unitsPerPack as int?) ?? 1;
          groups[normalizedName] = [
            ProductSubEntry(
              productId: product.id as String,
              productName: name,
              companyName: (product.companyName as String?) ?? '',
              purchasePrice: (product.purchasePrice as double?) ?? 0.0,
              salesPrice: (product.salesPrice as double?) ?? 0.0,
              stockQuantity:
                  (product.currentStock as num?)?.toDouble() ?? 0.0,
              purchaseDate: (product.createdAt as DateTime?) ?? DateTime.now(),
              unit: (productUnit != null && productUnit.isNotEmpty)
                  ? productUnit
                  : null,
              packUnit: (productPack != null && productPack.isNotEmpty)
                  ? productPack
                  : null,
              unitsPerPack: productUpp < 1 ? 1 : productUpp,
            ),
          ];
        }
      }
    }

    // Sort groups alphabetically by product name
    final sortedKeys = groups.keys.toList()..sort();

    return sortedKeys.map((key) {
      final entries = groups[key]!;
      // Sort sub-entries by purchase date (oldest first for FIFO display)
      entries.sort((a, b) => a.purchaseDate.compareTo(b.purchaseDate));
      return GroupedProduct(
        productName: entries.first.productName,
        subEntries: entries,
      );
    }).toList();
  }
}

import 'package:intl/intl.dart';

/// Represents a single batch/variant entry for a grouped product
/// Each sub-entry has distinct company, price, sell price, purchase date, etc.
class ProductSubEntry {
  final String productId;
  final String productName;
  final String companyName;
  final double purchasePrice;
  final double salesPrice;
  final int stockQuantity;
  final DateTime purchaseDate;
  final String? supplierName;
  final String? modelName;
  final int? batchId;

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
  });

  String get formattedDate => DateFormat('dd MMM yyyy').format(purchaseDate);
}

/// Represents a group of products that share the same name
/// but differ in company, price, batch, etc.
class GroupedProduct {
  /// The common product name (grouping key)
  final String productName;

  /// All individual sub-entries (batches/variants) for this product name
  final List<ProductSubEntry> subEntries;

  const GroupedProduct({
    required this.productName,
    required this.subEntries,
  });

  /// Grand total stock across all sub-entries
  int get totalStock =>
      subEntries.fold<int>(0, (sum, e) => sum + e.stockQuantity);

  /// Number of distinct variants/batches
  int get variantCount => subEntries.length;

  /// Whether this group has multiple distinct sub-entries
  bool get hasMultipleVariants => subEntries.length > 1;

  /// Lowest purchase price among all sub-entries
  double get minPurchasePrice =>
      subEntries.map((e) => e.purchasePrice).reduce((a, b) => a < b ? a : b);

  /// Highest purchase price among all sub-entries
  double get maxPurchasePrice =>
      subEntries.map((e) => e.purchasePrice).reduce((a, b) => a > b ? a : b);

  /// Lowest sales price among all sub-entries
  double get minSalesPrice =>
      subEntries.map((e) => e.salesPrice).reduce((a, b) => a < b ? a : b);

  /// Highest sales price among all sub-entries
  double get maxSalesPrice =>
      subEntries.map((e) => e.salesPrice).reduce((a, b) => a > b ? a : b);

  /// Total stock value across all sub-entries (based on purchase price)
  double get totalStockValue => subEntries.fold<double>(
      0.0, (sum, e) => sum + (e.stockQuantity * e.purchasePrice));

  /// Unique company names
  Set<String> get companies =>
      subEntries.map((e) => e.companyName).where((c) => c.isNotEmpty).toSet();

  /// Price range display string for purchase price
  String get purchasePriceRange {
    if (minPurchasePrice == maxPurchasePrice) {
      return '₹${minPurchasePrice.toStringAsFixed(2)}';
    }
    return '₹${minPurchasePrice.toStringAsFixed(0)} - ₹${maxPurchasePrice.toStringAsFixed(0)}';
  }

  /// Price range display string for sales price
  String get salesPriceRange {
    if (minSalesPrice == maxSalesPrice) {
      return '₹${minSalesPrice.toStringAsFixed(2)}';
    }
    return '₹${minSalesPrice.toStringAsFixed(0)} - ₹${maxSalesPrice.toStringAsFixed(0)}';
  }

  /// Check if low stock (total)
  bool isLowStock({int threshold = 10}) => totalStock <= threshold;

  /// Build grouped products from a flat list of products + batch data.
  ///
  /// Groups by normalized product name (lowercase, trimmed).
  /// Products without batch data appear as single-entry groups.
  static List<GroupedProduct> buildFromBatches(
    List<dynamic> batches, {
    List<dynamic>? productsWithoutBatches,
  }) {
    final Map<String, List<ProductSubEntry>> groups = {};

    for (final batch in batches) {
      final name = (batch.productName as String).trim();
      final normalizedName = name.toLowerCase();

      final entry = ProductSubEntry(
        productId: batch.productId as String,
        productName: name,
        companyName: (batch.companyName as String?) ?? '',
        purchasePrice: (batch.purchasePrice as double?) ?? 0.0,
        salesPrice: (batch.sellingPrice as double?) ?? 0.0,
        stockQuantity: (batch.quantityRemaining as int?) ?? 0,
        purchaseDate: batch.purchaseDate as DateTime,
        supplierName: batch.supplierName as String?,
        modelName: (batch.modelName as String?)?.isNotEmpty == true
            ? batch.modelName as String
            : null,
        batchId: batch.id as int?,
      );

      groups.putIfAbsent(normalizedName, () => []).add(entry);
    }

    // Add products that have no batch entries (e.g., initial stock only)
    if (productsWithoutBatches != null) {
      for (final product in productsWithoutBatches) {
        final name = (product.name as String).trim();
        final normalizedName = name.toLowerCase();

        if (!groups.containsKey(normalizedName)) {
          groups[normalizedName] = [
            ProductSubEntry(
              productId: product.id as String,
              productName: name,
              companyName: (product.companyName as String?) ?? '',
              purchasePrice: (product.purchasePrice as double?) ?? 0.0,
              salesPrice: (product.salesPrice as double?) ?? 0.0,
              stockQuantity: (product.currentStock as int?) ?? 0,
              purchaseDate: (product.createdAt as DateTime?) ?? DateTime.now(),
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

/// Filter model for Report generation
/// Encapsulates all possible filter criteria
class ReportFilterModel {
  /// Date range
  final DateTime startDate;
  final DateTime endDate;

  /// Optional product filter (by productId)
  final String? productId;
  final String? productName;

  /// Optional supplier filter (by supplierId)
  final String? supplierId;
  final String? supplierName;

  /// Show only expired products (expiryDate < today)
  final bool expiredOnly;

  /// Show only products expiring this week
  final bool expiringThisWeek;

  /// Show only returned products (having SALE_RETURN or PURCHASE_RETURN entries)
  final bool returnedOnly;

  /// Price range filter (purchase price)
  final double? minPrice;
  final double? maxPrice;

  /// Low stock filter (currentStock <= threshold)
  final bool lowStockOnly;
  final int lowStockThreshold;

  /// Preset label for display
  final String presetLabel;

  const ReportFilterModel({
    required this.startDate,
    required this.endDate,
    this.productId,
    this.productName,
    this.supplierId,
    this.supplierName,
    this.expiredOnly = false,
    this.expiringThisWeek = false,
    this.returnedOnly = false,
    this.minPrice,
    this.maxPrice,
    this.lowStockOnly = false,
    this.lowStockThreshold = 5,
    this.presetLabel = 'Custom',
  });

  /// Today preset
  factory ReportFilterModel.today() {
    final now = DateTime.now();
    return ReportFilterModel(
      startDate: DateTime(now.year, now.month, now.day),
      endDate: DateTime(now.year, now.month, now.day, 23, 59, 59),
      presetLabel: 'Today',
    );
  }

  /// This week preset
  factory ReportFilterModel.thisWeek() {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    return ReportFilterModel(
      startDate: DateTime(weekStart.year, weekStart.month, weekStart.day),
      endDate: DateTime(now.year, now.month, now.day, 23, 59, 59),
      presetLabel: 'This Week',
    );
  }

  /// This month preset
  factory ReportFilterModel.thisMonth() {
    final now = DateTime.now();
    return ReportFilterModel(
      startDate: DateTime(now.year, now.month, 1),
      endDate: DateTime(now.year, now.month, now.day, 23, 59, 59),
      presetLabel: 'This Month',
    );
  }

  /// This year preset
  factory ReportFilterModel.thisYear() {
    final now = DateTime.now();
    return ReportFilterModel(
      startDate: DateTime(now.year, 1, 1),
      endDate: DateTime(now.year, now.month, now.day, 23, 59, 59),
      presetLabel: 'This Year',
    );
  }

  ReportFilterModel copyWith({
    DateTime? startDate,
    DateTime? endDate,
    String? productId,
    String? productName,
    String? supplierId,
    String? supplierName,
    bool? expiredOnly,
    bool? expiringThisWeek,
    bool? returnedOnly,
    double? minPrice,
    double? maxPrice,
    bool? lowStockOnly,
    int? lowStockThreshold,
    String? presetLabel,
    bool clearProduct = false,
    bool clearSupplier = false,
    bool clearMinPrice = false,
    bool clearMaxPrice = false,
  }) {
    return ReportFilterModel(
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      productId: clearProduct ? null : (productId ?? this.productId),
      productName: clearProduct ? null : (productName ?? this.productName),
      supplierId: clearSupplier ? null : (supplierId ?? this.supplierId),
      supplierName: clearSupplier ? null : (supplierName ?? this.supplierName),
      expiredOnly: expiredOnly ?? this.expiredOnly,
      expiringThisWeek: expiringThisWeek ?? this.expiringThisWeek,
      returnedOnly: returnedOnly ?? this.returnedOnly,
      minPrice: clearMinPrice ? null : (minPrice ?? this.minPrice),
      maxPrice: clearMaxPrice ? null : (maxPrice ?? this.maxPrice),
      lowStockOnly: lowStockOnly ?? this.lowStockOnly,
      lowStockThreshold: lowStockThreshold ?? this.lowStockThreshold,
      presetLabel: presetLabel ?? this.presetLabel,
    );
  }

  /// Whether any advanced filter is active
  bool get hasAdvancedFilters =>
      productId != null ||
      supplierId != null ||
      expiredOnly ||
      expiringThisWeek ||
      returnedOnly ||
      minPrice != null ||
      maxPrice != null ||
      lowStockOnly;

  /// Summary string for PDF header
  String get filterSummary {
    final parts = <String>[];
    parts.add('Period: $presetLabel');
    if (productName != null) parts.add('Product: $productName');
    if (supplierName != null) parts.add('Supplier: $supplierName');
    if (expiredOnly) parts.add('Expired Only');
    if (expiringThisWeek) parts.add('Expiring This Week');
    if (returnedOnly) parts.add('Returned Only');
    if (minPrice != null) parts.add('Min Price: ₹${minPrice!.toStringAsFixed(0)}');
    if (maxPrice != null) parts.add('Max Price: ₹${maxPrice!.toStringAsFixed(0)}');
    if (lowStockOnly) parts.add('Low Stock (≤$lowStockThreshold)');
    return parts.join(' | ');
  }
}

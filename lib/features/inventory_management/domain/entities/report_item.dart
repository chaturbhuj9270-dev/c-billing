import 'package:c_billing/features/inventory_management/domain/entities/product.dart';

/// Model for report preview with selectable rows and editable order quantity.
///
/// - [isSelected] controls whether this item is included in the final report.
///   Defaults to `true` (all items selected).
/// - [orderQuantity] is nullable – `null` means the user has not entered a
///   value and should be displayed as "-" in the UI and reports.
/// - [expiryDate] is optional; shown as "-" when absent.
class ReportItem {
  final Product product;
  final int availableQuantity;
  int? orderQuantity;
  bool isSelected;
  final DateTime? expiryDate;

  ReportItem({
    required this.product,
    required this.availableQuantity,
    this.orderQuantity,
    this.isSelected = true,
    this.expiryDate,
  });

  /// Create from Product entity.
  /// [initialOrderQty] defaults to `null` (displayed as "-").
  factory ReportItem.fromProduct(
    Product product, {
    int? initialOrderQty,
    DateTime? expiryDate,
  }) {
    return ReportItem(
      product: product,
      availableQuantity: product.currentStock,
      orderQuantity: initialOrderQty,
      isSelected: true,
      expiryDate: expiryDate,
    );
  }

  /// Update order quantity with validation.
  /// Negative values are rejected; `null` is accepted (means "not set").
  void updateOrderQuantity(int? newQuantity) {
    if (newQuantity != null && newQuantity < 0) {
      orderQuantity = null;
    } else {
      orderQuantity = newQuantity;
    }
  }

  /// Get suggested reorder quantity based on stock status
  int getSuggestedReorderQuantity() {
    if (availableQuantity == 0) {
      return 50; // Default for out of stock
    } else if (availableQuantity <= 10) {
      return 30; // Default for low stock
    }
    return 0; // No reorder needed
  }

  /// Formatted order quantity for display: shows "-" when null.
  String get orderQtyDisplay => orderQuantity?.toString() ?? '-';

  /// Formatted expiry date for display: shows "-" when null.
  String get expiryDateDisplay {
    if (expiryDate == null) return '-';
    return '${expiryDate!.day.toString().padLeft(2, '0')}/'
        '${expiryDate!.month.toString().padLeft(2, '0')}/'
        '${expiryDate!.year}';
  }

  /// Copy with updated values
  ReportItem copyWith({
    Product? product,
    int? availableQuantity,
    int? Function()? orderQuantity,
    bool? isSelected,
    DateTime? Function()? expiryDate,
  }) {
    return ReportItem(
      product: product ?? this.product,
      availableQuantity: availableQuantity ?? this.availableQuantity,
      orderQuantity: orderQuantity != null
          ? orderQuantity()
          : this.orderQuantity,
      isSelected: isSelected ?? this.isSelected,
      expiryDate: expiryDate != null ? expiryDate() : this.expiryDate,
    );
  }
}

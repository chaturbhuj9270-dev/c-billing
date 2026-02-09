import 'package:c_billing/features/inventory_management/domain/entities/product.dart';

/// Model for report preview with editable order quantity
class ReportItem {
  final Product product;
  final int availableQuantity;
  int orderQuantity;

  ReportItem({
    required this.product,
    required this.availableQuantity,
    this.orderQuantity = 0,
  });

  /// Create from Product entity
  factory ReportItem.fromProduct(Product product, {int initialOrderQty = 0}) {
    return ReportItem(
      product: product,
      availableQuantity: product.currentStock,
      orderQuantity: initialOrderQty,
    );
  }

  /// Update order quantity with validation
  void updateOrderQuantity(int newQuantity) {
    if (newQuantity < 0) {
      orderQuantity = 0;
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

  /// Copy with updated values
  ReportItem copyWith({
    Product? product,
    int? availableQuantity,
    int? orderQuantity,
  }) {
    return ReportItem(
      product: product ?? this.product,
      availableQuantity: availableQuantity ?? this.availableQuantity,
      orderQuantity: orderQuantity ?? this.orderQuantity,
    );
  }
}

import 'package:uuid/uuid.dart';
import '../../../inventory_management/domain/entities/product.dart';
import '../../../product/offline/entities/product_entity.dart';

/// Represents a product item in a sales order
/// Note: Stock is NOT deducted when creating order. Only when converting to bill.
class OrderItem {
  /// Unique identifier for this order item
  final String id;
  
  /// Product ID
  final String productId;
  
  /// Product name
  final String productName;
  
  /// HSN code (if applicable)
  final String? hsnCode;
  
  /// Quantity ordered
  final int quantity;
  
  /// Rate per unit
  final double rate;
  
  /// Discount percentage (0-100)
  final double discountPercent;
  
  /// Discount amount
  final double discountAmount;
  
  /// CGST percentage
  final double cgstPercent;
  
  /// SGST percentage
  final double sgstPercent;
  
  /// CGST amount
  final double cgstAmount;
  
  /// SGST amount
  final double sgstAmount;
  
  /// Total tax amount
  final double taxAmount;
  
  /// Subtotal before tax and discount
  final double subtotal;
  
  /// Total amount after discount and tax
  final double total;
  
  const OrderItem({
    required this.id,
    required this.productId,
    required this.productName,
    this.hsnCode,
    required this.quantity,
    required this.rate,
    this.discountPercent = 0.0,
    this.discountAmount = 0.0,
    this.cgstPercent = 0.0,
    this.sgstPercent = 0.0,
    this.cgstAmount = 0.0,
    this.sgstAmount = 0.0,
    this.taxAmount = 0.0,
    required this.subtotal,
    required this.total,
  });
  
  /// Create from product with calculated values
  factory OrderItem.fromProductData({
    required String id,
    required String productId,
    required String productName,
    String? hsnCode,
    required int quantity,
    required double rate,
    double discountPercent = 0.0,
    double cgstPercent = 0.0,
    double sgstPercent = 0.0,
  }) {
    final subtotal = quantity * rate;
    final discountAmount = subtotal * (discountPercent / 100);
    final afterDiscount = subtotal - discountAmount;
    final cgstAmount = afterDiscount * (cgstPercent / 100);
    final sgstAmount = afterDiscount * (sgstPercent / 100);
    final taxAmount = cgstAmount + sgstAmount;
    final total = afterDiscount + taxAmount;
    
    return OrderItem(
      id: id,
      productId: productId,
      productName: productName,
      hsnCode: hsnCode,
      quantity: quantity,
      rate: rate,
      discountPercent: discountPercent,
      discountAmount: discountAmount,
      cgstPercent: cgstPercent,
      sgstPercent: sgstPercent,
      cgstAmount: cgstAmount,
      sgstAmount: sgstAmount,
      taxAmount: taxAmount,
      subtotal: subtotal,
      total: total,
    );
  }
  
  /// Create from Product domain entity
  factory OrderItem.fromProduct({
    required Product product,
    required int quantity,
    double? rate,
    double discountPercent = 0.0,
  }) {
    final uuid = const Uuid();
    final actualRate = rate ?? product.salesPrice;
    
    return OrderItem.fromProductData(
      id: uuid.v4(),
      productId: product.id,
      productName: product.name,
      hsnCode: product.hsnCode,
      quantity: quantity,
      rate: actualRate,
      discountPercent: discountPercent,
      cgstPercent: product.cgstPercent,
      sgstPercent: product.sgstPercent,
    );
  }
  
  /// Create from ProductEntity (Isar offline entity)
  factory OrderItem.fromProductEntity({
    required ProductEntity entity,
    required int quantity,
    double? rate,
    double discountPercent = 0.0,
  }) {
    final uuid = const Uuid();
    final actualRate = rate ?? entity.salesPrice;
    
    return OrderItem.fromProductData(
      id: uuid.v4(),
      productId: entity.serverId ?? 'local_${entity.id}',
      productName: entity.name,
      hsnCode: entity.hsnCode,
      quantity: quantity,
      rate: actualRate,
      discountPercent: discountPercent,
      cgstPercent: entity.cgstPercent,
      sgstPercent: entity.sgstPercent,
    );
  }
  
  /// Create a copy with updated fields and recalculations
  OrderItem copyWith({
    String? id,
    String? productId,
    String? productName,
    String? hsnCode,
    int? quantity,
    double? rate,
    double? discountPercent,
    double? cgstPercent,
    double? sgstPercent,
  }) {
    final newQuantity = quantity ?? this.quantity;
    final newRate = rate ?? this.rate;
    final newDiscountPercent = discountPercent ?? this.discountPercent;
    final newCgstPercent = cgstPercent ?? this.cgstPercent;
    final newSgstPercent = sgstPercent ?? this.sgstPercent;
    
    final subtotal = newQuantity * newRate;
    final discountAmount = subtotal * (newDiscountPercent / 100);
    final afterDiscount = subtotal - discountAmount;
    final cgstAmount = afterDiscount * (newCgstPercent / 100);
    final sgstAmount = afterDiscount * (newSgstPercent / 100);
    final taxAmount = cgstAmount + sgstAmount;
    final total = afterDiscount + taxAmount;
    
    return OrderItem(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      hsnCode: hsnCode ?? this.hsnCode,
      quantity: newQuantity,
      rate: newRate,
      discountPercent: newDiscountPercent,
      discountAmount: discountAmount,
      cgstPercent: newCgstPercent,
      sgstPercent: newSgstPercent,
      cgstAmount: cgstAmount,
      sgstAmount: sgstAmount,
      taxAmount: taxAmount,
      subtotal: subtotal,
      total: total,
    );
  }
  
  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'productId': productId,
      'productName': productName,
      'hsnCode': hsnCode,
      'quantity': quantity,
      'rate': rate,
      'discountPercent': discountPercent,
      'discountAmount': discountAmount,
      'cgstPercent': cgstPercent,
      'sgstPercent': sgstPercent,
      'cgstAmount': cgstAmount,
      'sgstAmount': sgstAmount,
      'taxAmount': taxAmount,
      'subtotal': subtotal,
      'total': total,
    };
  }
  
  /// Create from JSON
  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      id: json['id'] as String,
      productId: json['productId'] as String? ?? '',
      productName: json['productName'] as String? ?? '',
      hsnCode: json['hsnCode'] as String?,
      quantity: json['quantity'] as int? ?? 0,
      rate: (json['rate'] as num?)?.toDouble() ?? 0.0,
      discountPercent: (json['discountPercent'] as num?)?.toDouble() ?? 0.0,
      discountAmount: (json['discountAmount'] as num?)?.toDouble() ?? 0.0,
      cgstPercent: (json['cgstPercent'] as num?)?.toDouble() ?? 0.0,
      sgstPercent: (json['sgstPercent'] as num?)?.toDouble() ?? 0.0,
      cgstAmount: (json['cgstAmount'] as num?)?.toDouble() ?? 0.0,
      sgstAmount: (json['sgstAmount'] as num?)?.toDouble() ?? 0.0,
      taxAmount: (json['taxAmount'] as num?)?.toDouble() ?? 0.0,
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0.0,
      total: (json['total'] as num?)?.toDouble() ?? 0.0,
    );
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is OrderItem && other.id == id;
  }
  
  @override
  int get hashCode => id.hashCode;
}

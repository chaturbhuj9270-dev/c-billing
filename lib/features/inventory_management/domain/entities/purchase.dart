class Purchase {
  final String id;
  final String productId;
  final int quantity;
  final double purchasePrice;
  final double totalAmount;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  Purchase({
    required this.id,
    required this.productId,
    required this.quantity,
    required this.purchasePrice,
    required this.totalAmount,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  // Factory constructor to create from JSON
  factory Purchase.fromJson(Map<String, dynamic> json) {
    try {
      return Purchase(
        id: (json['id'] ?? '') as String,
        productId: (json['productId'] ?? '') as String,
        quantity: (json['quantity'] ?? 0) as int,
        purchasePrice: ((json['purchasePrice'] ?? 0) as num).toDouble(),
        totalAmount: ((json['totalAmount'] ?? 0) as num).toDouble(),
        notes: json['notes'] as String?,
        createdAt: json['createdAt'] != null
            ? DateTime.parse(json['createdAt'] as String)
            : DateTime.now(),
        updatedAt: json['updatedAt'] != null
            ? DateTime.parse(json['updatedAt'] as String)
            : DateTime.now(),
      );
    } catch (e) {
      print('[ERROR] Failed to parse Purchase from JSON: $json');
      print('[ERROR] Error details: $e');
      // Return a default purchase entry
      return Purchase(
        id: json['id']?.toString() ?? '',
        productId: json['productId']?.toString() ?? '',
        quantity: 0,
        purchasePrice: 0.0,
        totalAmount: 0.0,
        notes: null,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'productId': productId,
      'quantity': quantity,
      'purchasePrice': purchasePrice,
      'totalAmount': totalAmount,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // Copy with modifications
  Purchase copyWith({
    String? id,
    String? productId,
    int? quantity,
    double? purchasePrice,
    double? totalAmount,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Purchase(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      quantity: quantity ?? this.quantity,
      purchasePrice: purchasePrice ?? this.purchasePrice,
      totalAmount: totalAmount ?? this.totalAmount,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class Product {
  final String id;
  final String name;
  final String category;
  final double purchasePrice;
  final double salesPrice;
  final int currentStock;
  final DateTime createdAt;
  final DateTime updatedAt;

  Product({
    required this.id,
    required this.name,
    required this.category,
    required this.purchasePrice,
    required this.salesPrice,
    required this.currentStock,
    required this.createdAt,
    required this.updatedAt,
  });

  // Factory constructor to create from JSON (for Firebase)
  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as String,
      name: json['name'] as String,
      category: json['category'] as String,
      purchasePrice: (json['purchasePrice'] as num).toDouble(),
      salesPrice: (json['salesPrice'] as num).toDouble(),
      currentStock: json['currentStock'] as int? ?? 0,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  // Convert to JSON for Firebase
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'purchasePrice': purchasePrice,
      'salesPrice': salesPrice,
      'currentStock': currentStock,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // Copy with modifications
  Product copyWith({
    String? id,
    String? name,
    String? category,
    double? purchasePrice,
    double? salesPrice,
    int? currentStock,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      purchasePrice: purchasePrice ?? this.purchasePrice,
      salesPrice: salesPrice ?? this.salesPrice,
      currentStock: currentStock ?? this.currentStock,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Get total stock value based on purchase price
  double getStockValue() {
    return currentStock * purchasePrice;
  }

  // Check if low stock
  bool isLowStock({int threshold = 10}) {
    return currentStock <= threshold;
  }
}

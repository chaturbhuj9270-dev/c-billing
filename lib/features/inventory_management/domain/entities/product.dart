class Product {
  final String id;
  final String name;
  final String companyName;
  final String category;
  final double purchasePrice;
  final double salesPrice;
  final int currentStock;
  final DateTime createdAt;
  final DateTime updatedAt;

  Product({
    required this.id,
    required this.name,
    required this.companyName,
    required this.category,
    required this.purchasePrice,
    required this.salesPrice,
    required this.currentStock,
    required this.createdAt,
    required this.updatedAt,
  });

  // Factory constructor to create from JSON (for Firebase)
  factory Product.fromJson(Map<String, dynamic> json) {
    try {
      return Product(
        id: (json['id'] ?? '') as String,
        name: (json['name'] ?? '') as String,
        companyName: (json['companyName'] ?? '') as String,
        category: (json['category'] ?? '') as String,
        purchasePrice: ((json['purchasePrice'] ?? 0) as num).toDouble(),
        salesPrice: ((json['salesPrice'] ?? 0) as num).toDouble(),
        currentStock: (json['currentStock'] ?? 0) as int,
        createdAt: json['createdAt'] != null 
            ? DateTime.parse(json['createdAt'] as String)
            : DateTime.now(),
        updatedAt: json['updatedAt'] != null
            ? DateTime.parse(json['updatedAt'] as String)
            : DateTime.now(),
      );
    } catch (e) {
      print('[ERROR] Failed to parse Product from JSON: $json');
      print('[ERROR] Error details: $e');
      // Return a default product to prevent crashes
      return Product(
        id: json['id']?.toString() ?? '',
        name: json['name']?.toString() ?? 'Unknown Product',
        companyName: json['companyName']?.toString() ?? '',
        category: json['category']?.toString() ?? 'Uncategorized',
        purchasePrice: 0.0,
        salesPrice: 0.0,
        currentStock: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }
  }

  // Convert to JSON for Firebase
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'companyName': companyName,
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
    String? companyName,
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
      companyName: companyName ?? this.companyName,
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

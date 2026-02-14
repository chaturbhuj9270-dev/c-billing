/// Represents a purchase batch for FIFO inventory management.
/// Each purchase creates a separate batch even for the same product.
/// 
/// Unique product identification is based on: productName + companyName + modelName
/// Different purchase prices result in different batches.
class PurchaseBatch {
  /// Unique identifier for this batch
  final String batchId;
  
  /// Product ID (reference to Product)
  final String productId;
  
  /// Product name for quick reference
  final String productName;
  
  /// Company/Brand name
  final String companyName;
  
  /// Model name or variant
  final String modelName;
  
  /// Category of the product
  final String category;
  
  /// Purchase price per unit for this batch
  final double purchasePrice;
  
  /// Selling price per unit for this batch
  final double sellingPrice;
  
  /// Original quantity purchased in this batch
  final int quantityPurchased;
  
  /// Remaining quantity available for sale (FIFO tracking)
  final int quantityRemaining;
  
  /// Date when this batch was purchased
  final DateTime purchaseDate;
  
  /// Supplier ID (optional)
  final String? supplierId;
  
  /// Supplier name (optional)
  final String? supplierName;
  
  /// Unit of measurement
  final String unit;
  
  /// Expiry date (optional)
  final DateTime? expiryDate;
  
  /// Production/Manufacturing date (optional)
  final DateTime? productionDate;
  
  /// Warranty in months (optional)
  final int? warrantyMonths;
  
  /// Notes for this batch
  final String? notes;
  
  /// Whether this batch is fully consumed
  final bool isConsumed;
  
  /// When the record was created
  final DateTime createdAt;
  
  /// When the record was last updated
  final DateTime updatedAt;

  PurchaseBatch({
    required this.batchId,
    required this.productId,
    required this.productName,
    required this.companyName,
    this.modelName = '',
    this.category = '',
    required this.purchasePrice,
    required this.sellingPrice,
    required this.quantityPurchased,
    required this.quantityRemaining,
    required this.purchaseDate,
    this.supplierId,
    this.supplierName,
    this.unit = 'pcs',
    this.expiryDate,
    this.productionDate,
    this.warrantyMonths,
    this.notes,
    this.isConsumed = false,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Generate unique product key based on name + company + model
  String get productUniqueKey => 
      '${productName.toLowerCase().trim()}_${companyName.toLowerCase().trim()}_${modelName.toLowerCase().trim()}';

  /// Total purchase value for this batch
  double get totalPurchaseValue => purchasePrice * quantityPurchased;
  
  /// Remaining value of this batch
  double get remainingValue => purchasePrice * quantityRemaining;
  
  /// Quantity already sold from this batch
  int get quantitySold => quantityPurchased - quantityRemaining;

  /// Factory constructor to create from JSON (for Firebase)
  factory PurchaseBatch.fromJson(Map<String, dynamic> json) {
    try {
      return PurchaseBatch(
        batchId: (json['batchId'] ?? json['id'] ?? '') as String,
        productId: (json['productId'] ?? '') as String,
        productName: (json['productName'] ?? '') as String,
        companyName: (json['companyName'] ?? '') as String,
        modelName: (json['modelName'] ?? '') as String,
        category: (json['category'] ?? '') as String,
        purchasePrice: ((json['purchasePrice'] ?? 0) as num).toDouble(),
        sellingPrice: ((json['sellingPrice'] ?? 0) as num).toDouble(),
        quantityPurchased: (json['quantityPurchased'] ?? 0) as int,
        quantityRemaining: (json['quantityRemaining'] ?? 0) as int,
        purchaseDate: json['purchaseDate'] != null
            ? DateTime.parse(json['purchaseDate'] as String)
            : DateTime.now(),
        supplierId: json['supplierId'] as String?,
        supplierName: json['supplierName'] as String?,
        unit: (json['unit'] ?? 'pcs') as String,
        expiryDate: json['expiryDate'] != null
            ? DateTime.parse(json['expiryDate'] as String)
            : null,
        productionDate: json['productionDate'] != null
            ? DateTime.parse(json['productionDate'] as String)
            : null,
        warrantyMonths: json['warrantyMonths'] as int?,
        notes: json['notes'] as String?,
        isConsumed: (json['isConsumed'] ?? false) as bool,
        createdAt: json['createdAt'] != null
            ? DateTime.parse(json['createdAt'] as String)
            : DateTime.now(),
        updatedAt: json['updatedAt'] != null
            ? DateTime.parse(json['updatedAt'] as String)
            : DateTime.now(),
      );
    } catch (e) {
      print('[ERROR] Failed to parse PurchaseBatch from JSON: $json');
      print('[ERROR] Error details: $e');
      return PurchaseBatch(
        batchId: json['batchId']?.toString() ?? '',
        productId: json['productId']?.toString() ?? '',
        productName: json['productName']?.toString() ?? 'Unknown',
        companyName: json['companyName']?.toString() ?? '',
        purchasePrice: 0.0,
        sellingPrice: 0.0,
        quantityPurchased: 0,
        quantityRemaining: 0,
        purchaseDate: DateTime.now(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }
  }

  /// Convert to JSON for Firebase
  Map<String, dynamic> toJson() {
    return {
      'batchId': batchId,
      'productId': productId,
      'productName': productName,
      'companyName': companyName,
      'modelName': modelName,
      'category': category,
      'purchasePrice': purchasePrice,
      'sellingPrice': sellingPrice,
      'quantityPurchased': quantityPurchased,
      'quantityRemaining': quantityRemaining,
      'purchaseDate': purchaseDate.toIso8601String(),
      'supplierId': supplierId,
      'supplierName': supplierName,
      'unit': unit,
      'expiryDate': expiryDate?.toIso8601String(),
      'productionDate': productionDate?.toIso8601String(),
      'warrantyMonths': warrantyMonths,
      'notes': notes,
      'isConsumed': isConsumed,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'productUniqueKey': productUniqueKey,
    };
  }

  /// Copy with modifications
  PurchaseBatch copyWith({
    String? batchId,
    String? productId,
    String? productName,
    String? companyName,
    String? modelName,
    String? category,
    double? purchasePrice,
    double? sellingPrice,
    int? quantityPurchased,
    int? quantityRemaining,
    DateTime? purchaseDate,
    String? supplierId,
    String? supplierName,
    String? unit,
    DateTime? expiryDate,
    DateTime? productionDate,
    int? warrantyMonths,
    String? notes,
    bool? isConsumed,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PurchaseBatch(
      batchId: batchId ?? this.batchId,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      companyName: companyName ?? this.companyName,
      modelName: modelName ?? this.modelName,
      category: category ?? this.category,
      purchasePrice: purchasePrice ?? this.purchasePrice,
      sellingPrice: sellingPrice ?? this.sellingPrice,
      quantityPurchased: quantityPurchased ?? this.quantityPurchased,
      quantityRemaining: quantityRemaining ?? this.quantityRemaining,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      supplierId: supplierId ?? this.supplierId,
      supplierName: supplierName ?? this.supplierName,
      unit: unit ?? this.unit,
      expiryDate: expiryDate ?? this.expiryDate,
      productionDate: productionDate ?? this.productionDate,
      warrantyMonths: warrantyMonths ?? this.warrantyMonths,
      notes: notes ?? this.notes,
      isConsumed: isConsumed ?? this.isConsumed,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'PurchaseBatch(batchId: $batchId, product: $productName, company: $companyName, remaining: $quantityRemaining/$quantityPurchased)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PurchaseBatch && other.batchId == batchId;
  }

  @override
  int get hashCode => batchId.hashCode;
}

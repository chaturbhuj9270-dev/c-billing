enum ReferenceType {
  PURCHASE,
  SALE,
  ADJUSTMENT,
}

extension ReferenceTypeExtension on ReferenceType {
  String toShortString() {
    return toString().split('.').last;
  }

  static ReferenceType fromString(String value) {
    return ReferenceType.values.firstWhere(
      (e) => e.toShortString() == value,
      orElse: () => ReferenceType.ADJUSTMENT,
    );
  }
}

class Stock {
  final String id;
  final String productId;
  final int quantityIn;
  final int quantityOut;
  final int balanceQuantity;
  final ReferenceType referenceType;
  final String referenceId;
  final DateTime createdAt;

  Stock({
    required this.id,
    required this.productId,
    required this.quantityIn,
    required this.quantityOut,
    required this.balanceQuantity,
    required this.referenceType,
    required this.referenceId,
    required this.createdAt,
  });

  // Factory constructor to create from JSON
  factory Stock.fromJson(Map<String, dynamic> json) {
    try {
      return Stock(
        id: (json['id'] ?? '') as String,
        productId: (json['productId'] ?? '') as String,
        quantityIn: (json['quantityIn'] ?? 0) as int,
        quantityOut: (json['quantityOut'] ?? 0) as int,
        balanceQuantity: (json['balanceQuantity'] ?? 0) as int,
        referenceType: ReferenceTypeExtension.fromString(
          (json['referenceType'] ?? 'ADJUSTMENT') as String,
        ),
        referenceId: (json['referenceId'] ?? '') as String,
        createdAt: json['createdAt'] != null
            ? DateTime.parse(json['createdAt'] as String)
            : DateTime.now(),
      );
    } catch (e) {
      print('[ERROR] Failed to parse Stock from JSON: $json');
      print('[ERROR] Error details: $e');
      // Return a default stock entry
      return Stock(
        id: json['id']?.toString() ?? '',
        productId: json['productId']?.toString() ?? '',
        quantityIn: 0,
        quantityOut: 0,
        balanceQuantity: 0,
        referenceType: ReferenceType.ADJUSTMENT,
        referenceId: '',
        createdAt: DateTime.now(),
      );
    }
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'productId': productId,
      'quantityIn': quantityIn,
      'quantityOut': quantityOut,
      'balanceQuantity': balanceQuantity,
      'referenceType': referenceType.toShortString(),
      'referenceId': referenceId,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  // Get net quantity change
  int getNetChange() {
    return quantityIn - quantityOut;
  }

  // Check if this is an inbound transaction
  bool isInbound() {
    return quantityIn > 0;
  }

  // Copy with method
  Stock copyWith({
    String? id,
    String? productId,
    int? quantityIn,
    int? quantityOut,
    int? balanceQuantity,
    ReferenceType? referenceType,
    String? referenceId,
    DateTime? createdAt,
  }) {
    return Stock(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      quantityIn: quantityIn ?? this.quantityIn,
      quantityOut: quantityOut ?? this.quantityOut,
      balanceQuantity: balanceQuantity ?? this.balanceQuantity,
      referenceType: referenceType ?? this.referenceType,
      referenceId: referenceId ?? this.referenceId,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

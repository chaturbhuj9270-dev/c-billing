/// Type of ledger transaction
enum LedgerType {
  /// Stock increased due to purchase
  PURCHASE,
  
  /// Stock decreased due to sale
  SALE,
  
  /// Stock adjustment (manual correction)
  ADJUSTMENT,
  
  /// Stock returned from customer
  SALE_RETURN,
  
  /// Stock returned to supplier
  PURCHASE_RETURN,
  
  /// Stock transferred between locations
  TRANSFER,
  
  /// Initial stock entry
  OPENING_STOCK,
}

extension LedgerTypeExtension on LedgerType {
  String toShortString() {
    return toString().split('.').last;
  }

  static LedgerType fromString(String value) {
    return LedgerType.values.firstWhere(
      (e) => e.toShortString() == value,
      orElse: () => LedgerType.ADJUSTMENT,
    );
  }
  
  /// Returns true if this transaction type increases stock
  bool get isInbound {
    return this == LedgerType.PURCHASE || 
           this == LedgerType.SALE_RETURN || 
           this == LedgerType.OPENING_STOCK;
  }
  
  /// Returns true if this transaction type decreases stock
  bool get isOutbound {
    return this == LedgerType.SALE || 
           this == LedgerType.PURCHASE_RETURN;
  }
}

/// Represents a single ledger entry for tracking stock movements.
/// Each entry is linked to a specific batch for accurate COGS calculation.
class StockLedger {
  /// Unique identifier for this ledger entry
  final String ledgerId;
  
  /// Product ID
  final String productId;
  
  /// Product name for quick reference
  final String productName;
  
  /// Company name
  final String companyName;
  
  /// Model name
  final String modelName;
  
  /// Batch ID this transaction belongs to (for FIFO tracking)
  final String batchId;
  
  /// Type of transaction
  final LedgerType ledgerType;
  
  /// Reference ID (e.g., Bill ID for sales, Purchase ID for purchases)
  final String referenceId;
  
  /// Reference type (BILL, PURCHASE, ADJUSTMENT, etc.)
  final String referenceType;
  
  /// Quantity moved in this transaction (always positive)
  final int quantity;
  
  /// Cost price per unit from the batch (for COGS calculation)
  final double costPrice;
  
  /// Selling price per unit (for sales transactions)
  final double sellingPrice;
  
  /// Total cost = costPrice * quantity
  final double totalCost;
  
  /// Total revenue = sellingPrice * quantity (for sales)
  final double totalRevenue;
  
  /// Profit for this transaction (for sales)
  final double profit;
  
  /// Balance quantity after this transaction
  final int balanceQuantity;
  
  /// Balance value after this transaction
  final double balanceValue;
  
  /// Date of transaction
  final DateTime transactionDate;
  
  /// Notes for this entry
  final String? notes;
  
  /// When the record was created
  final DateTime createdAt;

  StockLedger({
    required this.ledgerId,
    required this.productId,
    required this.productName,
    this.companyName = '',
    this.modelName = '',
    required this.batchId,
    required this.ledgerType,
    required this.referenceId,
    this.referenceType = '',
    required this.quantity,
    required this.costPrice,
    this.sellingPrice = 0.0,
    required this.totalCost,
    this.totalRevenue = 0.0,
    this.profit = 0.0,
    required this.balanceQuantity,
    required this.balanceValue,
    required this.transactionDate,
    this.notes,
    required this.createdAt,
  });

  /// Generate unique product key based on name + company + model
  String get productUniqueKey => 
      '${productName.toLowerCase().trim()}_${companyName.toLowerCase().trim()}_${modelName.toLowerCase().trim()}';

  /// Factory constructor to create from JSON (for Firebase)
  factory StockLedger.fromJson(Map<String, dynamic> json) {
    try {
      return StockLedger(
        ledgerId: (json['ledgerId'] ?? json['id'] ?? '') as String,
        productId: (json['productId'] ?? '') as String,
        productName: (json['productName'] ?? '') as String,
        companyName: (json['companyName'] ?? '') as String,
        modelName: (json['modelName'] ?? '') as String,
        batchId: (json['batchId'] ?? '') as String,
        ledgerType: LedgerTypeExtension.fromString(
          (json['ledgerType'] ?? 'ADJUSTMENT') as String,
        ),
        referenceId: (json['referenceId'] ?? '') as String,
        referenceType: (json['referenceType'] ?? '') as String,
        quantity: (json['quantity'] ?? 0) as int,
        costPrice: ((json['costPrice'] ?? 0) as num).toDouble(),
        sellingPrice: ((json['sellingPrice'] ?? 0) as num).toDouble(),
        totalCost: ((json['totalCost'] ?? 0) as num).toDouble(),
        totalRevenue: ((json['totalRevenue'] ?? 0) as num).toDouble(),
        profit: ((json['profit'] ?? 0) as num).toDouble(),
        balanceQuantity: (json['balanceQuantity'] ?? 0) as int,
        balanceValue: ((json['balanceValue'] ?? 0) as num).toDouble(),
        transactionDate: json['transactionDate'] != null
            ? DateTime.parse(json['transactionDate'] as String)
            : DateTime.now(),
        notes: json['notes'] as String?,
        createdAt: json['createdAt'] != null
            ? DateTime.parse(json['createdAt'] as String)
            : DateTime.now(),
      );
    } catch (e) {
      print('[ERROR] Failed to parse StockLedger from JSON: $json');
      print('[ERROR] Error details: $e');
      return StockLedger(
        ledgerId: json['ledgerId']?.toString() ?? '',
        productId: json['productId']?.toString() ?? '',
        productName: json['productName']?.toString() ?? 'Unknown',
        batchId: json['batchId']?.toString() ?? '',
        ledgerType: LedgerType.ADJUSTMENT,
        referenceId: '',
        quantity: 0,
        costPrice: 0.0,
        totalCost: 0.0,
        balanceQuantity: 0,
        balanceValue: 0.0,
        transactionDate: DateTime.now(),
        createdAt: DateTime.now(),
      );
    }
  }

  /// Convert to JSON for Firebase
  Map<String, dynamic> toJson() {
    return {
      'ledgerId': ledgerId,
      'productId': productId,
      'productName': productName,
      'companyName': companyName,
      'modelName': modelName,
      'batchId': batchId,
      'ledgerType': ledgerType.toShortString(),
      'referenceId': referenceId,
      'referenceType': referenceType,
      'quantity': quantity,
      'costPrice': costPrice,
      'sellingPrice': sellingPrice,
      'totalCost': totalCost,
      'totalRevenue': totalRevenue,
      'profit': profit,
      'balanceQuantity': balanceQuantity,
      'balanceValue': balanceValue,
      'transactionDate': transactionDate.toIso8601String(),
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'productUniqueKey': productUniqueKey,
    };
  }

  /// Copy with modifications
  StockLedger copyWith({
    String? ledgerId,
    String? productId,
    String? productName,
    String? companyName,
    String? modelName,
    String? batchId,
    LedgerType? ledgerType,
    String? referenceId,
    String? referenceType,
    int? quantity,
    double? costPrice,
    double? sellingPrice,
    double? totalCost,
    double? totalRevenue,
    double? profit,
    int? balanceQuantity,
    double? balanceValue,
    DateTime? transactionDate,
    String? notes,
    DateTime? createdAt,
  }) {
    return StockLedger(
      ledgerId: ledgerId ?? this.ledgerId,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      companyName: companyName ?? this.companyName,
      modelName: modelName ?? this.modelName,
      batchId: batchId ?? this.batchId,
      ledgerType: ledgerType ?? this.ledgerType,
      referenceId: referenceId ?? this.referenceId,
      referenceType: referenceType ?? this.referenceType,
      quantity: quantity ?? this.quantity,
      costPrice: costPrice ?? this.costPrice,
      sellingPrice: sellingPrice ?? this.sellingPrice,
      totalCost: totalCost ?? this.totalCost,
      totalRevenue: totalRevenue ?? this.totalRevenue,
      profit: profit ?? this.profit,
      balanceQuantity: balanceQuantity ?? this.balanceQuantity,
      balanceValue: balanceValue ?? this.balanceValue,
      transactionDate: transactionDate ?? this.transactionDate,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'StockLedger(id: $ledgerId, type: $ledgerType, product: $productName, qty: $quantity, cost: $totalCost)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is StockLedger && other.ledgerId == ledgerId;
  }

  @override
  int get hashCode => ledgerId.hashCode;
}


/// Represents a consumed batch entry during a sale transaction.
/// Used for tracking which batches were used and their COGS.
class ConsumedBatchEntry {
  final String batchId;
  final String productId;
  final String productName;
  final String companyName;
  final String modelName;
  final int quantityConsumed;
  final double costPrice;
  final double totalCost;
  
  ConsumedBatchEntry({
    required this.batchId,
    required this.productId,
    required this.productName,
    this.companyName = '',
    this.modelName = '',
    required this.quantityConsumed,
    required this.costPrice,
    required this.totalCost,
  });
  
  Map<String, dynamic> toJson() {
    return {
      'batchId': batchId,
      'productId': productId,
      'productName': productName,
      'companyName': companyName,
      'modelName': modelName,
      'quantityConsumed': quantityConsumed,
      'costPrice': costPrice,
      'totalCost': totalCost,
    };
  }
  
  factory ConsumedBatchEntry.fromJson(Map<String, dynamic> json) {
    return ConsumedBatchEntry(
      batchId: (json['batchId'] ?? '') as String,
      productId: (json['productId'] ?? '') as String,
      productName: (json['productName'] ?? '') as String,
      companyName: (json['companyName'] ?? '') as String,
      modelName: (json['modelName'] ?? '') as String,
      quantityConsumed: (json['quantityConsumed'] ?? 0) as int,
      costPrice: ((json['costPrice'] ?? 0) as num).toDouble(),
      totalCost: ((json['totalCost'] ?? 0) as num).toDouble(),
    );
  }
}

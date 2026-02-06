/// Represents the type of customer transaction
enum TransactionType {
  /// Payment received from customer
  received,

  /// Amount adjusted (e.g., discount, write-off)
  adjusted,

  /// Bill generated (increases pending balance)
  billGenerated,

  /// Refund given to customer
  refund,
}

/// Extension to convert TransactionType to/from string for storage
extension TransactionTypeExtension on TransactionType {
  String get value {
    switch (this) {
      case TransactionType.received:
        return 'RECEIVED';
      case TransactionType.adjusted:
        return 'ADJUSTED';
      case TransactionType.billGenerated:
        return 'BILL_GENERATED';
      case TransactionType.refund:
        return 'REFUND';
    }
  }

  static TransactionType fromString(String value) {
    switch (value.toUpperCase()) {
      case 'RECEIVED':
        return TransactionType.received;
      case 'ADJUSTED':
        return TransactionType.adjusted;
      case 'BILL_GENERATED':
        return TransactionType.billGenerated;
      case 'REFUND':
        return TransactionType.refund;
      default:
        return TransactionType.received;
    }
  }
}

/// Represents the payment mode for a transaction
enum PaymentMode {
  cash,
  online,
  card,
  upi,
  cheque,
  other,
}

/// Extension to convert PaymentMode to/from string for storage
extension PaymentModeExtension on PaymentMode {
  String get value {
    switch (this) {
      case PaymentMode.cash:
        return 'CASH';
      case PaymentMode.online:
        return 'ONLINE';
      case PaymentMode.card:
        return 'CARD';
      case PaymentMode.upi:
        return 'UPI';
      case PaymentMode.cheque:
        return 'CHEQUE';
      case PaymentMode.other:
        return 'OTHER';
    }
  }

  String get displayName {
    switch (this) {
      case PaymentMode.cash:
        return 'Cash';
      case PaymentMode.online:
        return 'Online Transfer';
      case PaymentMode.card:
        return 'Card';
      case PaymentMode.upi:
        return 'UPI';
      case PaymentMode.cheque:
        return 'Cheque';
      case PaymentMode.other:
        return 'Other';
    }
  }

  static PaymentMode fromString(String value) {
    switch (value.toUpperCase()) {
      case 'CASH':
        return PaymentMode.cash;
      case 'ONLINE':
        return PaymentMode.online;
      case 'CARD':
        return PaymentMode.card;
      case 'UPI':
        return PaymentMode.upi;
      case 'CHEQUE':
        return PaymentMode.cheque;
      case 'OTHER':
        return PaymentMode.other;
      default:
        return PaymentMode.cash;
    }
  }
}

/// Represents a customer transaction (payment received or bill generated)
/// 
/// This entity is used for:
/// - Recording payments received from customers
/// - Tracking bill generation events
/// - Maintaining audit trail of all balance changes
/// - Supporting multi-bill partial payment scenarios
class CustomerTransaction {
  /// Unique identifier for the transaction
  final String id;

  /// Customer ID this transaction belongs to
  final String customerId;

  /// Bill ID this transaction is associated with (nullable for advance payments)
  final String? billId;

  /// Bill number for display purposes
  final String? billNumber;

  /// Transaction amount (positive value)
  /// For payments: amount received
  /// For bills: bill total amount
  final double amount;

  /// Type of transaction (RECEIVED, ADJUSTED, BILL_GENERATED, REFUND)
  final TransactionType transactionType;

  /// Payment mode (CASH, ONLINE, CARD, UPI, etc.)
  /// Only applicable for RECEIVED transactions
  final PaymentMode? paymentMode;

  /// Customer's pending balance after this transaction
  /// Stored for quick access without recalculating from all transactions
  final double balanceAfterTransaction;

  /// Optional notes/remarks for the transaction
  final String? notes;

  /// Reference number (e.g., UPI transaction ID, cheque number)
  final String? referenceNumber;

  /// Transaction creation timestamp
  final DateTime createdAt;

  /// User who created the transaction (for audit)
  final String? createdBy;

  const CustomerTransaction({
    required this.id,
    required this.customerId,
    this.billId,
    this.billNumber,
    required this.amount,
    required this.transactionType,
    this.paymentMode,
    required this.balanceAfterTransaction,
    this.notes,
    this.referenceNumber,
    required this.createdAt,
    this.createdBy,
  });

  /// Check if this is a payment transaction (reduces pending balance)
  bool get isPayment =>
      transactionType == TransactionType.received ||
      transactionType == TransactionType.adjusted;

  /// Check if this is a bill transaction (increases pending balance)
  bool get isBillTransaction =>
      transactionType == TransactionType.billGenerated;

  /// Get display string for transaction type
  String get transactionTypeDisplay {
    switch (transactionType) {
      case TransactionType.received:
        return 'Payment Received';
      case TransactionType.adjusted:
        return 'Adjustment';
      case TransactionType.billGenerated:
        return 'Bill Generated';
      case TransactionType.refund:
        return 'Refund';
    }
  }

  /// Factory constructor to create from Firebase JSON
  factory CustomerTransaction.fromJson(Map<String, dynamic> json) {
    return CustomerTransaction(
      id: (json['id'] ?? '') as String,
      customerId: (json['customerId'] ?? '') as String,
      billId: json['billId'] as String?,
      billNumber: json['billNumber'] as String?,
      amount: ((json['amount'] ?? 0) as num).toDouble(),
      transactionType: TransactionTypeExtension.fromString(
        (json['transactionType'] ?? 'RECEIVED') as String,
      ),
      paymentMode: json['paymentMode'] != null
          ? PaymentModeExtension.fromString(json['paymentMode'] as String)
          : null,
      balanceAfterTransaction:
          ((json['balanceAfterTransaction'] ?? 0) as num).toDouble(),
      notes: json['notes'] as String?,
      referenceNumber: json['referenceNumber'] as String?,
      createdAt: json['createdAt'] != null
          ? (json['createdAt'] is DateTime
              ? json['createdAt'] as DateTime
              : DateTime.parse(json['createdAt'].toString()))
          : DateTime.now(),
      createdBy: json['createdBy'] as String?,
    );
  }

  /// Convert to JSON for Firebase
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customerId': customerId,
      'billId': billId,
      'billNumber': billNumber,
      'amount': amount,
      'transactionType': transactionType.value,
      'paymentMode': paymentMode?.value,
      'balanceAfterTransaction': balanceAfterTransaction,
      'notes': notes,
      'referenceNumber': referenceNumber,
      'createdAt': createdAt.toIso8601String(),
      'createdBy': createdBy,
    };
  }

  /// Create a copy with updated fields
  CustomerTransaction copyWith({
    String? id,
    String? customerId,
    String? billId,
    String? billNumber,
    double? amount,
    TransactionType? transactionType,
    PaymentMode? paymentMode,
    double? balanceAfterTransaction,
    String? notes,
    String? referenceNumber,
    DateTime? createdAt,
    String? createdBy,
  }) {
    return CustomerTransaction(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      billId: billId ?? this.billId,
      billNumber: billNumber ?? this.billNumber,
      amount: amount ?? this.amount,
      transactionType: transactionType ?? this.transactionType,
      paymentMode: paymentMode ?? this.paymentMode,
      balanceAfterTransaction:
          balanceAfterTransaction ?? this.balanceAfterTransaction,
      notes: notes ?? this.notes,
      referenceNumber: referenceNumber ?? this.referenceNumber,
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
    );
  }

  @override
  String toString() {
    return 'CustomerTransaction(id: $id, customerId: $customerId, amount: $amount, type: ${transactionType.value}, balance: $balanceAfterTransaction)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CustomerTransaction && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

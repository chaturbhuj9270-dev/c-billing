import 'bill_item.dart';

/// Represents a sales bill containing multiple items sold to a customer
class Bill {
  final String id;
  final String? customerId;
  final String? customerName;
  final String? customerContact;
  final List<BillItem> items;
  final int totalQuantity;
  final double totalAmount;
  final double discountAmount;
  final double discountPercent;
  final double finalAmount;
  final DateTime billDate;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? notes;
  final bool returnStatus;
  final DateTime? returnDate;

  Bill({
    required this.id,
    this.customerId,
    this.customerName,
    this.customerContact,
    required this.items,
    required this.totalQuantity,
    required this.totalAmount,
    this.discountAmount = 0.0,
    this.discountPercent = 0.0,
    required this.finalAmount,
    required this.billDate,
    required this.createdAt,
    required this.updatedAt,
    this.notes,
    this.returnStatus = false,
    this.returnDate,
  });

  /// Factory constructor to create from JSON (for Firebase)
  factory Bill.fromJson(Map<String, dynamic> json) {
    try {
      List<BillItem> billItems = [];
      if (json['items'] != null) {
        billItems = (json['items'] as List)
            .map((item) => BillItem.fromJson(item as Map<String, dynamic>))
            .toList();
      }

      final totalAmount = ((json['totalAmount'] ?? 0) as num).toDouble();
      final discountAmount = ((json['discountAmount'] ?? 0) as num).toDouble();
      final discountPercent = ((json['discountPercent'] ?? 0) as num)
          .toDouble();
      final finalAmount = ((json['finalAmount'] ?? totalAmount) as num)
          .toDouble();

      return Bill(
        id: (json['id'] ?? '') as String,
        customerId: json['customerId'] as String?,
        customerName: json['customerName'] as String?,
        customerContact: json['customerContact'] as String?,
        items: billItems,
        totalQuantity: (json['totalQuantity'] ?? 0) as int,
        totalAmount: totalAmount,
        discountAmount: discountAmount,
        discountPercent: discountPercent,
        finalAmount: finalAmount,
        billDate: json['billDate'] != null
            ? DateTime.parse(json['billDate'] as String)
            : DateTime.now(),
        createdAt: json['createdAt'] != null
            ? DateTime.parse(json['createdAt'] as String)
            : DateTime.now(),
        updatedAt: json['updatedAt'] != null
            ? DateTime.parse(json['updatedAt'] as String)
            : DateTime.now(),
        notes: json['notes'] as String?,
        returnStatus: (json['returnStatus'] ?? false) as bool,
        returnDate: json['returnDate'] != null
            ? DateTime.parse(json['returnDate'] as String)
            : null,
      );
    } catch (e) {
      print('[ERROR] Failed to parse Bill from JSON: $json');
      print('[ERROR] Error details: $e');
      return Bill(
        id: json['id']?.toString() ?? '',
        customerId: null,
        customerName: null,
        customerContact: null,
        items: [],
        totalQuantity: 0,
        totalAmount: 0.0,
        discountAmount: 0.0,
        discountPercent: 0.0,
        finalAmount: 0.0,
        billDate: DateTime.now(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        notes: null,
        returnStatus: false,
        returnDate: null,
      );
    }
  }

  /// Convert to JSON for Firebase
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customerId': customerId,
      'customerName': customerName,
      'customerContact': customerContact,
      'items': items.map((item) => item.toJson()).toList(),
      'totalQuantity': totalQuantity,
      'totalAmount': totalAmount,
      'discountAmount': discountAmount,
      'discountPercent': discountPercent,
      'finalAmount': finalAmount,
      'billDate': billDate.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'notes': notes,
      'returnStatus': returnStatus,
      'returnDate': returnDate?.toIso8601String(),
    };
  }

  /// Copy with modifications
  Bill copyWith({
    String? id,
    String? customerId,
    String? customerName,
    String? customerContact,
    List<BillItem>? items,
    int? totalQuantity,
    double? totalAmount,
    double? discountAmount,
    double? discountPercent,
    double? finalAmount,
    DateTime? billDate,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? notes,
    bool? returnStatus,
    DateTime? returnDate,
  }) {
    return Bill(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      customerContact: customerContact ?? this.customerContact,
      items: items ?? this.items,
      totalQuantity: totalQuantity ?? this.totalQuantity,
      totalAmount: totalAmount ?? this.totalAmount,
      discountAmount: discountAmount ?? this.discountAmount,
      discountPercent: discountPercent ?? this.discountPercent,
      finalAmount: finalAmount ?? this.finalAmount,
      billDate: billDate ?? this.billDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      notes: notes ?? this.notes,
      returnStatus: returnStatus ?? this.returnStatus,
      returnDate: returnDate ?? this.returnDate,
    );
  }

  /// Get a formatted bill number
  String get billNumber {
    final dateStr = billDate
        .toIso8601String()
        .substring(0, 10)
        .replaceAll('-', '');
    return 'BILL-$dateStr-${id.substring(0, id.length > 6 ? 6 : id.length).toUpperCase()}';
  }

  /// Check if bill has customer information
  bool get hasCustomerInfo =>
      (customerName != null && customerName!.isNotEmpty) ||
      (customerContact != null && customerContact!.isNotEmpty);

  @override
  String toString() {
    return 'Bill(id: $id, customer: $customerName, items: ${items.length}, total: $totalAmount)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Bill && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

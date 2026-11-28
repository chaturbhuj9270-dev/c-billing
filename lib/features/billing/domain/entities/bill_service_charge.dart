/// Ad-hoc service / other charge line on a bill (description + amount).
///
/// Persisted as a normal bill item with [sentinelProductId] so offline DB,
/// Firebase sync, PDF, and print all show it without a schema migration.
/// Stock / FIFO must skip these lines.
class BillServiceCharge {
  static const String sentinelProductId = '__service_charge__';

  final String id;
  final String description;
  final double amount;

  const BillServiceCharge({
    required this.id,
    required this.description,
    required this.amount,
  });

  bool get isValid =>
      description.trim().isNotEmpty && amount > 0;

  Map<String, dynamic> toJson() => {
        'id': id,
        'description': description,
        'amount': amount,
      };

  factory BillServiceCharge.fromJson(Map<String, dynamic> json) {
    return BillServiceCharge(
      id: (json['id'] ?? '') as String,
      description: (json['description'] ?? json['productName'] ?? '') as String,
      amount: ((json['amount'] ?? json['subtotal'] ?? 0) as num).toDouble(),
    );
  }

  /// Detect a persisted bill item that represents a service charge.
  static bool isServiceItem({String? productId}) =>
      productId == sentinelProductId;
}

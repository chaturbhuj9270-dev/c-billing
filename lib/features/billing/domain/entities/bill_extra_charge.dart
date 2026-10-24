// A named extra charge on a bill (labour, service, accessory maintenance, etc.).
class BillExtraCharge {
  final String id;
  final String label;
  final double amount;

  const BillExtraCharge({
    required this.id,
    required this.label,
    required this.amount,
  });

  bool get isValid => label.trim().isNotEmpty && amount > 0;

  BillExtraCharge copyWith({
    String? id,
    String? label,
    double? amount,
  }) {
    return BillExtraCharge(
      id: id ?? this.id,
      label: label ?? this.label,
      amount: amount ?? this.amount,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'label': label,
    'amount': amount,
  };

  factory BillExtraCharge.fromJson(Map<String, dynamic> json) {
    return BillExtraCharge(
      id: (json['id'] ?? '').toString(),
      label: (json['label'] ?? '').toString(),
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

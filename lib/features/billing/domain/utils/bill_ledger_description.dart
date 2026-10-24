import 'package:c_billing/features/billing/domain/entities/bill_extra_charge.dart';

/// Builds a customer-ledger description for a bill (items, discount, tax, other charges).
String buildBillLedgerDescription({
  required String billId,
  required double itemsSubtotal,
  double discountAmount = 0,
  double taxAmount = 0,
  List<BillExtraCharge> extraCharges = const [],
  required double finalAmount,
}) {
  final parts = <String>['Bill #$billId'];
  parts.add('Items ₹${_money(itemsSubtotal)}');
  if (discountAmount > 0) {
    parts.add('Disc −₹${_money(discountAmount)}');
  }
  if (taxAmount > 0) {
    parts.add('Tax ₹${_money(taxAmount)}');
  }
  final validCharges = extraCharges
      .where((c) => c.label.trim().isNotEmpty && c.amount > 0)
      .toList();
  if (validCharges.isNotEmpty) {
    final detail = validCharges
        .map((c) => '${c.label.trim()} ₹${_money(c.amount)}')
        .join(', ');
    parts.add('Other $detail');
  }
  parts.add('Total ₹${_money(finalAmount)}');
  return parts.join(' · ');
}

/// Builds a ledger description for a sale return.
String buildReturnLedgerDescription({
  required String billId,
  required double refundAmount,
  List<BillExtraCharge> extraCharges = const [],
  bool fullReturn = false,
}) {
  final parts = <String>['Return for bill #$billId'];
  parts.add('Refund ₹${_money(refundAmount)}');
  final validCharges = extraCharges
      .where((c) => c.label.trim().isNotEmpty && c.amount > 0)
      .toList();
  if (validCharges.isNotEmpty) {
    if (fullReturn) {
      final detail = validCharges
          .map((c) => '${c.label.trim()} ₹${_money(c.amount)}')
          .join(', ');
      parts.add('incl. other $detail');
    } else {
      parts.add('incl. other-charges share');
    }
  }
  return parts.join(' · ');
}

String _money(double v) {
  if (v == v.roundToDouble()) return v.toStringAsFixed(0);
  return v.toStringAsFixed(2);
}

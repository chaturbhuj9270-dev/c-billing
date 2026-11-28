// Pure helpers that make a printed bill add up and resolve the customer's
// running balance. No Flutter / Firebase imports so they are unit-testable.
// Feature: print-formats.

/// Reconciled printed totals for one bill.
///
/// Printed lines = product lines + service-charge lines + extra-charge lines,
/// so `Subtotal` must be the sum of ALL of them. Then:
///   subtotal - discount + exclusiveTax + roundOff == grandTotal
class BillPrintTotals {
  final double subtotal;
  final double roundOff;
  const BillPrintTotals({required this.subtotal, required this.roundOff});
}

/// [productsTotal] is `Bill.totalAmount` (product lines only; service and extra
/// charges are stored separately and are NOT part of it).
BillPrintTotals computeBillPrintTotals({
  required double productsTotal,
  double serviceChargesTotal = 0,
  double extraChargesTotal = 0,
  double discountAmount = 0,
  bool exclusiveTax = false,
  double taxAmount = 0,
  required double finalAmount,
}) {
  final subtotal = productsTotal + serviceChargesTotal + extraChargesTotal;
  final expected = subtotal - discountAmount + (exclusiveTax ? taxAmount : 0.0);
  final diff = finalAmount - expected;
  // Only a genuine rounding difference (< 1 rupee) is shown as "Round off".
  // Anything larger is unexplained data and is never papered over.
  final roundOff = (diff.abs() >= 0.005 && diff.abs() < 1.0) ? diff : 0.0;
  return BillPrintTotals(subtotal: subtotal, roundOff: roundOff);
}

/// Customer's total pending "till date" to print on the bill.
///
/// * [customerPending] unknown (walk-in / lookup failed) -> [fallback]
///   (the value callers already passed, normally this bill's own pending).
/// * Otherwise the larger of the customer's balance and this bill's pending
///   (the ledger can lag a just-created bill); null when nothing is due.
double? resolveTotalDue({
  required double? customerPending,
  double billPending = 0,
  double? fallback,
}) {
  if (customerPending == null) return fallback;
  final bill = billPending > 0 ? billPending : 0.0;
  final customer = customerPending > 0 ? customerPending : 0.0;
  final total = customer > bill ? customer : bill;
  return total >= 0.005 ? total : null;
}

/// Part of [totalDue] that comes from earlier bills (0 when none).
double previousDueOf({required double? totalDue, double? billPending}) {
  if (totalDue == null) return 0;
  final prev =
      totalDue - (billPending != null && billPending > 0 ? billPending : 0);
  return prev >= 0.005 ? prev : 0;
}

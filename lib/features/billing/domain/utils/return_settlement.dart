/// How the value of returned goods is settled against the bill.
///
/// Example: bill 1,200, customer paid 1,000, 200 still pending. Returning the
/// whole bill (refund value 1,200) is settled as:
///  * [clearedPending] 200  - taken off what the customer still owes. This is
///    the ONLY part that changes the customer ledger / pending balance.
///  * [cashRefund] 1,000    - the paid money handed back to the customer. It
///    never touches the pending balance, so an older pending amount of 1,000
///    on the same customer stays 1,000.
///
/// Pure Dart (no Flutter / Firebase) so it can be unit tested.
class ReturnSettlement {
  /// Value of the returned goods as charged to the customer.
  final double refund;

  /// Portion of the refund that reduces the customer's pending amount.
  final double clearedPending;

  /// Portion of the refund that is paid money returned to the customer.
  final double cashRefund;

  const ReturnSettlement({
    required this.refund,
    required this.clearedPending,
    required this.cashRefund,
  });

  static const ReturnSettlement none = ReturnSettlement(
    refund: 0,
    clearedPending: 0,
    cashRefund: 0,
  );

  /// Splits [refund] using the bill's current [paid] and [pending] amounts.
  /// Pending is cleared first; only what the bill had paid is refunded.
  factory ReturnSettlement.split({
    required double refund,
    required double paid,
    required double pending,
  }) {
    final value = refund < 0 ? 0.0 : refund;
    final due = pending < 0 ? 0.0 : pending;
    final received = paid < 0 ? 0.0 : paid;

    final clearedFromDue = value < due ? value : due;
    final rest = value - clearedFromDue;
    final cash = rest < received ? rest : received;
    // Anything neither pending nor paid (stale bill balances) still comes off
    // the ledger, so a returned item can never leave a phantom debt behind.
    return ReturnSettlement(
      refund: value,
      clearedPending: value - cash,
      cashRefund: cash,
    );
  }

  /// Same as [split], but first repairs bills whose stored paid/pending are
  /// both 0 although the bill still has a chargeable amount (old data).
  factory ReturnSettlement.forBill({
    required double refund,
    required double paid,
    required double pending,
    required double finalAmount,
    required double priorReturned,
    required bool markedPaid,
  }) {
    var p = paid;
    var d = pending;
    final chargeable = finalAmount - priorReturned;
    if (p + d <= 0.009 && chargeable > 0.009) {
      if (markedPaid) {
        p = chargeable;
      } else {
        d = chargeable;
      }
    }
    return ReturnSettlement.split(refund: refund, paid: p, pending: d);
  }

  /// Paid money already handed back for a bill: the value returned minus what
  /// was taken off the ledger. Only meaningful when the bill has at least one
  /// return ledger row, otherwise 0.
  static double cashRefundFromLedger({
    required double returnedValue,
    required double clearedPending,
  }) {
    final cash = returnedValue - clearedPending;
    return cash > 0.009 ? cash : 0.0;
  }
}

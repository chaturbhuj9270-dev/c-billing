import 'package:c_billing/features/billing/domain/utils/bill_ledger_description.dart';
import 'package:c_billing/features/billing/domain/utils/return_settlement.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'customer owed 1000, sells 1200, pays 1000: returning it clears only the '
    '200 pending and pays back the 1000',
    () {
      // Ledger before the return: 1000 old pending + 1200 bill - 1000 paid.
      var ledger = 1000 + 1200 - 1000.0;
      expect(ledger, 1200);

      final s = ReturnSettlement.split(refund: 1200, paid: 1000, pending: 200);
      expect(s.cashRefund, 1000);
      expect(s.clearedPending, 200);
      expect(s.cashRefund + s.clearedPending, s.refund);

      ledger -= s.clearedPending; // the return ledger row
      expect(ledger, 1000, reason: 'the older 1000 pending is untouched');
    },
  );

  test('a fully paid bill is refunded in cash and leaves the ledger alone', () {
    final s = ReturnSettlement.split(refund: 1200, paid: 1200, pending: 0);
    expect(s.cashRefund, 1200);
    expect(s.clearedPending, 0);
  });

  test('an unpaid bill is cleared from pending with no cash refund', () {
    final s = ReturnSettlement.split(refund: 1200, paid: 0, pending: 1200);
    expect(s.cashRefund, 0);
    expect(s.clearedPending, 1200);
  });

  test('a partial return clears pending first, then refunds paid money', () {
    // Paid 1000, pending 200, returning goods worth 600.
    final s = ReturnSettlement.split(refund: 600, paid: 1000, pending: 200);
    expect(s.clearedPending, 200);
    expect(s.cashRefund, 400);

    // Smaller return than the pending: nothing is paid back.
    final small = ReturnSettlement.split(refund: 150, paid: 1000, pending: 200);
    expect(small.clearedPending, 150);
    expect(small.cashRefund, 0);
  });

  test('the parts always add up to the refund, even for stale balances', () {
    for (final c in [
      [500.0, 0.0, 0.0],
      [500.0, 100.0, 50.0],
      [500.0, 1000.0, 1000.0],
      [0.0, 100.0, 100.0],
      [500.0, -5.0, -5.0],
    ]) {
      final s = ReturnSettlement.split(
        refund: c[0],
        paid: c[1],
        pending: c[2],
      );
      expect(s.cashRefund + s.clearedPending, closeTo(s.refund, 1e-9));
      expect(s.cashRefund, greaterThanOrEqualTo(0));
      expect(s.clearedPending, greaterThanOrEqualTo(0));
    }
  });

  test('a bill stored as 0 paid / 0 pending is repaired before splitting', () {
    final unpaid = ReturnSettlement.forBill(
      refund: 1200,
      paid: 0,
      pending: 0,
      finalAmount: 1200,
      priorReturned: 0,
      markedPaid: false,
    );
    expect(unpaid.clearedPending, 1200);
    expect(unpaid.cashRefund, 0);

    final paid = ReturnSettlement.forBill(
      refund: 1200,
      paid: 0,
      pending: 0,
      finalAmount: 1200,
      priorReturned: 0,
      markedPaid: true,
    );
    expect(paid.cashRefund, 1200);
    expect(paid.clearedPending, 0);
  });

  test('cash already refunded is rebuilt from the ledger rows', () {
    expect(
      ReturnSettlement.cashRefundFromLedger(
        returnedValue: 1200,
        clearedPending: 200,
      ),
      1000,
    );
    // Older return rows hold the full value: nothing extra to show.
    expect(
      ReturnSettlement.cashRefundFromLedger(
        returnedValue: 1200,
        clearedPending: 1200,
      ),
      0,
    );
  });

  test('the ledger description explains the split', () {
    final text = buildReturnLedgerDescription(
      billId: 'B1',
      refundAmount: 1200,
      cashRefund: 1000,
      clearedPending: 200,
    );
    expect(text, contains('Refund ₹1200'));
    expect(text, contains('₹1000 paid back to customer'));
    expect(text, contains('₹200 cleared from pending'));
  });
}

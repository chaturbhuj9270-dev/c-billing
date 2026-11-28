import 'package:c_billing/features/billing/domain/sale_return_math.dart';
import 'package:flutter_test/flutter_test.dart';

/// Sales of a bill after returning [returnedQty] of [qty] units priced
/// [price], for a bill whose subtotal is [total] and final amount [finalAmt].
double _net(double total, double finalAmt, double price, double returnedQty) {
  final ratio = SaleReturnMath.chargeRatio(
    totalAmount: total,
    finalAmount: finalAmt,
  );
  final returned = SaleReturnMath.returnedValue(
    sellingPrice: price,
    returnedQuantity: returnedQty,
    chargeRatio: ratio,
  );
  return SaleReturnMath.netSales(
    finalAmount: finalAmt,
    returnedValue: returned,
  );
}

void main() {
  test('no return leaves sales unchanged', () {
    expect(_net(1000, 900, 250, 0), closeTo(900, 0.001));
  });

  test('full return of a discounted bill brings sales to zero', () {
    // 4 x 250 = 1000, 100 discount -> 900 charged
    expect(_net(1000, 900, 250, 4), closeTo(0, 0.01));
  });

  test('partial return reduces sales by what the customer was charged', () {
    // 1 of 4 units back: 250 * 0.9 = 225 refunded
    expect(_net(1000, 900, 250, 1), closeTo(675, 0.001));
  });

  test('bill with exclusive tax: full return still nets to zero', () {
    // 1000 + 18% tax = 1180. The old (1 - discount) maths left 180 behind.
    expect(_net(1000, 1180, 250, 4), closeTo(0, 0.01));
    expect(_net(1000, 1180, 250, 2), closeTo(590, 0.001));
  });

  test('refund matches the customer ledger refund formula', () {
    // processReturn: qty * sellingPrice * finalAmount / totalAmount
    const total = 1000.0, finalAmt = 1180.0, price = 250.0, qty = 3.0;
    final ledgerRefund = qty * price * (finalAmt / total);
    final ratio = SaleReturnMath.chargeRatio(
      totalAmount: total,
      finalAmount: finalAmt,
    );
    expect(
      SaleReturnMath.returnedValue(
        sellingPrice: price,
        returnedQuantity: qty,
        chargeRatio: ratio,
      ),
      closeTo(ledgerRefund, 0.0001),
    );
  });

  test('zero-total bill and never-negative sales are safe', () {
    expect(SaleReturnMath.chargeRatio(totalAmount: 0, finalAmount: 0), 1.0);
    expect(
      SaleReturnMath.netSales(finalAmount: 100, returnedValue: 100.004),
      0.0,
    );
    expect(SaleReturnMath.netSales(finalAmount: 100, returnedValue: 130), 0.0);
  });
}

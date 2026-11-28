// Regression guard: printed bill must add up, show the customer's total
// pending till date, and never lose a long shop name. Feature: print-formats.
import 'package:c_billing/core/printing/bill_print_math.dart';
import 'package:c_billing/core/printing/models/print_bill_data.dart';
import 'package:c_billing/core/printing/receipt_text_layout.dart';
import 'package:c_billing/core/printing/services/customer_due_resolver.dart';
import 'package:c_billing/features/billing/domain/entities/bill_service_charge.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeItem {
  final String productId;
  final String productName;
  final double sellingPrice;
  final double subtotal;
  final double quantity;
  _FakeItem(this.productId, this.productName, this.sellingPrice, this.quantity)
      : subtotal = sellingPrice * quantity;
  String? get companyName => null;
  double get returnedQuantity => 0;
  double? get cgstPercent => 0;
  double? get sgstPercent => 0;
  String? get hsnCode => null;
  String? get unit => null;
  String? get sellUnit => null;
}

class _FakeBill {
  final List<_FakeItem> items;
  final double totalAmount;
  final double finalAmount;
  final double discountAmount;
  final double paidAmount;
  final double pendingAmount;
  final String? customerId;
  _FakeBill({
    required this.items,
    required this.totalAmount,
    required this.finalAmount,
    this.discountAmount = 0,
    this.paidAmount = 0,
    this.pendingAmount = 0,
    this.customerId,
  });
  String get billNumber => 'B-1';
  DateTime get billDate => DateTime(2026, 1, 1);
  String? get customerName => 'Ravi';
  String? get customerContact => null;
  double? get discountPercent => null;
  double get totalTaxAmount => 0;
  double get cgstPercent => 0;
  double get sgstPercent => 0;
  double get igstPercent => 0;
  String? get notes => null;
  String? get paymentMode => 'CASH';

  // Unset optional Bill fields read as null, like an unset Bill.
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

void main() {
  group('computeBillPrintTotals', () {
    test('plain whole-rupee bill is unchanged (no round off)', () {
      final t = computeBillPrintTotals(productsTotal: 500, finalAmount: 500);
      expect(t.subtotal, 500);
      expect(t.roundOff, 0);
    });

    test('service + extra charges are inside subtotal; rounding is explicit', () {
      final t = computeBillPrintTotals(
        productsTotal: 100.40,
        serviceChargesTotal: 20,
        extraChargesTotal: 10,
        discountAmount: 5,
        finalAmount: 125, // 100.40+20+10-5 = 125.40 -> 125
      );
      expect(t.subtotal, closeTo(130.40, 1e-9));
      expect(t.roundOff, closeTo(-0.40, 1e-9));
      // The receipt reconciles.
      expect(130.40 - 5 + t.roundOff, closeTo(125, 1e-9));
    });

    test('exclusive tax is added; inclusive tax is not', () {
      final excl = computeBillPrintTotals(
        productsTotal: 100,
        exclusiveTax: true,
        taxAmount: 18,
        finalAmount: 118,
      );
      expect(excl.roundOff, 0);
      final incl = computeBillPrintTotals(
        productsTotal: 118,
        exclusiveTax: false,
        taxAmount: 18,
        finalAmount: 118,
      );
      expect(incl.roundOff, 0);
    });

    test('unexplained gaps of 1 rupee or more are not hidden as round off', () {
      final t = computeBillPrintTotals(productsTotal: 100, finalAmount: 150);
      expect(t.roundOff, 0);
    });
  });

  group('resolveTotalDue / previousDueOf', () {
    test('unknown customer keeps the caller fallback', () {
      expect(resolveTotalDue(customerPending: null, fallback: 40), 40);
      expect(resolveTotalDue(customerPending: null), isNull);
    });

    test('customer balance wins, never below this bill pending', () {
      expect(resolveTotalDue(customerPending: 500, billPending: 120), 500);
      expect(resolveTotalDue(customerPending: 50, billPending: 120), 120);
    });

    test('paid bill still shows old customer balance; nothing due -> null', () {
      expect(resolveTotalDue(customerPending: 300, billPending: 0), 300);
      expect(resolveTotalDue(customerPending: 0, billPending: 0), isNull);
      expect(resolveTotalDue(customerPending: -20, billPending: 0), isNull);
    });

    test('previous due = total due minus this bill pending', () {
      expect(previousDueOf(totalDue: 500, billPending: 120), 380);
      expect(previousDueOf(totalDue: 120, billPending: 120), 0);
      expect(previousDueOf(totalDue: null, billPending: 10), 0);
    });
  });

  group('PrintBillData.fromBill', () {
    test('subtotal includes service charge lines; round off + customer key', () {
      final bill = _FakeBill(
        items: [
          _FakeItem('p1', 'Rice', 50.2, 2), // 100.4
          _FakeItem(BillServiceCharge.sentinelProductId, 'Delivery', 20, 1),
        ],
        totalAmount: 100.4,
        finalAmount: 120, // 100.4 + 20 = 120.4 -> 120
        paidAmount: 100,
        pendingAmount: 20,
        customerId: 'abc123',
      );
      final d = PrintBillData.fromBill(bill);
      expect(d.subtotal, closeTo(120.4, 1e-9));
      expect(d.roundOff, closeTo(-0.4, 1e-9));
      expect(d.hasRoundOff, isTrue);
      expect(d.customerId, 'abc123');
      expect(d.grandTotal, 120);
    });

    test('plain bill prints exactly as before', () {
      final bill = _FakeBill(
        items: [_FakeItem('p1', 'Rice', 50, 2)],
        totalAmount: 100,
        finalAmount: 100,
        paidAmount: 100,
      );
      final d = PrintBillData.fromBill(bill);
      expect(d.subtotal, 100);
      expect(d.hasRoundOff, isFalse);
      expect(d.customerId, isNull);
      expect(d.hasTotalDue, isFalse);
    });

    test('withTotalDue only changes the due amount', () {
      final bill = _FakeBill(
        items: [_FakeItem('p1', 'Rice', 50, 2)],
        totalAmount: 100,
        finalAmount: 100,
        paidAmount: 60,
        pendingAmount: 40,
        customerId: 'c1',
      );
      final d = PrintBillData.fromBill(bill, totalDueAmount: 40);
      final e = d.withTotalDue(240);
      expect(e.totalDueAmount, 240);
      expect(e.previousDueAmount, 200);
      expect(e.subtotal, d.subtotal);
      expect(e.grandTotal, d.grandTotal);
      expect(e.customerId, 'c1');
      expect(e.items.length, d.items.length);
    });
  });

  group('CustomerDueResolver', () {
    tearDown(() => CustomerDueResolver.debugLookup = null);

    PrintBillData bill({String? customerId, double pending = 0}) =>
        PrintBillData.fromBill(
          _FakeBill(
            items: [_FakeItem('p1', 'Rice', 50, 2)],
            totalAmount: 100,
            finalAmount: 100,
            paidAmount: 100 - pending,
            pendingAmount: pending,
            customerId: customerId,
          ),
          totalDueAmount: pending > 0 ? pending : null,
        );

    test('prints customer total pending even when this bill is paid', () async {
      CustomerDueResolver.debugLookup = (_) async => 750;
      final d = await CustomerDueResolver.apply(bill(customerId: 'c1'));
      expect(d.totalDueAmount, 750);
      expect(d.previousDueAmount, 750);
    });

    test('adds previous due on top of this bill pending', () async {
      CustomerDueResolver.debugLookup = (_) async => 300;
      final d = await CustomerDueResolver.apply(
        bill(customerId: 'c1', pending: 100),
      );
      expect(d.totalDueAmount, 300);
      expect(d.previousDueAmount, 200);
    });

    test('walk-in bill and failed lookup keep existing behaviour', () async {
      CustomerDueResolver.debugLookup = (_) async => 999;
      final walkIn = await CustomerDueResolver.apply(bill(pending: 40));
      expect(walkIn.totalDueAmount, 40);

      CustomerDueResolver.debugLookup = (_) async => throw StateError('db');
      final failed = await CustomerDueResolver.apply(
        bill(customerId: 'c1', pending: 40),
      );
      expect(failed.totalDueAmount, 40);
    });

    test('customer with nothing due prints no due block', () async {
      CustomerDueResolver.debugLookup = (_) async => 0;
      final d = await CustomerDueResolver.apply(bill(customerId: 'c1'));
      expect(d.hasTotalDue, isFalse);
    });
  });

  group('shop name layout', () {
    test('wrapReceiptText never loses characters, even for long words', () {
      const name = 'SHRI GANESH AGRO-ELECTRICALS-AND-HARDWARE-TRADERS PVT LTD';
      for (final w in [8, 16, 24, 32, 48]) {
        final lines = wrapReceiptText(name, w);
        expect(lines.every((l) => l.length <= w), isTrue, reason: 'w=$w');
        expect(lines.join('').replaceAll(' ', ''), name.replaceAll(' ', ''));
      }
    });

    test('short name keeps the big double-size look', () {
      final l = layoutThermalShopName('RAHUL STORES', 32);
      expect(l.large, isTrue);
      expect(l.lines, ['RAHUL STORES']);
    });

    test('very long name falls back to full-width normal text, all visible', () {
      const name =
          'SHRI SWAMI SAMARTH KRUSHI SEVA KENDRA AND AGRO INPUTS TRADERS';
      final l = layoutThermalShopName(name, 32);
      expect(l.large, isFalse);
      expect(l.lines.every((x) => x.length <= 32), isTrue);
      expect(l.lines.join(' '), name);
    });

    test('POS PDF font shrinks with length but stays readable', () {
      expect(posShopNameFontSize('SHORT'), 11);
      expect(posShopNameFontSize('A' * 40), lessThan(11));
      expect(posShopNameFontSize('A' * 200), greaterThanOrEqualTo(7));
    });
  });
}

// Regression guard: print model labels/overrides shared by bills,
// quotations and event/order invoices. Feature: print-formats.
import 'package:c_billing/core/printing/models/print_bill_data.dart';
import 'package:flutter_test/flutter_test.dart';

PrintBillData _data({
  bool isQuotation = false,
  String? numberLabelText,
  String? documentTitle,
  String? formatOverride,
  double? qrAmountOverride,
}) {
  return PrintBillData(
    billNumber: 'X-1',
    dateTime: DateTime(2026, 1, 1),
    items: const [],
    subtotal: 0,
    grandTotal: 0,
    isQuotation: isQuotation,
    numberLabelText: numberLabelText,
    documentTitle: documentTitle,
    formatOverride: formatOverride,
    qrAmountOverride: qrAmountOverride,
  );
}

void main() {
  test('plain bill keeps Bill No / INVOICE labels', () {
    final d = _data();
    expect(d.numberLabel, 'Bill No');
    expect(d.documentHeaderTitle, 'INVOICE');
    expect(d.formatOverride, isNull);
    expect(d.qrAmountOverride, isNull);
  });

  test('quotation keeps Quotation No / QUOTATION labels', () {
    final d = _data(isQuotation: true);
    expect(d.numberLabel, 'Quotation No');
    expect(d.documentHeaderTitle, 'QUOTATION');
  });

  test('custom document kinds override labels', () {
    final d = _data(
      numberLabelText: 'Event',
      documentTitle: 'EVENT INVOICE',
      formatOverride: 'pos',
      qrAmountOverride: 120,
    );
    expect(d.numberLabel, 'Event');
    expect(d.documentHeaderTitle, 'EVENT INVOICE');
    expect(d.formatOverride, 'pos');
    expect(d.qrAmountOverride, 120);
  });
}

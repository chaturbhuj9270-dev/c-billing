import 'package:c_billing/features/billing/offline/entities/bill_entity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  BillItemEmbedded line() => BillItemEmbedded(
        itemId: 'line-1',
        productId: 'p1',
        productName: 'Rice',
        purchasePrice: 40,
        sellingPrice: 50,
        quantity: 3,
        subtotal: 150,
        returnedQuantity: 0.5,
        hsnCode: '1006',
        cgstPercent: 2.5,
        sgstPercent: 2.5,
        igstPercent: 0,
        unit: 'kg',
        sellUnit: 'gm',
        unitsPerPack: 10,
        employeeToken: 7,
      );

  test('a return only raises returnedQuantity and keeps every other field', () {
    final original = line();
    final returned = original.copyWith(returnedQuantity: 1.5);

    expect(returned.returnedQuantity, 1.5);
    final expected = original.toJson()..['returnedQuantity'] = 1.5;
    expect(returned.toJson(), expected);
  });

  test('copyWith without arguments is an exact copy', () {
    final original = line();
    expect(original.copyWith().toJson(), original.toJson());
  });
}

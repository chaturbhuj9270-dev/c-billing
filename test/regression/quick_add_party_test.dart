// Regression guard: quick add company / supplier on the add product screen.
// Feature: product-quick-add-party.
import 'package:c_billing/features/inventory_management/domain/utils/quick_add_party_logic.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('partyNameKey / findPartyByName', () {
    test('ignores case and extra spaces', () {
      expect(partyNameKey('  Tata   Motors '), 'tata motors');
    });

    test('finds an existing record so quick add never duplicates it', () {
      final names = ['Cipla', 'Tata  Motors', 'Amul'];
      expect(findPartyByName(names, 'tata motors', (n) => n), 'Tata  Motors');
      expect(findPartyByName(names, ' AMUL ', (n) => n), 'Amul');
      expect(findPartyByName(names, 'Nestle', (n) => n), isNull);
    });

    test('blank name never matches', () {
      expect(findPartyByName(['', 'A'], '   ', (n) => n), isNull);
    });
  });

  group('isValidOptionalMobile', () {
    test('empty is allowed, otherwise exactly 10 digits', () {
      expect(isValidOptionalMobile(''), isTrue);
      expect(isValidOptionalMobile('  '), isTrue);
      expect(isValidOptionalMobile('9876543210'), isTrue);
      expect(isValidOptionalMobile('98765'), isFalse);
      expect(isValidOptionalMobile('98765432101'), isFalse);
      expect(isValidOptionalMobile('98765abcde'), isFalse);
    });
  });

  group('picker maps keep the shape the add product sheet saves', () {
    test('company map', () {
      final m = companyPickerMap(id: 'c1', companyName: 'Cipla');
      expect(m['id'], 'c1');
      expect(m['companyName'], 'Cipla'); // read by selectedCompany?['companyName']
    });

    test('supplier map has fullName used for defaultSupplierName', () {
      final m = supplierPickerMap(id: '7', firstName: 'Ravi', lastName: 'Kumar');
      expect(m['id'], '7'); // defaultSupplierId
      expect(m['fullName'], 'Ravi Kumar'); // defaultSupplierName
      expect(supplierPickerMap(id: '1', firstName: 'Ravi', lastName: '')['fullName'], 'Ravi');
    });

    test('addPickerItemIfAbsent does not duplicate', () {
      final list = <Map<String, dynamic>>[
        companyPickerMap(id: 'a', companyName: 'A'),
      ];
      addPickerItemIfAbsent(list, companyPickerMap(id: 'a', companyName: 'A'));
      addPickerItemIfAbsent(list, companyPickerMap(id: 'b', companyName: 'B'));
      expect(list.map((e) => e['id']), ['a', 'b']);
    });
  });
}

// Regression guard: customer ledger duplicate repair.
// Protects the fix for "pending 200 shows 400" (billing used to write the
// ledger twice). Feature: customer-ledger in .cursor/feature-registry.json.
import 'package:c_billing/features/customer/offline/controllers/customer_transaction_offline_controller.dart';
import 'package:c_billing/features/customer/offline/entities/customer_transaction_entity.dart';
import 'package:flutter_test/flutter_test.dart';

final _t0 = DateTime(2026, 1, 1, 10, 0, 0);
int _nextId = 1;

CustomerTransactionEntity _tx(
  TransactionType type,
  double amount,
  String description, {
  Duration offset = Duration.zero,
  TransactionSyncStatus status = TransactionSyncStatus.synced,
}) {
  final at = _t0.add(offset);
  return CustomerTransactionEntity(
    customerId: 'c1',
    customerName: 'Test',
    transactionType: type,
    amount: amount,
    balanceAfter: 0,
    description: description,
    transactionDate: at,
    syncStatus: status,
    createdAt: at,
    updatedAt: at,
  )..id = _nextId++;
}

void main() {
  List<CustomerTransactionEntity> find(List<CustomerTransactionEntity> l) =>
      CustomerTransactionOfflineController.findDuplicateBillingEntries(l);

  test('legacy "Bill generated" copy of a same-amount original is flagged', () {
    final original = _tx(TransactionType.billCreated, 200, 'Bill #INV-1');
    final copy = _tx(TransactionType.billCreated, 200, 'Bill generated',
        offset: const Duration(seconds: 5));
    expect(find([original, copy]), [copy]);
  });

  test('legacy "Payment during billing" copy is flagged', () {
    final original =
        _tx(TransactionType.payment, 100, 'Payment for Bill #INV-1');
    final copy = _tx(TransactionType.payment, 100, 'Payment during billing',
        offset: const Duration(seconds: 3));
    expect(find([original, copy]), [copy]);
  });

  test('a copy without a same-amount original is NOT touched', () {
    final lone = _tx(TransactionType.billCreated, 200, 'Bill generated');
    final other = _tx(TransactionType.billCreated, 150, 'Bill #INV-2');
    expect(find([lone, other]), isEmpty);
  });

  test('original outside the 3 minute window is NOT matched', () {
    final original = _tx(TransactionType.billCreated, 200, 'Bill #INV-1');
    final copy = _tx(TransactionType.billCreated, 200, 'Bill generated',
        offset: const Duration(minutes: 10));
    expect(find([original, copy]), isEmpty);
  });

  test('normal rows and already deleted rows are never flagged', () {
    final bill = _tx(TransactionType.billCreated, 200, 'Bill #INV-1');
    final pay = _tx(TransactionType.payment, 50, 'Payment for Bill #INV-1');
    final deletedCopy = _tx(TransactionType.billCreated, 200, 'Bill generated',
        status: TransactionSyncStatus.deleted);
    expect(find([bill, pay, deletedCopy]), isEmpty);
  });

  test('one original can only absorb one copy', () {
    final original = _tx(TransactionType.billCreated, 200, 'Bill #INV-1');
    final c1 = _tx(TransactionType.billCreated, 200, 'Bill generated');
    final c2 = _tx(TransactionType.billCreated, 200, 'Bill generated');
    expect(find([original, c1, c2]).length, 1);
  });
}

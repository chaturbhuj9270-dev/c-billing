import 'package:c_billing/core/database/app_database.dart';
import 'package:c_billing/core/database/local_store.dart';
import 'package:c_billing/features/billing/offline/entities/bill_entity.dart';
import 'package:c_billing/features/event_order/offline/entities/event_order_entity.dart';
import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

// The pending report reads only the customer's open rows in SQL. These must
// match what the old full-table scan + Dart filter returned.
void main() {
  late AppDatabase db;
  final now = DateTime(2026, 1, 1);

  setUpAll(() => driftRuntimeOptions.dontWarnAboutMultipleDatabases = true);
  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  BillEntity bill(
    String? customerId,
    double pending, {
    BillSyncStatus sync = BillSyncStatus.synced,
  }) => BillEntity(
    customerId: customerId,
    pendingAmount: pending,
    finalAmount: 100,
    billDate: now,
    createdAt: now,
    updatedAt: now,
    syncStatus: sync,
  );

  EventOrderEntity order(
    String? customerId,
    double remaining, {
    EventOrderSyncStatus sync = EventOrderSyncStatus.synced,
  }) => EventOrderEntity(
    customerId: customerId,
    remainingAmount: remaining,
    eventDate: now,
    subEvents: const [],
    items: const [],
    createdAt: now,
    updatedAt: now,
    syncStatus: sync,
  );

  test('open bills: only this customer, pending > 0, not deleted', () async {
    await db.saveBill(bill('c1', 50));
    await db.saveBill(bill('local_7', 20));
    await db.saveBill(bill('c1', 0));
    await db.saveBill(bill('c1', 30, sync: BillSyncStatus.deleted));
    await db.saveBill(bill('other', 40));
    await db.saveBill(bill(null, 40));

    final rows = await db.loadOpenBillsForCustomers({'c1', 'local_7'});
    expect(rows.map((b) => b.pendingAmount).toList()..sort(), [20, 50]);
    expect(await db.loadOpenBillsForCustomers({}), isEmpty);
  });

  test('open event orders: only this customer, remaining > 0, not deleted',
      () async {
    await db.saveEventOrder(order('c1', 70));
    await db.saveEventOrder(order('c1', 0));
    await db.saveEventOrder(
      order('c1', 10, sync: EventOrderSyncStatus.deleted),
    );
    await db.saveEventOrder(order('other', 10));

    final rows = await db.loadOpenEventOrdersForCustomers({'c1'});
    expect(rows.map((o) => o.remainingAmount).toList(), [70]);
  });
}

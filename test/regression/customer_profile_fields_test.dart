import 'package:c_billing/core/database/app_database.dart';
import 'package:c_billing/core/database/local_store.dart';
import 'package:c_billing/features/customer/domain/customer_birthday.dart';
import 'package:c_billing/features/customer/offline/entities/customer_entity.dart';
import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

// Customer email + birth date are optional profile fields. They must never
// change the ledger fields (currentPendingAmount / totalPurchases).
void main() {
  setUpAll(() => driftRuntimeOptions.dontWarnAboutMultipleDatabases = true);

  group('birth date text helpers', () {
    test('stored as date-only yyyy-MM-dd', () {
      expect(birthDateToText(DateTime(1990, 2, 5)), '1990-02-05');
      expect(birthDateToText(null), isNull);
    });

    test('parses text literally (no timezone shift)', () {
      expect(birthDateFromValue('1990-02-05'), DateTime(1990, 2, 5));
      expect(
        birthDateFromValue('1990-02-05T00:00:00.000Z'),
        DateTime(1990, 2, 5),
      );
      expect(birthDateFromValue(''), isNull);
      expect(birthDateFromValue('garbage'), isNull);
      expect(birthDateFromValue(null), isNull);
    });

    test('DateTime values become date-only', () {
      expect(
        birthDateFromValue(DateTime(2000, 12, 31, 18, 30)),
        DateTime(2000, 12, 31),
      );
    });
  });

  group('CustomerEntity', () {
    CustomerEntity base() => CustomerEntity.create(
      name: 'Asha Patil',
      mobile: '9999999999',
      currentPendingAmount: 250,
      totalPurchases: 900,
    );

    test('sync payload carries email and birthDate', () {
      final e = base().copyWith(
        email: 'asha@example.com',
        birthDate: DateTime(1991, 7, 9),
      );
      final payload = e.toSyncPayload();
      expect(payload['email'], 'asha@example.com');
      expect(payload['birthDate'], '1991-07-09');
      expect(payload['currentPendingAmount'], 250);
    });

    test('importFromServer map round-trips birthDate', () {
      final e = CustomerEntity.fromCustomer({
        'id': 'abc',
        'firstName': 'Asha',
        'lastName': 'Patil',
        'contact': '9999999999',
        'birthDate': '1991-07-09',
      });
      expect(e.birthDate, DateTime(1991, 7, 9));
      expect(CustomerEntity.fromCustomer({'name': 'X'}).birthDate, isNull);
    });

    test('editing profile fields never changes ledger fields', () {
      final updated = base().copyWith(
        name: 'Asha P',
        email: 'a@b.co',
        birthDate: DateTime(1991, 7, 9),
      );
      expect(updated.currentPendingAmount, 250);
      expect(updated.totalPurchases, 900);
    });

    test('clearBirthDate removes only the birth date', () {
      final withDate = base().copyWith(birthDate: DateTime(1991, 7, 9));
      expect(withDate.copyWith().birthDate, DateTime(1991, 7, 9));
      final cleared = withDate.copyWith(clearBirthDate: true);
      expect(cleared.birthDate, isNull);
      expect(cleared.currentPendingAmount, 250);
    });
  });

  group('database', () {
    test('birthDate and email persist through save/load', () async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      final entity = CustomerEntity.create(
        name: 'Asha Patil',
        mobile: '9999999999',
        email: 'asha@example.com',
        birthDate: DateTime(1991, 7, 9),
        currentPendingAmount: 125.5,
      );
      await db.saveCustomer(entity);
      final loaded = (await db.loadCustomers()).single;
      expect(loaded.birthDate, DateTime(1991, 7, 9));
      expect(loaded.email, 'asha@example.com');
      expect(loaded.currentPendingAmount, 125.5);
    });

    test('v15 database upgrades in place and keeps customers', () async {
      final db = AppDatabase(
        NativeDatabase.memory(
          setup: (raw) {
            // Customers table exactly as shipped in schema v15 (no birth_date).
            raw.execute('''
              CREATE TABLE customers (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                server_id TEXT NULL,
                name TEXT NOT NULL,
                mobile TEXT NOT NULL,
                address TEXT NULL,
                email TEXT NULL,
                current_pending_amount REAL NOT NULL DEFAULT 0,
                total_purchases REAL NOT NULL DEFAULT 0,
                is_synced INTEGER NOT NULL DEFAULT 0,
                is_deleted INTEGER NOT NULL DEFAULT 0,
                updated_at INTEGER NOT NULL,
                created_at INTEGER NOT NULL
              )
            ''');
            raw.execute(
              "INSERT INTO customers (name, mobile, current_pending_amount, "
              "total_purchases, updated_at, created_at) "
              "VALUES ('Old Customer', '8888888888', 300, 700, 1700000000, 1700000000)",
            );
            raw.execute('PRAGMA user_version = 15');
          },
        ),
      );
      addTearDown(db.close);

      final loaded = (await db.loadCustomers()).single;
      expect(loaded.name, 'Old Customer');
      expect(loaded.currentPendingAmount, 300);
      expect(loaded.totalPurchases, 700);
      expect(loaded.birthDate, isNull);

      loaded.birthDate = DateTime(1980, 1, 2);
      await db.saveCustomer(loaded);
      final again = (await db.loadCustomers()).single;
      expect(again.birthDate, DateTime(1980, 1, 2));
      expect(again.currentPendingAmount, 300);
    });
  });

  group('isBirthdayOn', () {
    test('matches month and day only', () {
      expect(isBirthdayOn(DateTime(1990, 5, 17), DateTime(2026, 5, 17)), true);
      expect(isBirthdayOn(DateTime(1990, 5, 17), DateTime(2026, 5, 18)), false);
      expect(isBirthdayOn(null, DateTime(2026, 5, 17)), false);
    });

    test('29 Feb is celebrated on 28 Feb in non-leap years', () {
      final b = DateTime(2000, 2, 29);
      expect(isBirthdayOn(b, DateTime(2026, 2, 28)), true);
      expect(isBirthdayOn(b, DateTime(2028, 2, 28)), false);
      expect(isBirthdayOn(b, DateTime(2028, 2, 29)), true);
    });
  });
}

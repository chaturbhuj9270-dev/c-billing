import 'package:c_billing/common_widgets/master_data_form.dart';
import 'package:c_billing/core/database/app_database.dart';
import 'package:c_billing/core/database/local_store.dart';
import 'package:c_billing/features/company/offline/entities/company_entity.dart';
import 'package:c_billing/features/product/offline/entities/product_entity.dart';
import 'package:c_billing/features/supplier/offline/entities/supplier_entity.dart';
import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

// Supplier / company got optional profile fields (email, GST number, contact
// person) and the product form exposes unit, minimum stock and description.
// None of this may change existing data, stock or balances.
void main() {
  setUpAll(() => driftRuntimeOptions.dontWarnAboutMultipleDatabases = true);

  group('validators', () {
    test('email', () {
      expect(isValidEmailAddress('a@b.co'), true);
      expect(isValidEmailAddress(' shop@example.com '), true);
      expect(isValidEmailAddress('no-at-sign'), false);
      expect(isValidEmailAddress('a@b'), false);
      expect(isValidEmailAddress('a b@c.com'), false);
    });

    test('gstin', () {
      expect(isValidGstin('27AAPFU0939F1ZV'), true);
      expect(isValidGstin('27aapfu0939f1zv'), true);
      expect(isValidGstin('27AAPFU0939F1Z'), false);
      expect(isValidGstin('ABCDEFGHIJKLMNO'), false);
    });
  });

  group('SupplierEntity', () {
    test('new fields default to empty and sync/import round-trip', () {
      final s = SupplierEntity.create(firstName: 'Ravi', contact: '9999999999');
      expect(s.email, '');
      expect(s.gstNumber, '');

      final updated = s.copyWith(
        email: 'ravi@example.com',
        gstNumber: '27AAPFU0939F1ZV',
      );
      final payload = updated.toSyncPayload();
      expect(payload['email'], 'ravi@example.com');
      expect(payload['gstNumber'], '27AAPFU0939F1ZV');

      final imported = SupplierEntity.fromServer({
        'id': 'x',
        'firstName': 'Ravi',
        'contact': '9999999999',
        'email': 'ravi@example.com',
        'gstNumber': '27AAPFU0939F1ZV',
      });
      expect(imported.email, 'ravi@example.com');
      expect(imported.gstNumber, '27AAPFU0939F1ZV');
      // Old server documents without the fields still import.
      expect(SupplierEntity.fromServer({'id': 'y'}).email, '');
    });

    test('copyWith keeps untouched fields and can clear with empty text', () {
      final s = SupplierEntity.create(
        firstName: 'Ravi',
        middleName: 'K',
        contact: '9999999999',
        email: 'a@b.co',
      );
      expect(s.copyWith(address: 'Pune').email, 'a@b.co');
      expect(s.copyWith(address: 'Pune').middleName, 'K');
      expect(s.copyWith(email: '').email, '');
    });
  });

  group('CompanyEntity', () {
    test('new fields round-trip', () {
      final c = CompanyEntity.create(companyName: 'Acme');
      expect(c.email, '');
      expect(c.contactPerson, '');
      final u = c.copyWith(email: 'info@acme.com', contactPerson: 'Meera');
      final payload = u.toSyncPayload();
      expect(payload['email'], 'info@acme.com');
      expect(payload['contactPerson'], 'Meera');
      final imported = CompanyEntity.fromServer({
        'id': 'c1',
        'companyName': 'Acme',
        'email': 'info@acme.com',
        'contactPerson': 'Meera',
      });
      expect(imported.contactPerson, 'Meera');
      expect(CompanyEntity.fromServer({'id': 'c2'}).email, '');
    });
  });

  group('ProductEntity', () {
    ProductEntity base() => ProductEntity.create(
      name: 'Rice',
      purchasePrice: 40,
      salesPrice: 55,
      currentStock: 12,
      unit: 'kg',
      description: 'Basmati',
      minStockLevel: 5,
    );

    test('editing profile fields never changes stock or prices', () {
      final p = base().copyWith(unit: 'g', description: 'x', minStockLevel: 2);
      expect(p.currentStock, 12);
      expect(p.purchasePrice, 40);
      expect(p.salesPrice, 55);
    });

    test('blank form values clear only the requested field', () {
      final p = base().copyWith(
        clearUnit: true,
        clearDescription: true,
        clearMinStockLevel: true,
      );
      expect(p.unit, isNull);
      expect(p.description, isNull);
      expect(p.minStockLevel, isNull);
      expect(p.currentStock, 12);
      // Without the flags a null argument keeps the stored value.
      expect(base().copyWith().minStockLevel, 5);
      expect(base().copyWith().unit, 'kg');
    });
  });

  group('database', () {
    test('supplier and company new fields persist', () async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      await db.saveSupplier(
        SupplierEntity.create(
          firstName: 'Ravi',
          contact: '9999999999',
          email: 'ravi@example.com',
          gstNumber: '27AAPFU0939F1ZV',
        ),
      );
      await db.saveCompany(
        CompanyEntity.create(
          companyName: 'Acme',
          email: 'info@acme.com',
          contactPerson: 'Meera',
        ),
      );
      final s = (await db.loadSuppliers()).single;
      final c = (await db.loadCompanies()).single;
      expect(s.email, 'ravi@example.com');
      expect(s.gstNumber, '27AAPFU0939F1ZV');
      expect(c.email, 'info@acme.com');
      expect(c.contactPerson, 'Meera');
    });

    test('v16 database upgrades in place and keeps suppliers/companies', () async {
      final db = AppDatabase(
        NativeDatabase.memory(
          setup: (raw) {
            raw.execute('''
              CREATE TABLE suppliers (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                server_id TEXT NULL,
                first_name TEXT NOT NULL,
                middle_name TEXT NOT NULL DEFAULT '',
                last_name TEXT NOT NULL DEFAULT '',
                supplier_code TEXT NOT NULL DEFAULT '',
                contact TEXT NOT NULL,
                address TEXT NOT NULL DEFAULT '',
                is_active INTEGER NOT NULL DEFAULT 1,
                sync_status INTEGER NOT NULL,
                updated_at INTEGER NOT NULL,
                created_at INTEGER NOT NULL
              )
            ''');
            raw.execute('''
              CREATE TABLE companies (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                server_id TEXT NULL,
                company_name TEXT NOT NULL,
                company_code TEXT NOT NULL DEFAULT '',
                gst_code TEXT NOT NULL DEFAULT '',
                contact TEXT NOT NULL DEFAULT '',
                address TEXT NOT NULL DEFAULT '',
                is_active INTEGER NOT NULL DEFAULT 1,
                sync_status INTEGER NOT NULL,
                updated_at INTEGER NOT NULL,
                created_at INTEGER NOT NULL
              )
            ''');
            raw.execute(
              "INSERT INTO suppliers (first_name, middle_name, contact, "
              "supplier_code, sync_status, updated_at, created_at) VALUES "
              "('Old', 'Mid', '8888888888', '7', 3, 1700000000, 1700000000)",
            );
            raw.execute(
              "INSERT INTO companies (company_name, company_code, gst_code, "
              "sync_status, updated_at, created_at) VALUES "
              "('Old Co', '3', 'GST1', 3, 1700000000, 1700000000)",
            );
            raw.execute('PRAGMA user_version = 16');
          },
        ),
      );
      addTearDown(db.close);

      final s = (await db.loadSuppliers()).single;
      expect(s.firstName, 'Old');
      expect(s.middleName, 'Mid');
      expect(s.supplierCode, '7');
      expect(s.email, '');
      expect(s.gstNumber, '');
      final c = (await db.loadCompanies()).single;
      expect(c.companyName, 'Old Co');
      expect(c.gstCode, 'GST1');
      expect(c.email, '');

      s.email = 'old@example.com';
      await db.saveSupplier(s);
      expect((await db.loadSuppliers()).single.email, 'old@example.com');
    });
  });
}

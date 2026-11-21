import 'package:drift/drift.dart';

import 'database_executor.dart';

part 'app_database.g.dart';

@DataClassName('CompanyRecord')
class CompanyRecords extends Table {
  @override
  String get tableName => 'companies';

  IntColumn get id => integer().autoIncrement()();
  TextColumn get serverId => text().nullable()();
  TextColumn get companyName => text()();
  TextColumn get companyCode => text().withDefault(const Constant(''))();
  TextColumn get gstCode => text().withDefault(const Constant(''))();
  TextColumn get contact => text().withDefault(const Constant(''))();
  TextColumn get address => text().withDefault(const Constant(''))();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  IntColumn get syncStatus => integer()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get createdAt => dateTime()();
}

@DataClassName('CustomerRecord')
class CustomerRecords extends Table {
  @override
  String get tableName => 'customers';

  IntColumn get id => integer().autoIncrement()();
  TextColumn get serverId => text().nullable()();
  TextColumn get name => text()();
  TextColumn get mobile => text()();
  TextColumn get address => text().nullable()();
  TextColumn get email => text().nullable()();
  RealColumn get currentPendingAmount =>
      real().withDefault(const Constant(0))();
  RealColumn get totalPurchases => real().withDefault(const Constant(0))();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get createdAt => dateTime()();
}

@DataClassName('SupplierRecord')
class SupplierRecords extends Table {
  @override
  String get tableName => 'suppliers';

  IntColumn get id => integer().autoIncrement()();
  TextColumn get serverId => text().nullable()();
  TextColumn get firstName => text()();
  TextColumn get middleName => text().withDefault(const Constant(''))();
  TextColumn get lastName => text().withDefault(const Constant(''))();
  TextColumn get supplierCode => text().withDefault(const Constant(''))();
  TextColumn get contact => text()();
  TextColumn get address => text().withDefault(const Constant(''))();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  IntColumn get syncStatus => integer()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get createdAt => dateTime()();
}

@DataClassName('ProductRecord')
class ProductRecords extends Table {
  @override
  String get tableName => 'products';

  IntColumn get id => integer().autoIncrement()();
  TextColumn get serverId => text().nullable()();
  IntColumn get indexNo => integer().withDefault(const Constant(0))();
  TextColumn get name => text()();
  TextColumn get companyName => text().withDefault(const Constant(''))();
  TextColumn get category => text().withDefault(const Constant(''))();
  TextColumn get barcode => text().nullable()();
  RealColumn get purchasePrice => real().withDefault(const Constant(0))();
  RealColumn get salesPrice => real().withDefault(const Constant(0))();
  // REAL: matches on-disk DB (fractional kg/ml stock). Reading as int truncates.
  RealColumn get currentStock => real().withDefault(const Constant(0))();
  TextColumn get unit => text().nullable()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  IntColumn get syncStatus => integer()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get createdAt => dateTime()();
  IntColumn get minStockLevel => integer().nullable()();
  TextColumn get description => text().nullable()();
  TextColumn get imageUrl => text().nullable()();
  TextColumn get defaultSupplierId => text().nullable()();
  TextColumn get defaultSupplierName => text().nullable()();
  RealColumn get cgstPercent => real().withDefault(const Constant(0))();
  RealColumn get sgstPercent => real().withDefault(const Constant(0))();
  TextColumn get hsnCode => text().nullable()();
  TextColumn get customFieldsJson => text().nullable()();
}

@DataClassName('PurchaseRecord')
class PurchaseRecords extends Table {
  @override
  String get tableName => 'purchases';

  IntColumn get id => integer().autoIncrement()();
  TextColumn get serverId => text().nullable()();
  TextColumn get productId => text()();
  TextColumn get productName => text().withDefault(const Constant(''))();
  TextColumn get supplierId => text().nullable()();
  TextColumn get supplierName => text().nullable()();
  TextColumn get companyId => text().nullable()();
  TextColumn get companyName => text().nullable()();
  RealColumn get quantity => real().withDefault(const Constant(0))();
  TextColumn get unit => text().withDefault(const Constant(''))();
  RealColumn get purchasePrice => real().withDefault(const Constant(0))();
  RealColumn get salesPrice => real().withDefault(const Constant(0))();
  RealColumn get totalAmount => real().withDefault(const Constant(0))();
  DateTimeColumn get productionDate => dateTime().nullable()();
  DateTimeColumn get expiryDate => dateTime().nullable()();
  IntColumn get warrantyMonths => integer().nullable()();
  TextColumn get notes => text().nullable()();
  IntColumn get syncStatus => integer()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
}

@DataClassName('PurchaseBatchRecord')
class PurchaseBatchRecords extends Table {
  @override
  String get tableName => 'purchase_batches';

  IntColumn get id => integer().autoIncrement()();
  TextColumn get serverId => text().nullable()();
  TextColumn get productId => text()();
  TextColumn get productName => text().withDefault(const Constant(''))();
  TextColumn get companyName => text().withDefault(const Constant(''))();
  TextColumn get modelName => text().withDefault(const Constant(''))();
  TextColumn get category => text().withDefault(const Constant(''))();
  TextColumn get productUniqueKey => text().withDefault(const Constant(''))();
  RealColumn get purchasePrice => real().withDefault(const Constant(0))();
  RealColumn get sellingPrice => real().withDefault(const Constant(0))();
  RealColumn get quantityPurchased => real().withDefault(const Constant(0))();
  RealColumn get quantityRemaining => real().withDefault(const Constant(0))();
  DateTimeColumn get purchaseDate => dateTime()();
  TextColumn get supplierId => text().nullable()();
  TextColumn get supplierName => text().nullable()();
  TextColumn get unit => text().withDefault(const Constant(''))();
  DateTimeColumn get expiryDate => dateTime().nullable()();
  DateTimeColumn get productionDate => dateTime().nullable()();
  IntColumn get warrantyMonths => integer().nullable()();
  TextColumn get notes => text().nullable()();
  BoolColumn get isConsumed => boolean().withDefault(const Constant(false))();
  IntColumn get syncStatus => integer()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
}

@DataClassName('StockLedgerRecord')
class StockLedgerRecords extends Table {
  @override
  String get tableName => 'stock_ledger';

  IntColumn get id => integer().autoIncrement()();
  TextColumn get serverId => text().nullable()();
  TextColumn get productId => text()();
  TextColumn get productName => text().withDefault(const Constant(''))();
  TextColumn get companyName => text().withDefault(const Constant(''))();
  TextColumn get modelName => text().withDefault(const Constant(''))();
  TextColumn get productUniqueKey => text().withDefault(const Constant(''))();
  TextColumn get batchId => text().withDefault(const Constant(''))();
  IntColumn get localBatchId => integer().nullable()();
  IntColumn get ledgerType => integer()();
  TextColumn get referenceId => text().withDefault(const Constant(''))();
  TextColumn get referenceType => text().withDefault(const Constant(''))();
  RealColumn get quantity => real().withDefault(const Constant(0))();
  RealColumn get costPrice => real().withDefault(const Constant(0))();
  RealColumn get sellingPrice => real().withDefault(const Constant(0))();
  RealColumn get totalCost => real().withDefault(const Constant(0))();
  RealColumn get totalRevenue => real().withDefault(const Constant(0))();
  RealColumn get profit => real().withDefault(const Constant(0))();
  RealColumn get balanceQuantity => real().withDefault(const Constant(0))();
  RealColumn get balanceValue => real().withDefault(const Constant(0))();
  DateTimeColumn get transactionDate => dateTime()();
  TextColumn get notes => text().nullable()();
  IntColumn get syncStatus => integer()();
  DateTimeColumn get createdAt => dateTime()();
}

@DataClassName('BillRecord')
class BillRecords extends Table {
  @override
  String get tableName => 'bills';

  IntColumn get id => integer().autoIncrement()();
  TextColumn get serverId => text().nullable()();
  TextColumn get customerId => text().nullable()();
  TextColumn get customerName => text().nullable()();
  TextColumn get customerContact => text().nullable()();
  TextColumn get itemsJson => text().withDefault(const Constant('[]'))();
  RealColumn get totalQuantity => real().withDefault(const Constant(0))();
  RealColumn get totalAmount => real().withDefault(const Constant(0))();
  RealColumn get discountAmount => real().withDefault(const Constant(0))();
  RealColumn get discountPercent => real().withDefault(const Constant(0))();
  RealColumn get finalAmount => real().withDefault(const Constant(0))();
  DateTimeColumn get billDate => dateTime()();
  TextColumn get notes => text().nullable()();
  BoolColumn get returnStatus => boolean().withDefault(const Constant(false))();
  DateTimeColumn get returnDate => dateTime().nullable()();
  IntColumn get paymentStatus => integer()();
  RealColumn get paidAmount => real().withDefault(const Constant(0))();
  RealColumn get pendingAmount => real().withDefault(const Constant(0))();
  BoolColumn get isGstApplied => boolean().withDefault(const Constant(false))();
  BoolColumn get isTaxInclusive =>
      boolean().withDefault(const Constant(false))();
  RealColumn get cgstPercent => real().withDefault(const Constant(0))();
  RealColumn get sgstPercent => real().withDefault(const Constant(0))();
  RealColumn get otherTaxPercent => real().withDefault(const Constant(0))();
  TextColumn get otherTaxName => text().nullable()();
  RealColumn get cgstAmount => real().withDefault(const Constant(0))();
  RealColumn get sgstAmount => real().withDefault(const Constant(0))();
  RealColumn get otherTaxAmount => real().withDefault(const Constant(0))();
  RealColumn get totalTaxAmount => real().withDefault(const Constant(0))();
  IntColumn get syncStatus => integer()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
}

@DataClassName('EventOrderRecord')
class EventOrderRecords extends Table {
  @override
  String get tableName => 'event_orders';

  IntColumn get id => integer().autoIncrement()();
  TextColumn get serverId => text().nullable()();
  IntColumn get orderType => integer().withDefault(const Constant(0))();
  TextColumn get customerId => text().nullable()();
  TextColumn get customerName => text().withDefault(const Constant(''))();
  TextColumn get customerContact => text().withDefault(const Constant(''))();
  TextColumn get customerAddress => text().nullable()();
  TextColumn get orderName => text().withDefault(const Constant(''))();
  TextColumn get description => text().nullable()();
  DateTimeColumn get eventDate => dateTime()();
  TextColumn get eventLocation => text().nullable()();
  TextColumn get subEventsJson => text().withDefault(const Constant('[]'))();
  TextColumn get itemsJson => text().withDefault(const Constant('[]'))();
  RealColumn get eventCharges => real().withDefault(const Constant(0))();
  RealColumn get totalAmount => real().withDefault(const Constant(0))();
  RealColumn get advanceAmount => real().withDefault(const Constant(0))();
  RealColumn get remainingAmount => real().withDefault(const Constant(0))();
  TextColumn get notes => text().nullable()();
  IntColumn get status => integer().withDefault(const Constant(0))();
  TextColumn get convertedBillId => text().nullable()();
  TextColumn get customDataJson => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  IntColumn get syncStatus => integer()();
}

@DataClassName('QuotationRecord')
class QuotationRecords extends Table {
  @override
  String get tableName => 'quotations';

  IntColumn get id => integer().autoIncrement()();
  TextColumn get serverId => text().nullable()();
  TextColumn get quotationNumber => text().withDefault(const Constant(''))();
  IntColumn get quotationType => integer().withDefault(const Constant(0))();
  TextColumn get customerId => text().nullable()();
  TextColumn get customerName => text().withDefault(const Constant(''))();
  TextColumn get customerContact => text().withDefault(const Constant(''))();
  TextColumn get customerAddress => text().nullable()();
  TextColumn get title => text().withDefault(const Constant(''))();
  TextColumn get description => text().nullable()();
  DateTimeColumn get referenceDate => dateTime()();
  TextColumn get eventLocation => text().nullable()();
  DateTimeColumn get validUntil => dateTime()();
  TextColumn get subEventsJson => text().withDefault(const Constant('[]'))();
  TextColumn get itemsJson => text().withDefault(const Constant('[]'))();
  RealColumn get eventCharges => real().withDefault(const Constant(0))();
  RealColumn get discountPercent => real().withDefault(const Constant(0))();
  RealColumn get discountAmount => real().withDefault(const Constant(0))();
  RealColumn get totalAmount => real().withDefault(const Constant(0))();
  TextColumn get notes => text().nullable()();
  IntColumn get status => integer().withDefault(const Constant(0))();
  TextColumn get convertedBillId => text().nullable()();
  TextColumn get convertedEventOrderId => text().nullable()();
  TextColumn get customDataJson => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  IntColumn get syncStatus => integer()();
}

@DataClassName('ExpenseRecord')
class ExpenseRecords extends Table {
  @override
  String get tableName => 'expenses';

  IntColumn get id => integer().autoIncrement()();
  TextColumn get serverId => text().nullable()();
  TextColumn get title => text()();
  TextColumn get description => text().nullable()();
  IntColumn get category => integer()();
  RealColumn get amount => real().withDefault(const Constant(0))();
  TextColumn get paymentMethod => text().nullable()();
  TextColumn get vendorName => text().nullable()();
  TextColumn get receiptNumber => text().nullable()();
  BoolColumn get isRecurring => boolean().withDefault(const Constant(false))();
  DateTimeColumn get expenseDate => dateTime()();
  TextColumn get notes => text().nullable()();
  IntColumn get syncStatus => integer()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
}

@DataClassName('ShopImageRecord')
class ShopImageRecords extends Table {
  @override
  String get tableName => 'shop_images';

  IntColumn get id => integer().autoIncrement()();
  TextColumn get userId => text().unique()();
  TextColumn get shopLogoBase64 => text().nullable()();
  TextColumn get signatureBase64 => text().nullable()();
  TextColumn get qrCodeBase64 => text().nullable()();
  DateTimeColumn get lastSyncedAt => dateTime().nullable()();
  DateTimeColumn get updatedAt => dateTime()();
}

@DataClassName('CustomerTransactionRecord')
class CustomerTransactionRecords extends Table {
  @override
  String get tableName => 'customer_transactions';

  IntColumn get id => integer().autoIncrement()();
  TextColumn get serverId => text().nullable()();
  TextColumn get customerId => text()();
  TextColumn get customerName => text().withDefault(const Constant(''))();
  IntColumn get transactionType => integer()();
  RealColumn get amount => real().withDefault(const Constant(0))();
  RealColumn get balanceAfter => real().withDefault(const Constant(0))();
  TextColumn get referenceId => text().nullable()();
  TextColumn get referenceType => text().nullable()();
  TextColumn get description => text().nullable()();
  TextColumn get paymentMethod => text().nullable()();
  DateTimeColumn get transactionDate => dateTime()();
  IntColumn get syncStatus => integer()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
}

@DriftDatabase(
  tables: [
    CompanyRecords,
    CustomerRecords,
    SupplierRecords,
    ProductRecords,
    PurchaseRecords,
    PurchaseBatchRecords,
    StockLedgerRecords,
    BillRecords,
    EventOrderRecords,
    QuotationRecords,
    ExpenseRecords,
    ShopImageRecords,
    CustomerTransactionRecords,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? openAppDatabase());

  // v15: REAL qty affinity + derived-balance repair. Never alterTable bills /
  // purchases here — those tables carry extra GST/payment columns not in this
  // schema; alterTable would drop shop data.
  @override
  int get schemaVersion => 15;

  Future<bool> _hasTable(String table) async {
    final rows = await customSelect(
      "SELECT name FROM sqlite_master WHERE type = 'table' AND name = ?",
      variables: [Variable.withString(table)],
    ).get();
    return rows.isNotEmpty;
  }

  Future<void> _ensureTables(Migrator m) async {
    for (final table in allTables) {
      if (!await _hasTable(table.actualTableName)) {
        await m.createTable(table);
      }
    }
  }

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        // Idempotent: create any tables missing on this branch without
        // wiping existing shop data when switching branches / versions.
        await _ensureTables(m);
        if (from < 15) {
          await repairDerivedBalances();
        }
      },
    );
  }

  /// Rebuilds derived stock + customer running balances from source tables.
  /// Does not delete shop data and does not rewrite bill GST columns.
  Future<void> repairDerivedBalances() async {
    await transaction(() async {
      // 1) Relink orphan batches whose product_id no longer matches a product.
      await customStatement('''
        UPDATE purchase_batches
        SET product_id = (
          SELECT COALESCE(p.server_id, 'local_' || p.id)
          FROM products p
          WHERE LOWER(TRIM(p.name)) = LOWER(TRIM(purchase_batches.product_name))
          LIMIT 1
        )
        WHERE product_id IS NOT NULL
          AND product_id != ''
          AND NOT EXISTS (
            SELECT 1 FROM products p
            WHERE p.server_id = purchase_batches.product_id
               OR CAST(p.id AS TEXT) = purchase_batches.product_id
               OR ('local_' || p.id) = purchase_batches.product_id
          )
          AND EXISTS (
            SELECT 1 FROM products p
            WHERE LOWER(TRIM(p.name)) = LOWER(TRIM(purchase_batches.product_name))
          )
      ''');

      // 2) Product stock = sum of unconsumed batch remaining qty.
      await customStatement('''
        UPDATE products
        SET current_stock = COALESCE((
          SELECT SUM(b.quantity_remaining)
          FROM purchase_batches b
          WHERE b.is_consumed = 0
            AND (
              b.product_id = products.server_id
              OR b.product_id = CAST(products.id AS TEXT)
              OR b.product_id = ('local_' || products.id)
            )
        ), 0)
      ''');

      // 3) Rebuild customer ledger running balances from txn history.
      final customers = await customSelect(
        'SELECT id, server_id FROM customers WHERE is_deleted = 0',
      ).get();

      for (final customer in customers) {
        final localId = customer.read<int>('id');
        final serverId = customer.read<String?>('server_id');
        final ids = <String>{
          '$localId',
          'local_$localId',
          if (serverId != null && serverId.isNotEmpty) serverId,
        };

        final placeholders = List.filled(ids.length, '?').join(',');
        final txns = await customSelect(
          '''
          SELECT id, transaction_type, amount
          FROM customer_transactions
          WHERE customer_id IN ($placeholders)
            AND sync_status != 2
          ORDER BY transaction_date ASC, id ASC
          ''',
          variables: ids.map(Variable.withString).toList(),
        ).get();

        var running = 0.0;
        for (final txn in txns) {
          final type = txn.read<int>('transaction_type');
          final amount = txn.read<double>('amount');
          // 0 payment, 1 billCreated, 2 billReturn, 3 adjustment
          if (type == 0 || type == 2) {
            running -= amount;
          } else {
            running += amount;
          }
          await customStatement(
            'UPDATE customer_transactions SET balance_after = ? WHERE id = ?',
            [running, txn.read<int>('id')],
          );
        }

        await customStatement(
          'UPDATE customers SET current_pending_amount = ? WHERE id = ?',
          [running, localId],
        );
      }
    });
  }

  Future<void> clearAll() async {
    await transaction(() async {
      await delete(companyRecords).go();
      await delete(customerRecords).go();
      await delete(supplierRecords).go();
      await delete(productRecords).go();
      await delete(purchaseRecords).go();
      await delete(purchaseBatchRecords).go();
      await delete(stockLedgerRecords).go();
      await delete(billRecords).go();
      await delete(eventOrderRecords).go();
      await delete(quotationRecords).go();
      await delete(expenseRecords).go();
      await delete(shopImageRecords).go();
      await delete(customerTransactionRecords).go();
    });
  }
}

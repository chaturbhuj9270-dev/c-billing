import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

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
  IntColumn get currentStock => integer().withDefault(const Constant(0))();
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
  IntColumn get quantity => integer().withDefault(const Constant(0))();
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
  IntColumn get quantityPurchased => integer().withDefault(const Constant(0))();
  IntColumn get quantityRemaining => integer().withDefault(const Constant(0))();
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
  IntColumn get quantity => integer().withDefault(const Constant(0))();
  RealColumn get costPrice => real().withDefault(const Constant(0))();
  RealColumn get sellingPrice => real().withDefault(const Constant(0))();
  RealColumn get totalCost => real().withDefault(const Constant(0))();
  RealColumn get totalRevenue => real().withDefault(const Constant(0))();
  RealColumn get profit => real().withDefault(const Constant(0))();
  IntColumn get balanceQuantity => integer().withDefault(const Constant(0))();
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
  IntColumn get totalQuantity => integer().withDefault(const Constant(0))();
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
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _open());

  @override
  int get schemaVersion => 1;

  static QueryExecutor _open() {
    return driftDatabase(
      name: 'c_billing_db',
      web: DriftWebOptions(
        sqlite3Wasm: Uri.parse('sqlite3.wasm'),
        driftWorker: Uri.parse('drift_worker.js'),
      ),
    );
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

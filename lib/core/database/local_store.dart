import 'package:drift/drift.dart';

import '../../features/billing/offline/entities/bill_entity.dart';
import '../../features/company/offline/entities/company_entity.dart';
import '../../features/customer/offline/entities/customer_entity.dart';
import '../../features/customer/offline/entities/customer_transaction_entity.dart';
import '../../features/event_order/offline/entities/event_order_entity.dart';
import '../../features/expense/offline/entities/expense_entity.dart';
import '../../features/inventory_management/offline/entities/purchase_batch_entity.dart';
import '../../features/inventory_management/offline/entities/purchase_entity.dart';
import '../../features/inventory_management/offline/entities/stock_ledger_entity.dart';
import '../../features/product/offline/entities/product_entity.dart';
import '../../features/quotation/offline/entities/quotation_entity.dart';
import '../../features/shop/offline/entities/shop_image_cache_entity.dart';
import '../../features/supplier/offline/entities/supplier_entity.dart';
import 'app_database.dart';
import 'entity_mappers.dart';

extension LocalStore on AppDatabase {
  Future<int> saveCompany(CompanyEntity entity) =>
      _save(companyRecords, companyCompanion(entity), (id) => entity.id = id);

  Future<List<CompanyEntity>> loadCompanies() async {
    final rows = await select(companyRecords).get();
    return rows.map(companyFromRecord).toList();
  }

  Stream<List<CompanyEntity>> watchCompanies() {
    return select(companyRecords).watch().map(
      (rows) => rows.map(companyFromRecord).toList(),
    );
  }

  Future<bool> deleteCompanyById(int id) {
    return (delete(companyRecords)..where((t) => t.id.equals(id))).go().then(
      (count) => count > 0,
    );
  }

  Future<void> clearCompanies() => delete(companyRecords).go();

  Future<int> countCompanies() async {
    final count = companyRecords.id.count();
    final query = selectOnly(companyRecords)..addColumns([count]);
    final row = await query.getSingle();
    return row.read(count) ?? 0;
  }

  Future<int> saveCustomer(CustomerEntity entity) => _save(
    customerRecords,
    customerCompanion(entity),
    (id) => entity.id = id,
  );

  Future<List<CustomerEntity>> loadCustomers() async {
    final rows = await select(customerRecords).get();
    return rows.map(customerFromRecord).toList();
  }

  Stream<List<CustomerEntity>> watchCustomers() {
    return select(customerRecords).watch().map(
      (rows) => rows.map(customerFromRecord).toList(),
    );
  }

  Future<bool> deleteCustomerById(int id) {
    return (delete(customerRecords)..where((t) => t.id.equals(id))).go().then(
      (count) => count > 0,
    );
  }

  Future<void> clearCustomers() => delete(customerRecords).go();

  Future<int> countCustomers() async {
    final count = customerRecords.id.count();
    final query = selectOnly(customerRecords)..addColumns([count]);
    return (await query.getSingle()).read(count) ?? 0;
  }

  Future<int> saveSupplier(SupplierEntity entity) => _save(
    supplierRecords,
    supplierCompanion(entity),
    (id) => entity.id = id,
  );

  Future<List<SupplierEntity>> loadSuppliers() async {
    final rows = await select(supplierRecords).get();
    return rows.map(supplierFromRecord).toList();
  }

  Stream<List<SupplierEntity>> watchSuppliers() {
    return select(supplierRecords).watch().map(
      (rows) => rows.map(supplierFromRecord).toList(),
    );
  }

  Future<bool> deleteSupplierById(int id) {
    return (delete(supplierRecords)..where((t) => t.id.equals(id))).go().then(
      (count) => count > 0,
    );
  }

  Future<void> clearSuppliers() => delete(supplierRecords).go();

  Future<int> countSuppliers() async {
    final count = supplierRecords.id.count();
    final query = selectOnly(supplierRecords)..addColumns([count]);
    return (await query.getSingle()).read(count) ?? 0;
  }

  Future<int> saveProduct(ProductEntity entity) =>
      _save(productRecords, productCompanion(entity), (id) => entity.id = id);

  Future<List<ProductEntity>> loadProducts() async {
    final rows = await select(productRecords).get();
    return rows.map(productFromRecord).toList();
  }

  Stream<List<ProductEntity>> watchProducts() {
    return select(productRecords).watch().map(
      (rows) => rows.map(productFromRecord).toList(),
    );
  }

  Future<bool> deleteProductById(int id) {
    return (delete(productRecords)..where((t) => t.id.equals(id))).go().then(
      (count) => count > 0,
    );
  }

  Future<void> clearProducts() => delete(productRecords).go();

  Future<int> countProducts() async {
    final count = productRecords.id.count();
    final query = selectOnly(productRecords)..addColumns([count]);
    return (await query.getSingle()).read(count) ?? 0;
  }

  Future<int> savePurchase(PurchaseEntity entity) => _save(
    purchaseRecords,
    purchaseCompanion(entity),
    (id) => entity.id = id,
  );

  Future<List<PurchaseEntity>> loadPurchases() async {
    final rows = await select(purchaseRecords).get();
    return rows.map(purchaseFromRecord).toList();
  }

  Stream<List<PurchaseEntity>> watchPurchases() {
    return select(purchaseRecords).watch().map(
      (rows) => rows.map(purchaseFromRecord).toList(),
    );
  }

  Future<bool> deletePurchaseById(int id) {
    return (delete(purchaseRecords)..where((t) => t.id.equals(id))).go().then(
      (count) => count > 0,
    );
  }

  Future<void> clearPurchases() => delete(purchaseRecords).go();

  Future<int> countPurchases() async {
    final count = purchaseRecords.id.count();
    final query = selectOnly(purchaseRecords)..addColumns([count]);
    return (await query.getSingle()).read(count) ?? 0;
  }

  Future<int> saveBatch(PurchaseBatchEntity entity) =>
      _save(purchaseBatchRecords, batchCompanion(entity), (id) => entity.id = id);

  Future<List<PurchaseBatchEntity>> loadBatches() async {
    final rows = await select(purchaseBatchRecords).get();
    return rows.map(batchFromRecord).toList();
  }

  Stream<List<PurchaseBatchEntity>> watchBatches() {
    return select(purchaseBatchRecords).watch().map(
      (rows) => rows.map(batchFromRecord).toList(),
    );
  }

  Future<bool> deleteBatchById(int id) {
    return (delete(purchaseBatchRecords)..where((t) => t.id.equals(id)))
        .go()
        .then((count) => count > 0);
  }

  Future<int> deleteBatchesByIds(List<int> ids) {
    if (ids.isEmpty) return Future.value(0);
    return (delete(purchaseBatchRecords)..where((t) => t.id.isIn(ids))).go();
  }

  Future<void> clearBatches() => delete(purchaseBatchRecords).go();

  Future<int> countBatches() async {
    final count = purchaseBatchRecords.id.count();
    final query = selectOnly(purchaseBatchRecords)..addColumns([count]);
    return (await query.getSingle()).read(count) ?? 0;
  }

  Future<int> saveLedger(StockLedgerEntity entity) =>
      _save(stockLedgerRecords, ledgerCompanion(entity), (id) => entity.id = id);

  Future<List<StockLedgerEntity>> loadLedger() async {
    final rows = await select(stockLedgerRecords).get();
    return rows.map(ledgerFromRecord).toList();
  }

  Stream<List<StockLedgerEntity>> watchLedger() {
    return select(stockLedgerRecords).watch().map(
      (rows) => rows.map(ledgerFromRecord).toList(),
    );
  }

  Future<bool> deleteLedgerById(int id) {
    return (delete(stockLedgerRecords)..where((t) => t.id.equals(id)))
        .go()
        .then((count) => count > 0);
  }

  Future<void> clearLedger() => delete(stockLedgerRecords).go();

  Future<int> countLedger() async {
    final count = stockLedgerRecords.id.count();
    final query = selectOnly(stockLedgerRecords)..addColumns([count]);
    return (await query.getSingle()).read(count) ?? 0;
  }

  Future<int> saveBill(BillEntity entity) =>
      _save(billRecords, billCompanion(entity), (id) => entity.id = id);

  Future<List<BillEntity>> loadBills() async {
    final rows = await select(billRecords).get();
    return rows.map(billFromRecord).toList();
  }

  Stream<List<BillEntity>> watchBills() {
    return select(billRecords).watch().map(
      (rows) => rows.map(billFromRecord).toList(),
    );
  }

  Future<bool> deleteBillById(int id) {
    return (delete(billRecords)..where((t) => t.id.equals(id))).go().then(
      (count) => count > 0,
    );
  }

  Future<void> clearBills() => delete(billRecords).go();

  Future<int> countBills() async {
    final count = billRecords.id.count();
    final query = selectOnly(billRecords)..addColumns([count]);
    return (await query.getSingle()).read(count) ?? 0;
  }

  Future<int> saveEventOrder(EventOrderEntity entity) => _save(
    eventOrderRecords,
    eventOrderCompanion(entity),
    (id) => entity.id = id,
  );

  Future<List<EventOrderEntity>> loadEventOrders() async {
    final rows = await select(eventOrderRecords).get();
    return rows.map(eventOrderFromRecord).toList();
  }

  Stream<List<EventOrderEntity>> watchEventOrders() {
    return select(eventOrderRecords).watch().map(
      (rows) => rows.map(eventOrderFromRecord).toList(),
    );
  }

  Future<bool> deleteEventOrderById(int id) {
    return (delete(eventOrderRecords)..where((t) => t.id.equals(id))).go().then(
      (count) => count > 0,
    );
  }

  Future<int> deleteEventOrdersByIds(List<int> ids) {
    if (ids.isEmpty) return Future.value(0);
    return (delete(eventOrderRecords)..where((t) => t.id.isIn(ids))).go();
  }

  Future<void> clearEventOrders() => delete(eventOrderRecords).go();

  Future<int> countEventOrders() async {
    final count = eventOrderRecords.id.count();
    final query = selectOnly(eventOrderRecords)..addColumns([count]);
    return (await query.getSingle()).read(count) ?? 0;
  }

  Future<int> saveQuotation(QuotationEntity entity) => _save(
    quotationRecords,
    quotationCompanion(entity),
    (id) => entity.id = id,
  );

  Future<List<QuotationEntity>> loadQuotations() async {
    final rows = await select(quotationRecords).get();
    return rows.map(quotationFromRecord).toList();
  }

  Stream<List<QuotationEntity>> watchQuotations() {
    return select(quotationRecords).watch().map(
      (rows) => rows.map(quotationFromRecord).toList(),
    );
  }

  Future<bool> deleteQuotationById(int id) {
    return (delete(quotationRecords)..where((t) => t.id.equals(id))).go().then(
      (count) => count > 0,
    );
  }

  Future<void> clearQuotations() => delete(quotationRecords).go();

  Future<int> countQuotations() async {
    final count = quotationRecords.id.count();
    final query = selectOnly(quotationRecords)..addColumns([count]);
    return (await query.getSingle()).read(count) ?? 0;
  }

  Future<int> saveExpense(ExpenseEntity entity) =>
      _save(expenseRecords, expenseCompanion(entity), (id) => entity.id = id);

  Future<List<ExpenseEntity>> loadExpenses() async {
    final rows = await select(expenseRecords).get();
    return rows.map(expenseFromRecord).toList();
  }

  Stream<List<ExpenseEntity>> watchExpenses() {
    return select(expenseRecords).watch().map(
      (rows) => rows.map(expenseFromRecord).toList(),
    );
  }

  Future<bool> deleteExpenseById(int id) {
    return (delete(expenseRecords)..where((t) => t.id.equals(id))).go().then(
      (count) => count > 0,
    );
  }

  Future<void> clearExpenses() => delete(expenseRecords).go();

  Future<int> countExpenses() async {
    final count = expenseRecords.id.count();
    final query = selectOnly(expenseRecords)..addColumns([count]);
    return (await query.getSingle()).read(count) ?? 0;
  }

  Future<int> saveShopImage(ShopImageCacheEntity entity) => _save(
    shopImageRecords,
    shopImageCompanion(entity),
    (id) => entity.id = id,
  );

  Future<List<ShopImageCacheEntity>> loadShopImages() async {
    final rows = await select(shopImageRecords).get();
    return rows.map(shopImageFromRecord).toList();
  }

  Stream<List<ShopImageCacheEntity>> watchShopImages() {
    return select(shopImageRecords).watch().map(
      (rows) => rows.map(shopImageFromRecord).toList(),
    );
  }

  Future<bool> deleteShopImageById(int id) {
    return (delete(shopImageRecords)..where((t) => t.id.equals(id))).go().then(
      (count) => count > 0,
    );
  }

  Future<int> deleteAllShopImages() => delete(shopImageRecords).go();

  Future<void> clearShopImages() => delete(shopImageRecords).go();

  Future<int> saveTransaction(CustomerTransactionEntity entity) => _save(
    customerTransactionRecords,
    transactionCompanion(entity),
    (id) => entity.id = id,
  );

  Future<List<CustomerTransactionEntity>> loadTransactions() async {
    final rows = await select(customerTransactionRecords).get();
    return rows.map(transactionFromRecord).toList();
  }

  Stream<List<CustomerTransactionEntity>> watchTransactions() {
    return select(customerTransactionRecords).watch().map(
      (rows) => rows.map(transactionFromRecord).toList(),
    );
  }

  Future<bool> deleteTransactionById(int id) {
    return (delete(customerTransactionRecords)..where((t) => t.id.equals(id)))
        .go()
        .then((count) => count > 0);
  }

  Future<void> clearTransactions() => delete(customerTransactionRecords).go();

  Future<int> countTransactions() async {
    final count = customerTransactionRecords.id.count();
    final query = selectOnly(customerTransactionRecords)..addColumns([count]);
    return (await query.getSingle()).read(count) ?? 0;
  }

  Future<int> _save<T extends Table, D>(
    TableInfo<T, D> table,
    Insertable<D> companion,
    void Function(int id) assignId,
  ) async {
    final id = await into(table).insertOnConflictUpdate(companion);
    assignId(id);
    return id;
  }
}

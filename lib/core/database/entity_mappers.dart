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
import 'entity_codec.dart';

Value<int> rowId(int id) => id == 0 ? const Value.absent() : Value(id);

CompanyEntity companyFromRecord(CompanyRecord row) {
  final entity = CompanyEntity(
    serverId: row.serverId,
    companyName: row.companyName,
    companyCode: row.companyCode,
    gstCode: row.gstCode,
    contact: row.contact,
    address: row.address,
    isActive: row.isActive,
    syncStatus: enumAt(CompanySyncStatus.values, row.syncStatus),
    updatedAt: row.updatedAt,
    createdAt: row.createdAt,
  )..id = row.id;
  return entity;
}

CompanyRecordsCompanion companyCompanion(CompanyEntity entity) {
  return CompanyRecordsCompanion(
    id: rowId(entity.id),
    serverId: Value(entity.serverId),
    companyName: Value(entity.companyName),
    companyCode: Value(entity.companyCode),
    gstCode: Value(entity.gstCode),
    contact: Value(entity.contact),
    address: Value(entity.address),
    isActive: Value(entity.isActive),
    syncStatus: Value(entity.syncStatus.index),
    updatedAt: Value(entity.updatedAt),
    createdAt: Value(entity.createdAt),
  );
}

CustomerEntity customerFromRecord(CustomerRecord row) {
  return CustomerEntity(
    serverId: row.serverId,
    name: row.name,
    mobile: row.mobile,
    address: row.address,
    email: row.email,
    currentPendingAmount: row.currentPendingAmount,
    totalPurchases: row.totalPurchases,
    isSynced: row.isSynced,
    isDeleted: row.isDeleted,
    updatedAt: row.updatedAt,
    createdAt: row.createdAt,
  )..id = row.id;
}

CustomerRecordsCompanion customerCompanion(CustomerEntity entity) {
  return CustomerRecordsCompanion(
    id: rowId(entity.id),
    serverId: Value(entity.serverId),
    name: Value(entity.name),
    mobile: Value(entity.mobile),
    address: Value(entity.address),
    email: Value(entity.email),
    currentPendingAmount: Value(entity.currentPendingAmount),
    totalPurchases: Value(entity.totalPurchases),
    isSynced: Value(entity.isSynced),
    isDeleted: Value(entity.isDeleted),
    updatedAt: Value(entity.updatedAt),
    createdAt: Value(entity.createdAt),
  );
}

SupplierEntity supplierFromRecord(SupplierRecord row) {
  return SupplierEntity(
    serverId: row.serverId,
    firstName: row.firstName,
    middleName: row.middleName,
    lastName: row.lastName,
    supplierCode: row.supplierCode,
    contact: row.contact,
    address: row.address,
    isActive: row.isActive,
    syncStatus: enumAt(SupplierSyncStatus.values, row.syncStatus),
    updatedAt: row.updatedAt,
    createdAt: row.createdAt,
  )..id = row.id;
}

SupplierRecordsCompanion supplierCompanion(SupplierEntity entity) {
  return SupplierRecordsCompanion(
    id: rowId(entity.id),
    serverId: Value(entity.serverId),
    firstName: Value(entity.firstName),
    middleName: Value(entity.middleName),
    lastName: Value(entity.lastName),
    supplierCode: Value(entity.supplierCode),
    contact: Value(entity.contact),
    address: Value(entity.address),
    isActive: Value(entity.isActive),
    syncStatus: Value(entity.syncStatus.index),
    updatedAt: Value(entity.updatedAt),
    createdAt: Value(entity.createdAt),
  );
}

ProductEntity productFromRecord(ProductRecord row) {
  return ProductEntity(
    serverId: row.serverId,
    indexNo: row.indexNo,
    name: row.name,
    companyName: row.companyName,
    category: row.category,
    barcode: row.barcode,
    purchasePrice: row.purchasePrice,
    salesPrice: row.salesPrice,
    currentStock: row.currentStock,
    unit: row.unit,
    isActive: row.isActive,
    syncStatus: enumAt(SyncStatus.values, row.syncStatus),
    updatedAt: row.updatedAt,
    createdAt: row.createdAt,
    minStockLevel: row.minStockLevel,
    description: row.description,
    imageUrl: row.imageUrl,
    defaultSupplierId: row.defaultSupplierId,
    defaultSupplierName: row.defaultSupplierName,
    cgstPercent: row.cgstPercent,
    sgstPercent: row.sgstPercent,
    hsnCode: row.hsnCode,
    customFieldsJson: row.customFieldsJson,
  )..id = row.id;
}

ProductRecordsCompanion productCompanion(ProductEntity entity) {
  return ProductRecordsCompanion(
    id: rowId(entity.id),
    serverId: Value(entity.serverId),
    indexNo: Value(entity.indexNo),
    name: Value(entity.name),
    companyName: Value(entity.companyName),
    category: Value(entity.category),
    barcode: Value(entity.barcode),
    purchasePrice: Value(entity.purchasePrice),
    salesPrice: Value(entity.salesPrice),
    currentStock: Value(entity.currentStock),
    unit: Value(entity.unit),
    isActive: Value(entity.isActive),
    syncStatus: Value(entity.syncStatus.index),
    updatedAt: Value(entity.updatedAt),
    createdAt: Value(entity.createdAt),
    minStockLevel: Value(entity.minStockLevel),
    description: Value(entity.description),
    imageUrl: Value(entity.imageUrl),
    defaultSupplierId: Value(entity.defaultSupplierId),
    defaultSupplierName: Value(entity.defaultSupplierName),
    cgstPercent: Value(entity.cgstPercent),
    sgstPercent: Value(entity.sgstPercent),
    hsnCode: Value(entity.hsnCode),
    customFieldsJson: Value(entity.customFieldsJson),
  );
}

PurchaseEntity purchaseFromRecord(PurchaseRecord row) {
  return PurchaseEntity(
    serverId: row.serverId,
    productId: row.productId,
    productName: row.productName,
    supplierId: row.supplierId,
    supplierName: row.supplierName,
    companyId: row.companyId,
    companyName: row.companyName,
    quantity: row.quantity,
    unit: row.unit,
    purchasePrice: row.purchasePrice,
    salesPrice: row.salesPrice,
    totalAmount: row.totalAmount,
    productionDate: row.productionDate,
    expiryDate: row.expiryDate,
    warrantyMonths: row.warrantyMonths,
    notes: row.notes,
    syncStatus: enumAt(PurchaseSyncStatus.values, row.syncStatus),
    createdAt: row.createdAt,
    updatedAt: row.updatedAt,
  )..id = row.id;
}

PurchaseRecordsCompanion purchaseCompanion(PurchaseEntity entity) {
  return PurchaseRecordsCompanion(
    id: rowId(entity.id),
    serverId: Value(entity.serverId),
    productId: Value(entity.productId),
    productName: Value(entity.productName),
    supplierId: Value(entity.supplierId),
    supplierName: Value(entity.supplierName),
    companyId: Value(entity.companyId),
    companyName: Value(entity.companyName),
    quantity: Value(entity.quantity),
    unit: Value(entity.unit),
    purchasePrice: Value(entity.purchasePrice),
    salesPrice: Value(entity.salesPrice),
    totalAmount: Value(entity.totalAmount),
    productionDate: Value(entity.productionDate),
    expiryDate: Value(entity.expiryDate),
    warrantyMonths: Value(entity.warrantyMonths),
    notes: Value(entity.notes),
    syncStatus: Value(entity.syncStatus.index),
    createdAt: Value(entity.createdAt),
    updatedAt: Value(entity.updatedAt),
  );
}

PurchaseBatchEntity batchFromRecord(PurchaseBatchRecord row) {
  return PurchaseBatchEntity(
    serverId: row.serverId,
    productId: row.productId,
    productName: row.productName,
    companyName: row.companyName,
    modelName: row.modelName,
    category: row.category,
    productUniqueKey: row.productUniqueKey,
    purchasePrice: row.purchasePrice,
    sellingPrice: row.sellingPrice,
    quantityPurchased: row.quantityPurchased,
    quantityRemaining: row.quantityRemaining,
    purchaseDate: row.purchaseDate,
    supplierId: row.supplierId,
    supplierName: row.supplierName,
    unit: row.unit,
    expiryDate: row.expiryDate,
    productionDate: row.productionDate,
    warrantyMonths: row.warrantyMonths,
    notes: row.notes,
    isConsumed: row.isConsumed,
    syncStatus: enumAt(BatchSyncStatus.values, row.syncStatus),
    createdAt: row.createdAt,
    updatedAt: row.updatedAt,
  )..id = row.id;
}

PurchaseBatchRecordsCompanion batchCompanion(PurchaseBatchEntity entity) {
  return PurchaseBatchRecordsCompanion(
    id: rowId(entity.id),
    serverId: Value(entity.serverId),
    productId: Value(entity.productId),
    productName: Value(entity.productName),
    companyName: Value(entity.companyName),
    modelName: Value(entity.modelName),
    category: Value(entity.category),
    productUniqueKey: Value(entity.productUniqueKey),
    purchasePrice: Value(entity.purchasePrice),
    sellingPrice: Value(entity.sellingPrice),
    quantityPurchased: Value(entity.quantityPurchased),
    quantityRemaining: Value(entity.quantityRemaining),
    purchaseDate: Value(entity.purchaseDate),
    supplierId: Value(entity.supplierId),
    supplierName: Value(entity.supplierName),
    unit: Value(entity.unit),
    expiryDate: Value(entity.expiryDate),
    productionDate: Value(entity.productionDate),
    warrantyMonths: Value(entity.warrantyMonths),
    notes: Value(entity.notes),
    isConsumed: Value(entity.isConsumed),
    syncStatus: Value(entity.syncStatus.index),
    createdAt: Value(entity.createdAt),
    updatedAt: Value(entity.updatedAt),
  );
}

StockLedgerEntity ledgerFromRecord(StockLedgerRecord row) {
  return StockLedgerEntity(
    serverId: row.serverId,
    productId: row.productId,
    productName: row.productName,
    companyName: row.companyName,
    modelName: row.modelName,
    productUniqueKey: row.productUniqueKey,
    batchId: row.batchId,
    localBatchId: row.localBatchId,
    ledgerType: enumAt(LedgerTransactionType.values, row.ledgerType),
    referenceId: row.referenceId,
    referenceType: row.referenceType,
    quantity: row.quantity,
    costPrice: row.costPrice,
    sellingPrice: row.sellingPrice,
    totalCost: row.totalCost,
    totalRevenue: row.totalRevenue,
    profit: row.profit,
    balanceQuantity: row.balanceQuantity,
    balanceValue: row.balanceValue,
    transactionDate: row.transactionDate,
    notes: row.notes,
    syncStatus: enumAt(LedgerSyncStatus.values, row.syncStatus),
    createdAt: row.createdAt,
  )..id = row.id;
}

StockLedgerRecordsCompanion ledgerCompanion(StockLedgerEntity entity) {
  return StockLedgerRecordsCompanion(
    id: rowId(entity.id),
    serverId: Value(entity.serverId),
    productId: Value(entity.productId),
    productName: Value(entity.productName),
    companyName: Value(entity.companyName),
    modelName: Value(entity.modelName),
    productUniqueKey: Value(entity.productUniqueKey),
    batchId: Value(entity.batchId),
    localBatchId: Value(entity.localBatchId),
    ledgerType: Value(entity.ledgerType.index),
    referenceId: Value(entity.referenceId),
    referenceType: Value(entity.referenceType),
    quantity: Value(entity.quantity),
    costPrice: Value(entity.costPrice),
    sellingPrice: Value(entity.sellingPrice),
    totalCost: Value(entity.totalCost),
    totalRevenue: Value(entity.totalRevenue),
    profit: Value(entity.profit),
    balanceQuantity: Value(entity.balanceQuantity),
    balanceValue: Value(entity.balanceValue),
    transactionDate: Value(entity.transactionDate),
    notes: Value(entity.notes),
    syncStatus: Value(entity.syncStatus.index),
    createdAt: Value(entity.createdAt),
  );
}

BillEntity billFromRecord(BillRecord row) {
  return BillEntity(
    serverId: row.serverId,
    customerId: row.customerId,
    customerName: row.customerName,
    customerContact: row.customerContact,
    items: decodeBillItems(row.itemsJson),
    totalQuantity: row.totalQuantity,
    totalAmount: row.totalAmount,
    discountAmount: row.discountAmount,
    discountPercent: row.discountPercent,
    finalAmount: row.finalAmount,
    billDate: row.billDate,
    notes: row.notes,
    returnStatus: row.returnStatus,
    returnDate: row.returnDate,
    paymentStatus: enumAt(BillPaymentStatus.values, row.paymentStatus),
    paidAmount: row.paidAmount,
    pendingAmount: row.pendingAmount,
    isGstApplied: row.isGstApplied,
    isTaxInclusive: row.isTaxInclusive,
    cgstPercent: row.cgstPercent,
    sgstPercent: row.sgstPercent,
    otherTaxPercent: row.otherTaxPercent,
    otherTaxName: row.otherTaxName,
    cgstAmount: row.cgstAmount,
    sgstAmount: row.sgstAmount,
    otherTaxAmount: row.otherTaxAmount,
    totalTaxAmount: row.totalTaxAmount,
    extraCharges: decodeExtraCharges(row.extraChargesJson),
    paymentMode: row.paymentMode.trim().isEmpty ? 'CASH' : row.paymentMode,
    syncStatus: enumAt(BillSyncStatus.values, row.syncStatus),
    createdAt: row.createdAt,
    updatedAt: row.updatedAt,
  )..id = row.id;
}

BillRecordsCompanion billCompanion(BillEntity entity) {
  return BillRecordsCompanion(
    id: rowId(entity.id),
    serverId: Value(entity.serverId),
    customerId: Value(entity.customerId),
    customerName: Value(entity.customerName),
    customerContact: Value(entity.customerContact),
    itemsJson: Value(encodeBillItems(entity.items)),
    totalQuantity: Value(entity.totalQuantity),
    totalAmount: Value(entity.totalAmount),
    discountAmount: Value(entity.discountAmount),
    discountPercent: Value(entity.discountPercent),
    finalAmount: Value(entity.finalAmount),
    billDate: Value(entity.billDate),
    notes: Value(entity.notes),
    returnStatus: Value(entity.returnStatus),
    returnDate: Value(entity.returnDate),
    paymentStatus: Value(entity.paymentStatus.index),
    paidAmount: Value(entity.paidAmount),
    pendingAmount: Value(entity.pendingAmount),
    isGstApplied: Value(entity.isGstApplied),
    isTaxInclusive: Value(entity.isTaxInclusive),
    cgstPercent: Value(entity.cgstPercent),
    sgstPercent: Value(entity.sgstPercent),
    otherTaxPercent: Value(entity.otherTaxPercent),
    otherTaxName: Value(entity.otherTaxName),
    cgstAmount: Value(entity.cgstAmount),
    sgstAmount: Value(entity.sgstAmount),
    otherTaxAmount: Value(entity.otherTaxAmount),
    totalTaxAmount: Value(entity.totalTaxAmount),
    extraChargesJson: Value(encodeExtraCharges(entity.extraCharges)),
    paymentMode: Value(
      entity.paymentMode.trim().isEmpty ? 'CASH' : entity.paymentMode,
    ),
    syncStatus: Value(entity.syncStatus.index),
    createdAt: Value(entity.createdAt),
    updatedAt: Value(entity.updatedAt),
  );
}

EventOrderEntity eventOrderFromRecord(EventOrderRecord row) {
  return EventOrderEntity(
    serverId: row.serverId,
    orderType: row.orderType,
    customerId: row.customerId,
    customerName: row.customerName,
    customerContact: row.customerContact,
    customerAddress: row.customerAddress,
    orderName: row.orderName,
    description: row.description,
    eventDate: row.eventDate,
    eventLocation: row.eventLocation,
    subEvents: decodeSubEvents(row.subEventsJson),
    items: decodeOrderItems(row.itemsJson),
    eventCharges: row.eventCharges,
    totalAmount: row.totalAmount,
    advanceAmount: row.advanceAmount,
    remainingAmount: row.remainingAmount,
    notes: row.notes,
    status: row.status,
    convertedBillId: row.convertedBillId,
    customDataJson: row.customDataJson,
    createdAt: row.createdAt,
    updatedAt: row.updatedAt,
    syncStatus: enumAt(EventOrderSyncStatus.values, row.syncStatus),
  )..id = row.id;
}

EventOrderRecordsCompanion eventOrderCompanion(EventOrderEntity entity) {
  return EventOrderRecordsCompanion(
    id: rowId(entity.id),
    serverId: Value(entity.serverId),
    orderType: Value(entity.orderType),
    customerId: Value(entity.customerId),
    customerName: Value(entity.customerName),
    customerContact: Value(entity.customerContact),
    customerAddress: Value(entity.customerAddress),
    orderName: Value(entity.orderName),
    description: Value(entity.description),
    eventDate: Value(entity.eventDate),
    eventLocation: Value(entity.eventLocation),
    subEventsJson: Value(encodeSubEvents(entity.subEvents)),
    itemsJson: Value(encodeOrderItems(entity.items)),
    eventCharges: Value(entity.eventCharges),
    totalAmount: Value(entity.totalAmount),
    advanceAmount: Value(entity.advanceAmount),
    remainingAmount: Value(entity.remainingAmount),
    notes: Value(entity.notes),
    status: Value(entity.status),
    convertedBillId: Value(entity.convertedBillId),
    customDataJson: Value(entity.customDataJson),
    createdAt: Value(entity.createdAt),
    updatedAt: Value(entity.updatedAt),
    syncStatus: Value(entity.syncStatus.index),
  );
}

QuotationEntity quotationFromRecord(QuotationRecord row) {
  return QuotationEntity(
    serverId: row.serverId,
    quotationNumber: row.quotationNumber,
    quotationType: row.quotationType,
    customerId: row.customerId,
    customerName: row.customerName,
    customerContact: row.customerContact,
    customerAddress: row.customerAddress,
    title: row.title,
    description: row.description,
    referenceDate: row.referenceDate,
    eventLocation: row.eventLocation,
    validUntil: row.validUntil,
    subEvents: decodeSubEvents(row.subEventsJson),
    items: decodeOrderItems(row.itemsJson),
    eventCharges: row.eventCharges,
    discountPercent: row.discountPercent,
    discountAmount: row.discountAmount,
    totalAmount: row.totalAmount,
    notes: row.notes,
    status: row.status,
    convertedBillId: row.convertedBillId,
    convertedEventOrderId: row.convertedEventOrderId,
    customDataJson: row.customDataJson,
    createdAt: row.createdAt,
    updatedAt: row.updatedAt,
    syncStatus: enumAt(QuotationSyncStatus.values, row.syncStatus),
  )..id = row.id;
}

QuotationRecordsCompanion quotationCompanion(QuotationEntity entity) {
  return QuotationRecordsCompanion(
    id: rowId(entity.id),
    serverId: Value(entity.serverId),
    quotationNumber: Value(entity.quotationNumber),
    quotationType: Value(entity.quotationType),
    customerId: Value(entity.customerId),
    customerName: Value(entity.customerName),
    customerContact: Value(entity.customerContact),
    customerAddress: Value(entity.customerAddress),
    title: Value(entity.title),
    description: Value(entity.description),
    referenceDate: Value(entity.referenceDate),
    eventLocation: Value(entity.eventLocation),
    validUntil: Value(entity.validUntil),
    subEventsJson: Value(encodeSubEvents(entity.subEvents)),
    itemsJson: Value(encodeOrderItems(entity.items)),
    eventCharges: Value(entity.eventCharges),
    discountPercent: Value(entity.discountPercent),
    discountAmount: Value(entity.discountAmount),
    totalAmount: Value(entity.totalAmount),
    notes: Value(entity.notes),
    status: Value(entity.status),
    convertedBillId: Value(entity.convertedBillId),
    convertedEventOrderId: Value(entity.convertedEventOrderId),
    customDataJson: Value(entity.customDataJson),
    createdAt: Value(entity.createdAt),
    updatedAt: Value(entity.updatedAt),
    syncStatus: Value(entity.syncStatus.index),
  );
}

ExpenseEntity expenseFromRecord(ExpenseRecord row) {
  return ExpenseEntity(
    serverId: row.serverId,
    title: row.title,
    description: row.description,
    category: enumAt(ExpenseCategory.values, row.category),
    amount: row.amount,
    paymentMethod: row.paymentMethod,
    vendorName: row.vendorName,
    receiptNumber: row.receiptNumber,
    isRecurring: row.isRecurring,
    expenseDate: row.expenseDate,
    notes: row.notes,
    syncStatus: enumAt(ExpenseSyncStatus.values, row.syncStatus),
    createdAt: row.createdAt,
    updatedAt: row.updatedAt,
  )..id = row.id;
}

ExpenseRecordsCompanion expenseCompanion(ExpenseEntity entity) {
  return ExpenseRecordsCompanion(
    id: rowId(entity.id),
    serverId: Value(entity.serverId),
    title: Value(entity.title),
    description: Value(entity.description),
    category: Value(entity.category.index),
    amount: Value(entity.amount),
    paymentMethod: Value(entity.paymentMethod),
    vendorName: Value(entity.vendorName),
    receiptNumber: Value(entity.receiptNumber),
    isRecurring: Value(entity.isRecurring),
    expenseDate: Value(entity.expenseDate),
    notes: Value(entity.notes),
    syncStatus: Value(entity.syncStatus.index),
    createdAt: Value(entity.createdAt),
    updatedAt: Value(entity.updatedAt),
  );
}

ShopImageCacheEntity shopImageFromRecord(ShopImageRecord row) {
  return ShopImageCacheEntity(
    userId: row.userId,
    shopLogoBase64: row.shopLogoBase64,
    signatureBase64: row.signatureBase64,
    qrCodeBase64: row.qrCodeBase64,
    lastSyncedAt: row.lastSyncedAt,
    updatedAt: row.updatedAt,
  )..id = row.id;
}

ShopImageRecordsCompanion shopImageCompanion(ShopImageCacheEntity entity) {
  return ShopImageRecordsCompanion(
    id: rowId(entity.id),
    userId: Value(entity.userId),
    shopLogoBase64: Value(entity.shopLogoBase64),
    signatureBase64: Value(entity.signatureBase64),
    qrCodeBase64: Value(entity.qrCodeBase64),
    lastSyncedAt: Value(entity.lastSyncedAt),
    updatedAt: Value(entity.updatedAt),
  );
}

CustomerTransactionEntity transactionFromRecord(CustomerTransactionRecord row) {
  return CustomerTransactionEntity(
    serverId: row.serverId,
    customerId: row.customerId,
    customerName: row.customerName,
    transactionType: enumAt(TransactionType.values, row.transactionType),
    amount: row.amount,
    balanceAfter: row.balanceAfter,
    referenceId: row.referenceId,
    referenceType: row.referenceType,
    description: row.description,
    paymentMethod: row.paymentMethod,
    transactionDate: row.transactionDate,
    syncStatus: enumAt(TransactionSyncStatus.values, row.syncStatus),
    createdAt: row.createdAt,
    updatedAt: row.updatedAt,
  )..id = row.id;
}

CustomerTransactionRecordsCompanion transactionCompanion(
  CustomerTransactionEntity entity,
) {
  return CustomerTransactionRecordsCompanion(
    id: rowId(entity.id),
    serverId: Value(entity.serverId),
    customerId: Value(entity.customerId),
    customerName: Value(entity.customerName),
    transactionType: Value(entity.transactionType.index),
    amount: Value(entity.amount),
    balanceAfter: Value(entity.balanceAfter),
    referenceId: Value(entity.referenceId),
    referenceType: Value(entity.referenceType),
    description: Value(entity.description),
    paymentMethod: Value(entity.paymentMethod),
    transactionDate: Value(entity.transactionDate),
    syncStatus: Value(entity.syncStatus.index),
    createdAt: Value(entity.createdAt),
    updatedAt: Value(entity.updatedAt),
  );
}

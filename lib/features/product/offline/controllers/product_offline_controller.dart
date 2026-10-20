import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart' show Timestamp;
import '../../../../core/database/app_database.dart';
import '../../../../core/database/local_store.dart';
import '../../../../core/services/local_database.dart';
import '../entities/product_entity.dart';

// Helper to parse DateTime from Firestore Timestamp or ISO8601 string
DateTime? _parseDateTime(dynamic value) {
  if (value == null) return null;
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  if (value is String) return DateTime.tryParse(value);
  return null;
}

// Controller for handling offline-first Product CRUD operations All UI reads should go through this controller (never directly from API) Key features: - Immediate local saves (no...
class ProductOfflineController extends ChangeNotifier {
  static ProductOfflineController? _instance;

  AppDatabase get _db => LocalDatabase.instance.db;

  ProductOfflineController._();

  static ProductOfflineController get instance {
    _instance ??= ProductOfflineController._();
    return _instance!;
  }

  List<ProductEntity> _byName(Iterable<ProductEntity> products) {
    final list = products.toList();
    list.sort((a, b) => a.name.compareTo(b.name));
    return list;
  }

  Future<ProductEntity?> _findById(int id) async {
    for (final product in await _db.loadProducts()) {
      if (product.id == id) return product;
    }
    return null;
  }

  Future<ProductEntity?> findDuplicateProduct(
    String name,
    String companyName,
  ) async {
    final normalizedName = name.trim().toLowerCase();
    final normalizedCompany = companyName.trim().toLowerCase();

    for (final product in await _db.loadProducts()) {
      if (product.syncStatus == SyncStatus.deleted) continue;
      if (product.name.trim().toLowerCase() == normalizedName &&
          product.companyName.trim().toLowerCase() == normalizedCompany) {
        return product;
      }
    }
    return null;
  }

  Future<int> _getNextIndexNo() async {
    final allProducts = (await _db.loadProducts())
        .where((product) => product.syncStatus != SyncStatus.deleted)
        .toList();

    if (allProducts.isEmpty) return 1;

    var maxIndex = 0;
    for (final product in allProducts) {
      if (product.indexNo > maxIndex) {
        maxIndex = product.indexNo;
      }
    }
    return maxIndex + 1;
  }

  Future<ProductEntity> addProduct({
    int indexNo = 0,
    required String name,
    String companyName = '',
    String category = '',
    String? barcode,
    required double purchasePrice,
    required double salesPrice,
    int currentStock = 0,
    String? unit,
    bool isActive = true,
    String? description,
    String? imageUrl,
    int? minStockLevel,
    bool skipDuplicateCheck = false,
    String? defaultSupplierId,
    String? defaultSupplierName,
    double cgstPercent = 0.0,
    double sgstPercent = 0.0,
    String? hsnCode,
    String? customFieldsJson,
  }) async {
    debugPrint('[ProductOffline] Adding product: $name');

    if (!skipDuplicateCheck) {
      final existingProduct = await findDuplicateProduct(name, companyName);
      if (existingProduct != null) {
        debugPrint(
          '[ProductOffline] Duplicate product found: ${existingProduct.name} (${existingProduct.companyName})',
        );
        throw Exception(
          'Product "${name.trim()}" ${companyName.isNotEmpty ? "from $companyName " : ""}already exists',
        );
      }
    }

    final effectiveIndexNo = indexNo > 0 ? indexNo : await _getNextIndexNo();
    debugPrint('[ProductOffline] Assigned product code: $effectiveIndexNo');

    final product = ProductEntity.create(
      indexNo: effectiveIndexNo,
      name: name,
      companyName: companyName,
      category: category,
      barcode: barcode,
      purchasePrice: purchasePrice,
      salesPrice: salesPrice,
      currentStock: currentStock,
      unit: unit,
      isActive: isActive,
      syncStatus: SyncStatus.newRecord,
      description: description,
      imageUrl: imageUrl,
      minStockLevel: minStockLevel,
      defaultSupplierId: defaultSupplierId,
      defaultSupplierName: defaultSupplierName,
      cgstPercent: cgstPercent,
      sgstPercent: sgstPercent,
      hsnCode: hsnCode,
      customFieldsJson: customFieldsJson,
    );

    await _db.saveProduct(product);

    debugPrint('[ProductOffline] Product saved with ID: ${product.id}');
    notifyListeners();
    return product;
  }

  Future<List<ProductEntity>> getAllProducts() async {
    return _byName(
      (await _db.loadProducts()).where(
        (product) => product.syncStatus != SyncStatus.deleted,
      ),
    );
  }

  Stream<List<ProductEntity>> watchAllProducts() {
    return _db.watchProducts().map(
      (rows) => _byName(
        rows.where((product) => product.syncStatus != SyncStatus.deleted),
      ),
    );
  }

  Future<ProductEntity?> getProductById(int id) => _findById(id);

  Future<ProductEntity?> getProductByServerId(String serverId) async {
    for (final product in await _db.loadProducts()) {
      if (product.serverId == serverId) return product;
    }
    return null;
  }

  Future<ProductEntity?> getProductByBarcode(String barcode) async {
    final needle = barcode.trim();
    if (needle.isEmpty) return null;
    final needleLower = needle.toLowerCase();

    ProductEntity? exact;
    ProductEntity? caseInsensitive;
    for (final product in await _db.loadProducts()) {
      if (product.syncStatus == SyncStatus.deleted) continue;
      final stored = (product.barcode ?? '').trim();
      if (stored.isEmpty) continue;
      if (stored == needle) {
        exact = product;
        break;
      }
      if (caseInsensitive == null && stored.toLowerCase() == needleLower) {
        caseInsensitive = product;
      }
    }
    return exact ?? caseInsensitive;
  }

  Future<ProductEntity?> getProductByIndexNo(int indexNo) async {
    for (final product in await _db.loadProducts()) {
      if (product.indexNo == indexNo &&
          product.syncStatus != SyncStatus.deleted) {
        return product;
      }
    }
    return null;
  }

  Future<List<ProductEntity>> searchByName(String query) async {
    if (query.isEmpty) return getAllProducts();
    final needle = query.toLowerCase();
    return _byName(
      (await _db.loadProducts()).where(
        (product) =>
            product.syncStatus != SyncStatus.deleted &&
            product.name.toLowerCase().contains(needle),
      ),
    );
  }

  Future<List<ProductEntity>> searchProducts(String query) async {
    if (query.isEmpty) return getAllProducts();
    final needle = query.toLowerCase();
    return _byName(
      (await _db.loadProducts()).where((product) {
        if (product.syncStatus == SyncStatus.deleted) return false;
        final barcode = product.barcode ?? '';
        return product.name.toLowerCase().contains(needle) ||
            barcode.contains(query);
      }),
    );
  }

  Future<List<ProductEntity>> getProductsByCategory(String category) async {
    return _byName(
      (await _db.loadProducts()).where(
        (product) =>
            product.syncStatus != SyncStatus.deleted &&
            product.category == category,
      ),
    );
  }

  Future<List<ProductEntity>> getLowStockProducts() async {
    final products = await getAllProducts();
    return products.where((product) {
      if (product.minStockLevel == null) return false;
      return product.currentStock <= product.minStockLevel!;
    }).toList();
  }

  Future<ProductEntity?> updateProduct({
    required int id,
    int? indexNo,
    String? name,
    String? companyName,
    String? category,
    String? barcode,
    double? purchasePrice,
    double? salesPrice,
    int? currentStock,
    String? unit,
    bool? isActive,
    String? description,
    String? imageUrl,
    int? minStockLevel,
    double? cgstPercent,
    double? sgstPercent,
    String? hsnCode,
    String? customFieldsJson,
  }) async {
    final existing = await _findById(id);
    if (existing == null) {
      debugPrint('[ProductOffline] Product not found: $id');
      return null;
    }

    final SyncStatus newSyncStatus;
    switch (existing.syncStatus) {
      case SyncStatus.newRecord:
        newSyncStatus = SyncStatus.newRecord;
        break;
      case SyncStatus.synced:
      case SyncStatus.updated:
        newSyncStatus = SyncStatus.updated;
        break;
      case SyncStatus.deleted:
        newSyncStatus = SyncStatus.deleted;
        break;
    }

    final updated = existing.copyWith(
      indexNo: indexNo,
      name: name,
      companyName: companyName,
      category: category,
      barcode: barcode,
      purchasePrice: purchasePrice,
      salesPrice: salesPrice,
      currentStock: currentStock,
      unit: unit,
      isActive: isActive,
      description: description,
      imageUrl: imageUrl,
      minStockLevel: minStockLevel,
      cgstPercent: cgstPercent,
      sgstPercent: sgstPercent,
      hsnCode: hsnCode,
      customFieldsJson: customFieldsJson,
      syncStatus: newSyncStatus,
      updatedAt: DateTime.now(),
    );

    await _db.saveProduct(updated);

    debugPrint(
      '[ProductOffline] Product updated: ${updated.id}, syncStatus: ${updated.syncStatus}',
    );
    notifyListeners();
    return updated;
  }

  Future<ProductEntity?> updateStock(int id, int newQuantity) async {
    return updateProduct(id: id, currentStock: newQuantity);
  }

  Future<ProductEntity?> adjustStock(int id, int adjustment) async {
    final existing = await _findById(id);
    if (existing == null) return null;

    final newQuantity = existing.currentStock + adjustment;
    return updateProduct(id: id, currentStock: newQuantity);
  }

  Future<ProductEntity?> decrementStock(
    String productServerId,
    int quantity,
  ) async {
    final existing = await getProductByServerId(productServerId);

    if (existing == null) {
      debugPrint(
        '[ProductOffline] Cannot decrement stock: product not found with serverId: $productServerId',
      );
      return null;
    }

    final newQuantity = (existing.currentStock - quantity)
        .clamp(0, double.maxFinite)
        .toInt();
    debugPrint(
      '[ProductOffline] Decrementing stock for ${existing.name}: ${existing.currentStock} - $quantity = $newQuantity',
    );
    return updateProduct(id: existing.id, currentStock: newQuantity);
  }

  Future<ProductEntity?> incrementStock(
    String productServerId,
    int quantity,
  ) async {
    final existing = await getProductByServerId(productServerId);

    if (existing == null) {
      debugPrint(
        '[ProductOffline] Cannot increment stock: product not found with serverId: $productServerId',
      );
      return null;
    }

    final newQuantity = existing.currentStock + quantity;
    debugPrint(
      '[ProductOffline] Incrementing stock for ${existing.name}: ${existing.currentStock} + $quantity = $newQuantity',
    );
    return updateProduct(id: existing.id, currentStock: newQuantity);
  }

  Future<void> deleteProduct(int id) async {
    final existing = await _findById(id);
    if (existing == null) return;

    if (existing.syncStatus == SyncStatus.newRecord) {
      debugPrint('[ProductOffline] Hard deleting NEW product: $id');
      await _db.deleteProductById(id);
    } else {
      debugPrint('[ProductOffline] Soft deleting product: $id');
      final updated = existing.copyWith(
        syncStatus: SyncStatus.deleted,
        updatedAt: DateTime.now(),
      );
      await _db.saveProduct(updated);
    }

    notifyListeners();
  }

  Future<void> permanentlyDelete(int id) async {
    await _db.deleteProductById(id);
    notifyListeners();
  }

  Future<List<ProductEntity>> getProductsNeedingSync() async {
    return (await _db.loadProducts())
        .where((product) => product.syncStatus != SyncStatus.synced)
        .toList();
  }

  Future<List<ProductEntity>> getNewProducts() async {
    return (await _db.loadProducts())
        .where((product) => product.syncStatus == SyncStatus.newRecord)
        .toList();
  }

  Future<List<ProductEntity>> getUpdatedProducts() async {
    return (await _db.loadProducts())
        .where((product) => product.syncStatus == SyncStatus.updated)
        .toList();
  }

  Future<List<ProductEntity>> getDeletedProducts() async {
    return (await _db.loadProducts())
        .where((product) => product.syncStatus == SyncStatus.deleted)
        .toList();
  }

  Future<int> getUnsyncedCount() async {
    return (await getProductsNeedingSync()).length;
  }

  Future<void> markAsSynced(int id, {String? serverId}) async {
    final existing = await _findById(id);
    if (existing == null) return;

    final updated = existing.copyWith(
      serverId: serverId ?? existing.serverId,
      syncStatus: SyncStatus.synced,
    );

    await _db.saveProduct(updated);
  }

  Future<int> importFromServer(
    List<Map<String, dynamic>> serverProducts,
  ) async {
    var imported = 0;

    await _db.transaction(() async {
      for (final productData in serverProducts) {
        final serverId = productData['id'] as String?;
        if (serverId == null) continue;

        final all = await _db.loadProducts();
        ProductEntity? existing;
        for (final product in all) {
          if (product.serverId == serverId) {
            existing = product;
            break;
          }
        }

        if (existing == null) {
          final name = (productData['name'] ?? '').toString();
          final companyName = (productData['companyName'] ?? '').toString();
          if (name.isNotEmpty) {
            final nameNeedle = name.toLowerCase();
            final companyNeedle = companyName.toLowerCase();
            for (final product in all) {
              if (product.name.toLowerCase() == nameNeedle &&
                  product.companyName.toLowerCase() == companyNeedle) {
                existing = product;
                break;
              }
            }
            if (existing != null && existing.serverId == null) {
              existing.serverId = serverId;
              existing.syncStatus = SyncStatus.synced;
              await _db.saveProduct(existing);
              imported++;
              continue;
            }
          }
        }

        if (existing != null) {
          if (existing.syncStatus == SyncStatus.synced) {
            final serverUpdatedAt = _parseDateTime(productData['updatedAt']);
            if (serverUpdatedAt != null &&
                serverUpdatedAt.isAfter(existing.updatedAt)) {
              final updated = ProductEntity.fromServer(productData);
              updated.id = existing.id;
              await _db.saveProduct(updated);
              imported++;
            }
          }
        } else {
          final newProduct = ProductEntity.fromServer(productData);
          await _db.saveProduct(newProduct);
          imported++;
        }
      }
    });

    if (imported > 0) {
      notifyListeners();
    }

    debugPrint('[ProductOffline] Imported $imported products from server');
    return imported;
  }

  Future<void> updateWithServerResponse(
    int localId,
    Map<String, dynamic> serverResponse,
  ) async {
    final existing = await _findById(localId);
    if (existing == null) return;

    final updated = existing.copyWith(
      serverId: serverResponse['id'] as String?,
      syncStatus: SyncStatus.synced,
    );

    await _db.saveProduct(updated);
  }

  Future<int> clearDeletedRecords() async {
    final deleted = await getDeletedProducts();
    if (deleted.isEmpty) return 0;

    await _db.transaction(() async {
      for (final entity in deleted) {
        await _db.deleteProductById(entity.id);
      }
    });

    notifyListeners();
    return deleted.length;
  }

  Future<int> getTotalCount() async {
    return (await _db.loadProducts())
        .where((product) => product.syncStatus != SyncStatus.deleted)
        .length;
  }

  Future<double> getTotalStockValue() async {
    final products = await getAllProducts();
    return products.fold<double>(
      0,
      (total, product) =>
          total + (product.purchasePrice * product.currentStock),
    );
  }

  Future<List<String>> getAllCategories() async {
    final products = await getAllProducts();
    final categories = products
        .map((product) => product.category)
        .where((category) => category.isNotEmpty)
        .toSet()
        .toList();
    categories.sort();
    return categories;
  }
}

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:isar_community/isar.dart';
import '../../../../core/services/isar_service.dart';
import '../entities/product_entity.dart';

/// Controller for handling offline-first Product CRUD operations
/// All UI reads should go through this controller (never directly from API)
/// 
/// Key features:
/// - Immediate local saves (no network blocking)
/// - Proper syncStatus management for delta sync
/// - High-performance indexed queries
/// - Reactive streams for UI updates
class ProductOfflineController extends ChangeNotifier {
  static ProductOfflineController? _instance;
  
  Isar get _isar => IsarService.instance.isar;

  ProductOfflineController._();

  /// Get the singleton instance
  static ProductOfflineController get instance {
    _instance ??= ProductOfflineController._();
    return _instance!;
  }

  // ==================== CREATE ====================

  /// Check if a product with the same name and company already exists
  /// Returns the existing product if found, null otherwise
  Future<ProductEntity?> findDuplicateProduct(String name, String companyName) async {
    final normalizedName = name.trim().toLowerCase();
    final normalizedCompany = companyName.trim().toLowerCase();
    
    // Search for product with matching name and company (case-insensitive)
    final products = await _isar.productEntitys
        .filter()
        .not()
        .syncStatusEqualTo(SyncStatus.deleted)
        .findAll();
    
    for (final product in products) {
      if (product.name.trim().toLowerCase() == normalizedName &&
          product.companyName.trim().toLowerCase() == normalizedCompany) {
        return product;
      }
    }
    return null;
  }

  /// Get the next available product code (indexNo).
  /// Scans all non-deleted products and returns max(indexNo) + 1.
  /// If no products exist, starts at 1.
  Future<int> _getNextIndexNo() async {
    final allProducts = await _isar.productEntitys
        .filter()
        .not()
        .syncStatusEqualTo(SyncStatus.deleted)
        .findAll();
    
    if (allProducts.isEmpty) return 1;
    
    int maxIndex = 0;
    for (final p in allProducts) {
      if (p.indexNo > maxIndex) {
        maxIndex = p.indexNo;
      }
    }
    return maxIndex + 1;
  }

  /// Add a new product locally (will be synced later)
  /// Sets syncStatus = NEW, does NOT call API
  /// Throws exception if product with same name+company already exists
  /// Automatically generates indexNo (product code) if not provided or 0.
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
  }) async {
    debugPrint('[ProductOffline] Adding product: $name');
    
    // Check for duplicate product (same name + company)
    if (!skipDuplicateCheck) {
      final existingProduct = await findDuplicateProduct(name, companyName);
      if (existingProduct != null) {
        debugPrint('[ProductOffline] Duplicate product found: ${existingProduct.name} (${existingProduct.companyName})');
        throw Exception('Product "${name.trim()}" ${companyName.isNotEmpty ? "from $companyName " : ""}already exists');
      }
    }
    
    // Auto-generate product code if not provided
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
      syncStatus: SyncStatus.newRecord, // Mark as NEW for sync
      description: description,
      imageUrl: imageUrl,
      minStockLevel: minStockLevel,
      defaultSupplierId: defaultSupplierId,
      defaultSupplierName: defaultSupplierName,
      cgstPercent: cgstPercent,
      sgstPercent: sgstPercent,
      hsnCode: hsnCode,
    );

    await _isar.writeTxn(() async {
      await _isar.productEntitys.put(product);
    });
    
    debugPrint('[ProductOffline] Product saved with ID: ${product.id}');
    notifyListeners();
    return product;
  }

  // ==================== READ ====================

  /// Get all active (non-deleted) products
  /// Uses indexed query for performance
  Future<List<ProductEntity>> getAllProducts() async {
    return await _isar.productEntitys
        .filter()
        .not()
        .syncStatusEqualTo(SyncStatus.deleted)
        .sortByName()
        .findAll();
  }

  /// Watch all active products (reactive stream for UI)
  /// Fires immediately and on any changes
  Stream<List<ProductEntity>> watchAllProducts() {
    return _isar.productEntitys
        .filter()
        .not()
        .syncStatusEqualTo(SyncStatus.deleted)
        .sortByName()
        .watch(fireImmediately: true);
  }

  /// Get product by local Isar ID
  Future<ProductEntity?> getProductById(Id id) async {
    return await _isar.productEntitys.get(id);
  }

  /// Get product by server ID
  Future<ProductEntity?> getProductByServerId(String serverId) async {
    return await _isar.productEntitys
        .filter()
        .serverIdEqualTo(serverId)
        .findFirst();
  }

  /// Get product by barcode (fast indexed lookup)
  Future<ProductEntity?> getProductByBarcode(String barcode) async {
    return await _isar.productEntitys
        .filter()
        .barcodeEqualTo(barcode)
        .not()
        .syncStatusEqualTo(SyncStatus.deleted)
        .findFirst();
  }

  /// Search products by name (case-insensitive, indexed)
  Future<List<ProductEntity>> searchByName(String query) async {
    if (query.isEmpty) return getAllProducts();
    
    return await _isar.productEntitys
        .filter()
        .not()
        .syncStatusEqualTo(SyncStatus.deleted)
        .nameContains(query, caseSensitive: false)
        .sortByName()
        .findAll();
  }

  /// Search products by name or barcode
  Future<List<ProductEntity>> searchProducts(String query) async {
    if (query.isEmpty) return getAllProducts();
    
    return await _isar.productEntitys
        .filter()
        .not()
        .syncStatusEqualTo(SyncStatus.deleted)
        .group((q) => q
            .nameContains(query, caseSensitive: false)
            .or()
            .barcodeContains(query))
        .sortByName()
        .findAll();
  }

  /// Get products by category
  Future<List<ProductEntity>> getProductsByCategory(String category) async {
    return await _isar.productEntitys
        .filter()
        .not()
        .syncStatusEqualTo(SyncStatus.deleted)
        .categoryEqualTo(category)
        .sortByName()
        .findAll();
  }

  /// Get low stock products
  Future<List<ProductEntity>> getLowStockProducts() async {
    final products = await getAllProducts();
    return products.where((p) {
      if (p.minStockLevel == null) return false;
      return p.currentStock <= p.minStockLevel!;
    }).toList();
  }

  // ==================== UPDATE ====================

  /// Update an existing product
  /// If syncStatus was SYNCED, changes to UPDATED
  /// If syncStatus was NEW, keeps as NEW (not yet on server)
  Future<ProductEntity?> updateProduct({
    required Id id,
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
  }) async {
    final existing = await _isar.productEntitys.get(id);
    if (existing == null) {
      debugPrint('[ProductOffline] Product not found: $id');
      return null;
    }

    // Determine new syncStatus:
    // - If currently NEW → stay NEW (never synced)
    // - If currently SYNCED → change to UPDATED
    // - If currently UPDATED → stay UPDATED
    // - If currently DELETED → this shouldn't happen, but keep DELETED
    SyncStatus newSyncStatus;
    switch (existing.syncStatus) {
      case SyncStatus.newRecord:
        newSyncStatus = SyncStatus.newRecord;
        break;
      case SyncStatus.synced:
        newSyncStatus = SyncStatus.updated;
        break;
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
      syncStatus: newSyncStatus,
      updatedAt: DateTime.now(),
    );

    await _isar.writeTxn(() async {
      await _isar.productEntitys.put(updated);
    });

    debugPrint('[ProductOffline] Product updated: ${updated.id}, syncStatus: ${updated.syncStatus}');
    notifyListeners();
    return updated;
  }

  /// Update stock quantity only (common operation)
  Future<ProductEntity?> updateStock(Id id, int newQuantity) async {
    return await updateProduct(id: id, currentStock: newQuantity);
  }

  /// Adjust stock (add/subtract)
  Future<ProductEntity?> adjustStock(Id id, int adjustment) async {
    final existing = await _isar.productEntitys.get(id);
    if (existing == null) return null;
    
    final newQuantity = existing.currentStock + adjustment;
    return await updateProduct(id: id, currentStock: newQuantity);
  }

  /// Decrement stock by product server ID (used when creating bills)
  /// Reduces stock by the specified quantity
  Future<ProductEntity?> decrementStock(String productServerId, int quantity) async {
    // First find the product by server ID
    final existing = await _isar.productEntitys
        .filter()
        .serverIdEqualTo(productServerId)
        .findFirst();
    
    if (existing == null) {
      debugPrint('[ProductOffline] Cannot decrement stock: product not found with serverId: $productServerId');
      return null;
    }
    
    final newQuantity = (existing.currentStock - quantity).clamp(0, double.maxFinite).toInt();
    debugPrint('[ProductOffline] Decrementing stock for ${existing.name}: ${existing.currentStock} - $quantity = $newQuantity');
    return await updateProduct(id: existing.id, currentStock: newQuantity);
  }

  /// Increment stock by product server ID (used when restocking or returns)
  /// Increases stock by the specified quantity
  Future<ProductEntity?> incrementStock(String productServerId, int quantity) async {
    // First find the product by server ID
    final existing = await _isar.productEntitys
        .filter()
        .serverIdEqualTo(productServerId)
        .findFirst();
    
    if (existing == null) {
      debugPrint('[ProductOffline] Cannot increment stock: product not found with serverId: $productServerId');
      return null;
    }
    
    final newQuantity = existing.currentStock + quantity;
    debugPrint('[ProductOffline] Incrementing stock for ${existing.name}: ${existing.currentStock} + $quantity = $newQuantity');
    return await updateProduct(id: existing.id, currentStock: newQuantity);
  }

  // ==================== DELETE ====================

  /// Soft delete a product (marks for deletion, will be synced)
  /// Does NOT remove from Isar until server confirms deletion
  Future<void> deleteProduct(Id id) async {
    final existing = await _isar.productEntitys.get(id);
    if (existing == null) return;

    // If never synced to server (NEW), we can hard delete immediately
    if (existing.syncStatus == SyncStatus.newRecord) {
      debugPrint('[ProductOffline] Hard deleting NEW product: $id');
      await _isar.writeTxn(() async {
        await _isar.productEntitys.delete(id);
      });
    } else {
      // Soft delete - mark for server sync
      debugPrint('[ProductOffline] Soft deleting product: $id');
      final updated = existing.copyWith(
        syncStatus: SyncStatus.deleted,
        updatedAt: DateTime.now(),
      );

      await _isar.writeTxn(() async {
        await _isar.productEntitys.put(updated);
      });
    }

    notifyListeners();
  }

  /// Hard delete after confirmed server deletion
  Future<void> permanentlyDelete(Id id) async {
    await _isar.writeTxn(() async {
      await _isar.productEntitys.delete(id);
    });
    notifyListeners();
  }

  // ==================== SYNC HELPERS ====================

  /// Get all products that need to be synced (delta sync)
  /// Returns products where syncStatus != SYNCED
  Future<List<ProductEntity>> getProductsNeedingSync() async {
    return await _isar.productEntitys
        .filter()
        .not()
        .syncStatusEqualTo(SyncStatus.synced)
        .findAll();
  }

  /// Get NEW products (need to POST)
  Future<List<ProductEntity>> getNewProducts() async {
    return await _isar.productEntitys
        .filter()
        .syncStatusEqualTo(SyncStatus.newRecord)
        .findAll();
  }

  /// Get UPDATED products (need to PUT)
  Future<List<ProductEntity>> getUpdatedProducts() async {
    return await _isar.productEntitys
        .filter()
        .syncStatusEqualTo(SyncStatus.updated)
        .findAll();
  }

  /// Get DELETED products (need to DELETE on server)
  Future<List<ProductEntity>> getDeletedProducts() async {
    return await _isar.productEntitys
        .filter()
        .syncStatusEqualTo(SyncStatus.deleted)
        .findAll();
  }

  /// Get count of unsynced products
  Future<int> getUnsyncedCount() async {
    return await _isar.productEntitys
        .filter()
        .not()
        .syncStatusEqualTo(SyncStatus.synced)
        .count();
  }

  /// Mark product as synced (called after successful server sync)
  Future<void> markAsSynced(Id id, {String? serverId}) async {
    final existing = await _isar.productEntitys.get(id);
    if (existing == null) return;

    final updated = existing.copyWith(
      serverId: serverId ?? existing.serverId,
      syncStatus: SyncStatus.synced,
    );

    await _isar.writeTxn(() async {
      await _isar.productEntitys.put(updated);
    });
  }

  /// Import products from server (for initial sync or refresh)
  /// Merges by serverId, only updates if server version is newer
  Future<int> importFromServer(List<Map<String, dynamic>> serverProducts) async {
    int imported = 0;
    
    await _isar.writeTxn(() async {
      for (final productData in serverProducts) {
        final serverId = productData['id'] as String?;
        if (serverId == null) continue;

        // Check if exists locally by serverId
        var existing = await _isar.productEntitys
            .filter()
            .serverIdEqualTo(serverId)
            .findFirst();

        // Fallback: check by name + companyName (handles locally-created records without serverId yet)
        if (existing == null) {
          final name = (productData['name'] ?? '').toString();
          final companyName = (productData['companyName'] ?? '').toString();
          if (name.isNotEmpty) {
            existing = await _isar.productEntitys
                .filter()
                .nameEqualTo(name, caseSensitive: false)
                .and()
                .companyNameEqualTo(companyName, caseSensitive: false)
                .findFirst();
            if (existing != null && existing.serverId == null) {
              // Link local record with server ID and mark synced
              existing.serverId = serverId;
              existing.syncStatus = SyncStatus.synced;
              await _isar.productEntitys.put(existing);
              imported++;
              continue;
            }
          }
        }

        if (existing != null) {
          // Only update if not locally modified AND server is newer
          if (existing.syncStatus == SyncStatus.synced) {
            final serverUpdatedAt = DateTime.tryParse(
              productData['updatedAt']?.toString() ?? '',
            );
            if (serverUpdatedAt != null && serverUpdatedAt.isAfter(existing.updatedAt)) {
              final updated = ProductEntity.fromServer(productData);
              updated.id = existing.id; // Keep local ID
              await _isar.productEntitys.put(updated);
              imported++;
            }
          }
          // If locally modified, don't overwrite - local changes take precedence
        } else {
          // Create new
          final newProduct = ProductEntity.fromServer(productData);
          await _isar.productEntitys.put(newProduct);
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

  /// Update product with server response (after successful create)
  Future<void> updateWithServerResponse(Id localId, Map<String, dynamic> serverResponse) async {
    final existing = await _isar.productEntitys.get(localId);
    if (existing == null) return;

    final updated = existing.copyWith(
      serverId: serverResponse['id'] as String?,
      syncStatus: SyncStatus.synced,
    );

    await _isar.writeTxn(() async {
      await _isar.productEntitys.put(updated);
    });
  }

  /// Clear all synced deleted records (cleanup after successful server deletion)
  Future<int> clearDeletedRecords() async {
    final deleted = await _isar.productEntitys
        .filter()
        .syncStatusEqualTo(SyncStatus.deleted)
        .findAll();

    if (deleted.isEmpty) return 0;

    // Only remove products that have been confirmed deleted on server
    // For now, we'll just clear them after sync marks them
    await _isar.writeTxn(() async {
      for (final entity in deleted) {
        await _isar.productEntitys.delete(entity.id);
      }
    });

    notifyListeners();
    return deleted.length;
  }

  // ==================== STATISTICS ====================

  /// Get total product count
  Future<int> getTotalCount() async {
    return await _isar.productEntitys
        .filter()
        .not()
        .syncStatusEqualTo(SyncStatus.deleted)
        .count();
  }

  /// Get total stock value
  Future<double> getTotalStockValue() async {
    final products = await getAllProducts();
    return products.fold<double>(
      0,
      (sum, p) => sum + (p.purchasePrice * p.currentStock),
    );
  }

  /// Get all unique categories
  Future<List<String>> getAllCategories() async {
    final products = await getAllProducts();
    final categories = products
        .map((p) => p.category)
        .where((c) => c.isNotEmpty)
        .toSet()
        .toList();
    categories.sort();
    return categories;
  }
}

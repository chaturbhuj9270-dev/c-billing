import '../../offline/entities/product_entity.dart';
import '../../offline/controllers/product_offline_controller.dart';

/// Product model for domain layer
/// Clean separation from Isar entity
class Product {
  final int? localId;
  final String? serverId;
  final int indexNo;
  final String name;
  final String companyName;
  final String category;
  final String? barcode;
  final double purchasePrice;
  final double salesPrice;
  final int currentStock;
  final String? unit;
  final bool isActive;
  final bool isSynced;
  final SyncStatus syncStatus;
  final DateTime updatedAt;
  final DateTime createdAt;
  final String? description;
  final String? imageUrl;
  final int? minStockLevel;

  Product({
    this.localId,
    this.serverId,
    this.indexNo = 0,
    required this.name,
    this.companyName = '',
    this.category = '',
    this.barcode,
    required this.purchasePrice,
    required this.salesPrice,
    this.currentStock = 0,
    this.unit,
    this.isActive = true,
    this.isSynced = false,
    this.syncStatus = SyncStatus.newRecord,
    DateTime? updatedAt,
    DateTime? createdAt,
    this.description,
    this.imageUrl,
    this.minStockLevel,
  })  : updatedAt = updatedAt ?? DateTime.now(),
        createdAt = createdAt ?? DateTime.now();

  /// Create from entity
  factory Product.fromEntity(ProductEntity entity) {
    return Product(
      localId: entity.id,
      serverId: entity.serverId,
      indexNo: entity.indexNo,
      name: entity.name,
      companyName: entity.companyName,
      category: entity.category,
      barcode: entity.barcode,
      purchasePrice: entity.purchasePrice,
      salesPrice: entity.salesPrice,
      currentStock: entity.currentStock,
      unit: entity.unit,
      isActive: entity.isActive,
      isSynced: entity.syncStatus == SyncStatus.synced,
      syncStatus: entity.syncStatus,
      updatedAt: entity.updatedAt,
      createdAt: entity.createdAt,
      description: entity.description,
      imageUrl: entity.imageUrl,
      minStockLevel: entity.minStockLevel,
    );
  }

  /// Copy with modifications
  Product copyWith({
    int? localId,
    String? serverId,
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
    bool? isSynced,
    SyncStatus? syncStatus,
    DateTime? updatedAt,
    DateTime? createdAt,
    String? description,
    String? imageUrl,
    int? minStockLevel,
  }) {
    return Product(
      localId: localId ?? this.localId,
      serverId: serverId ?? this.serverId,
      indexNo: indexNo ?? this.indexNo,
      name: name ?? this.name,
      companyName: companyName ?? this.companyName,
      category: category ?? this.category,
      barcode: barcode ?? this.barcode,
      purchasePrice: purchasePrice ?? this.purchasePrice,
      salesPrice: salesPrice ?? this.salesPrice,
      currentStock: currentStock ?? this.currentStock,
      unit: unit ?? this.unit,
      isActive: isActive ?? this.isActive,
      isSynced: isSynced ?? this.isSynced,
      syncStatus: syncStatus ?? this.syncStatus,
      updatedAt: updatedAt ?? this.updatedAt,
      createdAt: createdAt ?? this.createdAt,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      minStockLevel: minStockLevel ?? this.minStockLevel,
    );
  }

  /// Get display ID (server ID if available, else local ID)
  String get displayId => serverId ?? 'local_$localId';

  /// Check if low stock
  bool get isLowStock {
    if (minStockLevel == null) return false;
    return currentStock <= minStockLevel!;
  }

  /// Get stock value
  double get stockValue => purchasePrice * currentStock;

  /// Get formatted price
  String get formattedPrice => '₹${purchasePrice.toStringAsFixed(2)}';

  /// Get formatted stock
  String get formattedStock {
    if (unit != null && unit!.isNotEmpty) {
      return '$currentStock $unit';
    }
    return currentStock.toString();
  }
}

/// Repository for Product data operations
/// Acts as the single source of truth for Product data
/// Always reads from local Isar database (offline-first)
class ProductRepository {
  static ProductRepository? _instance;
  
  final ProductOfflineController _offlineController;

  ProductRepository._(this._offlineController);

  /// Get the singleton instance
  static ProductRepository get instance {
    _instance ??= ProductRepository._(ProductOfflineController.instance);
    return _instance!;
  }

  // ==================== READ ====================

  /// Get all active products
  Future<List<Product>> getAllProducts() async {
    final entities = await _offlineController.getAllProducts();
    return entities.map((e) => Product.fromEntity(e)).toList();
  }

  /// Watch all products (reactive stream)
  Stream<List<Product>> watchAllProducts() {
    return _offlineController.watchAllProducts().map(
      (entities) => entities.map((e) => Product.fromEntity(e)).toList(),
    );
  }

  /// Get product by local ID
  Future<Product?> getProductById(int id) async {
    final entity = await _offlineController.getProductById(id);
    return entity != null ? Product.fromEntity(entity) : null;
  }

  /// Get product by barcode
  Future<Product?> getProductByBarcode(String barcode) async {
    final entity = await _offlineController.getProductByBarcode(barcode);
    return entity != null ? Product.fromEntity(entity) : null;
  }

  /// Search products by name or barcode
  Future<List<Product>> searchProducts(String query) async {
    final entities = await _offlineController.searchProducts(query);
    return entities.map((e) => Product.fromEntity(e)).toList();
  }

  /// Get products by category
  Future<List<Product>> getProductsByCategory(String category) async {
    final entities = await _offlineController.getProductsByCategory(category);
    return entities.map((e) => Product.fromEntity(e)).toList();
  }

  /// Get low stock products
  Future<List<Product>> getLowStockProducts() async {
    final entities = await _offlineController.getLowStockProducts();
    return entities.map((e) => Product.fromEntity(e)).toList();
  }

  /// Get all categories
  Future<List<String>> getAllCategories() async {
    return await _offlineController.getAllCategories();
  }

  // ==================== CREATE ====================

  /// Create a new product
  Future<Product> createProduct({
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
  }) async {
    final entity = await _offlineController.addProduct(
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
    );
    return Product.fromEntity(entity);
  }

  // ==================== UPDATE ====================

  /// Update an existing product
  Future<Product?> updateProduct({
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
  }) async {
    final entity = await _offlineController.updateProduct(
      id: id,
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
    );
    return entity != null ? Product.fromEntity(entity) : null;
  }

  /// Update stock quantity
  Future<Product?> updateStock(int id, int newQuantity) async {
    final entity = await _offlineController.updateStock(id, newQuantity);
    return entity != null ? Product.fromEntity(entity) : null;
  }

  /// Adjust stock (add/subtract)
  Future<Product?> adjustStock(int id, int adjustment) async {
    final entity = await _offlineController.adjustStock(id, adjustment);
    return entity != null ? Product.fromEntity(entity) : null;
  }

  // ==================== DELETE ====================

  /// Delete a product (soft delete)
  Future<void> deleteProduct(int id) async {
    await _offlineController.deleteProduct(id);
  }

  // ==================== SYNC STATUS ====================

  /// Get count of unsynced records
  Future<int> getUnsyncedCount() async {
    return await _offlineController.getUnsyncedCount();
  }

  /// Get total product count
  Future<int> getTotalCount() async {
    return await _offlineController.getTotalCount();
  }

  /// Get total stock value
  Future<double> getTotalStockValue() async {
    return await _offlineController.getTotalStockValue();
  }

  /// Check if product with barcode exists
  Future<bool> barcodeExists(String barcode, {int? excludeId}) async {
    final existing = await _offlineController.getProductByBarcode(barcode);
    if (existing == null) return false;
    if (excludeId != null && existing.id == excludeId) return false;
    return true;
  }
}

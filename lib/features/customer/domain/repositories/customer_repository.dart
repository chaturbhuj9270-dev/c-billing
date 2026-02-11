import '../../offline/entities/customer_entity.dart';
import '../../offline/controllers/customer_offline_controller.dart';

/// Customer model for domain layer
class Customer {
  final int? localId;
  final String? serverId;
  final String name;
  final String mobile;
  final String? address;
  final String? email;
  final double currentPendingAmount;
  final double totalPurchases;
  final bool isSynced;
  final bool isDeleted;
  final DateTime updatedAt;
  final DateTime createdAt;

  Customer({
    this.localId,
    this.serverId,
    required this.name,
    required this.mobile,
    this.address,
    this.email,
    this.currentPendingAmount = 0.0,
    this.totalPurchases = 0.0,
    this.isSynced = false,
    this.isDeleted = false,
    DateTime? updatedAt,
    DateTime? createdAt,
  })  : updatedAt = updatedAt ?? DateTime.now(),
        createdAt = createdAt ?? DateTime.now();

  /// Create from entity
  factory Customer.fromEntity(CustomerEntity entity) {
    return Customer(
      localId: entity.id,
      serverId: entity.serverId,
      name: entity.name,
      mobile: entity.mobile,
      address: entity.address,
      email: entity.email,
      currentPendingAmount: entity.currentPendingAmount,
      totalPurchases: entity.totalPurchases,
      isSynced: entity.isSynced,
      isDeleted: entity.isDeleted,
      updatedAt: entity.updatedAt,
      createdAt: entity.createdAt,
    );
  }

  /// Copy with modifications
  Customer copyWith({
    int? localId,
    String? serverId,
    String? name,
    String? mobile,
    String? address,
    String? email,
    double? currentPendingAmount,
    double? totalPurchases,
    bool? isSynced,
    bool? isDeleted,
    DateTime? updatedAt,
    DateTime? createdAt,
  }) {
    return Customer(
      localId: localId ?? this.localId,
      serverId: serverId ?? this.serverId,
      name: name ?? this.name,
      mobile: mobile ?? this.mobile,
      address: address ?? this.address,
      email: email ?? this.email,
      currentPendingAmount: currentPendingAmount ?? this.currentPendingAmount,
      totalPurchases: totalPurchases ?? this.totalPurchases,
      isSynced: isSynced ?? this.isSynced,
      isDeleted: isDeleted ?? this.isDeleted,
      updatedAt: updatedAt ?? this.updatedAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Get display ID (server ID if available, else local ID)
  String get displayId => serverId ?? 'local_$localId';
}

/// Repository for Customer data operations
/// Acts as the single source of truth for Customer data
/// Always reads from local Isar database (offline-first)
class CustomerRepository {
  static CustomerRepository? _instance;
  
  final CustomerOfflineController _offlineController;

  CustomerRepository._(this._offlineController);

  /// Get the singleton instance
  static CustomerRepository get instance {
    _instance ??= CustomerRepository._(CustomerOfflineController.instance);
    return _instance!;
  }

  // ==================== READ ====================

  /// Get all active customers
  Future<List<Customer>> getAllCustomers() async {
    final entities = await _offlineController.getAllCustomers();
    return entities.map((e) => Customer.fromEntity(e)).toList();
  }

  /// Watch all customers (reactive stream)
  Stream<List<Customer>> watchAllCustomers() {
    return _offlineController.watchAllCustomers().map(
      (entities) => entities.map((e) => Customer.fromEntity(e)).toList(),
    );
  }

  /// Get customer by local ID
  Future<Customer?> getCustomerById(int id) async {
    final entity = await _offlineController.getCustomerById(id);
    return entity != null ? Customer.fromEntity(entity) : null;
  }

  /// Get customer by mobile
  Future<Customer?> getCustomerByMobile(String mobile) async {
    final entity = await _offlineController.getCustomerByMobile(mobile);
    return entity != null ? Customer.fromEntity(entity) : null;
  }

  /// Search customers
  Future<List<Customer>> searchCustomers(String query) async {
    final entities = await _offlineController.searchCustomers(query);
    return entities.map((e) => Customer.fromEntity(e)).toList();
  }

  // ==================== CREATE ====================

  /// Create a new customer
  Future<Customer> createCustomer({
    required String name,
    required String mobile,
    String? address,
    String? email,
    double currentPendingAmount = 0.0,
    double totalPurchases = 0.0,
  }) async {
    final entity = await _offlineController.addCustomer(
      name: name,
      mobile: mobile,
      address: address,
      email: email,
      currentPendingAmount: currentPendingAmount,
      totalPurchases: totalPurchases,
    );
    return Customer.fromEntity(entity);
  }

  // ==================== UPDATE ====================

  /// Update an existing customer
  Future<Customer?> updateCustomer({
    required int id,
    String? name,
    String? mobile,
    String? address,
    String? email,
    double? currentPendingAmount,
    double? totalPurchases,
  }) async {
    final entity = await _offlineController.updateCustomer(
      id: id,
      name: name,
      mobile: mobile,
      address: address,
      email: email,
      currentPendingAmount: currentPendingAmount,
      totalPurchases: totalPurchases,
    );
    return entity != null ? Customer.fromEntity(entity) : null;
  }

  // ==================== DELETE ====================

  /// Delete a customer (soft delete)
  Future<void> deleteCustomer(int id) async {
    await _offlineController.deleteCustomer(id);
  }

  // ==================== SYNC STATUS ====================

  /// Get count of unsynced records
  Future<int> getUnsyncedCount() async {
    return await _offlineController.getUnsyncedCount();
  }

  /// Get total customer count
  Future<int> getTotalCount() async {
    return await _offlineController.getTotalCount();
  }

  /// Get total pending amount
  Future<double> getTotalPendingAmount() async {
    return await _offlineController.getTotalPendingAmount();
  }

  /// Check if customer with mobile exists
  Future<bool> mobileExists(String mobile, {int? excludeId}) async {
    final existing = await _offlineController.getCustomerByMobile(mobile);
    if (existing == null) return false;
    if (excludeId != null && existing.id == excludeId) return false;
    return true;
  }
}

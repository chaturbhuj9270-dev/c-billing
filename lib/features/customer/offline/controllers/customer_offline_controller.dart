import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart' show Timestamp;
import '../../../../core/database/app_database.dart';
import '../../../../core/database/local_store.dart';
import '../../../../core/services/local_database.dart';
import '../entities/customer_entity.dart';

/// Helper to parse DateTime from Firestore Timestamp or ISO8601 string
DateTime? _parseDateTime(dynamic value) {
  if (value == null) return null;
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  if (value is String) return DateTime.tryParse(value);
  return null;
}

/// Controller for handling offline-first Customer CRUD operations
/// All UI reads should go through this controller (never directly from API)
class CustomerOfflineController extends ChangeNotifier {
  static CustomerOfflineController? _instance;

  final AppDatabase _db;

  CustomerOfflineController._(this._db);

  /// Get the singleton instance
  static CustomerOfflineController get instance {
    _instance ??= CustomerOfflineController._(LocalDatabase.instance.db);
    return _instance!;
  }

  // ==================== CREATE ====================

  /// Add a new customer locally (will be synced later)
  Future<CustomerEntity> addCustomer({
    required String name,
    required String mobile,
    String? address,
    String? email,
    double currentPendingAmount = 0.0,
    double totalPurchases = 0.0,
  }) async {
    debugPrint('[CustomerOffline] Adding customer: $name, $mobile');
    final now = DateTime.now();
    final customer = CustomerEntity(
      name: name,
      mobile: mobile,
      address: address,
      email: email,
      currentPendingAmount: currentPendingAmount,
      totalPurchases: totalPurchases,
      isSynced: false, // Needs to be synced
      isDeleted: false,
      updatedAt: now,
      createdAt: now,
    );

    debugPrint('[CustomerOffline] Writing to local database...');
    await _db.saveCustomer(customer);
    debugPrint('[CustomerOffline] Customer saved with ID: ${customer.id}');

    notifyListeners();
    return customer;
  }

  // ==================== READ ====================

  /// Get all active (non-deleted) customers
  Future<List<CustomerEntity>> getAllCustomers() async {
    final customers = (await _db.loadCustomers())
        .where((customer) => customer.isDeleted == false)
        .toList();
    customers.sort((a, b) => b.name.compareTo(a.name));
    return customers;
  }

  /// Watch all active customers (reactive stream for UI)
  Stream<List<CustomerEntity>> watchAllCustomers() {
    return _db.watchCustomers().map((rows) {
      final customers = rows
          .where((customer) => customer.isDeleted == false)
          .toList();
      customers.sort((a, b) => b.name.compareTo(a.name));
      return customers;
    });
  }

  /// Get customer by local id
  Future<CustomerEntity?> getCustomerById(int id) async {
    for (final customer in await _db.loadCustomers()) {
      if (customer.id == id) return customer;
    }
    return null;
  }

  /// Get customer by server ID
  Future<CustomerEntity?> getCustomerByServerId(String serverId) async {
    for (final customer in await _db.loadCustomers()) {
      if (customer.serverId == serverId) return customer;
    }
    return null;
  }

  /// Get customer by mobile number
  Future<CustomerEntity?> getCustomerByMobile(String mobile) async {
    final needle = mobile.toLowerCase();
    for (final customer in await _db.loadCustomers()) {
      if (customer.mobile.toLowerCase() == needle) return customer;
    }
    return null;
  }

  /// Search customers by name or mobile
  Future<List<CustomerEntity>> searchCustomers(String query) async {
    if (query.isEmpty) return getAllCustomers();

    final lowerQuery = query.toLowerCase();
    return (await _db.loadCustomers()).where((customer) {
      if (customer.isDeleted) return false;
      return customer.name.toLowerCase().contains(lowerQuery) ||
          customer.mobile.contains(lowerQuery);
    }).toList();
  }

  /// Get all customers pending sync
  Future<List<CustomerEntity>> getUnsyncedCustomers() async {
    return (await _db.loadCustomers())
        .where((customer) => customer.isSynced == false)
        .toList();
  }

  /// Get count of unsynced records
  Future<int> getUnsyncedCount() async {
    return (await _db.loadCustomers())
        .where((customer) => customer.isSynced == false)
        .length;
  }

  /// Get customers marked for deletion (need to delete on server)
  Future<List<CustomerEntity>> getDeletedCustomers() async {
    return (await _db.loadCustomers())
        .where(
          (customer) => customer.isDeleted == true && customer.isSynced == false,
        )
        .toList();
  }

  // ==================== UPDATE ====================

  /// Update an existing customer
  Future<CustomerEntity?> updateCustomer({
    required int id,
    String? name,
    String? mobile,
    String? address,
    String? email,
    double? currentPendingAmount,
    double? totalPurchases,
  }) async {
    final existing = await getCustomerById(id);
    if (existing == null) return null;

    final updated = existing.copyWith(
      name: name,
      mobile: mobile,
      address: address,
      email: email,
      currentPendingAmount: currentPendingAmount,
      totalPurchases: totalPurchases,
      isSynced: false, // Mark as needing sync
      updatedAt: DateTime.now(),
    );

    await _db.saveCustomer(updated);

    notifyListeners();
    return updated;
  }

  /// Mark customer as synced (called after successful server sync)
  Future<void> markAsSynced(int id, {String? serverId}) async {
    final existing = await getCustomerById(id);
    if (existing == null) return;

    final updated = existing.copyWith(
      serverId: serverId ?? existing.serverId,
      isSynced: true,
    );

    await _db.saveCustomer(updated);
  }

  /// Bulk mark as synced
  Future<void> markAllAsSynced(List<int> ids) async {
    await _db.transaction(() async {
      for (final id in ids) {
        final existing = await getCustomerById(id);
        if (existing != null) {
          final updated = existing.copyWith(isSynced: true);
          await _db.saveCustomer(updated);
        }
      }
    });
    notifyListeners();
  }

  // ==================== DELETE ====================

  /// Soft delete a customer (marks for deletion, will be synced)
  Future<void> deleteCustomer(int id) async {
    final existing = await getCustomerById(id);
    if (existing == null) return;

    // If never synced to server, we can hard delete
    if (existing.serverId == null) {
      await _db.deleteCustomerById(id);
    } else {
      // Soft delete - mark for server sync
      final updated = existing.copyWith(
        isDeleted: true,
        isSynced: false,
        updatedAt: DateTime.now(),
      );

      await _db.saveCustomer(updated);
    }

    notifyListeners();
  }

  /// Hard delete after confirmed server deletion
  Future<void> permanentlyDelete(int id) async {
    await _db.deleteCustomerById(id);
    notifyListeners();
  }

  /// Clear all deleted records that have been synced
  Future<int> clearSyncedDeletedRecords() async {
    final deleted = (await _db.loadCustomers())
        .where(
          (customer) => customer.isDeleted == true && customer.isSynced == true,
        )
        .toList();

    if (deleted.isEmpty) return 0;

    await _db.transaction(() async {
      for (final entity in deleted) {
        await _db.deleteCustomerById(entity.id);
      }
    });

    notifyListeners();
    return deleted.length;
  }

  // ==================== SYNC HELPERS ====================

  /// Import customers from server (for initial sync or refresh)
  Future<void> importFromServer(
    List<Map<String, dynamic>> serverCustomers,
  ) async {
    await _db.transaction(() async {
      for (final customerData in serverCustomers) {
        final serverId = customerData['id'] as String?;
        if (serverId == null) continue;

        final all = await _db.loadCustomers();
        CustomerEntity? existing;
        for (final customer in all) {
          if (customer.serverId == serverId) {
            existing = customer;
            break;
          }
        }

        // Fallback: check by mobile number (handles locally-created records without serverId yet)
        if (existing == null) {
          final mobile =
              (customerData['mobile'] ?? customerData['contact'] ?? '')
                  .toString();
          if (mobile.isNotEmpty) {
            for (final customer in all) {
              if (customer.mobile == mobile) {
                existing = customer;
                break;
              }
            }
            // If found by mobile, update its serverId
            if (existing != null && existing.serverId == null) {
              existing.serverId = serverId;
              existing.isSynced = true;
              await _db.saveCustomer(existing);
              continue; // Already linked, skip further update
            }
          }
        }

        if (existing != null) {
          // Update existing if server version is newer and local is synced
          if (existing.isSynced) {
            final serverUpdatedAt = _parseDateTime(customerData['updatedAt']);
            if (serverUpdatedAt != null &&
                serverUpdatedAt.isAfter(existing.updatedAt)) {
              final updated = CustomerEntity.fromCustomer(customerData);
              updated.id = existing.id; // Keep local ID
              await _db.saveCustomer(updated);
            }
          }
          // If not synced, local changes take precedence
        } else {
          // Create new
          final newCustomer = CustomerEntity.fromCustomer(customerData);
          await _db.saveCustomer(newCustomer);
        }
      }
    });

    notifyListeners();
  }

  /// Get customers that need to be pushed to server
  Future<List<CustomerEntity>> getCustomersNeedingPush() async {
    return (await _db.loadCustomers())
        .where((customer) => customer.isSynced == false)
        .toList();
  }

  /// Update customer with server response (after successful create/update)
  Future<void> updateWithServerResponse(
    int localId,
    Map<String, dynamic> serverResponse,
  ) async {
    final existing = await getCustomerById(localId);
    if (existing == null) return;

    final updated = existing.copyWith(
      serverId: serverResponse['id'] as String?,
      isSynced: true,
    );

    await _db.saveCustomer(updated);
  }

  // ==================== STATISTICS ====================

  /// Get total customer count
  Future<int> getTotalCount() async {
    return (await _db.loadCustomers())
        .where((customer) => customer.isDeleted == false)
        .length;
  }

  /// Get total pending amount across all customers
  Future<double> getTotalPendingAmount() async {
    final customers = await getAllCustomers();
    return customers.fold<double>(
      0,
      (total, c) => total + c.currentPendingAmount,
    );
  }

  /// Get customers with pending balance (for dashboard)
  Future<List<CustomerEntity>> getCustomersWithPendingBalance() async {
    final customers = (await _db.loadCustomers())
        .where(
          (customer) =>
              customer.isDeleted == false && customer.currentPendingAmount > 0,
        )
        .toList();
    customers.sort(
      (a, b) => b.currentPendingAmount.compareTo(a.currentPendingAmount),
    );
    return customers;
  }
}

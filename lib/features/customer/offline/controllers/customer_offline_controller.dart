import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:isar_community/isar.dart';
import '../../../../core/services/isar_service.dart';
import '../entities/customer_entity.dart';

/// Controller for handling offline-first Customer CRUD operations
/// All UI reads should go through this controller (never directly from API)
class CustomerOfflineController extends ChangeNotifier {
  static CustomerOfflineController? _instance;
  
  Isar get _isar => IsarService.instance.isar;

  CustomerOfflineController._();

  /// Get the singleton instance
  static CustomerOfflineController get instance {
    _instance ??= CustomerOfflineController._();
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

    debugPrint('[CustomerOffline] Writing to Isar...');
    await _isar.writeTxn(() async {
      await _isar.customerEntitys.put(customer);
    });
    debugPrint('[CustomerOffline] Customer saved with ID: ${customer.id}');

    notifyListeners();
    return customer;
  }

  // ==================== READ ====================

  /// Get all active (non-deleted) customers
  Future<List<CustomerEntity>> getAllCustomers() async {
    return await _isar.customerEntitys
        .filter()
        .isDeletedEqualTo(false)
        .sortByNameDesc()
        .findAll();
  }

  /// Watch all active customers (reactive stream for UI)
  Stream<List<CustomerEntity>> watchAllCustomers() {
    return _isar.customerEntitys
        .filter()
        .isDeletedEqualTo(false)
        .sortByNameDesc()
        .watch(fireImmediately: true);
  }

  /// Get customer by local Isar ID
  Future<CustomerEntity?> getCustomerById(Id id) async {
    return await _isar.customerEntitys.get(id);
  }

  /// Get customer by server ID
  Future<CustomerEntity?> getCustomerByServerId(String serverId) async {
    return await _isar.customerEntitys
        .filter()
        .serverIdEqualTo(serverId)
        .findFirst();
  }

  /// Get customer by mobile number
  Future<CustomerEntity?> getCustomerByMobile(String mobile) async {
    return await _isar.customerEntitys
        .filter()
        .mobileEqualTo(mobile, caseSensitive: false)
        .findFirst();
  }

  /// Search customers by name or mobile
  Future<List<CustomerEntity>> searchCustomers(String query) async {
    if (query.isEmpty) return getAllCustomers();
    
    final lowerQuery = query.toLowerCase();
    return await _isar.customerEntitys
        .filter()
        .isDeletedEqualTo(false)
        .group((q) => q
            .nameContains(lowerQuery, caseSensitive: false)
            .or()
            .mobileContains(lowerQuery))
        .findAll();
  }

  /// Get all customers pending sync
  Future<List<CustomerEntity>> getUnsyncedCustomers() async {
    return await _isar.customerEntitys
        .filter()
        .isSyncedEqualTo(false)
        .findAll();
  }

  /// Get count of unsynced records
  Future<int> getUnsyncedCount() async {
    return await _isar.customerEntitys
        .filter()
        .isSyncedEqualTo(false)
        .count();
  }

  /// Get customers marked for deletion (need to delete on server)
  Future<List<CustomerEntity>> getDeletedCustomers() async {
    return await _isar.customerEntitys
        .filter()
        .isDeletedEqualTo(true)
        .isSyncedEqualTo(false)
        .findAll();
  }

  // ==================== UPDATE ====================

  /// Update an existing customer
  Future<CustomerEntity?> updateCustomer({
    required Id id,
    String? name,
    String? mobile,
    String? address,
    String? email,
    double? currentPendingAmount,
    double? totalPurchases,
  }) async {
    final existing = await _isar.customerEntitys.get(id);
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

    await _isar.writeTxn(() async {
      await _isar.customerEntitys.put(updated);
    });

    notifyListeners();
    return updated;
  }

  /// Mark customer as synced (called after successful server sync)
  Future<void> markAsSynced(Id id, {String? serverId}) async {
    final existing = await _isar.customerEntitys.get(id);
    if (existing == null) return;

    final updated = existing.copyWith(
      serverId: serverId ?? existing.serverId,
      isSynced: true,
    );

    await _isar.writeTxn(() async {
      await _isar.customerEntitys.put(updated);
    });
  }

  /// Bulk mark as synced
  Future<void> markAllAsSynced(List<Id> ids) async {
    await _isar.writeTxn(() async {
      for (final id in ids) {
        final existing = await _isar.customerEntitys.get(id);
        if (existing != null) {
          final updated = existing.copyWith(isSynced: true);
          await _isar.customerEntitys.put(updated);
        }
      }
    });
    notifyListeners();
  }

  // ==================== DELETE ====================

  /// Soft delete a customer (marks for deletion, will be synced)
  Future<void> deleteCustomer(Id id) async {
    final existing = await _isar.customerEntitys.get(id);
    if (existing == null) return;

    // If never synced to server, we can hard delete
    if (existing.serverId == null) {
      await _isar.writeTxn(() async {
        await _isar.customerEntitys.delete(id);
      });
    } else {
      // Soft delete - mark for server sync
      final updated = existing.copyWith(
        isDeleted: true,
        isSynced: false,
        updatedAt: DateTime.now(),
      );

      await _isar.writeTxn(() async {
        await _isar.customerEntitys.put(updated);
      });
    }

    notifyListeners();
  }

  /// Hard delete after confirmed server deletion
  Future<void> permanentlyDelete(Id id) async {
    await _isar.writeTxn(() async {
      await _isar.customerEntitys.delete(id);
    });
    notifyListeners();
  }

  /// Clear all deleted records that have been synced
  Future<int> clearSyncedDeletedRecords() async {
    final deleted = await _isar.customerEntitys
        .filter()
        .isDeletedEqualTo(true)
        .isSyncedEqualTo(true)
        .findAll();

    if (deleted.isEmpty) return 0;

    await _isar.writeTxn(() async {
      for (final entity in deleted) {
        await _isar.customerEntitys.delete(entity.id);
      }
    });

    notifyListeners();
    return deleted.length;
  }

  // ==================== SYNC HELPERS ====================

  /// Import customers from server (for initial sync or refresh)
  Future<void> importFromServer(List<Map<String, dynamic>> serverCustomers) async {
    await _isar.writeTxn(() async {
      for (final customerData in serverCustomers) {
        final serverId = customerData['id'] as String?;
        if (serverId == null) continue;

        // Check if exists locally
        final existing = await _isar.customerEntitys
            .filter()
            .serverIdEqualTo(serverId)
            .findFirst();

        if (existing != null) {
          // Update existing if server version is newer
          final serverUpdatedAt = DateTime.tryParse(customerData['updatedAt']?.toString() ?? '');
          if (serverUpdatedAt != null && serverUpdatedAt.isAfter(existing.updatedAt)) {
            final updated = CustomerEntity.fromCustomer(customerData);
            updated.id = existing.id; // Keep local ID
            await _isar.customerEntitys.put(updated);
          }
        } else {
          // Create new
          final newCustomer = CustomerEntity.fromCustomer(customerData);
          await _isar.customerEntitys.put(newCustomer);
        }
      }
    });

    notifyListeners();
  }

  /// Get customers that need to be pushed to server
  Future<List<CustomerEntity>> getCustomersNeedingPush() async {
    return await _isar.customerEntitys
        .filter()
        .isSyncedEqualTo(false)
        .findAll();
  }

  /// Update customer with server response (after successful create/update)
  Future<void> updateWithServerResponse(Id localId, Map<String, dynamic> serverResponse) async {
    final existing = await _isar.customerEntitys.get(localId);
    if (existing == null) return;

    final updated = existing.copyWith(
      serverId: serverResponse['id'] as String?,
      isSynced: true,
    );

    await _isar.writeTxn(() async {
      await _isar.customerEntitys.put(updated);
    });
  }

  // ==================== STATISTICS ====================

  /// Get total customer count
  Future<int> getTotalCount() async {
    return await _isar.customerEntitys
        .filter()
        .isDeletedEqualTo(false)
        .count();
  }

  /// Get total pending amount across all customers
  Future<double> getTotalPendingAmount() async {
    final customers = await getAllCustomers();
    return customers.fold<double>(0, (sum, c) => sum + c.currentPendingAmount);
  }
}

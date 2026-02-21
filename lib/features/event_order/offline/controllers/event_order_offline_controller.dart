import 'package:flutter/foundation.dart';
import 'package:isar_community/isar.dart';
import '../../../../core/services/isar_service.dart';
import '../entities/event_order_entity.dart';
import '../../domain/entities/event_order.dart';
import '../../domain/entities/sub_event.dart';
import '../../domain/entities/order_item.dart';

/// Offline-first controller for Event/Sales Order CRUD operations
/// All operations go to local Isar first, then sync in background
class EventOrderOfflineController extends ChangeNotifier {
  static EventOrderOfflineController? _instance;
  
  final Isar _isar;

  EventOrderOfflineController._(this._isar);

  /// Get the singleton instance
  static EventOrderOfflineController get instance {
    if (_instance == null) {
      final isar = IsarService.instance.isar;
      _instance = EventOrderOfflineController._(isar);
    }
    return _instance!;
  }

  /// Reset instance (for testing)
  @visibleForTesting
  static void resetInstance() {
    _instance = null;
  }

  // ==================== CREATE ====================

  /// Add a new event order locally
  /// Sets syncStatus to NEW for background sync
  Future<EventOrderEntity> addEventOrder({
    required OrderType orderType,
    String? customerId,
    required String customerName,
    String customerContact = '',
    required String orderName,
    String? description,
    required DateTime eventDate,
    List<SubEvent> subEvents = const [],
    List<OrderItem> items = const [],
    double advanceAmount = 0.0,
    String? notes,
  }) async {
    // Calculate total based on type
    double totalAmount = 0.0;
    if (orderType == OrderType.event) {
      totalAmount = subEvents.fold(0.0, (sum, e) => sum + e.charges);
    } else {
      totalAmount = items.fold(0.0, (sum, e) => sum + e.total);
    }
    
    final remainingAmount = totalAmount - advanceAmount;
    final now = DateTime.now();

    final entity = EventOrderEntity.create(
      orderType: orderType.index,
      customerId: customerId,
      customerName: customerName,
      customerContact: customerContact,
      orderName: orderName,
      description: description,
      eventDate: eventDate,
      subEvents: subEvents.map((e) => SubEventEmbedded.fromDomain(e)).toList(),
      items: items.map((e) => OrderItemEmbedded.fromDomain(e)).toList(),
      totalAmount: totalAmount,
      advanceAmount: advanceAmount,
      remainingAmount: remainingAmount,
      notes: notes,
      status: OrderStatus.pending.index,
      createdAt: now,
      updatedAt: now,
      syncStatus: EventOrderSyncStatus.newRecord,
    );

    await _isar.writeTxn(() async {
      await _isar.eventOrderEntitys.put(entity);
    });

    debugPrint('[EventOrderOffline] Order added: ${entity.id}, type: ${orderType.name}, status: NEW');
    notifyListeners();
    return entity;
  }

  // ==================== READ ====================

  /// Get all event orders (excluding deleted)
  Future<List<EventOrderEntity>> getAllEventOrders() async {
    return await _isar.eventOrderEntitys
        .filter()
        .not()
        .syncStatusEqualTo(EventOrderSyncStatus.deleted)
        .sortByEventDateDesc()
        .findAll();
  }

  /// Watch all event orders for real-time updates
  Stream<List<EventOrderEntity>> watchAllEventOrders() {
    return _isar.eventOrderEntitys
        .filter()
        .not()
        .syncStatusEqualTo(EventOrderSyncStatus.deleted)
        .sortByEventDateDesc()
        .watch(fireImmediately: true);
  }

  /// Get event order by local Isar ID
  Future<EventOrderEntity?> getEventOrderById(Id id) async {
    return await _isar.eventOrderEntitys.get(id);
  }

  /// Get event order by server ID
  Future<EventOrderEntity?> getEventOrderByServerId(String serverId) async {
    return await _isar.eventOrderEntitys
        .filter()
        .serverIdEqualTo(serverId)
        .findFirst();
  }

  /// Get event orders by type
  Future<List<EventOrderEntity>> getEventOrdersByType(OrderType type) async {
    return await _isar.eventOrderEntitys
        .filter()
        .orderTypeEqualTo(type.index)
        .not()
        .syncStatusEqualTo(EventOrderSyncStatus.deleted)
        .sortByEventDateDesc()
        .findAll();
  }

  /// Get event orders by customer ID
  Future<List<EventOrderEntity>> getEventOrdersByCustomerId(String customerId) async {
    return await _isar.eventOrderEntitys
        .filter()
        .customerIdEqualTo(customerId)
        .not()
        .syncStatusEqualTo(EventOrderSyncStatus.deleted)
        .sortByEventDateDesc()
        .findAll();
  }

  /// Get event orders by status
  Future<List<EventOrderEntity>> getEventOrdersByStatus(OrderStatus status) async {
    return await _isar.eventOrderEntitys
        .filter()
        .statusEqualTo(status.index)
        .not()
        .syncStatusEqualTo(EventOrderSyncStatus.deleted)
        .sortByEventDateDesc()
        .findAll();
  }

  /// Get event orders by date range
  Future<List<EventOrderEntity>> getEventOrdersByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    return await _isar.eventOrderEntitys
        .filter()
        .eventDateBetween(startDate, endDate)
        .not()
        .syncStatusEqualTo(EventOrderSyncStatus.deleted)
        .sortByEventDateDesc()
        .findAll();
  }

  /// Get pending event orders (not delivered, cancelled, or converted)
  Future<List<EventOrderEntity>> getPendingEventOrders() async {
    return await _isar.eventOrderEntitys
        .filter()
        .statusLessThan(OrderStatus.delivered.index)
        .not()
        .syncStatusEqualTo(EventOrderSyncStatus.deleted)
        .sortByEventDate()
        .findAll();
  }

  /// Get today's event orders
  Future<List<EventOrderEntity>> getTodaysEventOrders() async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    
    return await _isar.eventOrderEntitys
        .filter()
        .eventDateBetween(startOfDay, endOfDay)
        .not()
        .syncStatusEqualTo(EventOrderSyncStatus.deleted)
        .sortByEventDate()
        .findAll();
  }

  /// Get upcoming events (event date in future)
  Future<List<EventOrderEntity>> getUpcomingEvents() async {
    final now = DateTime.now();
    
    return await _isar.eventOrderEntitys
        .filter()
        .eventDateGreaterThan(now)
        .orderTypeEqualTo(OrderType.event.index)
        .not()
        .syncStatusEqualTo(EventOrderSyncStatus.deleted)
        .sortByEventDate()
        .findAll();
  }

  /// Search event orders by name or customer
  Future<List<EventOrderEntity>> searchEventOrders(String query) async {
    if (query.isEmpty) return getAllEventOrders();
    
    return await _isar.eventOrderEntitys
        .filter()
        .not()
        .syncStatusEqualTo(EventOrderSyncStatus.deleted)
        .group((q) => q
            .orderNameContains(query, caseSensitive: false)
            .or()
            .customerNameContains(query, caseSensitive: false)
            .or()
            .customerContactContains(query))
        .sortByEventDateDesc()
        .findAll();
  }

  // ==================== UPDATE ====================

  /// Update an existing event order
  Future<EventOrderEntity?> updateEventOrder({
    required Id id,
    OrderType? orderType,
    String? customerId,
    String? customerName,
    String? customerContact,
    String? orderName,
    String? description,
    DateTime? eventDate,
    List<SubEvent>? subEvents,
    List<OrderItem>? items,
    double? advanceAmount,
    String? notes,
    OrderStatus? status,
    String? convertedBillId,
  }) async {
    final existing = await _isar.eventOrderEntitys.get(id);
    if (existing == null) {
      debugPrint('[EventOrderOffline] Order not found: $id');
      return null;
    }

    // Apply updates
    if (orderType != null) existing.orderType = orderType.index;
    if (customerId != null) existing.customerId = customerId;
    if (customerName != null) existing.customerName = customerName;
    if (customerContact != null) existing.customerContact = customerContact;
    if (orderName != null) existing.orderName = orderName;
    if (description != null) existing.description = description;
    if (eventDate != null) existing.eventDate = eventDate;
    if (subEvents != null) {
      existing.subEvents = subEvents.map((e) => SubEventEmbedded.fromDomain(e)).toList();
    }
    if (items != null) {
      existing.items = items.map((e) => OrderItemEmbedded.fromDomain(e)).toList();
    }
    if (advanceAmount != null) existing.advanceAmount = advanceAmount;
    if (notes != null) existing.notes = notes;
    if (status != null) existing.status = status.index;
    if (convertedBillId != null) existing.convertedBillId = convertedBillId;

    // Recalculate totals
    if (existing.orderType == OrderType.event.index) {
      existing.totalAmount = existing.subEvents.fold(0.0, (sum, e) => sum + e.charges);
    } else {
      existing.totalAmount = existing.items.fold(0.0, (sum, e) => sum + e.total);
    }
    existing.remainingAmount = existing.totalAmount - existing.advanceAmount;
    existing.updatedAt = DateTime.now();

    // Update sync status
    if (existing.syncStatus == EventOrderSyncStatus.synced) {
      existing.syncStatus = EventOrderSyncStatus.updated;
    }

    await _isar.writeTxn(() async {
      await _isar.eventOrderEntitys.put(existing);
    });

    debugPrint('[EventOrderOffline] Order updated: $id, syncStatus: ${existing.syncStatus.name}');
    notifyListeners();
    return existing;
  }

  // ==================== DELETE ====================

  /// Soft delete an event order (mark as deleted for sync)
  Future<bool> deleteEventOrder(Id id) async {
    final existing = await _isar.eventOrderEntitys.get(id);
    if (existing == null) {
      debugPrint('[EventOrderOffline] Order not found: $id');
      return false;
    }

    // If it's a new record, just delete it permanently (never synced)
    if (existing.syncStatus == EventOrderSyncStatus.newRecord) {
      await _isar.writeTxn(() async {
        await _isar.eventOrderEntitys.delete(id);
      });
      debugPrint('[EventOrderOffline] New order permanently deleted: $id');
    } else {
      // Mark as deleted for sync
      existing.syncStatus = EventOrderSyncStatus.deleted;
      existing.updatedAt = DateTime.now();
      await _isar.writeTxn(() async {
        await _isar.eventOrderEntitys.put(existing);
      });
      debugPrint('[EventOrderOffline] Order marked deleted: $id');
    }

    notifyListeners();
    return true;
  }

  // ==================== STATISTICS ====================

  /// Get total advance amount collected
  Future<double> getTotalAdvanceAmount({DateTime? startDate, DateTime? endDate}) async {
    var query = _isar.eventOrderEntitys
        .filter()
        .not()
        .syncStatusEqualTo(EventOrderSyncStatus.deleted);
    
    if (startDate != null && endDate != null) {
      query = query.eventDateBetween(startDate, endDate);
    }
    
    final orders = await query.findAll();
    double total = 0.0;
    for (final order in orders) {
      total += order.advanceAmount;
    }
    return total;
  }

  /// Get total pending amount (remaining)
  Future<double> getTotalPendingAmount() async {
    final orders = await _isar.eventOrderEntitys
        .filter()
        .statusLessThan(OrderStatus.delivered.index)
        .not()
        .syncStatusEqualTo(EventOrderSyncStatus.deleted)
        .findAll();
    
    double total = 0.0;
    for (final order in orders) {
      total += order.remainingAmount;
    }
    return total;
  }

  /// Get order counts by status
  Future<Map<OrderStatus, int>> getOrderCountByStatus() async {
    final result = <OrderStatus, int>{};
    
    for (final status in OrderStatus.values) {
      final count = await _isar.eventOrderEntitys
          .filter()
          .statusEqualTo(status.index)
          .not()
          .syncStatusEqualTo(EventOrderSyncStatus.deleted)
          .count();
      result[status] = count;
    }
    
    return result;
  }

  /// Get total event order count
  Future<int> getTotalCount() async {
    return await _isar.eventOrderEntitys
        .filter()
        .not()
        .syncStatusEqualTo(EventOrderSyncStatus.deleted)
        .count();
  }

  // ==================== SYNC HELPERS ====================

  /// Get all records that need to be synced to server
  Future<List<EventOrderEntity>> getRecordsToSync() async {
    return await _isar.eventOrderEntitys
        .filter()
        .not()
        .syncStatusEqualTo(EventOrderSyncStatus.synced)
        .findAll();
  }

  /// Mark a record as synced (call after successful server sync)
  Future<void> markAsSynced(Id id, String serverId) async {
    final existing = await _isar.eventOrderEntitys.get(id);
    if (existing == null) return;

    existing.serverId = serverId;
    existing.syncStatus = EventOrderSyncStatus.synced;
    
    await _isar.writeTxn(() async {
      await _isar.eventOrderEntitys.put(existing);
    });
    
    debugPrint('[EventOrderOffline] Marked synced: $id -> $serverId');
  }

  /// Permanently delete all records marked as deleted (call after sync)
  Future<int> purgeDeletedRecords() async {
    final toDelete = await _isar.eventOrderEntitys
        .filter()
        .syncStatusEqualTo(EventOrderSyncStatus.deleted)
        .findAll();
    
    if (toDelete.isEmpty) return 0;

    await _isar.writeTxn(() async {
      await _isar.eventOrderEntitys.deleteAll(toDelete.map((e) => e.id).toList());
    });

    debugPrint('[EventOrderOffline] Purged ${toDelete.length} deleted records');
    return toDelete.length;
  }
}

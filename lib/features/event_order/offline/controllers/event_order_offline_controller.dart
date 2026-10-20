import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart' show Timestamp;
import '../../../../core/database/app_database.dart';
import '../../../../core/database/local_store.dart';
import '../../../../core/services/local_database.dart';
import '../entities/event_order_entity.dart';
import '../../domain/entities/event_order.dart';
import '../../domain/entities/sub_event.dart';
import '../../domain/entities/order_item.dart';

// Helper to parse DateTime from Firestore Timestamp or ISO8601 string
DateTime? _parseDateTime(dynamic value) {
  if (value == null) return null;
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  if (value is String) return DateTime.tryParse(value);
  return null;
}

// Offline-first controller for Event/Sales Order CRUD operations. All operations go to the local database first, then sync in the background.
class EventOrderOfflineController extends ChangeNotifier {
  static EventOrderOfflineController? _instance;

  final AppDatabase _db;

  EventOrderOfflineController._(this._db);

  // Get the singleton instance
  static EventOrderOfflineController get instance {
    _instance ??= EventOrderOfflineController._(LocalDatabase.instance.db);
    return _instance!;
  }

  // Reset instance (for testing)
  @visibleForTesting
  static void resetInstance() {
    _instance = null;
  }

  // ==================== CREATE ====================

  // Add a new event order locally Sets syncStatus to NEW for background sync
  Future<EventOrderEntity> addEventOrder({
    required OrderType orderType,
    String? customerId,
    required String customerName,
    String customerContact = '',
    String? customerAddress,
    required String orderName,
    String? description,
    required DateTime eventDate,
    String? eventLocation,
    List<SubEvent> subEvents = const [],
    List<OrderItem> items = const [],
    double eventCharges = 0.0,
    double advanceAmount = 0.0,
    String? notes,
    Map<String, dynamic>? customData,
  }) async {
    // Calculate total based on type
    double totalAmount = 0.0;
    if (orderType == OrderType.event) {
      totalAmount =
          subEvents.fold(0.0, (total, e) => total + e.charges) +
          eventCharges +
          items.fold(0.0, (total, e) => total + e.total);
    } else {
      totalAmount = items.fold(0.0, (total, e) => total + e.total);
    }

    final remainingAmount = totalAmount - advanceAmount;
    final now = DateTime.now();

    final entity = EventOrderEntity.create(
      orderType: orderType.index,
      customerId: customerId,
      customerName: customerName,
      customerContact: customerContact,
      customerAddress: customerAddress,
      orderName: orderName,
      description: description,
      eventDate: eventDate,
      eventLocation: eventLocation,
      subEvents: subEvents.map((e) => SubEventEmbedded.fromDomain(e)).toList(),
      items: items.map((e) => OrderItemEmbedded.fromDomain(e)).toList(),
      eventCharges: eventCharges,
      totalAmount: totalAmount,
      advanceAmount: advanceAmount,
      remainingAmount: remainingAmount,
      notes: notes,
      status: OrderStatus.pending.index,
      customDataJson: customData != null && customData.isNotEmpty
          ? jsonEncode(customData)
          : null,
      createdAt: now,
      updatedAt: now,
      syncStatus: EventOrderSyncStatus.newRecord,
    );

    await _db.saveEventOrder(entity);

    debugPrint(
      '[EventOrderOffline] Order added: ${entity.id}, type: ${orderType.name}, status: NEW',
    );
    notifyListeners();
    return entity;
  }

  // ==================== READ ====================

  // Get all event orders (excluding deleted)
  Future<List<EventOrderEntity>> getAllEventOrders() async {
    final orders = (await _db.loadEventOrders())
        .where((order) => order.syncStatus != EventOrderSyncStatus.deleted)
        .toList();
    orders.sort((a, b) => b.eventDate.compareTo(a.eventDate));
    return orders;
  }

  // Watch all event orders for real-time updates
  Stream<List<EventOrderEntity>> watchAllEventOrders() {
    return _db.watchEventOrders().map((rows) {
      final orders = rows
          .where((order) => order.syncStatus != EventOrderSyncStatus.deleted)
          .toList();
      orders.sort((a, b) => b.eventDate.compareTo(a.eventDate));
      return orders;
    });
  }

  // Get event order by local id
  Future<EventOrderEntity?> getEventOrderById(int id) async {
    for (final order in await _db.loadEventOrders()) {
      if (order.id == id) return order;
    }
    return null;
  }

  // Get event order by server ID
  Future<EventOrderEntity?> getEventOrderByServerId(String serverId) async {
    for (final order in await _db.loadEventOrders()) {
      if (order.serverId == serverId) return order;
    }
    return null;
  }

  // Get event orders by type
  Future<List<EventOrderEntity>> getEventOrdersByType(OrderType type) async {
    final orders = (await _db.loadEventOrders()).where((order) {
      return order.orderType == type.index &&
          order.syncStatus != EventOrderSyncStatus.deleted;
    }).toList();
    orders.sort((a, b) => b.eventDate.compareTo(a.eventDate));
    return orders;
  }

  // Get event orders by customer ID
  Future<List<EventOrderEntity>> getEventOrdersByCustomerId(
    String customerId,
  ) async {
    final orders = (await _db.loadEventOrders()).where((order) {
      return order.customerId == customerId &&
          order.syncStatus != EventOrderSyncStatus.deleted;
    }).toList();
    orders.sort((a, b) => b.eventDate.compareTo(a.eventDate));
    return orders;
  }

  // Get event orders by status
  Future<List<EventOrderEntity>> getEventOrdersByStatus(
    OrderStatus status,
  ) async {
    final orders = (await _db.loadEventOrders()).where((order) {
      return order.status == status.index &&
          order.syncStatus != EventOrderSyncStatus.deleted;
    }).toList();
    orders.sort((a, b) => b.eventDate.compareTo(a.eventDate));
    return orders;
  }

  // Get event orders by date range
  Future<List<EventOrderEntity>> getEventOrdersByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final orders = (await _db.loadEventOrders()).where((order) {
      if (order.syncStatus == EventOrderSyncStatus.deleted) return false;
      return !order.eventDate.isBefore(startDate) &&
          !order.eventDate.isAfter(endDate);
    }).toList();
    orders.sort((a, b) => b.eventDate.compareTo(a.eventDate));
    return orders;
  }

  // Get pending event orders (not delivered, cancelled, or converted)
  Future<List<EventOrderEntity>> getPendingEventOrders() async {
    final orders = (await _db.loadEventOrders()).where((order) {
      return order.status < OrderStatus.delivered.index &&
          order.syncStatus != EventOrderSyncStatus.deleted;
    }).toList();
    orders.sort((a, b) => a.eventDate.compareTo(b.eventDate));
    return orders;
  }

  // Get today's event orders
  Future<List<EventOrderEntity>> getTodaysEventOrders() async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final orders = (await _db.loadEventOrders()).where((order) {
      if (order.syncStatus == EventOrderSyncStatus.deleted) return false;
      return !order.eventDate.isBefore(startOfDay) &&
          !order.eventDate.isAfter(endOfDay);
    }).toList();
    orders.sort((a, b) => a.eventDate.compareTo(b.eventDate));
    return orders;
  }

  // Get upcoming events (event date today or in future)
  Future<List<EventOrderEntity>> getUpcomingEvents() async {
    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);

    final allEvents = (await _db.loadEventOrders())
        .where((order) => order.syncStatus != EventOrderSyncStatus.deleted)
        .toList();

    debugPrint('[EventOrderController] Total events in DB: ${allEvents.length}');
    debugPrint('[EventOrderController] Today: $startOfToday');
    for (var e in allEvents) {
      final eventDateOnly = DateTime(
        e.eventDate.year,
        e.eventDate.month,
        e.eventDate.day,
      );
      debugPrint(
        '[EventOrderController] Event: ${e.orderName}, date: ${e.eventDate}, dateOnly: $eventDateOnly, isUpcoming: ${!eventDateOnly.isBefore(startOfToday)}',
      );
    }

    // Filter for events with date >= today (compare date parts only)
    final upcomingEvents = allEvents.where((e) {
      final eventDateOnly = DateTime(
        e.eventDate.year,
        e.eventDate.month,
        e.eventDate.day,
      );
      return !eventDateOnly.isBefore(startOfToday);
    }).toList()..sort((a, b) => a.eventDate.compareTo(b.eventDate));

    debugPrint(
      '[EventOrderController] Upcoming events filtered: ${upcomingEvents.length}',
    );
    return upcomingEvents;
  }

  // Search event orders by name or customer
  Future<List<EventOrderEntity>> searchEventOrders(String query) async {
    if (query.isEmpty) return getAllEventOrders();

    final needle = query.toLowerCase();
    final orders = (await _db.loadEventOrders()).where((order) {
      if (order.syncStatus == EventOrderSyncStatus.deleted) return false;
      return order.orderName.toLowerCase().contains(needle) ||
          order.customerName.toLowerCase().contains(needle) ||
          order.customerContact.contains(query);
    }).toList();
    orders.sort((a, b) => b.eventDate.compareTo(a.eventDate));
    return orders;
  }

  // ==================== UPDATE ====================

  // Update an existing event order
  Future<EventOrderEntity?> updateEventOrder({
    required int id,
    OrderType? orderType,
    String? customerId,
    String? customerName,
    String? customerContact,
    String? customerAddress,
    String? orderName,
    String? description,
    DateTime? eventDate,
    String? eventLocation,
    List<SubEvent>? subEvents,
    List<OrderItem>? items,
    double? eventCharges,
    double? advanceAmount,
    String? notes,
    OrderStatus? status,
    String? convertedBillId,
    Map<String, dynamic>? customData,
  }) async {
    final existing = await getEventOrderById(id);
    if (existing == null) {
      debugPrint('[EventOrderOffline] Order not found: $id');
      return null;
    }

    // Apply updates
    if (orderType != null) existing.orderType = orderType.index;
    if (customerId != null) existing.customerId = customerId;
    if (customerName != null) existing.customerName = customerName;
    if (customerContact != null) existing.customerContact = customerContact;
    if (customerAddress != null) existing.customerAddress = customerAddress;
    if (orderName != null) existing.orderName = orderName;
    if (description != null) existing.description = description;
    if (eventDate != null) existing.eventDate = eventDate;
    if (eventLocation != null) existing.eventLocation = eventLocation;
    if (subEvents != null) {
      existing.subEvents = subEvents
          .map((e) => SubEventEmbedded.fromDomain(e))
          .toList();
    }
    if (items != null) {
      existing.items = items
          .map((e) => OrderItemEmbedded.fromDomain(e))
          .toList();
    }
    if (eventCharges != null) existing.eventCharges = eventCharges;
    if (advanceAmount != null) existing.advanceAmount = advanceAmount;
    if (notes != null) existing.notes = notes;
    if (status != null) existing.status = status.index;
    if (convertedBillId != null) existing.convertedBillId = convertedBillId;
    if (customData != null) {
      existing.customDataJson = customData.isNotEmpty
          ? jsonEncode(customData)
          : null;
    }

    // Recalculate totals
    if (existing.orderType == OrderType.event.index) {
      existing.totalAmount =
          existing.subEvents.fold(0.0, (total, e) => total + e.charges) +
          existing.eventCharges +
          existing.items.fold(0.0, (total, e) => total + e.total);
    } else {
      existing.totalAmount = existing.items.fold(
        0.0,
        (total, e) => total + e.total,
      );
    }
    existing.remainingAmount = existing.totalAmount - existing.advanceAmount;
    existing.updatedAt = DateTime.now();

    // Update sync status
    if (existing.syncStatus == EventOrderSyncStatus.synced) {
      existing.syncStatus = EventOrderSyncStatus.updated;
    }

    await _db.saveEventOrder(existing);

    debugPrint(
      '[EventOrderOffline] Order updated: $id, syncStatus: ${existing.syncStatus.name}',
    );
    notifyListeners();
    return existing;
  }

  // ==================== DELETE ====================

  // Soft delete an event order (mark as deleted for sync)
  Future<bool> deleteEventOrder(int id) async {
    final existing = await getEventOrderById(id);
    if (existing == null) {
      debugPrint('[EventOrderOffline] Order not found: $id');
      return false;
    }

    // If it's a new record, just delete it permanently (never synced)
    if (existing.syncStatus == EventOrderSyncStatus.newRecord) {
      await _db.deleteEventOrderById(id);
      debugPrint('[EventOrderOffline] New order permanently deleted: $id');
    } else {
      // Mark as deleted for sync
      existing.syncStatus = EventOrderSyncStatus.deleted;
      existing.updatedAt = DateTime.now();
      await _db.saveEventOrder(existing);
      debugPrint('[EventOrderOffline] Order marked deleted: $id');
    }

    notifyListeners();
    return true;
  }

  // ==================== STATISTICS ====================

  // Get total advance amount collected
  Future<double> getTotalAdvanceAmount({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final orders = (await _db.loadEventOrders()).where((order) {
      if (order.syncStatus == EventOrderSyncStatus.deleted) return false;
      if (startDate != null && endDate != null) {
        return !order.eventDate.isBefore(startDate) &&
            !order.eventDate.isAfter(endDate);
      }
      return true;
    });

    double total = 0.0;
    for (final order in orders) {
      total += order.advanceAmount;
    }
    return total;
  }

  // Get total pending amount (remaining)
  Future<double> getTotalPendingAmount() async {
    final orders = (await _db.loadEventOrders()).where((order) {
      return order.status < OrderStatus.delivered.index &&
          order.syncStatus != EventOrderSyncStatus.deleted;
    });

    double total = 0.0;
    for (final order in orders) {
      total += order.remainingAmount;
    }
    return total;
  }

  // Get order counts by status
  Future<Map<OrderStatus, int>> getOrderCountByStatus() async {
    final result = <OrderStatus, int>{};
    final orders = await _db.loadEventOrders();

    for (final status in OrderStatus.values) {
      result[status] = orders
          .where(
            (order) =>
                order.status == status.index &&
                order.syncStatus != EventOrderSyncStatus.deleted,
          )
          .length;
    }

    return result;
  }

  // Get total event order count
  Future<int> getTotalCount() async {
    return (await _db.loadEventOrders())
        .where((order) => order.syncStatus != EventOrderSyncStatus.deleted)
        .length;
  }

  // ==================== SYNC HELPERS ====================

  // Get all records that need to be synced to server
  Future<List<EventOrderEntity>> getRecordsToSync() async {
    return (await _db.loadEventOrders())
        .where((order) => order.syncStatus != EventOrderSyncStatus.synced)
        .toList();
  }

  // Mark a record as synced (call after successful server sync)
  Future<void> markAsSynced(int id, String serverId) async {
    final existing = await getEventOrderById(id);
    if (existing == null) return;

    existing.serverId = serverId;
    existing.syncStatus = EventOrderSyncStatus.synced;

    await _db.saveEventOrder(existing);

    debugPrint('[EventOrderOffline] Marked synced: $id -> $serverId');
  }

  // Permanently delete all records marked as deleted (call after sync)
  Future<int> purgeDeletedRecords() async {
    final toDelete = (await _db.loadEventOrders())
        .where((order) => order.syncStatus == EventOrderSyncStatus.deleted)
        .toList();

    if (toDelete.isEmpty) return 0;

    await _db.deleteEventOrdersByIds(toDelete.map((e) => e.id).toList());

    debugPrint('[EventOrderOffline] Purged ${toDelete.length} deleted records');
    return toDelete.length;
  }

  // Import an event order from server (used during sync)
  Future<void> importEventOrder(EventOrderEntity entity) async {
    await _db.saveEventOrder(entity);
    debugPrint(
      '[EventOrderOffline] Imported order from server: ${entity.serverId}',
    );
    notifyListeners();
  }

  // Update an order from server data (used during sync)
  Future<void> updateFromServer(int localId, Map<String, dynamic> data) async {
    final existing = await getEventOrderById(localId);
    if (existing == null) return;

    // Parse sub-events
    final subEvents =
        (data['subEvents'] as List<dynamic>?)
            ?.map(
              (e) => SubEventEmbedded(
                id: e['id'] as String?,
                name: e['name'] as String?,
                date: DateTime.tryParse(e['date']?.toString() ?? ''),
                charges: (e['charges'] as num?)?.toDouble() ?? 0.0,
                notes: e['notes'] as String?,
                customDataJson: e['customDataJson'] as String?,
              ),
            )
            .toList() ??
        existing.subEvents;

    // Parse items
    final items =
        (data['items'] as List<dynamic>?)
            ?.map(
              (e) => OrderItemEmbedded(
                id: e['id'] as String?,
                productId: e['productId'] as String?,
                productName: e['productName'] as String?,
                hsnCode: e['hsnCode'] as String?,
                quantity: (e['quantity'] as num?)?.toInt() ?? 0,
                rate: (e['rate'] as num?)?.toDouble() ?? 0.0,
                discountPercent:
                    (e['discountPercent'] as num?)?.toDouble() ?? 0.0,
                discountAmount:
                    (e['discountAmount'] as num?)?.toDouble() ?? 0.0,
                cgstPercent: (e['cgstPercent'] as num?)?.toDouble() ?? 0.0,
                sgstPercent: (e['sgstPercent'] as num?)?.toDouble() ?? 0.0,
                cgstAmount: (e['cgstAmount'] as num?)?.toDouble() ?? 0.0,
                sgstAmount: (e['sgstAmount'] as num?)?.toDouble() ?? 0.0,
                taxAmount: (e['taxAmount'] as num?)?.toDouble() ?? 0.0,
                subtotal: (e['subtotal'] as num?)?.toDouble() ?? 0.0,
                total: (e['total'] as num?)?.toDouble() ?? 0.0,
              ),
            )
            .toList() ??
        existing.items;

    // Update fields
    existing.orderType =
        (data['orderType'] as num?)?.toInt() ?? existing.orderType;
    existing.customerId = data['customerId'] as String? ?? existing.customerId;
    existing.customerName =
        data['customerName'] as String? ?? existing.customerName;
    existing.customerContact =
        data['customerContact'] as String? ?? existing.customerContact;
    existing.customerAddress =
        data['customerAddress'] as String? ?? existing.customerAddress;
    existing.orderName = data['orderName'] as String? ?? existing.orderName;
    existing.description =
        data['description'] as String? ?? existing.description;
    existing.eventDate =
        DateTime.tryParse(data['eventDate']?.toString() ?? '') ??
        existing.eventDate;
    existing.eventLocation =
        data['eventLocation'] as String? ?? existing.eventLocation;
    existing.subEvents = subEvents;
    existing.items = items;
    existing.eventCharges =
        (data['eventCharges'] as num?)?.toDouble() ?? existing.eventCharges;
    existing.totalAmount =
        (data['totalAmount'] as num?)?.toDouble() ?? existing.totalAmount;
    existing.advanceAmount =
        (data['advanceAmount'] as num?)?.toDouble() ?? existing.advanceAmount;
    existing.remainingAmount =
        (data['remainingAmount'] as num?)?.toDouble() ??
        existing.remainingAmount;
    existing.notes = data['notes'] as String? ?? existing.notes;
    existing.status = (data['status'] as num?)?.toInt() ?? existing.status;
    existing.convertedBillId =
        data['convertedBillId'] as String? ?? existing.convertedBillId;
    existing.customDataJson =
        data['customDataJson'] as String? ?? existing.customDataJson;
    existing.updatedAt = _parseDateTime(data['updatedAt']) ?? DateTime.now();
    existing.syncStatus = EventOrderSyncStatus.synced;

    await _db.saveEventOrder(existing);

    debugPrint('[EventOrderOffline] Updated from server: $localId');
    notifyListeners();
  }

  // Get count of unsynced records
  Future<int> getUnsyncedCount() async {
    return (await _db.loadEventOrders())
        .where(
          (order) =>
              order.syncStatus != EventOrderSyncStatus.synced &&
              order.syncStatus != EventOrderSyncStatus.deleted,
        )
        .length;
  }
}

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/event_order.dart';
import '../../domain/entities/sub_event.dart';
import '../../domain/entities/order_item.dart';
import '../../offline/controllers/event_order_offline_controller.dart';
import 'event_order_state.dart';

/// Cubit for managing Event/Sales Order operations
/// Uses offline-first approach with local Isar database
class EventOrderCubit extends Cubit<EventOrderState> {
  final EventOrderOfflineController _controller;

  EventOrderCubit({EventOrderOfflineController? controller})
    : _controller = controller ?? EventOrderOfflineController.instance,
      super(const EventOrderInitial());

  /// Load all event orders
  Future<void> loadEventOrders({
    OrderType? filterType,
    OrderStatus? filterStatus,
    String? searchQuery,
  }) async {
    final previousOrders = state is EventOrderLoaded
        ? (state as EventOrderLoaded).orders
        : null;

    emit(EventOrderLoading(previousOrders: previousOrders));

    try {
      List<EventOrder> orders;

      if (searchQuery != null && searchQuery.isNotEmpty) {
        final entities = await _controller.searchEventOrders(searchQuery);
        orders = entities.map((e) => e.toDomain()).toList();
      } else if (filterType != null) {
        final entities = await _controller.getEventOrdersByType(filterType);
        orders = entities.map((e) => e.toDomain()).toList();
      } else if (filterStatus != null) {
        final entities = await _controller.getEventOrdersByStatus(filterStatus);
        orders = entities.map((e) => e.toDomain()).toList();
      } else {
        final entities = await _controller.getAllEventOrders();
        orders = entities.map((e) => e.toDomain()).toList();
      }

      emit(EventOrderLoaded(
        orders: orders,
        filterType: filterType,
        filterStatus: filterStatus,
        searchQuery: searchQuery,
      ));
    } catch (e) {
      debugPrint('[EventOrderCubit] Error loading orders: $e');
      emit(EventOrderError(
        message: e.toString(),
        previousOrders: previousOrders,
      ));
    }
  }

  /// Load event order by ID
  Future<void> loadEventOrderById(int id) async {
    emit(const EventOrderLoading());

    try {
      final entity = await _controller.getEventOrderById(id);
      if (entity != null) {
        emit(EventOrderDetailLoaded(order: entity.toDomain()));
      } else {
        emit(const EventOrderError(message: 'Order not found'));
      }
    } catch (e) {
      debugPrint('[EventOrderCubit] Error loading order: $e');
      emit(EventOrderError(message: e.toString()));
    }
  }

  /// Create a new event order
  Future<void> createEventOrder({
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
    emit(const EventOrderSaving());

    try {
      final entity = await _controller.addEventOrder(
        orderType: orderType,
        customerId: customerId,
        customerName: customerName,
        customerContact: customerContact,
        customerAddress: customerAddress,
        orderName: orderName,
        description: description,
        eventDate: eventDate,
        eventLocation: eventLocation,
        subEvents: subEvents,
        items: items,
        eventCharges: eventCharges,
        advanceAmount: advanceAmount,
        notes: notes,
        customData: customData,
      );

      emit(EventOrderSaved(
        order: entity.toDomain(),
        isNew: true,
      ));

      // Reload list after creating
      await loadEventOrders();
    } catch (e) {
      debugPrint('[EventOrderCubit] Error creating order: $e');
      emit(EventOrderError(message: e.toString()));
    }
  }

  /// Update an existing event order
  Future<void> updateEventOrder({
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
    emit(const EventOrderSaving());

    try {
      final entity = await _controller.updateEventOrder(
        id: id,
        orderType: orderType,
        customerId: customerId,
        customerName: customerName,
        customerContact: customerContact,
        customerAddress: customerAddress,
        orderName: orderName,
        description: description,
        eventDate: eventDate,
        eventLocation: eventLocation,
        subEvents: subEvents,
        items: items,
        eventCharges: eventCharges,
        advanceAmount: advanceAmount,
        notes: notes,
        status: status,
        convertedBillId: convertedBillId,
        customData: customData,
      );

      if (entity != null) {
        emit(EventOrderSaved(
          order: entity.toDomain(),
          isNew: false,
        ));
      } else {
        emit(const EventOrderError(message: 'Order not found'));
      }

      // Reload list after updating
      await loadEventOrders();
    } catch (e) {
      debugPrint('[EventOrderCubit] Error updating order: $e');
      emit(EventOrderError(message: e.toString()));
    }
  }

  /// Delete an event order
  Future<void> deleteEventOrder(int id) async {
    emit(const EventOrderSaving());

    try {
      final success = await _controller.deleteEventOrder(id);
      if (success) {
        emit(const EventOrderDeleted());
        // Reload list after deleting
        await loadEventOrders();
      } else {
        emit(const EventOrderError(message: 'Failed to delete order'));
      }
    } catch (e) {
      debugPrint('[EventOrderCubit] Error deleting order: $e');
      emit(EventOrderError(message: e.toString()));
    }
  }

  /// Update order status
  Future<void> updateOrderStatus(int id, OrderStatus status) async {
    await updateEventOrder(id: id, status: status);
  }

  /// Get pending orders for customer
  Future<List<EventOrder>> getCustomerPendingOrders(String customerId) async {
    final entities = await _controller.getEventOrdersByCustomerId(customerId);
    return entities
        .where((e) => e.status < OrderStatus.delivered.index)
        .map((e) => e.toDomain())
        .toList();
  }

  /// Get upcoming events
  Future<List<EventOrder>> getUpcomingEvents() async {
    final entities = await _controller.getUpcomingEvents();
    return entities.map((e) => e.toDomain()).toList();
  }

  /// Get statistics
  Future<Map<String, dynamic>> getStatistics() async {
    final pendingAmount = await _controller.getTotalPendingAmount();
    final advanceAmount = await _controller.getTotalAdvanceAmount();
    final statusCounts = await _controller.getOrderCountByStatus();
    final totalCount = await _controller.getTotalCount();

    return {
      'pendingAmount': pendingAmount,
      'advanceAmount': advanceAmount,
      'statusCounts': statusCounts,
      'totalCount': totalCount,
    };
  }
}

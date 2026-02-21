import '../entities/event_order.dart';

/// Abstract repository interface for Event/Sales Order operations
abstract class EventOrderRepository {
  /// Create a new event order
  Future<String> createEventOrder(EventOrder order);

  /// Get an event order by ID
  Future<EventOrder?> getEventOrderById(String id);

  /// Get all event orders
  Future<List<EventOrder>> getAllEventOrders();

  /// Get event orders by type (event or salesOrder)
  Future<List<EventOrder>> getEventOrdersByType(OrderType type);

  /// Get event orders by customer ID
  Future<List<EventOrder>> getEventOrdersByCustomerId(String customerId);

  /// Get event orders by status
  Future<List<EventOrder>> getEventOrdersByStatus(OrderStatus status);

  /// Get event orders by date range
  Future<List<EventOrder>> getEventOrdersByDateRange(
    DateTime startDate,
    DateTime endDate,
  );

  /// Get pending event orders (not delivered or cancelled)
  Future<List<EventOrder>> getPendingEventOrders();

  /// Get today's event orders
  Future<List<EventOrder>> getTodaysEventOrders();

  /// Get upcoming events (event date in future)
  Future<List<EventOrder>> getUpcomingEvents();

  /// Update an event order
  Future<void> updateEventOrder(EventOrder order);

  /// Delete an event order
  Future<void> deleteEventOrder(String id);

  /// Search event orders by name or customer
  Future<List<EventOrder>> searchEventOrders(String query);

  /// Get total advance amount collected
  Future<double> getTotalAdvanceAmount({DateTime? startDate, DateTime? endDate});

  /// Get total pending amount (remaining)
  Future<double> getTotalPendingAmount();

  /// Convert event order to bill (used when finalizing)
  Future<String> convertToBill(String orderId);

  /// Get event orders count by status
  Future<Map<OrderStatus, int>> getOrderCountByStatus();
}

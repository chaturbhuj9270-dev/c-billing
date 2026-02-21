import 'package:equatable/equatable.dart';
import '../../domain/entities/event_order.dart';

/// Base state for EventOrder
abstract class EventOrderState extends Equatable {
  const EventOrderState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class EventOrderInitial extends EventOrderState {
  const EventOrderInitial();
}

/// Loading event orders list
class EventOrderLoading extends EventOrderState {
  final List<EventOrder>? previousOrders;

  const EventOrderLoading({this.previousOrders});

  @override
  List<Object?> get props => [previousOrders];
}

/// Event orders loaded successfully
class EventOrderLoaded extends EventOrderState {
  final List<EventOrder> orders;
  final OrderType? filterType;
  final OrderStatus? filterStatus;
  final String? searchQuery;

  const EventOrderLoaded({
    required this.orders,
    this.filterType,
    this.filterStatus,
    this.searchQuery,
  });

  @override
  List<Object?> get props => [orders, filterType, filterStatus, searchQuery];
}

/// Error loading event orders
class EventOrderError extends EventOrderState {
  final String message;
  final List<EventOrder>? previousOrders;

  const EventOrderError({
    required this.message,
    this.previousOrders,
  });

  @override
  List<Object?> get props => [message, previousOrders];
}

/// Creating/updating an event order
class EventOrderSaving extends EventOrderState {
  const EventOrderSaving();
}

/// Event order saved successfully
class EventOrderSaved extends EventOrderState {
  final EventOrder order;
  final bool isNew;

  const EventOrderSaved({
    required this.order,
    required this.isNew,
  });

  @override
  List<Object?> get props => [order, isNew];
}

/// Event order deleted
class EventOrderDeleted extends EventOrderState {
  const EventOrderDeleted();
}

/// Single event order detail loaded
class EventOrderDetailLoaded extends EventOrderState {
  final EventOrder order;

  const EventOrderDetailLoaded({required this.order});

  @override
  List<Object?> get props => [order];
}

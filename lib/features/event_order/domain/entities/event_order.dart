import 'sub_event.dart';
import 'order_item.dart';

/// The type of order
enum OrderType {
  /// Event with sub-events (like wedding event with haldi, sangeet, etc.)
  event,
  
  /// Sales order/booking with products
  salesOrder,
}

/// The status of an order
enum OrderStatus {
  /// Order just created, not yet confirmed
  pending,
  
  /// Order confirmed with advance payment
  confirmed,
  
  /// Order partially delivered or in progress
  inProgress,
  
  /// Order fully delivered
  delivered,
  
  /// Order cancelled
  cancelled,
  
  /// Order converted to final bill
  convertedToBill;
  
  /// Get display name for the status
  String get displayName {
    switch (this) {
      case OrderStatus.pending:
        return 'Pending';
      case OrderStatus.confirmed:
        return 'Confirmed';
      case OrderStatus.inProgress:
        return 'In Progress';
      case OrderStatus.delivered:
        return 'Delivered';
      case OrderStatus.cancelled:
        return 'Cancelled';
      case OrderStatus.convertedToBill:
        return 'Converted to Bill';
    }
  }
}

/// Main entity representing an Event or Sales Order
class EventOrder {
  /// Unique identifier
  final String id;
  
  /// Type of order (event or sales order)
  final OrderType orderType;
  
  /// Customer ID (linked to existing customer)
  final String? customerId;
  
  /// Customer name
  final String customerName;
  
  /// Customer contact number
  final String customerContact;
  
  /// Customer address (optional)
  final String? customerAddress;
  
  /// Event/Order name (e.g., "John's Wedding", "Bulk Order #123")
  final String orderName;
  
  /// Description of the event/order
  final String? description;
  
  /// Main event date / delivery date
  final DateTime eventDate;
  
  /// Event/Order location (optional)
  final String? eventLocation;
  
  /// List of sub-events (only for event type)
  final List<SubEvent> subEvents;
  
  /// List of order items (only for sales order type)
  final List<OrderItem> items;
  
  /// Total amount (calculated from sub-events or items)
  final double totalAmount;
  
  /// Advance amount received
  final double advanceAmount;
  
  /// Remaining amount (totalAmount - advanceAmount)
  final double remainingAmount;
  
  /// Additional notes
  final String? notes;
  
  /// Current status of the order
  final OrderStatus status;
  
  /// Bill ID if order is converted to bill
  final String? convertedBillId;
  
  /// Created timestamp
  final DateTime createdAt;
  
  /// Updated timestamp
  final DateTime updatedAt;
  
  const EventOrder({
    required this.id,
    required this.orderType,
    this.customerId,
    required this.customerName,
    required this.customerContact,
    this.customerAddress,
    required this.orderName,
    this.description,
    required this.eventDate,
    this.eventLocation,
    this.subEvents = const [],
    this.items = const [],
    required this.totalAmount,
    this.advanceAmount = 0.0,
    required this.remainingAmount,
    this.notes,
    this.status = OrderStatus.pending,
    this.convertedBillId,
    required this.createdAt,
    required this.updatedAt,
  });
  
  /// Check if this is an event type
  bool get isEvent => orderType == OrderType.event;
  
  /// Check if this is a sales order type
  bool get isSalesOrder => orderType == OrderType.salesOrder;
  
  /// Check if advance is paid
  bool get hasAdvance => advanceAmount > 0;
  
  /// Check if fully paid
  bool get isFullyPaid => remainingAmount <= 0;
  
  /// Check if order is confirmed
  bool get isConfirmed => status == OrderStatus.confirmed || 
      status == OrderStatus.inProgress || 
      status == OrderStatus.delivered ||
      status == OrderStatus.convertedToBill;
  
  /// Check if order is pending
  bool get isPending => status == OrderStatus.pending;
  
  /// Check if order is cancelled
  bool get isCancelled => status == OrderStatus.cancelled;
  
  /// Check if order is converted to bill
  bool get isConvertedToBill => status == OrderStatus.convertedToBill;
  
  /// Create a copy with updated fields
  EventOrder copyWith({
    String? id,
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
    double? totalAmount,
    double? advanceAmount,
    double? remainingAmount,
    String? notes,
    OrderStatus? status,
    String? convertedBillId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return EventOrder(
      id: id ?? this.id,
      orderType: orderType ?? this.orderType,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      customerContact: customerContact ?? this.customerContact,
      customerAddress: customerAddress ?? this.customerAddress,
      orderName: orderName ?? this.orderName,
      description: description ?? this.description,
      eventDate: eventDate ?? this.eventDate,
      eventLocation: eventLocation ?? this.eventLocation,
      subEvents: subEvents ?? this.subEvents,
      items: items ?? this.items,
      totalAmount: totalAmount ?? this.totalAmount,
      advanceAmount: advanceAmount ?? this.advanceAmount,
      remainingAmount: remainingAmount ?? this.remainingAmount,
      notes: notes ?? this.notes,
      status: status ?? this.status,
      convertedBillId: convertedBillId ?? this.convertedBillId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
  
  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'orderType': orderType.index,
      'customerId': customerId,
      'customerName': customerName,
      'customerContact': customerContact,
      'customerAddress': customerAddress,
      'orderName': orderName,
      'description': description,
      'eventDate': eventDate.toIso8601String(),
      'eventLocation': eventLocation,
      'subEvents': subEvents.map((e) => e.toJson()).toList(),
      'items': items.map((e) => e.toJson()).toList(),
      'totalAmount': totalAmount,
      'advanceAmount': advanceAmount,
      'remainingAmount': remainingAmount,
      'notes': notes,
      'status': status.index,
      'convertedBillId': convertedBillId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
  
  /// Create from JSON
  factory EventOrder.fromJson(Map<String, dynamic> json) {
    return EventOrder(
      id: json['id'] as String,
      orderType: OrderType.values[json['orderType'] as int? ?? 0],
      customerId: json['customerId'] as String?,
      customerName: json['customerName'] as String? ?? '',
      customerContact: json['customerContact'] as String? ?? '',
      customerAddress: json['customerAddress'] as String?,
      orderName: json['orderName'] as String? ?? '',
      description: json['description'] as String?,
      eventDate: DateTime.parse(json['eventDate'] as String),
      eventLocation: json['eventLocation'] as String?,
      subEvents: (json['subEvents'] as List<dynamic>?)
          ?.map((e) => SubEvent.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
      items: (json['items'] as List<dynamic>?)
          ?.map((e) => OrderItem.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0.0,
      advanceAmount: (json['advanceAmount'] as num?)?.toDouble() ?? 0.0,
      remainingAmount: (json['remainingAmount'] as num?)?.toDouble() ?? 0.0,
      notes: json['notes'] as String?,
      status: OrderStatus.values[json['status'] as int? ?? 0],
      convertedBillId: json['convertedBillId'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }
  
  /// Create an empty event order
  factory EventOrder.empty({OrderType type = OrderType.event}) {
    final now = DateTime.now();
    return EventOrder(
      id: '',
      orderType: type,
      customerName: '',
      customerContact: '',
      orderName: '',
      eventDate: now.add(const Duration(days: 7)),
      totalAmount: 0.0,
      remainingAmount: 0.0,
      createdAt: now,
      updatedAt: now,
    );
  }
}

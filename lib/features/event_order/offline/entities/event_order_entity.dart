import 'package:isar_community/isar.dart';
import '../../domain/entities/event_order.dart';
import '../../domain/entities/sub_event.dart';
import '../../domain/entities/order_item.dart';

part 'event_order_entity.g.dart';

/// Sync status for delta sync logic
enum EventOrderSyncStatus {
  /// Newly created locally, not yet on server
  newRecord,
  
  /// Modified locally after sync
  updated,
  
  /// Marked for deletion, pending server delete
  deleted,
  
  /// Fully synced with server
  synced,
}

/// Embedded entity for sub-events
@embedded
class SubEventEmbedded {
  String? id;
  String? name;
  DateTime? date;
  double charges;
  String? notes;
  
  SubEventEmbedded({
    this.id,
    this.name,
    this.date,
    this.charges = 0.0,
    this.notes,
  });
  
  SubEvent toDomain() {
    return SubEvent(
      id: id ?? '',
      name: name ?? '',
      date: date ?? DateTime.now(),
      charges: charges,
      notes: notes,
    );
  }
  
  static SubEventEmbedded fromDomain(SubEvent subEvent) {
    return SubEventEmbedded(
      id: subEvent.id,
      name: subEvent.name,
      date: subEvent.date,
      charges: subEvent.charges,
      notes: subEvent.notes,
    );
  }
}

/// Embedded entity for order items
@embedded
class OrderItemEmbedded {
  String? id;
  String? productId;
  String? productName;
  String? hsnCode;
  int quantity;
  double rate;
  double discountPercent;
  double discountAmount;
  double cgstPercent;
  double sgstPercent;
  double cgstAmount;
  double sgstAmount;
  double taxAmount;
  double subtotal;
  double total;
  
  OrderItemEmbedded({
    this.id,
    this.productId,
    this.productName,
    this.hsnCode,
    this.quantity = 0,
    this.rate = 0.0,
    this.discountPercent = 0.0,
    this.discountAmount = 0.0,
    this.cgstPercent = 0.0,
    this.sgstPercent = 0.0,
    this.cgstAmount = 0.0,
    this.sgstAmount = 0.0,
    this.taxAmount = 0.0,
    this.subtotal = 0.0,
    this.total = 0.0,
  });
  
  OrderItem toDomain() {
    return OrderItem(
      id: id ?? '',
      productId: productId ?? '',
      productName: productName ?? '',
      hsnCode: hsnCode,
      quantity: quantity,
      rate: rate,
      discountPercent: discountPercent,
      discountAmount: discountAmount,
      cgstPercent: cgstPercent,
      sgstPercent: sgstPercent,
      cgstAmount: cgstAmount,
      sgstAmount: sgstAmount,
      taxAmount: taxAmount,
      subtotal: subtotal,
      total: total,
    );
  }
  
  static OrderItemEmbedded fromDomain(OrderItem item) {
    return OrderItemEmbedded(
      id: item.id,
      productId: item.productId,
      productName: item.productName,
      hsnCode: item.hsnCode,
      quantity: item.quantity,
      rate: item.rate,
      discountPercent: item.discountPercent,
      discountAmount: item.discountAmount,
      cgstPercent: item.cgstPercent,
      sgstPercent: item.sgstPercent,
      cgstAmount: item.cgstAmount,
      sgstAmount: item.sgstAmount,
      taxAmount: item.taxAmount,
      subtotal: item.subtotal,
      total: item.total,
    );
  }
}

/// Isar Collection for Event/Sales Order with offline-first support
@collection
class EventOrderEntity {
  /// Auto-generated Isar ID
  Id id = Isar.autoIncrement;
  
  /// Server-side ID
  @Index()
  String? serverId;
  
  /// Order type (0 = event, 1 = salesOrder)
  int orderType;
  
  /// Customer ID
  @Index()
  String? customerId;
  
  /// Customer name
  String customerName;
  
  /// Customer contact
  String customerContact;
  
  /// Order name
  @Index()
  String orderName;
  
  /// Description
  String? description;
  
  /// Event/Delivery date
  @Index()
  DateTime eventDate;
  
  /// Sub-events (for event type)
  List<SubEventEmbedded> subEvents;
  
  /// Order items (for sales order type)
  List<OrderItemEmbedded> items;
  
  /// Total amount
  double totalAmount;
  
  /// Advance amount
  double advanceAmount;
  
  /// Remaining amount
  double remainingAmount;
  
  /// Notes
  String? notes;
  
  /// Status (0=pending, 1=confirmed, 2=inProgress, 3=delivered, 4=cancelled, 5=convertedToBill)
  @Index()
  int status;
  
  /// Converted bill ID
  String? convertedBillId;
  
  /// Created timestamp
  @Index()
  DateTime createdAt;
  
  /// Updated timestamp
  DateTime updatedAt;
  
  /// Sync status
  @Enumerated(EnumType.ordinal)
  EventOrderSyncStatus syncStatus;
  
  EventOrderEntity({
    this.serverId,
    this.orderType = 0,
    this.customerId,
    this.customerName = '',
    this.customerContact = '',
    this.orderName = '',
    this.description,
    required this.eventDate,
    required this.subEvents,
    required this.items,
    this.totalAmount = 0.0,
    this.advanceAmount = 0.0,
    this.remainingAmount = 0.0,
    this.notes,
    this.status = 0,
    this.convertedBillId,
    required this.createdAt,
    required this.updatedAt,
    this.syncStatus = EventOrderSyncStatus.newRecord,
  });
  
  /// Default constructor for creating new entity
  EventOrderEntity.create({
    this.serverId,
    this.orderType = 0,
    this.customerId,
    this.customerName = '',
    this.customerContact = '',
    this.orderName = '',
    this.description,
    DateTime? eventDate,
    List<SubEventEmbedded>? subEvents,
    List<OrderItemEmbedded>? items,
    this.totalAmount = 0.0,
    this.advanceAmount = 0.0,
    this.remainingAmount = 0.0,
    this.notes,
    this.status = 0,
    this.convertedBillId,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.syncStatus = EventOrderSyncStatus.newRecord,
  }) : eventDate = eventDate ?? DateTime.now(),
       subEvents = subEvents ?? [],
       items = items ?? [],
       createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();
  
  /// Convert to domain entity
  EventOrder toDomain() {
    return EventOrder(
      id: serverId ?? 'local_$id',
      orderType: OrderType.values[orderType],
      customerId: customerId,
      customerName: customerName,
      customerContact: customerContact,
      orderName: orderName,
      description: description,
      eventDate: eventDate,
      subEvents: subEvents.map((e) => e.toDomain()).toList(),
      items: items.map((e) => e.toDomain()).toList(),
      totalAmount: totalAmount,
      advanceAmount: advanceAmount,
      remainingAmount: remainingAmount,
      notes: notes,
      status: OrderStatus.values[status],
      convertedBillId: convertedBillId,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
  
  /// Create from domain entity
  static EventOrderEntity fromDomain(EventOrder order) {
    return EventOrderEntity(
      serverId: order.id.startsWith('local_') ? null : order.id,
      orderType: order.orderType.index,
      customerId: order.customerId,
      customerName: order.customerName,
      customerContact: order.customerContact,
      orderName: order.orderName,
      description: order.description,
      eventDate: order.eventDate,
      subEvents: order.subEvents.map((e) => SubEventEmbedded.fromDomain(e)).toList(),
      items: order.items.map((e) => OrderItemEmbedded.fromDomain(e)).toList(),
      totalAmount: order.totalAmount,
      advanceAmount: order.advanceAmount,
      remainingAmount: order.remainingAmount,
      notes: order.notes,
      status: order.status.index,
      convertedBillId: order.convertedBillId,
      createdAt: order.createdAt,
      updatedAt: order.updatedAt,
    );
  }
}

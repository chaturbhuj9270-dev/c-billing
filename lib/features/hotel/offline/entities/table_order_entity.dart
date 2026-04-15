import 'dart:convert';
import 'package:isar_community/isar.dart';

part 'table_order_entity.g.dart';

/// Plain Dart class for an individual ordered item.
/// Not an Isar collection — serialised as JSON inside [TableOrderEntity.itemsJson].
class OrderItem {
  final int menuItemLocalId;
  final String? menuItemServerId;
  final String name;
  final bool isVeg;
  final double price;
  final String category;
  int quantity;

  OrderItem({
    required this.menuItemLocalId,
    this.menuItemServerId,
    required this.name,
    required this.isVeg,
    required this.price,
    required this.category,
    this.quantity = 1,
  });

  double get lineTotal => price * quantity;

  Map<String, dynamic> toMap() => {
    'm': menuItemLocalId,
    's': menuItemServerId,
    'n': name,
    'v': isVeg,
    'p': price,
    'c': category,
    'q': quantity,
  };

  factory OrderItem.fromMap(Map<String, dynamic> map) => OrderItem(
    menuItemLocalId: (map['m'] as num?)?.toInt() ?? 0,
    menuItemServerId: map['s'] as String?,
    name: map['n'] as String? ?? '',
    isVeg: map['v'] as bool? ?? true,
    price: (map['p'] as num?)?.toDouble() ?? 0.0,
    category: map['c'] as String? ?? '',
    quantity: (map['q'] as num?)?.toInt() ?? 1,
  );
}

/// Encodes/decodes a list of [OrderItem] to/from JSON.
List<OrderItem> decodeOrderItems(String json) {
  try {
    return (jsonDecode(json) as List)
        .map((e) => OrderItem.fromMap(e as Map<String, dynamic>))
        .toList();
  } catch (_) {
    return [];
  }
}

String encodeOrderItems(List<OrderItem> items) =>
    jsonEncode(items.map((e) => e.toMap()).toList());

double calcOrderTotal(List<OrderItem> items) =>
    items.fold(0.0, (s, i) => s + i.lineTotal);

/// Status stages of a table order.
enum TableOrderStatus {
  open, // Being placed — table is Active
  sentToKitchen, // Order in kitchen — table is Waiting
  served, // Food served — table is Served
  billed, // Bill generated — table is Empty
  cancelled, // Manually cancelled
}

@collection
class TableOrderEntity {
  Id id = Isar.autoIncrement;

  @Index()
  int localTableId = 0;

  String tableNumber = '';

  String? guestName;
  String? guestPhone;
  int occupiedSeats = 1;
  String? notes;

  /// JSON-encoded [OrderItem] list.
  String itemsJson = '[]';

  double totalAmount = 0.0;

  String? billNumber;

  @Enumerated(EnumType.name)
  @Index()
  TableOrderStatus status = TableOrderStatus.open;

  DateTime? sentToKitchenAt;
  DateTime? servedAt;
  DateTime? billedAt;

  DateTime createdAt = DateTime.now();
  DateTime updatedAt = DateTime.now();
}

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

  /// How many units of this line the kitchen has marked prepared (0 … [quantity]).
  int kitchenDoneQty;

  OrderItem({
    required this.menuItemLocalId,
    this.menuItemServerId,
    required this.name,
    required this.isVeg,
    required this.price,
    required this.category,
    this.quantity = 1,
    this.kitchenDoneQty = 0,
  }) {
    _normalizeKitchenDone();
  }

  void _normalizeKitchenDone() {
    if (quantity < 0) quantity = 0;
    if (kitchenDoneQty < 0) kitchenDoneQty = 0;
    if (kitchenDoneQty > quantity) kitchenDoneQty = quantity;
  }

  /// True when every ordered unit of this line is done in the kitchen.
  bool get isReady => quantity > 0 && kitchenDoneQty >= quantity;

  /// Units still to prepare for this line (for kitchen display).
  int get pendingKitchenQty => (quantity - kitchenDoneQty).clamp(0, quantity);

  double get lineTotal => price * quantity;

  Map<String, dynamic> toMap() => {
    'm': menuItemLocalId,
    's': menuItemServerId,
    'n': name,
    'v': isVeg,
    'p': price,
    'c': category,
    'q': quantity,
    'kd': kitchenDoneQty,
    // Legacy readers / older builds
    'r': isReady,
  };

  factory OrderItem.fromMap(Map<String, dynamic> map) {
    final q = (map['q'] as num?)?.toInt() ?? 1;
    int kd;
    if (map['kd'] != null) {
      kd = (map['kd'] as num).toInt();
    } else {
      kd = (map['r'] as bool?) == true ? q : 0;
    }
    if (kd < 0) kd = 0;
    if (kd > q) kd = q;
    return OrderItem(
      menuItemLocalId: (map['m'] as num?)?.toInt() ?? 0,
      menuItemServerId: map['s'] as String?,
      name: map['n'] as String? ?? '',
      isVeg: map['v'] as bool? ?? true,
      price: (map['p'] as num?)?.toDouble() ?? 0.0,
      category: map['c'] as String? ?? '',
      quantity: q,
      kitchenDoneQty: kd,
    );
  }
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

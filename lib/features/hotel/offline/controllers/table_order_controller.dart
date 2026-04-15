import 'package:flutter/foundation.dart';
import 'package:isar_community/isar.dart';
import '../../../../core/services/isar_service.dart';
import '../entities/table_entity.dart';
import '../entities/table_order_entity.dart';
import 'table_offline_controller.dart';

class TableOrderController extends ChangeNotifier {
  static TableOrderController? _instance;
  final Isar _isar;
  final TableOfflineController _tableCtrl;

  TableOrderController._(this._isar, this._tableCtrl);

  static TableOrderController get instance {
    _instance ??= TableOrderController._(
      IsarService.instance.isar,
      TableOfflineController.instance,
    );
    return _instance!;
  }

  // ── CREATE ───────────────────────────────────────────────────────

  /// Creates an order for a table and moves it to [TableStatus.active].
  Future<TableOrderEntity> createOrder({
    required int localTableId,
    required String tableNumber,
    required List<OrderItem> items,
    String? guestName,
    String? guestPhone,
    int occupiedSeats = 1,
    String? notes,
  }) async {
    final total = calcOrderTotal(items);
    final order = TableOrderEntity()
      ..localTableId = localTableId
      ..tableNumber = tableNumber
      ..guestName = guestName
      ..guestPhone = guestPhone
      ..occupiedSeats = occupiedSeats
      ..notes = notes
      ..itemsJson = encodeOrderItems(items)
      ..totalAmount = total
      ..status = TableOrderStatus.open
      ..createdAt = DateTime.now()
      ..updatedAt = DateTime.now();

    await _isar.writeTxn(() async {
      await _isar.tableOrderEntitys.put(order);
    });

    await _tableCtrl.setStatus(
      localTableId,
      TableStatus.active,
      guestName: guestName,
      guestPhone: guestPhone,
      notes: notes,
      occupiedSeats: occupiedSeats,
    );

    debugPrint('[TableOrder] Created order ${order.id} for table $tableNumber');
    notifyListeners();
    return order;
  }

  // ── READ ────────────────────────────────────────────────────────

  /// Returns the latest non-billed/non-cancelled order for a table.
  Future<TableOrderEntity?> getActiveOrderForTable(int localTableId) async {
    return _isar.tableOrderEntitys
        .filter()
        .localTableIdEqualTo(localTableId)
        .not()
        .statusEqualTo(TableOrderStatus.billed)
        .not()
        .statusEqualTo(TableOrderStatus.cancelled)
        .sortByCreatedAtDesc()
        .findFirst();
  }

  // ── UPDATE ITEMS ────────────────────────────────────────────────

  Future<void> updateOrderItems(int orderId, List<OrderItem> items) async {
    final order = await _isar.tableOrderEntitys.get(orderId);
    if (order == null) return;

    final hadExtraItems =
        order.status == TableOrderStatus.sentToKitchen ||
        order.status == TableOrderStatus.served;

    order.itemsJson = encodeOrderItems(items);
    order.totalAmount = calcOrderTotal(items);
    order.updatedAt = DateTime.now();

    // If items are added after kitchen/served, restart the flow
    if (hadExtraItems) {
      order.status = TableOrderStatus.open;
    }

    await _isar.writeTxn(() async {
      await _isar.tableOrderEntitys.put(order);
    });

    // Revert table to active so new items go through kitchen flow
    if (hadExtraItems) {
      await _tableCtrl.setStatus(order.localTableId, TableStatus.active);
      debugPrint(
        '[TableOrder] Extra items added — order ${order.id} reset to open',
      );
    }

    notifyListeners();
  }

  // ── FLOW TRANSITIONS ────────────────────────────────────────────

  /// Sends order to kitchen → table becomes [TableStatus.waiting].
  Future<void> sendToKitchen(int orderId, int tableId) async {
    final order = await _isar.tableOrderEntitys.get(orderId);
    if (order == null) return;

    order.status = TableOrderStatus.sentToKitchen;
    order.sentToKitchenAt = DateTime.now();
    order.updatedAt = DateTime.now();

    await _isar.writeTxn(() async {
      await _isar.tableOrderEntitys.put(order);
    });
    await _tableCtrl.setStatus(tableId, TableStatus.waiting);

    debugPrint('[TableOrder] Sent to kitchen: order ${order.id}');
    notifyListeners();
  }

  /// Marks food as served → table becomes [TableStatus.served].
  Future<void> markServed(int orderId, int tableId) async {
    final order = await _isar.tableOrderEntitys.get(orderId);
    if (order == null) return;

    order.status = TableOrderStatus.served;
    order.servedAt = DateTime.now();
    order.updatedAt = DateTime.now();

    await _isar.writeTxn(() async {
      await _isar.tableOrderEntitys.put(order);
    });
    await _tableCtrl.setStatus(tableId, TableStatus.served);

    debugPrint('[TableOrder] Marked served: order ${order.id}');
    notifyListeners();
  }

  /// Generates bill, clears table → table becomes [TableStatus.empty].
  /// Returns the generated bill number.
  Future<String> generateBill(int orderId, int tableId) async {
    final order = await _isar.tableOrderEntitys.get(orderId);
    if (order == null) return '';

    final billNumber = _generateBillNumber();

    order.status = TableOrderStatus.billed;
    order.billNumber = billNumber;
    order.billedAt = DateTime.now();
    order.updatedAt = DateTime.now();

    await _isar.writeTxn(() async {
      await _isar.tableOrderEntitys.put(order);
    });

    await _tableCtrl.clearTable(tableId);

    debugPrint(
      '[TableOrder] Bill generated: $billNumber for order ${order.id}',
    );
    notifyListeners();
    return billNumber;
  }

  // ── KITCHEN DISPLAY ──────────────────────────────────────────────

  /// Returns all orders currently in the kitchen (sentToKitchen status).
  Future<List<TableOrderEntity>> getKitchenOrders() async {
    return _isar.tableOrderEntitys
        .filter()
        .statusEqualTo(TableOrderStatus.sentToKitchen)
        .sortBySentToKitchenAt()
        .findAll();
  }

  /// Marks a single item as ready in an order.
  Future<void> markItemReady(int orderId, int menuItemLocalId) async {
    final order = await _isar.tableOrderEntitys.get(orderId);
    if (order == null) return;

    final items = decodeOrderItems(order.itemsJson);
    for (final item in items) {
      if (item.menuItemLocalId == menuItemLocalId) {
        item.isReady = true;
        break;
      }
    }

    order.itemsJson = encodeOrderItems(items);
    order.updatedAt = DateTime.now();

    await _isar.writeTxn(() async {
      await _isar.tableOrderEntitys.put(order);
    });
    notifyListeners();
  }

  /// Marks all items in an order as ready.
  Future<void> markAllItemsReady(int orderId) async {
    final order = await _isar.tableOrderEntitys.get(orderId);
    if (order == null) return;

    final items = decodeOrderItems(order.itemsJson);
    for (final item in items) {
      item.isReady = true;
    }

    order.itemsJson = encodeOrderItems(items);
    order.updatedAt = DateTime.now();

    await _isar.writeTxn(() async {
      await _isar.tableOrderEntitys.put(order);
    });
    notifyListeners();
  }

  /// Marks entire order as ready to serve (all items ready + status → served).
  Future<void> markReadyToServe(int orderId, int tableId) async {
    await markAllItemsReady(orderId);
    await markServed(orderId, tableId);
  }

  // ── HELPERS ─────────────────────────────────────────────────────

  String _generateBillNumber() {
    final now = DateTime.now();
    final date =
        '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
    final rand = (now.millisecondsSinceEpoch % 10000).toString().padLeft(
      4,
      '0',
    );
    return 'BILL-$date-$rand';
  }
}

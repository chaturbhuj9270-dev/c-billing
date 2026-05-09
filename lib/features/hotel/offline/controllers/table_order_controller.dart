import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:isar_community/isar.dart';
import '../../../../core/services/isar_service.dart';
import '../../data/services/hotel_push_service.dart';
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

  /// Creates an order for a table and sends it to the kitchen immediately.
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
      ..status = TableOrderStatus.sentToKitchen
      ..sentToKitchenAt = DateTime.now()
      ..createdAt = DateTime.now()
      ..updatedAt = DateTime.now();

    await _isar.writeTxn(() async {
      await _isar.tableOrderEntitys.put(order);
    });

    await _tableCtrl.setStatus(
      localTableId,
      TableStatus.waiting,
      guestName: guestName,
      guestPhone: guestPhone,
      notes: notes,
      occupiedSeats: occupiedSeats,
    );

    debugPrint(
      '[TableOrder] Created and sent order ${order.id} for table $tableNumber',
    );
    notifyListeners();
    unawaited(
      HotelPushService.sendOrderEvent(
        event: HotelOrderPushEvent.orderToKitchen,
        tableNumber: tableNumber,
        orderId: order.id,
      ),
    );
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

  Future<TableOrderEntity?> getOrderById(Id id) async {
    return _isar.tableOrderEntitys.get(id);
  }

  // ── UPDATE ITEMS ────────────────────────────────────────────────

  /// Updates line items. When the order was already in kitchen or served,
  /// new/changed lines are marked not ready, order returns to [sentToKitchen],
  /// table becomes [waiting], and kitchen is notified.
  Future<void> updateOrderItems(
    int orderId,
    List<OrderItem> items, {
    bool syncGuestFields = false,
    String? guestName,
    String? guestPhone,
    int? occupiedSeats,
    String? notes,
  }) async {
    final order = await _isar.tableOrderEntitys.get(orderId);
    if (order == null) return;

    final oldItems = decodeOrderItems(order.itemsJson);
    final oldById = {for (final o in oldItems) o.menuItemLocalId: o};

    for (final ni in items) {
      final old = oldById[ni.menuItemLocalId];
      if (old == null) {
        ni.kitchenDoneQty = 0;
      } else {
        // Keep already-prepared units when the guest orders more of the same item.
        ni.kitchenDoneQty = old.kitchenDoneQty.clamp(0, ni.quantity);
      }
    }

    final wasInKitchenFlow =
        order.status == TableOrderStatus.sentToKitchen ||
        order.status == TableOrderStatus.served;
    final wasServed = order.status == TableOrderStatus.served;

    order.itemsJson = encodeOrderItems(items);
    order.totalAmount = calcOrderTotal(items);
    order.updatedAt = DateTime.now();

    if (syncGuestFields) {
      order.guestName = guestName;
      order.guestPhone = guestPhone;
      if (occupiedSeats != null) order.occupiedSeats = occupiedSeats;
      order.notes = notes;
    }

    if (wasInKitchenFlow) {
      order.status = TableOrderStatus.sentToKitchen;
      order.sentToKitchenAt = DateTime.now();
      if (wasServed) {
        order.servedAt = null;
      }
    }

    await _isar.writeTxn(() async {
      await _isar.tableOrderEntitys.put(order);
    });

    if (wasInKitchenFlow) {
      await _tableCtrl.setStatus(
        order.localTableId,
        TableStatus.waiting,
        guestName: order.guestName,
        guestPhone: order.guestPhone,
        notes: order.notes,
        occupiedSeats: order.occupiedSeats,
      );
      debugPrint(
        '[TableOrder] Order ${order.id} updated — (re)sent to kitchen, '
        '${items.length} lines',
      );
      unawaited(
        HotelPushService.sendOrderEvent(
          event: HotelOrderPushEvent.orderToKitchen,
          tableNumber: order.tableNumber,
          orderId: order.id,
        ),
      );
    } else if (syncGuestFields) {
      await _tableCtrl.setStatus(
        order.localTableId,
        TableStatus.active,
        guestName: order.guestName,
        guestPhone: order.guestPhone,
        notes: order.notes,
        occupiedSeats: order.occupiedSeats,
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
    unawaited(
      HotelPushService.sendOrderEvent(
        event: HotelOrderPushEvent.orderToKitchen,
        tableNumber: order.tableNumber,
        orderId: order.id,
      ),
    );
  }

  /// Marks food as served → table becomes [TableStatus.served].
  Future<void> markServed(int orderId, int tableId) async {
    final order = await _isar.tableOrderEntitys.get(orderId);
    if (order == null) return;

    final wasInKitchen = order.status == TableOrderStatus.sentToKitchen;

    order.status = TableOrderStatus.served;
    order.servedAt = DateTime.now();
    order.updatedAt = DateTime.now();

    await _isar.writeTxn(() async {
      await _isar.tableOrderEntitys.put(order);
    });
    await _tableCtrl.setStatus(tableId, TableStatus.served);

    debugPrint('[TableOrder] Marked served: order ${order.id}');
    notifyListeners();
    if (wasInKitchen) {
      unawaited(
        HotelPushService.sendOrderEvent(
          event: HotelOrderPushEvent.orderReady,
          tableNumber: order.tableNumber,
          orderId: order.id,
        ),
      );
    }
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
    unawaited(
      HotelPushService.sendOrderEvent(
        event: HotelOrderPushEvent.billCleared,
        tableNumber: order.tableNumber,
        billNumber: billNumber,
        orderId: order.id,
      ),
    );
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
        item.kitchenDoneQty = item.quantity;
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
      item.kitchenDoneQty = item.quantity;
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

  // ── ORDER LISTING / FILTERING ──────────────────────────────────

  /// Returns all orders, optionally filtered by status.
  Future<List<TableOrderEntity>> getAllOrders({
    TableOrderStatus? status,
  }) async {
    if (status != null) {
      return _isar.tableOrderEntitys
          .filter()
          .statusEqualTo(status)
          .sortByCreatedAtDesc()
          .findAll();
    }
    return _isar.tableOrderEntitys.where().sortByCreatedAtDesc().findAll();
  }

  /// Returns orders created today.
  Future<List<TableOrderEntity>> getTodayOrders() async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    return _isar.tableOrderEntitys
        .filter()
        .createdAtGreaterThan(startOfDay)
        .sortByCreatedAtDesc()
        .findAll();
  }

  /// Returns today's revenue (sum of billed orders).
  Future<double> getTodayRevenue() async {
    final orders = await getTodayOrders();
    double total = 0.0;
    for (final o in orders) {
      if (o.status == TableOrderStatus.billed) total += o.totalAmount;
    }
    return total;
  }

  /// Cancels an open/kitchen order.
  Future<void> cancelOrder(int orderId, int tableId) async {
    final order = await _isar.tableOrderEntitys.get(orderId);
    if (order == null) return;

    order.status = TableOrderStatus.cancelled;
    order.updatedAt = DateTime.now();

    await _isar.writeTxn(() async {
      await _isar.tableOrderEntitys.put(order);
    });

    await _tableCtrl.clearTable(tableId);

    debugPrint('[TableOrder] Cancelled order ${order.id}');
    notifyListeners();
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

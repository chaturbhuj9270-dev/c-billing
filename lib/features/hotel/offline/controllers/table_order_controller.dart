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

    order.itemsJson = encodeOrderItems(items);
    order.totalAmount = calcOrderTotal(items);
    order.updatedAt = DateTime.now();

    await _isar.writeTxn(() async {
      await _isar.tableOrderEntitys.put(order);
    });
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

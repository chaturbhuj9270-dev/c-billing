import '../entities/inventory_item.dart';

abstract class InventoryRepository {
  Future<List<InventoryItem>> fetchInventory();
  Future<InventoryItem> updateInventory(InventoryItem item);
}

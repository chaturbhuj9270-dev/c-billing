import '../entities/inventory_item.dart';
import '../repositories/inventory_repository.dart';

class UpdateInventory {
  final InventoryRepository repository;

  UpdateInventory(this.repository);

  Future<InventoryItem> call(InventoryItem item) async {
    return repository.updateInventory(item);
  }
}

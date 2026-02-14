import '../entities/inventory_item.dart';
import '../repositories/inventory_repository.dart';

class FetchInventory {
  final InventoryRepository repository;

  FetchInventory(this.repository);

  Future<List<InventoryItem>> call() async {
    return repository.fetchInventory();
  }
}

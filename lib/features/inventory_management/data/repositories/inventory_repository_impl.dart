import '../../domain/entities/inventory_item.dart';
import '../../domain/repositories/inventory_repository.dart';
import '../models/inventory_model.dart';
import '../providers/inventory_remote_data_provider.dart';

class InventoryRepositoryImpl implements InventoryRepository {
  final InventoryRemoteDataProvider remote;

  InventoryRepositoryImpl({required this.remote});

  @override
  Future<List<InventoryItem>> fetchInventory() async {
    final models = await remote.fetchInventory();
    return models;
  }

  @override
  Future<InventoryItem> updateInventory(InventoryItem item) async {
    final model = InventoryModel(
      id: item.id,
      name: item.name,
      quantity: item.quantity,
    );
    return remote.updateInventory(model);
  }
}

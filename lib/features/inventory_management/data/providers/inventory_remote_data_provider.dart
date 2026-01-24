import 'dart:convert';

import '../../../../core/network/network_service.dart';
import '../models/inventory_model.dart';

abstract class InventoryRemoteDataProvider {
  Future<List<InventoryModel>> fetchInventory();
  Future<InventoryModel> updateInventory(InventoryModel item);
}

class InventoryRemoteDataProviderImpl implements InventoryRemoteDataProvider {
  final NetworkService network;

  InventoryRemoteDataProviderImpl({required this.network});

  @override
  Future<List<InventoryModel>> fetchInventory() async {
    final res = await network.get('/inventory');
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body) as List<dynamic>;
      return data
          .map((e) => InventoryModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    throw Exception('Failed to fetch inventory');
  }

  @override
  Future<InventoryModel> updateInventory(InventoryModel item) async {
    final res = await network.post(
      '/inventory/${item.id}',
      body: item.toJson(),
    );
    if (res.statusCode == 200) {
      return InventoryModel.fromJson(
        jsonDecode(res.body) as Map<String, dynamic>,
      );
    }
    throw Exception('Failed to update inventory');
  }
}

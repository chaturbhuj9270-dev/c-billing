import '../../domain/entities/inventory_item.dart';

class InventoryModel extends InventoryItem {
  InventoryModel({
    required super.id,
    required super.name,
    required super.quantity,
  });

  factory InventoryModel.fromJson(Map<String, dynamic> json) {
    return InventoryModel(
      id: json['id'] as String,
      name: json['name'] as String,
      quantity: json['quantity'] as int,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'quantity': quantity,
  };
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:c_billing/features/inventory_management/data/repositories/firebase_product_repository.dart';
import 'package:c_billing/features/inventory_management/data/repositories/firebase_stock_repository.dart';
import 'package:c_billing/features/inventory_management/data/repositories/firebase_purchase_repository.dart';
import 'package:c_billing/features/inventory_management/domain/entities/product.dart';
import './inventory_service.dart';

class DashboardInventoryService {
  static final DashboardInventoryService _instance = DashboardInventoryService._internal();
  
  late InventoryService _inventoryService;
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  DashboardInventoryService._internal() {
    _initializeService();
  }

  factory DashboardInventoryService() {
    return _instance;
  }

  void _initializeService() {
    _inventoryService = InventoryService(
      productRepository: FirebaseProductRepository(firestore: _firestore),
      stockRepository: FirebaseStockRepository(firestore: _firestore),
      purchaseRepository: FirebasePurchaseRepository(firestore: _firestore),
    );
  }

  /// Get dashboard summary metrics
  Future<Map<String, dynamic>> getDashboardSummary({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final totalPurchasesAmount = await _inventoryService.getTotalPurchasesAmount(
        startDate: startDate,
        endDate: endDate,
      );
      
      final totalPurchasesQuantity = await _inventoryService.getTotalPurchasesQuantity(
        startDate: startDate,
        endDate: endDate,
      );
      
      final totalSalesAmount = await _inventoryService.getTotalSalesAmount(
        startDate: startDate,
        endDate: endDate,
      );
      
      final totalSalesQuantity = await _inventoryService.getTotalSalesQuantity(
        startDate: startDate,
        endDate: endDate,
      );
      
      final profit = await _inventoryService.getProfit(
        startDate: startDate,
        endDate: endDate,
      );
      
      final currentStockValue = await _inventoryService.getCurrentStockValue();
      
      final lowStockProducts = await _inventoryService.getLowStockProducts();
      
      return {
        'totalPurchases': {
          'amount': totalPurchasesAmount,
          'quantity': totalPurchasesQuantity,
        },
        'totalSales': {
          'amount': totalSalesAmount,
          'quantity': totalSalesQuantity,
        },
        'profit': profit,
        'currentStockValue': currentStockValue,
        'lowStockProductsCount': lowStockProducts.length,
        'lowStockProducts': lowStockProducts.map((p) => {
          'id': p.id,
          'name': p.name,
          'currentStock': p.currentStock,
          'category': p.category,
        }).toList(),
      };
    } catch (e) {
      throw Exception('Failed to get dashboard summary: $e');
    }
  }

  /// Get total purchases (amount and quantity)
  Future<Map<String, dynamic>> getTotalPurchases({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final amount = await _inventoryService.getTotalPurchasesAmount(
        startDate: startDate,
        endDate: endDate,
      );
      final quantity = await _inventoryService.getTotalPurchasesQuantity(
        startDate: startDate,
        endDate: endDate,
      );
      
      return {
        'amount': amount,
        'quantity': quantity,
      };
    } catch (e) {
      throw Exception('Failed to get total purchases: $e');
    }
  }

  /// Get total sales (amount and quantity)
  Future<Map<String, dynamic>> getTotalSales({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final amount = await _inventoryService.getTotalSalesAmount(
        startDate: startDate,
        endDate: endDate,
      );
      final quantity = await _inventoryService.getTotalSalesQuantity(
        startDate: startDate,
        endDate: endDate,
      );
      
      return {
        'amount': amount,
        'quantity': quantity,
      };
    } catch (e) {
      throw Exception('Failed to get total sales: $e');
    }
  }

  /// Get profit
  Future<double> getProfit({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      return await _inventoryService.getProfit(
        startDate: startDate,
        endDate: endDate,
      );
    } catch (e) {
      throw Exception('Failed to get profit: $e');
    }
  }

  /// Get current stock value
  Future<double> getCurrentStockValue() async {
    try {
      return await _inventoryService.getCurrentStockValue();
    } catch (e) {
      throw Exception('Failed to get current stock value: $e');
    }
  }

  /// Get low stock products
  Future<List<Product>> getLowStockProducts({int threshold = 10}) async {
    try {
      return await _inventoryService.getLowStockProducts(threshold: threshold);
    } catch (e) {
      throw Exception('Failed to get low stock products: $e');
    }
  }

  /// Get all products
  Future<List<Product>> getAllProducts() async {
    try {
      return await _inventoryService.getAllProducts();
    } catch (e) {
      throw Exception('Failed to get all products: $e');
    }
  }
}

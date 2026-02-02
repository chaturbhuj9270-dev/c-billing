import 'package:c_billing/features/inventory_management/domain/entities/product.dart';
import 'package:c_billing/features/inventory_management/domain/entities/purchase.dart';
import 'package:c_billing/features/inventory_management/domain/entities/stock.dart';
import 'package:c_billing/features/inventory_management/domain/repositories/product_repository.dart';
import 'package:c_billing/features/inventory_management/domain/repositories/purchase_repository.dart';
import 'package:c_billing/features/inventory_management/domain/repositories/stock_repository.dart';

class InventoryService {
  final ProductRepository _productRepository;
  final StockRepository _stockRepository;
  final PurchaseRepository _purchaseRepository;

  InventoryService({
    required ProductRepository productRepository,
    required StockRepository stockRepository,
    required PurchaseRepository purchaseRepository,
  })  : _productRepository = productRepository,
        _stockRepository = stockRepository,
        _purchaseRepository = purchaseRepository;

  // ==================== Purchase Operations ====================

  /// Process a purchase and update inventory
  Future<String> processPurchase({
    required String productId,
    required int quantity,
    required double purchasePrice,
    String? notes,
  }) async {
    try {
      // Get product
      final product = await _productRepository.getProductById(productId);
      if (product == null) {
        throw Exception('Product not found');
      }

      // Validate quantity
      if (quantity <= 0) {
        throw Exception('Quantity must be greater than 0');
      }

      // Validate price
      if (purchasePrice < 0) {
        throw Exception('Purchase price cannot be negative');
      }

      // Create purchase record
      final totalAmount = quantity * purchasePrice;
      final now = DateTime.now();
      
      final purchase = Purchase(
        id: '',
        productId: productId,
        quantity: quantity,
        purchasePrice: purchasePrice,
        totalAmount: totalAmount,
        notes: notes,
        createdAt: now,
        updatedAt: now,
      );

      final purchaseId = await _purchaseRepository.addPurchase(purchase);

      // Update product stock
      final newStock = product.currentStock + quantity;
      await _productRepository.updateProductStock(productId, newStock);

      // Create stock entry
      final stockEntry = Stock(
        id: '',
        productId: productId,
        quantityIn: quantity,
        quantityOut: 0,
        balanceQuantity: newStock,
        referenceType: ReferenceType.PURCHASE,
        referenceId: purchaseId,
        createdAt: now,
      );

      await _stockRepository.createStockEntry(stockEntry);

      return purchaseId;
    } catch (e) {
      throw Exception('Failed to process purchase: $e');
    }
  }

  // ==================== Sales Operations ====================

  /// Process a sale and update inventory
  Future<String> processSale({
    required String productId,
    required int quantity,
    String? referenceId,
  }) async {
    try {
      // Get product
      final product = await _productRepository.getProductById(productId);
      if (product == null) {
        throw Exception('Product not found');
      }

      // Validate quantity
      if (quantity <= 0) {
        throw Exception('Quantity must be greater than 0');
      }

      // Check stock availability
      if (product.currentStock < quantity) {
        throw Exception(
          'Insufficient stock. Available: ${product.currentStock}, Requested: $quantity',
        );
      }

      // Update product stock
      final newStock = product.currentStock - quantity;
      await _productRepository.updateProductStock(productId, newStock);

      // Create stock entry
      final now = DateTime.now();
      final saleId = referenceId ?? 'SALE_${now.millisecondsSinceEpoch}';
      
      final stockEntry = Stock(
        id: '',
        productId: productId,
        quantityIn: 0,
        quantityOut: quantity,
        balanceQuantity: newStock,
        referenceType: ReferenceType.SALE,
        referenceId: saleId,
        createdAt: now,
      );

      final stockId = await _stockRepository.createStockEntry(stockEntry);
      return stockId;
    } catch (e) {
      throw Exception('Failed to process sale: $e');
    }
  }

  // ==================== Dashboard Metrics ====================

  /// Get total purchases amount
  Future<double> getTotalPurchasesAmount({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      return await _purchaseRepository.getTotalPurchaseAmount(
        startDate: startDate,
        endDate: endDate,
      );
    } catch (e) {
      throw Exception('Failed to get total purchases amount: $e');
    }
  }

  /// Get total purchases quantity
  Future<int> getTotalPurchasesQuantity({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      return await _purchaseRepository.getTotalPurchaseQuantity(
        startDate: startDate,
        endDate: endDate,
      );
    } catch (e) {
      throw Exception('Failed to get total purchases quantity: $e');
    }
  }

  /// Get total sales amount (from sales stock entries)
  Future<double> getTotalSalesAmount({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final salesStocks = await _stockRepository.getStockByReferenceType('SALE');
      
      double total = 0;
      for (var stock in salesStocks) {
        final createdAt = stock.createdAt;
        
        // Filter by date range if provided
        if (startDate != null && createdAt.isBefore(startDate)) continue;
        if (endDate != null && createdAt.isAfter(endDate)) continue;

        // Get product to get sales price
        final product = await _productRepository.getProductById(stock.productId);
        if (product != null) {
          total += stock.quantityOut * product.salesPrice;
        }
      }
      return total;
    } catch (e) {
      throw Exception('Failed to get total sales amount: $e');
    }
  }

  /// Get total sales quantity (from sales stock entries)
  Future<int> getTotalSalesQuantity({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final salesStocks = await _stockRepository.getStockByReferenceType('SALE');
      
      int total = 0;
      for (var stock in salesStocks) {
        final createdAt = stock.createdAt;
        
        // Filter by date range if provided
        if (startDate != null && createdAt.isBefore(startDate)) continue;
        if (endDate != null && createdAt.isAfter(endDate)) continue;

        total += stock.quantityOut;
      }
      return total;
    } catch (e) {
      throw Exception('Failed to get total sales quantity: $e');
    }
  }

  /// Get profit (total sales - total purchases)
  Future<double> getProfit({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final salesAmount = await getTotalSalesAmount(
        startDate: startDate,
        endDate: endDate,
      );
      final purchaseAmount = await getTotalPurchasesAmount(
        startDate: startDate,
        endDate: endDate,
      );
      return salesAmount - purchaseAmount;
    } catch (e) {
      throw Exception('Failed to calculate profit: $e');
    }
  }

  /// Get current stock value (based on purchase price)
  Future<double> getCurrentStockValue() async {
    try {
      final products = await _productRepository.getAllProducts();
      double totalValue = 0;
      for (var product in products) {
        totalValue += product.getStockValue();
      }
      return totalValue;
    } catch (e) {
      throw Exception('Failed to get current stock value: $e');
    }
  }

  /// Get low stock products
  Future<List<Product>> getLowStockProducts({int threshold = 10}) async {
    try {
      return await _productRepository.getLowStockProducts(threshold: threshold);
    } catch (e) {
      throw Exception('Failed to get low stock products: $e');
    }
  }

  // ==================== Product Management ====================

  /// Create a new product
  Future<String> createProduct({
    required String name,
    required String category,
    required double purchasePrice,
    required double salesPrice,
    int initialStock = 0,
  }) async {
    try {
      // Validate inputs
      if (name.isEmpty) throw Exception('Product name cannot be empty');
      if (category.isEmpty) throw Exception('Category cannot be empty');
      if (purchasePrice < 0) throw Exception('Purchase price cannot be negative');
      if (salesPrice < 0) throw Exception('Sales price cannot be negative');
      if (initialStock < 0) throw Exception('Initial stock cannot be negative');

      final now = DateTime.now();
      final product = Product(
        id: '',
        name: name,
        category: category,
        purchasePrice: purchasePrice,
        salesPrice: salesPrice,
        currentStock: initialStock,
        createdAt: now,
        updatedAt: now,
      );

      return await _productRepository.addProduct(product);
    } catch (e) {
      throw Exception('Failed to create product: $e');
    }
  }

  /// Get all products
  Future<List<Product>> getAllProducts() async {
    try {
      return await _productRepository.getAllProducts();
    } catch (e) {
      throw Exception('Failed to get products: $e');
    }
  }

  /// Get product by ID
  Future<Product?> getProductById(String id) async {
    try {
      return await _productRepository.getProductById(id);
    } catch (e) {
      throw Exception('Failed to get product: $e');
    }
  }

  /// Update product
  Future<void> updateProduct(Product product) async {
    try {
      final updatedProduct = product.copyWith(
        updatedAt: DateTime.now(),
      );
      await _productRepository.updateProduct(updatedProduct);
    } catch (e) {
      throw Exception('Failed to update product: $e');
    }
  }

  /// Get stock history for a product
  Future<List<Stock>> getProductStockHistory(String productId) async {
    try {
      return await _stockRepository.getStockByProductId(productId);
    } catch (e) {
      throw Exception('Failed to get stock history: $e');
    }
  }
}

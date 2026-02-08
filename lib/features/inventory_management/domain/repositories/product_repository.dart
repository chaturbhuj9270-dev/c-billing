import '../entities/product.dart';

abstract class ProductRepository {
  // Create
  Future<String> addProduct(Product product);

  // Read
  Future<Product?> getProductById(String id);
  Future<List<Product>> getAllProducts();
  Future<List<Product>> getProductsByCategory(String category);

  // Update
  Future<void> updateProduct(Product product);
  Future<void> updateProductStock(String productId, int newStock);

  // Delete
  Future<void> deleteProduct(String id);

  // Query
  Future<List<Product>> getLowStockProducts({int threshold = 10});
  Future<List<String>> getAllCategories();
}

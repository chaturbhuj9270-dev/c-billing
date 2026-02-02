import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/product.dart';
import '../../domain/repositories/product_repository.dart';

class FirebaseProductRepository implements ProductRepository {
  final FirebaseFirestore _firestore;
  final String _collection = 'products';

  FirebaseProductRepository({required FirebaseFirestore firestore})
      : _firestore = firestore;

  @override
  Future<String> addProduct(Product product) async {
    try {
      final docRef = await _firestore.collection(_collection).add(
            product.copyWith(id: '').toJson(),
          );
      
      // Update document with its ID
      await docRef.update({'id': docRef.id});
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to add product: $e');
    }
  }

  @override
  Future<Product?> getProductById(String id) async {
    try {
      final doc = await _firestore.collection(_collection).doc(id).get();
      if (doc.exists) {
        return Product.fromJson(doc.data()!);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get product: $e');
    }
  }

  @override
  Future<List<Product>> getAllProducts() async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .orderBy('createdAt', descending: true)
          .get();
      return snapshot.docs
          .map((doc) => Product.fromJson(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Failed to get all products: $e');
    }
  }

  @override
  Future<List<Product>> getProductsByCategory(String category) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('category', isEqualTo: category)
          .orderBy('name')
          .get();
      return snapshot.docs
          .map((doc) => Product.fromJson(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Failed to get products by category: $e');
    }
  }

  @override
  Future<void> updateProduct(Product product) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(product.id)
          .update(product.toJson());
    } catch (e) {
      throw Exception('Failed to update product: $e');
    }
  }

  @override
  Future<void> updateProductStock(String productId, int newStock) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(productId)
          .update({
        'currentStock': newStock,
        'updatedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Failed to update product stock: $e');
    }
  }

  @override
  Future<void> deleteProduct(String id) async {
    try {
      await _firestore.collection(_collection).doc(id).delete();
    } catch (e) {
      throw Exception('Failed to delete product: $e');
    }
  }

  @override
  Future<List<Product>> getLowStockProducts({int threshold = 10}) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('currentStock', isLessThanOrEqualTo: threshold)
          .orderBy('currentStock')
          .get();
      return snapshot.docs
          .map((doc) => Product.fromJson(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Failed to get low stock products: $e');
    }
  }

  @override
  Future<List<String>> getAllCategories() async {
    try {
      final snapshot = await _firestore.collection(_collection).get();
      final categories = <String>{};
      for (var doc in snapshot.docs) {
        final category = doc.data()['category'] as String?;
        if (category != null && category.isNotEmpty) {
          categories.add(category);
        }
      }
      return categories.toList()..sort();
    } catch (e) {
      throw Exception('Failed to get all categories: $e');
    }
  }
}

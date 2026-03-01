import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../domain/entities/product.dart';
import '../../domain/repositories/product_repository.dart';

class FirebaseProductRepository implements ProductRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final String _collection = 'products';

  FirebaseProductRepository({
    required FirebaseFirestore firestore,
    FirebaseAuth? auth,
  }) : _firestore = firestore,
       _auth = auth ?? FirebaseAuth.instance;

  String get _userId {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }
    return user.uid;
  }

  CollectionReference get _productsCollection {
    return _firestore.collection('users').doc(_userId).collection(_collection);
  }

  @override
  Future<String> addProduct(Product product) async {
    try {
      final docRef = await _productsCollection.add(
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
      final doc = await _productsCollection.doc(id).get();
      if (doc.exists) {
        return Product.fromJson(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get product: $e');
    }
  }

  @override
  Future<List<Product>> getAllProducts() async {
    try {
      try {
        // Try to get products ordered by createdAt
        final snapshot = await _productsCollection
            .orderBy('createdAt', descending: true)
            .get();
        return snapshot.docs
            .map((doc) => Product.fromJson(doc.data() as Map<String, dynamic>))
            .toList();
      } catch (e) {
        // If ordering fails (e.g., missing index), get without ordering
        if (e.toString().contains('index') ||
            e.toString().contains('FAILED_PRECONDITION')) {
          print(
            '[DEBUG] Composite index not found, getting products without ordering',
          );
          final snapshot = await _productsCollection.get();
          final products = snapshot.docs
              .map(
                (doc) => Product.fromJson(doc.data() as Map<String, dynamic>),
              )
              .toList();
          // Sort client-side by createdAt descending
          products.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return products;
        } else {
          rethrow;
        }
      }
    } catch (e) {
      throw Exception('Failed to get all products: $e');
    }
  }

  @override
  Future<List<Product>> getProductsByCategory(String category) async {
    try {
      try {
        final snapshot = await _productsCollection
            .where('category', isEqualTo: category)
            .orderBy('name')
            .get();
        return snapshot.docs
            .map((doc) => Product.fromJson(doc.data() as Map<String, dynamic>))
            .toList();
      } catch (e) {
        // Fallback if index not available
        if (e.toString().contains('index') ||
            e.toString().contains('FAILED_PRECONDITION')) {
          print(
            '[DEBUG] Composite index not found, getting products without ordering',
          );
          final snapshot = await _productsCollection
              .where('category', isEqualTo: category)
              .get();
          final products = snapshot.docs
              .map(
                (doc) => Product.fromJson(doc.data() as Map<String, dynamic>),
              )
              .toList();
          products.sort((a, b) => a.name.compareTo(b.name));
          return products;
        } else {
          rethrow;
        }
      }
    } catch (e) {
      throw Exception('Failed to get products by category: $e');
    }
  }

  @override
  Future<void> updateProduct(Product product) async {
    try {
      await _productsCollection.doc(product.id).update(product.toJson());
    } catch (e) {
      throw Exception('Failed to update product: $e');
    }
  }

  @override
  Future<void> updateProductStock(String productId, int newStock) async {
    try {
      await _productsCollection.doc(productId).update({
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
      await _productsCollection.doc(id).delete();
    } catch (e) {
      throw Exception('Failed to delete product: $e');
    }
  }

  @override
  Future<List<Product>> getLowStockProducts({int threshold = 10}) async {
    try {
      try {
        final snapshot = await _productsCollection
            .where('currentStock', isLessThanOrEqualTo: threshold)
            .orderBy('currentStock')
            .get();
        return snapshot.docs
            .map((doc) => Product.fromJson(doc.data() as Map<String, dynamic>))
            .toList();
      } catch (e) {
        // Fallback if index not available
        if (e.toString().contains('index') ||
            e.toString().contains('FAILED_PRECONDITION')) {
          print(
            '[DEBUG] Composite index not found, getting low stock products without ordering',
          );
          final snapshot = await _productsCollection
              .where('currentStock', isLessThanOrEqualTo: threshold)
              .get();
          final products = snapshot.docs
              .map(
                (doc) => Product.fromJson(doc.data() as Map<String, dynamic>),
              )
              .toList();
          products.sort((a, b) => a.currentStock.compareTo(b.currentStock));
          return products;
        } else {
          rethrow;
        }
      }
    } catch (e) {
      throw Exception('Failed to get low stock products: $e');
    }
  }

  @override
  Future<List<String>> getAllCategories() async {
    try {
      final snapshot = await _productsCollection.get();
      final categories = <String>{};
      for (var doc in snapshot.docs) {
        final category =
            (doc.data() as Map<String, dynamic>)['category'] as String?;
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

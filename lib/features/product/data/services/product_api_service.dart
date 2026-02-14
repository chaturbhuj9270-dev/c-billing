import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// API Service for Product data operations with Firebase
/// Handles all remote server communication for products
class ProductApiService {
  static ProductApiService? _instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  ProductApiService._({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  /// Get the singleton instance
  static ProductApiService get instance {
    _instance ??= ProductApiService._();
    return _instance!;
  }

  /// Get current user ID
  String? get _userId => _auth.currentUser?.uid;

  /// Get products collection reference for current user
  CollectionReference<Map<String, dynamic>>? get _productsRef {
    final userId = _userId;
    if (userId == null) return null;
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('products');
  }

  /// Ensure user is authenticated
  void _ensureAuthenticated() {
    if (_userId == null) {
      throw Exception('User not authenticated');
    }
  }

  /// Fetch all products from server
  /// If [updatedSince] is provided, only fetch products updated after that time
  Future<List<Map<String, dynamic>>> getProducts({
    DateTime? updatedSince,
  }) async {
    _ensureAuthenticated();
    
    try {
      Query<Map<String, dynamic>> query = _productsRef!;

      // Filter by updatedSince for incremental sync
      if (updatedSince != null) {
        query = query.where(
          'updatedAt',
          isGreaterThan: updatedSince.toIso8601String(),
        );
      }

      // Order by updatedAt for consistent results
      query = query.orderBy('updatedAt', descending: true);

      final snapshot = await query.get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id; // Include document ID
        return data;
      }).toList();
    } catch (e) {
      debugPrint('[ProductAPI] Error fetching products: $e');
      rethrow;
    }
  }

  /// Get a single product by ID
  Future<Map<String, dynamic>?> getProduct(String id) async {
    _ensureAuthenticated();
    
    try {
      final doc = await _productsRef!.doc(id).get();
      if (!doc.exists) return null;

      final data = doc.data()!;
      data['id'] = doc.id;
      return data;
    } catch (e) {
      debugPrint('[ProductAPI] Error fetching product $id: $e');
      rethrow;
    }
  }

  /// Create a new product on the server
  /// Returns the server response with the new document ID
  Future<Map<String, dynamic>> createProduct(Map<String, dynamic> productData) async {
    _ensureAuthenticated();
    
    try {
      // Remove local-only fields
      final payload = Map<String, dynamic>.from(productData);
      payload.remove('id'); // Remove if empty or local
      payload.remove('localId');
      payload.remove('syncStatus');
      payload.remove('isSynced');
      
      // Ensure server timestamps
      payload['createdAt'] = FieldValue.serverTimestamp();
      payload['updatedAt'] = FieldValue.serverTimestamp();

      final docRef = await _productsRef!.add(payload);
      
      debugPrint('[ProductAPI] Product created with ID: ${docRef.id}');
      
      // Fetch the created document to return complete data
      final doc = await docRef.get();
      final data = doc.data()!;
      data['id'] = doc.id;
      
      return data;
    } catch (e) {
      debugPrint('[ProductAPI] Error creating product: $e');
      rethrow;
    }
  }

  /// Update an existing product on the server
  Future<Map<String, dynamic>> updateProduct(String id, Map<String, dynamic> productData) async {
    _ensureAuthenticated();
    
    try {
      // Remove local-only fields
      final payload = Map<String, dynamic>.from(productData);
      payload.remove('id');
      payload.remove('localId');
      payload.remove('syncStatus');
      payload.remove('isSynced');
      
      // Update timestamp
      payload['updatedAt'] = FieldValue.serverTimestamp();

      await _productsRef!.doc(id).update(payload);
      
      debugPrint('[ProductAPI] Product updated: $id');
      
      // Fetch the updated document
      final doc = await _productsRef!.doc(id).get();
      final data = doc.data()!;
      data['id'] = doc.id;
      
      return data;
    } catch (e) {
      debugPrint('[ProductAPI] Error updating product $id: $e');
      rethrow;
    }
  }

  /// Delete a product from the server
  Future<void> deleteProduct(String id) async {
    _ensureAuthenticated();
    
    try {
      await _productsRef!.doc(id).delete();
      debugPrint('[ProductAPI] Product deleted: $id');
    } catch (e) {
      debugPrint('[ProductAPI] Error deleting product $id: $e');
      rethrow;
    }
  }

  /// Check if a product with the given barcode exists on server
  Future<bool> barcodeExists(String barcode, {String? excludeId}) async {
    _ensureAuthenticated();
    
    try {
      final query = _productsRef!.where('barcode', isEqualTo: barcode);
      final snapshot = await query.get();
      
      if (snapshot.docs.isEmpty) return false;
      if (excludeId == null) return true;
      
      // Check if any doc has different ID
      return snapshot.docs.any((doc) => doc.id != excludeId);
    } catch (e) {
      debugPrint('[ProductAPI] Error checking barcode exists: $e');
      return false;
    }
  }

  /// Get products count on server
  Future<int> getProductsCount() async {
    _ensureAuthenticated();
    
    try {
      final snapshot = await _productsRef!.count().get();
      return snapshot.count ?? 0;
    } catch (e) {
      debugPrint('[ProductAPI] Error getting products count: $e');
      return 0;
    }
  }

  /// Search products by name (server-side)
  Future<List<Map<String, dynamic>>> searchProducts(String query) async {
    _ensureAuthenticated();
    
    try {
      // Firebase doesn't support full-text search well
      // This searches by exact prefix match on name
      final snapshot = await _productsRef!
          .where('name', isGreaterThanOrEqualTo: query)
          .where('name', isLessThanOrEqualTo: '$query\uf8ff')
          .limit(50)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      debugPrint('[ProductAPI] Error searching products: $e');
      rethrow;
    }
  }

  /// Get products by category
  Future<List<Map<String, dynamic>>> getProductsByCategory(String category) async {
    _ensureAuthenticated();
    
    try {
      final snapshot = await _productsRef!
          .where('category', isEqualTo: category)
          .orderBy('name')
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      debugPrint('[ProductAPI] Error getting products by category: $e');
      rethrow;
    }
  }

  /// Batch create products (for bulk import)
  Future<List<String>> batchCreateProducts(List<Map<String, dynamic>> products) async {
    _ensureAuthenticated();
    
    try {
      final batch = _firestore.batch();
      final docRefs = <DocumentReference>[];

      for (final product in products) {
        final payload = Map<String, dynamic>.from(product);
        payload.remove('id');
        payload.remove('localId');
        payload.remove('syncStatus');
        payload['createdAt'] = FieldValue.serverTimestamp();
        payload['updatedAt'] = FieldValue.serverTimestamp();

        final docRef = _productsRef!.doc();
        docRefs.add(docRef);
        batch.set(docRef, payload);
      }

      await batch.commit();
      debugPrint('[ProductAPI] Batch created ${docRefs.length} products');
      return docRefs.map((ref) => ref.id).toList();
    } catch (e) {
      debugPrint('[ProductAPI] Error batch creating products: $e');
      rethrow;
    }
  }

  /// Batch update products
  Future<void> batchUpdateProducts(Map<String, Map<String, dynamic>> updates) async {
    _ensureAuthenticated();
    
    try {
      final batch = _firestore.batch();

      for (final entry in updates.entries) {
        final payload = Map<String, dynamic>.from(entry.value);
        payload.remove('id');
        payload.remove('localId');
        payload.remove('syncStatus');
        payload['updatedAt'] = FieldValue.serverTimestamp();

        batch.update(_productsRef!.doc(entry.key), payload);
      }

      await batch.commit();
      debugPrint('[ProductAPI] Batch updated ${updates.length} products');
    } catch (e) {
      debugPrint('[ProductAPI] Error batch updating products: $e');
      rethrow;
    }
  }

  /// Batch delete products
  Future<void> batchDeleteProducts(List<String> ids) async {
    _ensureAuthenticated();
    
    try {
      final batch = _firestore.batch();

      for (final id in ids) {
        batch.delete(_productsRef!.doc(id));
      }

      await batch.commit();
      debugPrint('[ProductAPI] Batch deleted ${ids.length} products');
    } catch (e) {
      debugPrint('[ProductAPI] Error batch deleting products: $e');
      rethrow;
    }
  }
}

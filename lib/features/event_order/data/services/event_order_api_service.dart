import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// API Service for Event Order data operations with Firebase
/// Handles all remote server communication for event orders
class EventOrderApiService {
  static EventOrderApiService? _instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  EventOrderApiService._({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  /// Get the singleton instance
  static EventOrderApiService get instance {
    _instance ??= EventOrderApiService._();
    return _instance!;
  }

  /// Get current user ID
  String? get _userId => _auth.currentUser?.uid;

  /// Check if user is authenticated
  bool get isAuthenticated => _userId != null;

  /// Get event orders collection reference for current user
  CollectionReference<Map<String, dynamic>>? get _eventOrdersRef {
    final userId = _userId;
    if (userId == null) return null;
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('eventOrders');
  }

  /// Ensure user is authenticated
  void _ensureAuthenticated() {
    if (_userId == null) {
      throw Exception('User not authenticated');
    }
  }

  /// Fetch all event orders from server
  /// If [updatedSince] is provided, only fetch orders updated after that time
  Future<List<Map<String, dynamic>>> getEventOrders({
    DateTime? updatedSince,
  }) async {
    _ensureAuthenticated();
    
    try {
      Query<Map<String, dynamic>> query = _eventOrdersRef!;

      // Filter by updatedSince for incremental sync
      if (updatedSince != null) {
        query = query.where('updatedAt', isGreaterThan: updatedSince.toIso8601String());
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
      debugPrint('[EventOrderAPI] Error fetching event orders: $e');
      rethrow;
    }
  }

  /// Get a single event order by ID
  Future<Map<String, dynamic>?> getEventOrder(String id) async {
    _ensureAuthenticated();
    
    try {
      final doc = await _eventOrdersRef!.doc(id).get();
      if (!doc.exists) return null;

      final data = doc.data()!;
      data['id'] = doc.id;
      return data;
    } catch (e) {
      debugPrint('[EventOrderAPI] Error fetching event order $id: $e');
      rethrow;
    }
  }

  /// Create a new event order on the server
  /// Returns the server response with the new document ID
  Future<Map<String, dynamic>> createEventOrder(Map<String, dynamic> orderData) async {
    _ensureAuthenticated();
    
    try {
      // Remove local-only fields
      final payload = Map<String, dynamic>.from(orderData);
      payload.remove('id');
      payload.remove('localId');
      payload.remove('syncStatus');
      
      // Ensure server timestamps
      payload['createdAt'] = FieldValue.serverTimestamp();
      payload['updatedAt'] = FieldValue.serverTimestamp();

      final docRef = await _eventOrdersRef!.add(payload);
      
      debugPrint('[EventOrderAPI] Event order created with ID: ${docRef.id}');
      
      // Fetch the created document to return complete data
      final doc = await docRef.get();
      final data = doc.data()!;
      data['id'] = doc.id;
      
      return data;
    } catch (e) {
      debugPrint('[EventOrderAPI] Error creating event order: $e');
      rethrow;
    }
  }

  /// Update an existing event order on the server
  Future<Map<String, dynamic>> updateEventOrder(String id, Map<String, dynamic> orderData) async {
    _ensureAuthenticated();
    
    try {
      // Remove local-only fields
      final payload = Map<String, dynamic>.from(orderData);
      payload.remove('id');
      payload.remove('localId');
      payload.remove('syncStatus');
      
      // Update timestamp
      payload['updatedAt'] = FieldValue.serverTimestamp();

      await _eventOrdersRef!.doc(id).update(payload);
      
      debugPrint('[EventOrderAPI] Event order updated: $id');
      
      // Fetch the updated document
      final doc = await _eventOrdersRef!.doc(id).get();
      final data = doc.data()!;
      data['id'] = doc.id;
      
      return data;
    } catch (e) {
      debugPrint('[EventOrderAPI] Error updating event order $id: $e');
      rethrow;
    }
  }

  /// Delete an event order from server
  Future<void> deleteEventOrder(String id) async {
    _ensureAuthenticated();
    
    try {
      await _eventOrdersRef!.doc(id).delete();
      debugPrint('[EventOrderAPI] Event order deleted: $id');
    } catch (e) {
      debugPrint('[EventOrderAPI] Error deleting event order $id: $e');
      rethrow;
    }
  }
}

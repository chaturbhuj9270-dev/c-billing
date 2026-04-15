import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class MenuApiService {
  static MenuApiService? _instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  MenuApiService._({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  static MenuApiService get instance {
    _instance ??= MenuApiService._();
    return _instance!;
  }

  String? get _userId => _auth.currentUser?.uid;

  CollectionReference<Map<String, dynamic>> get _menuRef {
    final userId = _userId;
    if (userId == null) throw StateError('User not authenticated');
    return _firestore.collection('users').doc(userId).collection('menuItems');
  }

  Future<String> createMenuItem(Map<String, dynamic> data) async {
    final cleanData = Map<String, dynamic>.from(data)..remove('id');
    final docRef = await _menuRef.add({
      ...cleanData,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    debugPrint('[MenuAPI] Created: ${docRef.id}');
    return docRef.id;
  }

  Future<void> updateMenuItem(
    String serverId,
    Map<String, dynamic> data,
  ) async {
    final cleanData = Map<String, dynamic>.from(data)..remove('id');
    await _menuRef.doc(serverId).update({
      ...cleanData,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    debugPrint('[MenuAPI] Updated: $serverId');
  }

  Future<void> deleteMenuItem(String serverId) async {
    await _menuRef.doc(serverId).delete();
    debugPrint('[MenuAPI] Deleted: $serverId');
  }

  Future<List<Map<String, dynamic>>> getMenuItems() async {
    debugPrint('[MenuAPI] Fetching menu items for user: $_userId');
    final snapshot = await _menuRef
        .orderBy('createdAt', descending: true)
        .get();
    return snapshot.docs.map((doc) => {...doc.data(), 'id': doc.id}).toList();
  }

  Future<List<Map<String, dynamic>>> getMenuItemsSince(DateTime since) async {
    final snapshot = await _menuRef
        .where('updatedAt', isGreaterThan: Timestamp.fromDate(since))
        .get();
    return snapshot.docs.map((doc) => {...doc.data(), 'id': doc.id}).toList();
  }

  bool get isAuthenticated => _userId != null;
}

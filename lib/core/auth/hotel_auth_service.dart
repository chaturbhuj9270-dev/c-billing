import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'hotel_roles.dart';
import 'hotel_sub_user.dart';

/// Manages the current Hotel user session and permissions.
/// Admin users have full access; sub-users are restricted to allowed modules.
class HotelAuthService extends ChangeNotifier {
  static final HotelAuthService _instance = HotelAuthService._internal();
  static HotelAuthService get instance => _instance;
  HotelAuthService._internal();

  HotelSubUser? _currentSubUser;
  bool _isAdmin = true;

  HotelSubUser? get currentSubUser => _currentSubUser;
  bool get isAdmin => _isAdmin;

  /// Set the current session as admin (the Firebase-authenticated user).
  void setAdminSession() {
    _isAdmin = true;
    _currentSubUser = null;
    notifyListeners();
  }

  /// Set the current session as a sub-user.
  void setSubUserSession(HotelSubUser subUser) {
    _isAdmin = false;
    _currentSubUser = subUser;
    notifyListeners();
  }

  /// Check if current user can access a given module.
  bool hasAccess(HotelModule module) {
    if (_isAdmin) return true;
    return _currentSubUser?.hasAccessTo(module) ?? false;
  }

  /// Clear the session on logout.
  void clearSession() {
    _isAdmin = true;
    _currentSubUser = null;
    notifyListeners();
  }

  // ==================== FIRESTORE CRUD FOR SUB-USERS ====================

  CollectionReference<Map<String, dynamic>> _subUsersCollection() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw StateError('No authenticated user');
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('hotelSubUsers');
  }

  /// Create a new sub-user.
  Future<HotelSubUser> createSubUser({
    required String name,
    required String email,
    required String phone,
    required String pin,
    required HotelUserRole role,
    required List<HotelModule> allowedModules,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final docRef = _subUsersCollection().doc();
    final now = DateTime.now();

    final subUser = HotelSubUser(
      id: docRef.id,
      adminUid: uid,
      name: name,
      email: email,
      phone: phone,
      pin: pin,
      role: role,
      allowedModules: role == HotelUserRole.admin
          ? HotelModule.values
          : allowedModules,
      isActive: true,
      createdAt: now,
      updatedAt: now,
    );

    await docRef.set(subUser.toJson());
    return subUser;
  }

  /// Update an existing sub-user.
  Future<void> updateSubUser(HotelSubUser subUser) async {
    final updated = subUser.copyWith(updatedAt: DateTime.now());
    await _subUsersCollection().doc(subUser.id).update(updated.toJson());
  }

  /// Delete (deactivate) a sub-user.
  Future<void> deactivateSubUser(String id) async {
    await _subUsersCollection().doc(id).update({
      'isActive': false,
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  /// Get all sub-users for the current admin.
  Future<List<HotelSubUser>> getSubUsers() async {
    final snapshot = await _subUsersCollection()
        .orderBy('createdAt', descending: true)
        .get();
    return snapshot.docs
        .map((doc) => HotelSubUser.fromJson(doc.data()))
        .toList();
  }

  /// Stream of sub-users for real-time UI updates.
  Stream<List<HotelSubUser>> watchSubUsers() {
    return _subUsersCollection()
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map((d) => HotelSubUser.fromJson(d.data())).toList(),
        );
  }

  /// Validate PIN for sub-user quick login.
  Future<HotelSubUser?> authenticateByPin(String pin) async {
    final snapshot = await _subUsersCollection()
        .where('pin', isEqualTo: pin)
        .where('isActive', isEqualTo: true)
        .limit(1)
        .get();
    if (snapshot.docs.isEmpty) return null;
    return HotelSubUser.fromJson(snapshot.docs.first.data());
  }
}

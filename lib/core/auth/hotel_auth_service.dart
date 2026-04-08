import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
    final uid = FirebaseAuth.instance.currentUser?.uid;
    _isAdmin = true;
    _currentSubUser = null;
    notifyListeners();
    // Clear cached role so next login does a fresh check
    if (uid != null) {
      SharedPreferences.getInstance().then((prefs) {
        prefs.remove('hotel_role_$uid');
        prefs.remove('hotel_sub_admin_$uid');
        prefs.remove('hotel_sub_id_$uid');
      });
    }
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

  /// After Firebase login, detect whether the logged-in user is an admin
  /// or a sub-user.
  ///
  /// Fast path: admins always have a `users/{uid}` document. If it exists →
  /// admin. Only falls back to the slower collectionGroup query when the
  /// doc is missing (i.e. the user is a sub-user).
  ///
  /// Results are cached in SharedPreferences so subsequent logins are instant.
  Future<void> resolveSessionAfterLogin() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setAdminSession();
      return;
    }

    try {
      // ── 1. Check cache first (instant) ──
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = 'hotel_role_${user.uid}';
      final cached = prefs.getString(cacheKey);

      if (cached == 'admin') {
        setAdminSession();
        debugPrint('[HotelAuth] Cached → admin');
        return;
      }

      if (cached == 'sub_user') {
        // Load sub-user details from Firestore (still faster than collectionGroup)
        final subUser = await _loadCachedSubUser(user.uid);
        if (subUser != null) {
          setSubUserSession(subUser);
          debugPrint('[HotelAuth] Cached → sub-user: ${subUser.name}');
          return;
        }
        // Cache stale — fall through to fresh check
      }

      // ── 2. Fast check: does users/{uid} doc exist? ──
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (userDoc.exists) {
        // Admin — cache and return
        await prefs.setString(cacheKey, 'admin');
        setAdminSession();
        debugPrint('[HotelAuth] Admin (doc exists): ${user.uid}');
        return;
      }

      // ── 3. Not an admin doc → must be a sub-user ──
      final result = await FirebaseFirestore.instance
          .collectionGroup('hotelSubUsers')
          .where('firebaseUid', isEqualTo: user.uid)
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get()
          .timeout(const Duration(seconds: 4));

      if (result.docs.isNotEmpty) {
        final subUser = HotelSubUser.fromJson(result.docs.first.data());
        await prefs.setString(cacheKey, 'sub_user');
        // Cache the admin UID so we can reload sub-user data quickly
        await prefs.setString('hotel_sub_admin_${user.uid}', subUser.adminUid);
        await prefs.setString('hotel_sub_id_${user.uid}', subUser.id);
        setSubUserSession(subUser);
        debugPrint(
          '[HotelAuth] Sub-user: ${subUser.name} (${subUser.role.label})',
        );
      } else {
        // No admin doc AND no sub-user doc — treat as admin (new user)
        await prefs.setString(cacheKey, 'admin');
        setAdminSession();
        debugPrint('[HotelAuth] No records found, defaulting to admin');
      }
    } catch (e) {
      debugPrint('[HotelAuth] resolveSession error: $e — defaulting to admin');
      setAdminSession();
    }
  }

  /// Reload a cached sub-user's data using stored admin UID + sub-user ID.
  Future<HotelSubUser?> _loadCachedSubUser(String userUid) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final adminUid = prefs.getString('hotel_sub_admin_$userUid');
      final subId = prefs.getString('hotel_sub_id_$userUid');
      if (adminUid == null || subId == null) return null;

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(adminUid)
          .collection('hotelSubUsers')
          .doc(subId)
          .get();

      if (!doc.exists || doc.data() == null) return null;
      final subUser = HotelSubUser.fromJson(doc.data()!);
      return subUser.isActive ? subUser : null;
    } catch (e) {
      debugPrint('[HotelAuth] _loadCachedSubUser error: $e');
      return null;
    }
  }

  /// Create a new sub-user with a Firebase Auth account.
  /// The admin stays logged in throughout.
  Future<HotelSubUser> createSubUserWithCredentials({
    required String name,
    required String email,
    required String password,
    required String phone,
    required HotelUserRole role,
    required List<HotelModule> allowedModules,
  }) async {
    final adminUser = FirebaseAuth.instance.currentUser;
    if (adminUser == null) throw StateError('No authenticated admin');
    final adminUid = adminUser.uid;

    // Create Firebase Auth account for the sub-user
    // This will sign out the admin temporarily
    UserCredential subCred;
    try {
      subCred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      rethrow;
    }

    final subUid = subCred.user?.uid ?? '';

    // Immediately sign back in as admin using stored credentials
    // (The CredentialsManager has the admin's password)
    // We need the admin signed in to write to their Firestore collection
    final credManager = await _getAdminCredentials();
    await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: credManager['email']!,
      password: credManager['password']!,
    );

    // Now create the sub-user doc under the admin's collection
    final docRef = _subUsersCollection().doc();
    final now = DateTime.now();

    final subUser = HotelSubUser(
      id: docRef.id,
      adminUid: adminUid,
      name: name,
      email: email,
      phone: phone,
      pin: '',
      firebaseUid: subUid,
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

  Future<Map<String, String>> _getAdminCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'email': prefs.getString('user_email') ?? '',
      'password': prefs.getString('user_password') ?? '',
    };
  }
}

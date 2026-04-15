import 'dart:math';

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
  /// 1. Check SharedPreferences cache (instant).
  /// 2. Check if `users/{uid}` doc exists → admin.
  /// 3. Check `staffMapping/{uid}` for a direct sub-user pointer (fast).
  /// 4. Never default to admin when the user clearly has no admin doc.
  Future<void> resolveSessionAfterLogin() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setAdminSession();
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final cacheKey = 'hotel_role_${user.uid}';

    // ── 1. Check cache (instant) ──
    final cached = prefs.getString(cacheKey);

    if (cached == 'sub_user') {
      final subUser = await _loadCachedSubUser(user.uid);
      if (subUser != null) {
        setSubUserSession(subUser);
        debugPrint('[HotelAuth] Cached → sub-user: ${subUser.name}');
        return;
      }
      // Cache stale — fall through to fresh check
    }

    // ── 2. Check if admin doc exists ──
    bool adminDocExists = false;
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      adminDocExists = userDoc.exists;
    } catch (e) {
      debugPrint('[HotelAuth] Admin doc check error: $e');
      // If we can't even read our own doc, respect cached admin
      if (cached == 'admin') {
        setAdminSession();
        return;
      }
    }

    if (adminDocExists) {
      await prefs.setString(cacheKey, 'admin');
      setAdminSession();
      debugPrint('[HotelAuth] Admin (doc exists): ${user.uid}');
      return;
    }

    // ── 3. Not an admin — look up staffMapping/{uid} (fast, direct path) ──
    try {
      final mappingDoc = await FirebaseFirestore.instance
          .collection('staffMapping')
          .doc(user.uid)
          .get();

      if (mappingDoc.exists && mappingDoc.data() != null) {
        final data = mappingDoc.data()!;
        final adminUid = data['adminUid'] as String? ?? '';
        final subId = data['subUserId'] as String? ?? '';

        if (adminUid.isNotEmpty && subId.isNotEmpty) {
          final subDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(adminUid)
              .collection('hotelSubUsers')
              .doc(subId)
              .get();

          if (subDoc.exists && subDoc.data() != null) {
            final subUser = HotelSubUser.fromJson(subDoc.data()!);
            if (subUser.isActive) {
              await prefs.setString(cacheKey, 'sub_user');
              await prefs.setString('hotel_sub_admin_${user.uid}', adminUid);
              await prefs.setString('hotel_sub_id_${user.uid}', subId);
              setSubUserSession(subUser);
              debugPrint(
                '[HotelAuth] Sub-user via mapping: ${subUser.name} '
                '(${subUser.role.label})',
              );
              return;
            }
          }
        }
      }
    } catch (e) {
      debugPrint('[HotelAuth] staffMapping lookup error: $e');
      // Not critical — continue to check if it's a new admin account
    }

    // ── 4. No admin doc AND no staff mapping — new admin account ──
    // Only default to admin if there truly is no mapping at all.
    // This handles first-time admin signup where the user doc may not
    // yet exist (rare race condition).
    debugPrint(
      '[HotelAuth] No admin doc and no staffMapping for ${user.uid}, '
      'treating as restricted.',
    );
    _isAdmin = false;
    _currentSubUser = null;
    notifyListeners();
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
    HotelDepartment department = HotelDepartment.custom,
    String? staffId,
  }) async {
    final adminUser = FirebaseAuth.instance.currentUser;
    if (adminUser == null) throw StateError('No authenticated admin');
    final adminUid = adminUser.uid;

    // Generate Staff ID if not provided
    final generatedStaffId = staffId ?? await generateStaffId();

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
      staffId: generatedStaffId,
      name: name,
      email: email,
      phone: phone,
      pin: '',
      firebaseUid: subUid,
      role: role,
      department: department,
      allowedModules: role == HotelUserRole.admin
          ? HotelModule.values
          : allowedModules,
      isActive: true,
      createdAt: now,
      updatedAt: now,
    );

    await docRef.set(subUser.toJson());

    // Write a mapping doc so staff login can resolve without collectionGroup.
    // Path: staffMapping/{staffFirebaseUid} → { adminUid, subUserId }
    if (subUid.isNotEmpty) {
      await FirebaseFirestore.instance
          .collection('staffMapping')
          .doc(subUid)
          .set({'adminUid': adminUid, 'subUserId': docRef.id});
    }

    return subUser;
  }

  Future<Map<String, String>> _getAdminCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'email': prefs.getString('user_email') ?? '',
      'password': prefs.getString('user_password') ?? '',
    };
  }

  // ==================== STAFF ID & PASSWORD GENERATION ====================

  /// Generate the next sequential Staff ID (e.g. STF-001, STF-002).
  Future<String> generateStaffId() async {
    final snapshot = await _subUsersCollection()
        .orderBy('createdAt', descending: true)
        .get();
    final count = snapshot.docs.length;
    return 'STF-${(count + 1).toString().padLeft(3, '0')}';
  }

  /// Generate a secure random password of given length.
  static String generateSecurePassword({int length = 12}) {
    const upper = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    const lower = 'abcdefghijklmnopqrstuvwxyz';
    const digits = '0123456789';
    const special = '@#\$%&*!?';
    const all = upper + lower + digits + special;
    final rand = Random.secure();

    // Ensure at least one of each type
    final mandatory = [
      upper[rand.nextInt(upper.length)],
      lower[rand.nextInt(lower.length)],
      digits[rand.nextInt(digits.length)],
      special[rand.nextInt(special.length)],
    ];
    final remaining = List.generate(
      length - mandatory.length,
      (_) => all[rand.nextInt(all.length)],
    );
    final chars = [...mandatory, ...remaining]..shuffle(rand);
    return chars.join();
  }

  /// Permanently delete a sub-user document and its staff mapping.
  Future<void> deleteSubUser(String id) async {
    // Read the sub-user doc first to get the firebaseUid for mapping cleanup
    final doc = await _subUsersCollection().doc(id).get();
    if (doc.exists) {
      final fbUid = doc.data()?['firebaseUid'] as String? ?? '';
      if (fbUid.isNotEmpty) {
        await FirebaseFirestore.instance
            .collection('staffMapping')
            .doc(fbUid)
            .delete();
      }
    }
    await _subUsersCollection().doc(id).delete();
  }

  /// Backfill staffMapping docs for all existing sub-users that have a
  /// firebaseUid. Call once from admin context to migrate old data.
  Future<void> backfillStaffMappings() async {
    try {
      final adminUid = FirebaseAuth.instance.currentUser?.uid;
      if (adminUid == null) return;
      final snapshot = await _subUsersCollection().get();
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final fbUid = data['firebaseUid'] as String? ?? '';
        if (fbUid.isNotEmpty) {
          await FirebaseFirestore.instance
              .collection('staffMapping')
              .doc(fbUid)
              .set({'adminUid': adminUid, 'subUserId': doc.id});
        }
      }
      debugPrint(
        '[HotelAuth] Backfilled staffMapping for ${snapshot.docs.length} users',
      );
    } catch (e) {
      debugPrint('[HotelAuth] backfillStaffMappings error: $e');
    }
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import 'app_module.dart';

// Session access for the signed-in user. Owners keep full module access (unchanged).
// Employees resolve to the shop owner's data tree with a subset of modules.
class AccessControlService {
  AccessControlService._();
  static final AccessControlService instance = AccessControlService._();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String? _authUid;
  String? _dataOwnerId;
  bool _isOwner = true;
  Set<String> _allowedModules = AppModule.allKeys;
  String? displayName;
  int? tokenNumber;
  bool counterAccess = true;
  bool _loaded = false;

  bool get isLoaded => _loaded;
  bool get isOwner => _isOwner;
  bool get isEmployee => _loaded && !_isOwner;
  String? get authUid => _authUid;
  Set<String> get allowedModules => Set.unmodifiable(_allowedModules);

  // Firestore path root for shop data. Owners: own uid. Employees: owner uid.
  String? get dataOwnerId {
    if (_dataOwnerId != null && _dataOwnerId!.isNotEmpty) return _dataOwnerId;
    return _authUid ?? _auth.currentUser?.uid;
  }

  bool canAccess(AppModule module) {
    if (!_loaded || _isOwner) return true;
    // Hub filters report kinds by module; always allow opening the page.
    if (module == AppModule.reports) return true;
    if (AppModule.ownerOnly.contains(module)) return false;
    if (module == AppModule.billing && !counterAccess) return false;
    return _allowedModules.contains(module.key);
  }

  bool canAccessKey(String key) {
    final module = AppModule.fromKey(key);
    if (module == null) return _isOwner;
    return canAccess(module);
  }

  bool canAccessShellIndex(int index) {
    final module = AppModule.fromShellIndex(index);
    if (module == null) return _isOwner;
    return canAccess(module);
  }

  // First allowed shell index (for redirect when landing on a blocked tab).
  int firstAllowedShellIndex() {
    if (_isOwner || !_loaded) return AppModule.dashboard.shellIndex;
    for (final m in AppModule.grantable) {
      if (_allowedModules.contains(m.key)) return m.shellIndex;
    }
    return AppModule.password.shellIndex;
  }

  Future<void> loadForCurrentUser() async {
    final user = _auth.currentUser;
    if (user == null) {
      clear();
      return;
    }

    _authUid = user.uid;
    displayName = user.displayName;
    tokenNumber = null;
    counterAccess = true;

    try {
      // Prefer custom claims when Cloud Functions have set them.
      final token = await user.getIdTokenResult(true);
      final claims = token.claims ?? {};
      final claimOwner = claims['tenantOwnerId'] as String?;
      final claimRole = claims['role'] as String?;

      if (claimOwner != null &&
          claimOwner.isNotEmpty &&
          claimRole == 'employee') {
        await _applyEmployee(
          ownerId: claimOwner,
          modulesFromClaims: _modulesFromClaims(claims['modules']),
        );
        // Claims may omit token; refresh already ran inside _applyEmployee.
        _loaded = true;
        debugPrint(
          '[AccessControl] Employee via claims → owner=$claimOwner modules=${_allowedModules.length}',
        );
        return;
      }

      // Fallback: employee profile doc under users/{uid}
      final profile = await _firestore.collection('users').doc(user.uid).get();
      final data = profile.data();
      if (data != null &&
          data['role'] == 'employee' &&
          data['tenantOwnerId'] is String &&
          (data['tenantOwnerId'] as String).isNotEmpty) {
        if (data['active'] == false) {
          throw StateError('Employee account is deactivated');
        }
        final tokenRaw = data['tokenNumber'];
        tokenNumber = tokenRaw is int
            ? tokenRaw
            : int.tryParse('$tokenRaw');
        counterAccess = data['counterAccess'] as bool? ?? true;
        await _applyEmployee(
          ownerId: data['tenantOwnerId'] as String,
          modulesFromClaims: _stringSet(data['allowedModules']),
          name: data['displayName'] as String?,
        );
        _loaded = true;
        debugPrint(
          '[AccessControl] Employee via profile → owner=${data['tenantOwnerId']}',
        );
        return;
      }

      // Default: shop owner / admin - full access (backward compatible)
      _isOwner = true;
      _dataOwnerId = user.uid;
      _allowedModules = AppModule.allKeys;
      displayName = data?['firstName'] as String? ?? user.displayName;
      _loaded = true;
      debugPrint('[AccessControl] Owner session uid=${user.uid}');
    } catch (e) {
      debugPrint('[AccessControl] load failed: $e');
      // Fail closed for employees; owners can still proceed with own uid.
      final roleHint = (await _safeRoleHint(user.uid));
      if (roleHint == 'employee') {
        clear();
        rethrow;
      }
      _isOwner = true;
      _dataOwnerId = user.uid;
      _authUid = user.uid;
      _allowedModules = AppModule.allKeys;
      _loaded = true;
    }
  }

  Future<void> _applyEmployee({
    required String ownerId,
    Set<String>? modulesFromClaims,
    String? name,
  }) async {
    _isOwner = false;
    _dataOwnerId = ownerId;

    // Prefer live modules from owner employees/{uid} when online.
    Set<String> modules = modulesFromClaims ?? {};
    try {
      final empDoc = await _firestore
          .collection('users')
          .doc(ownerId)
          .collection('employees')
          .doc(_authUid)
          .get()
          .timeout(const Duration(seconds: 8));
      if (empDoc.exists) {
        final d = empDoc.data();
        if (d?['active'] == false) {
          throw StateError('Employee account is deactivated');
        }
        final live = _stringSet(d?['allowedModules']);
        if (live.isNotEmpty) modules = live;
        displayName = d?['displayName'] as String? ?? name ?? displayName;
        final tokenRaw = d?['tokenNumber'];
        tokenNumber = tokenRaw is int
            ? tokenRaw
            : int.tryParse('$tokenRaw');
        counterAccess = d?['counterAccess'] as bool? ?? true;
      }
    } catch (e) {
      if (e is StateError) rethrow;
      debugPrint('[AccessControl] employee doc refresh skipped: $e');
      displayName = name ?? displayName;
    }

    // Strip owner-only keys even if stored incorrectly.
    modules.removeWhere(
      (k) => AppModule.ownerOnly.any((m) => m.key == k),
    );
    if (!counterAccess) {
      modules.remove(AppModule.billing.key);
    }
    if (modules.isEmpty) {
      modules = AppModule.defaultEmployeeModules.map((m) => m.key).toSet();
      if (!counterAccess) modules.remove(AppModule.billing.key);
    }
    // Password always allowed for self-service.
    modules.add(AppModule.password.key);
    _allowedModules = modules;
  }

  Future<String?> _safeRoleHint(String uid) async {
    try {
      final snap = await _firestore.collection('users').doc(uid).get();
      return snap.data()?['role'] as String?;
    } catch (_) {
      return null;
    }
  }

  Set<String> _modulesFromClaims(dynamic raw) => _stringSet(raw);

  Set<String> _stringSet(dynamic raw) {
    if (raw is! List) return {};
    return raw.map((e) => e.toString()).where((e) => e.isNotEmpty).toSet();
  }

  void clear() {
    _authUid = null;
    _dataOwnerId = null;
    _isOwner = true;
    _allowedModules = AppModule.allKeys;
    displayName = null;
    tokenNumber = null;
    counterAccess = true;
    _loaded = false;
  }
}

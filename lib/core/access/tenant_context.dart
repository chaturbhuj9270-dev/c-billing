import 'package:firebase_auth/firebase_auth.dart';

import 'access_control_service.dart';

// Resolves the shop data owner for Firestore paths.
// Existing single-user shops keep using auth.uid. Employees use the admin owner id.
class TenantContext {
  TenantContext._();

  static String get dataOwnerId {
    final fromAccess = AccessControlService.instance.dataOwnerId;
    if (fromAccess != null && fromAccess.isNotEmpty) return fromAccess;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      throw Exception('User not authenticated');
    }
    return uid;
  }

  static String? get dataOwnerIdOrNull {
    final fromAccess = AccessControlService.instance.dataOwnerId;
    if (fromAccess != null && fromAccess.isNotEmpty) return fromAccess;
    return FirebaseAuth.instance.currentUser?.uid;
  }

  static String get authUid {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      throw Exception('User not authenticated');
    }
    return uid;
  }
}

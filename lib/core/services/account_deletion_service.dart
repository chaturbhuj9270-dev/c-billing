import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../access/access_control_service.dart';
import 'credentials_manager.dart';
import 'local_user_data_guard.dart';
import 'session_manager.dart';
import 'sync_bootstrap.dart';

/// Deletes the signed-in user account (Play Store account-deletion requirement).
class AccountDeletionService {
  AccountDeletionService._();
  static final AccountDeletionService instance = AccountDeletionService._();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Deletes Auth user + marks/removes cloud profile, then clears local data.
  Future<void> deleteCurrentAccount({String? password}) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('No signed-in user');
    }

    final uid = user.uid;
    final email = user.email;

    // Email/password accounts may require recent login.
    if (password != null &&
        password.isNotEmpty &&
        email != null &&
        email.isNotEmpty) {
      final cred = EmailAuthProvider.credential(
        email: email,
        password: password,
      );
      await user.reauthenticateWithCredential(cred);
    }

    // Soft-delete / remove user profile document we own.
    try {
      await _firestore.collection('users').doc(uid).set({
        'deletedAt': FieldValue.serverTimestamp(),
        'deletionRequested': true,
        'email': email,
      }, SetOptions(merge: true));
      await _firestore.collection('users').doc(uid).delete();
    } catch (e) {
      debugPrint('[AccountDeletion] Firestore profile cleanup: $e');
    }

    SessionManager().endSession();
    AccessControlService.instance.clear();
    await CredentialsManager().clearCredentials();
    await LocalUserDataGuard.clearAllUserData();
    await LocalUserDataGuard.clearBinding();
    SyncBootstrap.resetOnLogout();

    await user.delete();
  }

  Future<void> deleteAndExit(BuildContext context, {String? password}) async {
    await deleteCurrentAccount(password: password);
    if (!context.mounted) return;
    Navigator.of(context, rootNavigator: true).pushNamedAndRemoveUntil(
      '/',
      (route) => false,
    );
  }
}

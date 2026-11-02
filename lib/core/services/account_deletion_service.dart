import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../access/access_control_service.dart';
import 'credentials_manager.dart';
import 'local_user_data_guard.dart';
import 'session_manager.dart';
import 'sync_bootstrap.dart';

/// Deletes the signed-in user account (Play Store account-deletion requirement).
///
/// Works on all Flutter platforms (Android / iOS / web / desktop) by calling the
/// shared Cloud Function `deleteMyAccount`, which also powers the public web page.
class AccountDeletionService {
  AccountDeletionService._();
  static final AccountDeletionService instance = AccountDeletionService._();

  static const String _functionsRegion = 'asia-south1';

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFunctions _functions =
      FirebaseFunctions.instanceFor(region: _functionsRegion);

  /// Deletes Auth user + cloud profile via Admin SDK, then clears local data.
  Future<void> deleteCurrentAccount({String? password}) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('No signed-in user');
    }

    final email = user.email;

    // Email/password accounts may require recent login before privileged calls.
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

    try {
      await _functions.httpsCallable('deleteMyAccount').call(<String, dynamic>{
        'confirmation': 'DELETE',
        'source': 'app',
      });
    } on FirebaseFunctionsException catch (e) {
      // Fall back to client Auth delete if Functions are not deployed yet.
      if (e.code == 'not-found' || e.code == 'unavailable') {
        await _legacyClientDelete();
      } else {
        rethrow;
      }
    }

    await _clearLocalSession();

    // Auth user is usually already removed by Admin SDK; ignore if gone.
    try {
      await _auth.signOut();
    } catch (_) {}
  }

  Future<void> _legacyClientDelete() async {
    final user = _auth.currentUser;
    if (user == null) return;
    await user.delete();
  }

  Future<void> _clearLocalSession() async {
    SessionManager().endSession();
    AccessControlService.instance.clear();
    await CredentialsManager().clearCredentials();
    await LocalUserDataGuard.clearAllUserData();
    await LocalUserDataGuard.clearBinding();
    SyncBootstrap.resetOnLogout();
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

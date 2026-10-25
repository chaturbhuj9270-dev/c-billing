import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:c_billing/core/access/access_control_service.dart';
import 'local_database.dart';
import 'session_manager.dart';
import 'credentials_manager.dart';
import 'sync_bootstrap.dart';

// Centralized logout service to ensure all local data is cleared when a user logs out or session expires
class LogoutService {
  static final LogoutService _instance = LogoutService._internal();

  factory LogoutService() => _instance;

  LogoutService._internal();

  static LogoutService get instance => _instance;

  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Perform complete logout - clears all local data and signs out
  Future<void> logout(BuildContext context) async {
    debugPrint('[LogoutService] Starting logout process...');

    try {
      // 1. End session timer
      SessionManager().endSession();
      debugPrint('[LogoutService] Session ended');

      // 2. Clear access / tenant context
      AccessControlService.instance.clear();

      // 3. Clear stored credentials
      await CredentialsManager().clearCredentials();
      debugPrint('[LogoutService] Credentials cleared');

      // 4. Clear ALL local database data - THIS IS CRITICAL FOR SECURITY
      await _clearAllLocalData();
      debugPrint('[LogoutService] Local data cleared');

      // 5. Clear in-memory sync cursors so next login does a full pull
      SyncBootstrap.resetOnLogout();

      // 6. Sign out from Firebase
      await _auth.signOut();
      debugPrint('[LogoutService] Firebase sign out complete');

      // 7. Navigate to login screen
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pushNamedAndRemoveUntil(
          '/',
          (route) => false,
        );
      }

      debugPrint('[LogoutService] Logout complete');
    } catch (e) {
      debugPrint('[LogoutService] Error during logout: $e');
      // Even if there's an error, still sign out and navigate
      try {
        await _auth.signOut();
      } catch (_) {}
      
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pushNamedAndRemoveUntil(
          '/',
          (route) => false,
        );
      }
    }
  }

  // Clear all local database data
  Future<void> _clearAllLocalData() async {
    try {
      if (LocalDatabase.instance.isInitialized) {
        await LocalDatabase.instance.clearAllData();
        debugPrint('[LogoutService] Local data cleared successfully');
      }
    } catch (e) {
      debugPrint('[LogoutService] Error clearing local data: $e');
    }
  }

  // Called when session expires - clears data and signs out
  Future<void> onSessionExpired(BuildContext context) async {
    debugPrint('[LogoutService] Session expired - clearing data');
    
    try {
      AccessControlService.instance.clear();
      await _clearAllLocalData();
      SyncBootstrap.resetOnLogout();

      await _auth.signOut();

      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pushNamedAndRemoveUntil(
          '/',
          (route) => false,
        );
      }
    } catch (e) {
      debugPrint('[LogoutService] Error during session expiry: $e');
      try {
        SyncBootstrap.resetOnLogout();
        await _auth.signOut();
      } catch (_) {}

      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pushNamedAndRemoveUntil(
          '/',
          (route) => false,
        );
      }
    }
  }

  // Clear data only (without signing out) - useful for data refresh
  Future<void> clearLocalDataOnly() async {
    await _clearAllLocalData();
  }
}

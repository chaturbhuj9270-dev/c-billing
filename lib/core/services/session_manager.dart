import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import 'package:flutter/material.dart';

class SessionManager {
  static final SessionManager _instance = SessionManager._internal();

  factory SessionManager() {
    return _instance;
  }

  SessionManager._internal();

  // 2 hours in milliseconds
  static const Duration sessionTimeout = Duration(hours: 2);

  User? _currentUser;
  Timer? _sessionTimer;
  late VoidCallback _onSessionExpired;

  User? get currentUser => _currentUser;

  /// Initialize session with a user and callback for expiration
  void initializeSession(User user, VoidCallback onSessionExpired) {
    debugPrint('[DEBUG] Session initialized for user: ${user.uid}');
    _currentUser = user;
    _onSessionExpired = onSessionExpired;
    _resetSessionTimer();
  }

  /// Reset the session timer (called on every user activity)
  void resetSession() {
    if (_currentUser != null) {
      debugPrint('[DEBUG] Session reset for user: ${_currentUser!.uid}');
      _resetSessionTimer();
    }
  }

  /// Internal method to reset the timer
  void _resetSessionTimer() {
    // Cancel existing timer
    _sessionTimer?.cancel();

    // Start new timer for 2 hours
    _sessionTimer = Timer(sessionTimeout, () {
      debugPrint('[CRITICAL] Session expired for user: ${_currentUser?.uid}');
      _sessionExpired();
    });
  }

  /// Called when session expires
  void _sessionExpired() {
    debugPrint('[CRITICAL] Session timeout triggered');
    _currentUser = null;
    _sessionTimer?.cancel();
    _onSessionExpired();
  }

  /// Manually end the session (e.g., on logout)
  void endSession() {
    debugPrint('[DEBUG] Session ended for user: ${_currentUser?.uid}');
    _currentUser = null;
    _sessionTimer?.cancel();
  }

  /// Check if user is still authenticated
  Future<bool> isSessionValid() async {
    if (_currentUser == null) {
      debugPrint('[ERROR] No user in session');
      return false;
    }

    try {
      await _currentUser!.reload();
      debugPrint('[DEBUG] Session valid for user: ${_currentUser!.uid}');
      return true;
    } catch (e) {
      debugPrint('[ERROR] Session validation failed: $e');
      return false;
    }
  }

  /// Get remaining session time in minutes
  Duration? getRemainingSessionTime() {
    if (_sessionTimer == null || !_sessionTimer!.isActive) {
      return null;
    }
    // This is approximate; for accurate tracking, consider storing the expiration time
    return sessionTimeout;
  }
}

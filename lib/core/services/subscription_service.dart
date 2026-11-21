import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Service to manage user subscription status.
//
// Access rules:
// - New users get a 30-day free trial from signup (`subscriptionStatus: trial`)
// - Paid users stay active for 365 days from `subscriptionDate`
// - Activation after payment is performed by Cloud Functions
class SubscriptionService {
  static final SubscriptionService _instance = SubscriptionService._internal();
  factory SubscriptionService() => _instance;
  SubscriptionService._internal();

  FirebaseFirestore get _firestore => FirebaseFirestore.instance;
  FirebaseAuth get _auth => FirebaseAuth.instance;

  // Subscription price in INR
  static const double subscriptionPrice = 3999.0;

  // Display price (with thousands separator)
  static const String subscriptionPriceDisplay = '3,999';

  // Paid subscription validity
  static const Duration subscriptionDuration = Duration(days: 365);

  // Free trial before paywall
  static const Duration trialDuration = Duration(days: 30);

  static const String statusTrial = 'trial';
  static const String statusActive = 'active';
  static const String statusInactive = 'inactive';

  // Get current user ID
  String? get _userId => _auth.currentUser?.uid;

  DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  // Check if user's subscription/trial is still valid.
  Future<bool> isSubscriptionValid() async {
    try {
      final userId = _userId;
      if (userId == null) {
        debugPrint(
          '[SubscriptionService] No user logged in - subscription required',
        );
        return false;
      }

      final userDoc = await _firestore
          .collection('users')
          .doc(userId)
          .get()
          .timeout(const Duration(seconds: 8));

      if (!userDoc.exists) {
        debugPrint(
          '[SubscriptionService] User document not found - subscription required',
        );
        return false;
      }

      final data = userDoc.data();
      if (data == null) {
        debugPrint(
          '[SubscriptionService] User data is null - subscription required',
        );
        return false;
      }

      final resolved = await _resolveAccessWindow(userId, data);
      if (resolved == null) {
        debugPrint(
          '[SubscriptionService] No valid trial/subscription - payment required',
        );
        return false;
      }

      final isValid = DateTime.now().isBefore(resolved.expiry);
      debugPrint(
        '[SubscriptionService] Access valid: $isValid '
        '(status: ${resolved.status}, expires: ${resolved.expiry})',
      );
      return isValid;
    } catch (e) {
      debugPrint('[SubscriptionService] Error checking subscription: $e');
      // Fail closed — do not unlock the app on network/read errors.
      return false;
    }
  }

  // Get subscription / trial expiry date
  Future<DateTime?> getExpiryDate() async {
    try {
      final userId = _userId;
      if (userId == null) return null;

      final userDoc = await _firestore.collection('users').doc(userId).get();
      final data = userDoc.data();
      if (data == null) return null;

      final resolved = await _resolveAccessWindow(userId, data);
      return resolved?.expiry;
    } catch (e) {
      debugPrint('[SubscriptionService] Error getting expiry date: $e');
      return null;
    }
  }

  // Get remaining days in subscription / trial
  Future<int> getRemainingDays() async {
    final expiryDate = await getExpiryDate();
    if (expiryDate == null) return 0;

    final now = DateTime.now();
    if (now.isAfter(expiryDate)) return 0;
    return expiryDate.difference(now).inDays;
  }

  // Wait until Firestore reflects an active subscription (after payment verify).
  Future<bool> waitUntilActive({
    Duration timeout = const Duration(seconds: 20),
    Duration pollInterval = const Duration(seconds: 1),
  }) async {
    final deadline = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(deadline)) {
      if (await isSubscriptionValid()) return true;
      await Future.delayed(pollInterval);
    }
    return await isSubscriptionValid();
  }

  // New users start with a 30-day free trial.
  static Future<void> setInitialSubscription(String userId) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(userId).set({
        'subscriptionDate': FieldValue.serverTimestamp(),
        'subscriptionStatus': statusTrial,
        'trialStartedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      debugPrint(
        '[SubscriptionService] 30-day trial started for user: $userId',
      );
    } catch (e) {
      debugPrint('[SubscriptionService] Error setting initial trial: $e');
    }
  }

  // Get subscription status details
  Future<Map<String, dynamic>> getSubscriptionStatus() async {
    try {
      final userId = _userId;
      if (userId == null) {
        return {'isActive': false, 'message': 'Not logged in'};
      }

      final userDoc = await _firestore.collection('users').doc(userId).get();
      final data = userDoc.data();
      if (data == null) {
        return {'isActive': false, 'message': 'No user data'};
      }

      final resolved = await _resolveAccessWindow(userId, data);
      if (resolved == null) {
        return {
          'isActive': false,
          'message': 'No subscription found',
          'subscriptionDate': null,
          'expiryDate': null,
          'remainingDays': 0,
          'status': statusInactive,
        };
      }

      final now = DateTime.now();
      final isActive = now.isBefore(resolved.expiry);
      final remainingDays =
          isActive ? resolved.expiry.difference(now).inDays : 0;

      return {
        'isActive': isActive,
        'message': isActive
            ? (resolved.status == statusTrial
                ? 'Free trial active'
                : 'Subscription active')
            : 'Subscription expired',
        'subscriptionDate': resolved.start,
        'expiryDate': resolved.expiry,
        'remainingDays': remainingDays,
        'status': resolved.status,
      };
    } catch (e) {
      debugPrint('[SubscriptionService] Error getting subscription status: $e');
      return {'isActive': false, 'message': 'Error checking subscription'};
    }
  }

  /// Resolves the access window for a user document.
  ///
  /// Also backfills a trial for older accounts that still have
  /// `subscriptionDate: null` but are within 30 days of `createdAt`.
  Future<_AccessWindow?> _resolveAccessWindow(
    String userId,
    Map<String, dynamic> data,
  ) async {
    final status = (data['subscriptionStatus'] as String?)?.toLowerCase();
    var start = _parseDate(data['subscriptionDate']);

    // Legacy / broken docs: no subscriptionDate → trial from createdAt (or now).
    if (start == null) {
      final createdAt = _parseDate(data['createdAt']) ?? DateTime.now();
      start = createdAt;
      final trialExpiry = start.add(trialDuration);
      if (DateTime.now().isBefore(trialExpiry)) {
        // Persist trial so subsequent checks are consistent.
        try {
          await _firestore.collection('users').doc(userId).set({
            'subscriptionDate': Timestamp.fromDate(start),
            'subscriptionStatus': statusTrial,
            'trialStartedAt': Timestamp.fromDate(start),
          }, SetOptions(merge: true));
        } catch (e) {
          debugPrint('[SubscriptionService] Trial backfill failed: $e');
        }
        return _AccessWindow(
          start: start,
          expiry: trialExpiry,
          status: statusTrial,
        );
      }
      return null;
    }

    final effectiveStatus =
        (status == null || status.isEmpty || status == statusInactive)
            ? statusTrial
            : status;

    // Paid active subscriptions use 1 year; trial uses 30 days.
    final duration = effectiveStatus == statusActive
        ? subscriptionDuration
        : trialDuration;

    return _AccessWindow(
      start: start,
      expiry: start.add(duration),
      status: effectiveStatus == statusActive ? statusActive : statusTrial,
    );
  }
}

class _AccessWindow {
  final DateTime start;
  final DateTime expiry;
  final String status;

  const _AccessWindow({
    required this.start,
    required this.expiry,
    required this.status,
  });
}

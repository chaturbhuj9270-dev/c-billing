import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:c_billing/core/access/tenant_context.dart';

// Service to manage user subscription status.
// Access is allowed during a 30-day free trial (`trialStartedAt`) or a paid
 // `subscriptionDate` within [subscriptionDuration]. Paid activation is done
 // by Cloud Functions after Cashfree / Play Billing.
class SubscriptionService {
  static final SubscriptionService _instance = SubscriptionService._internal();
  factory SubscriptionService() => _instance;
  SubscriptionService._internal();

  FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  // Subscription price in INR
  static const double subscriptionPrice = 3999.0;

  // Display price (with thousands separator)
  static const String subscriptionPriceDisplay = '3,999';

  // Paid subscription validity duration
  static const Duration subscriptionDuration = Duration(days: 365);

  // Free trial after registration
  static const Duration freeTrialDuration = Duration(days: 30);

  // Get current user ID
  String? get _userId => TenantContext.dataOwnerIdOrNull;

  DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  // Paid expiry if subscribed; otherwise free-trial expiry.
  // Falls back to createdAt when trialStartedAt was never written (older accounts).
  DateTime? _accessExpiryFromData(Map<String, dynamic> data) {
    final subDate = _parseDate(data['subscriptionDate']);
    if (subDate != null) {
      return subDate.add(subscriptionDuration);
    }
    final trialStart =
        _parseDate(data['trialStartedAt']) ?? _parseDate(data['createdAt']);
    if (trialStart != null) {
      return trialStart.add(freeTrialDuration);
    }
    return null;
  }

  bool _isActiveExpiry(DateTime? expiry) {
    if (expiry == null) return false;
    return DateTime.now().isBefore(expiry);
  }

  // Older accounts never received trialStartedAt. Grant a one-time 30-day trial
  // when there is no paid subscription and no trial field yet.
  Future<Map<String, dynamic>> _ensureTrialStarted(
    String userId,
    Map<String, dynamic> data,
  ) async {
    if (_parseDate(data['subscriptionDate']) != null) return data;
    if (_parseDate(data['trialStartedAt']) != null) return data;

    final createdAt = _parseDate(data['createdAt']);
    // Still inside first month from registration — treat createdAt as trial start.
    if (createdAt != null &&
        DateTime.now().isBefore(createdAt.add(freeTrialDuration))) {
      try {
        await _firestore.collection('users').doc(userId).set({
          'trialStartedAt': Timestamp.fromDate(createdAt),
          'subscriptionStatus': 'trial',
        }, SetOptions(merge: true));
      } catch (e) {
        debugPrint('[SubscriptionService] Could not backfill trial from createdAt: $e');
      }
      return {
        ...data,
        'trialStartedAt': Timestamp.fromDate(createdAt),
        'subscriptionStatus': 'trial',
      };
    }

    // Account older than 30 days / missing createdAt: start trial from now once.
    try {
      await _firestore.collection('users').doc(userId).set({
        'trialStartedAt': FieldValue.serverTimestamp(),
        'subscriptionStatus': 'trial',
      }, SetOptions(merge: true));
      debugPrint('[SubscriptionService] Started free trial for existing user $userId');
    } catch (e) {
      debugPrint('[SubscriptionService] Could not start free trial: $e');
      // Still allow access locally for this session using "now".
      return {
        ...data,
        'trialStartedAt': Timestamp.fromDate(DateTime.now()),
        'subscriptionStatus': 'trial',
      };
    }

    final refreshed = await _firestore.collection('users').doc(userId).get();
    return refreshed.data() ?? {
      ...data,
      'trialStartedAt': Timestamp.fromDate(DateTime.now()),
      'subscriptionStatus': 'trial',
    };
  }

  // Check if user's subscription / free trial is valid. Fail-closed on errors.
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

      var data = userDoc.data();
      if (data == null) {
        debugPrint(
          '[SubscriptionService] User data is null - subscription required',
        );
        return false;
      }

      data = await _ensureTrialStarted(userId, data);

      final expiry = _accessExpiryFromData(data);
      final isValid = _isActiveExpiry(expiry);
      debugPrint(
        '[SubscriptionService] Access valid: $isValid (expires: $expiry)',
      );
      return isValid;
    } catch (e) {
      debugPrint('[SubscriptionService] Error checking subscription: $e');
      // Fail closed - do not unlock the app on network/read errors.
      return false;
    }
  }

  // Get access expiry date (paid subscription or free trial)
  Future<DateTime?> getExpiryDate() async {
    try {
      final userId = _userId;
      if (userId == null) return null;

      final userDoc = await _firestore.collection('users').doc(userId).get();
      var data = userDoc.data();
      if (data == null) return null;
      data = await _ensureTrialStarted(userId, data);
      return _accessExpiryFromData(data);
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

  Future<bool> isOnFreeTrial() async {
    try {
      final userId = _userId;
      if (userId == null) return false;
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final data = userDoc.data();
      if (data == null) return false;
      if (_parseDate(data['subscriptionDate']) != null) return false;
      final trialStart = _parseDate(data['trialStartedAt']);
      if (trialStart == null) return false;
      return _isActiveExpiry(trialStart.add(freeTrialDuration));
    } catch (_) {
      return false;
    }
  }

  // Wait until Firestore reflects an active subscription (after Cashfree verify).
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

  // New users start with a 30-day free trial, then must subscribe.
  static Future<void> setInitialSubscription(String userId) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(userId).set({
        'subscriptionDate': null,
        'subscriptionStatus': 'trial',
        'trialStartedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      debugPrint(
        '[SubscriptionService] Free trial started for user: $userId',
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
      final data = userDoc.data() ?? <String, dynamic>{};
      final subDate = _parseDate(data['subscriptionDate']);
      final trialStart = _parseDate(data['trialStartedAt']);
      final expiryDate = _accessExpiryFromData(data);
      final isActive = _isActiveExpiry(expiryDate);
      final remainingDays = isActive && expiryDate != null
          ? expiryDate.difference(DateTime.now()).inDays
          : 0;
      final onTrial = isActive && subDate == null && trialStart != null;

      if (expiryDate == null) {
        return {
          'isActive': false,
          'isTrial': false,
          'message': 'No subscription found',
          'subscriptionDate': null,
          'expiryDate': null,
          'remainingDays': 0,
        };
      }

      return {
        'isActive': isActive,
        'isTrial': onTrial,
        'message': !isActive
            ? (subDate == null ? 'Free trial ended' : 'Subscription expired')
            : (onTrial ? 'Free trial active' : 'Subscription active'),
        'subscriptionDate': subDate,
        'trialStartedAt': trialStart,
        'expiryDate': expiryDate,
        'remainingDays': remainingDays,
      };
    } catch (e) {
      debugPrint('[SubscriptionService] Error getting subscription status: $e');
      return {'isActive': false, 'message': 'Error checking subscription'};
    }
  }
}

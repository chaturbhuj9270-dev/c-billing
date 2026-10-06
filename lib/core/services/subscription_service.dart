import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Service to manage user subscription status.
///
/// Access requires an active `subscriptionDate` within [subscriptionDuration].
/// Activation after Cashfree payment is performed by Cloud Functions.
class SubscriptionService {
  static final SubscriptionService _instance = SubscriptionService._internal();
  factory SubscriptionService() => _instance;
  SubscriptionService._internal();

  FirebaseFirestore get _firestore => FirebaseFirestore.instance;
  FirebaseAuth get _auth => FirebaseAuth.instance;

  /// Subscription price in INR
  static const double subscriptionPrice = 3999.0;

  /// Display price (with thousands separator)
  static const String subscriptionPriceDisplay = '3,999';

  /// Subscription validity duration
  static const Duration subscriptionDuration = Duration(days: 365);

  /// Get current user ID
  String? get _userId => _auth.currentUser?.uid;

  DateTime? _parseSubscriptionDate(dynamic subscriptionDate) {
    if (subscriptionDate == null) return null;
    if (subscriptionDate is Timestamp) return subscriptionDate.toDate();
    if (subscriptionDate is String) return DateTime.tryParse(subscriptionDate);
    return null;
  }

  /// Check if user's subscription is valid.
  ///
  /// Fail-closed for logged-in users: missing/expired/error → false.
  /// No logged-in user → true (auth flow handles that case).
  Future<bool> isSubscriptionValid() async {
    try {
      final userId = _userId;
      if (userId == null) {
        print(
          '[SubscriptionService] No user logged in - returning true to let auth flow handle',
        );
        return true;
      }

      final userDoc = await _firestore
          .collection('users')
          .doc(userId)
          .get()
          .timeout(const Duration(seconds: 8));

      if (!userDoc.exists) {
        print(
          '[SubscriptionService] User document not found - subscription required',
        );
        return false;
      }

      final data = userDoc.data();
      if (data == null) {
        print('[SubscriptionService] User data is null - subscription required');
        return false;
      }

      final subDate = _parseSubscriptionDate(data['subscriptionDate']);
      if (subDate == null) {
        print(
          '[SubscriptionService] No valid subscription date - subscription required',
        );
        return false;
      }

      final expiryDate = subDate.add(subscriptionDuration);
      final isValid = DateTime.now().isBefore(expiryDate);
      print(
        '[SubscriptionService] Subscription valid: $isValid (expires: $expiryDate)',
      );
      return isValid;
    } catch (e) {
      print('[SubscriptionService] Error checking subscription: $e');
      // Fail closed — do not unlock the app on network/read errors.
      return false;
    }
  }

  /// Get subscription expiry date
  Future<DateTime?> getExpiryDate() async {
    try {
      final userId = _userId;
      if (userId == null) return null;

      final userDoc = await _firestore.collection('users').doc(userId).get();
      final data = userDoc.data();
      if (data == null) return null;

      final subDate = _parseSubscriptionDate(data['subscriptionDate']);
      if (subDate == null) return null;
      return subDate.add(subscriptionDuration);
    } catch (e) {
      print('[SubscriptionService] Error getting expiry date: $e');
      return null;
    }
  }

  /// Get remaining days in subscription
  Future<int> getRemainingDays() async {
    final expiryDate = await getExpiryDate();
    if (expiryDate == null) return 0;

    final now = DateTime.now();
    if (now.isAfter(expiryDate)) return 0;
    return expiryDate.difference(now).inDays;
  }

  /// Wait until Firestore reflects an active subscription (after Cashfree verify).
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

  /// Client-side activate — kept for admin/manual tooling only.
  /// Production unlock must go through Cloud Functions after Cashfree PAID.
  Future<bool> activateSubscription() async {
    try {
      final userId = _userId;
      if (userId == null) {
        print('[SubscriptionService] No user logged in');
        return false;
      }

      await _firestore.collection('users').doc(userId).update({
        'subscriptionDate': FieldValue.serverTimestamp(),
        'lastSubscriptionUpdate': FieldValue.serverTimestamp(),
        'subscriptionStatus': 'active',
      });

      print('[SubscriptionService] Subscription activated successfully');
      return true;
    } catch (e) {
      print('[SubscriptionService] Error activating subscription: $e');
      return false;
    }
  }

  /// New users start without an active subscription (must pay via Cashfree).
  static Future<void> setInitialSubscription(String userId) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(userId).set({
        'subscriptionDate': null,
        'subscriptionStatus': 'inactive',
      }, SetOptions(merge: true));
      print(
        '[SubscriptionService] Initial inactive subscription set for user: $userId',
      );
    } catch (e) {
      print('[SubscriptionService] Error setting initial subscription: $e');
    }
  }

  /// Get subscription status details
  Future<Map<String, dynamic>> getSubscriptionStatus() async {
    try {
      final userId = _userId;
      if (userId == null) {
        return {'isActive': false, 'message': 'Not logged in'};
      }

      final userDoc = await _firestore.collection('users').doc(userId).get();
      final data = userDoc.data();
      final subDate = _parseSubscriptionDate(data?['subscriptionDate']);

      if (subDate == null) {
        return {
          'isActive': false,
          'message': 'No subscription found',
          'subscriptionDate': null,
          'expiryDate': null,
          'remainingDays': 0,
        };
      }

      final expiryDate = subDate.add(subscriptionDuration);
      final now = DateTime.now();
      final isActive = now.isBefore(expiryDate);
      final remainingDays = isActive ? expiryDate.difference(now).inDays : 0;

      return {
        'isActive': isActive,
        'message': isActive ? 'Subscription active' : 'Subscription expired',
        'subscriptionDate': subDate,
        'expiryDate': expiryDate,
        'remainingDays': remainingDays,
      };
    } catch (e) {
      print('[SubscriptionService] Error getting subscription status: $e');
      return {'isActive': false, 'message': 'Error checking subscription'};
    }
  }
}

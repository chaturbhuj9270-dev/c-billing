import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Service to manage user subscription status
class SubscriptionService {
  static final SubscriptionService _instance = SubscriptionService._internal();
  factory SubscriptionService() => _instance;
  SubscriptionService._internal();

  FirebaseFirestore get _firestore => FirebaseFirestore.instance;
  FirebaseAuth get _auth => FirebaseAuth.instance;

  /// Subscription price in INR
  static const double subscriptionPrice = 3999.0;

  /// Subscription validity duration
  static const Duration subscriptionDuration = Duration(days: 365);

  /// Get current user ID
  String? get _userId => _auth.currentUser?.uid;

  /// Check if user's subscription is valid
  /// Returns true if subscription is active or no user logged in (let auth handle it)
  /// Returns false only if user is logged in AND subscription is expired
  Future<bool> isSubscriptionValid() async {
    try {
      final userId = _userId;
      if (userId == null) {
        print(
          '[SubscriptionService] No user logged in - returning true to let auth flow handle',
        );
        return true; // Let the auth flow handle non-logged-in users
      }

      final userDoc = await _firestore.collection('users').doc(userId).get();

      if (!userDoc.exists) {
        print(
          '[SubscriptionService] User document not found - granting access',
        );
        return true; // New user, document not yet created
      }

      final data = userDoc.data();
      if (data == null) {
        print('[SubscriptionService] User data is null - granting access');
        return true;
      }

      final subscriptionDate = data['subscriptionDate'];
      if (subscriptionDate == null) {
        print(
          '[SubscriptionService] No subscription date found - granting access',
        );
        return true; // Legacy user without subscription field
      }

      DateTime subDate;
      if (subscriptionDate is Timestamp) {
        subDate = subscriptionDate.toDate();
      } else if (subscriptionDate is String) {
        subDate = DateTime.parse(subscriptionDate);
      } else {
        print('[SubscriptionService] Invalid subscription date format');
        return false;
      }

      final expiryDate = subDate.add(subscriptionDuration);
      final now = DateTime.now();

      final isValid = now.isBefore(expiryDate);
      print(
        '[SubscriptionService] Subscription valid: $isValid (expires: $expiryDate)',
      );

      return isValid;
    } catch (e) {
      print('[SubscriptionService] Error checking subscription: $e');
      return true; // Grant access on error/timeout to avoid blocking user
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

      final subscriptionDate = data['subscriptionDate'];
      if (subscriptionDate == null) return null;

      DateTime subDate;
      if (subscriptionDate is Timestamp) {
        subDate = subscriptionDate.toDate();
      } else if (subscriptionDate is String) {
        subDate = DateTime.parse(subscriptionDate);
      } else {
        return null;
      }

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

  /// Activate subscription for current user
  /// Updates subscriptionDate to current date
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
      });

      print('[SubscriptionService] Subscription activated successfully');
      return true;
    } catch (e) {
      print('[SubscriptionService] Error activating subscription: $e');
      return false;
    }
  }

  /// Set subscription date for new user registration
  static Future<void> setInitialSubscription(String userId) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'subscriptionDate': FieldValue.serverTimestamp(),
      });
      print('[SubscriptionService] Initial subscription set for user: $userId');
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

      if (data == null || data['subscriptionDate'] == null) {
        return {
          'isActive': false,
          'message': 'No subscription found',
          'subscriptionDate': null,
          'expiryDate': null,
          'remainingDays': 0,
        };
      }

      final subscriptionDate = data['subscriptionDate'];
      DateTime subDate;
      if (subscriptionDate is Timestamp) {
        subDate = subscriptionDate.toDate();
      } else if (subscriptionDate is String) {
        subDate = DateTime.parse(subscriptionDate);
      } else {
        return {'isActive': false, 'message': 'Invalid subscription date'};
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

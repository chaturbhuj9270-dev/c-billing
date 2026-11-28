import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Pricing from backend (`app_config/subscription`).
///
/// - [amount] original / list price
/// - [offerAmount] discounted price when [offerEnabled] is true
/// - Charge / primary display uses [payableAmount]
class SubscriptionPricing {
  final double amount;
  final double offerAmount;
  final bool offerEnabled;
  final String currency;
  final int durationDays;

  const SubscriptionPricing({
    required this.amount,
    required this.offerAmount,
    required this.offerEnabled,
    required this.currency,
    required this.durationDays,
  });

  /// Offline / pre-fetch defaults (must match Cloud Function defaults).
  static const SubscriptionPricing defaults = SubscriptionPricing(
    amount: 6999,
    offerAmount: 3999,
    offerEnabled: true,
    currency: 'INR',
    durationDays: 365,
  );

  static final NumberFormat _inr = NumberFormat.decimalPattern('en_IN');

  /// Amount the user actually pays.
  double get payableAmount =>
      offerEnabled && offerAmount > 0 ? offerAmount : amount;

  /// Show struck-through original + offer price.
  bool get showOffer => offerEnabled && offerAmount > 0;

  String get amountDisplay => _inr.format(amount.round());
  String get offerAmountDisplay => _inr.format(offerAmount.round());
  String get payableAmountDisplay => _inr.format(payableAmount.round());
  String get priceLabel => '₹$payableAmountDisplay';
  String get originalPriceLabel => '₹$amountDisplay';
  String get monthlyDisplay =>
      _inr.format((payableAmount / 12).round().clamp(1, payableAmount.round()));

  static bool _parseBool(dynamic value, {required bool fallback}) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final normalized = value.trim().toLowerCase();
      if (const ['true', '1', 'yes', 'y'].contains(normalized)) return true;
      if (const ['false', '0', 'no', 'n'].contains(normalized)) return false;
    }
    return fallback;
  }

  factory SubscriptionPricing.fromMap(Map<String, dynamic> data) {
    final durationDays = (data['durationDays'] as num?)?.toInt();
    final currency = data['currency'] as String?;
    final hasOfferAmount = data['offerAmount'] != null;
    final hasLegacyRegular = data['regularAmount'] != null;

    late final double amount;
    late final double offerAmount;
    late final bool offerEnabled;

    if (hasOfferAmount) {
      // New schema: amount = original, offerAmount = offer.
      final parsedAmount = (data['amount'] as num?)?.toDouble();
      final parsedOffer = (data['offerAmount'] as num?)?.toDouble();
      amount = (parsedAmount != null && parsedAmount > 0)
          ? parsedAmount
          : SubscriptionPricing.defaults.amount;
      offerAmount = (parsedOffer != null && parsedOffer > 0)
          ? parsedOffer
          : SubscriptionPricing.defaults.offerAmount;
      offerEnabled = _parseBool(
        data['offerEnabled'],
        fallback: SubscriptionPricing.defaults.offerEnabled,
      );
    } else if (hasLegacyRegular) {
      // Legacy: amount was charge, regularAmount was list price.
      final parsedCharge = (data['amount'] as num?)?.toDouble();
      final parsedList = (data['regularAmount'] as num?)?.toDouble();
      amount = (parsedList != null && parsedList > 0)
          ? parsedList
          : SubscriptionPricing.defaults.amount;
      offerAmount = (parsedCharge != null && parsedCharge > 0)
          ? parsedCharge
          : SubscriptionPricing.defaults.offerAmount;
      offerEnabled = _parseBool(data['offerEnabled'], fallback: true);
    } else {
      final parsedAmount = (data['amount'] as num?)?.toDouble();
      amount = (parsedAmount != null && parsedAmount > 0)
          ? parsedAmount
          : SubscriptionPricing.defaults.amount;
      offerAmount = amount;
      offerEnabled = _parseBool(data['offerEnabled'], fallback: false);
    }

    return SubscriptionPricing(
      amount: amount,
      offerAmount: offerAmount,
      offerEnabled: offerEnabled,
      currency: (currency != null && currency.trim().isNotEmpty)
          ? currency.trim().toUpperCase()
          : SubscriptionPricing.defaults.currency,
      durationDays: (durationDays != null && durationDays > 0)
          ? durationDays
          : SubscriptionPricing.defaults.durationDays,
    );
  }
}

// Service to manage user subscription status.
//
// Access rules:
// - New users get a 30-day free trial from signup (`subscriptionStatus: trial`)
// - Paid users stay active for 365 days from `subscriptionDate`
// - Activation after payment is performed by Cloud Functions
// - Display / Cashfree charge amounts come from backend (not client constants)
class SubscriptionService {
  static final SubscriptionService _instance = SubscriptionService._internal();
  factory SubscriptionService() => _instance;
  SubscriptionService._internal();

  FirebaseFirestore get _firestore => FirebaseFirestore.instance;
  FirebaseAuth get _auth => FirebaseAuth.instance;
  final FirebaseFunctions _functions = FirebaseFunctions.instanceFor(
    region: 'asia-south1',
  );

  SubscriptionPricing _pricing = SubscriptionPricing.defaults;
  bool _pricingLoaded = false;

  /// Latest known pricing (defaults until [fetchPricing] succeeds).
  SubscriptionPricing get pricing => _pricing;

  // Paid subscription validity
  static const Duration subscriptionDuration = Duration(days: 365);

  // Free trial before paywall
  static const Duration trialDuration = Duration(days: 30);

  static const String statusTrial = 'trial';
  static const String statusActive = 'active';
  static const String statusInactive = 'inactive';

  // Get current user ID
  String? get _userId => _auth.currentUser?.uid;

  /// Loads offer price from Firestore / Cloud Function.
  /// Safe to call repeatedly; caches until [force] is true.
  Future<SubscriptionPricing> fetchPricing({bool force = false}) async {
    if (_pricingLoaded && !force) return _pricing;

    try {
      final doc = await _firestore
          .collection('app_config')
          .doc('subscription')
          .get()
          .timeout(const Duration(seconds: 8));

      if (doc.exists && doc.data() != null) {
        _pricing = SubscriptionPricing.fromMap(doc.data()!);
        _pricingLoaded = true;
        debugPrint(
          '[SubscriptionService] Pricing from Firestore: '
          'payable=${_pricing.priceLabel} original=${_pricing.originalPriceLabel} '
          'offerEnabled=${_pricing.offerEnabled}',
        );
        return _pricing;
      }
    } catch (e) {
      debugPrint('[SubscriptionService] Firestore pricing read failed: $e');
    }

    // Fallback: callable seeds app_config if missing.
    try {
      final callable = _functions.httpsCallable('getSubscriptionPricing');
      final result = await callable.call().timeout(const Duration(seconds: 12));
      final data = Map<String, dynamic>.from(result.data as Map);
      _pricing = SubscriptionPricing.fromMap(data);
      _pricingLoaded = true;
      debugPrint(
        '[SubscriptionService] Pricing from Cloud Function: '
        '${_pricing.priceLabel}',
      );
      return _pricing;
    } catch (e) {
      debugPrint(
        '[SubscriptionService] Pricing fetch failed, using defaults: $e',
      );
      _pricing = SubscriptionPricing.defaults;
      return _pricing;
    }
  }

  DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  // Key prefix for the last access expiry this device confirmed from Firestore.
  static const String _lastExpiryKeyPrefix = 'subscription_last_expiry_';

  /// Waits for Firebase Auth to restore the signed-in user (cold start on a
  /// slow device / simulator can report `currentUser` as null for a moment).
  Future<String?> _resolveUserId() async {
    final current = _userId;
    if (current != null) return current;
    try {
      final user = await _auth.authStateChanges().first.timeout(
        const Duration(seconds: 5),
      );
      return user?.uid;
    } catch (_) {
      return null;
    }
  }

  // Reads the user document from the server, falling back to the local cache
  // when the server cannot be reached. Returns null when the doc is missing.
  Future<Map<String, dynamic>?> _readUserData(String userId) async {
    final ref = _firestore.collection('users').doc(userId);
    DocumentSnapshot<Map<String, dynamic>> snap;
    try {
      snap = await ref.get().timeout(const Duration(seconds: 15));
    } catch (e) {
      debugPrint('[SubscriptionService] Server read failed, using cache: $e');
      snap = await ref
          .get(const GetOptions(source: Source.cache))
          .timeout(const Duration(seconds: 5));
    }
    if (!snap.exists) return null;
    return snap.data();
  }

  /// True when this device last confirmed a paid/trial window that has not
  /// yet ended. Used only when Firestore cannot be reached at all, so a
  /// slow or offline start does not lock out a customer who is still valid.
  Future<bool> isWithinLastKnownWindow([String? userId]) async {
    final uid = userId ?? await _resolveUserId();
    if (uid == null) return false;
    return lastKnownWindowOpen(uid);
  }

  /// Static so it can run without building the service (no Firebase needed).
  static Future<bool> lastKnownWindowOpen(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final millis = prefs.getInt('$_lastExpiryKeyPrefix$userId');
      if (millis == null) return false;
      return DateTime.now().isBefore(
        DateTime.fromMillisecondsSinceEpoch(millis),
      );
    } catch (_) {
      return false;
    }
  }

  Future<void> _rememberExpiry(String userId, DateTime expiry) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(
        '$_lastExpiryKeyPrefix$userId',
        expiry.millisecondsSinceEpoch,
      );
    } catch (e) {
      debugPrint('[SubscriptionService] Could not cache expiry: $e');
    }
  }

  // Check if user's subscription/trial is still valid.
  //
  // Decision rules:
  // - Firestore answers "no user doc" or "no trial/subscription" -> locked.
  // - Firestore answers with a window that has not ended -> open (and cached).
  // - Firestore cannot be reached (timeout, offline, simulator network) ->
  //   open only if this device last confirmed a window that is still running.
  //   Never locks a paying user out because of a transient network error.
  Future<bool> isSubscriptionValid() async {
    String? userId;
    try {
      userId = await _resolveUserId();
      if (userId == null) {
        debugPrint(
          '[SubscriptionService] No user logged in - subscription required',
        );
        return false;
      }

      final data = await _readUserData(userId);
      if (data == null) {
        debugPrint(
          '[SubscriptionService] User document not found - subscription required',
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
      if (isValid) await _rememberExpiry(userId, resolved.expiry);
      debugPrint(
        '[SubscriptionService] Access valid: $isValid '
        '(status: ${resolved.status}, expires: ${resolved.expiry})',
      );
      return isValid;
    } catch (e) {
      debugPrint('[SubscriptionService] Error checking subscription: $e');
      return await isWithinLastKnownWindow(userId);
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
      final remainingDays = isActive
          ? resolved.expiry.difference(now).inDays
          : 0;

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
  /// Handles legacy / console-edited docs where `subscriptionDate` is null:
  /// - `subscriptionStatus: active` → 365-day paid window (do not downgrade)
  /// - otherwise → 30-day trial from `trialStartedAt` / `createdAt`
  Future<_AccessWindow?> _resolveAccessWindow(
    String userId,
    Map<String, dynamic> data,
  ) async {
    final status = (data['subscriptionStatus'] as String?)?.toLowerCase();
    var start = _parseDate(data['subscriptionDate']);
    final trialStartedAt = _parseDate(data['trialStartedAt']);
    final createdAt = _parseDate(data['createdAt']);

    // Console / legacy: marked active but subscriptionDate never set.
    // Previously this fell through to trial-from-createdAt and denied access
    // once that 30-day window ended — even with status "active".
    if (start == null && status == statusActive) {
      start = trialStartedAt ?? createdAt ?? DateTime.now();
      final expiry = start.add(subscriptionDuration);
      try {
        await _firestore.collection('users').doc(userId).set({
          'subscriptionDate': Timestamp.fromDate(start),
          'subscriptionStatus': statusActive,
        }, SetOptions(merge: true));
      } catch (e) {
        debugPrint(
          '[SubscriptionService] Active subscriptionDate backfill failed: $e',
        );
      }
      debugPrint(
        '[SubscriptionService] Active with null subscriptionDate — '
        'using start=$start expiry=$expiry',
      );
      return _AccessWindow(start: start, expiry: expiry, status: statusActive);
    }

    // No subscriptionDate → trial from trialStartedAt (preferred) or createdAt.
    if (start == null) {
      start = trialStartedAt ?? createdAt ?? DateTime.now();
      final trialExpiry = start.add(trialDuration);
      if (DateTime.now().isBefore(trialExpiry)) {
        try {
          await _firestore.collection('users').doc(userId).set({
            'subscriptionDate': Timestamp.fromDate(start),
            // Never overwrite an explicit active flag here.
            if (status != statusActive) 'subscriptionStatus': statusTrial,
            'trialStartedAt': Timestamp.fromDate(trialStartedAt ?? start),
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

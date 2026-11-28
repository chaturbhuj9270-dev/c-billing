import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:c_billing/core/access/tenant_context.dart';

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
// **Source of truth = Cloud Function `getSubscriptionAccess`** (server clock).
// Paid: `subscriptionExpiresAt` written only by Functions on payment verify.
// Trial: `trialExpiresAt` written only by Functions on first access check.
// Local cache stores the last server-issued expiresAt for offline use only —
// the app never invents a year/trial end date itself while online.
class SubscriptionService {
  static final SubscriptionService _instance = SubscriptionService._internal();
  factory SubscriptionService() => _instance;
  SubscriptionService._internal();

  FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  static const String _functionsRegion = 'asia-south1';

  FirebaseFunctions get _functions =>
      FirebaseFunctions.instanceFor(region: _functionsRegion);

  // Subscription price in INR
  static const double subscriptionPrice = 3999.0;

  // Display price (with thousands separator)
  static const String subscriptionPriceDisplay = '3,999';

  // Paid subscription validity duration
  static const Duration subscriptionDuration = Duration(days: 365);

  // Free trial after registration
  static const Duration freeTrialDuration = Duration(days: 30);
  static const Duration trialDuration = freeTrialDuration;

  static const String statusTrial = 'trial';
  static const String statusActive = 'active';
  static const String statusInactive = 'inactive';

  SubscriptionPricing _pricing = SubscriptionPricing.defaults;
  bool _pricingLoaded = false;

  /// Latest known pricing (defaults until [fetchPricing] succeeds).
  SubscriptionPricing get pricing => _pricing;

  static const String _prefsExpiryKeyPrefix = 'sub_access_expiry_';
  static const String _prefsSourceKeyPrefix = 'sub_access_source_';

  // Get current user ID (auth uid for trial ownership; tenant for shop data)
  String? get _userId => TenantContext.dataOwnerIdOrNull;

  String? get _authUid => FirebaseAuth.instance.currentUser?.uid;

  /// Prefer auth uid for caching trial — employees share dataOwner but trial
  /// is on the shop owner's user doc; cache key still uses owner when known.
  String? get _cacheUid => _userId ?? _authUid;

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

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  bool _isActiveExpiry(DateTime? expiry) {
    if (expiry == null) return false;
    return DateTime.now().isBefore(expiry);
  }

  Future<void> _cacheAccessExpiry(DateTime expiry, {required String source}) async {
    final uid = _cacheUid;
    if (uid == null) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('$_prefsExpiryKeyPrefix$uid', expiry.toIso8601String());
      await prefs.setString('$_prefsSourceKeyPrefix$uid', source);
    } catch (e) {
      debugPrint('[SubscriptionService] Cache write failed: $e');
    }
  }

  Future<DateTime?> _cachedAccessExpiry() async {
    final uid = _cacheUid;
    if (uid == null) return null;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('$_prefsExpiryKeyPrefix$uid');
      if (raw == null || raw.isEmpty) return null;
      return DateTime.tryParse(raw);
    } catch (e) {
      debugPrint('[SubscriptionService] Cache read failed: $e');
      return null;
    }
  }

  /// Offline / fail-open: Auth account age is authoritative for free trial.
  DateTime? _authCreationTrialExpiry() {
    final created = FirebaseAuth.instance.currentUser?.metadata.creationTime;
    if (created == null) return null;
    return created.add(freeTrialDuration);
  }

  /// Fast offline check used by splash timeouts — never hits the network.
  Future<bool> hasOfflineEntitlement() =>
      _allowFromLocalFallbacks(reason: 'offline-only');

  // Last access expiry confirmed from Firestore by the ledger-line builds.
  static const String _lastExpiryKeyPrefix = 'subscription_last_expiry_';

  /// True when this device last confirmed a paid/trial window that has not
  /// yet ended. Used only when the server cannot be reached at all, so a
  /// slow or offline start does not lock out a customer who is still valid.
  Future<bool> isWithinLastKnownWindow([String? userId]) async {
    if (await hasOfflineEntitlement()) return true;
    final uid = userId ?? _cacheUid;
    if (uid == null) return false;
    if (await lastKnownWindowOpen(uid)) return true;
    return _allowFromUserDoc(await _accessFromUserDoc(cacheOnly: true));
  }

  /// Static so it can run without building the service (no Firebase needed).
  static Future<bool> lastKnownWindowOpen(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final millis = prefs.getInt('$_lastExpiryKeyPrefix$userId');
      if (millis != null &&
          DateTime.now().isBefore(
            DateTime.fromMillisecondsSinceEpoch(millis),
          )) {
        return true;
      }
      final raw = prefs.getString('$_prefsExpiryKeyPrefix$userId');
      final cached = raw == null ? null : DateTime.tryParse(raw);
      return cached != null && DateTime.now().isBefore(cached);
    } catch (_) {
      return false;
    }
  }

  /// Access expiry from a `users/{uid}` document. Must match
  /// `resolveSubscriptionAccess` in functions/index.js: paid wins, then trial.
  /// `subscriptionDate` counts as a paid year only when status is `active`
  /// (older trial builds also wrote it as the trial start).
  static DateTime? accessExpiryFromUserData(
    Map<String, dynamic> data, {
    DateTime? authCreatedAt,
    DateTime? now,
  }) {
    final status = data['subscriptionStatus']?.toString().toLowerCase();
    final subDate = _parseDate(data['subscriptionDate']);
    final trialStartedAt = _parseDate(data['trialStartedAt']);
    final createdAt = _parseDate(data['createdAt']);

    final paidExpires = _parseDate(data['subscriptionExpiresAt']);
    if (paidExpires != null) return paidExpires;

    if (status == statusActive) {
      final start = subDate ?? trialStartedAt ?? createdAt ?? now ?? DateTime.now();
      return start.add(subscriptionDuration);
    }

    final trialExpires = _parseDate(data['trialExpiresAt']);
    if (trialExpires != null) return trialExpires;

    final trialStart = trialStartedAt ?? subDate ?? createdAt ?? authCreatedAt;
    return trialStart?.add(freeTrialDuration);
  }

  /// Reads the data owner's user document (server first, then the Firestore
  /// offline cache) and caches the resulting expiry. Returns null when the
  /// document cannot be read at all, so callers fall back to local caches.
  Future<({DateTime? expiry})?> _accessFromUserDoc({bool cacheOnly = false}) async {
    final uid = _userId ?? _authUid;
    if (uid == null) return null;
    final ref = _firestore.collection('users').doc(uid);

    DocumentSnapshot<Map<String, dynamic>>? snap;
    if (!cacheOnly) {
      try {
        snap = await ref
            .get(const GetOptions(source: Source.server))
            .timeout(const Duration(seconds: 6));
      } catch (e) {
        debugPrint('[SubscriptionService] User doc server read failed: $e');
      }
    }
    if (snap == null) {
      try {
        snap = await ref
            .get(const GetOptions(source: Source.cache))
            .timeout(const Duration(seconds: 2));
      } catch (_) {
        return null;
      }
    }

    final data = snap.data();
    if (data == null) {
      // No profile yet: same as the server, a new account is on its trial.
      return (expiry: _authCreationTrialExpiry());
    }
    final expiry = accessExpiryFromUserData(
      data,
      authCreatedAt: FirebaseAuth.instance.currentUser?.metadata.creationTime,
    );
    debugPrint('[SubscriptionService] User doc access expiry: $expiry');
    return (expiry: expiry);
  }

  Future<bool> _allowFromUserDoc(({DateTime? expiry})? doc) async {
    final expiry = doc?.expiry;
    if (!_isActiveExpiry(expiry)) return false;
    await _cacheAccessExpiry(expiry!, source: 'user-doc');
    return true;
  }

  /// Splash / session restore gate: trust local entitlement immediately when
  /// present, and only block on a short network budget when offline says no.
  Future<bool> isSubscriptionValidQuick({
    Duration networkBudget = const Duration(seconds: 7),
  }) async {
    if (await hasOfflineEntitlement()) {
      // Refresh server cache in the background; do not hold the splash.
      unawaited(
        isSubscriptionValid().then(
          (_) {},
          onError: (Object e, StackTrace _) {
            debugPrint('[SubscriptionService] background refresh failed: $e');
          },
        ),
      );
      return true;
    }

    try {
      return await isSubscriptionValid().timeout(
        networkBudget,
        onTimeout: () {
          debugPrint(
            '[SubscriptionService] Quick check timed out after '
            '${networkBudget.inSeconds}s — using last known window',
          );
          return isWithinLastKnownWindow();
        },
      );
    } catch (e) {
      debugPrint('[SubscriptionService] Quick check failed: $e');
      return isWithinLastKnownWindow();
    }
  }

  Future<bool> _allowFromLocalFallbacks({String reason = ''}) async {
    final cached = await _cachedAccessExpiry();
    if (_isActiveExpiry(cached)) {
      debugPrint(
        '[SubscriptionService] Allowing via local cache (expires: $cached) [$reason]',
      );
      return true;
    }

    final authTrialExpiry = _authCreationTrialExpiry();
    if (_isActiveExpiry(authTrialExpiry)) {
      debugPrint(
        '[SubscriptionService] Allowing via Auth creationTime trial '
        '(expires: $authTrialExpiry) [$reason]',
      );
      // Persist so subsequent offline opens stay consistent.
      await _cacheAccessExpiry(authTrialExpiry!, source: 'trial');
      return true;
    }

    debugPrint(
      '[SubscriptionService] No local/auth trial access [$reason] '
      '(cached: $cached, authTrial: $authTrialExpiry)',
    );
    return false;
  }

  /// Ask Cloud Functions for access using **server time + server-written expiry**.
  Future<Map<String, dynamic>?> fetchAccessFromApi() async {
    try {
      final callable = _functions.httpsCallable('getSubscriptionAccess');
      final result = await callable.call().timeout(const Duration(seconds: 8));
      final raw = result.data;
      if (raw is! Map) return null;
      return Map<String, dynamic>.from(raw);
    } catch (e) {
      debugPrint('[SubscriptionService] getSubscriptionAccess failed: $e');
      return null;
    }
  }

  // Check if user's subscription / free trial is valid.
  // Online: trust API only. Offline: last server-issued expiresAt (never invent).
  Future<bool> isSubscriptionValid() async {
    try {
      if (FirebaseAuth.instance.currentUser == null && _userId == null) {
        debugPrint(
          '[SubscriptionService] No user logged in - subscription required',
        );
        return false;
      }

      // Read the user doc alongside the API so a missing or slow function
      // does not add its own delay before the fallback answer.
      final docFuture = _accessFromUserDoc();
      final api = await fetchAccessFromApi();
      if (api != null) {
        unawaited(docFuture.then((_) {}, onError: (Object _, StackTrace _) {}));
        final allowed = api['allowed'] == true;
        final expiresRaw = api['expiresAt']?.toString();
        final expiresAt =
            expiresRaw != null ? DateTime.tryParse(expiresRaw) : null;
        final source = api['source']?.toString() ?? 'api';
        if (expiresAt != null) {
          await _cacheAccessExpiry(expiresAt, source: source);
        }
        debugPrint(
          '[SubscriptionService] API access allowed=$allowed '
          '(expires: $expiresAt, status: ${api['status']}, '
          'serverNow: ${api['serverNow']})',
        );
        return allowed;
      }

      // API down or not deployed — decide from the user document.
      if (await _allowFromUserDoc(await docFuture)) return true;

      // Offline / API down — use last server-issued expiry only.
      if (await _allowFromLocalFallbacks(reason: 'api-unavailable')) {
        return true;
      }
      return isWithinLastKnownWindow();
    } catch (e) {
      debugPrint('[SubscriptionService] Error checking subscription: $e');
      if (await _allowFromLocalFallbacks(reason: 'unexpected-error')) {
        return true;
      }
      return isWithinLastKnownWindow();
    }
  }

  // Get access expiry date — prefers server API `expiresAt`.
  Future<DateTime?> getExpiryDate() async {
    try {
      final api = await fetchAccessFromApi();
      if (api != null) {
        final expiresRaw = api['expiresAt']?.toString();
        final expiresAt =
            expiresRaw != null ? DateTime.tryParse(expiresRaw) : null;
        if (expiresAt != null) {
          await _cacheAccessExpiry(
            expiresAt,
            source: api['source']?.toString() ?? 'api',
          );
          return expiresAt;
        }
      }
      final doc = await _accessFromUserDoc();
      if (doc?.expiry != null) return doc!.expiry;
      return await _cachedAccessExpiry() ?? _authCreationTrialExpiry();
    } catch (e) {
      debugPrint('[SubscriptionService] Error getting expiry date: $e');
      return await _cachedAccessExpiry() ?? _authCreationTrialExpiry();
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
      if (data == null) {
        return _isActiveExpiry(_authCreationTrialExpiry());
      }
      if (_parseDate(data['subscriptionDate']) != null) return false;
      final trialStart =
          _parseDate(data['trialStartedAt']) ?? _parseDate(data['createdAt']);
      if (trialStart == null) {
        return _isActiveExpiry(_authCreationTrialExpiry());
      }
      return _isActiveExpiry(trialStart.add(freeTrialDuration));
    } catch (_) {
      return _isActiveExpiry(_authCreationTrialExpiry());
    }
  }

  // Wait until Firestore reflects an active subscription (after Play verify).
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
      final trialStart = DateTime.now();
      await FirebaseFirestore.instance.collection('users').doc(userId).set({
        'subscriptionDate': null,
        'subscriptionStatus': 'trial',
        'trialStartedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Cache immediately so splash/login never flash the paywall.
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        '$_prefsExpiryKeyPrefix$userId',
        trialStart.add(freeTrialDuration).toIso8601String(),
      );
      await prefs.setString('$_prefsSourceKeyPrefix$userId', 'trial');

      debugPrint(
        '[SubscriptionService] Free trial started for user: $userId',
      );
    } catch (e) {
      debugPrint('[SubscriptionService] Error setting initial trial: $e');
      // Still cache locally so the free month works offline.
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(
          '$_prefsExpiryKeyPrefix$userId',
          DateTime.now().add(freeTrialDuration).toIso8601String(),
        );
        await prefs.setString('$_prefsSourceKeyPrefix$userId', 'trial');
      } catch (_) {}
    }
  }

  /// Call right after signup so the free month is locked in on-device.
  static Future<void> cacheTrialStartLocally(String userId, {DateTime? start}) async {
    final trialStart = start ?? DateTime.now();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        '$_prefsExpiryKeyPrefix$userId',
        trialStart.add(freeTrialDuration).toIso8601String(),
      );
      await prefs.setString('$_prefsSourceKeyPrefix$userId', 'trial');
    } catch (e) {
      debugPrint('[SubscriptionService] Local trial cache failed: $e');
    }
  }

  /// After paid activation, refresh local cache so offline stays unlocked.
  Future<void> cachePaidSubscriptionLocally(DateTime subscriptionDate) async {
    await _cacheAccessExpiry(
      subscriptionDate.add(subscriptionDuration),
      source: 'paid',
    );
  }

  /// Prefer caching the exact `expiresAt` returned by the payment verify API.
  Future<void> cacheServerExpiresAt(String? isoExpiresAt, {String source = 'paid'}) async {
    if (isoExpiresAt == null || isoExpiresAt.isEmpty) return;
    final parsed = DateTime.tryParse(isoExpiresAt);
    if (parsed == null) return;
    await _cacheAccessExpiry(parsed, source: source);
  }

  // Get subscription status details (API-first).
  Future<Map<String, dynamic>> getSubscriptionStatus() async {
    try {
      if (FirebaseAuth.instance.currentUser == null && _userId == null) {
        return {'isActive': false, 'message': 'Not logged in'};
      }

      final api = await fetchAccessFromApi();
      if (api != null) {
        final allowed = api['allowed'] == true;
        final expiresAt = api['expiresAt'] != null
            ? DateTime.tryParse(api['expiresAt'].toString())
            : null;
        final source = api['source']?.toString();
        final onTrial = source == 'trial' && allowed;
        if (expiresAt != null) {
          await _cacheAccessExpiry(expiresAt, source: source ?? 'api');
        }
        return {
          'isActive': allowed,
          'isTrial': onTrial,
          'message': !allowed
              ? (source == 'paid' ? 'Subscription expired' : 'Free trial ended')
              : (onTrial ? 'Free trial active' : 'Subscription active'),
          'expiryDate': expiresAt,
          'remainingDays': api['remainingDays'] ?? 0,
          'serverNow': api['serverNow'],
          'source': source,
        };
      }

      final expiry =
          await _cachedAccessExpiry() ?? _authCreationTrialExpiry();
      final active = _isActiveExpiry(expiry);
      return {
        'isActive': active,
        'isTrial': active,
        'message': active
            ? 'Free trial / subscription active (offline)'
            : 'Unable to verify subscription',
        'expiryDate': expiry,
        'remainingDays': active && expiry != null
            ? expiry.difference(DateTime.now()).inDays
            : 0,
      };
    } catch (e) {
      debugPrint('[SubscriptionService] Error getting subscription status: $e');
      return {'isActive': false, 'message': 'Error checking subscription'};
    }
  }
}

import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:c_billing/core/access/tenant_context.dart';

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

  static const String _prefsExpiryKeyPrefix = 'sub_access_expiry_';
  static const String _prefsSourceKeyPrefix = 'sub_access_source_';

  // Get current user ID (auth uid for trial ownership; tenant for shop data)
  String? get _userId => TenantContext.dataOwnerIdOrNull;

  String? get _authUid => FirebaseAuth.instance.currentUser?.uid;

  /// Prefer auth uid for caching trial — employees share dataOwner but trial
  /// is on the shop owner's user doc; cache key still uses owner when known.
  String? get _cacheUid => _userId ?? _authUid;

  DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
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
      final result = await callable.call().timeout(const Duration(seconds: 12));
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

      final api = await fetchAccessFromApi();
      if (api != null) {
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

      // Offline / API down — use last server-issued expiry only.
      return _allowFromLocalFallbacks(reason: 'api-unavailable');
    } catch (e) {
      debugPrint('[SubscriptionService] Error checking subscription: $e');
      return _allowFromLocalFallbacks(reason: 'unexpected-error');
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

import 'dart:async';
import 'dart:io';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';

import '../config/subscription_products.dart';

/// Result of a Google Play / App Store subscription purchase.
class PlayBillingResult {
  final bool success;
  final String status;
  final String message;
  final String? productId;
  final String? purchaseId;
  /// Server-written ISO expiry from `verifyPlayPurchase` (preferred for cache).
  final String? expiresAt;

  const PlayBillingResult({
    required this.success,
    required this.status,
    required this.message,
    this.productId,
    this.purchaseId,
    this.expiresAt,
  });
}

/// Google Play Billing in-app purchase for the yearly subscription.
///
/// Flow:
/// 1. Load product `cbilling_yearly` from Play
/// 2. Start native purchase sheet with subscription [offerToken]
/// 3. On success, verify token via Cloud Function `verifyPlayPurchase`
/// 4. Function activates 1-year access and returns `expiresAt`
class PlayBillingService {
  static final PlayBillingService _instance = PlayBillingService._internal();
  factory PlayBillingService() => _instance;
  PlayBillingService._internal();

  static const String _functionsRegion = 'asia-south1';

  final InAppPurchase _iap = InAppPurchase.instance;
  final FirebaseFunctions _functions = FirebaseFunctions.instanceFor(
    region: _functionsRegion,
  );

  StreamSubscription<List<PurchaseDetails>>? _purchaseSub;
  Completer<PlayBillingResult>? _pendingPurchase;
  ProductDetails? _yearlyProduct;
  bool _initialized = false;
  bool _storeAvailable = false;

  ProductDetails? get yearlyProduct => _yearlyProduct;
  bool get isStoreAvailable => _storeAvailable;

  String get displayPrice =>
      _yearlyProduct?.price ?? SubscriptionProducts.fallbackPriceLabel;

  /// Initialize store connection and load the yearly subscription product.
  Future<void> initialize() async {
    if (_initialized) {
      // Refresh product price if already initialized.
      try {
        await loadProducts();
      } catch (_) {}
      return;
    }

    final available = await _iap.isAvailable();
    _storeAvailable = available;
    if (!available) {
      throw StateError(
        'Google Play Billing is not available on this device. '
        'Install/update Play Store and sign in with a license tester.',
      );
    }

    _purchaseSub ??= _iap.purchaseStream.listen(
      _onPurchaseUpdates,
      onError: (Object e) {
        debugPrint('[PlayBilling] purchaseStream error: $e');
        _completePending(
          PlayBillingResult(
            success: false,
            status: 'STREAM_ERROR',
            message: e.toString(),
          ),
        );
      },
    );

    await loadProducts();
    _initialized = true;
  }

  Future<void> loadProducts() async {
    final response = await _iap.queryProductDetails({
      SubscriptionProducts.yearlyProductId,
    });

    if (response.error != null) {
      throw StateError(
        'Failed to load products: ${response.error!.message}',
      );
    }

    if (response.notFoundIDs.contains(SubscriptionProducts.yearlyProductId) ||
        response.productDetails.isEmpty) {
      throw StateError(
        'Product "${SubscriptionProducts.yearlyProductId}" not found in Play. '
        'Create a Subscription with this product ID in Play Console, '
        'activate a base plan, and use a license tester account.',
      );
    }

    _yearlyProduct = _pickYearlyOffer(response.productDetails);
    debugPrint(
      '[PlayBilling] Loaded ${_yearlyProduct!.id} @ ${_yearlyProduct!.price}'
      '${_yearlyProduct is GooglePlayProductDetails ? ' (offer=${(_yearlyProduct as GooglePlayProductDetails).offerToken != null})' : ''}',
    );
  }

  /// Prefer the base plan / first paid offer for the yearly subscription.
  ProductDetails _pickYearlyOffer(List<ProductDetails> products) {
    final matches = products
        .where((p) => p.id == SubscriptionProducts.yearlyProductId)
        .toList();
    if (matches.isEmpty) return products.first;

    // Android returns one ProductDetails per offer. Prefer base plan
    // (offerId empty/null) over intro/promo offers.
    GooglePlayProductDetails? base;
    for (final p in matches) {
      if (p is! GooglePlayProductDetails) continue;
      final idx = p.subscriptionIndex;
      final offers = p.productDetails.subscriptionOfferDetails;
      if (idx == null || offers == null || idx >= offers.length) {
        base ??= p;
        continue;
      }
      final offerId = offers[idx].offerId;
      if (offerId == null || offerId.isEmpty) {
        return p;
      }
      base ??= p;
    }
    return base ?? matches.first;
  }

  /// Starts Google Play purchase for the yearly plan.
  Future<PlayBillingResult> purchaseYearlySubscription() async {
    if (_pendingPurchase != null && !_pendingPurchase!.isCompleted) {
      throw StateError('A purchase is already in progress');
    }

    await initialize();

    final product = _yearlyProduct;
    if (product == null) {
      return const PlayBillingResult(
        success: false,
        status: 'PRODUCT_MISSING',
        message: 'Subscription product is not available',
      );
    }

    _pendingPurchase = Completer<PlayBillingResult>();

    final uid = FirebaseAuth.instance.currentUser?.uid;
    final PurchaseParam param;
    if (Platform.isAndroid && product is GooglePlayProductDetails) {
      // Billing Library 5+ requires offerToken for subscriptions.
      param = GooglePlayPurchaseParam(
        productDetails: product,
        applicationUserName: uid,
        offerToken: product.offerToken,
      );
    } else {
      param = PurchaseParam(
        productDetails: product,
        applicationUserName: uid,
      );
    }

    final started = await _iap.buyNonConsumable(purchaseParam: param);
    if (!started) {
      _completePending(
        const PlayBillingResult(
          success: false,
          status: 'START_FAILED',
          message: 'Could not start Google Play purchase',
        ),
      );
    }

    return _pendingPurchase!.future.timeout(
      const Duration(minutes: 15),
      onTimeout: () => const PlayBillingResult(
        success: false,
        status: 'TIMEOUT',
        message: 'Purchase timed out. If charged, tap Restore Purchase.',
      ),
    );
  }

  /// Restores prior store purchases and re-activates subscription when valid.
  Future<PlayBillingResult> restorePurchases() async {
    if (_pendingPurchase != null && !_pendingPurchase!.isCompleted) {
      throw StateError('A purchase is already in progress');
    }

    await initialize();
    _pendingPurchase = Completer<PlayBillingResult>();

    // Android: also query active purchases directly (more reliable than restore alone).
    if (Platform.isAndroid) {
      try {
        final addition = _iap
            .getPlatformAddition<InAppPurchaseAndroidPlatformAddition>();
        final past = await addition.queryPastPurchases();
        if (past.error == null && past.pastPurchases.isNotEmpty) {
          final yearly = past.pastPurchases.where(
            (p) => p.productID == SubscriptionProducts.yearlyProductId,
          );
          if (yearly.isNotEmpty) {
            await _onPurchaseUpdates(yearly.toList());
            if (_pendingPurchase != null && _pendingPurchase!.isCompleted) {
              return _pendingPurchase!.future;
            }
          }
        }
      } catch (e) {
        debugPrint('[PlayBilling] queryPastPurchases failed: $e');
      }
    }

    unawaited(
      Future<void>.delayed(const Duration(seconds: 10), () {
        if (_pendingPurchase != null && !_pendingPurchase!.isCompleted) {
          _completePending(
            const PlayBillingResult(
              success: false,
              status: 'NOTHING_TO_RESTORE',
              message: 'No previous subscription found to restore',
            ),
          );
        }
      }),
    );

    await _iap.restorePurchases();
    return _pendingPurchase!.future;
  }

  Future<void> _onPurchaseUpdates(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      // Ignore other SKUs.
      if (purchase.productID != SubscriptionProducts.yearlyProductId &&
          purchase.status != PurchaseStatus.error &&
          purchase.status != PurchaseStatus.canceled) {
        if (purchase.pendingCompletePurchase) {
          await _iap.completePurchase(purchase);
        }
        continue;
      }

      switch (purchase.status) {
        case PurchaseStatus.pending:
          debugPrint('[PlayBilling] pending: ${purchase.productID}');
          break;
        case PurchaseStatus.error:
          _completePending(
            PlayBillingResult(
              success: false,
              status: 'ERROR',
              message:
                  purchase.error?.message ?? 'Google Play purchase failed',
              productId: purchase.productID,
              purchaseId: purchase.purchaseID,
            ),
          );
          if (purchase.pendingCompletePurchase) {
            await _iap.completePurchase(purchase);
          }
          break;
        case PurchaseStatus.canceled:
          _completePending(
            PlayBillingResult(
              success: false,
              status: 'CANCELED',
              message: 'Purchase cancelled',
              productId: purchase.productID,
              purchaseId: purchase.purchaseID,
            ),
          );
          if (purchase.pendingCompletePurchase) {
            await _iap.completePurchase(purchase);
          }
          break;
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          try {
            final verified = await _verifyWithBackend(purchase);
            if (purchase.pendingCompletePurchase) {
              await _iap.completePurchase(purchase);
            }
            _completePending(verified);
          } catch (e) {
            debugPrint('[PlayBilling] verify failed: $e');
            // Still complete so Play does not keep retrying forever;
            // user can Restore after Functions/secret is fixed.
            if (purchase.pendingCompletePurchase) {
              try {
                await _iap.completePurchase(purchase);
              } catch (_) {}
            }
            _completePending(
              PlayBillingResult(
                success: false,
                status: 'VERIFY_ERROR',
                message: 'Purchase received but verification failed: $e',
                productId: purchase.productID,
                purchaseId: purchase.purchaseID,
              ),
            );
          }
          break;
      }
    }
  }

  Future<PlayBillingResult> _verifyWithBackend(PurchaseDetails purchase) async {
    String purchaseToken = '';
    String packageName = SubscriptionProducts.androidPackageName;

    if (Platform.isAndroid && purchase is GooglePlayPurchaseDetails) {
      purchaseToken = purchase.billingClientPurchase.purchaseToken;
      // Prefer package from Play response when present.
      final pkg = purchase.billingClientPurchase.packageName;
      if (pkg.isNotEmpty) packageName = pkg;
    } else {
      purchaseToken = purchase.verificationData.serverVerificationData;
    }

    if (purchaseToken.isEmpty) {
      throw StateError('Missing purchase token');
    }

    final callable = _functions.httpsCallable('verifyPlayPurchase');
    final result = await callable.call(<String, dynamic>{
      'productId': purchase.productID,
      'purchaseToken': purchaseToken,
      'packageName': packageName,
      'purchaseId': purchase.purchaseID,
      'source': Platform.isIOS ? 'app_store' : 'google_play',
      'localVerificationData':
          purchase.verificationData.localVerificationData,
    });

    final data = Map<String, dynamic>.from(result.data as Map);
    final success = data['success'] == true;
    return PlayBillingResult(
      success: success,
      status: (data['status'] as String?) ?? (success ? 'ACTIVE' : 'FAILED'),
      message:
          (data['message'] as String?) ??
          (success
              ? 'Subscription activated'
              : 'Could not verify Google Play purchase'),
      productId: purchase.productID,
      purchaseId: purchase.purchaseID,
      expiresAt: data['expiresAt']?.toString(),
    );
  }

  void _completePending(PlayBillingResult result) {
    final completer = _pendingPurchase;
    if (completer != null && !completer.isCompleted) {
      completer.complete(result);
    }
    _pendingPurchase = null;
  }

  Future<void> dispose() async {
    await _purchaseSub?.cancel();
    _purchaseSub = null;
    _initialized = false;
  }
}

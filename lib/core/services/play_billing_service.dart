import 'dart:async';
import 'dart:io';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';

import '../config/subscription_products.dart';

// Result of a Google Play / App Store subscription purchase.
class PlayBillingResult {
  final bool success;
  final String status;
  final String message;
  final String? productId;
  final String? purchaseId;

  const PlayBillingResult({
    required this.success,
    required this.status,
    required this.message,
    this.productId,
    this.purchaseId,
  });
}

// Google Play Billing (and StoreKit on iOS) for the yearly subscription.
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

  ProductDetails? get yearlyProduct => _yearlyProduct;

  String get displayPrice =>
      _yearlyProduct?.price ?? SubscriptionProducts.fallbackPriceLabel;

  bool get hasProduct => _yearlyProduct != null;

  // Initialize store connection and load the yearly subscription product.
  Future<void> initialize({bool forceReload = false}) async {
    if (_initialized && !forceReload && _yearlyProduct != null) return;

    final available = await _iap.isAvailable();
    if (!available) {
      _initialized = false;
      throw StateError(
        'Google Play Billing is not available. '
        'Use a real Android device/emulator with Play Store, '
        'and a license-tester account.',
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
      _yearlyProduct = null;
      throw StateError(
        'Failed to load products: ${response.error!.message}',
      );
    }

    if (response.productDetails.isEmpty) {
      _yearlyProduct = null;
      throw StateError(
        'Product "${SubscriptionProducts.yearlyProductId}" not found. '
        'Create a Subscription with that ID in Play Console and use a '
        'license tester account on a signed build.',
      );
    }

    _yearlyProduct = _pickBestSubscriptionOffer(response.productDetails);
    debugPrint(
      '[PlayBilling] Loaded product=${_yearlyProduct?.id} '
      'price=${_yearlyProduct?.price} '
      'offer=${_yearlyProduct is GooglePlayProductDetails ? (_yearlyProduct as GooglePlayProductDetails).offerToken != null : 'n/a'}',
    );
  }

  /// Prefer the base plan (no offerId), otherwise first offer with a token.
  ProductDetails _pickBestSubscriptionOffer(List<ProductDetails> details) {
    GooglePlayProductDetails? basePlan;
    GooglePlayProductDetails? anyWithToken;

    for (final detail in details) {
      if (detail is! GooglePlayProductDetails) continue;
      final token = detail.offerToken;
      if (token == null || token.isEmpty) continue;

      anyWithToken ??= detail;
      final index = detail.subscriptionIndex;
      final offers = detail.productDetails.subscriptionOfferDetails;
      if (index != null && offers != null && index < offers.length) {
        final offerId = offers[index].offerId;
        if (offerId == null || offerId.isEmpty) {
          basePlan = detail;
          break;
        }
      }
    }

    return basePlan ?? anyWithToken ?? details.first;
  }

  // Starts Google Play / App Store purchase for the yearly plan.
  Future<PlayBillingResult> purchaseYearlySubscription() async {
    if (_pendingPurchase != null && !_pendingPurchase!.isCompleted) {
      throw StateError('A purchase is already in progress');
    }

    try {
      await initialize(forceReload: _yearlyProduct == null);
    } catch (e) {
      return PlayBillingResult(
        success: false,
        status: 'INIT_FAILED',
        message: e.toString(),
      );
    }

    final product = _yearlyProduct;
    if (product == null) {
      return const PlayBillingResult(
        success: false,
        status: 'PRODUCT_MISSING',
        message: 'Subscription product is not available',
      );
    }

    _pendingPurchase = Completer<PlayBillingResult>();

    final PurchaseParam param;
    if (product is GooglePlayProductDetails) {
      final offerToken = product.offerToken;
      if (offerToken == null || offerToken.isEmpty) {
        _pendingPurchase = null;
        return const PlayBillingResult(
          success: false,
          status: 'OFFER_MISSING',
          message:
              'Google Play subscription offer is missing. '
              'Activate a base plan for "cbilling_yearly" in Play Console.',
        );
      }
      param = GooglePlayPurchaseParam(
        productDetails: product,
        offerToken: offerToken,
        applicationUserName: FirebaseAuth.instance.currentUser?.uid,
      );
    } else {
      param = PurchaseParam(
        productDetails: product,
        applicationUserName: FirebaseAuth.instance.currentUser?.uid,
      );
    }

    debugPrint(
      '[PlayBilling] Starting purchase for ${product.id} '
      '(${product.runtimeType})',
    );

    bool started;
    try {
      started = await _iap.buyNonConsumable(purchaseParam: param);
    } catch (e) {
      _pendingPurchase = null;
      return PlayBillingResult(
        success: false,
        status: 'START_EXCEPTION',
        message: 'Could not open Google Play: $e',
        productId: product.id,
      );
    }

    if (!started) {
      _completePending(
        const PlayBillingResult(
          success: false,
          status: 'START_FAILED',
          message:
              'Could not start Google Play purchase. '
              'Check Play Store login and that the product is active.',
        ),
      );
    }

    return _pendingPurchase!.future.timeout(
      const Duration(minutes: 15),
      onTimeout: () {
        _pendingPurchase = null;
        return const PlayBillingResult(
          success: false,
          status: 'TIMEOUT',
          message: 'Purchase timed out. If charged, tap Restore Purchases.',
        );
      },
    );
  }

  // Restores prior store purchases and re-activates subscription when valid.
  Future<PlayBillingResult> restorePurchases() async {
    if (_pendingPurchase != null && !_pendingPurchase!.isCompleted) {
      throw StateError('A purchase is already in progress');
    }

    await initialize();
    _pendingPurchase = Completer<PlayBillingResult>();

    // If nothing comes back, resolve after a short wait.
    unawaited(
      Future<void>.delayed(const Duration(seconds: 8), () {
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
    final String purchaseToken =
        Platform.isAndroid && purchase is GooglePlayPurchaseDetails
        ? purchase.billingClientPurchase.purchaseToken
        : purchase.verificationData.serverVerificationData;

    if (purchaseToken.isEmpty) {
      throw StateError('Missing purchase token');
    }

    final callable = _functions.httpsCallable('verifyPlayPurchase');
    final result = await callable.call(<String, dynamic>{
      'productId': purchase.productID,
      'purchaseToken': purchaseToken,
      'packageName': SubscriptionProducts.androidPackageName,
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

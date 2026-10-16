import 'dart:async';
import 'dart:io';

import 'package:cloud_functions/cloud_functions.dart';
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

  const PlayBillingResult({
    required this.success,
    required this.status,
    required this.message,
    this.productId,
    this.purchaseId,
  });
}

/// Google Play Billing (and StoreKit on iOS) for the yearly subscription.
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

  /// Initialize store connection and load the yearly subscription product.
  Future<void> initialize() async {
    if (_initialized) return;

    final available = await _iap.isAvailable();
    if (!available) {
      throw StateError('Store billing is not available on this device');
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

    if (response.productDetails.isEmpty) {
      throw StateError(
        'Product "${SubscriptionProducts.yearlyProductId}" not found. '
        'Create it in Play Console and use a license tester account.',
      );
    }

    _yearlyProduct = response.productDetails.first;
  }

  /// Starts Google Play / App Store purchase for the yearly plan.
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

    final param = PurchaseParam(productDetails: product);
    // Subscriptions use buyNonConsumable in the Flutter IAP plugin.
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

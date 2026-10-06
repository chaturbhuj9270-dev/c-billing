import 'dart:async';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_cashfree_pg_sdk/api/cferrorresponse/cferrorresponse.dart';
import 'package:flutter_cashfree_pg_sdk/api/cfpayment/cfwebcheckoutpayment.dart';
import 'package:flutter_cashfree_pg_sdk/api/cfpaymentgateway/cfpaymentgatewayservice.dart';
import 'package:flutter_cashfree_pg_sdk/api/cfsession/cfsession.dart';
import 'package:flutter_cashfree_pg_sdk/utils/cfenums.dart';
import 'package:flutter_cashfree_pg_sdk/utils/cfexceptions.dart';

/// Result of a Cashfree subscription payment attempt.
class CashfreePaymentResult {
  final bool success;
  final String orderId;
  final String status;
  final String message;

  const CashfreePaymentResult({
    required this.success,
    required this.orderId,
    required this.status,
    required this.message,
  });
}

/// Handles Cashfree PG checkout for the yearly subscription.
///
/// Order creation and payment verification run on Cloud Functions so the
/// Cashfree secret key never ships in the app.
class CashfreePaymentService {
  static final CashfreePaymentService _instance =
      CashfreePaymentService._internal();
  factory CashfreePaymentService() => _instance;
  CashfreePaymentService._internal();

  static const String _functionsRegion = 'asia-south1';

  final CFPaymentGatewayService _gateway = CFPaymentGatewayService();
  final FirebaseFunctions _functions = FirebaseFunctions.instanceFor(
    region: _functionsRegion,
  );

  Completer<CashfreePaymentResult>? _pendingCheckout;

  /// Starts Cashfree Web Checkout for ₹3999 subscription.
  ///
  /// Resolves after SDK callback + server-side verification.
  Future<CashfreePaymentResult> payForSubscription() async {
    if (_pendingCheckout != null && !_pendingCheckout!.isCompleted) {
      throw StateError('A payment is already in progress');
    }

    _pendingCheckout = Completer<CashfreePaymentResult>();

    try {
      final order = await _createOrder();
      final orderId = order['orderId'] as String;
      final paymentSessionId = order['paymentSessionId'] as String;
      final environmentName =
          (order['environment'] as String?)?.toUpperCase() ?? 'SANDBOX';

      final environment = environmentName == 'PRODUCTION'
          ? CFEnvironment.PRODUCTION
          : CFEnvironment.SANDBOX;

      _gateway.setCallback(
        (verifiedOrderId) => _onPaymentSuccess(verifiedOrderId),
        (error, failedOrderId) => _onPaymentError(error, failedOrderId),
      );

      final session = CFSessionBuilder()
          .setEnvironment(environment)
          .setOrderId(orderId)
          .setPaymentSessionId(paymentSessionId)
          .build();

      final checkout = CFWebCheckoutPaymentBuilder()
          .setSession(session)
          .build();

      _gateway.doPayment(checkout);

      return _pendingCheckout!.future.timeout(
        const Duration(minutes: 15),
        onTimeout: () => CashfreePaymentResult(
          success: false,
          orderId: orderId,
          status: 'TIMEOUT',
          message: 'Payment timed out. If money was deducted, contact support.',
        ),
      );
    } on CFException catch (e) {
      _completePending(
        CashfreePaymentResult(
          success: false,
          orderId: '',
          status: 'SDK_ERROR',
          message: e.message.isNotEmpty ? e.message : 'Cashfree SDK error',
        ),
      );
      return _pendingCheckout!.future;
    } on FirebaseFunctionsException catch (e) {
      final message = e.message ?? e.code;
      _completePending(
        CashfreePaymentResult(
          success: false,
          orderId: '',
          status: 'ORDER_ERROR',
          message: message,
        ),
      );
      return _pendingCheckout!.future;
    } catch (e) {
      _completePending(
        CashfreePaymentResult(
          success: false,
          orderId: '',
          status: 'ERROR',
          message: e.toString(),
        ),
      );
      return _pendingCheckout!.future;
    }
  }

  Future<Map<String, dynamic>> _createOrder() async {
    final callable = _functions.httpsCallable('createSubscriptionOrder');
    final result = await callable.call(<String, dynamic>{});
    final data = Map<String, dynamic>.from(result.data as Map);
    if (data['orderId'] == null || data['paymentSessionId'] == null) {
      throw StateError('Invalid createSubscriptionOrder response');
    }
    return data;
  }

  Future<CashfreePaymentResult> verifyPayment(String orderId) async {
    final callable = _functions.httpsCallable('verifySubscriptionPayment');
    final result = await callable.call(<String, dynamic>{'orderId': orderId});
    final data = Map<String, dynamic>.from(result.data as Map);
    final success = data['success'] == true;
    return CashfreePaymentResult(
      success: success,
      orderId: orderId,
      status: (data['status'] as String?) ?? (success ? 'PAID' : 'FAILED'),
      message:
          (data['message'] as String?) ??
          (success
              ? 'Subscription activated'
              : 'Payment verification failed'),
    );
  }

  Future<void> _onPaymentSuccess(String orderId) async {
    debugPrint('[Cashfree] SDK success callback for order: $orderId');
    try {
      final verified = await verifyPayment(orderId);
      _completePending(verified);
    } catch (e) {
      _completePending(
        CashfreePaymentResult(
          success: false,
          orderId: orderId,
          status: 'VERIFY_ERROR',
          message: 'Payment received but verification failed: $e',
        ),
      );
    }
  }

  void _onPaymentError(CFErrorResponse error, String orderId) {
    debugPrint(
      '[Cashfree] SDK error for order $orderId: ${error.getMessage()}',
    );
    _completePending(
      CashfreePaymentResult(
        success: false,
        orderId: orderId,
        status: error.getStatus() ?? 'FAILED',
        message: error.getMessage() ?? 'Payment failed or cancelled',
      ),
    );
  }

  void _completePending(CashfreePaymentResult result) {
    final completer = _pendingCheckout;
    if (completer != null && !completer.isCompleted) {
      completer.complete(result);
    }
    _pendingCheckout = null;
  }
}

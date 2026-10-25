import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

// Email OTP two-step verification for login (flag on users/{uid}).
class TwoStepVerificationService {
  TwoStepVerificationService._();
  static final TwoStepVerificationService instance =
      TwoStepVerificationService._();

  static const String _functionsRegion = 'asia-south1';

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFunctions _functions = FirebaseFunctions.instanceFor(
    region: _functionsRegion,
  );

  String? get _uid => _auth.currentUser?.uid;

  Future<bool> isEnabledForCurrentUser() async {
    final uid = _uid;
    if (uid == null) return false;
    try {
      final snap = await _firestore.collection('users').doc(uid).get();
      return snap.data()?['twoStepVerificationEnabled'] == true;
    } catch (e) {
      debugPrint('[TwoStep] isEnabled failed: $e');
      return false;
    }
  }

  Future<bool> isEnabledForUid(String uid) async {
    try {
      final snap = await _firestore.collection('users').doc(uid).get();
      return snap.data()?['twoStepVerificationEnabled'] == true;
    } catch (e) {
      debugPrint('[TwoStep] isEnabledForUid failed: $e');
      return false;
    }
  }

  // Sends OTP email. Pass [force] when enabling 2FA from settings.
  Future<String> sendLoginOtp({bool force = false}) async {
    final callable = _functions.httpsCallable('sendLoginOtp');
    final result = await callable.call(<String, dynamic>{'force': force});
    final data = Map<String, dynamic>.from(result.data as Map? ?? {});
    return (data['email'] as String?) ??
        (_auth.currentUser?.email ?? '');
  }

  Future<void> verifyLoginOtp(String otp) async {
    final callable = _functions.httpsCallable('verifyLoginOtp');
    await callable.call(<String, dynamic>{'otp': otp.trim()});
  }

  Future<void> setEnabled({required bool enabled, String? otp}) async {
    final callable = _functions.httpsCallable('setTwoStepVerification');
    await callable.call(<String, dynamic>{
      'enabled': enabled,
      if (otp != null) 'otp': otp.trim(),
    });
  }

  String messageFromFunctionsError(Object e) {
    if (e is FirebaseFunctionsException) {
      return e.message?.trim().isNotEmpty == true
          ? e.message!
          : e.code;
    }
    return e.toString();
  }
}

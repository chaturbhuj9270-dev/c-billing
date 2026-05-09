import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../../core/flavor/app_flavor.dart';
import '../auth/hotel_auth_service.dart';
import '../auth/hotel_roles.dart';

/// Must match `region` in `functions/index.js`.
const _functionsRegion = 'us-central1';

/// Payload `event` values for [HotelPushService.sendOrderEvent].
abstract class HotelOrderPushEvent {
  static const orderToKitchen = 'order_to_kitchen';
  static const orderReady = 'order_ready';
  static const billCleared = 'bill_cleared';
}

/// Registers FCM tokens and invokes the `sendHotelOrderPush` callable for
/// kitchen / service / billing notifications.
class HotelPushService {
  HotelPushService._();
  static final HotelPushService instance = HotelPushService._();

  bool _tokenListenerAttached = false;

  String? get _hotelAdminUid {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;
    final hotelAuth = HotelAuthService.instance;
    if (hotelAuth.isAdmin) return user.uid;
    final sub = hotelAuth.currentSubUser;
    if (sub == null || sub.adminUid.isEmpty) return null;
    return sub.adminUid;
  }

  String? get _tokenDocId => FirebaseAuth.instance.currentUser?.uid;

  /// Call after hotel session is resolved (e.g. from dashboard).
  Future<void> registerIfHotel() async {
    if (!FlavorConfig.instance.isHotel) return;
    final adminUid = _hotelAdminUid;
    final uid = _tokenDocId;
    if (adminUid == null || uid == null) return;

    try {
      final messaging = FirebaseMessaging.instance;
      await messaging.setAutoInitEnabled(true);
      if (defaultTargetPlatform == TargetPlatform.android) {
        await Permission.notification.request();
      }
      if (defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.macOS) {
        await messaging.requestPermission(
          alert: true,
          badge: true,
          sound: true,
        );
      }
      final token = await messaging.getToken();
      if (token == null || token.isEmpty) return;

      await _writeToken(adminUid, uid, token);

      if (!_tokenListenerAttached) {
        _tokenListenerAttached = true;
        messaging.onTokenRefresh.listen((newToken) {
          final a = _hotelAdminUid;
          final u = _tokenDocId;
          if (a != null && u != null) {
            unawaited(_writeToken(a, u, newToken));
          }
        });
      }
    } catch (e) {
      debugPrint('[HotelPush] register error: $e');
    }
  }

  Future<void> _writeToken(String adminUid, String uid, String token) async {
    final hotelAuth = HotelAuthService.instance;
    final String role;
    final String department;
    if (hotelAuth.isAdmin) {
      role = HotelUserRole.admin.name;
      department = HotelDepartment.management.name;
    } else {
      final sub = hotelAuth.currentSubUser;
      if (sub == null) return;
      role = sub.role.name;
      department = sub.department.name;
    }

    await FirebaseFirestore.instance
        .doc('users/$adminUid/hotelPushTokens/$uid')
        .set({
      'fcmToken': token,
      'role': role,
      'department': department,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Fire-and-forget from order flow; errors are logged only.
  static Future<void> sendOrderEvent({
    required String event,
    required String tableNumber,
    String? billNumber,
    int? orderId,
    /// Short text like "2× Roti" for add-on orders; kitchen notification only.
    String? kitchenSummary,
  }) async {
    if (!FlavorConfig.instance.isHotel) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final hotelAuth = HotelAuthService.instance;
    final adminUid = hotelAuth.isAdmin
        ? user.uid
        : (hotelAuth.currentSubUser?.adminUid ?? '');
    if (adminUid.isEmpty) return;

    try {
      final callable = FirebaseFunctions.instanceFor(
        app: Firebase.app(),
        region: _functionsRegion,
      ).httpsCallable('sendHotelOrderPush');

      await callable.call(<String, dynamic>{
        'adminUid': adminUid,
        'event': event,
        'tableNumber': tableNumber,
        if (billNumber != null && billNumber.isNotEmpty) 'billNumber': billNumber,
        if (orderId != null) 'orderId': orderId,
        if (kitchenSummary != null && kitchenSummary.trim().isNotEmpty)
          'kitchenSummary': kitchenSummary.trim(),
      });
    } catch (e) {
      debugPrint('[HotelPush] sendOrderEvent failed: $e');
    }
  }
}

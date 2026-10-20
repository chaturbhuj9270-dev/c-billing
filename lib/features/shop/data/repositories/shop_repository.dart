import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:c_billing/core/access/tenant_context.dart';
import '../../domain/entities/shop.dart';

// Repository for fetching and managing shop details
class ShopRepository {
  final FirebaseFirestore _firestore;

  Shop? _cachedShop;

  ShopRepository({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  // Get shop details for the current user
  Future<Shop> getShopDetails({bool forceRefresh = false}) async {
    // Return cached shop if available and not forcing refresh
    if (_cachedShop != null && !forceRefresh) {
      return _cachedShop!;
    }

    try {
      final ownerId = TenantContext.dataOwnerId;

      final doc = await _firestore
          .collection('users')
          .doc(ownerId)
          .collection('shop_details')
          .doc('main')
          .get();

      if (doc.exists && doc.data() != null) {
        _cachedShop = Shop.fromJson(doc.data()!);
        return _cachedShop!;
      }

      // Return default shop if not found
      return Shop.empty;
    } catch (e) {
      debugPrint('[ERROR] Failed to fetch shop details: $e');
      return Shop.empty;
    }
  }

  // Save or update shop details
  Future<bool> saveShopDetails(Shop shop) async {
    try {
      final ownerId = TenantContext.dataOwnerId;

      await _firestore
          .collection('users')
          .doc(ownerId)
          .collection('shop_details')
          .doc('main')
          .set(shop.toJson(), SetOptions(merge: true));

      _cachedShop = shop;
      return true;
    } catch (e) {
      debugPrint('[ERROR] Failed to save shop details: $e');
      return false;
    }
  }

  // Stream of shop details changes
  Stream<Shop> watchShopDetails() {
    final ownerId = TenantContext.dataOwnerIdOrNull;
    if (ownerId == null) {
      return Stream.value(Shop.empty);
    }

    return _firestore
        .collection('users')
        .doc(ownerId)
        .collection('shop_details')
        .doc('main')
        .snapshots()
        .map((doc) {
      if (doc.exists && doc.data() != null) {
        _cachedShop = Shop.fromJson(doc.data()!);
        return _cachedShop!;
      }
      return Shop.empty;
    });
  }

  // Clear cached shop data
  void clearCache() {
    _cachedShop = null;
  }
}

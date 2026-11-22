import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../domain/entities/shop.dart';
import '../../offline/controllers/shop_image_cache_controller.dart';

/// Repository for fetching and managing shop details.
///
/// Cache is process-wide (static) so [clearCache] from Shop Details always
/// invalidates the shop used by Billing / Bills list / print flows.
class ShopRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  /// Shared across every [ShopRepository] instance in the app.
  static Shop? _cachedShop;

  ShopRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  /// Get shop details for the current user.
  ///
  /// Merges logo / signature / QR from the local image cache when Firestore
  /// is missing those fields (common for large QR images or offline edits).
  Future<Shop> getShopDetails({bool forceRefresh = false}) async {
    if (_cachedShop != null && !forceRefresh) {
      return _cachedShop!;
    }

    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      final doc = await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('shop_details')
          .doc('main')
          .get();

      if (doc.exists && doc.data() != null) {
        final shop = await _hydrateImages(
          Shop.fromJson(doc.data()!),
          currentUser.uid,
        );
        _cachedShop = shop;
        return shop;
      }

      return Shop.empty;
    } catch (e) {
      debugPrint('[ERROR] Failed to fetch shop details: $e');
      // Offline / network failure: still try local image cache on last shop.
      if (_cachedShop != null) {
        return _cachedShop!;
      }
      return Shop.empty;
    }
  }

  /// Fill missing image fields from SQLite shop image cache.
  Future<Shop> _hydrateImages(Shop shop, String userId) async {
    final needsLogo =
        shop.shopLogoBase64 == null || shop.shopLogoBase64!.isEmpty;
    final needsSignature =
        shop.signatureBase64 == null || shop.signatureBase64!.isEmpty;
    final needsQr = shop.qrCodeBase64 == null || shop.qrCodeBase64!.isEmpty;

    if (!needsLogo && !needsSignature && !needsQr) return shop;

    try {
      final cached =
          await ShopImageCacheController.instance.getCachedImages(userId);
      if (cached == null || !cached.hasAnyImages) return shop;

      return shop.copyWith(
        shopLogoBase64: needsLogo ? cached.shopLogoBase64 : shop.shopLogoBase64,
        signatureBase64:
            needsSignature ? cached.signatureBase64 : shop.signatureBase64,
        qrCodeBase64: needsQr ? cached.qrCodeBase64 : shop.qrCodeBase64,
      );
    } catch (e) {
      debugPrint('[ShopRepository] Image cache hydrate failed: $e');
      return shop;
    }
  }

  /// Save or update shop details.
  Future<bool> saveShopDetails(Shop shop) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      await _firestore
          .collection('users')
          .doc(currentUser.uid)
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

  /// Stream of shop details changes.
  Stream<Shop> watchShopDetails() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return Stream.value(Shop.empty);
    }

    return _firestore
        .collection('users')
        .doc(currentUser.uid)
        .collection('shop_details')
        .doc('main')
        .snapshots()
        .asyncMap((doc) async {
      if (doc.exists && doc.data() != null) {
        final shop = await _hydrateImages(
          Shop.fromJson(doc.data()!),
          currentUser.uid,
        );
        _cachedShop = shop;
        return shop;
      }
      return Shop.empty;
    });
  }

  /// Clear cached shop data for every repository instance.
  void clearCache() {
    _cachedShop = null;
  }

  /// Static clear for call sites that don't hold a repository reference.
  static void clearSharedCache() {
    _cachedShop = null;
  }
}

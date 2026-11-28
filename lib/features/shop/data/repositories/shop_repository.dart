import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:c_billing/core/access/tenant_context.dart';
import '../../domain/entities/shop.dart';
import '../../offline/controllers/shop_image_cache_controller.dart';

/// Repository for fetching and managing shop details.
///
/// Cache is process-wide (static) so [clearCache] from Shop Details always
/// invalidates the shop used by Billing / Bills list / print flows.
class ShopRepository {
  final FirebaseFirestore _firestore;

  /// Shared across every [ShopRepository] instance in the app.
  static Shop? _cachedShop;

  ShopRepository({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Get shop details for the current user.
  ///
  /// Merges logo / signature / QR from the local image cache when Firestore
  /// is missing those fields (common for large QR images or offline edits).
  Future<Shop> getShopDetails({bool forceRefresh = false}) async {
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
        final shop = await _hydrateImages(
          Shop.fromJson(doc.data()!),
          ownerId,
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

  /// Prefer non-empty Firebase images, otherwise fall back to local cache.
  Future<Shop> _hydrateImages(Shop shop, String userId) async {
    try {
      final cached =
          await ShopImageCacheController.instance.getCachedImages(userId);
      if (cached == null || !cached.hasAnyImages) return shop;

      String? prefer(String? remote, String? local) {
        if (remote != null && remote.trim().isNotEmpty) return remote;
        if (local != null && local.trim().isNotEmpty) return local;
        return remote ?? local;
      }

      final logo = prefer(shop.shopLogoBase64, cached.shopLogoBase64);
      final signature = prefer(shop.signatureBase64, cached.signatureBase64);
      final qr = prefer(shop.qrCodeBase64, cached.qrCodeBase64);

      debugPrint(
        '[ShopRepository] Hydrated images '
        'logo=${logo?.isNotEmpty == true}, '
        'sig=${signature?.isNotEmpty == true}, '
        'qr=${qr?.isNotEmpty == true}',
      );

      return shop.copyWith(
        shopLogoBase64: logo,
        setShopLogoBase64: true,
        signatureBase64: signature,
        setSignatureBase64: true,
        qrCodeBase64: qr,
        setQrCodeBase64: true,
      );
    } catch (e) {
      debugPrint('[ShopRepository] Image cache hydrate failed: $e');
      return shop;
    }
  }

  /// Save or update shop details.
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

  /// Stream of shop details changes.
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
        .asyncMap((doc) async {
      if (doc.exists && doc.data() != null) {
        final shop = await _hydrateImages(
          Shop.fromJson(doc.data()!),
          ownerId,
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

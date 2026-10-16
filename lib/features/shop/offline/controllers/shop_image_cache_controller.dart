import '../../../../core/database/app_database.dart';
import '../../../../core/database/local_store.dart';
import '../../../../core/services/local_database.dart';
import '../entities/shop_image_cache_entity.dart';

/// Controller for managing shop image cache in the local database.
/// Provides fast local access to shop images (logo, signature, QR code).
class ShopImageCacheController {
  static ShopImageCacheController? _instance;

  AppDatabase get _db => LocalDatabase.instance.db;

  ShopImageCacheController._();

  /// Get the singleton instance
  static ShopImageCacheController get instance {
    _instance ??= ShopImageCacheController._();
    return _instance!;
  }

  /// Get cached images for a user
  /// Returns null if no cache exists
  Future<ShopImageCacheEntity?> getCachedImages(String userId) async {
    for (final image in await _db.loadShopImages()) {
      if (image.userId == userId) return image;
    }
    return null;
  }

  /// Save images to local cache
  /// Creates new entry or updates existing one
  Future<void> saveToCache({
    required String userId,
    String? shopLogoBase64,
    String? signatureBase64,
    String? qrCodeBase64,
  }) async {
    // Check if cache already exists for this user
    final existing = await getCachedImages(userId);

    if (existing != null) {
      // Update existing cache
      final updated = existing.copyWith(
        shopLogoBase64: shopLogoBase64 ?? existing.shopLogoBase64,
        signatureBase64: signatureBase64 ?? existing.signatureBase64,
        qrCodeBase64: qrCodeBase64 ?? existing.qrCodeBase64,
        updatedAt: DateTime.now(),
      );
      await _db.saveShopImage(updated);
    } else {
      // Create new cache entry
      final newCache = ShopImageCacheEntity(
        userId: userId,
        shopLogoBase64: shopLogoBase64,
        signatureBase64: signatureBase64,
        qrCodeBase64: qrCodeBase64,
        updatedAt: DateTime.now(),
      );
      await _db.saveShopImage(newCache);
    }
  }

  /// Update specific image in cache
  Future<void> updateLogo(String userId, String? logoBase64) async {
    final existing = await getCachedImages(userId);

    if (existing != null) {
      final updated = existing.copyWith(
        shopLogoBase64: logoBase64,
        updatedAt: DateTime.now(),
      );
      await _db.saveShopImage(updated);
    } else {
      final newCache = ShopImageCacheEntity(
        userId: userId,
        shopLogoBase64: logoBase64,
        updatedAt: DateTime.now(),
      );
      await _db.saveShopImage(newCache);
    }
  }

  /// Update signature in cache
  Future<void> updateSignature(String userId, String? signatureBase64) async {
    final existing = await getCachedImages(userId);

    if (existing != null) {
      final updated = existing.copyWith(
        signatureBase64: signatureBase64,
        updatedAt: DateTime.now(),
      );
      await _db.saveShopImage(updated);
    } else {
      final newCache = ShopImageCacheEntity(
        userId: userId,
        signatureBase64: signatureBase64,
        updatedAt: DateTime.now(),
      );
      await _db.saveShopImage(newCache);
    }
  }

  /// Update QR code in cache
  Future<void> updateQrCode(String userId, String? qrCodeBase64) async {
    final existing = await getCachedImages(userId);

    if (existing != null) {
      final updated = existing.copyWith(
        qrCodeBase64: qrCodeBase64,
        updatedAt: DateTime.now(),
      );
      await _db.saveShopImage(updated);
    } else {
      final newCache = ShopImageCacheEntity(
        userId: userId,
        qrCodeBase64: qrCodeBase64,
        updatedAt: DateTime.now(),
      );
      await _db.saveShopImage(newCache);
    }
  }

  /// Remove specific image from cache
  Future<void> removeLogo(String userId) async {
    await updateLogo(userId, null);
  }

  Future<void> removeSignature(String userId) async {
    await updateSignature(userId, null);
  }

  Future<void> removeQrCode(String userId) async {
    await updateQrCode(userId, null);
  }

  /// Clear all cached images for a user
  Future<void> clearCache(String userId) async {
    final existing = await getCachedImages(userId);
    if (existing == null) return;
    await _db.deleteShopImageById(existing.id);
  }

  /// Sync images from Firebase to local cache
  /// Call this after fetching from Firebase
  Future<void> syncFromFirebase({
    required String userId,
    String? shopLogoBase64,
    String? signatureBase64,
    String? qrCodeBase64,
  }) async {
    final existing = await getCachedImages(userId);

    final now = DateTime.now();

    if (existing != null) {
      final updated = ShopImageCacheEntity(
        userId: userId,
        shopLogoBase64: shopLogoBase64,
        signatureBase64: signatureBase64,
        qrCodeBase64: qrCodeBase64,
        lastSyncedAt: now,
        updatedAt: now,
      )..id = existing.id;
      await _db.saveShopImage(updated);
    } else {
      final newCache = ShopImageCacheEntity(
        userId: userId,
        shopLogoBase64: shopLogoBase64,
        signatureBase64: signatureBase64,
        qrCodeBase64: qrCodeBase64,
        lastSyncedAt: now,
        updatedAt: now,
      );
      await _db.saveShopImage(newCache);
    }
  }
}

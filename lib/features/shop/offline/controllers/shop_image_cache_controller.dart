import 'package:isar_community/isar.dart';
import '../../../../core/services/isar_service.dart';
import '../entities/shop_image_cache_entity.dart';

/// Controller for managing shop image cache in local Isar database
/// Provides fast local access to shop images (logo, signature, QR code)
class ShopImageCacheController {
  static ShopImageCacheController? _instance;

  Isar get _isar => IsarService.instance.isar;

  ShopImageCacheController._();

  /// Get the singleton instance
  static ShopImageCacheController get instance {
    _instance ??= ShopImageCacheController._();
    return _instance!;
  }

  /// Get cached images for a user
  /// Returns null if no cache exists
  Future<ShopImageCacheEntity?> getCachedImages(String userId) async {
    return await _isar.shopImageCacheEntitys
        .filter()
        .userIdEqualTo(userId)
        .findFirst();
  }

  /// Save images to local cache
  /// Creates new entry or updates existing one
  Future<void> saveToCache({
    required String userId,
    String? shopLogoBase64,
    String? signatureBase64,
    String? qrCodeBase64,
  }) async {
    await _isar.writeTxn(() async {
      // Check if cache already exists for this user
      final existing = await _isar.shopImageCacheEntitys
          .filter()
          .userIdEqualTo(userId)
          .findFirst();

      if (existing != null) {
        // Update existing cache
        final updated = existing.copyWith(
          shopLogoBase64: shopLogoBase64 ?? existing.shopLogoBase64,
          signatureBase64: signatureBase64 ?? existing.signatureBase64,
          qrCodeBase64: qrCodeBase64 ?? existing.qrCodeBase64,
          updatedAt: DateTime.now(),
        );
        await _isar.shopImageCacheEntitys.put(updated);
      } else {
        // Create new cache entry
        final newCache = ShopImageCacheEntity(
          userId: userId,
          shopLogoBase64: shopLogoBase64,
          signatureBase64: signatureBase64,
          qrCodeBase64: qrCodeBase64,
          updatedAt: DateTime.now(),
        );
        await _isar.shopImageCacheEntitys.put(newCache);
      }
    });
  }

  /// Update specific image in cache
  Future<void> updateLogo(String userId, String? logoBase64) async {
    await _isar.writeTxn(() async {
      final existing = await _isar.shopImageCacheEntitys
          .filter()
          .userIdEqualTo(userId)
          .findFirst();

      if (existing != null) {
        final updated = existing.copyWith(
          shopLogoBase64: logoBase64,
          updatedAt: DateTime.now(),
        );
        await _isar.shopImageCacheEntitys.put(updated);
      } else {
        final newCache = ShopImageCacheEntity(
          userId: userId,
          shopLogoBase64: logoBase64,
          updatedAt: DateTime.now(),
        );
        await _isar.shopImageCacheEntitys.put(newCache);
      }
    });
  }

  /// Update signature in cache
  Future<void> updateSignature(String userId, String? signatureBase64) async {
    await _isar.writeTxn(() async {
      final existing = await _isar.shopImageCacheEntitys
          .filter()
          .userIdEqualTo(userId)
          .findFirst();

      if (existing != null) {
        final updated = existing.copyWith(
          signatureBase64: signatureBase64,
          updatedAt: DateTime.now(),
        );
        await _isar.shopImageCacheEntitys.put(updated);
      } else {
        final newCache = ShopImageCacheEntity(
          userId: userId,
          signatureBase64: signatureBase64,
          updatedAt: DateTime.now(),
        );
        await _isar.shopImageCacheEntitys.put(newCache);
      }
    });
  }

  /// Update QR code in cache
  Future<void> updateQrCode(String userId, String? qrCodeBase64) async {
    await _isar.writeTxn(() async {
      final existing = await _isar.shopImageCacheEntitys
          .filter()
          .userIdEqualTo(userId)
          .findFirst();

      if (existing != null) {
        final updated = existing.copyWith(
          qrCodeBase64: qrCodeBase64,
          updatedAt: DateTime.now(),
        );
        await _isar.shopImageCacheEntitys.put(updated);
      } else {
        final newCache = ShopImageCacheEntity(
          userId: userId,
          qrCodeBase64: qrCodeBase64,
          updatedAt: DateTime.now(),
        );
        await _isar.shopImageCacheEntitys.put(newCache);
      }
    });
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
    await _isar.writeTxn(() async {
      await _isar.shopImageCacheEntitys
          .filter()
          .userIdEqualTo(userId)
          .deleteAll();
    });
  }

  /// Sync images from Firebase to local cache
  /// Call this after fetching from Firebase
  Future<void> syncFromFirebase({
    required String userId,
    String? shopLogoBase64,
    String? signatureBase64,
    String? qrCodeBase64,
  }) async {
    await _isar.writeTxn(() async {
      final existing = await _isar.shopImageCacheEntitys
          .filter()
          .userIdEqualTo(userId)
          .findFirst();

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
        await _isar.shopImageCacheEntitys.put(updated);
      } else {
        final newCache = ShopImageCacheEntity(
          userId: userId,
          shopLogoBase64: shopLogoBase64,
          signatureBase64: signatureBase64,
          qrCodeBase64: qrCodeBase64,
          lastSyncedAt: now,
          updatedAt: now,
        );
        await _isar.shopImageCacheEntitys.put(newCache);
      }
    });
  }
}

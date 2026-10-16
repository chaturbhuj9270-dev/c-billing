
/// Local entity for caching shop images locally
/// Stores base64 encoded images for fast loading without network calls
class ShopImageCacheEntity {
  /// Local row id
  int id = 0;

  /// User ID (Firebase UID) - indexed for quick lookup
  String userId;

  /// Shop logo as base64 encoded string
  String? shopLogoBase64;

  /// Signature as base64 encoded string
  String? signatureBase64;

  /// Payment QR code as base64 encoded string
  String? qrCodeBase64;

  /// Last sync timestamp from Firebase
  DateTime? lastSyncedAt;

  /// Local update timestamp
  DateTime updatedAt;

  ShopImageCacheEntity({
    required this.userId,
    this.shopLogoBase64,
    this.signatureBase64,
    this.qrCodeBase64,
    this.lastSyncedAt,
    required this.updatedAt,
  });

  /// Check if any images are cached
  bool get hasAnyImages =>
      (shopLogoBase64 != null && shopLogoBase64!.isNotEmpty) ||
      (signatureBase64 != null && signatureBase64!.isNotEmpty) ||
      (qrCodeBase64 != null && qrCodeBase64!.isNotEmpty);

  /// Create a copy with updated fields
  ShopImageCacheEntity copyWith({
    String? userId,
    String? shopLogoBase64,
    String? signatureBase64,
    String? qrCodeBase64,
    DateTime? lastSyncedAt,
    DateTime? updatedAt,
  }) {
    return ShopImageCacheEntity(
      userId: userId ?? this.userId,
      shopLogoBase64: shopLogoBase64 ?? this.shopLogoBase64,
      signatureBase64: signatureBase64 ?? this.signatureBase64,
      qrCodeBase64: qrCodeBase64 ?? this.qrCodeBase64,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      updatedAt: updatedAt ?? this.updatedAt,
    )..id = id;
  }
}

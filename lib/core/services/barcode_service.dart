import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:barcode/barcode.dart';
import 'package:flutter/rendering.dart';
import '../../features/product/offline/controllers/product_offline_controller.dart';
import '../../features/product/offline/entities/product_entity.dart';
import '../../features/inventory_management/offline/controllers/purchase_batch_offline_controller.dart';
import '../../features/inventory_management/offline/entities/purchase_batch_entity.dart';

/// Barcode types supported for generation
enum BarcodeFormat {
  code128('CODE128', 'Code 128 - Alphanumeric'),
  code39('CODE39', 'Code 39 - Alphanumeric'),
  ean13('EAN13', 'EAN-13 - 13 digits'),
  ean8('EAN8', 'EAN-8 - 8 digits'),
  upcA('UPCA', 'UPC-A - 12 digits'),
  qrCode('QRCODE', 'QR Code - Any data');

  final String code;
  final String displayName;
  const BarcodeFormat(this.code, this.displayName);
}

/// Data model for barcode content
class BarcodeData {
  final String code;
  final String productId;
  final String productName;
  final String? batchId;
  final String? companyName;
  final double? price;
  final DateTime? expiryDate;
  final DateTime generatedAt;

  BarcodeData({
    required this.code,
    required this.productId,
    required this.productName,
    this.batchId,
    this.companyName,
    this.price,
    this.expiryDate,
    DateTime? generatedAt,
  }) : generatedAt = generatedAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'code': code,
    'productId': productId,
    'productName': productName,
    'batchId': batchId,
    'companyName': companyName,
    'price': price,
    'expiryDate': expiryDate?.toIso8601String(),
    'generatedAt': generatedAt.toIso8601String(),
  };

  factory BarcodeData.fromJson(Map<String, dynamic> json) => BarcodeData(
    code: json['code'] as String,
    productId: json['productId'] as String,
    productName: json['productName'] as String,
    batchId: json['batchId'] as String?,
    companyName: json['companyName'] as String?,
    price: (json['price'] as num?)?.toDouble(),
    expiryDate: json['expiryDate'] != null
        ? DateTime.parse(json['expiryDate'] as String)
        : null,
    generatedAt: json['generatedAt'] != null
        ? DateTime.parse(json['generatedAt'] as String)
        : DateTime.now(),
  );
}

/// Result of barcode lookup for fast billing
class BarcodeLookupResult {
  final bool found;
  final ProductEntity? product;
  final PurchaseBatchEntity? batch;
  final String? errorMessage;

  BarcodeLookupResult({
    required this.found,
    this.product,
    this.batch,
    this.errorMessage,
  });

  factory BarcodeLookupResult.notFound(String code) => BarcodeLookupResult(
    found: false,
    errorMessage: 'No product found for barcode: $code',
  );

  factory BarcodeLookupResult.success({
    required ProductEntity product,
    PurchaseBatchEntity? batch,
  }) => BarcodeLookupResult(found: true, product: product, batch: batch);
}

/// Barcode Service - Common logic for barcode generation and lookup
/// Used for fast billing and inventory management
class BarcodeService {
  static BarcodeService? _instance;

  BarcodeService._();

  /// Get the singleton instance
  static BarcodeService get instance {
    _instance ??= BarcodeService._();
    return _instance!;
  }

  // ==================== BARCODE GENERATION ====================

  /// Generate a unique barcode for a product
  /// Uses format: PROD-{productId}-{timestamp}
  String generateProductBarcode(String productId) {
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    // Take last 8 digits of timestamp to keep it short
    final shortTimestamp = timestamp.substring(timestamp.length - 8);
    return 'P${productId.substring(0, productId.length.clamp(0, 6))}$shortTimestamp';
  }

  /// Generate a unique barcode for a batch
  /// Uses format: BATCH-{batchId}-{timestamp}
  String generateBatchBarcode(String batchId) {
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final shortTimestamp = timestamp.substring(timestamp.length - 8);
    return 'B${batchId.substring(0, batchId.length.clamp(0, 6))}$shortTimestamp';
  }

  /// Generate a custom barcode based on product info
  /// Creates a readable code: IndexNo-CompanyCode-ProductCode
  String generateCustomBarcode({
    required int productIndexNo,
    String? companyCode,
    int? batchNo,
  }) {
    final parts = <String>[];
    parts.add(productIndexNo.toString().padLeft(4, '0'));
    if (companyCode != null && companyCode.isNotEmpty) {
      // Take first 3 chars of company
      parts.add(
        companyCode.substring(0, companyCode.length.clamp(0, 3)).toUpperCase(),
      );
    }
    if (batchNo != null) {
      parts.add(batchNo.toString().padLeft(3, '0'));
    }
    return parts.join('-');
  }

  /// Generate EAN-13 compatible barcode (13 digits with check digit)
  String generateEAN13({
    required int productIndexNo,
    int prefixCode = 200, // 200-299 is for internal use
  }) {
    // Format: PPP-OOOO-NNNNN-C
    // PPP = prefix (200-299 for internal use)
    // OOOO = organization code (use 0000)
    // NNNNN = product index no (padded)
    // C = check digit

    final base =
        '${prefixCode}0000${productIndexNo.toString().padLeft(5, '0')}';
    final checkDigit = _calculateEAN13CheckDigit(base);
    return '$base$checkDigit';
  }

  /// Calculate EAN-13 check digit
  int _calculateEAN13CheckDigit(String code12) {
    int sum = 0;
    for (int i = 0; i < 12; i++) {
      final digit = int.parse(code12[i]);
      sum += (i % 2 == 0) ? digit : digit * 3;
    }
    return (10 - (sum % 10)) % 10;
  }

  /// Get the barcode renderer for a given format
  Barcode getBarcodeRenderer(BarcodeFormat format) {
    switch (format) {
      case BarcodeFormat.code128:
        return Barcode.code128();
      case BarcodeFormat.code39:
        return Barcode.code39();
      case BarcodeFormat.ean13:
        return Barcode.ean13();
      case BarcodeFormat.ean8:
        return Barcode.ean8();
      case BarcodeFormat.upcA:
        return Barcode.upcA();
      case BarcodeFormat.qrCode:
        return Barcode.qrCode();
    }
  }

  /// Generate SVG string for barcode
  String generateBarcodeSvg({
    required String data,
    BarcodeFormat format = BarcodeFormat.code128,
    double width = 200,
    double height = 80,
  }) {
    final barcode = getBarcodeRenderer(format);
    return barcode.toSvg(
      data,
      width: width,
      height: height,
      drawText: true,
      fontHeight: 14,
    );
  }

  /// Validate barcode data for format
  bool validateBarcodeData(String data, BarcodeFormat format) {
    try {
      final barcode = getBarcodeRenderer(format);
      barcode.verify(data);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Get valid characters info for barcode format
  String getFormatInfo(BarcodeFormat format) {
    switch (format) {
      case BarcodeFormat.code128:
        return 'Supports all ASCII characters (0-127)';
      case BarcodeFormat.code39:
        return 'Supports A-Z, 0-9, and special characters: - . \$ / + % space';
      case BarcodeFormat.ean13:
        return 'Exactly 12 digits (13th is check digit)';
      case BarcodeFormat.ean8:
        return 'Exactly 7 digits (8th is check digit)';
      case BarcodeFormat.upcA:
        return 'Exactly 11 digits (12th is check digit)';
      case BarcodeFormat.qrCode:
        return 'Supports any text, numbers, or special characters';
    }
  }

  // ==================== BARCODE LOOKUP (FOR FAST BILLING) ====================

  /// Look up product by barcode - primary method for fast billing
  /// Returns product and optionally matching batch
  Future<BarcodeLookupResult> lookupByBarcode(String barcode) async {
    if (barcode.isEmpty) {
      return BarcodeLookupResult(
        found: false,
        errorMessage: 'Barcode is empty',
      );
    }

    try {
      // First try to find product by barcode field
      final product = await ProductOfflineController.instance
          .getProductByBarcode(barcode);

      if (product != null) {
        // Try to get the latest batch with stock (for FIFO)
        final batches = await PurchaseBatchOfflineController.instance
            .getBatchesByProductId(
              product.serverId ?? product.id.toString(),
              onlyWithStock: true,
            );

        return BarcodeLookupResult.success(
          product: product,
          batch: batches.isNotEmpty ? batches.first : null,
        );
      }

      // If barcode starts with 'B', it might be a batch-specific barcode
      if (barcode.startsWith('B')) {
        // Try to parse batch ID from barcode
        // Format: B{batchId}{timestamp}
        final batchIdPart = barcode.substring(1, barcode.length - 8);
        final batches = await PurchaseBatchOfflineController.instance
            .getAllBatches(includeConsumed: false);

        for (final batch in batches) {
          final batchId = batch.serverId ?? batch.id.toString();
          if (batchId.startsWith(batchIdPart) ||
              batchId.endsWith(batchIdPart)) {
            // Find the product for this batch
            final prod = await ProductOfflineController.instance
                .getProductByServerId(batch.productId);
            if (prod != null) {
              return BarcodeLookupResult.success(product: prod, batch: batch);
            }
          }
        }
      }

      return BarcodeLookupResult.notFound(barcode);
    } catch (e) {
      return BarcodeLookupResult(
        found: false,
        errorMessage: 'Error looking up barcode: $e',
      );
    }
  }

  /// Scan and add to bill - convenience method for billing
  /// Returns null if not found, otherwise returns product data for billing
  Future<Map<String, dynamic>?> scanForBilling(String barcode) async {
    final result = await lookupByBarcode(barcode);

    if (!result.found || result.product == null) {
      return null;
    }

    final product = result.product!;
    final batch = result.batch;

    return {
      'productId': product.serverId ?? product.id.toString(),
      'productName': product.name,
      'companyName': product.companyName,
      'unitPrice': batch?.sellingPrice ?? product.salesPrice,
      'purchasePrice': batch?.purchasePrice ?? product.purchasePrice,
      'batchId': batch?.serverId ?? batch?.id.toString(),
      'availableStock': batch?.quantityRemaining ?? product.currentStock,
      'unit': product.unit ?? 'pcs',
      'cgst': product.cgstPercent,
      'sgst': product.sgstPercent,
      'hsnCode': product.hsnCode,
    };
  }

  // ==================== BARCODE ASSIGNMENT ====================

  /// Assign barcode to product
  Future<bool> assignBarcodeToProduct(String productId, String barcode) async {
    try {
      // Find product by server ID first
      var product = await ProductOfflineController.instance
          .getProductByServerId(productId);

      if (product == null) {
        // Try parsing as local ID
        final localId = int.tryParse(productId);
        if (localId != null) {
          product = await ProductOfflineController.instance.getProductById(
            localId,
          );
        }
      }

      if (product == null) {
        return false;
      }

      // Check if barcode is already assigned to another product
      final existing = await ProductOfflineController.instance
          .getProductByBarcode(barcode);
      if (existing != null && existing.id != product.id) {
        return false; // Barcode already in use
      }

      // Update product with barcode
      await ProductOfflineController.instance.updateProduct(
        id: product.id,
        barcode: barcode,
      );

      return true;
    } catch (e) {
      debugPrint('[BarcodeService] Error assigning barcode: $e');
      return false;
    }
  }

  /// Check if barcode is available (not assigned to any product)
  Future<bool> isBarcodeAvailable(String barcode) async {
    final existing = await ProductOfflineController.instance
        .getProductByBarcode(barcode);
    return existing == null;
  }
}

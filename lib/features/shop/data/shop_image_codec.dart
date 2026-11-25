import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

/// Compresses shop logo / QR images so they fit Firestore's 1MB document limit
/// (together with signature + text fields) and still decode in the UI.
class ShopImageCodec {
  ShopImageCodec._();

  /// Soft cap for a single base64 field (~75KB binary ≈ ~100KB base64).
  static const int maxBytes = 75 * 1024;

  /// Strips `data:image/...;base64,` prefixes and whitespace.
  static String normalizeBase64(String raw) {
    var value = raw.trim();
    final marker = 'base64,';
    final idx = value.indexOf(marker);
    if (idx != -1) {
      value = value.substring(idx + marker.length);
    }
    return value.replaceAll(RegExp(r'\s+'), '');
  }

  static Uint8List? tryDecodeBase64(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    try {
      return base64Decode(normalizeBase64(raw));
    } catch (e) {
      debugPrint('[ShopImageCodec] base64 decode failed: $e');
      return null;
    }
  }

  /// Resize + JPEG-encode for Firestore / local cache.
  static Future<String> compressToBase64(
    Uint8List bytes, {
    int maxSide = 280,
    int quality = 55,
  }) async {
    return compute(
      _compressWorker,
      _CompressArgs(bytes: bytes, maxSide: maxSide, quality: quality),
    );
  }
}

class _CompressArgs {
  final Uint8List bytes;
  final int maxSide;
  final int quality;

  const _CompressArgs({
    required this.bytes,
    required this.maxSide,
    required this.quality,
  });
}

String _compressWorker(_CompressArgs args) {
  var quality = args.quality;
  var maxSide = args.maxSide;
  Uint8List encoded = args.bytes;

  final decoded = img.decodeImage(args.bytes);
  if (decoded == null) {
    // Unrecognized format — return original if already small enough.
    return base64Encode(args.bytes);
  }

  for (var attempt = 0; attempt < 5; attempt++) {
    final resized = img.copyResize(
      decoded,
      width: decoded.width >= decoded.height ? maxSide : null,
      height: decoded.height > decoded.width ? maxSide : null,
      interpolation: img.Interpolation.average,
    );
    encoded = Uint8List.fromList(img.encodeJpg(resized, quality: quality));
    if (encoded.lengthInBytes <= ShopImageCodec.maxBytes) {
      return base64Encode(encoded);
    }
    quality = (quality - 12).clamp(28, 55);
    maxSide = (maxSide * 0.8).round().clamp(120, args.maxSide);
  }

  return base64Encode(encoded);
}

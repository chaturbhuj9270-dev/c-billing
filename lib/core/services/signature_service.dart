import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Raw RGBA pixel data + dimensions for direct PDF embedding.
class SignatureRawData {
  final Uint8List bytes;
  final int width;
  final int height;
  const SignatureRawData({
    required this.bytes,
    required this.width,
    required this.height,
  });
}

/// Service to manage owner signature storage, retrieval, and removal.
///
/// Stores signature as a PNG file in application documents directory and
/// caches the base64 representation in SharedPreferences for fast access
/// during PDF/print generation.
class SignatureService {
  static final SignatureService _instance = SignatureService._internal();
  factory SignatureService() => _instance;
  SignatureService._internal();

  static const String _keySignaturePath = 'owner_signature_path';
  static const String _keySignatureBase64 = 'owner_signature_base64';
  static const String _signatureFileName = 'owner_signature.png';

  /// Save signature from drawn points to local storage.
  ///
  /// Renders the [points] onto a canvas, encodes as PNG, saves to disk,
  /// and caches the base64 in SharedPreferences.
  /// Returns `true` on success.
  Future<bool> saveSignature(List<List<Offset>> strokes, Size canvasSize) async {
    try {
      // Validate — prevent saving empty signature
      if (strokes.isEmpty || strokes.every((s) => s.isEmpty)) {
        return false;
      }

      // Render strokes to image
      final bytes = await _renderSignatureToBytes(strokes, canvasSize);
      if (bytes == null || bytes.isEmpty) return false;

      // Save PNG file
      final dir = await getApplicationDocumentsDirectory();
      final filePath = '${dir.path}/$_signatureFileName';
      final file = File(filePath);
      await file.writeAsBytes(bytes);

      // Cache base64 + path in SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final base64Str = base64Encode(bytes);
      await prefs.setString(_keySignaturePath, filePath);
      await prefs.setString(_keySignatureBase64, base64Str);

      return true;
    } catch (e) {
      debugPrint('[SignatureService] Error saving signature: $e');
      return false;
    }
  }

  /// Get signature as raw PNG bytes (for PDF embedding).
  /// Returns `null` if no signature exists or file is missing.
  Future<Uint8List?> getSignatureBytes() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Try base64 from cache first (fastest)
      final base64Str = prefs.getString(_keySignatureBase64);
      if (base64Str != null && base64Str.isNotEmpty) {
        return base64Decode(base64Str);
      }

      // Fallback: read from file
      final path = prefs.getString(_keySignaturePath);
      if (path != null && path.isNotEmpty) {
        final file = File(path);
        if (await file.exists()) {
          final bytes = await file.readAsBytes();
          // Re-cache base64
          await prefs.setString(_keySignatureBase64, base64Encode(bytes));
          return bytes;
        }
      }

      return null;
    } catch (e) {
      debugPrint('[SignatureService] Error reading signature: $e');
      return null;
    }
  }

  /// Get signature as raw RGBA pixel data for direct PdfImage creation.
  /// This bypasses PNG encode/decode and avoids image library compatibility issues.
  /// Returns `null` if no signature exists.
  Future<SignatureRawData?> getSignatureRaw() async {
    try {
      final pngBytes = await getSignatureBytes();
      if (pngBytes == null || pngBytes.isEmpty) return null;

      // Decode PNG back to raw pixels via dart:ui
      final codec = await ui.instantiateImageCodec(pngBytes);
      final frame = await codec.getNextFrame();
      final image = frame.image;
      final byteData = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      if (byteData == null) return null;

      return SignatureRawData(
        bytes: byteData.buffer.asUint8List(),
        width: image.width,
        height: image.height,
      );
    } catch (e) {
      debugPrint('[SignatureService] Error decoding signature raw: $e');
      return null;
    }
  }

  /// Get signature as base64 string (for quick checks / lightweight use).
  Future<String?> getSignatureBase64() async {
    final prefs = await SharedPreferences.getInstance();
    final base64Str = prefs.getString(_keySignatureBase64);
    if (base64Str != null && base64Str.isNotEmpty) return base64Str;

    // Fallback: re-derive from file
    final bytes = await getSignatureBytes();
    if (bytes != null) return base64Encode(bytes);
    return null;
  }

  /// Get the file path of the saved signature.
  Future<String?> getSignaturePath() async {
    final prefs = await SharedPreferences.getInstance();
    final path = prefs.getString(_keySignaturePath);
    if (path != null && path.isNotEmpty) {
      final file = File(path);
      if (await file.exists()) return path;
    }
    return null;
  }

  /// Check if a signature has been saved.
  Future<bool> hasSignature() async {
    final prefs = await SharedPreferences.getInstance();
    final base64Str = prefs.getString(_keySignatureBase64);
    if (base64Str != null && base64Str.isNotEmpty) return true;

    final path = prefs.getString(_keySignaturePath);
    if (path != null && path.isNotEmpty) {
      return File(path).existsSync();
    }
    return false;
  }

  /// Remove saved signature from disk and SharedPreferences.
  Future<void> removeSignature() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final path = prefs.getString(_keySignaturePath);

      // Delete the file
      if (path != null && path.isNotEmpty) {
        final file = File(path);
        if (await file.exists()) {
          await file.delete();
        }
      }

      // Clear SharedPreferences
      await prefs.remove(_keySignaturePath);
      await prefs.remove(_keySignatureBase64);
    } catch (e) {
      debugPrint('[SignatureService] Error removing signature: $e');
    }
  }

  // ─────────── INTERNAL ───────────

  /// Render strokes to PNG bytes.
  /// Produces a compact image (max 400×160) with white background for PDF compatibility.
  Future<Uint8List?> _renderSignatureToBytes(
    List<List<Offset>> strokes,
    Size canvasSize,
  ) async {
    try {
      // Scale down to a reasonable image size for storage & PDF embedding
      const double maxW = 400;
      const double maxH = 160;
      final double scaleX = maxW / canvasSize.width;
      final double scaleY = maxH / canvasSize.height;
      final double scale = scaleX < scaleY ? scaleX : scaleY;
      final int imgW = (canvasSize.width * scale).toInt().clamp(1, maxW.toInt());
      final int imgH = (canvasSize.height * scale).toInt().clamp(1, maxH.toInt());

      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);

      // Solid white background (no transparency — required for pdf package)
      canvas.drawRect(
        Rect.fromLTWH(0, 0, imgW.toDouble(), imgH.toDouble()),
        Paint()..color = const Color(0xFFFFFFFF),
      );

      // Scale strokes to fit the output image
      canvas.scale(scale);

      // Draw signature strokes
      final paint = Paint()
        ..color = const Color(0xFF000000)
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;

      for (final stroke in strokes) {
        if (stroke.length < 2) {
          if (stroke.length == 1) {
            canvas.drawCircle(stroke[0], 1.5, paint..style = PaintingStyle.fill);
            paint.style = PaintingStyle.stroke;
          }
          continue;
        }

        final path = Path()..moveTo(stroke[0].dx, stroke[0].dy);
        for (var i = 1; i < stroke.length; i++) {
          path.lineTo(stroke[i].dx, stroke[i].dy);
        }
        canvas.drawPath(path, paint);
      }

      final picture = recorder.endRecording();
      final image = await picture.toImage(imgW, imgH);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (e) {
      debugPrint('[SignatureService] Error rendering signature: $e');
      return null;
    }
  }
}

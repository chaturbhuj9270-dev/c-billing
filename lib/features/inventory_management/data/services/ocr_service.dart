import 'dart:io';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

/// Result of OCR text recognition on an image.
class OcrResult {
  final bool success;
  final String? rawText;
  final List<OcrTextBlock> blocks;
  final String? errorMessage;

  OcrResult._({
    required this.success,
    this.rawText,
    this.blocks = const [],
    this.errorMessage,
  });

  factory OcrResult.success({
    required String rawText,
    required List<OcrTextBlock> blocks,
  }) {
    return OcrResult._(success: true, rawText: rawText, blocks: blocks);
  }

  factory OcrResult.failure(String message) {
    return OcrResult._(success: false, errorMessage: message);
  }
}

/// A block of recognized text with its lines and bounding box.
class OcrTextBlock {
  final String text;
  final List<String> lines;
  final Rect? boundingBox;

  OcrTextBlock({required this.text, required this.lines, this.boundingBox});
}

/// Service for performing OCR text recognition using Google MLKit.
///
/// Usage:
/// ```dart
/// final result = await OcrService.instance.recognizeText(imageFile);
/// if (result.success) {
///   print(result.rawText);
/// }
/// ```
class OcrService {
  static OcrService? _instance;

  OcrService._();

  static OcrService get instance {
    _instance ??= OcrService._();
    return _instance!;
  }

  /// Process an image file and return recognized text.
  /// The [TextRecognizer] is created and disposed per call to avoid memory leaks.
  Future<OcrResult> recognizeText(File imageFile) async {
    final textRecognizer = TextRecognizer(
      script: TextRecognitionScript.latin,
    );

    try {
      if (!await imageFile.exists()) {
        return OcrResult.failure('Image file does not exist');
      }

      final inputImage = InputImage.fromFile(imageFile);
      final recognizedText = await textRecognizer.processImage(inputImage);

      if (recognizedText.text.trim().isEmpty) {
        return OcrResult.failure('No text found in image');
      }

      final blocks =
          recognizedText.blocks.map((block) {
            return OcrTextBlock(
              text: block.text,
              lines: block.lines.map((line) => line.text).toList(),
              boundingBox: block.boundingBox,
            );
          }).toList();

      debugPrint(
        '[OcrService] Recognized ${blocks.length} blocks, '
        '${recognizedText.text.length} chars total',
      );

      return OcrResult.success(rawText: recognizedText.text, blocks: blocks);
    } catch (e) {
      debugPrint('[OcrService] OCR processing failed: $e');
      return OcrResult.failure('OCR processing failed: $e');
    } finally {
      textRecognizer.close();
    }
  }
}

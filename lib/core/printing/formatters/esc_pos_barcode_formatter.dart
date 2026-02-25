import 'dart:convert';
import '../models/printer_models.dart';
import 'esc_pos_bill_formatter.dart';

/// ESC/POS Barcode Commands for thermal printers
/// Reference: ESC/POS Command Set
class EscPosBarcodeCommands {
  // Barcode height setting: GS h n (n = 1-255 dots)
  static List<int> setBarcodeHeight(int height) => [0x1D, 0x68, height];
  
  // Barcode width setting: GS w n (n = 2-6)
  static List<int> setBarcodeWidth(int width) => [0x1D, 0x77, width];
  
  // HRI (Human Readable Interpretation) position: GS H n
  // n=0: Not printed, n=1: Above, n=2: Below, n=3: Both
  static List<int> setHriPosition(int position) => [0x1D, 0x48, position];
  
  // HRI font: GS f n (n=0: Font A, n=1: Font B)
  static List<int> setHriFont(int font) => [0x1D, 0x66, font];
  
  // Print barcode: GS k m d1...dk NUL (for format m <= 6)
  // or GS k m n d1...dn (for format m >= 65)
  
  /// Barcode types for GS k command
  static const int barcodeUpcA = 0;      // UPC-A
  static const int barcodeUpcE = 1;      // UPC-E
  static const int barcodeEan13 = 2;     // JAN13 (EAN13)
  static const int barcodeEan8 = 3;      // JAN8 (EAN8)
  static const int barcodeCode39 = 4;    // CODE39
  static const int barcodeItf = 5;       // ITF (Interleaved 2 of 5)
  static const int barcodeCodabar = 6;   // CODABAR
  
  // Modern format (m >= 65)
  static const int barcodeUpcA2 = 65;    // UPC-A
  static const int barcodeUpcE2 = 66;    // UPC-E
  static const int barcodeEan13_2 = 67;  // JAN13 (EAN13)
  static const int barcodeEan8_2 = 68;   // JAN8 (EAN8)
  static const int barcodeCode39_2 = 69; // CODE39
  static const int barcodeItf2 = 70;     // ITF
  static const int barcodeCodabar2 = 71; // CODABAR
  static const int barcodeCode93 = 72;   // CODE93
  static const int barcodeCode128 = 73;  // CODE128
}

/// Configuration for barcode label printing
class BarcodeLabelConfig {
  final int labelWidth;        // Width allocation for label (mm)
  final int barcodeHeight;     // Barcode height (1-255 dots)
  final int barcodeWidth;      // Barcode module width (2-6)
  final bool showProductName;
  final bool showPrice;
  final bool showProductCode;
  final bool showHriText;      // Human-readable barcode text
  final int labelsPerLine;     // For 80mm: 2, for 58mm: 1
  
  const BarcodeLabelConfig({
    this.labelWidth = 40,
    this.barcodeHeight = 50,
    this.barcodeWidth = 2,
    this.showProductName = true,
    this.showPrice = true,
    this.showProductCode = true,
    this.showHriText = true,
    this.labelsPerLine = 2,
  });
  
  BarcodeLabelConfig copyWith({
    int? labelWidth,
    int? barcodeHeight,
    int? barcodeWidth,
    bool? showProductName,
    bool? showPrice,
    bool? showProductCode,
    bool? showHriText,
    int? labelsPerLine,
  }) {
    return BarcodeLabelConfig(
      labelWidth: labelWidth ?? this.labelWidth,
      barcodeHeight: barcodeHeight ?? this.barcodeHeight,
      barcodeWidth: barcodeWidth ?? this.barcodeWidth,
      showProductName: showProductName ?? this.showProductName,
      showPrice: showPrice ?? this.showPrice,
      showProductCode: showProductCode ?? this.showProductCode,
      showHriText: showHriText ?? this.showHriText,
      labelsPerLine: labelsPerLine ?? this.labelsPerLine,
    );
  }
}

/// Data for a single barcode label
class BarcodeLabelData {
  final String barcodeData;
  final String? productName;
  final String? productCode;
  final double? price;
  final String barcodeFormat;  // CODE128, EAN13, EAN8, CODE39, UPC-A
  
  const BarcodeLabelData({
    required this.barcodeData,
    this.productName,
    this.productCode,
    this.price,
    this.barcodeFormat = 'CODE128',
  });
}

/// ESC/POS Barcode Formatter for thermal printers
class EscPosBarcodeFormatter {
  final PosPaperSize paperSize;
  late final int _cols;
  
  EscPosBarcodeFormatter({this.paperSize = PosPaperSize.mm58}) {
    _cols = paperSize.charsPerLine;
  }
  
  /// Generate bytes for printing multiple barcode labels
  List<int> generateBarcodeLabels({
    required List<BarcodeLabelData> labels,
    BarcodeLabelConfig config = const BarcodeLabelConfig(),
  }) {
    final bytes = <int>[];
    
    // Initialize printer
    bytes.addAll(EscPosCommands.init);
    bytes.addAll(EscPosCommands.setLineSpacing(30));
    
    // Configure barcode settings
    bytes.addAll(EscPosBarcodeCommands.setBarcodeHeight(config.barcodeHeight));
    bytes.addAll(EscPosBarcodeCommands.setBarcodeWidth(config.barcodeWidth));
    bytes.addAll(EscPosBarcodeCommands.setHriPosition(config.showHriText ? 2 : 0)); // Below barcode
    bytes.addAll(EscPosBarcodeCommands.setHriFont(1)); // Font B (smaller)
    
    // Print each label
    for (int i = 0; i < labels.length; i++) {
      final label = labels[i];
      bytes.addAll(_buildSingleLabel(label, config));
      
      // Add separator between labels (thin line)
      if (i < labels.length - 1) {
        bytes.addAll(_thinDivider());
        bytes.addAll(EscPosCommands.lineFeed);
      }
    }
    
    // Feed and cut
    bytes.addAll(EscPosCommands.feedLines(3));
    bytes.addAll(EscPosCommands.cutPaperPartial);
    
    return bytes;
  }
  
  /// Build bytes for a single barcode label
  List<int> _buildSingleLabel(BarcodeLabelData label, BarcodeLabelConfig config) {
    final bytes = <int>[];
    
    // Center alignment for label
    bytes.addAll(EscPosCommands.alignCenter);
    
    // Product name (bold, if enabled)
    if (config.showProductName && label.productName != null && label.productName!.isNotEmpty) {
      bytes.addAll(EscPosCommands.boldOn);
      bytes.addAll(_wrap(label.productName!, maxWidth: _cols));
      bytes.addAll(EscPosCommands.boldOff);
      bytes.addAll(EscPosCommands.lineFeed);
    }
    
    // Product code (small, if enabled)
    if (config.showProductCode && label.productCode != null && label.productCode!.isNotEmpty) {
      bytes.addAll(_textLine('Index: #${label.productCode}'));
    }
    
    // Barcode
    bytes.addAll(_printBarcode(label.barcodeData, label.barcodeFormat));
    bytes.addAll(EscPosCommands.lineFeed);
    
    // Price (bold, larger, if enabled)
    if (config.showPrice && label.price != null) {
      bytes.addAll(EscPosCommands.boldOn);
      bytes.addAll(EscPosCommands.textDoubleHeight);
      bytes.addAll(_textLine('Rs.${label.price!.toStringAsFixed(2)}'));
      bytes.addAll(EscPosCommands.textNormal);
      bytes.addAll(EscPosCommands.boldOff);
    }
    
    bytes.addAll(EscPosCommands.lineFeed);
    
    return bytes;
  }
  
  /// Generate barcode printing command
  List<int> _printBarcode(String data, String format) {
    final bytes = <int>[];
    
    // Get barcode type and sanitize data
    final barcodeType = _getBarcodeType(format);
    final sanitizedData = _sanitizeBarcodeData(data, format);
    
    // Use modern format (m >= 65) with length parameter
    // GS k m n d1...dn
    bytes.add(0x1D); // GS
    bytes.add(0x6B); // k
    bytes.add(barcodeType);
    bytes.add(sanitizedData.length); // n = data length
    bytes.addAll(utf8.encode(sanitizedData));
    
    return bytes;
  }
  
  /// Get ESC/POS barcode type code
  int _getBarcodeType(String format) {
    switch (format.toUpperCase()) {
      case 'EAN13':
        return EscPosBarcodeCommands.barcodeEan13_2;
      case 'EAN8':
        return EscPosBarcodeCommands.barcodeEan8_2;
      case 'UPC-A':
      case 'UPCA':
        return EscPosBarcodeCommands.barcodeUpcA2;
      case 'CODE39':
        return EscPosBarcodeCommands.barcodeCode39_2;
      case 'CODE93':
        return EscPosBarcodeCommands.barcodeCode93;
      case 'CODE128':
      default:
        return EscPosBarcodeCommands.barcodeCode128;
    }
  }
  
  /// Sanitize barcode data for the specific format
  String _sanitizeBarcodeData(String data, String format) {
    switch (format.toUpperCase()) {
      case 'EAN13':
        // EAN13 requires exactly 12 or 13 digits
        String digits = data.replaceAll(RegExp(r'[^0-9]'), '');
        if (digits.length < 12) {
          digits = digits.padLeft(12, '0');
        }
        return digits.substring(0, 12);
      case 'EAN8':
        // EAN8 requires exactly 7 or 8 digits
        String digits = data.replaceAll(RegExp(r'[^0-9]'), '');
        if (digits.length < 7) {
          digits = digits.padLeft(7, '0');
        }
        return digits.substring(0, 7);
      case 'UPC-A':
      case 'UPCA':
        // UPC-A requires exactly 11 or 12 digits
        String digits = data.replaceAll(RegExp(r'[^0-9]'), '');
        if (digits.length < 11) {
          digits = digits.padLeft(11, '0');
        }
        return digits.substring(0, 11);
      case 'CODE39':
        // CODE39 only allows uppercase alphanumeric and some special chars
        return data.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9\-\.\$\/\+\%\s]'), '');
      case 'CODE128':
      default:
        // CODE128 supports full ASCII, prefix with {B for Code Set B
        return '{B$data';
    }
  }
  
  /// Generate text line bytes
  List<int> _textLine(String text) {
    final bytes = <int>[];
    bytes.addAll(utf8.encode(text));
    bytes.addAll(EscPosCommands.lineFeed);
    return bytes;
  }
  
  /// Wrap text to fit within column width
  List<int> _wrap(String text, {int? maxWidth}) {
    final bytes = <int>[];
    final width = maxWidth ?? _cols;
    
    if (text.length <= width) {
      bytes.addAll(utf8.encode(text));
    } else {
      // Truncate with ellipsis for thermal printers
      bytes.addAll(utf8.encode(text.substring(0, width - 3)));
      bytes.addAll(utf8.encode('...'));
    }
    bytes.addAll(EscPosCommands.lineFeed);
    
    return bytes;
  }
  
  /// Thin divider line
  List<int> _thinDivider() {
    final bytes = <int>[];
    bytes.addAll(EscPosCommands.alignCenter);
    bytes.addAll(utf8.encode('-' * _cols));
    bytes.addAll(EscPosCommands.lineFeed);
    return bytes;
  }
  
  /// Generate a simple test barcode
  List<int> generateTestBarcode() {
    return generateBarcodeLabels(
      labels: [
        const BarcodeLabelData(
          barcodeData: '123456789012',
          productName: 'Test Product',
          productCode: 'TST001',
          price: 99.99,
          barcodeFormat: 'CODE128',
        ),
      ],
    );
  }
}

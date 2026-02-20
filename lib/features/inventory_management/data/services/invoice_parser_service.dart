import 'dart:math';

import 'package:flutter/foundation.dart';

import '../../../product/offline/controllers/product_offline_controller.dart';
import '../../models/parsed_purchase_item.dart';

/// Result of parsing invoice text into structured purchase items.
class InvoiceParseResult {
  final bool success;
  final List<ParsedPurchaseItem> items;
  final String? supplierName;
  final DateTime? invoiceDate;
  final String? invoiceNumber;
  final String? errorMessage;
  final String rawText;

  InvoiceParseResult._({
    required this.success,
    this.items = const [],
    this.supplierName,
    this.invoiceDate,
    this.invoiceNumber,
    this.errorMessage,
    this.rawText = '',
  });

  factory InvoiceParseResult.success({
    required List<ParsedPurchaseItem> items,
    required String rawText,
    String? supplierName,
    DateTime? invoiceDate,
    String? invoiceNumber,
  }) {
    return InvoiceParseResult._(
      success: true,
      items: items,
      rawText: rawText,
      supplierName: supplierName,
      invoiceDate: invoiceDate,
      invoiceNumber: invoiceNumber,
    );
  }

  factory InvoiceParseResult.failure(String message, {String rawText = ''}) {
    return InvoiceParseResult._(
      success: false,
      errorMessage: message,
      rawText: rawText,
    );
  }
}

/// Service that converts raw OCR text from invoices into structured
/// [ParsedPurchaseItem] objects. Handles common Indian invoice formats.
class InvoiceParserService {
  static InvoiceParserService? _instance;

  InvoiceParserService._();

  static InvoiceParserService get instance {
    _instance ??= InvoiceParserService._();
    return _instance!;
  }

  // --- Regex patterns for line items ---

  // Pattern 1: Serial number prefix: "1. Product Name  10  25.00  250.00"
  static final _serialPattern = RegExp(
    r'^\s*(\d{1,3})[.)]\s*(.+?)\s{2,}(\d+)\s+([\d,]+\.?\d*)\s+([\d,]+\.?\d*)\s*$',
  );

  // Pattern 2: Product name followed by qty, rate, amount (2+ spaces separation)
  static final _spacedPattern = RegExp(
    r'^(.+?)\s{2,}(\d+)\s+([\d,]+\.?\d*)\s+([\d,]+\.?\d*)\s*$',
  );

  // Pattern 3: Product, qty with unit, rate, amount
  static final _unitPattern = RegExp(
    r'^(.+?)\s+(\d+)\s*(pcs|kg|ltr|box|strip|nos|pair|set|unit|doz|pack|gm|ml|mtr)\.?\s+([\d,]+\.?\d*)\s+([\d,]+\.?\d*)\s*$',
    caseSensitive: false,
  );

  // Pattern 4: HSN code prefix: "12345678 Product Name 10 25.00 250.00"
  static final _hsnPattern = RegExp(
    r'^(\d{4,8})\s+(.+?)\s{2,}(\d+)\s+([\d,]+\.?\d*)\s+([\d,]+\.?\d*)\s*$',
  );

  // Pattern 5: Simple - product name then numbers (fallback)
  static final _simplePattern = RegExp(
    r'^(.+?)\s+(\d+)\s+([\d,]+\.?\d*)\s+([\d,]+\.?\d*)\s*$',
  );

  // Pattern 6: Product name, qty, rate only (no total)
  static final _noTotalPattern = RegExp(
    r'^(.+?)\s{2,}(\d+)\s+([\d,]+\.?\d*)\s*$',
  );

  // Lines to skip
  static final _skipPatterns = [
    RegExp(
      r'(sub\s*total|grand\s*total|net\s*amount|balance\s*due|amount\s*paid|round\s*off)',
      caseSensitive: false,
    ),
    RegExp(
      r'(cgst|sgst|igst|gst\s*@|tax\s*amount|vat\s*@)',
      caseSensitive: false,
    ),
    RegExp(
      r'(bank|ifsc|account|upi|a/c\s*no|neft|rtgs|imps)',
      caseSensitive: false,
    ),
    RegExp(
      r'(terms|condition|note:|remark|thank\s*you|e\.?\s*&\s*o\.?\s*e)',
      caseSensitive: false,
    ),
    RegExp(
      r'^\s*(s\.?\s*no\.?|sr\.?\s*no\.?|item|particular|description|qty|quantity|rate|price|amount|hsn|sac|total)\s*$',
      caseSensitive: false,
    ),
    RegExp(r'(invoice|bill\s*no|dated|gstin|pan|cin|tin)', caseSensitive: false),
    RegExp(r'(phone|mobile|tel|email|web|www)', caseSensitive: false),
    RegExp(r'(address|city|state|pin|zip)', caseSensitive: false),
    RegExp(r'^\s*[-=_*]{3,}\s*$'), // Separator lines
    RegExp(r'^\s*\d{1,2}[/-]\d{1,2}[/-]\d{2,4}\s*$'), // Date-only lines
  ];

  // Header row detection
  static final _headerPattern = RegExp(
    r'(s\.?\s*no|sr|item|particular|description|product)\s.*(qty|quantity|rate|price|amount)',
    caseSensitive: false,
  );

  // Date extraction
  static final _datePatterns = [
    RegExp(
      r'(?:date|dated)\s*:?\s*(\d{1,2}[/-]\d{1,2}[/-]\d{2,4})',
      caseSensitive: false,
    ),
    RegExp(r'(\d{1,2}[/-]\d{1,2}[/-]\d{4})'),
  ];

  // Invoice number extraction
  static final _invoiceNumberPattern = RegExp(
    r'(?:invoice|bill|inv)\s*(?:no\.?|number|#)?\s*:?\s*([A-Za-z0-9/-]+)',
    caseSensitive: false,
  );

  /// Parse raw OCR text into structured invoice items.
  Future<InvoiceParseResult> parseInvoiceText(String rawText) async {
    if (rawText.trim().isEmpty) {
      return InvoiceParseResult.failure('Empty text provided', rawText: rawText);
    }

    try {
      // Extract header info
      final invoiceDate = _extractDate(rawText);
      final invoiceNumber = _extractInvoiceNumber(rawText);

      // Parse line items
      final items = _parseLineItems(rawText);

      if (items.isEmpty) {
        return InvoiceParseResult.failure(
          'No product items could be identified in the invoice',
          rawText: rawText,
        );
      }

      debugPrint(
        '[InvoiceParser] Parsed ${items.length} items from invoice',
      );

      return InvoiceParseResult.success(
        items: items,
        rawText: rawText,
        invoiceDate: invoiceDate,
        invoiceNumber: invoiceNumber,
      );
    } catch (e) {
      debugPrint('[InvoiceParser] Parsing failed: $e');
      return InvoiceParseResult.failure(
        'Failed to parse invoice: $e',
        rawText: rawText,
      );
    }
  }

  /// Auto-match parsed items against existing products in the database.
  Future<void> matchWithExistingProducts(
    List<ParsedPurchaseItem> items,
  ) async {
    try {
      final allProducts =
          await ProductOfflineController.instance.getAllProducts();

      if (allProducts.isEmpty) return;

      for (final item in items) {
        final itemNameLower = item.productName.toLowerCase().trim();
        if (itemNameLower.isEmpty) continue;

        String? bestMatchId;
        String? bestMatchName;
        String? bestMatchCompany;
        String? bestMatchCategory;
        double? bestMatchSalesPrice;
        double bestScore = 0.0;

        for (final product in allProducts) {
          final productNameLower = product.name.toLowerCase().trim();
          final score = _stringSimilarity(itemNameLower, productNameLower);

          if (score > bestScore && score >= 0.6) {
            bestScore = score;
            bestMatchId = product.serverId ?? 'local_${product.id}';
            bestMatchName = product.name;
            bestMatchCompany = product.companyName;
            bestMatchCategory = product.category;
            bestMatchSalesPrice = product.salesPrice;
          }
        }

        if (bestMatchId != null) {
          item.matchedProductId = bestMatchId;
          item.matchedProductName = bestMatchName;
          item.matchedCompanyName = bestMatchCompany;
          item.matchedCategory = bestMatchCategory;
          item.existingSalesPrice = bestMatchSalesPrice;

          // Fill in sales price from existing product if not parsed
          if (item.salesPrice <= 0 && (bestMatchSalesPrice ?? 0) > 0) {
            item.salesPrice = bestMatchSalesPrice!;
          }

          debugPrint(
            '[InvoiceParser] Matched "${item.productName}" → '
            '"$bestMatchName" (score: ${bestScore.toStringAsFixed(2)})',
          );
        }
      }
    } catch (e) {
      debugPrint('[InvoiceParser] Product matching failed: $e');
    }
  }

  // --- Private helpers ---

  List<ParsedPurchaseItem> _parseLineItems(String text) {
    final lines =
        text
            .split('\n')
            .map((l) => l.trim())
            .where((l) => l.isNotEmpty)
            .toList();

    final items = <ParsedPurchaseItem>[];
    bool pastHeader = false;

    for (final line in lines) {
      // Detect header row to start parsing after it
      if (_headerPattern.hasMatch(line)) {
        pastHeader = true;
        continue;
      }

      // Skip known non-item lines
      if (_shouldSkipLine(line)) continue;

      // Try to parse as a product line item
      final item = _tryParseLine(line, pastHeader);
      if (item != null) {
        items.add(item);
        pastHeader = true; // Once we find items, we're past the header
      }
    }

    return items;
  }

  bool _shouldSkipLine(String line) {
    return _skipPatterns.any((p) => p.hasMatch(line));
  }

  ParsedPurchaseItem? _tryParseLine(String line, bool pastHeader) {
    // Try each pattern in order of specificity

    // Pattern 1: Serial number prefix
    var match = _serialPattern.firstMatch(line);
    if (match != null) {
      final name = _cleanProductName(match.group(2)!);
      if (name.isNotEmpty) {
        return ParsedPurchaseItem(
          productName: name,
          quantity: int.tryParse(match.group(3)!) ?? 1,
          purchasePrice: _parsePrice(match.group(4)!),
          salesPrice: 0.0,
          confidence: 0.85,
        );
      }
    }

    // Pattern 4: HSN prefix
    match = _hsnPattern.firstMatch(line);
    if (match != null) {
      final name = _cleanProductName(match.group(2)!);
      if (name.isNotEmpty) {
        return ParsedPurchaseItem(
          productName: name,
          quantity: int.tryParse(match.group(3)!) ?? 1,
          purchasePrice: _parsePrice(match.group(4)!),
          salesPrice: 0.0,
          hsnCode: match.group(1),
          confidence: 0.80,
        );
      }
    }

    // Pattern 3: With unit
    match = _unitPattern.firstMatch(line);
    if (match != null) {
      final name = _cleanProductName(match.group(1)!);
      if (name.isNotEmpty) {
        return ParsedPurchaseItem(
          productName: name,
          quantity: int.tryParse(match.group(2)!) ?? 1,
          purchasePrice: _parsePrice(match.group(4)!),
          salesPrice: 0.0,
          unit: match.group(3)!.toLowerCase().replaceAll('.', ''),
          confidence: 0.80,
        );
      }
    }

    // Pattern 2: Space-delimited (qty, rate, amount)
    match = _spacedPattern.firstMatch(line);
    if (match != null) {
      final name = _cleanProductName(match.group(1)!);
      final qty = int.tryParse(match.group(2)!) ?? 0;
      final rate = _parsePrice(match.group(3)!);
      final amount = _parsePrice(match.group(4)!);

      if (name.isNotEmpty && qty > 0 && rate > 0) {
        // Validate: qty * rate should approximately equal amount
        final expectedAmount = qty * rate;
        final confidence = _calculateConfidence(expectedAmount, amount);

        return ParsedPurchaseItem(
          productName: name,
          quantity: qty,
          purchasePrice: rate,
          salesPrice: 0.0,
          confidence: confidence,
        );
      }
    }

    // Pattern 5: Simple fallback (product, qty, rate, amount)
    if (pastHeader) {
      match = _simplePattern.firstMatch(line);
      if (match != null) {
        final name = _cleanProductName(match.group(1)!);
        final qty = int.tryParse(match.group(2)!) ?? 0;
        final rate = _parsePrice(match.group(3)!);
        final amount = _parsePrice(match.group(4)!);

        if (name.isNotEmpty && name.length > 2 && qty > 0 && rate > 0) {
          final expectedAmount = qty * rate;
          final confidence = _calculateConfidence(expectedAmount, amount);

          // Lower confidence for simple pattern to avoid false positives
          return ParsedPurchaseItem(
            productName: name,
            quantity: qty,
            purchasePrice: rate,
            salesPrice: 0.0,
            confidence: confidence * 0.8,
          );
        }
      }

      // Pattern 6: No total column
      match = _noTotalPattern.firstMatch(line);
      if (match != null) {
        final name = _cleanProductName(match.group(1)!);
        final qty = int.tryParse(match.group(2)!) ?? 0;
        final rate = _parsePrice(match.group(3)!);

        if (name.isNotEmpty && name.length > 2 && qty > 0 && rate > 0) {
          return ParsedPurchaseItem(
            productName: name,
            quantity: qty,
            purchasePrice: rate,
            salesPrice: 0.0,
            confidence: 0.55,
          );
        }
      }
    }

    return null;
  }

  /// Clean up a product name extracted from OCR text.
  String _cleanProductName(String raw) {
    var name = raw.trim();

    // Remove leading serial numbers/bullets
    name = name.replaceFirst(RegExp(r'^[\d.)\-]+\s*'), '');

    // Remove ₹ symbol
    name = name.replaceAll('₹', '').trim();

    // Remove trailing spaces and common noise
    name = name.replaceAll(RegExp(r'\s+'), ' ').trim();

    // Remove if it's all numbers (not a product name)
    if (RegExp(r'^[\d\s,.]+$').hasMatch(name)) return '';

    return name;
  }

  /// Parse a price string, handling Indian number formats.
  /// "1,25,000.50" → 125000.50
  /// "₹ 250" → 250.0
  double _parsePrice(String priceStr) {
    var cleaned = priceStr.replaceAll(RegExp(r'[₹,\s]'), '');
    return double.tryParse(cleaned) ?? 0.0;
  }

  /// Calculate confidence based on how close qty*rate is to the total amount.
  double _calculateConfidence(double expected, double actual) {
    if (actual <= 0) return 0.65;
    if (expected <= 0) return 0.50;

    final ratio = (expected / actual).clamp(0.0, 2.0);
    // Perfect match = 1.0, some tolerance for rounding
    if ((ratio - 1.0).abs() < 0.02) return 0.90;
    if ((ratio - 1.0).abs() < 0.10) return 0.75;
    if ((ratio - 1.0).abs() < 0.25) return 0.60;
    return 0.45;
  }

  /// Extract invoice date from text.
  DateTime? _extractDate(String text) {
    for (final pattern in _datePatterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        final dateStr = match.group(1)!;
        return _tryParseDate(dateStr);
      }
    }
    return null;
  }

  /// Try parsing a date string in common Indian formats.
  DateTime? _tryParseDate(String dateStr) {
    final parts = dateStr.split(RegExp(r'[/-]'));
    if (parts.length != 3) return null;

    try {
      final day = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      var year = int.parse(parts[2]);

      // Handle 2-digit year
      if (year < 100) {
        year += 2000;
      }

      if (month >= 1 && month <= 12 && day >= 1 && day <= 31) {
        return DateTime(year, month, day);
      }
    } catch (_) {}

    return null;
  }

  /// Extract invoice number from text.
  String? _extractInvoiceNumber(String text) {
    final match = _invoiceNumberPattern.firstMatch(text);
    return match?.group(1)?.trim();
  }

  /// Calculate string similarity using normalized Levenshtein distance.
  /// Returns a value between 0.0 (no match) and 1.0 (exact match).
  double _stringSimilarity(String a, String b) {
    if (a == b) return 1.0;
    if (a.isEmpty || b.isEmpty) return 0.0;

    // Check containment
    if (a.contains(b) || b.contains(a)) {
      final shorter = a.length < b.length ? a.length : b.length;
      final longer = a.length > b.length ? a.length : b.length;
      return 0.7 + (0.3 * (shorter / longer));
    }

    final distance = _levenshteinDistance(a, b);
    final maxLen = max(a.length, b.length);
    return 1.0 - (distance / maxLen);
  }

  /// Compute Levenshtein edit distance between two strings.
  int _levenshteinDistance(String a, String b) {
    if (a.isEmpty) return b.length;
    if (b.isEmpty) return a.length;

    List<int> prev = List<int>.generate(b.length + 1, (i) => i);
    List<int> curr = List<int>.filled(b.length + 1, 0);

    for (int i = 1; i <= a.length; i++) {
      curr[0] = i;
      for (int j = 1; j <= b.length; j++) {
        final cost = a[i - 1] == b[j - 1] ? 0 : 1;
        curr[j] = min(min(curr[j - 1] + 1, prev[j] + 1), prev[j - 1] + cost);
      }
      final temp = prev;
      prev = curr;
      curr = temp;
    }

    return prev[b.length];
  }
}

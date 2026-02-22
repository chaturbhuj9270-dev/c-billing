import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Model representing a scanned invoice item
class ScannedInvoiceItem {
  String productName;
  String? companyName;
  int quantity;
  double purchasePrice;
  double? salesPrice;
  String? unit;
  String? hsnCode;
  DateTime? productionDate;
  DateTime? expiryDate;
  double? cgstPercent;
  double? sgstPercent;
  String? batchNumber;
  bool isSelected;
  String? matchedProductId;

  ScannedInvoiceItem({
    required this.productName,
    this.companyName,
    required this.quantity,
    required this.purchasePrice,
    this.salesPrice,
    this.unit,
    this.hsnCode,
    this.productionDate,
    this.expiryDate,
    this.cgstPercent,
    this.sgstPercent,
    this.batchNumber,
    this.isSelected = true,
    this.matchedProductId,
  });

  factory ScannedInvoiceItem.fromJson(Map<String, dynamic> json) {
    return ScannedInvoiceItem(
      productName: json['productName'] ?? json['name'] ?? 'Unknown',
      companyName: json['companyName'] ?? json['company'] ?? json['brand'],
      quantity: _parseIntSafe(json['quantity'] ?? json['qty']),
      purchasePrice: _parseDoubleSafe(json['purchasePrice'] ?? json['price'] ?? json['rate'] ?? json['unitPrice']),
      salesPrice: json['salesPrice'] != null || json['mrp'] != null || json['sellingPrice'] != null
          ? _parseDoubleSafe(json['salesPrice'] ?? json['mrp'] ?? json['sellingPrice'])
          : null,
      unit: json['unit'] ?? json['uom'],
      hsnCode: json['hsnCode'] ?? json['hsn'],
      productionDate: _parseDateSafe(json['productionDate'] ?? json['mfgDate'] ?? json['manufacturingDate']),
      expiryDate: _parseDateSafe(json['expiryDate'] ?? json['expDate'] ?? json['expiry']),
      cgstPercent: json['cgstPercent'] != null || json['cgst'] != null
          ? _parseDoubleSafe(json['cgstPercent'] ?? json['cgst'])
          : null,
      sgstPercent: json['sgstPercent'] != null || json['sgst'] != null
          ? _parseDoubleSafe(json['sgstPercent'] ?? json['sgst'])
          : null,
      batchNumber: json['batchNumber'] ?? json['batch'] ?? json['lotNumber'],
    );
  }

  Map<String, dynamic> toJson() => {
    'productName': productName,
    'companyName': companyName,
    'quantity': quantity,
    'purchasePrice': purchasePrice,
    'salesPrice': salesPrice,
    'unit': unit,
    'hsnCode': hsnCode,
    'productionDate': productionDate?.toIso8601String(),
    'expiryDate': expiryDate?.toIso8601String(),
    'cgstPercent': cgstPercent,
    'sgstPercent': sgstPercent,
    'batchNumber': batchNumber,
    'isSelected': isSelected,
    'matchedProductId': matchedProductId,
  };

  static int _parseIntSafe(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) {
      final cleaned = value.replaceAll(RegExp(r'[^\d.]'), '');
      return int.tryParse(cleaned) ?? double.tryParse(cleaned)?.toInt() ?? 0;
    }
    return 0;
  }

  static double _parseDoubleSafe(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      final cleaned = value.replaceAll(RegExp(r'[^\d.]'), '');
      return double.tryParse(cleaned) ?? 0.0;
    }
    return 0.0;
  }

  static DateTime? _parseDateSafe(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) {
      try {
        // Try ISO format first
        final parsed = DateTime.tryParse(value);
        if (parsed != null) return parsed;
        
        // Try common date formats
        final formats = [
          RegExp(r'(\d{2})/(\d{2})/(\d{4})'), // DD/MM/YYYY
          RegExp(r'(\d{2})-(\d{2})-(\d{4})'), // DD-MM-YYYY
          RegExp(r'(\d{4})/(\d{2})/(\d{2})'), // YYYY/MM/DD
          RegExp(r'(\d{4})-(\d{2})-(\d{2})'), // YYYY-MM-DD
        ];
        
        for (final format in formats) {
          final match = format.firstMatch(value);
          if (match != null) {
            final groups = match.groups([1, 2, 3]);
            if (groups.every((g) => g != null)) {
              int year, month, day;
              if (groups[0]!.length == 4) {
                year = int.parse(groups[0]!);
                month = int.parse(groups[1]!);
                day = int.parse(groups[2]!);
              } else {
                day = int.parse(groups[0]!);
                month = int.parse(groups[1]!);
                year = int.parse(groups[2]!);
              }
              return DateTime(year, month, day);
            }
          }
        }
      } catch (_) {}
    }
    return null;
  }

  ScannedInvoiceItem copyWith({
    String? productName,
    String? companyName,
    int? quantity,
    double? purchasePrice,
    double? salesPrice,
    String? unit,
    String? hsnCode,
    DateTime? productionDate,
    DateTime? expiryDate,
    double? cgstPercent,
    double? sgstPercent,
    String? batchNumber,
    bool? isSelected,
    String? matchedProductId,
  }) {
    return ScannedInvoiceItem(
      productName: productName ?? this.productName,
      companyName: companyName ?? this.companyName,
      quantity: quantity ?? this.quantity,
      purchasePrice: purchasePrice ?? this.purchasePrice,
      salesPrice: salesPrice ?? this.salesPrice,
      unit: unit ?? this.unit,
      hsnCode: hsnCode ?? this.hsnCode,
      productionDate: productionDate ?? this.productionDate,
      expiryDate: expiryDate ?? this.expiryDate,
      cgstPercent: cgstPercent ?? this.cgstPercent,
      sgstPercent: sgstPercent ?? this.sgstPercent,
      batchNumber: batchNumber ?? this.batchNumber,
      isSelected: isSelected ?? this.isSelected,
      matchedProductId: matchedProductId ?? this.matchedProductId,
    );
  }
}

/// Model representing scanned invoice metadata
class ScannedInvoiceData {
  String? invoiceNumber;
  DateTime? invoiceDate;
  String? supplierName;
  String? supplierContact;
  String? supplierAddress;
  double? totalAmount;
  double? taxAmount;
  double? discountAmount;
  List<ScannedInvoiceItem> items;
  Uint8List? imageBytes;

  ScannedInvoiceData({
    this.invoiceNumber,
    this.invoiceDate,
    this.supplierName,
    this.supplierContact,
    this.supplierAddress,
    this.totalAmount,
    this.taxAmount,
    this.discountAmount,
    required this.items,
    this.imageBytes,
  });

  factory ScannedInvoiceData.fromJson(Map<String, dynamic> json) {
    final itemsList = json['items'] as List<dynamic>? ?? [];
    return ScannedInvoiceData(
      invoiceNumber: json['invoiceNumber'] ?? json['billNumber'] ?? json['receiptNumber'],
      invoiceDate: ScannedInvoiceItem._parseDateSafe(json['invoiceDate'] ?? json['date'] ?? json['billDate']),
      supplierName: json['supplierName'] ?? json['vendor'] ?? json['seller'],
      supplierContact: json['supplierContact'] ?? json['contact'] ?? json['phone'],
      supplierAddress: json['supplierAddress'] ?? json['address'],
      totalAmount: json['totalAmount'] != null || json['total'] != null || json['grandTotal'] != null
          ? ScannedInvoiceItem._parseDoubleSafe(json['totalAmount'] ?? json['total'] ?? json['grandTotal'])
          : null,
      taxAmount: json['taxAmount'] != null || json['tax'] != null || json['gst'] != null
          ? ScannedInvoiceItem._parseDoubleSafe(json['taxAmount'] ?? json['tax'] ?? json['gst'])
          : null,
      discountAmount: json['discountAmount'] != null || json['discount'] != null
          ? ScannedInvoiceItem._parseDoubleSafe(json['discountAmount'] ?? json['discount'])
          : null,
      items: itemsList.map((item) => ScannedInvoiceItem.fromJson(item as Map<String, dynamic>)).toList(),
    );
  }
}

/// Result of invoice scanning operation
class InvoiceScanResult {
  final bool success;
  final ScannedInvoiceData? data;
  final String? errorMessage;
  final String? rawResponse;

  InvoiceScanResult({
    required this.success,
    this.data,
    this.errorMessage,
    this.rawResponse,
  });

  factory InvoiceScanResult.error(String message) {
    return InvoiceScanResult(success: false, errorMessage: message);
  }

  factory InvoiceScanResult.success(ScannedInvoiceData data, {String? rawResponse}) {
    return InvoiceScanResult(success: true, data: data, rawResponse: rawResponse);
  }
}

/// Service for scanning invoices using Google Gemini AI
class InvoiceScannerService {
  static const String _apiKeyPrefKey = 'gemini_api_key';
  static final InvoiceScannerService _instance = InvoiceScannerService._internal();
  
  factory InvoiceScannerService() => _instance;
  static InvoiceScannerService get instance => _instance;
  
  InvoiceScannerService._internal();

  GenerativeModel? _model;
  String? _apiKey;

  /// Initialize the service with API key
  Future<void> initialize({String? apiKey}) async {
    if (apiKey != null && apiKey.isNotEmpty) {
      _apiKey = apiKey;
      await _saveApiKey(apiKey);
    } else {
      _apiKey = await _loadApiKey();
    }
    
    if (_apiKey != null && _apiKey!.isNotEmpty) {
      _initializeModel();
    }
  }

  void _initializeModel() {
    if (_apiKey == null || _apiKey!.isEmpty) return;
    
    _model = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: _apiKey!,
      generationConfig: GenerationConfig(
        temperature: 0.1, // Low temperature for accuracy
        topP: 0.95,
        maxOutputTokens: 8192,
      ),
    );
  }

  Future<void> _saveApiKey(String apiKey) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_apiKeyPrefKey, apiKey);
  }

  Future<String?> _loadApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_apiKeyPrefKey);
  }

  /// Check if API key is configured
  bool get isConfigured => _apiKey != null && _apiKey!.isNotEmpty;

  /// Get current API key (masked)
  String? get maskedApiKey {
    if (_apiKey == null || _apiKey!.length < 8) return null;
    return '${_apiKey!.substring(0, 4)}****${_apiKey!.substring(_apiKey!.length - 4)}';
  }

  /// Update API key
  Future<void> setApiKey(String apiKey) async {
    _apiKey = apiKey;
    await _saveApiKey(apiKey);
    _initializeModel();
  }

  /// Clear API key
  Future<void> clearApiKey() async {
    _apiKey = null;
    _model = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_apiKeyPrefKey);
  }

  /// Pick image from camera or gallery
  Future<File?> pickImage({required ImageSource source}) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: source,
      maxWidth: 2048,
      maxHeight: 2048,
      imageQuality: 85,
    );
    
    if (pickedFile != null) {
      return File(pickedFile.path);
    }
    return null;
  }

  /// Scan invoice image and extract data using Gemini AI
  Future<InvoiceScanResult> scanInvoice(File imageFile) async {
    if (!isConfigured) {
      return InvoiceScanResult.error('Gemini API key not configured. Please set up your API key in settings.');
    }

    if (_model == null) {
      _initializeModel();
      if (_model == null) {
        return InvoiceScanResult.error('Failed to initialize Gemini AI model.');
      }
    }

    try {
      final imageBytes = await imageFile.readAsBytes();
      
      final prompt = '''
Analyze this supplier invoice/purchase receipt image and extract all product/item details.

Return a JSON object with this exact structure:
{
  "invoiceNumber": "invoice/bill number if visible",
  "invoiceDate": "date in YYYY-MM-DD format",
  "supplierName": "supplier/vendor name",
  "supplierContact": "phone/contact if visible",
  "supplierAddress": "address if visible",
  "totalAmount": total amount as number,
  "taxAmount": tax/GST amount as number,
  "discountAmount": discount if any as number,
  "items": [
    {
      "productName": "exact product name",
      "companyName": "brand/company name if visible",
      "quantity": quantity as integer,
      "purchasePrice": unit purchase price as number,
      "salesPrice": MRP/selling price if visible as number,
      "unit": "unit of measurement (pcs, kg, box, etc)",
      "hsnCode": "HSN code if visible",
      "productionDate": "manufacturing date in YYYY-MM-DD if visible",
      "expiryDate": "expiry date in YYYY-MM-DD if visible",
      "cgstPercent": CGST percentage as number,
      "sgstPercent": SGST percentage as number,
      "batchNumber": "batch/lot number if visible"
    }
  ]
}

Important rules:
1. Return ONLY valid JSON, no markdown formatting or extra text
2. Extract ALL items from the invoice, each as a separate object in the items array
3. If a field is not visible or unclear, omit it or set to null
4. Ensure numerical values are numbers, not strings
5. For dates, use YYYY-MM-DD format
6. Calculate unit price if only total price and quantity are shown
7. If GST is combined, split equally between CGST and SGST
8. Be accurate - don't guess values that aren't visible
''';

      final content = [
        Content.multi([
          TextPart(prompt),
          DataPart('image/jpeg', imageBytes),
        ])
      ];

      final response = await _model!.generateContent(content);
      final responseText = response.text;

      if (responseText == null || responseText.isEmpty) {
        return InvoiceScanResult.error('No response from Gemini AI. Please try again.');
      }

      debugPrint('[InvoiceScanner] Raw response: $responseText');

      // Clean the response - remove markdown code blocks if present
      String cleanedResponse = responseText.trim();
      if (cleanedResponse.startsWith('```json')) {
        cleanedResponse = cleanedResponse.substring(7);
      }
      if (cleanedResponse.startsWith('```')) {
        cleanedResponse = cleanedResponse.substring(3);
      }
      if (cleanedResponse.endsWith('```')) {
        cleanedResponse = cleanedResponse.substring(0, cleanedResponse.length - 3);
      }
      cleanedResponse = cleanedResponse.trim();

      // Parse JSON
      final jsonData = jsonDecode(cleanedResponse) as Map<String, dynamic>;
      final invoiceData = ScannedInvoiceData.fromJson(jsonData);
      invoiceData.imageBytes = imageBytes;

      if (invoiceData.items.isEmpty) {
        return InvoiceScanResult.error('No items found in the invoice. Please ensure the image is clear and contains product details.');
      }

      return InvoiceScanResult.success(invoiceData, rawResponse: responseText);

    } on FormatException catch (e) {
      debugPrint('[InvoiceScanner] JSON parse error: $e');
      return InvoiceScanResult.error('Failed to parse invoice data. Please try with a clearer image.');
    } catch (e) {
      debugPrint('[InvoiceScanner] Error: $e');
      if (e.toString().contains('API key')) {
        return InvoiceScanResult.error('Invalid API key. Please check your Gemini API key in settings.');
      }
      if (e.toString().contains('quota') || e.toString().contains('rate limit')) {
        return InvoiceScanResult.error('API quota exceeded. Please try again later.');
      }
      return InvoiceScanResult.error('Error scanning invoice: ${e.toString()}');
    }
  }

  /// Scan invoice from bytes (for web or pre-loaded images)
  Future<InvoiceScanResult> scanInvoiceFromBytes(Uint8List imageBytes) async {
    if (!isConfigured) {
      return InvoiceScanResult.error('Gemini API key not configured. Please set up your API key in settings.');
    }

    if (_model == null) {
      _initializeModel();
      if (_model == null) {
        return InvoiceScanResult.error('Failed to initialize Gemini AI model.');
      }
    }

    try {
      final prompt = '''
Analyze this supplier invoice/purchase receipt image and extract all product/item details.

Return a JSON object with this exact structure:
{
  "invoiceNumber": "invoice/bill number if visible",
  "invoiceDate": "date in YYYY-MM-DD format",
  "supplierName": "supplier/vendor name",
  "supplierContact": "phone/contact if visible",
  "supplierAddress": "address if visible",
  "totalAmount": total amount as number,
  "taxAmount": tax/GST amount as number,
  "discountAmount": discount if any as number,
  "items": [
    {
      "productName": "exact product name",
      "companyName": "brand/company name if visible",
      "quantity": quantity as integer,
      "purchasePrice": unit purchase price as number,
      "salesPrice": MRP/selling price if visible as number,
      "unit": "unit of measurement (pcs, kg, box, etc)",
      "hsnCode": "HSN code if visible",
      "productionDate": "manufacturing date in YYYY-MM-DD if visible",
      "expiryDate": "expiry date in YYYY-MM-DD if visible",
      "cgstPercent": CGST percentage as number,
      "sgstPercent": SGST percentage as number,
      "batchNumber": "batch/lot number if visible"
    }
  ]
}

Important rules:
1. Return ONLY valid JSON, no markdown formatting or extra text
2. Extract ALL items from the invoice, each as a separate object in the items array
3. If a field is not visible or unclear, omit it or set to null
4. Ensure numerical values are numbers, not strings
5. For dates, use YYYY-MM-DD format
6. Calculate unit price if only total price and quantity are shown
7. If GST is combined, split equally between CGST and SGST
8. Be accurate - don't guess values that aren't visible
''';

      final content = [
        Content.multi([
          TextPart(prompt),
          DataPart('image/jpeg', imageBytes),
        ])
      ];

      final response = await _model!.generateContent(content);
      final responseText = response.text;

      if (responseText == null || responseText.isEmpty) {
        return InvoiceScanResult.error('No response from Gemini AI. Please try again.');
      }

      // Clean the response
      String cleanedResponse = responseText.trim();
      if (cleanedResponse.startsWith('```json')) {
        cleanedResponse = cleanedResponse.substring(7);
      }
      if (cleanedResponse.startsWith('```')) {
        cleanedResponse = cleanedResponse.substring(3);
      }
      if (cleanedResponse.endsWith('```')) {
        cleanedResponse = cleanedResponse.substring(0, cleanedResponse.length - 3);
      }
      cleanedResponse = cleanedResponse.trim();

      final jsonData = jsonDecode(cleanedResponse) as Map<String, dynamic>;
      final invoiceData = ScannedInvoiceData.fromJson(jsonData);
      invoiceData.imageBytes = imageBytes;

      if (invoiceData.items.isEmpty) {
        return InvoiceScanResult.error('No items found in the invoice.');
      }

      return InvoiceScanResult.success(invoiceData, rawResponse: responseText);

    } on FormatException catch (e) {
      debugPrint('[InvoiceScanner] JSON parse error: $e');
      return InvoiceScanResult.error('Failed to parse invoice data.');
    } catch (e) {
      debugPrint('[InvoiceScanner] Error: $e');
      return InvoiceScanResult.error('Error scanning invoice: ${e.toString()}');
    }
  }
}

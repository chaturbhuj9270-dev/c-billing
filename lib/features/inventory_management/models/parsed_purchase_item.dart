/// Model representing a single product row parsed from an invoice via OCR.
/// Used as an intermediate data structure between OCR parsing and
/// the existing [InventoryIntegrationService.processPurchase()] pipeline.
class ParsedPurchaseItem {
  // Raw OCR values (user-editable on preview screen)
  String productName;
  int quantity;
  double purchasePrice;
  double salesPrice;
  String unit;

  // Confidence score from parsing (0.0 - 1.0)
  double confidence;

  // Auto-match to existing product (nullable)
  String? matchedProductId;
  String? matchedProductName;
  String? matchedCompanyName;
  String? matchedCategory;
  double? existingSalesPrice;

  // Optional invoice fields
  String? hsnCode;
  double? cgstPercent;
  double? sgstPercent;

  // Selection state for preview screen
  bool isSelected;

  bool get isValid =>
      productName.trim().isNotEmpty && quantity > 0 && purchasePrice >= 0;

  bool get hasMatch => matchedProductId != null;

  double get total => quantity * purchasePrice;

  ParsedPurchaseItem({
    required this.productName,
    this.quantity = 1,
    this.purchasePrice = 0.0,
    this.salesPrice = 0.0,
    this.unit = 'pcs',
    this.confidence = 0.0,
    this.matchedProductId,
    this.matchedProductName,
    this.matchedCompanyName,
    this.matchedCategory,
    this.existingSalesPrice,
    this.hsnCode,
    this.cgstPercent,
    this.sgstPercent,
    this.isSelected = true,
  });

  ParsedPurchaseItem copyWith({
    String? productName,
    int? quantity,
    double? purchasePrice,
    double? salesPrice,
    String? unit,
    double? confidence,
    String? matchedProductId,
    String? matchedProductName,
    String? matchedCompanyName,
    String? matchedCategory,
    double? existingSalesPrice,
    String? hsnCode,
    double? cgstPercent,
    double? sgstPercent,
    bool? isSelected,
  }) {
    return ParsedPurchaseItem(
      productName: productName ?? this.productName,
      quantity: quantity ?? this.quantity,
      purchasePrice: purchasePrice ?? this.purchasePrice,
      salesPrice: salesPrice ?? this.salesPrice,
      unit: unit ?? this.unit,
      confidence: confidence ?? this.confidence,
      matchedProductId: matchedProductId ?? this.matchedProductId,
      matchedProductName: matchedProductName ?? this.matchedProductName,
      matchedCompanyName: matchedCompanyName ?? this.matchedCompanyName,
      matchedCategory: matchedCategory ?? this.matchedCategory,
      existingSalesPrice: existingSalesPrice ?? this.existingSalesPrice,
      hsnCode: hsnCode ?? this.hsnCode,
      cgstPercent: cgstPercent ?? this.cgstPercent,
      sgstPercent: sgstPercent ?? this.sgstPercent,
      isSelected: isSelected ?? this.isSelected,
    );
  }
}

/// Pack ↔ base unit conversion for bulk buy / loose sell
/// (e.g. Strip→Tablet, Bag→Kg, Box→Pcs).
///
/// Inventory, FIFO batches, and stock ledgers always use **base units**.
/// Pack qty is a UI / purchase-entry convenience only.
class PackUnitConversion {
  PackUnitConversion._();

  static const int defaultUnitsPerPack = 1;

  /// Pack container units that trigger pack↔base conversion UI.
  /// Visibility in purchase/sale still comes from user settings.
  static const List<String> knownPackUnits = ['Strip', 'Bag', 'Box'];

  static bool isKnownPackUnit(String? unit) {
    final u = unit?.trim().toLowerCase();
    if (u == null || u.isEmpty) return false;
    return knownPackUnits.any((p) => p.toLowerCase() == u);
  }

  /// True when the product can be bought/sold as a pack.
  static bool hasPack({String? packUnit, int? unitsPerPack}) {
    final n = unitsPerPack ?? defaultUnitsPerPack;
    return n > 1 && packUnit != null && packUnit.trim().isNotEmpty;
  }

  static int normalizeUnitsPerPack(int? unitsPerPack) {
    final n = unitsPerPack ?? defaultUnitsPerPack;
    return n < 1 ? defaultUnitsPerPack : n;
  }

  /// Packs → base units (stock scale). Supports fractional packs.
  static double toBaseQuantity(num packOrBaseQty, int unitsPerPack) {
    final n = normalizeUnitsPerPack(unitsPerPack);
    if (n <= 1) return packOrBaseQty.toDouble();
    return packOrBaseQty.toDouble() * n;
  }

  /// Base units → pack display qty.
  static double toPackQuantity(num baseQty, int unitsPerPack) {
    final n = normalizeUnitsPerPack(unitsPerPack);
    if (n <= 1) return baseQty.toDouble();
    return baseQty / n;
  }

  /// Price entered per pack → price per base unit (FIFO / product cost).
  static double toBaseUnitPrice(num packPrice, int unitsPerPack) {
    final n = normalizeUnitsPerPack(unitsPerPack);
    if (n <= 1) return packPrice.toDouble();
    return packPrice / n;
  }

  /// Price per base → price for one pack (billing UI).
  static double toPackUnitPrice(num basePrice, int unitsPerPack) {
    final n = normalizeUnitsPerPack(unitsPerPack);
    if (n <= 1) return basePrice.toDouble();
    return (basePrice * n).toDouble();
  }

  /// Whether [sellUnit] refers to the pack (not base / not kg-gm).
  static bool isSellingAsPack({
    required String? sellUnit,
    required String? baseUnit,
    required String? packUnit,
    int? unitsPerPack,
  }) {
    if (!hasPack(packUnit: packUnit, unitsPerPack: unitsPerPack)) return false;
    final sell = sellUnit?.trim().toLowerCase();
    final pack = packUnit!.trim().toLowerCase();
    if (sell == null || sell.isEmpty) return false;
    if (sell == pack) return true;
    final base = baseUnit?.trim().toLowerCase();
    return sell != base && sell == pack;
  }

  /// Convert a UI quantity in [sellUnit] into base-unit quantity for stock.
  static double displayToBaseQty({
    required double displayQty,
    required String? sellUnit,
    required String? baseUnit,
    String? packUnit,
    int? unitsPerPack,
  }) {
    final sell = sellUnit?.trim().toLowerCase();
    final base = baseUnit?.trim().toLowerCase();

    // Mass / volume sub-units (existing behaviour).
    if (sell == 'gm' && base == 'kg') return displayQty / 1000;
    if (sell == 'ml' && base == 'ltr') return displayQty / 1000;

    if (isSellingAsPack(
      sellUnit: sellUnit,
      baseUnit: baseUnit,
      packUnit: packUnit,
      unitsPerPack: unitsPerPack,
    )) {
      return displayQty * normalizeUnitsPerPack(unitsPerPack);
    }
    return displayQty;
  }

  /// Convert base qty to UI display qty for [sellUnit].
  static double baseToDisplayQty({
    required double baseQty,
    required String? sellUnit,
    required String? baseUnit,
    String? packUnit,
    int? unitsPerPack,
  }) {
    final sell = sellUnit?.trim().toLowerCase();
    final base = baseUnit?.trim().toLowerCase();

    if (sell == 'gm' && base == 'kg') return baseQty * 1000;
    if (sell == 'ml' && base == 'ltr') return baseQty * 1000;

    if (isSellingAsPack(
      sellUnit: sellUnit,
      baseUnit: baseUnit,
      packUnit: packUnit,
      unitsPerPack: unitsPerPack,
    )) {
      return toPackQuantity(baseQty, normalizeUnitsPerPack(unitsPerPack));
    }
    return baseQty;
  }

  /// Max sellable in display unit from base stock.
  static double maxStockInDisplayUnit({
    required num baseStock,
    required String? sellUnit,
    required String? baseUnit,
    String? packUnit,
    int? unitsPerPack,
  }) {
    return baseToDisplayQty(
      baseQty: baseStock.toDouble(),
      sellUnit: sellUnit,
      baseUnit: baseUnit,
      packUnit: packUnit,
      unitsPerPack: unitsPerPack,
    );
  }

  /// Effective **per-base** sell price for bill lines / FIFO revenue.
  /// Pack sale uses [packSalesPrice] ÷ unitsPerPack (not base×N), so strip
  /// and tablet can have independent list prices.
  static double sellPricePerBaseUnit({
    required double baseSalesPrice,
    double? packSalesPrice,
    required bool sellingAsPack,
    int? unitsPerPack,
  }) {
    final n = normalizeUnitsPerPack(unitsPerPack);
    if (sellingAsPack && packSalesPrice != null && packSalesPrice > 0 && n > 1) {
      return packSalesPrice / n;
    }
    return baseSalesPrice;
  }

  /// Price shown in UI for the selected sell unit (pack or base).
  static double displaySellPrice({
    required double baseSalesPrice,
    double? packSalesPrice,
    required bool sellingAsPack,
    int? unitsPerPack,
  }) {
    if (sellingAsPack) {
      final n = normalizeUnitsPerPack(unitsPerPack);
      if (packSalesPrice != null && packSalesPrice > 0) return packSalesPrice;
      return toPackUnitPrice(baseSalesPrice, n);
    }
    return baseSalesPrice;
  }

  /// Suggested stock unit when buying a pack (Bag→Kg, Strip→Tablet).
  static String? suggestedBaseUnitForPack(String? packUnit) {
    switch ((packUnit ?? '').trim().toLowerCase()) {
      case 'bag':
        return 'Kg';
      case 'strip':
        return 'Tablet';
      case 'box':
        return 'Pcs';
      default:
        return null;
    }
  }

  /// Example content for one pack, e.g. "50 Kg" or "10 Tablet".
  static String unitsPerPackExample({
    required String? packUnit,
    required String? baseUnit,
  }) {
    final pack = (packUnit ?? 'pack').trim();
    final base = (baseUnit ?? suggestedBaseUnitForPack(pack) ?? 'unit').trim();
    if (pack.toLowerCase() == 'bag') return 'e.g. 50 $base';
    if (pack.toLowerCase() == 'strip') return 'e.g. 10 $base';
    return 'e.g. 10 $base';
  }

  /// Invoice / ledger total when buying packs at a **per-base** rate.
  /// Example: 2 Bag × 50 Kg × ₹40/Kg = ₹4000.
  static double packPurchaseTotal({
    required num packQty,
    required int unitsPerPack,
    required num pricePerBaseUnit,
  }) {
    return toBaseQuantity(packQty, unitsPerPack) * pricePerBaseUnit.toDouble();
  }

  /// Human-readable stock: "150 Tablet (15 Strip)".
  static String formatStockLabel({
    required num baseStock,
    String? baseUnit,
    String? packUnit,
    int? unitsPerPack,
  }) {
    final baseLabel = (baseUnit != null && baseUnit.trim().isNotEmpty)
        ? baseUnit.trim()
        : 'pcs';
    final stock = baseStock.toDouble();
    final stockText = stock == stock.roundToDouble()
        ? stock.toInt().toString()
        : stock.toStringAsFixed(2);
    if (!hasPack(packUnit: packUnit, unitsPerPack: unitsPerPack)) {
      return '$stockText $baseLabel';
    }
    final n = normalizeUnitsPerPack(unitsPerPack);
    final packs = (stock / n).floor();
    final loose = stock - (packs * n);
    final packLabel = packUnit!.trim();
    if (loose.abs() < 1e-9) {
      return '$stockText $baseLabel ($packs $packLabel)';
    }
    final looseText = loose == loose.roundToDouble()
        ? loose.toInt().toString()
        : loose.toStringAsFixed(2);
    return '$stockText $baseLabel ($packs $packLabel + $looseText)';
  }
}

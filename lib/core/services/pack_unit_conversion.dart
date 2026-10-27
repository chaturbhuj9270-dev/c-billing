/// Pack ↔ base unit conversion for bulk buy / loose sell
/// (e.g. Strip→Tablet, Bag→Kg, Box→Pcs).
///
/// Inventory, FIFO batches, and stock ledgers always use **base units**.
/// Pack qty is a UI / purchase-entry convenience only.
class PackUnitConversion {
  PackUnitConversion._();

  static const int defaultUnitsPerPack = 1;

  /// True when the product can be bought/sold as a pack.
  static bool hasPack({String? packUnit, int? unitsPerPack}) {
    final n = unitsPerPack ?? defaultUnitsPerPack;
    return n > 1 && packUnit != null && packUnit.trim().isNotEmpty;
  }

  static int normalizeUnitsPerPack(int? unitsPerPack) {
    final n = unitsPerPack ?? defaultUnitsPerPack;
    return n < 1 ? defaultUnitsPerPack : n;
  }

  /// Packs → base units (stock scale).
  static int toBaseQuantity(num packOrBaseQty, int unitsPerPack) {
    final n = normalizeUnitsPerPack(unitsPerPack);
    if (n <= 1) return packOrBaseQty.round();
    return (packOrBaseQty * n).round();
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
    required int baseStock,
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

  /// Human-readable stock: "150 Tablet (15 Strip)".
  static String formatStockLabel({
    required int baseStock,
    String? baseUnit,
    String? packUnit,
    int? unitsPerPack,
  }) {
    final baseLabel = (baseUnit != null && baseUnit.trim().isNotEmpty)
        ? baseUnit.trim()
        : 'pcs';
    if (!hasPack(packUnit: packUnit, unitsPerPack: unitsPerPack)) {
      return '$baseStock $baseLabel';
    }
    final n = normalizeUnitsPerPack(unitsPerPack);
    final packs = baseStock ~/ n;
    final loose = baseStock % n;
    final packLabel = packUnit!.trim();
    if (loose == 0) {
      return '$baseStock $baseLabel ($packs $packLabel)';
    }
    return '$baseStock $baseLabel ($packs $packLabel + $loose)';
  }
}

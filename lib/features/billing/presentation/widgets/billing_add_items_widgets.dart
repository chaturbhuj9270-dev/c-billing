import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/ui/glassy_toast.dart';
import '../../domain/entities/bill_item.dart';
import '../../../inventory_management/domain/entities/product.dart';
import '../../../inventory_management/offline/entities/purchase_batch_entity.dart';

/// Bottom sheet widget for adding multiple items to the bill
/// Step 1: Shows products grouped by name with total stock
/// Step 2: When tapping a product, shows batch selection for specific stock entry
class AddItemsBottomSheet extends StatefulWidget {
  final List<Product> products;
  final List<Product>
  allProducts; // All products including zero-stock (for code lookup)
  final List<BillItem> billItems;
  final List<PurchaseBatchEntity> availableBatches;
  final Function(
    String productId,
    String productName,
    String companyName,
    int? batchLocalId,
    double sellingPrice,
    double purchasePrice,
    double quantity, // Changed to double to support decimal quantities
    int maxStock,
    double cgstPercent,
    double sgstPercent,
    String? hsnCode,
    String? unit, // Base unit (kg, ltr, pcs)
    String? sellUnit, // Unit used for sale (kg, gm, ltr, ml, pcs)
  )
  onBatchItemAdded;
  final Function(String uniqueKey) onItemRemoved;
  final Function(String message, {bool isError}) showSnackbar;
  final AppLocalizations localizations;

  const AddItemsBottomSheet({
    required this.products,
    required this.allProducts,
    required this.billItems,
    required this.availableBatches,
    required this.onBatchItemAdded,
    required this.onItemRemoved,
    required this.showSnackbar,
    required this.localizations,
  });

  @override
  State<AddItemsBottomSheet> createState() => AddItemsBottomSheetState();
}

class AddItemsBottomSheetState extends State<AddItemsBottomSheet> {
  late List<GroupedBillingProduct> _allGroupedProducts;
  late List<GroupedBillingProduct> _filteredGroups;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _buildGroupedProducts();
  }

  /// Build grouped products: group by product name (lowercase), aggregate all batches
  void _buildGroupedProducts() {
    final Map<String, GroupedBillingProduct> groups = {};
    final productIdsWithBatches = <String>{};

    // Group batches by product name (normalized)
    for (final batch in widget.availableBatches) {
      if (batch.quantityRemaining <= 0) continue;
      productIdsWithBatches.add(batch.productId);

      final normalizedName = batch.productName.trim().toLowerCase();
      if (groups.containsKey(normalizedName)) {
        groups[normalizedName]!.batches.add(batch);
      } else {
        // Find matching product for indexNo (search all products including zero-stock)
        final product = widget.allProducts.cast<Product?>().firstWhere(
          (p) => p!.id == batch.productId,
          orElse: () => null,
        );
        groups[normalizedName] = GroupedBillingProduct(
          productName: batch.productName.trim(),
          indexNo: product?.indexNo ?? 0,
          category: product?.category ?? batch.category,
          batches: [batch],
          cgstPercent: product?.cgstPercent ?? 0.0,
          sgstPercent: product?.sgstPercent ?? 0.0,
          hsnCode: product?.hsnCode,
          unit: batch.unit.isNotEmpty ? batch.unit : product?.unit,
        );
      }
    }

    // Add products that have no batch entries (fallback to product-level data)
    for (final product in widget.products) {
      if (!productIdsWithBatches.contains(product.id) &&
          product.currentStock > 0) {
        final normalizedName = product.name.trim().toLowerCase();
        if (!groups.containsKey(normalizedName)) {
          groups[normalizedName] = GroupedBillingProduct(
            productName: product.name.trim(),
            indexNo: product.indexNo,
            category: product.category,
            batches: [],
            fallbackProduct: product,
            cgstPercent: product.cgstPercent,
            sgstPercent: product.sgstPercent,
            hsnCode: product.hsnCode,
            unit: product.unit,
          );
        }
      }
    }

    final items = groups.values.toList()
      ..sort(
        (a, b) =>
            a.productName.toLowerCase().compareTo(b.productName.toLowerCase()),
      );

    _allGroupedProducts = items;
    _filteredGroups = items;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterProducts(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredGroups = _allGroupedProducts;
      } else {
        final lowerQuery = query.toLowerCase();
        final indexNo = int.tryParse(query);
        _filteredGroups = _allGroupedProducts
            .where(
              (item) =>
                  item.productName.toLowerCase().contains(lowerQuery) ||
                  item.category.toLowerCase().contains(lowerQuery) ||
                  item.allCompanyNames.any(
                    (c) => c.toLowerCase().contains(lowerQuery),
                  ) ||
                  (indexNo != null && item.indexNo == indexNo),
            )
            .toList();
      }
    });
  }

  /// Count total items added to bill
  int get _totalItems {
    double count = 0;
    for (final item in widget.billItems) {
      count += item.quantity;
    }
    return count.round();
  }

  /// Check if any batch from this product group is already in the bill
  int _getGroupQuantityInBill(GroupedBillingProduct group) {
    int total = 0;
    for (final billItem in widget.billItems) {
      // Check if bill item belongs to this product group
      for (final batch in group.batches) {
        final uniqueKey = '${batch.productId}_batch_${batch.id}';
        if (billItem.productId == uniqueKey) {
          total += billItem.quantityInt;
        }
      }
      // Also check fallback product
      if (group.fallbackProduct != null &&
          billItem.productId == group.fallbackProduct!.id) {
        total += billItem.quantityInt;
      }
    }
    return total;
  }

  /// Show dialog to adjust quantity or remove a product
  /// Supports unit selection for kg/ltr products (can sell in gm/ml)
  void _showProductQuantityDialog({
    required String productId,
    required String productName,
    required String companyName,
    required int? batchLocalId,
    required double sellingPrice,
    required double purchasePrice,
    required double currentQty,
    required int maxStock,
    required double cgstPercent,
    required double sgstPercent,
    required String? hsnCode,
    String? unit,
    String? currentSellUnit,
  }) {
    // Determine if this product supports sub-unit selling
    final lowerUnit = unit?.toLowerCase();
    final supportsSubUnit = lowerUnit == 'kg' || lowerUnit == 'ltr';
    final subUnit = lowerUnit == 'kg'
        ? 'gm'
        : (lowerUnit == 'ltr' ? 'ml' : null);

    // Initialize sell unit (default to base unit)
    String selectedSellUnit = currentSellUnit ?? unit ?? 'pcs';

    // Convert current quantity to display value based on sell unit
    double displayQty = currentQty;
    if (selectedSellUnit == 'gm' && lowerUnit == 'kg') {
      displayQty = currentQty * 1000;
    } else if (selectedSellUnit == 'ml' && lowerUnit == 'ltr') {
      displayQty = currentQty * 1000;
    }

    final qtyController = TextEditingController(
      text: displayQty == displayQty.roundToDouble()
          ? displayQty.toInt().toString()
          : displayQty.toStringAsFixed(2),
    );
    String? errorText;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          // Get max stock in current display unit
          double getMaxStockInDisplayUnit() {
            if (selectedSellUnit == 'gm' && lowerUnit == 'kg') {
              return maxStock * 1000.0;
            } else if (selectedSellUnit == 'ml' && lowerUnit == 'ltr') {
              return maxStock * 1000.0;
            }
            return maxStock.toDouble();
          }

          // Validate quantity based on selected unit
          void validateQty() {
            final qty = double.tryParse(qtyController.text) ?? 0;
            final maxInDisplayUnit = getMaxStockInDisplayUnit();
            setDialogState(() {
              if (qty < 0) {
                errorText = widget.localizations.pleaseEnterValidNumber;
              } else if (qty > maxInDisplayUnit) {
                errorText =
                    '${widget.localizations.maxStock}: ${maxInDisplayUnit.toStringAsFixed(maxInDisplayUnit == maxInDisplayUnit.roundToDouble() ? 0 : 1)} $selectedSellUnit';
              } else {
                errorText = null;
              }
            });
          }

          // Convert display quantity to base unit quantity
          double getBaseUnitQuantity() {
            final displayQty = double.tryParse(qtyController.text) ?? 0;
            if (selectedSellUnit == 'gm' && lowerUnit == 'kg') {
              return displayQty / 1000;
            } else if (selectedSellUnit == 'ml' && lowerUnit == 'ltr') {
              return displayQty / 1000;
            }
            return displayQty;
          }

          // Handle unit toggle
          void toggleUnit(String newUnit) {
            final currentDisplayQty = double.tryParse(qtyController.text) ?? 0;
            double newDisplayQty;

            if (selectedSellUnit == newUnit) return; // No change

            // Convert between units
            if (newUnit == 'gm' && selectedSellUnit == 'kg') {
              newDisplayQty = currentDisplayQty * 1000;
            } else if (newUnit == 'kg' && selectedSellUnit == 'gm') {
              newDisplayQty = currentDisplayQty / 1000;
            } else if (newUnit == 'ml' && selectedSellUnit == 'ltr') {
              newDisplayQty = currentDisplayQty * 1000;
            } else if (newUnit == 'ltr' && selectedSellUnit == 'ml') {
              newDisplayQty = currentDisplayQty / 1000;
            } else {
              newDisplayQty = currentDisplayQty;
            }

            setDialogState(() {
              selectedSellUnit = newUnit;
              qtyController.text =
                  newDisplayQty == newDisplayQty.roundToDouble()
                  ? newDisplayQty.toInt().toString()
                  : newDisplayQty.toStringAsFixed(2);
            });
            validateQty();
          }

          return AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1B4D3E).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.edit,
                    color: Color(0xFF1B4D3E),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        productName,
                        style: const TextStyle(
                          fontFamily: 'Literata',
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1A1A2E),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (companyName.isNotEmpty)
                        Text(
                          companyName,
                          style: TextStyle(
                            fontFamily: 'Literata',
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Price info
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Price: ₹${sellingPrice.toStringAsFixed(0)}${unit != null ? '/$unit' : ''}',
                        style: const TextStyle(
                          fontFamily: 'Literata',
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1B4D3E),
                        ),
                      ),
                      Text(
                        '${widget.localizations.stock}: $maxStock ${unit ?? ''}',
                        style: TextStyle(
                          fontFamily: 'Literata',
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                // Unit toggle for kg/ltr products
                if (supportsSubUnit && subUnit != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => toggleUnit(unit ?? 'pcs'),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: selectedSellUnit == unit
                                    ? const Color(0xFF1B4D3E)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Center(
                                child: Text(
                                  (unit ?? 'PCS').toUpperCase(),
                                  style: TextStyle(
                                    fontFamily: 'Literata',
                                    fontWeight: FontWeight.w600,
                                    color: selectedSellUnit == unit
                                        ? Colors.white
                                        : Colors.grey[600],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => toggleUnit(subUnit),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: selectedSellUnit == subUnit
                                    ? const Color(0xFF1B4D3E)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Center(
                                child: Text(
                                  subUnit.toUpperCase(),
                                  style: TextStyle(
                                    fontFamily: 'Literata',
                                    fontWeight: FontWeight.w600,
                                    color: selectedSellUnit == subUnit
                                        ? Colors.white
                                        : Colors.grey[600],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                // Quantity input with +/- buttons
                Row(
                  children: [
                    // Minus button
                    IconButton(
                      onPressed: () {
                        final current =
                            double.tryParse(qtyController.text) ?? 0;
                        // Decrement by 1 for base unit, 100 for sub-unit
                        final step =
                            (selectedSellUnit == 'gm' ||
                                selectedSellUnit == 'ml')
                            ? 100.0
                            : 1.0;
                        if (current > 0) {
                          final newVal = (current - step).clamp(
                            0.0,
                            getMaxStockInDisplayUnit(),
                          );
                          qtyController.text = newVal == newVal.roundToDouble()
                              ? newVal.toInt().toString()
                              : newVal.toStringAsFixed(2);
                          validateQty();
                        }
                      },
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.red[50],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.remove,
                          color: Colors.red[700],
                          size: 20,
                        ),
                      ),
                    ),
                    // Quantity field
                    Expanded(
                      child: TextField(
                        controller: qtyController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        textAlign: TextAlign.center,
                        onChanged: (_) => validateQty(),
                        style: const TextStyle(
                          fontFamily: 'Literata',
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                        decoration: InputDecoration(
                          suffixText: selectedSellUnit,
                          errorText: errorText,
                          errorStyle: const TextStyle(fontSize: 11),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFF1B4D3E),
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Plus button
                    IconButton(
                      onPressed: () {
                        final current =
                            double.tryParse(qtyController.text) ?? 0;
                        final maxInDisplayUnit = getMaxStockInDisplayUnit();
                        // Increment by 1 for base unit, 100 for sub-unit
                        final step =
                            (selectedSellUnit == 'gm' ||
                                selectedSellUnit == 'ml')
                            ? 100.0
                            : 1.0;
                        if (current < maxInDisplayUnit) {
                          final newVal = (current + step).clamp(
                            0.0,
                            maxInDisplayUnit,
                          );
                          qtyController.text = newVal == newVal.roundToDouble()
                              ? newVal.toInt().toString()
                              : newVal.toStringAsFixed(2);
                          validateQty();
                        }
                      },
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.green[50],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.add,
                          color: Colors.green[700],
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              // Remove button
              TextButton.icon(
                onPressed: () {
                  final uniqueKey = batchLocalId != null
                      ? '${productId}_batch_$batchLocalId'
                      : productId;
                  widget.onItemRemoved(uniqueKey);
                  setState(() {});
                  Navigator.pop(ctx);
                  widget.showSnackbar(
                    '$productName ${widget.localizations.delete}d',
                    isError: false,
                  );
                },
                icon: Icon(
                  Icons.delete_outline,
                  color: Colors.red[700],
                  size: 20,
                ),
                label: Text(
                  widget.localizations.delete,
                  style: TextStyle(
                    fontFamily: 'Literata',
                    color: Colors.red[700],
                  ),
                ),
              ),
              const Spacer(),
              // Cancel button
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(
                  widget.localizations.cancel,
                  style: TextStyle(
                    fontFamily: 'Literata',
                    color: Colors.grey[600],
                  ),
                ),
              ),
              // Update button
              ElevatedButton(
                onPressed: errorText == null
                    ? () {
                        final baseQty = getBaseUnitQuantity();
                        if (baseQty <= 0.001) {
                          // Remove item (very small or zero quantity)
                          final uniqueKey = batchLocalId != null
                              ? '${productId}_batch_$batchLocalId'
                              : productId;
                          widget.onItemRemoved(uniqueKey);
                          setState(() {});
                          Navigator.pop(ctx);
                          widget.showSnackbar(
                            '$productName ${widget.localizations.delete}d',
                            isError: false,
                          );
                        } else {
                          // Update quantity with unit info
                          widget.onBatchItemAdded(
                            productId,
                            productName,
                            companyName,
                            batchLocalId,
                            sellingPrice,
                            purchasePrice,
                            baseQty,
                            maxStock,
                            cgstPercent,
                            sgstPercent,
                            hsnCode,
                            unit,
                            selectedSellUnit,
                          );
                          setState(() {});
                          Navigator.pop(ctx);
                          widget.showSnackbar(
                            '$productName ${widget.localizations.update}d',
                            isError: false,
                          );
                        }
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1B4D3E),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  widget.localizations.update,
                  style: const TextStyle(
                    fontFamily: 'Literata',
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showBatchSelection(GroupedBillingProduct group) {
    // Fallback product with no batches — toggle add/remove
    if (group.batches.isEmpty && group.fallbackProduct != null) {
      final product = group.fallbackProduct!;
      final existingItem = widget.billItems.cast<BillItem?>().firstWhere(
        (item) => item!.productId == product.id,
        orElse: () => null,
      );
      final existingQty = existingItem?.quantity ?? 0.0;
      final existingSellUnit = existingItem?.sellUnit;

      // If already in bill, show quantity adjustment dialog
      if (existingQty > 0) {
        _showProductQuantityDialog(
          productId: product.id,
          productName: product.name,
          companyName: product.companyName,
          batchLocalId: null,
          sellingPrice: product.salesPrice,
          purchasePrice: product.purchasePrice,
          currentQty: existingQty,
          maxStock: product.currentStock,
          cgstPercent: group.cgstPercent,
          sgstPercent: group.sgstPercent,
          hsnCode: group.hsnCode,
          unit: group.unit,
          currentSellUnit: existingSellUnit,
        );
        return;
      }

      // Check if product supports sub-unit (kg->gm, ltr->ml)
      final lowerUnit = group.unit?.toLowerCase();
      final supportsSubUnit = lowerUnit == 'kg' || lowerUnit == 'ltr';

      // For kg/ltr products, show quantity dialog to allow unit selection
      if (supportsSubUnit && product.currentStock > 0) {
        _showProductQuantityDialog(
          productId: product.id,
          productName: product.name,
          companyName: product.companyName,
          batchLocalId: null,
          sellingPrice: product.salesPrice,
          purchasePrice: product.purchasePrice,
          currentQty: 0, // New item, start from 0
          maxStock: product.currentStock,
          cgstPercent: group.cgstPercent,
          sgstPercent: group.sgstPercent,
          hsnCode: group.hsnCode,
          unit: group.unit,
          currentSellUnit: null,
        );
        return;
      }

      // Not in bill — add with quantity 1 (for non kg/ltr products)
      if (existingQty < product.currentStock) {
        widget.onBatchItemAdded(
          product.id,
          product.name,
          product.companyName,
          null,
          product.salesPrice,
          product.purchasePrice,
          1.0,
          product.currentStock,
          group.cgstPercent,
          group.sgstPercent,
          group.hsnCode,
          group.unit,
          group.unit, // Default sellUnit same as base unit
        );
        setState(() {});
        widget.showSnackbar(
          '${widget.localizations.added}: ${product.name}',
          isError: false,
        );
      } else {
        widget.showSnackbar(
          '${widget.localizations.maxStock}: ${product.currentStock}',
          isError: true,
        );
      }
      return;
    }

    // Has batches (1 or more) — always show batch selection bottom sheet
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => BatchSelectionSheet(
        productName: group.productName,
        productCode: group.indexNo,
        batches: group.batches,
        localizations: widget.localizations,
        existingBillItems: widget.billItems,
        cgstPercent: group.cgstPercent,
        sgstPercent: group.sgstPercent,
        hsnCode: group.hsnCode,
        unit: group.unit,
        onBatchSelected: (batch, quantity, sellUnit) {
          widget.onBatchItemAdded(
            batch.productId,
            batch.productName,
            batch.companyName,
            batch.id,
            batch.sellingPrice,
            batch.purchasePrice,
            quantity,
            batch.quantityRemaining,
            group.cgstPercent,
            group.sgstPercent,
            group.hsnCode,
            group.unit,
            sellUnit,
          );
          setState(() {});
          Navigator.pop(ctx);
          widget.showSnackbar(
            '${widget.localizations.added}: ${batch.productName}',
            isError: false,
          );
        },
        onItemRemoved: (uniqueKey) {
          widget.onItemRemoved(uniqueKey);
          setState(() {});
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (_, controller) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Handle bar
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1B4D3E).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.add_shopping_cart,
                      color: Color(0xFF1B4D3E),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.localizations.addItems,
                          style: const TextStyle(
                            fontFamily: 'Literata',
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1B4D3E),
                          ),
                        ),
                        Text(
                          widget.localizations.tapToAddItems,
                          style: const TextStyle(
                            fontFamily: 'Literata',
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_totalItems > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1B4D3E),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '$_totalItems ${widget.localizations.items.toLowerCase()}',
                        style: const TextStyle(
                          fontFamily: 'Literata',
                          fontSize: 13,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // Search bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                controller: _searchController,
                onChanged: _filterProducts,
                style: const TextStyle(fontFamily: 'Literata', fontSize: 14),
                decoration: InputDecoration(
                  hintText: widget.localizations.searchProducts,
                  hintStyle: TextStyle(color: Colors.grey[500]),
                  prefixIcon: const Icon(
                    Icons.search,
                    color: Color(0xFF1B4D3E),
                  ),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 20),
                          onPressed: () {
                            _searchController.clear();
                            _filterProducts('');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: const Color(0xFFF5F5F5),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Grouped products list (Step 1)
            Expanded(
              child: _filteredGroups.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.inventory_2_outlined,
                            size: 48,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            widget.localizations.noProductsFound,
                            style: TextStyle(
                              fontFamily: 'Literata',
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      controller: controller,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _filteredGroups.length,
                      itemBuilder: (context, index) {
                        final group = _filteredGroups[index];
                        final qtyInBill = _getGroupQuantityInBill(group);
                        final isAdded = qtyInBill > 0;
                        final hasMultipleBatches = group.batches.length > 1;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: isAdded
                                ? const Color(0xFFE8F5E9)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isAdded
                                  ? const Color(0xFF1B4D3E)
                                  : Colors.grey[200]!,
                              width: isAdded ? 1.5 : 1,
                            ),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () => _showBatchSelection(group),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Row(
                                  children: [
                                    // Product index number badge
                                    Container(
                                      width: 44,
                                      height: 44,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF1B4D3E),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Center(
                                        child: Text(
                                          group.indexNo > 0
                                              ? '${group.indexNo}'
                                              : '#',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 14,
                                            fontFamily: 'Literata',
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    // Product details
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            group.productName,
                                            style: const TextStyle(
                                              fontFamily: 'Literata',
                                              fontWeight: FontWeight.w600,
                                              fontSize: 14,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 3),
                                          // Company names (show unique companies)
                                          if (group
                                              .allCompanyNames
                                              .isNotEmpty) ...[
                                            Text(
                                              group.allCompanyNames.join(', '),
                                              style: TextStyle(
                                                fontFamily: 'Literata',
                                                fontSize: 11,
                                                color: Colors.grey[600],
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 3),
                                          ],
                                          Row(
                                            children: [
                                              // Price range
                                              Text(
                                                group.priceRangeDisplay,
                                                style: const TextStyle(
                                                  fontFamily: 'Literata',
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 13,
                                                  color: Color(0xFF1B4D3E),
                                                ),
                                              ),
                                              // Variant count badge
                                              if (hasMultipleBatches) ...[
                                                const SizedBox(width: 6),
                                                Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 6,
                                                        vertical: 2,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color: Colors.blue
                                                        .withValues(alpha: 0.1),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          4,
                                                        ),
                                                  ),
                                                  child: Text(
                                                    '${group.batches.length} ${widget.localizations.variants}',
                                                    style: TextStyle(
                                                      fontFamily: 'Literata',
                                                      fontSize: 9,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      color: Colors.blue[700],
                                                    ),
                                                  ),
                                                ),
                                              ],
                                              const SizedBox(width: 6),
                                              // Total stock badge
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 6,
                                                      vertical: 2,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: group.totalStock > 10
                                                      ? Colors.green[50]
                                                      : group.totalStock > 0
                                                      ? Colors.orange[50]
                                                      : Colors.red[50],
                                                  borderRadius:
                                                      BorderRadius.circular(4),
                                                ),
                                                child: Text(
                                                  '${group.totalStock} left',
                                                  style: TextStyle(
                                                    fontFamily: 'Literata',
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.w600,
                                                    color: group.totalStock > 10
                                                        ? Colors.green[700]
                                                        : group.totalStock > 0
                                                        ? Colors.orange[700]
                                                        : Colors.red[700],
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    // Action area
                                    if (isAdded)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF1B4D3E),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(
                                              Icons.check,
                                              color: Colors.white,
                                              size: 16,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              '$qtyInBill',
                                              style: const TextStyle(
                                                fontFamily: 'Literata',
                                                color: Colors.white,
                                                fontWeight: FontWeight.w700,
                                                fontSize: 13,
                                              ),
                                            ),
                                          ],
                                        ),
                                      )
                                    else
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: hasMultipleBatches
                                              ? Colors.blue[50]
                                              : const Color(
                                                  0xFF1B4D3E,
                                                ).withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Icon(
                                          hasMultipleBatches
                                              ? Icons.expand_more
                                              : Icons.add,
                                          color: hasMultipleBatches
                                              ? Colors.blue[700]
                                              : const Color(0xFF1B4D3E),
                                          size: 20,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
            // Done button
            Container(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 16,
                bottom: MediaQuery.of(context).padding.bottom + 16,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1B4D3E),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    _totalItems > 0
                        ? '${widget.localizations.done} ($_totalItems ${widget.localizations.items.toLowerCase()})'
                        : widget.localizations.done,
                    style: const TextStyle(
                      fontFamily: 'Literata',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Represents a billable item in the Add Items sheet.
/// Wraps product data with FIFO batch information.
/// Groups products by name, aggregating all batches across companies/prices.
class GroupedBillingProduct {
  final String productName;
  final int indexNo;
  final String category;
  final List<PurchaseBatchEntity>
  batches; // All batches for this product name (FIFO sorted)
  final Product? fallbackProduct; // For products without batch data
  final double cgstPercent;
  final double sgstPercent;
  final String? hsnCode;
  final String? unit; // Base unit (kg, ltr, pcs, etc.)

  GroupedBillingProduct({
    required this.productName,
    required this.indexNo,
    required this.category,
    required this.batches,
    this.fallbackProduct,
    this.cgstPercent = 0.0,
    this.sgstPercent = 0.0,
    this.hsnCode,
    this.unit,
  }) {
    // Sort batches FIFO (oldest first)
    batches.sort((a, b) => a.purchaseDate.compareTo(b.purchaseDate));
  }

  /// Check if this product supports sub-unit selling (kg -> gm, ltr -> ml)
  bool get supportsSubUnit =>
      unit?.toLowerCase() == 'kg' || unit?.toLowerCase() == 'ltr';

  /// Get the sub-unit for this product (gm for kg, ml for ltr)
  String? get subUnit {
    final lowerUnit = unit?.toLowerCase();
    if (lowerUnit == 'kg') return 'gm';
    if (lowerUnit == 'ltr') return 'ml';
    return null;
  }

  /// Total stock across all batches
  int get totalStock {
    if (batches.isNotEmpty) {
      return batches.fold<int>(0, (s, b) => s + b.quantityRemaining);
    }
    return fallbackProduct?.currentStock ?? 0;
  }

  /// All unique company names across batches
  List<String> get allCompanyNames {
    final names = <String>{};
    for (final batch in batches) {
      if (batch.companyName.isNotEmpty) {
        names.add(batch.companyName);
      }
    }
    if (names.isEmpty &&
        fallbackProduct != null &&
        fallbackProduct!.companyName.isNotEmpty) {
      names.add(fallbackProduct!.companyName);
    }
    return names.toList();
  }

  /// Price range display: single price or range
  String get priceRangeDisplay {
    if (batches.isEmpty) {
      return '₹${fallbackProduct?.salesPrice.toStringAsFixed(0) ?? '0'}';
    }
    final prices = batches.map((b) => b.sellingPrice).toSet().toList()..sort();
    if (prices.length == 1) {
      return '₹${prices.first.toStringAsFixed(0)}';
    }
    return '₹${prices.first.toStringAsFixed(0)} - ₹${prices.last.toStringAsFixed(0)}';
  }
}

/// Bottom sheet for selecting a specific batch/stock entry from a product
/// Step 2 of the billing flow: shows all available stock entries
class BatchSelectionSheet extends StatefulWidget {
  final String productName;
  final int productCode;
  final List<PurchaseBatchEntity> batches;
  final AppLocalizations localizations;
  final List<BillItem> existingBillItems;
  final Function(PurchaseBatchEntity batch, double quantity, String sellUnit)
  onBatchSelected;
  final Function(String uniqueKey) onItemRemoved;
  final double cgstPercent;
  final double sgstPercent;
  final String? hsnCode;
  final String? unit; // Base unit (kg, ltr, pcs)

  const BatchSelectionSheet({
    required this.productName,
    this.productCode = 0,
    required this.batches,
    required this.localizations,
    required this.existingBillItems,
    required this.onBatchSelected,
    required this.onItemRemoved,
    this.cgstPercent = 0.0,
    this.sgstPercent = 0.0,
    this.hsnCode,
    this.unit,
  });

  /// Check if this product supports sub-unit selling (kg -> gm, ltr -> ml)
  bool get supportsSubUnit =>
      unit?.toLowerCase() == 'kg' || unit?.toLowerCase() == 'ltr';

  /// Get the sub-unit for this product (gm for kg, ml for ltr)
  String? get subUnit {
    final lowerUnit = unit?.toLowerCase();
    if (lowerUnit == 'kg') return 'gm';
    if (lowerUnit == 'ltr') return 'ml';
    return null;
  }

  @override
  State<BatchSelectionSheet> createState() => BatchSelectionSheetState();
}

class BatchSelectionSheetState extends State<BatchSelectionSheet> {
  int? _selectedBatchIndex;
  final _qtyController = TextEditingController(text: '1');
  final _batchSearchController = TextEditingController();
  String? _qtyError;
  late List<PurchaseBatchEntity> _filteredBatches;
  late String _selectedSellUnit; // Current sell unit selection

  @override
  void initState() {
    super.initState();
    _filteredBatches = widget.batches;
    _selectedSellUnit = widget.unit ?? 'pcs'; // Default to base unit
  }

  @override
  void dispose() {
    _qtyController.dispose();
    _batchSearchController.dispose();
    super.dispose();
  }

  void _filterBatches(String query) {
    setState(() {
      _selectedBatchIndex = null;
      if (query.isEmpty) {
        _filteredBatches = widget.batches;
      } else {
        final lowerQuery = query.toLowerCase();
        _filteredBatches = widget.batches.where((batch) {
          return batch.companyName.toLowerCase().contains(lowerQuery) ||
              batch.sellingPrice.toStringAsFixed(0).contains(lowerQuery) ||
              batch.purchasePrice.toStringAsFixed(0).contains(lowerQuery) ||
              DateFormat(
                'dd MMM yyyy',
              ).format(batch.purchaseDate).toLowerCase().contains(lowerQuery) ||
              (batch.supplierName?.toLowerCase().contains(lowerQuery) ?? false);
        }).toList();
      }
    });
  }

  double _getExistingQtyForBatch(PurchaseBatchEntity batch) {
    final uniqueKey = '${batch.productId}_batch_${batch.id}';
    return widget.existingBillItems
        .where((item) => item.productId == uniqueKey)
        .fold<double>(0, (s, item) => s + item.quantity);
  }

  /// Get max stock in display unit
  double _getMaxStockInDisplayUnit(int maxStock) {
    if (_selectedSellUnit == 'gm' && widget.unit?.toLowerCase() == 'kg') {
      return maxStock * 1000.0;
    } else if (_selectedSellUnit == 'ml' &&
        widget.unit?.toLowerCase() == 'ltr') {
      return maxStock * 1000.0;
    }
    return maxStock.toDouble();
  }

  void _validateQuantity() {
    if (_selectedBatchIndex == null) return;
    final batch = _filteredBatches[_selectedBatchIndex!];
    final existingQty = _getExistingQtyForBatch(batch);
    final maxAvailable = batch.quantityRemaining - existingQty.round();
    final maxInDisplayUnit = _getMaxStockInDisplayUnit(maxAvailable);
    final qty = double.tryParse(_qtyController.text) ?? 0;

    setState(() {
      if (qty <= 0) {
        _qtyError = widget.localizations.pleaseEnterValidNumber;
      } else if (qty > maxInDisplayUnit) {
        _qtyError =
            '${widget.localizations.quantityExceedsStock} (${maxInDisplayUnit.toStringAsFixed(maxInDisplayUnit == maxInDisplayUnit.roundToDouble() ? 0 : 1)} $_selectedSellUnit)';
      } else {
        _qtyError = null;
      }
    });
  }

  /// Show dialog to adjust quantity or remove a batch item
  void _showBatchQuantityDialog({
    required PurchaseBatchEntity batch,
    required double existingQty,
  }) {
    final qtyController = TextEditingController(
      text: existingQty == existingQty.roundToDouble()
          ? existingQty.toInt().toString()
          : existingQty.toStringAsFixed(2),
    );
    final maxStock = batch.quantityRemaining;
    String? errorText;
    String localSellUnit = _selectedSellUnit;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          void validateQty() {
            final qty = double.tryParse(qtyController.text) ?? 0;
            setDialogState(() {
              if (qty < 0) {
                errorText = widget.localizations.pleaseEnterValidNumber;
              } else if (qty > maxStock) {
                errorText = '${widget.localizations.maxStock}: $maxStock';
              } else {
                errorText = null;
              }
            });
          }

          return AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1B4D3E).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.edit,
                    color: Color(0xFF1B4D3E),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        batch.productName,
                        style: const TextStyle(
                          fontFamily: 'Literata',
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1A1A2E),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (batch.companyName.isNotEmpty)
                        Text(
                          batch.companyName,
                          style: TextStyle(
                            fontFamily: 'Literata',
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Price info
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Price: ₹${batch.sellingPrice.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontFamily: 'Literata',
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1B4D3E),
                        ),
                      ),
                      Text(
                        '${widget.localizations.stock}: $maxStock',
                        style: TextStyle(
                          fontFamily: 'Literata',
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Quantity input with +/- buttons
                Row(
                  children: [
                    // Minus button
                    IconButton(
                      onPressed: () {
                        final current = int.tryParse(qtyController.text) ?? 0;
                        if (current > 0) {
                          qtyController.text = (current - 1).toString();
                          validateQty();
                        }
                      },
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.red[50],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.remove,
                          color: Colors.red[700],
                          size: 20,
                        ),
                      ),
                    ),
                    // Quantity field
                    Expanded(
                      child: TextField(
                        controller: qtyController,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        onChanged: (_) => validateQty(),
                        style: const TextStyle(
                          fontFamily: 'Literata',
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                        decoration: InputDecoration(
                          errorText: errorText,
                          errorStyle: const TextStyle(fontSize: 11),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFF1B4D3E),
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Plus button
                    IconButton(
                      onPressed: () {
                        final current = int.tryParse(qtyController.text) ?? 0;
                        if (current < maxStock) {
                          qtyController.text = (current + 1).toString();
                          validateQty();
                        }
                      },
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.green[50],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.add,
                          color: Colors.green[700],
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              // Remove button
              TextButton.icon(
                onPressed: () {
                  final uniqueKey = '${batch.productId}_batch_${batch.id}';
                  widget.onItemRemoved(uniqueKey);
                  setState(() {});
                  Navigator.pop(ctx);
                  GlassyToast.show(
                    context,
                    '${batch.productName} ${widget.localizations.delete}d',
                  );
                },
                icon: Icon(
                  Icons.delete_outline,
                  color: Colors.red[700],
                  size: 20,
                ),
                label: Text(
                  widget.localizations.delete,
                  style: TextStyle(
                    fontFamily: 'Literata',
                    color: Colors.red[700],
                  ),
                ),
              ),
              const Spacer(),
              // Cancel button
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(
                  widget.localizations.cancel,
                  style: TextStyle(
                    fontFamily: 'Literata',
                    color: Colors.grey[600],
                  ),
                ),
              ),
              // Update button
              ElevatedButton(
                onPressed: errorText == null
                    ? () {
                        final qty = double.tryParse(qtyController.text) ?? 0;
                        if (qty <= 0.001) {
                          // Remove item
                          final uniqueKey =
                              '${batch.productId}_batch_${batch.id}';
                          widget.onItemRemoved(uniqueKey);
                          setState(() {});
                          Navigator.pop(ctx);
                          GlassyToast.show(
                            context,
                            '${batch.productName} ${widget.localizations.delete}d',
                          );
                        } else {
                          // Update quantity
                          widget.onBatchSelected(batch, qty, localSellUnit);
                          setState(() {});
                          Navigator.pop(ctx);
                        }
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1B4D3E),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  widget.localizations.update,
                  style: const TextStyle(
                    fontFamily: 'Literata',
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      maxChildSize: 0.9,
      minChildSize: 0.4,
      builder: (_, controller) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Handle bar
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  // Product code badge
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1B4D3E),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        widget.productCode > 0 ? '${widget.productCode}' : '#',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          fontFamily: 'Literata',
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.productName,
                          style: const TextStyle(
                            fontFamily: 'Literata',
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1B4D3E),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Row(
                          children: [
                            Text(
                              widget.localizations.chooseSpecificBatch,
                              style: const TextStyle(
                                fontFamily: 'Literata',
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                            if (widget.productCode > 0) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 1,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFF1B4D3E,
                                  ).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '#${widget.productCode}',
                                  style: const TextStyle(
                                    fontFamily: 'Literata',
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF1B4D3E),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Unit toggle for kg/ltr products
            if (widget.supportsSubUnit && widget.subUnit != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedSellUnit = widget.unit!;
                              _validateQuantity();
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: _selectedSellUnit == widget.unit
                                  ? const Color(0xFF1B4D3E)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Text(
                                (widget.unit ?? 'PCS').toUpperCase(),
                                style: TextStyle(
                                  fontFamily: 'Literata',
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                  color: _selectedSellUnit == widget.unit
                                      ? Colors.white
                                      : Colors.grey[600],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedSellUnit = widget.subUnit!;
                              _validateQuantity();
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: _selectedSellUnit == widget.subUnit
                                  ? const Color(0xFF1B4D3E)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Text(
                                widget.subUnit!.toUpperCase(),
                                style: TextStyle(
                                  fontFamily: 'Literata',
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                  color: _selectedSellUnit == widget.subUnit
                                      ? Colors.white
                                      : Colors.grey[600],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            // Search bar for batches
            if (widget.batches.length > 1)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: TextField(
                  controller: _batchSearchController,
                  onChanged: _filterBatches,
                  style: const TextStyle(fontFamily: 'Literata', fontSize: 14),
                  decoration: InputDecoration(
                    hintText: widget.localizations.searchBatches,
                    hintStyle: TextStyle(color: Colors.grey[500]),
                    prefixIcon: const Icon(
                      Icons.search,
                      color: Color(0xFF1B4D3E),
                      size: 20,
                    ),
                    suffixIcon: _batchSearchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _batchSearchController.clear();
                              _filterBatches('');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: const Color(0xFFF5F5F5),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
            // Available entries label
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Row(
                children: [
                  Text(
                    widget.localizations.availableEntries,
                    style: TextStyle(
                      fontFamily: 'Literata',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1B4D3E).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${_filteredBatches.length}',
                      style: const TextStyle(
                        fontFamily: 'Literata',
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1B4D3E),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            // Batch entries list
            Expanded(
              child: _filteredBatches.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.search_off,
                            size: 48,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            widget.localizations.noBatchesFound,
                            style: TextStyle(
                              fontFamily: 'Literata',
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      controller: controller,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _filteredBatches.length,
                      itemBuilder: (context, index) {
                        final batch = _filteredBatches[index];
                        final isSelected = _selectedBatchIndex == index;
                        // Check if this is the oldest batch (FIFO recommended)
                        final isOldest =
                            widget.batches.isNotEmpty &&
                            batch.id == widget.batches.first.id;
                        final existingQty = _getExistingQtyForBatch(batch);
                        final alreadyInBill = existingQty > 0;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFFE3F2FD)
                                : alreadyInBill
                                ? const Color(0xFFE8F5E9)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isSelected
                                  ? Colors.blue
                                  : alreadyInBill
                                  ? const Color(0xFF1B4D3E)
                                  : Colors.grey[200]!,
                              width: isSelected || alreadyInBill ? 1.5 : 1,
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: Colors.blue.withValues(
                                        alpha: 0.15,
                                      ),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(14),
                              onTap: () {
                                // If already in bill, show edit dialog
                                if (alreadyInBill) {
                                  _showBatchQuantityDialog(
                                    batch: batch,
                                    existingQty: existingQty,
                                  );
                                  return;
                                }
                                // Determine quantity to add based on selected unit
                                // For gm/ml: add 0.1 kg/ltr (100 gm/ml)
                                // For kg/ltr/pcs: add 1
                                final addQty =
                                    (_selectedSellUnit == 'gm' ||
                                        _selectedSellUnit == 'ml')
                                    ? 0.1
                                    : 1.0;
                                final maxAvailable =
                                    batch.quantityRemaining -
                                    existingQty.round();
                                if (addQty <= maxAvailable) {
                                  widget.onBatchSelected(
                                    batch,
                                    existingQty + addQty,
                                    _selectedSellUnit,
                                  );
                                } else {
                                  GlassyToast.show(
                                    context,
                                    '${widget.localizations.quantityExceedsStock} (${maxAvailable > 0 ? maxAvailable : 0} $_selectedSellUnit)',
                                    isError: true,
                                  );
                                }
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(14),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Top row: Company + badges
                                    Row(
                                      children: [
                                        // Company icon
                                        Container(
                                          width: 36,
                                          height: 36,
                                          decoration: BoxDecoration(
                                            color: const Color(
                                              0xFF1B4D3E,
                                            ).withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: Center(
                                            child: Text(
                                              batch.companyName.isNotEmpty
                                                  ? batch.companyName[0]
                                                        .toUpperCase()
                                                  : '?',
                                              style: const TextStyle(
                                                fontFamily: 'Literata',
                                                fontWeight: FontWeight.w700,
                                                fontSize: 14,
                                                color: Color(0xFF1B4D3E),
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                batch.companyName.isNotEmpty
                                                    ? batch.companyName
                                                    : '—',
                                                style: const TextStyle(
                                                  fontFamily: 'Literata',
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 14,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              Text(
                                                '${widget.localizations.purchasedOn}: ${DateFormat('dd MMM yyyy').format(batch.purchaseDate)}',
                                                style: TextStyle(
                                                  fontFamily: 'Literata',
                                                  fontSize: 11,
                                                  color: Colors.grey[600],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        // Badges
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.end,
                                          children: [
                                            if (isOldest)
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 6,
                                                      vertical: 2,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: Colors.amber[50],
                                                  borderRadius:
                                                      BorderRadius.circular(4),
                                                  border: Border.all(
                                                    color: Colors.amber[300]!,
                                                  ),
                                                ),
                                                child: Text(
                                                  widget
                                                      .localizations
                                                      .fifoRecommended,
                                                  style: TextStyle(
                                                    fontFamily: 'Literata',
                                                    fontSize: 9,
                                                    fontWeight: FontWeight.w700,
                                                    color: Colors.amber[800],
                                                  ),
                                                ),
                                              ),
                                            if (alreadyInBill) ...[
                                              const SizedBox(height: 4),
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 6,
                                                      vertical: 2,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: Colors.green[50],
                                                  borderRadius:
                                                      BorderRadius.circular(4),
                                                ),
                                                child: Text(
                                                  '✓ $existingQty in bill',
                                                  style: TextStyle(
                                                    fontFamily: 'Literata',
                                                    fontSize: 9,
                                                    fontWeight: FontWeight.w600,
                                                    color: Colors.green[700],
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    // Price row + Stock
                                    Row(
                                      children: [
                                        // Sell price
                                        _buildBatchInfoChip(
                                          label: widget.localizations.sellPrice,
                                          value:
                                              '₹${batch.sellingPrice.toStringAsFixed(0)}',
                                          color: const Color(0xFF1B4D3E),
                                        ),
                                        const SizedBox(width: 8),
                                        // Cost price
                                        _buildBatchInfoChip(
                                          label: widget.localizations.costPrice,
                                          value:
                                              '₹${batch.purchasePrice.toStringAsFixed(0)}',
                                          color: Colors.grey[700]!,
                                        ),
                                        const SizedBox(width: 8),
                                        // Stock
                                        _buildBatchInfoChip(
                                          label: widget.localizations.stock,
                                          value:
                                              '${batch.quantityRemaining} ${batch.unit}',
                                          color: batch.quantityRemaining > 10
                                              ? Colors.green[700]!
                                              : Colors.orange[700]!,
                                        ),
                                      ],
                                    ),
                                    // Quantity input + Add button (shown when selected)
                                    if (isSelected) ...[
                                      const SizedBox(height: 12),
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.blue[50],
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                        child: Column(
                                          children: [
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: TextField(
                                                    controller: _qtyController,
                                                    keyboardType:
                                                        TextInputType.number,
                                                    onChanged: (_) =>
                                                        _validateQuantity(),
                                                    style: const TextStyle(
                                                      fontFamily: 'Literata',
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                    decoration: InputDecoration(
                                                      labelText: widget
                                                          .localizations
                                                          .enterQuantity,
                                                      labelStyle: TextStyle(
                                                        fontSize: 12,
                                                        color: Colors.grey[600],
                                                      ),
                                                      errorText: _qtyError,
                                                      errorStyle:
                                                          const TextStyle(
                                                            fontSize: 10,
                                                          ),
                                                      contentPadding:
                                                          const EdgeInsets.symmetric(
                                                            horizontal: 12,
                                                            vertical: 10,
                                                          ),
                                                      border: OutlineInputBorder(
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              8,
                                                            ),
                                                        borderSide: BorderSide(
                                                          color:
                                                              Colors.grey[300]!,
                                                        ),
                                                      ),
                                                      focusedBorder:
                                                          OutlineInputBorder(
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  8,
                                                                ),
                                                            borderSide:
                                                                const BorderSide(
                                                                  color: Color(
                                                                    0xFF1B4D3E,
                                                                  ),
                                                                  width: 1.5,
                                                                ),
                                                          ),
                                                      filled: true,
                                                      fillColor: Colors.white,
                                                      suffixText:
                                                          '/ ${batch.quantityRemaining - existingQty}',
                                                      suffixStyle: TextStyle(
                                                        fontSize: 12,
                                                        color: Colors.grey[500],
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 12),
                                                ElevatedButton.icon(
                                                  onPressed:
                                                      _qtyError == null &&
                                                          _qtyController
                                                              .text
                                                              .isNotEmpty &&
                                                          (double.tryParse(
                                                                    _qtyController
                                                                        .text,
                                                                  ) ??
                                                                  0) >
                                                              0
                                                      ? () {
                                                          final qty =
                                                              double.parse(
                                                                _qtyController
                                                                    .text,
                                                              );
                                                          widget.onBatchSelected(
                                                            batch,
                                                            existingQty + qty,
                                                            _selectedSellUnit,
                                                          );
                                                        }
                                                      : null,
                                                  icon: const Icon(
                                                    Icons.add_shopping_cart,
                                                    size: 18,
                                                  ),
                                                  label: Text(
                                                    widget
                                                        .localizations
                                                        .addToBill,
                                                    style: const TextStyle(
                                                      fontFamily: 'Literata',
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      fontSize: 13,
                                                    ),
                                                  ),
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor:
                                                        const Color(0xFF1B4D3E),
                                                    foregroundColor:
                                                        Colors.white,
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 16,
                                                          vertical: 12,
                                                        ),
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            10,
                                                          ),
                                                    ),
                                                    elevation: 0,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBatchInfoChip({
    required String label,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Literata',
                fontSize: 9,
                color: Colors.grey[600],
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontFamily: 'Literata',
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

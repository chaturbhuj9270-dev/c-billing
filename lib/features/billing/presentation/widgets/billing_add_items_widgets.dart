import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/ui/glassy_toast.dart';
import '../../domain/entities/bill_item.dart';
import '../../../inventory_management/domain/entities/product.dart';
import '../../../inventory_management/offline/entities/purchase_batch_entity.dart';
import 'package:c_billing/core/theme/app_theme.dart';

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
            backgroundColor: AppColors.card(context),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.accentSoft(context, 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.edit,
                    color: AppColors.accent(context),
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
                        style: TextStyle(
                          fontFamily: 'Literata',
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryText(context),
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
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.scaffold(context),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Price: ₹${sellingPrice.toStringAsFixed(0)}${unit != null ? '/$unit' : ''}',
                        style: TextStyle(
                          fontFamily: 'Literata',
                          fontWeight: FontWeight.w600,
                          color: AppColors.accent(context),
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
                    padding: EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppColors.chipFill(context),
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
                                    ? AppTheme.mint
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
                                        ? AppTheme.onMint
                                        : AppColors.mutedText(context),
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
                                    ? AppTheme.mint
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
                                        ? AppTheme.onMint
                                        : AppColors.mutedText(context),
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
                          color: const Color(0xFFEF5350).withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.remove,
                          color: Color(0xFFEF5350),
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
                        style: TextStyle(
                          fontFamily: 'Literata',
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                        decoration: InputDecoration(
                          suffixText: selectedSellUnit,
                          errorText: errorText,
                          errorStyle: TextStyle(fontSize: 11),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: AppColors.accent(context),
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
                          color: AppTheme.mint.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.add,
                          color: AppTheme.mint,
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
                  backgroundColor: AppTheme.mint,
                  foregroundColor: AppTheme.onMint,
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
        decoration: BoxDecoration(
          color: AppColors.card(context),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Handle bar
            const SizedBox(height: 12),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.mutedText(context).withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            // Header
            Padding(
              padding: EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.isDark(context)
                          ? const Color(0xFF14352C)
                          : AppTheme.mint.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.add_shopping_cart,
                      color: AppTheme.mint,
                      size: 22,
                    ),
                  ),
                  SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.localizations.addItems,
                          style: TextStyle(
                            fontFamily: 'Literata',
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryText(context),
                          ),
                        ),
                        Text(
                          widget.localizations.tapToAddItems,
                          style: TextStyle(
                            fontFamily: 'Literata',
                            fontSize: 12,
                            color: AppColors.mutedText(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_totalItems > 0)
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.mint,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '$_totalItems ${widget.localizations.items.toLowerCase()}',
                        style: const TextStyle(
                          fontFamily: 'Literata',
                          fontSize: 13,
                          color: AppTheme.onMint,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // Search bar
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                controller: _searchController,
                onChanged: _filterProducts,
                style: TextStyle(
                  fontFamily: 'Literata',
                  fontSize: 14,
                  color: AppColors.primaryText(context),
                ),
                decoration: InputDecoration(
                  hintText: widget.localizations.searchProducts,
                  hintStyle: TextStyle(color: AppColors.mutedText(context)),
                  prefixIcon: Icon(
                    Icons.search,
                    color: AppColors.mutedText(context),
                  ),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear, size: 20),
                          onPressed: () {
                            _searchController.clear();
                            _filterProducts('');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: AppColors.scaffold(context),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  disabledBorder: OutlineInputBorder(
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
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _filteredGroups.length,
                      itemBuilder: (context, index) {
                        final group = _filteredGroups[index];
                        final qtyInBill = _getGroupQuantityInBill(group);
                        final isAdded = qtyInBill > 0;
                        final hasMultipleBatches = group.batches.length > 1;

                        return Container(
                          margin: EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: AppColors.inputFill(context),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isAdded
                                  ? AppTheme.mint
                                  : AppColors.border(context),
                              width: isAdded ? 1.5 : 1,
                            ),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () => _showBatchSelection(group),
                              child: Padding(
                                padding: EdgeInsets.all(12),
                                child: Row(
                                  children: [
                                    // Product index number badge
                                    Container(
                                      width: 44,
                                      height: 44,
                                      decoration: BoxDecoration(
                                        color: AppColors.isDark(context)
                                            ? const Color(0xFF14352C)
                                            : AppTheme.mint.withValues(
                                                alpha: 0.16,
                                              ),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Center(
                                        child: Text(
                                          group.indexNo > 0
                                              ? '${group.indexNo}'
                                              : '#',
                                          style: const TextStyle(
                                            color: AppTheme.mint,
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
                                            style: TextStyle(
                                              fontFamily: 'Literata',
                                              fontWeight: FontWeight.w600,
                                              fontSize: 14,
                                              color: AppColors.primaryText(
                                                context,
                                              ),
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
                                                color: AppColors.mutedText(
                                                  context,
                                                ),
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            SizedBox(height: 3),
                                          ],
                                          Row(
                                            children: [
                                              // Price range
                                              Text(
                                                group.priceRangeDisplay,
                                                style: TextStyle(
                                                  fontFamily: 'Literata',
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 13,
                                                  color: AppTheme.mint,
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
                                                    color: AppTheme.toneBlue
                                                        .withValues(alpha: 0.16),
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
                                                      color: AppTheme.toneBlue,
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
                                                      ? AppTheme.mint.withValues(
                                                          alpha: 0.16,
                                                        )
                                                      : group.totalStock > 0
                                                      ? AppTheme.toneAmber
                                                            .withValues(
                                                              alpha: 0.16,
                                                            )
                                                      : const Color(0xFFEF5350)
                                                            .withValues(
                                                              alpha: 0.16,
                                                            ),
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
                                                        ? AppTheme.mint
                                                        : group.totalStock > 0
                                                        ? AppTheme.toneAmber
                                                        : const Color(
                                                            0xFFEF5350,
                                                          ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    SizedBox(width: 8),
                                    // Action area
                                    if (isAdded)
                                      Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppTheme.mint,
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(
                                              Icons.check,
                                              color: AppTheme.onMint,
                                              size: 16,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              '$qtyInBill',
                                              style: const TextStyle(
                                                fontFamily: 'Literata',
                                                color: AppTheme.onMint,
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
                                              ? AppTheme.toneBlue.withValues(
                                                  alpha: 0.16,
                                                )
                                              : AppTheme.mint.withValues(
                                                  alpha: 0.16,
                                                ),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Icon(
                                          hasMultipleBatches
                                              ? Icons.expand_more
                                              : Icons.add,
                                          color: hasMultipleBatches
                                              ? AppTheme.toneBlue
                                              : AppTheme.mint,
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
                color: AppColors.card(context),
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
                    backgroundColor: AppTheme.mint,
                    foregroundColor: AppTheme.onMint,
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
                      color: AppTheme.onMint,
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
    _selectedSellUnit = widget.unit ?? 'pcs';
    if (widget.batches.isNotEmpty) {
      _selectedBatchIndex = 0;
    }
  }

  @override
  void dispose() {
    _qtyController.dispose();
    _batchSearchController.dispose();
    super.dispose();
  }

  void _filterBatches(String query) {
    setState(() {
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
      _selectedBatchIndex = _filteredBatches.isEmpty ? null : 0;
      _qtyController.text = '1';
      _qtyError = null;
    });
  }

  double _toBaseQty(double displayQty) {
    final unit = widget.unit?.toLowerCase();
    if (_selectedSellUnit == 'gm' && unit == 'kg') return displayQty / 1000;
    if (_selectedSellUnit == 'ml' && unit == 'ltr') return displayQty / 1000;
    return displayQty;
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
            backgroundColor: AppColors.card(context),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.accentSoft(context, 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.edit,
                    color: AppColors.accent(context),
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
                        style: TextStyle(
                          fontFamily: 'Literata',
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryText(context),
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
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.scaffold(context),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Price: ₹${batch.sellingPrice.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontFamily: 'Literata',
                          fontWeight: FontWeight.w600,
                          color: AppColors.accent(context),
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
                          color: const Color(0xFFEF5350).withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.remove,
                          color: Color(0xFFEF5350),
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
                        style: TextStyle(
                          fontFamily: 'Literata',
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                        decoration: InputDecoration(
                          errorText: errorText,
                          errorStyle: TextStyle(fontSize: 11),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: AppColors.accent(context),
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
                          color: AppTheme.mint.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.add,
                          color: AppTheme.mint,
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
                  backgroundColor: AppTheme.mint,
                  foregroundColor: AppTheme.onMint,
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
    final selected = _selectedBatchIndex != null &&
            _selectedBatchIndex! < _filteredBatches.length
        ? _filteredBatches[_selectedBatchIndex!]
        : null;

    return DraggableScrollableSheet(
      initialChildSize: 0.72,
      maxChildSize: 0.92,
      minChildSize: 0.45,
      builder: (_, controller) => Container(
        decoration: BoxDecoration(
          color: AppColors.isDark(context)
              ? AppTheme.darkSurface
              : AppColors.card(context),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border(top: BorderSide(color: AppColors.border(context))),
        ),
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.mutedText(context).withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  _iconWell(
                    const Icon(
                      Icons.inventory_2_outlined,
                      color: AppTheme.mint,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.productName,
                          style: TextStyle(
                            fontFamily: 'Literata',
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primaryText(context),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          widget.localizations.chooseSpecificBatch,
                          style: TextStyle(
                            fontFamily: 'Literata',
                            fontSize: 12,
                            color: AppColors.mutedText(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (widget.productCode > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.border(context)),
                      ),
                      child: Text(
                        '#${widget.productCode}',
                        style: TextStyle(
                          fontFamily: 'Literata',
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.secondaryText(context),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            if (widget.supportsSubUnit && widget.subUnit != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.chipFill(context),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      _unitChip(widget.unit!, widget.unit!),
                      _unitChip(widget.subUnit!, widget.subUnit!),
                    ],
                  ),
                ),
              ),
            if (widget.batches.length > 1)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                child: TextField(
                  controller: _batchSearchController,
                  onChanged: _filterBatches,
                  style: TextStyle(
                    fontFamily: 'Literata',
                    fontSize: 14,
                    color: AppColors.primaryText(context),
                  ),
                  decoration: InputDecoration(
                    hintText: widget.localizations.searchBatches,
                    hintStyle: TextStyle(color: AppColors.mutedText(context)),
                    prefixIcon: Icon(
                      Icons.search,
                      color: AppColors.mutedText(context),
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
                    fillColor: AppColors.inputFill(context),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: AppColors.border(context)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: AppColors.border(context)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: AppTheme.mint),
                    ),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              child: Row(
                children: [
                  Text(
                    widget.localizations.availableEntries,
                    style: TextStyle(
                      fontFamily: 'Literata',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.secondaryText(context),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 22,
                    height: 22,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      color: AppTheme.mint,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${_filteredBatches.length}',
                      style: const TextStyle(
                        fontFamily: 'Literata',
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.onMint,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: _filteredBatches.isEmpty
                  ? Center(
                      child: Text(
                        widget.localizations.noBatchesFound,
                        style: TextStyle(
                          fontFamily: 'Literata',
                          color: AppColors.mutedText(context),
                        ),
                      ),
                    )
                  : ListView.builder(
                      controller: controller,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _filteredBatches.length,
                      itemBuilder: (context, index) {
                        final batch = _filteredBatches[index];
                        final isOldest = widget.batches.isNotEmpty &&
                            batch.id == widget.batches.first.id;
                        final existingQty = _getExistingQtyForBatch(batch);
                        return _buildBatchCard(
                          batch: batch,
                          isSelected: _selectedBatchIndex == index,
                          isOldest: isOldest,
                          existingQty: existingQty,
                          onTap: () {
                            if (existingQty > 0) {
                              _showBatchQuantityDialog(
                                batch: batch,
                                existingQty: existingQty,
                              );
                              return;
                            }
                            setState(() {
                              _selectedBatchIndex = index;
                              _qtyController.text = '1';
                              _qtyError = null;
                            });
                            _validateQuantity();
                          },
                        );
                      },
                    ),
            ),
            if (selected != null)
              _buildQuantityBar(selected, _getExistingQtyForBatch(selected)),
          ],
        ),
      ),
    );
  }

  Widget _iconWell(Widget child) {
    return Container(
      width: 42,
      height: 42,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.isDark(context)
            ? const Color(0xFF14352C)
            : AppTheme.mint.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(14),
      ),
      child: child,
    );
  }

  Widget _unitChip(String unit, String value) {
    final selected = _selectedSellUnit == value;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedSellUnit = value;
            _qtyController.text = '1';
            _qtyError = null;
          });
          _validateQuantity();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? AppTheme.mint : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              unit.toUpperCase(),
              style: TextStyle(
                fontFamily: 'Literata',
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: selected
                    ? AppTheme.onMint
                    : AppColors.mutedText(context),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBatchCard({
    required PurchaseBatchEntity batch,
    required bool isSelected,
    required bool isOldest,
    required double existingQty,
    required VoidCallback onTap,
  }) {
    final initial = batch.companyName.isNotEmpty
        ? batch.companyName[0].toUpperCase()
        : '?';
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? AppTheme.mint : AppColors.border(context),
          width: isSelected ? 1.6 : 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.isDark(context)
                            ? const Color(0xFF14352C)
                            : AppTheme.mint.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        initial,
                        style: const TextStyle(
                          fontFamily: 'Literata',
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          color: AppTheme.mint,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            batch.companyName.isNotEmpty
                                ? batch.companyName
                                : '—',
                            style: TextStyle(
                              fontFamily: 'Literata',
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                              color: AppColors.primaryText(context),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            '${widget.localizations.purchasedOn} ${DateFormat('dd MMM yyyy').format(batch.purchaseDate)}',
                            style: TextStyle(
                              fontFamily: 'Literata',
                              fontSize: 12,
                              color: AppColors.mutedText(context),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isOldest)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.toneAmber.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.verified_rounded,
                              size: 14,
                              color: AppTheme.toneAmber,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'FIFO',
                              style: TextStyle(
                                fontFamily: 'Literata',
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.toneAmber,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                if (existingQty > 0) ...[
                  const SizedBox(height: 8),
                  Text(
                    '✓ $existingQty in bill',
                    style: const TextStyle(
                      fontFamily: 'Literata',
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.mint,
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildBatchInfoChip(
                      label: widget.localizations.sellPrice,
                      value: '₹${_money(batch.sellingPrice)}',
                      valueColor: AppTheme.mint,
                    ),
                    const SizedBox(width: 8),
                    _buildBatchInfoChip(
                      label: widget.localizations.costPrice,
                      value: '₹${_money(batch.purchasePrice)}',
                      valueColor: AppColors.primaryText(context),
                    ),
                    const SizedBox(width: 8),
                    _buildBatchInfoChip(
                      label: widget.localizations.inStock,
                      value: '${batch.quantityRemaining} ${batch.unit}',
                      valueColor: AppColors.primaryText(context),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuantityBar(PurchaseBatchEntity batch, double existingQty) {
    final displayQty = double.tryParse(_qtyController.text) ?? 0;
    final maxAvailable = batch.quantityRemaining - existingQty.round();
    final maxDisplay = _getMaxStockInDisplayUnit(
      maxAvailable < 0 ? 0 : maxAvailable,
    );
    final baseQty = _toBaseQty(displayQty < 0 ? 0 : displayQty);
    final lineTotal = batch.sellingPrice * baseQty;
    final canAdd = _qtyError == null && displayQty > 0;

    void changeQty(int delta) {
      final current = double.tryParse(_qtyController.text) ?? 0;
      final next = current + delta;
      if (next < 1) return;
      if (next > maxDisplay) return;
      setState(() {
        _qtyController.text = next == next.roundToDouble()
            ? next.toInt().toString()
            : next.toStringAsFixed(1);
      });
      _validateQuantity();
    }

    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        MediaQuery.paddingOf(context).bottom + 14,
      ),
      decoration: BoxDecoration(
        color: AppColors.isDark(context)
            ? AppTheme.darkSurface
            : AppColors.card(context),
        border: Border(top: BorderSide(color: AppColors.border(context))),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.localizations.quantity,
                    style: TextStyle(
                      fontFamily: 'Literata',
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: AppColors.primaryText(context),
                    ),
                  ),
                  Text(
                    'Max ${_money(maxDisplay)} $_selectedSellUnit',
                    style: TextStyle(
                      fontFamily: 'Literata',
                      fontSize: 12,
                      color: AppColors.mutedText(context),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              _stepButton(Icons.remove, () => changeQty(-1)),
              SizedBox(
                width: 56,
                child: TextField(
                  controller: _qtyController,
                  textAlign: TextAlign.center,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                  ],
                  onChanged: (_) => _validateQuantity(),
                  style: TextStyle(
                    fontFamily: 'Literata',
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primaryText(context),
                  ),
                  decoration: const InputDecoration(
                    isDense: true,
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
              _stepButton(Icons.add, () => changeQty(1)),
            ],
          ),
          if (_qtyError != null) ...[
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                _qtyError!,
                style: const TextStyle(
                  fontFamily: 'Literata',
                  fontSize: 11,
                  color: Color(0xFFEF5350),
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: canAdd
                  ? () {
                      widget.onBatchSelected(
                        batch,
                        existingQty + baseQty,
                        _selectedSellUnit,
                      );
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.mint,
                foregroundColor: AppTheme.onMint,
                disabledBackgroundColor: AppColors.chipFill(context),
                disabledForegroundColor: AppColors.mutedText(context),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                '${widget.localizations.addToBill} · ₹${_money(lineTotal)}',
                style: const TextStyle(
                  fontFamily: 'Literata',
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _money(double amount) {
    if (amount == amount.roundToDouble()) return amount.toStringAsFixed(0);
    return amount.toStringAsFixed(2);
  }

  Widget _stepButton(IconData icon, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border(context)),
          ),
          child: Icon(icon, size: 18, color: AppColors.primaryText(context)),
        ),
      ),
    );
  }

  Widget _buildBatchInfoChip({
    required String label,
    required String value,
    required Color valueColor,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.inputFill(context),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border(context)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Literata',
                fontSize: 10,
                color: AppColors.mutedText(context),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'Literata',
                fontWeight: FontWeight.w800,
                fontSize: 14,
                color: valueColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

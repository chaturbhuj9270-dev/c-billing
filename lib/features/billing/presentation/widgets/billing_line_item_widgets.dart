import 'package:flutter/material.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../inventory_management/domain/entities/product.dart';
import '../../../inventory_management/offline/entities/purchase_batch_entity.dart';
import '../../domain/entities/bill_item.dart';

/// Max available stock for a bill line (batch-aware), same logic as billing page.
int resolveBillItemMaxStock({
  required BillItem item,
  required List<Product> products,
  required List<PurchaseBatchEntity> availableBatches,
}) {
  final realProductId = item.productId.split('_batch_').first;
  Product product;
  try {
    product = products.firstWhere((p) => p.id == realProductId);
  } catch (_) {
    product = Product(
      id: realProductId,
      indexNo: 0,
      name: item.productName,
      companyName: '',
      category: '',
      purchasePrice: 0,
      salesPrice: item.sellingPrice,
      currentStock: 999,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  final parts = item.productId.split('_batch_');
  final batchLocalId = parts.length > 1 ? int.tryParse(parts.last) : null;
  if (batchLocalId != null) {
    PurchaseBatchEntity? batch;
    for (final b in availableBatches) {
      if (b.id == batchLocalId && b.quantityRemaining > 0) {
        batch = b;
        break;
      }
    }
    return batch?.quantityRemaining ?? 0;
  }

  final batchStock = availableBatches
      .where(
        (b) => b.productId == realProductId && b.quantityRemaining > 0,
      )
      .fold<int>(0, (s, b) => s + b.quantityRemaining);
  return batchStock > 0 ? batchStock : product.currentStock;
}

/// Compact bill line list with +/- qty, inline qty edit, and tappable price — same as billing.
class BillItemsLineList extends StatelessWidget {
  final List<BillItem> items;
  final List<Product> products;
  final List<PurchaseBatchEntity> availableBatches;
  final AppLocalizations localizations;
  final ValueChanged<List<BillItem>> onItemsChanged;
  final void Function(String message, {bool isError}) showSnackbar;

  const BillItemsLineList({
    super.key,
    required this.items,
    required this.products,
    required this.availableBatches,
    required this.localizations,
    required this.onItemsChanged,
    required this.showSnackbar,
  });

  void _updateItem(int index, BillItem updated) {
    final next = List<BillItem>.from(items);
    next[index] = updated;
    onItemsChanged(next);
  }

  void _removeAt(int index) {
    final next = List<BillItem>.from(items)..removeAt(index);
    onItemsChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(vertical: 6),
        itemCount: items.length,
        separatorBuilder: (_, _) => Divider(
          height: 1,
          thickness: 0.5,
          indent: 12,
          endIndent: 12,
          color: Colors.grey.withValues(alpha: 0.12),
        ),
        itemBuilder: (context, index) {
          final item = items[index];
          final maxStock = resolveBillItemMaxStock(
            item: item,
            products: products,
            availableBatches: availableBatches,
          );

          return Dismissible(
            key: Key('${item.productId}_$index'),
            direction: DismissDirection.endToStart,
            background: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 16),
              color: Colors.red[400],
              child: const Icon(
                Icons.delete_outline_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
            onDismissed: (_) => _removeAt(index),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(
                          fontFamily: 'Literata',
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          item.productName,
                          style: const TextStyle(
                            fontFamily: 'Literata',
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                            color: Color(0xFF1A1A2E),
                            height: 1.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        GestureDetector(
                          onTap: () => showEditBillItemSellPriceDialog(
                            context: context,
                            index: index,
                            item: item,
                            products: products,
                            localizations: localizations,
                            onPriceUpdated: (price) {
                              _updateItem(
                                index,
                                BillItem.create(
                                  productId: item.productId,
                                  productName: item.productName,
                                  companyName: item.companyName,
                                  sellingPrice: price,
                                  purchasePrice: item.purchasePrice,
                                  quantity: item.quantity,
                                  cgstPercent: item.cgstPercent,
                                  sgstPercent: item.sgstPercent,
                                  hsnCode: item.hsnCode,
                                  unit: item.unit,
                                  sellUnit: item.sellUnit,
                                ),
                              );
                              showSnackbar(
                                'Price updated to ₹${price.toStringAsFixed(0)}',
                              );
                            },
                          ),
                          child: Row(
                            children: [
                              Text(
                                '₹${item.sellingPrice.toStringAsFixed(0)}',
                                style: TextStyle(
                                  fontFamily: 'Literata',
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(
                                    0xFF1B4D3E,
                                  ).withValues(alpha: 0.8),
                                ),
                              ),
                              const SizedBox(width: 3),
                              Icon(
                                Icons.edit_rounded,
                                size: 10,
                                color: Colors.grey[400],
                              ),
                              if (item.cgstPercent > 0 || item.sgstPercent > 0) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                    vertical: 1,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.orange[50],
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                  child: Text(
                                    '${(item.cgstPercent + item.sgstPercent).toStringAsFixed(0)}%',
                                    style: TextStyle(
                                      fontFamily: 'Literata',
                                      fontSize: 9,
                                      color: Colors.orange[700],
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    height: 30,
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.grey.withValues(alpha: 0.15),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        GestureDetector(
                          onTap: () {
                            final step = (item.sellUnit == 'gm' ||
                                    item.sellUnit == 'ml')
                                ? 0.1
                                : 1.0;
                            if (item.quantity > step) {
                              _updateItem(
                                index,
                                BillItem.create(
                                  productId: item.productId,
                                  productName: item.productName,
                                  companyName: item.companyName,
                                  sellingPrice: item.sellingPrice,
                                  purchasePrice: item.purchasePrice,
                                  quantity: item.quantity - step,
                                  cgstPercent: item.cgstPercent,
                                  sgstPercent: item.sgstPercent,
                                  hsnCode: item.hsnCode,
                                  unit: item.unit,
                                  sellUnit: item.sellUnit,
                                ),
                              );
                            } else {
                              _removeAt(index);
                            }
                          },
                          child: Container(
                            width: 28,
                            height: 30,
                            decoration: BoxDecoration(
                              color: const Color(
                                0xFF1B4D3E,
                              ).withValues(alpha: 0.08),
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(7),
                                bottomLeft: Radius.circular(7),
                              ),
                            ),
                            child: const Icon(
                              Icons.remove,
                              size: 14,
                              color: Color(0xFF1B4D3E),
                            ),
                          ),
                        ),
                        InlineBillQuantityField(
                          item: item,
                          maxStock: maxStock,
                          onQuantityChanged: (newQty) {
                            _updateItem(
                              index,
                              BillItem.create(
                                productId: item.productId,
                                productName: item.productName,
                                companyName: item.companyName,
                                sellingPrice: item.sellingPrice,
                                purchasePrice: item.purchasePrice,
                                quantity: newQty,
                                cgstPercent: item.cgstPercent,
                                sgstPercent: item.sgstPercent,
                                hsnCode: item.hsnCode,
                                unit: item.unit,
                                sellUnit: item.sellUnit,
                              ),
                            );
                          },
                          onRemoveItem: () => _removeAt(index),
                        ),
                        GestureDetector(
                          onTap: () {
                            final step = (item.sellUnit == 'gm' ||
                                    item.sellUnit == 'ml')
                                ? 0.1
                                : 1.0;
                            if (item.quantity + step <= maxStock) {
                              _updateItem(
                                index,
                                BillItem.create(
                                  productId: item.productId,
                                  productName: item.productName,
                                  companyName: item.companyName,
                                  sellingPrice: item.sellingPrice,
                                  purchasePrice: item.purchasePrice,
                                  quantity: item.quantity + step,
                                  cgstPercent: item.cgstPercent,
                                  sgstPercent: item.sgstPercent,
                                  hsnCode: item.hsnCode,
                                  unit: item.unit,
                                  sellUnit: item.sellUnit,
                                ),
                              );
                            } else {
                              showSnackbar(
                                '${localizations.maxStock}: $maxStock',
                                isError: true,
                              );
                            }
                          },
                          child: Container(
                            width: 28,
                            height: 30,
                            decoration: BoxDecoration(
                              color: item.quantity < maxStock
                                  ? const Color(
                                      0xFF1B4D3E,
                                    ).withValues(alpha: 0.08)
                                  : Colors.grey[100],
                              borderRadius: const BorderRadius.only(
                                topRight: Radius.circular(7),
                                bottomRight: Radius.circular(7),
                              ),
                            ),
                            child: Icon(
                              Icons.add,
                              size: 14,
                              color: item.quantity < maxStock
                                  ? const Color(0xFF1B4D3E)
                                  : Colors.grey[400],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 60,
                    child: Text(
                      '₹${item.subtotal.toStringAsFixed(0)}',
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        fontFamily: 'Literata',
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: Color(0xFF1B4D3E),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

void showEditBillItemSellPriceDialog({
  required BuildContext context,
  required int index,
  required BillItem item,
  required List<Product> products,
  required AppLocalizations localizations,
  required ValueChanged<double> onPriceUpdated,
}) {
  final priceController = TextEditingController(
    text: item.sellingPrice.toStringAsFixed(2),
  );
  String? errorText;

  showDialog(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (context, setDialogState) {
        void validatePrice() {
          final price = double.tryParse(priceController.text) ?? 0;
          setDialogState(() {
            if (price <= 0) {
              errorText = localizations.pleaseEnterValidPrice;
            } else {
              errorText = null;
            }
          });
        }

        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1B4D3E), Color(0xFF2D6A4F)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF1B4D3E).withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.currency_rupee_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${localizations.edit} ${localizations.price}',
                      style: const TextStyle(
                        fontFamily: 'Literata',
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A1A2E),
                      ),
                    ),
                    Text(
                      item.productName,
                      style: TextStyle(
                        fontFamily: 'Literata',
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: Colors.grey.withValues(alpha: 0.1),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          localizations.quantity,
                          style: TextStyle(
                            fontFamily: 'Literata',
                            fontSize: 11,
                            color: Colors.grey[500],
                          ),
                        ),
                        Text(
                          item.displayQuantity,
                          style: const TextStyle(
                            fontFamily: 'Literata',
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            color: Color(0xFF1B4D3E),
                          ),
                        ),
                      ],
                    ),
                    Container(width: 1, height: 36, color: Colors.grey[200]),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          localizations.subtotal,
                          style: TextStyle(
                            fontFamily: 'Literata',
                            fontSize: 11,
                            color: Colors.grey[500],
                          ),
                        ),
                        Text(
                          '₹${((double.tryParse(priceController.text) ?? item.sellingPrice) * item.quantity).toStringAsFixed(0)}',
                          style: TextStyle(
                            fontFamily: 'Literata',
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            color: Colors.blue[700],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: priceController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                textAlign: TextAlign.center,
                autofocus: true,
                onChanged: (_) => validatePrice(),
                style: const TextStyle(
                  fontFamily: 'Literata',
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1B4D3E),
                ),
                decoration: InputDecoration(
                  prefixText: '₹ ',
                  prefixStyle: const TextStyle(
                    fontFamily: 'Literata',
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1B4D3E),
                  ),
                  errorText: errorText,
                  errorStyle: const TextStyle(fontSize: 11),
                  filled: true,
                  fillColor: Colors.grey[50],
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(
                      color: Color(0xFF1B4D3E),
                      width: 2,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: Colors.grey[200]!),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton.icon(
              onPressed: () {
                final realProductId = item.productId.split('_batch_').first;
                final product = products.firstWhere(
                  (p) => p.id == realProductId,
                  orElse: () => Product(
                    id: realProductId,
                    indexNo: 0,
                    name: item.productName,
                    companyName: '',
                    category: '',
                    purchasePrice: 0,
                    salesPrice: item.sellingPrice,
                    currentStock: 0,
                    createdAt: DateTime.now(),
                    updatedAt: DateTime.now(),
                  ),
                );
                priceController.text = product.salesPrice.toStringAsFixed(2);
                validatePrice();
              },
              icon: Icon(
                Icons.refresh_rounded,
                color: Colors.orange[700],
                size: 20,
              ),
              label: Text(
                localizations.reset,
                style: TextStyle(
                  fontFamily: 'Literata',
                  color: Colors.orange[700],
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const Spacer(),
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                localizations.cancel,
                style: TextStyle(
                  fontFamily: 'Literata',
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: errorText == null
                  ? () {
                      final price = double.tryParse(priceController.text) ?? 0;
                      if (price > 0) {
                        onPriceUpdated(price);
                        Navigator.pop(ctx);
                      }
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1B4D3E),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                elevation: 0,
              ),
              child: Text(
                localizations.update,
                style: const TextStyle(
                  fontFamily: 'Literata',
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        );
      },
    ),
  );
}

/// Inline editable quantity field for bill items (billing page parity).
class InlineBillQuantityField extends StatefulWidget {
  final BillItem item;
  final int maxStock;
  final ValueChanged<double> onQuantityChanged;
  final VoidCallback onRemoveItem;

  const InlineBillQuantityField({
    super.key,
    required this.item,
    required this.maxStock,
    required this.onQuantityChanged,
    required this.onRemoveItem,
  });

  @override
  State<InlineBillQuantityField> createState() => _InlineBillQuantityFieldState();
}

class _InlineBillQuantityFieldState extends State<InlineBillQuantityField> {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  bool _isEditing = false;
  bool _hasSubmitted = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: _getDisplayValue());
    _focusNode = FocusNode();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void didUpdateWidget(InlineBillQuantityField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_isEditing && oldWidget.item.quantity != widget.item.quantity) {
      _controller.text = _getDisplayValue();
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (_focusNode.hasFocus) {
      setState(() {
        _isEditing = true;
        _hasSubmitted = false;
      });
      _controller.selection = TextSelection(
        baseOffset: 0,
        extentOffset: _controller.text.length,
      );
    } else {
      setState(() => _isEditing = false);
      if (!_hasSubmitted) {
        _validateAndSubmit();
      }
    }
  }

  String _getDisplayValue() {
    final item = widget.item;
    double displayQty = item.quantity;

    if (item.sellUnit == 'gm' && item.unit == 'kg') {
      displayQty = item.quantity * 1000;
    } else if (item.sellUnit == 'ml' && item.unit == 'ltr') {
      displayQty = item.quantity * 1000;
    }

    if (displayQty == displayQty.roundToDouble()) {
      return displayQty.toInt().toString();
    }
    return displayQty.toStringAsFixed(2);
  }

  String _getUnitSuffix() {
    final item = widget.item;
    return item.sellUnit ?? item.unit ?? '';
  }

  double _convertToBaseUnit(double displayQty) {
    final item = widget.item;
    if (item.sellUnit == 'gm' && item.unit == 'kg') {
      return displayQty / 1000;
    } else if (item.sellUnit == 'ml' && item.unit == 'ltr') {
      return displayQty / 1000;
    }
    return displayQty;
  }

  double _getMaxStockInDisplayUnit() {
    final item = widget.item;
    if (item.sellUnit == 'gm' && item.unit == 'kg') {
      return widget.maxStock * 1000.0;
    } else if (item.sellUnit == 'ml' && item.unit == 'ltr') {
      return widget.maxStock * 1000.0;
    }
    return widget.maxStock.toDouble();
  }

  void _validateAndSubmit() {
    _hasSubmitted = true;

    final text = _controller.text.trim();
    final displayQty = double.tryParse(text);

    if (displayQty == null || displayQty <= 0) {
      _controller.text = _getDisplayValue();
      _focusNode.unfocus();
      return;
    }

    final maxDisplayStock = _getMaxStockInDisplayUnit();
    if (displayQty > maxDisplayStock) {
      final baseQty = _convertToBaseUnit(maxDisplayStock);
      widget.onQuantityChanged(baseQty);
      _focusNode.unfocus();
      return;
    }

    final baseQty = _convertToBaseUnit(displayQty);

    if (baseQty < 0.001) {
      widget.onRemoveItem();
      return;
    }

    widget.onQuantityChanged(baseQty);
    _focusNode.unfocus();
  }

  void _onTextChanged(String text) {
    final displayQty = double.tryParse(text.trim());

    if (displayQty == null || displayQty <= 0) {
      return;
    }

    final maxDisplayStock = _getMaxStockInDisplayUnit();
    final effectiveDisplayQty = displayQty > maxDisplayStock
        ? maxDisplayStock
        : displayQty;

    final baseQty = _convertToBaseUnit(effectiveDisplayQty);

    if (baseQty >= 0.001) {
      widget.onQuantityChanged(baseQty);
    }
  }

  @override
  Widget build(BuildContext context) {
    final unitSuffix = _getUnitSuffix();

    return Container(
      constraints: const BoxConstraints(minWidth: 36, maxWidth: 60),
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Flexible(
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Literata',
                fontWeight: FontWeight.w700,
                fontSize: 11,
                color: Color(0xFF1B4D3E),
              ),
              decoration: const InputDecoration(
                isDense: true,
                contentPadding: EdgeInsets.symmetric(
                  vertical: 4,
                  horizontal: 2,
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
              ),
              onChanged: _onTextChanged,
              onSubmitted: (_) => _validateAndSubmit(),
            ),
          ),
          if (unitSuffix.isNotEmpty)
            Text(
              ' $unitSuffix',
              style: const TextStyle(
                fontFamily: 'Literata',
                fontWeight: FontWeight.w600,
                fontSize: 9,
                color: Color(0xFF1B4D3E),
              ),
            ),
        ],
      ),
    );
  }
}

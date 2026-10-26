import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../inventory_management/domain/entities/product.dart';
import '../../../inventory_management/offline/entities/purchase_batch_entity.dart';
import '../../domain/entities/bill_item.dart';
import 'billing_line_item_widgets.dart';

/// Desktop bill lines — shared flex columns so header + rows stay aligned.
class BillItemsDesktopTable extends StatelessWidget {
  final List<BillItem> items;
  final List<Product> products;
  final List<PurchaseBatchEntity> availableBatches;
  final AppLocalizations localizations;
  final bool showEmployeeToken;
  final ValueChanged<List<BillItem>> onItemsChanged;
  final void Function(String productId)? onItemRemoved;
  final void Function(String message, {bool isError}) showSnackbar;

  const BillItemsDesktopTable({
    super.key,
    required this.items,
    required this.products,
    required this.availableBatches,
    required this.localizations,
    required this.onItemsChanged,
    required this.showSnackbar,
    this.showEmployeeToken = false,
    this.onItemRemoved,
  });

  // Shared flex weights — header and body use the exact same row shell.
  static const int _fHash = 1;
  static const int _fProduct = 4;
  static const int _fQty = 3;
  static const int _fPrice = 3;
  static const int _fGst = 2;
  static const int _fToken = 2;
  static const int _fAmount = 2;
  static const int _fAction = 1;

  BillItem _rebuild(
    BillItem item, {
    double? quantity,
    double? sellingPrice,
    int? employeeToken,
    bool clearEmployeeToken = false,
  }) {
    return BillItem.create(
      productId: item.productId,
      productName: item.productName,
      companyName: item.companyName,
      sellingPrice: sellingPrice ?? item.sellingPrice,
      purchasePrice: item.purchasePrice,
      quantity: quantity ?? item.quantity,
      cgstPercent: item.cgstPercent,
      sgstPercent: item.sgstPercent,
      hsnCode: item.hsnCode,
      unit: item.unit,
      sellUnit: item.sellUnit,
      employeeToken: clearEmployeeToken
          ? null
          : (employeeToken ?? item.employeeToken),
    );
  }

  void _updateAt(int index, BillItem updated) {
    final next = List<BillItem>.from(items);
    next[index] = updated;
    onItemsChanged(next);
  }

  void _removeAt(int index) {
    onItemRemoved?.call(items[index].productId);
    final next = List<BillItem>.from(items)..removeAt(index);
    onItemsChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border(context)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          _ColumnRow(
            showEmployeeToken: showEmployeeToken,
            height: 42,
            color: AppColors.chipFill(context),
            hash: _label('#', context, center: true, header: true),
            product: _label('PRODUCT', context, header: true),
            qty: _label('QTY', context, center: true, header: true),
            price: _label('PRICE', context, center: true, header: true),
            gst: _label('GST', context, center: true, header: true),
            token: showEmployeeToken
                ? _label('TOKEN', context, center: true, header: true)
                : null,
            amount: _label('AMOUNT', context, center: true, header: true),
            action: const SizedBox.shrink(),
          ),
          for (var i = 0; i < items.length; i++) ...[
            Divider(height: 1, thickness: 1, color: AppColors.border(context)),
            _buildDataRow(context, i),
          ],
        ],
      ),
    );
  }

  Widget _label(
    String text,
    BuildContext context, {
    bool center = false,
    bool header = false,
  }) {
    return Align(
      alignment: center ? Alignment.center : Alignment.centerLeft,
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontFamily: 'Literata',
          fontSize: header ? 11 : 13,
          fontWeight: FontWeight.w700,
          letterSpacing: header ? 0.3 : 0,
          color: header
              ? AppColors.mutedText(context)
              : AppColors.primaryText(context),
        ),
      ),
    );
  }

  Widget _buildDataRow(BuildContext context, int index) {
    final item = items[index];
    final maxStock = resolveBillItemMaxStock(
      item: item,
      products: products,
      availableBatches: availableBatches,
    );
    final gst = item.cgstPercent + item.sgstPercent;
    final unitLabel = item.displayUnit.isEmpty ? 'unit' : item.displayUnit;

    return _ColumnRow(
      showEmployeeToken: showEmployeeToken,
      height: 56,
      hash: Center(
        child: Text(
          '${index + 1}',
          style: TextStyle(
            fontFamily: 'Literata',
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.mutedText(context),
          ),
        ),
      ),
      product: Align(
        alignment: Alignment.centerLeft,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.productName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'Literata',
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryText(context),
              ),
            ),
            if (item.companyName != null && item.companyName!.isNotEmpty)
              Text(
                item.companyName!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Literata',
                  fontSize: 11,
                  color: AppColors.mutedText(context),
                ),
              ),
          ],
        ),
      ),
      qty: _QtyEditor(
        item: item,
        maxStock: maxStock,
        unitLabel: unitLabel,
        onChanged: (qty) {
          if (qty <= 0) {
            _removeAt(index);
            return;
          }
          if (qty > maxStock) {
            showSnackbar('${localizations.maxStock}: $maxStock', isError: true);
            return;
          }
          _updateAt(index, _rebuild(item, quantity: qty));
        },
        onStep: (delta) {
          final step =
              (item.sellUnit == 'gm' || item.sellUnit == 'ml') ? 0.1 : 1.0;
          final next = item.quantity + (delta * step);
          if (next <= 0) {
            _removeAt(index);
            return;
          }
          if (next > maxStock) {
            showSnackbar('${localizations.maxStock}: $maxStock', isError: true);
            return;
          }
          _updateAt(index, _rebuild(item, quantity: next));
        },
      ),
      price: _PriceEditor(
        item: item,
        onChanged: (price) {
          if (price <= 0) {
            showSnackbar(localizations.pleaseEnterValidPrice, isError: true);
            return;
          }
          _updateAt(index, _rebuild(item, sellingPrice: price));
        },
      ),
      gst: Center(
        child: Text(
          gst > 0 ? '${gst.toStringAsFixed(0)}%' : '—',
          style: TextStyle(
            fontFamily: 'Literata',
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: gst > 0 ? AppTheme.toneAmber : AppColors.mutedText(context),
          ),
        ),
      ),
      token: showEmployeeToken
          ? _TokenEditor(
              token: item.employeeToken,
              onChanged: (token) {
                _updateAt(
                  index,
                  _rebuild(
                    item,
                    employeeToken: token,
                    clearEmployeeToken: token == null,
                  ),
                );
              },
            )
          : null,
      amount: Center(
        child: Text(
          '₹${item.subtotal.toStringAsFixed(0)}',
          style: TextStyle(
            fontFamily: 'Literata',
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: AppColors.primaryText(context),
          ),
        ),
      ),
      action: Center(
        child: InkWell(
          onTap: () => _removeAt(index),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: Icon(
              Icons.delete_outline_rounded,
              size: 18,
              color: AppColors.mutedText(context),
            ),
          ),
        ),
      ),
    );
  }
}

/// One row shell used by header + data so columns always line up.
class _ColumnRow extends StatelessWidget {
  final bool showEmployeeToken;
  final double height;
  final Color? color;
  final Widget hash;
  final Widget product;
  final Widget qty;
  final Widget price;
  final Widget gst;
  final Widget? token;
  final Widget amount;
  final Widget action;

  const _ColumnRow({
    required this.showEmployeeToken,
    required this.height,
    required this.hash,
    required this.product,
    required this.qty,
    required this.price,
    required this.gst,
    required this.amount,
    required this.action,
    this.token,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: color ?? AppTheme.transparent,
      child: SizedBox(
        height: height,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Row(
            children: [
              Expanded(
                flex: BillItemsDesktopTable._fHash,
                child: hash,
              ),
              Expanded(
                flex: BillItemsDesktopTable._fProduct,
                child: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: product,
                ),
              ),
              Expanded(
                flex: BillItemsDesktopTable._fQty,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: qty,
                ),
              ),
              Expanded(
                flex: BillItemsDesktopTable._fPrice,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: price,
                ),
              ),
              Expanded(
                flex: BillItemsDesktopTable._fGst,
                child: gst,
              ),
              if (showEmployeeToken)
                Expanded(
                  flex: BillItemsDesktopTable._fToken,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: token ?? const SizedBox.shrink(),
                  ),
                ),
              Expanded(
                flex: BillItemsDesktopTable._fAmount,
                child: amount,
              ),
              Expanded(
                flex: BillItemsDesktopTable._fAction,
                child: action,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QtyEditor extends StatefulWidget {
  final BillItem item;
  final int maxStock;
  final String unitLabel;
  final ValueChanged<double> onChanged;
  final ValueChanged<int> onStep;

  const _QtyEditor({
    required this.item,
    required this.maxStock,
    required this.unitLabel,
    required this.onChanged,
    required this.onStep,
  });

  @override
  State<_QtyEditor> createState() => _QtyEditorState();
}

class _QtyEditorState extends State<_QtyEditor> {
  late TextEditingController _controller;
  late FocusNode _focus;
  bool _editing = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: _display());
    _focus = FocusNode()..addListener(_onFocus);
  }

  @override
  void didUpdateWidget(_QtyEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_editing && oldWidget.item.quantity != widget.item.quantity) {
      _controller.text = _display();
    }
  }

  @override
  void dispose() {
    _focus.removeListener(_onFocus);
    _focus.dispose();
    _controller.dispose();
    super.dispose();
  }

  String _display() {
    final q = widget.item.quantity;
    if (widget.item.sellUnit == 'gm' && widget.item.unit == 'kg') {
      final g = q * 1000;
      return g == g.roundToDouble()
          ? g.toInt().toString()
          : g.toStringAsFixed(1);
    }
    if (widget.item.sellUnit == 'ml' && widget.item.unit == 'ltr') {
      final m = q * 1000;
      return m == m.roundToDouble()
          ? m.toInt().toString()
          : m.toStringAsFixed(1);
    }
    return q == q.roundToDouble() ? q.toInt().toString() : q.toStringAsFixed(2);
  }

  double _toBase(double display) {
    if (widget.item.sellUnit == 'gm' && widget.item.unit == 'kg') {
      return display / 1000;
    }
    if (widget.item.sellUnit == 'ml' && widget.item.unit == 'ltr') {
      return display / 1000;
    }
    return display;
  }

  void _onFocus() {
    if (_focus.hasFocus) {
      setState(() => _editing = true);
      _controller.selection = TextSelection(
        baseOffset: 0,
        extentOffset: _controller.text.length,
      );
    } else {
      _commit();
      setState(() => _editing = false);
    }
  }

  void _commit() {
    final parsed = double.tryParse(_controller.text.trim());
    if (parsed == null || parsed <= 0) {
      _controller.text = _display();
      return;
    }
    widget.onChanged(_toBase(parsed));
    _controller.text = _display();
  }

  @override
  Widget build(BuildContext context) {
    final canAdd = widget.item.quantity < widget.maxStock;
    return Row(
      children: [
        _iconBtn(Icons.remove_rounded, () => widget.onStep(-1)),
        Expanded(
          child: SizedBox(
            height: 34,
            child: TextField(
              controller: _controller,
              focusNode: _focus,
              textAlign: TextAlign.center,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
              ],
              style: TextStyle(
                fontFamily: 'Literata',
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryText(context),
              ),
              decoration: InputDecoration(
                isDense: true,
                suffixText: widget.unitLabel,
                suffixStyle: TextStyle(
                  fontFamily: 'Literata',
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: AppColors.mutedText(context),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 4,
                  vertical: 8,
                ),
                filled: true,
                fillColor: _editing
                    ? AppColors.accentSoft(context, 0.12)
                    : AppColors.inputFill(context),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: AppColors.border(context)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: AppColors.border(context)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: AppColors.action(context)),
                ),
              ),
              onSubmitted: (_) => _commit(),
            ),
          ),
        ),
        _iconBtn(Icons.add_rounded, () => widget.onStep(1), enabled: canAdd),
      ],
    );
  }

  Widget _iconBtn(IconData icon, VoidCallback onTap, {bool enabled = true}) {
    return SizedBox(
      width: 28,
      height: 34,
      child: IconButton(
        onPressed: enabled ? onTap : null,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints.tightFor(width: 28, height: 34),
        visualDensity: VisualDensity.compact,
        icon: Icon(
          icon,
          size: 16,
          color: enabled
              ? AppColors.action(context)
              : AppColors.mutedText(context),
        ),
      ),
    );
  }
}

class _PriceEditor extends StatefulWidget {
  final BillItem item;
  final ValueChanged<double> onChanged;

  const _PriceEditor({
    required this.item,
    required this.onChanged,
  });

  @override
  State<_PriceEditor> createState() => _PriceEditorState();
}

class _PriceEditorState extends State<_PriceEditor> {
  late TextEditingController _controller;
  late FocusNode _focus;
  bool _editing = false;

  @override
  void initState() {
    super.initState();
    _controller =
        TextEditingController(text: _format(widget.item.sellingPrice));
    _focus = FocusNode()..addListener(_onFocus);
  }

  @override
  void didUpdateWidget(_PriceEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_editing &&
        oldWidget.item.sellingPrice != widget.item.sellingPrice) {
      _controller.text = _format(widget.item.sellingPrice);
    }
  }

  @override
  void dispose() {
    _focus.removeListener(_onFocus);
    _focus.dispose();
    _controller.dispose();
    super.dispose();
  }

  String _format(double v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(2);

  void _onFocus() {
    if (_focus.hasFocus) {
      setState(() => _editing = true);
      _controller.selection = TextSelection(
        baseOffset: 0,
        extentOffset: _controller.text.length,
      );
    } else {
      _commit();
      setState(() => _editing = false);
    }
  }

  void _commit() {
    final parsed = double.tryParse(_controller.text.trim());
    if (parsed == null) {
      _controller.text = _format(widget.item.sellingPrice);
      return;
    }
    if ((parsed - widget.item.sellingPrice).abs() > 0.0001) {
      widget.onChanged(parsed);
    }
    _controller.text = _format(parsed);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 34,
      width: double.infinity,
      child: TextField(
        controller: _controller,
        focusNode: _focus,
        textAlign: TextAlign.center,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
        ],
        style: TextStyle(
          fontFamily: 'Literata',
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: AppColors.action(context),
        ),
        decoration: InputDecoration(
          isDense: true,
          prefixText: '₹',
          prefixStyle: TextStyle(
            fontFamily: 'Literata',
            fontSize: 12,
            color: AppColors.mutedText(context),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 6,
            vertical: 8,
          ),
          filled: true,
          fillColor: _editing
              ? AppColors.accentSoft(context, 0.12)
              : AppColors.inputFill(context),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: AppColors.border(context)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: AppColors.border(context)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: AppColors.action(context)),
          ),
        ),
        onSubmitted: (_) => _commit(),
      ),
    );
  }
}

class _TokenEditor extends StatefulWidget {
  final int? token;
  final ValueChanged<int?> onChanged;

  const _TokenEditor({
    required this.token,
    required this.onChanged,
  });

  @override
  State<_TokenEditor> createState() => _TokenEditorState();
}

class _TokenEditorState extends State<_TokenEditor> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.token != null && widget.token! > 0 ? '${widget.token}' : '',
    );
  }

  @override
  void didUpdateWidget(_TokenEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.token != widget.token) {
      final next =
          widget.token != null && widget.token! > 0 ? '${widget.token}' : '';
      if (_controller.text != next) _controller.text = next;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _commit() {
    final raw = _controller.text.trim();
    if (raw.isEmpty) {
      widget.onChanged(null);
      return;
    }
    final parsed = int.tryParse(raw);
    widget.onChanged(parsed != null && parsed > 0 ? parsed : null);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 34,
      width: double.infinity,
      child: TextField(
        controller: _controller,
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        style: TextStyle(
          fontFamily: 'Literata',
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: AppColors.primaryText(context),
        ),
        decoration: InputDecoration(
          isDense: true,
          hintText: '—',
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
          filled: true,
          fillColor: AppColors.inputFill(context),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: AppColors.border(context)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: AppColors.border(context)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: AppColors.action(context)),
          ),
        ),
        onSubmitted: (_) => _commit(),
        onEditingComplete: _commit,
      ),
    );
  }
}

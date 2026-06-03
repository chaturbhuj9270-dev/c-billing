import 'dart:async';

import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/ui/glassy_toast.dart';
import '../../../billing/domain/entities/bill_item.dart';
import '../../../billing/presentation/widgets/barcode_scanner_sheet.dart';
import '../../../billing/presentation/widgets/billing_add_items_widgets.dart';
import '../../../billing/presentation/widgets/billing_line_item_widgets.dart';
import '../../../event_order/domain/entities/order_item.dart';
import '../../../inventory_management/domain/entities/product.dart';
import '../../../inventory_management/offline/controllers/purchase_batch_offline_controller.dart';
import '../../../inventory_management/offline/entities/purchase_batch_entity.dart';
import '../../../product/data/services/product_sync_service.dart';
import '../../../product/offline/controllers/product_offline_controller.dart';
import '../../../product/offline/entities/product_entity.dart';

/// Product add UI for quotations — same flow and line editing as billing.
class QuotationProductsPanel extends StatefulWidget {
  final List<OrderItem> items;
  final ValueChanged<List<OrderItem>> onItemsChanged;
  final AppLocalizations localizations;

  const QuotationProductsPanel({
    super.key,
    required this.items,
    required this.onItemsChanged,
    required this.localizations,
  });

  @override
  State<QuotationProductsPanel> createState() => _QuotationProductsPanelState();
}

class _QuotationProductsPanelState extends State<QuotationProductsPanel> {
  static const _primary = Color(0xFF1B4D3E);
  final _uuid = const Uuid();

  final _indexNoController = TextEditingController();
  final _indexNoFocusNode = FocusNode();
  Timer? _debounceTimer;

  List<Product> _products = [];
  List<Product> _allProducts = [];
  List<PurchaseBatchEntity> _availableBatches = [];
  Map<int, Product> _productByIndexNo = {};
  bool _isLoadingProducts = true;

  List<BillItem> _billItems = [];
  final Map<String, String> _orderItemIdsByProductKey = {};
  bool _syncingToParent = false;

  @override
  void initState() {
    super.initState();
    _billItems = _billItemsFromOrderItems(widget.items);
    _loadProducts();
  }

  @override
  void didUpdateWidget(QuotationProductsPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_syncingToParent) return;
    if (oldWidget.items != widget.items) {
      _billItems = _billItemsFromOrderItems(widget.items);
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _indexNoController.dispose();
    _indexNoFocusNode.dispose();
    super.dispose();
  }

  List<BillItem> _billItemsFromOrderItems(List<OrderItem> items) {
    for (final item in items) {
      _orderItemIdsByProductKey[item.productId] = item.id;
    }
    return items
        .map(
          (item) => BillItem.create(
            productId: item.productId,
            productName: item.productName,
            sellingPrice: item.rate,
            purchasePrice: 0,
            quantity: item.quantity.toDouble(),
            hsnCode: item.hsnCode,
            cgstPercent: item.cgstPercent,
            sgstPercent: item.sgstPercent,
          ),
        )
        .toList();
  }

  List<OrderItem> _orderItemsFromBillItems(List<BillItem> billItems) {
    return billItems.map((billItem) {
      final existingId = _orderItemIdsByProductKey[billItem.productId];
      final qty = billItem.quantity < 1
          ? 1
          : billItem.quantity.round().clamp(1, 999999);
      final orderItem = OrderItem.fromProductData(
        id: existingId ?? _uuid.v4(),
        productId: billItem.productId,
        productName: billItem.productName,
        hsnCode: billItem.hsnCode,
        quantity: qty,
        rate: billItem.sellingPrice,
        cgstPercent: billItem.cgstPercent,
        sgstPercent: billItem.sgstPercent,
      );
      _orderItemIdsByProductKey[billItem.productId] = orderItem.id;
      return orderItem;
    }).toList();
  }

  void _syncBillItemsToParent(List<BillItem> next) {
    setState(() => _billItems = next);
    _syncingToParent = true;
    widget.onItemsChanged(_orderItemsFromBillItems(next));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _syncingToParent = false;
    });
  }

  Future<void> _loadProducts() async {
    try {
      var entities = await ProductOfflineController.instance.getAllProducts();
      if (entities.isEmpty) {
        await ProductSyncService.instance.forceFullRefresh();
        entities = await ProductOfflineController.instance.getAllProducts();
      }

      final mapped = entities.map(_entityToProduct).toList();
      final batches = await PurchaseBatchOfflineController.instance
          .getAllBatches(includeConsumed: false);

      if (mounted) {
        setState(() {
          _allProducts = mapped;
          _products = mapped.where((p) => p.currentStock > 0).toList();
          _availableBatches =
              batches.where((b) => b.quantityRemaining > 0).toList()
                ..sort((a, b) => a.purchaseDate.compareTo(b.purchaseDate));
          _productByIndexNo = {
            for (final product in mapped)
              if (product.indexNo > 0) product.indexNo: product,
          };
          _isLoadingProducts = false;
        });
      }
    } catch (e) {
      debugPrint('[QuotationProducts] Load error: $e');
      if (mounted) setState(() => _isLoadingProducts = false);
    }
  }

  Product _entityToProduct(ProductEntity entity) {
    return Product(
      id: entity.serverId ?? entity.id.toString(),
      indexNo: entity.indexNo,
      name: entity.name,
      companyName: entity.companyName,
      category: entity.category,
      purchasePrice: entity.purchasePrice,
      salesPrice: entity.salesPrice,
      currentStock: entity.currentStock,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      cgstPercent: entity.cgstPercent,
      sgstPercent: entity.sgstPercent,
      hsnCode: entity.hsnCode,
      unit: entity.unit,
    );
  }

  void _showSnackbar(String message, {bool isError = false}) {
    GlassyToast.show(context, message, isError: isError);
  }

  void _upsertFromBillItem(BillItem billItem) {
    final items = List<BillItem>.from(_billItems);
    final existingIndex = items.indexWhere(
      (item) => item.productId == billItem.productId,
    );

    if (existingIndex != -1) {
      items[existingIndex] = billItem;
    } else {
      items.add(billItem);
    }
    _syncBillItemsToParent(items);
  }

  void _removeByProductKey(String productKey) {
    _syncBillItemsToParent(
      _billItems.where((item) => item.productId != productKey).toList(),
    );
  }

  void _showAddItemsPopup() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AddItemsBottomSheet(
        products: _products,
        allProducts: _allProducts,
        billItems: _billItems,
        availableBatches: _availableBatches,
        localizations: widget.localizations,
        showSnackbar: _showSnackbar,
        onBatchItemAdded:
            (
              productId,
              productName,
              companyName,
              batchLocalId,
              sellingPrice,
              purchasePrice,
              quantity,
              maxStock,
              cgstPercent,
              sgstPercent,
              hsnCode,
              unit,
              sellUnit,
            ) {
              final uniqueKey = batchLocalId != null
                  ? '${productId}_batch_$batchLocalId'
                  : productId;
              _upsertFromBillItem(
                BillItem.create(
                  productId: uniqueKey,
                  productName: productName,
                  companyName: companyName.isNotEmpty ? companyName : null,
                  sellingPrice: sellingPrice,
                  purchasePrice: purchasePrice,
                  quantity: quantity,
                  hsnCode: hsnCode,
                  unit: unit,
                  sellUnit: sellUnit,
                  cgstPercent: cgstPercent,
                  sgstPercent: sgstPercent,
                ),
              );
            },
        onItemRemoved: _removeByProductKey,
      ),
    );
  }

  void _showBarcodeScanner() {
    BarcodeScannerSheet.show(
      context,
      onProductScanned: (productData) {
        final productId = productData['productId'] as String;
        final batchId = productData['batchId'] as String?;
        final uniqueKey = batchId != null
            ? '${productId}_batch_$batchId'
            : productId;
        _upsertFromBillItem(
          BillItem.create(
            productId: uniqueKey,
            productName: productData['productName'] as String,
            sellingPrice: (productData['unitPrice'] as num?)?.toDouble() ?? 0,
            purchasePrice:
                (productData['purchasePrice'] as num?)?.toDouble() ?? 0,
            quantity: 1,
            hsnCode: productData['hsnCode'] as String?,
            unit: productData['unit'] as String? ?? 'pcs',
            cgstPercent: (productData['cgst'] as num?)?.toDouble() ?? 0,
            sgstPercent: (productData['sgst'] as num?)?.toDouble() ?? 0,
          ),
        );
      },
      onProductRemoved: _removeByProductKey,
    );
  }

  void _addProductByIndexNo() {
    final indexText = _indexNoController.text.trim();
    if (indexText.isEmpty) return;

    final indexNo = int.tryParse(indexText);
    if (indexNo == null) {
      _showSnackbar(widget.localizations.pleaseEnterValidNumber, isError: true);
      _indexNoController.clear();
      return;
    }

    final product = _productByIndexNo[indexNo];
    if (product == null) {
      _showSnackbar(
        '${widget.localizations.productNotFound} #$indexNo',
        isError: true,
      );
      _indexNoController.clear();
      return;
    }

    final productBatches =
        _availableBatches
            .where((b) => b.productId == product.id && b.quantityRemaining > 0)
            .toList()
          ..sort((a, b) => a.purchaseDate.compareTo(b.purchaseDate));
    final batchStock = productBatches.fold<int>(
      0,
      (s, b) => s + b.quantityRemaining,
    );
    final effectiveStock = batchStock > 0 ? batchStock : product.currentStock;

    if (effectiveStock <= 0) {
      _showSnackbar(
        '${product.name} ${widget.localizations.outOfStock}',
        isError: true,
      );
      _indexNoController.clear();
      return;
    }

    if (productBatches.isNotEmpty) {
      _indexNoController.clear();
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (ctx) => BatchSelectionSheet(
          productName: product.name,
          productCode: product.indexNo,
          batches: productBatches,
          localizations: widget.localizations,
          existingBillItems: _billItems,
          cgstPercent: product.cgstPercent,
          sgstPercent: product.sgstPercent,
          hsnCode: product.hsnCode,
          unit: product.unit,
          onBatchSelected: (batch, quantity, sellUnit) {
            final uniqueKey = '${product.id}_batch_${batch.id}';
            _upsertFromBillItem(
              BillItem.create(
                productId: uniqueKey,
                productName: product.name,
                companyName: batch.companyName.isNotEmpty
                    ? batch.companyName
                    : null,
                sellingPrice: batch.sellingPrice,
                purchasePrice: batch.purchasePrice,
                quantity: quantity,
                hsnCode: product.hsnCode,
                unit: product.unit,
                sellUnit: sellUnit,
                cgstPercent: product.cgstPercent,
                sgstPercent: product.sgstPercent,
              ),
            );
            Navigator.pop(ctx);
            _showSnackbar('${widget.localizations.added}: ${product.name}');
          },
          onItemRemoved: _removeByProductKey,
        ),
      );
      _indexNoFocusNode.requestFocus();
      return;
    }

    final items = List<BillItem>.from(_billItems);
    final existingIndex = items.indexWhere(
      (item) => item.productId == product.id,
    );

    if (existingIndex != -1) {
      final existing = items[existingIndex];
      if (existing.quantity + 1 <= effectiveStock) {
        items[existingIndex] = BillItem.create(
          productId: existing.productId,
          productName: existing.productName,
          companyName: existing.companyName,
          sellingPrice: existing.sellingPrice,
          purchasePrice: existing.purchasePrice,
          quantity: existing.quantity + 1,
          cgstPercent: existing.cgstPercent,
          sgstPercent: existing.sgstPercent,
          hsnCode: existing.hsnCode,
          unit: existing.unit,
          sellUnit: existing.sellUnit,
        );
      } else {
        _showSnackbar(
          '${widget.localizations.maxStock}: $effectiveStock',
          isError: true,
        );
        _indexNoController.clear();
        return;
      }
    } else {
      items.add(
        BillItem.create(
          productId: product.id,
          productName: product.name,
          sellingPrice: product.salesPrice,
          purchasePrice: product.purchasePrice,
          quantity: 1,
          hsnCode: product.hsnCode,
          unit: product.unit,
          cgstPercent: product.cgstPercent,
          sgstPercent: product.sgstPercent,
        ),
      );
    }

    _syncBillItemsToParent(items);
    _showSnackbar('${widget.localizations.added}: ${product.name}');
    _indexNoController.clear();
    _indexNoFocusNode.requestFocus();
  }

  void _onIndexNoChanged() {
    _debounceTimer?.cancel();
    if (_indexNoController.text.trim().isEmpty) return;
    _debounceTimer = Timer(const Duration(milliseconds: 400), () {
      if (mounted) _addProductByIndexNo();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = widget.localizations;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_isLoadingProducts)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Center(
              child: CircularProgressIndicator(color: _primary),
            ),
          )
        else ...[
          _buildAddProductBar(l10n),
          const SizedBox(height: 12),
          if (_billItems.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  l10n.noProductsFound,
                  style: TextStyle(
                    fontFamily: 'Literata',
                    color: Colors.grey[600],
                  ),
                ),
              ),
            )
          else
            BillItemsLineList(
              items: _billItems,
              products: _allProducts,
              availableBatches: _availableBatches,
              localizations: l10n,
              onItemsChanged: _syncBillItemsToParent,
              showSnackbar: _showSnackbar,
            ),
        ],
      ],
    );
  }

  Widget _buildAddProductBar(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.amber[700]!, Colors.amber[600]!],
              ),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(
              Icons.flash_on_rounded,
              color: Colors.white,
              size: 14,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _indexNoController,
              focusNode: _indexNoFocusNode,
              keyboardType: TextInputType.number,
              style: const TextStyle(
                fontFamily: 'Literata',
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                hintText: l10n.enterProductCode,
                hintStyle: TextStyle(
                  color: Colors.grey[500],
                  fontWeight: FontWeight.w400,
                  fontSize: 13,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
              onChanged: (_) => _onIndexNoChanged(),
              onSubmitted: (_) => _addProductByIndexNo(),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _showAddItemsPopup,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: _primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(
                Icons.search_rounded,
                color: _primary,
                size: 18,
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _showBarcodeScanner,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1B4D3E), Color(0xFF2D6A4F)],
                ),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(
                Icons.barcode_reader,
                color: Colors.white,
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:barcode_widget/barcode_widget.dart' as bw;
import '../../../../core/services/barcode_service.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/printing/barcode_label/barcode_label_escpos.dart';
import '../../../../core/printing/barcode_label/barcode_label_layout.dart';
import '../../../../core/printing/barcode_label/barcode_label_models.dart';
import '../../../../core/printing/barcode_label/barcode_label_pdf.dart';
import '../../../../core/printing/barcode_label/barcode_label_settings_service.dart';
import '../../../../core/printing/barcode_label/barcode_label_tspl.dart';
import '../widgets/barcode_label_preview.dart';
import '../widgets/barcode_label_ui_helpers.dart';
import 'barcode_settings_page.dart';
import '../../../../core/printing/services/pos_printer_service.dart';
import '../../../../common_widgets/printer_selection_widget.dart';
import '../../../product/offline/controllers/product_offline_controller.dart';
import '../../../product/offline/entities/product_entity.dart';
import '../../offline/controllers/purchase_batch_offline_controller.dart';
import '../../offline/entities/purchase_batch_entity.dart';
import 'package:c_billing/core/ui/glassy_toast.dart';
import 'package:c_billing/common_widgets/app_tab_bar.dart';
import 'package:c_billing/common_widgets/app_top_bar.dart';
import 'package:c_billing/core/theme/app_theme.dart';
import 'package:c_billing/common_widgets/glass_bottom_sheet.dart';

class BarcodeGeneratorPage extends StatefulWidget {
  final bool isEmbedded;

  const BarcodeGeneratorPage({super.key, this.isEmbedded = false});

  @override
  State<BarcodeGeneratorPage> createState() => _BarcodeGeneratorPageState();
}

class _BarcodeGeneratorPageState extends State<BarcodeGeneratorPage>
    with TickerProviderStateMixin {
  // Animation Controllers
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _scaleController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;

  // Tab Controller for mobile view
  late TabController _tabController;

  // State
  bool _isLoading = true;
  List<ProductEntity> _products = [];
  List<ProductEntity> _filteredProducts = [];
  ProductEntity? _selectedProduct;
  List<PurchaseBatchEntity> _productBatches = [];
  PurchaseBatchEntity? _selectedBatch;
  String _searchQuery = '';
  BarcodeFormat _selectedFormat = BarcodeFormat.ean13;
  String _generatedBarcode = '';
  final _labelSvc = BarcodeLabelSettingsService.instance;
  bool get _includePrice => _labelSvc.settings.includePrice;
  bool get _includeCompany => _labelSvc.settings.includeCompany;
  AppLocalizations get _l => barcodeL10n();
  bool _autoGenerate = true;

  // Controllers
  final _searchController = TextEditingController();
  final _customBarcodeController = TextEditingController();
  final _quantityController = TextEditingController(text: '1');
  final _barcodeKey = GlobalKey();
  final _printerService = PosPrinterService();

  // Theme colors
  Color get _primaryColor => AppColors.action(context);
  static const Color _accentColor = AppTheme.paletteFF2E7D5A;
  Color _backgroundColor(BuildContext context) => AppColors.scaffold(context);
  Color get _cardColor => AppColors.card(context);
  Color get _borderColor => AppColors.border(context);
  Color get _primaryText => AppColors.primaryText(context);
  Color get _secondaryText => AppColors.secondaryText(context);
  Color get _mutedText => AppColors.mutedText(context);
  static const Color _successColor = AppTheme.green;
  static const Color _warningColor = AppTheme.orange400;

  @override
  void initState() {
    super.initState();

    // Initialize tab controller
    _tabController = TabController(length: 2, vsync: this);

    // Setup animations
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
        );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeOutBack),
    );

    _labelSvc.ensureLoaded();
    _labelSvc.addListener(_onLabelSettingsChanged);
    _loadProducts();
  }

  void _onLabelSettingsChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _labelSvc.removeListener(_onLabelSettingsChanged);
    _fadeController.dispose();
    _slideController.dispose();
    _scaleController.dispose();
    _tabController.dispose();
    _searchController.dispose();
    _customBarcodeController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    setState(() => _isLoading = true);

    try {
      final products = await ProductOfflineController.instance.getAllProducts();
      setState(() {
        _products = products.where((p) => p.isActive).toList();
        _filteredProducts = _products;
        _isLoading = false;
      });

      // Start animations
      _fadeController.forward();
      _slideController.forward();
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackBar('Error loading products: $e', isError: true);
    }
  }

  void _filterProducts(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredProducts = _products;
      } else {
        _filteredProducts = _products.where((p) {
          final nameLower = p.name.toLowerCase();
          final companyLower = p.companyName.toLowerCase();
          final queryLower = query.toLowerCase();
          return nameLower.contains(queryLower) ||
              companyLower.contains(queryLower) ||
              p.indexNo.toString().contains(query);
        }).toList();
      }
    });
  }

  Future<void> _selectProduct(ProductEntity product) async {
    setState(() {
      _selectedProduct = product;
      _generatedBarcode = '';
      _selectedBatch = null;
    });

    // Load batches for this product
    try {
      final productId = product.serverId ?? product.id.toString();
      final batches = await PurchaseBatchOfflineController.instance
          .getBatchesByProductId(productId, onlyWithStock: false);

      setState(() {
        _productBatches = batches;
        if (batches.isNotEmpty) {
          _selectedBatch = batches.first;
        }
      });

      // Auto-generate barcode if enabled
      if (_autoGenerate) {
        _generateBarcode();
      }

      _scaleController.forward(from: 0);

      // Switch to barcode tab on mobile after selecting product
      if (!mounted) return;
      if (MediaQuery.of(context).size.width < 600) {
        _tabController.animateTo(1);
      }
    } catch (e) {
      _showSnackBar('Error loading batches: $e', isError: true);
    }
  }

  // Build a safe barcode widget that validates data before rendering Returns a placeholder if data is invalid for the format
  Widget _buildSafeBarcodeWidget({
    required String data,
    required BarcodeFormat format,
    double width = 200,
    double height = 70,
  }) {
    // Check if data is empty
    if (data.isEmpty) {
      return _buildBarcodePlaceholder(
        width: width,
        height: height,
        message: 'No barcode generated',
      );
    }

    // Quick pre-validation without calling the barcode library
    if (!_quickValidateFormat(data, format)) {
      return _buildBarcodePlaceholder(
        width: width,
        height: height,
        message: 'Invalid for ${format.code}',
        isError: true,
      );
    }

    // Use RepaintBoundary to isolate rendering and prevent UI freeze
    return RepaintBoundary(
      child: Builder(
        builder: (context) {
          try {
            return bw.BarcodeWidget(
              barcode: BarcodeService.instance.getBarcodeRenderer(format),
              data: data,
              drawText: false,
              color: AppTheme.black,
              backgroundColor: AppTheme.transparent,
              errorBuilder: (context, error) => _buildBarcodePlaceholder(
                width: width,
                height: height,
                message: 'Render error',
                isError: true,
              ),
            );
          } catch (e) {
            return _buildBarcodePlaceholder(
              width: width,
              height: height,
              message: 'Render error',
              isError: true,
            );
          }
        },
      ),
    );
  }

  // Quick validation without calling barcode library (prevents hangs)
  bool _quickValidateFormat(String data, BarcodeFormat format) {
    switch (format) {
      case BarcodeFormat.ean13:
        // EAN-13: exactly 13 digits
        return data.length == 13 && RegExp(r'^\d+$').hasMatch(data);
      case BarcodeFormat.ean8:
        // EAN-8: exactly 8 digits
        return data.length == 8 && RegExp(r'^\d+$').hasMatch(data);
      case BarcodeFormat.upcA:
        // UPC-A: exactly 12 digits
        return data.length == 12 && RegExp(r'^\d+$').hasMatch(data);
      case BarcodeFormat.code128:
        // Code128: ASCII characters only, non-empty
        return data.isNotEmpty && data.length <= 80;
      case BarcodeFormat.code39:
        // Code39: alphanumeric + special chars
        return data.isNotEmpty &&
            RegExp(
              r'^[A-Z0-9\-\.\$\/\+\%\s]+$',
              caseSensitive: false,
            ).hasMatch(data);
      case BarcodeFormat.qrCode:
        // QR Code: any data up to reasonable length
        return data.isNotEmpty && data.length <= 2953;
    }
  }

  // Build a placeholder for invalid/empty barcode
  Widget _buildBarcodePlaceholder({
    required double width,
    required double height,
    required String message,
    bool isError = false,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: isError
            ? AppTheme.red.withValues(alpha: 0.12)
            : AppColors.chipFill(context),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isError ? AppTheme.red.withValues(alpha: 0.35) : _borderColor,
          style: BorderStyle.solid,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isError ? Icons.error_outline_rounded : Icons.barcode_reader,
            size: 24,
            color: isError ? AppTheme.toneRose : _mutedText,
          ),
          const SizedBox(height: 4),
          Text(
            message,
            style: TextStyle(
              fontFamily: 'Literata',
              fontSize: 10,
              color: isError ? AppTheme.toneRose : _mutedText,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _generateBarcode() {
    if (_selectedProduct == null) return;

    String barcode;

    if (!_autoGenerate && _customBarcodeController.text.isNotEmpty) {
      barcode = _customBarcodeController.text.trim();
    } else {
      // Generate based on selected format - always include batch when available
      final batchId = _selectedBatch?.id;

      switch (_selectedFormat) {
        case BarcodeFormat.ean13:
          barcode = BarcodeService.instance.generateEAN13(
            productIndexNo: _selectedProduct!.indexNo,
            batchNo: batchId,
          );
          break;
        case BarcodeFormat.ean8:
          // EAN-8: 2 digits prefix + 5 digits product (include batch in product)
          final productWithBatch =
              (_selectedProduct!.indexNo * 100 + (batchId ?? 0) % 100) % 100000;
          barcode = BarcodeService.instance.generateEAN8(
            productIndexNo: productWithBatch,
          );
          break;
        case BarcodeFormat.upcA:
          barcode = BarcodeService.instance.generateUPCA(
            productIndexNo: _selectedProduct!.indexNo,
            batchNo: batchId,
          );
          break;
        case BarcodeFormat.code128:
        case BarcodeFormat.code39:
          barcode = BarcodeService.instance.generateCustomBarcode(
            productIndexNo: _selectedProduct!.indexNo,
            companyCode: _selectedProduct!.companyName.isNotEmpty
                ? _selectedProduct!.companyName
                : null,
            batchNo: batchId,
          );
          break;
        case BarcodeFormat.qrCode:
          // QR Code can contain more data - include batch info in text
          barcode = BarcodeService.instance.generateQRData(
            productId:
                _selectedProduct!.serverId ?? _selectedProduct!.id.toString(),
            productName: _selectedProduct!.name,
            batchNo: batchId,
            price: _selectedBatch?.sellingPrice ?? _selectedProduct!.salesPrice,
          );
          break;
      }
    }

    // Validate barcode
    if (!BarcodeService.instance.validateBarcodeData(
      barcode,
      _selectedFormat,
    )) {
      _showSnackBar(
        'Invalid barcode for ${_selectedFormat.displayName}. ${BarcodeService.instance.getFormatInfo(_selectedFormat)}',
        isError: true,
      );
      return;
    }

    setState(() {
      _generatedBarcode = barcode;
    });

    _scaleController.forward(from: 0);
  }

  Future<void> _assignBarcodeToProduct() async {
    if (_selectedProduct == null || _generatedBarcode.isEmpty) return;

    final productId =
        _selectedProduct!.serverId ?? _selectedProduct!.id.toString();
    final success = await BarcodeService.instance.assignBarcodeToProduct(
      productId,
      _generatedBarcode,
    );

    if (success) {
      _showSnackBar('Barcode assigned successfully!', isError: false);
      // Refresh product data
      _loadProducts();
    } else {
      _showSnackBar(
        'Failed to assign barcode. It may already be in use.',
        isError: true,
      );
    }
  }

  // ---------------------------------------------------------------------
  // Label printing (feature: barcode-labels). Layout, PDF, ESC/POS and TSPL
  // output come from core/printing/barcode_label so every printer type prints
  // the same label for the chosen size.
  // ---------------------------------------------------------------------

  BarcodeLabelSettings get _labelSettings => _labelSvc.settings;

  int get _copies => (int.tryParse(_quantityController.text) ?? 1).clamp(
    1,
    BarcodeLabelPdf.maxCopies,
  );

  LabelContent _currentLabelContent() {
    final p = _selectedProduct;
    final b = _selectedBatch;
    String? batchLabel;
    if (b != null) {
      final n = b.batchNumber?.trim();
      batchLabel = (n != null && n.isNotEmpty) ? n : 'B#${b.id}';
    }
    return LabelContent.build(
      name: p?.name ?? '',
      code: _generatedBarcode,
      format: _selectedFormat,
      settings: _labelSettings,
      company: p?.companyName,
      size: p?.size,
      color: p?.color,
      price: b?.sellingPrice ?? p?.salesPrice,
      mrp: p?.mrp,
      batchLabel: batchLabel,
      expiry: b?.expiryDate,
    );
  }

  LabelLayout _currentLabelLayout([LabelContent? content]) {
    final s = _labelSettings;
    return computeLabelLayout(
      widthMm: s.widthMm,
      heightMm: s.heightMm,
      content: content ?? _currentLabelContent(),
    );
  }

  String get _jobName => 'Barcode_${_selectedProduct?.name ?? 'Label'}';

  /// Normal printer: labels in a grid on A4 sheets.
  Future<void> _printBarcode() async {
    if (_generatedBarcode.isEmpty) return;
    try {
      final settings = _labelSettings.copyWith(
        printerType: BarcodePrinterType.normal,
      );
      final content = _currentLabelContent();
      final copies = _copies;
      await Printing.layoutPdf(
        onLayout: (format) => BarcodeLabelPdf.build(
          settings: settings,
          content: content,
          copies: copies,
        ),
        name: _jobName,
        format: PdfPageFormat.a4,
      );
    } catch (e) {
      _showSnackBar('Error printing barcode: $e', isError: true);
    }
  }

  /// Barcode (label roll) printer: one label per page at the exact size, via
  /// the printer driver, or TSPL over Bluetooth.
  Future<void> _printBarcodeLabel() async {
    if (_generatedBarcode.isEmpty) return;
    final s = _labelSettings;
    if (s.connection == LabelConnection.bluetooth) {
      return _printBarcodeTspl();
    }
    try {
      final settings = s.copyWith(printerType: BarcodePrinterType.label);
      final content = _currentLabelContent();
      final copies = _copies;
      await Printing.layoutPdf(
        onLayout: (format) => BarcodeLabelPdf.build(
          settings: settings,
          content: content,
          copies: copies,
        ),
        name: _jobName,
        format: PdfPageFormat(
          s.widthMm * PdfPageFormat.mm,
          s.heightMm * PdfPageFormat.mm,
        ),
        usePrinterSettings: false,
      );
    } catch (e) {
      _showSnackBar('Error printing barcode: $e', isError: true);
    }
  }

  Future<bool> _ensurePosConnected() async {
    if (_printerService.isConnected) return true;
    final selectedPrinter = await PrinterSelectionWidget.show(context);
    if (selectedPrinter == null) {
      _showSnackBar('No printer selected', isError: true);
      return false;
    }
    return true;
  }

  /// Bluetooth barcode printer that understands TSPL.
  Future<void> _printBarcodeTspl() async {
    if (_generatedBarcode.isEmpty) return;
    if (!await _ensurePosConnected()) return;
    try {
      final s = _labelSettings;
      final content = _currentLabelContent();
      final bytes = BarcodeLabelTspl.build(
        widthMm: s.widthMm,
        heightMm: s.heightMm,
        gapMm: s.gapMm,
        content: content,
        layout: _currentLabelLayout(content),
        copies: _copies,
      );
      final result = await _printerService.printRaw(bytes);
      if (result.success) {
        _showSnackBar(_l.labelsSentToPrinter, isError: false);
      } else {
        _showSnackBar(result.message ?? 'Print failed', isError: true);
      }
    } catch (e) {
      _showSnackBar('Error printing barcode: $e', isError: true);
    }
  }

  /// POS (thermal receipt) printer over ESC/POS.
  Future<void> _printBarcodePos() async {
    if (_generatedBarcode.isEmpty) return;
    if (!await _ensurePosConnected()) return;
    try {
      final content = _currentLabelContent();
      final paper = _printerService.config.paperSize;
      if (!BarcodeLabelEscPos.fitsPaper(paper: paper, content: content)) {
        _showSnackBar(_l.posBarcodeTooLong, isError: true);
        return;
      }
      final bytes = BarcodeLabelEscPos.build(
        paper: paper,
        content: content,
        layout: _currentLabelLayout(content),
        copies: _copies,
      );
      final result = await _printerService.printRaw(bytes);
      if (result.success) {
        _showSnackBar(_l.labelsSentToPrinter, isError: false);
      } else {
        _showSnackBar(result.message ?? 'Print failed', isError: true);
      }
    } catch (e) {
      _showSnackBar('Error printing barcode: $e', isError: true);
    }
  }

  /// PDF used for sharing: label-sized pages for a barcode printer, otherwise
  /// A4 sheets.
  Future<Uint8List> _generateBarcodePdf(int quantity) {
    final s = _labelSettings;
    return BarcodeLabelPdf.build(
      settings: s.printerType == BarcodePrinterType.label
          ? s
          : s.copyWith(printerType: BarcodePrinterType.normal),
      content: _currentLabelContent(),
      copies: quantity.clamp(1, BarcodeLabelPdf.maxCopies),
    );
  }

  void _setIncludePrice(bool v) =>
      _labelSvc.update(_labelSettings.copyWith(includePrice: v));

  void _setIncludeCompany(bool v) =>
      _labelSvc.update(_labelSettings.copyWith(includeCompany: v));

  void _openBarcodeSettings() {
    showAppPage(context, const BarcodeSettingsPage());
  }

  void _copyBarcodeToClipboard() {
    if (_generatedBarcode.isEmpty) return;

    Clipboard.setData(ClipboardData(text: _generatedBarcode));
    _showSnackBar('Barcode copied to clipboard!', isError: false);
  }

  void _showSnackBar(String message, {required bool isError}) {
    GlassyToast.show(context, message, isError: isError);
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Scaffold(
      backgroundColor: _backgroundColor(context),
      body: SafeArea(
        top: _isLoading,
        child: _isLoading
            ? _buildLoadingState()
            : FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Column(
                    children: [
                      if (!widget.isEmbedded) _buildHeader(isMobile),
                      if (isMobile) ...[
                        // Mobile: Tab-based layout
                        _buildMobileTabBar(),
                        Expanded(
                          child: TabBarView(
                            controller: _tabController,
                            children: [
                              _buildMobileProductList(),
                              _buildMobileBarcodeView(),
                            ],
                          ),
                        ),
                      ] else ...[
                        // Tablet/Desktop: Side-by-side layout
                        Expanded(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 4,
                                child: _buildProductSelectionPanel(),
                              ),
                              Expanded(flex: 6, child: _buildBarcodePanel()),
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
  }

  Widget _buildMobileTabBar() {
    return AppTabBar(
      controller: _tabController,
      tabs: [
        Tab(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.inventory_2_rounded, size: 18),
              const SizedBox(width: 8),
              Text('Products (${_products.length})'),
            ],
          ),
        ),
        Tab(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.barcode_reader, size: 18),
              const SizedBox(width: 8),
              const Text('Barcode'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMobileProductList() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchController,
              onChanged: _filterProducts,
              style: const TextStyle(fontFamily: 'Literata', fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Search products...',
                hintStyle: TextStyle(
                  fontFamily: 'Literata',
                  color: _mutedText,
                  fontSize: 13,
                ),
                prefixIcon: Icon(Icons.search, color: _mutedText, size: 20),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear, color: _mutedText, size: 20),
                        onPressed: () {
                          _searchController.clear();
                          _filterProducts('');
                        },
                      )
                    : null,
                filled: true,
                fillColor: AppColors.inputFill(context),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: _primaryColor, width: 1.5),
                ),
              ),
            ),
          ),
          // Product list
          Expanded(
            child: _filteredProducts.isEmpty
                ? _buildEmptyProductState()
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                    itemCount: _filteredProducts.length,
                    itemBuilder: (context, index) {
                      final product = _filteredProducts[index];
                      final isSelected = _selectedProduct?.id == product.id;
                      return _buildProductCard(product, isSelected);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileBarcodeView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        children: [
          // Barcode Preview Card
          _buildMobileBarcodePreviewCard(),
          const SizedBox(height: 12),
          // Options Card
          _buildMobileOptionsCard(),
        ],
      ),
    );
  }

  Widget _buildMobileBarcodePreviewCard() {
    return Container(
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _primaryColor.withValues(alpha: 0.08),
                  _accentColor.withValues(alpha: 0.04),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.barcode_reader,
                    color: _primaryColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Barcode Preview',
                        style: TextStyle(
                          fontFamily: 'Literata',
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: _primaryColor,
                        ),
                      ),
                      if (_selectedProduct != null)
                        Text(
                          _selectedProduct!.name,
                          style: TextStyle(
                            fontFamily: 'Literata',
                            fontSize: 12,
                            color: _secondaryText,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                if (_generatedBarcode.isNotEmpty)
                  IconButton(
                    onPressed: _copyBarcodeToClipboard,
                    icon: Icon(
                      Icons.copy_rounded,
                      color: _primaryColor,
                      size: 20,
                    ),
                    tooltip: 'Copy barcode',
                  ),
              ],
            ),
          ),
          // Barcode Display
          Container(
            constraints: const BoxConstraints(minHeight: 200),
            padding: const EdgeInsets.all(16),
            child: _selectedProduct == null
                ? _buildSelectProductPrompt()
                : _generatedBarcode.isEmpty
                ? _buildGenerateBarcodePrompt()
                : ScaleTransition(
                    scale: _scaleAnimation,
                    child: _buildBarcodeDisplay(),
                  ),
          ),
          // Action Buttons
          if (_generatedBarcode.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: _buildActionButton(
                      icon: Icons.save_alt_rounded,
                      label: 'Assign',
                      onTap: _assignBarcodeToProduct,
                      isPrimary: false,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: _buildPrintButtonWithOptions(isMobile: true)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMobileOptionsCard() {
    return Container(
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _accentColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.tune_rounded,
                  color: _accentColor,
                  size: 16,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Options',
                style: TextStyle(
                  fontFamily: 'Literata',
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: _primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Format Selection
          Text(
            'Barcode Format',
            style: TextStyle(
              fontFamily: 'Literata',
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: _primaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: BarcodeFormat.values.map((format) {
              final isSelected = _selectedFormat == format;
              return GestureDetector(
                onTap: () {
                  if (_selectedFormat != format) {
                    setState(() {
                      _selectedFormat = format;
                      // Clear barcode when format changes - will regenerate if product selected
                      _generatedBarcode = '';
                    });
                    // Defer barcode generation to next frame to prevent UI hang
                    if (_selectedProduct != null) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted) _generateBarcode();
                      });
                    }
                  }
                },
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? _primaryColor
                        : AppColors.chipFill(context),
                    borderRadius: BorderRadius.circular(8),
                    border: isSelected ? null : Border.all(color: _borderColor),
                  ),
                  child: Text(
                    format.code,
                    style: TextStyle(
                      fontFamily: 'Literata',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? AppTheme.white : _secondaryText,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 16),

          // Batch Selection (if available)
          if (_productBatches.isNotEmpty) ...[
            Text(
              'Select Batch',
              style: TextStyle(
                fontFamily: 'Literata',
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: _primaryColor,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: AppColors.scaffold(context),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _borderColor),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<PurchaseBatchEntity>(
                  value: _selectedBatch,
                  isExpanded: true,
                  hint: const Text(
                    'Select batch',
                    style: TextStyle(fontFamily: 'Literata', fontSize: 13),
                  ),
                  items: _productBatches.map((batch) {
                    return DropdownMenuItem(
                      value: batch,
                      child: Text(
                        'Batch #${batch.id} - ₹${batch.sellingPrice.toStringAsFixed(0)} (${batch.quantityRemaining} left)',
                        style: const TextStyle(
                          fontFamily: 'Literata',
                          fontSize: 13,
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (batch) {
                    setState(() => _selectedBatch = batch);
                    if (_autoGenerate) _generateBarcode();
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          _buildPrintSetupSummary(),
          // Toggle Options
          _buildToggleOption(
            'Auto-generate barcode',
            'Auto create when selecting product',
            _autoGenerate,
            (value) {
              setState(() => _autoGenerate = value);
              if (value && _selectedProduct != null) _generateBarcode();
            },
          ),
          _buildToggleOption(
            'Include price',
            'Show price on label',
            _includePrice,
            _setIncludePrice,
          ),
          _buildToggleOption(
            'Include company',
            'Show company name',
            _includeCompany,
            _setIncludeCompany,
          ),

          const SizedBox(height: 16),

          // Print Quantity
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Print Quantity',
                      style: TextStyle(
                        fontFamily: 'Literata',
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: _primaryColor,
                      ),
                    ),
                    Text(
                      'Number of labels',
                      style: TextStyle(
                        fontFamily: 'Literata',
                        fontSize: 11,
                        color: _mutedText,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.scaffold(context),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _borderColor),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      onPressed: () {
                        final current =
                            int.tryParse(_quantityController.text) ?? 1;
                        if (current > 1) {
                          _quantityController.text = (current - 1).toString();
                        }
                      },
                      icon: const Icon(Icons.remove, size: 18),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 36,
                        minHeight: 36,
                      ),
                    ),
                    SizedBox(
                      width: 40,
                      child: TextField(
                        controller: _quantityController,
                        textAlign: TextAlign.center,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(
                          fontFamily: 'Literata',
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        final current =
                            int.tryParse(_quantityController.text) ?? 1;
                        _quantityController.text = (current + 1).toString();
                      },
                      icon: const Icon(Icons.add, size: 18),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 36,
                        minHeight: 36,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Custom Barcode Input (when auto-generate is off)
          if (!_autoGenerate) ...[
            const SizedBox(height: 16),
            Text(
              'Custom Barcode',
              style: TextStyle(
                fontFamily: 'Literata',
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: _primaryColor,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _customBarcodeController,
                    style: TextStyle(
                      fontFamily: 'Literata',
                      fontSize: 14,
                      letterSpacing: 1,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Enter barcode...',
                      hintStyle: TextStyle(
                        fontFamily: 'Literata',
                        color: _mutedText,
                        fontSize: 13,
                      ),
                      filled: true,
                      fillColor: AppColors.inputFill(context),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: _borderColor),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: _borderColor),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: _primaryColor),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: _generateBarcode,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryColor,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Go',
                    style: TextStyle(
                      fontFamily: 'Literata',
                      fontWeight: FontWeight.w600,
                      color: AppTheme.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: _primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(24),
            ),
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(_primaryColor),
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Loading Products...',
            style: TextStyle(
              fontFamily: 'Literata',
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: _secondaryText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isMobile) {
    return AppTopBar(
      title: 'Barcode Generator',
      subtitle: 'Generate & print barcodes for products and batches',
      actions: [
        AppTopBar.action(icon: Icons.tune_rounded, onTap: _openBarcodeSettings),
        if (!isMobile) const SizedBox(width: 8),
        if (!isMobile)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppTopBar.chipFill(context),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTopBar.chipBorder(context)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.inventory_2_outlined,
                  size: 18,
                  color: AppTopBar.onBar(context),
                ),
                const SizedBox(width: 8),
                Text(
                  '${_products.length} Products',
                  style: TextStyle(
                    fontFamily: 'Literata',
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: AppTopBar.onBar(context),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildProductSelectionPanel() {
    return Container(
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Search Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _primaryColor.withValues(alpha: 0.04),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.search_rounded,
                      color: _primaryColor.withValues(alpha: 0.7),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Select Product',
                      style: TextStyle(
                        fontFamily: 'Literata',
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: _primaryColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _searchController,
                  onChanged: _filterProducts,
                  style: const TextStyle(fontFamily: 'Literata', fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Search by name, company or code...',
                    hintStyle: TextStyle(
                      fontFamily: 'Literata',
                      color: _mutedText,
                      fontSize: 13,
                    ),
                    prefixIcon: Icon(Icons.search, color: _mutedText, size: 20),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: Icon(
                              Icons.clear,
                              color: _mutedText,
                              size: 20,
                            ),
                            onPressed: () {
                              _searchController.clear();
                              _filterProducts('');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: AppColors.inputFill(context),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: _borderColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: _primaryColor, width: 1.5),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Product List
          Expanded(
            child: _filteredProducts.isEmpty
                ? _buildEmptyProductState()
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    itemCount: _filteredProducts.length,
                    itemBuilder: (context, index) {
                      final product = _filteredProducts[index];
                      final isSelected = _selectedProduct?.id == product.id;
                      return _buildProductCard(product, isSelected);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyProductState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.chipFill(context),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              Icons.inventory_2_outlined,
              size: 48,
              color: _mutedText,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isNotEmpty
                ? 'No products found'
                : 'No products available',
            style: TextStyle(
              fontFamily: 'Literata',
              fontWeight: FontWeight.w600,
              fontSize: 16,
              color: _secondaryText,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isNotEmpty
                ? 'Try a different search term'
                : 'Add products to generate barcodes',
            style: TextStyle(
              fontFamily: 'Literata',
              fontSize: 13,
              color: _mutedText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(ProductEntity product, bool isSelected) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: AppTheme.transparent,
        child: InkWell(
          onTap: () => _selectProduct(product),
          borderRadius: BorderRadius.circular(14),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isSelected
                  ? _primaryColor.withValues(alpha: 0.08)
                  : AppColors.scaffold(context),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isSelected ? _primaryColor : AppTheme.transparent,
                width: isSelected ? 1.5 : 0,
              ),
            ),
            child: Row(
              children: [
                // Product Code Badge
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: isSelected
                        ? LinearGradient(
                            colors: [_primaryColor, _accentColor],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                    color: isSelected ? null : AppColors.border(context),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      product.indexNo.toString(),
                      style: TextStyle(
                        fontFamily: 'Literata',
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: isSelected ? AppTheme.white : _secondaryText,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Product Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        style: TextStyle(
                          fontFamily: 'Literata',
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: isSelected ? _primaryColor : _primaryText,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (product.companyName.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          product.companyName,
                          style: TextStyle(
                            fontFamily: 'Literata',
                            fontSize: 12,
                            color: _mutedText,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                // Price & Stock
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '₹${product.salesPrice.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontFamily: 'Literata',
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: isSelected ? _primaryColor : _accentColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: product.currentStock > 0
                            ? _successColor.withValues(alpha: 0.1)
                            : _warningColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${product.currentStock} ${product.unit ?? 'pcs'}',
                        style: TextStyle(
                          fontFamily: 'Literata',
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: product.currentStock > 0
                              ? _successColor
                              : _warningColor,
                        ),
                      ),
                    ),
                  ],
                ),
                // Selection indicator
                if (isSelected) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: _primaryColor,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check,
                      size: 14,
                      color: AppTheme.white,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBarcodePanel() {
    return Container(
      margin: const EdgeInsets.fromLTRB(0, 12, 12, 12),
      child: Column(
        children: [
          // Barcode Preview Card
          Expanded(flex: 5, child: _buildBarcodePreviewCard()),
          const SizedBox(height: 12),
          // Options Card
          Expanded(flex: 4, child: _buildOptionsCard()),
        ],
      ),
    );
  }

  Widget _buildBarcodePreviewCard() {
    return Container(
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _primaryColor.withValues(alpha: 0.06),
                  _accentColor.withValues(alpha: 0.03),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.barcode_reader,
                    color: _primaryColor,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Barcode Preview',
                        style: TextStyle(
                          fontFamily: 'Literata',
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: _primaryColor,
                        ),
                      ),
                      if (_selectedProduct != null)
                        Text(
                          _selectedProduct!.name,
                          style: TextStyle(
                            fontFamily: 'Literata',
                            fontSize: 12,
                            color: _secondaryText,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                if (_generatedBarcode.isNotEmpty) ...[
                  IconButton(
                    onPressed: _copyBarcodeToClipboard,
                    icon: Icon(Icons.copy_rounded, color: _primaryColor),
                    tooltip: 'Copy barcode',
                  ),
                ],
              ],
            ),
          ),
          // Barcode Display
          Expanded(
            child: _fitPreview(
              _selectedProduct == null
                  ? _buildSelectProductPrompt()
                  : _generatedBarcode.isEmpty
                  ? _buildGenerateBarcodePrompt()
                  : ScaleTransition(
                      scale: _scaleAnimation,
                      child: _buildBarcodeDisplay(),
                    ),
            ),
          ),
          // Action Buttons
          if (_generatedBarcode.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: _buildActionButton(
                      icon: Icons.save_alt_rounded,
                      label: 'Assign to Product',
                      onTap: _assignBarcodeToProduct,
                      isPrimary: false,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildPrintButtonWithOptions(isMobile: false),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // Scales a preview down when the pane is shorter than its content, so the yellow overflow strip never appears.
  Widget _fitPreview(Widget child) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : 360.0;
        return FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.center,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: child,
          ),
        );
      },
    );
  }

  Widget _buildSelectProductPrompt() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: _primaryColor.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Icon(
            Icons.touch_app_rounded,
            size: 56,
            color: _primaryColor.withValues(alpha: 0.5),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Select a Product',
          style: TextStyle(
            fontFamily: 'Literata',
            fontWeight: FontWeight.w700,
            fontSize: 18,
            color: _primaryColor,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Choose a product from the list to generate barcode',
          style: TextStyle(
            fontFamily: 'Literata',
            fontSize: 14,
            color: _mutedText,
          ),
        ),
      ],
    );
  }

  Widget _buildGenerateBarcodePrompt() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: _accentColor.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Icon(
            Icons.barcode_reader,
            size: 56,
            color: _accentColor.withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Ready to Generate',
          style: TextStyle(
            fontFamily: 'Literata',
            fontWeight: FontWeight.w700,
            fontSize: 18,
            color: _primaryColor,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Configure options and click generate',
          style: TextStyle(
            fontFamily: 'Literata',
            fontSize: 14,
            color: _mutedText,
          ),
        ),
        const SizedBox(height: 20),
        ElevatedButton.icon(
          onPressed: _generateBarcode,
          style: ElevatedButton.styleFrom(
            backgroundColor: _primaryColor,
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            elevation: 0,
          ),
          icon: const Icon(
            Icons.auto_fix_high_rounded,
            color: AppTheme.white,
            size: 20,
          ),
          label: const Text(
            'Generate Barcode',
            style: TextStyle(
              fontFamily: 'Literata',
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: AppTheme.white,
            ),
          ),
        ),
      ],
    );
  }

  /// WYSIWYG label preview at the selected label size.
  Widget _buildLabelPreview({
    required double maxWidth,
    required double maxHeight,
  }) {
    final content = _currentLabelContent();
    final layout = _currentLabelLayout(content);
    return BarcodeLabelPreview(
      layout: layout,
      content: content,
      maxWidth: maxWidth,
      maxHeight: maxHeight,
      barcodeBuilder: (w, h) => _buildSafeBarcodeWidget(
        data: content.code,
        format: content.format,
        width: w,
        height: h,
      ),
    );
  }

  Widget _infoChip(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              text,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'Literata',
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Format, label size and printer chips shown under the preview.
  Widget _buildLabelInfoChips() {
    final s = _labelSettings;
    final l = _l;
    final layout = _currentLabelLayout();
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 8,
      runSpacing: 6,
      children: [
        _infoChip(
          Icons.qr_code_2_rounded,
          _selectedFormat.displayName,
          _accentColor,
        ),
        _infoChip(
          Icons.straighten_rounded,
          formatSizeMm(s.widthMm, s.heightMm),
          _primaryColor,
        ),
        _infoChip(
          printerTypeIcon(s.printerType),
          printerTypeName(l, s.printerType),
          _primaryColor,
        ),
        if (layout.barcodeTooNarrow)
          _infoChip(
            Icons.warning_amber_rounded,
            l.labelTooNarrowWarning,
            _warningColor,
          ),
      ],
    );
  }

  Widget _buildBarcodeDisplay() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            key: _barcodeKey,
            child: _buildLabelPreview(maxWidth: 300, maxHeight: 220),
          ),
          const SizedBox(height: 14),
          _buildLabelInfoChips(),
        ],
      ),
    );
  }

  /// Card in the options panel: current printer + label size with a shortcut
  /// to Barcode Settings.
  Widget _buildPrintSetupSummary() {
    final s = _labelSettings;
    final l = _l;
    final sizeLabel = s.isCustom
        ? l.sizeCustomLabel
        : presetName(l, s.presetId);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
      decoration: BoxDecoration(
        color: _primaryColor.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _primaryColor.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(printerTypeIcon(s.printerType), color: _primaryColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l.printingOn,
                  style: TextStyle(
                    fontFamily: 'Literata',
                    fontSize: 11,
                    color: _secondaryText,
                  ),
                ),
                Text(
                  '${printerTypeName(l, s.printerType)} · $sizeLabel '
                  '${formatSizeMm(s.widthMm, s.heightMm)}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Literata',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _primaryText,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: _openBarcodeSettings,
            child: Text(l.changeLabelSettings),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionsCard() {
    return Container(
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _accentColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.tune_rounded,
                    color: _accentColor,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'Barcode Options',
                  style: TextStyle(
                    fontFamily: 'Literata',
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: _primaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Format Selection
            Text(
              'Barcode Format',
              style: TextStyle(
                fontFamily: 'Literata',
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: _primaryColor,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: BarcodeFormat.values.map((format) {
                final isSelected = _selectedFormat == format;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  child: Material(
                    color: AppTheme.transparent,
                    child: InkWell(
                      onTap: () {
                        if (_selectedFormat != format) {
                          setState(() {
                            _selectedFormat = format;
                            // Clear barcode when format changes - will regenerate if product selected
                            _generatedBarcode = '';
                          });
                          // Defer barcode generation to next frame to prevent UI hang
                          if (_selectedProduct != null) {
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (mounted) _generateBarcode();
                            });
                          }
                        }
                      },
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? _primaryColor
                              : AppColors.chipFill(context),
                          borderRadius: BorderRadius.circular(10),
                          border: isSelected
                              ? null
                              : Border.all(color: _borderColor),
                        ),
                        child: Text(
                          format.code,
                          style: TextStyle(
                            fontFamily: 'Literata',
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isSelected ? AppTheme.white : _secondaryText,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 16),

            // Batch Selection (if available)
            if (_productBatches.isNotEmpty) ...[
              Text(
                'Select Batch',
                style: TextStyle(
                  fontFamily: 'Literata',
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: _primaryColor,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: AppColors.scaffold(context),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _borderColor),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<PurchaseBatchEntity>(
                    value: _selectedBatch,
                    isExpanded: true,
                    hint: const Text(
                      'Select batch',
                      style: TextStyle(fontFamily: 'Literata', fontSize: 13),
                    ),
                    items: _productBatches.map((batch) {
                      return DropdownMenuItem(
                        value: batch,
                        child: Text(
                          'Batch #${batch.id} - ₹${batch.sellingPrice.toStringAsFixed(0)} (${batch.quantityRemaining} left)',
                          style: const TextStyle(
                            fontFamily: 'Literata',
                            fontSize: 13,
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: (batch) {
                      setState(() => _selectedBatch = batch);
                      if (_autoGenerate) _generateBarcode();
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            _buildPrintSetupSummary(),
            // Toggle Options
            _buildToggleOption(
              'Auto-generate barcode',
              'Automatically create barcode when selecting product',
              _autoGenerate,
              (value) {
                setState(() => _autoGenerate = value);
                if (value && _selectedProduct != null) _generateBarcode();
              },
            ),
            _buildToggleOption(
              'Include price',
              'Show price on the barcode label',
              _includePrice,
              _setIncludePrice,
            ),
            _buildToggleOption(
              'Include company',
              'Show company name on the label',
              _includeCompany,
              _setIncludeCompany,
            ),

            const SizedBox(height: 16),

            // Print Quantity
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Print Quantity',
                        style: TextStyle(
                          fontFamily: 'Literata',
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: _primaryColor,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Number of labels to print',
                        style: TextStyle(
                          fontFamily: 'Literata',
                          fontSize: 11,
                          color: _mutedText,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 100,
                  decoration: BoxDecoration(
                    color: AppColors.scaffold(context),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _borderColor),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () {
                          final current =
                              int.tryParse(_quantityController.text) ?? 1;
                          if (current > 1) {
                            _quantityController.text = (current - 1).toString();
                          }
                        },
                        icon: const Icon(Icons.remove, size: 18),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 30,
                          minHeight: 36,
                        ),
                      ),
                      Expanded(
                        child: TextField(
                          controller: _quantityController,
                          textAlign: TextAlign.center,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(
                            fontFamily: 'Literata',
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          final current =
                              int.tryParse(_quantityController.text) ?? 1;
                          _quantityController.text = (current + 1).toString();
                        },
                        icon: const Icon(Icons.add, size: 18),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 30,
                          minHeight: 36,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Custom Barcode Input (when auto-generate is off)
            if (!_autoGenerate) ...[
              const SizedBox(height: 16),
              Text(
                'Custom Barcode',
                style: TextStyle(
                  fontFamily: 'Literata',
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: _primaryColor,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _customBarcodeController,
                      style: TextStyle(
                        fontFamily: 'Literata',
                        fontSize: 14,
                        letterSpacing: 1,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Enter custom barcode...',
                        hintStyle: TextStyle(
                          fontFamily: 'Literata',
                          color: _mutedText,
                          fontSize: 13,
                        ),
                        filled: true,
                        fillColor: AppColors.inputFill(context),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: _borderColor),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: _borderColor),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: _primaryColor),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: _generateBarcode,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primaryColor,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Generate',
                      style: TextStyle(
                        fontFamily: 'Literata',
                        fontWeight: FontWeight.w600,
                        color: AppTheme.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildToggleOption(
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Literata',
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                    color: AppTheme.paletteFF333333,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontFamily: 'Literata',
                    fontSize: 11,
                    color: _mutedText,
                  ),
                ),
              ],
            ),
          ),
          Transform.scale(
            scale: 0.85,
            child: Switch(
              value: value,
              onChanged: onChanged,
              activeThumbColor: _primaryColor,
              activeTrackColor: _primaryColor.withValues(alpha: 0.3),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required bool isPrimary,
  }) {
    return Material(
      color: AppTheme.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            gradient: isPrimary
                ? LinearGradient(
                    colors: [_primaryColor, _accentColor],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: isPrimary ? null : _primaryColor.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
            border: isPrimary
                ? null
                : Border.all(color: _primaryColor.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 20,
                color: isPrimary ? AppTheme.white : _primaryColor,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Literata',
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: isPrimary ? AppTheme.white : _primaryColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Build print button with popup menu for PDF and POS options
  Widget _buildPrintButtonWithOptions({required bool isMobile}) {
    return GestureDetector(
      onTap: _showBarcodePreviewSheet,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [_primaryColor, _accentColor],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.visibility_rounded,
              size: 20,
              color: AppTheme.white,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                isMobile ? 'Preview' : 'Preview & Print',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'Literata',
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: AppTheme.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Show barcode preview bottom sheet with share and print options
  void _showBarcodePreviewSheet() {
    if (_generatedBarcode.isEmpty || _selectedProduct == null) return;

    final quantity = _copies;

    showAppBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.transparent,
      builder: (context) => GlassDraggableSheet(
        initialChildSize: 0.72,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        builder: (_, controller) => Column(
          children: [
            const GlassSheetHandle(),
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [_primaryColor, _accentColor],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.barcode_reader,
                      color: AppTheme.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Barcode Preview',
                          style: TextStyle(
                            fontFamily: 'Literata',
                            fontWeight: FontWeight.w700,
                            fontSize: 18,
                            color: _primaryColor,
                          ),
                        ),
                        Text(
                          'Qty: $quantity label${quantity > 1 ? 's' : ''}',
                          style: TextStyle(
                            fontFamily: 'Literata',
                            fontSize: 13,
                            color: _secondaryText,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close_rounded),
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.chipFill(context),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                controller: controller,
                child: Column(
                  children: [
                    // Label preview at the selected size
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: AppColors.chipFill(context),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: _borderColor),
                      ),
                      child: Column(
                        children: [
                          _buildLabelPreview(maxWidth: 300, maxHeight: 240),
                          const SizedBox(height: 14),
                          _buildLabelInfoChips(),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Action Buttons
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        children: [..._buildPrintActionButtons(context)],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Three print actions (default printer first, with a badge) + share.
  List<Widget> _buildPrintActionButtons(BuildContext sheetContext) {
    final s = _labelSettings;
    final l = _l;
    final grid = computeSheetGrid(
      labelWidthMm: s.widthMm,
      labelHeightMm: s.heightMm,
    );
    final size = formatSizeMm(s.widthMm, s.heightMm);

    Widget action(BarcodePrinterType t) {
      late final String label;
      late final String subtitle;
      late final Color color;
      late final VoidCallback run;
      switch (t) {
        case BarcodePrinterType.normal:
          label = l.printOnNormalPrinter;
          subtitle = '$size · ${grid.perPage} ${l.labelsPerSheetSuffix}';
          color = _primaryColor;
          run = _printBarcode;
        case BarcodePrinterType.label:
          label = l.printOnBarcodePrinter;
          subtitle =
              '$size · ${s.connection == LabelConnection.bluetooth ? l.connViaBluetooth : l.connViaDriver}';
          color = AppTheme.indigo400;
          run = _printBarcodeLabel;
        case BarcodePrinterType.pos:
          label = l.printOnPosPrinter;
          subtitle = _printerService.isConnected
              ? 'Connected: ${_printerService.connectedPrinter?.name ?? "Printer"}'
              : 'Tap to connect thermal printer';
          color = _accentColor;
          run = _printBarcodePos;
      }
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: _buildPreviewActionButton(
          icon: printerTypeIcon(t),
          label: label,
          subtitle: subtitle,
          color: color,
          badge: s.printerType == t ? l.defaultBadge : null,
          onTap: () {
            Navigator.pop(sheetContext);
            run();
          },
        ),
      );
    }

    final order = <BarcodePrinterType>[
      s.printerType,
      ...BarcodePrinterType.values.where((t) => t != s.printerType),
    ];
    return [
      for (final t in order) action(t),
      _buildPreviewActionButton(
        icon: Icons.share_rounded,
        label: l.shareLabelsPdf,
        subtitle: 'PDF',
        color: AppTheme.orange400,
        onTap: () {
          Navigator.pop(sheetContext);
          _shareBarcode();
        },
      ),
    ];
  }

  Widget _buildPreviewActionButton({
    required IconData icon,
    required String label,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
    String? badge,
  }) {
    return Material(
      color: AppTheme.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            label,
                            style: TextStyle(
                              fontFamily: 'Literata',
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                              color: color,
                            ),
                          ),
                        ),
                        if (badge != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              badge,
                              style: const TextStyle(
                                fontFamily: 'Literata',
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.white,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontFamily: 'Literata',
                        fontSize: 12,
                        color: _secondaryText,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded, color: color, size: 18),
            ],
          ),
        ),
      ),
    );
  }

  // Share barcode as PDF
  Future<void> _shareBarcode() async {
    if (_generatedBarcode.isEmpty) return;

    try {
      final pdfBytes = await _generateBarcodePdf(_copies);

      // Save to temp file
      final tempDir = await getTemporaryDirectory();
      final fileName =
          'Barcode_${_selectedProduct?.name ?? 'Label'}_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final file = File('${tempDir.path}/$fileName');
      await file.writeAsBytes(pdfBytes);

      // Share
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Barcode for ${_selectedProduct?.name ?? 'Product'}',
        subject: 'Barcode Label',
      );
    } catch (e) {
      _showSnackBar('Error sharing barcode: $e', isError: true);
    }
  }
}

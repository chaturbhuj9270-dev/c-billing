import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/services/barcode_service.dart';
import '../../../../core/services/language_service.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/printing/services/pos_printer_service.dart';
import '../../../../core/printing/formatters/esc_pos_bill_formatter.dart';
import '../../../../common_widgets/printer_selection_widget.dart';
import '../../../product/offline/controllers/product_offline_controller.dart';
import '../../../product/offline/entities/product_entity.dart';
import '../../offline/controllers/purchase_batch_offline_controller.dart';
import '../../offline/entities/purchase_batch_entity.dart';

class BarcodeGeneratorPage extends StatefulWidget {
  const BarcodeGeneratorPage({super.key});

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
  BarcodeFormat _selectedFormat = BarcodeFormat.code128;
  String _generatedBarcode = '';
  bool _includePrice = true;
  bool _includeCompany = true;
  bool _autoGenerate = true;

  // Controllers
  final _searchController = TextEditingController();
  final _customBarcodeController = TextEditingController();
  final _quantityController = TextEditingController(text: '1');
  final _barcodeKey = GlobalKey();
  final _printerService = PosPrinterService();

  // Localization (for future i18n support)
  // ignore: unused_field
  late AppLocalizations _localizations;

  // Theme colors
  static const Color _primaryColor = Color(0xFF1B4D3E);
  static const Color _accentColor = Color(0xFF2E7D5A);
  static const Color _backgroundColor = Color(0xFFF5F7F6);
  static const Color _cardColor = Colors.white;
  static const Color _successColor = Color(0xFF4CAF50);
  static const Color _warningColor = Color(0xFFFFA726);

  @override
  void initState() {
    super.initState();
    _localizations = AppLocalizations.of(
      LanguageService.instance.currentLanguage,
    );

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

    _loadProducts();
  }

  @override
  void dispose() {
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
      if (MediaQuery.of(context).size.width < 600) {
        _tabController.animateTo(1);
      }
    } catch (e) {
      _showSnackBar('Error loading batches: $e', isError: true);
    }
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

  Future<void> _printBarcode() async {
    if (_generatedBarcode.isEmpty) return;

    final quantity = int.tryParse(_quantityController.text) ?? 1;

    try {
      await Printing.layoutPdf(
        onLayout: (format) => _generateBarcodePdf(quantity),
        name: 'Barcode_${_selectedProduct?.name ?? 'Label'}',
      );
    } catch (e) {
      _showSnackBar('Error printing barcode: $e', isError: true);
    }
  }

  /// Print barcode using POS thermal printer
  Future<void> _printBarcodePos() async {
    if (_generatedBarcode.isEmpty) return;

    // Check if printer is connected
    if (!_printerService.isConnected) {
      // Show printer selection dialog
      final selectedPrinter = await PrinterSelectionWidget.show(context);
      if (selectedPrinter == null) {
        _showSnackBar('No printer selected', isError: true);
        return;
      }
    }

    final quantity = int.tryParse(_quantityController.text) ?? 1;

    try {
      // Generate barcode label bytes
      final bytes = _generateBarcodeLabelBytes(quantity);

      // Print using POS printer
      final result = await _printerService.printRaw(bytes);

      if (result.success) {
        _showSnackBar('Barcode printed successfully!', isError: false);
      } else {
        _showSnackBar(result.message ?? 'Print failed', isError: true);
      }
    } catch (e) {
      _showSnackBar('Error printing barcode: $e', isError: true);
    }
  }

  /// Generate ESC/POS bytes for barcode label
  List<int> _generateBarcodeLabelBytes(int quantity) {
    final bytes = <int>[];

    // Initialize printer
    bytes.addAll(EscPosCommands.init);
    bytes.addAll(EscPosCommands.setLineSpacing(26)); // Tighter line spacing

    for (int i = 0; i < quantity; i++) {
      // Center align
      bytes.addAll(EscPosCommands.alignCenter);

      // TOP LINE: Product Name | Rs.Price | Batch (all in one line, normal size)
      bytes.addAll(EscPosCommands.textNormal);
      bytes.addAll(EscPosCommands.boldOn);
      final topLine = _buildTopLine();
      bytes.addAll(topLine.codeUnits);
      bytes.addAll(EscPosCommands.boldOff);
      bytes.addAll(EscPosCommands.lineFeed);

      // Barcode settings
      bytes.addAll(EscPosCommands.setBarcodeHeight(50)); // Slightly smaller
      bytes.addAll(
        EscPosCommands.setBarcodeWidth(2),
      ); // Narrower for more chars
      bytes.addAll(EscPosCommands.setHRIPosition(2)); // Print below barcode
      bytes.addAll(EscPosCommands.setHRIFont(1)); // Font B (smaller)

      // Print barcode based on format
      switch (_selectedFormat) {
        case BarcodeFormat.code128:
          bytes.addAll(EscPosCommands.printCode128(_generatedBarcode));
          break;
        case BarcodeFormat.code39:
          bytes.addAll(EscPosCommands.printCode39(_generatedBarcode));
          break;
        case BarcodeFormat.ean13:
          bytes.addAll(EscPosCommands.printEAN13(_generatedBarcode));
          break;
        case BarcodeFormat.ean8:
          bytes.addAll(EscPosCommands.printEAN8(_generatedBarcode));
          break;
        case BarcodeFormat.upcA:
          bytes.addAll(EscPosCommands.printUPCA(_generatedBarcode));
          break;
        case BarcodeFormat.qrCode:
          bytes.addAll(
            EscPosCommands.printQRCode(_generatedBarcode, moduleSize: 5),
          );
          break;
      }

      bytes.addAll(EscPosCommands.lineFeed);

      // Add spacing between labels
      bytes.addAll(EscPosCommands.feedLines(2));

      // Separator line between multiple labels
      if (i < quantity - 1) {
        bytes.addAll('--------------------------------'.codeUnits);
        bytes.addAll(EscPosCommands.lineFeed);
        bytes.addAll(EscPosCommands.feedLines(1));
      }
    }

    // Final feed
    bytes.addAll(EscPosCommands.feedLines(3));

    return bytes;
  }

  /// Build top line: Product Name | Rs.Price | Batch (single line)
  String _buildTopLine() {
    final parts = <String>[];

    // Product name (truncate to fit in line)
    final productName = _selectedProduct?.name ?? '';
    parts.add(
      productName.length > 16 ? productName.substring(0, 16) : productName,
    );

    // Price
    if (_includePrice) {
      final price =
          _selectedBatch?.sellingPrice ?? _selectedProduct?.salesPrice ?? 0;
      parts.add('Rs.${price.toStringAsFixed(0)}');
    }

    // Batch
    if (_selectedBatch != null) {
      parts.add('B#${_selectedBatch!.id}');
    }

    return parts.join('|');
  }

  Future<Uint8List> _generateBarcodePdf(int quantity) async {
    final pdf = pw.Document();
    final barcode = BarcodeService.instance.getBarcodeRenderer(_selectedFormat);

    // Create barcode widgets
    final barcodeWidgets = <pw.Widget>[];

    for (int i = 0; i < quantity; i++) {
      barcodeWidgets.add(
        pw.Container(
          width: 60 * PdfPageFormat.mm,
          height: 35 * PdfPageFormat.mm, // Slightly smaller height
          padding: const pw.EdgeInsets.all(3),
          child: pw.Column(
            mainAxisAlignment: pw.MainAxisAlignment.center,
            children: [
              // TOP LINE: Product Name | Rs.Price | Batch (single line, smaller font)
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.center,
                children: [
                  pw.Flexible(
                    child: pw.Text(
                      (_selectedProduct?.name ?? '').length > 18
                          ? (_selectedProduct?.name ?? '').substring(0, 18)
                          : (_selectedProduct?.name ?? ''),
                      style: pw.TextStyle(
                        fontSize: 7,
                        fontWeight: pw.FontWeight.bold,
                      ),
                      maxLines: 1,
                    ),
                  ),
                  if (_includePrice) ...[
                    pw.Text('|', style: const pw.TextStyle(fontSize: 6)),
                    pw.Text(
                      'Rs.${(_selectedBatch?.sellingPrice ?? _selectedProduct?.salesPrice ?? 0).toStringAsFixed(0)}',
                      style: pw.TextStyle(
                        fontSize: 7,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                  if (_selectedBatch != null) ...[
                    pw.Text('|', style: const pw.TextStyle(fontSize: 6)),
                    pw.Text(
                      'B#${_selectedBatch!.id}',
                      style: const pw.TextStyle(fontSize: 6),
                    ),
                  ],
                ],
              ),
              pw.SizedBox(height: 2),
              // BARCODE
              pw.BarcodeWidget(
                barcode: barcode,
                data: _generatedBarcode,
                width: 50 * PdfPageFormat.mm,
                height: 14 * PdfPageFormat.mm,
                drawText: true,
                textStyle: const pw.TextStyle(fontSize: 7),
              ),
            ],
          ),
        ),
      );
    }

    // Layout barcodes in a grid (3 columns)
    final rows = <pw.TableRow>[];
    for (int i = 0; i < barcodeWidgets.length; i += 3) {
      final rowWidgets = <pw.Widget>[];
      for (int j = 0; j < 3 && (i + j) < barcodeWidgets.length; j++) {
        rowWidgets.add(barcodeWidgets[i + j]);
      }
      // Fill empty cells
      while (rowWidgets.length < 3) {
        rowWidgets.add(pw.SizedBox(width: 60 * PdfPageFormat.mm));
      }
      rows.add(pw.TableRow(children: rowWidgets));
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(10 * PdfPageFormat.mm),
        build: (context) => [pw.Table(children: rows)],
      ),
    );

    return pdf.save();
  }

  void _copyBarcodeToClipboard() {
    if (_generatedBarcode.isEmpty) return;

    Clipboard.setData(ClipboardData(text: _generatedBarcode));
    _showSnackBar('Barcode copied to clipboard!', isError: false);
  }

  void _showSnackBar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isError ? Colors.red.shade600 : _successColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Scaffold(
      backgroundColor: _backgroundColor,
      body: SafeArea(
        child: _isLoading
            ? _buildLoadingState()
            : FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Column(
                    children: [
                      _buildHeader(isMobile),
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
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: _primaryColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: _primaryColor,
          borderRadius: BorderRadius.circular(10),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: Colors.white,
        unselectedLabelColor: _primaryColor,
        labelStyle: const TextStyle(
          fontFamily: 'Literata',
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
        unselectedLabelStyle: const TextStyle(
          fontFamily: 'Literata',
          fontWeight: FontWeight.w500,
          fontSize: 14,
        ),
        dividerColor: Colors.transparent,
        padding: const EdgeInsets.all(4),
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
                const Icon(Icons.qr_code_2_rounded, size: 18),
                const SizedBox(width: 8),
                const Text('Barcode'),
              ],
            ),
          ),
        ],
      ),
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
            color: Colors.black.withOpacity(0.04),
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
                  color: Colors.grey[400],
                  fontSize: 13,
                ),
                prefixIcon: Icon(
                  Icons.search,
                  color: Colors.grey[400],
                  size: 20,
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: Icon(
                          Icons.clear,
                          color: Colors.grey[400],
                          size: 20,
                        ),
                        onPressed: () {
                          _searchController.clear();
                          _filterProducts('');
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.grey[50],
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
                  borderSide: const BorderSide(
                    color: _primaryColor,
                    width: 1.5,
                  ),
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
            color: Colors.black.withOpacity(0.04),
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
                  _primaryColor.withOpacity(0.08),
                  _accentColor.withOpacity(0.04),
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
                    color: _primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.qr_code_scanner_rounded,
                    color: _primaryColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
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
                            color: Colors.grey[600],
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
                    icon: const Icon(
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
            color: Colors.black.withOpacity(0.04),
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
                  color: _accentColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.tune_rounded,
                  color: _accentColor,
                  size: 16,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
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
          const Text(
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
                  setState(() => _selectedFormat = format);
                  if (_autoGenerate && _selectedProduct != null) {
                    _generateBarcode();
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected ? _primaryColor : Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                    border: isSelected
                        ? null
                        : Border.all(color: Colors.grey.shade300),
                  ),
                  child: Text(
                    format.code,
                    style: TextStyle(
                      fontFamily: 'Literata',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white : Colors.grey[700],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 16),

          // Batch Selection (if available)
          if (_productBatches.isNotEmpty) ...[
            const Text(
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
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade200),
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
            (value) => setState(() => _includePrice = value),
          ),
          _buildToggleOption(
            'Include company',
            'Show company name',
            _includeCompany,
            (value) => setState(() => _includeCompany = value),
          ),

          const SizedBox(height: 16),

          // Print Quantity
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
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
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade200),
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
            const Text(
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
                    style: const TextStyle(
                      fontFamily: 'Literata',
                      fontSize: 14,
                      letterSpacing: 1,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Enter barcode...',
                      hintStyle: TextStyle(
                        fontFamily: 'Literata',
                        color: Colors.grey[400],
                        fontSize: 13,
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.grey.shade200),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.grey.shade200),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: _primaryColor),
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
                      color: Colors.white,
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
              color: _primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const CircularProgressIndicator(
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
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isMobile) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        isMobile ? 12 : 16,
        12,
        isMobile ? 12 : 16,
        12,
      ),
      decoration: BoxDecoration(
        color: _cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Back button
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: EdgeInsets.all(isMobile ? 8 : 10),
              decoration: BoxDecoration(
                color: _primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(isMobile ? 10 : 12),
              ),
              child: Icon(
                Icons.arrow_back_ios_rounded,
                size: isMobile ? 18 : 20,
                color: _primaryColor,
              ),
            ),
          ),
          SizedBox(width: isMobile ? 12 : 16),
          // Title and subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(isMobile ? 6 : 8),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [_primaryColor, _accentColor],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(isMobile ? 8 : 10),
                      ),
                      child: Icon(
                        Icons.qr_code_2_rounded,
                        size: isMobile ? 18 : 22,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Barcode Generator',
                        style: TextStyle(
                          fontFamily: 'Literata',
                          fontWeight: FontWeight.w800,
                          fontSize: isMobile ? 16 : 22,
                          color: _primaryColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                if (!isMobile) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Generate & print barcodes for products and batches',
                    style: TextStyle(
                      fontFamily: 'Literata',
                      fontWeight: FontWeight.w400,
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ],
            ),
          ),
          // Quick Stats - only for tablet/desktop
          if (!isMobile)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: _primaryColor.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.inventory_2_outlined,
                    size: 18,
                    color: _primaryColor,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${_products.length} Products',
                    style: const TextStyle(
                      fontFamily: 'Literata',
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: _primaryColor,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
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
            color: Colors.black.withOpacity(0.04),
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
              color: _primaryColor.withOpacity(0.04),
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
                      color: _primaryColor.withOpacity(0.7),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    const Text(
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
                      color: Colors.grey[400],
                      fontSize: 13,
                    ),
                    prefixIcon: Icon(
                      Icons.search,
                      color: Colors.grey[400],
                      size: 20,
                    ),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: Icon(
                              Icons.clear,
                              color: Colors.grey[400],
                              size: 20,
                            ),
                            onPressed: () {
                              _searchController.clear();
                              _filterProducts('');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.white,
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
                      borderSide: BorderSide(color: Colors.grey.shade200),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: _primaryColor,
                        width: 1.5,
                      ),
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
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              Icons.inventory_2_outlined,
              size: 48,
              color: Colors.grey[400],
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
              color: Colors.grey[600],
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
              color: Colors.grey[500],
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
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _selectProduct(product),
          borderRadius: BorderRadius.circular(14),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isSelected
                  ? _primaryColor.withOpacity(0.08)
                  : Colors.grey[50],
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isSelected ? _primaryColor : Colors.transparent,
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
                        ? const LinearGradient(
                            colors: [_primaryColor, _accentColor],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                    color: isSelected ? null : Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      product.indexNo.toString(),
                      style: TextStyle(
                        fontFamily: 'Literata',
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: isSelected ? Colors.white : Colors.grey[600],
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
                          color: isSelected ? _primaryColor : Colors.grey[800],
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
                            color: Colors.grey[500],
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
                            ? _successColor.withOpacity(0.1)
                            : _warningColor.withOpacity(0.1),
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
                    decoration: const BoxDecoration(
                      color: _primaryColor,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check,
                      size: 14,
                      color: Colors.white,
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
            color: Colors.black.withOpacity(0.04),
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
                  _primaryColor.withOpacity(0.06),
                  _accentColor.withOpacity(0.03),
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
                    color: _primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.qr_code_scanner_rounded,
                    color: _primaryColor,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
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
                            color: Colors.grey[600],
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
                    icon: const Icon(Icons.copy_rounded, color: _primaryColor),
                    tooltip: 'Copy barcode',
                  ),
                ],
              ],
            ),
          ),
          // Barcode Display
          Expanded(
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

  Widget _buildSelectProductPrompt() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: _primaryColor.withOpacity(0.06),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(
              Icons.touch_app_rounded,
              size: 56,
              color: _primaryColor.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
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
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGenerateBarcodePrompt() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: _accentColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(
              Icons.qr_code_2_rounded,
              size: 56,
              color: _accentColor.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
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
              color: Colors.grey[500],
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
              color: Colors.white,
              size: 20,
            ),
            label: const Text(
              'Generate Barcode',
              style: TextStyle(
                fontFamily: 'Literata',
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBarcodeDisplay() {
    // Build top line info: Product Name | Rs.Price | Batch
    final topLineInfo = _buildPreviewTopLine();

    return Container(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Barcode Label Card
            Container(
              key: _barcodeKey,
              padding: const EdgeInsets.all(16),
              constraints: const BoxConstraints(maxWidth: 280),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 15,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // TOP LINE: Product Name | Rs.Price | Batch (single line)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _primaryColor.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      topLineInfo,
                      style: const TextStyle(
                        fontFamily: 'Literata',
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                        color: _primaryColor,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Barcode SVG
                  SizedBox(
                    width: 200,
                    height: 70,
                    child: CustomPaint(
                      painter: BarcodePainter(
                        data: _generatedBarcode,
                        format: _selectedFormat,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Barcode text
                  Text(
                    _generatedBarcode,
                    style: const TextStyle(
                      fontFamily: 'Literata',
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Format badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: _accentColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                _selectedFormat.displayName,
                style: const TextStyle(
                  fontFamily: 'Literata',
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: _accentColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build preview top line: Product Name | Rs.Price | Batch
  String _buildPreviewTopLine() {
    final parts = <String>[];

    // Product name (truncate to fit)
    final productName = _selectedProduct?.name ?? '';
    final truncatedName = productName.length > 18
        ? productName.substring(0, 18)
        : productName;
    parts.add(truncatedName);

    // Price
    if (_includePrice) {
      final price =
          _selectedBatch?.sellingPrice ?? _selectedProduct?.salesPrice ?? 0;
      parts.add('Rs.${price.toStringAsFixed(0)}');
    }

    // Batch
    if (_selectedBatch != null) {
      parts.add('B#${_selectedBatch!.id}');
    }

    return parts.join(' | ');
  }

  Widget _buildOptionsCard() {
    return Container(
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
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
                    color: _accentColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.tune_rounded,
                    color: _accentColor,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                const Text(
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
            const Text(
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
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        setState(() => _selectedFormat = format);
                        if (_autoGenerate && _selectedProduct != null) {
                          _generateBarcode();
                        }
                      },
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected ? _primaryColor : Colors.grey[100],
                          borderRadius: BorderRadius.circular(10),
                          border: isSelected
                              ? null
                              : Border.all(color: Colors.grey.shade300),
                        ),
                        child: Text(
                          format.code,
                          style: TextStyle(
                            fontFamily: 'Literata',
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isSelected ? Colors.white : Colors.grey[700],
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
              const Text(
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
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
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
              (value) => setState(() => _includePrice = value),
            ),
            _buildToggleOption(
              'Include company',
              'Show company name on the label',
              _includeCompany,
              (value) => setState(() => _includeCompany = value),
            ),

            const SizedBox(height: 16),

            // Print Quantity
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Print Quantity',
                        style: TextStyle(
                          fontFamily: 'Literata',
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: _primaryColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Number of labels to print',
                        style: TextStyle(
                          fontFamily: 'Literata',
                          fontSize: 11,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 100,
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.shade200),
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
              const Text(
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
                      style: const TextStyle(
                        fontFamily: 'Literata',
                        fontSize: 14,
                        letterSpacing: 1,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Enter custom barcode...',
                        hintStyle: TextStyle(
                          fontFamily: 'Literata',
                          color: Colors.grey[400],
                          fontSize: 13,
                        ),
                        filled: true,
                        fillColor: Colors.grey[50],
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: Colors.grey.shade200),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: Colors.grey.shade200),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: _primaryColor),
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
                        color: Colors.white,
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
                    color: Color(0xFF333333),
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontFamily: 'Literata',
                    fontSize: 11,
                    color: Colors.grey[500],
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
              activeColor: _primaryColor,
              activeTrackColor: _primaryColor.withOpacity(0.3),
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
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            gradient: isPrimary
                ? const LinearGradient(
                    colors: [_primaryColor, _accentColor],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: isPrimary ? null : _primaryColor.withOpacity(0.08),
            borderRadius: BorderRadius.circular(14),
            border: isPrimary
                ? null
                : Border.all(color: _primaryColor.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 20,
                color: isPrimary ? Colors.white : _primaryColor,
              ),
              const SizedBox(width: 10),
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Literata',
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: isPrimary ? Colors.white : _primaryColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build print button with popup menu for PDF and POS options
  Widget _buildPrintButtonWithOptions({required bool isMobile}) {
    return GestureDetector(
      onTap: _showBarcodePreviewSheet,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [_primaryColor, _accentColor],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.visibility_rounded, size: 20, color: Colors.white),
            const SizedBox(width: 10),
            Text(
              isMobile ? 'Preview' : 'Preview & Print',
              style: const TextStyle(
                fontFamily: 'Literata',
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Show barcode preview bottom sheet with share and print options
  void _showBarcodePreviewSheet() {
    if (_generatedBarcode.isEmpty || _selectedProduct == null) return;

    final quantity = int.tryParse(_quantityController.text) ?? 1;
    final topLineInfo = _buildPreviewTopLine();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12),
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
                      gradient: const LinearGradient(
                        colors: [_primaryColor, _accentColor],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.qr_code_2_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
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
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.grey[100],
                    ),
                  ),
                ],
              ),
            ),
            // Barcode Preview Card
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Top line info
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: _primaryColor.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      topLineInfo,
                      style: const TextStyle(
                        fontFamily: 'Literata',
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                        color: _primaryColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Barcode
                  SizedBox(
                    width: 240,
                    height: 80,
                    child: CustomPaint(
                      painter: BarcodePainter(
                        data: _generatedBarcode,
                        format: _selectedFormat,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Barcode number
                  Text(
                    _generatedBarcode,
                    style: const TextStyle(
                      fontFamily: 'Literata',
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Format badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _accentColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _selectedFormat.displayName,
                      style: const TextStyle(
                        fontFamily: 'Literata',
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: _accentColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Action Buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  // Share Button
                  _buildPreviewActionButton(
                    icon: Icons.share_rounded,
                    label: 'Share Barcode',
                    subtitle: 'Share as PDF image',
                    color: const Color(0xFF5C6BC0),
                    onTap: () {
                      Navigator.pop(context);
                      _shareBarcode();
                    },
                  ),
                  const SizedBox(height: 12),
                  // Print PDF Button
                  _buildPreviewActionButton(
                    icon: Icons.picture_as_pdf_rounded,
                    label: 'Print as PDF',
                    subtitle: 'Standard paper printer',
                    color: _primaryColor,
                    onTap: () {
                      Navigator.pop(context);
                      _printBarcode();
                    },
                  ),
                  const SizedBox(height: 12),
                  // Print POS Button
                  _buildPreviewActionButton(
                    icon: Icons.receipt_long_rounded,
                    label: 'Print on POS',
                    subtitle: _printerService.isConnected
                        ? 'Connected: ${_printerService.connectedPrinter?.name ?? "Printer"}'
                        : 'Tap to connect thermal printer',
                    color: _accentColor,
                    onTap: () {
                      Navigator.pop(context);
                      _printBarcodePos();
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewActionButton({
    required IconData icon,
    required String label,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontFamily: 'Literata',
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: color,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontFamily: 'Literata',
                        fontSize: 12,
                        color: Colors.grey[600],
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

  /// Share barcode as PDF
  Future<void> _shareBarcode() async {
    if (_generatedBarcode.isEmpty) return;

    try {
      final quantity = int.tryParse(_quantityController.text) ?? 1;
      final pdfBytes = await _generateBarcodePdf(quantity);

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

/// Custom painter for rendering barcode
class BarcodePainter extends CustomPainter {
  final String data;
  final BarcodeFormat format;

  BarcodePainter({required this.data, required this.format});

  @override
  void paint(Canvas canvas, Size size) {
    try {
      final barcode = BarcodeService.instance.getBarcodeRenderer(format);
      final svg = barcode.toSvg(
        data,
        width: size.width,
        height: size.height,
        drawText: false,
      );

      final paint = Paint()
        ..color = Colors.black
        ..style = PaintingStyle.fill;

      // Draw barcode bars from SVG
      _drawBarcodeFromSvg(canvas, size, svg, paint);
    } catch (e) {
      // Draw error placeholder with icon
      final paint = Paint()
        ..color = Colors.red.withOpacity(0.1)
        ..style = PaintingStyle.fill;
      canvas.drawRect(Offset.zero & size, paint);

      // Draw error text
      final textPainter = TextPainter(
        text: TextSpan(
          text: 'Invalid barcode',
          style: TextStyle(color: Colors.red.shade300, fontSize: 10),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(
          (size.width - textPainter.width) / 2,
          (size.height - textPainter.height) / 2,
        ),
      );
    }
  }

  void _drawBarcodeFromSvg(Canvas canvas, Size size, String svg, Paint paint) {
    // More robust regex to handle different attribute orders in SVG rect elements
    // Matches rect elements and extracts all attributes
    final rectPattern = RegExp(r'<rect\s+([^>]*)/?>', caseSensitive: false);
    final matches = rectPattern.allMatches(svg);

    for (final match in matches) {
      try {
        final attributes = match.group(1) ?? '';

        // Extract individual attributes
        final xMatch = RegExp(r'x="([^"]*)"').firstMatch(attributes);
        final yMatch = RegExp(r'y="([^"]*)"').firstMatch(attributes);
        final widthMatch = RegExp(r'width="([^"]*)"').firstMatch(attributes);
        final heightMatch = RegExp(r'height="([^"]*)"').firstMatch(attributes);

        final x = double.tryParse(xMatch?.group(1) ?? '0') ?? 0;
        final y = double.tryParse(yMatch?.group(1) ?? '0') ?? 0;
        final width = double.tryParse(widthMatch?.group(1) ?? '0') ?? 0;
        final height =
            double.tryParse(heightMatch?.group(1) ?? size.height.toString()) ??
            size.height;

        // Only draw if it's a visible bar (not the background)
        if (width > 0 && width < size.width) {
          canvas.drawRect(Rect.fromLTWH(x, y, width, height), paint);
        }
      } catch (e) {
        // Skip invalid rect
      }
    }
  }

  @override
  bool shouldRepaint(covariant BarcodePainter oldDelegate) {
    return oldDelegate.data != data || oldDelegate.format != format;
  }
}

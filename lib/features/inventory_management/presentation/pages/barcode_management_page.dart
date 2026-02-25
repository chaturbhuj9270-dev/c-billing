import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import '../../../../core/services/language_service.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/printing/services/pos_printer_service.dart';
import '../../../../core/printing/formatters/esc_pos_barcode_formatter.dart';
import '../../../../core/printing/models/printer_models.dart';
import '../../../product/offline/controllers/product_offline_controller.dart';
import '../../../product/offline/entities/product_entity.dart';

/// Enum for printer type selection
enum PrinterType { regular, pos }

/// Barcode Management Page with tabs for Generate, Bulk Generate, and Printed List
class BarcodeManagementPage extends StatefulWidget {
  const BarcodeManagementPage({super.key});

  @override
  State<BarcodeManagementPage> createState() => _BarcodeManagementPageState();
}

class _BarcodeManagementPageState extends State<BarcodeManagementPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  // ignore: unused_field
  late AppLocalizations _localizations;
  
  // State
  bool _isLoading = true;
  List<ProductEntity> _products = [];
  List<ProductEntity> _filteredProducts = [];
  String _searchQuery = '';
  
  // Printer selection
  PrinterType _selectedPrinterType = PrinterType.regular;
  PosPrinterDevice? _connectedPosPrinter;
  bool _isPosConnecting = false;
  bool _isScanning = false;
  List<PosPrinterDevice> _discoveredPrinters = [];
  
  // Single barcode generation
  ProductEntity? _selectedProduct;
  int _labelQuantity = 1;
  bool _includeName = true;
  bool _includePrice = true;
  bool _includeProductCode = true;
  String _barcodeFormat = 'CODE128';
  
  // Bulk generation
  final Map<int, int> _bulkSelections = {}; // productId -> quantity
  bool _selectAllForBulk = false;
  
  // Printed history
  List<PrintedBarcodeRecord> _printedHistory = [];
  
  // Controllers
  final _searchController = TextEditingController();
  final _quantityController = TextEditingController(text: '1');

  // Services
  final _auth = FirebaseAuth.instance;
  final _posPrinterService = PosPrinterService();
  StreamSubscription<PrinterStatus>? _printerStatusSubscription;
  StreamSubscription<List<PosPrinterDevice>>? _printerDevicesSubscription;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _localizations = AppLocalizations.of(
      LanguageService.instance.currentLanguage,
    );
    LanguageService.instance.addListener(_onLanguageChanged);
    _loadProducts();
    _initPrinterListeners();
  }

  void _initPrinterListeners() {
    // Listen to printer status changes
    _printerStatusSubscription = _posPrinterService.statusStream.listen((status) {
      if (mounted) {
        setState(() {
          _isPosConnecting = status == PrinterStatus.connecting;
          if (status == PrinterStatus.connected) {
            _connectedPosPrinter = _posPrinterService.connectedPrinter;
          } else if (status == PrinterStatus.disconnected) {
            _connectedPosPrinter = null;
          }
        });
      }
    });
    
    // Listen to discovered devices
    _printerDevicesSubscription = _posPrinterService.devicesStream.listen((devices) {
      if (mounted) {
        setState(() {
          _discoveredPrinters = devices;
        });
      }
    });
    
    // Check if already connected
    if (_posPrinterService.isConnected) {
      _connectedPosPrinter = _posPrinterService.connectedPrinter;
    }
  }

  void _onLanguageChanged() {
    setState(() {
      _localizations = AppLocalizations.of(
        LanguageService.instance.currentLanguage,
      );
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _quantityController.dispose();
    _printerStatusSubscription?.cancel();
    _printerDevicesSubscription?.cancel();
    LanguageService.instance.removeListener(_onLanguageChanged);
    super.dispose();
  }

  Future<void> _loadProducts() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;
      
      final products = await ProductOfflineController.instance.getAllProducts();
      if (mounted) {
        setState(() {
          _products = products;
          _filteredProducts = products;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('[BarcodeManagement] Error loading products: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _filterProducts(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredProducts = _products;
      } else {
        _filteredProducts = _products.where((p) {
          final nameMatch = p.name.toLowerCase().contains(query.toLowerCase());
          final codeMatch = p.indexNo.toString().contains(query.toLowerCase());
          final barcodeMatch = p.barcode?.toLowerCase().contains(query.toLowerCase()) ?? false;
          return nameMatch || codeMatch || barcodeMatch;
        }).toList();
      }
    });
  }

  // ============ POS PRINTER METHODS ============
  
  Future<void> _scanForPrinters() async {
    if (_isScanning) return;
    
    setState(() {
      _isScanning = true;
      _discoveredPrinters = [];
    });
    
    try {
      final result = await _posPrinterService.startScan(
        timeout: const Duration(seconds: 10),
      );
      
      if (!result.success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message ?? 'Failed to scan'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isScanning = false);
    }
  }
  
  Future<void> _connectToPrinter(PosPrinterDevice device) async {
    setState(() => _isPosConnecting = true);
    
    try {
      final result = await _posPrinterService.connectPrinter(device);
      
      if (mounted) {
        if (result.success) {
          setState(() {
            _connectedPosPrinter = device;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                  const SizedBox(width: 10),
                  Text('Connected to ${device.name}'),
                ],
              ),
              backgroundColor: const Color(0xFF1B4D3E),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
          Navigator.pop(context); // Close the dialog
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.message ?? 'Failed to connect'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } finally {
      if (mounted) setState(() => _isPosConnecting = false);
    }
  }
  
  Future<void> _disconnectPrinter() async {
    await _posPrinterService.disconnectPrinter();
    if (mounted) {
      setState(() {
        _connectedPosPrinter = null;
      });
    }
  }
  
  void _showPrinterSelectionDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildPrinterSelectionSheet(),
    );
  }
  
  Widget _buildPrinterSelectionSheet() {
    return StatefulBuilder(
      builder: (context, setSheetState) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.7,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle
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
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1B4D3E).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.bluetooth, color: Color(0xFF1B4D3E)),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Select POS Printer',
                            style: TextStyle(
                              fontFamily: 'Literata',
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Choose a Bluetooth thermal printer',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () async {
                        setSheetState(() => _isScanning = true);
                        await _scanForPrinters();
                        setSheetState(() => _isScanning = false);
                      },
                      icon: _isScanning 
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.refresh_rounded),
                      label: Text(_isScanning ? 'Scanning...' : 'Scan'),
                    ),
                  ],
                ),
              ),
              
              const Divider(height: 1),
              
              // Printer List
              Expanded(
                child: StreamBuilder<List<PosPrinterDevice>>(
                  stream: _posPrinterService.devicesStream,
                  initialData: _discoveredPrinters,
                  builder: (context, snapshot) {
                    final devices = snapshot.data ?? [];
                    
                    if (devices.isEmpty && !_isScanning) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.bluetooth_searching,
                              size: 48,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No printers found',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Tap "Scan" to search for printers',
                              style: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: () async {
                                setSheetState(() => _isScanning = true);
                                await _scanForPrinters();
                                setSheetState(() => _isScanning = false);
                              },
                              icon: const Icon(Icons.bluetooth_searching),
                              label: const Text('Start Scanning'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1B4D3E),
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                    
                    return ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: devices.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final device = devices[index];
                        final isConnected = _connectedPosPrinter?.id == device.id;
                        
                        return Material(
                          color: isConnected 
                              ? const Color(0xFF1B4D3E).withOpacity(0.1) 
                              : Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                          child: InkWell(
                            onTap: isConnected ? null : () => _connectToPrinter(device),
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: isConnected 
                                          ? const Color(0xFF1B4D3E) 
                                          : Colors.grey[200],
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(
                                      Icons.print_rounded,
                                      color: isConnected ? Colors.white : Colors.grey[600],
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          device.name,
                                          style: TextStyle(
                                            fontFamily: 'Literata',
                                            fontWeight: FontWeight.w600,
                                            color: isConnected 
                                                ? const Color(0xFF1B4D3E) 
                                                : Colors.black87,
                                          ),
                                        ),
                                        Text(
                                          device.address ?? 'Unknown address',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[500],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (isConnected)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF1B4D3E),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Text(
                                        'Connected',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    )
                                  else if (_isPosConnecting)
                                    const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  else
                                    const Icon(
                                      Icons.chevron_right_rounded,
                                      color: Colors.grey,
                                    ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
  
  Widget _buildPrinterSelection() {
    return Column(
      children: [
        // Printer Type Toggle
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF8F9FA),
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.all(4),
          child: Row(
            children: [
              Expanded(
                child: _buildPrinterTypeButton(
                  type: PrinterType.regular,
                  icon: Icons.description_rounded,
                  label: 'Regular Printer',
                  subtitle: 'PDF Print',
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: _buildPrinterTypeButton(
                  type: PrinterType.pos,
                  icon: Icons.receipt_long_rounded,
                  label: 'POS Printer',
                  subtitle: 'Thermal',
                ),
              ),
            ],
          ),
        ),
        
        // POS Printer Status (shown when POS is selected)
        if (_selectedPrinterType == PrinterType.pos) ...[
          const SizedBox(height: 12),
          _buildPosPrinterStatus(),
        ],
      ],
    );
  }
  
  Widget _buildPrinterTypeButton({
    required PrinterType type,
    required IconData icon,
    required String label,
    required String subtitle,
  }) {
    final isSelected = _selectedPrinterType == type;
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => setState(() => _selectedPrinterType = type),
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: const Color(0xFF1B4D3E).withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 20,
                color: isSelected ? const Color(0xFF1B4D3E) : Colors.grey[500],
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontFamily: 'Literata',
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      fontSize: 12,
                      color: isSelected ? const Color(0xFF1B4D3E) : Colors.grey[600],
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 9,
                      color: Colors.grey[400],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildPosPrinterStatus() {
    return Material(
      color: _connectedPosPrinter != null
          ? const Color(0xFF1B4D3E).withOpacity(0.08)
          : Colors.orange.withOpacity(0.08),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: _showPrinterSelectionDialog,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: _connectedPosPrinter != null
                      ? const Color(0xFF1B4D3E)
                      : Colors.orange,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _connectedPosPrinter != null
                      ? Icons.bluetooth_connected_rounded
                      : Icons.bluetooth_disabled_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _connectedPosPrinter != null
                          ? _connectedPosPrinter!.name
                          : 'No Printer Connected',
                      style: TextStyle(
                        fontFamily: 'Literata',
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: _connectedPosPrinter != null
                            ? const Color(0xFF1B4D3E)
                            : Colors.orange[700],
                      ),
                    ),
                    Text(
                      _connectedPosPrinter != null
                          ? 'Tap to change printer'
                          : 'Tap to connect a printer',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),
              if (_connectedPosPrinter != null)
                IconButton(
                  icon: const Icon(Icons.link_off_rounded, size: 18),
                  onPressed: _disconnectPrinter,
                  color: Colors.red[400],
                  tooltip: 'Disconnect',
                )
              else
                Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.grey[400],
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: _buildAppBar(),
      body: _isLoading
          ? _buildLoadingState()
          : TabBarView(
              controller: _tabController,
              children: [
                _buildGenerateBarcodeTab(),
                _buildBulkGenerateTab(),
                _buildPrintedListTab(),
              ],
            ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: const Color(0xFF1B4D3E),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      title: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Barcode Management',
            style: TextStyle(
              fontFamily: 'Literata',
              fontWeight: FontWeight.w700,
              fontSize: 18,
              color: Colors.white,
            ),
          ),
          Text(
            'Generate, print & manage barcodes',
            style: TextStyle(
              fontFamily: 'Literata',
              fontSize: 11,
              color: Colors.white70,
            ),
          ),
        ],
      ),
      bottom: TabBar(
        controller: _tabController,
        indicatorColor: Colors.white,
        indicatorWeight: 3,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white60,
        labelStyle: const TextStyle(
          fontFamily: 'Literata',
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
        tabs: const [
          Tab(
            icon: Icon(Icons.qr_code_rounded, size: 20),
            text: 'Generate',
          ),
          Tab(
            icon: Icon(Icons.library_add_rounded, size: 20),
            text: 'Bulk',
          ),
          Tab(
            icon: Icon(Icons.history_rounded, size: 20),
            text: 'History',
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: Color(0xFF1B4D3E),
          ),
          SizedBox(height: 16),
          Text(
            'Loading products...',
            style: TextStyle(
              fontFamily: 'Literata',
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  // ============ GENERATE BARCODE TAB ============
  
  Widget _buildGenerateBarcodeTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Printer Selection
          _buildSectionCard(
            icon: Icons.print_rounded,
            title: 'Printer Selection',
            subtitle: 'Choose your printer type',
            child: _buildPrinterSelection(),
          ),
          const SizedBox(height: 16),
          
          // Product Search & Selection
          _buildSectionCard(
            icon: Icons.inventory_2_rounded,
            title: 'Select Product',
            subtitle: 'Choose a product to generate barcode',
            child: Column(
              children: [
                _buildSearchField(),
                const SizedBox(height: 12),
                _buildProductSelector(),
              ],
            ),
          ),
          const SizedBox(height: 16),
          
          // Selected Product Info
          if (_selectedProduct != null) ...[
            _buildSectionCard(
              icon: Icons.info_outline_rounded,
              title: 'Selected Product',
              subtitle: 'Product details',
              child: _buildSelectedProductInfo(),
            ),
            const SizedBox(height: 16),
          ],
          
          // Barcode Options
          _buildSectionCard(
            icon: Icons.settings_rounded,
            title: 'Barcode Options',
            subtitle: 'Customize your barcode label',
            child: _buildBarcodeOptions(),
          ),
          const SizedBox(height: 16),
          
          // Label Preview
          if (_selectedProduct != null) ...[
            _buildSectionCard(
              icon: Icons.preview_rounded,
              title: 'Label Preview',
              subtitle: 'How your barcode label will look',
              child: _buildBarcodePreview(),
            ),
            const SizedBox(height: 16),
          ],
          
          // Generate Button
          _buildGenerateButton(),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1B4D3E).withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF1B4D3E).withOpacity(0.15),
                        const Color(0xFF2D6A4F).withOpacity(0.08),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: const Color(0xFF1B4D3E), size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontFamily: 'Literata',
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: Color(0xFF1B4D3E),
                        ),
                      ),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontFamily: 'Literata',
                          fontSize: 11,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: Colors.grey[200]),
          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: child,
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      onChanged: _filterProducts,
      style: const TextStyle(fontFamily: 'Literata', fontSize: 14),
      decoration: InputDecoration(
        hintText: 'Search by name, code, or barcode...',
        hintStyle: TextStyle(
          fontFamily: 'Literata',
          color: Colors.grey[400],
          fontSize: 13,
        ),
        prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF1B4D3E)),
        suffixIcon: _searchQuery.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear_rounded, size: 20),
                onPressed: () {
                  _searchController.clear();
                  _filterProducts('');
                },
              )
            : null,
        filled: true,
        fillColor: Colors.grey[50],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[200]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF1B4D3E), width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  Widget _buildProductSelector() {
    if (_filteredProducts.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(Icons.inventory_2_outlined, size: 40, color: Colors.grey[400]),
            const SizedBox(height: 8),
            Text(
              _searchQuery.isEmpty ? 'No products found' : 'No matching products',
              style: TextStyle(
                fontFamily: 'Literata',
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      constraints: const BoxConstraints(maxHeight: 200),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[200]!),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        itemCount: _filteredProducts.length > 50 ? 50 : _filteredProducts.length,
        separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey[200]),
        itemBuilder: (context, index) {
          final product = _filteredProducts[index];
          final isSelected = _selectedProduct?.id == product.id;
          
          return ListTile(
            dense: true,
            selected: isSelected,
            selectedTileColor: const Color(0xFF1B4D3E).withOpacity(0.08),
            leading: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF1B4D3E).withOpacity(0.15)
                    : Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.inventory_2_rounded,
                size: 18,
                color: isSelected ? const Color(0xFF1B4D3E) : Colors.grey[600],
              ),
            ),
            title: Text(
              product.name,
              style: TextStyle(
                fontFamily: 'Literata',
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                fontSize: 13,
                color: isSelected ? const Color(0xFF1B4D3E) : Colors.black87,
              ),
            ),
            subtitle: Text(
              '#${product.indexNo} • ₹${product.salesPrice.toStringAsFixed(2)}',
              style: TextStyle(
                fontFamily: 'Literata',
                fontSize: 11,
                color: Colors.grey[600],
              ),
            ),
            trailing: isSelected
                ? const Icon(Icons.check_circle_rounded, color: Color(0xFF1B4D3E), size: 20)
                : null,
            onTap: () => setState(() => _selectedProduct = product),
          );
        },
      ),
    );
  }

  Widget _buildSelectedProductInfo() {
    final product = _selectedProduct!;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF1B4D3E).withOpacity(0.08),
            const Color(0xFF1B4D3E).withOpacity(0.03),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF1B4D3E).withOpacity(0.15)),
      ),
      child: Column(
        children: [
          _buildInfoRow('Product Name', product.name),
          const SizedBox(height: 8),
          _buildInfoRow('Index No', '#${product.indexNo}'),
          const SizedBox(height: 8),
          _buildInfoRow('Existing Barcode', product.barcode ?? 'None'),
          const SizedBox(height: 8),
          _buildInfoRow('Sales Price', '₹${product.salesPrice.toStringAsFixed(2)}'),
          const SizedBox(height: 8),
          _buildInfoRow('Purchase Price', '₹${product.purchasePrice.toStringAsFixed(2)}'),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Literata',
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(
              fontFamily: 'Literata',
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: Color(0xFF1B4D3E),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBarcodeOptions() {
    return Column(
      children: [
        // Barcode Format
        _buildOptionDropdown(
          label: 'Barcode Format',
          value: _barcodeFormat,
          items: const ['CODE128', 'CODE39', 'EAN13', 'EAN8', 'UPC-A'],
          onChanged: (val) => setState(() => _barcodeFormat = val!),
        ),
        const SizedBox(height: 16),
        
        // Quantity
        _buildQuantitySelector(),
        const SizedBox(height: 16),
        
        // Label Content Options
        const Text(
          'Label Content',
          style: TextStyle(
            fontFamily: 'Literata',
            fontWeight: FontWeight.w600,
            fontSize: 13,
            color: Color(0xFF1B4D3E),
          ),
        ),
        const SizedBox(height: 10),
        _buildOptionSwitch('Include Product Name', _includeName, (val) {
          setState(() => _includeName = val);
        }),
        _buildOptionSwitch('Include Price', _includePrice, (val) {
          setState(() => _includePrice = val);
        }),
        _buildOptionSwitch('Include Product Code', _includeProductCode, (val) {
          setState(() => _includeProductCode = val);
        }),
      ],
    );
  }

  Widget _buildOptionDropdown({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: const TextStyle(
              fontFamily: 'Literata',
              fontSize: 13,
              color: Color(0xFF1B4D3E),
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(10),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: value,
                isExpanded: true,
                icon: const Icon(Icons.keyboard_arrow_down_rounded),
                style: const TextStyle(
                  fontFamily: 'Literata',
                  fontSize: 13,
                  color: Colors.black87,
                ),
                items: items.map((item) {
                  return DropdownMenuItem(value: item, child: Text(item));
                }).toList(),
                onChanged: onChanged,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuantitySelector() {
    return Row(
      children: [
        const Expanded(
          flex: 2,
          child: Text(
            'Label Quantity',
            style: TextStyle(
              fontFamily: 'Literata',
              fontSize: 13,
              color: Color(0xFF1B4D3E),
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Row(
            children: [
              _buildQuantityButton(Icons.remove, () {
                if (_labelQuantity > 1) {
                  setState(() => _labelQuantity--);
                  _quantityController.text = '$_labelQuantity';
                }
              }),
              Expanded(
                child: TextField(
                  controller: _quantityController,
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(
                    fontFamily: 'Literata',
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                  onChanged: (val) {
                    final qty = int.tryParse(val) ?? 1;
                    setState(() => _labelQuantity = qty.clamp(1, 500));
                  },
                ),
              ),
              _buildQuantityButton(Icons.add, () {
                if (_labelQuantity < 500) {
                  setState(() => _labelQuantity++);
                  _quantityController.text = '$_labelQuantity';
                }
              }),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuantityButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: const Color(0xFF1B4D3E).withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: const Color(0xFF1B4D3E), size: 18),
      ),
    );
  }

  Widget _buildOptionSwitch(String label, bool value, ValueChanged<bool> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Literata',
              fontSize: 13,
              color: Colors.grey[700],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFF1B4D3E),
          ),
        ],
      ),
    );
  }

  Widget _buildBarcodePreview() {
    if (_selectedProduct == null) return const SizedBox.shrink();
    
    final product = _selectedProduct!;
    final barcodeData = product.barcode ?? product.indexNo.toString();
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // Product Name (if enabled)
          if (_includeName)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                product.name,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Literata',
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          
          // Barcode placeholder (actual barcode will be in PDF)
          Container(
            height: 50,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(4),
            ),
            child: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.qr_code_2_rounded, size: 24, color: Color(0xFF1B4D3E)),
                  const SizedBox(width: 8),
                  Text(
                    barcodeData,
                    style: const TextStyle(
                      fontFamily: 'Literata',
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Barcode number
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              barcodeData,
              style: TextStyle(
                fontFamily: 'Literata',
                fontSize: 10,
                color: Colors.grey[600],
                letterSpacing: 1.5,
              ),
            ),
          ),
          
          // Product Code (if enabled)
          if (_includeProductCode)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'Index: #${product.indexNo}',
                style: TextStyle(
                  fontFamily: 'Literata',
                  fontSize: 10,
                  color: Colors.grey[600],
                ),
              ),
            ),
          
          // Price (if enabled)
          if (_includePrice)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '₹${product.salesPrice.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontFamily: 'Literata',
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: Color(0xFF1B4D3E),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildGenerateButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _selectedProduct != null ? _generateAndPrintBarcodes : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1B4D3E),
          disabledBackgroundColor: Colors.grey[300],
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.print_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Text(
              'Generate & Print (${_labelQuantity} ${_labelQuantity == 1 ? 'label' : 'labels'})',
              style: const TextStyle(
                fontFamily: 'Literata',
                fontWeight: FontWeight.w600,
                fontSize: 15,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _generateAndPrintBarcodes() async {
    if (_selectedProduct == null) return;
    
    // Check if POS printer is selected but not connected
    if (_selectedPrinterType == PrinterType.pos && _connectedPosPrinter == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.white, size: 20),
              SizedBox(width: 10),
              Text('Please connect a POS printer first'),
            ],
          ),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          action: SnackBarAction(
            label: 'Connect',
            textColor: Colors.white,
            onPressed: _showPrinterSelectionDialog,
          ),
        ),
      );
      return;
    }
    
    try {
      final product = _selectedProduct!;
      final barcodeData = product.barcode ?? product.indexNo.toString();
      
      if (_selectedPrinterType == PrinterType.pos) {
        // POS Thermal Printer
        await _printToPosThePrinter(product, barcodeData);
      } else {
        // Regular PDF Printer
        await _printToPdfPrinter(product, barcodeData);
      }
      
      // Add to print history
      _addToPrintHistory(product, _labelQuantity);
      
    } catch (e) {
      debugPrint('[BarcodeManagement] Error generating barcodes: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating barcodes: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  /// Print barcodes to POS thermal printer
  Future<void> _printToPosThePrinter(ProductEntity product, String barcodeData) async {
    // Generate barcode labels using ESC/POS formatter
    final labelConfig = BarcodeLabelConfig(
      showProductName: _includeName,
      showPrice: _includePrice,
      showProductCode: _includeProductCode,
      showHriText: true,
      barcodeHeight: 50,
      barcodeWidth: 2,
    );
    
    final result = await _posPrinterService.printSingleBarcode(
      barcodeData: barcodeData,
      productName: _includeName ? product.name : null,
      productCode: _includeProductCode ? product.indexNo.toString() : null,
      price: _includePrice ? product.salesPrice : null,
      barcodeFormat: _barcodeFormat,
      quantity: _labelQuantity,
      config: labelConfig,
    );
    
    if (mounted) {
      if (result.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Text(
                  'Printed $_labelQuantity barcode labels to POS printer',
                  style: const TextStyle(fontFamily: 'Literata'),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF1B4D3E),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message ?? 'Failed to print'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  /// Print barcodes to regular PDF printer
  Future<void> _printToPdfPrinter(ProductEntity product, String barcodeData) async {
    // Generate PDF with barcodes
    final pdf = pw.Document();
    
    // Calculate barcode type
    final barcodeType = _getBarcodeType(_barcodeFormat);
    
    // Create labels (4 columns x N rows per page)
    const labelsPerRow = 4;
    const labelsPerPage = 20; // 4 columns x 5 rows
    
    int totalLabels = _labelQuantity;
    int pageCount = (totalLabels / labelsPerPage).ceil();
    
    for (int page = 0; page < pageCount; page++) {
      int labelsOnThisPage = (page == pageCount - 1)
          ? totalLabels - (page * labelsPerPage)
          : labelsPerPage;
      
      int rowCount = (labelsOnThisPage / labelsPerRow).ceil();
      
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(10),
          build: (context) {
            return pw.Column(
              children: List.generate(rowCount, (rowIndex) {
                int startIndex = rowIndex * labelsPerRow;
                int endIndex = (startIndex + labelsPerRow).clamp(0, labelsOnThisPage);
                int labelsInRow = endIndex - startIndex;
                
                return pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(vertical: 4),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
                    children: List.generate(labelsInRow, (_) {
                      return _buildPdfBarcodeLabel(
                        product: product,
                        barcodeData: barcodeData,
                        barcodeType: barcodeType,
                      );
                    }),
                  ),
                );
              }),
            );
          },
        ),
      );
    }
    
    // Print or save PDF
    await Printing.layoutPdf(
      onLayout: (format) => pdf.save(),
      name: 'Barcode_${product.name}_${DateTime.now().millisecondsSinceEpoch}',
    );
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Text(
                'Generated $_labelQuantity barcode labels',
                style: const TextStyle(fontFamily: 'Literata'),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF1B4D3E),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  pw.BarcodeType _getBarcodeType(String format) {
    switch (format) {
      case 'CODE39':
        return pw.BarcodeType.Code39;
      case 'EAN13':
        return pw.BarcodeType.CodeEAN13;
      case 'EAN8':
        return pw.BarcodeType.CodeEAN8;
      case 'UPC-A':
        return pw.BarcodeType.CodeUPCA;
      default:
        return pw.BarcodeType.Code128;
    }
  }

  pw.Widget _buildPdfBarcodeLabel({
    required ProductEntity product,
    required String barcodeData,
    required pw.BarcodeType barcodeType,
  }) {
    return pw.Container(
      width: 120,
      padding: const pw.EdgeInsets.all(6),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
      ),
      child: pw.Column(
        mainAxisSize: pw.MainAxisSize.min,
        children: [
          // Product Name
          if (_includeName)
            pw.Text(
              product.name,
              style: pw.TextStyle(
                fontSize: 7,
                fontWeight: pw.FontWeight.bold,
              ),
              textAlign: pw.TextAlign.center,
              maxLines: 2,
            ),
          pw.SizedBox(height: 2),
          
          // Barcode
          pw.BarcodeWidget(
            data: _sanitizeBarcodeData(barcodeData, barcodeType),
            barcode: pw.Barcode.fromType(barcodeType),
            width: 100,
            height: 30,
            drawText: false,
          ),
          
          // Barcode number
          pw.Text(
            barcodeData,
            style: const pw.TextStyle(fontSize: 6),
          ),
          
          // Product Code
          if (_includeProductCode)
            pw.Text(
              'Index: #${product.indexNo}',
              style: const pw.TextStyle(fontSize: 5),
            ),
          
          // Price
          if (_includePrice)
            pw.Text(
              'Rs.${product.salesPrice.toStringAsFixed(2)}',
              style: pw.TextStyle(
                fontSize: 8,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
        ],
      ),
    );
  }

  String _sanitizeBarcodeData(String data, pw.BarcodeType type) {
    // Ensure data is valid for the barcode type
    switch (type) {
      case pw.BarcodeType.CodeEAN13:
        // EAN13 requires exactly 12 or 13 digits
        String digits = data.replaceAll(RegExp(r'[^0-9]'), '');
        if (digits.length < 12) {
          digits = digits.padLeft(12, '0');
        }
        return digits.substring(0, 12);
      case pw.BarcodeType.CodeEAN8:
        // EAN8 requires exactly 7 or 8 digits
        String digits = data.replaceAll(RegExp(r'[^0-9]'), '');
        if (digits.length < 7) {
          digits = digits.padLeft(7, '0');
        }
        return digits.substring(0, 7);
      case pw.BarcodeType.CodeUPCA:
        // UPC-A requires exactly 11 or 12 digits
        String digits = data.replaceAll(RegExp(r'[^0-9]'), '');
        if (digits.length < 11) {
          digits = digits.padLeft(11, '0');
        }
        return digits.substring(0, 11);
      default:
        return data;
    }
  }

  void _addToPrintHistory(ProductEntity product, int quantity) {
    setState(() {
      _printedHistory.insert(0, PrintedBarcodeRecord(
        productId: product.id,
        productName: product.name,
        productCode: product.indexNo.toString(),
        barcode: product.barcode,
        quantity: quantity,
        printedAt: DateTime.now(),
      ));
    });
  }

  // ============ BULK GENERATE TAB ============

  Widget _buildBulkGenerateTab() {
    return Column(
      children: [
        // Printer Selection Card (at top)
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: _buildPrinterSelection(),
        ),
        
        // Header with Select All
        _buildBulkHeader(),
        
        // Product List
        Expanded(
          child: _buildBulkProductList(),
        ),
        
        // Bottom Action Bar
        _buildBulkActionBar(),
      ],
    );
  }

  Widget _buildBulkHeader() {
    final selectedCount = _bulkSelections.values.where((q) => q > 0).length;
    final totalLabels = _bulkSelections.values.fold<int>(0, (sum, q) => sum + q);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Search
          TextField(
            onChanged: _filterProducts,
            style: const TextStyle(fontFamily: 'Literata', fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Search products...',
              hintStyle: TextStyle(fontFamily: 'Literata', color: Colors.grey[400]),
              prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF1B4D3E)),
              filled: true,
              fillColor: Colors.grey[50],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
          const SizedBox(height: 12),
          
          // Select All & Stats
          Row(
            children: [
              GestureDetector(
                onTap: _toggleSelectAll,
                child: Row(
                  children: [
                    Icon(
                      _selectAllForBulk ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
                      color: const Color(0xFF1B4D3E),
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Select All (1 each)',
                      style: TextStyle(
                        fontFamily: 'Literata',
                        fontSize: 13,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF1B4D3E).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$selectedCount products • $totalLabels labels',
                  style: const TextStyle(
                    fontFamily: 'Literata',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1B4D3E),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _toggleSelectAll() {
    setState(() {
      _selectAllForBulk = !_selectAllForBulk;
      if (_selectAllForBulk) {
        for (var product in _filteredProducts) {
          _bulkSelections[product.id] = 1;
        }
      } else {
        _bulkSelections.clear();
      }
    });
  }

  Widget _buildBulkProductList() {
    if (_filteredProducts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2_outlined, size: 60, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'No products found',
              style: TextStyle(
                fontFamily: 'Literata',
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _filteredProducts.length,
      itemBuilder: (context, index) {
        final product = _filteredProducts[index];
        final quantity = _bulkSelections[product.id] ?? 0;
        final isSelected = quantity > 0;
        
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF1B4D3E).withOpacity(0.3)
                  : Colors.grey[200]!,
            ),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            leading: GestureDetector(
              onTap: () => _toggleBulkSelection(product),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF1B4D3E).withOpacity(0.15)
                      : Colors.grey[100],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  isSelected ? Icons.check_rounded : Icons.add_rounded,
                  color: isSelected ? const Color(0xFF1B4D3E) : Colors.grey[400],
                  size: 20,
                ),
              ),
            ),
            title: Text(
              product.name,
              style: const TextStyle(
                fontFamily: 'Literata',
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              '#${product.indexNo} • ₹${product.salesPrice.toStringAsFixed(2)}',
              style: TextStyle(
                fontFamily: 'Literata',
                fontSize: 11,
                color: Colors.grey[600],
              ),
            ),
            trailing: isSelected
                ? _buildBulkQuantityControl(product, quantity)
                : null,
          ),
        );
      },
    );
  }

  void _toggleBulkSelection(ProductEntity product) {
    setState(() {
      if (_bulkSelections.containsKey(product.id) && _bulkSelections[product.id]! > 0) {
        _bulkSelections.remove(product.id);
      } else {
        _bulkSelections[product.id] = 1;
      }
      _updateSelectAllState();
    });
  }

  void _updateSelectAllState() {
    _selectAllForBulk = _filteredProducts.every((p) => (_bulkSelections[p.id] ?? 0) > 0);
  }

  Widget _buildBulkQuantityControl(ProductEntity product, int quantity) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildMiniQuantityButton(Icons.remove, () {
          setState(() {
            if (quantity > 1) {
              _bulkSelections[product.id] = quantity - 1;
            } else {
              _bulkSelections.remove(product.id);
              _updateSelectAllState();
            }
          });
        }),
        Container(
          width: 36,
          alignment: Alignment.center,
          child: Text(
            '$quantity',
            style: const TextStyle(
              fontFamily: 'Literata',
              fontWeight: FontWeight.w700,
              fontSize: 14,
              color: Color(0xFF1B4D3E),
            ),
          ),
        ),
        _buildMiniQuantityButton(Icons.add, () {
          setState(() {
            _bulkSelections[product.id] = quantity + 1;
          });
        }),
      ],
    );
  }

  Widget _buildMiniQuantityButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: const Color(0xFF1B4D3E).withOpacity(0.1),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icon, color: const Color(0xFF1B4D3E), size: 16),
      ),
    );
  }

  Widget _buildBulkActionBar() {
    final totalLabels = _bulkSelections.values.fold<int>(0, (sum, q) => sum + q);
    final hasSelection = totalLabels > 0;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.15),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            if (hasSelection)
              TextButton.icon(
                onPressed: () => setState(() => _bulkSelections.clear()),
                icon: const Icon(Icons.clear_all_rounded, size: 18),
                label: const Text('Clear'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.grey[700],
                ),
              ),
            const Spacer(),
            ElevatedButton.icon(
              onPressed: hasSelection ? _generateBulkBarcodes : null,
              icon: const Icon(Icons.print_rounded, size: 18),
              label: Text(
                hasSelection ? 'Print $totalLabels Labels' : 'Select Products',
                style: const TextStyle(
                  fontFamily: 'Literata',
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1B4D3E),
                disabledBackgroundColor: Colors.grey[300],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _generateBulkBarcodes() async {
    // Check if POS printer is selected but not connected
    if (_selectedPrinterType == PrinterType.pos && _connectedPosPrinter == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.white, size: 20),
              SizedBox(width: 10),
              Text('Please connect a POS printer first'),
            ],
          ),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          action: SnackBarAction(
            label: 'Connect',
            textColor: Colors.white,
            onPressed: _showPrinterSelectionDialog,
          ),
        ),
      );
      return;
    }
        
    try {
      // Collect all labels
      List<ProductEntity> labelsToGenerate = [];
      for (var entry in _bulkSelections.entries) {
        final product = _products.firstWhere((p) => p.id == entry.key);
        for (int i = 0; i < entry.value; i++) {
          labelsToGenerate.add(product);
        }
      }
      
      final totalLabels = labelsToGenerate.length;
      
      if (_selectedPrinterType == PrinterType.pos) {
        // POS Thermal Printer - generate ESC/POS commands
        await _printBulkToPosThePrinter(labelsToGenerate);
      } else {
        // Regular PDF Printer
        await _printBulkToPdfPrinter(labelsToGenerate);
      }
      
      // Add to print history
      for (var entry in _bulkSelections.entries) {
        final product = _products.firstWhere((p) => p.id == entry.key);
        _addToPrintHistory(product, entry.value);
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Text(
                  'Generated $totalLabels bulk barcode labels',
                  style: const TextStyle(fontFamily: 'Literata'),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF1B4D3E),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
        
        // Clear selections
        setState(() => _bulkSelections.clear());
      }
    } catch (e) {
      debugPrint('[BarcodeManagement] Error generating bulk barcodes: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating bulk barcodes: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  /// Print bulk barcodes to POS thermal printer
  Future<void> _printBulkToPosThePrinter(List<ProductEntity> products) async {
    final labelConfig = BarcodeLabelConfig(
      showProductName: _includeName,
      showPrice: _includePrice,
      showProductCode: _includeProductCode,
      showHriText: true,
      barcodeHeight: 50,
      barcodeWidth: 2,
    );
    
    final labels = products.map((product) {
      final barcodeData = product.barcode ?? product.indexNo.toString();
      return BarcodeLabelData(
        barcodeData: barcodeData,
        productName: _includeName ? product.name : null,
        productCode: _includeProductCode ? product.indexNo.toString() : null,
        price: _includePrice ? product.salesPrice : null,
        barcodeFormat: _barcodeFormat,
      );
    }).toList();
    
    final result = await _posPrinterService.printBarcodeLabels(
      labels: labels,
      config: labelConfig,
    );
    
    if (!result.success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message ?? 'Failed to print to POS printer'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  /// Print bulk barcodes to regular PDF printer
  Future<void> _printBulkToPdfPrinter(List<ProductEntity> products) async {
    final pdf = pw.Document();
    final barcodeType = _getBarcodeType(_barcodeFormat);
    
    // Generate PDF pages (20 labels per page - 4 columns x 5 rows)
    const labelsPerRow = 4;
    const labelsPerPage = 20;
    
    int pageCount = (products.length / labelsPerPage).ceil();
    
    for (int page = 0; page < pageCount; page++) {
      int startIndex = page * labelsPerPage;
      int endIndex = (startIndex + labelsPerPage).clamp(0, products.length);
      List<ProductEntity> pageProducts = products.sublist(startIndex, endIndex);
      
      int rowCount = (pageProducts.length / labelsPerRow).ceil();
      
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(10),
          build: (context) {
            return pw.Column(
              children: List.generate(rowCount, (rowIndex) {
                int rowStart = rowIndex * labelsPerRow;
                int rowEnd = (rowStart + labelsPerRow).clamp(0, pageProducts.length);
                List<ProductEntity> rowProducts = pageProducts.sublist(rowStart, rowEnd);
                
                return pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(vertical: 4),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
                    children: rowProducts.map((product) {
                      final barcodeData = product.barcode ?? product.indexNo.toString();
                      return _buildPdfBarcodeLabel(
                        product: product,
                        barcodeData: barcodeData,
                        barcodeType: barcodeType,
                      );
                    }).toList(),
                  ),
                );
              }),
            );
          },
        ),
      );
    }
    
    // Print or save PDF
    await Printing.layoutPdf(
      onLayout: (format) => pdf.save(),
      name: 'Bulk_Barcodes_${DateTime.now().millisecondsSinceEpoch}',
    );
  }

  // ============ PRINTED LIST TAB ============

  Widget _buildPrintedListTab() {
    if (_printedHistory.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFF1B4D3E).withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.history_rounded,
                size: 40,
                color: Color(0xFF1B4D3E),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'No Print History',
              style: TextStyle(
                fontFamily: 'Literata',
                fontWeight: FontWeight.w700,
                fontSize: 18,
                color: Color(0xFF1B4D3E),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Printed barcodes will appear here',
              style: TextStyle(
                fontFamily: 'Literata',
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _tabController.animateTo(0),
              icon: const Icon(Icons.qr_code_rounded, size: 18),
              label: const Text(
                'Generate First Barcode',
                style: TextStyle(fontFamily: 'Literata'),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1B4D3E),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Stats Header
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: Row(
            children: [
              _buildHistoryStatCard(
                icon: Icons.print_rounded,
                value: '${_printedHistory.length}',
                label: 'Print Jobs',
                color: const Color(0xFF667eea),
              ),
              const SizedBox(width: 12),
              _buildHistoryStatCard(
                icon: Icons.qr_code_rounded,
                value: '${_printedHistory.fold<int>(0, (sum, r) => sum + r.quantity)}',
                label: 'Total Labels',
                color: const Color(0xFF1B4D3E),
              ),
            ],
          ),
        ),
        
        // History List
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _printedHistory.length,
            itemBuilder: (context, index) {
              final record = _printedHistory[index];
              return _buildHistoryCard(record, index);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildHistoryStatCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              color.withOpacity(0.12),
              color.withOpacity(0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontFamily: 'Literata',
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                    color: color,
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(
                    fontFamily: 'Literata',
                    fontSize: 11,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryCard(PrintedBarcodeRecord record, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(14),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1B4D3E), Color(0xFF2D6A4F)],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.qr_code_2_rounded, color: Colors.white, size: 22),
        ),
        title: Text(
          record.productName,
          style: const TextStyle(
            fontFamily: 'Literata',
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              'Code: ${record.productCode ?? record.barcode ?? 'N/A'}',
              style: TextStyle(
                fontFamily: 'Literata',
                fontSize: 11,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 2),
            Text(
              DateFormat('dd MMM yyyy, hh:mm a').format(record.printedAt),
              style: TextStyle(
                fontFamily: 'Literata',
                fontSize: 10,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF1B4D3E).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${record.quantity}',
                style: const TextStyle(
                  fontFamily: 'Literata',
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: Color(0xFF1B4D3E),
                ),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'labels',
              style: TextStyle(
                fontFamily: 'Literata',
                fontSize: 9,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        onTap: () => _reprintBarcode(record),
      ),
    );
  }

  void _reprintBarcode(PrintedBarcodeRecord record) {
    // Find the product and navigate to generate tab with it selected
    final product = _products.firstWhere(
      (p) => p.id == record.productId,
      orElse: () => _products.first,
    );
    
    setState(() {
      _selectedProduct = product;
      _labelQuantity = record.quantity;
      _quantityController.text = '${record.quantity}';
    });
    
    _tabController.animateTo(0);
  }
}

/// Model for tracking printed barcode history
class PrintedBarcodeRecord {
  final int productId;
  final String productName;
  final String? productCode;
  final String? barcode;
  final int quantity;
  final DateTime printedAt;

  PrintedBarcodeRecord({
    required this.productId,
    required this.productName,
    this.productCode,
    this.barcode,
    required this.quantity,
    required this.printedAt,
  });
}

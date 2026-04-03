import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../../../core/services/invoice_scanner_service.dart';
import '../../../../core/services/inventory_integration_service.dart';
import '../../../../core/services/language_service.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../supplier/offline/controllers/supplier_offline_controller.dart';
import '../../../supplier/offline/entities/supplier_entity.dart';
import '../../../company/offline/controllers/company_offline_controller.dart';
import '../../../company/offline/entities/company_entity.dart';
import '../../../product/offline/controllers/product_offline_controller.dart';
import '../../../product/offline/entities/product_entity.dart';
import '../../data/services/purchase_sync_service.dart';
import '../../data/services/purchase_batch_sync_service.dart';
import 'package:c_billing/core/ui/glassy_toast.dart';

class InvoiceScannerPage extends StatefulWidget {
  const InvoiceScannerPage({super.key});

  @override
  State<InvoiceScannerPage> createState() => _InvoiceScannerPageState();
}

class _InvoiceScannerPageState extends State<InvoiceScannerPage> {
  final InvoiceScannerService _scannerService = InvoiceScannerService.instance;
  // ignore: unused_field
  late AppLocalizations _localizations;

  bool _isScanning = false;
  bool _isSaving = false;
  File? _selectedImage;
  ScannedInvoiceData? _scannedData;
  String? _errorMessage;

  // Supplier and Company selection
  SupplierEntity? _selectedSupplier;
  CompanyEntity? _selectedCompany;
  List<SupplierEntity> _suppliers = [];
  List<CompanyEntity> _companies = [];
  List<ProductEntity> _products = [];

  // API Key input
  final _apiKeyController = TextEditingController();
  bool _showApiKeyInput = false;

  @override
  void initState() {
    super.initState();
    _localizations = AppLocalizations.of(
      LanguageService.instance.currentLanguage,
    );
    _initializeService();
    _loadData();
  }

  Future<void> _initializeService() async {
    await _scannerService.initialize();
    // API key is pre-configured, no need to show input
    if (mounted) {
      setState(() {
        _showApiKeyInput = false;
      });
    }
  }

  Future<void> _loadData() async {
    final suppliers = await SupplierOfflineController.instance
        .getAllSuppliers();
    final companies = await CompanyOfflineController.instance.getAllCompanies();
    final products = await ProductOfflineController.instance.getAllProducts();

    if (mounted) {
      setState(() {
        _suppliers = suppliers.where((s) => s.isActive).toList();
        _companies = companies.where((c) => c.isActive).toList();
        _products = products.where((p) => p.isActive).toList();
      });
    }
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final file = await _scannerService.pickImage(source: source);
      if (file != null) {
        setState(() {
          _selectedImage = file;
          _scannedData = null;
          _errorMessage = null;
        });
        await _scanImage();
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to pick image: $e';
      });
    }
  }

  Future<void> _scanImage() async {
    if (_selectedImage == null) return;

    if (!_scannerService.isConfigured) {
      setState(() {
        _showApiKeyInput = true;
        _errorMessage = 'Please configure your Gemini API key first';
      });
      return;
    }

    setState(() {
      _isScanning = true;
      _errorMessage = null;
    });

    try {
      final result = await _scannerService.scanInvoice(_selectedImage!);

      if (mounted) {
        setState(() {
          _isScanning = false;
          if (result.success && result.data != null) {
            _scannedData = result.data;
            _matchProductsWithScannedItems();
            // Try to match supplier from scanned data
            if (result.data!.supplierName != null) {
              _matchSupplier(result.data!.supplierName!);
            }
          } else {
            _errorMessage = result.errorMessage ?? 'Failed to scan invoice';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isScanning = false;
          _errorMessage = 'Error scanning invoice: $e';
        });
      }
    }
  }

  void _matchProductsWithScannedItems() {
    if (_scannedData == null) return;

    for (var item in _scannedData!.items) {
      // Try to find matching product by name
      final matchedProduct = _products.firstWhere(
        (p) =>
            p.name.toLowerCase().contains(item.productName.toLowerCase()) ||
            item.productName.toLowerCase().contains(p.name.toLowerCase()),
        orElse: () => ProductEntity(
          name: '',
          purchasePrice: 0,
          salesPrice: 0,
          updatedAt: DateTime.now(),
          createdAt: DateTime.now(),
        ),
      );

      if (matchedProduct.name.isNotEmpty) {
        item.matchedProductId =
            matchedProduct.serverId ?? matchedProduct.id.toString();
        // Use existing prices if not detected
        if (item.salesPrice == null || item.salesPrice == 0) {
          item.salesPrice = matchedProduct.salesPrice;
        }
      }
    }
  }

  void _matchSupplier(String supplierName) {
    final matched = _suppliers.firstWhere(
      (s) =>
          s.fullName.toLowerCase().contains(supplierName.toLowerCase()) ||
          supplierName.toLowerCase().contains(s.fullName.toLowerCase()),
      orElse: () => SupplierEntity(
        firstName: '',
        contact: '',
        updatedAt: DateTime.now(),
        createdAt: DateTime.now(),
      ),
    );

    if (matched.firstName.isNotEmpty) {
      setState(() {
        _selectedSupplier = matched;
      });
    }
  }

  Future<void> _saveApiKey() async {
    final apiKey = _apiKeyController.text.trim();
    if (apiKey.isEmpty) {
      GlassyToast.show(context, 'Please enter a valid API key');
      return;
    }

    await _scannerService.setApiKey(apiKey);
    setState(() {
      _showApiKeyInput = false;
    });

    GlassyToast.show(context, 'API key saved successfully');

    // If we have an image, try scanning again
    if (_selectedImage != null) {
      await _scanImage();
    }
  }

  Future<void> _saveTourchaseRecords() async {
    if (_scannedData == null || _scannedData!.items.isEmpty) {
      GlassyToast.show(context, 'No items to save');
      return;
    }

    if (_selectedSupplier == null) {
      GlassyToast.show(context, 'Please select a supplier');
      return;
    }

    final selectedItems = _scannedData!.items
        .where((item) => item.isSelected)
        .toList();
    if (selectedItems.isEmpty) {
      GlassyToast.show(context, 'No items selected');
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      int successCount = 0;
      int failCount = 0;

      for (final item in selectedItems) {
        try {
          // If no matched product, create new or skip
          String productId = item.matchedProductId ?? '';
          String productName = item.productName;

          // Find matched product for additional details
          ProductEntity? matchedProduct;
          if (item.matchedProductId != null) {
            matchedProduct = _products.firstWhere(
              (p) => (p.serverId ?? p.id.toString()) == item.matchedProductId,
              orElse: () => ProductEntity(
                name: '',
                purchasePrice: 0,
                salesPrice: 0,
                updatedAt: DateTime.now(),
                createdAt: DateTime.now(),
              ),
            );
            if (matchedProduct.name.isEmpty) {
              matchedProduct = null;
            }
          }

          // If no matched product, create a new one first
          String finalProductId = productId;
          if (finalProductId.isEmpty && matchedProduct == null) {
            // Create new product
            final newProduct = await ProductOfflineController.instance
                .addProduct(
                  name: productName,
                  companyName: item.companyName ?? '',
                  purchasePrice: item.purchasePrice,
                  salesPrice: item.salesPrice ?? item.purchasePrice * 1.2,
                  unit: item.unit ?? 'pcs',
                );
            finalProductId = newProduct.serverId ?? newProduct.id.toString();
          }

          await InventoryIntegrationService.instance.processPurchase(
            productId: finalProductId,
            productName: productName,
            supplierId:
                _selectedSupplier!.serverId ?? _selectedSupplier!.id.toString(),
            supplierName: _selectedSupplier!.fullName,
            companyId:
                _selectedCompany?.serverId ?? _selectedCompany?.id.toString(),
            companyName:
                item.companyName ?? _selectedCompany?.companyName ?? '',
            quantity: item.quantity,
            unit: item.unit ?? matchedProduct?.unit ?? 'pcs',
            purchasePrice: item.purchasePrice,
            salesPrice:
                item.salesPrice ??
                matchedProduct?.salesPrice ??
                item.purchasePrice * 1.2,
            productionDate: item.productionDate,
            expiryDate: item.expiryDate,
            warrantyMonths: null,
            notes:
                'Scanned from invoice${_scannedData!.invoiceNumber != null ? ' #${_scannedData!.invoiceNumber}' : ''}',
          );
          successCount++;
        } catch (e) {
          debugPrint('Failed to save item ${item.productName}: $e');
          failCount++;
        }
      }

      // Trigger sync
      PurchaseSyncService.instance.syncNow();
      PurchaseBatchSyncService.instance.syncNow();

      if (mounted) {
        setState(() {
          _isSaving = false;
        });

        GlassyToast.show(
          context,
          failCount == 0
              ? 'Successfully saved $successCount items to purchase records'
              : 'Saved $successCount items, $failCount failed',
        );

        if (failCount == 0) {
          Navigator.of(context).pop(true);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
        GlassyToast.show(context, 'Error saving purchases: $e', isError: true);
      }
    }
  }

  void _editItem(int index) {
    final item = _scannedData!.items[index];
    showDialog(
      context: context,
      builder: (context) => _EditItemDialog(
        item: item,
        products: _products,
        companies: _companies,
        onSave: (updatedItem) {
          setState(() {
            _scannedData!.items[index] = updatedItem;
          });
        },
      ),
    );
  }

  void _removeItem(int index) {
    setState(() {
      _scannedData!.items.removeAt(index);
    });
  }

  void _toggleItemSelection(int index) {
    setState(() {
      _scannedData!.items[index].isSelected =
          !_scannedData!.items[index].isSelected;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Invoice'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => _showSettingsDialog(),
            tooltip: 'API Settings',
          ),
        ],
      ),
      body: _showApiKeyInput && !_scannerService.isConfigured
          ? _buildApiKeySetup(theme, colorScheme)
          : _buildMainContent(theme, colorScheme),
      floatingActionButton:
          _scannedData != null && _scannedData!.items.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: _isSaving ? null : _saveTourchaseRecords,
              icon: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save),
              label: Text(_isSaving ? 'Saving...' : 'Save to Purchases'),
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
            )
          : null,
    );
  }

  Widget _buildApiKeySetup(ThemeData theme, ColorScheme colorScheme) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.key, size: 64, color: colorScheme.primary),
                const SizedBox(height: 16),
                Text(
                  'Configure Gemini API Key',
                  style: theme.textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'Get your free API key from Google AI Studio',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _apiKeyController,
                  decoration: InputDecoration(
                    labelText: 'Gemini API Key',
                    hintText: 'Enter your API key',
                    prefixIcon: const Icon(Icons.vpn_key),
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.info_outline),
                      onPressed: () => _showApiKeyHelp(),
                    ),
                  ),
                  obscureText: true,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _saveApiKey,
                    icon: const Icon(Icons.check),
                    label: const Text('Save API Key'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMainContent(ThemeData theme, ColorScheme colorScheme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Image capture section
          _buildImageSection(theme, colorScheme),
          const SizedBox(height: 16),

          // Error message
          if (_errorMessage != null)
            Card(
              color: colorScheme.errorContainer,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: colorScheme.error),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(color: colorScheme.onErrorContainer),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Scanning indicator
          if (_isScanning)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    Text(
                      'Scanning invoice with AI...',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'This may take a few seconds',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Scanned data section
          if (_scannedData != null && !_isScanning) ...[
            const SizedBox(height: 16),
            _buildInvoiceInfoSection(theme, colorScheme),
            const SizedBox(height: 16),
            _buildSupplierSection(theme, colorScheme),
            const SizedBox(height: 16),
            _buildScannedItemsSection(theme, colorScheme),
            const SizedBox(height: 80), // Space for FAB
          ],
        ],
      ),
    );
  }

  Widget _buildImageSection(ThemeData theme, ColorScheme colorScheme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.document_scanner, color: colorScheme.primary),
                const SizedBox(width: 8),
                Text('Invoice Image', style: theme.textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 16),
            if (_selectedImage != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(
                  _selectedImage!,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              )
            else
              Container(
                height: 150,
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: colorScheme.outline,
                    style: BorderStyle.solid,
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.image_outlined,
                        size: 48,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'No image selected',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isScanning
                        ? null
                        : () => _pickImage(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Camera'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isScanning
                        ? null
                        : () => _pickImage(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Gallery'),
                  ),
                ),
              ],
            ),
            if (_selectedImage != null) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _isScanning ? null : _scanImage,
                  icon: const Icon(Icons.document_scanner),
                  label: const Text('Scan Again'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInvoiceInfoSection(ThemeData theme, ColorScheme colorScheme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.receipt_long, color: colorScheme.primary),
                const SizedBox(width: 8),
                Text('Invoice Details', style: theme.textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                if (_scannedData!.invoiceNumber != null)
                  _buildInfoChip(
                    'Invoice #',
                    _scannedData!.invoiceNumber!,
                    colorScheme,
                  ),
                if (_scannedData!.invoiceDate != null)
                  _buildInfoChip(
                    'Date',
                    DateFormat('dd/MM/yyyy').format(_scannedData!.invoiceDate!),
                    colorScheme,
                  ),
                if (_scannedData!.totalAmount != null)
                  _buildInfoChip(
                    'Total',
                    '₹${_scannedData!.totalAmount!.toStringAsFixed(2)}',
                    colorScheme,
                  ),
                if (_scannedData!.taxAmount != null)
                  _buildInfoChip(
                    'Tax',
                    '₹${_scannedData!.taxAmount!.toStringAsFixed(2)}',
                    colorScheme,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(String label, String value, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 12,
              color: colorScheme.onPrimaryContainer.withValues(alpha: 0.7),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: colorScheme.onPrimaryContainer,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSupplierSection(ThemeData theme, ColorScheme colorScheme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.business, color: colorScheme.primary),
                const SizedBox(width: 8),
                Text('Supplier', style: theme.textTheme.titleMedium),
                if (_scannedData!.supplierName != null) ...[
                  const Spacer(),
                  Text(
                    'Detected: ${_scannedData!.supplierName}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<SupplierEntity>(
              initialValue: _selectedSupplier,
              decoration: const InputDecoration(
                labelText: 'Select Supplier',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
              items: _suppliers.map((supplier) {
                return DropdownMenuItem(
                  value: supplier,
                  child: Text(supplier.fullName),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedSupplier = value;
                });
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<CompanyEntity>(
              initialValue: _selectedCompany,
              decoration: const InputDecoration(
                labelText: 'Select Company (Optional)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.apartment),
              ),
              items: _companies.map((company) {
                return DropdownMenuItem(
                  value: company,
                  child: Text(company.companyName),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedCompany = value;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScannedItemsSection(ThemeData theme, ColorScheme colorScheme) {
    final items = _scannedData!.items;
    final selectedCount = items.where((i) => i.isSelected).length;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.inventory_2, color: colorScheme.primary),
                const SizedBox(width: 8),
                Text('Scanned Items', style: theme.textTheme.titleMedium),
                const Spacer(),
                Text(
                  '$selectedCount/${items.length} selected',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      for (var item in items) {
                        item.isSelected = true;
                      }
                    });
                  },
                  icon: const Icon(Icons.select_all, size: 18),
                  label: const Text('Select All'),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                ),
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      for (var item in items) {
                        item.isSelected = false;
                      }
                    });
                  },
                  icon: const Icon(Icons.deselect, size: 18),
                  label: const Text('Deselect All'),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                ),
              ],
            ),
            const Divider(),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: items.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final item = items[index];
                return _buildItemCard(item, index, theme, colorScheme);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemCard(
    ScannedInvoiceItem item,
    int index,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    final hasMatch = item.matchedProductId != null;

    return InkWell(
      onTap: () => _toggleItemSelection(index),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Checkbox(
              value: item.isSelected,
              onChanged: (_) => _toggleItemSelection(index),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.productName,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            decoration: item.isSelected
                                ? null
                                : TextDecoration.lineThrough,
                            color: item.isSelected
                                ? null
                                : colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      if (hasMatch)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: Colors.green.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.check_circle,
                                size: 12,
                                color: Colors.green[700],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Matched',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.green[700],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  if (item.companyName != null && item.companyName!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        item.companyName!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 12,
                    runSpacing: 4,
                    children: [
                      _buildItemDetail(
                        Icons.numbers,
                        'Qty: ${item.quantity} ${item.unit ?? ''}',
                        colorScheme,
                      ),
                      _buildItemDetail(
                        Icons.payments,
                        '₹${item.purchasePrice.toStringAsFixed(2)}',
                        colorScheme,
                      ),
                      if (item.salesPrice != null)
                        _buildItemDetail(
                          Icons.sell,
                          'MRP: ₹${item.salesPrice!.toStringAsFixed(2)}',
                          colorScheme,
                        ),
                      if (item.expiryDate != null)
                        _buildItemDetail(
                          Icons.event,
                          'Exp: ${DateFormat('dd/MM/yy').format(item.expiryDate!)}',
                          colorScheme,
                        ),
                      if (item.batchNumber != null)
                        _buildItemDetail(
                          Icons.tag,
                          'Batch: ${item.batchNumber}',
                          colorScheme,
                        ),
                    ],
                  ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert, color: colorScheme.onSurfaceVariant),
              onSelected: (value) {
                if (value == 'edit') {
                  _editItem(index);
                } else if (value == 'remove') {
                  _removeItem(index);
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit),
                      SizedBox(width: 8),
                      Text('Edit'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'remove',
                  child: Row(
                    children: [
                      Icon(Icons.delete, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Remove', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemDetail(IconData icon, String text, ColorScheme colorScheme) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: colorScheme.primary),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }

  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('API Settings'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_scannerService.isConfigured) ...[
              Text('Current API Key: ${_scannerService.maskedApiKey}'),
              const SizedBox(height: 16),
            ],
            TextField(
              controller: _apiKeyController,
              decoration: const InputDecoration(
                labelText: 'New API Key',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
          ],
        ),
        actions: [
          if (_scannerService.isConfigured)
            TextButton(
              onPressed: () async {
                await _scannerService.clearApiKey();
                Navigator.of(context).pop();
                setState(() {
                  _showApiKeyInput = true;
                });
              },
              child: const Text(
                'Clear Key',
                style: TextStyle(color: Colors.red),
              ),
            ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              await _saveApiKey();
              Navigator.of(context).pop();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showApiKeyHelp() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('How to get API Key'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('1. Go to Google AI Studio'),
            Text('   (aistudio.google.com)'),
            SizedBox(height: 8),
            Text('2. Sign in with your Google account'),
            SizedBox(height: 8),
            Text('3. Click "Get API Key"'),
            SizedBox(height: 8),
            Text('4. Create a new API key'),
            SizedBox(height: 8),
            Text('5. Copy and paste it here'),
            SizedBox(height: 16),
            Text(
              'Note: The API key is stored securely on your device.',
              style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
            ),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }
}

/// Dialog for editing scanned item details
class _EditItemDialog extends StatefulWidget {
  final ScannedInvoiceItem item;
  final List<ProductEntity> products;
  final List<CompanyEntity> companies;
  final Function(ScannedInvoiceItem) onSave;

  const _EditItemDialog({
    required this.item,
    required this.products,
    required this.companies,
    required this.onSave,
  });

  @override
  State<_EditItemDialog> createState() => _EditItemDialogState();
}

class _EditItemDialogState extends State<_EditItemDialog> {
  late TextEditingController _nameController;
  late TextEditingController _quantityController;
  late TextEditingController _purchasePriceController;
  late TextEditingController _salesPriceController;
  late TextEditingController _unitController;
  late TextEditingController _batchController;

  String? _selectedCompanyName;
  String? _selectedProductId;
  DateTime? _expiryDate;
  DateTime? _productionDate;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.item.productName);
    _quantityController = TextEditingController(
      text: widget.item.quantity.toString(),
    );
    _purchasePriceController = TextEditingController(
      text: widget.item.purchasePrice.toStringAsFixed(2),
    );
    _salesPriceController = TextEditingController(
      text: widget.item.salesPrice?.toStringAsFixed(2) ?? '',
    );
    _unitController = TextEditingController(text: widget.item.unit ?? '');
    _batchController = TextEditingController(
      text: widget.item.batchNumber ?? '',
    );
    _selectedCompanyName = widget.item.companyName;
    _selectedProductId = widget.item.matchedProductId;
    _expiryDate = widget.item.expiryDate;
    _productionDate = widget.item.productionDate;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    _purchasePriceController.dispose();
    _salesPriceController.dispose();
    _unitController.dispose();
    _batchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Item'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Product matching dropdown
            DropdownButtonFormField<String?>(
              initialValue: _selectedProductId,
              decoration: const InputDecoration(
                labelText: 'Match Product',
                border: OutlineInputBorder(),
                helperText: 'Link to existing product for stock update',
              ),
              items: [
                const DropdownMenuItem(
                  value: null,
                  child: Text('-- New Product --'),
                ),
                ...widget.products.map((product) {
                  return DropdownMenuItem(
                    value: product.serverId ?? product.id.toString(),
                    child: Text(product.name),
                  );
                }),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedProductId = value;
                  if (value != null) {
                    final product = widget.products.firstWhere(
                      (p) => (p.serverId ?? p.id.toString()) == value,
                    );
                    _nameController.text = product.name;
                    _salesPriceController.text = product.salesPrice
                        .toStringAsFixed(2);
                    _unitController.text = product.unit ?? '';
                  }
                });
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Product Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _quantityController,
                    decoration: const InputDecoration(
                      labelText: 'Quantity',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _unitController,
                    decoration: const InputDecoration(
                      labelText: 'Unit',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _purchasePriceController,
                    decoration: const InputDecoration(
                      labelText: 'Purchase Price',
                      border: OutlineInputBorder(),
                      prefixText: '₹ ',
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _salesPriceController,
                    decoration: const InputDecoration(
                      labelText: 'Sales Price',
                      border: OutlineInputBorder(),
                      prefixText: '₹ ',
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Company dropdown
            DropdownButtonFormField<String?>(
              initialValue: _selectedCompanyName,
              decoration: const InputDecoration(
                labelText: 'Company',
                border: OutlineInputBorder(),
              ),
              items: [
                const DropdownMenuItem(value: null, child: Text('-- None --')),
                ...widget.companies.map((company) {
                  return DropdownMenuItem(
                    value: company.companyName,
                    child: Text(company.companyName),
                  );
                }),
                if (_selectedCompanyName != null &&
                    !widget.companies.any(
                      (c) => c.companyName == _selectedCompanyName,
                    ))
                  DropdownMenuItem(
                    value: _selectedCompanyName,
                    child: Text('${_selectedCompanyName!} (scanned)'),
                  ),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedCompanyName = value;
                });
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _batchController,
              decoration: const InputDecoration(
                labelText: 'Batch Number',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            // Dates
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _productionDate ?? DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime.now(),
                      );
                      if (date != null) {
                        setState(() => _productionDate = date);
                      }
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Production Date',
                        border: OutlineInputBorder(),
                        suffixIcon: Icon(Icons.calendar_today),
                      ),
                      child: Text(
                        _productionDate != null
                            ? DateFormat('dd/MM/yyyy').format(_productionDate!)
                            : 'Not set',
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate:
                            _expiryDate ??
                            DateTime.now().add(const Duration(days: 365)),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(
                          const Duration(days: 3650),
                        ),
                      );
                      if (date != null) {
                        setState(() => _expiryDate = date);
                      }
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Expiry Date',
                        border: OutlineInputBorder(),
                        suffixIcon: Icon(Icons.calendar_today),
                      ),
                      child: Text(
                        _expiryDate != null
                            ? DateFormat('dd/MM/yyyy').format(_expiryDate!)
                            : 'Not set',
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            final updatedItem = widget.item.copyWith(
              productName: _nameController.text,
              quantity:
                  int.tryParse(_quantityController.text) ??
                  widget.item.quantity,
              purchasePrice:
                  double.tryParse(_purchasePriceController.text) ??
                  widget.item.purchasePrice,
              salesPrice: double.tryParse(_salesPriceController.text),
              unit: _unitController.text.isNotEmpty
                  ? _unitController.text
                  : null,
              companyName: _selectedCompanyName,
              batchNumber: _batchController.text.isNotEmpty
                  ? _batchController.text
                  : null,
              matchedProductId: _selectedProductId,
              productionDate: _productionDate,
              expiryDate: _expiryDate,
            );
            widget.onSave(updatedItem);
            Navigator.of(context).pop();
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}

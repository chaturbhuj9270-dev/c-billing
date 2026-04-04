import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:c_billing/core/services/inventory_service.dart';
import 'package:c_billing/core/services/language_service.dart';
import 'package:c_billing/core/services/dashboard_refresh_service.dart';
import 'package:c_billing/core/services/purchase_settings_service.dart';
import 'package:c_billing/core/services/product_settings_service.dart';
import 'package:c_billing/core/localization/app_localizations.dart';
import '../../data/repositories/firebase_product_repository.dart';
import '../../data/repositories/firebase_stock_repository.dart';
import '../../data/repositories/firebase_purchase_repository.dart';
import '../../data/datasources/purchase_cache_datasource.dart';
import '../../domain/entities/product.dart';
import '../../data/services/purchase_sync_service.dart';
import '../../data/services/purchase_batch_sync_service.dart';
import '../../../product/offline/controllers/product_offline_controller.dart';
import '../../../product/data/services/product_sync_service.dart';
import '../../../supplier/offline/controllers/supplier_offline_controller.dart';
import '../../../supplier/offline/entities/supplier_entity.dart';
import '../../../supplier/data/services/supplier_sync_service.dart';
import '../../../company/offline/controllers/company_offline_controller.dart';
import '../../../company/offline/entities/company_entity.dart';
import '../../../company/data/services/company_sync_service.dart';
import '../../../product/offline/entities/product_entity.dart';
import '../../../../core/services/inventory_integration_service.dart';
import 'purchase_settings_page.dart';
import 'invoice_scanner_page.dart';
import 'package:c_billing/core/ui/glassy_toast.dart';

class PurchasePage extends StatefulWidget {
  final bool isEmbedded;

  const PurchasePage({super.key, this.isEmbedded = false});

  @override
  State<PurchasePage> createState() => _PurchasePageState();
}

class _PurchasePageState extends State<PurchasePage>
    with SingleTickerProviderStateMixin {
  // ignore: unused_field
  late InventoryService _inventoryService;
  late FirebaseFirestore _firestore;
  late AnimationController _animController;
  late Animation<Offset> _offsetAnimation;
  late Animation<double> _opacityAnimation;
  late AppLocalizations _localizations;
  final _cacheDataSource = PurchaseCacheDataSource();

  // Real-time Isar stream subscriptions
  StreamSubscription<List<ProductEntity>>? _productStreamSubscription;
  StreamSubscription<List<SupplierEntity>>? _supplierStreamSubscription;
  StreamSubscription<List<CompanyEntity>>? _companyStreamSubscription;

  Product? _selectedProduct;
  Map<String, dynamic>? _selectedSupplier;
  Map<String, dynamic>? _selectedCompany;
  DateTime? _productionDate;
  DateTime? _expiryDate;
  String? _selectedUnit;
  int? _selectedWarranty;

  final _quantityController = TextEditingController();
  final _priceController = TextEditingController();
  final _salesPriceController = TextEditingController();
  final _notesController = TextEditingController();
  final _productSearchController = TextEditingController();
  final _supplierSearchController = TextEditingController();
  final _companySearchController = TextEditingController();
  final _productionDateController = TextEditingController();
  final _expiryDateController = TextEditingController();

  // For adding new supplier/company
  final _newSupplierFirstNameController = TextEditingController();
  final _newSupplierLastNameController = TextEditingController();
  final _newSupplierContactController = TextEditingController();
  final _newSupplierAddressController = TextEditingController();

  final _newCompanyNameController = TextEditingController();
  final _newCompanyContactController = TextEditingController();
  final _newCompanyAddressController = TextEditingController();
  final _newCompanyGstCodeController = TextEditingController();

  bool _isLoading = false;
  List<Product> _products = [];
  List<Product> _filteredProducts = [];
  List<Map<String, dynamic>> _suppliers = [];
  List<Map<String, dynamic>> _filteredSuppliers = [];
  List<Map<String, dynamic>> _companies = [];
  List<Map<String, dynamic>> _filteredCompanies = [];

  // Scroll tracking for bottom button
  final ScrollController _scrollController = ScrollController();
  bool _hasScrolledToBottom = false;

  @override
  void initState() {
    super.initState();
    _firestore = FirebaseFirestore.instance;
    _localizations = AppLocalizations.of(
      LanguageService.instance.currentLanguage,
    );

    // Listen for language changes
    LanguageService.instance.addListener(_onLanguageChanged);

    // Listen for purchase settings changes
    PurchaseSettingsService.instance.addListener(_onPurchaseSettingsChanged);

    // Initialize selected unit with default
    _selectedUnit = PurchaseSettingsService.instance.defaultUnit;

    // Initialize selected warranty with default
    _selectedWarranty = PurchaseSettingsService.instance.defaultWarranty;

    _inventoryService = InventoryService(
      productRepository: FirebaseProductRepository(firestore: _firestore),
      stockRepository: FirebaseStockRepository(firestore: _firestore),
      purchaseRepository: FirebasePurchaseRepository(firestore: _firestore),
    );

    // Initialize animations
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeIn));
    Future.delayed(
      const Duration(milliseconds: 150),
      () => _animController.forward(),
    );

    // Setup real-time Isar streams for instant UI updates
    _setupProductStream();
    _setupSupplierStream();
    _setupCompanyStream();

    // Setup scroll listener to track when user scrolls to bottom
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.hasClients) {
      final maxScroll = _scrollController.position.maxScrollExtent;
      final currentScroll = _scrollController.offset;
      // Consider "scrolled to bottom" when within 50 pixels of the end
      final isAtBottom = currentScroll >= maxScroll - 50;
      if (isAtBottom != _hasScrolledToBottom) {
        setState(() {
          _hasScrolledToBottom = isAtBottom;
        });
      }
    }
  }

  void _onLanguageChanged() {
    if (mounted) {
      setState(() {
        _localizations = AppLocalizations.of(
          LanguageService.instance.currentLanguage,
        );
      });
    }
  }

  void _onPurchaseSettingsChanged() {
    if (mounted) {
      setState(() {
        // Always update to the new default unit when settings change
        // This ensures immediate effect when user changes default unit in settings
        _selectedUnit = PurchaseSettingsService.instance.defaultUnit;

        // Always update to the new default warranty when settings change
        _selectedWarranty = PurchaseSettingsService.instance.defaultWarranty;
      });
    }
  }

  /// Setup real-time product stream from Isar
  void _setupProductStream() {
    _productStreamSubscription = ProductOfflineController.instance
        .watchAllProducts()
        .listen((entities) {
          if (!mounted) return;
          final products = entities
              .map(
                (entity) => Product(
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
                  defaultSupplierId: entity.defaultSupplierId,
                  defaultSupplierName: entity.defaultSupplierName,
                ),
              )
              .toList();
          setState(() {
            _products = products;
            _filteredProducts = products;
          });
          _cacheDataSource.saveProducts(products);
          print('[Purchase] Product stream: ${products.length} products');
        }, onError: (e) => print('[ERROR] Product stream error: $e'));
  }

  /// Setup real-time supplier stream from Isar
  void _setupSupplierStream() {
    _supplierStreamSubscription = SupplierOfflineController.instance
        .watchAllSuppliers()
        .listen((entities) {
          if (!mounted) return;
          final suppliers = entities
              .map(
                (entity) => <String, dynamic>{
                  'id': entity.serverId ?? entity.id.toString(),
                  'firstName': entity.firstName,
                  'lastName': entity.lastName,
                  'fullName': '${entity.firstName} ${entity.lastName}'.trim(),
                },
              )
              .toList();
          setState(() {
            _suppliers = suppliers;
            _filteredSuppliers = suppliers;
          });
          _cacheDataSource.saveSuppliers(suppliers);
          print('[Purchase] Supplier stream: ${suppliers.length} suppliers');
        }, onError: (e) => print('[ERROR] Supplier stream error: $e'));
  }

  /// Setup real-time company stream from Isar
  void _setupCompanyStream() {
    _companyStreamSubscription = CompanyOfflineController.instance
        .watchAllCompanies()
        .listen((entities) {
          if (!mounted) return;
          final companies = entities
              .map(
                (entity) => <String, dynamic>{
                  'id': entity.serverId ?? entity.id.toString(),
                  'companyName': entity.companyName,
                },
              )
              .toList();
          setState(() {
            _companies = companies;
            _filteredCompanies = companies;
          });
          _cacheDataSource.saveCompanies(companies);
          print('[Purchase] Company stream: ${companies.length} companies');
        }, onError: (e) => print('[ERROR] Company stream error: $e'));
  }

  Future<void> _addNewProduct() async {
    final nameController = TextEditingController();
    final purchasePriceController = TextEditingController();
    final salesPriceController = TextEditingController();
    final cgstController = TextEditingController();
    final sgstController = TextEditingController();
    final hsnController = TextEditingController();
    Map<String, dynamic>? sheetSelectedCompany;
    Map<String, dynamic>? sheetSelectedSupplier;

    // Sync CGST and SGST values
    bool isSyncingGst = false;
    cgstController.addListener(() {
      if (!isSyncingGst && cgstController.text != sgstController.text) {
        isSyncingGst = true;
        sgstController.text = cgstController.text;
        isSyncingGst = false;
      }
    });
    sgstController.addListener(() {
      if (!isSyncingGst && sgstController.text != cgstController.text) {
        isSyncingGst = true;
        cgstController.text = sgstController.text;
        isSyncingGst = false;
      }
    });

    // Custom fields controllers and values
    final customColumns = ProductSettingsService.instance.activeCustomColumns;
    final Map<String, TextEditingController> customTextControllers = {};
    final Map<String, dynamic> customFieldValues = {};

    // Initialize controllers for custom fields
    for (final column in customColumns) {
      if (column.type == CustomColumnType.text ||
          column.type == CustomColumnType.number ||
          column.type == CustomColumnType.decimal) {
        customTextControllers[column.id] = TextEditingController(
          text: column.defaultValue ?? '',
        );
      } else if (column.type == CustomColumnType.boolean) {
        customFieldValues[column.id] = column.defaultValue == 'true';
      } else if (column.type == CustomColumnType.dropdown) {
        customFieldValues[column.id] =
            column.defaultValue ??
            ((column.dropdownOptions?.isNotEmpty ?? false)
                ? column.dropdownOptions!.first
                : '');
      } else if (column.type == CustomColumnType.date) {
        customFieldValues[column.id] = column.defaultValue;
      }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Container(
          height: MediaQuery.of(context).size.height * 0.9,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: Column(
            children: [
              // Drag handle
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFFf093fb),
                            const Color(0xFFf093fb).withValues(alpha: 0.8),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.inventory_2_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _localizations.addNewProduct,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'Literata',
                              color: Color(0xFF1B4D3E),
                            ),
                          ),
                          Text(
                            _localizations.createNewProductRecord,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[500],
                              fontFamily: 'Literata',
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.close,
                          size: 20,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(height: 1, color: Colors.grey[200]),
              // Scrollable content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Product Name
                      _buildBottomSheetTextField(
                        controller: nameController,
                        label: _localizations.productName,
                        hint: _localizations.enterProductName,
                        icon: Icons.inventory_2_outlined,
                        isRequired: true,
                        onChanged: (_) => setSheetState(() {}),
                      ),
                      const SizedBox(height: 16),
                      // Company selector
                      _buildSelectorField(
                        label: _localizations.selectCompany,
                        value: sheetSelectedCompany?['companyName'],
                        icon: Icons.business_outlined,
                        color: const Color(0xFF7B68EE),
                        onTap: () async {
                          final company = await _showInlineCompanyPicker(
                            context,
                          );
                          if (company != null) {
                            setSheetState(() {
                              sheetSelectedCompany = company;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      // Supplier selector
                      _buildSelectorField(
                        label: _localizations.selectSupplier,
                        value: sheetSelectedSupplier?['fullName'],
                        icon: Icons.person_outline,
                        color: const Color(0xFFFF6B6B),
                        onTap: () async {
                          final supplier = await _showInlineSupplierPicker(
                            context,
                          );
                          if (supplier != null) {
                            setSheetState(() {
                              sheetSelectedSupplier = supplier;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      // Prices row
                      Row(
                        children: [
                          Expanded(
                            child: _buildBottomSheetTextField(
                              controller: purchasePriceController,
                              label: _localizations.purchasePrice,
                              hint: '0.00',
                              icon: Icons.shopping_cart_outlined,
                              keyboardType: TextInputType.number,
                              onChanged: (_) => setSheetState(() {}),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildBottomSheetTextField(
                              controller: salesPriceController,
                              label: _localizations.salesPrice,
                              hint: '0.00',
                              icon: Icons.sell_outlined,
                              keyboardType: TextInputType.number,
                              onChanged: (_) => setSheetState(() {}),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // GST row
                      Row(
                        children: [
                          Expanded(
                            child: _buildBottomSheetTextField(
                              controller: cgstController,
                              label: 'CGST %',
                              hint: '0',
                              icon: Icons.percent,
                              keyboardType: TextInputType.number,
                              onChanged: (_) => setSheetState(() {}),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildBottomSheetTextField(
                              controller: sgstController,
                              label: 'SGST %',
                              hint: '0',
                              icon: Icons.percent,
                              keyboardType: TextInputType.number,
                              onChanged: (_) => setSheetState(() {}),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // HSN Code
                      _buildBottomSheetTextField(
                        controller: hsnController,
                        label: _localizations.hsnCode,
                        hint: 'e.g. 30049099',
                        icon: Icons.tag,
                        keyboardType: TextInputType.number,
                        maxLength: 8,
                        onChanged: (_) => setSheetState(() {}),
                      ),
                      // Custom Fields Section
                      if (customColumns.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        ...customColumns.map((column) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _buildCustomFieldWidgetForPurchase(
                              column,
                              customTextControllers[column.id],
                              customFieldValues,
                              setSheetState,
                            ),
                          );
                        }),
                      ],
                      const SizedBox(height: 24),
                      // Action buttons
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(context),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.grey[700],
                                side: BorderSide(color: Colors.grey[300]!),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                _localizations.cancel,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontFamily: 'Literata',
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: ElevatedButton(
                              onPressed: nameController.text.trim().isEmpty
                                  ? null
                                  : () => _saveNewProduct(
                                      context,
                                      nameController,
                                      purchasePriceController,
                                      salesPriceController,
                                      cgstController,
                                      sgstController,
                                      hsnController,
                                      sheetSelectedCompany,
                                      sheetSelectedSupplier,
                                      customColumns,
                                      customTextControllers,
                                      customFieldValues,
                                    ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1B4D3E),
                                foregroundColor: Colors.white,
                                disabledBackgroundColor: Colors.grey[300],
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 0,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.add_rounded, size: 20),
                                  const SizedBox(width: 8),
                                  Text(
                                    _localizations.addProduct,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontFamily: 'Literata',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Save new product from bottom sheet
  Future<void> _saveNewProduct(
    BuildContext sheetContext,
    TextEditingController nameController,
    TextEditingController purchasePriceController,
    TextEditingController salesPriceController,
    TextEditingController cgstController,
    TextEditingController sgstController,
    TextEditingController hsnController,
    Map<String, dynamic>? selectedCompany,
    Map<String, dynamic>? selectedSupplier,
    List<CustomColumn> customColumns,
    Map<String, TextEditingController> customTextControllers,
    Map<String, dynamic> customFieldValues,
  ) async {
    try {
      // Validate HSN: required if CGST or SGST > 0
      final cgstVal = double.tryParse(cgstController.text) ?? 0.0;
      final sgstVal = double.tryParse(sgstController.text) ?? 0.0;
      final hsnVal = hsnController.text.trim();
      if ((cgstVal > 0 || sgstVal > 0) && hsnVal.isEmpty) {
        GlassyToast.show(
          sheetContext,
          _localizations.hsnCodeRequired,
          isError: true,
        );
        return;
      }

      // Collect custom field values
      final Map<String, dynamic> finalCustomFields = {};
      for (final column in customColumns) {
        String? value;
        if (column.type == CustomColumnType.text ||
            column.type == CustomColumnType.number ||
            column.type == CustomColumnType.decimal) {
          value = customTextControllers[column.id]?.text.trim();
        } else if (column.type == CustomColumnType.boolean) {
          value = (customFieldValues[column.id] ?? false).toString();
        } else if (column.type == CustomColumnType.dropdown ||
            column.type == CustomColumnType.date) {
          value = customFieldValues[column.id]?.toString();
        }
        if (value != null && value.isNotEmpty) {
          finalCustomFields[column.id] = value;
        }
      }

      // Convert to JSON string
      String? customFieldsJson;
      if (finalCustomFields.isNotEmpty) {
        customFieldsJson = jsonEncode(finalCustomFields);
      }

      // Use offline controller for consistent offline-first behavior
      final productOfflineController = ProductOfflineController.instance;

      // This will throw if duplicate exists
      final newProduct = await productOfflineController.addProduct(
        name: nameController.text.trim(),
        companyName: selectedCompany?['companyName'] ?? '',
        category: '', // No category required
        purchasePrice: double.tryParse(purchasePriceController.text) ?? 0.0,
        salesPrice: double.tryParse(salesPriceController.text) ?? 0.0,
        currentStock: 0,
        defaultSupplierId: selectedSupplier?['id'],
        defaultSupplierName: selectedSupplier?['fullName'],
        cgstPercent: cgstVal,
        sgstPercent: sgstVal,
        hsnCode: hsnVal.isNotEmpty ? hsnVal : null,
        customFieldsJson: customFieldsJson,
      );

      // Notify other screens about the product change
      DashboardRefreshService.instance.notifyDataChanged(
        DataChangeType.product,
      );

      // Trigger background sync if online
      ProductSyncService.instance.syncNow();

      if (mounted) {
        if (sheetContext.mounted) {
          Navigator.pop(sheetContext);
        }
        // Stream auto-updates products, just wait a tick for UI
        await Future.delayed(const Duration(milliseconds: 100));
        // Select the newly added product (last one in list)
        if (_products.isNotEmpty) {
          setState(() {
            _selectedProduct = _products.last;
            _priceController.text = _selectedProduct!.purchasePrice.toString();
            _salesPriceController.text = _selectedProduct!.salesPrice
                .toString();
            // Auto-populate company and supplier from the newly created product
            if (selectedCompany != null) {
              _selectedCompany = selectedCompany;
            }
            if (selectedSupplier != null) {
              _selectedSupplier = selectedSupplier;
            }
          });
        }
        if (mounted) {
          GlassyToast.show(context, '#${newProduct.indexNo}');
        }
      }
    } catch (e) {
      if (mounted && sheetContext.mounted) {
        GlassyToast.show(
          sheetContext,
          '${_localizations.error}: $e',
          isError: true,
        );
      }
    }
  }

  /// Builds a selector field for company/supplier selection
  Widget _buildSelectorField({
    required String label,
    required String? value,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    final hasValue = value != null && value.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1B4D3E),
            fontFamily: 'Literata',
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            decoration: BoxDecoration(
              border: Border.all(
                color: hasValue ? color : Colors.grey[300]!,
                width: hasValue ? 2 : 1,
              ),
              borderRadius: BorderRadius.circular(12),
              color: hasValue ? color.withValues(alpha: 0.05) : Colors.grey[50],
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: hasValue
                        ? color.withValues(alpha: 0.15)
                        : Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: hasValue ? color : Colors.grey[500],
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    value ?? _localizations.tapToSelect,
                    style: TextStyle(
                      fontFamily: 'Literata',
                      color: hasValue ? Colors.black87 : Colors.grey[500],
                      fontSize: 14,
                      fontWeight: hasValue
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: Colors.grey[400],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Build a custom field widget based on column type (for purchase page)
  Widget _buildCustomFieldWidgetForPurchase(
    CustomColumn column,
    TextEditingController? textController,
    Map<String, dynamic> fieldValues,
    StateSetter setDialogState,
  ) {
    final primaryColor = const Color(0xFF1B4D3E);

    switch (column.type) {
      case CustomColumnType.text:
        return TextField(
          controller: textController,
          decoration: InputDecoration(
            labelText: column.name + (column.isRequired ? ' *' : ''),
            hintText:
                column.placeholder ?? 'Enter ${column.name.toLowerCase()}',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: primaryColor, width: 2),
            ),
            prefixIcon: const Icon(Icons.text_fields_rounded, size: 20),
          ),
        );

      case CustomColumnType.number:
        return TextField(
          controller: textController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: column.name + (column.isRequired ? ' *' : ''),
            hintText:
                column.placeholder ?? 'Enter ${column.name.toLowerCase()}',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: primaryColor, width: 2),
            ),
            prefixIcon: const Icon(Icons.numbers_rounded, size: 20),
          ),
        );

      case CustomColumnType.decimal:
        return TextField(
          controller: textController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: column.name + (column.isRequired ? ' *' : ''),
            hintText:
                column.placeholder ?? 'Enter ${column.name.toLowerCase()}',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: primaryColor, width: 2),
            ),
            prefixIcon: const Icon(Icons.percent_rounded, size: 20),
          ),
        );

      case CustomColumnType.date:
        final currentValue = fieldValues[column.id] as String?;
        DateTime? selectedDate;
        if (currentValue != null && currentValue.isNotEmpty) {
          try {
            selectedDate = DateTime.parse(currentValue);
          } catch (_) {}
        }
        return InkWell(
          onTap: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: selectedDate ?? DateTime.now(),
              firstDate: DateTime(2000),
              lastDate: DateTime(2100),
              builder: (context, child) {
                return Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: ColorScheme.light(primary: primaryColor),
                  ),
                  child: child!,
                );
              },
            );
            if (date != null) {
              setDialogState(() {
                fieldValues[column.id] = date
                    .toIso8601String()
                    .split('T')
                    .first;
              });
            }
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            decoration: BoxDecoration(
              border: Border.all(
                color: currentValue != null ? primaryColor : Colors.grey[400]!,
                width: currentValue != null ? 2 : 1,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today_rounded,
                  color: currentValue != null ? primaryColor : Colors.grey,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    currentValue ??
                        column.placeholder ??
                        'Select ${column.name.toLowerCase()}',
                    style: TextStyle(
                      fontFamily: 'Literata',
                      color: currentValue != null
                          ? Colors.black87
                          : Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ),
                Text(
                  column.name + (column.isRequired ? ' *' : ''),
                  style: TextStyle(
                    fontFamily: 'Literata',
                    color: Colors.grey[500],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        );

      case CustomColumnType.dropdown:
        final currentValue = fieldValues[column.id] as String?;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(
              color: currentValue != null && currentValue.isNotEmpty
                  ? primaryColor
                  : Colors.grey[400]!,
              width: currentValue != null && currentValue.isNotEmpty ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: currentValue,
              hint: Text(
                column.placeholder ?? 'Select ${column.name.toLowerCase()}',
                style: TextStyle(
                  fontFamily: 'Literata',
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
              isExpanded: true,
              icon: Icon(Icons.arrow_drop_down, color: Colors.grey[600]),
              items: (column.dropdownOptions ?? []).map((option) {
                return DropdownMenuItem<String>(
                  value: option,
                  child: Text(
                    option,
                    style: const TextStyle(
                      fontFamily: 'Literata',
                      fontSize: 14,
                    ),
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setDialogState(() {
                  fieldValues[column.id] = value;
                });
              },
            ),
          ),
        );

      case CustomColumnType.boolean:
        final currentValue = fieldValues[column.id] as bool? ?? false;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            border: Border.all(
              color: currentValue ? primaryColor : Colors.grey[400]!,
              width: currentValue ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(
                Icons.toggle_on_rounded,
                color: currentValue ? primaryColor : Colors.grey,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  column.name + (column.isRequired ? ' *' : ''),
                  style: const TextStyle(fontFamily: 'Literata', fontSize: 14),
                ),
              ),
              Switch(
                value: currentValue,
                activeThumbColor: primaryColor,
                onChanged: (value) {
                  setDialogState(() {
                    fieldValues[column.id] = value;
                  });
                },
              ),
            ],
          ),
        );
    }
  }

  /// Inline company picker for use inside dialogs
  Future<Map<String, dynamic>?> _showInlineCompanyPicker(
    BuildContext parentContext,
  ) async {
    return await showDialog<Map<String, dynamic>>(
      context: parentContext,
      builder: (context) {
        var filtered = _companies.toList();
        return StatefulBuilder(
          builder: (context, setPickerState) => AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Text(
              _localizations.selectCompany,
              style: const TextStyle(
                fontFamily: 'Literata',
                fontWeight: FontWeight.w700,
                color: Color(0xFF1B4D3E),
                fontSize: 16,
              ),
            ),
            content: SizedBox(
              width: double.maxFinite,
              height: 300,
              child: Column(
                children: [
                  TextField(
                    decoration: InputDecoration(
                      hintText: _localizations.searchByCompany,
                      prefixIcon: const Icon(Icons.search, size: 20),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      isDense: true,
                    ),
                    onChanged: (q) {
                      setPickerState(() {
                        filtered = _companies
                            .where(
                              (c) => (c['companyName'] as String? ?? '')
                                  .toLowerCase()
                                  .contains(q.toLowerCase()),
                            )
                            .toList();
                      });
                    },
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: filtered.isEmpty
                        ? Center(
                            child: Text(
                              _localizations.noCompaniesFound,
                              style: TextStyle(
                                color: Colors.grey[500],
                                fontFamily: 'Literata',
                              ),
                            ),
                          )
                        : ListView.builder(
                            itemCount: filtered.length,
                            itemBuilder: (context, index) {
                              final company = filtered[index];
                              return ListTile(
                                dense: true,
                                leading: const Icon(
                                  Icons.business,
                                  color: Color(0xFF1B4D3E),
                                  size: 20,
                                ),
                                title: Text(
                                  company['companyName'] ?? '',
                                  style: const TextStyle(
                                    fontFamily: 'Literata',
                                    fontSize: 14,
                                  ),
                                ),
                                onTap: () => Navigator.pop(context, company),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// Inline supplier picker for use inside dialogs
  Future<Map<String, dynamic>?> _showInlineSupplierPicker(
    BuildContext parentContext,
  ) async {
    return await showDialog<Map<String, dynamic>>(
      context: parentContext,
      builder: (context) {
        var filtered = _suppliers.toList();
        return StatefulBuilder(
          builder: (context, setPickerState) => AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Text(
              _localizations.selectSupplier,
              style: const TextStyle(
                fontFamily: 'Literata',
                fontWeight: FontWeight.w700,
                color: Color(0xFF1B4D3E),
                fontSize: 16,
              ),
            ),
            content: SizedBox(
              width: double.maxFinite,
              height: 300,
              child: Column(
                children: [
                  TextField(
                    decoration: InputDecoration(
                      hintText: _localizations.searchBySupplier,
                      prefixIcon: const Icon(Icons.search, size: 20),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      isDense: true,
                    ),
                    onChanged: (q) {
                      setPickerState(() {
                        filtered = _suppliers
                            .where(
                              (s) => (s['fullName'] as String? ?? '')
                                  .toLowerCase()
                                  .contains(q.toLowerCase()),
                            )
                            .toList();
                      });
                    },
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: filtered.isEmpty
                        ? Center(
                            child: Text(
                              _localizations.noSuppliersFound,
                              style: TextStyle(
                                color: Colors.grey[500],
                                fontFamily: 'Literata',
                              ),
                            ),
                          )
                        : ListView.builder(
                            itemCount: filtered.length,
                            itemBuilder: (context, index) {
                              final supplier = filtered[index];
                              return ListTile(
                                dense: true,
                                leading: const Icon(
                                  Icons.person,
                                  color: Color(0xFF1B4D3E),
                                  size: 20,
                                ),
                                title: Text(
                                  supplier['fullName'] ?? '',
                                  style: const TextStyle(
                                    fontFamily: 'Literata',
                                    fontSize: 14,
                                  ),
                                ),
                                onTap: () => Navigator.pop(context, supplier),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _filterProducts(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredProducts = _products;
      } else {
        _filteredProducts = _products
            .where(
              (product) =>
                  product.name.toLowerCase().contains(query.toLowerCase()) ||
                  product.companyName.toLowerCase().contains(
                    query.toLowerCase(),
                  ) ||
                  product.category.toLowerCase().contains(query.toLowerCase()),
            )
            .toList();
      }
    });
  }

  void _filterSuppliers(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredSuppliers = _suppliers;
      } else {
        _filteredSuppliers = _suppliers
            .where(
              (supplier) =>
                  supplier['fullName'].toLowerCase().contains(
                    query.toLowerCase(),
                  ) ||
                  supplier['firstName'].toLowerCase().contains(
                    query.toLowerCase(),
                  ) ||
                  supplier['lastName'].toLowerCase().contains(
                    query.toLowerCase(),
                  ),
            )
            .toList();
      }
    });
  }

  void _filterCompanies(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredCompanies = _companies;
      } else {
        _filteredCompanies = _companies
            .where(
              (company) => company['companyName'].toLowerCase().contains(
                query.toLowerCase(),
              ),
            )
            .toList();
      }
    });
  }

  void _showProductSelectionBottomSheet() {
    _productSearchController.clear();
    _filteredProducts = _products;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Drag handle
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
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF1B4D3E),
                            const Color(0xFF1B4D3E).withValues(alpha: 0.8),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.inventory_2_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _localizations.selectProduct,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'Literata',
                              color: Color(0xFF1B4D3E),
                            ),
                          ),
                          Text(
                            '${_products.length} products available',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[500],
                              fontFamily: 'Literata',
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.close,
                          size: 20,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Search bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: TextField(
                    controller: _productSearchController,
                    decoration: InputDecoration(
                      hintText: _localizations.searchByProduct,
                      hintStyle: TextStyle(
                        color: Colors.grey[400],
                        fontFamily: 'Literata',
                      ),
                      prefixIcon: Icon(
                        Icons.search_rounded,
                        color: Colors.grey[400],
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                    onChanged: (query) {
                      _filterProducts(query);
                      setModalState(() {});
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Divider
              Container(height: 1, color: Colors.grey[200]),
              // Product list
              Expanded(
                child: _filteredProducts.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.inventory_2_outlined,
                              size: 64,
                              color: Colors.grey[300],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _productSearchController.text.isEmpty
                                  ? _localizations.noProductsAvailable
                                  : _localizations.noProductsFound,
                              style: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 15,
                                fontFamily: 'Literata',
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        itemCount: _filteredProducts.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final product = _filteredProducts[index];
                          final isSelected = _selectedProduct?.id == product.id;
                          return Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                setState(() {
                                  _selectedProduct = product;
                                  _priceController.text = product.purchasePrice
                                      .toString();
                                  _salesPriceController.text = product
                                      .salesPrice
                                      .toString();

                                  // Auto-populate company from product
                                  if (product.companyName.isNotEmpty) {
                                    final matchingCompany = _companies
                                        .firstWhere(
                                          (c) =>
                                              (c['companyName'] as String?)
                                                  ?.toLowerCase() ==
                                              product.companyName.toLowerCase(),
                                          orElse: () => <String, dynamic>{},
                                        );
                                    if (matchingCompany.isNotEmpty) {
                                      _selectedCompany = matchingCompany;
                                    }
                                  }

                                  // Auto-populate supplier from product's default supplier
                                  if (product.defaultSupplierId != null &&
                                      product.defaultSupplierId!.isNotEmpty) {
                                    final matchingSupplier = _suppliers
                                        .firstWhere(
                                          (s) =>
                                              s['id'] ==
                                              product.defaultSupplierId,
                                          orElse: () => <String, dynamic>{},
                                        );
                                    if (matchingSupplier.isNotEmpty) {
                                      _selectedSupplier = matchingSupplier;
                                    }
                                  }
                                });
                                Navigator.pop(context);
                              },
                              borderRadius: BorderRadius.circular(14),
                              child: Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? const Color(
                                          0xFF1B4D3E,
                                        ).withValues(alpha: 0.08)
                                      : Colors.grey[50],
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: isSelected
                                        ? const Color(0xFF1B4D3E)
                                        : Colors.grey[200]!,
                                    width: isSelected ? 1.5 : 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 48,
                                      height: 48,
                                      decoration: BoxDecoration(
                                        color: const Color(
                                          0xFF1B4D3E,
                                        ).withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Icon(
                                        Icons.inventory_2_rounded,
                                        color: Color(0xFF1B4D3E),
                                        size: 22,
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            product.name,
                                            style: const TextStyle(
                                              fontFamily: 'Literata',
                                              fontWeight: FontWeight.w600,
                                              fontSize: 15,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              if (product
                                                  .companyName
                                                  .isNotEmpty)
                                                Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 2,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color: Colors.blue
                                                        .withValues(alpha: 0.1),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          6,
                                                        ),
                                                  ),
                                                  child: Text(
                                                    product.companyName,
                                                    style: const TextStyle(
                                                      fontSize: 11,
                                                      color: Colors.blue,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                  ),
                                                ),
                                              if (product
                                                  .companyName
                                                  .isNotEmpty)
                                                const SizedBox(width: 8),
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 2,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color:
                                                      product.currentStock > 0
                                                      ? Colors.green.withValues(
                                                          alpha: 0.1,
                                                        )
                                                      : Colors.red.withValues(
                                                          alpha: 0.1,
                                                        ),
                                                  borderRadius:
                                                      BorderRadius.circular(6),
                                                ),
                                                child: Text(
                                                  '${_localizations.stock}: ${product.currentStock}',
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    color:
                                                        product.currentStock > 0
                                                        ? Colors.green[700]
                                                        : Colors.red[700],
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          '₹${product.purchasePrice}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                            color: Color(0xFF1B4D3E),
                                            fontSize: 16,
                                          ),
                                        ),
                                        Text(
                                          _localizations.perUnit,
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.grey[400],
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (isSelected) ...[
                                      const SizedBox(width: 8),
                                      const Icon(
                                        Icons.check_circle,
                                        color: Color(0xFF1B4D3E),
                                        size: 22,
                                      ),
                                    ],
                                  ],
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
      ),
    );
  }

  void _showSupplierSelectionBottomSheet() {
    _supplierSearchController.clear();
    _filteredSuppliers = _suppliers;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          height: MediaQuery.of(context).size.height * 0.75,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Drag handle
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
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFFFF6B6B),
                            const Color(0xFFFF6B6B).withValues(alpha: 0.8),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.person_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _localizations.selectSupplier,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'Literata',
                              color: Color(0xFF1B4D3E),
                            ),
                          ),
                          Text(
                            '${_suppliers.length} suppliers available',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[500],
                              fontFamily: 'Literata',
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.close,
                          size: 20,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Search bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: TextField(
                    controller: _supplierSearchController,
                    decoration: InputDecoration(
                      hintText: _localizations.searchBySupplier,
                      hintStyle: TextStyle(
                        color: Colors.grey[400],
                        fontFamily: 'Literata',
                      ),
                      prefixIcon: Icon(
                        Icons.search_rounded,
                        color: Colors.grey[400],
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                    onChanged: (query) {
                      _filterSuppliers(query);
                      setModalState(() {});
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Divider
              Container(height: 1, color: Colors.grey[200]),
              // Supplier list
              Expanded(
                child: _filteredSuppliers.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.person_off_outlined,
                              size: 64,
                              color: Colors.grey[300],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _supplierSearchController.text.isEmpty
                                  ? _localizations.noSuppliersAvailable
                                  : _localizations.noSuppliersFound,
                              style: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 15,
                                fontFamily: 'Literata',
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        itemCount: _filteredSuppliers.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final supplier = _filteredSuppliers[index];
                          final isSelected =
                              _selectedSupplier?['id'] == supplier['id'];
                          return Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                setState(() {
                                  _selectedSupplier = supplier;
                                });
                                Navigator.pop(context);
                              },
                              borderRadius: BorderRadius.circular(14),
                              child: Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? const Color(
                                          0xFFFF6B6B,
                                        ).withValues(alpha: 0.08)
                                      : Colors.grey[50],
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: isSelected
                                        ? const Color(0xFFFF6B6B)
                                        : Colors.grey[200]!,
                                    width: isSelected ? 1.5 : 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 48,
                                      height: 48,
                                      decoration: BoxDecoration(
                                        color: const Color(
                                          0xFFFF6B6B,
                                        ).withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Center(
                                        child: Text(
                                          (supplier['fullName'] as String)
                                                  .isNotEmpty
                                              ? (supplier['fullName'] as String)
                                                    .substring(0, 1)
                                                    .toUpperCase()
                                              : 'S',
                                          style: const TextStyle(
                                            color: Color(0xFFFF6B6B),
                                            fontWeight: FontWeight.w700,
                                            fontSize: 20,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Text(
                                        supplier['fullName'],
                                        style: const TextStyle(
                                          fontFamily: 'Literata',
                                          fontWeight: FontWeight.w600,
                                          fontSize: 15,
                                        ),
                                      ),
                                    ),
                                    if (isSelected)
                                      const Icon(
                                        Icons.check_circle,
                                        color: Color(0xFFFF6B6B),
                                        size: 22,
                                      ),
                                  ],
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
      ),
    );
  }

  void _showCompanySelectionBottomSheet() {
    _companySearchController.clear();
    _filteredCompanies = _companies;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          height: MediaQuery.of(context).size.height * 0.75,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Drag handle
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
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF7B68EE),
                            const Color(0xFF7B68EE).withValues(alpha: 0.8),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.business_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _localizations.selectCompany,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'Literata',
                              color: Color(0xFF1B4D3E),
                            ),
                          ),
                          Text(
                            '${_companies.length} companies available',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[500],
                              fontFamily: 'Literata',
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.close,
                          size: 20,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Search bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: TextField(
                    controller: _companySearchController,
                    decoration: InputDecoration(
                      hintText: _localizations.searchByCompany,
                      hintStyle: TextStyle(
                        color: Colors.grey[400],
                        fontFamily: 'Literata',
                      ),
                      prefixIcon: Icon(
                        Icons.search_rounded,
                        color: Colors.grey[400],
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                    onChanged: (query) {
                      _filterCompanies(query);
                      setModalState(() {});
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Divider
              Container(height: 1, color: Colors.grey[200]),
              // Company list
              Expanded(
                child: _filteredCompanies.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.business_outlined,
                              size: 64,
                              color: Colors.grey[300],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _companySearchController.text.isEmpty
                                  ? _localizations.noCompaniesAvailable
                                  : _localizations.noCompaniesFound,
                              style: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 15,
                                fontFamily: 'Literata',
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        itemCount: _filteredCompanies.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final company = _filteredCompanies[index];
                          final isSelected =
                              _selectedCompany?['id'] == company['id'];
                          return Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                setState(() {
                                  _selectedCompany = company;
                                });
                                Navigator.pop(context);
                              },
                              borderRadius: BorderRadius.circular(14),
                              child: Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? const Color(
                                          0xFF7B68EE,
                                        ).withValues(alpha: 0.08)
                                      : Colors.grey[50],
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: isSelected
                                        ? const Color(0xFF7B68EE)
                                        : Colors.grey[200]!,
                                    width: isSelected ? 1.5 : 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 48,
                                      height: 48,
                                      decoration: BoxDecoration(
                                        color: const Color(
                                          0xFF7B68EE,
                                        ).withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Center(
                                        child: Text(
                                          (company['companyName'] as String)
                                                  .isNotEmpty
                                              ? (company['companyName']
                                                        as String)
                                                    .substring(0, 1)
                                                    .toUpperCase()
                                              : 'C',
                                          style: const TextStyle(
                                            color: Color(0xFF7B68EE),
                                            fontWeight: FontWeight.w700,
                                            fontSize: 20,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Text(
                                        company['companyName'],
                                        style: const TextStyle(
                                          fontFamily: 'Literata',
                                          fontWeight: FontWeight.w600,
                                          fontSize: 15,
                                        ),
                                      ),
                                    ),
                                    if (isSelected)
                                      const Icon(
                                        Icons.check_circle,
                                        color: Color(0xFF7B68EE),
                                        size: 22,
                                      ),
                                  ],
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
      ),
    );
  }

  void _calculateTotal() {
    // Total is calculated and displayed in the UI
    setState(() {});
  }

  Future<void> _processPurchase() async {
    if (_selectedProduct == null) {
      GlassyToast.show(context, _localizations.pleaseSelectProduct);
      return;
    }

    if (_selectedSupplier == null) {
      GlassyToast.show(context, _localizations.pleaseSelectSupplier);
      return;
    }

    // Company is optional - no validation required

    // Validate expiry date is after production date only if both are provided
    if (_productionDate != null &&
        _expiryDate != null &&
        _expiryDate!.isBefore(_productionDate!)) {
      GlassyToast.show(context, _localizations.expiryDateAfterProduction);
      return;
    }

    final quantity = int.tryParse(_quantityController.text);
    final price = double.tryParse(_priceController.text);
    final salesPrice = double.tryParse(_salesPriceController.text);

    if (quantity == null || quantity <= 0) {
      GlassyToast.show(context, _localizations.pleaseEnterValidQuantity);
      return;
    }

    if (price == null || price < 0) {
      GlassyToast.show(context, _localizations.pleaseEnterValidPurchasePrice);
      return;
    }

    if (salesPrice == null || salesPrice < 0) {
      GlassyToast.show(context, _localizations.pleaseEnterValidSalesPrice);
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Use InventoryIntegrationService for unified processing:
      // Creates PurchaseEntity + PurchaseBatch (FIFO) + StockLedger + updates Product stock/prices
      final integrationResult = await InventoryIntegrationService.instance
          .processPurchase(
            productId: _selectedProduct!.id,
            productName: _selectedProduct!.name,
            supplierId: _selectedSupplier!['id'],
            supplierName: _selectedSupplier!['fullName'],
            companyId: _selectedCompany?['id'],
            companyName: _selectedCompany?['companyName'],
            quantity: quantity,
            unit: _selectedUnit ?? PurchaseSettingsService.instance.defaultUnit,
            purchasePrice: price,
            salesPrice: salesPrice,
            productionDate: _productionDate,
            expiryDate: _expiryDate,
            warrantyMonths: _selectedWarranty ?? 0,
            notes: _notesController.text.isNotEmpty
                ? _notesController.text
                : null,
          );

      if (!integrationResult.success) {
        throw Exception(
          integrationResult.errorMessage ??
              _localizations.purchaseProcessingFailed,
        );
      }

      print(
        '[DEBUG] Purchase fully processed: PurchaseEntity + PurchaseBatch + StockLedger + Product stock updated',
      );

      // Also update Firestore if online and product is synced
      final currentUser = FirebaseAuth.instance.currentUser;
      final productId = _selectedProduct!.id;
      final newStock = _selectedProduct!.currentStock + quantity;
      final isValidServerId =
          productId.isNotEmpty &&
          !productId.startsWith('local_') &&
          productId.length >= 10;

      if (currentUser != null && isValidServerId) {
        try {
          // Only update purchasePrice; keep salesPrice from product creation
          final updateData = <String, dynamic>{
            'purchasePrice': price,
            'currentStock': newStock,
            'updatedAt': DateTime.now().toIso8601String(),
          };

          await _firestore
              .collection('users')
              .doc(currentUser.uid)
              .collection('products')
              .doc(productId)
              .update(updateData)
              .timeout(const Duration(seconds: 1));
          print('[DEBUG] Updated product in Firestore');
        } catch (e) {
          print('[DEBUG] Failed to update Firestore (will sync later): $e');
        }
      }

      // Trigger background sync for both PurchaseEntity and PurchaseBatchEntity
      PurchaseSyncService.instance.syncNow();
      PurchaseBatchSyncService.instance.syncNow();

      if (mounted) {
        GlassyToast.show(context, _localizations.purchaseRecorded);

        // Notify dashboard to refresh (purchase affects product stock)
        DashboardRefreshService.instance.notifyDataChanged(
          DataChangeType.purchase,
        );
        DashboardRefreshService.instance.notifyDataChanged(
          DataChangeType.product,
        );

        // Reset form
        setState(() {
          _selectedProduct = null;
          _selectedSupplier = null;
          _selectedCompany = null;
          _productionDate = null;
          _expiryDate = null;
          _selectedUnit = PurchaseSettingsService.instance.defaultUnit;
          _selectedWarranty = PurchaseSettingsService.instance.defaultWarranty;
          _quantityController.clear();
          _priceController.clear();
          _salesPriceController.clear();
          _notesController.clear();
          _productionDateController.clear();
          _expiryDateController.clear();
        });

        // Reload products to show updated stock — stream auto-handles this
      }
    } catch (e) {
      print('[ERROR] Failed to process purchase: $e');
      if (mounted) {
        GlassyToast.show(context, '${_localizations.error}: $e');
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _productStreamSubscription?.cancel();
    _supplierStreamSubscription?.cancel();
    _companyStreamSubscription?.cancel();
    LanguageService.instance.removeListener(_onLanguageChanged);
    PurchaseSettingsService.instance.removeListener(_onPurchaseSettingsChanged);
    _animController.dispose();
    _quantityController.dispose();
    _priceController.dispose();
    _salesPriceController.dispose();
    _notesController.dispose();
    _productSearchController.dispose();
    _supplierSearchController.dispose();
    _companySearchController.dispose();
    _newSupplierFirstNameController.dispose();
    _newSupplierLastNameController.dispose();
    _newSupplierContactController.dispose();
    _newSupplierAddressController.dispose();
    _newCompanyNameController.dispose();
    _newCompanyContactController.dispose();
    _newCompanyAddressController.dispose();
    _newCompanyGstCodeController.dispose();
    _productionDateController.dispose();
    _expiryDateController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  // ============ QUICK ACTIONS BAR ============
  Widget _buildQuickActionsBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildQuickActionChip(
              icon: Icons.inventory_2_rounded,
              label: _localizations.addProduct,
              color: const Color(0xFFf093fb),
              onTap: _addNewProduct,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: _buildQuickActionChip(
              icon: Icons.person_add_rounded,
              label: _localizations.addSupplier,
              color: const Color(0xFFFF6B6B),
              onTap: _showAddSupplierDialog,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: _buildQuickActionChip(
              icon: Icons.business_rounded,
              label: _localizations.addCompany,
              color: const Color(0xFF7B68EE),
              onTap: _showAddCompanyDialog,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionChip({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withValues(alpha: 0.12),
              color.withValues(alpha: 0.04),
            ],
          ),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.15), width: 1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 14),
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: const Color(0xFF1B4D3E).withValues(alpha: 0.8),
                  fontSize: 10,
                  fontFamily: 'Literata',
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddSupplierDialog() {
    _newSupplierFirstNameController.clear();
    _newSupplierLastNameController.clear();
    _newSupplierContactController.clear();
    _newSupplierAddressController.clear();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Drag handle
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Header
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFFFF6B6B),
                              const Color(0xFFFF6B6B).withValues(alpha: 0.8),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.person_add_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _localizations.addNewSupplier,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                fontFamily: 'Literata',
                                color: Color(0xFF1B4D3E),
                              ),
                            ),
                            Text(
                              _localizations.createNewSupplierRecord,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[500],
                                fontFamily: 'Literata',
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.close,
                            size: 20,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Form fields
                  _buildBottomSheetTextField(
                    controller: _newSupplierFirstNameController,
                    label: _localizations.firstName,
                    hint: _localizations.enterFirstName,
                    icon: Icons.person_outline,
                    isRequired: true,
                    onChanged: (_) => setSheetState(() {}),
                  ),
                  const SizedBox(height: 16),
                  _buildBottomSheetTextField(
                    controller: _newSupplierLastNameController,
                    label: _localizations.lastName,
                    hint: _localizations.enterLastName,
                    icon: Icons.person_outline,
                    isRequired: true,
                    onChanged: (_) => setSheetState(() {}),
                  ),
                  const SizedBox(height: 16),
                  _buildBottomSheetTextField(
                    controller: _newSupplierContactController,
                    label: _localizations.contactNumber,
                    hint: _localizations.enterTenDigitNumber,
                    icon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                    maxLength: 10,
                    onChanged: (_) => setSheetState(() {}),
                  ),
                  const SizedBox(height: 16),
                  _buildBottomSheetTextField(
                    controller: _newSupplierAddressController,
                    label: _localizations.address,
                    hint: _localizations.enterAddress,
                    icon: Icons.location_on_outlined,
                    maxLines: 3,
                    onChanged: (_) => setSheetState(() {}),
                  ),
                  const SizedBox(height: 24),
                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.grey[700],
                            side: BorderSide(color: Colors.grey[300]!),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            _localizations.cancel,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Literata',
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed:
                              (_newSupplierFirstNameController.text
                                      .trim()
                                      .isEmpty ||
                                  _newSupplierLastNameController.text
                                      .trim()
                                      .isEmpty)
                              ? null
                              : () => _saveNewSupplier(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1B4D3E),
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: Colors.grey[300],
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.add_rounded, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                _localizations.addSupplier,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontFamily: 'Literata',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Reusable text field widget for bottom sheets
  Widget _buildBottomSheetTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool isRequired = false,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    int? maxLength,
    Function(String)? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1B4D3E),
                fontFamily: 'Literata',
              ),
            ),
            if (isRequired)
              const Text(' *', style: TextStyle(color: Colors.red)),
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          maxLength: maxLength,
          onChanged: onChanged,
          style: const TextStyle(fontFamily: 'Literata'),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: Colors.grey[400],
              fontFamily: 'Literata',
            ),
            prefixIcon: Icon(icon, color: Colors.grey[600]),
            counterText: '',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF1B4D3E), width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
            filled: true,
            fillColor: Colors.grey[50],
          ),
        ),
      ],
    );
  }

  Future<void> _saveNewSupplier(BuildContext dialogContext) async {
    final firstName = _newSupplierFirstNameController.text.trim();
    final lastName = _newSupplierLastNameController.text.trim();
    final contact = _newSupplierContactController.text.trim();

    if (firstName.isEmpty || lastName.isEmpty) {
      if (dialogContext.mounted) {
        GlassyToast.show(
          dialogContext,
          _localizations.firstLastNameRequired,
          isError: true,
        );
      }
      return;
    }

    try {
      // Use offline controller — saves to Isar (stream auto-updates UI) + syncs to Firestore in background
      // Supplier code is optional, so we don't pass it - avoids duplicate code issues
      await SupplierOfflineController.instance.addSupplier(
        firstName: firstName,
        lastName: lastName,
        supplierCode: '', // Optional - leave empty
        contact: contact,
        address: _newSupplierAddressController.text.trim(),
      );

      // Trigger sync to upload to server immediately and wait for it
      final supplierSyncResult = await SupplierSyncService.instance.syncNow();
      debugPrint('Supplier sync result: $supplierSyncResult');

      if (dialogContext.mounted) {
        Navigator.pop(dialogContext);
      }

      // Notify dashboard to refresh
      DashboardRefreshService.instance.notifyDataChanged(
        DataChangeType.supplier,
      );

      if (mounted) {
        GlassyToast.show(context, _localizations.supplierAddedSuccessfully);
      }
    } catch (e) {
      if (mounted) {
        GlassyToast.show(context, '${_localizations.errorAddingSupplier}: $e');
      }
    }
  }

  void _showAddCompanyDialog() {
    _newCompanyNameController.clear();
    _newCompanyContactController.clear();
    _newCompanyAddressController.clear();
    _newCompanyGstCodeController.clear();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Drag handle
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Header
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFF7B68EE),
                              const Color(0xFF7B68EE).withValues(alpha: 0.8),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.business_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _localizations.addNewCompany,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                fontFamily: 'Literata',
                                color: Color(0xFF1B4D3E),
                              ),
                            ),
                            Text(
                              _localizations.createNewCompanyRecord,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[500],
                                fontFamily: 'Literata',
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.close,
                            size: 20,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Form fields
                  _buildBottomSheetTextField(
                    controller: _newCompanyNameController,
                    label: _localizations.companyName,
                    hint: _localizations.enterCompanyName,
                    icon: Icons.business_outlined,
                    isRequired: true,
                    onChanged: (_) => setSheetState(() {}),
                  ),
                  const SizedBox(height: 16),
                  _buildBottomSheetTextField(
                    controller: _newCompanyContactController,
                    label: _localizations.contactNumber,
                    hint: _localizations.enterTenDigitNumber,
                    icon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                    maxLength: 10,
                    onChanged: (_) => setSheetState(() {}),
                  ),
                  const SizedBox(height: 16),
                  _buildBottomSheetTextField(
                    controller: _newCompanyGstCodeController,
                    label: 'GST Code',
                    hint: 'Enter GST code',
                    icon: Icons.receipt_long_outlined,
                    onChanged: (_) => setSheetState(() {}),
                  ),
                  const SizedBox(height: 16),
                  _buildBottomSheetTextField(
                    controller: _newCompanyAddressController,
                    label: _localizations.address,
                    hint: _localizations.enterAddress,
                    icon: Icons.location_on_outlined,
                    maxLines: 3,
                    onChanged: (_) => setSheetState(() {}),
                  ),
                  const SizedBox(height: 24),
                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.grey[700],
                            side: BorderSide(color: Colors.grey[300]!),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            _localizations.cancel,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Literata',
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed:
                              _newCompanyNameController.text.trim().isEmpty
                              ? null
                              : () => _saveNewCompany(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1B4D3E),
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: Colors.grey[300],
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.add_rounded, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                _localizations.addCompany,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontFamily: 'Literata',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _saveNewCompany(BuildContext dialogContext) async {
    final companyName = _newCompanyNameController.text.trim();

    if (companyName.isEmpty) {
      if (dialogContext.mounted) {
        GlassyToast.show(
          dialogContext,
          _localizations.companyNameIsRequired,
          isError: true,
        );
      }
      return;
    }

    try {
      // Use offline controller — saves to Isar (stream auto-updates UI) + syncs to Firestore in background
      // Company code is optional, so we don't pass it - avoids duplicate code issues
      await CompanyOfflineController.instance.addCompany(
        companyName: companyName,
        gstCode: _newCompanyGstCodeController.text.trim(),
        contact: _newCompanyContactController.text.trim(),
        address: _newCompanyAddressController.text.trim(),
      );

      // Trigger sync to upload to server immediately and await result
      final syncResult = await CompanySyncService.instance.syncNow();
      debugPrint(
        '[PurchasePage] Company sync result: ${syncResult.success}, created: ${syncResult.createdCount}, error: ${syncResult.errorMessage}',
      );

      if (dialogContext.mounted) {
        Navigator.pop(dialogContext);
      }

      // Notify dashboard to refresh
      DashboardRefreshService.instance.notifyDataChanged(
        DataChangeType.company,
      );

      if (mounted) {
        GlassyToast.show(context, _localizations.companyAddedSuccessfully);
      }
    } catch (e) {
      if (mounted) {
        GlassyToast.show(context, 'Error adding company: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F6),
      body: SafeArea(
        top: !widget.isEmbedded,
        child: Column(
          children: [
            // Scrollable content
            Expanded(
              child: CustomScrollView(
                controller: _scrollController,
                slivers: [
                  // Sticky App Bar Section
                  if (!widget.isEmbedded)
                    SliverPersistentHeader(
                      pinned: true,
                      delegate: _StickyHeaderDelegate(
                        child: _buildHeader(),
                        height: 90,
                      ),
                    ),
                  // Sticky Quick Actions
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: _StickyHeaderDelegate(
                      child: Container(
                        color: const Color(0xFFF5F7F6),
                        padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
                        child: _buildQuickActionsBar(),
                      ),
                      height: 62,
                    ),
                  ),
                  // Main Form Content
                  SliverToBoxAdapter(
                    child: SlideTransition(
                      position: _offsetAnimation,
                      child: FadeTransition(
                        opacity: _opacityAnimation,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Column(
                            children: [
                              const SizedBox(height: 8),
                              // Selection Cards Section
                              _buildSelectionSection(),
                              const SizedBox(height: 16),
                              // Date & Quantity Section
                              _buildDetailsSection(),
                              const SizedBox(height: 16),
                              // Pricing Section
                              _buildPricingSection(),
                              const SizedBox(height: 16),
                              // Notes Section
                              _buildNotesSection(),
                              const SizedBox(height: 24),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Sticky Bottom Submit Button
            _buildStickyBottomButton(),
          ],
        ),
      ),
    );
  }

  /// Sticky bottom submit button
  Widget _buildStickyBottomButton() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1B4D3E), Color(0xFF0F3B2F)],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1B4D3E).withValues(alpha: 0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: _isLoading ? null : _processPurchase,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            disabledBackgroundColor: Colors.transparent,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: _isLoading
              ? const SizedBox(
                  height: 22,
                  width: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.check_circle_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      _localizations.recordPurchase,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Literata',
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  /// Modern header with gradient
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1B4D3E), Color(0xFF0F3B2F)],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1B4D3E).withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.arrow_back_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _localizations.addPurchase,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Literata',
                  ),
                ),
                Text(
                  _localizations.recordNewInventoryPurchase,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 12,
                    fontFamily: 'Literata',
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const InvoiceScannerPage()),
              );
              if (result == true && mounted) {
                // Data auto-refreshes via Isar streams
                setState(() {});
              }
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.document_scanner_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PurchaseSettingsPage()),
            ),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.settings_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Selection section with product, supplier, company cards
  Widget _buildSelectionSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF1B4D3E).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.checklist_rounded,
                  color: Color(0xFF1B4D3E),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                _localizations.selectionDetails,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Literata',
                  color: Color(0xFF1B4D3E),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Product Selection
          _buildSelectionCard(
            title: _localizations.productText,
            value: _selectedProduct?.name,
            subtitle: _selectedProduct != null
                ? 'Stock: ${_selectedProduct!.currentStock} • ${_selectedProduct!.companyName}'
                : null,
            icon: Icons.inventory_2_rounded,
            color: const Color(0xFF1B4D3E),
            onTap: _showProductSelectionBottomSheet,
            isSelected: _selectedProduct != null,
          ),
          const SizedBox(height: 12),
          // Supplier & Company in row
          Row(
            children: [
              Expanded(
                child: _buildSelectionCard(
                  title: _localizations.supplier,
                  value: _selectedSupplier?['fullName'],
                  icon: Icons.person_rounded,
                  color: const Color(0xFFFF6B6B),
                  onTap: _showSupplierSelectionBottomSheet,
                  isSelected: _selectedSupplier != null,
                  compact: true,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSelectionCard(
                  title: _localizations.company,
                  value: _selectedCompany?['companyName'],
                  icon: Icons.business_rounded,
                  color: const Color(0xFF7B68EE),
                  onTap: _showCompanySelectionBottomSheet,
                  isSelected: _selectedCompany != null,
                  compact: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Reusable selection card widget
  Widget _buildSelectionCard({
    required String title,
    String? value,
    String? subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    required bool isSelected,
    bool compact = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.all(compact ? 12 : 14),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.08) : Colors.grey[50],
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? color.withValues(alpha: 0.4)
                : Colors.grey[200]!,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: compact ? 36 : 42,
              height: compact ? 36 : 42,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isSelected
                      ? [color, color.withValues(alpha: 0.8)]
                      : [Colors.grey[300]!, Colors.grey[400]!],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: Colors.white, size: compact ? 18 : 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'Literata',
                      color: Colors.grey[500],
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value ?? 'Select $title',
                    style: TextStyle(
                      fontSize: compact ? 13 : 14,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Literata',
                      color: isSelected ? Colors.black87 : Colors.grey[400],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (subtitle != null && !compact) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 11,
                        fontFamily: 'Literata',
                        color: Colors.grey[500],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: isSelected ? color : Colors.grey[400],
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  /// Details section with dates, quantity, unit, warranty
  Widget _buildDetailsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF2196F3).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.tune_rounded,
                  color: Color(0xFF2196F3),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                _localizations.purchase,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Literata',
                  color: Color(0xFF1B4D3E),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Date pickers row (if enabled)
          if (PurchaseSettingsService.instance.showManufacturingDate ||
              PurchaseSettingsService.instance.showExpiryDate)
            Row(
              children: [
                if (PurchaseSettingsService.instance.showManufacturingDate)
                  Expanded(
                    child: _buildDateField(
                      label: _localizations.mfgDate,
                      value: _productionDate,
                      icon: Icons.event_rounded,
                      color: const Color(0xFF4CAF50),
                      onTap: () => _selectDate(isProduction: true),
                    ),
                  ),
                if (PurchaseSettingsService.instance.showManufacturingDate &&
                    PurchaseSettingsService.instance.showExpiryDate)
                  const SizedBox(width: 12),
                if (PurchaseSettingsService.instance.showExpiryDate)
                  Expanded(
                    child: _buildDateField(
                      label: _localizations.expiryDate,
                      value: _expiryDate,
                      icon: Icons.event_busy_rounded,
                      color: const Color(0xFFFF9800),
                      onTap: () => _selectDate(isProduction: false),
                    ),
                  ),
              ],
            ),
          if (PurchaseSettingsService.instance.showManufacturingDate ||
              PurchaseSettingsService.instance.showExpiryDate)
            const SizedBox(height: 16),
          // Quantity field
          _buildTextField(
            controller: _quantityController,
            label: _localizations.purchaseQuantity,
            hint: _localizations.enterQuantity,
            icon: Icons.shopping_cart_rounded,
            keyboardType: TextInputType.number,
            onChanged: (_) => _calculateTotal(),
          ),
          const SizedBox(height: 16),
          // Measurement Unit
          _buildChipSelector(
            label: _localizations.measurementUnit,
            options: PurchaseSettingsService.instance.availableUnits,
            selectedValue: _selectedUnit,
            onSelected: (unit) => setState(() => _selectedUnit = unit),
            color: const Color(0xFF1B4D3E),
            icon: Icons.straighten_rounded,
          ),
          // Warranty (if enabled)
          if (PurchaseSettingsService.instance.showWarranty) ...[
            const SizedBox(height: 16),
            _buildChipSelector<int>(
              label: _localizations.warrantyPeriod,
              options: PurchaseSettingsService.instance.warrantyOptions,
              selectedValue: _selectedWarranty,
              onSelected: (warranty) =>
                  setState(() => _selectedWarranty = warranty),
              color: const Color(0xFF9C27B0),
              icon: Icons.verified_user_rounded,
              labelBuilder: (value) =>
                  PurchaseSettingsService.instance.getWarrantyLabel(value),
            ),
          ],
        ],
      ),
    );
  }

  /// Date field widget
  Widget _buildDateField({
    required String label,
    DateTime? value,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    final hasValue = value != null;
    final dateStr = hasValue
        ? '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}'
        : _localizations.selectText;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: hasValue ? color.withValues(alpha: 0.08) : Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: hasValue ? color.withValues(alpha: 0.3) : Colors.grey[200]!,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: hasValue
                    ? color.withValues(alpha: 0.15)
                    : Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: hasValue ? color : Colors.grey[500],
                size: 16,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'Literata',
                      color: Colors.grey[500],
                    ),
                  ),
                  Text(
                    dateStr,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Literata',
                      color: hasValue ? Colors.black87 : Colors.grey[400],
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.calendar_month_rounded,
              color: Colors.grey[400],
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  /// Date picker helper
  Future<void> _selectDate({required bool isProduction}) async {
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: isProduction
          ? (_productionDate ?? DateTime.now())
          : (_expiryDate ?? DateTime.now().add(const Duration(days: 30))),
      firstDate: isProduction ? DateTime(2000) : DateTime.now(),
      lastDate: isProduction ? DateTime.now() : DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF1B4D3E),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (selectedDate != null) {
      setState(() {
        if (isProduction) {
          _productionDate = selectedDate;
          _productionDateController.text =
              '${selectedDate.day.toString().padLeft(2, '0')}/${selectedDate.month.toString().padLeft(2, '0')}/${selectedDate.year}';
        } else {
          _expiryDate = selectedDate;
          _expiryDateController.text =
              '${selectedDate.day.toString().padLeft(2, '0')}/${selectedDate.month.toString().padLeft(2, '0')}/${selectedDate.year}';
        }
      });
    }
  }

  /// Text field widget
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    Function(String)? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            fontFamily: 'Literata',
            color: Color(0xFF1B4D3E),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          onChanged: onChanged,
          style: const TextStyle(
            fontFamily: 'Literata',
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: Colors.grey[400],
              fontFamily: 'Literata',
            ),
            prefixIcon: Icon(icon, color: const Color(0xFF1B4D3E), size: 20),
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
              borderSide: const BorderSide(
                color: Color(0xFF1B4D3E),
                width: 1.5,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
        ),
      ],
    );
  }

  /// Chip selector widget
  Widget _buildChipSelector<T>({
    required String label,
    required List<T> options,
    required T? selectedValue,
    required Function(T) onSelected,
    required Color color,
    required IconData icon,
    String Function(T)? labelBuilder,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            fontFamily: 'Literata',
            color: Color(0xFF1B4D3E),
          ),
        ),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: options.map((option) {
              final isSelected = selectedValue == option;
              final displayLabel = labelBuilder != null
                  ? labelBuilder(option)
                  : option.toString();
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () => onSelected(option),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      gradient: isSelected
                          ? LinearGradient(
                              colors: [color, color.withValues(alpha: 0.8)],
                            )
                          : null,
                      color: isSelected ? null : Colors.grey[100],
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected ? color : Colors.grey[300]!,
                        width: isSelected ? 0 : 1,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: color.withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isSelected ? Icons.check_rounded : icon,
                          size: 16,
                          color: isSelected ? Colors.white : Colors.grey[600],
                        ),
                        const SizedBox(width: 6),
                        Text(
                          displayLabel,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Literata',
                            color: isSelected ? Colors.white : Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  /// Pricing section
  Widget _buildPricingSection() {
    final quantity = int.tryParse(_quantityController.text) ?? 0;
    final price = double.tryParse(_priceController.text) ?? 0;
    final total = quantity * price;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF4CAF50).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.currency_rupee_rounded,
                  color: Color(0xFF4CAF50),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                _localizations.pricing,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Literata',
                  color: Color(0xFF1B4D3E),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Price fields row
          Row(
            children: [
              Expanded(
                child: _buildPriceField(
                  controller: _priceController,
                  label: _localizations.purchasePrice,
                  hint: '0.00',
                  onChanged: (_) => _calculateTotal(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildPriceField(
                  controller: _salesPriceController,
                  label: _localizations.salesPrice,
                  hint: '0.00',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Total amount card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF1B4D3E).withValues(alpha: 0.08),
                  const Color(0xFF4CAF50).withValues(alpha: 0.08),
                ],
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: const Color(0xFF1B4D3E).withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1B4D3E).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.receipt_long_rounded,
                        color: Color(0xFF1B4D3E),
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _localizations.totalAmount,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            fontFamily: 'Literata',
                            color: Colors.grey[600],
                          ),
                        ),
                        Text(
                          '$quantity × ₹${price.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 11,
                            fontFamily: 'Literata',
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Text(
                  '₹${total.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'Literata',
                    color: Color(0xFF1B4D3E),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Price field widget
  Widget _buildPriceField({
    required TextEditingController controller,
    required String label,
    required String hint,
    Function(String)? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            fontFamily: 'Literata',
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          onChanged: onChanged,
          style: const TextStyle(
            fontFamily: 'Literata',
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey[400]),
            prefixText: '₹ ',
            prefixStyle: TextStyle(
              fontWeight: FontWeight.w700,
              color: Colors.grey[600],
              fontSize: 15,
            ),
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
              borderSide: const BorderSide(
                color: Color(0xFF4CAF50),
                width: 1.5,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 14,
            ),
          ),
        ),
      ],
    );
  }

  /// Notes section
  Widget _buildNotesSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF9800).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.notes_rounded,
                  color: Color(0xFFFF9800),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                _localizations.notes,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Literata',
                  color: Color(0xFF1B4D3E),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '(${_localizations.optional})',
                style: TextStyle(
                  fontSize: 12,
                  fontFamily: 'Literata',
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _notesController,
            maxLines: 3,
            style: const TextStyle(fontFamily: 'Literata'),
            decoration: InputDecoration(
              hintText: _localizations.addNotesAboutPurchase,
              hintStyle: TextStyle(
                color: Colors.grey[400],
                fontFamily: 'Literata',
              ),
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
                borderSide: const BorderSide(
                  color: Color(0xFFFF9800),
                  width: 1.5,
                ),
              ),
              contentPadding: const EdgeInsets.all(14),
            ),
          ),
        ],
      ),
    );
  }
}

/// Sticky header delegate for pinned sections
class _StickyHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  final double height;

  _StickyHeaderDelegate({required this.child, this.height = 90});

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return child;
  }

  @override
  double get maxExtent => height;

  @override
  double get minExtent => height;

  @override
  bool shouldRebuild(covariant _StickyHeaderDelegate oldDelegate) {
    return child != oldDelegate.child || height != oldDelegate.height;
  }
}

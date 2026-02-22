import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:isar_community/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:c_billing/core/services/language_service.dart';
import 'package:c_billing/core/services/dashboard_refresh_service.dart';
import 'package:c_billing/core/services/isar_service.dart';
import 'package:c_billing/core/services/product_settings_service.dart';
import 'package:c_billing/core/localization/app_localizations.dart';
import 'package:c_billing/common_widgets/file_preview_page.dart';
import '../../offline/entities/purchase_batch_entity.dart';
import '../../offline/controllers/purchase_batch_offline_controller.dart';
import '../../data/services/purchase_sync_service.dart';
import '../../data/services/purchase_batch_sync_service.dart';
import '../../data/services/purchase_report_pdf_generator.dart';
import '../../../supplier/offline/controllers/supplier_offline_controller.dart';
import '../../../supplier/offline/entities/supplier_entity.dart';
import '../../../product/offline/controllers/product_offline_controller.dart';
import '../widgets/purchase_filter_widget.dart';
import '../widgets/purchase_list_widget.dart';
import 'purchase_page.dart';
import 'purchase_settings_page.dart';
import 'purchase_report_settings_page.dart';
import 'invoice_scanner_page.dart';

/// Enhanced Purchase Screen with purchase list as default view
/// Features: Modern UI, filters, FAB for adding purchases, real-time updates
class EnhancedPurchaseScreen extends StatefulWidget {
  final bool isEmbedded;

  const EnhancedPurchaseScreen({super.key, this.isEmbedded = false});

  @override
  State<EnhancedPurchaseScreen> createState() => _EnhancedPurchaseScreenState();
}

class _EnhancedPurchaseScreenState extends State<EnhancedPurchaseScreen>
    with SingleTickerProviderStateMixin {
  late AppLocalizations _localizations;
  late AnimationController _animController;
  late Animation<Offset> _offsetAnimation;
  late Animation<double> _opacityAnimation;

  // Data
  List<PurchaseBatchEntity> _purchases = [];
  List<Map<String, dynamic>> _suppliers = [];
  bool _isLoading = true;

  // Filters
  PurchaseDateFilter _dateFilter = PurchaseDateFilter.all;
  String? _supplierFilter;
  DateTime? _customStartDate;
  DateTime? _customEndDate;

  // Streams
  StreamSubscription<List<PurchaseBatchEntity>>? _purchaseStreamSubscription;
  StreamSubscription<List<SupplierEntity>>? _supplierStreamSubscription;
  StreamSubscription<void>? _purchaseChangeSubscription;

  @override
  void initState() {
    super.initState();
    _localizations = AppLocalizations.of(LanguageService.instance.currentLanguage);
    LanguageService.instance.addListener(_onLanguageChanged);

    // Initialize animations
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeIn));

    // Load data directly from Isar first
    _loadPurchasesFromIsar();
    _setupSupplierStream();
    _setupCrossPageRefresh();

    // Start animation
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) _animController.forward();
    });

    // Trigger background sync for both PurchaseEntity and PurchaseBatchEntity
    PurchaseSyncService.instance.syncNow();
    PurchaseBatchSyncService.instance.syncNow();
  }

  void _onLanguageChanged() {
    if (mounted) {
      setState(() {
        _localizations = AppLocalizations.of(LanguageService.instance.currentLanguage);
      });
    }
  }

  @override
  void dispose() {
    LanguageService.instance.removeListener(_onLanguageChanged);
    _animController.dispose();
    _purchaseStreamSubscription?.cancel();
    _supplierStreamSubscription?.cancel();
    _purchaseChangeSubscription?.cancel();
    super.dispose();
  }

  /// Load purchases directly from Isar database
  Future<void> _loadPurchasesFromIsar() async {
    try {
      final isar = IsarService.instance.isar;
      
      // Query all purchase batches directly from Isar
      var batches = await isar.purchaseBatchEntitys
          .filter()
          .not()
          .syncStatusEqualTo(BatchSyncStatus.deleted)
          .sortByPurchaseDateDesc()
          .findAll();
      
      debugPrint('[EnhancedPurchase] Isar found ${batches.length} batches');
      
      // If Isar is empty, let the sync service handle downloading from server
      // Do NOT do manual Firestore import here — PurchaseBatchSyncService handles it
      if (batches.isEmpty) {
        debugPrint('[EnhancedPurchase] Isar empty, requesting sync service to download...');
        await PurchaseBatchSyncService.instance.forceFullSync();
        
        // Re-query Isar after sync
        batches = await isar.purchaseBatchEntitys
            .filter()
            .not()
            .syncStatusEqualTo(BatchSyncStatus.deleted)
            .sortByPurchaseDateDesc()
            .findAll();
        
        debugPrint('[EnhancedPurchase] After sync service download: ${batches.length} batches');
      }
      
      if (mounted) {
        setState(() {
          _purchases = batches;
          _isLoading = false;
        });
      }
      
      // Now setup the stream for real-time updates
      _setupPurchaseStream();
      
    } catch (e, stack) {
      debugPrint('[EnhancedPurchase] Error loading from Isar: $e');
      debugPrint('[EnhancedPurchase] Stack: $stack');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Setup real-time purchase stream from Isar (for updates after initial load)
  void _setupPurchaseStream() {
    final isar = IsarService.instance.isar;
    
    _purchaseStreamSubscription = isar.purchaseBatchEntitys
        .filter()
        .not()
        .syncStatusEqualTo(BatchSyncStatus.deleted)
        .sortByPurchaseDateDesc()
        .watch(fireImmediately: false) // Don't fire immediately since we already loaded
        .listen(
      (purchases) {
        debugPrint('[EnhancedPurchase] Stream update: ${purchases.length} purchases');
        if (mounted) {
          setState(() {
            _purchases = purchases;
          });
        }
      },
      onError: (e) {
        debugPrint('[EnhancedPurchase] Stream error: $e');
      },
    );
  }

  /// Setup supplier stream for filter dropdown
  void _setupSupplierStream() {
    // Load suppliers once instead of streaming to avoid rebuilds
    _loadSuppliers();
  }

  /// Load suppliers once
  Future<void> _loadSuppliers() async {
    try {
      final suppliers = await SupplierOfflineController.instance.getAllSuppliers();
      if (mounted) {
        setState(() {
          _suppliers = suppliers.map((s) => {
            'id': s.serverId ?? s.id.toString(),
            'firstName': s.firstName,
            'lastName': s.lastName,
            'fullName': '${s.firstName} ${s.lastName}'.trim(),
            'contact': s.contact,
          }).toList();
        });
      }
    } catch (e) {
      debugPrint('[EnhancedPurchase] Error loading suppliers: $e');
    }
  }

  /// Listen for purchase changes from other screens
  void _setupCrossPageRefresh() {
    _purchaseChangeSubscription = DashboardRefreshService.instance
        .onPurchaseChanged
        .listen((_) {
      if (mounted) {
        // Reload from Isar when purchases change
        _loadPurchasesFromIsar();
      }
    });
  }

  /// Navigate to add purchase page
  void _navigateToAddPurchase() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const PurchasePage(isEmbedded: false),
      ),
    );
    // Reload purchases after returning from add page
    _loadPurchasesFromIsar();
  }

  /// Show purchase details bottom sheet
  void _showPurchaseDetails(PurchaseBatchEntity purchase) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _PurchaseDetailsSheet(
        purchase: purchase,
        onEdit: () {
          Navigator.pop(context);
          _showEditPurchaseDialog(purchase);
        },
        onDelete: () async {
          Navigator.pop(context);
          _confirmDeletePurchase(purchase);
        },
      ),
    );
  }

  /// Show purchase context menu on long press
  void _showPurchaseContextMenu(PurchaseBatchEntity purchase) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.95),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 12),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      purchase.productName,
                      style: const TextStyle(
                        fontFamily: 'Literata',
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: Color(0xFF1B4D3E),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Divider(height: 1),
                  _buildContextMenuItem(
                    icon: Icons.visibility_rounded,
                    label: 'View Details',
                    onTap: () {
                      Navigator.pop(context);
                      _showPurchaseDetails(purchase);
                    },
                  ),
                  _buildContextMenuItem(
                    icon: Icons.edit_rounded,
                    label: 'Edit',
                    onTap: () {
                      Navigator.pop(context);
                      _showEditPurchaseDialog(purchase);
                    },
                  ),
                  _buildContextMenuItem(
                    icon: Icons.delete_outline_rounded,
                    label: 'Delete',
                    isDestructive: true,
                    onTap: () {
                      Navigator.pop(context);
                      _confirmDeletePurchase(purchase);
                    },
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContextMenuItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            Icon(
              icon,
              size: 22,
              color: isDestructive ? Colors.red : Colors.grey[700],
            ),
            const SizedBox(width: 16),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Literata',
                fontWeight: FontWeight.w500,
                fontSize: 15,
                color: isDestructive ? Colors.red : Colors.grey[800],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Show edit purchase dialog
  void _showEditPurchaseDialog(PurchaseBatchEntity purchase) {
    final purchasePriceController = TextEditingController(
      text: purchase.purchasePrice.toStringAsFixed(2),
    );
    final sellingPriceController = TextEditingController(
      text: purchase.sellingPrice.toStringAsFixed(2),
    );
    final quantityController = TextEditingController(
      text: purchase.quantityPurchased.toString(),
    );
    final unitController = TextEditingController(text: purchase.unit);
    final notesController = TextEditingController(text: purchase.notes ?? '');
    final warrantyController = TextEditingController(
      text: (purchase.warrantyMonths ?? 0) > 0
          ? purchase.warrantyMonths.toString()
          : '',
    );

    DateTime? selectedPurchaseDate = purchase.purchaseDate;
    DateTime? selectedExpiryDate = purchase.expiryDate;
    DateTime? selectedProductionDate = purchase.productionDate;
    String? selectedSupplierId = purchase.supplierId;
    String? selectedSupplierName = purchase.supplierName;
    final originalQty = purchase.quantityPurchased;
    final consumed = originalQty - purchase.quantityRemaining;

    // Load custom columns
    final customColumns = ProductSettingsService.instance.activeCustomColumns;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: AlertDialog(
            backgroundColor: Colors.white.withOpacity(0.95),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(
                color: Colors.white.withOpacity(0.3),
                width: 1.5,
              ),
            ),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1B4D3E).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.edit_rounded,
                    color: Color(0xFF1B4D3E),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Edit Purchase',
                        style: TextStyle(
                          fontFamily: 'Literata',
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: Color(0xFF1B4D3E),
                        ),
                      ),
                      Text(
                        purchase.productName,
                        style: TextStyle(
                          fontFamily: 'Literata',
                          fontWeight: FontWeight.w500,
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
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Purchase Price
                  _buildEditField(
                    controller: purchasePriceController,
                    label: _localizations.purchasePrice,
                    icon: Icons.currency_rupee_rounded,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                  const SizedBox(height: 12),

                  // Selling Price
                  _buildEditField(
                    controller: sellingPriceController,
                    label: _localizations.salesPrice,
                    icon: Icons.sell_rounded,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                  const SizedBox(height: 12),

                  // Quantity
                  Row(
                    children: [
                      Expanded(
                        child: _buildEditField(
                          controller: quantityController,
                          label: '${_localizations.quantity} (min: $consumed sold)',
                          icon: Icons.inventory_2_rounded,
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildEditField(
                          controller: unitController,
                          label: 'Unit',
                          icon: Icons.straighten_rounded,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Supplier selector
                  InkWell(
                    onTap: () async {
                      final supplier = await _showSupplierPickerDialog(context);
                      if (supplier != null) {
                        setDialogState(() {
                          selectedSupplierId = supplier['id'] as String?;
                          selectedSupplierName = supplier['fullName'] as String?;
                        });
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.person_rounded, size: 20, color: Colors.grey[600]),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              selectedSupplierName ?? _localizations.selectSupplier,
                              style: TextStyle(
                                fontFamily: 'Literata',
                                fontSize: 14,
                                color: selectedSupplierName != null
                                    ? Colors.black87
                                    : Colors.grey[500],
                              ),
                            ),
                          ),
                          if (selectedSupplierName != null)
                            GestureDetector(
                              onTap: () {
                                setDialogState(() {
                                  selectedSupplierId = null;
                                  selectedSupplierName = null;
                                });
                              },
                              child: Icon(Icons.close, size: 18, color: Colors.grey[500]),
                            ),
                          if (selectedSupplierName == null)
                            Icon(Icons.arrow_drop_down, color: Colors.grey[500]),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Purchase Date
                  InkWell(
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: selectedPurchaseDate ?? DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now().add(const Duration(days: 1)),
                      );
                      if (date != null) {
                        setDialogState(() => selectedPurchaseDate = date);
                      }
                    },
                    child: _buildDateField(
                      label: 'Purchase Date',
                      date: selectedPurchaseDate,
                      icon: Icons.calendar_today_rounded,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Production Date & Expiry Date
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: selectedProductionDate ?? DateTime.now(),
                              firstDate: DateTime(2020),
                              lastDate: DateTime.now().add(const Duration(days: 1)),
                            );
                            if (date != null) {
                              setDialogState(() => selectedProductionDate = date);
                            }
                          },
                          child: _buildDateField(
                            label: 'Mfg Date',
                            date: selectedProductionDate,
                            icon: Icons.factory_rounded,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: selectedExpiryDate ?? DateTime.now().add(const Duration(days: 365)),
                              firstDate: DateTime.now(),
                              lastDate: DateTime(2035),
                            );
                            if (date != null) {
                              setDialogState(() => selectedExpiryDate = date);
                            }
                          },
                          child: _buildDateField(
                            label: 'Expiry',
                            date: selectedExpiryDate,
                            icon: Icons.event_busy_rounded,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Warranty
                  _buildEditField(
                    controller: warrantyController,
                    label: 'Warranty (months)',
                    icon: Icons.verified_user_rounded,
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 12),

                  // Notes
                  _buildEditField(
                    controller: notesController,
                    label: 'Notes',
                    icon: Icons.notes_rounded,
                    maxLines: 3,
                  ),
                  
                  // Custom Fields Section (Read-only display)
                  if (customColumns.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          Icon(Icons.tune_rounded, 
                              size: 16, 
                              color: Colors.grey[600]),
                          const SizedBox(width: 8),
                          Text(
                            'Custom Fields',
                            style: TextStyle(
                              fontFamily: 'Literata',
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    FutureBuilder<Map<String, dynamic>>(
                      future: _loadProductCustomFields(purchase.productId),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Center(
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Color(0xFF1B4D3E),
                                ),
                              ),
                            ),
                          );
                        }
                        final fieldValues = snapshot.data ?? {};
                        return Column(
                          children: customColumns.map((column) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _buildCustomFieldDisplay(
                                column,
                                fieldValues[column.id],
                              ),
                            );
                          }).toList(),
                        );
                      },
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  _localizations.cancel,
                  style: const TextStyle(
                    fontFamily: 'Literata',
                    color: Colors.grey,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () async {
                  try {
                    final newPurchasePrice =
                        double.tryParse(purchasePriceController.text) ??
                            purchase.purchasePrice;
                    final newSellingPrice =
                        double.tryParse(sellingPriceController.text) ??
                            purchase.sellingPrice;
                    var newQuantity =
                        int.tryParse(quantityController.text) ??
                            purchase.quantityPurchased;
                    final newUnit = unitController.text.trim().isNotEmpty
                        ? unitController.text.trim()
                        : purchase.unit;
                    final newNotes = notesController.text.trim().isNotEmpty
                        ? notesController.text.trim()
                        : null;
                    final newWarranty =
                        int.tryParse(warrantyController.text);

                    // Validate: quantity cannot be less than already consumed
                    if (newQuantity < consumed) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Quantity cannot be less than $consumed (already sold)',
                            style: const TextStyle(fontFamily: 'Literata'),
                          ),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }

                    // Calculate new remaining: newQuantity - consumed
                    final newRemaining = newQuantity - consumed;

                    final controller = PurchaseBatchOfflineController.instance;
                    await controller.updateBatch(
                      id: purchase.id,
                      purchasePrice: newPurchasePrice,
                      sellingPrice: newSellingPrice,
                      quantityPurchased: newQuantity,
                      quantityRemaining: newRemaining,
                      unit: newUnit,
                      notes: newNotes,
                      supplierId: selectedSupplierId,
                      supplierName: selectedSupplierName,
                      purchaseDate: selectedPurchaseDate,
                      expiryDate: selectedExpiryDate,
                      productionDate: selectedProductionDate,
                      warrantyMonths: newWarranty,
                    );

                    // Notify dashboard
                    DashboardRefreshService.instance
                        .notifyDataChanged(DataChangeType.purchase);

                    // Trigger background sync
                    PurchaseBatchSyncService.instance.syncNow();

                    if (mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Purchase updated successfully',
                            style: TextStyle(fontFamily: 'Literata'),
                          ),
                          backgroundColor: Color(0xFF1B4D3E),
                        ),
                      );
                    }
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Error updating purchase: $e',
                          style: const TextStyle(fontFamily: 'Literata'),
                        ),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1B4D3E),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Update',
                  style: TextStyle(fontFamily: 'Literata', color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build a text field for the edit dialog
  Widget _buildEditField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: const TextStyle(fontFamily: 'Literata', fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          fontFamily: 'Literata',
          fontSize: 13,
          color: Colors.grey[600],
        ),
        prefixIcon: Icon(icon, size: 20, color: const Color(0xFF1B4D3E)),
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
          borderSide: const BorderSide(color: Color(0xFF1B4D3E), width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        isDense: true,
      ),
    );
  }

  /// Build a date display field for the edit dialog
  Widget _buildDateField({
    required String label,
    required DateTime? date,
    required IconData icon,
  }) {
    final dateFormat = DateFormat('dd MMM yyyy');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xFF1B4D3E)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontFamily: 'Literata',
                    fontSize: 10,
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  date != null ? dateFormat.format(date) : 'Not set',
                  style: TextStyle(
                    fontFamily: 'Literata',
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: date != null ? Colors.black87 : Colors.grey[400],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Load custom field values from the product
  Future<Map<String, dynamic>> _loadProductCustomFields(String productId) async {
    try {
      final product = await ProductOfflineController.instance.getProductByServerId(productId);
      if (product != null && product.customFieldsJson != null && product.customFieldsJson!.isNotEmpty) {
        return jsonDecode(product.customFieldsJson!) as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('Error loading product custom fields: $e');
    }
    return {};
  }

  /// Build a read-only custom field display widget
  Widget _buildCustomFieldDisplay(CustomColumn column, dynamic value) {
    final primaryColor = const Color(0xFF1B4D3E);
    String displayValue = '';
    IconData icon = Icons.text_fields_rounded;
    
    switch (column.type) {
      case CustomColumnType.text:
        displayValue = value?.toString() ?? '-';
        icon = Icons.text_fields_rounded;
        break;
      case CustomColumnType.number:
        displayValue = value?.toString() ?? '-';
        icon = Icons.numbers_rounded;
        break;
      case CustomColumnType.decimal:
        displayValue = value?.toString() ?? '-';
        icon = Icons.percent_rounded;
        break;
      case CustomColumnType.date:
        if (value != null && value.toString().isNotEmpty) {
          try {
            final date = DateTime.parse(value.toString());
            displayValue = DateFormat('dd MMM yyyy').format(date);
          } catch (_) {
            displayValue = value.toString();
          }
        } else {
          displayValue = '-';
        }
        icon = Icons.calendar_today_rounded;
        break;
      case CustomColumnType.dropdown:
        displayValue = value?.toString() ?? '-';
        icon = Icons.arrow_drop_down_circle_rounded;
        break;
      case CustomColumnType.boolean:
        displayValue = value == true || value == 'true' ? 'Yes' : 'No';
        icon = Icons.check_circle_outline_rounded;
        break;
    }
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(12),
        color: Colors.grey[50],
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: primaryColor),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  column.name,
                  style: TextStyle(
                    fontFamily: 'Literata',
                    fontSize: 10,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  displayValue,
                  style: TextStyle(
                    fontFamily: 'Literata',
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: displayValue != '-' ? Colors.black87 : Colors.grey[400],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Show supplier picker dialog
  Future<Map<String, dynamic>?> _showSupplierPickerDialog(BuildContext parentContext) async {
    return await showDialog<Map<String, dynamic>>(
      context: parentContext,
      builder: (context) {
        var filtered = _suppliers.toList();
        return StatefulBuilder(
          builder: (context, setPickerState) => AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                      hintText: 'Search supplier...',
                      hintStyle: const TextStyle(fontFamily: 'Literata', fontSize: 13),
                      prefixIcon: const Icon(Icons.search, size: 20),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      isDense: true,
                    ),
                    style: const TextStyle(fontFamily: 'Literata', fontSize: 13),
                    onChanged: (q) {
                      setPickerState(() {
                        filtered = _suppliers.where((s) =>
                          (s['fullName'] as String).toLowerCase().contains(q.toLowerCase())
                        ).toList();
                      });
                    },
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: filtered.isEmpty
                        ? Center(
                            child: Text(
                              'No suppliers found',
                              style: TextStyle(
                                fontFamily: 'Literata',
                                color: Colors.grey[500],
                                fontSize: 13,
                              ),
                            ),
                          )
                        : ListView.builder(
                            itemCount: filtered.length,
                            itemBuilder: (context, index) {
                              final supplier = filtered[index];
                              return ListTile(
                                dense: true,
                                title: Text(
                                  supplier['fullName'] as String,
                                  style: const TextStyle(
                                    fontFamily: 'Literata',
                                    fontSize: 14,
                                  ),
                                ),
                                subtitle: supplier['contact'] != null
                                    ? Text(
                                        supplier['contact'] as String,
                                        style: TextStyle(
                                          fontFamily: 'Literata',
                                          fontSize: 12,
                                          color: Colors.grey[500],
                                        ),
                                      )
                                    : null,
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

  /// Confirm and delete a purchase batch
  void _confirmDeletePurchase(PurchaseBatchEntity purchase) {
    showDialog(
      context: context,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: AlertDialog(
          backgroundColor: Colors.white.withOpacity(0.95),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Delete Purchase',
            style: TextStyle(
              fontFamily: 'Literata',
              fontWeight: FontWeight.w700,
              color: Colors.red,
              fontSize: 16,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Are you sure you want to delete this purchase?',
                style: TextStyle(
                  fontFamily: 'Literata',
                  fontSize: 14,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.withOpacity(0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      purchase.productName,
                      style: const TextStyle(
                        fontFamily: 'Literata',
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Qty: ${purchase.quantityPurchased} ${purchase.unit} • ₹${purchase.purchasePrice.toStringAsFixed(2)}/unit',
                      style: TextStyle(
                        fontFamily: 'Literata',
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    if (purchase.quantityRemaining < purchase.quantityPurchased) ...[
                      const SizedBox(height: 4),
                      Text(
                        '⚠ ${purchase.quantityPurchased - purchase.quantityRemaining} units already sold from this batch',
                        style: const TextStyle(
                          fontFamily: 'Literata',
                          fontSize: 11,
                          color: Colors.orange,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'This action cannot be undone. Stock will be adjusted accordingly.',
                style: TextStyle(
                  fontFamily: 'Literata',
                  fontSize: 12,
                  color: Colors.grey[500],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                _localizations.cancel,
                style: const TextStyle(
                  fontFamily: 'Literata',
                  color: Colors.grey,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  final controller = PurchaseBatchOfflineController.instance;
                  await controller.deleteBatch(purchase.id);

                  // Update product stock
                  DashboardRefreshService.instance
                      .notifyDataChanged(DataChangeType.purchase);
                  DashboardRefreshService.instance
                      .notifyDataChanged(DataChangeType.product);

                  // Trigger background sync
                  PurchaseBatchSyncService.instance.syncNow();

                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Purchase deleted successfully',
                          style: TextStyle(fontFamily: 'Literata'),
                        ),
                        backgroundColor: Color(0xFF1B4D3E),
                      ),
                    );
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Error deleting purchase: $e',
                        style: const TextStyle(fontFamily: 'Literata'),
                      ),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Delete',
                style: TextStyle(fontFamily: 'Literata', color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F6),
      floatingActionButton: _buildFAB(),
      body: SafeArea(
        top: !widget.isEmbedded,
        child: Column(
          children: [
            // Header (only when not embedded)
            if (!widget.isEmbedded) _buildHeader(),
            
            // Main content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SlideTransition(
                  position: _offsetAnimation,
                  child: FadeTransition(
                    opacity: _opacityAnimation,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 16),
                        
                        // Summary stats
                        PurchaseSummaryWidget(
                          purchases: _purchases,
                          dateFilter: _dateFilter,
                          supplierFilter: _supplierFilter,
                          customStartDate: _customStartDate,
                          customEndDate: _customEndDate,
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Filters
                        PurchaseFilterWidget(
                          selectedDateFilter: _dateFilter,
                          selectedSupplierId: _supplierFilter,
                          suppliers: _suppliers,
                          customStartDate: _customStartDate,
                          customEndDate: _customEndDate,
                          onDateFilterChanged: (filter) {
                            setState(() => _dateFilter = filter);
                          },
                          onSupplierChanged: (supplierId) {
                            setState(() => _supplierFilter = supplierId);
                          },
                          onCustomDateRangeSelected: (start, end) {
                            setState(() {
                              _customStartDate = start;
                              _customEndDate = end;
                            });
                          },
                          onReportTap: _generatePurchaseReport,
                          allLabel: _localizations.all,
                          todayLabel: _localizations.today,
                          supplierLabel: _localizations.supplier,
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Purchase list
                        Expanded(
                          child: PurchaseListWidget(
                            purchases: _purchases,
                            isLoading: _isLoading,
                            dateFilter: _dateFilter,
                            supplierFilter: _supplierFilter,
                            customStartDate: _customStartDate,
                            customEndDate: _customEndDate,
                            onRefresh: () {
                              PurchaseSyncService.instance.syncNow();
                              PurchaseBatchSyncService.instance.syncNow();
                            },
                            onPurchaseTap: _showPurchaseDetails,
                            onPurchaseLongPress: _showPurchaseContextMenu,
                            emptyTitle: _localizations.noPurchasesFound,
                            emptySubtitle: _localizations.trackPurchases,
                          ),
                        ),
                      ],
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

  // ── Filtered purchases (same logic as PurchaseListWidget) ──
  List<PurchaseBatchEntity> get _filteredPurchases {
    var filtered = _purchases;

    // Date filter
    if (_dateFilter == PurchaseDateFilter.today) {
      final today = DateTime.now();
      filtered = filtered.where((p) {
        return p.purchaseDate.year == today.year &&
            p.purchaseDate.month == today.month &&
            p.purchaseDate.day == today.day;
      }).toList();
    } else if (_dateFilter == PurchaseDateFilter.thisMonth) {
      final now = DateTime.now();
      filtered = filtered.where((p) {
        return p.purchaseDate.year == now.year &&
            p.purchaseDate.month == now.month;
      }).toList();
    } else if (_dateFilter == PurchaseDateFilter.thisYear) {
      final now = DateTime.now();
      filtered = filtered.where((p) {
        return p.purchaseDate.year == now.year;
      }).toList();
    } else if (_dateFilter == PurchaseDateFilter.custom && _customStartDate != null) {
      final start = DateTime(
        _customStartDate!.year,
        _customStartDate!.month,
        _customStartDate!.day,
      );
      final end = _customEndDate != null
          ? DateTime(
              _customEndDate!.year,
              _customEndDate!.month,
              _customEndDate!.day,
              23, 59, 59,
            )
          : DateTime(start.year, start.month, start.day, 23, 59, 59);
      filtered = filtered.where((p) {
        return p.purchaseDate.isAfter(start.subtract(const Duration(seconds: 1))) &&
            p.purchaseDate.isBefore(end.add(const Duration(seconds: 1)));
      }).toList();
    }

    // Supplier filter
    if (_supplierFilter != null && _supplierFilter!.isNotEmpty) {
      filtered = filtered.where((p) => p.supplierId == _supplierFilter).toList();
    }

    return filtered;
  }

  String _buildFilterDescription() {
    final parts = <String>[];
    if (_dateFilter == PurchaseDateFilter.today) {
      parts.add('Today');
    } else if (_dateFilter == PurchaseDateFilter.thisMonth) {
      parts.add('This Month');
    } else if (_dateFilter == PurchaseDateFilter.thisYear) {
      parts.add('This Year');
    } else if (_dateFilter == PurchaseDateFilter.custom && _customStartDate != null) {
      final dateFormat = DateFormat('dd MMM yyyy');
      final start = dateFormat.format(_customStartDate!);
      if (_customEndDate == null || _customStartDate == _customEndDate) {
        parts.add(start);
      } else {
        final end = dateFormat.format(_customEndDate!);
        parts.add('$start - $end');
      }
    } else {
      parts.add('All Time');
    }
    if (_supplierFilter != null && _supplierFilter!.isNotEmpty) {
      final supplierName = _suppliers
          .where((s) => s['id'] == _supplierFilter)
          .map((s) => s['name'] as String?)
          .firstOrNull;
      if (supplierName != null) {
        parts.add('Supplier: $supplierName');
      }
    }
    return parts.join(' | ');
  }

  // Flag to prevent concurrent report generation
  bool _isGeneratingReport = false;

  // ── Generate & show purchase report ──
  Future<void> _generatePurchaseReport() async {
    debugPrint('[PurchaseReport] Button tapped! _isGeneratingReport=$_isGeneratingReport');
    
    // Prevent concurrent generation
    if (_isGeneratingReport) {
      debugPrint('[PurchaseReport] Already generating, skipping');
      return;
    }
    
    final filtered = _filteredPurchases;
    debugPrint('[PurchaseReport] Filtered purchases: ${filtered.length}');
    
    if (filtered.isEmpty) {
      debugPrint('[PurchaseReport] No data - showing snackbar');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No purchase data to generate report'),
            duration: Duration(seconds: 2),
          ),
        );
      }
      return;
    }

    _isGeneratingReport = true;

    // Show loading indicator
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
              SizedBox(width: 12),
              Text('Generating PDF report...'),
            ],
          ),
          duration: Duration(seconds: 30),
        ),
      );
    }

    try {
      debugPrint('[PurchaseReport] Generating PDF for ${filtered.length} entries...');
      
      final pdfBytes = await PurchaseReportPdfGenerator.generate(
        purchases: filtered,
        filterDescription: _buildFilterDescription(),
      );
      
      debugPrint('[PurchaseReport] PDF generated: ${pdfBytes.length} bytes');
      
      // Save to temporary file for preview
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final tempFile = File('${tempDir.path}/purchase_report_$timestamp.pdf');
      await tempFile.writeAsBytes(pdfBytes);
      
      // Dismiss loading snackbar
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
      }

      if (!mounted) {
        _isGeneratingReport = false;
        return;
      }

      // Navigate to file preview page
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => FilePreviewPage(
            file: tempFile,
            fileName: 'Purchase Report',
            fileType: FilePreviewType.pdf,
            subtitle: '${filtered.length} entries • ${DateFormat('dd MMM yyyy').format(DateTime.now())}',
          ),
        ),
      );
      
      _isGeneratingReport = false;
    } catch (e, stack) {
      debugPrint('[PurchaseReport] Error: $e');
      debugPrint('[PurchaseReport] Stack: $stack');
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to generate report: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      _isGeneratingReport = false;
    }
  }

  Widget _buildHeader() {
    return SlideTransition(
      position: _offsetAnimation,
      child: FadeTransition(
        opacity: _opacityAnimation,
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1B4D3E).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.arrow_back_ios_rounded,
                    size: 20,
                    color: Color(0xFF1B4D3E),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _localizations.purchaseHistory,
                      style: const TextStyle(
                        fontFamily: 'Literata',
                        fontWeight: FontWeight.w800,
                        fontSize: 22,
                        color: Color(0xFF1B4D3E),
                      ),
                    ),
                    Text(
                      _localizations.trackPurchases,
                      style: TextStyle(
                        fontFamily: 'Literata',
                        fontWeight: FontWeight.w400,
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              // Scan Invoice button
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const InvoiceScannerPage()),
                    );
                    if (result == true && mounted) {
                      setState(() {});
                    }
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1B4D3E).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.document_scanner_rounded,
                      size: 22,
                      color: Color(0xFF1B4D3E),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Report button
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    debugPrint('[PurchaseReport] Report button InkWell tapped!');
                    _generatePurchaseReport();
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1B4D3E).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.description_rounded,
                      size: 22,
                      color: Color(0xFF1B4D3E),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Settings menu
              PopupMenuButton<String>(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1B4D3E).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.settings_rounded,
                    size: 22,
                    color: Color(0xFF1B4D3E),
                  ),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                onSelected: (value) async {
                  if (value == 'purchase_settings') {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const PurchaseSettingsPage(),
                      ),
                    );
                    setState(() {});
                  } else if (value == 'report_settings') {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const PurchaseReportSettingsPage(),
                      ),
                    );
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem<String>(
                    value: 'purchase_settings',
                    child: Row(
                      children: [
                        Icon(Icons.tune_rounded, 
                            color: Colors.grey[700], size: 20),
                        const SizedBox(width: 12),
                        const Text(
                          'Purchase Settings',
                          style: TextStyle(
                            fontFamily: 'Literata',
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuItem<String>(
                    value: 'report_settings',
                    child: Row(
                      children: [
                        Icon(Icons.view_column_rounded, 
                            color: Colors.grey[700], size: 20),
                        const SizedBox(width: 12),
                        const Text(
                          'Report Settings',
                          style: TextStyle(
                            fontFamily: 'Literata',
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
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

  Widget _buildFAB() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF1B4D3E),
                const Color(0xFF1B4D3E).withOpacity(0.85),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1B4D3E).withOpacity(0.35),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _navigateToAddPurchase,
              splashColor: Colors.white.withOpacity(0.2),
              highlightColor: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(22),
              child: const Center(
                child: Icon(
                  Icons.add_rounded,
                  size: 32,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Purchase details bottom sheet
class _PurchaseDetailsSheet extends StatefulWidget {
  final PurchaseBatchEntity purchase;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const _PurchaseDetailsSheet({
    required this.purchase,
    this.onEdit,
    this.onDelete,
  });

  @override
  State<_PurchaseDetailsSheet> createState() => _PurchaseDetailsSheetState();
}

class _PurchaseDetailsSheetState extends State<_PurchaseDetailsSheet> {
  /// Calculate total amount for this batch
  double get totalAmount => widget.purchase.purchasePrice * widget.purchase.quantityPurchased;

  /// Load custom field values from the product
  Future<Map<String, dynamic>> _loadProductCustomFields() async {
    try {
      final product = await ProductOfflineController.instance.getProductByServerId(widget.purchase.productId);
      if (product != null && product.customFieldsJson != null && product.customFieldsJson!.isNotEmpty) {
        return jsonDecode(product.customFieldsJson!) as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('Error loading product custom fields: $e');
    }
    return {};
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMM yyyy');
    final timeFormat = DateFormat('hh:mm a');
    final customColumns = ProductSettingsService.instance.activeCustomColumns;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.98),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle
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
                  const SizedBox(height: 20),

                  // Header
                  Row(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1B4D3E).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.inventory_2_rounded,
                          color: Color(0xFF1B4D3E),
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.purchase.productName,
                              style: const TextStyle(
                                fontFamily: 'Literata',
                                fontWeight: FontWeight.w800,
                                fontSize: 18,
                                color: Color(0xFF1B4D3E),
                              ),
                            ),
                            if (widget.purchase.companyName.isNotEmpty)
                              Text(
                                widget.purchase.companyName,
                                style: TextStyle(
                                  fontFamily: 'Literata',
                                  fontWeight: FontWeight.w500,
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Details grid
                  _buildDetailRow('Quantity', '${widget.purchase.quantityPurchased} ${widget.purchase.unit}'),
                  _buildDetailRow('Purchase Price', '₹${widget.purchase.purchasePrice.toStringAsFixed(2)}/unit'),
                  _buildDetailRow('Sales Price', '₹${widget.purchase.sellingPrice.toStringAsFixed(2)}/unit'),
                  _buildDetailRow('Total Amount', '₹${totalAmount.toStringAsFixed(2)}', highlight: true),
                  
                  if (widget.purchase.supplierName != null && widget.purchase.supplierName!.isNotEmpty)
                    _buildDetailRow('Supplier', widget.purchase.supplierName!),
                  
                  _buildDetailRow('Date', dateFormat.format(widget.purchase.purchaseDate)),
                  _buildDetailRow('Time', timeFormat.format(widget.purchase.purchaseDate)),
                  
                  if (widget.purchase.productionDate != null)
                    _buildDetailRow('Production Date', dateFormat.format(widget.purchase.productionDate!)),
                  
                  if (widget.purchase.expiryDate != null)
                    _buildDetailRow('Expiry Date', dateFormat.format(widget.purchase.expiryDate!)),
                  
                  if (widget.purchase.warrantyMonths != null && widget.purchase.warrantyMonths! > 0)
                    _buildDetailRow('Warranty', '${widget.purchase.warrantyMonths} months'),
                  
                  if (widget.purchase.notes != null && widget.purchase.notes!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Text(
                      'Notes',
                      style: TextStyle(
                        fontFamily: 'Literata',
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: Color(0xFF1B4D3E),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        widget.purchase.notes!,
                        style: TextStyle(
                          fontFamily: 'Literata',
                          fontWeight: FontWeight.w400,
                          fontSize: 13,
                          color: Colors.grey[700],
                        ),
                      ),
                    ),
                  ],

                  // Custom Fields Section
                  if (customColumns.isNotEmpty) ...[                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Icon(Icons.tune_rounded, 
                            size: 16, 
                            color: Colors.grey[600]),
                        const SizedBox(width: 8),
                        Text(
                          'Custom Fields',
                          style: TextStyle(
                            fontFamily: 'Literata',
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    FutureBuilder<Map<String, dynamic>>(
                      future: _loadProductCustomFields(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Center(
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Color(0xFF1B4D3E),
                                ),
                              ),
                            ),
                          );
                        }
                        final fieldValues = snapshot.data ?? {};
                        return Column(
                          children: customColumns.map((column) {
                            final value = fieldValues[column.id];
                            String displayValue = _formatCustomFieldValue(column, value);
                            return _buildDetailRow(column.name, displayValue);
                          }).toList(),
                        );
                      },
                    ),
                  ],

                  const SizedBox(height: 24),

                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: widget.onEdit,
                          icon: const Icon(Icons.edit_rounded, size: 18),
                          label: const Text('Edit'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF1B4D3E),
                            side: const BorderSide(color: Color(0xFF1B4D3E)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: widget.onDelete,
                          icon: const Icon(Icons.delete_outline_rounded, size: 18),
                          label: const Text('Delete'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
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

  /// Format custom field value for display
  String _formatCustomFieldValue(CustomColumn column, dynamic value) {
    if (value == null) return '-';
    
    switch (column.type) {
      case CustomColumnType.date:
        if (value.toString().isNotEmpty) {
          try {
            final date = DateTime.parse(value.toString());
            return DateFormat('dd MMM yyyy').format(date);
          } catch (_) {
            return value.toString();
          }
        }
        return '-';
      case CustomColumnType.boolean:
        return value == true || value == 'true' ? 'Yes' : 'No';
      default:
        return value.toString().isEmpty ? '-' : value.toString();
    }
  }

  Widget _buildDetailRow(String label, String value, {bool highlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Literata',
              fontWeight: FontWeight.w500,
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Literata',
              fontWeight: highlight ? FontWeight.w800 : FontWeight.w600,
              fontSize: highlight ? 16 : 14,
              color: highlight ? const Color(0xFF1B4D3E) : Colors.grey[800],
            ),
          ),
        ],
      ),
    );
  }
}

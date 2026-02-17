import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:c_billing/core/services/language_service.dart';
import 'package:c_billing/core/services/dashboard_refresh_service.dart';
import 'package:c_billing/core/localization/app_localizations.dart';
import '../../offline/entities/purchase_entity.dart';
import '../../offline/controllers/purchase_offline_controller.dart';
import '../../data/services/purchase_sync_service.dart';
import '../../../supplier/offline/controllers/supplier_offline_controller.dart';
import '../../../supplier/offline/entities/supplier_entity.dart';
import '../../../../common_widgets/action_menu.dart';
import '../widgets/purchase_filter_widget.dart';
import '../widgets/purchase_list_widget.dart';
import 'purchase_page.dart';
import 'purchase_settings_page.dart';

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
  List<PurchaseEntity> _purchases = [];
  List<Map<String, dynamic>> _suppliers = [];
  bool _isLoading = true;

  // Filters
  PurchaseDateFilter _dateFilter = PurchaseDateFilter.all;
  String? _supplierFilter;

  // Streams
  StreamSubscription<List<PurchaseEntity>>? _purchaseStreamSubscription;
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

    // Setup data streams
    _setupPurchaseStream();
    _setupSupplierStream();
    _setupCrossPageRefresh();

    // Start animation
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) _animController.forward();
    });

    // Trigger background sync
    PurchaseSyncService.instance.syncNow();
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

  /// Setup real-time purchase stream from Isar
  void _setupPurchaseStream() {
    _purchaseStreamSubscription = PurchaseOfflineController.instance
        .watchAllPurchases()
        .listen(
      (purchases) {
        if (mounted) {
          setState(() {
            _purchases = purchases;
            _isLoading = false;
          });
        }
      },
      onError: (e) {
        debugPrint('[EnhancedPurchase] Stream error: $e');
        if (mounted) {
          setState(() => _isLoading = false);
        }
      },
    );
  }

  /// Setup supplier stream for filter dropdown
  void _setupSupplierStream() {
    _supplierStreamSubscription = SupplierOfflineController.instance
        .watchAllSuppliers()
        .listen(
      (suppliers) {
        if (mounted) {
          setState(() {
            _suppliers = suppliers.map((s) => {
              'id': s.serverId ?? 'local_${s.id}',
              'firstName': s.firstName,
              'lastName': s.lastName,
              'fullName': '${s.firstName} ${s.lastName}'.trim(),
              'contact': s.contact,
            }).toList();
          });
        }
      },
      onError: (e) {
        debugPrint('[EnhancedPurchase] Supplier stream error: $e');
      },
    );
  }

  /// Listen for purchase changes from other screens
  void _setupCrossPageRefresh() {
    _purchaseChangeSubscription = DashboardRefreshService.instance
        .onPurchaseChanged
        .listen((_) {
      if (mounted) {
        // Stream auto-updates, just trigger sync
        PurchaseSyncService.instance.syncNow();
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
    // Stream auto-refreshes, but trigger sync just in case
    PurchaseSyncService.instance.syncNow();
  }

  /// Show purchase details bottom sheet
  void _showPurchaseDetails(PurchaseEntity purchase) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _PurchaseDetailsSheet(
        purchase: purchase,
        onEdit: () {
          Navigator.pop(context);
          // TODO: Navigate to edit purchase if supported
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Edit feature coming soon'),
              duration: Duration(seconds: 2),
            ),
          );
        },
        onDelete: () async {
          Navigator.pop(context);
          // TODO: Implement delete if supported
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Delete feature coming soon'),
              duration: Duration(seconds: 2),
            ),
          );
        },
      ),
    );
  }

  /// Show purchase context menu on long press
  void _showPurchaseContextMenu(PurchaseEntity purchase) {
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
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Edit feature coming soon'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                  ),
                  _buildContextMenuItem(
                    icon: Icons.delete_outline_rounded,
                    label: 'Delete',
                    isDestructive: true,
                    onTap: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Delete feature coming soon'),
                          duration: Duration(seconds: 2),
                        ),
                      );
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
                        // Section header
                        if (widget.isEmbedded) ...[
                          const SizedBox(height: 12),
                          _buildSectionHeader(),
                        ],
                        
                        const SizedBox(height: 16),
                        
                        // Summary stats
                        PurchaseSummaryWidget(
                          purchases: _purchases,
                          dateFilter: _dateFilter,
                          supplierFilter: _supplierFilter,
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Filters
                        PurchaseFilterWidget(
                          selectedDateFilter: _dateFilter,
                          selectedSupplierId: _supplierFilter,
                          suppliers: _suppliers,
                          onDateFilterChanged: (filter) {
                            setState(() => _dateFilter = filter);
                          },
                          onSupplierChanged: (supplierId) {
                            setState(() => _supplierFilter = supplierId);
                          },
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
                            onRefresh: () {
                              PurchaseSyncService.instance.syncNow();
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
              ActionMenu(
                menuColor: const Color(0xFF1B4D3E),
                iconColor: const Color(0xFF1B4D3E),
                onSettingsTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PurchaseSettingsPage(),
                    ),
                  );
                  setState(() {});
                },
                onLanguageTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Language change is available in Dashboard'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
                onBugReportTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Bug report feature coming soon'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _localizations.purchaseHistory,
              style: const TextStyle(
                fontFamily: 'Literata',
                fontWeight: FontWeight.w800,
                fontSize: 20,
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
        IconButton(
          onPressed: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const PurchaseSettingsPage(),
              ),
            );
            setState(() {});
          },
          icon: const Icon(
            Icons.settings_rounded,
            color: Color(0xFF1B4D3E),
          ),
        ),
      ],
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
class _PurchaseDetailsSheet extends StatelessWidget {
  final PurchaseEntity purchase;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const _PurchaseDetailsSheet({
    required this.purchase,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMM yyyy');
    final timeFormat = DateFormat('hh:mm a');

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
                              purchase.productName,
                              style: const TextStyle(
                                fontFamily: 'Literata',
                                fontWeight: FontWeight.w800,
                                fontSize: 18,
                                color: Color(0xFF1B4D3E),
                              ),
                            ),
                            if (purchase.companyName != null &&
                                purchase.companyName!.isNotEmpty)
                              Text(
                                purchase.companyName!,
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
                  _buildDetailRow('Quantity', '${purchase.quantity} ${purchase.unit}'),
                  _buildDetailRow('Purchase Price', '₹${purchase.purchasePrice.toStringAsFixed(2)}/unit'),
                  _buildDetailRow('Sales Price', '₹${purchase.salesPrice.toStringAsFixed(2)}/unit'),
                  _buildDetailRow('Total Amount', '₹${purchase.totalAmount.toStringAsFixed(2)}', highlight: true),
                  
                  if (purchase.supplierName != null && purchase.supplierName!.isNotEmpty)
                    _buildDetailRow('Supplier', purchase.supplierName!),
                  
                  _buildDetailRow('Date', dateFormat.format(purchase.createdAt)),
                  _buildDetailRow('Time', timeFormat.format(purchase.createdAt)),
                  
                  if (purchase.productionDate != null)
                    _buildDetailRow('Production Date', dateFormat.format(purchase.productionDate!)),
                  
                  if (purchase.expiryDate != null)
                    _buildDetailRow('Expiry Date', dateFormat.format(purchase.expiryDate!)),
                  
                  if (purchase.warrantyMonths != null && purchase.warrantyMonths! > 0)
                    _buildDetailRow('Warranty', '${purchase.warrantyMonths} months'),
                  
                  if (purchase.notes != null && purchase.notes!.isNotEmpty) ...[
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
                        purchase.notes!,
                        style: TextStyle(
                          fontFamily: 'Literata',
                          fontWeight: FontWeight.w400,
                          fontSize: 13,
                          color: Colors.grey[700],
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: onEdit,
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
                          onPressed: onDelete,
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

import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/services/language_service.dart';
import '../../../../core/services/dashboard_refresh_service.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../data/datasources/customer_cache_datasource.dart';
import '../../offline/controllers/customer_offline_controller.dart';
import '../../offline/entities/customer_entity.dart';
import '../../data/services/customer_sync_service.dart';
import '../../../event_order/offline/controllers/event_order_offline_controller.dart';
import '../../../event_order/offline/entities/event_order_entity.dart';
import '../../../event_order/domain/entities/event_order.dart';
import '../widgets/customer_summary_widget.dart';
import '../widgets/customer_filter_widget.dart';
import '../widgets/customer_list_widget.dart';
import 'customer_details_page.dart';
import 'customer_finance_page.dart';
import 'customer_transactions_page.dart';
import 'package:c_billing/core/ui/glassy_toast.dart';
import 'package:c_billing/common_widgets/app_top_bar.dart';
import 'package:c_billing/core/theme/app_theme.dart';
import 'package:c_billing/common_widgets/glass_bottom_sheet.dart';
import 'package:c_billing/common_widgets/app_pill_button.dart';
import 'package:c_billing/common_widgets/glass_icon_fab.dart';
import 'package:c_billing/core/ui/desktop_canvas.dart';

// Lets the desktop shell header open the add-customer sheet.
class CustomerScreenActions {
  static VoidCallback? add;
}

class EnhancedCustomerPage extends StatefulWidget {
  final bool isEmbedded;

  const EnhancedCustomerPage({super.key, this.isEmbedded = false});

  @override
  State<EnhancedCustomerPage> createState() => _EnhancedCustomerPageState();
}

class _EnhancedCustomerPageState extends State<EnhancedCustomerPage>
    with SingleTickerProviderStateMixin {
  // Animation
  late AnimationController _animController;
  late Animation<Offset> _offsetAnimation;
  late Animation<double> _opacityAnimation;

  // Form controllers
  final _firstNameController = TextEditingController();
  final _middleNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _contactController = TextEditingController();
  final _addressController = TextEditingController();
  final _gstinController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  // State
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isEditing = false;
  String? _editingCustomerId;
  List<Map<String, dynamic>> _customers = [];
  // Raw customer entities from the local database stream (used to recompute _customers)
  List<CustomerEntity> _customerEntities = [];
  String _searchQuery = '';
  CustomerSortField _sortField = CustomerSortField.name;
  bool _sortAscending = true;
  bool _isNavigatingAway = false;

  // local stream for real-time updates
  StreamSubscription<List<CustomerEntity>>? _customerStreamSub;
  // Event order stream for pending amount calculation
  StreamSubscription<List<EventOrderEntity>>? _eventOrderStreamSub;
  // Cached event pending amounts per customer (customerId -> total remaining)
  Map<String, double> _eventPendingByCustomer = {};
  // Firestore stream for cross-device real-time sync
  StreamSubscription<QuerySnapshot>? _firestoreStreamSub;

  // Services
  final _auth = FirebaseAuth.instance;
  late final FirebaseFirestore _firestore;
  late AppLocalizations _localizations;
  final _cacheDataSource = CustomerCacheDataSource();

  @override
  void initState() {
    super.initState();
    _firestore = FirebaseFirestore.instance;
    _localizations = AppLocalizations.of(
      LanguageService.instance.currentLanguage,
    );
    LanguageService.instance.addListener(_onLanguageChanged);

    // Setup animations
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _offsetAnimation =
        Tween<Offset>(begin: const Offset(0, 0.05), end: Offset.zero).animate(
          CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
        );
    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));

    CustomerScreenActions.add = _showAddCustomerSheet;
    _checkUserAuthentication();
    _setupLocalStream();
    _setupEventOrderStream();
    _loadLocalCustomers();
    _fetchFromFirebase();
    _setupFirestoreStream();

    // Start animation after frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _animController.forward();
    });
  }

  @override
  void dispose() {
    CustomerScreenActions.add = null;
    _isNavigatingAway = true;
    _animController.dispose();
    _customerStreamSub?.cancel();
    _eventOrderStreamSub?.cancel();
    _firestoreStreamSub?.cancel();
    _firstNameController.dispose();
    _middleNameController.dispose();
    _lastNameController.dispose();
    _contactController.dispose();
    _addressController.dispose();
    _gstinController.dispose();
    LanguageService.instance.removeListener(_onLanguageChanged);
    super.dispose();
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

  void _checkUserAuthentication() {
    if (_auth.currentUser == null) {
      Navigator.of(
        context,
        rootNavigator: true,
      ).pushNamedAndRemoveUntil('/login', (route) => false);
    }
  }

  // ━━━ DATA: Local stream (offline-first, real-time) ━━━

  Future<void> _loadLocalCustomers() async {
    try {
      final entities = await CustomerOfflineController.instance
          .getAllCustomers();
      if (!mounted || _isNavigatingAway) return;
      _customerEntities = entities;
      _rebuildCustomerList();
    } catch (e) {
      debugPrint('[EnhancedCustomer] local load error: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _setupLocalStream() {
    final offlineCtrl = CustomerOfflineController.instance;
    _customerStreamSub = offlineCtrl.watchAllCustomers().listen(
      (entities) {
        if (!mounted || _isNavigatingAway) return;
        _customerEntities = entities;
        _rebuildCustomerList();
        debugPrint(
          '[EnhancedCustomer] local stream: ${entities.length} customers',
        );
      },
      onError: (e) {
        debugPrint('[EnhancedCustomer] local stream error: $e');
        if (mounted) setState(() => _isLoading = false);
      },
    );
  }

  // Watch event orders to compute per-customer event pending amounts
  void _setupEventOrderStream() {
    final eventCtrl = EventOrderOfflineController.instance;
    _eventOrderStreamSub = eventCtrl.watchAllEventOrders().listen(
      (orders) {
        if (!mounted || _isNavigatingAway) return;
        final pendingMap = <String, double>{};
        for (final order in orders) {
          final custId = order.customerId;
          if (custId == null || custId.isEmpty) continue;
          // Skip cancelled and convertedToBill orders
          if (order.status == OrderStatus.cancelled.index ||
              order.status == OrderStatus.convertedToBill.index) {
            continue;
          }
          pendingMap[custId] =
              (pendingMap[custId] ?? 0.0) + order.remainingAmount;
        }
        if (!mounted) return;
        _eventPendingByCustomer = pendingMap;
        _rebuildCustomerList();
        debugPrint(
          '[EnhancedCustomer] Event pending updated for ${pendingMap.length} customers',
        );
      },
      onError: (e) {
        debugPrint('[EnhancedCustomer] Event order stream error: $e');
      },
    );
  }

  // Rebuild _customers list from raw entities + event pending data
  void _rebuildCustomerList() {
    final mapped = _customerEntities.map(_entityToMap).toList();
    setState(() {
      _customers = mapped;
      _isLoading = false;
    });
  }

  // Convert CustomerEntity -> Map for UI
  Map<String, dynamic> _entityToMap(CustomerEntity entity) {
    final nameParts = entity.name.split(' ');
    final firstName = nameParts.isNotEmpty ? nameParts.first : '';
    final lastName = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';
    return {
      'id': entity.serverId ?? 'local_${entity.id}',
      'localId': entity.id,
      'serverId': entity.serverId, // Explicit serverId field
      'firstName': firstName,
      'lastName': lastName,
      'contact': entity.mobile,
      'address': entity.address ?? '',
      'email': entity.email ?? '',
      'gstin': entity.gstin ?? '',
      'isActive': true,
      'isSynced': entity.isSynced,
      'currentPendingAmount':
          entity.currentPendingAmount +
          (_eventPendingByCustomer[entity.serverId] ?? 0.0) +
          (_eventPendingByCustomer['local_${entity.id}'] ?? 0.0),
      'billPendingAmount': entity.currentPendingAmount,
      'eventPendingAmount':
          (_eventPendingByCustomer[entity.serverId] ?? 0.0) +
          (_eventPendingByCustomer['local_${entity.id}'] ?? 0.0),
      'totalPurchases': entity.totalPurchases,
      'createdAt': entity.createdAt,
    };
  }

  // ━━━ DATA: Firebase fetch + import into the local database ━━━

  Future<void> _fetchFromFirebase() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return;

      final snapshot = await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('customers')
          .get();

      debugPrint('[EnhancedCustomer] Firebase: ${snapshot.docs.length} docs');

      final serverList = snapshot.docs
          .where((doc) {
            final data = doc.data();
            return data['isActive'] != false;
          })
          .map((doc) {
            final data = doc.data();
            final firstName = (data['firstName'] ?? '').toString();
            final middleName = (data['middleName'] ?? '').toString();
            final lastName = (data['lastName'] ?? '').toString();
            final fullName = [
              firstName,
              middleName,
              lastName,
            ].where((s) => s.isNotEmpty).join(' ');

            return <String, dynamic>{
              'id': doc.id,
              'name': fullName,
              'mobile': data['contact'] ?? '',
              'address': data['address'] ?? '',
              'email': data['email'] ?? '',
              'gstin': data['gstin'] ?? data['gst'] ?? '',
              'currentPendingAmount':
                  data['currentPendingAmount'] ?? data['pendingBalance'] ?? 0,
              'totalPurchases':
                  data['totalPurchaseAmount'] ?? data['totalPurchases'] ?? 0,
              'updatedAt': data['updatedAt'] is Timestamp
                  ? (data['updatedAt'] as Timestamp).toDate().toIso8601String()
                  : data['updatedAt']?.toString() ?? '',
              'createdAt': data['createdAt'] is Timestamp
                  ? (data['createdAt'] as Timestamp).toDate().toIso8601String()
                  : data['createdAt']?.toString() ?? '',
            };
          })
          .toList();

      // Import into the local database - the stream listener auto-updates the UI
      await CustomerOfflineController.instance.importFromServer(serverList);

      // Trigger background sync for any local-only records
      CustomerSyncService.instance.syncNow();

      // Cache for next time
      if (_customers.isNotEmpty) {
        _cacheDataSource.saveCustomers(_customers);
      }
    } catch (e) {
      debugPrint('[EnhancedCustomer] Firebase fetch error: $e');
      if (mounted && _customers.isEmpty) {
        GlassyToast.show(
          context,
          '${_localizations.errorLoadingCustomers}: $e',
          isError: true,
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Setup real-time Firestore stream for cross-device synchronization
  void _setupFirestoreStream() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    _firestoreStreamSub = _firestore
        .collection('users')
        .doc(currentUser.uid)
        .collection('customers')
        .snapshots()
        .listen(
          (snapshot) async {
            if (!mounted || _isNavigatingAway) return;

            debugPrint(
              '[EnhancedCustomer] Firestore stream: ${snapshot.docs.length} docs (${snapshot.docChanges.length} changes)',
            );

            final serverList = snapshot.docs
                .where((doc) {
                  final data = doc.data();
                  return data['isActive'] != false;
                })
                .map((doc) {
                  final data = doc.data();
                  final firstName = (data['firstName'] ?? '').toString();
                  final middleName = (data['middleName'] ?? '').toString();
                  final lastName = (data['lastName'] ?? '').toString();
                  final fullName = [
                    firstName,
                    middleName,
                    lastName,
                  ].where((s) => s.isNotEmpty).join(' ');

                  return <String, dynamic>{
                    'id': doc.id,
                    'name': fullName,
                    'mobile': data['contact'] ?? '',
                    'address': data['address'] ?? '',
                    'email': data['email'] ?? '',
                    'currentPendingAmount':
                        data['currentPendingAmount'] ??
                        data['pendingBalance'] ??
                        0,
                    'totalPurchases':
                        data['totalPurchaseAmount'] ??
                        data['totalPurchases'] ??
                        0,
                    'updatedAt': data['updatedAt'] is Timestamp
                        ? (data['updatedAt'] as Timestamp)
                              .toDate()
                              .toIso8601String()
                        : data['updatedAt']?.toString() ?? '',
                    'createdAt': data['createdAt'] is Timestamp
                        ? (data['createdAt'] as Timestamp)
                              .toDate()
                              .toIso8601String()
                        : data['createdAt']?.toString() ?? '',
                  };
                })
                .toList();

            // Import into the local database - the stream listener auto-updates the UI
            await CustomerOfflineController.instance.importFromServer(
              serverList,
            );

            // Cache for next time
            if (_customers.isNotEmpty && mounted) {
              _cacheDataSource.saveCustomers(_customers);
            }
          },
          onError: (e) {
            debugPrint('[ERROR] Firestore customer stream error: $e');
          },
        );
  }

  // ━━━ FORM HELPERS ━━━

  void _clearForm() {
    _firstNameController.clear();
    _middleNameController.clear();
    _lastNameController.clear();
    _contactController.clear();
    _addressController.clear();
    _gstinController.clear();
    _editingCustomerId = null;
    _isEditing = false;
  }

  void _editCustomer(Map<String, dynamic> customer) {
    _firstNameController.text = customer['firstName'] ?? '';
    _middleNameController.text = customer['middleName'] ?? '';
    _lastNameController.text = customer['lastName'] ?? '';
    _contactController.text = customer['contact'] ?? '';
    _addressController.text = customer['address'] ?? '';
    _gstinController.text = customer['gstin'] ?? customer['gst'] ?? '';
    _editingCustomerId = customer['id'];
    _isEditing = true;
  }

  // ━━━ SAVE ━━━

  Future<void> _saveCustomer() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    try {
      final firstName = _firstNameController.text.trim();
      final middleName = _middleNameController.text.trim();
      final lastName = _lastNameController.text.trim();
      final fullName = [
        firstName,
        middleName,
        lastName,
      ].where((s) => s.isNotEmpty).join(' ');
      final contact = _contactController.text.trim();
      final address = _addressController.text.trim();
      final gstinRaw = _gstinController.text.trim().toUpperCase();
      final gstin = gstinRaw.isEmpty ? null : gstinRaw;
      final offlineCtrl = CustomerOfflineController.instance;

      if (_isEditing && _editingCustomerId != null) {
        // Update existing customer
        final existing = await offlineCtrl.getCustomerByServerId(
          _editingCustomerId!,
        );
        if (existing != null) {
          await offlineCtrl.updateCustomer(
            id: existing.id,
            name: fullName,
            mobile: contact,
            address: address,
            gstin: gstin,
            updateGstin: true,
          );
        } else {
          // Fallback: Firebase direct update
          final uid = _auth.currentUser?.uid;
          if (uid != null) {
            await _firestore
                .collection('users')
                .doc(uid)
                .collection('customers')
                .doc(_editingCustomerId)
                .update({
                  'firstName': firstName,
                  'middleName': middleName,
                  'lastName': lastName,
                  'contact': contact,
                  'address': address,
                  'gstin': gstin,
                  'updatedAt': FieldValue.serverTimestamp(),
                });
            _fetchFromFirebase();
          }
        }
        DashboardRefreshService.instance.notifyDataChanged(
          DataChangeType.customer,
        );

        // Trigger background sync for the update
        CustomerSyncService.instance.syncNow();

        _clearForm();
        if (mounted && context.mounted) {
          Navigator.pop(context);
          _showSnackbar(_localizations.customerUpdatedSuccess, false);
        }
      } else {
        // Create new -> local database first (offline-first)
        await offlineCtrl.addCustomer(
          name: fullName,
          mobile: contact,
          address: address,
          gstin: gstin,
        );
        DashboardRefreshService.instance.notifyDataChanged(
          DataChangeType.customer,
        );
        CustomerSyncService.instance.syncNow();

        _clearForm();
        if (mounted && context.mounted) {
          Navigator.pop(context);
          _showSnackbar(_localizations.customerSavedOffline, false);
        }
      }
    } catch (e) {
      debugPrint('[EnhancedCustomer] Save error: $e');
      if (mounted && context.mounted) {
        _showSnackbar('${_localizations.errorSavingCustomer}: $e', true);
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // ━━━ DELETE ━━━

  Future<void> _deleteCustomer(Map<String, dynamic> customer) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: AlertDialog(
          backgroundColor: AppColors.card(context),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            _localizations.deleteCustomer,
            style: TextStyle(
              fontFamily: 'Literata',
              fontWeight: FontWeight.w700,
              color: AppTheme.red,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _localizations.deleteCustomerConfirmation,
                style: TextStyle(
                  fontFamily: 'Literata',
                  fontSize: 14,
                  color: AppTheme.grey700,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.red.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.red.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.accentSoft(context, 0.1),
                      ),
                      child: Center(
                        child: Text(
                          (customer['firstName'] ?? 'C')
                              .toString()
                              .substring(0, 1)
                              .toUpperCase(),
                          style: TextStyle(
                            fontFamily: 'Literata',
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            color: AppColors.accent(context),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${customer['firstName'] ?? ''} ${customer['lastName'] ?? ''}'
                                .trim(),
                            style: const TextStyle(
                              fontFamily: 'Literata',
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                          if ((customer['contact'] ?? '').isNotEmpty)
                            Text(
                              customer['contact'],
                              style: TextStyle(
                                fontFamily: 'Literata',
                                fontSize: 12,
                                color: AppTheme.grey600,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _localizations.actionCannotBeUndone,
                style: TextStyle(
                  fontFamily: 'Literata',
                  fontSize: 12,
                  color: AppTheme.grey,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(
                _localizations.cancel,
                style: const TextStyle(
                  fontFamily: 'Literata',
                  color: AppTheme.grey,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.red,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                _localizations.delete,
                style: const TextStyle(
                  fontFamily: 'Literata',
                  color: AppTheme.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
    if (confirmed != true) return;

    try {
      final offlineCtrl = CustomerOfflineController.instance;
      final localId = customer['localId'] as int?;
      final serverId = customer['id'] as String?;

      if (localId != null) {
        await offlineCtrl.deleteCustomer(localId);
      } else if (serverId != null) {
        final existing = await offlineCtrl.getCustomerByServerId(serverId);
        if (existing != null) {
          await offlineCtrl.deleteCustomer(existing.id);
        } else {
          // Fallback: delete from Firebase directly
          final uid = _auth.currentUser?.uid;
          if (uid != null) {
            await _firestore
                .collection('users')
                .doc(uid)
                .collection('customers')
                .doc(serverId)
                .delete();
            _fetchFromFirebase();
          }
        }
      }

      CustomerSyncService.instance.syncNow();
      DashboardRefreshService.instance.notifyDataChanged(
        DataChangeType.customer,
      );

      if (mounted && context.mounted) {
        _showSnackbar(_localizations.customerDeletedSuccess, false);
      }
    } catch (e) {
      debugPrint('[EnhancedCustomer] Delete error: $e');
      if (mounted && context.mounted) {
        _showSnackbar('${_localizations.errorDeletingCustomer}: $e', true);
      }
    }
  }

  // ━━━ NAVIGATION ━━━

  void _navigateToCustomerDetails(Map<String, dynamic> customer) {
    _isNavigatingAway = true;
    showAppPage(
      context,
      CustomerDetailsPage(customerId: customer['id']),
    ).then((_) {
      _isNavigatingAway = false;
      _fetchFromFirebase();
    });
  }

  // ━━━ SNACKBAR ━━━

  void _showSnackbar(String message, bool isError) {
    GlassyToast.show(context, message);
  }

  // ━━━ BUILD ━━━

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffold(context),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton:
          widget.isEmbedded && DesktopCanvas.isDesktopPlatform
          ? null
          : GlassIconFab(
              tooltip: _localizations.addCustomer,
              onPressed: _showAddCustomerSheet,
            ),
      body: SafeArea(
        top: false,
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
                        CustomerSummaryWidget(
                          customers: _customers,
                          searchQuery: _searchQuery,
                          customersLabel: _localizations.customers,
                          pendingLabel: _localizations.pendingAmount,
                          unsyncedLabel: _localizations.unsynced,
                          allSyncedLabel: _localizations.allSynced,
                        ),

                        const SizedBox(height: 16),

                        // Filters
                        CustomerFilterWidget(
                          searchQuery: _searchQuery,
                          sortField: _sortField,
                          sortAscending: _sortAscending,
                          onSearchChanged: (query) {
                            setState(() => _searchQuery = query);
                          },
                          onSortFieldChanged: (field) {
                            setState(() => _sortField = field);
                          },
                          onSortDirectionToggle: () {
                            setState(() => _sortAscending = !_sortAscending);
                          },
                          searchHint: _localizations.searchCustomers,
                          sortByNameLabel: _localizations.sortByName,
                          sortByDateLabel: _localizations.sortByDate,
                          sortByPendingLabel: _localizations.pendingAmount,
                        ),

                        const SizedBox(height: 16),

                        // Customer list
                        Expanded(
                          child: CustomerListWidget(
                            customers: _customers,
                            isLoading: _isLoading,
                            searchQuery: _searchQuery,
                            sortField: _sortField,
                            sortAscending: _sortAscending,
                            onRefresh: _fetchFromFirebase,
                            onCustomerTap: _showCustomerDetails,
                            onCustomerLongPress: _showCustomerContextMenu,
                            onFinanceTap: _openCustomerFinance,
                            onTransactionsTap: _openCustomerTransactions,
                            emptyTitle: _localizations.noCustomersYet,
                            emptySubtitle: _localizations.createFirstCustomer,
                            noResultsTitle: _localizations.noResultsFound,
                            noResultsSubtitle:
                                _localizations.tryDifferentSearch,
                            pendingLabel: _localizations.syncPending
                                .toLowerCase(),
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

  // ━━━ HEADER ━━━

  Widget _buildHeader() {
    return AppTopBar(
      title: _localizations.manageCustomers,
      subtitle: '${_customers.length} ${_localizations.customers.toLowerCase()}',
    );
  }

  // ━━━ CUSTOMER FINANCE/HISTORY PAGE ━━━

  void _openCustomerFinance(Map<String, dynamic> customer) {
    // Get the explicit serverId if available
    final serverId = customer['serverId'] as String?;
    // Get the local integer local id
    final localId = customer['localId']?.toString() ?? '';

    // Use serverId if available, otherwise use local ID
    final customerId = (serverId != null && serverId.isNotEmpty)
        ? serverId
        : localId;

    debugPrint(
      '[CustomerFinance] Opening finance page - serverId: $serverId, localId: $localId, using customerId: $customerId',
    );

    final firstName = customer['firstName'] as String? ?? '';
    final lastName = customer['lastName'] as String? ?? '';
    final fullName = '$firstName $lastName'.trim();
    final contact = customer['contact'] as String? ?? '';
    final pendingAmount =
        (customer['currentPendingAmount'] as num?)?.toDouble() ?? 0.0;

    showAppPage(
      context,
      CustomerFinancePage(
        customerId: customerId,
        customerLocalId: localId,
        customerName: fullName.isNotEmpty ? fullName : 'Customer',
        customerContact: contact,
        currentPendingAmount: pendingAmount,
      ),
    );
  }

  // ━━━ CUSTOMER TRANSACTIONS PAGE ━━━

  void _openCustomerTransactions(Map<String, dynamic> customer) {
    // Get the explicit serverId if available
    final serverId = customer['serverId'] as String?;
    // Get the local integer local id
    final localId = customer['localId']?.toString() ?? '';

    // Use serverId if available, otherwise use local ID
    final customerId = (serverId != null && serverId.isNotEmpty)
        ? serverId
        : localId;

    debugPrint(
      '[CustomerTransactions] Opening transactions page - serverId: $serverId, localId: $localId, using customerId: $customerId',
    );

    final firstName = customer['firstName'] as String? ?? '';
    final lastName = customer['lastName'] as String? ?? '';
    final fullName = '$firstName $lastName'.trim();
    final contact = customer['contact'] as String? ?? '';
    final pendingAmount =
        (customer['currentPendingAmount'] as num?)?.toDouble() ?? 0.0;

    showAppPage(
      context,
      CustomerTransactionsPage(
        customerId: customerId,
        customerLocalId: localId,
        customerName: fullName.isNotEmpty ? fullName : 'Customer',
        customerContact: contact,
        currentPendingAmount: pendingAmount,
      ),
    );
  }

  // ━━━ CUSTOMER DETAILS BOTTOM SHEET ━━━

  void _showCustomerDetails(Map<String, dynamic> customer) {
    showAppBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.transparent,
      builder: (context) => _CustomerDetailsSheet(
        customer: customer,
        localizations: _localizations,
        onViewDetails: () {
          Navigator.pop(context);
          _navigateToCustomerDetails(customer);
        },
        onEdit: () {
          Navigator.pop(context);
          _showEditCustomerSheet(customer);
        },
        onDelete: () {
          Navigator.pop(context);
          _deleteCustomer(customer);
        },
      ),
    );
  }

  // ━━━ CUSTOMER CONTEXT MENU ━━━

  void _showCustomerContextMenu(Map<String, dynamic> customer) {
    showAppBottomSheet(
      context: context,
      backgroundColor: AppTheme.transparent,
      builder: (context) => ClipRRect(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.card(context),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
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
                      color: AppTheme.grey300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      '${customer['firstName'] ?? ''} ${customer['lastName'] ?? ''}'
                          .trim(),
                      style: TextStyle(
                        fontFamily: 'Literata',
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: AppColors.accent(context),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Divider(height: 1),
                  _buildContextMenuItem(
                    icon: Icons.visibility_rounded,
                    label: _localizations.viewDetails,
                    onTap: () {
                      Navigator.pop(context);
                      _showCustomerDetails(customer);
                    },
                  ),
                  _buildContextMenuItem(
                    icon: Icons.account_balance_wallet_rounded,
                    label: _localizations.viewBalance,
                    onTap: () {
                      Navigator.pop(context);
                      _navigateToCustomerDetails(customer);
                    },
                  ),
                  _buildContextMenuItem(
                    icon: Icons.edit_rounded,
                    label: _localizations.edit,
                    onTap: () {
                      Navigator.pop(context);
                      _showEditCustomerSheet(customer);
                    },
                  ),
                  _buildContextMenuItem(
                    icon: Icons.delete_outline_rounded,
                    label: _localizations.delete,
                    isDestructive: true,
                    onTap: () {
                      Navigator.pop(context);
                      _deleteCustomer(customer);
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
              color: isDestructive ? AppTheme.red : AppTheme.grey700,
            ),
            const SizedBox(width: 16),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Literata',
                fontWeight: FontWeight.w500,
                fontSize: 15,
                color: isDestructive ? AppTheme.red : AppTheme.grey800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ━━━ ADD/EDIT BOTTOM SHEETS ━━━

  void _showAddCustomerSheet() {
    _clearForm();
    showAppBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.transparent,
      builder: (_) => _buildFormSheet(),
    );
  }

  void _showEditCustomerSheet(Map<String, dynamic> customer) {
    _editCustomer(customer);
    showAppBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.transparent,
      builder: (_) => _buildFormSheet(),
    );
  }

  Widget _buildFormSheet() {
    final action = DrawerBottomBar(
      action: AppPillButton(
        label: _isEditing
            ? _localizations.update
            : _localizations.addCustomer,
        icon: Icons.check_rounded,
        loading: _isSaving,
        expanded: !_isEditing,
        onPressed: _isSaving ? null : _saveCustomer,
      ),
    );
    return dockDrawerAction(
      context: context,
      action: action,
      phoneDecoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      body: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!DesktopCanvas.isDesktopPlatform)
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppTheme.grey300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                if (!DesktopCanvas.isDesktopPlatform) const SizedBox(height: 16),
                // Title
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _isEditing
                          ? _localizations.editCustomer
                          : _localizations.addNewCustomer,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.accent(context),
                        fontFamily: 'Literata',
                      ),
                    ),
                    if (!DesktopCanvas.isDesktopPlatform)
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          _clearForm();
                          Navigator.pop(context);
                        },
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                _buildField(
                  label: _localizations.firstName,
                  controller: _firstNameController,
                  icon: Icons.person_outline,
                  isRequired: true,
                ),
                const SizedBox(height: 14),
                _buildField(
                  label: _localizations.middleName,
                  controller: _middleNameController,
                  icon: Icons.person_outline,
                ),
                const SizedBox(height: 14),
                _buildField(
                  label: _localizations.lastName,
                  controller: _lastNameController,
                  icon: Icons.person_outline,
                  isRequired: true,
                ),
                const SizedBox(height: 14),
                _buildField(
                  label: _localizations.contactNumber,
                  controller: _contactController,
                  icon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                  isRequired: true,
                  maxLength: 10,
                ),
                const SizedBox(height: 14),
                _buildField(
                  label: _localizations.address,
                  controller: _addressController,
                  icon: Icons.location_on_outlined,
                  maxLines: 3,
                  isRequired: true,
                ),
                const SizedBox(height: 14),
                _buildField(
                  label: 'GSTIN (optional)',
                  controller: _gstinController,
                  icon: Icons.receipt_long_outlined,
                  maxLength: 15,
                ),
              ],
            ),
          ),
    );
  }

  Widget _buildField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    int? maxLength,
    bool isRequired = false,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      maxLength: maxLength,
      style: TextStyle(fontFamily: 'Literata', fontSize: 14),
      decoration: InputDecoration(
        labelText: isRequired ? '$label *' : label,
        labelStyle: TextStyle(color: AppTheme.grey600, fontFamily: 'Literata'),
        prefixIcon: Icon(icon, color: AppTheme.grey600),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppTheme.grey300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppTheme.grey300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.accent(context), width: 2),
        ),
        filled: true,
        fillColor: AppColors.scaffold(context),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
      ),
      validator: isRequired
          ? (value) {
              if (value == null || value.trim().isEmpty) {
                return '$label ${_localizations.isRequired}';
              }
              if (label == _localizations.contactNumber && value.length != 10) {
                return _localizations.contactMustBe10Digits;
              }
              return null;
            }
          : null,
    );
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ CUSTOMER DETAILS BOTTOM SHEET ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━...

class _CustomerDetailsSheet extends StatelessWidget {
  final Map<String, dynamic> customer;
  final AppLocalizations localizations;
  final VoidCallback onViewDetails;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _CustomerDetailsSheet({
    required this.customer,
    required this.localizations,
    required this.onViewDetails,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final fullName =
        '${customer['firstName'] ?? ''} ${customer['lastName'] ?? ''}'.trim();
    final firstName = (customer['firstName'] ?? '').toString();
    final contact = (customer['contact'] ?? '').toString();
    final address = (customer['address'] ?? '').toString();
    final pendingAmount =
        (customer['currentPendingAmount'] as num?)?.toDouble() ?? 0.0;
    final isSynced = customer['isSynced'] as bool? ?? true;

    final accentColor = AppColors.action(context);
    final initials = firstName.isNotEmpty ? firstName[0].toUpperCase() : 'C';

    return ClipRRect(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.7,
          ),
          decoration: BoxDecoration(
            color: AppColors.card(context),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SingleChildScrollView(
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Handle
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppTheme.grey300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Header with avatar
                    Row(
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                accentColor,
                                accentColor.withValues(alpha: 0.7),
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: accentColor.withValues(alpha: 0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              initials,
                              style: TextStyle(
                                color: AppTheme.white,
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                                fontFamily: 'Literata',
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      fullName.isNotEmpty ? fullName : '-',
                                      style: TextStyle(
                                        fontFamily: 'Literata',
                                        fontWeight: FontWeight.w700,
                                        fontSize: 18,
                                        color: AppColors.accent(context),
                                      ),
                                    ),
                                  ),
                                  // Sync status badge - always show
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isSynced
                                          ? AppTheme.green50
                                          : AppTheme.orange50,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          isSynced
                                              ? Icons.cloud_done_rounded
                                              : Icons.cloud_upload_rounded,
                                          size: 12,
                                          color: isSynced
                                              ? AppTheme.green700
                                              : AppTheme.orange700,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          isSynced
                                              ? localizations.synced
                                              : localizations.syncPending,
                                          style: TextStyle(
                                            fontFamily: 'Literata',
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                            color: isSynced
                                                ? AppTheme.green700
                                                : AppTheme.orange700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              if (contact.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.phone_rounded,
                                      size: 14,
                                      color: AppTheme.grey,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      contact,
                                      style: TextStyle(
                                        fontFamily: 'Literata',
                                        fontSize: 14,
                                        color: AppTheme.grey600,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Pending amount card
                    if (pendingAmount > 0)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.red50,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppTheme.red100),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppTheme.red100,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                Icons.account_balance_wallet_rounded,
                                color: AppTheme.red700,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    localizations.pendingAmount,
                                    style: TextStyle(
                                      fontFamily: 'Literata',
                                      fontSize: 12,
                                      color: AppTheme.error,
                                    ),
                                  ),
                                  Text(
                                    '₹${pendingAmount.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      fontFamily: 'Literata',
                                      fontWeight: FontWeight.w700,
                                      fontSize: 20,
                                      color: AppTheme.red700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Address
                    if (address.isNotEmpty && address != 'N/A') ...[
                      const SizedBox(height: 16),
                      _buildDetailRow(
                        context: context,
                        icon: Icons.location_on_outlined,
                        label: localizations.address,
                        value: address,
                      ),
                    ],

                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 16),

                    // Action buttons
                    Row(
                      children: [
                        Expanded(
                          child: _buildActionButton(
                            context: context,
                            icon: Icons.visibility_rounded,
                            label: localizations.viewBalance,
                            onTap: onViewDetails,
                            isPrimary: true,
                          ),
                        ),
                        const SizedBox(width: 12),
                        _buildActionButton(
                          context: context,
                          icon: Icons.edit_rounded,
                          label: localizations.edit,
                          onTap: onEdit,
                        ),
                        const SizedBox(width: 12),
                        _buildActionButton(
                          context: context,
                          icon: Icons.delete_outline_rounded,
                          label: localizations.delete,
                          onTap: onDelete,
                          isDestructive: true,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.scaffold(context),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.isDark(context)
                  ? AppTheme.white.withValues(alpha: 0.1)
                  : AppColors.action(context).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 18,
              color: AppColors.isDark(context)
                  ? AppTheme.white
                  : AppColors.action(context),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontFamily: 'Literata',
                    fontSize: 11,
                    color: AppColors.mutedText(context),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontFamily: 'Literata',
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.primaryText(context),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isPrimary = false,
    bool isDestructive = false,
  }) {
    final isDark = AppColors.isDark(context);
    final primaryFill = isDark ? AppTheme.white : AppColors.action(context);
    final onPrimary = isDark ? AppTheme.black : AppTheme.white;
    final destructiveFill = isDark
        ? AppTheme.red.withValues(alpha: 0.18)
        : AppTheme.red50;
    final muted = AppColors.secondaryText(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isPrimary
              ? primaryFill
              : isDestructive
              ? destructiveFill
              : AppColors.chipFill(context),
          borderRadius: BorderRadius.circular(12),
          border: isDestructive
              ? Border.all(
                  color: isDark
                      ? AppTheme.red.withValues(alpha: 0.4)
                      : AppTheme.red200,
                )
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 20,
              color: isPrimary
                  ? onPrimary
                  : isDestructive
                  ? (isDark ? AppTheme.toneRose : AppTheme.red700)
                  : muted,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Literata',
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isPrimary
                    ? onPrimary
                    : isDestructive
                    ? (isDark ? AppTheme.toneRose : AppTheme.red700)
                    : muted,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

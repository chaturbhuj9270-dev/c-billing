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
import '../widgets/customer_summary_widget.dart';
import '../widgets/customer_filter_widget.dart';
import '../widgets/customer_list_widget.dart';
import 'customer_details_page.dart';

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
  final _formKey = GlobalKey<FormState>();

  // State
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isEditing = false;
  String? _editingCustomerId;
  List<Map<String, dynamic>> _customers = [];
  String _searchQuery = '';
  CustomerSortField _sortField = CustomerSortField.name;
  bool _sortAscending = true;
  bool _isNavigatingAway = false;

  // Isar stream for real-time updates
  StreamSubscription<List<CustomerEntity>>? _customerStreamSub;
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
    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    ));
    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    ));

    _checkUserAuthentication();
    _setupIsarStream();
    _fetchFromFirebase();
    _setupFirestoreStream();

    // Start animation after frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _animController.forward();
    });
  }

  @override
  void dispose() {
    _isNavigatingAway = true;
    _animController.dispose();
    _customerStreamSub?.cancel();
    _firestoreStreamSub?.cancel();
    _firstNameController.dispose();
    _middleNameController.dispose();
    _lastNameController.dispose();
    _contactController.dispose();
    _addressController.dispose();
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
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    }
  }

  // ━━━ DATA: Isar Stream (offline-first, real-time) ━━━

  void _setupIsarStream() {
    final offlineCtrl = CustomerOfflineController.instance;
    _customerStreamSub = offlineCtrl.watchAllCustomers().listen(
      (entities) {
        if (!mounted || _isNavigatingAway) return;
        final mapped = entities.map(_entityToMap).toList();
        setState(() {
          _customers = mapped;
          _isLoading = false;
        });
        debugPrint('[EnhancedCustomer] Isar stream: ${mapped.length} customers');
      },
      onError: (e) {
        debugPrint('[EnhancedCustomer] Isar stream error: $e');
        if (mounted) setState(() => _isLoading = false);
      },
    );
  }

  /// Convert CustomerEntity -> Map for UI
  Map<String, dynamic> _entityToMap(CustomerEntity entity) {
    final nameParts = entity.name.split(' ');
    final firstName = nameParts.isNotEmpty ? nameParts.first : '';
    final lastName = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';
    return {
      'id': entity.serverId ?? 'local_${entity.id}',
      'localId': entity.id,
      'firstName': firstName,
      'lastName': lastName,
      'contact': entity.mobile,
      'address': entity.address ?? '',
      'email': entity.email ?? '',
      'isActive': true,
      'isSynced': entity.isSynced,
      'currentPendingAmount': entity.currentPendingAmount,
      'totalPurchases': entity.totalPurchases,
      'createdAt': entity.createdAt,
    };
  }

  // ━━━ DATA: Firebase fetch + import into Isar ━━━

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

      final serverList = snapshot.docs.where((doc) {
        final data = doc.data();
        return data['isActive'] != false;
      }).map((doc) {
        final data = doc.data();
        final firstName = (data['firstName'] ?? '').toString();
        final middleName = (data['middleName'] ?? '').toString();
        final lastName = (data['lastName'] ?? '').toString();
        final fullName = [firstName, middleName, lastName]
            .where((s) => s.isNotEmpty)
            .join(' ');

        return <String, dynamic>{
          'id': doc.id,
          'name': fullName,
          'mobile': data['contact'] ?? '',
          'address': data['address'] ?? '',
          'email': data['email'] ?? '',
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
      }).toList();

      // Import into Isar — the stream listener auto-updates the UI
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading customers: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Setup real-time Firestore stream for cross-device synchronization
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
            '[EnhancedCustomer] Firestore stream: ${snapshot.docs.length} docs (${snapshot.docChanges.length} changes)');

        final serverList = snapshot.docs.where((doc) {
          final data = doc.data();
          return data['isActive'] != false;
        }).map((doc) {
          final data = doc.data();
          final firstName = (data['firstName'] ?? '').toString();
          final middleName = (data['middleName'] ?? '').toString();
          final lastName = (data['lastName'] ?? '').toString();
          final fullName = [firstName, middleName, lastName]
              .where((s) => s.isNotEmpty)
              .join(' ');

          return <String, dynamic>{
            'id': doc.id,
            'name': fullName,
            'mobile': data['contact'] ?? '',
            'address': data['address'] ?? '',
            'email': data['email'] ?? '',
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
        }).toList();

        // Import into Isar — the stream listener auto-updates the UI
        await CustomerOfflineController.instance.importFromServer(serverList);

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
    _editingCustomerId = null;
    _isEditing = false;
  }

  void _editCustomer(Map<String, dynamic> customer) {
    _firstNameController.text = customer['firstName'] ?? '';
    _middleNameController.text = customer['middleName'] ?? '';
    _lastNameController.text = customer['lastName'] ?? '';
    _contactController.text = customer['contact'] ?? '';
    _addressController.text = customer['address'] ?? '';
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
      final fullName = [firstName, middleName, lastName]
          .where((s) => s.isNotEmpty)
          .join(' ');
      final contact = _contactController.text.trim();
      final address = _addressController.text.trim();
      final offlineCtrl = CustomerOfflineController.instance;

      if (_isEditing && _editingCustomerId != null) {
        // Update existing customer
        final existing =
            await offlineCtrl.getCustomerByServerId(_editingCustomerId!);
        if (existing != null) {
          await offlineCtrl.updateCustomer(
            id: existing.id,
            name: fullName,
            mobile: contact,
            address: address,
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
              'updatedAt': FieldValue.serverTimestamp(),
            });
            _fetchFromFirebase();
          }
        }
        DashboardRefreshService.instance
            .notifyDataChanged(DataChangeType.customer);

        // Trigger background sync for the update
        CustomerSyncService.instance.syncNow();

        _clearForm();
        if (mounted && context.mounted) {
          Navigator.pop(context);
          _showSnackbar('Customer updated successfully', false);
        }
      } else {
        // Create new -> Isar first (offline-first)
        await offlineCtrl.addCustomer(
          name: fullName,
          mobile: contact,
          address: address,
        );
        DashboardRefreshService.instance
            .notifyDataChanged(DataChangeType.customer);
        CustomerSyncService.instance.syncNow();

        _clearForm();
        if (mounted && context.mounted) {
          Navigator.pop(context);
          _showSnackbar('Customer saved. Will sync when online.', false);
        }
      }
    } catch (e) {
      debugPrint('[EnhancedCustomer] Save error: $e');
      if (mounted && context.mounted) {
        _showSnackbar('Error saving customer: $e', true);
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
          backgroundColor: Colors.white.withOpacity(0.95),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            _localizations.deleteCustomer,
            style: const TextStyle(
              fontFamily: 'Literata',
              fontWeight: FontWeight.w700,
              color: Colors.red,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Are you sure you want to delete this customer?',
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
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF1B4D3E).withOpacity(0.1),
                      ),
                      child: Center(
                        child: Text(
                          (customer['firstName'] ?? 'C')
                              .toString()
                              .substring(0, 1)
                              .toUpperCase(),
                          style: const TextStyle(
                            fontFamily: 'Literata',
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            color: Color(0xFF1B4D3E),
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
                                color: Colors.grey[600],
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
                'This action cannot be undone.',
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
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(
                _localizations.cancel,
                style:
                    const TextStyle(fontFamily: 'Literata', color: Colors.grey),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                _localizations.delete,
                style:
                    const TextStyle(fontFamily: 'Literata', color: Colors.white),
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
      DashboardRefreshService.instance
          .notifyDataChanged(DataChangeType.customer);

      if (mounted && context.mounted) {
        _showSnackbar('Customer deleted successfully', false);
      }
    } catch (e) {
      debugPrint('[EnhancedCustomer] Delete error: $e');
      if (mounted && context.mounted) {
        _showSnackbar('Error deleting customer: $e', true);
      }
    }
  }

  // ━━━ NAVIGATION ━━━

  void _navigateToCustomerDetails(Map<String, dynamic> customer) {
    _isNavigatingAway = true;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CustomerDetailsPage(customerId: customer['id']),
      ),
    ).then((_) {
      _isNavigatingAway = false;
      _fetchFromFirebase();
    });
  }

  // ━━━ SNACKBAR ━━━

  void _showSnackbar(String message, bool isError) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontFamily: 'Literata'),
        ),
        backgroundColor: isError ? Colors.red : const Color(0xFF1B4D3E),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  // ━━━ BUILD ━━━

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
                        CustomerSummaryWidget(
                          customers: _customers,
                          searchQuery: _searchQuery,
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
                            emptyTitle: _localizations.noCustomersYet,
                            emptySubtitle: _localizations.createFirstCustomer,
                            noResultsTitle: _localizations.noResultsFound,
                            noResultsSubtitle: _localizations.tryDifferentSearch,
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
    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        MediaQuery.of(context).padding.top + 16,
        20,
        16,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1B4D3E), Color(0xFF0F3B2F)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1B4D3E).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.arrow_back_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _localizations.manageCustomers,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Literata',
                      height: 1.2,
                    ),
                  ),
                  Text(
                    '${_customers.length} ${_localizations.customers.toLowerCase()}',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 11,
                      fontFamily: 'Literata',
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ━━━ FAB ━━━

  Widget _buildFAB() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1B4D3E), Color(0xFF0F3B2F)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1B4D3E).withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: FloatingActionButton(
        onPressed: _showAddCustomerSheet,
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: const Icon(Icons.person_add_rounded, color: Colors.white),
      ),
    );
  }

  // ━━━ CUSTOMER DETAILS BOTTOM SHEET ━━━

  void _showCustomerDetails(Map<String, dynamic> customer) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
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
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
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
                      '${customer['firstName'] ?? ''} ${customer['lastName'] ?? ''}'
                          .trim(),
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

  // ━━━ ADD/EDIT BOTTOM SHEETS ━━━

  void _showAddCustomerSheet() {
    _clearForm();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _buildFormSheet(),
    );
  }

  void _showEditCustomerSheet(Map<String, dynamic> customer) {
    _editCustomer(customer);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _buildFormSheet(),
    );
  }

  Widget _buildFormSheet() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Form(
            key: _formKey,
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
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Title
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _isEditing
                          ? _localizations.editCustomer
                          : _localizations.addNewCustomer,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1B4D3E),
                        fontFamily: 'Literata',
                      ),
                    ),
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
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _saveCustomer,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1B4D3E),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor:
                                      AlwaysStoppedAnimation(Colors.white),
                                ),
                              )
                            : Text(
                                _isEditing
                                    ? _localizations.update
                                    : _localizations.addCustomer,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  fontFamily: 'Literata',
                                ),
                              ),
                      ),
                    ),
                    if (_isEditing) ...[
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _isSaving
                              ? null
                              : () {
                                  _clearForm();
                                  Navigator.pop(context);
                                },
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            _localizations.cancel,
                            style: const TextStyle(
                              color: Color(0xFF1B4D3E),
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'Literata',
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
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
      style: const TextStyle(fontFamily: 'Literata', fontSize: 14),
      decoration: InputDecoration(
        labelText: isRequired ? '$label *' : label,
        labelStyle: TextStyle(color: Colors.grey[600], fontFamily: 'Literata'),
        prefixIcon: Icon(icon, color: Colors.grey[600]),
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
        filled: true,
        fillColor: Colors.grey[50],
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
      validator: isRequired
          ? (value) {
              if (value == null || value.trim().isEmpty) {
                return '$label ${_localizations.isRequired}';
              }
              if (label == _localizations.contactNumber && value.length != 10) {
                return 'Contact number must be exactly 10 digits';
              }
              return null;
            }
          : null,
    );
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// CUSTOMER DETAILS BOTTOM SHEET
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

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

    const accentColor = Color(0xFF1B4D3E);
    final initials = firstName.isNotEmpty ? firstName[0].toUpperCase() : 'C';

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.7,
          ),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.98),
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
                          color: Colors.grey[300],
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
                                accentColor.withOpacity(0.7)
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: accentColor.withOpacity(0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              initials,
                              style: const TextStyle(
                                color: Colors.white,
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
                                      fullName.isNotEmpty ? fullName : '—',
                                      style: const TextStyle(
                                        fontFamily: 'Literata',
                                        fontWeight: FontWeight.w700,
                                        fontSize: 18,
                                        color: Color(0xFF1B4D3E),
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
                                          ? Colors.green[50]
                                          : Colors.orange[50],
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
                                              ? Colors.green[700]
                                              : Colors.orange[700],
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          isSynced ? 'Synced' : 'Pending',
                                          style: TextStyle(
                                            fontFamily: 'Literata',
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                            color: isSynced
                                                ? Colors.green[700]
                                                : Colors.orange[700],
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
                                      color: Colors.grey[500],
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      contact,
                                      style: TextStyle(
                                        fontFamily: 'Literata',
                                        fontSize: 14,
                                        color: Colors.grey[600],
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
                          color: Colors.red[50],
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.red[100]!),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.red[100],
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                Icons.account_balance_wallet_rounded,
                                color: Colors.red[700],
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Pending Amount',
                                    style: TextStyle(
                                      fontFamily: 'Literata',
                                      fontSize: 12,
                                      color: Colors.red[400],
                                    ),
                                  ),
                                  Text(
                                    '₹${pendingAmount.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      fontFamily: 'Literata',
                                      fontWeight: FontWeight.w700,
                                      fontSize: 20,
                                      color: Colors.red[700],
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
                            icon: Icons.visibility_rounded,
                            label: localizations.viewBalance,
                            onTap: onViewDetails,
                            isPrimary: true,
                          ),
                        ),
                        const SizedBox(width: 12),
                        _buildActionButton(
                          icon: Icons.edit_rounded,
                          label: localizations.edit,
                          onTap: onEdit,
                        ),
                        const SizedBox(width: 12),
                        _buildActionButton(
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
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF1B4D3E).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 18,
              color: const Color(0xFF1B4D3E),
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
                    color: Colors.grey[500],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontFamily: 'Literata',
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF2D2D2D),
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
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isPrimary = false,
    bool isDestructive = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isPrimary
              ? const Color(0xFF1B4D3E)
              : isDestructive
                  ? Colors.red[50]
                  : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: isDestructive
              ? Border.all(color: Colors.red[200]!)
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 20,
              color: isPrimary
                  ? Colors.white
                  : isDestructive
                      ? Colors.red[700]
                      : Colors.grey[700],
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Literata',
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isPrimary
                    ? Colors.white
                    : isDestructive
                        ? Colors.red[700]
                        : Colors.grey[700],
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

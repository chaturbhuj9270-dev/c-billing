import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/services/session_manager.dart';
import '../../../../core/services/language_service.dart';
import '../../../../core/services/dashboard_refresh_service.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../data/datasources/customer_cache_datasource.dart';
import '../../offline/controllers/customer_offline_controller.dart';
import '../../offline/entities/customer_entity.dart';
import '../../data/services/customer_sync_service.dart';
import 'customer_details_page.dart';

class CustomerPage extends StatefulWidget {
  final bool isEmbedded;

  const CustomerPage({super.key, this.isEmbedded = false});

  @override
  State<CustomerPage> createState() => _CustomerPageState();
}

class _CustomerPageState extends State<CustomerPage> {
  // Form controllers
  final _firstNameController = TextEditingController();
  final _middleNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _contactController = TextEditingController();
  final _addressController = TextEditingController();
  final _searchController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  // State
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isEditing = false;
  String? _editingCustomerId;
  List<Map<String, dynamic>> _customers = [];
  List<Map<String, dynamic>> _filteredCustomers = [];
  bool _isSortAscending = true;
  Timer? _searchDebounce;
  bool _isNavigatingAway = false;

  // Isar stream for real-time updates
  StreamSubscription<List<CustomerEntity>>? _customerStreamSub;
  // Firestore stream for cross-device real-time sync
  StreamSubscription<QuerySnapshot>? _firestoreStreamSub;

  // Services
  final _auth = FirebaseAuth.instance;
  late final FirebaseFirestore _firestore;
  late SessionManager _sessionManager;
  late AppLocalizations _localizations;
  final _cacheDataSource = CustomerCacheDataSource();

  @override
  void initState() {
    super.initState();
    _firestore = FirebaseFirestore.instance;
    _sessionManager = SessionManager();
    _localizations = AppLocalizations.of(
      LanguageService.instance.currentLanguage,
    );
    LanguageService.instance.addListener(_onLanguageChanged);
    _searchController.addListener(_onSearchChanged);

    _checkUserAuthentication();
    _setupIsarStream();
    _fetchFromFirebase();
    _setupFirestoreStream();
  }

  @override
  void dispose() {
    _isNavigatingAway = true;
    _customerStreamSub?.cancel();
    _firestoreStreamSub?.cancel();
    _searchDebounce?.cancel();
    _searchController.dispose();
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
          _applyFilter();
          _isLoading = false;
        });
        debugPrint('[Customer] Isar stream: ${mapped.length} customers');
      },
      onError: (e) {
        debugPrint('[Customer] Isar stream error: $e');
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
      'createdAt': entity.createdAt.toIso8601String(),
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

      debugPrint('[Customer] Firebase: ${snapshot.docs.length} docs');

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
          'currentPendingAmount': data['currentPendingAmount'] ?? data['pendingBalance'] ?? 0,
          'totalPurchases': data['totalPurchaseAmount'] ?? data['totalPurchases'] ?? 0,
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
      debugPrint('[Customer] Firebase fetch error: $e');
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

        debugPrint('[Customer] Firestore stream: ${snapshot.docs.length} docs (${snapshot.docChanges.length} changes)');

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
            'currentPendingAmount': data['currentPendingAmount'] ?? data['pendingBalance'] ?? 0,
            'totalPurchases': data['totalPurchaseAmount'] ?? data['totalPurchases'] ?? 0,
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

  // ━━━ SEARCH & SORT ━━━

  void _onSearchChanged() {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      if (mounted) setState(() => _applyFilter());
    });
  }

  void _applyFilter() {
    final query = _searchController.text.toLowerCase().trim();
    if (query.isEmpty) {
      _filteredCustomers = List.from(_customers);
    } else {
      _filteredCustomers = _customers.where((c) {
        final firstName = (c['firstName'] ?? '').toString().toLowerCase();
        final lastName = (c['lastName'] ?? '').toString().toLowerCase();
        final contact = (c['contact'] ?? '').toString().toLowerCase();
        final address = (c['address'] ?? '').toString().toLowerCase();
        return firstName.contains(query) ||
            lastName.contains(query) ||
            contact.contains(query) ||
            address.contains(query);
      }).toList();
    }
    _applySorting();
  }

  void _applySorting() {
    _filteredCustomers.sort((a, b) {
      final nameA = '${a['firstName'] ?? ''} ${a['lastName'] ?? ''}'
          .trim()
          .toLowerCase();
      final nameB = '${b['firstName'] ?? ''} ${b['lastName'] ?? ''}'
          .trim()
          .toLowerCase();
      return _isSortAscending
          ? nameA.compareTo(nameB)
          : nameB.compareTo(nameA);
    });
  }

  void _toggleSort() {
    setState(() {
      _isSortAscending = !_isSortAscending;
      _applySorting();
    });
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
      final fullName =
          [firstName, middleName, lastName].where((s) => s.isNotEmpty).join(' ');
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
      debugPrint('[Customer] Save error: $e');
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
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          _localizations.deleteCustomer,
          style: const TextStyle(
            fontFamily: 'Literata',
            fontWeight: FontWeight.w700,
            color: Color(0xFF1B4D3E),
          ),
        ),
        content: Text(
          'Are you sure you want to delete ${customer['firstName'] ?? ''} ${customer['lastName'] ?? ''}?',
          style: const TextStyle(fontFamily: 'Literata'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              _localizations.cancel,
              style: const TextStyle(fontFamily: 'Literata', color: Colors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(
              _localizations.delete,
              style: const TextStyle(fontFamily: 'Literata', color: Colors.white),
            ),
          ),
        ],
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
      debugPrint('[Customer] Delete error: $e');
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
        builder: (_) =>
            CustomerDetailsPage(customerId: customer['id'] as String),
      ),
    ).then((_) {
      _isNavigatingAway = false;
      _fetchFromFirebase();
    });
  }

  // ━━━ SNACKBAR ━━━

  void _showSnackbar(String message, bool isError) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontFamily: 'Literata')),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  //  BUILD
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  @override
  Widget build(BuildContext context) {
    _sessionManager.resetSession();
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      // App Bar
      appBar: widget.isEmbedded
          ? null
          : PreferredSize(
              preferredSize: const Size.fromHeight(70),
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF1B4D3E), Color(0xFF0F3B2F)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF1B4D3E).withOpacity(0.2),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () {
                            _isNavigatingAway = true;
                            if (Navigator.of(context).canPop()) {
                              Navigator.of(context).pop();
                            }
                          },
                          child: Icon(
                            Icons.arrow_back_rounded,
                            color: Colors.white.withOpacity(0.9),
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
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
                ),
              ),
            ),

      // FAB
      floatingActionButton: Container(
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
      ),

      // Body
      body: _isLoading && _customers.isEmpty
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF1B4D3E)),
            )
          : Column(
              children: [
                _buildSearchBar(),
                Expanded(child: _buildCustomerList()),
              ],
            ),
    );
  }

  // ── Search Bar ──
  Widget _buildSearchBar() {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        widget.isEmbedded ? 12 : 16,
        16,
        8,
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!, width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                style: const TextStyle(
                  fontSize: 14,
                  fontFamily: 'Literata',
                  color: Color(0xFF1B4D3E),
                ),
                decoration: InputDecoration(
                  hintText: _localizations.searchCustomers,
                  hintStyle: TextStyle(
                    color: Colors.grey[400],
                    fontFamily: 'Literata',
                  ),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: Colors.grey[600],
                    size: 20,
                  ),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? GestureDetector(
                          onTap: () {
                            _searchController.clear();
                            setState(() => _applyFilter());
                          },
                          child: Icon(
                            Icons.close,
                            color: Colors.grey[600],
                            size: 18,
                          ),
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  isDense: true,
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!, width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _toggleSort,
                borderRadius: BorderRadius.circular(11),
                child: Center(
                  child: Icon(
                    _isSortAscending
                        ? Icons.arrow_upward_rounded
                        : Icons.arrow_downward_rounded,
                    color: const Color(0xFF1B4D3E),
                    size: 20,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Customer List / Empty State ──
  Widget _buildCustomerList() {
    if (_customers.isEmpty && !_isLoading) {
      return _buildEmptyState(
        icon: Icons.people_outline,
        title: _localizations.noCustomersYet,
        subtitle: _localizations.createFirstCustomer,
      );
    }
    if (_filteredCustomers.isEmpty) {
      return _buildEmptyState(
        icon: Icons.search_off,
        title: _localizations.noResultsFound,
        subtitle: _localizations.tryDifferentSearch,
      );
    }

    return RefreshIndicator(
      color: const Color(0xFF1B4D3E),
      onRefresh: _fetchFromFirebase,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: _filteredCustomers.length,
        itemBuilder: (_, index) {
          return RepaintBoundary(
            child: _buildCustomerCard(_filteredCustomers[index]),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: const Color(0xFF1B4D3E).withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(icon, size: 50,
                color: const Color(0xFF1B4D3E).withOpacity(0.3)),
          ),
          const SizedBox(height: 20),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
              fontFamily: 'Literata',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
              fontFamily: 'Literata',
            ),
          ),
        ],
      ),
    );
  }

  // ── Customer Card ──
  Widget _buildCustomerCard(Map<String, dynamic> customer) {
    final fullName =
        '${customer['firstName'] ?? ''} ${customer['lastName'] ?? ''}'.trim();
    final firstName = (customer['firstName'] ?? '').toString();
    final contact = (customer['contact'] ?? '').toString();
    final address = (customer['address'] ?? '').toString();
    final pendingAmount =
        (customer['currentPendingAmount'] as num?)?.toDouble() ?? 0.0;
    final isSynced = customer['isSynced'] as bool? ?? true;

    const accentColors = [
      Color(0xFF1B4D3E),
      Color(0xFF0F3B2F),
      Color(0xFF2C6F5E),
      Color(0xFF1A5E52),
    ];
    final accentColor =
        accentColors[((customer['id'] ?? '').hashCode.abs()) % 4];
    final initials = firstName.isNotEmpty ? firstName[0].toUpperCase() : 'C';

    return GestureDetector(
      onTap: () => _navigateToCustomerDetails(customer),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
            BoxShadow(
              color: accentColor.withOpacity(0.12),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Row: Avatar + Info + Menu
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Avatar
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [accentColor, accentColor.withOpacity(0.7)],
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
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Literata',
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Name + Contact + Badge
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                fullName.isNotEmpty ? fullName : '\u2014',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF1B4D3E),
                                  fontFamily: 'Literata',
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (!isSynced)
                              Padding(
                                padding: const EdgeInsets.only(left: 6),
                                child: Icon(
                                  Icons.cloud_off,
                                  size: 14,
                                  color: Colors.orange[600],
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(Icons.phone_outlined,
                                size: 13, color: Colors.grey[500]),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                contact.isNotEmpty ? contact : '\u2014',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[600],
                                  fontFamily: 'Literata',
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        if (pendingAmount > 0) ...[
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.red[50],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.account_balance_wallet_outlined,
                                    size: 12, color: Colors.red[700]),
                                const SizedBox(width: 4),
                                Text(
                                  '\u20B9${pendingAmount.toStringAsFixed(0)} pending',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.red[700],
                                    fontFamily: 'Literata',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  // Popup menu
                  PopupMenuButton(
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 8,
                    itemBuilder: (_) => [
                      PopupMenuItem(
                        child: Row(
                          children: [
                            Icon(Icons.account_balance_wallet_outlined,
                                color: accentColor, size: 18),
                            const SizedBox(width: 10),
                            Text(_localizations.viewBalance,
                                style: const TextStyle(
                                    fontFamily: 'Literata', fontSize: 14)),
                          ],
                        ),
                        onTap: () => Future.delayed(
                          const Duration(milliseconds: 100),
                          () => _navigateToCustomerDetails(customer),
                        ),
                      ),
                      PopupMenuItem(
                        child: Row(
                          children: [
                            Icon(Icons.edit_outlined,
                                color: accentColor, size: 18),
                            const SizedBox(width: 10),
                            Text(_localizations.edit,
                                style: const TextStyle(
                                    fontFamily: 'Literata', fontSize: 14)),
                          ],
                        ),
                        onTap: () => Future.delayed(
                          const Duration(milliseconds: 100),
                          () => _showEditCustomerSheet(customer),
                        ),
                      ),
                      PopupMenuItem(
                        child: Row(
                          children: [
                            const Icon(Icons.delete_outline,
                                color: Colors.red, size: 18),
                            const SizedBox(width: 10),
                            Text(_localizations.delete,
                                style: const TextStyle(
                                    color: Colors.red,
                                    fontFamily: 'Literata',
                                    fontSize: 14)),
                          ],
                        ),
                        onTap: () => _deleteCustomer(customer),
                      ),
                    ],
                    icon: Icon(Icons.more_vert, color: accentColor, size: 20),
                  ),
                ],
              ),
              // Address row
              if (address.isNotEmpty && address != 'N/A') ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.location_on_outlined,
                          size: 13, color: Colors.grey[600]),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          address,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[700],
                            fontFamily: 'Literata',
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ━━━ BOTTOM SHEETS ━━━

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
              if (label == _localizations.contactNumber &&
                  value.length != 10) {
                return 'Contact number must be exactly 10 digits';
              }
              return null;
            }
          : null,
    );
  }
}

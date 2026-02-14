import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import '../../../../core/services/session_manager.dart';
import '../../../../core/services/language_service.dart';
import '../../../../core/services/dashboard_refresh_service.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../data/datasources/customer_cache_datasource.dart';
import '../../offline/controllers/customer_offline_controller.dart';
import '../../data/services/customer_sync_service.dart';
import 'customer_details_page.dart';

class CustomerPage extends StatefulWidget {
  final bool isEmbedded;

  const CustomerPage({super.key, this.isEmbedded = false});

  @override
  State<CustomerPage> createState() => _CustomerPageState();
}

class _CustomerPageState extends State<CustomerPage> {
  final _firstNameController = TextEditingController();
  final _middleNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _contactController = TextEditingController();
  final _addressController = TextEditingController();
  final _filterController = TextEditingController();

  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isEditing = false;
  String? _editingCustomerId;
  List<Map<String, dynamic>> _customers = [];
  List<Map<String, dynamic>> _filteredCustomers = [];
  Timer? _filterDebounceTimer;
  bool _isSortAscending = true; // Track sort order

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

    // Listen for language changes
    LanguageService.instance.addListener(_onLanguageChanged);

    _checkUserAuthentication();
    _setupInitialData();
    _filterController.addListener(_filterCustomers);
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

  Future<void> _setupInitialData() async {
    // 1. Load from cache immediately for < 0.5s loading
    final cached = await _cacheDataSource.getCachedCustomers();
    if (cached != null && mounted) {
      // Filter out inactive/deleted from cache too
      final activeCached = cached.where((c) {
        final isActive = c['isActive'];
        return isActive != false;
      }).toList();
      setState(() {
        _customers = activeCached;
        _applyFilterImmediate();
      });
      print('[DEBUG] Loaded ${_customers.length} customers from cache');
    }

    // 2. Fetch from Firestore in background
    _loadCustomers();
  }

  /// Apply filter immediately without debounce - for programmatic use
  void _applyFilterImmediate() {
    final query = _filterController.text.toLowerCase();
    if (query.isEmpty) {
      _filteredCustomers = List.from(_customers);
    } else {
      _filteredCustomers = _customers.where((customer) {
        final firstName = (customer['firstName'] ?? '')
            .toString()
            .toLowerCase();
        final lastName = (customer['lastName'] ?? '')
            .toString()
            .toLowerCase();
        final contact = (customer['contact'] ?? '')
            .toString()
            .toLowerCase();

        return firstName.contains(query) ||
            lastName.contains(query) ||
            contact.contains(query);
      }).toList();
    }
    _applySorting();
    print('[DEBUG] Immediate filter: ${_filteredCustomers.length} of ${_customers.length}');
  }

  void _filterCustomers() {
    // Cancel previous timer
    _filterDebounceTimer?.cancel();

    // Debounce filter operations (300ms delay)
    _filterDebounceTimer = Timer(const Duration(milliseconds: 300), () {
      print(
        '[DEBUG] Filtering customers with query: ${_filterController.text}',
      );

      setState(() {
        _applyFilterImmediate();
      });
    });
  }

  void _applySorting() {
    _filteredCustomers.sort((a, b) {
      final nameA = '${a['firstName'] ?? ''} ${a['lastName'] ?? ''}'
          .trim()
          .toLowerCase();
      final nameB = '${b['firstName'] ?? ''} ${b['lastName'] ?? ''}'
          .trim()
          .toLowerCase();

      if (_isSortAscending) {
        return nameA.compareTo(nameB);
      } else {
        return nameB.compareTo(nameA);
      }
    });
  }

  void _toggleSort() {
    setState(() {
      _isSortAscending = !_isSortAscending;
      _applySorting();
    });
  }

  void _checkUserAuthentication() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    }
  }

  Future<void> _loadCustomers() async {
    try {
      // Only show loader if we have no cached data
      if (_customers.isEmpty) {
        setState(() => _isLoading = true);
      }

      print('[DEBUG] Loading customers from Firestore...');
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        print('[ERROR] No authenticated user - cannot load customers');
        setState(() => _isLoading = false);
        return;
      }

      print('[DEBUG] Fetching customers for user: ${currentUser.uid}');
      // Don't use orderBy to avoid composite index requirement
      // Sort in memory instead
      final snapshot = await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('customers')
          .get();

      print('[DEBUG] Loaded ${snapshot.docs.length} customers from Firestore');

      final freshCustomers = snapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data()})
          .where((doc) {
            // Filter out inactive/deleted customers
            final isActive = doc['isActive'];
            if (isActive == false) return false;
            return true;
          })
          .toList();
      
      // Sort by createdAt in memory (descending, newest first)
      freshCustomers.sort((a, b) {
        final aCreatedAt = a['createdAt'];
        final bCreatedAt = b['createdAt'];
        if (aCreatedAt == null && bCreatedAt == null) return 0;
        if (aCreatedAt == null) return 1;
        if (bCreatedAt == null) return -1;
        // Handle both Timestamp and String types
        DateTime aDate;
        DateTime bDate;
        if (aCreatedAt is Timestamp) {
          aDate = aCreatedAt.toDate();
        } else {
          aDate = DateTime.tryParse(aCreatedAt.toString()) ?? DateTime(2000);
        }
        if (bCreatedAt is Timestamp) {
          bDate = bCreatedAt.toDate();
        } else {
          bDate = DateTime.tryParse(bCreatedAt.toString()) ?? DateTime(2000);
        }
        return bDate.compareTo(aDate);
      });

      print('[DEBUG] After filtering active customers: ${freshCustomers.length}');

      if (mounted) {
        setState(() {
          _customers = freshCustomers;
          // Update filtered list directly instead of using debounced _filterCustomers
          _applyFilterImmediate();
          _isLoading = false;
        });

        // Save to cache for next time
        _cacheDataSource.saveCustomers(freshCustomers);
      }
    } catch (e) {
      print('[ERROR] Failed to load customers: $e');
      print('[ERROR] Error type: ${e.runtimeType}');

      if (e.toString().contains('permission-denied')) {
        print(
          '[ERROR] CRITICAL: Permission denied when reading customers - security rules issue',
        );
      }

      if (mounted) {
        setState(() => _isLoading = false);
      }

      if (mounted && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading customers: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _clearForm() {
    _firstNameController.clear();
    _middleNameController.clear();
    _lastNameController.clear();
    _contactController.clear();
    _addressController.clear();
    _editingCustomerId = null;
    _isEditing = false;
  }

  void _showAddCustomerBottomSheet() {
    print('[DEBUG] Opening add customer bottom sheet');
    _clearForm();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            ),
            child: _buildCustomerForm(),
          ),
        ),
      ),
    );
  }

  /// Navigate to customer details page to view transactions and pending balance
  void _navigateToCustomerDetails(Map<String, dynamic> customer) {
    print('[DEBUG] Navigating to customer details for: ${customer['id']}');
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            CustomerDetailsPage(customerId: customer['id'] as String),
      ),
    ).then((_) {
      // Refresh customer list when returning from details page
      _loadCustomers();
    });
  }

  void _showEditCustomerBottomSheet(Map<String, dynamic> customer) {
    print('[DEBUG] Opening edit customer bottom sheet for: ${customer['id']}');
    _editCustomer(customer);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            ),
            child: _buildCustomerForm(onClose: () => Navigator.pop(ctx)),
          ),
        ),
      ),
    );
  }

  Widget _buildCustomerForm({VoidCallback? onClose}) {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
          // First Name
          _buildInputField(
            label: _localizations.firstName,
            controller: _firstNameController,
            icon: Icons.person_outline,
            isRequired: true,
          ),
          const SizedBox(height: 16),
          // Middle Name
          _buildInputField(
            label: _localizations.middleName,
            controller: _middleNameController,
            icon: Icons.person_outline,
          ),
          const SizedBox(height: 16),
          // Last Name
          _buildInputField(
            label: _localizations.lastName,
            controller: _lastNameController,
            icon: Icons.person_outline,
            isRequired: true,
          ),
          const SizedBox(height: 16),
          // Contact Number
          _buildInputField(
            label: _localizations.contactNumber,
            controller: _contactController,
            icon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
            isRequired: true,
          ),
          const SizedBox(height: 16),
          // Address
          _buildInputField(
            label: _localizations.address,
            controller: _addressController,
            icon: Icons.location_on_outlined,
            maxLines: 3,
            isRequired: true,
          ),
          const SizedBox(height: 24),
          // Buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveCustomer,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1B4D3E),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
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
                    onPressed: _isLoading
                        ? null
                        : () {
                            _clearForm();
                            Navigator.pop(context);
                          },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
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
    );
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

  Future<void> _saveCustomer() async {
    print('[DEBUG] _saveCustomer() called - IsEditing: $_isEditing');
    if (!_formKey.currentState!.validate()) {
      print('[ERROR] Form validation failed');
      return;
    }

    setState(() => _isLoading = true);
    print('[DEBUG] Starting customer save operation (offline-first)');

    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        print('[ERROR] No authenticated user found');
        if (mounted && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('User not authenticated')),
          );
        }
        return;
      }

      // Build full name
      final firstName = _firstNameController.text.trim();
      final middleName = _middleNameController.text.trim();
      final lastName = _lastNameController.text.trim();
      final fullName = [firstName, middleName, lastName]
          .where((s) => s.isNotEmpty)
          .join(' ');
      final contact = _contactController.text.trim();
      final address = _addressController.text.trim();

      print('[DEBUG] Saving to Isar (offline-first): $fullName');

      // Get offline controller
      final offlineController = CustomerOfflineController.instance;

      if (_isEditing && _editingCustomerId != null) {
        // For editing, we need to find the local ID
        // Try to get by server ID first
        final existing = await offlineController.getCustomerByServerId(_editingCustomerId!);
        
        if (existing != null) {
          await offlineController.updateCustomer(
            id: existing.id,
            name: fullName,
            mobile: contact,
            address: address,
          );
          print('[DEBUG] Customer updated in Isar');
        } else {
          // Fallback to Firebase direct update if not in Isar
          print('[DEBUG] Customer not in Isar, updating Firebase directly');
          final customersCollection = _firestore
              .collection('users')
              .doc(currentUser.uid)
              .collection('customers');
          
          await customersCollection.doc(_editingCustomerId).update({
            'firstName': firstName,
            'middleName': middleName,
            'lastName': lastName,
            'contact': contact,
            'address': address,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }

        // Optimistic update UI
        final index = _customers.indexWhere((c) => c['id'] == _editingCustomerId);
        if (index != -1) {
          setState(() {
            _customers[index] = {
              ..._customers[index],
              'firstName': firstName,
              'middleName': middleName,
              'lastName': lastName,
              'contact': contact,
              'address': address,
            };
            _applyFilterImmediate();
          });
          _cacheDataSource.saveCustomers(_customers);
        }
        
        DashboardRefreshService.instance.notifyDataChanged(DataChangeType.customer);
        
        _clearForm();
        if (mounted && context.mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Customer updated successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        // Create new customer - save to Isar first (offline-first)
        print('[DEBUG] Creating new customer in Isar');
        
        final newCustomer = await offlineController.addCustomer(
          name: fullName,
          mobile: contact,
          address: address,
        );
        
        print('[DEBUG] Customer saved to Isar with ID: ${newCustomer.id}');

        // Optimistic add to UI
        final tempCustomerData = {
          'id': 'local_${newCustomer.id}',
          'localId': newCustomer.id,
          'firstName': firstName,
          'middleName': middleName,
          'lastName': lastName,
          'contact': contact,
          'address': address,
          'isSynced': false,
        };
        
        setState(() {
          _customers.insert(0, tempCustomerData);
          _applyFilterImmediate();
        });
        _cacheDataSource.saveCustomers(_customers);
        
        DashboardRefreshService.instance.notifyDataChanged(DataChangeType.customer);
        
        _clearForm();
        if (mounted && context.mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: const [
                  Icon(Icons.cloud_off, color: Colors.white, size: 18),
                  SizedBox(width: 8),
                  Text('Customer saved offline. Will sync when online.'),
                ],
              ),
              backgroundColor: Colors.green,
            ),
          );
        }

        // Trigger background sync (non-blocking)
        CustomerSyncService.instance.syncNow();
      }
    } catch (e) {
      print('[ERROR] Failed to save customer: $e');
      print('[ERROR] Error type: ${e.runtimeType}');

      if (mounted && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving customer: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
      print('[DEBUG] _saveCustomer() completed');
    }
  }

  Future<void> _deleteCustomer(String customerId) async {
    print('[DEBUG] Delete customer initiated for ID: $customerId');
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
        content: const Text(
          'Are you sure you want to delete this customer?',
          style: TextStyle(fontFamily: 'Literata'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              _localizations.cancel,
              style: const TextStyle(
                fontFamily: 'Literata',
                color: Colors.grey,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(
              _localizations.delete,
              style: const TextStyle(
                fontFamily: 'Literata',
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      print('[DEBUG] Delete cancelled by user');
      return;
    }

    try {
      print('[DEBUG] Attempting to delete customer: $customerId');
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        print('[ERROR] No authenticated user for delete operation');
        return;
      }

      print(
        '[DEBUG] Deleting from path: users/${currentUser.uid}/customers/$customerId',
      );

      // Optimistic delete
      setState(() {
        _customers.removeWhere((c) => c['id'] == customerId);
        _applyFilterImmediate();
      });
      _cacheDataSource.saveCustomers(_customers);

      await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('customers')
          .doc(customerId)
          .delete();

      print('[DEBUG] Customer deleted successfully');
      
      // Notify dashboard to refresh
      DashboardRefreshService.instance.notifyDataChanged(DataChangeType.customer);
      
      if (mounted && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Customer deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }

      _loadCustomers();
    } catch (e) {
      print('[ERROR] Failed to delete customer: $e');
      print('[ERROR] Error type: ${e.runtimeType}');

      if (e.toString().contains('permission-denied')) {
        print(
          '[ERROR] CRITICAL: Permission denied when deleting - security rules issue',
        );
      }

      if (mounted && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting customer: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    LanguageService.instance.removeListener(_onLanguageChanged);
    _filterDebounceTimer?.cancel();
    _firstNameController.dispose();
    _middleNameController.dispose();
    _lastNameController.dispose();
    _contactController.dispose();
    _addressController.dispose();
    _filterController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _sessionManager.resetSession(); // Reset session timer on user activity
    print('[DEBUG] CustomerPage build() called');
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1B4D3E), Color(0xFF2E7D32)],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1B4D3E).withOpacity(0.4),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
            BoxShadow(
              color: const Color(0xFF1B4D3E).withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          child: InkWell(
            onTap: () {
              print('[DEBUG] FAB pressed to add customer');
              _showAddCustomerBottomSheet();
            },
            borderRadius: BorderRadius.circular(20),
            splashColor: Colors.white.withOpacity(0.2),
            highlightColor: Colors.white.withOpacity(0.1),
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: const Icon(
                Icons.add_rounded,
                color: Colors.white,
                size: 28,
              ),
            ),
          ),
        ),
      ),
      body: _isLoading && _customers.isEmpty
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF1B4D3E)),
            )
          : _customers.isEmpty
          ? Center(
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
                    child: const Icon(
                      Icons.people_outline,
                      size: 50,
                      color: Color(0xFF1B4D3E),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    _localizations.noCustomersYet,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                      fontFamily: 'Literata',
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _localizations.createFirstCustomer,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                      fontFamily: 'Literata',
                    ),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                // Search bar outside navbar with sort button
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    16,
                    widget.isEmbedded ? 12 : 50,
                    16,
                    8,
                  ),
                  child: Row(
                    children: [
                      // Search field
                      Expanded(
                        child: SizedBox(
                          height: 44,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.grey[300]!,
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Center(
                              child: TextField(
                                controller: _filterController,
                                textAlignVertical: TextAlignVertical.center,
                                style: const TextStyle(
                                  color: Colors.black87,
                                  fontFamily: 'Literata',
                                  fontSize: 14,
                                  height: 1,
                                ),
                                decoration: InputDecoration(
                                  hintText: _localizations.searchCustomers,
                                  hintStyle: TextStyle(
                                    color: Colors.grey[500],
                                    fontFamily: 'Literata',
                                    fontSize: 14,
                                  ),
                                  prefixIcon: Icon(
                                    Icons.search_rounded,
                                    color: Colors.grey[600],
                                    size: 20,
                                  ),
                                  suffixIcon: _filterController.text.isNotEmpty
                                      ? GestureDetector(
                                          onTap: () {
                                            _filterController.clear();
                                            _filterCustomers();
                                          },
                                          child: Icon(
                                            Icons.close,
                                            color: Colors.grey[600],
                                            size: 20,
                                          ),
                                        )
                                      : null,
                                  border: InputBorder.none,
                                  isDense: true,
                                  contentPadding: const EdgeInsets.fromLTRB(
                                    0,
                                    0,
                                    12,
                                    0,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Sort button
                      GestureDetector(
                        onTap: _toggleSort,
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.grey[300]!,
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
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
                    ],
                  ),
                ),
                // Customer list
                Expanded(
                  child: _filteredCustomers.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.search_off,
                                size: 48,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                _localizations.noResultsFound,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey[600],
                                  fontFamily: 'Literata',
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _localizations.tryDifferentSearch,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[500],
                                  fontFamily: 'Literata',
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filteredCustomers.length,
                          itemBuilder: (context, index) {
                            final customer = _filteredCustomers[index];
                            return RepaintBoundary(
                              child: _buildCustomerCard(customer),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    bool isRequired = false,
  }) {
    try {
      print('[DEBUG] Building input field for label: $label');
      return TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        maxLength: (label == _localizations.contactNumber) ? 10 : null,
        decoration: InputDecoration(
          labelText: isRequired ? '$label *' : label,
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
        ),
        validator: isRequired
            ? (value) {
                if (value == null || value.isEmpty) {
                  return '$label ${_localizations.isRequired}';
                }
                if (label == _localizations.contactNumber &&
                    value.isNotEmpty &&
                    value.length != 10) {
                  return 'Contact number must be exactly 10 digits';
                }
                return null;
              }
            : null,
      );
    } catch (e) {
      print('[ERROR] Error building input field for $label: $e');
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.red[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red[300]!),
        ),
        child: Text(
          'Error rendering field: $e',
          style: TextStyle(color: Colors.red[700], fontSize: 12),
        ),
      );
    }
  }

  Widget _buildCustomerCard(Map<String, dynamic> customer) {
    try {
      print(
        '[DEBUG] Building customer card for customer ID: ${customer['id']}',
      );
      final fullName =
          '${customer['firstName']} ${customer['middleName']} ${customer['lastName']}'
              .trim();
      final firstName = customer['firstName'] ?? '';
      final contact = customer['contact'] ?? 'N/A';
      final address = customer['address'] ?? 'N/A';

      // Use customer ID hash instead of indexOf for better performance
      const accentColors = [
        Color(0xFF1B4D3E),
        Color(0xFF0F3B2F),
        Color(0xFF2C6F5E),
        Color(0xFF1A5E52),
      ];
      final accentColor =
          accentColors[(customer['id'].hashCode.abs()) % accentColors.length];

      // Get initials for avatar
      final initials =
          '${firstName.isNotEmpty ? firstName[0].toUpperCase() : 'C'}';

      return GestureDetector(
        onTap: () => _navigateToCustomerDetails(customer),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Container(
            margin: const EdgeInsets.only(bottom: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                // Subtle bottom shadow for depth
                BoxShadow(
                  color: accentColor.withOpacity(0.12),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
                // Subtle top shadow for elevation
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                // Card content
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
                  child: Column(
                    children: [
                      // Avatar + Name + Actions row
                      Row(
                        children: [
                          // Circular avatar with initials
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  accentColor,
                                  accentColor.withOpacity(0.7),
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
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  fontFamily: 'Literata',
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Name and contact
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  fullName,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    fontFamily: 'Literata',
                                    color: Color(0xFF1B4D3E),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.phone_outlined,
                                      size: 13,
                                      color: Colors.grey[500],
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        contact,
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.grey[600],
                                          fontFamily: 'Literata',
                                          height: 1.2,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Action buttons in compact layout
                          PopupMenuButton(
                            color: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 6,
                            constraints: const BoxConstraints(minWidth: 160),
                            itemBuilder: (context) => [
                              PopupMenuItem(
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.account_balance_wallet_outlined,
                                      color: accentColor,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      _localizations.viewBalance,
                                      style: const TextStyle(
                                        fontFamily: 'Literata',
                                        fontSize: 14,
                                      ),
                                    ),
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
                                    Icon(
                                      Icons.edit_outlined,
                                      color: accentColor,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      _localizations.edit,
                                      style: const TextStyle(
                                        fontFamily: 'Literata',
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                                onTap: () => Future.delayed(
                                  const Duration(milliseconds: 100),
                                  () => _showEditCustomerBottomSheet(customer),
                                ),
                              ),
                              PopupMenuItem(
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.delete_outline,
                                      color: Colors.red,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      _localizations.delete,
                                      style: const TextStyle(
                                        color: Colors.red,
                                        fontFamily: 'Literata',
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                                onTap: () => _deleteCustomer(customer['id']),
                              ),
                            ],
                            icon: Icon(
                              Icons.more_vert_rounded,
                              color: Colors.grey[600],
                              size: 20,
                            ),
                          ),
                        ],
                      ),
                      // Address row - only if present
                      if (address != 'N/A') ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.fromLTRB(0, 10, 0, 10),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.location_on_rounded,
                                  size: 14,
                                  color: accentColor.withOpacity(0.7),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    address,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[700],
                                      fontFamily: 'Literata',
                                      height: 1.3,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } catch (e) {
      print('[ERROR] Error building customer card: $e');
      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.red[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red[300]!),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Error rendering customer card',
              style: TextStyle(
                color: Colors.red[700],
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              e.toString(),
              style: TextStyle(color: Colors.red[600], fontSize: 12),
            ),
          ],
        ),
      );
    }
  }
}

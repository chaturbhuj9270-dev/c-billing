import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import '../../../../core/services/session_manager.dart';
import '../../data/datasources/customer_cache_datasource.dart';
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
  final _cacheDataSource = CustomerCacheDataSource();

  @override
  void initState() {
    super.initState();
    _firestore = FirebaseFirestore.instance;
    _sessionManager = SessionManager();
    _checkUserAuthentication();
    _setupInitialData();
    _filterController.addListener(_filterCustomers);
  }

  Future<void> _setupInitialData() async {
    // 1. Load from cache immediately for < 0.5s loading
    final cached = await _cacheDataSource.getCachedCustomers();
    if (cached != null && mounted) {
      setState(() {
        _customers = cached;
        _filteredCustomers = List.from(_customers);
        _applySorting();
      });
      print('[DEBUG] Loaded ${_customers.length} customers from cache');
    }

    // 2. Fetch from Firestore in background
    _loadCustomers();
  }

  void _filterCustomers() {
    // Cancel previous timer
    _filterDebounceTimer?.cancel();

    // Debounce filter operations (300ms delay)
    _filterDebounceTimer = Timer(const Duration(milliseconds: 300), () {
      print(
        '[DEBUG] Filtering customers with query: ${_filterController.text}',
      );
      final query = _filterController.text.toLowerCase();

      setState(() {
        if (query.isEmpty) {
          _filteredCustomers = _customers;
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

        // Apply sorting
        _applySorting();
      });
      print(
        '[DEBUG] Filtered results: ${_filteredCustomers.length} of ${_customers.length}',
      );
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
      final snapshot = await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('customers')
          .orderBy('createdAt', descending: true)
          .get();

      print('[DEBUG] Loaded ${snapshot.docs.length} customers from Firestore');

      final freshCustomers = snapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data()})
          .toList();

      if (mounted) {
        setState(() {
          _customers = freshCustomers;
          _filterCustomers(); // This handles _filteredCustomers and sorting
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
                _isEditing ? 'Edit Customer' : 'Add New Customer',
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
            label: 'First Name',
            controller: _firstNameController,
            icon: Icons.person_outline,
            isRequired: true,
          ),
          const SizedBox(height: 16),
          // Middle Name
          _buildInputField(
            label: 'Middle Name',
            controller: _middleNameController,
            icon: Icons.person_outline,
          ),
          const SizedBox(height: 16),
          // Last Name
          _buildInputField(
            label: 'Last Name',
            controller: _lastNameController,
            icon: Icons.person_outline,
            isRequired: true,
          ),
          const SizedBox(height: 16),
          // Contact Number
          _buildInputField(
            label: 'Contact Number',
            controller: _contactController,
            icon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
            isRequired: true,
          ),
          const SizedBox(height: 16),
          // Address
          _buildInputField(
            label: 'Address',
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
                          _isEditing ? 'Update' : 'Add Customer',
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
                    child: const Text(
                      'Cancel',
                      style: TextStyle(
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
    print('[DEBUG] Starting customer save operation');

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

      print('[DEBUG] Authenticated user ID: ${currentUser.uid}');
      print('[DEBUG] Building customer data...');

      final customersCollection = _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('customers');

      print('[DEBUG] Firestore path: users/${currentUser.uid}/customers');

      final customerData = {
        'firstName': _firstNameController.text.trim(),
        'middleName': _middleNameController.text.trim(),
        'lastName': _lastNameController.text.trim(),
        'contact': _contactController.text.trim(),
        'address': _addressController.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      print('[DEBUG] Customer data: $customerData');

      if (_isEditing && _editingCustomerId != null) {
        // Optimistic update
        final index = _customers.indexWhere(
          (c) => c['id'] == _editingCustomerId,
        );
        if (index != -1) {
          setState(() {
            _customers[index] = {..._customers[index], ...customerData};
            _filterCustomers();
          });
          _cacheDataSource.saveCustomers(_customers);
        }

        // Update existing customer
        print('[DEBUG] Updating existing customer: $_editingCustomerId');
        await customersCollection.doc(_editingCustomerId).update(customerData);
        print('[DEBUG] Customer updated successfully');
        _clearForm();
        _loadCustomers();
        if (mounted && context.mounted) {
          Navigator.pop(context);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Customer updated successfully'),
                backgroundColor: Colors.green,
              ),
            );
          }
        }
      } else {
        // Create new customer
        print('[DEBUG] Creating new customer');
        customerData['createdAt'] = FieldValue.serverTimestamp();

        // Optimistic add
        final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
        final newCustomer = {...customerData, 'id': tempId};
        setState(() {
          _customers.insert(0, newCustomer);
          _filterCustomers();
        });
        _cacheDataSource.saveCustomers(_customers);

        final docRef = await customersCollection.add(customerData);
        print('[DEBUG] Customer added successfully with ID: ${docRef.id}');
        _clearForm();
        _loadCustomers();
        if (mounted && context.mounted) {
          Navigator.pop(context);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Customer added successfully'),
                backgroundColor: Colors.green,
              ),
            );
          }
        }
      }
    } catch (e) {
      print('[ERROR] Failed to save customer: $e');
      print('[ERROR] Error type: ${e.runtimeType}');
      print('[ERROR] Full error: $e');

      String errorMsg = 'Error saving customer: ${e.toString()}';

      // Handle permission denied error
      if (e.toString().contains('permission-denied')) {
        errorMsg =
            'Permission Denied - Firestore security rules are blocking write access.\n\nYou need to:\n1. Go to Firebase Console\n2. Go to Firestore Database\n3. Go to Rules tab\n4. Update rules to allow authenticated users to read/write their own data\n\nSee console logs for detailed error.';
        print(
          '[ERROR] CRITICAL: Firestore permission denied - security rules issue',
        );
      }

      if (mounted && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMsg),
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
        title: const Text(
          'Delete Customer',
          style: TextStyle(
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
            child: const Text(
              'Cancel',
              style: TextStyle(fontFamily: 'Literata', color: Colors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text(
              'Delete',
              style: TextStyle(fontFamily: 'Literata', color: Colors.white),
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
        _filterCustomers();
      });
      _cacheDataSource.saveCustomers(_customers);

      await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('customers')
          .doc(customerId)
          .delete();

      print('[DEBUG] Customer deleted successfully');
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
      body: _filteredCustomers.isEmpty
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
                    child: Icon(
                      Icons.people_outline,
                      size: 50,
                      color: const Color(0xFF1B4D3E),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    _filterController.text.isEmpty
                        ? 'No customers yet'
                        : 'No results found',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                      fontFamily: 'Literata',
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _filterController.text.isEmpty
                        ? 'Create your first customer to get started'
                        : 'Try a different search',
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
                                  hintText: 'Search customers...',
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
                  child: ListView.builder(
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
                  return '$label is required';
                }
                if (label == 'Contact Number' && value.length < 10) {
                  return 'Enter a valid phone number';
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
                                    const Text(
                                      'View Balance',
                                      style: TextStyle(
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
                                    const Text(
                                      'Edit',
                                      style: TextStyle(
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
                                    const Text(
                                      'Delete',
                                      style: TextStyle(
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

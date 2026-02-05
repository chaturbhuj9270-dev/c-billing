import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/services/session_manager.dart';
import '../../data/datasources/supplier_cache_datasource.dart';

class SupplierPage extends StatefulWidget {
  const SupplierPage({super.key});

  @override
  State<SupplierPage> createState() => _SupplierPageState();
}

class _SupplierPageState extends State<SupplierPage> {
  final _firstNameController = TextEditingController();
  final _middleNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _contactController = TextEditingController();
  final _addressController = TextEditingController();
  final _searchController = TextEditingController();

  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isEditing = false;
  String? _editingSupplierId;
  List<Map<String, dynamic>> _suppliers = [];
  List<Map<String, dynamic>> _filteredSuppliers = [];
  final _cacheDataSource = SupplierCacheDataSource();
  
  // Search, sort, and filter variables
  String _sortBy = 'name'; // 'name', 'date', 'contact'
  bool _isSortAscending = true; // Toggle for ascending/descending
  Timer? _filterDebounceTimer; // Debounce timer for search
  bool _isNavigatingAway = false; // Flag to prevent setState after navigation

  final _auth = FirebaseAuth.instance;
  late final FirebaseFirestore _firestore;
  late SessionManager _sessionManager;

  @override
  void initState() {
    super.initState();
    _firestore = FirebaseFirestore.instance;
    _sessionManager = SessionManager();
    _checkUserAuthentication();
    _setupInitialData();
    _searchController.addListener(_filterAndSearchSuppliers);
  }

  @override
  void dispose() {
    _isNavigatingAway = true; // Signal async operations to stop
    _filterDebounceTimer?.cancel();
    _searchController.dispose();
    _firstNameController.dispose();
    _middleNameController.dispose();
    _lastNameController.dispose();
    _contactController.dispose();
    _addressController.dispose();
    super.dispose();
  }


  void _applySorting() {
    // Sort by selected option
    switch (_sortBy) {
      case 'name':
        _filteredSuppliers.sort((a, b) {
          final aName = '${a['firstName'] ?? ''} ${a['lastName'] ?? ''}'.trim().toLowerCase();
          final bName = '${b['firstName'] ?? ''} ${b['lastName'] ?? ''}'.trim().toLowerCase();
          if (_isSortAscending) {
            return aName.compareTo(bName);
          } else {
            return bName.compareTo(aName);
          }
        });
        break;
      case 'date':
        _filteredSuppliers.sort((a, b) {
          final aDate = a['createdAt'] as Timestamp? ?? Timestamp.now();
          final bDate = b['createdAt'] as Timestamp? ?? Timestamp.now();
          if (_isSortAscending) {
            return aDate.compareTo(bDate);
          } else {
            return bDate.compareTo(aDate);
          }
        });
        break;
      case 'contact':
        _filteredSuppliers.sort((a, b) {
          final aContact = (a['contact'] ?? '').toString();
          final bContact = (b['contact'] ?? '').toString();
          if (_isSortAscending) {
            return aContact.compareTo(bContact);
          } else {
            return bContact.compareTo(aContact);
          }
        });
        break;
    }
  }

  void _toggleSort() {
    setState(() {
      _isSortAscending = !_isSortAscending;
      _applySorting();
    });
  }

  void _filterAndSearchSuppliers() {
    _filterDebounceTimer?.cancel();
    _filterDebounceTimer = Timer(const Duration(milliseconds: 300), () {
      setState(() {
        final query = _searchController.text.toLowerCase();
        if (query.isEmpty) {
          _filteredSuppliers = List.from(_suppliers);
        } else {
          _filteredSuppliers = _suppliers.where((supplier) {
            final firstName = (supplier['firstName'] ?? '').toString().toLowerCase();
            final lastName = (supplier['lastName'] ?? '').toString().toLowerCase();
            final contact = (supplier['contact'] ?? '').toString().toLowerCase();
            final address = (supplier['address'] ?? '').toString().toLowerCase();
            return firstName.contains(query) ||
                lastName.contains(query) ||
                contact.contains(query) ||
                address.contains(query);
          }).toList();
        }
        _applySorting();
      });
    });
  }

  void _filterAndSortSuppliers() {
    setState(() {
      _filteredSuppliers = List.from(_suppliers);
      _applySorting();
    });
  }

  void _checkUserAuthentication() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    }
  }

  Future<void> _setupInitialData() async {
    // 1. Load from cache immediately for < 0.5s loading
    final cached = await _cacheDataSource.getCachedSuppliers();
    if (cached != null && mounted) {
      setState(() {
        _suppliers = cached;
        _filterAndSortSuppliers();
      });
      print('[DEBUG] Loaded ${_suppliers.length} suppliers from cache');
    }

    // 2. Fetch from Firestore in background
    _loadSuppliers();
  }

  Future<void> _loadSuppliers() async {
    try {
      // Only show loader if we have no cached data
      if (_suppliers.isEmpty) {
        setState(() => _isLoading = true);
      }
      
      print('[DEBUG] Loading suppliers from Firestore...');
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        print('[ERROR] No authenticated user - cannot load suppliers');
        setState(() => _isLoading = false);
        return;
      }

      final snapshot = await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('suppliers')
          .orderBy('createdAt', descending: true)
          .get();

      if (!mounted || _isNavigatingAway) return;

      final freshSuppliers = snapshot.docs
          .map((doc) => {
                'id': doc.id,
                ...doc.data(),
              })
          .toList();

      setState(() {
        _suppliers = freshSuppliers;
        _filterAndSortSuppliers();
        _isLoading = false;
      });
      
      // Save to cache for next time
      _cacheDataSource.saveSuppliers(freshSuppliers);
    } catch (e) {
      print('[ERROR] Failed to load suppliers: $e');
      
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading suppliers: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _clearForm() {
    try {
      setState(() {
        _firstNameController.clear();
        _middleNameController.clear();
        _lastNameController.clear();
        _contactController.clear();
        _addressController.clear();
        _editingSupplierId = null;
        _isEditing = false;
      });
    } catch (e) {
      print('[ERROR] Error clearing form: $e');
    }
  }

  void _showAddSupplierBottomSheet() {
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
            child: _buildSupplierForm(),
          ),
        ),
      ),
    );
  }

  void _showEditSupplierBottomSheet(Map<String, dynamic> supplier) {
    _editSupplier(supplier);
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
            child: _buildSupplierForm(
              onClose: () => Navigator.pop(ctx),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSupplierForm({VoidCallback? onClose}) {
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
                _isEditing ? 'Edit Supplier' : 'Add New Supplier',
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
                  onPressed: _isLoading ? null : _saveSupplier,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1B4D3E),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
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
                          _isEditing ? 'Update' : 'Add Supplier',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),
              if (_isEditing) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isLoading ? null : _deleteSupplier,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Delete',
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
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

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    bool isRequired = false,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
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
              const Text(
                ' *',
                style: TextStyle(color: Colors.red),
              ),
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          minLines: maxLines,
          decoration: InputDecoration(
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
              borderSide: const BorderSide(
                color: Color(0xFF1B4D3E),
                width: 2,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
            filled: true,
            fillColor: Colors.grey[50],
          ),
          validator: (value) {
            if (isRequired && (value == null || value.isEmpty)) {
              return '$label is required';
            }
            return null;
          },
        ),
      ],
    );
  }

  void _editSupplier(Map<String, dynamic> supplier) {
    try {
      _firstNameController.text = supplier['firstName'] ?? '';
      _middleNameController.text = supplier['middleName'] ?? '';
      _lastNameController.text = supplier['lastName'] ?? '';
      _contactController.text = supplier['contact'] ?? '';
      _addressController.text = supplier['address'] ?? '';
    } catch (e) {
      print('[ERROR] Error setting controller text: $e');
    }
    _editingSupplierId = supplier['id'];
    _isEditing = true;
  }

  Future<void> _saveSupplier() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      final suppliersRef = _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('suppliers');

      if (_isEditing) {
        final updatedData = {
          'firstName': _firstNameController.text,
          'middleName': _middleNameController.text,
          'lastName': _lastNameController.text,
          'contact': _contactController.text,
          'address': _addressController.text,
          'updatedAt': FieldValue.serverTimestamp(),
        };

        // Optimistic update
        final index = _suppliers.indexWhere((s) => s['id'] == _editingSupplierId);
        if (index != -1) {
          setState(() {
            _suppliers[index] = {
              ..._suppliers[index],
              ...updatedData,
            };
            _filterAndSortSuppliers();
          });
          _cacheDataSource.saveSuppliers(_suppliers);
        }

        await suppliersRef.doc(_editingSupplierId).update(updatedData);
        print('[DEBUG] Supplier updated: $_editingSupplierId');
      } else {
        final newData = {
          'firstName': _firstNameController.text,
          'middleName': _middleNameController.text,
          'lastName': _lastNameController.text,
          'contact': _contactController.text,
          'address': _addressController.text,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        };

        // Optimistic add
        final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
        final newSupplier = {
          'id': tempId,
          ...newData,
        };
        setState(() {
          _suppliers.insert(0, newSupplier);
          _filterAndSortSuppliers();
        });
        _cacheDataSource.saveSuppliers(_suppliers);

        await suppliersRef.add(newData);
        print('[DEBUG] New supplier added');
      }

      if (mounted && context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEditing ? 'Supplier updated successfully' : 'Supplier added successfully',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }

      if (mounted) {
        _clearForm();
      }
    } catch (e) {
      print('[ERROR] Error saving supplier: $e');
      // Reload on error to revert optimistic update
      _loadSuppliers();
      if (mounted && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _deleteSupplier() async {
    setState(() => _isLoading = true);

    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Optimistic delete
      setState(() {
        _suppliers.removeWhere((s) => s['id'] == _editingSupplierId);
        _filterAndSortSuppliers();
      });
      _cacheDataSource.saveSuppliers(_suppliers);

      await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('suppliers')
          .doc(_editingSupplierId)
          .delete();

      if (mounted && context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Supplier deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }

      if (mounted) {
        _clearForm();
      }
    } catch (e) {
      print('[ERROR] Error deleting supplier: $e');
      // Reload on error to revert optimistic delete
      _loadSuppliers();
      if (mounted && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    _sessionManager.resetSession(); // Reset session timer on user activity
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70),
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1B4D3E), Color(0xFF0F3B2F)],
            ),
            boxShadow: [
              BoxShadow(color: const Color(0xFF1B4D3E).withOpacity(0.2), blurRadius: 12, offset: const Offset(0, 4)),
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
                      // Close any open bottom sheets first
                      if (Navigator.of(context).canPop()) {
                        Navigator.of(context).pop();
                      }
                    },
                    child: Icon(Icons.arrow_back_rounded, color: Colors.white.withOpacity(0.9), size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'My Suppliers',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'Literata',
                            height: 1.2,
                          ),
                        ),
                        Text(
                          'Manage your vendors',
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
          onPressed: _showAddSupplierBottomSheet,
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
      body: Column(
        children: [
          // Search bar + Sort + Filter buttons
          Padding(
            padding: const EdgeInsets.all(16),
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
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            style: const TextStyle(
                              fontSize: 14,
                              fontFamily: 'Literata',
                              color: Color(0xFF1B4D3E),
                            ),
                            decoration: InputDecoration(
                              hintText: 'Search suppliers...',
                              hintStyle: TextStyle(
                                color: Colors.grey[400],
                                fontFamily: 'Literata',
                              ),
                              prefixIcon: Icon(Icons.search_rounded, color: Colors.grey[600], size: 20),
                              suffixIcon: _searchController.text.isNotEmpty
                                  ? GestureDetector(
                                      onTap: () {
                                        _searchController.clear();
                                      },
                                      child: Icon(Icons.close, color: Colors.grey[600], size: 18),
                                    )
                                  : null,
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(vertical: 12),
                              isDense: true,
                            ),
                            onChanged: (_) {
                              setState(() {});
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Sort button
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
                          _isSortAscending ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                          color: const Color(0xFF1B4D3E),
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
            ),
          ),
          // List or empty state
          Expanded(
            child: _filteredSuppliers.isEmpty
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
                          child: Icon(Icons.business_outlined, size: 50, color: const Color(0xFF1B4D3E).withOpacity(0.3)),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          _suppliers.isEmpty ? 'No suppliers yet' : 'No results found',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.grey[700], fontFamily: 'Literata'),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _suppliers.isEmpty ? 'Create your first supplier to get started' : 'Try a different search',
                          style: TextStyle(fontSize: 14, color: Colors.grey[500], fontFamily: 'Literata'),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: _filteredSuppliers.length,
                    itemBuilder: (context, index) {
                      final supplier = _filteredSuppliers[index];
                      return RepaintBoundary(
                        child: _buildSupplierCard(supplier),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSupplierCard(Map<String, dynamic> supplier) {
    final fullName = '${supplier['firstName'] ?? ''} ${supplier['lastName'] ?? ''}'.trim();
    final firstName = supplier['firstName'] ?? '';
    final contact = supplier['contact'] ?? 'N/A';
    final address = supplier['address'] ?? 'N/A';
    final supplierId = supplier['id'] ?? '';

    final accentColors = [const Color(0xFF1B4D3E), const Color(0xFF0F3B2F), const Color(0xFF2C6F5E), const Color(0xFF1A5E52)];
    final accentColor = accentColors[(supplierId.hashCode.abs()) % 4];
    
    // Get initials for avatar
    final initials = firstName.isNotEmpty ? firstName[0].toUpperCase() : 'S';

    return GestureDetector(
      onTap: () => _showEditSupplierBottomSheet(supplier),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
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
                color: Colors.black.withOpacity(0.12),
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
                // Top Row: Avatar + Details + Menu
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Circular gradient avatar
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
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            fullName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1B4D3E),
                              fontFamily: 'Literata',
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(Icons.phone_outlined, size: 13, color: Colors.grey[600]),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  contact,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[700],
                                    fontFamily: 'Literata',
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
                    PopupMenuButton(
                      color: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 8,
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          child: Row(
                            children: [Icon(Icons.edit_outlined, color: accentColor, size: 18), const SizedBox(width: 8), const Text('Edit')],
                          ),
                          onTap: () => Future.delayed(const Duration(milliseconds: 100), () => _showEditSupplierBottomSheet(supplier)),
                        ),
                        PopupMenuItem(
                          child: Row(
                            children: [const Icon(Icons.delete_outline, color: Colors.red, size: 18), const SizedBox(width: 8), const Text('Delete', style: TextStyle(color: Colors.red))],
                          ),
                          onTap: () => _deleteSupplier(),
                        ),
                      ],
                      icon: Icon(Icons.more_vert, color: accentColor, size: 20),
                    ),
                  ],
                ),
                // Address section - only show if address exists
                if (address != 'N/A') ...[
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
                        Icon(Icons.location_on_outlined, size: 13, color: Colors.grey[600]),
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
      ),
    );
  }
}

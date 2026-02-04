import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/services/session_manager.dart';

class CompanyPage extends StatefulWidget {
  const CompanyPage({super.key});

  @override
  State<CompanyPage> createState() => _CompanyPageState();
}

class _CompanyPageState extends State<CompanyPage> {
  final _companyNameController = TextEditingController();
  final _supplierSearchController = TextEditingController();
  final _contactController = TextEditingController();
  final _addressController = TextEditingController();
  final _searchController = TextEditingController();

  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isEditing = false;
  String? _editingCompanyId;
  String? _selectedSupplierId;
  String? _selectedSupplierName;
  List<Map<String, dynamic>> _companies = [];
  List<Map<String, dynamic>> _filteredCompanies = [];
  List<Map<String, dynamic>> _suppliers = [];
  List<Map<String, dynamic>> _filteredSuppliers = [];
  bool _isSortAscending = true;
  Timer? _filterDebounceTimer;
  bool _isNavigatingAway = false;

  final _auth = FirebaseAuth.instance;
  late final FirebaseFirestore _firestore;
  late SessionManager _sessionManager;

  @override
  void initState() {
    super.initState();
    _firestore = FirebaseFirestore.instance;
    _sessionManager = SessionManager();
    _checkUserAuthentication();
    _loadSuppliers();
    _loadCompanies();
    _supplierSearchController.addListener(_filterSuppliers);
    _searchController.addListener(_filterAndSearchCompanies);
  }

  void _toggleSort() {
    setState(() {
      _isSortAscending = !_isSortAscending;
      _applyCompanySorting();
    });
  }

  void _filterAndSearchCompanies() {
    _filterDebounceTimer?.cancel();
    _filterDebounceTimer = Timer(const Duration(milliseconds: 300), () {
      setState(() {
        final query = _searchController.text.toLowerCase();
        if (query.isEmpty) {
          _filteredCompanies = List.from(_companies);
        } else {
          _filteredCompanies = _companies.where((company) {
            final name = (company['companyName'] ?? '').toString().toLowerCase();
            final contact = (company['contact'] ?? '').toString().toLowerCase();
            final contactPerson = (company['contactPerson'] ?? '').toString().toLowerCase();
            final address = (company['address'] ?? '').toString().toLowerCase();
            return name.contains(query) ||
                contact.contains(query) ||
                contactPerson.contains(query) ||
                address.contains(query);
          }).toList();
        }
        _applyCompanySorting();
      });
    });
  }

  void _applyCompanySorting() {
    _filteredCompanies.sort((a, b) {
      final nameA = (a['companyName'] ?? '').toString().toLowerCase();
      final nameB = (b['companyName'] ?? '').toString().toLowerCase();
      if (_isSortAscending) {
        return nameA.compareTo(nameB);
      } else {
        return nameB.compareTo(nameA);
      }
    });
  }

  void _filterAndSortCompanies() {
    setState(() {
      _filteredCompanies = List.from(_companies);
      _applyCompanySorting();
    });
  }

  void _filterSuppliers() {
    final query = _supplierSearchController.text.toLowerCase();
    
    setState(() {
      if (query.isEmpty) {
        _filteredSuppliers = _suppliers;
      } else {
        _filteredSuppliers = _suppliers.where((supplier) {
          final firstName = (supplier['firstName'] ?? '').toString().toLowerCase();
          final lastName = (supplier['lastName'] ?? '').toString().toLowerCase();
          final contact = (supplier['contact'] ?? '').toString().toLowerCase();
          final fullName = '$firstName $lastName'.trim().toLowerCase();
          
          return fullName.contains(query) || contact.contains(query);
        }).toList();
      }
    });
  }

  void _checkUserAuthentication() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    }
  }

  Future<void> _loadSuppliers() async {
    try {
      print('[DEBUG] Loading suppliers...');
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        print('[ERROR] No authenticated user - cannot load suppliers');
        return;
      }

      print('[DEBUG] Fetching suppliers for user: ${currentUser.uid}');
      final snapshot = await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('suppliers')
          .orderBy('firstName')
          .get();

      print('[DEBUG] Loaded ${snapshot.docs.length} suppliers');
      
      // Log each supplier
      for (var doc in snapshot.docs) {
        print('[DEBUG] Supplier: ${doc.data()}');
      }

      if (mounted) {
        setState(() {
          _suppliers = snapshot.docs
              .map((doc) => {
                    'id': doc.id,
                    ...doc.data(),
                  })
              .toList();
          _filteredSuppliers = _suppliers;
          print('[DEBUG] Suppliers set in state: ${_suppliers.length}');
        });
      }
    } catch (e) {
      print('[ERROR] Failed to load suppliers: $e');
      print('[ERROR] Error type: ${e.runtimeType}');
      
      if (e.toString().contains('permission-denied')) {
        print('[ERROR] CRITICAL: Permission denied - check Firestore security rules');
      }
      
      if (mounted) {
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

  Future<void> _loadCompanies() async {
    try {
      print('[DEBUG] Loading companies...');
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        print('[ERROR] No authenticated user - cannot load companies');
        return;
      }

      print('[DEBUG] Fetching companies for user: ${currentUser.uid}');
      final snapshot = await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('companies')
          .orderBy('createdAt', descending: true)
          .get();

      print('[DEBUG] Loaded ${snapshot.docs.length} companies');
      if (mounted && !_isNavigatingAway) {
        setState(() {
          _companies = snapshot.docs
              .map((doc) => {
                    'id': doc.id,
                    ...doc.data(),
                  })
              .toList();
          _filterAndSortCompanies();
        });
      }
    } catch (e) {
      print('[ERROR] Failed to load companies: $e');
      print('[ERROR] Error type: ${e.runtimeType}');
      
      if (e.toString().contains('permission-denied')) {
        print('[ERROR] CRITICAL: Permission denied when reading companies - security rules issue');
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading companies: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _clearForm() {
    _companyNameController.clear();
    _supplierSearchController.clear();
    _contactController.clear();
    _addressController.clear();
    _selectedSupplierId = null;
    _selectedSupplierName = null;
    _editingCompanyId = null;
    _isEditing = false;
  }

  void _showAddCompanyBottomSheet() {
    print('[DEBUG] Opening add company bottom sheet');
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
            child: _buildCompanyForm(),
          ),
        ),
      ),
    );
  }

  void _showEditCompanyBottomSheet(Map<String, dynamic> company) {
    print('[DEBUG] Opening edit company bottom sheet for: ${company['id']}');
    _editCompany(company);
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
            child: _buildCompanyForm(),
          ),
        ),
      ),
    );
  }

  void _showSupplierBottomSheet() {
    print('[DEBUG] Opening supplier selection bottom sheet');
    _supplierSearchController.clear();
    setState(() => _filteredSuppliers = _suppliers);
    
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Select Contact Person',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1B4D3E),
                        fontFamily: 'Literata',
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: TextField(
                  controller: _supplierSearchController,
                  onChanged: (_) => _filterSuppliers(),
                  decoration: InputDecoration(
                    hintText: 'Search by name or contact...',
                    hintStyle: TextStyle(color: Colors.grey[400], fontFamily: 'Literata'),
                    prefixIcon: Icon(Icons.search, color: Colors.grey[600], size: 20),
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
                ),
              ),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 400),
                child: _suppliers.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.all(40),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.person_add_outlined, color: Colors.grey[400], size: 50),
                              const SizedBox(height: 16),
                              Text(
                                'No suppliers yet',
                                style: TextStyle(color: Colors.grey[600], fontFamily: 'Literata', fontWeight: FontWeight.w600, fontSize: 16),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Add suppliers from the Suppliers page first',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.grey[500], fontFamily: 'Literata', fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                      )
                    : _filteredSuppliers.isEmpty
                        ? Padding(
                            padding: const EdgeInsets.all(20),
                            child: Center(
                              child: Text(
                                'No suppliers found',
                                style: TextStyle(color: Colors.grey[600], fontFamily: 'Literata', fontSize: 14),
                              ),
                            ),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                            itemCount: _filteredSuppliers.length,
                            itemBuilder: (context, index) {
                              final supplier = _filteredSuppliers[index];
                              final fullName = '${supplier['firstName'] ?? ''} ${supplier['lastName'] ?? ''}'.trim();
                              final contact = supplier['contact'] ?? '';
                              final isSelected = _selectedSupplierId == supplier['id'];
                              
                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                decoration: BoxDecoration(
                                  color: isSelected ? const Color(0xFF1B4D3E).withOpacity(0.1) : Colors.grey[50],
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isSelected ? const Color(0xFF1B4D3E) : Colors.grey[300]!,
                                    width: isSelected ? 2 : 1,
                                  ),
                                ),
                                child: ListTile(
                                  leading: Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF1B4D3E).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(Icons.person, color: Color(0xFF1B4D3E), size: 22),
                                  ),
                                  title: Text(
                                    fullName,
                                    style: const TextStyle(
                                      fontFamily: 'Literata',
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF1B4D3E),
                                    ),
                                  ),
                                  subtitle: Text(
                                    contact,
                                    style: TextStyle(
                                      fontFamily: 'Literata',
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  trailing: isSelected
                                      ? const Icon(Icons.check_circle, color: Color(0xFF1B4D3E), size: 24)
                                      : const Icon(Icons.circle_outlined, color: Colors.grey, size: 24),
                                  onTap: () {
                                    print('[DEBUG] Selected supplier: $fullName (ID: ${supplier['id']})');
                                    setState(() {
                                      _selectedSupplierId = supplier['id'];
                                      _selectedSupplierName = fullName;
                                    });
                                    Navigator.pop(ctx);
                                  },
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

  Widget _buildCompanyForm() {
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
                _isEditing ? 'Edit Company' : 'Add New Company',
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
          // Company Name
          _buildInputField(
            label: 'Company Name',
            controller: _companyNameController,
            icon: Icons.business_outlined,
            isRequired: true,
          ),
          const SizedBox(height: 16),
          // Contact Person (Supplier Selection with Search)
          Text(
            'Contact Person (Supplier) *',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1B4D3E),
              fontFamily: 'Literata',
            ),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: _showSupplierBottomSheet,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!, width: 1.5),
              ),
              child: Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 12),
                    child: Icon(Icons.person_outlined, color: Colors.grey[600], size: 20),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                      child: Text(
                        _selectedSupplierName ?? 'Select a supplier...',
                        style: TextStyle(
                          color: _selectedSupplierName != null ? Colors.black87 : Colors.grey[500],
                          fontSize: 14,
                          fontFamily: 'Literata',
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: Icon(Icons.expand_more, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
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
          ),
          const SizedBox(height: 24),
          // Buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveCompany,
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
                          _isEditing ? 'Update' : 'Add Company',
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

  void _editCompany(Map<String, dynamic> company) {
    _companyNameController.text = company['companyName'] ?? '';
    _selectedSupplierId = company['contactPersonId'];
    _selectedSupplierName = company['contactPerson'] ?? '';
    _contactController.text = company['contact'] ?? '';
    _addressController.text = company['address'] ?? '';
    _editingCompanyId = company['id'];
    _isEditing = true;
  }

  Future<void> _saveCompany() async {
    print('[DEBUG] _saveCompany() called - IsEditing: $_isEditing');
    if (!_formKey.currentState!.validate()) {
      print('[ERROR] Form validation failed');
      return;
    }

    if (_selectedSupplierId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a contact person (supplier)'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    print('[DEBUG] Starting company save operation');

    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        print('[ERROR] No authenticated user found');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User not authenticated')),
        );
        return;
      }

      print('[DEBUG] Authenticated user ID: ${currentUser.uid}');
      print('[DEBUG] Building company data...');

      final companiesCollection = _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('companies');

      print('[DEBUG] Firestore path: users/${currentUser.uid}/companies');

      final companyData = {
        'companyName': _companyNameController.text.trim(),
        'contactPerson': _selectedSupplierName ?? '',
        'contactPersonId': _selectedSupplierId,
        'contact': _contactController.text.trim(),
        'address': _addressController.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      print('[DEBUG] Company data: $companyData');

      if (_isEditing && _editingCompanyId != null) {
        // Update existing company
        print('[DEBUG] Updating existing company: $_editingCompanyId');
        await companiesCollection.doc(_editingCompanyId).update(companyData);
        print('[DEBUG] Company updated successfully');
        _clearForm();
        _loadCompanies();
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Company updated successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        // Create new company
        print('[DEBUG] Creating new company');
        companyData['createdAt'] = FieldValue.serverTimestamp();
        final docRef = await companiesCollection.add(companyData);
        print('[DEBUG] Company added successfully with ID: ${docRef.id}');
        _clearForm();
        _loadCompanies();
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Company added successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      print('[ERROR] Failed to save company: $e');
      print('[ERROR] Error type: ${e.runtimeType}');
      print('[ERROR] Full error: $e');
      
      String errorMsg = 'Error saving company: ${e.toString()}';
      
      if (e.toString().contains('permission-denied')) {
        errorMsg = 'Permission Denied - Firestore security rules are blocking write access.';
        print('[ERROR] CRITICAL: Firestore permission denied - security rules issue');
      }
      
      if (mounted) {
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
      print('[DEBUG] _saveCompany() completed');
    }
  }

  Future<void> _deleteCompany(String companyId) async {
    print('[DEBUG] Delete company initiated for ID: $companyId');
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Company'),
        content: const Text('Are you sure you want to delete this company?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      print('[DEBUG] Delete cancelled by user');
      return;
    }

    try {
      print('[DEBUG] Attempting to delete company: $companyId');
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        print('[ERROR] No authenticated user for delete operation');
        return;
      }

      print('[DEBUG] Deleting from path: users/${currentUser.uid}/companies/$companyId');
      await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('companies')
          .doc(companyId)
          .delete();

      print('[DEBUG] Company deleted successfully');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Company deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }

      _loadCompanies();
    } catch (e) {
      print('[ERROR] Failed to delete company: $e');
      print('[ERROR] Error type: ${e.runtimeType}');
      
      if (e.toString().contains('permission-denied')) {
        print('[ERROR] CRITICAL: Permission denied when deleting - security rules issue');
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting company: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _isNavigatingAway = true;
    _filterDebounceTimer?.cancel();
    _companyNameController.dispose();
    _supplierSearchController.dispose();
    _contactController.dispose();
    _addressController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _sessionManager.resetSession();
    print('[DEBUG] CompanyPage build() called');
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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      _isNavigatingAway = true;
                      Navigator.pop(context);
                    },
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.arrow_back, color: Colors.white, size: 22),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'My Companies',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'Literata',
                            height: 1.2,
                          ),
                        ),
                        Text(
                          'Manage your businesses',
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
          onPressed: () {
            print('[DEBUG] FAB pressed to add company');
            _showAddCompanyBottomSheet();
          },
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
      body: Column(
        children: [
          // Search bar + Sort button
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
                              hintText: 'Search companies...',
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
              ],
            ),
          ),
          // List or empty state
          Expanded(
            child: _filteredCompanies.isEmpty
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
                          _companies.isEmpty ? 'No companies yet' : 'No results found',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.grey[700], fontFamily: 'Literata'),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _companies.isEmpty ? 'Create your first company to get started' : 'Try a different search',
                          style: TextStyle(fontSize: 14, color: Colors.grey[500], fontFamily: 'Literata'),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: _filteredCompanies.length,
                    itemBuilder: (context, index) {
                      final company = _filteredCompanies[index];
                      return RepaintBoundary(
                        child: _buildCompanyCard(company),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompanyCard(Map<String, dynamic> company) {
    final companyName = company['companyName'] ?? 'Unknown Company';
    final contactPerson = company['contactPerson'] ?? 'N/A';
    final contact = company['contact'] ?? 'N/A';
    final address = company['address'] ?? 'N/A';
    final companyId = company['id'] ?? '';

    const accentColors = [Color(0xFF1B4D3E), Color(0xFF0F3B2F), Color(0xFF2C6F5E), Color(0xFF1A5E52)];
    final accentColor = accentColors[(companyId.hashCode.abs()) % accentColors.length];

    // Get first letter for avatar
    final initials = companyName.isNotEmpty ? companyName[0].toUpperCase() : 'C';

    return GestureDetector(
      onTap: () => _showEditCompanyBottomSheet(company),
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
                            companyName,
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
                          if (contactPerson != 'N/A')
                            Row(
                              children: [
                                Icon(Icons.person_outlined, size: 13, color: Colors.grey[600]),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    contactPerson,
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
                          onTap: () => Future.delayed(const Duration(milliseconds: 100), () => _showEditCompanyBottomSheet(company)),
                        ),
                        PopupMenuItem(
                          child: Row(
                            children: [const Icon(Icons.delete_outline, color: Colors.red, size: 18), const SizedBox(width: 8), const Text('Delete', style: TextStyle(color: Colors.red))],
                          ),
                          onTap: () => _deleteCompany(company['id']),
                        ),
                      ],
                      icon: Icon(Icons.more_vert, color: accentColor, size: 20),
                    ),
                  ],
                ),
                // Contact section
                if (contact != 'N/A') ...[
                  const SizedBox(height: 12),
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

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    bool isRequired = false,
  }) {
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
          borderSide: const BorderSide(
            color: Color(0xFF1B4D3E),
            width: 2,
          ),
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
  }
}

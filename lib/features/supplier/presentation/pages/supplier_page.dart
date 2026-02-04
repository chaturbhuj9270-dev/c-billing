import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/services/session_manager.dart';

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
  final _companyController = TextEditingController();
  final _filterController = TextEditingController();
  final _companyFilterController = TextEditingController();

  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isEditing = false;
  String? _editingSupplierId;
  List<String> _companies = [];
  List<Map<String, dynamic>> _suppliers = [];
  List<Map<String, dynamic>> _filteredSuppliers = [];
  
  // Search, sort, and filter variables
  String _sortBy = 'name'; // 'name', 'date', 'contact'
  bool _isSortAscending = true; // Toggle for ascending/descending
  Timer? _filterDebounceTimer; // Debounce timer for search
  Set<String> _selectedCompanyFilters = {}; // Multiple company selection
  Set<String> _allCompanies = {};

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
    _filterController.addListener(_filterSuppliers);
  }

  @override
  void dispose() {
    _filterDebounceTimer?.cancel();
    _filterController.removeListener(_filterSuppliers);
    _filterController.dispose();
    _firstNameController.dispose();
    _middleNameController.dispose();
    _lastNameController.dispose();
    _contactController.dispose();
    _addressController.dispose();
    _companyController.dispose();
    _companyFilterController.dispose();
    super.dispose();
  }

  void _updateAllCompanies() {
    _allCompanies = {};
    for (var supplier in _suppliers) {
      final companies = List<String>.from(supplier['companies'] ?? []);
      _allCompanies.addAll(companies);
    }
  }

  void _filterSuppliers() {
    // Cancel previous timer
    _filterDebounceTimer?.cancel();
    
    // Create new timer with 300ms debounce
    _filterDebounceTimer = Timer(const Duration(milliseconds: 300), () {
      setState(() {
        _applyFiltering();
      });
    });
  }

  void _applyFiltering() {
    final query = _filterController.text.toLowerCase();
    
    // Filter by search query
    List<Map<String, dynamic>> filtered = _suppliers.where((supplier) {
      if (query.isEmpty) return true;
      
      final firstName = (supplier['firstName'] ?? '').toString().toLowerCase();
      final lastName = (supplier['lastName'] ?? '').toString().toLowerCase();
      final contact = (supplier['contact'] ?? '').toString().toLowerCase();
      
      return firstName.contains(query) ||
          lastName.contains(query) ||
          contact.contains(query);
    }).toList();

    // Filter by company (multiple selection)
    if (_selectedCompanyFilters.isNotEmpty) {
      filtered = filtered.where((supplier) {
        final companies = List<String>.from(supplier['companies'] ?? []);
        return companies.any((company) => _selectedCompanyFilters.contains(company));
      }).toList();
    }

    _filteredSuppliers = filtered;
    _applySorting();
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

  void _filterAndSortSuppliers() {
    setState(() {
      _applyFiltering();
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
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        print('[ERROR] No authenticated user - cannot load suppliers');
        return;
      }

      final snapshot = await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('suppliers')
          .orderBy('createdAt', descending: true)
          .get();

      setState(() {
        _suppliers = snapshot.docs
            .map((doc) => {
                  'id': doc.id,
                  ...doc.data(),
                })
            .toList();
        _updateAllCompanies();
        _filterAndSortSuppliers();
      });
    } catch (e) {
      print('[ERROR] Failed to load suppliers: $e');
      
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

  void _clearForm() {
    setState(() {
      _firstNameController.clear();
      _middleNameController.clear();
      _lastNameController.clear();
      _contactController.clear();
      _addressController.clear();
      _companyController.clear();
      _companies.clear();
      _editingSupplierId = null;
      _isEditing = false;
    });
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

  void _showCompanyFilterBottomSheet() {
    _companyFilterController.clear();
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
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Filter by Companies',
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
                const SizedBox(height: 16),
                // Search field
                TextField(
                  controller: _companyFilterController,
                  decoration: InputDecoration(
                    hintText: 'Search companies...',
                    hintStyle: TextStyle(color: Colors.grey[400]),
                    prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
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
                  onChanged: (value) => setState(() {}),
                ),
                const SizedBox(height: 16),
                // Company list with checkboxes
                StatefulBuilder(
                  builder: (ctx, setStateLocal) {
                    final query = _companyFilterController.text.toLowerCase();
                    final filteredCompanies = _allCompanies
                        .where((company) =>
                            company.toLowerCase().contains(query))
                        .toList()
                        ..sort();

                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (filteredCompanies.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 24),
                            child: Text(
                              'No companies found',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                          )
                        else
                          ...filteredCompanies.map((company) {
                            final isSelected =
                                _selectedCompanyFilters.contains(company);
                            return CheckboxListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(
                                company,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF1B4D3E),
                                ),
                              ),
                              value: isSelected,
                              onChanged: (bool? value) {
                                setState(() {
                                  if (value == true) {
                                    _selectedCompanyFilters.add(company);
                                  } else {
                                    _selectedCompanyFilters.remove(company);
                                  }
                                  _filterAndSortSuppliers();
                                });
                                setStateLocal(() {});
                              },
                              activeColor: const Color(0xFF1B4D3E),
                              checkColor: Colors.white,
                            );
                          }).toList(),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 20),
                // Clear All button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: _selectedCompanyFilters.isEmpty
                        ? null
                        : () {
                            setState(() {
                              _selectedCompanyFilters.clear();
                              _filterAndSortSuppliers();
                            });
                            Navigator.pop(ctx);
                          },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Clear All',
                      style: TextStyle(
                        color: Color(0xFF1B4D3E),
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Done button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1B4D3E),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Done',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
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
          ),
          const SizedBox(height: 16),
          // Companies Section
          Text(
            'Companies *',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1B4D3E),
              fontFamily: 'Literata',
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _companyController,
                  decoration: InputDecoration(
                    hintText: 'Enter company name',
                    hintStyle: TextStyle(color: Colors.grey[400]),
                    prefixIcon: Icon(
                      Icons.business_outlined,
                      color: Colors.grey[600],
                    ),
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
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _addCompany,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1B4D3E),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Icon(Icons.add, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Companies List
          if (_companies.isNotEmpty)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _companies.map((company) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        company,
                        style: const TextStyle(
                          color: Color(0xFF1B4D3E),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => _removeCompany(company),
                        child: const Icon(
                          Icons.close,
                          color: Color(0xFF1B4D3E),
                          size: 16,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
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

  void _addCompany() {
    if (_companyController.text.isNotEmpty) {
      setState(() {
        _companies.add(_companyController.text);
        _companyController.clear();
      });
    }
  }

  void _removeCompany(String company) {
    setState(() {
      _companies.remove(company);
    });
  }

  void _editSupplier(Map<String, dynamic> supplier) {
    _firstNameController.text = supplier['firstName'] ?? '';
    _middleNameController.text = supplier['middleName'] ?? '';
    _lastNameController.text = supplier['lastName'] ?? '';
    _contactController.text = supplier['contact'] ?? '';
    _addressController.text = supplier['address'] ?? '';
    _companies = List<String>.from(supplier['companies'] ?? []);
    _editingSupplierId = supplier['id'];
    _isEditing = true;
  }

  Future<void> _saveSupplier() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_companies.isEmpty) {
      if (mounted && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please add at least one company'),
            backgroundColor: Colors.orange,
          ),
        );
      }
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
        await suppliersRef.doc(_editingSupplierId).update({
          'firstName': _firstNameController.text,
          'middleName': _middleNameController.text,
          'lastName': _lastNameController.text,
          'contact': _contactController.text,
          'address': _addressController.text,
          'companies': _companies,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        print('[DEBUG] Supplier updated: $_editingSupplierId');
      } else {
        await suppliersRef.add({
          'firstName': _firstNameController.text,
          'middleName': _middleNameController.text,
          'lastName': _lastNameController.text,
          'contact': _contactController.text,
          'address': _addressController.text,
          'companies': _companies,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
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

      _loadSuppliers();
      _updateAllCompanies();
    } catch (e) {
      print('[ERROR] Error saving supplier: $e');
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

      _loadSuppliers();
      _updateAllCompanies();
    } catch (e) {
      print('[ERROR] Error deleting supplier: $e');
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
                    onTap: () => Navigator.of(context).pop(),
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
                            controller: _filterController,
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
                              suffixIcon: _filterController.text.isNotEmpty
                                  ? GestureDetector(
                                      onTap: () {
                                        _filterController.clear();
                                        _filterSuppliers();
                                      },
                                      child: Icon(Icons.close, color: Colors.grey[600], size: 18),
                                    )
                                  : null,
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(vertical: 12),
                              isDense: true,
                            ),
                            onChanged: (_) {
                              setState(() {}); // Update UI for suffix icon
                              _filterSuppliers();
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
                // Filter by company button
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
                      onTap: _showCompanyFilterBottomSheet,
                      borderRadius: BorderRadius.circular(11),
                      child: Center(
                        child: Icon(
                          Icons.business_outlined,
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
    final companies = List<String>.from(supplier['companies'] ?? []);
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
                // Companies section
                if (companies.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: companies.map((company) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: accentColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: accentColor.withOpacity(0.3), width: 1),
                        ),
                        child: Text(
                          company,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: accentColor,
                            fontFamily: 'Literata',
                          ),
                        ),
                      );
                    }).toList(),
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

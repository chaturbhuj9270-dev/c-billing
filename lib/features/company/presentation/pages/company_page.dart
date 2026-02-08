import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/services/session_manager.dart';
import '../../../../core/services/language_service.dart';
import '../../../../core/services/dashboard_refresh_service.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../data/datasources/company_cache_datasource.dart';

class CompanyPage extends StatefulWidget {
  const CompanyPage({super.key});

  @override
  State<CompanyPage> createState() => _CompanyPageState();
}

class _CompanyPageState extends State<CompanyPage> {
  final _companyNameController = TextEditingController();
  final _contactController = TextEditingController();
  final _addressController = TextEditingController();
  final _searchController = TextEditingController();

  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isEditing = false;
  String? _editingCompanyId;
  List<Map<String, dynamic>> _companies = [];
  List<Map<String, dynamic>> _filteredCompanies = [];
  bool _isSortAscending = true;
  Timer? _filterDebounceTimer;
  bool _isNavigatingAway = false;
  final _cacheDataSource = CompanyCacheDataSource();

  final _auth = FirebaseAuth.instance;
  late final FirebaseFirestore _firestore;
  late SessionManager _sessionManager;
  late AppLocalizations _localizations;

  @override
  void initState() {
    super.initState();
    _firestore = FirebaseFirestore.instance;
    _sessionManager = SessionManager();
    _localizations = AppLocalizations(LanguageService.instance.currentLanguage);
    LanguageService.instance.addListener(_onLanguageChanged);
    _checkUserAuthentication();
    _setupInitialData();
    _searchController.addListener(_filterAndSearchCompanies);
  }

  void _onLanguageChanged() {
    setState(() {
      _localizations = AppLocalizations(
        LanguageService.instance.currentLanguage,
      );
    });
  }

  Future<void> _setupInitialData() async {
    // Load from cache immediately for < 0.5s loading
    final cachedCompanies = await _cacheDataSource.getCachedCompanies();

    if (mounted) {
      setState(() {
        if (cachedCompanies != null) {
          _companies = cachedCompanies;
          _filterAndSortCompanies();
        }
      });
      print('[DEBUG] Loaded from cache: ${_companies.length} companies');
    }

    // Fetch from Firestore in background
    _loadCompanies();
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
            final name = (company['companyName'] ?? '')
                .toString()
                .toLowerCase();
            final contact = (company['contact'] ?? '').toString().toLowerCase();
            final contactPerson = (company['contactPerson'] ?? '')
                .toString()
                .toLowerCase();
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

  void _checkUserAuthentication() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    }
  }

  Future<void> _loadCompanies() async {
    try {
      print('[DEBUG] Loading companies from Firestore...');
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

      print('[DEBUG] Loaded ${snapshot.docs.length} companies from Firestore');

      final freshCompanies = snapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data()})
          .toList();

      if (mounted && !_isNavigatingAway) {
        setState(() {
          _companies = freshCompanies;
          _filterAndSortCompanies();
        });
        // Save to cache for next time
        _cacheDataSource.saveCompanies(freshCompanies);
      }
    } catch (e) {
      print('[ERROR] Failed to load companies: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_localizations.errorLoadingCompanies}: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _clearForm() {
    _companyNameController.clear();
    _contactController.clear();
    _addressController.clear();
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
                _isEditing
                    ? _localizations.editCompany
                    : _localizations.addNewCompany,
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
            label: _localizations.companyName,
            controller: _companyNameController,
            icon: Icons.business_outlined,
            isRequired: true,
          ),
          const SizedBox(height: 16),
          // Contact Number
          _buildInputField(
            label: _localizations.contactNumber,
            controller: _contactController,
            icon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
            isRequired: false,
          ),
          const SizedBox(height: 16),
          // Address
          _buildInputField(
            label: _localizations.address,
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
                          _isEditing
                              ? _localizations.update
                              : _localizations.addCompany,
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

    setState(() => _isLoading = true);
    print('[DEBUG] Starting company save operation');

    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        print('[ERROR] No authenticated user found');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_localizations.userNotAuthenticated)),
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
        'contact': _contactController.text.trim(),
        'address': _addressController.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      print('[DEBUG] Company data: $companyData');

      if (_isEditing && _editingCompanyId != null) {
        // Optimistic update
        final index = _companies.indexWhere(
          (c) => c['id'] == _editingCompanyId,
        );
        if (index != -1) {
          setState(() {
            _companies[index] = {..._companies[index], ...companyData};
            _filterAndSortCompanies();
          });
          _cacheDataSource.saveCompanies(_companies);
        }

        // Update existing company
        print('[DEBUG] Updating existing company: $_editingCompanyId');
        await companiesCollection.doc(_editingCompanyId).update(companyData);
        print('[DEBUG] Company updated successfully');
        
        // Notify dashboard to refresh
        DashboardRefreshService.instance.notifyDataChanged(DataChangeType.company);
        
        _clearForm();
        _loadCompanies();
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_localizations.companyUpdatedSuccessfully),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        // Create new company
        print('[DEBUG] Creating new company');
        companyData['createdAt'] = FieldValue.serverTimestamp();

        // Optimistic add
        final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
        final newCompany = {'id': tempId, ...companyData};
        setState(() {
          _companies.insert(0, newCompany);
          _filterAndSortCompanies();
        });
        _cacheDataSource.saveCompanies(_companies);

        final docRef = await companiesCollection.add(companyData);
        print('[DEBUG] Company added successfully with ID: ${docRef.id}');
        
        // Notify dashboard to refresh
        DashboardRefreshService.instance.notifyDataChanged(DataChangeType.company);
        
        _clearForm();
        _loadCompanies();
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_localizations.companyAddedSuccessfully),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      print('[ERROR] Failed to save company: $e');
      // Reload on error to revert optimistic update
      _loadCompanies();
      print('[ERROR] Error type: ${e.runtimeType}');
      print('[ERROR] Full error: $e');

      String errorMsg = '${_localizations.errorSavingCompany}: ${e.toString()}';

      if (e.toString().contains('permission-denied')) {
        errorMsg =
            'Permission Denied - Firestore security rules are blocking write access.';
        print(
          '[ERROR] CRITICAL: Firestore permission denied - security rules issue',
        );
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
        title: Text(_localizations.deleteCompany),
        content: Text(_localizations.deleteCompanyConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(_localizations.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(_localizations.delete),
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

      // Optimistic delete
      setState(() {
        _companies.removeWhere((c) => c['id'] == companyId);
        _filterAndSortCompanies();
      });
      _cacheDataSource.saveCompanies(_companies);

      print(
        '[DEBUG] Deleting from path: users/${currentUser.uid}/companies/$companyId',
      );
      await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('companies')
          .doc(companyId)
          .delete();

      print('[DEBUG] Company deleted successfully');
      
      // Notify dashboard to refresh
      DashboardRefreshService.instance.notifyDataChanged(DataChangeType.company);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_localizations.companyDeletedSuccessfully),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('[ERROR] Failed to delete company: $e');
      // Reload on error to revert optimistic delete
      _loadCompanies();
      print('[ERROR] Error type: ${e.runtimeType}');

      if (e.toString().contains('permission-denied')) {
        print(
          '[ERROR] CRITICAL: Permission denied when deleting - security rules issue',
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_localizations.errorDeletingCompany}: $e'),
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
    _contactController.dispose();
    _addressController.dispose();
    _searchController.dispose();
    LanguageService.instance.removeListener(_onLanguageChanged);
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
                      child: const Icon(
                        Icons.arrow_back,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _localizations.myCompanies,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'Literata',
                            height: 1.2,
                          ),
                        ),
                        Text(
                          _localizations.manageYourBusinesses,
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
              print('[DEBUG] FAB pressed to add company');
              _showAddCompanyBottomSheet();
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
                              hintText: _localizations.searchCompanies,
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
                                      },
                                      child: Icon(
                                        Icons.close,
                                        color: Colors.grey[600],
                                        size: 18,
                                      ),
                                    )
                                  : null,
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 12,
                              ),
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
                          child: Icon(
                            Icons.business_outlined,
                            size: 50,
                            color: const Color(0xFF1B4D3E).withOpacity(0.3),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          _companies.isEmpty
                              ? _localizations.noCompaniesYet
                              : _localizations.noResultsFound,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[700],
                            fontFamily: 'Literata',
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _companies.isEmpty
                              ? _localizations.createFirstCompany
                              : _localizations.tryDifferentSearch,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                            fontFamily: 'Literata',
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    itemCount: _filteredCompanies.length,
                    itemBuilder: (context, index) {
                      final company = _filteredCompanies[index];
                      return RepaintBoundary(child: _buildCompanyCard(company));
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompanyCard(Map<String, dynamic> company) {
    final companyName = company['companyName'] ?? _localizations.unknownCompany;
    final contact = company['contact'] ?? 'N/A';
    final address = company['address'] ?? 'N/A';
    final companyId = company['id'] ?? '';

    const accentColors = [
      Color(0xFF1B4D3E),
      Color(0xFF0F3B2F),
      Color(0xFF2C6F5E),
      Color(0xFF1A5E52),
    ];
    final accentColor =
        accentColors[(companyId.hashCode.abs()) % accentColors.length];

    // Get first letter for avatar
    final initials = companyName.isNotEmpty
        ? companyName[0].toUpperCase()
        : 'C';

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
                        ],
                      ),
                    ),
                    PopupMenuButton(
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 8,
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          child: Row(
                            children: [
                              Icon(
                                Icons.edit_outlined,
                                color: accentColor,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Text(_localizations.edit),
                            ],
                          ),
                          onTap: () => Future.delayed(
                            const Duration(milliseconds: 100),
                            () => _showEditCompanyBottomSheet(company),
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
                              const SizedBox(width: 8),
                              Text(
                                _localizations.delete,
                                style: const TextStyle(color: Colors.red),
                              ),
                            ],
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
                      Icon(
                        Icons.phone_outlined,
                        size: 13,
                        color: Colors.grey[600],
                      ),
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
                        Icon(
                          Icons.location_on_outlined,
                          size: 13,
                          color: Colors.grey[600],
                        ),
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
  }
}

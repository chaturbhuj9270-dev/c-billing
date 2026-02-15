import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/services/session_manager.dart';
import '../../../../core/services/language_service.dart';
import '../../../../core/services/dashboard_refresh_service.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../data/datasources/company_cache_datasource.dart';
import '../../offline/controllers/company_offline_controller.dart';
import '../../offline/entities/company_entity.dart';
import '../../data/services/company_sync_service.dart';

class CompanyPage extends StatefulWidget {
  const CompanyPage({super.key});

  @override
  State<CompanyPage> createState() => _CompanyPageState();
}

class _CompanyPageState extends State<CompanyPage> {
  final _companyNameController = TextEditingController();
  final _companyCodeController = TextEditingController();
  final _contactController = TextEditingController();
  final _addressController = TextEditingController();
  final _searchController = TextEditingController();

  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isInitialLoading = true;
  bool _isEditing = false;
  String? _editingCompanyId;
  int? _editingCompanyLocalId; // Local Isar ID for offline-first
  List<Map<String, dynamic>> _companies = [];
  List<Map<String, dynamic>> _filteredCompanies = [];
  bool _isSortAscending = true;
  Timer? _filterDebounceTimer;
  bool _isNavigatingAway = false;
  final _cacheDataSource = CompanyCacheDataSource();
  
  // Offline-first support
  StreamSubscription<List<CompanyEntity>>? _companyStreamSubscription;
  StreamSubscription<QuerySnapshot>? _firestoreStreamSubscription;
  int _unsyncedCount = 0;

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
    _setupOfflineStream();
    _setupFirestoreStream();
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
          _isInitialLoading = false;
          _filterAndSortCompanies();
        }
      });
      print('[DEBUG] Loaded from cache: ${_companies.length} companies');
    }

    // Fetch from Firestore in background
    _loadCompanies();
  }

  /// Setup offline stream for real-time Isar updates
  void _setupOfflineStream() {
    final offlineController = CompanyOfflineController.instance;
    
    // Listen to Isar changes for instant UI updates
    _companyStreamSubscription = offlineController.watchAllCompanies().listen(
      (entities) {
        if (mounted && !_isNavigatingAway) {
          // Convert entities to Map format for existing UI
          final companies = entities.map((e) => e.toCompanyMap()).toList();
          
          setState(() {
            _companies = companies;
            _isInitialLoading = false;
            _filterAndSortCompanies();
          });
          
          // Update unsynced count
          _updateUnsyncedCount();
        }
      },
      onError: (e) {
        print('[ERROR] Isar stream error: $e');
      },
    );
    
    // Initial unsynced count
    _updateUnsyncedCount();
  }
  
  Future<void> _updateUnsyncedCount() async {
    final count = await CompanyOfflineController.instance.getUnsyncedCount();
    if (mounted && count != _unsyncedCount) {
      setState(() => _unsyncedCount = count);
    }
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
            final companyCode = (company['companyCode'] ?? '').toString().toLowerCase();
            return name.contains(query) ||
                contact.contains(query) ||
                contactPerson.contains(query) ||
                address.contains(query) ||
                companyCode.contains(query);
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
      print('[DEBUG] Loading companies from Firestore (one-time)...');
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

      // Import server data to Isar (offline-first)
      await CompanyOfflineController.instance.importFromServer(freshCompanies);
      
      // Trigger background sync for any pending local changes
      CompanySyncService.instance.syncNow();

      if (mounted && !_isNavigatingAway) {
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

  /// Setup real-time Firestore stream for cross-device synchronization
  void _setupFirestoreStream() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    _firestoreStreamSubscription = _firestore
        .collection('users')
        .doc(currentUser.uid)
        .collection('companies')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen(
      (snapshot) async {
        if (!mounted || _isNavigatingAway) return;

        print('[Company] Firestore stream: ${snapshot.docs.length} docs (${snapshot.docChanges.length} changes)');

        final freshCompanies = snapshot.docs
            .map((doc) => {'id': doc.id, ...doc.data()})
            .toList();

        // Import to Isar — the Isar stream listener auto-updates the UI
        await CompanyOfflineController.instance.importFromServer(freshCompanies);

        // Update cache
        if (mounted && !_isNavigatingAway) {
          _cacheDataSource.saveCompanies(freshCompanies);
        }
      },
      onError: (e) {
        print('[ERROR] Firestore company stream error: $e');
      },
    );
  }

  void _clearForm() {
    _companyNameController.clear();
    _companyCodeController.clear();
    _contactController.clear();
    _addressController.clear();
    _editingCompanyId = null;
    _editingCompanyLocalId = null;
    _isEditing = false;
  }

  /// Generate next company code by finding highest existing code and adding 1
  Future<String> _generateNextCompanyCode() async {
    try {
      // Get all companies from local list (already loaded)
      if (_companies.isEmpty) {
        return '1'; // First company
      }

      // Extract numeric codes from existing companies
      int maxCode = 0;
      for (var company in _companies) {
        final code = company['companyCode'] as String?;
        if (code != null && code.isNotEmpty) {
          // Try to parse as integer
          final numericCode = int.tryParse(code);
          if (numericCode != null && numericCode > maxCode) {
            maxCode = numericCode;
          }
        }
      }

      // Return next code
      return '${maxCode + 1}';
    } catch (e) {
      print('[ERROR] Failed to generate company code: $e');
      return '1';
    }
  }

  Future<void> _showAddCompanyBottomSheet() async {
    print('[DEBUG] Opening add company bottom sheet');
    _clearForm();
    
    // Auto-generate next company code
    final nextCode = await _generateNextCompanyCode();
    _companyCodeController.text = nextCode;
    print('[DEBUG] Auto-generated company code: $nextCode');
    
    if (!mounted) return;
    
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
          // Company Code (auto-generated for new, editable for existing)
          _buildInputField(
            label: _localizations.companyCode,
            controller: _companyCodeController,
            icon: Icons.qr_code_rounded,
            isRequired: true,
            isReadOnly: !_isEditing, // Read-only when adding new company
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
    _companyCodeController.text = company['companyCode'] ?? '';
    _contactController.text = company['contact'] ?? '';
    _addressController.text = company['address'] ?? '';
    _editingCompanyId = company['id'];
    _editingCompanyLocalId = company['localId'] as int?;
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
      final offlineController = CompanyOfflineController.instance;

      if (_isEditing) {
        // For editing, we need the local Isar ID
        int? localId = _editingCompanyLocalId;
        
        // If localId not available, try to find by serverId
        if (localId == null && _editingCompanyId != null) {
          final existing = await offlineController.getCompanyByServerId(_editingCompanyId!);
          localId = existing?.id;
        }
        
        if (localId != null) {
          // Update existing company in Isar
          await offlineController.updateCompany(
            id: localId,
            companyName: _companyNameController.text.trim(),
            companyCode: _companyCodeController.text.trim(),
            contact: _contactController.text.trim(),
            address: _addressController.text.trim(),
          );
          print('[DEBUG] Company updated locally: $localId');
        } else {
          print('[ERROR] Could not find company to update');
          throw Exception('Company not found');
        }
        
        // Notify dashboard to refresh
        DashboardRefreshService.instance.notifyDataChanged(DataChangeType.company);
      } else {
        // Add new company to Isar
        await offlineController.addCompany(
          companyName: _companyNameController.text.trim(),
          companyCode: _companyCodeController.text.trim(),
          contact: _contactController.text.trim(),
          address: _addressController.text.trim(),
        );
        print('[DEBUG] New company added locally');
        
        // Notify dashboard to refresh
        DashboardRefreshService.instance.notifyDataChanged(DataChangeType.company);
      }

      // Trigger background sync
      CompanySyncService.instance.syncNow();

      if (mounted && context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEditing
                  ? _localizations.companyUpdatedSuccessfully
                  : _localizations.companyAddedSuccessfully,
            ),
            backgroundColor: Colors.green,
          ),
        );
      }

      if (mounted) {
        _clearForm();
      }
    } catch (e) {
      print('[ERROR] Error saving company: $e');
      if (mounted && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _deleteCompany(String companyId, {int? localId}) async {
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
      final offlineController = CompanyOfflineController.instance;
      
      // Get the local Isar ID
      int? deleteLocalId = localId;
      
      // If localId not available, try to find by serverId
      if (deleteLocalId == null) {
        final existing = await offlineController.getCompanyByServerId(companyId);
        deleteLocalId = existing?.id;
      }
      
      if (deleteLocalId != null) {
        // Soft delete in Isar (marks as deleted for sync)
        await offlineController.deleteCompany(deleteLocalId);
        print('[DEBUG] Company marked for deletion: $deleteLocalId');
      } else {
        print('[ERROR] Could not find company to delete');
        throw Exception('Company not found');
      }
      
      // Trigger background sync to delete from server
      CompanySyncService.instance.syncNow();
      
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
      print('[ERROR] Error deleting company: $e');
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
    _companyStreamSubscription?.cancel();
    _firestoreStreamSubscription?.cancel();
    _filterDebounceTimer?.cancel();
    _companyNameController.dispose();
    _companyCodeController.dispose();
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
            onTap: () async {
              print('[DEBUG] FAB pressed to add company');
              await _showAddCompanyBottomSheet();
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
      body: _isInitialLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF1B4D3E),
              ),
            )
          : _companies.isEmpty && !_isLoading
              ? _buildEmptyState()
              : _buildCompanyListBody(),
    );
  }

  /// Clean empty state widget when no companies exist
  Widget _buildEmptyState() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isTablet = constraints.maxWidth > 600;
        final iconSize = isTablet ? 120.0 : 90.0;
        final titleSize = isTablet ? 22.0 : 18.0;
        final subtitleSize = isTablet ? 16.0 : 14.0;

        return Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: iconSize,
                  height: iconSize,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        const Color(0xFF1B4D3E).withOpacity(0.12),
                        const Color(0xFF2E7D32).withOpacity(0.08),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(iconSize * 0.25),
                  ),
                  child: Icon(
                    Icons.business_outlined,
                    size: iconSize * 0.5,
                    color: const Color(0xFF1B4D3E).withOpacity(0.4),
                  ),
                ),
                const SizedBox(height: 28),
                Text(
                  _localizations.noCompaniesAvailable,
                  style: TextStyle(
                    fontSize: titleSize,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey[800],
                    fontFamily: 'Literata',
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: isTablet ? 80 : 32),
                  child: Text(
                    _localizations.addYourFirstCompany,
                    style: TextStyle(
                      fontSize: subtitleSize,
                      color: Colors.grey[500],
                      fontFamily: 'Literata',
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: _showAddCompanyBottomSheet,
                  icon: const Icon(Icons.add_rounded, size: 20),
                  label: Text(
                    _localizations.addCompanyNow,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Literata',
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1B4D3E),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 28,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 4,
                    shadowColor: const Color(0xFF1B4D3E).withOpacity(0.3),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Main company list body with search bar and responsive list
  Widget _buildCompanyListBody() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isTablet = constraints.maxWidth > 600;
        final horizontalPadding = isTablet ? 24.0 : 16.0;

        return Column(
          children: [
            // Search bar + Sort button
            Padding(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 16),
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
            // List or search-empty state
            Expanded(
              child: _filteredCompanies.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.search_off_rounded,
                            size: 48,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _localizations.noResultsFound,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[700],
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
                  : isTablet
                      ? GridView.builder(
                          padding: EdgeInsets.symmetric(
                            horizontal: horizontalPadding,
                            vertical: 8,
                          ),
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: constraints.maxWidth > 900 ? 3 : 2,
                            crossAxisSpacing: 14,
                            mainAxisSpacing: 14,
                            childAspectRatio: 1.8,
                          ),
                          itemCount: _filteredCompanies.length,
                          itemBuilder: (context, index) {
                            final company = _filteredCompanies[index];
                            return RepaintBoundary(child: _buildCompanyCard(company));
                          },
                        )
                      : ListView.builder(
                          padding: EdgeInsets.symmetric(
                            horizontal: horizontalPadding,
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
        );
      },
    );
  }

  Widget _buildCompanyCard(Map<String, dynamic> company) {
    final companyName = company['companyName'] ?? _localizations.unknownCompany;
    final companyCode = company['companyCode'] ?? '';
    final contact = company['contact'] as String?;
    final address = company['address'] as String?;
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
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.grey.withValues(alpha: 0.08),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Row: Avatar + Details + Menu
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Circular gradient avatar with enhanced shadow
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          accentColor,
                          accentColor.withValues(alpha: 0.75),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: accentColor.withValues(alpha: 0.25),
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
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Company name with improved typography
                        Text(
                          companyName,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1B4D3E),
                            fontFamily: 'Literata',
                            height: 1.3,
                            letterSpacing: -0.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        // Company code badge with enhanced styling
                        if (companyCode.isNotEmpty) ...[
                          const SizedBox(height: 5),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 9,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1B4D3E).withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(7),
                              border: Border.all(
                                color: const Color(0xFF1B4D3E).withValues(alpha: 0.12),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              companyCode,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF1B4D3E).withValues(alpha: 0.85),
                                fontFamily: 'Literata',
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  // Enhanced menu button
                  PopupMenuButton(
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 12,
                    shadowColor: Colors.black.withValues(alpha: 0.15),
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        child: Row(
                          children: [
                            Icon(
                              Icons.edit_outlined,
                              color: accentColor,
                              size: 19,
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
                          () => _showEditCompanyBottomSheet(company),
                        ),
                      ),
                      PopupMenuItem(
                        child: Row(
                          children: [
                            const Icon(
                              Icons.delete_outline,
                              color: Colors.red,
                              size: 19,
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
                        onTap: () => _deleteCompany(
                          company['id'],
                          localId: company['localId'] as int?,
                        ),
                      ),
                    ],
                    icon: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.more_vert,
                        color: accentColor,
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),
              // Contact section - only show if contact exists and is not empty
              if (contact != null && contact.isNotEmpty) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F9FA),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: Colors.grey.withValues(alpha: 0.08),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1B4D3E).withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.phone_outlined,
                          size: 15,
                          color: const Color(0xFF1B4D3E).withValues(alpha: 0.7),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          contact,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[800],
                            fontFamily: 'Literata',
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              // Address section - only show if address exists and is not empty
              if (address != null && address.isNotEmpty) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F9FA),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: Colors.grey.withValues(alpha: 0.08),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1B4D3E).withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.location_on_outlined,
                          size: 15,
                          color: const Color(0xFF1B4D3E).withValues(alpha: 0.7),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          address,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[800],
                            fontFamily: 'Literata',
                            height: 1.4,
                            letterSpacing: 0.1,
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

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    bool isRequired = false,
    bool isReadOnly = false,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      maxLength: (label == _localizations.contactNumber) ? 10 : null,
      readOnly: isReadOnly,
      style: isReadOnly
          ? TextStyle(
              color: Colors.grey[600],
              fontFamily: 'Literata',
            )
          : null,
      decoration: InputDecoration(
        labelText: isRequired ? '$label *' : label,
        suffixIcon: isReadOnly
            ? Tooltip(
                message: 'Auto-generated',
                child: Icon(
                  Icons.lock_outline,
                  size: 18,
                  color: Colors.grey[500],
                ),
              )
            : null,
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
        fillColor: isReadOnly ? Colors.grey[100] : Colors.grey[50],
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

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
import '../widgets/company_summary_widget.dart';
import '../widgets/company_filter_widget.dart';
import '../widgets/company_list_widget.dart';

class EnhancedCompanyPage extends StatefulWidget {
  final bool isEmbedded;

  const EnhancedCompanyPage({super.key, this.isEmbedded = false});

  @override
  State<EnhancedCompanyPage> createState() => _EnhancedCompanyPageState();
}

class _EnhancedCompanyPageState extends State<EnhancedCompanyPage>
    with SingleTickerProviderStateMixin {
  // Animation
  late AnimationController _animController;
  late Animation<Offset> _offsetAnimation;
  late Animation<double> _opacityAnimation;

  // Form controllers
  final _companyNameController = TextEditingController();
  final _companyCodeController = TextEditingController();
  final _contactController = TextEditingController();
  final _addressController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  // State
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isEditing = false;
  String? _editingCompanyId;
  int? _editingCompanyLocalId;
  List<Map<String, dynamic>> _companies = [];
  String _searchQuery = '';
  CompanySortField _sortField = CompanySortField.name;
  bool _sortAscending = true;
  bool _isNavigatingAway = false;

  // Isar stream for real-time updates
  StreamSubscription<List<CompanyEntity>>? _companyStreamSub;
  // Firestore stream for cross-device real-time sync
  StreamSubscription<QuerySnapshot>? _firestoreStreamSub;

  // Services
  final _auth = FirebaseAuth.instance;
  late final FirebaseFirestore _firestore;
  late AppLocalizations _localizations;
  late SessionManager _sessionManager;
  final _cacheDataSource = CompanyCacheDataSource();

  @override
  void initState() {
    super.initState();
    _firestore = FirebaseFirestore.instance;
    _sessionManager = SessionManager();
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
    _companyStreamSub?.cancel();
    _firestoreStreamSub?.cancel();
    _companyNameController.dispose();
    _companyCodeController.dispose();
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
    final offlineCtrl = CompanyOfflineController.instance;
    _companyStreamSub = offlineCtrl.watchAllCompanies().listen(
      (entities) {
        if (!mounted || _isNavigatingAway) return;
        final mapped = entities.map(_entityToMap).toList();
        setState(() {
          _companies = mapped;
          _isLoading = false;
        });
        debugPrint('[EnhancedCompany] Isar stream: ${mapped.length} companies');
      },
      onError: (e) {
        debugPrint('[EnhancedCompany] Isar stream error: $e');
      },
    );
  }

  Map<String, dynamic> _entityToMap(CompanyEntity e) {
    return {
      'id': e.serverId ?? 'local_${e.id}',
      'localId': e.id,
      'companyName': e.companyName,
      'companyCode': e.companyCode,
      'contact': e.contact,
      'address': e.address,
      'isActive': e.isActive,
      'isSynced': e.syncStatus == CompanySyncStatus.synced,
      'syncStatus': e.syncStatus.name,
      'createdAt': e.createdAt,
      'updatedAt': e.updatedAt,
    };
  }

  // ━━━ DATA: Firebase Fetch (background) ━━━

  Future<void> _fetchFromFirebase() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return;

      final snapshot = await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('companies')
          .orderBy('createdAt', descending: true)
          .get();

      if (!mounted || _isNavigatingAway) return;

      final freshCompanies = snapshot.docs
          .map((doc) => {...doc.data(), 'id': doc.id})
          .toList();

      // Import to Isar
      await CompanyOfflineController.instance.importFromServer(freshCompanies);

      // Trigger background sync
      CompanySyncService.instance.syncNow();

      // Cache for next time
      _cacheDataSource.saveCompanies(freshCompanies);
    } catch (e) {
      debugPrint('[EnhancedCompany] Firebase fetch error: $e');
    }
  }

  // ━━━ DATA: Firestore Stream (cross-device sync) ━━━

  void _setupFirestoreStream() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    _firestoreStreamSub = _firestore
        .collection('users')
        .doc(currentUser.uid)
        .collection('companies')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen(
          (snapshot) async {
            if (!mounted || _isNavigatingAway) return;

            final freshCompanies = snapshot.docs
                .map((doc) => {...doc.data(), 'id': doc.id})
                .toList();

            await CompanyOfflineController.instance.importFromServer(
              freshCompanies,
            );
            _cacheDataSource.saveCompanies(freshCompanies);
          },
          onError: (e) {
            debugPrint('[EnhancedCompany] Firestore stream error: $e');
          },
        );
  }

  // ━━━ CRUD: Add/Edit/Delete ━━━

  void _clearForm() {
    _companyNameController.clear();
    _companyCodeController.clear();
    _contactController.clear();
    _addressController.clear();
    _editingCompanyId = null;
    _editingCompanyLocalId = null;
    _isEditing = false;
  }

  Future<String> _generateNextCompanyCode() async {
    try {
      if (_companies.isEmpty) return '1';

      int maxCode = 0;
      for (var company in _companies) {
        final code = company['companyCode'] as String?;
        if (code != null && code.isNotEmpty) {
          final numericCode = int.tryParse(code);
          if (numericCode != null && numericCode > maxCode) {
            maxCode = numericCode;
          }
        }
      }
      return '${maxCode + 1}';
    } catch (e) {
      return '1';
    }
  }

  void _showAddCompanySheet() async {
    _clearForm();
    final nextCode = await _generateNextCompanyCode();
    _companyCodeController.text = nextCode;

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _buildCompanyFormSheet(ctx),
    );
  }

  void _showEditCompanySheet(Map<String, dynamic> company) {
    _companyNameController.text = company['companyName'] ?? '';
    _companyCodeController.text = company['companyCode'] ?? '';
    _contactController.text = company['contact'] ?? '';
    _addressController.text = company['address'] ?? '';
    _editingCompanyId = company['id'];
    _editingCompanyLocalId = company['localId'] as int?;
    _isEditing = true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _buildCompanyFormSheet(ctx),
    );
  }

  Widget _buildCompanyFormSheet(BuildContext ctx) {
    return StatefulBuilder(
      builder: (context, setSheetState) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Drag handle
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
                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _isEditing
                              ? _localizations.editCompany
                              : _localizations.addNewCompany,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1B4D3E),
                            fontFamily: 'Literata',
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () {
                            _clearForm();
                            Navigator.pop(ctx);
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Form fields
                    _buildInputField(
                      label: _localizations.companyName,
                      controller: _companyNameController,
                      icon: Icons.business_outlined,
                      isRequired: true,
                    ),
                    const SizedBox(height: 16),
                    // Only show code field when editing (optional field)
                    if (_isEditing) ...[
                      _buildInputField(
                        label: _localizations.companyCode,
                        controller: _companyCodeController,
                        icon: Icons.qr_code_rounded,
                        isRequired: false,
                      ),
                      const SizedBox(height: 16),
                    ],
                    _buildInputField(
                      label: _localizations.contactNumber,
                      controller: _contactController,
                      icon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 16),
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
                            onPressed: _isSaving
                                ? null
                                : () => _saveCompany(ctx, setSheetState),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1B4D3E),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            child: _isSaving
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                : Text(
                                    _isEditing
                                        ? _localizations.update
                                        : _localizations.addCompany,
                                    style: const TextStyle(
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
                                  : () => _deleteCompany(ctx, setSheetState),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.red,
                                side: const BorderSide(color: Colors.red),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                'Delete',
                                style: TextStyle(
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
      },
    );
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    bool isRequired = false,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    bool isReadOnly = false,
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
              const Text(' *', style: TextStyle(color: Colors.red)),
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          minLines: maxLines,
          readOnly: isReadOnly,
          style: TextStyle(
            color: isReadOnly ? Colors.grey[600] : null,
            fontFamily: 'Literata',
          ),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: Colors.grey[600]),
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
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
            filled: true,
            fillColor: isReadOnly ? Colors.grey[100] : Colors.grey[50],
          ),
          validator: (value) {
            if (isRequired && (value == null || value.isEmpty)) {
              return '$label ${_localizations.isRequired}';
            }
            return null;
          },
        ),
      ],
    );
  }

  Future<void> _saveCompany(
    BuildContext ctx,
    void Function(void Function()) setSheetState,
  ) async {
    if (!_formKey.currentState!.validate()) return;

    setSheetState(() => _isSaving = true);

    try {
      final offlineCtrl = CompanyOfflineController.instance;

      if (_isEditing) {
        int? localId = _editingCompanyLocalId;
        if (localId == null && _editingCompanyId != null) {
          final existing = await offlineCtrl.getCompanyByServerId(
            _editingCompanyId!,
          );
          localId = existing?.id;
        }

        if (localId != null) {
          await offlineCtrl.updateCompany(
            id: localId,
            companyName: _companyNameController.text.trim(),
            companyCode: _companyCodeController.text.trim(),
            contact: _contactController.text.trim(),
            address: _addressController.text.trim(),
          );
        } else {
          throw Exception('Company not found');
        }
        DashboardRefreshService.instance.notifyDataChanged(
          DataChangeType.company,
        );
      } else {
        await offlineCtrl.addCompany(
          companyName: _companyNameController.text.trim(),
          companyCode: _companyCodeController.text.trim(),
          contact: _contactController.text.trim(),
          address: _addressController.text.trim(),
        );
        DashboardRefreshService.instance.notifyDataChanged(
          DataChangeType.company,
        );
      }

      final syncResult = await CompanySyncService.instance.syncNow();
      debugPrint('[EnhancedCompany] Sync after save result: $syncResult');

      if (mounted && ctx.mounted) {
        Navigator.pop(ctx);
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

      _clearForm();
    } catch (e) {
      if (mounted && ctx.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setSheetState(() => _isSaving = false);
      }
    }
  }

  Future<void> _deleteCompany(
    BuildContext ctx,
    void Function(void Function()) setSheetState,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Company'),
        content: const Text('Are you sure you want to delete this company?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setSheetState(() => _isSaving = true);

    try {
      final offlineCtrl = CompanyOfflineController.instance;
      int? localId = _editingCompanyLocalId;

      if (localId == null && _editingCompanyId != null) {
        final existing = await offlineCtrl.getCompanyByServerId(
          _editingCompanyId!,
        );
        localId = existing?.id;
      }

      if (localId != null) {
        await offlineCtrl.deleteCompany(localId);
      } else {
        throw Exception('Company not found');
      }

      final syncResult = await CompanySyncService.instance.syncNow();
      debugPrint('[EnhancedCompany] Sync after delete result: $syncResult');
      DashboardRefreshService.instance.notifyDataChanged(
        DataChangeType.company,
      );

      if (mounted && ctx.mounted) {
        Navigator.pop(ctx);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_localizations.companyDeletedSuccessfully),
            backgroundColor: Colors.green,
          ),
        );
      }

      _clearForm();
    } catch (e) {
      if (mounted && ctx.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setSheetState(() => _isSaving = false);
      }
    }
  }

  // ━━━ UI: Context Menu ━━━

  void _showContextMenu(Map<String, dynamic> company) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                _buildContextMenuItem(
                  icon: Icons.edit_rounded,
                  label: 'Edit Company',
                  onTap: () {
                    Navigator.pop(ctx);
                    _showEditCompanySheet(company);
                  },
                ),
                if ((company['contact'] ?? '').toString().isNotEmpty)
                  _buildContextMenuItem(
                    icon: Icons.phone_rounded,
                    label: 'Call ${company['contact']}',
                    onTap: () {
                      Navigator.pop(ctx);
                      // TODO: Implement call action
                    },
                  ),
                _buildContextMenuItem(
                  icon: Icons.delete_rounded,
                  label: 'Delete',
                  color: Colors.red,
                  onTap: () {
                    Navigator.pop(ctx);
                    _companyNameController.text = company['companyName'] ?? '';
                    _editingCompanyId = company['id'];
                    _editingCompanyLocalId = company['localId'] as int?;
                    _isEditing = true;
                    _deleteCompany(context, setState);
                  },
                ),
              ],
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
    Color? color,
  }) {
    return ListTile(
      leading: Icon(icon, color: color ?? const Color(0xFF1B4D3E)),
      title: Text(
        label,
        style: TextStyle(
          fontFamily: 'Literata',
          fontWeight: FontWeight.w600,
          color: color ?? Colors.grey[800],
        ),
      ),
      onTap: onTap,
    );
  }

  // ━━━ BUILD ━━━

  @override
  Widget build(BuildContext context) {
    _sessionManager.resetSession();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: widget.isEmbedded ? null : _buildAppBar(),
      floatingActionButton: _buildFAB(),
      body: SlideTransition(
        position: _offsetAnimation,
        child: FadeTransition(
          opacity: _opacityAnimation,
          child: Column(
            children: [
              // Summary widget
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: CompanySummaryWidget(
                  companies: _companies,
                  searchQuery: _searchQuery,
                ),
              ),
              // Filter widget
              Padding(
                padding: const EdgeInsets.all(16),
                child: CompanyFilterWidget(
                  searchQuery: _searchQuery,
                  onSearchChanged: (q) => setState(() => _searchQuery = q),
                  sortField: _sortField,
                  onSortFieldChanged: (f) => setState(() => _sortField = f),
                  sortAscending: _sortAscending,
                  onSortDirectionToggle: () =>
                      setState(() => _sortAscending = !_sortAscending),
                ),
              ),
              // Company list
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: CompanyListWidget(
                    companies: _companies,
                    isLoading: _isLoading,
                    searchQuery: _searchQuery,
                    sortField: _sortField,
                    sortAscending: _sortAscending,
                    onRefresh: _fetchFromFirebase,
                    onCompanyTap: _showEditCompanySheet,
                    onCompanyLongPress: _showContextMenu,
                    emptyTitle: _localizations.noCompaniesYet,
                    emptySubtitle: _localizations.createFirstCompany,
                    noResultsTitle: _localizations.noResultsFound,
                    noResultsSubtitle: _localizations.tryDifferentSearch,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return PreferredSize(
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
              color: const Color(0xFF1B4D3E).withValues(alpha: 0.2),
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
                    Navigator.of(context).pop();
                  },
                  child: Icon(
                    Icons.arrow_back_rounded,
                    color: Colors.white.withValues(alpha: 0.9),
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
                        _localizations.myCompanies,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Literata',
                          height: 1.2,
                        ),
                      ),
                      Text(
                        _localizations.manageYourBusinesses,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
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
    );
  }

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
            color: const Color(0xFF1B4D3E).withValues(alpha: 0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: FloatingActionButton(
        onPressed: _showAddCompanySheet,
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

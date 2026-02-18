import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/services/session_manager.dart';
import '../../../../core/services/language_service.dart';
import '../../../../core/services/dashboard_refresh_service.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../data/datasources/supplier_cache_datasource.dart';
import '../../offline/controllers/supplier_offline_controller.dart';
import '../../offline/entities/supplier_entity.dart';
import '../../data/services/supplier_sync_service.dart';
import '../widgets/supplier_summary_widget.dart';
import '../widgets/supplier_filter_widget.dart';
import '../widgets/supplier_list_widget.dart';

class EnhancedSupplierPage extends StatefulWidget {
  final bool isEmbedded;

  const EnhancedSupplierPage({super.key, this.isEmbedded = false});

  @override
  State<EnhancedSupplierPage> createState() => _EnhancedSupplierPageState();
}

class _EnhancedSupplierPageState extends State<EnhancedSupplierPage>
    with SingleTickerProviderStateMixin {
  // Animation
  late AnimationController _animController;
  late Animation<Offset> _offsetAnimation;
  late Animation<double> _opacityAnimation;

  // Form controllers
  final _firstNameController = TextEditingController();
  final _middleNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _supplierCodeController = TextEditingController();
  final _contactController = TextEditingController();
  final _addressController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  // State
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isEditing = false;
  String? _editingSupplierId;
  int? _editingSupplierLocalId;
  List<Map<String, dynamic>> _suppliers = [];
  String _searchQuery = '';
  SupplierSortField _sortField = SupplierSortField.name;
  bool _sortAscending = true;
  bool _isNavigatingAway = false;

  // Isar stream for real-time updates
  StreamSubscription<List<SupplierEntity>>? _supplierStreamSub;
  // Firestore stream for cross-device real-time sync
  StreamSubscription<QuerySnapshot>? _firestoreStreamSub;

  // Services
  final _auth = FirebaseAuth.instance;
  late final FirebaseFirestore _firestore;
  late AppLocalizations _localizations;
  late SessionManager _sessionManager;
  final _cacheDataSource = SupplierCacheDataSource();

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
    _supplierStreamSub?.cancel();
    _firestoreStreamSub?.cancel();
    _firstNameController.dispose();
    _middleNameController.dispose();
    _lastNameController.dispose();
    _supplierCodeController.dispose();
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
    final offlineCtrl = SupplierOfflineController.instance;
    _supplierStreamSub = offlineCtrl.watchAllSuppliers().listen(
      (entities) {
        if (!mounted || _isNavigatingAway) return;
        final mapped = entities.map(_entityToMap).toList();
        setState(() {
          _suppliers = mapped;
          _isLoading = false;
        });
        debugPrint('[EnhancedSupplier] Isar stream: ${mapped.length} suppliers');
      },
      onError: (e) {
        debugPrint('[EnhancedSupplier] Isar stream error: $e');
      },
    );
  }

  Map<String, dynamic> _entityToMap(SupplierEntity e) {
    return {
      'id': e.serverId ?? 'local_${e.id}',
      'localId': e.id,
      'firstName': e.firstName,
      'middleName': e.middleName,
      'lastName': e.lastName,
      'supplierCode': e.supplierCode,
      'contact': e.contact,
      'address': e.address,
      'isActive': e.isActive,
      'isSynced': e.syncStatus == SupplierSyncStatus.synced,
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
          .collection('suppliers')
          .orderBy('createdAt', descending: true)
          .get();

      if (!mounted || _isNavigatingAway) return;

      final freshSuppliers = snapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data()})
          .toList();

      // Import to Isar
      await SupplierOfflineController.instance.importFromServer(freshSuppliers);

      // Trigger background sync
      SupplierSyncService.instance.syncNow();

      // Cache for next time
      _cacheDataSource.saveSuppliers(freshSuppliers);
    } catch (e) {
      debugPrint('[EnhancedSupplier] Firebase fetch error: $e');
    }
  }

  // ━━━ DATA: Firestore Stream (cross-device sync) ━━━

  void _setupFirestoreStream() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    _firestoreStreamSub = _firestore
        .collection('users')
        .doc(currentUser.uid)
        .collection('suppliers')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen(
      (snapshot) async {
        if (!mounted || _isNavigatingAway) return;

        final freshSuppliers = snapshot.docs
            .map((doc) => {'id': doc.id, ...doc.data()})
            .toList();

        await SupplierOfflineController.instance.importFromServer(freshSuppliers);
        _cacheDataSource.saveSuppliers(freshSuppliers);
      },
      onError: (e) {
        debugPrint('[EnhancedSupplier] Firestore stream error: $e');
      },
    );
  }

  // ━━━ CRUD: Add/Edit/Delete ━━━

  void _clearForm() {
    _firstNameController.clear();
    _middleNameController.clear();
    _lastNameController.clear();
    _supplierCodeController.clear();
    _contactController.clear();
    _addressController.clear();
    _editingSupplierId = null;
    _editingSupplierLocalId = null;
    _isEditing = false;
  }

  Future<String> _generateNextSupplierCode() async {
    try {
      if (_suppliers.isEmpty) return '1';

      int maxCode = 0;
      for (var supplier in _suppliers) {
        final code = supplier['supplierCode'] as String?;
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

  void _showAddSupplierSheet() async {
    _clearForm();
    final nextCode = await _generateNextSupplierCode();
    _supplierCodeController.text = nextCode;

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _buildSupplierFormSheet(ctx),
    );
  }

  void _showEditSupplierSheet(Map<String, dynamic> supplier) {
    _firstNameController.text = supplier['firstName'] ?? '';
    _middleNameController.text = supplier['middleName'] ?? '';
    _lastNameController.text = supplier['lastName'] ?? '';
    _supplierCodeController.text = supplier['supplierCode'] ?? '';
    _contactController.text = supplier['contact'] ?? '';
    _addressController.text = supplier['address'] ?? '';
    _editingSupplierId = supplier['id'];
    _editingSupplierLocalId = supplier['localId'] as int?;
    _isEditing = true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _buildSupplierFormSheet(ctx),
    );
  }

  Widget _buildSupplierFormSheet(BuildContext ctx) {
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
                              ? _localizations.editSupplier
                              : _localizations.addNewSupplier,
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
                      label: _localizations.firstName,
                      controller: _firstNameController,
                      icon: Icons.person_outline_rounded,
                      isRequired: true,
                    ),
                    const SizedBox(height: 16),
                    _buildInputField(
                      label: _localizations.middleName,
                      controller: _middleNameController,
                      icon: Icons.person_outline_rounded,
                    ),
                    const SizedBox(height: 16),
                    _buildInputField(
                      label: _localizations.lastName,
                      controller: _lastNameController,
                      icon: Icons.person_outline_rounded,
                      isRequired: true,
                    ),
                    const SizedBox(height: 16),
                    _buildInputField(
                      label: _localizations.supplierCode,
                      controller: _supplierCodeController,
                      icon: Icons.qr_code_rounded,
                      isRequired: true,
                      isReadOnly: !_isEditing,
                    ),
                    const SizedBox(height: 16),
                    _buildInputField(
                      label: _localizations.contactNumber,
                      controller: _contactController,
                      icon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                      isRequired: true,
                      maxLength: 10,
                    ),
                    const SizedBox(height: 16),
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
                            onPressed: _isSaving
                                ? null
                                : () => _saveSupplier(ctx, setSheetState),
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
                                        : _localizations.addSupplier,
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
                                  : () => _deleteSupplier(ctx, setSheetState),
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
    int? maxLength,
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
          maxLength: maxLength,
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
            counterText: '',
          ),
          validator: (value) {
            if (isRequired && (value == null || value.isEmpty)) {
              return '$label ${_localizations.isRequired}';
            }
            if (label == _localizations.contactNumber &&
                value != null &&
                value.isNotEmpty &&
                value.length != 10) {
              return 'Contact number must be exactly 10 digits';
            }
            return null;
          },
        ),
      ],
    );
  }

  Future<void> _saveSupplier(
    BuildContext ctx,
    void Function(void Function()) setSheetState,
  ) async {
    if (!_formKey.currentState!.validate()) return;

    setSheetState(() => _isSaving = true);

    try {
      final offlineCtrl = SupplierOfflineController.instance;

      if (_isEditing) {
        int? localId = _editingSupplierLocalId;
        if (localId == null && _editingSupplierId != null) {
          final existing = await offlineCtrl.getSupplierByServerId(_editingSupplierId!);
          localId = existing?.id;
        }

        if (localId != null) {
          await offlineCtrl.updateSupplier(
            id: localId,
            firstName: _firstNameController.text,
            middleName: _middleNameController.text,
            lastName: _lastNameController.text,
            supplierCode: _supplierCodeController.text.trim(),
            contact: _contactController.text,
            address: _addressController.text,
          );
        } else {
          throw Exception('Supplier not found');
        }
        DashboardRefreshService.instance.notifyDataChanged(DataChangeType.supplier);
      } else {
        await offlineCtrl.addSupplier(
          firstName: _firstNameController.text,
          middleName: _middleNameController.text,
          lastName: _lastNameController.text,
          supplierCode: _supplierCodeController.text.trim(),
          contact: _contactController.text,
          address: _addressController.text,
        );
        DashboardRefreshService.instance.notifyDataChanged(DataChangeType.supplier);
      }

      SupplierSyncService.instance.syncNow();

      if (mounted && ctx.mounted) {
        Navigator.pop(ctx);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEditing
                  ? _localizations.supplierUpdatedSuccessfully
                  : _localizations.supplierAddedSuccessfully,
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

  Future<void> _deleteSupplier(
    BuildContext ctx,
    void Function(void Function()) setSheetState,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Supplier'),
        content: const Text('Are you sure you want to delete this supplier?'),
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
      final offlineCtrl = SupplierOfflineController.instance;
      int? localId = _editingSupplierLocalId;

      if (localId == null && _editingSupplierId != null) {
        final existing = await offlineCtrl.getSupplierByServerId(_editingSupplierId!);
        localId = existing?.id;
      }

      if (localId != null) {
        await offlineCtrl.deleteSupplier(localId);
      } else {
        throw Exception('Supplier not found');
      }

      SupplierSyncService.instance.syncNow();
      DashboardRefreshService.instance.notifyDataChanged(DataChangeType.supplier);

      if (mounted && ctx.mounted) {
        Navigator.pop(ctx);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_localizations.supplierDeletedSuccessfully),
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

  void _showContextMenu(Map<String, dynamic> supplier) {
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
                  label: 'Edit Supplier',
                  onTap: () {
                    Navigator.pop(ctx);
                    _showEditSupplierSheet(supplier);
                  },
                ),
                _buildContextMenuItem(
                  icon: Icons.phone_rounded,
                  label: 'Call ${supplier['contact'] ?? ''}',
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
                    _firstNameController.text = supplier['firstName'] ?? '';
                    _editingSupplierId = supplier['id'];
                    _editingSupplierLocalId = supplier['localId'] as int?;
                    _isEditing = true;
                    _deleteSupplier(context, setState);
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
                child: SupplierSummaryWidget(
                  suppliers: _suppliers,
                  searchQuery: _searchQuery,
                ),
              ),
              // Filter widget
              Padding(
                padding: const EdgeInsets.all(16),
                child: SupplierFilterWidget(
                  searchQuery: _searchQuery,
                  onSearchChanged: (q) => setState(() => _searchQuery = q),
                  sortField: _sortField,
                  onSortFieldChanged: (f) => setState(() => _sortField = f),
                  sortAscending: _sortAscending,
                  onSortDirectionToggle: () =>
                      setState(() => _sortAscending = !_sortAscending),
                ),
              ),
              // Supplier list
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: SupplierListWidget(
                    suppliers: _suppliers,
                    isLoading: _isLoading,
                    searchQuery: _searchQuery,
                    sortField: _sortField,
                    sortAscending: _sortAscending,
                    onRefresh: _fetchFromFirebase,
                    onSupplierTap: _showEditSupplierSheet,
                    onSupplierLongPress: _showContextMenu,
                    emptyTitle: _localizations.noSuppliersYetPage,
                    emptySubtitle: _localizations.createFirstSupplier,
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
                        _localizations.mySuppliers,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Literata',
                          height: 1.2,
                        ),
                      ),
                      Text(
                        _localizations.manageYourVendors,
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
        onPressed: _showAddSupplierSheet,
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

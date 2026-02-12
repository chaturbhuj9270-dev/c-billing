import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../offline/controllers/purchase_offline_controller.dart';
import '../../offline/entities/purchase_entity.dart';
import '../../data/services/purchase_sync_service.dart';
import '../../../product/offline/controllers/product_offline_controller.dart';

/// Purchase History Screen with bulk editable quantity and offline-first support
/// Displays purchase records in a paginated table with search and filter capabilities
class PurchaseHistoryScreen extends StatefulWidget {
  const PurchaseHistoryScreen({super.key});

  @override
  State<PurchaseHistoryScreen> createState() => _PurchaseHistoryScreenState();
}

class _PurchaseHistoryScreenState extends State<PurchaseHistoryScreen> {
  // Controllers
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  Timer? _debounceTimer;

  // Data
  List<PurchaseEntity> _purchases = [];
  List<PurchaseEntity> _filteredPurchases = [];
  Map<int, int> _editedQuantities = {}; // Map<purchaseId, addedQty>
  Map<String, int> _productCurrentStock = {}; // Map<productId, currentStock>
  
  // Filter state
  DateTime? _startDate;
  DateTime? _endDate;
  String? _selectedSupplierId;
  bool? _syncedFilter; // null = all, true = synced, false = pending
  List<Map<String, String>> _suppliers = [];
  
  // UI state
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isOnline = false;
  int _rowsPerPage = 10;
  int _currentPage = 0;

  // Date formatter
  final _dateFormat = DateFormat('dd/MM/yyyy');
  final _dateTimeFormat = DateFormat('dd/MM/yyyy HH:mm');

  @override
  void initState() {
    super.initState();
    _checkConnectivityAndLoad();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  /// Check connectivity and trigger sync if online
  Future<void> _checkConnectivityAndLoad() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      final isOnline = connectivityResult.isNotEmpty && 
          !connectivityResult.contains(ConnectivityResult.none);
      
      if (mounted) {
        setState(() => _isOnline = isOnline);
      }
      
      // If online, trigger sync first then load data
      if (isOnline) {
        debugPrint('[PurchaseHistory] Online - triggering sync before load');
        await PurchaseSyncService.instance.syncNow();
      }
    } catch (e) {
      debugPrint('[PurchaseHistory] Connectivity check error: $e');
    }
    
    // Load data from local database (works both online and offline)
    await _loadData();
  }

  /// Load initial data from offline controller (offline-first)
  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      // Load purchases from local Isar database
      final purchases = await PurchaseOfflineController.instance.getAllPurchases();
      
      // Load suppliers for filter
      final suppliers = await PurchaseOfflineController.instance.getUniqueSuppliers();
      
      // Load product stock levels
      final products = await ProductOfflineController.instance.getAllProducts();
      final stockMap = <String, int>{};
      for (final product in products) {
        final productId = product.serverId ?? product.id.toString();
        stockMap[productId] = product.currentStock;
      }
      
      if (mounted) {
        setState(() {
          _purchases = purchases;
          _filteredPurchases = purchases;
          _suppliers = suppliers;
          _productCurrentStock = stockMap;
          _isLoading = false;
        });
      }
      
      debugPrint('[PurchaseHistory] Loaded ${purchases.length} purchases (online: $_isOnline)');
    } catch (e) {
      debugPrint('[PurchaseHistory] Error loading data: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        _showSnackBar('Error loading purchases: $e', isError: true);
      }
    }
  }

  /// Handle search with debounce
  void _onSearchChanged() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      _applyFilters();
    });
  }

  /// Apply all filters to purchases
  Future<void> _applyFilters() async {
    final results = await PurchaseOfflineController.instance.getFilteredPurchases(
      searchQuery: _searchController.text,
      startDate: _startDate,
      endDate: _endDate,
      supplierId: _selectedSupplierId,
      syncedOnly: _syncedFilter == true ? true : null,
      pendingOnly: _syncedFilter == false ? true : null,
    );
    
    if (mounted) {
      setState(() {
        _filteredPurchases = results;
        _currentPage = 0; // Reset to first page
      });
    }
  }

  /// Clear all filters
  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _startDate = null;
      _endDate = null;
      _selectedSupplierId = null;
      _syncedFilter = null;
      _filteredPurchases = _purchases;
      _currentPage = 0;
    });
  }

  /// Show filter bottom sheet
  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildFilterSheet(),
    );
  }

  /// Build filter bottom sheet
  Widget _buildFilterSheet() {
    return StatefulBuilder(
      builder: (context, setSheetState) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Filter Purchases',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Literata',
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      _clearFilters();
                      Navigator.pop(context);
                    },
                    child: const Text('Clear All'),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              
              // Date Range
              const Text(
                'Date Range',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildDateButton(
                      label: _startDate != null 
                          ? _dateFormat.format(_startDate!) 
                          : 'Start Date',
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: _startDate ?? DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                        );
                        if (date != null) {
                          setSheetState(() => _startDate = date);
                          setState(() => _startDate = date);
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildDateButton(
                      label: _endDate != null 
                          ? _dateFormat.format(_endDate!) 
                          : 'End Date',
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: _endDate ?? DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                        );
                        if (date != null) {
                          setSheetState(() => _endDate = date);
                          setState(() => _endDate = date);
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Supplier Filter
              const Text(
                'Supplier',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String?>(
                value: _selectedSupplierId,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                hint: const Text('All Suppliers'),
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('All Suppliers'),
                  ),
                  ..._suppliers.map((s) => DropdownMenuItem<String?>(
                    value: s['id'],
                    child: Text(s['name'] ?? '-'),
                  )),
                ],
                onChanged: (value) {
                  setSheetState(() => _selectedSupplierId = value);
                  setState(() => _selectedSupplierId = value);
                },
              ),
              const SizedBox(height: 16),
              
              // Sync Status Filter
              const Text(
                'Sync Status',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildFilterChip(
                    label: 'All',
                    isSelected: _syncedFilter == null,
                    onTap: () {
                      setSheetState(() => _syncedFilter = null);
                      setState(() => _syncedFilter = null);
                    },
                  ),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    label: 'Synced',
                    isSelected: _syncedFilter == true,
                    onTap: () {
                      setSheetState(() => _syncedFilter = true);
                      setState(() => _syncedFilter = true);
                    },
                  ),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    label: 'Pending',
                    isSelected: _syncedFilter == false,
                    onTap: () {
                      setSheetState(() => _syncedFilter = false);
                      setState(() => _syncedFilter = false);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              // Apply Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _applyFilters();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1B4D3E),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Apply Filters',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              SizedBox(height: MediaQuery.of(context).viewInsets.bottom + 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDateButton({required String label, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today, size: 18, color: Colors.grey[600]),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(color: Colors.grey[700])),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1B4D3E) : Colors.grey[100],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF1B4D3E) : Colors.grey[300]!,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[700],
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  /// Show purchase details bottom sheet
  void _showPurchaseDetails(PurchaseEntity purchase) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Purchase Details',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Literata',
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 12),
            
            // Product Name
            _buildDetailRow('Product', purchase.productName),
            _buildDetailRow('Quantity', '${purchase.quantity} ${purchase.unit}'),
            _buildDetailRow('Purchase Price', '₹${purchase.purchasePrice.toStringAsFixed(2)}'),
            _buildDetailRow('Sales Price', '₹${purchase.salesPrice.toStringAsFixed(2)}'),
            _buildDetailRow('Total Amount', '₹${purchase.totalAmount.toStringAsFixed(2)}'),
            _buildDetailRow('Supplier', purchase.supplierName ?? '-'),
            _buildDetailRow('Company', purchase.companyName ?? '-'),
            if (purchase.productionDate != null)
              _buildDetailRow('Production Date', _dateFormat.format(purchase.productionDate!)),
            if (purchase.expiryDate != null)
              _buildDetailRow('Expiry Date', _dateFormat.format(purchase.expiryDate!)),
            if (purchase.warrantyMonths != null)
              _buildDetailRow('Warranty', '${purchase.warrantyMonths} months'),
            _buildDetailRow('Created', _dateTimeFormat.format(purchase.createdAt)),
            _buildDetailRow('Last Updated', _dateTimeFormat.format(purchase.updatedAt)),
            _buildDetailRow(
              'Status',
              purchase.syncStatus == PurchaseSyncStatus.synced ? 'Synced' : 'Pending Sync',
              valueColor: purchase.syncStatus == PurchaseSyncStatus.synced 
                  ? Colors.green 
                  : Colors.orange,
            ),
            if (purchase.notes != null && purchase.notes!.isNotEmpty)
              _buildDetailRow('Notes', purchase.notes!),
            
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: valueColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Show bulk save confirmation dialog
  void _showBulkSaveDialog() {
    if (_editedQuantities.isEmpty) {
      _showSnackBar('No changes to save');
      return;
    }

    final editedPurchases = _filteredPurchases
        .where((p) => _editedQuantities.containsKey(p.id))
        .toList();

    final selectedIds = <int>{...editedPurchases.map((p) => p.id)};

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text(
              'Confirm Stock Update',
              style: TextStyle(fontFamily: 'Literata'),
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${editedPurchases.length} product(s) will be updated:',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 12),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 300),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: editedPurchases.length,
                      itemBuilder: (context, index) {
                        final purchase = editedPurchases[index];
                        final addedQty = _editedQuantities[purchase.id] ?? 0;
                        final oldQty = purchase.quantity;
                        final newQty = oldQty + addedQty;
                        final isSelected = selectedIds.contains(purchase.id);
                        
                        return CheckboxListTile(
                          value: isSelected,
                          onChanged: (value) {
                            setDialogState(() {
                              if (value == true) {
                                selectedIds.add(purchase.id);
                              } else {
                                selectedIds.remove(purchase.id);
                              }
                            });
                          },
                          title: Text(
                            purchase.productName,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(
                            'Old: $oldQty → Add: +$addedQty → New: $newQty',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                          controlAffinity: ListTileControlAffinity.leading,
                          dense: true,
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: selectedIds.isEmpty
                    ? null
                    : () {
                        Navigator.pop(context);
                        _saveBulkChanges(selectedIds.toList());
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1B4D3E),
                ),
                child: const Text('Save Changes', style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Save bulk changes to database
  Future<void> _saveBulkChanges(List<int> selectedIds) async {
    setState(() => _isSaving = true);

    try {
      // Prepare updates
      final updates = selectedIds
          .where((id) => _editedQuantities.containsKey(id))
          .map((id) => {
                'id': id,
                'addedQty': _editedQuantities[id]!,
              })
          .toList();

      // Update purchases in database
      await PurchaseOfflineController.instance.bulkUpdateQuantities(updates);

      // Also update product stock
      for (final id in selectedIds) {
        final purchase = _filteredPurchases.firstWhere((p) => p.id == id);
        final addedQty = _editedQuantities[id] ?? 0;
        
        if (purchase.productId.isNotEmpty) {
          await ProductOfflineController.instance.incrementStock(
            purchase.productId,
            addedQty,
          );
        }
      }

      // Clear edited quantities for saved items
      for (final id in selectedIds) {
        _editedQuantities.remove(id);
      }

      // Trigger sync if available
      PurchaseSyncService.instance.syncNow();

      // Reload data
      await _loadData();

      _showSnackBar('Successfully updated ${selectedIds.length} purchase(s)');
    } catch (e) {
      debugPrint('[PurchaseHistory] Error saving changes: $e');
      _showSnackBar('Error saving changes: $e', isError: true);
    } finally {
      setState(() => _isSaving = false);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : const Color(0xFF1B4D3E),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: _buildAppBar(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF1B4D3E)))
          : Column(
              children: [
                _buildSearchBar(),
                _buildActiveFilters(),
                Expanded(child: _buildDataTable()),
              ],
            ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    final hasChanges = _editedQuantities.isNotEmpty;
    
    return AppBar(
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              'Purchase History',
              style: TextStyle(
                fontFamily: 'Literata',
                fontWeight: FontWeight.w600,
                color: Colors.white,
                fontSize: MediaQuery.of(context).size.width < 360 ? 16 : 18,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 6),
          // Connectivity indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
            decoration: BoxDecoration(
              color: _isOnline ? Colors.green.withValues(alpha: 0.2) : Colors.orange.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _isOnline ? Icons.cloud_done : Icons.cloud_off,
              size: 14,
              color: _isOnline ? Colors.greenAccent : Colors.orangeAccent,
            ),
          ),
        ],
      ),
      backgroundColor: const Color(0xFF1B4D3E),
      elevation: 0,
      iconTheme: const IconThemeData(color: Colors.white),
      actions: [
        // Filter button
        IconButton(
          onPressed: _showFilterSheet,
          icon: const Icon(Icons.filter_list),
          tooltip: 'Filter',
        ),
        // Save button (visible when there are changes)
        if (hasChanges)
          Stack(
            children: [
              IconButton(
                onPressed: _isSaving ? null : _showBulkSaveDialog,
                icon: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.save),
                tooltip: 'Save Changes',
              ),
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.orange,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '${_editedQuantities.length}',
                    style: const TextStyle(
                      fontSize: 10,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        // Refresh button
        IconButton(
          onPressed: _checkConnectivityAndLoad,
          icon: const Icon(Icons.refresh),
          tooltip: 'Refresh',
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search by product or supplier...',
          prefixIcon: const Icon(Icons.search, color: Color(0xFF1B4D3E)),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  onPressed: () {
                    _searchController.clear();
                    _applyFilters();
                  },
                  icon: const Icon(Icons.clear),
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF1B4D3E), width: 2),
          ),
          filled: true,
          fillColor: Colors.grey[50],
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildActiveFilters() {
    final hasFilters = _startDate != null ||
        _endDate != null ||
        _selectedSupplierId != null ||
        _syncedFilter != null;

    if (!hasFilters) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.white,
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          if (_startDate != null || _endDate != null)
            _buildFilterTag(
              'Date: ${_startDate != null ? _dateFormat.format(_startDate!) : '...'} - ${_endDate != null ? _dateFormat.format(_endDate!) : '...'}',
              onRemove: () {
                setState(() {
                  _startDate = null;
                  _endDate = null;
                });
                _applyFilters();
              },
            ),
          if (_selectedSupplierId != null)
            _buildFilterTag(
              'Supplier: ${_suppliers.firstWhere((s) => s['id'] == _selectedSupplierId, orElse: () => {'name': '-'})['name']}',
              onRemove: () {
                setState(() => _selectedSupplierId = null);
                _applyFilters();
              },
            ),
          if (_syncedFilter != null)
            _buildFilterTag(
              _syncedFilter! ? 'Synced' : 'Pending',
              onRemove: () {
                setState(() => _syncedFilter = null);
                _applyFilters();
              },
            ),
        ],
      ),
    );
  }

  Widget _buildFilterTag(String label, {required VoidCallback onRemove}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF1B4D3E).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF1B4D3E),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onRemove,
            child: const Icon(
              Icons.close,
              size: 16,
              color: Color(0xFF1B4D3E),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataTable() {
    if (_filteredPurchases.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No purchases found',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your filters',
              style: TextStyle(color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    // Calculate pagination
    final startIndex = _currentPage * _rowsPerPage;
    final endIndex = (startIndex + _rowsPerPage).clamp(0, _filteredPurchases.length);
    final paginatedPurchases = _filteredPurchases.sublist(startIndex, endIndex);
    final totalPages = (_filteredPurchases.length / _rowsPerPage).ceil();

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            controller: _scrollController,
            scrollDirection: Axis.horizontal,
            child: SingleChildScrollView(
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(const Color(0xFFE8F5E9)),
                dataRowMinHeight: 56,
                dataRowMaxHeight: 72,
                columnSpacing: 20,
                horizontalMargin: 16,
                columns: const [
                  DataColumn(label: Text('Product', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Current Stock', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Add Qty', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Price', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Supplier', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Date', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Updated', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
                ],
                rows: paginatedPurchases.map((purchase) => _buildDataRow(purchase)).toList(),
              ),
            ),
          ),
        ),
        // Pagination controls
        _buildPaginationControls(totalPages),
      ],
    );
  }

  DataRow _buildDataRow(PurchaseEntity purchase) {
    final currentStock = _productCurrentStock[purchase.productId] ?? 0;
    final editedQty = _editedQuantities[purchase.id];
    final isEdited = editedQty != null;
    final isSynced = purchase.syncStatus == PurchaseSyncStatus.synced;

    return DataRow(
      color: WidgetStateProperty.resolveWith<Color?>((states) {
        if (isEdited) return Colors.amber.withValues(alpha: 0.1);
        return null;
      }),
      onSelectChanged: (_) => _showPurchaseDetails(purchase),
      cells: [
        // Product Name
        DataCell(
          SizedBox(
            width: 150,
            child: Text(
              purchase.productName,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ),
        // Current Stock
        DataCell(
          Text(
            currentStock.toString(),
            style: TextStyle(
              color: currentStock < 10 ? Colors.red : Colors.black87,
              fontWeight: currentStock < 10 ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
        // Add Purchase Qty (Editable)
        DataCell(
          SizedBox(
            width: 80,
            child: TextFormField(
              key: ValueKey('qty_${purchase.id}'),
              initialValue: editedQty?.toString() ?? '',
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                hintText: '-',
                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: isEdited ? Colors.orange : Colors.grey[300]!,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFF1B4D3E), width: 2),
                ),
                filled: true,
                fillColor: isEdited ? Colors.amber.withValues(alpha: 0.1) : Colors.white,
              ),
              onChanged: (value) {
                final qty = int.tryParse(value);
                if (qty != null && qty > 0) {
                  _editedQuantities[purchase.id] = qty;
                } else {
                  _editedQuantities.remove(purchase.id);
                }
                // Update UI without triggering rebuild during typing
              },
              onFieldSubmitted: (_) {
                // Rebuild only when done editing
                setState(() {});
              },
              onTapOutside: (_) {
                // Rebuild when tapping outside to show updated state
                setState(() {});
              },
            ),
          ),
        ),
        // Purchase Price
        DataCell(Text('₹${purchase.purchasePrice.toStringAsFixed(2)}')),
        // Supplier
        DataCell(
          SizedBox(
            width: 120,
            child: Text(
              purchase.supplierName ?? '-',
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        // Purchase Date
        DataCell(Text(_dateFormat.format(purchase.createdAt))),
        // Last Updated
        DataCell(Text(_dateFormat.format(purchase.updatedAt))),
        // Sync Status
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isSynced ? Colors.green.withValues(alpha: 0.1) : Colors.orange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isSynced ? Icons.cloud_done : Icons.cloud_upload,
                  size: 14,
                  color: isSynced ? Colors.green : Colors.orange,
                ),
                const SizedBox(width: 4),
                Text(
                  isSynced ? 'Synced' : 'Pending',
                  style: TextStyle(
                    fontSize: 12,
                    color: isSynced ? Colors.green : Colors.orange,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPaginationControls(int totalPages) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Rows per page selector
          Row(
            children: [
              const Text('Rows per page:'),
              const SizedBox(width: 8),
              DropdownButton<int>(
                value: _rowsPerPage,
                items: [10, 25, 50, 100].map((n) => DropdownMenuItem(
                  value: n,
                  child: Text('$n'),
                )).toList(),
                onChanged: (value) {
                  setState(() {
                    _rowsPerPage = value ?? 10;
                    _currentPage = 0;
                  });
                },
                underline: const SizedBox.shrink(),
              ),
            ],
          ),
          // Page info
          Text(
            '${_currentPage * _rowsPerPage + 1}-${((_currentPage + 1) * _rowsPerPage).clamp(0, _filteredPurchases.length)} of ${_filteredPurchases.length}',
            style: TextStyle(color: Colors.grey[600]),
          ),
          // Page navigation
          Row(
            children: [
              IconButton(
                onPressed: _currentPage > 0
                    ? () => setState(() => _currentPage--)
                    : null,
                icon: const Icon(Icons.chevron_left),
              ),
              Text('${_currentPage + 1} / $totalPages'),
              IconButton(
                onPressed: _currentPage < totalPages - 1
                    ? () => setState(() => _currentPage++)
                    : null,
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

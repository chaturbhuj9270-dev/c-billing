import 'package:flutter/material.dart';
import 'dart:ui';

/// Filter options for purchase list
enum PurchaseDateFilter {
  all,
  today,
}

/// Sticky filter widget for purchase list
/// Features: All/Today toggle, Supplier searchable dropdown
class PurchaseFilterWidget extends StatefulWidget {
  final PurchaseDateFilter selectedDateFilter;
  final String? selectedSupplierId;
  final List<Map<String, dynamic>> suppliers;
  final ValueChanged<PurchaseDateFilter> onDateFilterChanged;
  final ValueChanged<String?> onSupplierChanged;
  final String allLabel;
  final String todayLabel;
  final String supplierLabel;

  const PurchaseFilterWidget({
    super.key,
    required this.selectedDateFilter,
    required this.selectedSupplierId,
    required this.suppliers,
    required this.onDateFilterChanged,
    required this.onSupplierChanged,
    this.allLabel = 'All',
    this.todayLabel = 'Today',
    this.supplierLabel = 'Supplier',
  });

  @override
  State<PurchaseFilterWidget> createState() => _PurchaseFilterWidgetState();
}

class _PurchaseFilterWidgetState extends State<PurchaseFilterWidget> {
  final _supplierSearchController = TextEditingController();

  @override
  void dispose() {
    _supplierSearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date filter row
          Row(
            children: [
              // All/Today toggle buttons
              Expanded(
                child: Row(
                  children: [
                    _buildFilterChip(
                      label: widget.allLabel,
                      isSelected: widget.selectedDateFilter == PurchaseDateFilter.all,
                      onTap: () => widget.onDateFilterChanged(PurchaseDateFilter.all),
                      icon: Icons.list_alt_rounded,
                    ),
                    const SizedBox(width: 8),
                    _buildFilterChip(
                      label: widget.todayLabel,
                      isSelected: widget.selectedDateFilter == PurchaseDateFilter.today,
                      onTap: () => widget.onDateFilterChanged(PurchaseDateFilter.today),
                      icon: Icons.today_rounded,
                    ),
                  ],
                ),
              ),
              
              // Supplier dropdown
              _buildSupplierDropdown(),
            ],
          ),
          
          // Show active filters indicator
          if (widget.selectedDateFilter == PurchaseDateFilter.today || 
              widget.selectedSupplierId != null) ...[
            const SizedBox(height: 10),
            _buildActiveFiltersRow(),
          ],
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required IconData icon,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected 
              ? const Color(0xFF1B4D3E) 
              : Colors.grey[100],
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected 
                ? const Color(0xFF1B4D3E) 
                : Colors.grey[300]!,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.white : Colors.grey[600],
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Literata',
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: isSelected ? Colors.white : Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSupplierDropdown() {
    final selectedSupplier = widget.selectedSupplierId != null
        ? widget.suppliers.firstWhere(
            (s) => s['id'] == widget.selectedSupplierId,
            orElse: () => {},
          )
        : null;
    
    final displayText = selectedSupplier != null && selectedSupplier.isNotEmpty
        ? (selectedSupplier['fullName'] ?? selectedSupplier['firstName'] ?? 'Supplier')
        : widget.supplierLabel;
    
    return GestureDetector(
      onTap: () => _showSupplierPicker(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: widget.selectedSupplierId != null 
              ? const Color(0xFF1B4D3E).withOpacity(0.1)
              : Colors.grey[100],
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: widget.selectedSupplierId != null 
                ? const Color(0xFF1B4D3E)
                : Colors.grey[300]!,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.person_outline_rounded,
              size: 16,
              color: widget.selectedSupplierId != null 
                  ? const Color(0xFF1B4D3E)
                  : Colors.grey[600],
            ),
            const SizedBox(width: 6),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 100),
              child: Text(
                displayText,
                style: TextStyle(
                  fontFamily: 'Literata',
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: widget.selectedSupplierId != null 
                      ? const Color(0xFF1B4D3E)
                      : Colors.grey[700],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.arrow_drop_down_rounded,
              size: 20,
              color: widget.selectedSupplierId != null 
                  ? const Color(0xFF1B4D3E)
                  : Colors.grey[600],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveFiltersRow() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          Text(
            'Active: ',
            style: TextStyle(
              fontFamily: 'Literata',
              fontWeight: FontWeight.w500,
              fontSize: 11,
              color: Colors.grey[600],
            ),
          ),
          if (widget.selectedDateFilter == PurchaseDateFilter.today)
            _buildActiveFilterTag(
              label: widget.todayLabel,
              onRemove: () => widget.onDateFilterChanged(PurchaseDateFilter.all),
            ),
          if (widget.selectedSupplierId != null) ...[
            if (widget.selectedDateFilter == PurchaseDateFilter.today)
              const SizedBox(width: 6),
            _buildActiveFilterTag(
              label: _getSupplierName(widget.selectedSupplierId!),
              onRemove: () => widget.onSupplierChanged(null),
            ),
          ],
        ],
      ),
    );
  }

  String _getSupplierName(String supplierId) {
    final supplier = widget.suppliers.firstWhere(
      (s) => s['id'] == supplierId,
      orElse: () => {},
    );
    if (supplier.isEmpty) return 'Unknown';
    return supplier['fullName'] ?? supplier['firstName'] ?? 'Supplier';
  }

  Widget _buildActiveFilterTag({
    required String label,
    required VoidCallback onRemove,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF1B4D3E).withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: const Color(0xFF1B4D3E).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Literata',
              fontWeight: FontWeight.w500,
              fontSize: 11,
              color: Color(0xFF1B4D3E),
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onRemove,
            child: Icon(
              Icons.close_rounded,
              size: 14,
              color: const Color(0xFF1B4D3E).withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  void _showSupplierPicker(BuildContext context) {
    _supplierSearchController.clear();
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) {
          final query = _supplierSearchController.text.toLowerCase();
          final filteredSuppliers = query.isEmpty
              ? widget.suppliers
              : widget.suppliers.where((s) {
                  final name = (s['fullName'] ?? s['firstName'] ?? '').toLowerCase();
                  return name.contains(query);
                }).toList();

          return ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.7,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.95),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Handle
                    Container(
                      margin: const EdgeInsets.only(top: 12),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    
                    // Header
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Select Supplier',
                            style: TextStyle(
                              fontFamily: 'Literata',
                              fontWeight: FontWeight.w700,
                              fontSize: 18,
                              color: Color(0xFF1B4D3E),
                            ),
                          ),
                          if (widget.selectedSupplierId != null)
                            TextButton(
                              onPressed: () {
                                widget.onSupplierChanged(null);
                                Navigator.pop(context);
                              },
                              child: const Text(
                                'Clear',
                                style: TextStyle(
                                  fontFamily: 'Literata',
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                  color: Colors.red,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    
                    // Search field
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: TextField(
                        controller: _supplierSearchController,
                        onChanged: (_) => setSheetState(() {}),
                        decoration: InputDecoration(
                          hintText: 'Search supplier...',
                          hintStyle: TextStyle(color: Colors.grey[500]),
                          prefixIcon: Icon(Icons.search_rounded, color: Colors.grey[500]),
                          filled: true,
                          fillColor: Colors.grey[100],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 12),
                    
                    // Supplier list
                    Flexible(
                      child: filteredSuppliers.isEmpty
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.all(32),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.person_off_rounded,
                                      size: 48,
                                      color: Colors.grey[400],
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      'No suppliers found',
                                      style: TextStyle(
                                        fontFamily: 'Literata',
                                        fontWeight: FontWeight.w500,
                                        fontSize: 14,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : ListView.builder(
                              shrinkWrap: true,
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                              itemCount: filteredSuppliers.length,
                              itemBuilder: (context, index) {
                                final supplier = filteredSuppliers[index];
                                final isSelected = supplier['id'] == widget.selectedSupplierId;
                                final name = supplier['fullName'] ?? 
                                    '${supplier['firstName'] ?? ''} ${supplier['lastName'] ?? ''}'.trim();
                                
                                return GestureDetector(
                                  onTap: () {
                                    widget.onSupplierChanged(supplier['id']);
                                    Navigator.pop(context);
                                  },
                                  child: Container(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: isSelected 
                                          ? const Color(0xFF1B4D3E).withOpacity(0.1)
                                          : Colors.grey[50],
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: isSelected 
                                            ? const Color(0xFF1B4D3E)
                                            : Colors.grey[200]!,
                                        width: isSelected ? 1.5 : 1,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 40,
                                          height: 40,
                                          decoration: BoxDecoration(
                                            color: isSelected 
                                                ? const Color(0xFF1B4D3E)
                                                : Colors.grey[200],
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: Icon(
                                            Icons.person_rounded,
                                            color: isSelected 
                                                ? Colors.white 
                                                : Colors.grey[600],
                                            size: 20,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                name.isNotEmpty ? name : 'Unknown Supplier',
                                                style: TextStyle(
                                                  fontFamily: 'Literata',
                                                  fontWeight: isSelected 
                                                      ? FontWeight.w700 
                                                      : FontWeight.w600,
                                                  fontSize: 14,
                                                  color: isSelected 
                                                      ? const Color(0xFF1B4D3E)
                                                      : Colors.grey[800],
                                                ),
                                              ),
                                              if (supplier['contact'] != null) ...[
                                                const SizedBox(height: 2),
                                                Text(
                                                  supplier['contact'],
                                                  style: TextStyle(
                                                    fontFamily: 'Literata',
                                                    fontWeight: FontWeight.w400,
                                                    fontSize: 12,
                                                    color: Colors.grey[600],
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
                                        if (isSelected)
                                          const Icon(
                                            Icons.check_circle_rounded,
                                            color: Color(0xFF1B4D3E),
                                            size: 22,
                                          ),
                                      ],
                                    ),
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
        },
      ),
    );
  }
}

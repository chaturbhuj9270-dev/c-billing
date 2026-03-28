import 'package:flutter/material.dart';

/// Sort options for product list
enum ProductSortField { name, stock, price, category }

/// Filter widget for product list
/// Features: Search bar, Sort options, Category filter
class ProductFilterWidget extends StatefulWidget {
  final String searchQuery;
  final ProductSortField sortField;
  final bool sortAscending;
  final String? selectedCategory;
  final List<String> categories;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<ProductSortField> onSortFieldChanged;
  final VoidCallback onSortDirectionToggle;
  final ValueChanged<String?> onCategoryChanged;
  final VoidCallback? onClearSearch;
  final VoidCallback? onFilterTap;

  // Labels
  final String searchHint;
  final String sortByNameLabel;
  final String sortByStockLabel;
  final String sortByPriceLabel;

  const ProductFilterWidget({
    super.key,
    required this.searchQuery,
    required this.sortField,
    required this.sortAscending,
    required this.selectedCategory,
    required this.categories,
    required this.onSearchChanged,
    required this.onSortFieldChanged,
    required this.onSortDirectionToggle,
    required this.onCategoryChanged,
    this.onClearSearch,
    this.onFilterTap,
    this.searchHint = 'Search products...',
    this.sortByNameLabel = 'Name',
    this.sortByStockLabel = 'Stock',
    this.sortByPriceLabel = 'Price',
  });

  @override
  State<ProductFilterWidget> createState() => _ProductFilterWidgetState();
}

class _ProductFilterWidgetState extends State<ProductFilterWidget> {
  late TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.searchQuery);
  }

  @override
  void didUpdateWidget(covariant ProductFilterWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.searchQuery != widget.searchQuery &&
        widget.searchQuery != _searchController.text) {
      _searchController.text = widget.searchQuery;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
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
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search bar row
          Row(
            children: [
              Expanded(child: _buildSearchBar()),
              const SizedBox(width: 10),
              _buildSortDirectionButton(),
              if (widget.onFilterTap != null) ...[
                const SizedBox(width: 8),
                _buildFilterButton(),
              ],
            ],
          ),
          const SizedBox(height: 12),
          // Sort chips row
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildSortChip(
                  label: widget.sortByNameLabel,
                  isSelected: widget.sortField == ProductSortField.name,
                  onTap: () => widget.onSortFieldChanged(ProductSortField.name),
                  icon: Icons.sort_by_alpha_rounded,
                ),
                const SizedBox(width: 8),
                _buildSortChip(
                  label: widget.sortByStockLabel,
                  isSelected: widget.sortField == ProductSortField.stock,
                  onTap: () =>
                      widget.onSortFieldChanged(ProductSortField.stock),
                  icon: Icons.inventory_rounded,
                ),
                const SizedBox(width: 8),
                _buildSortChip(
                  label: widget.sortByPriceLabel,
                  isSelected: widget.sortField == ProductSortField.price,
                  onTap: () =>
                      widget.onSortFieldChanged(ProductSortField.price),
                  icon: Icons.currency_rupee_rounded,
                ),
                if (widget.categories.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  _buildCategoryDropdown(),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!, width: 1),
      ),
      child: TextField(
        controller: _searchController,
        style: const TextStyle(
          fontSize: 14,
          fontFamily: 'Literata',
          color: Color(0xFF1B4D3E),
        ),
        decoration: InputDecoration(
          hintText: widget.searchHint,
          hintStyle: TextStyle(
            color: Colors.grey[400],
            fontFamily: 'Literata',
            fontSize: 13,
          ),
          prefixIcon: Icon(
            Icons.search_rounded,
            color: Colors.grey[500],
            size: 20,
          ),
          suffixIcon: _searchController.text.isNotEmpty
              ? GestureDetector(
                  onTap: () {
                    _searchController.clear();
                    widget.onSearchChanged('');
                    widget.onClearSearch?.call();
                  },
                  child: Icon(
                    Icons.close_rounded,
                    color: Colors.grey[500],
                    size: 18,
                  ),
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
          isDense: true,
        ),
        onChanged: (value) {
          widget.onSearchChanged(value);
          setState(() {}); // Rebuild to show/hide clear button
        },
      ),
    );
  }

  Widget _buildSortDirectionButton() {
    return GestureDetector(
      onTap: widget.onSortDirectionToggle,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: const Color(0xFF1B4D3E),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: AnimatedRotation(
            duration: const Duration(milliseconds: 200),
            turns: widget.sortAscending ? 0 : 0.5,
            child: const Icon(
              Icons.arrow_upward_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterButton() {
    return GestureDetector(
      onTap: widget.onFilterTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!, width: 1),
        ),
        child: Center(
          child: Icon(Icons.tune_rounded, color: Colors.grey[700], size: 20),
        ),
      ),
    );
  }

  Widget _buildSortChip({
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
          color: isSelected ? const Color(0xFF1B4D3E) : Colors.grey[100],
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? const Color(0xFF1B4D3E) : Colors.grey[300]!,
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

  Widget _buildCategoryDropdown() {
    final hasSelection =
        widget.selectedCategory != null && widget.selectedCategory!.isNotEmpty;

    return GestureDetector(
      onTap: () => _showCategoryPicker(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: hasSelection
              ? const Color(0xFF1B4D3E).withValues(alpha: 0.1)
              : Colors.grey[100],
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: hasSelection ? const Color(0xFF1B4D3E) : Colors.grey[300]!,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.category_rounded,
              size: 16,
              color: hasSelection ? const Color(0xFF1B4D3E) : Colors.grey[600],
            ),
            const SizedBox(width: 6),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 80),
              child: Text(
                hasSelection ? widget.selectedCategory! : 'Category',
                style: TextStyle(
                  fontFamily: 'Literata',
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: hasSelection
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
              size: 18,
              color: hasSelection ? const Color(0xFF1B4D3E) : Colors.grey[600],
            ),
          ],
        ),
      ),
    );
  }

  void _showCategoryPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Select Category',
                  style: TextStyle(
                    fontFamily: 'Literata',
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: Color(0xFF1B4D3E),
                  ),
                ),
              ),
              const Divider(height: 1),
              // All categories option
              ListTile(
                leading: Icon(
                  Icons.all_inclusive_rounded,
                  color: widget.selectedCategory == null
                      ? const Color(0xFF1B4D3E)
                      : Colors.grey[600],
                ),
                title: Text(
                  'All Categories',
                  style: TextStyle(
                    fontFamily: 'Literata',
                    fontWeight: widget.selectedCategory == null
                        ? FontWeight.w700
                        : FontWeight.w500,
                    color: widget.selectedCategory == null
                        ? const Color(0xFF1B4D3E)
                        : Colors.grey[800],
                  ),
                ),
                trailing: widget.selectedCategory == null
                    ? const Icon(Icons.check_rounded, color: Color(0xFF1B4D3E))
                    : null,
                onTap: () {
                  widget.onCategoryChanged(null);
                  Navigator.pop(context);
                },
              ),
              // Category list
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: widget.categories.length,
                  itemBuilder: (context, index) {
                    final category = widget.categories[index];
                    final isSelected = widget.selectedCategory == category;
                    return ListTile(
                      leading: Icon(
                        Icons.label_rounded,
                        color: isSelected
                            ? const Color(0xFF1B4D3E)
                            : Colors.grey[600],
                      ),
                      title: Text(
                        category,
                        style: TextStyle(
                          fontFamily: 'Literata',
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: isSelected
                              ? const Color(0xFF1B4D3E)
                              : Colors.grey[800],
                        ),
                      ),
                      trailing: isSelected
                          ? const Icon(
                              Icons.check_rounded,
                              color: Color(0xFF1B4D3E),
                            )
                          : null,
                      onTap: () {
                        widget.onCategoryChanged(category);
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

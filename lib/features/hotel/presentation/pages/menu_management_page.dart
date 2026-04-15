import 'dart:ui';
import 'package:flutter/material.dart';
import '../../data/auth/hotel_auth_service.dart';
import '../../offline/controllers/menu_offline_controller.dart';
import '../../offline/entities/menu_item_entity.dart';
import '../../data/services/menu_sync_service.dart';
import 'menu_item_form_page.dart';

class MenuManagementPage extends StatefulWidget {
  const MenuManagementPage({super.key});

  @override
  State<MenuManagementPage> createState() => _MenuManagementPageState();
}

class _MenuManagementPageState extends State<MenuManagementPage>
    with SingleTickerProviderStateMixin {
  final _controller = MenuOfflineController.instance;
  final _syncService = MenuSyncService.instance;
  final _auth = HotelAuthService.instance;
  final _searchController = TextEditingController();

  List<MenuItemEntity> _allItems = [];
  List<MenuItemEntity> _filteredItems = [];
  List<String> _categories = [];
  String? _selectedCategory;
  bool _isLoading = true;
  bool _showSearch = false;

  late AnimationController _fabController;
  late Animation<double> _fabScale;

  @override
  void initState() {
    super.initState();
    _fabController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _fabScale = CurvedAnimation(
      parent: _fabController,
      curve: Curves.elasticOut,
    );
    _loadMenuItems();
    _syncService.initialize();
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) _fabController.forward();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _fabController.dispose();
    super.dispose();
  }

  Future<void> _loadMenuItems() async {
    setState(() => _isLoading = true);
    try {
      final items = await _controller.getAllMenuItems();
      final categories = await _controller.getAllCategories();
      if (mounted) {
        setState(() {
          _allItems = items;
          _categories = categories;
          _applyFilter();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _applyFilter() {
    final query = _searchController.text.toLowerCase();
    _filteredItems = _allItems.where((item) {
      final matchesCategory =
          _selectedCategory == null || item.category == _selectedCategory;
      final matchesSearch =
          query.isEmpty ||
          item.name.toLowerCase().contains(query) ||
          item.description.toLowerCase().contains(query);
      return matchesCategory && matchesSearch;
    }).toList();
  }

  void _onSearchChanged(String value) {
    setState(() => _applyFilter());
  }

  void _selectCategory(String? category) {
    setState(() {
      _selectedCategory = category;
      _applyFilter();
    });
  }

  Future<void> _navigateToForm({MenuItemEntity? item}) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => MenuItemFormPage(editItem: item)),
    );
    if (result == true) _loadMenuItems();
  }

  Future<void> _toggleAvailability(MenuItemEntity item) async {
    await _controller.toggleAvailability(item.id);
    _loadMenuItems();
  }

  Future<void> _deleteItem(MenuItemEntity item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Delete Item',
          style: TextStyle(fontFamily: 'Literata', fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Remove "${item.name}" from the menu?',
          style: const TextStyle(fontFamily: 'Literata'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.grey[600], fontFamily: 'Literata'),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Delete',
              style: TextStyle(
                color: Color(0xFFD32F2F),
                fontFamily: 'Literata',
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _controller.deleteMenuItem(item.id);
      _loadMenuItems();
    }
  }

  Future<void> _syncNow() async {
    final result = await _syncService.syncNow();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.success ? 'Menu synced' : 'Sync failed'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          duration: const Duration(seconds: 2),
        ),
      );
      _loadMenuItems();
    }
  }

  // ─── BUILD ──────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F0),
      body: Column(
        children: [
          _buildHeader(),
          if (_categories.isNotEmpty) _buildCategoryChips(),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF1B4D3E)),
                  )
                : _filteredItems.isEmpty
                ? _buildEmptyState()
                : _buildMenuGrid(),
          ),
        ],
      ),
      floatingActionButton: _auth.isAdmin
          ? ScaleTransition(
              scale: _fabScale,
              child: FloatingActionButton.extended(
                onPressed: () => _navigateToForm(),
                backgroundColor: const Color(0xFF1B4D3E),
                foregroundColor: Colors.white,
                icon: const Icon(Icons.add_rounded),
                label: const Text(
                  'Add Item',
                  style: TextStyle(
                    fontFamily: 'Literata',
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            )
          : null,
    );
  }

  // ─── HEADER ─────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1B4D3E), Color(0xFF0F3B2F), Color(0xFF134E3A)],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 12, 16),
          child: Column(
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.arrow_back_rounded,
                      color: Colors.white,
                    ),
                  ),
                  Expanded(
                    child: _showSearch
                        ? _buildSearchField()
                        : const Text(
                            'Menu',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'Literata',
                            ),
                          ),
                  ),
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _showSearch = !_showSearch;
                        if (!_showSearch) {
                          _searchController.clear();
                          _applyFilter();
                        }
                      });
                    },
                    icon: Icon(
                      _showSearch ? Icons.close_rounded : Icons.search_rounded,
                      color: Colors.white,
                    ),
                  ),
                  IconButton(
                    onPressed: _syncNow,
                    icon: ListenableBuilder(
                      listenable: _syncService,
                      builder: (_, __) {
                        final syncing = _syncService.isSyncing;
                        return syncing
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white70,
                                ),
                              )
                            : Icon(
                                Icons.sync_rounded,
                                color:
                                    _syncService.status ==
                                        MenuSyncServiceStatus.success
                                    ? const Color(0xFF4CAF50)
                                    : Colors.white70,
                              );
                      },
                    ),
                  ),
                ],
              ),
              // Stats row
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    _buildStatChip(
                      Icons.restaurant_menu_rounded,
                      '${_allItems.length} items',
                    ),
                    const SizedBox(width: 10),
                    _buildStatChip(
                      Icons.category_rounded,
                      '${_categories.length} categories',
                    ),
                    const SizedBox(width: 10),
                    _buildStatChip(
                      Icons.check_circle_outline,
                      '${_allItems.where((i) => i.isAvailable).length} available',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      onChanged: _onSearchChanged,
      autofocus: true,
      style: const TextStyle(color: Colors.white, fontFamily: 'Literata'),
      decoration: InputDecoration(
        hintText: 'Search menu items...',
        hintStyle: TextStyle(
          color: Colors.white.withValues(alpha: 0.5),
          fontFamily: 'Literata',
        ),
        border: InputBorder.none,
        contentPadding: EdgeInsets.zero,
      ),
    );
  }

  Widget _buildStatChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white70, size: 14),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 11,
              fontFamily: 'Literata',
            ),
          ),
        ],
      ),
    );
  }

  // ─── CATEGORY CHIPS ─────────────────────────────────────────────

  Widget _buildCategoryChips() {
    return Container(
      height: 50,
      padding: const EdgeInsets.only(top: 8),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _buildChip('All', _selectedCategory == null, () {
            _selectCategory(null);
          }),
          ..._categories.map(
            (cat) => Padding(
              padding: const EdgeInsets.only(left: 8),
              child: _buildChip(cat, _selectedCategory == cat, () {
                _selectCategory(cat);
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChip(String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          gradient: selected
              ? const LinearGradient(
                  colors: [Color(0xFF1B4D3E), Color(0xFF2E7D5B)],
                )
              : null,
          color: selected ? null : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: selected
              ? null
              : Border.all(color: Colors.grey.withValues(alpha: 0.3)),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: const Color(0xFF1B4D3E).withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : const Color(0xFF333333),
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            fontSize: 13,
            fontFamily: 'Literata',
          ),
        ),
      ),
    );
  }

  // ─── MENU GRID ──────────────────────────────────────────────────

  Widget _buildMenuGrid() {
    // Group by category
    final grouped = <String, List<MenuItemEntity>>{};
    for (final item in _filteredItems) {
      grouped.putIfAbsent(item.category, () => []).add(item);
    }

    final sortedCategories = grouped.keys.toList()..sort();

    return RefreshIndicator(
      onRefresh: () async {
        await _syncService.syncNow();
        await _loadMenuItems();
      },
      color: const Color(0xFF1B4D3E),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        itemCount: sortedCategories.length,
        itemBuilder: (context, index) {
          final category = sortedCategories[index];
          final items = grouped[category]!;
          return _buildCategorySection(category, items);
        },
      ),
    );
  }

  Widget _buildCategorySection(String category, List<MenuItemEntity> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 16, bottom: 10),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 20,
                decoration: BoxDecoration(
                  color: const Color(0xFF1B4D3E),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                category.toUpperCase(),
                style: const TextStyle(
                  color: Color(0xFF333333),
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Literata',
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF1B4D3E).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${items.length}',
                  style: const TextStyle(
                    color: Color(0xFF1B4D3E),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Literata',
                  ),
                ),
              ),
            ],
          ),
        ),
        ...items.map((item) => _buildMenuItemCard(item)),
      ],
    );
  }

  // ─── MENU ITEM CARD ─────────────────────────────────────────────

  Widget _buildMenuItemCard(MenuItemEntity item) {
    final isUnavailable = !item.isAvailable;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        onTap: _auth.isAdmin ? () => _navigateToForm(item: item) : null,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isUnavailable
                  ? Colors.grey.withValues(alpha: 0.3)
                  : Colors.transparent,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              children: [
                // Noise texture
                Positioned.fill(
                  child: Opacity(
                    opacity: 0.03,
                    child: Image.asset(
                      'assets/images/noise.png',
                      fit: BoxFit.cover,
                      repeat: ImageRepeat.repeat,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      // Veg/Non-veg indicator + price badge
                      _buildItemBadge(item),
                      const SizedBox(width: 14),
                      // Item details
                      Expanded(
                        child: Opacity(
                          opacity: isUnavailable ? 0.5 : 1.0,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      item.name,
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        fontFamily: 'Literata',
                                        color: Color(0xFF1A1A1A),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  // Sync indicator
                                  if (item.needsSync)
                                    Container(
                                      width: 8,
                                      height: 8,
                                      margin: const EdgeInsets.only(left: 6),
                                      decoration: const BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Color(0xFFFF9800),
                                      ),
                                    ),
                                ],
                              ),
                              if (item.description.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 3),
                                  child: Text(
                                    item.description,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                      fontFamily: 'Literata',
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  // Price
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(
                                        0xFF1B4D3E,
                                      ).withValues(alpha: 0.08),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      '₹${item.price.toStringAsFixed(item.price == item.price.roundToDouble() ? 0 : 2)}',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        fontFamily: 'Literata',
                                        color: Color(0xFF1B4D3E),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  if (item.preparationTimeMinutes > 0)
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.schedule_rounded,
                                          size: 13,
                                          color: Colors.grey[500],
                                        ),
                                        const SizedBox(width: 3),
                                        Text(
                                          '${item.preparationTimeMinutes} min',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.grey[500],
                                            fontFamily: 'Literata',
                                          ),
                                        ),
                                      ],
                                    ),
                                  const Spacer(),
                                  if (isUnavailable)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.red.withValues(
                                          alpha: 0.1,
                                        ),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Text(
                                        'Unavailable',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: Color(0xFFD32F2F),
                                          fontWeight: FontWeight.w600,
                                          fontFamily: 'Literata',
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Actions
                      if (_auth.isAdmin) ...[
                        const SizedBox(width: 8),
                        _buildItemActions(item),
                      ],
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

  Widget _buildItemBadge(MenuItemEntity item) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: item.isVeg
              ? [const Color(0xFF2E7D32), const Color(0xFF43A047)]
              : [const Color(0xFFD32F2F), const Color(0xFFE53935)],
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color:
                (item.isVeg ? const Color(0xFF2E7D32) : const Color(0xFFD32F2F))
                    .withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Glassmorphic overlay
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 1, sigmaY: 1),
                child: Container(color: Colors.transparent),
              ),
            ),
          ),
          Icon(
            item.isVeg ? Icons.eco_rounded : Icons.lunch_dining_rounded,
            color: Colors.white,
            size: 24,
          ),
        ],
      ),
    );
  }

  Widget _buildItemActions(MenuItemEntity item) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Toggle availability
        GestureDetector(
          onTap: () => _toggleAvailability(item),
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: item.isAvailable
                  ? const Color(0xFF4CAF50).withValues(alpha: 0.1)
                  : Colors.grey.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              item.isAvailable
                  ? Icons.visibility_rounded
                  : Icons.visibility_off_rounded,
              color: item.isAvailable
                  ? const Color(0xFF4CAF50)
                  : Colors.grey[400],
              size: 18,
            ),
          ),
        ),
        const SizedBox(height: 6),
        // Delete
        GestureDetector(
          onTap: () => _deleteItem(item),
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFD32F2F).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.delete_outline_rounded,
              color: Color(0xFFD32F2F),
              size: 18,
            ),
          ),
        ),
      ],
    );
  }

  // ─── EMPTY STATE ────────────────────────────────────────────────

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: const Color(0xFF1B4D3E).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(30),
            ),
            child: const Icon(
              Icons.restaurant_menu_rounded,
              size: 48,
              color: Color(0xFF1B4D3E),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'No Menu Items Yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              fontFamily: 'Literata',
              color: Color(0xFF333333),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _selectedCategory != null
                ? 'No items in this category'
                : 'Tap + to add your first dish',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
              fontFamily: 'Literata',
            ),
          ),
        ],
      ),
    );
  }
}

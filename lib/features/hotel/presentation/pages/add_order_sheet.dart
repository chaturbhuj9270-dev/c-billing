import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../offline/entities/table_entity.dart';
import '../../offline/entities/menu_item_entity.dart';
import '../../offline/entities/table_order_entity.dart';
import '../../offline/controllers/menu_offline_controller.dart';
import '../../offline/controllers/table_order_controller.dart';

/// Full-screen page for placing/editing a table order.
/// Opens for empty tables (new order) or active tables (edit existing).
class AddOrderSheet extends StatefulWidget {
  final TableEntity table;
  final TableOrderEntity? existingOrder; // non-null when editing

  const AddOrderSheet({super.key, required this.table, this.existingOrder});

  @override
  State<AddOrderSheet> createState() => _AddOrderSheetState();
}

class _AddOrderSheetState extends State<AddOrderSheet> {
  final _menuCtrl = MenuOfflineController.instance;
  final _orderCtrl = TableOrderController.instance;

  final _guestNameCtrl = TextEditingController();
  final _guestPhoneCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  int _seats = 2;

  List<MenuItemEntity> _menuItems = [];
  List<String> _categories = [];
  String? _selectedCategory;
  String _searchQuery = '';
  bool _isLoading = true;
  bool _placing = false;

  // localMenuItemId → qty
  final Map<int, int> _qtys = {};

  bool get _isEdit => widget.existingOrder != null;

  String get _headerTitle {
    if (!_isEdit) return 'New order';
    switch (widget.existingOrder!.status) {
      case TableOrderStatus.open:
        return 'Edit order';
      case TableOrderStatus.sentToKitchen:
      case TableOrderStatus.served:
        return 'Add to order';
      default:
        return 'Order';
    }
  }

  String get _headerSubtitle {
    final base =
        'Table ${widget.table.tableNumber} · ${widget.table.section}';
    if (!_isEdit) return base;
    if (widget.existingOrder!.status == TableOrderStatus.sentToKitchen) {
      return '$base · items go to kitchen';
    }
    if (widget.existingOrder!.status == TableOrderStatus.served) {
      return '$base · new items go to kitchen first';
    }
    return base;
  }

  String get _placeOrderLabel {
    if (!_isEdit) return 'Place order';
    switch (widget.existingOrder!.status) {
      case TableOrderStatus.open:
        return 'Update order';
      case TableOrderStatus.sentToKitchen:
      case TableOrderStatus.served:
        return 'Save & send to kitchen';
      default:
        return 'Save order';
    }
  }

  @override
  void initState() {
    super.initState();
    _seats = widget.table.capacity;

    // Pre-fill guest info
    _guestNameCtrl.text = widget.table.guestName ?? '';
    _guestPhoneCtrl.text = widget.table.guestPhone ?? '';
    _notesCtrl.text = widget.table.notes ?? '';

    // Pre-load existing order items
    if (_isEdit) {
      final existing = decodeOrderItems(widget.existingOrder!.itemsJson);
      _seats = widget.existingOrder!.occupiedSeats;
      _guestNameCtrl.text = widget.existingOrder!.guestName ?? '';
      _guestPhoneCtrl.text = widget.existingOrder!.guestPhone ?? '';
      _notesCtrl.text = widget.existingOrder!.notes ?? '';
      for (final item in existing) {
        if (item.quantity > 0) {
          _qtys[item.menuItemLocalId] = item.quantity;
        }
      }
    }

    _loadMenu();
  }

  @override
  void dispose() {
    _guestNameCtrl.dispose();
    _guestPhoneCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadMenu() async {
    final items = await _menuCtrl.getAllMenuItems();
    final cats = await _menuCtrl.getAllCategories();
    if (mounted) {
      setState(() {
        _menuItems = items.where((i) => i.isAvailable).toList();
        _categories = cats;
        _isLoading = false;
      });
    }
  }

  List<MenuItemEntity> get _visibleItems {
    return _menuItems.where((item) {
      final matchCat =
          _selectedCategory == null || item.category == _selectedCategory;
      final matchSearch =
          _searchQuery.isEmpty ||
          item.name.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchCat && matchSearch;
    }).toList();
  }

  int get _totalItemCount => _qtys.values.fold(0, (s, q) => s + q);

  double get _totalAmount {
    double total = 0;
    for (final item in _menuItems) {
      final qty = _qtys[item.id] ?? 0;
      total += item.price * qty;
    }
    return total;
  }

  List<OrderItem> _buildOrderItems() {
    final result = <OrderItem>[];
    for (final item in _menuItems) {
      final qty = _qtys[item.id] ?? 0;
      if (qty > 0) {
        result.add(
          OrderItem(
            menuItemLocalId: item.id,
            menuItemServerId: item.serverId,
            name: item.name,
            isVeg: item.isVeg,
            price: item.price,
            category: item.category,
            quantity: qty,
          ),
        );
      }
    }
    return result;
  }

  Future<void> _placeOrder() async {
    final items = _buildOrderItems();
    if (items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Add at least one item to the order'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          backgroundColor: const Color(0xFFD32F2F),
        ),
      );
      return;
    }

    HapticFeedback.mediumImpact();
    setState(() => _placing = true);

    try {
      if (_isEdit) {
        await _orderCtrl.updateOrderItems(
          widget.existingOrder!.id,
          items,
          syncGuestFields: true,
          guestName: _guestNameCtrl.text.trim().isEmpty
              ? null
              : _guestNameCtrl.text.trim(),
          guestPhone: _guestPhoneCtrl.text.trim().isEmpty
              ? null
              : _guestPhoneCtrl.text.trim(),
          occupiedSeats: _seats,
          notes: _notesCtrl.text.trim().isEmpty
              ? null
              : _notesCtrl.text.trim(),
        );
      } else {
        await _orderCtrl.createOrder(
          localTableId: widget.table.id,
          tableNumber: widget.table.tableNumber,
          items: items,
          guestName: _guestNameCtrl.text.trim().isEmpty
              ? null
              : _guestNameCtrl.text.trim(),
          guestPhone: _guestPhoneCtrl.text.trim().isEmpty
              ? null
              : _guestPhoneCtrl.text.trim(),
          occupiedSeats: _seats,
          notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
        );
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _placing = false);
    }
  }

  // ── BUILD ────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A160F),
      body: Column(
        children: [
          _buildHeader(),
          _buildGuestInfo(),
          _buildSearchAndFilter(),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF4ADE80)),
                  )
                : _visibleItems.isEmpty
                ? _buildEmptyMenu()
                : _buildMenuList(),
          ),
        ],
      ),
      bottomSheet: _buildOrderBar(),
    );
  }

  // ── HEADER ───────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0A1F16), Color(0xFF0E2A1C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(6, 8, 16, 16),
          child: Row(
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _headerTitle,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        fontFamily: 'Literata',
                      ),
                    ),
                    Text(
                      _headerSubtitle,
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                        fontFamily: 'Literata',
                      ),
                    ),
                  ],
                ),
              ),
              // Seats selector
              _buildSeatsSelector(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSeatsSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              if (_seats > 1) setState(() => _seats--);
            },
            child: const Icon(
              Icons.remove_rounded,
              color: Colors.white60,
              size: 18,
            ),
          ),
          const SizedBox(width: 8),
          Icon(Icons.people_rounded, color: Colors.white54, size: 16),
          const SizedBox(width: 4),
          Text(
            '$_seats',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w700,
              fontFamily: 'Literata',
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () {
              if (_seats < widget.table.capacity) {
                setState(() => _seats++);
              }
            },
            child: const Icon(
              Icons.add_rounded,
              color: Colors.white60,
              size: 18,
            ),
          ),
        ],
      ),
    );
  }

  // ── GUEST INFO ───────────────────────────────────────────────────

  Widget _buildGuestInfo() {
    return Container(
      color: const Color(0xFF0C1910),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Row(
        children: [
          Expanded(
            child: _miniField(
              _guestNameCtrl,
              'Guest name',
              Icons.person_rounded,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _miniField(
              _guestPhoneCtrl,
              'Phone',
              Icons.phone_rounded,
              type: TextInputType.phone,
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniField(
    TextEditingController ctrl,
    String hint,
    IconData icon, {
    TextInputType type = TextInputType.text,
  }) {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: TextField(
        controller: ctrl,
        keyboardType: type,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 13,
          fontFamily: 'Literata',
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
            color: Colors.white.withValues(alpha: 0.25),
            fontSize: 12,
          ),
          prefixIcon: Icon(icon, color: Colors.white30, size: 16),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 10,
          ),
        ),
      ),
    );
  }

  // ── SEARCH + FILTER ──────────────────────────────────────────────

  Widget _buildSearchAndFilter() {
    return Container(
      color: const Color(0xFF0E1C17),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Column(
        children: [
          // Search bar
          Container(
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: TextField(
              onChanged: (v) => setState(() => _searchQuery = v),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontFamily: 'Literata',
              ),
              decoration: InputDecoration(
                hintText: 'Search menu...',
                hintStyle: TextStyle(
                  color: Colors.white.withValues(alpha: 0.3),
                  fontSize: 13,
                  fontFamily: 'Literata',
                ),
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: Colors.white38,
                  size: 18,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Category chips
          SizedBox(
            height: 30,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _catChip(null, 'All'),
                ..._categories.map((c) => _catChip(c, c)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _catChip(String? cat, String label) {
    final selected = _selectedCategory == cat;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () => setState(() => _selectedCategory = cat),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: selected
                ? const Color(0xFF22C55E).withValues(alpha: 0.2)
                : Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected
                  ? const Color(0xFF22C55E).withValues(alpha: 0.6)
                  : Colors.white.withValues(alpha: 0.09),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? const Color(0xFF4ADE80) : Colors.white54,
              fontSize: 11,
              fontFamily: 'Literata',
              fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }

  // ── MENU LIST ────────────────────────────────────────────────────

  Widget _buildMenuList() {
    final grouped = <String, List<MenuItemEntity>>{};
    for (final item in _visibleItems) {
      grouped.putIfAbsent(item.category, () => []).add(item);
    }
    final sortedCats = grouped.keys.toList()..sort();

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 130),
      itemCount: sortedCats.length,
      itemBuilder: (_, i) {
        final cat = sortedCats[i];
        return _buildCategoryGroup(cat, grouped[cat]!);
      },
    );
  }

  Widget _buildCategoryGroup(String cat, List<MenuItemEntity> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 14, bottom: 8),
          child: Row(
            children: [
              Container(
                width: 3,
                height: 14,
                decoration: BoxDecoration(
                  color: const Color(0xFF4ADE80),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                cat.toUpperCase(),
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Literata',
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ),
        ...items.map(_buildMenuItemRow),
      ],
    );
  }

  Widget _buildMenuItemRow(MenuItemEntity item) {
    final qty = _qtys[item.id] ?? 0;
    final isInOrder = qty > 0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isInOrder
            ? const Color(0xFF22C55E).withValues(alpha: 0.1)
            : Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isInOrder
              ? const Color(0xFF22C55E).withValues(alpha: 0.4)
              : Colors.white.withValues(alpha: 0.07),
          width: isInOrder ? 1.4 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            // Veg/non-veg dot
            Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: item.isVeg
                      ? const Color(0xFF22C55E)
                      : const Color(0xFFF87171),
                  width: 2,
                ),
              ),
              child: Center(
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: item.isVeg
                        ? const Color(0xFF22C55E)
                        : const Color(0xFFF87171),
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
                    item.name,
                    style: TextStyle(
                      color: isInOrder
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.85),
                      fontSize: 14,
                      fontWeight: isInOrder ? FontWeight.w700 : FontWeight.w500,
                      fontFamily: 'Literata',
                    ),
                  ),
                  if (item.description.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        item.description,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white38,
                          fontSize: 11,
                          fontFamily: 'Literata',
                        ),
                      ),
                    ),
                  const SizedBox(height: 2),
                  Text(
                    '₹${item.price.toStringAsFixed(item.price == item.price.roundToDouble() ? 0 : 2)}',
                    style: const TextStyle(
                      color: Color(0xFF4ADE80),
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Literata',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Qty control
            _buildQtyControl(item, qty),
          ],
        ),
      ),
    );
  }

  Widget _buildQtyControl(MenuItemEntity item, int qty) {
    if (qty == 0) {
      return GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() => _qtys[item.id] = 1);
        },
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: const Color(0xFF22C55E).withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: const Color(0xFF22C55E).withValues(alpha: 0.5),
            ),
          ),
          child: const Icon(
            Icons.add_rounded,
            color: Color(0xFF4ADE80),
            size: 20,
          ),
        ),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() {
              if (qty <= 1) {
                _qtys.remove(item.id);
              } else {
                _qtys[item.id] = qty - 1;
              }
            });
          },
          child: Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.remove_rounded,
              color: Colors.white70,
              size: 16,
            ),
          ),
        ),
        SizedBox(
          width: 32,
          child: Text(
            '$qty',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w800,
              fontFamily: 'Literata',
            ),
          ),
        ),
        GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() => _qtys[item.id] = qty + 1);
          },
          child: Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: const Color(0xFF22C55E).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.add_rounded,
              color: Color(0xFF4ADE80),
              size: 16,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyMenu() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.restaurant_menu_rounded,
            color: Color(0xFF4ADE80),
            size: 48,
          ),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isNotEmpty ? 'No results found' : 'Menu is empty',
            style: const TextStyle(
              color: Colors.white60,
              fontSize: 16,
              fontFamily: 'Literata',
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Add items from Menu Management first',
            style: TextStyle(
              color: Colors.white38,
              fontSize: 12,
              fontFamily: 'Literata',
            ),
          ),
        ],
      ),
    );
  }

  // ── ORDER BAR ────────────────────────────────────────────────────

  Widget _buildOrderBar() {
    final count = _totalItemCount;
    final total = _totalAmount;

    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0A160F), Color(0xFF0C1A12)],
        ),
        border: Border(
          top: BorderSide(
            color: count > 0
                ? const Color(0xFF22C55E).withValues(alpha: 0.3)
                : Colors.white.withValues(alpha: 0.07),
          ),
        ),
      ),
      child: Row(
        children: [
          // Summary chip
          if (count > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF22C55E).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: const Color(0xFF22C55E).withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$count item${count == 1 ? '' : 's'}',
                    style: const TextStyle(
                      color: Colors.white60,
                      fontSize: 11,
                      fontFamily: 'Literata',
                    ),
                  ),
                  Text(
                    '₹${total.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: Color(0xFF4ADE80),
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      fontFamily: 'Literata',
                    ),
                  ),
                ],
              ),
            ),
          if (count > 0) const SizedBox(width: 12),
          // Place order button
          Expanded(
            child: SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _placing ? null : _placeOrder,
                style: ElevatedButton.styleFrom(
                  backgroundColor: count > 0
                      ? const Color(0xFF22C55E)
                      : Colors.white.withValues(alpha: 0.08),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: const Color(
                    0xFF22C55E,
                  ).withValues(alpha: 0.4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: _placing
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        count == 0
                            ? 'Select items to order'
                            : _placeOrderLabel,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Literata',
                          color: count > 0 ? Colors.white : Colors.white38,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

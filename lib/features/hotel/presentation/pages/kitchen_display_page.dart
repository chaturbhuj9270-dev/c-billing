import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../offline/entities/table_order_entity.dart';
import '../../offline/controllers/table_order_controller.dart';

class KitchenDisplayPage extends StatefulWidget {
  const KitchenDisplayPage({super.key});

  @override
  State<KitchenDisplayPage> createState() => _KitchenDisplayPageState();
}

class _KitchenDisplayPageState extends State<KitchenDisplayPage> {
  final _ctrl = TableOrderController.instance;

  List<TableOrderEntity> _orders = [];
  bool _isLoading = true;
  Timer? _refreshTimer;
  Timer? _pollTimer;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _load();

    // Auto-refresh every second for live timers
    _refreshTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });

    // Poll for new orders every 5 seconds
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (mounted) _load(silent: true);
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _load({bool silent = false}) async {
    if (!silent) setState(() => _isLoading = true);
    final orders = await _ctrl.getKitchenOrders();
    if (mounted) {
      setState(() {
        _orders = orders;
        _isLoading = false;
        _now = DateTime.now();
      });
    }
  }

  Future<void> _toggleItemReady(TableOrderEntity order, OrderItem item) async {
    HapticFeedback.selectionClick();
    if (item.isReady) return; // once ready, stays ready
    await _ctrl.markItemReady(order.id, item.menuItemLocalId);
    await _load(silent: true);
  }

  Future<void> _markAllReady(TableOrderEntity order) async {
    HapticFeedback.mediumImpact();
    await _ctrl.markAllItemsReady(order.id);
    await _load(silent: true);
  }

  Future<void> _markReadyToServe(TableOrderEntity order) async {
    HapticFeedback.heavyImpact();
    await _ctrl.markReadyToServe(order.id, order.localTableId);
    await _load(silent: true);
  }

  // ── BUILD ─────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildStatsBar(),
        Expanded(
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFF16A34A),
                    strokeWidth: 2.5,
                  ),
                )
              : _orders.isEmpty
              ? _buildEmptyState()
              : _buildOrderGrid(),
        ),
      ],
    );
  }

  // ── STATS BAR ─────────────────────────────────────────────────

  Widget _buildStatsBar() {
    int totalItems = 0;
    int readyItems = 0;
    for (final order in _orders) {
      final items = decodeOrderItems(order.itemsJson);
      totalItems += items.length;
      readyItems += items.where((i) => i.isReady).length;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: const Color(0xFF16A34A).withValues(alpha: 0.1),
          ),
        ),
      ),
      child: Row(
        children: [
          _statChip(
            Icons.receipt_long_rounded,
            '${_orders.length}',
            'Orders',
            const Color(0xFF16A34A),
          ),
          const SizedBox(width: 12),
          _statChip(
            Icons.restaurant_rounded,
            '$totalItems',
            'Items',
            const Color(0xFFD97706),
          ),
          const SizedBox(width: 12),
          _statChip(
            Icons.check_circle_rounded,
            '$readyItems',
            'Ready',
            const Color(0xFF16A34A),
          ),
          const Spacer(),
          // Live clock
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${_now.hour.toString().padLeft(2, '0')}:${_now.minute.toString().padLeft(2, '0')}:${_now.second.toString().padLeft(2, '0')}',
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontSize: 13,
                fontFamily: 'Literata',
                fontWeight: FontWeight.w600,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statChip(IconData icon, String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 6),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.w800,
              fontFamily: 'Literata',
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color.withValues(alpha: 0.6),
              fontSize: 10,
              fontFamily: 'Literata',
            ),
          ),
        ],
      ),
    );
  }

  // ── ORDER GRID ────────────────────────────────────────────────

  Widget _buildOrderGrid() {
    return RefreshIndicator(
      onRefresh: _load,
      color: const Color(0xFF16A34A),
      backgroundColor: Colors.white,
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Responsive: 1 col on narrow, 2 on medium, 3 on wide
          final crossAxisCount = constraints.maxWidth > 900
              ? 3
              : constraints.maxWidth > 550
              ? 2
              : 1;
          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              mainAxisSpacing: 14,
              crossAxisSpacing: 14,
              childAspectRatio: crossAxisCount == 1 ? 1.4 : 0.75,
            ),
            itemCount: _orders.length,
            itemBuilder: (_, i) => _KitchenOrderCard(
              order: _orders[i],
              now: _now,
              onItemTap: (item) => _toggleItemReady(_orders[i], item),
              onMarkAllReady: () => _markAllReady(_orders[i]),
              onReadyToServe: () => _markReadyToServe(_orders[i]),
            ),
          );
        },
      ),
    );
  }

  // ── EMPTY STATE ───────────────────────────────────────────────

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              color: const Color(0xFF16A34A).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: const Color(0xFF16A34A).withValues(alpha: 0.15),
              ),
            ),
            child: const Icon(
              Icons.soup_kitchen_rounded,
              size: 46,
              color: Color(0xFF16A34A),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Kitchen is Clear',
            style: TextStyle(
              color: Color(0xFF1E293B),
              fontSize: 20,
              fontWeight: FontWeight.w700,
              fontFamily: 'Literata',
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'No pending orders — all caught up!',
            style: TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 13,
              fontFamily: 'Literata',
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// KITCHEN ORDER CARD
// ─────────────────────────────────────────────────────────────────

class _KitchenOrderCard extends StatelessWidget {
  final TableOrderEntity order;
  final DateTime now;
  final ValueChanged<OrderItem> onItemTap;
  final VoidCallback onMarkAllReady;
  final VoidCallback onReadyToServe;

  const _KitchenOrderCard({
    required this.order,
    required this.now,
    required this.onItemTap,
    required this.onMarkAllReady,
    required this.onReadyToServe,
  });

  @override
  Widget build(BuildContext context) {
    final items = decodeOrderItems(order.itemsJson);
    final readyCount = items.where((i) => i.isReady).length;
    final allReady = readyCount == items.length;
    final elapsed = order.sentToKitchenAt != null
        ? now.difference(order.sentToKitchenAt!)
        : Duration.zero;
    final isUrgent = elapsed.inMinutes >= 15;
    final progressPct = items.isEmpty ? 0.0 : readyCount / items.length;

    final accentColor = isUrgent
        ? const Color(0xFFDC2626)
        : allReady
        ? const Color(0xFF16A34A)
        : const Color(0xFF16A34A);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isUrgent ? const Color(0xFFFCA5A5) : const Color(0xFFE2E8F0),
          width: isUrgent ? 1.8 : 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Card header ──────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.08),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(17),
              ),
            ),
            child: Row(
              children: [
                // Table badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: accentColor.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    'T-${order.tableNumber}',
                    style: TextStyle(
                      color: accentColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      fontFamily: 'Literata',
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // Guest name
                Expanded(
                  child: Text(
                    order.guestName ?? 'Guest',
                    style: const TextStyle(
                      color: Color(0xFF475569),
                      fontSize: 12,
                      fontFamily: 'Literata',
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                // Timer
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: isUrgent
                        ? const Color(0xFFFEE2E2)
                        : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.schedule_rounded,
                        size: 12,
                        color: isUrgent
                            ? const Color(0xFFDC2626)
                            : const Color(0xFF94A3B8),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatElapsed(elapsed),
                        style: TextStyle(
                          color: isUrgent
                              ? const Color(0xFFDC2626)
                              : const Color(0xFF64748B),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Literata',
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Progress bar ─────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            child: Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: progressPct,
                      minHeight: 4,
                      backgroundColor: const Color(0xFFE2E8F0),
                      color: allReady
                          ? const Color(0xFF16A34A)
                          : const Color(0xFF16A34A),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '$readyCount/${items.length}',
                  style: TextStyle(
                    color: allReady
                        ? const Color(0xFF16A34A)
                        : const Color(0xFF94A3B8),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Literata',
                  ),
                ),
              ],
            ),
          ),

          // ── Items list ───────────────────────────────────
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 4),
              itemBuilder: (_, i) => _buildItemRow(items[i]),
            ),
          ),

          // ── Action buttons ───────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(10, 6, 10, 10),
            child: Row(
              children: [
                if (!allReady) ...[
                  // Mark all ready
                  Expanded(
                    child: _actionButton(
                      label: 'All Ready',
                      icon: Icons.done_all_rounded,
                      color: const Color(0xFFD97706),
                      onTap: onMarkAllReady,
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                // Ready to serve
                Expanded(
                  flex: allReady ? 1 : 1,
                  child: _actionButton(
                    label: allReady ? 'Ready to Serve' : 'Serve Now',
                    icon: Icons.room_service_rounded,
                    color: allReady
                        ? const Color(0xFF16A34A)
                        : const Color(0xFF94A3B8),
                    filled: allReady,
                    onTap: onReadyToServe,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemRow(OrderItem item) {
    return GestureDetector(
      onTap: () => onItemTap(item),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: item.isReady
              ? const Color(0xFF16A34A).withValues(alpha: 0.06)
              : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: item.isReady
                ? const Color(0xFF16A34A).withValues(alpha: 0.25)
                : const Color(0xFFE2E8F0),
          ),
        ),
        child: Row(
          children: [
            // Ready checkbox
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: item.isReady
                    ? const Color(0xFF16A34A)
                    : Colors.transparent,
                border: Border.all(
                  color: item.isReady
                      ? const Color(0xFF16A34A)
                      : const Color(0xFFCBD5E1),
                  width: 2,
                ),
              ),
              child: item.isReady
                  ? const Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 14,
                    )
                  : null,
            ),
            const SizedBox(width: 10),
            // Veg/non-veg dot
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: item.isVeg
                    ? const Color(0xFF16A34A)
                    : const Color(0xFFDC2626),
              ),
            ),
            const SizedBox(width: 8),
            // Item name
            Expanded(
              child: Text(
                item.name,
                style: TextStyle(
                  color: item.isReady
                      ? const Color(0xFF94A3B8)
                      : const Color(0xFF1E293B),
                  fontSize: 13,
                  fontFamily: 'Literata',
                  fontWeight: FontWeight.w500,
                  decoration: item.isReady ? TextDecoration.lineThrough : null,
                  decorationColor: const Color(0xFF94A3B8),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // Quantity badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: item.isReady
                    ? const Color(0xFF16A34A).withValues(alpha: 0.1)
                    : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '×${item.quantity}',
                style: TextStyle(
                  color: item.isReady
                      ? const Color(0xFF16A34A)
                      : const Color(0xFF64748B),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Literata',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    bool filled = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 38,
        decoration: BoxDecoration(
          color: filled ? color : color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: color.withValues(alpha: filled ? 1.0 : 0.3),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 15, color: filled ? Colors.white : color),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                color: filled ? Colors.white : color,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                fontFamily: 'Literata',
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatElapsed(Duration d) {
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    if (m >= 60) {
      return '${m ~/ 60}h ${m % 60}m';
    }
    return '${m}m ${s.toString().padLeft(2, '0')}s';
  }
}

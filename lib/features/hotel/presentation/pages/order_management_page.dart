import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../offline/entities/table_order_entity.dart';
import '../../offline/controllers/table_order_controller.dart';
import 'order_detail_sheet.dart';

// ─────────────────────────────────────────────────────────────────
// ORDER STATUS HELPERS (local to this page)
// ─────────────────────────────────────────────────────────────────

Color _orderStatusColor(TableOrderStatus s) {
  switch (s) {
    case TableOrderStatus.open:
      return const Color(0xFF3B82F6); // blue
    case TableOrderStatus.sentToKitchen:
      return const Color(0xFFF59E0B); // amber
    case TableOrderStatus.served:
      return const Color(0xFF22C55E); // green
    case TableOrderStatus.billed:
      return const Color(0xFF8B5CF6); // violet
    case TableOrderStatus.cancelled:
      return const Color(0xFFEF4444); // red
  }
}

String _orderStatusLabel(TableOrderStatus s) {
  switch (s) {
    case TableOrderStatus.open:
      return 'Open';
    case TableOrderStatus.sentToKitchen:
      return 'In Kitchen';
    case TableOrderStatus.served:
      return 'Served';
    case TableOrderStatus.billed:
      return 'Billed';
    case TableOrderStatus.cancelled:
      return 'Cancelled';
  }
}

IconData _orderStatusIcon(TableOrderStatus s) {
  switch (s) {
    case TableOrderStatus.open:
      return Icons.edit_note_rounded;
    case TableOrderStatus.sentToKitchen:
      return Icons.soup_kitchen_rounded;
    case TableOrderStatus.served:
      return Icons.room_service_rounded;
    case TableOrderStatus.billed:
      return Icons.receipt_long_rounded;
    case TableOrderStatus.cancelled:
      return Icons.cancel_rounded;
  }
}

// ─────────────────────────────────────────────────────────────────
// ORDER MANAGEMENT PAGE
// ─────────────────────────────────────────────────────────────────

class OrderManagementPage extends StatefulWidget {
  const OrderManagementPage({super.key});

  @override
  State<OrderManagementPage> createState() => _OrderManagementPageState();
}

class _OrderManagementPageState extends State<OrderManagementPage> {
  final _ctrl = TableOrderController.instance;

  List<TableOrderEntity> _all = [];
  TableOrderStatus? _filterStatus;
  bool _isLoading = true;

  // Live clock
  Timer? _clockTimer;
  Timer? _pollTimer;
  DateTime _now = DateTime.now();

  // Stats
  int get _openCount =>
      _all.where((o) => o.status == TableOrderStatus.open).length;
  int get _kitchenCount =>
      _all.where((o) => o.status == TableOrderStatus.sentToKitchen).length;
  int get _servedCount =>
      _all.where((o) => o.status == TableOrderStatus.served).length;
  int get _billedCount =>
      _all.where((o) => o.status == TableOrderStatus.billed).length;
  double get _todayRevenue => _all
      .where((o) => o.status == TableOrderStatus.billed)
      .fold(0.0, (sum, o) => sum + o.totalAmount);

  @override
  void initState() {
    super.initState();
    _load();

    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });

    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (mounted) _load(silent: true);
    });
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _load({bool silent = false}) async {
    if (!silent) setState(() => _isLoading = true);
    final orders = await _ctrl.getTodayOrders();
    if (mounted) {
      setState(() {
        _all = orders;
        _isLoading = false;
        _now = DateTime.now();
      });
    }
  }

  List<TableOrderEntity> get _filtered {
    if (_filterStatus == null) return _all;
    return _all.where((o) => o.status == _filterStatus).toList();
  }

  Future<void> _onOrderTap(TableOrderEntity order) async {
    final changed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => OrderDetailSheet(order: order),
    );
    if (changed == true) _load();
  }

  // ── BUILD ────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFD1FAE5),
            Color(0xFFECFDF5),
            Color(0xFFF0FDF4),
            Color(0xFFF8FAFC),
          ],
          stops: [0.0, 0.3, 0.6, 1.0],
        ),
      ),
      child: Stack(
        children: [
          // Ambient glow — top right
          Positioned(
            top: -50,
            right: -50,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF22C55E).withValues(alpha: 0.12),
                    const Color(0xFF22C55E).withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
          // Ambient glow — bottom left
          Positioned(
            bottom: -70,
            left: -70,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF3B82F6).withValues(alpha: 0.08),
                    const Color(0xFF3B82F6).withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
          Column(
            children: [
              _buildStatsStrip(),
              _buildStatusFilterBar(),
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF16A34A),
                          strokeWidth: 2.5,
                        ),
                      )
                    : _filtered.isEmpty
                    ? _buildEmptyState()
                    : _buildOrderList(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── STATS STRIP ──────────────────────────────────────────────────

  Widget _buildStatsStrip() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            padding: const EdgeInsets.fromLTRB(8, 14, 8, 14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withValues(alpha: 0.75),
                  Colors.white.withValues(alpha: 0.55),
                ],
              ),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.6),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF16A34A).withValues(alpha: 0.06),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                _buildStatTile(
                  'Open',
                  _openCount,
                  const Color(0xFF3B82F6),
                  Icons.edit_note_rounded,
                ),
                _tinyDivider(),
                _buildStatTile(
                  'Kitchen',
                  _kitchenCount,
                  const Color(0xFFF59E0B),
                  Icons.soup_kitchen_rounded,
                ),
                _tinyDivider(),
                _buildStatTile(
                  'Served',
                  _servedCount,
                  const Color(0xFF22C55E),
                  Icons.room_service_rounded,
                ),
                _tinyDivider(),
                _buildStatTile(
                  'Billed',
                  _billedCount,
                  const Color(0xFF8B5CF6),
                  Icons.receipt_long_rounded,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _tinyDivider() {
    return Container(
      width: 1,
      height: 32,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      color: const Color(0xFFE2E8F0).withValues(alpha: 0.6),
    );
  }

  Widget _buildStatTile(String label, int count, Color color, IconData icon) {
    final isSelected = _filterStatus == _labelToStatus(label);
    return Expanded(
      child: GestureDetector(
        onTap: () {
          final status = _labelToStatus(label);
          setState(() {
            _filterStatus = _filterStatus == status ? null : status;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          decoration: BoxDecoration(
            color: isSelected
                ? color.withValues(alpha: 0.12)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? color.withValues(alpha: 0.4)
                  : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 16),
              ),
              const SizedBox(height: 6),
              Text(
                '$count',
                style: TextStyle(
                  color: color,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'Literata',
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  color: color.withValues(alpha: 0.7),
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Literata',
                  letterSpacing: 0.3,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  TableOrderStatus? _labelToStatus(String label) {
    switch (label) {
      case 'Open':
        return TableOrderStatus.open;
      case 'Kitchen':
        return TableOrderStatus.sentToKitchen;
      case 'Served':
        return TableOrderStatus.served;
      case 'Billed':
        return TableOrderStatus.billed;
      case 'Cancelled':
        return TableOrderStatus.cancelled;
      default:
        return null;
    }
  }

  // ── STATUS FILTER BAR ────────────────────────────────────────────

  Widget _buildStatusFilterBar() {
    final statuses = <TableOrderStatus?>[null, ...TableOrderStatus.values];
    return Container(
      height: 52,
      padding: const EdgeInsets.only(top: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        itemCount: statuses.length,
        itemBuilder: (_, i) {
          final s = statuses[i];
          final selected = _filterStatus == s;
          final color = s == null
              ? const Color(0xFF16A34A)
              : _orderStatusColor(s);
          final label = s == null ? 'All' : _orderStatusLabel(s);
          final count = s == null
              ? _all.length
              : _all.where((o) => o.status == s).length;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => setState(() => _filterStatus = s),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: selected
                      ? color.withValues(alpha: 0.15)
                      : Colors.white.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: selected
                        ? color.withValues(alpha: 0.5)
                        : const Color(0xFFE2E8F0),
                    width: selected ? 1.5 : 1,
                  ),
                  boxShadow: selected
                      ? [
                          BoxShadow(
                            color: color.withValues(alpha: 0.12),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (s != null) ...[
                      Icon(
                        _orderStatusIcon(s),
                        size: 13,
                        color: selected ? color : const Color(0xFF94A3B8),
                      ),
                      const SizedBox(width: 5),
                    ],
                    Text(
                      label,
                      style: TextStyle(
                        color: selected ? color : const Color(0xFF64748B),
                        fontSize: 12,
                        fontWeight: selected
                            ? FontWeight.w700
                            : FontWeight.w500,
                        fontFamily: 'Literata',
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: selected
                            ? color.withValues(alpha: 0.2)
                            : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '$count',
                        style: TextStyle(
                          color: selected ? color : const Color(0xFF94A3B8),
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          fontFamily: 'Literata',
                        ),
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

  // ── ORDER LIST ───────────────────────────────────────────────────

  Widget _buildOrderList() {
    final orders = _filtered;

    return RefreshIndicator(
      onRefresh: _load,
      color: const Color(0xFF16A34A),
      backgroundColor: Colors.white,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        itemCount: orders.length + 1, // +1 for revenue header
        itemBuilder: (_, i) {
          if (i == 0) return _buildRevenueHeader();
          return _OrderCard(
            order: orders[i - 1],
            now: _now,
            onTap: () => _onOrderTap(orders[i - 1]),
          );
        },
      ),
    );
  }

  Widget _buildRevenueHeader() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF16A34A).withValues(alpha: 0.08),
                  const Color(0xFF16A34A).withValues(alpha: 0.03),
                ],
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: const Color(0xFF16A34A).withValues(alpha: 0.15),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFF16A34A).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.trending_up_rounded,
                    color: Color(0xFF16A34A),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Today's Revenue",
                        style: TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 11,
                          fontFamily: 'Literata',
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '₹${_todayRevenue.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: Color(0xFF16A34A),
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          fontFamily: 'Literata',
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${_all.length} orders',
                      style: const TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 11,
                        fontFamily: 'Literata',
                      ),
                    ),
                    const SizedBox(height: 2),
                    // Live clock
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${_now.hour.toString().padLeft(2, '0')}:${_now.minute.toString().padLeft(2, '0')}',
                        style: const TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 11,
                          fontFamily: 'Literata',
                          fontWeight: FontWeight.w600,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── EMPTY STATE ──────────────────────────────────────────────────

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
              Icons.receipt_long_rounded,
              size: 46,
              color: Color(0xFF16A34A),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'No Orders Yet',
            style: TextStyle(
              color: Color(0xFF1E293B),
              fontSize: 20,
              fontWeight: FontWeight.w700,
              fontFamily: 'Literata',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _filterStatus != null
                ? 'No ${_orderStatusLabel(_filterStatus!).toLowerCase()} orders today'
                : 'Orders placed today will appear here',
            style: const TextStyle(
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
// ORDER CARD WIDGET
// ─────────────────────────────────────────────────────────────────

class _OrderCard extends StatelessWidget {
  final TableOrderEntity order;
  final DateTime now;
  final VoidCallback onTap;

  const _OrderCard({
    required this.order,
    required this.now,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final items = decodeOrderItems(order.itemsJson);
    final color = _orderStatusColor(order.status);
    final elapsed = now.difference(order.createdAt);
    final isActive =
        order.status == TableOrderStatus.open ||
        order.status == TableOrderStatus.sentToKitchen;
    final isUrgent =
        order.status == TableOrderStatus.sentToKitchen &&
        order.sentToKitchenAt != null &&
        now.difference(order.sentToKitchenAt!).inMinutes >= 15;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withValues(alpha: 0.95),
                Colors.white.withValues(alpha: 0.85),
                color.withValues(alpha: 0.03),
              ],
              stops: const [0.0, 0.6, 1.0],
            ),
            border: Border.all(
              color: isUrgent
                  ? const Color(0xFFFCA5A5)
                  : color.withValues(alpha: 0.25),
              width: isUrgent ? 1.8 : 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.08),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
              BoxShadow(
                color: Colors.white.withValues(alpha: 0.8),
                blurRadius: 1,
                offset: const Offset(0, -1),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Header row ─────────────────────────
                    Row(
                      children: [
                        // Table badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: color.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.table_restaurant_rounded,
                                size: 13,
                                color: color,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                'T-${order.tableNumber}',
                                style: TextStyle(
                                  color: color,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w900,
                                  fontFamily: 'Literata',
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        // Guest name
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                order.guestName ?? 'Guest',
                                style: const TextStyle(
                                  color: Color(0xFF1E293B),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  fontFamily: 'Literata',
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (order.occupiedSeats > 0)
                                Text(
                                  '${order.occupiedSeats} guests',
                                  style: const TextStyle(
                                    color: Color(0xFF94A3B8),
                                    fontSize: 10,
                                    fontFamily: 'Literata',
                                  ),
                                ),
                            ],
                          ),
                        ),
                        // Status badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: color.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (isActive)
                                _MiniPulseDot(color: color)
                              else
                                Icon(
                                  _orderStatusIcon(order.status),
                                  size: 12,
                                  color: color,
                                ),
                              const SizedBox(width: 5),
                              Text(
                                _orderStatusLabel(order.status),
                                style: TextStyle(
                                  color: color,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  fontFamily: 'Literata',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // ── Items preview ──────────────────────
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFFE2E8F0).withValues(alpha: 0.6),
                        ),
                      ),
                      child: Column(
                        children: [
                          for (
                            int idx = 0;
                            idx < items.length && idx < 3;
                            idx++
                          )
                            Padding(
                              padding: EdgeInsets.only(
                                bottom: idx < 2 && idx < items.length - 1
                                    ? 6
                                    : 0,
                              ),
                              child: Row(
                                children: [
                                  // Veg/non-veg dot
                                  Container(
                                    width: 7,
                                    height: 7,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: items[idx].isVeg
                                          ? const Color(0xFF16A34A)
                                          : const Color(0xFFDC2626),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      items[idx].name,
                                      style: TextStyle(
                                        color: const Color(0xFF475569),
                                        fontSize: 12,
                                        fontFamily: 'Literata',
                                        fontWeight: FontWeight.w500,
                                        decoration: items[idx].isReady
                                            ? TextDecoration.lineThrough
                                            : null,
                                        decorationColor: const Color(
                                          0xFF94A3B8,
                                        ),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Text(
                                    '×${items[idx].quantity}',
                                    style: const TextStyle(
                                      color: Color(0xFF94A3B8),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      fontFamily: 'Literata',
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '₹${items[idx].lineTotal.toStringAsFixed(0)}',
                                    style: const TextStyle(
                                      color: Color(0xFF475569),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      fontFamily: 'Literata',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          if (items.length > 3)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                '+${items.length - 3} more items',
                                style: TextStyle(
                                  color: color.withValues(alpha: 0.7),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: 'Literata',
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    // ── Footer row ─────────────────────────
                    Row(
                      children: [
                        // Time elapsed
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: isUrgent
                                ? const Color(0xFFFEE2E2)
                                : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(8),
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
                                  fontFeatures: const [
                                    FontFeature.tabularFigures(),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Items count
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${items.length} items',
                            style: const TextStyle(
                              color: Color(0xFF94A3B8),
                              fontSize: 11,
                              fontFamily: 'Literata',
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const Spacer(),
                        // Bill number (if billed)
                        if (order.billNumber != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(
                                0xFF8B5CF6,
                              ).withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              order.billNumber!,
                              style: const TextStyle(
                                color: Color(0xFF8B5CF6),
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                fontFamily: 'Literata',
                              ),
                            ),
                          ),
                        if (order.billNumber == null)
                          // Total amount
                          Text(
                            '₹${order.totalAmount.toStringAsFixed(0)}',
                            style: TextStyle(
                              color: color,
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              fontFamily: 'Literata',
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _formatElapsed(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes % 60;
    if (h > 0) return '${h}h ${m}m';
    return '${m}m';
  }
}

// ─────────────────────────────────────────────────────────────────
// MINI PULSE DOT (for active order status badge)
// ─────────────────────────────────────────────────────────────────

class _MiniPulseDot extends StatefulWidget {
  final Color color;
  const _MiniPulseDot({required this.color});

  @override
  State<_MiniPulseDot> createState() => _MiniPulseDotState();
}

class _MiniPulseDotState extends State<_MiniPulseDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _anim;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Opacity(
        opacity: 0.5 + 0.5 * _anim.value,
        child: Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.color,
            boxShadow: [
              BoxShadow(
                color: widget.color.withValues(alpha: 0.5),
                blurRadius: 4,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

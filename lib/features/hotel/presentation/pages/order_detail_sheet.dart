import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../offline/entities/table_order_entity.dart';
import '../../offline/controllers/table_offline_controller.dart';
import '../../offline/controllers/table_order_controller.dart';
import 'add_order_sheet.dart';

/// Bottom sheet showing full order details with actions.
class OrderDetailSheet extends StatefulWidget {
  final TableOrderEntity order;
  const OrderDetailSheet({super.key, required this.order});

  @override
  State<OrderDetailSheet> createState() => _OrderDetailSheetState();
}

class _OrderDetailSheetState extends State<OrderDetailSheet> {
  final _ctrl = TableOrderController.instance;

  late TableOrderEntity _order;
  late List<OrderItem> _items;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _order = widget.order;
    _items = decodeOrderItems(_order.itemsJson);
  }

  // ── Actions ──────────────────────────────────────────────────────

  Future<void> _sendToKitchen() async {
    HapticFeedback.mediumImpact();
    setState(() => _saving = true);
    await _ctrl.sendToKitchen(_order.id, _order.localTableId);
    if (mounted) Navigator.pop(context, true);
  }

  Future<void> _markServed() async {
    HapticFeedback.mediumImpact();
    setState(() => _saving = true);
    await _ctrl.markServed(_order.id, _order.localTableId);
    if (mounted) Navigator.pop(context, true);
  }

  Future<void> _generateBill() async {
    HapticFeedback.mediumImpact();
    setState(() => _saving = true);
    await _ctrl.generateBill(_order.id, _order.localTableId);
    if (mounted) Navigator.pop(context, true);
  }

  Future<void> _openAddMoreItems() async {
    final table = await TableOfflineController.instance.getTableById(
      _order.localTableId,
    );
    if (!mounted) return;
    if (table == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Table not found'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          backgroundColor: const Color(0xFFB45309),
        ),
      );
      return;
    }
    final latest = await _ctrl.getOrderById(_order.id);
    if (!mounted || latest == null) return;

    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => AddOrderSheet(table: table, existingOrder: latest),
      ),
    );
    if (changed == true && mounted) {
      final again = await _ctrl.getOrderById(_order.id);
      if (again != null) {
        setState(() {
          _order = again;
          _items = decodeOrderItems(_order.itemsJson);
        });
      }
    }
  }

  Future<void> _cancelOrder() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF142318),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Cancel Order',
          style: TextStyle(
            color: Colors.white,
            fontFamily: 'Literata',
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          'Cancel order for table "${_order.tableNumber}"? This will free the table.',
          style: const TextStyle(color: Colors.white60, fontFamily: 'Literata'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Keep', style: TextStyle(color: Colors.white38)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Cancel Order',
              style: TextStyle(
                color: Color(0xFFF87171),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      HapticFeedback.mediumImpact();
      setState(() => _saving = true);
      await _ctrl.cancelOrder(_order.id, _order.localTableId);
      if (mounted) Navigator.pop(context, true);
    }
  }

  // ── Build ────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(_order.status);

    return DraggableScrollableSheet(
      initialChildSize: 0.72,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      expand: false,
      builder: (_, scrollCtrl) {
        return Container(
          decoration: BoxDecoration(
            color: const Color(0xFF0E1C17),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border(
              top: BorderSide(color: color.withValues(alpha: 0.35), width: 1.5),
            ),
          ),
          child: ListView(
            controller: scrollCtrl,
            padding: EdgeInsets.fromLTRB(
              24,
              12,
              24,
              MediaQuery.of(context).padding.bottom + 24,
            ),
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // ── Header ────────────────────────────────────
              _buildHeader(color),
              const SizedBox(height: 20),

              // ── Order Timeline ────────────────────────────
              _buildTimeline(color),
              const SizedBox(height: 20),

              // ── Info cards ────────────────────────────────
              _buildInfoRow(),
              const SizedBox(height: 20),

              // ── Guest info ────────────────────────────────
              if (_order.guestName != null && _order.guestName!.isNotEmpty) ...[
                _buildDetailRow(
                  Icons.person_rounded,
                  'Guest',
                  _order.guestName!,
                ),
                const SizedBox(height: 8),
              ],
              if (_order.guestPhone != null &&
                  _order.guestPhone!.isNotEmpty) ...[
                _buildDetailRow(
                  Icons.phone_rounded,
                  'Phone',
                  _order.guestPhone!,
                ),
                const SizedBox(height: 8),
              ],
              if (_order.notes != null && _order.notes!.isNotEmpty) ...[
                _buildDetailRow(Icons.notes_rounded, 'Notes', _order.notes!),
                const SizedBox(height: 8),
              ],

              const SizedBox(height: 20),
              const Divider(color: Color(0xFF1E3329), thickness: 1),
              const SizedBox(height: 16),

              // ── Items list ────────────────────────────────
              _buildItemsSection(color),
              const SizedBox(height: 20),

              // ── Bill summary ──────────────────────────────
              _buildBillSummary(color),
              const SizedBox(height: 24),

              // ── Actions ───────────────────────────────────
              if (!_saving) _buildActions(color),

              if (_saving)
                const Padding(
                  padding: EdgeInsets.only(top: 20),
                  child: Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF4ADE80),
                      strokeWidth: 2,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  // ── Header ────────────────────────────────────────────────────

  Widget _buildHeader(Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withValues(alpha: 0.4)),
          ),
          child: Icon(Icons.receipt_long_rounded, color: color, size: 28),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Table ${_order.tableNumber}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  fontFamily: 'Literata',
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: color.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _statusIcon(_order.status),
                          color: color,
                          size: 12,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          _statusLabel(_order.status),
                          style: TextStyle(
                            color: color,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'Literata',
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (_order.billNumber != null)
                    Text(
                      _order.billNumber!,
                      style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 11,
                        fontFamily: 'Literata',
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
        // Cancel button for non-terminal orders
        if (_order.status != TableOrderStatus.billed &&
            _order.status != TableOrderStatus.cancelled)
          IconButton(
            onPressed: _cancelOrder,
            icon: const Icon(
              Icons.cancel_outlined,
              color: Color(0xFFF87171),
              size: 22,
            ),
          ),
      ],
    );
  }

  // ── Timeline ──────────────────────────────────────────────────

  Widget _buildTimeline(Color color) {
    final stages = <_Stage>[
      _Stage(
        'Created',
        Icons.edit_note_rounded,
        _order.createdAt,
        true,
        const Color(0xFF3B82F6),
      ),
      _Stage(
        'Kitchen',
        Icons.soup_kitchen_rounded,
        _order.sentToKitchenAt,
        _order.sentToKitchenAt != null,
        const Color(0xFFF59E0B),
      ),
      _Stage(
        'Served',
        Icons.room_service_rounded,
        _order.servedAt,
        _order.servedAt != null,
        const Color(0xFF22C55E),
      ),
      _Stage(
        'Billed',
        Icons.receipt_long_rounded,
        _order.billedAt,
        _order.billedAt != null,
        const Color(0xFF8B5CF6),
      ),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 4, bottom: 12),
            child: Text(
              'ORDER TIMELINE',
              style: TextStyle(
                color: Colors.white38,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                fontFamily: 'Literata',
                letterSpacing: 1.2,
              ),
            ),
          ),
          Row(
            children: [
              for (int i = 0; i < stages.length; i++) ...[
                Expanded(child: _buildStageNode(stages[i])),
                if (i < stages.length - 1)
                  _buildConnector(stages[i + 1].reached),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStageNode(_Stage stage) {
    final isActive = stage.reached;
    final color = isActive ? stage.color : Colors.white.withValues(alpha: 0.15);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive
                ? color.withValues(alpha: 0.2)
                : Colors.white.withValues(alpha: 0.04),
            border: Border.all(
              color: isActive ? color : Colors.white.withValues(alpha: 0.1),
              width: isActive ? 2 : 1,
            ),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: color.withValues(alpha: 0.3),
                      blurRadius: 8,
                    ),
                  ]
                : [],
          ),
          child: Icon(
            stage.icon,
            size: 14,
            color: isActive ? color : Colors.white.withValues(alpha: 0.2),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          stage.label,
          style: TextStyle(
            color: isActive ? Colors.white70 : Colors.white24,
            fontSize: 9,
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
            fontFamily: 'Literata',
          ),
        ),
        const SizedBox(height: 2),
        Text(
          stage.time != null
              ? '${stage.time!.hour.toString().padLeft(2, '0')}:${stage.time!.minute.toString().padLeft(2, '0')}'
              : '—',
          style: TextStyle(
            color: isActive
                ? stage.color.withValues(alpha: 0.8)
                : Colors.white.withValues(alpha: 0.12),
            fontSize: 9,
            fontFamily: 'Literata',
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildConnector(bool nextReached) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 28),
        child: Container(
          height: 2,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(1),
            gradient: nextReached
                ? const LinearGradient(
                    colors: [Color(0xFF22C55E), Color(0xFF60A5FA)],
                  )
                : null,
            color: nextReached ? null : Colors.white.withValues(alpha: 0.08),
          ),
        ),
      ),
    );
  }

  // ── Info row ──────────────────────────────────────────────────

  Widget _buildInfoRow() {
    final elapsed = DateTime.now().difference(_order.createdAt);
    return Row(
      children: [
        _infoCard(
          Icons.people_rounded,
          '${_order.occupiedSeats}',
          'Guests',
          const Color(0xFF60A5FA),
        ),
        const SizedBox(width: 10),
        _infoCard(
          Icons.schedule_rounded,
          _formatDuration(elapsed),
          'Duration',
          const Color(0xFFFBBF24),
        ),
        const SizedBox(width: 10),
        _infoCard(
          Icons.restaurant_rounded,
          '${_items.length}',
          'Items',
          const Color(0xFF22C55E),
        ),
      ],
    );
  }

  Widget _infoCard(IconData icon, String value, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.15)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color.withValues(alpha: 0.7), size: 18),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 16,
                fontWeight: FontWeight.w900,
                fontFamily: 'Literata',
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: color.withValues(alpha: 0.5),
                fontSize: 9,
                fontFamily: 'Literata',
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white38, size: 16),
          const SizedBox(width: 10),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white38,
              fontSize: 12,
              fontFamily: 'Literata',
            ),
          ),
          const Spacer(),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                fontFamily: 'Literata',
              ),
              textAlign: TextAlign.end,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // ── Items section ─────────────────────────────────────────────

  Widget _buildItemsSection(Color color) {
    // Group items by category
    final grouped = <String, List<OrderItem>>{};
    for (final item in _items) {
      grouped.putIfAbsent(item.category, () => []).add(item);
    }
    final categories = grouped.keys.toList()..sort();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'ORDER ITEMS',
              style: TextStyle(
                color: Colors.white38,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                fontFamily: 'Literata',
                letterSpacing: 1.2,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${_items.length} items',
                style: TextStyle(
                  color: color,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Literata',
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        for (final cat in categories) ...[
          // Category header
          Padding(
            padding: const EdgeInsets.only(bottom: 8, top: 4),
            child: Text(
              cat.toUpperCase(),
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.25),
                fontSize: 9,
                fontWeight: FontWeight.w700,
                fontFamily: 'Literata',
                letterSpacing: 1,
              ),
            ),
          ),
          // Items
          for (final item in grouped[cat]!) _buildItemRow(item),
        ],
      ],
    );
  }

  Widget _buildItemRow(OrderItem item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: item.isReady
              ? const Color(0xFF22C55E).withValues(alpha: 0.06)
              : Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: item.isReady
                ? const Color(0xFF22C55E).withValues(alpha: 0.2)
                : Colors.white.withValues(alpha: 0.07),
          ),
        ),
        child: Row(
          children: [
            // Ready indicator
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: item.isReady
                    ? const Color(0xFF22C55E)
                    : Colors.transparent,
                border: Border.all(
                  color: item.isReady
                      ? const Color(0xFF22C55E)
                      : Colors.white.withValues(alpha: 0.15),
                  width: 1.5,
                ),
              ),
              child: item.isReady
                  ? const Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 12,
                    )
                  : null,
            ),
            const SizedBox(width: 10),
            // Veg dot
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: item.isVeg
                    ? const Color(0xFF22C55E)
                    : const Color(0xFFEF4444),
              ),
            ),
            const SizedBox(width: 10),
            // Name
            Expanded(
              child: Text(
                item.name,
                style: TextStyle(
                  color: item.isReady ? Colors.white38 : Colors.white70,
                  fontSize: 13,
                  fontFamily: 'Literata',
                  fontWeight: FontWeight.w500,
                  decoration: item.isReady ? TextDecoration.lineThrough : null,
                  decorationColor: Colors.white38,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // Qty
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '×${item.quantity}',
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Literata',
                ),
              ),
            ),
            const SizedBox(width: 10),
            // Price
            Text(
              '₹${item.lineTotal.toStringAsFixed(0)}',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 13,
                fontWeight: FontWeight.w800,
                fontFamily: 'Literata',
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Bill summary ──────────────────────────────────────────────

  Widget _buildBillSummary(Color color) {
    const gstRate = 0.025;
    final subtotal = _order.totalAmount;
    final cgst = subtotal * gstRate;
    final sgst = subtotal * gstRate;
    final grandTotal = subtotal + cgst + sgst;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Column(
        children: [
          _summaryRow('Subtotal', '₹${subtotal.toStringAsFixed(2)}', false),
          const SizedBox(height: 6),
          _summaryRow('CGST (2.5%)', '₹${cgst.toStringAsFixed(2)}', false),
          const SizedBox(height: 6),
          _summaryRow('SGST (2.5%)', '₹${sgst.toStringAsFixed(2)}', false),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Divider(
              color: Colors.white.withValues(alpha: 0.1),
              thickness: 1,
            ),
          ),
          _summaryRow('Grand Total', '₹${grandTotal.toStringAsFixed(2)}', true),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value, bool isBold) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: isBold ? Colors.white : Colors.white54,
            fontSize: isBold ? 15 : 12,
            fontWeight: isBold ? FontWeight.w800 : FontWeight.w500,
            fontFamily: 'Literata',
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: isBold ? const Color(0xFF4ADE80) : Colors.white70,
            fontSize: isBold ? 18 : 13,
            fontWeight: isBold ? FontWeight.w900 : FontWeight.w600,
            fontFamily: 'Literata',
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }

  // ── Actions ───────────────────────────────────────────────────

  Widget _buildActions(Color color) {
    switch (_order.status) {
      case TableOrderStatus.open:
        return Column(
          children: [
            _actionButton(
              'Send to Kitchen',
              Icons.soup_kitchen_rounded,
              const Color(0xFFF59E0B),
              _sendToKitchen,
              filled: true,
            ),
            const SizedBox(height: 10),
            _actionButton(
              'Cancel Order',
              Icons.cancel_outlined,
              const Color(0xFFEF4444),
              _cancelOrder,
            ),
          ],
        );
      case TableOrderStatus.sentToKitchen:
        return Column(
          children: [
            _actionButton(
              'Add more items',
              Icons.add_shopping_cart_rounded,
              const Color(0xFF38BDF8),
              _openAddMoreItems,
            ),
            const SizedBox(height: 10),
            _actionButton(
              'Mark as Served',
              Icons.room_service_rounded,
              const Color(0xFF22C55E),
              _markServed,
              filled: true,
            ),
            const SizedBox(height: 10),
            _actionButton(
              'Cancel Order',
              Icons.cancel_outlined,
              const Color(0xFFEF4444),
              _cancelOrder,
            ),
          ],
        );
      case TableOrderStatus.served:
        return Column(
          children: [
            _actionButton(
              'Add more items',
              Icons.add_shopping_cart_rounded,
              const Color(0xFF38BDF8),
              _openAddMoreItems,
            ),
            const SizedBox(height: 10),
            _actionButton(
              'Generate Bill',
              Icons.receipt_long_rounded,
              const Color(0xFF8B5CF6),
              _generateBill,
              filled: true,
            ),
          ],
        );
      case TableOrderStatus.billed:
      case TableOrderStatus.cancelled:
        return const SizedBox.shrink();
    }
  }

  Widget _actionButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap, {
    bool filled = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: filled ? color : color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: color.withValues(alpha: filled ? 1.0 : 0.3),
          ),
          boxShadow: filled
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: filled ? Colors.white : color),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: filled ? Colors.white : color,
                fontSize: 14,
                fontWeight: FontWeight.w700,
                fontFamily: 'Literata',
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────

  String _formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes % 60;
    if (h > 0) return '${h}h ${m}m';
    return '${m}m';
  }

  Color _statusColor(TableOrderStatus s) {
    switch (s) {
      case TableOrderStatus.open:
        return const Color(0xFF3B82F6);
      case TableOrderStatus.sentToKitchen:
        return const Color(0xFFF59E0B);
      case TableOrderStatus.served:
        return const Color(0xFF22C55E);
      case TableOrderStatus.billed:
        return const Color(0xFF8B5CF6);
      case TableOrderStatus.cancelled:
        return const Color(0xFFEF4444);
    }
  }

  String _statusLabel(TableOrderStatus s) {
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

  IconData _statusIcon(TableOrderStatus s) {
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
}

class _Stage {
  final String label;
  final IconData icon;
  final DateTime? time;
  final bool reached;
  final Color color;

  const _Stage(this.label, this.icon, this.time, this.reached, this.color);
}

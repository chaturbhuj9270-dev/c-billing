import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../offline/entities/table_entity.dart';
import '../../offline/entities/table_order_entity.dart';
import '../../offline/controllers/table_offline_controller.dart';
import '../../offline/controllers/table_order_controller.dart';
import 'table_status_helpers.dart';
import 'add_order_sheet.dart';
import 'bill_preview_sheet.dart';

class TableDetailSheet extends StatefulWidget {
  final TableEntity table;
  const TableDetailSheet({super.key, required this.table});

  @override
  State<TableDetailSheet> createState() => _TableDetailSheetState();
}

class _TableDetailSheetState extends State<TableDetailSheet> {
  final _ctrl = TableOfflineController.instance;
  final _orderCtrl = TableOrderController.instance;

  late TableEntity _table;
  TableOrderEntity? _activeOrder;
  bool _saving = false;
  bool _orderLoading = true;

  // Admin controls expanded state
  bool _adminExpanded = false;

  @override
  void initState() {
    super.initState();
    _table = widget.table;
    _loadOrder();
  }

  Future<void> _loadOrder() async {
    final order = await _orderCtrl.getActiveOrderForTable(_table.id);
    if (mounted)
      setState(() {
        _activeOrder = order;
        _orderLoading = false;
      });
  }

  // ── Order flow actions ───────────────────────────────────────────

  Future<void> _openAddOrEditOrder() async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) =>
            AddOrderSheet(table: _table, existingOrder: _activeOrder),
      ),
    );
    if (changed == true && mounted) {
      await _loadOrder();
      final t = await _ctrl.getTableById(_table.id);
      if (t != null) _table = t;
      setState(() {});
    }
  }

  Future<void> _sendToKitchen() async {
    if (_activeOrder == null) return;
    HapticFeedback.mediumImpact();
    setState(() => _saving = true);
    await _orderCtrl.sendToKitchen(_activeOrder!.id, _table.id);
    if (mounted) Navigator.pop(context, true);
  }

  Future<void> _markServed() async {
    if (_activeOrder == null) return;
    HapticFeedback.mediumImpact();
    setState(() => _saving = true);
    await _orderCtrl.markServed(_activeOrder!.id, _table.id);
    if (mounted) Navigator.pop(context, true);
  }

  Future<void> _openBillPreview() async {
    if (_activeOrder == null) return;
    final done = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BillPreviewSheet(table: _table, order: _activeOrder!),
    );
    if (done == true && mounted) Navigator.pop(context, true);
  }

  Future<void> _changeStatus(TableStatus newStatus) async {
    // For active/waiting, optionally collect guest info
    if (newStatus == TableStatus.active || newStatus == TableStatus.waiting) {
      await _showGuestDialog(newStatus);
      return;
    }

    HapticFeedback.mediumImpact();
    setState(() => _saving = true);
    final updated = await _ctrl.setStatus(_table.id, newStatus);
    if (mounted) {
      setState(() {
        _saving = false;
        if (updated != null) _table = updated;
      });
      Navigator.pop(context, true);
    }
  }

  Future<void> _showGuestDialog(TableStatus newStatus) async {
    final nameCtrl = TextEditingController(text: _table.guestName ?? '');
    final phoneCtrl = TextEditingController(text: _table.guestPhone ?? '');
    final seatsCtrl = TextEditingController(
      text: (_table.occupiedSeats > 0 ? _table.occupiedSeats : _table.capacity)
          .toString(),
    );
    final notesCtrl = TextEditingController(text: _table.notes ?? '');

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF142318).withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      newStatus == TableStatus.active
                          ? 'Seat Guests'
                          : 'Mark as Waiting',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Literata',
                      ),
                    ),
                    const SizedBox(height: 20),
                    _dialogField(nameCtrl, 'Guest Name', Icons.person_rounded),
                    const SizedBox(height: 12),
                    _dialogField(
                      phoneCtrl,
                      'Phone (optional)',
                      Icons.phone_rounded,
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 12),
                    _dialogField(
                      seatsCtrl,
                      'Seats',
                      Icons.people_rounded,
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 12),
                    _dialogField(
                      notesCtrl,
                      'Notes (optional)',
                      Icons.notes_rounded,
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: const Text(
                              'Cancel',
                              style: TextStyle(
                                color: Colors.white38,
                                fontFamily: 'Literata',
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF22C55E),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            child: Text(
                              newStatus == TableStatus.active
                                  ? 'Seat'
                                  : 'Confirm',
                              style: const TextStyle(
                                fontFamily: 'Literata',
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
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
        ),
      ),
    );

    if (confirmed != true || !mounted) return;

    HapticFeedback.mediumImpact();
    setState(() => _saving = true);
    final updated = await _ctrl.setStatus(
      _table.id,
      newStatus,
      guestName: nameCtrl.text.trim().isEmpty ? null : nameCtrl.text.trim(),
      guestPhone: phoneCtrl.text.trim().isEmpty ? null : phoneCtrl.text.trim(),
      notes: notesCtrl.text.trim().isEmpty ? null : notesCtrl.text.trim(),
      occupiedSeats: int.tryParse(seatsCtrl.text.trim()) ?? _table.capacity,
    );
    if (mounted) {
      setState(() {
        _saving = false;
        if (updated != null) _table = updated;
      });
      Navigator.pop(context, true);
    }
  }

  Widget _dialogField(
    TextEditingController ctrl,
    String hint,
    IconData icon, {
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: TextField(
        controller: ctrl,
        keyboardType: keyboardType,
        style: const TextStyle(
          color: Colors.white,
          fontFamily: 'Literata',
          fontSize: 14,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(
            color: Colors.white38,
            fontFamily: 'Literata',
            fontSize: 14,
          ),
          prefixIcon: Icon(icon, color: Colors.white38, size: 18),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 12,
          ),
        ),
      ),
    );
  }

  Future<void> _deleteTable() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF142318),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Delete Table',
          style: TextStyle(
            color: Colors.white,
            fontFamily: 'Literata',
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          'Remove table "${_table.tableNumber}"?',
          style: const TextStyle(color: Colors.white60, fontFamily: 'Literata'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white38),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Delete',
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
      await _ctrl.deleteTable(_table.id);
      if (mounted) Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = tableStatusColor(_table.status);
    final mins = _table.occupiedAt != null
        ? DateTime.now().difference(_table.occupiedAt!).inMinutes
        : 0;

    return DraggableScrollableSheet(
      initialChildSize: 0.62,
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

              // ── Header ────────────────────────────────────────
              Row(
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
                    child: Icon(
                      tableStatusIcon(_table.status),
                      color: color,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Table ${_table.tableNumber}',
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
                                border: Border.all(
                                  color: color.withValues(alpha: 0.4),
                                ),
                              ),
                              child: Text(
                                tableStatusLabel(_table.status),
                                style: TextStyle(
                                  color: color,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  fontFamily: 'Literata',
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _table.section,
                              style: const TextStyle(
                                color: Colors.white38,
                                fontSize: 12,
                                fontFamily: 'Literata',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Delete button
                  IconButton(
                    onPressed: _deleteTable,
                    icon: const Icon(
                      Icons.delete_outline_rounded,
                      color: Color(0xFFF87171),
                      size: 22,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // ── Order timeline (top) ──────────────────────────
              if (!_orderLoading && _activeOrder != null) ...[
                _buildOrderProgressBar(),
                const SizedBox(height: 16),
              ],

              // ── Info cards ────────────────────────────────────
              Row(
                children: [
                  _infoCard(
                    Icons.people_rounded,
                    '${_table.occupiedSeats}/${_table.capacity}',
                    'Seats',
                    const Color(0xFF60A5FA),
                  ),
                  const SizedBox(width: 10),
                  _infoCard(
                    Icons.schedule_rounded,
                    _table.status == TableStatus.active
                        ? _formatMins(mins)
                        : '—',
                    'Duration',
                    const Color(0xFFFBBF24),
                  ),
                  const SizedBox(width: 10),
                  _infoCard(
                    Icons.sync_rounded,
                    _table.needsSync ? 'Pending' : 'Synced',
                    'Sync',
                    _table.needsSync
                        ? const Color(0xFFF59E0B)
                        : const Color(0xFF4ADE80),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // ── Guest info ────────────────────────────────────
              if (_table.guestName != null && _table.guestName!.isNotEmpty) ...[
                _buildDetailRow(
                  Icons.person_rounded,
                  'Guest',
                  _table.guestName!,
                ),
                const SizedBox(height: 8),
              ],
              if (_table.guestPhone != null &&
                  _table.guestPhone!.isNotEmpty) ...[
                _buildDetailRow(
                  Icons.phone_rounded,
                  'Phone',
                  _table.guestPhone!,
                ),
                const SizedBox(height: 8),
              ],
              if (_table.notes != null && _table.notes!.isNotEmpty) ...[
                _buildDetailRow(Icons.notes_rounded, 'Notes', _table.notes!),
                const SizedBox(height: 8),
              ],

              const SizedBox(height: 24),
              const Divider(color: Color(0xFF1E3329), thickness: 1),
              const SizedBox(height: 20),

              // ── Order section ─────────────────────────────────
              if (_orderLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(12),
                    child: CircularProgressIndicator(
                      color: Color(0xFF4ADE80),
                      strokeWidth: 2,
                    ),
                  ),
                )
              else ...[
                _buildOrderSection(),
                const SizedBox(height: 16),
                _buildFlowActions(),
              ],

              const SizedBox(height: 20),

              // ── Admin controls (collapsible) ──────────────────
              GestureDetector(
                onTap: () => setState(() => _adminExpanded = !_adminExpanded),
                child: Row(
                  children: [
                    const Text(
                      'ADMIN CONTROLS',
                      style: TextStyle(
                        color: Colors.white24,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Literata',
                        letterSpacing: 1.2,
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      _adminExpanded
                          ? Icons.expand_less_rounded
                          : Icons.expand_more_rounded,
                      color: Colors.white24,
                      size: 18,
                    ),
                  ],
                ),
              ),
              AnimatedCrossFade(
                firstChild: const SizedBox.shrink(),
                secondChild: Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: TableStatus.values
                        .where((s) => s != _table.status)
                        .map((s) => _statusButton(s))
                        .toList(),
                  ),
                ),
                crossFadeState: _adminExpanded
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                duration: const Duration(milliseconds: 220),
              ),

              const SizedBox(height: 4),
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

  // ── Order progress bar ────────────────────────────────────────

  Widget _buildOrderProgressBar() {
    final order = _activeOrder!;

    // 4 stages: Active → Waiting → Served → Completed
    final stages = <_ProgressStage>[
      _ProgressStage(
        label: 'Active',
        icon: Icons.restaurant_rounded,
        time: order.createdAt,
        reached: true, // always reached if order exists
        color: const Color(0xFF22C55E),
      ),
      _ProgressStage(
        label: 'Kitchen',
        icon: Icons.kitchen_rounded,
        time: order.sentToKitchenAt,
        reached: order.sentToKitchenAt != null,
        color: const Color(0xFF60A5FA),
      ),
      _ProgressStage(
        label: 'Served',
        icon: Icons.done_all_rounded,
        time: order.servedAt,
        reached: order.servedAt != null,
        color: const Color(0xFFA78BFA),
      ),
      _ProgressStage(
        label: 'Completed',
        icon: Icons.check_circle_rounded,
        time: order.billedAt,
        reached: order.billedAt != null,
        color: const Color(0xFFF59E0B),
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
          // Progress line + nodes
          Row(
            children: [
              for (int i = 0; i < stages.length; i++) ...[
                Expanded(child: _buildStageNode(stages[i], i, stages.length)),
                if (i < stages.length - 1)
                  _buildConnector(stages[i + 1].reached),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStageNode(_ProgressStage stage, int index, int total) {
    final isActive = stage.reached;
    final color = isActive ? stage.color : Colors.white.withValues(alpha: 0.15);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Circle node
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
        // Label
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
        // Time
        Text(
          stage.time != null
              ? '${stage.time!.hour.toString().padLeft(2, '0')}:${stage.time!.minute.toString().padLeft(2, '0')}:${stage.time!.second.toString().padLeft(2, '0')}'
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

  // ── Order section ─────────────────────────────────────────────

  Widget _buildOrderSection() {
    if (_activeOrder == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.receipt_long_rounded,
              color: Colors.white24,
              size: 18,
            ),
            const SizedBox(width: 12),
            const Text(
              'No active order',
              style: TextStyle(
                color: Colors.white38,
                fontSize: 13,
                fontFamily: 'Literata',
              ),
            ),
            const Spacer(),
            if (_table.status == TableStatus.active ||
                _table.status == TableStatus.empty ||
                _table.status == TableStatus.reserved)
              GestureDetector(
                onTap: _openAddOrEditOrder,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF22C55E).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: const Color(0xFF22C55E).withValues(alpha: 0.35),
                    ),
                  ),
                  child: const Text(
                    'Add Order',
                    style: TextStyle(
                      color: Color(0xFF4ADE80),
                      fontSize: 12,
                      fontFamily: 'Literata',
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
    }

    final items = decodeOrderItems(_activeOrder!.itemsJson);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF22C55E).withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFF22C55E).withValues(alpha: 0.18),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.receipt_long_rounded,
                color: Color(0xFF4ADE80),
                size: 16,
              ),
              const SizedBox(width: 8),
              const Text(
                'ORDER',
                style: TextStyle(
                  color: Color(0xFF4ADE80),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Literata',
                  letterSpacing: 1,
                ),
              ),
              const Spacer(),
              // Edit / add items (allowed until billed)
              if (_activeOrder!.status != TableOrderStatus.billed &&
                  _activeOrder!.status != TableOrderStatus.cancelled)
                GestureDetector(
                  onTap: _openAddOrEditOrder,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.add_circle_outline_rounded,
                        color: Color(0xFF4ADE80),
                        size: 15,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _activeOrder!.status == TableOrderStatus.open
                            ? 'Edit'
                            : 'Add Items',
                        style: const TextStyle(
                          color: Color(0xFF4ADE80),
                          fontSize: 12,
                          fontFamily: 'Literata',
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 5),
              child: Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    margin: const EdgeInsets.only(right: 8, top: 1),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: item.isVeg
                          ? const Color(0xFF4ADE80)
                          : const Color(0xFFF87171),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      item.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontFamily: 'Literata',
                      ),
                    ),
                  ),
                  Text(
                    '${item.quantity}×  ₹${item.lineTotal.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontFamily: 'Literata',
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Divider(color: Colors.white.withValues(alpha: 0.07), height: 1),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${items.length} item${items.length == 1 ? '' : 's'}',
                style: const TextStyle(
                  color: Colors.white38,
                  fontSize: 12,
                  fontFamily: 'Literata',
                ),
              ),
              Text(
                '₹${_activeOrder!.totalAmount.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: Color(0xFF4ADE80),
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  fontFamily: 'Literata',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Flow action buttons ───────────────────────────────────────

  Widget _buildFlowActions() {
    switch (_table.status) {
      case TableStatus.active:
        if (_activeOrder == null) return const SizedBox.shrink();
        return _primaryButton(
          label: 'Send to Kitchen',
          icon: Icons.kitchen_rounded,
          color: const Color(0xFF22C55E),
          onPressed: _sendToKitchen,
        );

      case TableStatus.waiting:
        return _primaryButton(
          label: 'Mark as Served',
          icon: Icons.done_all_rounded,
          color: const Color(0xFF60A5FA),
          onPressed: _markServed,
        );

      case TableStatus.served:
        return _primaryButton(
          label: 'Generate & Print Bill',
          icon: Icons.receipt_long_rounded,
          color: const Color(0xFFF59E0B),
          onPressed: _openBillPreview,
        );

      default:
        return const SizedBox.shrink();
    }
  }

  Widget _primaryButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton.icon(
        onPressed: _saving ? null : onPressed,
        icon: Icon(icon, size: 20),
        label: Text(
          label,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            fontFamily: 'Literata',
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          disabledBackgroundColor: color.withValues(alpha: 0.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 0,
        ),
      ),
    );
  }

  Widget _infoCard(IconData icon, String value, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 15,
                fontWeight: FontWeight.w700,
                fontFamily: 'Literata',
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white38,
                fontSize: 10,
                fontFamily: 'Literata',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white38, size: 16),
          const SizedBox(width: 12),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white38,
              fontSize: 12,
              fontFamily: 'Literata',
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              fontFamily: 'Literata',
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusButton(TableStatus status) {
    final color = tableStatusColor(status);
    return GestureDetector(
      onTap: () => _changeStatus(status),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.35)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(tableStatusIcon(status), color: color, size: 16),
            const SizedBox(width: 7),
            Text(
              'Mark ${tableStatusLabel(status)}',
              style: TextStyle(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                fontFamily: 'Literata',
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatMins(int mins) {
    if (mins < 60) return '${mins}m';
    return '${mins ~/ 60}h ${mins % 60}m';
  }
}

// Helper data class for progress bar stages
class _ProgressStage {
  final String label;
  final IconData icon;
  final DateTime? time;
  final bool reached;
  final Color color;

  const _ProgressStage({
    required this.label,
    required this.icon,
    required this.time,
    required this.reached,
    required this.color,
  });
}

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../offline/entities/table_entity.dart';
import '../../offline/controllers/table_offline_controller.dart';
import 'table_form_sheet.dart';
import 'table_detail_sheet.dart';
import 'add_order_sheet.dart';
import 'table_status_helpers.dart';

class TableManagementPage extends StatefulWidget {
  const TableManagementPage({super.key});

  @override
  State<TableManagementPage> createState() => _TableManagementPageState();
}

class _TableManagementPageState extends State<TableManagementPage>
    with TickerProviderStateMixin {
  final _ctrl = TableOfflineController.instance;

  List<TableEntity> _all = [];
  List<String> _sections = [];
  String? _selectedSection;
  TableStatus? _filterStatus;
  bool _isLoading = true;

  // Live-clock for "occupied since" countdown
  Timer? _clockTimer;
  DateTime _now = DateTime.now();

  // Stats
  int get _emptyCount =>
      _all.where((t) => t.status == TableStatus.empty).length;
  int get _activeCount =>
      _all.where((t) => t.status == TableStatus.active).length;
  int get _waitingCount =>
      _all.where((t) => t.status == TableStatus.waiting).length;
  int get _servedCount =>
      _all.where((t) => t.status == TableStatus.served).length;
  int get _reservedCount =>
      _all.where((t) => t.status == TableStatus.reserved).length;

  @override
  void initState() {
    super.initState();
    _load();

    // Tick every second for live timers
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final tables = await _ctrl.getAllTables();
    final sections = await _ctrl.getAllSections();
    if (mounted) {
      setState(() {
        _all = tables;
        _sections = sections;
        _isLoading = false;
        _now = DateTime.now();
      });
    }
  }

  List<TableEntity> get _filtered {
    return _all.where((t) {
      final matchSection =
          _selectedSection == null || t.section == _selectedSection;
      final matchStatus = _filterStatus == null || t.status == _filterStatus;
      return matchSection && matchStatus;
    }).toList();
  }

  // ── Navigation helpers ───────────────────────────────────────────

  Future<void> _onTableTap(TableEntity table) async {
    bool? changed;
    if (table.status == TableStatus.empty ||
        table.status == TableStatus.reserved) {
      changed = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          fullscreenDialog: true,
          builder: (_) => AddOrderSheet(table: table),
        ),
      );
    } else {
      changed = await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => TableDetailSheet(table: table),
      );
    }
    if (changed == true) _load();
  }

  Future<void> _openAddForm() async {
    final added = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const TableFormSheet(),
    );
    if (added == true) _load();
  }

  // ── Build ────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFF0FDF4),
            Color(0xFFF8FAFC),
            Color(0xFFFFFFFF),
          ],
          stops: [0.0, 0.45, 1.0],
        ),
      ),
      child: Stack(
        children: [
          // Ambient glow — top right
          Positioned(
            top: -60,
            right: -40,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF16A34A).withValues(alpha: 0.05),
                    const Color(0xFF16A34A).withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
          Column(
            children: [
              _buildStatsStrip(),
              if (_sections.length > 1) _buildSectionChips(),
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF16A34A),
                        ),
                      )
                    : _filtered.isEmpty
                    ? _buildEmptyState()
                    : _buildTableGrid(),
              ),
            ],
          ),
          Positioned(right: 16, bottom: 16, child: _buildFab()),
        ],
      ),
    );
  }

  // ── STATS STRIP ──────────────────────────────────────────────────

  Widget _buildStatsStrip() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
      child: LayoutBuilder(
        builder: (context, c) {
          final tiles = <Widget>[
            _buildStatTile('Empty', _emptyCount, kTableEmpty, Icons.chair_outlined),
            _buildStatTile('Active', _activeCount, kTableActive, Icons.restaurant_rounded),
            _buildStatTile('Waiting', _waitingCount, kTableWaiting, Icons.soup_kitchen_rounded),
            _buildStatTile('Served', _servedCount, kTableServed, Icons.room_service_rounded),
            if (_reservedCount > 0)
              _buildStatTile('Reserved', _reservedCount, kTableReserved, Icons.bookmark_rounded),
          ];
          final useScroll = c.maxWidth < 380;
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0F172A).withValues(alpha: 0.04),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: useScroll
                ? SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        for (var i = 0; i < tiles.length; i++) ...[
                          if (i > 0) const SizedBox(width: 8),
                          SizedBox(width: 76, child: tiles[i]),
                        ],
                      ],
                    ),
                  )
                : Row(children: [
                    for (var i = 0; i < tiles.length; i++) ...[
                      if (i > 0) const SizedBox(width: 8),
                      Expanded(child: tiles[i]),
                    ],
                  ]),
          );
        },
      ),
    );
  }

  Widget _buildStatTile(String label, int count, Color color, IconData icon) {
    final isSelected = _filterStatus == _labelToStatus(label);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          final status = _labelToStatus(label);
          setState(() {
            _filterStatus = _filterStatus == status ? null : status;
          });
        },
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
          decoration: BoxDecoration(
            color: isSelected ? color.withValues(alpha: 0.12) : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? color.withValues(alpha: 0.35) : const Color(0xFFE2E8F0),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(height: 6),
              Text(
                '$count',
                style: TextStyle(
                  color: isSelected ? const Color(0xFF0F172A) : const Color(0xFF334155),
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Literata',
                  height: 1,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? color.withValues(alpha: 0.95) : const Color(0xFF64748B),
                  fontSize: 11,
                  fontFamily: 'Literata',
                  fontWeight: FontWeight.w600,
                  height: 1.1,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  TableStatus? _labelToStatus(String label) {
    switch (label) {
      case 'Empty':
        return TableStatus.empty;
      case 'Active':
        return TableStatus.active;
      case 'Waiting':
        return TableStatus.waiting;
      case 'Served':
        return TableStatus.served;
      case 'Reserved':
        return TableStatus.reserved;
      default:
        return null;
    }
  }

  // ── SECTION CHIPS ────────────────────────────────────────────────

  Widget _buildSectionChips() {
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
        children: [
          _sectionChip(null, 'All sections'),
          ..._sections.map((s) => _sectionChip(s, s)),
        ],
      ),
    );
  }

  Widget _sectionChip(String? section, String label) {
    final selected = _selectedSection == section;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => setState(() => _selectedSection = section),
          borderRadius: BorderRadius.circular(20),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: selected ? const Color(0xFF16A34A) : Colors.white.withValues(alpha: 0.95),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: selected ? const Color(0xFF16A34A) : const Color(0xFFE2E8F0),
              ),
              boxShadow: [
                if (!selected)
                  BoxShadow(
                    color: const Color(0xFF0F172A).withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
              ],
            ),
            child: Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : const Color(0xFF475569),
                fontSize: 13,
                fontFamily: 'Literata',
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── TABLE GRID ───────────────────────────────────────────────────

  Widget _buildTableGrid() {
    // Group by section
    final grouped = <String, List<TableEntity>>{};
    for (final t in _filtered) {
      grouped.putIfAbsent(t.section, () => []).add(t);
    }
    final sortedSections = grouped.keys.toList()..sort();

    return RefreshIndicator(
      onRefresh: _load,
      color: const Color(0xFF16A34A),
      backgroundColor: Colors.white,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
        itemCount: sortedSections.length,
        itemBuilder: (_, i) {
          final sec = sortedSections[i];
          final tables = grouped[sec]!;
          return _buildSectionGroup(sec, tables);
        },
      ),
    );
  }

  Widget _buildSectionGroup(String section, List<TableEntity> tables) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 18, bottom: 12),
          child: Row(
            children: [
              Text(
                section,
                style: const TextStyle(
                  color: Color(0xFF0F172A),
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Literata',
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '${tables.length} tables',
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Literata',
                  ),
                ),
              ),
            ],
          ),
        ),
        LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final crossAxisCount = width > 720
                ? 4
                : width > 480
                    ? 3
                    : 2;
            final aspect = crossAxisCount >= 4 ? 0.88 : (crossAxisCount == 3 ? 0.9 : 0.95);
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                childAspectRatio: aspect,
              ),
              itemCount: tables.length,
              itemBuilder: (_, i) => _TableCard(
                table: tables[i],
                now: _now,
                onTap: () => _onTableTap(tables[i]),
              ),
            );
          },
        ),
      ],
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
              color: const Color(0xFF16A34A).withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: const Color(0xFF16A34A).withValues(alpha: 0.12),
              ),
            ),
            child: const Icon(
              Icons.table_restaurant_rounded,
              size: 46,
              color: Color(0xFF16A34A),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'No Tables',
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
                ? 'No ${tableStatusLabel(_filterStatus!)} tables'
                : 'Tap + to add your first table',
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

  // ── FAB ──────────────────────────────────────────────────────────

  Widget _buildFab() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF16A34A).withValues(alpha: 0.40),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: const Color(0xFF16A34A).withValues(alpha: 0.20),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: FloatingActionButton(
        onPressed: _openAddForm,
        backgroundColor: const Color(0xFF16A34A),
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.add_rounded, size: 28),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// TABLE CARD WIDGET
// ─────────────────────────────────────────────────────────────────

class _TableCard extends StatelessWidget {
  final TableEntity table;
  final DateTime now;
  final VoidCallback onTap;

  const _TableCard({
    required this.table,
    required this.now,
    required this.onTap,
  });

  static const _kBorder = Color(0xFFE2E8F0);
  static const _kMuted = Color(0xFF64748B);

  @override
  Widget build(BuildContext context) {
    final color = tableStatusColor(table.status);
    final elapsed = table.occupiedAt != null
        ? now.difference(table.occupiedAt!)
        : Duration.zero;
    final mins = elapsed.inMinutes;
    final isLong =
        table.status != TableStatus.empty &&
        table.status != TableStatus.reserved &&
        mins > 60;
    final occupied = table.status != TableStatus.empty &&
        table.status != TableStatus.reserved;

    return Material(
      color: Colors.white,
      elevation: 0,
      shadowColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isLong ? const Color(0xFFFECACA) : _kBorder,
          width: isLong ? 1.5 : 1,
        ),
      ),
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        borderRadius: BorderRadius.circular(16),
        splashColor: color.withValues(alpha: 0.08),
        highlightColor: color.withValues(alpha: 0.04),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 5,
              decoration: BoxDecoration(
                color: color,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(15),
                  bottomLeft: Radius.circular(15),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                table.tableNumber,
                                style: const TextStyle(
                                  color: Color(0xFF0F172A),
                                  fontSize: 19,
                                  fontWeight: FontWeight.w700,
                                  fontFamily: 'Literata',
                                  height: 1.15,
                                  letterSpacing: -0.3,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 6),
                              Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  _StatusPill(color: color, label: tableStatusLabel(table.status)),
                                  if (occupied)
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          width: 6,
                                          height: 6,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: color.withValues(alpha: 0.9),
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Live',
                                          style: TextStyle(
                                            color: color.withValues(alpha: 0.95),
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            fontFamily: 'Literata',
                                          ),
                                        ),
                                      ],
                                    ),
                                  if (table.needsSync)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFFFBEB),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(color: const Color(0xFFFDE68A)),
                                      ),
                                      child: const Text(
                                        'Sync',
                                        style: TextStyle(
                                          color: Color(0xFFB45309),
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          fontFamily: 'Literata',
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          tableStatusIcon(table.status),
                          color: color.withValues(alpha: 0.85),
                          size: 26,
                        ),
                      ],
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Icon(Icons.event_seat_outlined, size: 15, color: _kMuted.withValues(alpha: 0.9)),
                        const SizedBox(width: 4),
                        Text(
                          '${table.occupiedSeats} / ${table.capacity} seats',
                          style: const TextStyle(
                            color: _kMuted,
                            fontSize: 12,
                            fontFamily: 'Literata',
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (occupied && table.occupiedAt != null) ...[
                          const Spacer(),
                          Icon(
                            Icons.schedule_rounded,
                            size: 15,
                            color: isLong ? const Color(0xFFDC2626) : _kMuted,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _formatTime(elapsed),
                            style: TextStyle(
                              color: isLong ? const Color(0xFFDC2626) : const Color(0xFF0F172A),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Literata',
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (table.guestName != null && table.guestName!.trim().isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        table.guestName!.trim(),
                        style: const TextStyle(
                          color: _kMuted,
                          fontSize: 12,
                          fontFamily: 'Literata',
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    if (occupied) ...[
                      const SizedBox(height: 10),
                      _ServiceJourneyBar(status: table.status),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes % 60;
    if (h > 0) return '${h}h ${m}m';
    if (m > 0) return '${m}m';
    final s = d.inSeconds % 60;
    return '${s}s';
  }
}

/// Order → Kitchen → Served (no micro-copy; colour shows progress).
class _ServiceJourneyBar extends StatelessWidget {
  final TableStatus status;

  const _ServiceJourneyBar({required this.status});

  int get _stage {
    switch (status) {
      case TableStatus.active:
        return 0;
      case TableStatus.waiting:
        return 1;
      case TableStatus.served:
        return 2;
      default:
        return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    const fills = [
      Color(0xFF3B82F6),
      Color(0xFFF59E0B),
      Color(0xFF22C55E),
    ];
    final stage = _stage;
    return Row(
      children: [
        for (var i = 0; i < 3; i++) ...[
          Expanded(
            child: Tooltip(
              message: i == 0 ? 'Ordering' : (i == 1 ? 'In kitchen' : 'Ready to serve'),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 240),
                height: 5,
                decoration: BoxDecoration(
                  color: i <= stage ? fills[i] : const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ),
          if (i < 2) const SizedBox(width: 5),
        ],
      ],
    );
  }
}

class _StatusPill extends StatelessWidget {
  final Color color;
  final String label;

  const _StatusPill({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color.withValues(alpha: 0.95),
          fontSize: 12,
          fontWeight: FontWeight.w600,
          fontFamily: 'Literata',
        ),
      ),
    );
  }
}

// Helpers are in table_status_helpers.dart

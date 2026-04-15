import 'dart:async';
import 'dart:ui';
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
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF16A34A).withValues(alpha: 0.10),
                    const Color(0xFF16A34A).withValues(alpha: 0.0),
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
                    const Color(0xFF16A34A).withValues(alpha: 0.07),
                    const Color(0xFF16A34A).withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
          Column(
            children: [
              _buildStatsStrip(),
              _buildStatusFilterBar(),
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
                  Colors.white.withValues(alpha: 0.82),
                  Colors.white.withValues(alpha: 0.60),
                ],
              ),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.7),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0F172A).withValues(alpha: 0.06),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
                BoxShadow(
                  color: const Color(0xFF16A34A).withValues(alpha: 0.04),
                  blurRadius: 40,
                  spreadRadius: -5,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Row(
              children: [
                _buildStatTile(
                  'Empty',
                  _emptyCount,
                  kTableEmpty,
                  Icons.chair_outlined,
                ),
                const SizedBox(width: 6),
                _buildStatTile(
                  'Active',
                  _activeCount,
                  kTableActive,
                  Icons.people_rounded,
                ),
                const SizedBox(width: 6),
                _buildStatTile(
                  'Waiting',
                  _waitingCount,
                  kTableWaiting,
                  Icons.access_time_rounded,
                ),
                const SizedBox(width: 6),
                _buildStatTile(
                  'Served',
                  _servedCount,
                  kTableServed,
                  Icons.check_circle_rounded,
                ),
                if (_reservedCount > 0) ...[
                  const SizedBox(width: 6),
                  _buildStatTile(
                    'Reserved',
                    _reservedCount,
                    kTableReserved,
                    Icons.bookmark_rounded,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
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
                ? color.withValues(alpha: 0.10)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? color.withValues(alpha: 0.30)
                  : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Circular icon badge
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      color.withValues(alpha: isSelected ? 0.25 : 0.14),
                      color.withValues(alpha: isSelected ? 0.12 : 0.05),
                    ],
                  ),
                  border: Border.all(color: color.withValues(alpha: 0.18)),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: isSelected ? 0.25 : 0.10),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Icon(icon, color: color, size: 17),
              ),
              const SizedBox(height: 8),
              Text(
                '$count',
                style: TextStyle(
                  color: isSelected ? color : const Color(0xFF1E293B),
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  fontFamily: 'Literata',
                ),
              ),
              const SizedBox(height: 1),
              Text(
                label,
                style: TextStyle(
                  color: isSelected
                      ? color.withValues(alpha: 0.8)
                      : const Color(0xFF94A3B8),
                  fontSize: 10,
                  fontFamily: 'Literata',
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
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

  // ── STATUS FILTER BAR ────────────────────────────────────────────

  Widget _buildStatusFilterBar() {
    final statuses = [null, ...TableStatus.values];
    return SizedBox(
      height: 44,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        itemCount: statuses.length,
        itemBuilder: (_, i) {
          final s = statuses[i];
          final selected = _filterStatus == s;
          final color = s == null
              ? const Color(0xFF16A34A)
              : tableStatusColor(s);
          final label = s == null ? 'All' : tableStatusLabel(s);
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => setState(() => _filterStatus = s),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: selected
                      ? color.withValues(alpha: 0.12)
                      : Colors.white.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: selected
                        ? color.withValues(alpha: 0.4)
                        : Colors.white.withValues(alpha: 0.7),
                  ),
                  boxShadow: selected
                      ? [
                          BoxShadow(
                            color: color.withValues(alpha: 0.15),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : [
                          BoxShadow(
                            color: const Color(
                              0xFF0F172A,
                            ).withValues(alpha: 0.04),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (s != null) ...[
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: color,
                          boxShadow: [
                            BoxShadow(
                              color: color.withValues(alpha: 0.4),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                    ],
                    Text(
                      label,
                      style: TextStyle(
                        color: selected ? color : const Color(0xFF64748B),
                        fontSize: 12,
                        fontFamily: 'Literata',
                        fontWeight: selected
                            ? FontWeight.w700
                            : FontWeight.w500,
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

  // ── SECTION CHIPS ────────────────────────────────────────────────

  Widget _buildSectionChips() {
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(left: 16, bottom: 4),
        children: [
          _sectionChip(null, 'All Sections'),
          ..._sections.map((s) => _sectionChip(s, s)),
        ],
      ),
    );
  }

  Widget _sectionChip(String? section, String label) {
    final selected = _selectedSection == section;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () => setState(() => _selectedSection = section),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
          decoration: BoxDecoration(
            color: selected
                ? const Color(0xFF16A34A).withValues(alpha: 0.1)
                : Colors.white.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected
                  ? const Color(0xFF16A34A).withValues(alpha: 0.4)
                  : Colors.white.withValues(alpha: 0.7),
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0F172A).withValues(alpha: 0.03),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected
                  ? const Color(0xFF16A34A)
                  : const Color(0xFF64748B),
              fontSize: 11,
              fontFamily: 'Literata',
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
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
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
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
          padding: const EdgeInsets.only(top: 20, bottom: 14),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 22,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF16A34A), Color(0xFF22C55E)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.circular(2),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF16A34A).withValues(alpha: 0.3),
                      blurRadius: 6,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Text(
                section.toUpperCase(),
                style: const TextStyle(
                  color: Color(0xFF1E293B),
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  fontFamily: 'Literata',
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF16A34A).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: const Color(0xFF16A34A).withValues(alpha: 0.15),
                  ),
                ),
                child: Text(
                  '${tables.length}',
                  style: const TextStyle(
                    color: Color(0xFF16A34A),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Literata',
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  height: 1,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF16A34A).withValues(alpha: 0.15),
                        const Color(0xFF16A34A).withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.85,
          ),
          itemCount: tables.length,
          itemBuilder: (_, i) => _TableCard(
            table: tables[i],
            now: _now,
            onTap: () => _onTableTap(tables[i]),
          ),
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
      child: FloatingActionButton.extended(
        onPressed: _openAddForm,
        backgroundColor: const Color(0xFF16A34A),
        foregroundColor: Colors.white,
        elevation: 0,
        icon: const Icon(Icons.add_rounded, size: 22),
        label: const Text(
          'Add Table',
          style: TextStyle(
            fontFamily: 'Literata',
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
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

    return GestureDetector(
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
              color.withValues(alpha: 0.12),
              color.withValues(alpha: 0.04),
              Colors.white.withValues(alpha: 0.9),
            ],
            stops: const [0.0, 0.4, 1.0],
          ),
          border: Border.all(
            color: isLong
                ? const Color(0xFFFCA5A5).withValues(alpha: 0.8)
                : color.withValues(alpha: 0.22),
            width: isLong ? 1.8 : 1.2,
          ),
          boxShadow: [
            // Main colored glow
            BoxShadow(
              color: color.withValues(alpha: 0.18),
              blurRadius: 20,
              spreadRadius: -2,
              offset: const Offset(0, 8),
            ),
            // Soft lift shadow
            BoxShadow(
              color: const Color(0xFF0F172A).withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
            // Inner highlight (top-left)
            BoxShadow(
              color: Colors.white.withValues(alpha: 0.7),
              blurRadius: 1,
              spreadRadius: 0,
              offset: const Offset(-1, -1),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Stack(
              children: [
                // Top-left glass highlight arc
                Positioned(
                  top: -20,
                  left: -20,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          Colors.white.withValues(alpha: 0.35),
                          Colors.white.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                ),
                // Bottom-right status glow
                Positioned(
                  bottom: -30,
                  right: -30,
                  child: Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          color.withValues(alpha: 0.15),
                          color.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                ),
                // Pulsing dot for occupied tables
                if (table.status != TableStatus.empty &&
                    table.status != TableStatus.reserved)
                  Positioned(
                    top: 10,
                    right: 10,
                    child: _PulseDot(color: color),
                  ),
                // Pending sync dot
                if (table.needsSync)
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFFF59E0B),
                      ),
                    ),
                  ),
                // Main content
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 14, 12, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Table icon with glass pill
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: color.withValues(alpha: 0.25),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: color.withValues(alpha: 0.15),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          tableStatusIcon(table.status),
                          color: color,
                          size: 20,
                        ),
                      ),
                      const SizedBox(height: 10),
                      // Table number
                      Text(
                        table.tableNumber,
                        style: const TextStyle(
                          color: Color(0xFF1E293B),
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          fontFamily: 'Literata',
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      // Status label
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: color.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Text(
                          tableStatusLabel(table.status),
                          style: TextStyle(
                            color: color,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'Literata',
                          ),
                        ),
                      ),
                      const Spacer(),
                      // Capacity / time row
                      Row(
                        children: [
                          Icon(
                            Icons.people_outline_rounded,
                            color: const Color(0xFF94A3B8),
                            size: 12,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            '${table.occupiedSeats}/${table.capacity}',
                            style: const TextStyle(
                              color: Color(0xFF94A3B8),
                              fontSize: 10,
                              fontFamily: 'Literata',
                            ),
                          ),
                          if (table.status != TableStatus.empty &&
                              table.status != TableStatus.reserved &&
                              table.occupiedAt != null) ...[
                            const Spacer(),
                            Text(
                              _formatTime(elapsed),
                              style: TextStyle(
                                color: isLong ? const Color(0xFFDC2626) : color,
                                fontSize: 10,
                                fontFamily: 'Literata',
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ],
                      ),
                      // Guest name if present
                      if (table.guestName != null &&
                          table.guestName!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          table.guestName!,
                          style: const TextStyle(
                            color: Color(0xFF94A3B8),
                            fontSize: 9,
                            fontFamily: 'Literata',
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
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

  String _formatTime(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes % 60;
    final s = d.inSeconds % 60;
    final ss = s.toString().padLeft(2, '0');
    if (h > 0) return '${h}h ${m}m ${ss}s';
    return '${m}m ${ss}s';
  }
}

// ─────────────────────────────────────────────────────────────────
// PULSE DOT (animated active indicator)
// ─────────────────────────────────────────────────────────────────

class _PulseDot extends StatefulWidget {
  final Color color;
  const _PulseDot({required this.color});

  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _anim;
  late Animation<double> _scale;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _scale = Tween<double>(
      begin: 0.8,
      end: 1.3,
    ).animate(CurvedAnimation(parent: _anim, curve: Curves.easeInOut));
    _opacity = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _anim, curve: Curves.easeInOut));
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
      builder: (_, __) => Transform.scale(
        scale: _scale.value,
        child: Opacity(
          opacity: _opacity.value,
          child: Container(
            width: 9,
            height: 9,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: widget.color,
              boxShadow: [
                BoxShadow(
                  color: widget.color.withValues(alpha: 0.6),
                  blurRadius: 6,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Helpers are in table_status_helpers.dart

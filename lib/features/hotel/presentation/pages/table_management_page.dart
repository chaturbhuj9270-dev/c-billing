import 'dart:async';
import 'dart:ui' show ImageFilter;
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
            Color(0xFFD8F3E0),
            Color(0xFFE8F5EC),
            Color(0xFFF0FDF4),
            Color(0xFFF7FDF9),
          ],
          stops: [0.0, 0.35, 0.65, 1.0],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -80,
            right: -60,
            child: Container(
              width: 260,
              height: 260,
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
          Positioned(
            bottom: 120,
            left: -40,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF1B4D3E).withValues(alpha: 0.06),
                    const Color(0xFF1B4D3E).withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
          Column(
            children: [
              _buildStatsStrip(),
              _buildGlassFilterChips(),
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
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
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
          return ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withValues(alpha: 0.58),
                      Colors.white.withValues(alpha: 0.32),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.85),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF134E4A).withValues(alpha: 0.07),
                      blurRadius: 24,
                      offset: const Offset(0, 10),
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
                    : Row(
                        children: [
                          for (var i = 0; i < tiles.length; i++) ...[
                            if (i > 0) const SizedBox(width: 8),
                            Expanded(child: tiles[i]),
                          ],
                        ],
                      ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// Glass pill filters (same state as stat tiles) — matches “All / Empty / …” row.
  Widget _buildGlassFilterChips() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.white.withValues(alpha: 0.45),
                  Colors.white.withValues(alpha: 0.22),
                ],
              ),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: Colors.white.withValues(alpha: 0.75)),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _glassFilterChip('All', null, const Color(0xFF16A34A)),
                  _glassFilterChip(
                    'Empty',
                    TableStatus.empty,
                    kTableEmpty,
                  ),
                  _glassFilterChip(
                    'Active',
                    TableStatus.active,
                    kTableActive,
                  ),
                  _glassFilterChip(
                    'Waiting',
                    TableStatus.waiting,
                    kTableWaiting,
                  ),
                  _glassFilterChip(
                    'Served',
                    TableStatus.served,
                    kTableServed,
                  ),
                  if (_reservedCount > 0)
                    _glassFilterChip(
                      'Reserved',
                      TableStatus.reserved,
                      kTableReserved,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _glassFilterChip(String label, TableStatus? status, Color dotColor) {
    final selected = _filterStatus == status;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => setState(() => _filterStatus = status),
          borderRadius: BorderRadius.circular(18),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: selected
                  ? LinearGradient(
                      colors: [
                        const Color(0xFF16A34A).withValues(alpha: 0.92),
                        const Color(0xFF15803D).withValues(alpha: 0.88),
                      ],
                    )
                  : null,
              color: selected ? null : Colors.white.withValues(alpha: 0.35),
              border: Border.all(
                color: selected
                    ? const Color(0xFF22C55E).withValues(alpha: 0.5)
                    : Colors.white.withValues(alpha: 0.65),
              ),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: const Color(0xFF16A34A).withValues(alpha: 0.45),
                        blurRadius: 14,
                        spreadRadius: -2,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : [
                      BoxShadow(
                        color: const Color(0xFF0F172A).withValues(alpha: 0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (status != null) ...[
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: selected ? Colors.white : dotColor,
                    ),
                  ),
                  const SizedBox(width: 6),
                ],
                Text(
                  label,
                  style: TextStyle(
                    color: selected ? Colors.white : const Color(0xFF334155),
                    fontSize: 12,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                    fontFamily: 'Literata',
                  ),
                ),
              ],
            ),
          ),
        ),
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
            color: isSelected
                ? color.withValues(alpha: 0.18)
                : Colors.white.withValues(alpha: 0.28),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected
                  ? color.withValues(alpha: 0.45)
                  : Colors.white.withValues(alpha: 0.55),
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: color.withValues(alpha: 0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
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
      height: 48,
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
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => setState(() => _selectedSection = section),
              borderRadius: BorderRadius.circular(20),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  gradient: selected
                      ? LinearGradient(
                          colors: [
                            const Color(0xFF16A34A).withValues(alpha: 0.95),
                            const Color(0xFF15803D).withValues(alpha: 0.9),
                          ],
                        )
                      : LinearGradient(
                          colors: [
                            Colors.white.withValues(alpha: 0.42),
                            Colors.white.withValues(alpha: 0.22),
                          ],
                        ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: selected
                        ? const Color(0xFF4ADE80).withValues(alpha: 0.55)
                        : Colors.white.withValues(alpha: 0.75),
                  ),
                  boxShadow: selected
                      ? [
                          BoxShadow(
                            color: const Color(0xFF16A34A).withValues(alpha: 0.4),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : null,
                ),
                child: Text(
                  label,
                  style: TextStyle(
                    color: selected ? Colors.white : const Color(0xFF1E293B),
                    fontSize: 13,
                    fontFamily: 'Literata',
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                  ),
                ),
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
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.75)),
                    ),
                    child: Text(
                      '${tables.length} tables',
                      style: const TextStyle(
                        color: Color(0xFF475569),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Literata',
                      ),
                    ),
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
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 36),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withValues(alpha: 0.55),
                    Colors.white.withValues(alpha: 0.28),
                  ],
                ),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: Colors.white.withValues(alpha: 0.85)),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF134E4A).withValues(alpha: 0.06),
                    blurRadius: 28,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF16A34A).withValues(alpha: 0.12),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                    child: const Icon(
                      Icons.table_restaurant_rounded,
                      size: 42,
                      color: Color(0xFF15803D),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'No Tables',
                    style: TextStyle(
                      color: Color(0xFF0F172A),
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
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 13,
                      fontFamily: 'Literata',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── FAB ──────────────────────────────────────────────────────────

  Widget _buildFab() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF16A34A).withValues(alpha: 0.45),
            blurRadius: 22,
            spreadRadius: -2,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: const Color(0xFF16A34A).withValues(alpha: 0.22),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: FloatingActionButton(
            onPressed: _openAddForm,
            backgroundColor: const Color(0xFF16A34A).withValues(alpha: 0.94),
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
              side: BorderSide(color: Colors.white.withValues(alpha: 0.35)),
            ),
            child: const Icon(Icons.add_rounded, size: 28),
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

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              HapticFeedback.lightImpact();
              onTap();
            },
            borderRadius: BorderRadius.circular(20),
            splashColor: color.withValues(alpha: 0.12),
            highlightColor: color.withValues(alpha: 0.06),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withValues(alpha: 0.72),
                    Colors.white.withValues(alpha: 0.38),
                  ],
                ),
                border: Border.all(
                  color: isLong
                      ? const Color(0xFFFECACA).withValues(alpha: 0.95)
                      : Colors.white.withValues(alpha: 0.9),
                  width: isLong ? 1.6 : 1.15,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF134E4A).withValues(alpha: 0.07),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    width: 5,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          color,
                          color.withValues(alpha: 0.65),
                        ],
                      ),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(19),
                        bottomLeft: Radius.circular(19),
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
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.white.withValues(alpha: 0.75),
                                      Colors.white.withValues(alpha: 0.35),
                                    ],
                                  ),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.9),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: color.withValues(alpha: 0.2),
                                      blurRadius: 10,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  tableStatusIcon(table.status),
                                  color: color,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      table.tableNumber,
                                      style: const TextStyle(
                                        color: Color(0xFF0F172A),
                                        fontSize: 22,
                                        fontWeight: FontWeight.w700,
                                        fontFamily: 'Literata',
                                        height: 1.1,
                                        letterSpacing: -0.4,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 6),
                                    Wrap(
                                      spacing: 6,
                                      runSpacing: 6,
                                      crossAxisAlignment:
                                          WrapCrossAlignment.center,
                                      children: [
                                        _StatusPill(
                                          color: color,
                                          label: tableStatusLabel(table.status),
                                        ),
                                        if (occupied)
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Container(
                                                width: 6,
                                                height: 6,
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  color: color.withValues(
                                                    alpha: 0.95,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                'Live',
                                                style: TextStyle(
                                                  color: color.withValues(
                                                    alpha: 0.95,
                                                  ),
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w600,
                                                  fontFamily: 'Literata',
                                                ),
                                              ),
                                            ],
                                          ),
                                        if (table.needsSync)
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFFFFBEB),
                                              borderRadius: BorderRadius.circular(6),
                                              border: Border.all(
                                                color: const Color(0xFFFDE68A),
                                              ),
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
                            ],
                          ),
                          const Spacer(),
                          Row(
                            children: [
                              Icon(
                                Icons.event_seat_outlined,
                                size: 15,
                                color: _kMuted.withValues(alpha: 0.95),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${table.occupiedSeats} / ${table.capacity}',
                                style: const TextStyle(
                                  color: _kMuted,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: 'Literata',
                                ),
                              ),
                              if (occupied && table.occupiedAt != null) ...[
                                const Spacer(),
                                Icon(
                                  Icons.schedule_rounded,
                                  size: 15,
                                  color: isLong
                                      ? const Color(0xFFDC2626)
                                      : _kMuted,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _formatTime(elapsed),
                                  style: TextStyle(
                                    color: isLong
                                        ? const Color(0xFFDC2626)
                                        : const Color(0xFF0F172A),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    fontFamily: 'Literata',
                                  ),
                                ),
                              ],
                            ],
                          ),
                          if (table.guestName != null &&
                              table.guestName!.trim().isNotEmpty) ...[
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
                          if (occupied ||
                              table.status == TableStatus.reserved) ...[
                            const SizedBox(height: 10),
                            _GlassOrderJourney(status: table.status),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
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

/// Order → Kitchen → Served → Done (glass-style progress like reference UI).
class _GlassOrderJourney extends StatelessWidget {
  final TableStatus status;

  const _GlassOrderJourney({required this.status});

  /// Number of stages completed left-to-right (0–4). Lines before stage use strong color.
  int get _stagesComplete {
    switch (status) {
      case TableStatus.empty:
        return 0;
      case TableStatus.reserved:
        return 0;
      case TableStatus.active:
        return 1;
      case TableStatus.waiting:
        return 2;
      case TableStatus.served:
        return 3;
    }
  }

  static const _labels = ['Order', 'Kitchen', 'Served', 'Done'];
  static const _colors = [
    Color(0xFF3B82F6),
    Color(0xFFF59E0B),
    Color(0xFF22C55E),
    Color(0xFF94A3B8),
  ];

  @override
  Widget build(BuildContext context) {
    final n = _stagesComplete;
    return Column(
      children: [
        Row(
          children: [
            for (var i = 0; i < 4; i++) ...[
              _journeyDot(
                filled: i < n,
                current: i == n && n < 4,
                color: _colors[i],
                isReserved: status == TableStatus.reserved && i == 0,
              ),
              if (i < 3)
                Expanded(
                  child: Container(
                    height: 2.5,
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(2),
                      color: i + 1 <= n
                          ? _colors[i + 1].withValues(alpha: 0.55)
                          : const Color(0xFFE2E8F0),
                    ),
                  ),
                ),
            ],
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            for (var i = 0; i < 4; i++)
              Expanded(
                child: Text(
                  _labels[i],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: i < n
                        ? _colors[i].withValues(alpha: 0.95)
                        : (i == n && n < 4
                            ? _colors[i].withValues(alpha: 0.85)
                            : const Color(0xFFCBD5E1)),
                    fontSize: 9,
                    fontWeight: i <= n ? FontWeight.w700 : FontWeight.w500,
                    fontFamily: 'Literata',
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _journeyDot({
    required bool filled,
    required bool current,
    required Color color,
    bool isReserved = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        width: 11,
        height: 11,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: filled ? color : Colors.white.withValues(alpha: 0.65),
          border: Border.all(
            color: isReserved
                ? kTableReserved
                : (filled ? color.withValues(alpha: 0.65) : const Color(0xFFCBD5E1)),
            width: current || isReserved ? 2 : 1.5,
          ),
          boxShadow: filled
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.35),
                    blurRadius: 6,
                  ),
                ]
              : null,
        ),
      ),
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

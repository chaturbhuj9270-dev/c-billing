import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:c_billing/common_widgets/app_pill_button.dart';
import 'package:c_billing/common_widgets/glass_bottom_sheet.dart';
import 'package:c_billing/core/theme/app_theme.dart';
import 'package:c_billing/core/ui/desktop_canvas.dart';

import '../../../../common_widgets/app_scaffold.dart';
import '../../../../core/access/access_control_service.dart';
import '../../../../core/access/app_module.dart';
import '../../../../core/ui/glassy_toast.dart';
import '../../data/repositories/employee_repository.dart';
import '../../domain/entities/employee.dart';

class EmployeeScreenActions {
  static VoidCallback? add;
}

enum _StatusFilter { all, active, inactive }

class EmployeesPage extends StatefulWidget {
  final bool isEmbedded;

  const EmployeesPage({super.key, this.isEmbedded = false});

  @override
  State<EmployeesPage> createState() => _EmployeesPageState();
}

class _EmployeesPageState extends State<EmployeesPage> {
  final _repo = EmployeeRepository();
  final _searchCtrl = TextEditingController();
  List<Employee> _employees = [];
  bool _loading = true;
  String? _error;
  _StatusFilter _filter = _StatusFilter.all;

  bool get _desktop => DesktopCanvas.isDesktopPlatform;

  int get _activeCount => _employees.where((e) => e.active).length;
  int get _inactiveCount => _employees.length - _activeCount;

  List<Employee> get _filtered {
    final q = _searchCtrl.text.trim().toLowerCase();
    return _employees.where((e) {
      if (_filter == _StatusFilter.active && !e.active) return false;
      if (_filter == _StatusFilter.inactive && e.active) return false;
      if (q.isEmpty) return true;
      return e.displayName.toLowerCase().contains(q) ||
          e.email.toLowerCase().contains(q) ||
          '${e.tokenNumber}'.contains(q) ||
          (e.phone?.toLowerCase().contains(q) ?? false);
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    EmployeeScreenActions.add = () => _openEditor();
    _load();
  }

  @override
  void dispose() {
    if (EmployeeScreenActions.add != null) {
      EmployeeScreenActions.add = null;
    }
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (!AccessControlService.instance.isOwner) {
      setState(() {
        _loading = false;
        _error = 'Only the shop admin can manage employees';
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await _repo.getEmployees();
      if (!mounted) return;
      setState(() {
        _employees = list;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _setActive(Employee e, bool active) async {
    try {
      await _repo.setActive(e.id, active);
      await _load();
    } catch (err) {
      if (!mounted) return;
      GlassyToast.show(context, 'Update failed: $err');
    }
  }

  Future<void> _openEditor({Employee? existing}) async {
    final nextToken =
        existing?.tokenNumber ?? await _repo.nextTokenNumber();
    if (!mounted) return;
    final result = await showAppBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.transparent,
      builder: (ctx) => _EmployeeEditorSheet(
        existing: existing,
        previewToken: nextToken,
        onSave: (data) async {
          if (existing == null) {
            await _repo.createEmployee(
              email: data.email,
              password: data.password!,
              displayName: data.displayName,
              phone: data.phone,
              counterAccess: data.counterAccess,
              allowedModules: data.modules,
              dateOfBirth: data.dateOfBirth,
              address: data.address,
              pinCode: data.pinCode,
              govIdNumber: data.govIdNumber,
              govIdType: data.govIdType,
              salary: data.salary,
              dateOfJoining: data.dateOfJoining,
            );
          } else {
            await _repo.updateEmployee(
              existing.copyWith(
                displayName: data.displayName,
                phone: data.phone,
                counterAccess: data.counterAccess,
                allowedModules: data.modules,
                active: data.active,
                dateOfBirth: data.dateOfBirth,
                address: data.address,
                pinCode: data.pinCode,
                govIdNumber: data.govIdNumber,
                govIdType: data.govIdType,
                salary: data.salary,
                dateOfJoining: data.dateOfJoining,
                clearDateOfBirth: data.dateOfBirth == null,
                clearDateOfJoining: data.dateOfJoining == null,
                clearSalary: data.salary == null,
              ),
            );
          }
        },
      ),
    );
    if (result == true) {
      await _load();
      if (mounted) {
        GlassyToast.show(
          context,
          existing == null ? 'Employee created' : 'Employee updated',
        );
      }
    }
  }

  String _initials(Employee e) {
    final parts = e.displayName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  String _pointsLabel(double points) {
    return points % 1 == 0
        ? points.toStringAsFixed(0)
        : points.toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    final body = _buildBody();
    if (widget.isEmbedded) return body;
    return AppScaffold(
      title: 'Employees',
      body: Stack(
        children: [
          body,
          if (AccessControlService.instance.isOwner && !_desktop)
            Positioned(
              right: 16,
              bottom: 16,
              child: FloatingActionButton.extended(
                onPressed: () => _openEditor(),
                icon: const Icon(Icons.person_add_alt_1_rounded),
                label: const Text('Add employee'),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              TextButton(onPressed: _load, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        slivers: [
          SliverPadding(
            padding: EdgeInsets.fromLTRB(
              _desktop ? 20 : 16,
              _desktop ? 8 : 12,
              _desktop ? 20 : 16,
              8,
            ),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (!_desktop && !widget.isEmbedded) ...[
                    Text(
                      'Manage staff and their access.',
                      style: TextStyle(
                        fontFamily: 'Literata',
                        color: AppColors.mutedText(context),
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  _buildStatCards(),
                  const SizedBox(height: 14),
                  _buildSearchAndFilters(),
                  const SizedBox(height: 14),
                ],
              ),
            ),
          ),
          if (_filtered.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: _buildEmptyState(),
            )
          else if (_desktop)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              sliver: SliverToBoxAdapter(child: _buildDesktopTable()),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
              sliver: SliverList.separated(
                itemCount: _filtered.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, index) =>
                    _buildMobileCard(_filtered[index]),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final searching = _searchCtrl.text.trim().isNotEmpty ||
        _filter != _StatusFilter.all;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              searching ? Icons.search_off_rounded : Icons.groups_outlined,
              size: 56,
              color: AppColors.mutedText(context),
            ),
            const SizedBox(height: 12),
            Text(
              searching ? 'No matching employees' : 'No employees yet',
              style: TextStyle(
                fontFamily: 'Literata',
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryText(context),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              searching
                  ? 'Try a different search or filter.'
                  : 'Add counter staff and choose which modules they can use.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.mutedText(context)),
            ),
            if (!searching) ...[
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => _openEditor(),
                icon: const Icon(Icons.person_add_alt_1_rounded),
                label: const Text('Add employee'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatCards() {
    final cards = [
      _StatSpec(
        icon: Icons.groups_rounded,
        label: 'Employees',
        value: '${_employees.length}',
        color: AppColors.action(context),
      ),
      _StatSpec(
        icon: Icons.check_circle_rounded,
        label: 'Active',
        value: '$_activeCount',
        color: AppTheme.green,
      ),
      _StatSpec(
        icon: Icons.cancel_rounded,
        label: 'Inactive',
        value: '$_inactiveCount',
        color: AppTheme.coral,
      ),
    ];

    if (_desktop) {
      return Row(
        children: [
          for (var i = 0; i < cards.length; i++) ...[
            if (i > 0) const SizedBox(width: 12),
            Expanded(child: _buildStatCard(cards[i])),
          ],
        ],
      );
    }

    return SizedBox(
      height: 92,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: cards.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (_, i) => SizedBox(
          width: 148,
          child: _buildStatCard(cards[i]),
        ),
      ),
    );
  }

  Widget _buildStatCard(_StatSpec spec) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: spec.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(spec.icon, color: spec.color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  spec.value,
                  style: TextStyle(
                    fontFamily: 'Literata',
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primaryText(context),
                  ),
                ),
                Text(
                  spec.label,
                  style: TextStyle(
                    fontFamily: 'Literata',
                    fontSize: 12,
                    color: AppColors.mutedText(context),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          height: 46,
          decoration: BoxDecoration(
            color: AppColors.inputFill(context),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border(context)),
          ),
          child: TextField(
            controller: _searchCtrl,
            onChanged: (_) => setState(() {}),
            style: TextStyle(
              fontFamily: 'Literata',
              fontSize: 14,
              color: AppColors.primaryText(context),
            ),
            decoration: InputDecoration(
              hintText: 'Search employees',
              hintStyle: TextStyle(
                fontFamily: 'Literata',
                color: AppColors.mutedText(context),
              ),
              prefixIcon: Icon(
                Icons.search_rounded,
                color: AppColors.mutedText(context),
                size: 20,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _filterChip(
              label: 'All ${_employees.length}',
              selected: _filter == _StatusFilter.all,
              onTap: () => setState(() => _filter = _StatusFilter.all),
            ),
            _filterChip(
              label: 'Active $_activeCount',
              selected: _filter == _StatusFilter.active,
              onTap: () => setState(() => _filter = _StatusFilter.active),
            ),
            _filterChip(
              label: 'Inactive $_inactiveCount',
              selected: _filter == _StatusFilter.inactive,
              onTap: () => setState(() => _filter = _StatusFilter.inactive),
            ),
          ],
        ),
      ],
    );
  }

  Widget _filterChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final action = AppColors.action(context);
    return Material(
      color: selected ? action : AppColors.card(context),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? action : AppColors.border(context),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'Literata',
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: selected
                  ? AppTheme.white
                  : AppColors.secondaryText(context),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopTable() {
    final rows = _filtered;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border(context)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          _buildTableHeader(),
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0)
              Divider(height: 1, color: AppColors.border(context)),
            _buildDesktopRow(rows[i]),
          ],
        ],
      ),
    );
  }

  static const _tokenW = 100.0;
  static const _roleW = 110.0;
  static const _accessW = 110.0;
  static const _pointsW = 100.0;
  static const _statusW = 140.0;
  static const _actionsW = 88.0;

  Widget _tableCell({
    double? width,
    int? flex,
    Alignment align = Alignment.centerLeft,
    required Widget child,
  }) {
    final aligned = Align(alignment: align, child: child);
    if (width != null) {
      return SizedBox(width: width, child: aligned);
    }
    return Expanded(flex: flex ?? 1, child: aligned);
  }

  Widget _buildTableHeader() {
    final style = TextStyle(
      fontFamily: 'Literata',
      fontSize: 11,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.6,
      color: AppColors.mutedText(context),
    );
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: AppColors.scaffold(context).withValues(alpha: 0.55),
      child: Row(
        children: [
          _tableCell(flex: 3, child: Text('EMPLOYEE', style: style)),
          _tableCell(width: _tokenW, child: Text('TOKEN', style: style)),
          _tableCell(width: _roleW, child: Text('ROLE', style: style)),
          _tableCell(width: _accessW, child: Text('ACCESS', style: style)),
          _tableCell(width: _pointsW, child: Text('POINTS', style: style)),
          _tableCell(width: _statusW, child: Text('STATUS', style: style)),
          _tableCell(
            width: _actionsW,
            align: Alignment.centerRight,
            child: Text('ACTIONS', style: style),
          ),
        ],
      ),
    );
  }

  Widget _themeSwitch({
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final action = AppColors.action(context);
    return Switch(
      value: value,
      onChanged: onChanged,
      activeThumbColor: AppTheme.white,
      activeTrackColor: action,
      inactiveThumbColor: AppColors.isDark(context)
          ? AppTheme.grey
          : AppTheme.grey50,
      inactiveTrackColor: AppColors.isDark(context)
          ? AppTheme.white24
          : AppTheme.black12,
    );
  }

  Widget _buildDesktopRow(Employee e) {
    final modules = e.allowedModules.length;
    return Material(
      color: AppTheme.transparent,
      child: InkWell(
        onTap: () => _openEditor(existing: e),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              _tableCell(
                flex: 3,
                child: Row(
                  children: [
                    _Avatar(initials: _initials(e), active: e.active),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            e.displayName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: 'Literata',
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: AppColors.primaryText(context),
                            ),
                          ),
                          Text(
                            e.email,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: 'Literata',
                              fontSize: 12,
                              color: AppColors.mutedText(context),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              _tableCell(
                width: _tokenW,
                child: Text(
                  '${e.tokenNumber}',
                  style: TextStyle(
                    fontFamily: 'Literata',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryText(context),
                  ),
                ),
              ),
              _tableCell(
                width: _roleW,
                child: _RoleBadge(counter: e.counterAccess),
              ),
              _tableCell(
                width: _accessW,
                child: Text(
                  '$modules modules',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Literata',
                    fontSize: 12,
                    color: AppColors.secondaryText(context),
                  ),
                ),
              ),
              _tableCell(
                width: _pointsW,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.star_rounded,
                      size: 16,
                      color: AppColors.action(context),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _pointsLabel(e.points),
                      style: TextStyle(
                        fontFamily: 'Literata',
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: AppColors.primaryText(context),
                      ),
                    ),
                  ],
                ),
              ),
              _tableCell(
                width: _statusW,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _themeSwitch(
                      value: e.active,
                      onChanged: (v) => _setActive(e, v),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      e.active ? 'Active' : 'Inactive',
                      style: TextStyle(
                        fontFamily: 'Literata',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: e.active
                            ? AppColors.action(context)
                            : AppColors.mutedText(context),
                      ),
                    ),
                  ],
                ),
              ),
              _tableCell(
                width: _actionsW,
                align: Alignment.centerRight,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: 'Edit',
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 36,
                        minHeight: 36,
                      ),
                      onPressed: () => _openEditor(existing: e),
                      icon: Icon(
                        Icons.edit_outlined,
                        size: 20,
                        color: AppColors.secondaryText(context),
                      ),
                    ),
                    PopupMenuButton<String>(
                      tooltip: 'More',
                      padding: EdgeInsets.zero,
                      onSelected: (v) async {
                        if (v == 'edit') {
                          await _openEditor(existing: e);
                        } else if (v == 'toggle') {
                          await _setActive(e, !e.active);
                        }
                      },
                      itemBuilder: (_) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Text('Edit'),
                        ),
                        PopupMenuItem(
                          value: 'toggle',
                          child: Text(e.active ? 'Deactivate' : 'Activate'),
                        ),
                      ],
                      icon: Icon(
                        Icons.more_vert_rounded,
                        color: AppColors.secondaryText(context),
                      ),
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

  Widget _buildMobileCard(Employee e) {
    final modules = e.allowedModules.length;
    return Material(
      color: AppColors.card(context),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () => _openEditor(existing: e),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border(context)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _Avatar(initials: _initials(e), active: e.active),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          e.displayName,
                          style: TextStyle(
                            fontFamily: 'Literata',
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: AppColors.primaryText(context),
                          ),
                        ),
                        Text(
                          e.email,
                          style: TextStyle(
                            fontFamily: 'Literata',
                            fontSize: 12,
                            color: AppColors.mutedText(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                  _themeSwitch(
                    value: e.active,
                    onChanged: (v) => _setActive(e, v),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _infoChip(Icons.tag_rounded, '${e.tokenNumber}'),
                  _RoleBadge(counter: e.counterAccess),
                  _infoChip(Icons.apps_rounded, '$modules modules'),
                  _PointsGlassBadge(points: e.points),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.chipFill(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.mutedText(context)),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Literata',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.secondaryText(context),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatSpec {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatSpec({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });
}

class _Avatar extends StatelessWidget {
  final String initials;
  final bool active;

  const _Avatar({required this.initials, required this.active});

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 20,
      backgroundColor: active
          ? AppColors.action(context).withValues(alpha: 0.15)
          : AppTheme.grey300,
      child: Text(
        initials,
        style: TextStyle(
          fontFamily: 'Literata',
          fontWeight: FontWeight.w800,
          color: active ? AppColors.action(context) : AppTheme.grey600,
        ),
      ),
    );
  }
}

class _RoleBadge extends StatelessWidget {
  final bool counter;

  const _RoleBadge({required this.counter});

  @override
  Widget build(BuildContext context) {
    final label = counter ? 'Counter' : 'No counter';
    final color = counter ? AppTheme.paletteFF7B68EE : AppTheme.grey600;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Literata',
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

class _PointsGlassBadge extends StatelessWidget {
  final double points;

  const _PointsGlassBadge({required this.points});

  @override
  Widget build(BuildContext context) {
    final label = points % 1 == 0
        ? points.toStringAsFixed(0)
        : points.toStringAsFixed(2);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: (isDark ? AppTheme.white : AppTheme.primary)
                .withValues(alpha: isDark ? 0.12 : 0.10),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: (isDark ? AppTheme.white : AppTheme.primary)
                  .withValues(alpha: 0.22),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.star_rounded,
                size: 14,
                color: isDark ? AppTheme.white : AppTheme.primary,
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppTheme.white : AppTheme.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EditorData {
  final String email;
  final String? password;
  final String displayName;
  final String? phone;
  final bool counterAccess;
  final List<String> modules;
  final bool active;
  final DateTime? dateOfBirth;
  final String? address;
  final String? pinCode;
  final String? govIdNumber;
  final String? govIdType;
  final double? salary;
  final DateTime? dateOfJoining;

  const _EditorData({
    required this.email,
    this.password,
    required this.displayName,
    this.phone,
    required this.counterAccess,
    required this.modules,
    required this.active,
    this.dateOfBirth,
    this.address,
    this.pinCode,
    this.govIdNumber,
    this.govIdType,
    this.salary,
    this.dateOfJoining,
  });
}

class _EmployeeEditorSheet extends StatefulWidget {
  final Employee? existing;
  final int previewToken;
  final Future<void> Function(_EditorData data) onSave;

  const _EmployeeEditorSheet({
    required this.existing,
    required this.previewToken,
    required this.onSave,
  });

  @override
  State<_EmployeeEditorSheet> createState() => _EmployeeEditorSheetState();
}

class _EmployeeEditorSheetState extends State<_EmployeeEditorSheet> {
  static const _govIdTypes = [
    'Aadhaar',
    'PAN',
    'Voter ID',
    'Driving License',
    'Passport',
    'Other',
  ];

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _passwordCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _addressCtrl;
  late final TextEditingController _pinCtrl;
  late final TextEditingController _govIdCtrl;
  late final TextEditingController _salaryCtrl;
  late Set<String> _modules;
  late bool _active;
  late bool _counterAccess;
  DateTime? _dateOfBirth;
  DateTime? _dateOfJoining;
  String? _govIdType;
  bool _saving = false;
  final _dateFmt = DateFormat('dd MMM yyyy');

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _nameCtrl = TextEditingController(text: e?.displayName ?? '');
    _emailCtrl = TextEditingController(text: e?.email ?? '');
    _passwordCtrl = TextEditingController();
    _phoneCtrl = TextEditingController(text: e?.phone ?? '');
    _addressCtrl = TextEditingController(text: e?.address ?? '');
    _pinCtrl = TextEditingController(text: e?.pinCode ?? '');
    _govIdCtrl = TextEditingController(text: e?.govIdNumber ?? '');
    _salaryCtrl = TextEditingController(
      text: e?.salary != null
          ? (e!.salary! % 1 == 0
                ? e.salary!.toStringAsFixed(0)
                : e.salary!.toStringAsFixed(2))
          : '',
    );
    _dateOfBirth = e?.dateOfBirth;
    _dateOfJoining = e?.dateOfJoining;
    _govIdType = e?.govIdType;
    _counterAccess = e?.counterAccess ?? true;
    _modules = {
      ...(e?.allowedModules ??
          AppModule.defaultEmployeeModules.map((m) => m.key)),
    };
    if (!_counterAccess) {
      _modules.remove(AppModule.billing.key);
    }
    _active = e?.active ?? true;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    _pinCtrl.dispose();
    _govIdCtrl.dispose();
    _salaryCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate({
    required DateTime? current,
    required ValueChanged<DateTime?> onPicked,
    DateTime? firstDate,
    DateTime? lastDate,
  }) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: current ?? now,
      firstDate: firstDate ?? DateTime(1950),
      lastDate: lastDate ?? now,
    );
    if (picked != null) onPicked(picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_modules.isEmpty) {
      GlassyToast.show(context, 'Select at least one module');
      return;
    }
    setState(() => _saving = true);
    try {
      final salaryRaw = _salaryCtrl.text.trim();
      await widget.onSave(
        _EditorData(
          email: _emailCtrl.text.trim(),
          password: widget.existing == null ? _passwordCtrl.text : null,
          displayName: _nameCtrl.text.trim(),
          phone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
          counterAccess: _counterAccess,
          modules: _modules.toList(),
          active: _active,
          dateOfBirth: _dateOfBirth,
          address: _addressCtrl.text.trim().isEmpty
              ? null
              : _addressCtrl.text.trim(),
          pinCode: _pinCtrl.text.trim().isEmpty ? null : _pinCtrl.text.trim(),
          govIdNumber: _govIdCtrl.text.trim().isEmpty
              ? null
              : _govIdCtrl.text.trim(),
          govIdType: _govIdType,
          salary: salaryRaw.isEmpty ? null : double.tryParse(salaryRaw),
          dateOfJoining: _dateOfJoining,
        ),
      );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        final msg = e is StateError
            ? e.message
            : e.toString().replaceFirst('Exception: ', '');
        GlassyToast.show(context, msg, isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isNew = widget.existing == null;
    final isDesktop = DesktopCanvas.isDesktopPlatform;

    return dockDrawerAction(
      context: context,
      phoneDecoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      action: DrawerBottomBar(
        action: AppPillButton(
          label: isNew ? 'Create employee' : 'Save changes',
          icon: Icons.check_rounded,
          loading: _saving,
          expanded: true,
          onPressed: _saving ? null : () => _submit(),
        ),
      ),
      body: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!isDesktop)
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.grey300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            if (!isDesktop) const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Text(
                    isNew ? 'Add employee' : 'Edit employee',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppColors.accent(context),
                      fontFamily: 'Literata',
                    ),
                  ),
                ),
                if (!isDesktop)
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Token is used on bills. Counter access controls billing.',
              style: TextStyle(
                color: AppColors.mutedText(context),
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 16),
            InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Token number',
                border: OutlineInputBorder(),
              ),
              child: Text(
                '${widget.previewToken}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _nameCtrl,
              enabled: !_saving,
              decoration: const InputDecoration(
                labelText: 'Full name',
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _emailCtrl,
              enabled: isNew && !_saving,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Login email',
                border: OutlineInputBorder(),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Required';
                if (!v.contains('@')) return 'Invalid email';
                return null;
              },
            ),
            if (isNew) ...[
              const SizedBox(height: 12),
              TextFormField(
                controller: _passwordCtrl,
                enabled: !_saving,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Temporary password',
                  border: OutlineInputBorder(),
                ),
                validator: (v) {
                  if (v == null || v.length < 6) {
                    return 'At least 6 characters';
                  }
                  return null;
                },
              ),
            ],
            const SizedBox(height: 12),
            TextFormField(
              controller: _phoneCtrl,
              enabled: !_saving,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Phone (optional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Personal & employment',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 16,
                color: AppColors.primaryText(context),
              ),
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: _saving
                  ? null
                  : () => _pickDate(
                        current: _dateOfBirth,
                        lastDate: DateTime.now(),
                        onPicked: (d) => setState(() => _dateOfBirth = d),
                      ),
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: 'Date of birth',
                  border: const OutlineInputBorder(),
                  suffixIcon: _dateOfBirth != null
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 18),
                          onPressed: _saving
                              ? null
                              : () => setState(() => _dateOfBirth = null),
                        )
                      : const Icon(Icons.calendar_today_outlined, size: 18),
                ),
                child: Text(
                  _dateOfBirth != null
                      ? _dateFmt.format(_dateOfBirth!)
                      : 'Select date',
                  style: TextStyle(
                    color: _dateOfBirth != null
                        ? AppColors.primaryText(context)
                        : AppColors.mutedText(context),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _addressCtrl,
              enabled: !_saving,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Address',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _pinCtrl,
              enabled: !_saving,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(6),
              ],
              decoration: const InputDecoration(
                labelText: 'PIN code',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _govIdType,
              decoration: const InputDecoration(
                labelText: 'Gov ID type',
                border: OutlineInputBorder(),
              ),
              items: _govIdTypes
                  .map(
                    (t) => DropdownMenuItem(value: t, child: Text(t)),
                  )
                  .toList(),
              onChanged: _saving
                  ? null
                  : (v) => setState(() => _govIdType = v),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _govIdCtrl,
              enabled: !_saving,
              decoration: const InputDecoration(
                labelText: 'Gov ID number / proof',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _salaryCtrl,
              enabled: !_saving,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
              ],
              decoration: const InputDecoration(
                labelText: 'Salary (₹)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: _saving
                  ? null
                  : () => _pickDate(
                        current: _dateOfJoining ?? DateTime.now(),
                        firstDate: DateTime(1990),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                        onPicked: (d) => setState(() => _dateOfJoining = d),
                      ),
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: 'Date of joining',
                  border: const OutlineInputBorder(),
                  suffixIcon: _dateOfJoining != null
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 18),
                          onPressed: _saving
                              ? null
                              : () => setState(() => _dateOfJoining = null),
                        )
                      : const Icon(Icons.event_available_outlined, size: 18),
                ),
                child: Text(
                  _dateOfJoining != null
                      ? _dateFmt.format(_dateOfJoining!)
                      : 'Select date',
                  style: TextStyle(
                    color: _dateOfJoining != null
                        ? AppColors.primaryText(context)
                        : AppColors.mutedText(context),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Allow counter access'),
              subtitle: const Text('Required to open Billing and print bills'),
              value: _counterAccess,
              onChanged: _saving
                  ? null
                  : (v) {
                      setState(() {
                        _counterAccess = v ?? false;
                        if (_counterAccess) {
                          _modules.add(AppModule.billing.key);
                        } else {
                          _modules.remove(AppModule.billing.key);
                        }
                      });
                    },
              controlAffinity: ListTileControlAffinity.leading,
            ),
            if (!isNew) ...[
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Active'),
                value: _active,
                onChanged: _saving ? null : (v) => setState(() => _active = v),
              ),
            ],
            const SizedBox(height: 12),
            const Text(
              'Module access',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: AppModule.grantable.map((m) {
                final selected = _modules.contains(m.key);
                final billingLocked =
                    m == AppModule.billing && !_counterAccess;
                return FilterChip(
                  label: Text(m.label),
                  selected: selected,
                  onSelected: (_saving || billingLocked)
                      ? null
                      : (v) {
                          setState(() {
                            if (v) {
                              _modules.add(m.key);
                            } else if (m != AppModule.password) {
                              _modules.remove(m.key);
                            }
                          });
                        },
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

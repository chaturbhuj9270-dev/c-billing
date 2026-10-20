import 'package:flutter/material.dart';
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

class EmployeesPage extends StatefulWidget {
  final bool isEmbedded;

  const EmployeesPage({super.key, this.isEmbedded = false});

  @override
  State<EmployeesPage> createState() => _EmployeesPageState();
}

class _EmployeesPageState extends State<EmployeesPage> {
  final _repo = EmployeeRepository();
  List<Employee> _employees = [];
  bool _loading = true;
  String? _error;

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

  Future<void> _openEditor({Employee? existing}) async {
    final result = await showAppBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.transparent,
      builder: (ctx) => _EmployeeEditorSheet(
        existing: existing,
        onSave: (data) async {
          if (existing == null) {
            await _repo.createEmployee(
              email: data.email,
              password: data.password!,
              displayName: data.displayName,
              phone: data.phone,
              counterLabel: data.counterLabel,
              allowedModules: data.modules,
            );
          } else {
            await _repo.updateEmployee(
              existing.copyWith(
                displayName: data.displayName,
                phone: data.phone,
                counterLabel: data.counterLabel,
                allowedModules: data.modules,
                active: data.active,
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

  @override
  Widget build(BuildContext context) {
    final body = Stack(
      children: [
        _buildBody(),
        if (AccessControlService.instance.isOwner &&
            !(widget.isEmbedded && DesktopCanvas.isDesktopPlatform))
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
    );
    if (widget.isEmbedded) return body;
    return AppScaffold(title: 'Employees', body: body);
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
    if (_employees.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.groups_outlined,
                size: 56,
                color: AppTheme.grey,
              ),
              const SizedBox(height: 12),
              const Text(
                'No employees yet',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Text(
                'Add counter staff and choose which modules they can use.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.grey600),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => _openEditor(),
                icon: const Icon(Icons.person_add_alt_1_rounded),
                label: const Text('Add employee'),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 88),
        itemCount: _employees.length,
        separatorBuilder: (_, _) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final e = _employees[index];
          final moduleCount = e.allowedModules.length;
          return Material(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(12),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              leading: CircleAvatar(
                backgroundColor: e.active
                    ? AppTheme.primary.withValues(alpha: 0.15)
                    : AppTheme.grey300,
                child: Text(
                  e.displayName.isNotEmpty
                      ? e.displayName[0].toUpperCase()
                      : '?',
                  style: TextStyle(
                    color: e.active ? AppTheme.primary : AppTheme.grey600,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              title: Text(
                e.displayName,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                [
                  e.email,
                  if (e.counterLabel != null && e.counterLabel!.isNotEmpty)
                    e.counterLabel!,
                  '$moduleCount modules',
                  if (!e.active) 'Inactive',
                ].join(' · '),
              ),
              trailing: Switch(
                value: e.active,
                onChanged: (v) async {
                  try {
                    await _repo.setActive(e.id, v);
                    await _load();
                  } catch (err) {
                    if (!mounted) return;
                    GlassyToast.show(context, 'Update failed: $err');
                  }
                },
              ),
              onTap: () => _openEditor(existing: e),
            ),
          );
        },
      ),
    );
  }
}

class _EditorData {
  final String email;
  final String? password;
  final String displayName;
  final String? phone;
  final String? counterLabel;
  final List<String> modules;
  final bool active;

  const _EditorData({
    required this.email,
    this.password,
    required this.displayName,
    this.phone,
    this.counterLabel,
    required this.modules,
    required this.active,
  });
}

class _EmployeeEditorSheet extends StatefulWidget {
  final Employee? existing;
  final Future<void> Function(_EditorData data) onSave;

  const _EmployeeEditorSheet({
    required this.existing,
    required this.onSave,
  });

  @override
  State<_EmployeeEditorSheet> createState() => _EmployeeEditorSheetState();
}

class _EmployeeEditorSheetState extends State<_EmployeeEditorSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _passwordCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _counterCtrl;
  late Set<String> _modules;
  late bool _active;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _nameCtrl = TextEditingController(text: e?.displayName ?? '');
    _emailCtrl = TextEditingController(text: e?.email ?? '');
    _passwordCtrl = TextEditingController();
    _phoneCtrl = TextEditingController(text: e?.phone ?? '');
    _counterCtrl = TextEditingController(text: e?.counterLabel ?? '');
    _modules = {
      ...(e?.allowedModules ??
          AppModule.defaultEmployeeModules.map((m) => m.key)),
    };
    _active = e?.active ?? true;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _phoneCtrl.dispose();
    _counterCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_modules.isEmpty) {
      GlassyToast.show(context, 'Select at least one module');
      return;
    }
    setState(() => _saving = true);
    try {
      await widget.onSave(
        _EditorData(
          email: _emailCtrl.text.trim(),
          password: widget.existing == null ? _passwordCtrl.text : null,
          displayName: _nameCtrl.text.trim(),
          phone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
          counterLabel: _counterCtrl.text.trim().isEmpty
              ? null
              : _counterCtrl.text.trim(),
          modules: _modules.toList(),
          active: _active,
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
              'Choose modules this counter user can open.',
              style: TextStyle(
                color: AppColors.mutedText(context),
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 16),
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
            const SizedBox(height: 12),
            TextFormField(
              controller: _counterCtrl,
              enabled: !_saving,
              decoration: const InputDecoration(
                labelText: 'Counter / label (optional)',
                hintText: 'e.g. Counter 1',
                border: OutlineInputBorder(),
              ),
            ),
            if (!isNew) ...[
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Active'),
                value: _active,
                onChanged: _saving ? null : (v) => setState(() => _active = v),
              ),
            ],
            const SizedBox(height: 16),
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
                return FilterChip(
                  label: Text(m.label),
                  selected: selected,
                  onSelected: _saving
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

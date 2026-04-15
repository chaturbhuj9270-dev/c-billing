import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/auth/hotel_auth_service.dart';
import '../../../../core/auth/hotel_roles.dart';
import '../../../../core/auth/hotel_sub_user.dart';
import '../../../../core/ui/glassy_toast.dart';
import '../widgets/credential_display_sheet.dart';

/// Full-page form for Admin to create or edit staff credentials.
/// Prevents self-registration — only accessible from admin session.
class StaffCredentialFormPage extends StatefulWidget {
  final HotelSubUser? existing;

  const StaffCredentialFormPage({super.key, this.existing});

  @override
  State<StaffCredentialFormPage> createState() =>
      _StaffCredentialFormPageState();
}

class _StaffCredentialFormPageState extends State<StaffCredentialFormPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _authService = HotelAuthService.instance;

  late final TextEditingController _nameCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _passwordCtrl;
  late final TextEditingController _staffIdCtrl;

  late HotelUserRole _selectedRole;
  late HotelDepartment _selectedDepartment;
  late List<HotelModule> _selectedModules;
  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _isGeneratingId = false;

  late final AnimationController _animController;
  late final Animation<double> _fadeAnim;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _nameCtrl = TextEditingController(text: e?.name ?? '');
    _emailCtrl = TextEditingController(text: e?.email ?? '');
    _phoneCtrl = TextEditingController(text: e?.phone ?? '');
    _passwordCtrl = TextEditingController();
    _staffIdCtrl = TextEditingController(text: e?.staffId ?? '');
    _selectedRole = e?.role ?? HotelUserRole.waiter;
    _selectedDepartment = e?.department ?? HotelDepartment.custom;
    _selectedModules = List.from(
      e?.allowedModules ?? _defaultModulesForRole(_selectedRole),
    );

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();

    if (!_isEdit) _autoGenerateStaffId();
  }

  @override
  void dispose() {
    _animController.dispose();
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _passwordCtrl.dispose();
    _staffIdCtrl.dispose();
    super.dispose();
  }

  Future<void> _autoGenerateStaffId() async {
    setState(() => _isGeneratingId = true);
    try {
      final id = await _authService.generateStaffId();
      if (mounted) {
        _staffIdCtrl.text = id;
        setState(() => _isGeneratingId = false);
      }
    } catch (_) {
      if (mounted) setState(() => _isGeneratingId = false);
    }
  }

  void _generatePassword() {
    final pw = HotelAuthService.generateSecurePassword();
    _passwordCtrl.text = pw;
    setState(() => _obscurePassword = false);
  }

  void _onRoleChanged(HotelUserRole role) {
    setState(() {
      _selectedRole = role;
      _selectedModules = _defaultModulesForRole(role);
      // Auto-suggest department
      _selectedDepartment = _suggestDepartment(role);
    });
  }

  HotelDepartment _suggestDepartment(HotelUserRole role) {
    switch (role) {
      case HotelUserRole.cook:
        return HotelDepartment.kitchen;
      case HotelUserRole.waiter:
      case HotelUserRole.captain:
        return HotelDepartment.service;
      case HotelUserRole.receptionist:
        return HotelDepartment.frontDesk;
      case HotelUserRole.housekeeping:
        return HotelDepartment.housekeeping;
      case HotelUserRole.manager:
      case HotelUserRole.admin:
        return HotelDepartment.management;
      case HotelUserRole.custom:
        return HotelDepartment.custom;
    }
  }

  List<HotelModule> _defaultModulesForRole(HotelUserRole role) {
    switch (role) {
      case HotelUserRole.admin:
        return HotelModule.values.toList();
      case HotelUserRole.waiter:
        return [
          HotelModule.dashboard,
          HotelModule.tableManagement,
          HotelModule.orderManagement,
        ];
      case HotelUserRole.cook:
        return [HotelModule.kitchenDisplay, HotelModule.orderManagement];
      case HotelUserRole.captain:
        return [
          HotelModule.dashboard,
          HotelModule.tableManagement,
          HotelModule.orderManagement,
          HotelModule.menuManagement,
          HotelModule.billing,
        ];
      case HotelUserRole.receptionist:
        return [
          HotelModule.dashboard,
          HotelModule.roomManagement,
          HotelModule.guestManagement,
          HotelModule.billing,
        ];
      case HotelUserRole.manager:
        return [
          HotelModule.dashboard,
          HotelModule.tableManagement,
          HotelModule.orderManagement,
          HotelModule.billing,
          HotelModule.reports,
          HotelModule.staffManagement,
          HotelModule.expenses,
        ];
      case HotelUserRole.housekeeping:
        return [HotelModule.roomManagement];
      case HotelUserRole.custom:
        return [HotelModule.dashboard];
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final phone = _phoneCtrl.text.trim();
    final password = _passwordCtrl.text;
    final staffId = _staffIdCtrl.text.trim();

    if (_selectedModules.isEmpty) {
      GlassyToast.show(
        context,
        'Select at least one permission module',
        isError: true,
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (_isEdit) {
        await _authService.updateSubUser(
          widget.existing!.copyWith(
            name: name,
            phone: phone,
            role: _selectedRole,
            department: _selectedDepartment,
            allowedModules: _selectedModules,
            staffId: staffId,
          ),
        );
        if (mounted) {
          GlassyToast.show(context, 'Staff updated successfully');
          Navigator.pop(context, true);
        }
      } else {
        final subUser = await _authService.createSubUserWithCredentials(
          name: name,
          email: email,
          password: password,
          phone: phone,
          role: _selectedRole,
          allowedModules: _selectedModules,
          department: _selectedDepartment,
          staffId: staffId,
        );
        if (mounted) {
          // Show credential display bottom sheet
          await CredentialDisplaySheet.show(
            context,
            user: subUser,
            password: password,
          );
          if (mounted) Navigator.pop(context, true);
        }
      }
    } catch (e) {
      if (mounted) {
        GlassyToast.show(context, 'Error: $e', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F6),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          style: IconButton.styleFrom(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        title: Text(
          _isEdit ? 'Edit Staff' : 'New Staff Credential',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1A1A1A),
          ),
        ),
        centerTitle: true,
      ),
      body: FadeTransition(
        opacity: _fadeAnim,
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
            children: [
              // ─── SECTION: STAFF IDENTITY ───
              _SectionHeader(
                title: 'Staff Identity',
                icon: Icons.badge_outlined,
              ),
              const SizedBox(height: 12),
              _buildCard([
                // Staff ID row
                _buildStaffIdField(),
                const SizedBox(height: 16),
                // Name
                _buildField(
                  controller: _nameCtrl,
                  label: 'Full Name',
                  hint: 'Enter staff member\'s name',
                  icon: Icons.person_outline,
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Name is required' : null,
                ),
                const SizedBox(height: 16),
                // Phone
                _buildField(
                  controller: _phoneCtrl,
                  label: 'Phone Number',
                  hint: '+91 XXXXX XXXXX',
                  icon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),
              ]),
              const SizedBox(height: 24),

              // ─── SECTION: LOGIN CREDENTIALS ───
              _SectionHeader(
                title: 'Login Credentials',
                icon: Icons.lock_outline,
              ),
              const SizedBox(height: 12),
              _buildCard([
                // Email
                _buildField(
                  controller: _emailCtrl,
                  label: 'Email Address',
                  hint: 'staff@hotel.com',
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  readOnly: _isEdit,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Email required';
                    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(v.trim())) {
                      return 'Enter a valid email';
                    }
                    return null;
                  },
                ),
                if (!_isEdit) ...[
                  const SizedBox(height: 16),
                  // Password with generate
                  _buildPasswordField(),
                ],
              ]),
              const SizedBox(height: 24),

              // ─── SECTION: ROLE & DEPARTMENT ───
              _SectionHeader(
                title: 'Role & Department',
                icon: Icons.work_outline,
              ),
              const SizedBox(height: 12),
              _buildRoleSelector(theme),
              const SizedBox(height: 16),
              _buildDepartmentSelector(theme),
              const SizedBox(height: 24),

              // ─── SECTION: PERMISSIONS ───
              _SectionHeader(
                title: 'Module Permissions',
                icon: Icons.security_outlined,
              ),
              const SizedBox(height: 8),
              Text(
                'Control exactly what this staff member can access',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.grey.shade500,
                ),
              ),
              const SizedBox(height: 12),
              _buildPermissionGrid(theme),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomBar(theme),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  STAFF ID FIELD
  // ═══════════════════════════════════════════════════════════════
  Widget _buildStaffIdField() {
    return Row(
      children: [
        Expanded(
          child: _buildField(
            controller: _staffIdCtrl,
            label: 'Staff ID',
            hint: 'STF-001',
            icon: Icons.tag,
            readOnly: true,
          ),
        ),
        const SizedBox(width: 8),
        if (!_isEdit)
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1B4D3E).withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              onPressed: _isGeneratingId ? null : _autoGenerateStaffId,
              icon: _isGeneratingId
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh, color: Color(0xFF1B4D3E)),
              tooltip: 'Regenerate ID',
            ),
          ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  PASSWORD FIELD WITH GENERATE BUTTON
  // ═══════════════════════════════════════════════════════════════
  Widget _buildPasswordField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _passwordCtrl,
                obscureText: _obscurePassword,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Password required';
                  if (v.length < 6) return 'Min 6 characters';
                  return null;
                },
                decoration: InputDecoration(
                  labelText: 'Password',
                  hintText: 'Min 6 characters',
                  prefixIcon: const Icon(
                    Icons.lock_outline,
                    size: 20,
                    color: Color(0xFF1B4D3E),
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      size: 20,
                    ),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF8FAF9),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(
                      color: Color(0xFF1B4D3E),
                      width: 1.5,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1B4D3E), Color(0xFF2E7D5B)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                onPressed: _generatePassword,
                icon: const Icon(Icons.auto_fix_high, color: Colors.white),
                tooltip: 'Generate secure password',
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Icon(Icons.info_outline, size: 12, color: Colors.grey.shade400),
            const SizedBox(width: 4),
            Text(
              'Tap the wand to auto-generate a secure password',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
            ),
          ],
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  ROLE SELECTOR — HORIZONTAL SCROLLABLE CHIPS
  // ═══════════════════════════════════════════════════════════════
  Widget _buildRoleSelector(ThemeData theme) {
    final roles = HotelUserRole.values
        .where((r) => r != HotelUserRole.admin)
        .toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select Role',
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: roles.map((role) {
              final isSelected = role == _selectedRole;
              final color = _roleColor(role);

              return GestureDetector(
                onTap: () => _onRoleChanged(role),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected ? color : color.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: isSelected ? color : color.withOpacity(0.2),
                      width: isSelected ? 2 : 1,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: color.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ]
                        : null,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _roleIcon(role),
                        size: 16,
                        color: isSelected ? Colors.white : color,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        role.label,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? Colors.white : color,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  DEPARTMENT SELECTOR
  // ═══════════════════════════════════════════════════════════════
  Widget _buildDepartmentSelector(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Department',
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: HotelDepartment.values.map((dept) {
              final isSelected = dept == _selectedDepartment;

              return GestureDetector(
                onTap: () => setState(() => _selectedDepartment = dept),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 9,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF1B4D3E)
                        : const Color(0xFF1B4D3E).withOpacity(0.05),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF1B4D3E)
                          : Colors.grey.shade300,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        dept.icon,
                        size: 15,
                        color: isSelected
                            ? Colors.white
                            : const Color(0xFF1B4D3E),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        dept.label,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? Colors.white
                              : const Color(0xFF1A1A1A),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  PERMISSION GRID — TOGGLE CHIPS
  // ═══════════════════════════════════════════════════════════════
  Widget _buildPermissionGrid(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Select All / None
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${_selectedModules.length} of ${HotelModule.values.length} modules',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade500,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Row(
                children: [
                  TextButton(
                    onPressed: () => setState(
                      () => _selectedModules = HotelModule.values.toList(),
                    ),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text(
                      'All',
                      style: TextStyle(fontSize: 12, color: Color(0xFF1B4D3E)),
                    ),
                  ),
                  const Text('|', style: TextStyle(color: Colors.grey)),
                  TextButton(
                    onPressed: () => setState(() => _selectedModules.clear()),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      'None',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.red.shade400,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Module toggles
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: HotelModule.values.map((module) {
              final isOn = _selectedModules.contains(module);
              return GestureDetector(
                onTap: () {
                  setState(() {
                    if (isOn) {
                      _selectedModules.remove(module);
                    } else {
                      _selectedModules.add(module);
                    }
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isOn
                        ? const Color(0xFF1B4D3E).withOpacity(0.1)
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isOn
                          ? const Color(0xFF1B4D3E)
                          : Colors.grey.shade300,
                      width: isOn ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isOn
                            ? Icons.check_circle
                            : Icons.radio_button_unchecked,
                        size: 16,
                        color: isOn
                            ? const Color(0xFF1B4D3E)
                            : Colors.grey.shade400,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        module.label,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isOn ? FontWeight.w600 : FontWeight.w400,
                          color: isOn
                              ? const Color(0xFF1B4D3E)
                              : Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  BOTTOM ACTION BAR
  // ═══════════════════════════════════════════════════════════════
  Widget _buildBottomBar(ThemeData theme) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        12 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Cancel
          Expanded(
            child: OutlinedButton(
              onPressed: _isLoading ? null : () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: BorderSide(color: Colors.grey.shade300),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                'Cancel',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF666666),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Submit
          Expanded(
            flex: 2,
            child: FilledButton(
              onPressed: _isLoading ? null : _submit,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                backgroundColor: const Color(0xFF1B4D3E),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _isEdit ? Icons.save_rounded : Icons.person_add,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _isEdit ? 'Update Staff' : 'Create Staff',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  SHARED WIDGETS
  // ═══════════════════════════════════════════════════════════════
  Widget _buildCard(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    String? hint,
    IconData? icon,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    bool readOnly = false,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      readOnly: readOnly,
      inputFormatters: inputFormatters,
      validator: validator,
      style: TextStyle(
        color: readOnly ? Colors.grey.shade500 : const Color(0xFF1A1A1A),
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: icon != null
            ? Icon(icon, size: 20, color: const Color(0xFF1B4D3E))
            : null,
        filled: true,
        fillColor: readOnly ? Colors.grey.shade100 : const Color(0xFFF8FAF9),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF1B4D3E), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.red),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
    );
  }

  Color _roleColor(HotelUserRole role) {
    switch (role) {
      case HotelUserRole.admin:
        return const Color(0xFF1B4D3E);
      case HotelUserRole.waiter:
        return const Color(0xFF43A047);
      case HotelUserRole.cook:
        return const Color(0xFFEF6C00);
      case HotelUserRole.captain:
        return const Color(0xFF8E24AA);
      case HotelUserRole.receptionist:
        return const Color(0xFF00897B);
      case HotelUserRole.manager:
        return const Color(0xFF2E7D5B);
      case HotelUserRole.housekeeping:
        return const Color(0xFF5D4037);
      case HotelUserRole.custom:
        return const Color(0xFF757575);
    }
  }

  IconData _roleIcon(HotelUserRole role) {
    switch (role) {
      case HotelUserRole.admin:
        return Icons.admin_panel_settings;
      case HotelUserRole.waiter:
        return Icons.room_service;
      case HotelUserRole.cook:
        return Icons.restaurant;
      case HotelUserRole.captain:
        return Icons.military_tech;
      case HotelUserRole.receptionist:
        return Icons.desk;
      case HotelUserRole.manager:
        return Icons.business_center;
      case HotelUserRole.housekeeping:
        return Icons.cleaning_services;
      case HotelUserRole.custom:
        return Icons.person;
    }
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;

  const _SectionHeader({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: const Color(0xFF1B4D3E).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: const Color(0xFF1B4D3E)),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1A1A1A),
          ),
        ),
      ],
    );
  }
}

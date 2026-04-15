import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/auth/hotel_sub_user.dart';
import '../../data/auth/hotel_roles.dart';
import '../../../../core/ui/glassy_toast.dart';

/// Bottom sheet displayed after creating a staff member,
/// showing their generated credentials for admin to share/copy.
class CredentialDisplaySheet extends StatelessWidget {
  final HotelSubUser user;
  final String password;

  const CredentialDisplaySheet({
    super.key,
    required this.user,
    required this.password,
  });

  static Future<void> show(
    BuildContext context, {
    required HotelSubUser user,
    required String password,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: false,
      builder: (_) => CredentialDisplaySheet(user: user, password: password),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: EdgeInsets.fromLTRB(24, 8, 24, 24 + bottom),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 30,
                offset: const Offset(0, -8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),

              // Success icon
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1B4D3E).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: Color(0xFF1B4D3E),
                  size: 48,
                ),
              ),
              const SizedBox(height: 16),

              Text(
                'Staff Created Successfully',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF1A1A1A),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Share these credentials with ${user.name}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 24),

              // Credential card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAF9),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFF1B4D3E).withOpacity(0.15),
                  ),
                ),
                child: Column(
                  children: [
                    _CredentialRow(
                      label: 'Staff ID',
                      value: user.staffId,
                      icon: Icons.badge_outlined,
                    ),
                    const Divider(height: 20),
                    _CredentialRow(
                      label: 'Name',
                      value: user.name,
                      icon: Icons.person_outline,
                    ),
                    const Divider(height: 20),
                    _CredentialRow(
                      label: 'Email',
                      value: user.email,
                      icon: Icons.email_outlined,
                    ),
                    const Divider(height: 20),
                    _CredentialRow(
                      label: 'Password',
                      value: password,
                      icon: Icons.lock_outline,
                      isSensitive: true,
                    ),
                    const Divider(height: 20),
                    _CredentialRow(
                      label: 'Role',
                      value: user.role.label,
                      icon: Icons.work_outline,
                    ),
                    const Divider(height: 20),
                    _CredentialRow(
                      label: 'Department',
                      value: user.department.label,
                      icon: Icons.business_outlined,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Copy all button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _copyAll(context),
                  icon: const Icon(Icons.copy_rounded, size: 18),
                  label: const Text('Copy All Credentials'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    foregroundColor: const Color(0xFF1B4D3E),
                    side: const BorderSide(color: Color(0xFF1B4D3E)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Done button
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.pop(context),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: const Color(0xFF1B4D3E),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Done',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _copyAll(BuildContext context) {
    final text =
        '''
Staff Credentials — ${user.name}
━━━━━━━━━━━━━━━━━━━━━━
Staff ID: ${user.staffId}
Name: ${user.name}
Email: ${user.email}
Password: $password
Role: ${user.role.label}
Department: ${user.department.label}
━━━━━━━━━━━━━━━━━━━━━━
''';
    Clipboard.setData(ClipboardData(text: text.trim()));
    GlassyToast.show(context, 'Credentials copied to clipboard');
  }
}

class _CredentialRow extends StatefulWidget {
  final String label;
  final String value;
  final IconData icon;
  final bool isSensitive;

  const _CredentialRow({
    required this.label,
    required this.value,
    required this.icon,
    this.isSensitive = false,
  });

  @override
  State<_CredentialRow> createState() => _CredentialRowState();
}

class _CredentialRowState extends State<_CredentialRow> {
  bool _revealed = false;

  @override
  Widget build(BuildContext context) {
    final displayValue = widget.isSensitive && !_revealed
        ? '•' * widget.value.length
        : widget.value;

    return Row(
      children: [
        Icon(widget.icon, size: 18, color: const Color(0xFF1B4D3E)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade500,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                displayValue,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A1A),
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
        ),
        if (widget.isSensitive)
          GestureDetector(
            onTap: () => setState(() => _revealed = !_revealed),
            child: Icon(
              _revealed ? Icons.visibility_off : Icons.visibility,
              size: 18,
              color: Colors.grey.shade400,
            ),
          ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: () {
            Clipboard.setData(ClipboardData(text: widget.value));
            GlassyToast.show(context, '${widget.label} copied');
          },
          child: Icon(Icons.copy, size: 16, color: Colors.grey.shade400),
        ),
      ],
    );
  }
}

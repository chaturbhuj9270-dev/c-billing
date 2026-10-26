import 'package:flutter/material.dart';
import 'package:c_billing/core/theme/app_theme.dart';

/// Shared sync indicator for list rows: cloud + check when synced,
/// cloud upload when pending. Icon only — theme colors only.
class SyncStatusIcon extends StatelessWidget {
  final bool isSynced;
  final double size;
  final bool padded;

  const SyncStatusIcon({
    super.key,
    required this.isSynced,
    this.size = 16,
    this.padded = true,
  });

  static IconData iconFor(bool isSynced) =>
      isSynced ? Icons.cloud_done_rounded : Icons.cloud_upload_rounded;

  static Color colorFor(BuildContext context, bool isSynced) => isSynced
      ? AppColors.actionBright(context)
      : AppTheme.toneAmber;

  @override
  Widget build(BuildContext context) {
    final icon = Icon(
      iconFor(isSynced),
      size: size,
      color: colorFor(context, isSynced),
    );
    if (!padded) return icon;
    return Padding(
      padding: const EdgeInsets.only(left: 6),
      child: icon,
    );
  }
}

import 'package:flutter/material.dart';
import 'package:c_billing/core/services/language_service.dart';
import 'package:c_billing/core/localization/app_localizations.dart';

/// World-class UI/UX Action Menu — three-dot popup menu
/// Works inside Row, Column, AppBar, or any layout widget.
/// Uses PopupMenuButton under the hood so it never causes Stack constraint errors.
class ActionMenu extends StatelessWidget {
  final VoidCallback? onSettingsTap;
  final VoidCallback? onReportSettingsTap;
  final VoidCallback? onLanguageTap;
  final VoidCallback? onBugReportTap;
  final Color menuColor;
  final Color iconColor;
  final double iconSize;

  const ActionMenu({
    super.key,
    this.onSettingsTap,
    this.onReportSettingsTap,
    this.onLanguageTap,
    this.onBugReportTap,
    this.menuColor = const Color(0xFF1B4D3E),
    this.iconColor = Colors.white,
    this.iconSize = 22,
  });

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(
      LanguageService.instance.currentLanguage,
    );

    // Collect visible menu entries
    final List<_MenuEntry> entries = [];
    if (onSettingsTap != null) {
      entries.add(_MenuEntry(
        icon: Icons.settings_rounded,
        label: localizations.settings,
        onTap: onSettingsTap!,
      ));
    }
    if (onReportSettingsTap != null) {
      entries.add(_MenuEntry(
        icon: Icons.view_column_rounded,
        label: 'Report Settings',
        onTap: onReportSettingsTap!,
      ));
    }
    if (onLanguageTap != null) {
      entries.add(_MenuEntry(
        icon: Icons.language_rounded,
        label: localizations.language,
        onTap: onLanguageTap!,
      ));
    }
    if (onBugReportTap != null) {
      entries.add(_MenuEntry(
        icon: Icons.bug_report_rounded,
        label: localizations.reportIssue,
        onTap: onBugReportTap!,
      ));
    }

    return PopupMenuButton<int>(
      icon: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.2),
          ),
        ),
        child: Icon(
          Icons.more_vert_rounded,
          color: iconColor,
          size: iconSize,
        ),
      ),
      offset: const Offset(0, 48),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 8,
      color: Colors.white,
      surfaceTintColor: Colors.transparent,
      onSelected: (index) {
        entries[index].onTap();
      },
      itemBuilder: (context) {
        final items = <PopupMenuEntry<int>>[];

        // Header
        items.add(PopupMenuItem<int>(
          enabled: false,
          height: 40,
          padding: EdgeInsets.zero,
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  menuColor.withValues(alpha: 0.08),
                  menuColor.withValues(alpha: 0.03),
                ],
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.tune_rounded, color: menuColor, size: 16),
                const SizedBox(width: 8),
                Text(
                  localizations.options,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: menuColor,
                    fontFamily: 'Literata',
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
        ));

        items.add(const PopupMenuDivider(height: 1));

        // Menu items
        for (int i = 0; i < entries.length; i++) {
          items.add(PopupMenuItem<int>(
            value: i,
            height: 52,
            padding: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: menuColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: menuColor.withValues(alpha: 0.1),
                        width: 1,
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        entries[i].icon,
                        color: menuColor,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    entries[i].label,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1B4D3E),
                      fontFamily: 'Literata',
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
            ),
          ));

          if (i < entries.length - 1) {
            items.add(const PopupMenuDivider(height: 1));
          }
        }

        return items;
      },
    );
  }
}

class _MenuEntry {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _MenuEntry({
    required this.icon,
    required this.label,
    required this.onTap,
  });
}

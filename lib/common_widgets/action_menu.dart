import 'package:flutter/material.dart';
import 'package:c_billing/core/theme/app_theme.dart';
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

    final List<_MenuEntry> entries = [];
    if (onSettingsTap != null) {
      entries.add(
        _MenuEntry(
          icon: Icons.settings_outlined,
          color: AppTheme.mint,
          label: localizations.settings,
          onTap: onSettingsTap!,
        ),
      );
    }
    if (onReportSettingsTap != null) {
      entries.add(
        _MenuEntry(
          icon: Icons.view_column_rounded,
          color: AppTheme.toneBlue,
          label: localizations.reportSettings,
          onTap: onReportSettingsTap!,
        ),
      );
    }
    if (onLanguageTap != null) {
      entries.add(
        _MenuEntry(
          icon: Icons.language_rounded,
          color: AppTheme.toneAmber,
          label: localizations.language,
          onTap: onLanguageTap!,
        ),
      );
    }
    if (onBugReportTap != null) {
      entries.add(
        _MenuEntry(
          icon: Icons.bug_report_outlined,
          color: AppTheme.toneRose,
          label: localizations.reportIssue,
          onTap: onBugReportTap!,
        ),
      );
    }

    final useMintButton = menuColor == const Color(0xFF1B4D3E);
    final buttonColor = useMintButton ? AppTheme.mint : menuColor;
    final dotColor = useMintButton ? AppTheme.onMint : iconColor;

    return PopupMenuButton<int>(
      padding: EdgeInsets.zero,
      icon: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(color: buttonColor, shape: BoxShape.circle),
        child: Icon(Icons.more_vert_rounded, color: dotColor, size: iconSize),
      ),
      offset: const Offset(0, 48),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      elevation: 12,
      color: AppColors.isDark(context)
          ? AppTheme.darkCard
          : AppColors.card(context),
      surfaceTintColor: Colors.transparent,
      onSelected: (index) => entries[index].onTap(),
      itemBuilder: (context) {
        final items = <PopupMenuEntry<int>>[
          PopupMenuItem<int>(
            enabled: false,
            height: 32,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Text(
              localizations.options.toUpperCase(),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.1,
                color: AppColors.mutedText(context),
                fontFamily: 'Literata',
              ),
            ),
          ),
        ];

        for (var i = 0; i < entries.length; i++) {
          final entry = entries[i];
          items.add(
            PopupMenuItem<int>(
              value: i,
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: entry.color.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(entry.icon, color: entry.color, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    entry.label,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryText(context),
                      fontFamily: 'Literata',
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return items;
      },
    );
  }
}

class _MenuEntry {
  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback onTap;

  const _MenuEntry({
    required this.icon,
    required this.color,
    required this.label,
    required this.onTap,
  });
}

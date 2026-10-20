import 'package:flutter/material.dart';
import 'package:c_billing/core/theme/app_theme.dart';

// One figure in the desktop summary bar used by list screens.
class DesktopStat {
  final String value;
  final String label;
  final VoidCallback? onTap;
  final bool selected;

  const DesktopStat({
    required this.value,
    required this.label,
    this.onTap,
    this.selected = false,
  });
}

// White summary bar matching the Invoices screen: value, label, dividers.
class DesktopStatBar extends StatelessWidget {
  final List<DesktopStat> stats;

  const DesktopStatBar({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    final valueColor = AppColors.action(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Row(
        children: [
          for (var i = 0; i < stats.length; i++) ...[
            if (i > 0)
              Container(
                width: 1,
                height: 36,
                color: AppColors.border(context),
              ),
            Expanded(
              child: InkWell(
                onTap: stats[i].onTap,
                child: Column(
                  children: [
                    Text(
                      stats[i].value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Literata',
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                        color: valueColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      stats[i].label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Literata',
                        fontSize: 11,
                        fontWeight: stats[i].selected
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: stats[i].selected
                            ? valueColor
                            : AppColors.mutedText(context),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

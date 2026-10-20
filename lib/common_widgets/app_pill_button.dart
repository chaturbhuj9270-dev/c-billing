import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../core/ui/desktop_canvas.dart';
import 'glass_bevel_frame.dart';

// Green pill used by the billing Print button.
class AppPillButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool loading;

  // Stretches across the row when this is the only button.
  final bool expanded;

  const AppPillButton({
    super.key,
    required this.label,
    required this.icon,
    this.onPressed,
    this.loading = false,
    this.expanded = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final action = AppColors.action(context);
    final enabled = onPressed != null && !loading;
    final pill = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: action.withValues(alpha: enabled ? 0.28 : 0.1),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: CustomPaint(
          foregroundPainter: GlassBevelBorderPainter(
            isDark: isDark,
            themeColor: AppTheme.primary,
            radius: 28,
            strokeWidth: 1.4,
          ),
          child: Material(
            color: AppTheme.transparent,
            child: InkWell(
              onTap: enabled ? onPressed : null,
              child: Ink(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color.lerp(AppTheme.white, action, isDark ? 0.72 : 0.55)!,
                      action,
                      Color.lerp(action, AppTheme.black, isDark ? 0.28 : 0.18)!,
                    ],
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 22,
                    vertical: 14,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize:
                        expanded ? MainAxisSize.max : MainAxisSize.min,
                    children: loading
                        ? [
                            const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.4,
                                valueColor: AlwaysStoppedAnimation(
                                  AppTheme.white,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Please wait…',
                              style: const TextStyle(
                                fontFamily: 'Literata',
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.white,
                              ),
                            ),
                          ]
                        : [
                            Icon(icon, size: 18, color: AppTheme.white),
                            const SizedBox(width: 8),
                            Text(
                              label,
                              style: const TextStyle(
                                fontFamily: 'Literata',
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.white,
                              ),
                            ),
                          ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    if (!expanded) return pill;
    return SizedBox(width: double.infinity, child: pill);
  }
}

// Pins [action] to the bottom-right of a drawer, matching the billing bar.
class DrawerBottomBar extends StatelessWidget {
  final Widget? leading;
  final Widget action;

  const DrawerBottomBar({super.key, this.leading, required this.action});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        border: Border(top: BorderSide(color: AppColors.border(context))),
      ),
      child: leading == null
          ? action
          : Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(child: leading!),
                const SizedBox(width: 12),
                action,
              ],
            ),
    );
  }
}

// On desktop the action stays at the bottom of the panel. On a phone the sheet keeps its own height and the action sits under the fields.
Widget dockDrawerAction({
  required BuildContext context,
  required Widget body,
  required Widget action,
  BoxDecoration? phoneDecoration,
  EdgeInsets padding = const EdgeInsets.fromLTRB(20, 16, 20, 8),
}) {
  if (DesktopCanvas.isDesktopPlatform) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(padding: padding, child: body),
        ),
        action,
      ],
    );
  }
  return Container(
    decoration: phoneDecoration,
    child: SingleChildScrollView(
      padding: padding.copyWith(
        bottom: padding.bottom + MediaQuery.viewInsetsOf(context).bottom + 12,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [body, action],
      ),
    ),
  );
}

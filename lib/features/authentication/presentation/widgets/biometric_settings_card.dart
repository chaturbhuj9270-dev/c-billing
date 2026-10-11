import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:c_billing/core/theme/app_theme.dart';
import 'package:c_billing/common_widgets/glass_bevel_frame.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/biometric_cubit.dart';
import '../cubit/biometric_state.dart';
import '../../../../../../core/services/biometric_service.dart';
import 'package:c_billing/core/ui/glassy_toast.dart';

/// Settings card for enabling/disabling biometric authentication
class BiometricSettingsCard extends StatefulWidget {
  final String userId;
  final VoidCallback? onChanged;

  const BiometricSettingsCard({
    super.key,
    required this.userId,
    this.onChanged,
  });

  @override
  State<BiometricSettingsCard> createState() => _BiometricSettingsCardState();
}

class _BiometricSettingsCardState extends State<BiometricSettingsCard> {
  late BiometricCubit _biometricCubit;
  bool _isBiometricEnabled = false;
  String? _preferredType;

  @override
  void initState() {
    super.initState();
    _biometricCubit = BiometricCubit(
      biometricService: BiometricService.instance,
      userId: widget.userId,
    );
    _loadBiometricSettings();
  }

  Future<void> _loadBiometricSettings() async {
    try {
      final biometricService = BiometricService.instance;
      final isEnabled = await biometricService.isBiometricAuthEnabled(
        widget.userId,
      );
      final preferredType = await biometricService.getPreferredBiometricType(
        widget.userId,
      );

      if (mounted) {
        setState(() {
          _isBiometricEnabled = isEnabled;
          _preferredType = preferredType;
        });
      }
    } catch (e) {
      print('[ERROR] Error loading biometric settings: $e');
    }
  }

  Future<void> _toggleBiometric(bool value) async {
    try {
      if (value) {
        // First check availability
        await _biometricCubit.checkBiometricAvailability();

        // Get current state to check if biometric is available
        final state = _biometricCubit.state;
        if (state is BiometricAvailable &&
            (state.canUseFace || state.canUseFingerprint)) {
          await _biometricCubit.enableBiometric();

          if (mounted) {
            setState(() {
              _isBiometricEnabled = true;
            });
            widget.onChanged?.call();

            GlassyToast.show(context, 'Biometric authentication enabled');
          }
        } else {
          if (mounted) {
            GlassyToast.show(context, 'Biometric authentication is not available on this device', isError: true);
          }
        }
      } else {
        await _biometricCubit.disableBiometric();

        if (mounted) {
          setState(() {
            _isBiometricEnabled = false;
            _preferredType = null;
          });
          widget.onChanged?.call();

          GlassyToast.show(context, 'Biometric authentication disabled');
        }
      }
    } catch (e) {
      print('[ERROR] Error toggling biometric: $e');
      if (mounted) {
        GlassyToast.show(context, 'Error: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BiometricCubit, BiometricState>(
      bloc: _biometricCubit,
      builder: (context, state) {
        final isDark = AppColors.isDark(context);
        return ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: CustomPaint(
              foregroundPainter: GlassBevelBorderPainter(
                isDark: isDark,
                themeColor: Theme.of(context).primaryColor,
                radius: 16,
              ),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: isDark
                        ? const [
                            AppTheme.darkElevated,
                            AppTheme.darkCard,
                          ]
                        : [
                            AppTheme.white.withValues(alpha: 0.92),
                            AppTheme.white.withValues(alpha: 0.8),
                          ],
                  ),
                ),
                child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with icon and toggle
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Icon(
                              Icons.fingerprint,
                              color: AppColors.accent(context),
                              size: 24,
                            ),
                          ),
                        ),
                        SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Biometric Authentication',
                              style: TextStyle(
                                color: AppColors.accent(context),
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                fontFamily: 'Literata',
                              ),
                            ),
                            Text(
                              _isBiometricEnabled
                                  ? 'Enabled on this device'
                                  : 'Disabled',
                              style: TextStyle(
                                color: AppColors.secondaryText(context),
                                fontSize: 12,
                                fontFamily: 'Literata',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Switch(
                      value: _isBiometricEnabled,
                      onChanged: _toggleBiometric,
                      activeThumbColor: AppTheme.primary,
                      activeTrackColor: AppTheme.primary.withValues(alpha: 0.3),
                    ),
                  ],
                ),
                if (_isBiometricEnabled) ...[
                  SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.accentSoft(context, 0.05),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Icon(
                          Icons.check_circle,
                          color: AppTheme.green600,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Your identity will be verified using $_preferredType authentication when you log in',
                            style: TextStyle(
                              color: AppColors.secondaryText(context),
                              fontSize: 12,
                              fontFamily: 'Literata',
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _biometricCubit.close();
    super.dispose();
  }
}

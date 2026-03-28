import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/biometric_cubit.dart';
import '../cubit/biometric_state.dart';
import '../../../../../../core/services/biometric_service.dart';

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

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Biometric authentication enabled'),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 2),
              ),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text(
                  'Biometric authentication is not available on this device',
                ),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 2),
              ),
            );
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

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Biometric authentication disabled'),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      print('[ERROR] Error toggling biometric: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BiometricCubit, BiometricState>(
      bloc: _biometricCubit,
      builder: (context, state) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.white.withValues(alpha: 0.95),
                Colors.white.withValues(alpha: 0.85),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.3),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1B4D3E).withValues(alpha: 0.08),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
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
                            color: const Color(
                              0xFF1B4D3E,
                            ).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.fingerprint,
                              color: Color(0xFF1B4D3E),
                              size: 24,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Biometric Authentication',
                              style: TextStyle(
                                color: Color(0xFF1B4D3E),
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
                                color: Colors.grey[600],
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
                      activeThumbColor: const Color(0xFF1B4D3E),
                      activeTrackColor: const Color(
                        0xFF1B4D3E,
                      ).withValues(alpha: 0.3),
                    ),
                  ],
                ),
                if (_isBiometricEnabled) ...[
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF1B4D3E).withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Icon(
                          Icons.check_circle,
                          color: Colors.green[600],
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Your identity will be verified using $_preferredType authentication when you log in',
                            style: TextStyle(
                              color: Colors.grey[700],
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

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:ui';
import '../cubit/biometric_cubit.dart';
import '../cubit/biometric_state.dart';

/// Bottom sheet overlay for biometric authentication
class BiometricAuthOverlay extends StatefulWidget {
  final String userId;
  final VoidCallback onSuccess;
  final VoidCallback? onCancel;

  const BiometricAuthOverlay({
    super.key,
    required this.userId,
    required this.onSuccess,
    this.onCancel,
  });

  @override
  State<BiometricAuthOverlay> createState() => _BiometricAuthOverlayState();
}

class _BiometricAuthOverlayState extends State<BiometricAuthOverlay> {
  late BiometricCubit _biometricCubit;

  @override
  void initState() {
    super.initState();
    _biometricCubit = context.read<BiometricCubit>();
    // Don't auto-authenticate - wait for user to tap button
  }

  Future<void> _authenticateUser() async {
    final result = await _biometricCubit.authenticate(
      reason: 'Verify your identity to continue',
    );

    if (result && mounted) {
      widget.onSuccess();
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BiometricCubit, BiometricState>(
      builder: (context, state) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.95),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(24)),
                border: Border(
                  top: BorderSide(
                    color: Colors.white.withOpacity(0.3),
                    width: 1.5,
                  ),
                ),
              ),
              constraints: BoxConstraints(
                minHeight: 300,
                maxHeight: MediaQuery.of(context).size.height * 0.7,
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.symmetric(horizontal: 0),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1B4D3E).withOpacity(0.3),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 24),
                      if (state is BiometricAuthenticating) ...[
                        _buildAuthenticatingContent(),
                      ] else if (state is BiometricAuthenticated) ...[
                        _buildSuccessContent(),
                      ] else if (state is BiometricAuthFailed) ...[
                        _buildErrorContent(state.message),
                      ] else if (state is BiometricAuthCancelled) ...[
                        _buildCancelledContent(),
                      ] else ...[
                        // Initial/Available state - show unlock prompt
                        _buildInitialContent(),
                      ],
                      const SizedBox(height: 16),
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

  Widget _buildInitialContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: const Color(0xFF1B4D3E).withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Center(
            child: Icon(
              Icons.fingerprint,
              color: Color(0xFF1B4D3E),
              size: 48,
            ),
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'Biometric Authentication',
          style: TextStyle(
            color: Color(0xFF1B4D3E),
            fontSize: 20,
            fontWeight: FontWeight.w700,
            fontFamily: 'Literata',
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Use your fingerprint or face to unlock the app securely',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
            fontFamily: 'Literata',
          ),
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _authenticateUser,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1B4D3E),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.lock_open, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text(
                  'Authenticate',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Literata',
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () {
              widget.onCancel?.call();
              Navigator.pop(context);
            },
            style: OutlinedButton.styleFrom(
              side: const BorderSide(
                color: Color(0xFF1B4D3E),
                width: 1.5,
              ),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Skip',
              style: TextStyle(
                color: const Color(0xFF1B4D3E),
                fontSize: 16,
                fontWeight: FontWeight.w600,
                fontFamily: 'Literata',
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAuthenticatingContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: const Color(0xFF1B4D3E).withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Center(
            child: SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(
                  Color(0xFF1B4D3E),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Authenticating',
          style: TextStyle(
            color: Color(0xFF1B4D3E),
            fontSize: 18,
            fontWeight: FontWeight.w700,
            fontFamily: 'Literata',
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Place your finger on the sensor or look at the camera',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 13,
            fontFamily: 'Literata',
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () {
              widget.onCancel?.call();
              Navigator.pop(context);
            },
            style: OutlinedButton.styleFrom(
              side: const BorderSide(
                color: Color(0xFF1B4D3E),
                width: 1.5,
              ),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Skip',
              style: TextStyle(
                color: const Color(0xFF1B4D3E),
                fontSize: 14,
                fontWeight: FontWeight.w600,
                fontFamily: 'Literata',
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSuccessContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: const Color(0xFF4CAF50).withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Center(
            child: Icon(
              Icons.check_circle,
              color: Color(0xFF4CAF50),
              size: 40,
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Authentication Successful',
          style: TextStyle(
            color: Color(0xFF4CAF50),
            fontSize: 18,
            fontWeight: FontWeight.w700,
            fontFamily: 'Literata',
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'You have been verified successfully',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 13,
            fontFamily: 'Literata',
          ),
        ),
      ],
    );
  }

  Widget _buildErrorContent(String message) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: const Color(0xFFFF6B6B).withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Center(
            child: Icon(
              Icons.error,
              color: Color(0xFFFF6B6B),
              size: 40,
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Authentication Failed',
          style: TextStyle(
            color: Color(0xFFFF6B6B),
            fontSize: 18,
            fontWeight: FontWeight.w700,
            fontFamily: 'Literata',
          ),
        ),
        const SizedBox(height: 8),
        Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
            fontFamily: 'Literata',
          ),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  widget.onCancel?.call();
                  Navigator.pop(context);
                },
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(
                    color: Color(0xFF1B4D3E),
                    width: 1.5,
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Cancel',
                  style: TextStyle(
                    color: const Color(0xFF1B4D3E),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Literata',
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  _biometricCubit.reset();
                  _authenticateUser();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1B4D3E),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Try Again',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Literata',
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCancelledContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: Colors.orange.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Center(
            child: Icon(
              Icons.cancel,
              color: Colors.orange,
              size: 40,
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Authentication Cancelled',
          style: TextStyle(
            color: Colors.orange,
            fontSize: 18,
            fontWeight: FontWeight.w700,
            fontFamily: 'Literata',
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'You cancelled the authentication process',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 13,
            fontFamily: 'Literata',
          ),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  widget.onCancel?.call();
                  Navigator.pop(context);
                },
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(
                    color: Color(0xFF1B4D3E),
                    width: 1.5,
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Cancel',
                  style: TextStyle(
                    color: const Color(0xFF1B4D3E),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Literata',
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  _biometricCubit.reset();
                  _authenticateUser();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1B4D3E),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Try Again',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Literata',
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/services/biometric_service.dart';
import 'biometric_state.dart';

/// Cubit for managing biometric authentication
class BiometricCubit extends Cubit<BiometricState> {
  final BiometricService _biometricService;
  final String userId;

  BiometricCubit({
    required BiometricService biometricService,
    required this.userId,
  })  : _biometricService = biometricService,
        super(const BiometricInitial());

  /// Check if biometric authentication is available
  Future<void> checkBiometricAvailability() async {
    try {
      final canUseBiometrics = await _biometricService.canUseBiometrics();

      if (!canUseBiometrics) {
        emit(const BiometricNotAvailable());
        return;
      }

      final canUseFace = await _biometricService.canUseFaceAuth();
      final canUseFingerprint = await _biometricService.canUseFingerprint();
      final isBiometricEnabled =
          await _biometricService.isBiometricAuthEnabled(userId);

      emit(BiometricAvailable(
        canUseFace: canUseFace,
        canUseFingerprint: canUseFingerprint,
        isBiometricEnabled: isBiometricEnabled,
      ));
    } catch (e) {
      print('[BiometricCubit] Error checking biometric availability: $e');
      emit(const BiometricNotAvailable());
    }
  }

  /// Authenticate using biometrics
  Future<bool> authenticate({
    String reason = 'Authenticate to access your account',
  }) async {
    try {
      emit(const BiometricAuthenticating());

      final isAuthenticated = await _biometricService.authenticate(
        reason: reason,
        useErrorDialogs: true,
      );

      if (isAuthenticated) {
        emit(const BiometricAuthenticated());
        return true;
      } else {
        // User cancelled or denied - show failed message
        emit(const BiometricAuthFailed('Authentication was not completed. Please try again.'));
        return false;
      }
    } catch (e) {
      print('[BiometricCubit] Authentication error: $e');
      final errorMessage = e.toString();
      
      // Check for specific error types
      if (errorMessage.contains('NotAvailable') || 
          errorMessage.contains('NotEnrolled')) {
        emit(const BiometricAuthFailed('Biometric authentication is not set up on this device. Please set up fingerprint or face ID in your device settings.'));
      } else if (errorMessage.contains('LockedOut')) {
        emit(const BiometricAuthFailed('Too many failed attempts. Please try again later.'));
      } else if (errorMessage.contains('Cancelled') || 
                 errorMessage.contains('UserCancel')) {
        emit(const BiometricAuthCancelled());
      } else {
        emit(BiometricAuthFailed('Authentication failed: ${e.toString().replaceAll('Exception: ', '')}'));
      }
      return false;
    }
  }

  /// Enable biometric authentication for user
  Future<void> enableBiometric() async {
    try {
      await _biometricService.enableBiometricAuth(userId);
      await checkBiometricAvailability();
    } catch (e) {
      print('[BiometricCubit] Error enabling biometric: $e');
    }
  }

  /// Disable biometric authentication for user
  Future<void> disableBiometric() async {
    try {
      await _biometricService.disableBiometricAuth(userId);
      await checkBiometricAvailability();
    } catch (e) {
      print('[BiometricCubit] Error disabling biometric: $e');
    }
  }

  /// Reset to initial state
  void reset() {
    emit(const BiometricInitial());
  }
}

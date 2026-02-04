import 'package:local_auth/local_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Service for handling biometric authentication
class BiometricService {
  static final BiometricService _instance = BiometricService._internal();

  factory BiometricService() {
    return _instance;
  }

  BiometricService._internal();

  /// Get the singleton instance
  static BiometricService get instance => _instance;

  final LocalAuthentication _localAuth = LocalAuthentication();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  /// Check if device supports biometric authentication
  Future<bool> canUseBiometrics() async {
    try {
      final isDeviceSupported = await _localAuth.canCheckBiometrics;
      return isDeviceSupported;
    } catch (e) {
      print('[BiometricService] Error checking biometrics support: $e');
      return false;
    }
  }

  /// Get available biometric types on device
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      final availableBiometrics = await _localAuth.getAvailableBiometrics();
      return availableBiometrics;
    } catch (e) {
      print('[BiometricService] Error getting available biometrics: $e');
      return [];
    }
  }

  /// Check if device supports face authentication
  Future<bool> canUseFaceAuth() async {
    final biometrics = await getAvailableBiometrics();
    return biometrics.contains(BiometricType.face);
  }

  /// Check if device supports fingerprint authentication
  Future<bool> canUseFingerprint() async {
    final biometrics = await getAvailableBiometrics();
    return biometrics.contains(BiometricType.fingerprint);
  }

  /// Authenticate using biometrics
  Future<bool> authenticate({
    required String reason,
    bool useErrorDialogs = true,
    bool stickyAuth = false,
  }) async {
    try {
      // First check if biometrics are available
      final canAuth = await canUseBiometrics();
      if (!canAuth) {
        print('[BiometricService] Biometrics not available on device');
        return false;
      }

      final availableBiometrics = await getAvailableBiometrics();
      if (availableBiometrics.isEmpty) {
        print('[BiometricService] No biometrics enrolled on device');
        return false;
      }

      final isAuthenticated = await _localAuth.authenticate(
        localizedReason: reason,
        options: AuthenticationOptions(
          stickyAuth: stickyAuth,
          biometricOnly: false, // Allow PIN/pattern as fallback
          useErrorDialogs: useErrorDialogs,
        ),
      );
      print('[BiometricService] Authentication result: $isAuthenticated');
      return isAuthenticated;
    } catch (e) {
      print('[BiometricService] Error during authentication: $e');
      rethrow; // Let the caller handle the exception
    }
  }

  /// Save user preference for biometric authentication
  Future<void> enableBiometricAuth(String userId) async {
    try {
      await _secureStorage.write(
        key: 'biometric_enabled_$userId',
        value: 'true',
      );
    } catch (e) {
      print('[BiometricService] Error enabling biometric auth: $e');
    }
  }

  /// Remove user preference for biometric authentication
  Future<void> disableBiometricAuth(String userId) async {
    try {
      await _secureStorage.delete(
        key: 'biometric_enabled_$userId',
      );
    } catch (e) {
      print('[BiometricService] Error disabling biometric auth: $e');
    }
  }

  /// Check if biometric auth is enabled for user
  Future<bool> isBiometricAuthEnabled(String userId) async {
    try {
      final value = await _secureStorage.read(
        key: 'biometric_enabled_$userId',
      );
      return value == 'true';
    } catch (e) {
      print('[BiometricService] Error checking biometric auth status: $e');
      return false;
    }
  }

  /// Get the type of biometric to use (face or fingerprint)
  Future<String> getPreferredBiometricType(String userId) async {
    try {
      final biometrics = await getAvailableBiometrics();
      if (biometrics.contains(BiometricType.face)) {
        return 'face';
      } else if (biometrics.contains(BiometricType.fingerprint)) {
        return 'fingerprint';
      }
      return 'unknown';
    } catch (e) {
      print('[BiometricService] Error getting preferred biometric type: $e');
      return 'unknown';
    }
  }
}

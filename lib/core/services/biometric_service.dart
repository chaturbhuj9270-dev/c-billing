import 'package:flutter/foundation.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// Service for handling biometric authentication and the global app lock.
class BiometricService {
  static final BiometricService _instance = BiometricService._internal();

  factory BiometricService() {
    return _instance;
  }

  BiometricService._internal();

  // Get the singleton instance
  static BiometricService get instance => _instance;

  final LocalAuthentication _localAuth = LocalAuthentication();

  // Match CredentialsManager options — bare FlutterSecureStorage() fails to
  // persist on many Android devices (EncryptedSharedPreferences required).
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
    mOptions: MacOsOptions(
      accessibility: KeychainAccessibility.unlocked,
      useDataProtectionKeyChain: false,
    ),
    webOptions: WebOptions(
      dbName: 'c_billing_secure',
      publicKey: 'c_billing_biometric',
    ),
  );

  // Check if device can use biometric authentication (hardware + enrollment).
  Future<bool> canUseBiometrics() async {
    try {
      final canCheck = await _localAuth.canCheckBiometrics.timeout(
        const Duration(seconds: 3),
        onTimeout: () => false,
      );
      if (canCheck) return true;

      // Some OEMs report canCheck=false until isDeviceSupported is queried.
      final supported = await _localAuth.isDeviceSupported().timeout(
        const Duration(seconds: 3),
        onTimeout: () => false,
      );
      if (!supported) return false;

      final available = await getAvailableBiometrics();
      return available.isNotEmpty;
    } catch (e) {
      debugPrint('[BiometricService] Error checking biometrics support: $e');
      return false;
    }
  }

  // Get available biometric types on device
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      final availableBiometrics = await _localAuth.getAvailableBiometrics()
          .timeout(const Duration(seconds: 3), onTimeout: () => <BiometricType>[]);
      return availableBiometrics;
    } catch (e) {
      debugPrint('[BiometricService] Error getting available biometrics: $e');
      return [];
    }
  }

  // Check if device supports face authentication
  Future<bool> canUseFaceAuth() async {
    final biometrics = await getAvailableBiometrics();
    return biometrics.contains(BiometricType.face);
  }

  // Check if device supports fingerprint authentication
  Future<bool> canUseFingerprint() async {
    final biometrics = await getAvailableBiometrics();
    return biometrics.contains(BiometricType.fingerprint);
  }

  // Authenticate using biometrics
  Future<bool> authenticate({
    required String reason,
    bool useErrorDialogs = true,
    bool stickyAuth = false,
  }) async {
    try {
      final canAuth = await canUseBiometrics();
      if (!canAuth) {
        debugPrint('[BiometricService] Biometrics not available on device');
        return false;
      }

      final availableBiometrics = await getAvailableBiometrics();
      if (availableBiometrics.isEmpty) {
        debugPrint('[BiometricService] No biometrics enrolled on device');
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
      debugPrint('[BiometricService] Authentication result: $isAuthenticated');
      return isAuthenticated;
    } catch (e) {
      debugPrint('[BiometricService] Error during authentication: $e');
      rethrow;
    }
  }

  // Save user preference for biometric authentication
  Future<void> enableBiometricAuth(String userId) async {
    try {
      await _secureStorage.write(
        key: 'biometric_enabled_$userId',
        value: 'true',
      );
    } catch (e) {
      debugPrint('[BiometricService] Error enabling biometric auth: $e');
    }
  }

  // Remove user preference for biometric authentication
  Future<void> disableBiometricAuth(String userId) async {
    try {
      await _secureStorage.delete(
        key: 'biometric_enabled_$userId',
      );
    } catch (e) {
      debugPrint('[BiometricService] Error disabling biometric auth: $e');
    }
  }

  // Check if biometric auth is enabled for user
  Future<bool> isBiometricAuthEnabled(String userId) async {
    try {
      final value = await _secureStorage.read(
        key: 'biometric_enabled_$userId',
      );
      return value == 'true';
    } catch (e) {
      debugPrint('[BiometricService] Error checking biometric auth status: $e');
      return false;
    }
  }

  // =========== Global App Lock Settings ===========
  static const String _biometricLockEnabledKey = 'biometric_lock_enabled';

  // Enable global biometric app lock (shown on splash screen).
  // Returns false if the preference could not be persisted.
  Future<bool> enableBiometricLock() async {
    try {
      await _secureStorage.write(
        key: _biometricLockEnabledKey,
        value: 'true',
      );
      // Verify write — some devices report success then drop the value.
      final stored = await _secureStorage.read(key: _biometricLockEnabledKey);
      final ok = stored == 'true';
      debugPrint(
        '[BiometricService] Biometric lock enable ${ok ? 'OK' : 'FAILED verify'}',
      );
      return ok;
    } catch (e) {
      debugPrint('[BiometricService] Error enabling biometric lock: $e');
      return false;
    }
  }

  // Disable global biometric app lock.
  Future<bool> disableBiometricLock() async {
    try {
      await _secureStorage.write(
        key: _biometricLockEnabledKey,
        value: 'false',
      );
      final stored = await _secureStorage.read(key: _biometricLockEnabledKey);
      final ok = stored != 'true';
      debugPrint(
        '[BiometricService] Biometric lock disable ${ok ? 'OK' : 'FAILED verify'}',
      );
      return ok;
    } catch (e) {
      debugPrint('[BiometricService] Error disabling biometric lock: $e');
      return false;
    }
  }

  // Check if global biometric lock is enabled.
  // Throws when the setting cannot be read so splash can fail closed.
  Future<bool> isBiometricLockEnabled() async {
    final value = await _secureStorage.read(
      key: _biometricLockEnabledKey,
    );
    return value == 'true';
  }

  /// Enable/disable lock. When enabling, requires a successful biometric
  /// prompt first so we never persist a lock the device cannot unlock.
  Future<bool> setBiometricLockEnabled(bool enabled) async {
    if (enabled) {
      final canUse = await canUseBiometrics();
      if (!canUse) {
        debugPrint('[BiometricService] Cannot enable lock — biometrics unavailable');
        return false;
      }
      final authenticated = await authenticate(
        reason: 'Confirm biometrics to enable app lock',
        stickyAuth: true,
      );
      if (!authenticated) {
        debugPrint('[BiometricService] Enable cancelled — auth failed');
        return false;
      }
      return enableBiometricLock();
    }
    return disableBiometricLock();
  }

  // Get the type of biometric to use (face or fingerprint)
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
      debugPrint('[BiometricService] Error getting preferred biometric type: $e');
      return 'unknown';
    }
  }
}

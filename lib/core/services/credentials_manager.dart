import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Stores remembered login credentials in platform secure storage.
///
/// Android uses encrypted storage, Apple platforms use the Keychain, desktop
/// uses the OS secret store, and web uses encrypted browser storage.
/// SharedPreferences is only read once to move any older saved password out
/// of plain storage, then those keys are deleted.
class CredentialsManager {
  static final CredentialsManager _instance = CredentialsManager._internal();

  factory CredentialsManager() => _instance;

  CredentialsManager._internal();

  static const FlutterSecureStorage _storage = FlutterSecureStorage(
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
      publicKey: 'c_billing_credentials',
    ),
  );

  static const String _emailKey = 'secure_user_email';
  static const String _passwordKey = 'secure_user_password';
  static const String _userIdKey = 'secure_user_id';
  static const String _rememberKey = 'secure_remember_me';
  static const String _timestampKey = 'secure_login_timestamp';

  static const List<String> _legacyKeys = [
    'user_email',
    'user_password',
    'user_id',
    'is_logged_in',
    'login_timestamp',
  ];

  bool _initialized = false;

  /// Prepare storage and move any legacy plain-text credentials across.
  Future<void> init() async {
    if (_initialized) return;
    await _migrateLegacyPreferences();
    _initialized = true;
    debugPrint('[DEBUG] CredentialsManager initialized');
  }

  /// Save credentials after the user signs in with Remember me checked.
  ///
  /// Web keeps the email and the remember flag only. The password is not
  /// stored there because the web encryption key ships inside the app.
  /// Firebase Auth persistence keeps that session instead.
  Future<void> saveCredentials({
    required String email,
    required String password,
    required String userId,
  }) async {
    if (kIsWeb) {
      await _writeRememberedSession(email: email, userId: userId);
      await _storage.delete(key: _passwordKey);
      debugPrint('[DEBUG] Remembered web session saved without a password');
      return;
    }
    await _writeCredentials(email: email, password: password, userId: userId);
    debugPrint('[DEBUG] Remembered login saved in secure storage');
  }

  /// Replace the stored password after a successful password change.
  Future<void> updateStoredPassword(String password) async {
    if (!await isRemembered()) return;
    if (kIsWeb) {
      await _storage.delete(key: _passwordKey);
      return;
    }
    await _storage.write(key: _passwordKey, value: password);
    await _storage.write(
      key: _timestampKey,
      value: DateTime.now().millisecondsSinceEpoch.toString(),
    );
    debugPrint('[DEBUG] Remembered password updated in secure storage');
  }

  Future<String?> getEmail() => _storage.read(key: _emailKey);

  /// True when the user chose Remember me and credentials are still stored.
  Future<bool> isRemembered() async {
    try {
      return await _storage.read(key: _rememberKey) == 'true';
    } catch (e) {
      debugPrint('[ERROR] Could not read remembered login: $e');
      return false;
    }
  }

  /// Credentials for automatic sign-in. Null when Remember me is off.
  ///
  /// Web never returns a password. The splash screen uses the Firebase
  /// session that Remember me already persisted.
  Future<Map<String, String>?> getStoredCredentials() async {
    try {
      if (kIsWeb) return null;
      if (!await isRemembered()) return null;
      final email = await _storage.read(key: _emailKey);
      final password = await _storage.read(key: _passwordKey);
      if (email == null ||
          password == null ||
          email.isEmpty ||
          password.isEmpty) {
        return null;
      }
      final userId = await _storage.read(key: _userIdKey) ?? '';
      return {'email': email, 'password': password, 'userId': userId};
    } catch (e) {
      debugPrint('[ERROR] Could not read stored credentials: $e');
      return null;
    }
  }

  /// Remove remembered credentials. Used on logout and when Remember me is off.
  Future<void> clearCredentials() async {
    try {
      await _storage.delete(key: _emailKey);
      await _storage.delete(key: _passwordKey);
      await _storage.delete(key: _userIdKey);
      await _storage.delete(key: _rememberKey);
      await _storage.delete(key: _timestampKey);
      debugPrint('[DEBUG] Remembered login cleared');
    } catch (e) {
      debugPrint('[ERROR] Failed to clear remembered login: $e');
      rethrow;
    }
  }

  Future<void> _writeRememberedSession({
    required String email,
    required String userId,
  }) async {
    await _storage.write(key: _emailKey, value: email);
    await _storage.write(key: _userIdKey, value: userId);
    await _storage.write(key: _rememberKey, value: 'true');
    await _storage.write(
      key: _timestampKey,
      value: DateTime.now().millisecondsSinceEpoch.toString(),
    );
  }

  Future<void> _writeCredentials({
    required String email,
    required String password,
    required String userId,
  }) async {
    await _storage.write(key: _emailKey, value: email);
    await _storage.write(key: _passwordKey, value: password);
    await _storage.write(key: _userIdKey, value: userId);
    await _storage.write(key: _rememberKey, value: 'true');
    await _storage.write(
      key: _timestampKey,
      value: DateTime.now().millisecondsSinceEpoch.toString(),
    );
  }

  /// One-time move from SharedPreferences, then delete the plain-text copies.
  Future<void> _migrateLegacyPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final hasLegacy = _legacyKeys.any(prefs.containsKey);
      if (!hasLegacy) return;

      final alreadyRemembered = await _storage.read(key: _rememberKey) == 'true';
      if (!alreadyRemembered && (prefs.getBool('is_logged_in') ?? false)) {
        final email = prefs.getString('user_email');
        final password = prefs.getString('user_password');
        if (email != null &&
            password != null &&
            email.isNotEmpty &&
            password.isNotEmpty) {
          await _writeCredentials(
            email: email,
            password: password,
            userId: prefs.getString('user_id') ?? '',
          );
          debugPrint('[DEBUG] Moved legacy login into secure storage');
        }
      }

      for (final key in _legacyKeys) {
        await prefs.remove(key);
      }

      // Drop any password previously saved in web storage.
      if (kIsWeb) {
        await _storage.delete(key: _passwordKey);
      }
    } catch (e) {
      debugPrint('[ERROR] Legacy credential migration failed: $e');
    }
  }
}

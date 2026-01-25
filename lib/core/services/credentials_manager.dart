import 'package:shared_preferences/shared_preferences.dart';

class CredentialsManager {
  static final CredentialsManager _instance = CredentialsManager._internal();

  factory CredentialsManager() {
    return _instance;
  }

  CredentialsManager._internal();

  late SharedPreferences _prefs;
  bool _initialized = false;

  // Preference keys
  static const String _emailKey = 'user_email';
  static const String _passwordKey = 'user_password';
  static const String _userIdKey = 'user_id';
  static const String _isLoggedInKey = 'is_logged_in';
  static const String _loginTimestampKey = 'login_timestamp';

  /// Initialize SharedPreferences
  Future<void> init() async {
    if (!_initialized) {
      _prefs = await SharedPreferences.getInstance();
      _initialized = true;
      print('[DEBUG] CredentialsManager initialized');
    }
  }

  /// Save credentials after successful login
  Future<void> saveCredentials({
    required String email,
    required String password,
    required String userId,
  }) async {
    try {
      await _prefs.setString(_emailKey, email);
      await _prefs.setString(_passwordKey, password);
      await _prefs.setString(_userIdKey, userId);
      await _prefs.setBool(_isLoggedInKey, true);
      await _prefs.setInt(_loginTimestampKey, DateTime.now().millisecondsSinceEpoch);
      print('[DEBUG] Credentials saved for email: $email');
    } catch (e) {
      print('[ERROR] Failed to save credentials: $e');
      rethrow;
    }
  }

  /// Get saved email
  String? getEmail() {
    final email = _prefs.getString(_emailKey);
    print('[DEBUG] Retrieved email from preferences: ${email != null ? "***" : "null"}');
    return email;
  }

  /// Get saved password
  String? getPassword() {
    final password = _prefs.getString(_passwordKey);
    print('[DEBUG] Retrieved password from preferences: ${password != null ? "***" : "null"}');
    return password;
  }

  /// Get saved user ID
  String? getUserId() {
    final userId = _prefs.getString(_userIdKey);
    print('[DEBUG] Retrieved userId: $userId');
    return userId;
  }

  /// Check if user is logged in (stored credentials exist)
  bool isLoggedIn() {
    final loggedIn = _prefs.getBool(_isLoggedInKey) ?? false;
    print('[DEBUG] isLoggedIn check: $loggedIn');
    return loggedIn;
  }

  /// Get login timestamp
  int? getLoginTimestamp() {
    return _prefs.getInt(_loginTimestampKey);
  }

  /// Clear all credentials (logout)
  Future<void> clearCredentials() async {
    try {
      await _prefs.remove(_emailKey);
      await _prefs.remove(_passwordKey);
      await _prefs.remove(_userIdKey);
      await _prefs.remove(_isLoggedInKey);
      await _prefs.remove(_loginTimestampKey);
      print('[DEBUG] Credentials cleared (user logged out)');
    } catch (e) {
      print('[ERROR] Failed to clear credentials: $e');
      rethrow;
    }
  }

  /// Get all stored credentials (for auto-login)
  Map<String, dynamic>? getStoredCredentials() {
    if (!isLoggedIn()) {
      print('[DEBUG] No stored credentials available');
      return null;
    }

    final email = getEmail();
    final password = getPassword();
    final userId = getUserId();

    if (email == null || password == null) {
      print('[ERROR] Stored credentials incomplete');
      return null;
    }

    print('[DEBUG] Retrieved stored credentials for auto-login');
    return {
      'email': email,
      'password': password,
      'userId': userId,
      'timestamp': getLoginTimestamp(),
    };
  }

  /// Validate if stored credentials are still valid
  /// Returns true if credentials exist and session is within 2-hour window
  bool areStoredCredentialsValid() {
    if (!isLoggedIn()) {
      print('[DEBUG] No stored credentials to validate');
      return false;
    }

    final timestamp = getLoginTimestamp();
    if (timestamp == null) {
      print('[DEBUG] No login timestamp found');
      return false;
    }

    // Check if session expired (2 hours = 7200000 milliseconds)
    final now = DateTime.now().millisecondsSinceEpoch;
    const sessionDuration = 2 * 60 * 60 * 1000; // 2 hours in milliseconds

    final isValid = (now - timestamp) < sessionDuration;
    print('[DEBUG] Stored credentials valid: $isValid (age: ${(now - timestamp) / 1000 / 60} minutes)');
    return isValid;
  }
}

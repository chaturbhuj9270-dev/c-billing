import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageService extends ChangeNotifier {
  static const String _languageKey = 'selected_language';
  static LanguageService? _instance;
  
  String _currentLanguage = 'English';
  
  LanguageService._();
  
  static LanguageService get instance {
    _instance ??= LanguageService._();
    return _instance!;
  }
  
  String get currentLanguage => _currentLanguage;
  
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _currentLanguage = prefs.getString(_languageKey) ?? 'English';
  }
  
  Future<void> setLanguage(String language) async {
    _currentLanguage = language;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageKey, language);
    notifyListeners(); // Notify all listeners about the language change
  }
}

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

class AppLanguage {
  final String code;
  final String name;
  final String nativeName;
  final String flag;

  const AppLanguage({
    required this.code,
    required this.name,
    required this.nativeName,
    required this.flag,
  });
}

class LanguageProvider extends ChangeNotifier {
  static const String _boxName = 'app_settings';
  static const String _languageKey = 'selected_language';
  static const String _languageSetKey = 'language_set';

  late Box _box;

  String _languageCode = 'hi';
  bool _isInitialized = false;

  String get languageCode => _languageCode;
  bool get isInitialized => _isInitialized;
  bool get isLanguageSet => _box.get(_languageSetKey, defaultValue: false) as bool;

  static const List<AppLanguage> supportedLanguages = [
    AppLanguage(code: 'hi', name: 'Hindi', nativeName: 'हिंदी', flag: '🇮🇳'),
    AppLanguage(code: 'en', name: 'English', nativeName: 'English', flag: '🇬🇧'),
    AppLanguage(code: 'pa', name: 'Punjabi', nativeName: 'ਪੰਜਾਬੀ', flag: '🌾'),
    AppLanguage(code: 'mr', name: 'Marathi', nativeName: 'मराठी', flag: '🌻'),
    AppLanguage(code: 'gu', name: 'Gujarati', nativeName: 'ગુજરાતી', flag: '🌿'),
    AppLanguage(code: 'bn', name: 'Bengali', nativeName: 'বাংলা', flag: '🌸'),
    AppLanguage(code: 'te', name: 'Telugu', nativeName: 'తెలుగు', flag: '🌴'),
    AppLanguage(code: 'ta', name: 'Tamil', nativeName: 'தமிழ்', flag: '🏵️'),
    AppLanguage(code: 'kn', name: 'Kannada', nativeName: 'ಕನ್ನಡ', flag: '🌺'),
    AppLanguage(code: 'ml', name: 'Malayalam', nativeName: 'മലയാളം', flag: '🌴'),
    AppLanguage(code: 'or', name: 'Odia', nativeName: 'ଓଡ଼ିଆ', flag: '🪷'),
    AppLanguage(code: 'ur', name: 'Urdu', nativeName: 'اردو', flag: '🌙'),
  ];

  Future<void> init() async {
    _box = await Hive.openBox(_boxName);
    _languageCode = _box.get(_languageKey, defaultValue: 'hi') as String;
    _isInitialized = true;
    notifyListeners();
  }

  Future<void> setLanguage(String code) async {
    _languageCode = code;
    await _box.put(_languageKey, code);
    await _box.put(_languageSetKey, true);
    notifyListeners();
  }

  AppLanguage get currentLanguage {
    return supportedLanguages.firstWhere(
      (l) => l.code == _languageCode,
      orElse: () => supportedLanguages.first,
    );
  }
}

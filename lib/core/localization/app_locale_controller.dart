import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppLocaleController extends ChangeNotifier {
  static const String _localeKey = 'app_locale';

  Locale _locale = const Locale('en');

  Locale get locale => _locale;

  Future<void> loadLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final languageCode = prefs.getString(_localeKey) ?? 'en';

    _locale = Locale(languageCode);
    notifyListeners();
  }

  Future<void> changeLocale(String languageCode) async {
    if (languageCode != 'en' && languageCode != 'ar') return;

    if (_locale.languageCode == languageCode) return;

    _locale = Locale(languageCode);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_localeKey, languageCode);

    notifyListeners();
  }
}
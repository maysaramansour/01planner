import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleService {
  LocaleService._internal();
  static final LocaleService _instance = LocaleService._internal();
  factory LocaleService() => _instance;

  static const _prefKey = 'locale';
  static const _defaultLocale = Locale('ar');

  final ValueNotifier<Locale> notifier = ValueNotifier<Locale>(_defaultLocale);

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_prefKey);
    if (code == 'en' || code == 'ar') {
      notifier.value = Locale(code!);
    }
  }

  Future<void> setLocale(Locale locale) async {
    if (locale.languageCode != 'en' && locale.languageCode != 'ar') return;
    notifier.value = locale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, locale.languageCode);
  }
}

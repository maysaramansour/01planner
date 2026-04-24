import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AIConfig {
  AIConfig._internal();
  static final AIConfig _instance = AIConfig._internal();
  factory AIConfig() => _instance;

  static const _kBaseUrl = 'ai.baseUrl';
  static const _kModel = 'ai.model';
  static const _kEnabled = 'ai.enabled';

  static const defaultBaseUrl = '';
  static const defaultModel = 'qwen/qwen2.5-vl-7b';

  final ValueNotifier<String> baseUrl = ValueNotifier<String>(defaultBaseUrl);
  final ValueNotifier<String> model = ValueNotifier<String>(defaultModel);
  final ValueNotifier<bool> enabled = ValueNotifier<bool>(false);

  Listenable get listenable => Listenable.merge([baseUrl, model, enabled]);

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    baseUrl.value = prefs.getString(_kBaseUrl) ?? defaultBaseUrl;
    model.value = prefs.getString(_kModel) ?? defaultModel;
    enabled.value = prefs.getBool(_kEnabled) ?? false;
  }

  Future<void> setBaseUrl(String value) async {
    final trimmed = value.trim();
    baseUrl.value = trimmed.isEmpty ? defaultBaseUrl : trimmed;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kBaseUrl, baseUrl.value);
  }

  Future<void> setModel(String value) async {
    final trimmed = value.trim();
    model.value = trimmed.isEmpty ? defaultModel : trimmed;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kModel, model.value);
  }

  Future<void> setEnabled(bool value) async {
    enabled.value = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kEnabled, value);
  }
}

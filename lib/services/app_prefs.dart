import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// App-wide user preferences (theme color, first day of week, default task
/// alerts, layout mode). Backed by SharedPreferences, exposed as
/// ValueNotifiers so widgets can rebuild reactively.
class AppPrefs {
  AppPrefs._internal();
  static final AppPrefs _instance = AppPrefs._internal();
  factory AppPrefs() => _instance;

  static const _kPrimaryColor = 'prefs.primaryColor';
  static const _kFirstDayOfWeek = 'prefs.firstDayOfWeek';
  static const _kDefaultAlerts = 'prefs.defaultAlerts';
  static const _kLayoutMode = 'prefs.layoutMode';
  static const _kGoalPulses = 'prefs.goalPulses';
  static const _kWeekendDays = 'prefs.weekendDays';
  static const _kWorkStartHour = 'prefs.workStartHour';
  static const _kWorkEndHour = 'prefs.workEndHour';

  // Coral default matches AppPalette.primary.
  static const int defaultPrimaryColor = 0xFFE89F94;
  static const int defaultFirstDayOfWeek = 7; // Saturday
  static const List<int> defaultAlertMinutes = [0, 15];
  static const String defaultLayoutMode = 'full';

  /// Available primary-color palette (ARGB int).
  static const List<int> palette = [
    0xFFE89F94, // coral (default)
    0xFFE8A860, // orange
    0xFFE8C547, // yellow
    0xFF7BB274, // green
    0xFF6BA4D6, // blue
    0xFF4FA7A4, // teal
    0xFFCF6679, // red
  ];

  final ValueNotifier<int> primaryColor = ValueNotifier<int>(defaultPrimaryColor);
  final ValueNotifier<int> firstDayOfWeek = ValueNotifier<int>(defaultFirstDayOfWeek);
  final ValueNotifier<List<int>> defaultAlerts = ValueNotifier<List<int>>(defaultAlertMinutes);
  final ValueNotifier<String> layoutMode = ValueNotifier<String>(defaultLayoutMode);
  final ValueNotifier<bool> goalPulsesEnabled = ValueNotifier<bool>(true);

  // Default Friday + Saturday weekend (Arabic-world defaults). 6 = Sat, 7 = Sun.
  // Per ISO: 1 = Mon, 7 = Sun.
  static const List<int> defaultWeekendDays = [5, 6];
  final ValueNotifier<List<int>> weekendDays =
      ValueNotifier<List<int>>(defaultWeekendDays);

  static const int defaultWorkStartHour = 9;
  static const int defaultWorkEndHour = 17;
  final ValueNotifier<int> workStartHour = ValueNotifier<int>(defaultWorkStartHour);
  final ValueNotifier<int> workEndHour = ValueNotifier<int>(defaultWorkEndHour);

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    primaryColor.value = prefs.getInt(_kPrimaryColor) ?? defaultPrimaryColor;
    firstDayOfWeek.value =
        prefs.getInt(_kFirstDayOfWeek) ?? defaultFirstDayOfWeek;
    final alertsRaw = prefs.getString(_kDefaultAlerts);
    if (alertsRaw != null) {
      try {
        final parsed = jsonDecode(alertsRaw);
        if (parsed is List) {
          defaultAlerts.value = [
            for (final v in parsed)
              if (v is int) v
          ];
        }
      } catch (_) {}
    }
    layoutMode.value = prefs.getString(_kLayoutMode) ?? defaultLayoutMode;
    goalPulsesEnabled.value = prefs.getBool(_kGoalPulses) ?? true;

    final weekendRaw = prefs.getString(_kWeekendDays);
    if (weekendRaw != null) {
      try {
        final parsed = jsonDecode(weekendRaw);
        if (parsed is List) {
          weekendDays.value = [
            for (final v in parsed)
              if (v is int && v >= 1 && v <= 7) v
          ];
        }
      } catch (_) {}
    }
    final ws = prefs.getInt(_kWorkStartHour);
    if (ws != null && ws >= 0 && ws <= 23) workStartHour.value = ws;
    final we = prefs.getInt(_kWorkEndHour);
    if (we != null && we >= 1 && we <= 24) workEndHour.value = we;
  }

  Future<void> setWeekendDays(List<int> days) async {
    final cleaned = days.where((d) => d >= 1 && d <= 7).toSet().toList()..sort();
    weekendDays.value = cleaned;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kWeekendDays, jsonEncode(cleaned));
  }

  Future<void> setWorkHours({required int startHour, required int endHour}) async {
    if (startHour < 0 || startHour > 22 || endHour <= startHour || endHour > 24) return;
    workStartHour.value = startHour;
    workEndHour.value = endHour;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kWorkStartHour, startHour);
    await prefs.setInt(_kWorkEndHour, endHour);
  }

  Future<void> setGoalPulsesEnabled(bool value) async {
    goalPulsesEnabled.value = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kGoalPulses, value);
  }

  Future<void> setPrimaryColor(int value) async {
    primaryColor.value = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kPrimaryColor, value);
  }

  Future<void> setFirstDayOfWeek(int value) async {
    if (value < 1 || value > 7) return;
    firstDayOfWeek.value = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kFirstDayOfWeek, value);
  }

  Future<void> setDefaultAlerts(List<int> minutes) async {
    final cleaned = minutes.where((m) => m >= 0 && m <= 10080).toSet().toList()
      ..sort();
    defaultAlerts.value = cleaned;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kDefaultAlerts, jsonEncode(cleaned));
  }

  Future<void> setLayoutMode(String mode) async {
    if (!const ['full', 'simplified', 'minimal'].contains(mode)) return;
    layoutMode.value = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kLayoutMode, mode);
  }

  /// Reset to defaults (used by Reset App in Advanced).
  Future<void> resetAll() async {
    primaryColor.value = defaultPrimaryColor;
    firstDayOfWeek.value = defaultFirstDayOfWeek;
    defaultAlerts.value = defaultAlertMinutes;
    layoutMode.value = defaultLayoutMode;
    goalPulsesEnabled.value = true;
    weekendDays.value = defaultWeekendDays;
    workStartHour.value = defaultWorkStartHour;
    workEndHour.value = defaultWorkEndHour;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kPrimaryColor);
    await prefs.remove(_kFirstDayOfWeek);
    await prefs.remove(_kDefaultAlerts);
    await prefs.remove(_kLayoutMode);
    await prefs.remove(_kGoalPulses);
    await prefs.remove(_kWeekendDays);
    await prefs.remove(_kWorkStartHour);
    await prefs.remove(_kWorkEndHour);
  }
}

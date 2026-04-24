import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'ai_service.dart';

/// Persists the "Convert chat to plan" extraction across app restarts so the
/// user can background the app while the local LLM is still thinking.
///
/// States:
/// - idle      : nothing going on
/// - generating: extraction running (start time recorded for staleness check)
/// - ready     : extraction finished; waiting for user to review + commit
class PendingPlanService {
  PendingPlanService._internal();
  static final PendingPlanService _instance = PendingPlanService._internal();
  factory PendingPlanService() => _instance;

  static const _kState = 'pending_plan.state';
  static const _kStartedAt = 'pending_plan.startedAt';
  static const _kResult = 'pending_plan.result'; // JSON of action.data + kind
  static const _kSessionId = 'pending_plan.sessionId';

  /// Reactive status so UI can listen (spinner on "Convert" button, auto-open
  /// review sheet when result becomes ready).
  final ValueNotifier<String> state = ValueNotifier<String>('idle');

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final s = prefs.getString(_kState) ?? 'idle';
    // If a "generating" state survived a process kill and is older than 15 min,
    // consider it orphaned and reset.
    if (s == 'generating') {
      final started = prefs.getInt(_kStartedAt) ?? 0;
      final ageMin =
          DateTime.now().millisecondsSinceEpoch - started;
      if (ageMin > 15 * 60 * 1000) {
        await clear();
        return;
      }
    }
    state.value = s;
  }

  Future<void> markGenerating({String? sessionId}) async {
    state.value = 'generating';
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kState, 'generating');
    await prefs.setInt(_kStartedAt, DateTime.now().millisecondsSinceEpoch);
    if (sessionId != null) await prefs.setString(_kSessionId, sessionId);
    await prefs.remove(_kResult);
  }

  Future<void> saveResult(AIAction action) async {
    final encoded = jsonEncode({
      'kind': _kindToString(action.kind),
      'data': action.data,
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kState, 'ready');
    await prefs.setString(_kResult, encoded);
    state.value = 'ready';
  }

  Future<AIAction?> readResult() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kResult);
    if (raw == null) return null;
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final kind = _kindFromString(decoded['kind'] as String?);
      final data = decoded['data'];
      if (kind == null || data is! Map<String, dynamic>) return null;
      return AIAction(kind, data);
    } catch (_) {
      return null;
    }
  }

  Future<String?> readSessionId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kSessionId);
  }

  Future<void> clear() async {
    state.value = 'idle';
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kState);
    await prefs.remove(_kStartedAt);
    await prefs.remove(_kResult);
    await prefs.remove(_kSessionId);
  }

  String _kindToString(AIActionKind k) => k.name;
  AIActionKind? _kindFromString(String? s) {
    if (s == null) return null;
    for (final k in AIActionKind.values) {
      if (k.name == s) return k;
    }
    return null;
  }
}

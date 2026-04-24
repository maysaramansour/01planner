import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../models/ai_message.dart';
import '../models/chat_session.dart';
import 'ai_service.dart';
import 'storage_service.dart';

class AIChatService {
  AIChatService._internal();
  static final AIChatService _instance = AIChatService._internal();
  factory AIChatService() => _instance;

  static const _kActiveSession = 'ai.activeSession';

  Box<AIMessage> get _messages => StorageService().aiMessages;
  Box<ChatSession> get _sessions => StorageService().chatSessions;

  final ValueNotifier<String?> activeSessionId = ValueNotifier<String?>(null);

  ValueListenable<Box<AIMessage>> messagesListenable() =>
      _messages.listenable();
  ValueListenable<Box<ChatSession>> sessionsListenable() =>
      _sessions.listenable();

  Future<void> init() async {
    // Ensure at least one session exists, then backfill sessionId on any
    // orphan messages (from pre-sessions builds).
    final prefs = await SharedPreferences.getInstance();
    String? id = prefs.getString(_kActiveSession);
    if (_sessions.isEmpty) {
      final session = await _create('New chat');
      id = session.id;
    }
    if (id == null || _sessions.get(id) == null) {
      id = sessions().first.id;
    }
    activeSessionId.value = id;

    // Migrate orphan messages into the active session.
    final orphan = _messages.values.where((m) => m.sessionId == null).toList();
    for (final m in orphan) {
      m.sessionId = id;
      await m.save();
    }

    await prefs.setString(_kActiveSession, id);
  }

  List<ChatSession> sessions() {
    final list = _sessions.values.toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return list;
  }

  ChatSession? active() {
    final id = activeSessionId.value;
    if (id == null) return null;
    return _sessions.get(id);
  }

  List<AIMessage> messagesForActive() {
    final id = activeSessionId.value;
    if (id == null) return [];
    final list = _messages.values.where((m) => m.sessionId == id).toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return list;
  }

  List<ConversationTurn> asHistory() => messagesForActive()
      .map((m) => m.role == 'user'
          ? ConversationTurn.user(m.text)
          : m.role == 'system'
              ? ConversationTurn.system(m.text)
              : ConversationTurn.assistant(m.text))
      .toList();

  Future<ChatSession> _create(String title) async {
    final now = DateTime.now();
    final s = ChatSession(
      id: const Uuid().v4(),
      title: title,
      createdAt: now,
      updatedAt: now,
    );
    await _sessions.put(s.id, s);
    return s;
  }

  Future<ChatSession> newSession([String title = 'New chat']) async {
    final s = await _create(title);
    await setActive(s.id);
    return s;
  }

  Future<void> setActive(String id) async {
    activeSessionId.value = id;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kActiveSession, id);
  }

  Future<void> renameSession(String id, String newTitle) async {
    final s = _sessions.get(id);
    if (s == null) return;
    s.title = newTitle.trim().isEmpty ? s.title : newTitle.trim();
    s.updatedAt = DateTime.now();
    await s.save();
  }

  Future<void> deleteSession(String id) async {
    // Remove all messages in this session.
    final toDelete = _messages.values
        .where((m) => m.sessionId == id)
        .map((m) => m.id)
        .toList();
    for (final mid in toDelete) {
      await _messages.delete(mid);
    }
    await _sessions.delete(id);
    // Ensure an active session remains.
    if (activeSessionId.value == id) {
      if (_sessions.isEmpty) {
        final s = await _create('New chat');
        await setActive(s.id);
      } else {
        await setActive(sessions().first.id);
      }
    }
  }

  Future<AIMessage> add(String role, String text) async {
    final sessionId = activeSessionId.value;
    if (sessionId == null) throw StateError('No active session');
    final msg = AIMessage(
      id: const Uuid().v4(),
      role: role,
      text: text,
      createdAt: DateTime.now(),
      sessionId: sessionId,
    );
    await _messages.put(msg.id, msg);
    // Bump session updatedAt and auto-title from first user message.
    final session = _sessions.get(sessionId);
    if (session != null) {
      session.updatedAt = DateTime.now();
      if (role == 'user' &&
          (session.title == 'New chat' || session.title.isEmpty)) {
        final snippet = text.trim();
        session.title =
            snippet.length > 40 ? '${snippet.substring(0, 40)}…' : snippet;
      }
      await session.save();
    }
    return msg;
  }

  Future<void> clearActive() async {
    final id = activeSessionId.value;
    if (id == null) return;
    final toDelete = _messages.values
        .where((m) => m.sessionId == id)
        .map((m) => m.id)
        .toList();
    for (final mid in toDelete) {
      await _messages.delete(mid);
    }
  }
}

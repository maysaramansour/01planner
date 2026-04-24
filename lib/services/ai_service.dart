import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show TimeOfDay;
import 'package:http/http.dart' as http;

import '../models/event.dart';
import '../models/task.dart';
import 'ai_config.dart';
import 'app_prefs.dart';
import 'event_service.dart';
import 'task_service.dart';

const List<String> kIconKeys = [
  'work',
  'gym',
  'call',
  'home',
  'shop',
  'study',
  'food',
  'travel',
  'health',
  'meet',
  'read',
  'idea',
];

const List<int> kPaletteColors = [
  0xFFE89F94,
  0xFFE8B89A,
  0xFF8FB996,
  0xFFCF6679,
  0xFFE6B655,
  0xFFB58FC0,
  0xFF6FA8D3,
  0xFFE08A6C,
  0xFF5EA79A,
  0xFFD37A9E,
  0xFF9FB3C8,
  0xFFAF8E5A,
];

class ParsedTask {
  final String title;
  final DateTime? scheduledStart;
  final int? durationMinutes;
  final String? iconKey;
  final int? colorValue;
  final List<String> subtasks;
  final String? notes;

  ParsedTask({
    required this.title,
    this.scheduledStart,
    this.durationMinutes,
    this.iconKey,
    this.colorValue,
    this.subtasks = const [],
    this.notes,
  });

  factory ParsedTask.fromJson(Map<String, dynamic> json) {
    DateTime? start;
    final rawStart = json['scheduledStart'];
    if (rawStart is String && rawStart.isNotEmpty) {
      start = DateTime.tryParse(rawStart);
    }
    final duration = json['durationMinutes'];
    final iconKey = json['iconKey'] is String ? json['iconKey'] as String : null;
    final colorValue =
        json['colorValue'] is int ? json['colorValue'] as int : null;
    final subtasksRaw = json['subtasks'];
    final subtasks = <String>[];
    if (subtasksRaw is List) {
      for (final s in subtasksRaw) {
        if (s is String && s.trim().isNotEmpty) subtasks.add(s);
      }
    }
    return ParsedTask(
      title: (json['title'] as String?)?.trim() ?? '',
      scheduledStart: start,
      durationMinutes: duration is int ? duration : null,
      iconKey: kIconKeys.contains(iconKey) ? iconKey : null,
      colorValue: colorValue,
      subtasks: subtasks,
      notes: json['notes'] is String ? json['notes'] as String : null,
    );
  }
}

class ScheduleChange {
  final String taskId;
  final DateTime scheduledStart;
  final int durationMinutes;
  final String? reason;

  ScheduleChange({
    required this.taskId,
    required this.scheduledStart,
    required this.durationMinutes,
    this.reason,
  });

  static ScheduleChange? tryFromJson(Map<String, dynamic> json) {
    final taskId = json['taskId'];
    final startRaw = json['scheduledStart'];
    final duration = json['durationMinutes'];
    if (taskId is! String) return null;
    if (startRaw is! String) return null;
    final start = DateTime.tryParse(startRaw);
    if (start == null) return null;
    final dur = duration is int ? duration : 30;
    return ScheduleChange(
      taskId: taskId,
      scheduledStart: start,
      durationMinutes: dur,
      reason: json['reason'] is String ? json['reason'] as String : null,
    );
  }
}

/// Conversation action — what the AI wants the app to do after speaking.
enum AIActionKind {
  none,
  done,
  createTask,
  updateTask,
  deleteTask,
  toggleTask,
  createEvent,
  updateEvent,
  deleteEvent,
  createHabit,
  updateHabit,
  deleteHabit,
  toggleHabit,
  createGoal,
  updateGoal,
  deleteGoal,
  archiveGoal,
  plan,
  notFound,
}

class AIAction {
  final AIActionKind kind;
  final Map<String, dynamic> data;
  const AIAction(this.kind, [this.data = const {}]);

  static const none = AIAction(AIActionKind.none);
}

/// A quick-reply option the assistant offers (chip button).
/// `picker` is one of: null (plain text send), 'date', 'time', 'duration'.
class AIQuickOption {
  final String label;
  final String? picker;
  const AIQuickOption(this.label, {this.picker});
}

/// One turn in the conversation.
class ConversationTurn {
  final String role; // 'user' | 'assistant' | 'system'
  final String text;
  final AIAction action;
  final List<AIQuickOption> options;
  final bool multiselect;

  ConversationTurn.user(this.text)
      : role = 'user',
        action = AIAction.none,
        options = const [],
        multiselect = false;
  ConversationTurn.assistant(
    this.text, {
    this.action = AIAction.none,
    this.options = const [],
    this.multiselect = false,
  }) : role = 'assistant';
  ConversationTurn.system(this.text)
      : role = 'system',
        action = AIAction.none,
        options = const [],
        multiselect = false;
}

class AIService {
  AIService._internal();
  static final AIService _instance = AIService._internal();
  factory AIService() => _instance;

  // Local LLMs (especially large plan extractions on CPU) can take minutes.
  static const _timeout = Duration(minutes: 8);

  Uri? _endpoint() {
    var base = AIConfig().baseUrl.value.trim().replaceAll(RegExp(r'/+$'), '');
    if (base.isEmpty) return null;
    // If the user typed just host:port (no /v1 or other version path), assume
    // OpenAI-compatible layout and append /v1. Preserves paths like /v1, /v2,
    // or /openai/v1.
    final uri = Uri.tryParse(base);
    final hasVersion =
        uri != null && RegExp(r'/v\d+').hasMatch(uri.path);
    if (!hasVersion) base = '$base/v1';
    return Uri.parse('$base/chat/completions');
  }

  Future<Map<String, dynamic>?> _chat({
    required List<Map<String, String>> messages,
    bool jsonMode = true,
    double temperature = 0.3,
    int maxTokens = 4096,
  }) async {
    // Note: we don't use LM Studio's `response_format: json_object` because its
    // GBNF grammar has issues with Unicode (notably Arabic) and aborts mid-
    // generation. Instead we prompt for JSON and parse tolerantly.
    final body = jsonEncode({
      'model': AIConfig().model.value,
      'messages': messages,
      'temperature': temperature,
      'max_tokens': maxTokens,
    });

    final endpoint = _endpoint();
    if (endpoint == null) {
      debugPrint('AI chat skipped: base URL not configured');
      return null;
    }
    try {
      final resp = await http
          .post(
            endpoint,
            headers: {'Content-Type': 'application/json'},
            body: body,
          )
          .timeout(_timeout);
      if (resp.statusCode != 200) {
        debugPrint('AI chat non-200: ${resp.statusCode} ${resp.body}');
        return null;
      }
      final decoded = jsonDecode(resp.body) as Map<String, dynamic>;
      final choices = decoded['choices'];
      if (choices is! List || choices.isEmpty) return null;
      final message = (choices.first as Map)['message'];
      final content = message is Map ? message['content'] : null;
      if (content is! String) return null;
      if (!jsonMode) return {'_text': content};
      final parsed = _tryParseJson(content);
      return parsed;
    } on TimeoutException {
      debugPrint('AI chat timeout');
      return null;
    } catch (e, st) {
      debugPrint('AI chat failed: $e\n$st');
      return null;
    }
  }

  /// Strip trailing bullet-list options from free-form text and return them
  /// as quick-reply options.
  (String, List<AIQuickOption>) _extractBulletOptions(String text) {
    final lines = text.trim().split('\n');
    final bullets = <String>[];
    var i = lines.length - 1;
    while (i >= 0) {
      var line = lines[i].trim();
      if (line.isEmpty) {
        i--;
        continue;
      }
      final m = RegExp(r'^(?:[-*•·▫◦]|\d+[\.\)])\s+"?(.+?)"?\s*$')
          .firstMatch(line);
      if (m == null) break;
      final value = m.group(1)!.replaceAll(RegExp(r'^"|"$'), '').trim();
      if (value.isEmpty) break;
      bullets.insert(0, value);
      i--;
    }
    if (bullets.length < 2) return (text.trim(), const <AIQuickOption>[]);
    final cleanReply = lines.sublist(0, i + 1).join('\n').trim();
    return (
      cleanReply.isEmpty ? text.trim() : cleanReply,
      bullets.map((b) => AIQuickOption(b)).toList()
    );
  }

  Map<String, dynamic>? _tryParseJson(String raw) {
    var s = raw.trim();
    // Strip ```json ... ``` fences.
    if (s.startsWith('```')) {
      s = s.replaceFirst(RegExp(r'^```(?:json)?\s*'), '');
      if (s.endsWith('```')) s = s.substring(0, s.length - 3);
      s = s.trim();
    }
    try {
      final v = jsonDecode(s);
      if (v is Map<String, dynamic>) return v;
    } catch (_) {}
    // Fallback: find the first {...} object in the text (some models prefix
    // prose before the JSON).
    final firstBrace = s.indexOf('{');
    final lastBrace = s.lastIndexOf('}');
    if (firstBrace >= 0 && lastBrace > firstBrace) {
      final slice = s.substring(firstBrace, lastBrace + 1);
      try {
        final v = jsonDecode(slice);
        if (v is Map<String, dynamic>) return v;
      } catch (_) {}
    }
    // Truncation repair: the model hit max_tokens mid-output. Chop at the last
    // complete "}," inside an array, then auto-close any still-open arrays and
    // objects so the JSON parses.
    final repaired = _repairTruncatedJson(s);
    if (repaired != null) return repaired;
    return null;
  }

  Map<String, dynamic>? _repairTruncatedJson(String raw) {
    final firstBrace = raw.indexOf('{');
    if (firstBrace < 0) return null;
    var s = raw.substring(firstBrace);
    // Find the last position where a `}` is followed by `,` or `]` or `}` —
    // i.e. a complete array element boundary.
    final match = RegExp(r'\}\s*(?=[,\]\}])').allMatches(s).toList().lastOrNull;
    if (match == null) return null;
    var cut = s.substring(0, match.end);
    // Scan to count open arrays/objects (ignoring strings).
    int openObj = 0, openArr = 0;
    bool inStr = false, escaped = false;
    for (int i = 0; i < cut.length; i++) {
      final c = cut[i];
      if (escaped) {
        escaped = false;
        continue;
      }
      if (c == '\\' && inStr) {
        escaped = true;
        continue;
      }
      if (c == '"') {
        inStr = !inStr;
        continue;
      }
      if (inStr) continue;
      if (c == '{') {
        openObj++;
      } else if (c == '}') {
        openObj--;
      } else if (c == '[') {
        openArr++;
      } else if (c == ']') {
        openArr--;
      }
    }
    // Trim trailing comma if present.
    cut = cut.replaceFirst(RegExp(r',\s*$'), '');
    final buf = StringBuffer(cut);
    while (openArr > 0) {
      buf.write(']');
      openArr--;
    }
    while (openObj > 0) {
      buf.write('}');
      openObj--;
    }
    try {
      final v = jsonDecode(buf.toString());
      if (v is Map<String, dynamic>) return v;
    } catch (_) {}
    return null;
  }

  Future<ParsedTask?> parseTask(String naturalText) async {
    final now = DateTime.now().toIso8601String();
    final system =
        'You are a personal planner task parser. Convert the user\'s natural-language request into a single task.\n'
        'Return ONLY a JSON object matching exactly this schema:\n'
        '{"title": string, "scheduledStart": ISO8601 or null, "durationMinutes": int or null, "iconKey": one of [${kIconKeys.join(", ")}] or null, "colorValue": int or null, "subtasks": array of strings, "notes": string or null}\n'
        'Rules: current datetime is $now. Resolve relative dates. If no time, return null. Default duration 30 when time is given but no duration. No prose outside JSON.';
    final result = await _chat(messages: [
      {'role': 'system', 'content': system},
      {'role': 'user', 'content': naturalText},
    ]);
    if (result == null) return null;
    final parsed = ParsedTask.fromJson(result);
    if (parsed.title.isEmpty) return null;
    return parsed;
  }

  /// Conversational planner. Given history, returns the next assistant turn.
  /// The assistant either asks a follow-up question (action=none) or emits an
  /// action the app should execute (createTask/Event/Habit/Goal or done).
  Future<ConversationTurn?> converse(
    List<ConversationTurn> history, {
    String? stateSnapshot,
  }) async {
    final now = DateTime.now().toIso8601String();
    final system = '''You are the user's personal planning manager inside a day-planner app. You already know their current plans and have direct access to create TASKS, EVENTS, HABITS, and GOALS.

Be proactive like a good chief-of-staff:
- Read the user's current state (listed below) before replying.
- Catch conflicts with existing events and scheduled tasks.
- Suggest moving Inbox items onto the timeline when helpful.
- Remind the user of open habits/goals that relate to what they're planning.
- Keep the conversation flowing: confirm, then offer the logical next step.

How to decide the right type:
- TASK  — a one-time to-do (schedule on the timeline when a time is known)
- EVENT — an appointment/meeting with fixed start AND end (often has a location)
- HABIT — a recurring routine (daily, or specific weekdays) with a reminder time
- GOAL  — a long-term objective with a target date

Rules:
1) BE DECISIVE. At most 2 short clarifying turns — then commit to an action. If the user's goal is a learning plan, routine, or multi-step project, emit kind "plan" that creates several items at once (a goal, one or more habits, a handful of tasks).
2) EVERY user-facing question MUST come with 3–5 tappable "options" in the JSON array. NEVER list options as bullets inside "reply" — only in the "options" array. Use picker objects when precise values are needed.
3) You MUST respond with ONLY a JSON object — no code fences — matching exactly:
   {"reply": "<markdown text to the user>", "action": {"kind": "<see kinds below>", "data": <object>}, "options": [<option>, ...], "multiselect": <bool>}
   where each <option> is either a string (sent verbatim when tapped) OR an object {"label": str, "picker": "date"|"time"|"duration"} that opens a native picker.
   Set "multiselect": true for questions where the user may pick multiple options (e.g. "which areas apply"); the app will join their picks with commas. Default is false (single-select).
4) Use kind="none" ONLY while still gathering essential info. Use kind="plan" for multi-item plans. Use individual create_/update_/delete_ kinds for single-item operations.
5) "reply" field SUPPORTS Markdown (headings `##`, lists, tables, **bold**, [links](https://), emoji). Use rich markdown for plans/roadmaps. For short follow-ups keep it ≤ 20 words. Options labels stay short (≤ 5 words).
6) Current datetime: $now. Resolve relative times using it.
7) For UPDATE/DELETE/TOGGLE/ARCHIVE actions you MUST use an "id" copied verbatim from the CURRENT USER STATE — never invent ids.

Action kinds and data schemas:

CREATE (emit when the user intends to add a new item):
- kind "create_task" (alias: "task"):  {"title": str, "scheduledStart": ISO8601 or null, "durationMinutes": int or null, "iconKey": "${kIconKeys.join("|")}", "notes": str or null, "subtasks": [str, ...], "goalId": str or null (link to an existing goal from CURRENT USER STATE)}
- kind "create_event" (alias: "event"): {"title": str, "startAt": ISO8601, "endAt": ISO8601, "location": str or null, "recurrence": 0|1|2|3}
- kind "create_habit" (alias: "habit"): {"name": str, "frequencyType": 0|1, "weekdays": [1..7], "reminderHour": 0-23, "reminderMinute": 0-59}
- kind "create_goal" (alias: "goal"):   {"title": str, "description": str or null, "targetDate": ISO8601 or null}

UPDATE (include ONLY the fields the user wants to change; id is required):
- kind "update_task":  {"id": str, <any task field>}
- kind "update_event": {"id": str, <any event field>}
- kind "update_habit": {"id": str, <any habit field>}
- kind "update_goal":  {"id": str, <any goal field>}

TOGGLE / COMPLETION:
- kind "toggle_task":  {"id": str}   — flips completed state
- kind "toggle_habit": {"id": str, "done": true|false, "date": ISO8601 optional (default today)}

DELETE / ARCHIVE:
- kind "delete_task" | "delete_event" | "delete_habit" | "delete_goal": {"id": str}
- kind "archive_goal": {"id": str, "archived": true|false}

BATCH (use for multi-step plans — a goal with supporting tasks/habits, a learning curriculum, a trip itinerary):
- kind "plan":
  {
    "goals":  [{same shape as create_goal  data}, ...]  (0..many),
    "habits": [{same shape as create_habit data}, ...]  (0..many),
    "tasks":  [{same shape as create_task  data}, ...]  (0..many)
  }
  IMPORTANT — when the user's request includes words like "plan", "tasks", "daily", "step by step", "schedule", "roadmap":
  - The `tasks` array MUST contain at least 5 CONCRETE scheduled items spread across multiple days starting from today.
  - Each task MUST have a `scheduledStart` ISO8601 (day + hour) and a `durationMinutes` integer.
  - Do NOT put the task list in the goal's description. Always emit separate entries in `tasks`.
  - Prefer 30–60 minute blocks; space them across days.

Control:
- kind "none": still gathering info (max 2 consecutive turns)
- kind "done": conversation complete

Examples:
User: "I want to start exercising"
Assistant: {"reply":"Is this a one-time session or a recurring habit?","action":{"kind":"none","data":{}},"options":["One-time","Daily","Weekdays","Weekly"]}
User: "Weekdays"
Assistant: {"reply":"What time works?","action":{"kind":"none","data":{}},"options":["Morning (7:00)","Noon (12:00)","Evening (18:00)",{"label":"Pick a time…","picker":"time"}]}
User: "Morning (7:00)"
Assistant: {"reply":"Created a weekday workout habit at 7:00 AM.","action":{"kind":"habit","data":{"name":"Workout","frequencyType":1,"weekdays":[1,2,3,4,5],"reminderHour":7,"reminderMinute":0}},"options":["Anything else?","Done"]}

User: "call mom"
Assistant: {"reply":"When?","action":{"kind":"none","data":{}},"options":["Today","Tomorrow","This week",{"label":"Pick a date…","picker":"date"}]}
User: "Tomorrow"
Assistant: {"reply":"At what time?","action":{"kind":"none","data":{}},"options":["Morning","Afternoon","Evening",{"label":"Pick a time…","picker":"time"}]}
User: "Evening"
Assistant: {"reply":"Added: Call mom tomorrow 6 PM.","action":{"kind":"task","data":{"title":"Call mom","scheduledStart":"<tomorrow 18:00 ISO>","durationMinutes":15,"iconKey":"call","notes":null,"subtasks":[]}},"options":["Another task","Done"]}

CAREER / ROADMAP FLOW — when the user asks about a new role, promotion, career transition, multi-month plan, or "first 30/60/90 days":
Step A. Ask ONE question at a time in this order (use options + multiselect where noted):
  1. "What's the main focus of this plan?" — single-select (e.g. "First 30-60-90 days as <role>", "Deep technical mastery", "Leadership transition", "Certification prep")
  2. "Which areas matter most to you right now?" — MULTISELECT true, 4–6 role-relevant options
  3. "Preferred content language?" — single-select ["English", "العربية", "Mix of both"]
Step B. After the 3 answers are collected, emit kind="plan" with:
  - 1 `goal` summarizing the outcome with a targetDate ~90 days from today
  - 2–4 `habits` (reading/learning/1:1s rhythms) at specific reminder times
  - 8+ `tasks` spread across days (study sessions, audits, 1:1s, deliverables), each with scheduledStart + durationMinutes
  The `reply` markdown should include:
    ## Phase headings (30/60/90 days or Pillars)
    **Key activities**, bullet lists, book recommendations, article links, YouTube channels
    A small weekly-rhythm table
    🎯 summary bullets at the end
  After the plan action, offer options ["Expand automation section","Weekly rhythm","Done"].

User: "I want to learn web development"
Assistant: {"reply":"Starting a 4-week plan with daily study tasks and a practice habit.","action":{"kind":"plan","data":{"goals":[{"title":"Learn web development","description":"HTML + CSS + JavaScript fundamentals","targetDate":"<4 weeks from now ISO>"}],"habits":[{"name":"Code practice","frequencyType":0,"weekdays":[],"reminderHour":19,"reminderMinute":0}],"tasks":[{"title":"HTML basics tutorial","scheduledStart":"<tomorrow 19:00 ISO>","durationMinutes":60,"iconKey":"study","notes":null,"subtasks":["Elements","Attributes","Semantic tags"]},{"title":"CSS selectors & box model","scheduledStart":"<day+2 19:00 ISO>","durationMinutes":60,"iconKey":"study","notes":null,"subtasks":[]},{"title":"JavaScript variables & functions","scheduledStart":"<day+3 19:00 ISO>","durationMinutes":60,"iconKey":"study","notes":null,"subtasks":[]}]}},"options":["Adjust the schedule","Add a weekly review","Done"]}

User: "move my 3 PM Call Sam task to 5 PM"
(state shows task id "abc-123", "Call Sam", scheduledStart 15:00)
Assistant: {"reply":"Moved Call Sam to 5 PM.","action":{"kind":"update_task","data":{"id":"abc-123","scheduledStart":"<today 17:00 ISO>"}},"options":["Anything else?","Done"]}

User: "delete the workout habit"
(state shows habit id "h-999", "Workout")
Assistant: {"reply":"Deleted the Workout habit.","action":{"kind":"delete_habit","data":{"id":"h-999"}},"options":["Done"]}

User: "mark the workout habit done today"
(state shows habit id "h-999")
Assistant: {"reply":"Marked Workout done for today.","action":{"kind":"toggle_habit","data":{"id":"h-999","done":true}},"options":["Done"]}

User: "that's all"
Assistant: {"reply":"Great — I'm here whenever you need more planning.","action":{"kind":"done","data":{}},"options":[]}

Never invent facts. Never include anything outside the JSON object.''';

    final messages = <Map<String, String>>[
      {'role': 'system', 'content': system},
      if (stateSnapshot != null && stateSnapshot.isNotEmpty)
        {'role': 'system', 'content': 'CURRENT USER STATE:\n$stateSnapshot'},
    ];
    for (final t in history) {
      if (t.role == 'system') continue;
      messages.add({
        'role': t.role == 'assistant' ? 'assistant' : 'user',
        'content': t.text,
      });
    }

    Map<String, dynamic>? result = await _chat(messages: messages);
    // Retry with a stronger JSON-only reminder if the model didn't follow.
    if (result == null || result['reply'] is! String) {
      final retryMessages = [
        ...messages,
        {
          'role': 'system',
          'content':
              'Reply ONLY with a JSON object matching {"reply","action":{"kind","data"},"options":[...]}. No prose, no markdown, no bullets in "reply". Options MUST be in the "options" array.'
        }
      ];
      result = await _chat(messages: retryMessages);
    }
    // Final fallback: plain text reply with extracted bullet options.
    if (result == null || result['reply'] is! String) {
      final plain = await _chat(messages: messages, jsonMode: false);
      final text = plain?['_text'] as String?;
      if (text != null && text.trim().isNotEmpty) {
        final (cleanReply, extracted) = _extractBulletOptions(text);
        return ConversationTurn.assistant(cleanReply, options: extracted);
      }
      return null;
    }
    final reply = (result['reply'] as String).trim();
    if (reply.isEmpty) return null;
    final actionRaw = result['action'];
    AIAction action = AIAction.none;
    final optionsRaw = result['options'];
    final options = <AIQuickOption>[];
    if (optionsRaw is List) {
      for (final o in optionsRaw) {
        if (o is String && o.trim().isNotEmpty) {
          options.add(AIQuickOption(o.trim()));
        } else if (o is Map<String, dynamic>) {
          final label = (o['label'] as String?)?.trim();
          final picker = o['picker'] as String?;
          if (label != null && label.isNotEmpty) {
            options.add(AIQuickOption(label,
                picker: const ['date', 'time', 'duration'].contains(picker)
                    ? picker
                    : null));
          }
        }
      }
    }
    if (actionRaw is Map<String, dynamic>) {
      final kindStr = actionRaw['kind'] as String?;
      final data = (actionRaw['data'] is Map<String, dynamic>)
          ? actionRaw['data'] as Map<String, dynamic>
          : <String, dynamic>{};
      switch (kindStr) {
        case 'task':
        case 'create_task':
          action = AIAction(AIActionKind.createTask, data);
          break;
        case 'update_task':
          action = AIAction(AIActionKind.updateTask, data);
          break;
        case 'delete_task':
          action = AIAction(AIActionKind.deleteTask, data);
          break;
        case 'toggle_task':
          action = AIAction(AIActionKind.toggleTask, data);
          break;
        case 'event':
        case 'create_event':
          action = AIAction(AIActionKind.createEvent, data);
          break;
        case 'update_event':
          action = AIAction(AIActionKind.updateEvent, data);
          break;
        case 'delete_event':
          action = AIAction(AIActionKind.deleteEvent, data);
          break;
        case 'habit':
        case 'create_habit':
          action = AIAction(AIActionKind.createHabit, data);
          break;
        case 'update_habit':
          action = AIAction(AIActionKind.updateHabit, data);
          break;
        case 'delete_habit':
          action = AIAction(AIActionKind.deleteHabit, data);
          break;
        case 'toggle_habit':
          action = AIAction(AIActionKind.toggleHabit, data);
          break;
        case 'goal':
        case 'create_goal':
          action = AIAction(AIActionKind.createGoal, data);
          break;
        case 'update_goal':
          action = AIAction(AIActionKind.updateGoal, data);
          break;
        case 'delete_goal':
          action = AIAction(AIActionKind.deleteGoal, data);
          break;
        case 'archive_goal':
          action = AIAction(AIActionKind.archiveGoal, data);
          break;
        case 'plan':
          action = AIAction(AIActionKind.plan, data);
          break;
        case 'done':
          action = const AIAction(AIActionKind.done);
          break;
      }
    }
    final multi = result['multiselect'] == true;
    return ConversationTurn.assistant(
      reply,
      action: action,
      options: options,
      multiselect: multi,
    );
  }

  Future<List<ScheduleChange>?> proposeSchedule({
    required List<Task> inbox,
    required List<Task> scheduled,
    required List<Event> events,
    required TimeOfDay wake,
    required TimeOfDay sleep,
    required DateTime day,
  }) async {
    String iso(DateTime d) => d.toIso8601String();

    final inboxJson = inbox
        .map((t) => {
              'id': t.id,
              'title': t.title,
              'durationMinutes': t.durationMinutes ?? 30,
              'priority': t.priority,
              if (t.notes != null) 'notes': t.notes,
            })
        .toList();

    final scheduledJson = scheduled
        .where((t) => t.scheduledStart != null)
        .map((t) => {
              'id': t.id,
              'title': t.title,
              'scheduledStart': iso(t.scheduledStart!),
              'durationMinutes': t.durationMinutes ?? 30,
            })
        .toList();

    final eventsJson = events
        .map((e) => {
              'id': e.id,
              'title': e.title,
              'startAt': iso(e.startAt),
              'endAt': iso(e.endAt),
            })
        .toList();

    final wakeIso = iso(
        DateTime(day.year, day.month, day.day, wake.hour, wake.minute));
    final sleepIso = iso(
        DateTime(day.year, day.month, day.day, sleep.hour, sleep.minute));

    final user = jsonEncode({
      'now': iso(DateTime.now()),
      'day': iso(DateTime(day.year, day.month, day.day)),
      'wake': wakeIso,
      'sleep': sleepIso,
      'events': eventsJson,
      'scheduled': scheduledJson,
      'inbox': inboxJson,
    });

    const system =
        'You are a day-planner. Given events, scheduled tasks and an inbox, propose start times for every inbox task between wake and sleep on the given day. Do not overlap events or already-scheduled tasks; leave 5-min buffers; schedule higher priority earlier. Omit tasks that cannot fit.\n'
        'Return ONLY: {"changes": [{"taskId", "scheduledStart": ISO8601, "durationMinutes": int, "reason": string}]}';

    final result = await _chat(messages: [
      {'role': 'system', 'content': system},
      {'role': 'user', 'content': user},
    ]);
    if (result == null) return null;
    final raw = result['changes'];
    if (raw is! List) return null;
    final changes = <ScheduleChange>[];
    for (final item in raw) {
      if (item is Map<String, dynamic>) {
        final change = ScheduleChange.tryFromJson(item);
        if (change != null) changes.add(change);
      }
    }
    return changes;
  }

  /// Describe the user's availability window (work hours, skipped weekend
  /// weekdays) in plain English.
  String _availabilityPrompt() {
    final sh = AppPrefs().workStartHour.value.toString().padLeft(2, '0');
    final eh = AppPrefs().workEndHour.value.toString().padLeft(2, '0');
    final weekend = AppPrefs().weekendDays.value;
    if (weekend.isEmpty) {
      return 'User availability: every day from $sh:00 to $eh:00. Never schedule outside these hours.';
    }
    final names = {
      1: 'Mon',
      2: 'Tue',
      3: 'Wed',
      4: 'Thu',
      5: 'Fri',
      6: 'Sat',
      7: 'Sun',
    };
    final off = weekend.map((d) => names[d] ?? '').join(', ');
    return 'User availability: $sh:00–$eh:00 on non-weekend days. Weekend days (NEVER schedule on these): $off. Never schedule outside these hours.';
  }

  /// Build a JSON snippet of busy windows (events + scheduled tasks) for the
  /// next N days. Used to tell the model which slots to avoid.
  String _busyWindowsJson({int fromDays = 0, int toDays = 60}) {
    String iso(DateTime d) => d.toIso8601String();
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day)
        .add(Duration(days: fromDays));
    final end = start.add(Duration(days: toDays));
    final items = <Map<String, String>>[];
    final events = EventService().eventsForRange(start, end);
    for (final e in events) {
      items.add({
        'start': iso(e.startAt),
        'end': iso(e.endAt),
        'title': e.title,
      });
    }
    for (final t in TaskService().all()) {
      final s = t.scheduledStart;
      if (s == null) continue;
      if (s.isBefore(start) || s.isAfter(end)) continue;
      final dur = t.durationMinutes ?? 30;
      items.add({
        'start': iso(s),
        'end': iso(s.add(Duration(minutes: dur))),
        'title': t.title,
      });
    }
    items.sort((a, b) => a['start']!.compareTo(b['start']!));
    return jsonEncode(items);
  }

  /// Take a free-form chat history and extract a concrete `plan` action with
  /// real ISO dates starting today. Used by the "Convert chat to plan" button
  /// so the model doesn't have to emit JSON on every turn.
  Future<AIAction?> extractPlan(List<ConversationTurn> history) async {
    final now = DateTime.now();
    final anchor = DateTime(
            now.year, now.month, now.day, AppPrefs().workStartHour.value, 0)
        .toIso8601String();
    final system =
        'You convert chat history into a single "plan" action for a day planner.\n'
        'Output ONLY a JSON object: {"goals":[], "habits":[], "tasks":[]}.\n'
        'NO prose, NO markdown fences, NO placeholder tokens like "<tomorrow 19:00 ISO>" — every date MUST be a real ISO 8601 datetime string.\n'
        'Use today\'s date ($anchor) as the first task\'s scheduledStart anchor.\n'
        'DAY DISTRIBUTION — CRITICAL:\n'
        '• Each task goes on a DIFFERENT calendar date. AT MOST 2 tasks may share the same date, and only if they are at clearly different hours.\n'
        '• Walk forward day-by-day: task 1 → today, task 2 → tomorrow, task 3 → day after tomorrow, etc. Skip weekend days if the user configured them.\n'
        '• Never put all tasks on the same day. Minimum of 5 distinct dates across the plan.\n'
        'Include exactly 1 goal (targetDate ~90 days out) and EXACTLY 8–15 tasks with real scheduledStart + durationMinutes. Do NOT generate habits (leave the habits array empty).\n'
        'HARD LIMIT: 15 tasks maximum. Every task title MUST BE UNIQUE — never repeat a title. After 15 tasks, STOP and close the JSON.\n'
        '${_availabilityPrompt()}\n'
        'CONFLICTS — these time windows are already BUSY. You MUST NOT schedule any new task that overlaps these; pick an earlier or later slot on the same day, or the next free day.\n'
        'BUSY: ${_busyWindowsJson(fromDays: 0, toDays: 60)}\n'
        'Schemas:\n'
        '- goal:  {"title": str, "description": str or null, "targetDate": ISO8601}\n'
        '- habit: {"name": str, "frequencyType": 0|1, "weekdays": [1..7], "reminderHour": 0-23, "reminderMinute": 0-59}\n'
        '- task:  {"title": str, "scheduledStart": ISO8601, "durationMinutes": int, "iconKey": one of [${kIconKeys.join(", ")}], "notes": str or null, "subtasks": [str, ...]}\n'
        'Current datetime: ${now.toIso8601String()}.';

    final transcript = history
        .where((t) => t.role != 'system')
        .map((t) => '${t.role.toUpperCase()}: ${t.text}')
        .join('\n\n');

    final messages = <Map<String, String>>[
      {'role': 'system', 'content': system},
      {
        'role': 'user',
        'content':
            'Conversation so far:\n\n$transcript\n\nEmit the plan JSON now.'
      },
    ];

    // 3500 tokens is enough for ~15 tasks + goal + habits and reduces
    // generation time significantly vs 8192.
    final result = await _chat(messages: messages, maxTokens: 3500);
    if (result == null) return null;
    _dedupeTasksInPlan(result);
    final hasAny =
        (result['goals'] is List && (result['goals'] as List).isNotEmpty) ||
            (result['habits'] is List && (result['habits'] as List).isNotEmpty) ||
            (result['tasks'] is List && (result['tasks'] as List).isNotEmpty);
    if (!hasAny) return null;
    return AIAction(AIActionKind.plan, result);
  }

  /// Generate scheduled sub-tasks tied to an existing goal (no new goal/habits).
  /// Returns an AIAction(plan) with tasks[] populated and targetGoalId stamped.
  Future<AIAction?> extractTasksForGoal({
    required String goalId,
    required String goalTitle,
    String? goalDescription,
    DateTime? targetDate,
  }) async {
    final now = DateTime.now();
    final anchor = DateTime(
            now.year, now.month, now.day, AppPrefs().workStartHour.value, 0)
        .toIso8601String();
    final days = targetDate != null
        ? targetDate.difference(now).inDays.clamp(14, 365)
        : 90;
    final system =
        'You break a GOAL into 8–15 concrete SCHEDULED sub-tasks for a day planner.\n'
        'Output ONLY JSON: {"goals":[],"habits":[],"tasks":[...]}\n'
        'NO prose, NO markdown, NO placeholder tokens — every date is a real ISO 8601 string.\n'
        'Anchor the first task at $anchor.\n'
        'DAY DISTRIBUTION — CRITICAL:\n'
        '• Each task goes on a DIFFERENT calendar date. AT MOST 2 tasks may share the same date, and only if at clearly different hours.\n'
        '• Walk forward day-by-day, skipping configured weekend days.\n'
        '• Never place every task on the same day. Use at least 5 distinct dates across the plan within the next $days days.\n'
        '30–60 min blocks. Each task needs scheduledStart, durationMinutes, iconKey (one of [${kIconKeys.join(", ")}]), a useful title, optional notes and 0–3 subtasks.\n'
        'HARD LIMIT: 15 tasks maximum. Every task title MUST BE UNIQUE — never repeat a title. After 15 tasks STOP and close the JSON.\n'
        '${_availabilityPrompt()}\n'
        'CONFLICTS — these time windows are already BUSY. You MUST NOT schedule any new task that overlaps these; pick an earlier/later slot or the next free day.\n'
        'BUSY: ${_busyWindowsJson(fromDays: 0, toDays: days)}\n'
        'Current datetime: ${now.toIso8601String()}.\n'
        'GOAL: "$goalTitle"${goalDescription != null && goalDescription.isNotEmpty ? '\nDESCRIPTION: "$goalDescription"' : ''}${targetDate != null ? '\nTARGET: ${targetDate.toIso8601String()}' : ''}';

    final messages = <Map<String, String>>[
      {'role': 'system', 'content': system},
      {
        'role': 'user',
        'content':
            'Generate sub-tasks for the goal above. JSON only.'
      },
    ];

    final result = await _chat(messages: messages, maxTokens: 3500);
    if (result == null) return null;
    _dedupeTasksInPlan(result);
    final tasks = result['tasks'];
    if (tasks is! List || tasks.isEmpty) return null;
    return AIAction(AIActionKind.plan, {
      'goals': [],
      'habits': [],
      'tasks': tasks,
      'targetGoalId': goalId,
    });
  }

  /// Drop duplicate tasks (same normalized title) in place, cap at 15,
  /// and — if the model crammed everything on one date — redistribute.
  void _dedupeTasksInPlan(Map<String, dynamic> plan) {
    final raw = plan['tasks'];
    if (raw is! List) return;
    final seen = <String>{};
    final unique = <Map<String, dynamic>>[];
    for (final t in raw) {
      if (t is! Map<String, dynamic>) continue;
      final title = (t['title'] as String?)?.trim().toLowerCase() ?? '';
      if (title.isEmpty || seen.contains(title)) continue;
      seen.add(title);
      unique.add(t);
      if (unique.length >= 15) break;
    }
    _spreadTasksAcrossDays(unique);
    plan['tasks'] = unique;
  }

  /// Force tasks onto distinct calendar dates: allow at most 2 per day, and
  /// if the model crammed more than that, bump them to subsequent weekdays
  /// (skipping the user's configured weekend).
  void _spreadTasksAcrossDays(List<Map<String, dynamic>> tasks) {
    if (tasks.isEmpty) return;
    final weekend = AppPrefs().weekendDays.value;
    final startHour = AppPrefs().workStartHour.value;
    final endHour = AppPrefs().workEndHour.value;
    const maxPerDay = 2;

    final perDateCount = <String, int>{};
    DateTime nextNonWeekend(DateTime d) {
      var c = DateTime(d.year, d.month, d.day);
      while (weekend.contains(c.weekday)) {
        c = c.add(const Duration(days: 1));
      }
      return c;
    }

    String key(DateTime d) =>
        '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

    for (final t in tasks) {
      final raw = t['scheduledStart'];
      if (raw is! String) continue;
      final parsed = DateTime.tryParse(raw);
      if (parsed == null) continue;
      DateTime dt = parsed;

      // Push off weekend.
      if (weekend.contains(dt.weekday)) {
        final nd = nextNonWeekend(dt);
        dt = DateTime(nd.year, nd.month, nd.day, dt.hour, dt.minute);
      }

      // Clamp hour into the work window.
      if (dt.hour < startHour) {
        dt = DateTime(dt.year, dt.month, dt.day, startHour, 0);
      } else if (dt.hour >= endHour) {
        final nd = nextNonWeekend(dt.add(const Duration(days: 1)));
        dt = DateTime(nd.year, nd.month, nd.day, startHour, 0);
      }

      // If this day already has too many tasks, bump forward.
      while ((perDateCount[key(dt)] ?? 0) >= maxPerDay) {
        final nd = nextNonWeekend(dt.add(const Duration(days: 1)));
        dt = DateTime(nd.year, nd.month, nd.day, startHour, 0);
      }

      // If two tasks land on the same day, stagger the second by 2h.
      final count = perDateCount[key(dt)] ?? 0;
      if (count == 1) {
        final bumped = dt.add(const Duration(hours: 2));
        if (bumped.hour < endHour) dt = bumped;
      }

      perDateCount[key(dt)] = count + 1;
      t['scheduledStart'] = dt.toIso8601String();
    }
  }

  Future<ConnectionResult> testConnection() async {
    final uri = _endpoint();
    if (uri == null) {
      return ConnectionResult.failure('Base URL is empty — configure it first.');
    }
    try {
      // First a cheap GET to /v1/models to verify TCP + HTTP path.
      final modelsUri = uri.replace(pathSegments: [
        ...uri.pathSegments.sublist(0, uri.pathSegments.length - 1),
        'models',
      ]);
      final modelsResp =
          await http.get(modelsUri).timeout(const Duration(seconds: 20));
      if (modelsResp.statusCode != 200) {
        return ConnectionResult.failure(
            'GET $modelsUri → HTTP ${modelsResp.statusCode}');
      }
      // Then a real chat completion.
      final resp = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'model': AIConfig().model.value,
              'messages': [
                {'role': 'user', 'content': 'ping'},
              ],
              'max_tokens': 4,
              'temperature': 0,
            }),
          )
          .timeout(const Duration(seconds: 60));
      if (resp.statusCode == 200) return const ConnectionResult.ok();
      return ConnectionResult.failure(
          'POST $uri → HTTP ${resp.statusCode}\n${resp.body.isNotEmpty ? resp.body.substring(0, resp.body.length.clamp(0, 300)) : ""}');
    } on TimeoutException {
      return ConnectionResult.failure('Timeout contacting $uri');
    } catch (e) {
      return ConnectionResult.failure('$e\nURL: $uri');
    }
  }
}

class ConnectionResult {
  final bool ok;
  final String? error;
  const ConnectionResult.ok()
      : ok = true,
        error = null;
  const ConnectionResult.failure(this.error) : ok = false;
}

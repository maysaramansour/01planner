import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:one_planner/l10n/app_localizations.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';

import '../models/chat_session.dart';
import '../models/event.dart';
import '../models/goal.dart';
import '../models/habit.dart';
import '../models/task.dart';
import '../services/ai_chat_service.dart';
import '../services/ai_config.dart';
import '../services/ai_service.dart';
import '../services/event_service.dart';
import '../services/goal_service.dart';
import '../services/habit_service.dart';
import '../services/notification_service.dart';
import '../services/pending_plan_service.dart';
import '../services/speech_service.dart';
import '../services/storage_service.dart';
import '../services/task_service.dart';
import '../widgets/plan_preview_sheet.dart';
import 'ai_settings_screen.dart';

class AIScreen extends StatefulWidget {
  const AIScreen({super.key});

  @override
  State<AIScreen> createState() => _AIScreenState();
}

class _AIScreenState extends State<AIScreen> with WidgetsBindingObserver {
  final List<ConversationTurn> _history = [];
  final _input = TextEditingController();
  final _scroll = ScrollController();
  bool _loading = false;
  bool _presenting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _reloadHistory();
    AIChatService().activeSessionId.addListener(_reloadHistory);
    PendingPlanService().state.addListener(_onPendingStateChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _scrollToBottom();
      // If a plan finished while the app was backgrounded, show it now.
      await _presentPendingPlan();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    AIChatService().activeSessionId.removeListener(_reloadHistory);
    PendingPlanService().state.removeListener(_onPendingStateChanged);
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _presentPendingPlan();
    }
  }

  void _onPendingStateChanged() {
    if (!mounted) return;
    setState(() {});
    if (PendingPlanService().state.value == 'ready') {
      _presentPendingPlan();
    }
  }

  void _reloadHistory() {
    setState(() {
      _history
        ..clear()
        ..addAll(AIChatService().asHistory());
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut);
      }
    });
  }

  Future<void> _send(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || _loading) return;
    final l = AppLocalizations.of(context)!;
    setState(() {
      _history.add(ConversationTurn.user(trimmed));
      _input.clear();
      _loading = true;
    });
    await AIChatService().add('user', trimmed);
    _scrollToBottom();
    final reply = await AIService().converse(
      _history,
      stateSnapshot: _buildStateSnapshot(),
    );
    if (!mounted) return;
    if (reply == null) {
      setState(() {
        _loading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.aiUnavailable)),
      );
      _scrollToBottom();
      return;
    }
    setState(() {
      _history.add(reply);
      _loading = false;
    });
    await AIChatService().add('assistant', reply.text);
    _scrollToBottom();
    if (reply.action.kind != AIActionKind.none &&
        reply.action.kind != AIActionKind.done) {
      await _executeAction(reply.action);
    }
  }

  Future<void> _executeAction(AIAction action) async {
    final l = AppLocalizations.of(context)!;
    String confirmation = '';
    try {
      switch (action.kind) {
        case AIActionKind.createTask:
          final title = (action.data['title'] as String?)?.trim() ?? '';
          if (title.isEmpty) return;
          final startRaw = action.data['scheduledStart'] as String?;
          final start = startRaw != null ? DateTime.tryParse(startRaw) : null;
          final task = Task(
            id: const Uuid().v4(),
            title: title,
            createdAt: DateTime.now(),
            scheduledStart: start,
            durationMinutes: action.data['durationMinutes'] is int
                ? action.data['durationMinutes'] as int
                : (start != null ? 30 : null),
            iconKey: kIconKeys.contains(action.data['iconKey'])
                ? action.data['iconKey'] as String
                : null,
            colorValue: kPaletteColors.first,
            notes: action.data['notes'] is String
                ? action.data['notes'] as String
                : null,
            subtasks: _stringList(action.data['subtasks']),
            reminderEnabled: start != null,
            reminderLeadMinutes: 10,
            goalId: action.data['goalId'] is String
                ? action.data['goalId'] as String
                : null,
          );
          await TaskService().add(task);
          confirmation = l.aiCreatedTask(title);
          break;
        case AIActionKind.createEvent:
          final title = (action.data['title'] as String?)?.trim() ?? '';
          final startRaw = action.data['startAt'] as String?;
          final endRaw = action.data['endAt'] as String?;
          final start = startRaw != null ? DateTime.tryParse(startRaw) : null;
          final end = endRaw != null ? DateTime.tryParse(endRaw) : null;
          if (title.isEmpty || start == null || end == null) return;
          final event = Event(
            id: const Uuid().v4(),
            title: title,
            startAt: start,
            endAt: end,
            location: action.data['location'] is String
                ? action.data['location'] as String
                : null,
            recurrence: action.data['recurrence'] is int
                ? action.data['recurrence'] as int
                : 0,
            createdAt: DateTime.now(),
          );
          await EventService().add(event);
          confirmation = l.aiCreatedEvent(title);
          break;
        case AIActionKind.createHabit:
          final name = (action.data['name'] as String?)?.trim() ?? '';
          if (name.isEmpty) return;
          final freq = action.data['frequencyType'] is int
              ? action.data['frequencyType'] as int
              : 0;
          final weekdays = <int>[];
          final raw = action.data['weekdays'];
          if (raw is List) {
            for (final v in raw) {
              if (v is int && v >= 1 && v <= 7) weekdays.add(v);
            }
          }
          final habit = Habit(
            id: const Uuid().v4(),
            name: name,
            frequencyType: freq,
            weekdays: weekdays,
            reminderHour: action.data['reminderHour'] is int
                ? action.data['reminderHour'] as int
                : 8,
            reminderMinute: action.data['reminderMinute'] is int
                ? action.data['reminderMinute'] as int
                : 0,
            createdAt: DateTime.now(),
          );
          await HabitService().add(habit);
          confirmation = l.aiCreatedHabit(name);
          break;
        case AIActionKind.createGoal:
          final title = (action.data['title'] as String?)?.trim() ?? '';
          if (title.isEmpty) return;
          final targetRaw = action.data['targetDate'] as String?;
          final target = targetRaw != null ? DateTime.tryParse(targetRaw) : null;
          final goal = Goal(
            id: const Uuid().v4(),
            title: title,
            description: action.data['description'] is String
                ? action.data['description'] as String
                : null,
            targetDate: target,
            createdAt: DateTime.now(),
          );
          await GoalService().add(goal);
          confirmation = l.aiCreatedGoal(title);
          break;

        case AIActionKind.updateTask:
          {
            final id = action.data['id'] as String?;
            if (id == null) return;
            final t = StorageService().tasks.get(id);
            if (t == null) {
              confirmation = l.aiNotFound;
              break;
            }
            if (action.data['title'] is String) {
              t.title = (action.data['title'] as String).trim();
            }
            if (action.data.containsKey('scheduledStart')) {
              final raw = action.data['scheduledStart'];
              t.scheduledStart =
                  raw is String ? DateTime.tryParse(raw) : null;
              t.reminderEnabled = t.scheduledStart != null || t.dueAt != null;
            }
            if (action.data['durationMinutes'] is int) {
              t.durationMinutes = action.data['durationMinutes'] as int;
            }
            if (action.data.containsKey('iconKey')) {
              final ik = action.data['iconKey'];
              if (ik is String && kIconKeys.contains(ik)) t.iconKey = ik;
            }
            if (action.data['colorValue'] is int) {
              t.colorValue = action.data['colorValue'] as int;
            }
            if (action.data['notes'] is String) {
              t.notes = (action.data['notes'] as String);
            }
            if (action.data['priority'] is int) {
              t.priority = action.data['priority'] as int;
            }
            if (action.data['recurrence'] is int) {
              t.recurrence = action.data['recurrence'] as int;
            }
            if (action.data['subtasks'] is List) {
              t.subtasks = _stringList(action.data['subtasks']);
            }
            if (action.data.containsKey('goalId')) {
              final g = action.data['goalId'];
              t.goalId = g is String ? g : null;
            }
            await TaskService().update(t);
            confirmation = l.aiUpdatedTask(t.title);
          }
          break;
        case AIActionKind.deleteTask:
          {
            final id = action.data['id'] as String?;
            if (id == null) return;
            final t = StorageService().tasks.get(id);
            final name = t?.title ?? '';
            if (t == null) {
              confirmation = l.aiNotFound;
              break;
            }
            await TaskService().delete(id);
            confirmation = l.aiDeletedTask(name);
          }
          break;
        case AIActionKind.toggleTask:
          {
            final id = action.data['id'] as String?;
            if (id == null) return;
            final t = StorageService().tasks.get(id);
            if (t == null) {
              confirmation = l.aiNotFound;
              break;
            }
            await TaskService().toggleComplete(id);
            confirmation = l.aiToggledTask(t.title);
          }
          break;

        case AIActionKind.updateEvent:
          {
            final id = action.data['id'] as String?;
            if (id == null) return;
            final e = StorageService().events.get(id);
            if (e == null) {
              confirmation = l.aiNotFound;
              break;
            }
            if (action.data['title'] is String) {
              e.title = (action.data['title'] as String).trim();
            }
            if (action.data['startAt'] is String) {
              final s = DateTime.tryParse(action.data['startAt'] as String);
              if (s != null) e.startAt = s;
            }
            if (action.data['endAt'] is String) {
              final en = DateTime.tryParse(action.data['endAt'] as String);
              if (en != null) e.endAt = en;
            }
            if (action.data.containsKey('location')) {
              final loc = action.data['location'];
              e.location = loc is String ? loc : null;
            }
            if (action.data['recurrence'] is int) {
              e.recurrence = action.data['recurrence'] as int;
            }
            await EventService().update(e);
            confirmation = l.aiUpdatedEvent(e.title);
          }
          break;
        case AIActionKind.deleteEvent:
          {
            final id = action.data['id'] as String?;
            if (id == null) return;
            final e = StorageService().events.get(id);
            final name = e?.title ?? '';
            if (e == null) {
              confirmation = l.aiNotFound;
              break;
            }
            await EventService().delete(id);
            confirmation = l.aiDeletedEvent(name);
          }
          break;

        case AIActionKind.updateHabit:
          {
            final id = action.data['id'] as String?;
            if (id == null) return;
            final h = StorageService().habits.get(id);
            if (h == null) {
              confirmation = l.aiNotFound;
              break;
            }
            if (action.data['name'] is String) {
              h.name = (action.data['name'] as String).trim();
            }
            if (action.data['frequencyType'] is int) {
              h.frequencyType = action.data['frequencyType'] as int;
            }
            if (action.data['weekdays'] is List) {
              h.weekdays = [
                for (final v in (action.data['weekdays'] as List))
                  if (v is int && v >= 1 && v <= 7) v
              ];
            }
            if (action.data['reminderHour'] is int) {
              h.reminderHour = action.data['reminderHour'] as int;
            }
            if (action.data['reminderMinute'] is int) {
              h.reminderMinute = action.data['reminderMinute'] as int;
            }
            await HabitService().update(h);
            confirmation = l.aiUpdatedHabit(h.name);
          }
          break;
        case AIActionKind.deleteHabit:
          {
            final id = action.data['id'] as String?;
            if (id == null) return;
            final h = StorageService().habits.get(id);
            final name = h?.name ?? '';
            if (h == null) {
              confirmation = l.aiNotFound;
              break;
            }
            await HabitService().delete(id);
            confirmation = l.aiDeletedHabit(name);
          }
          break;
        case AIActionKind.toggleHabit:
          {
            final id = action.data['id'] as String?;
            if (id == null) return;
            final h = StorageService().habits.get(id);
            if (h == null) {
              confirmation = l.aiNotFound;
              break;
            }
            DateTime date = DateTime.now();
            final dRaw = action.data['date'];
            if (dRaw is String) {
              final d = DateTime.tryParse(dRaw);
              if (d != null) date = d;
            }
            final done = action.data['done'] is bool
                ? action.data['done'] as bool
                : !HabitService().isDoneOn(id, date);
            if (done) {
              await HabitService().markDone(id, date);
            } else {
              await HabitService().unmarkDone(id, date);
            }
            confirmation = l.aiToggledHabit(h.name);
          }
          break;

        case AIActionKind.updateGoal:
          {
            final id = action.data['id'] as String?;
            if (id == null) return;
            final g = StorageService().goals.get(id);
            if (g == null) {
              confirmation = l.aiNotFound;
              break;
            }
            if (action.data['title'] is String) {
              g.title = (action.data['title'] as String).trim();
            }
            if (action.data.containsKey('description')) {
              final d = action.data['description'];
              g.description = d is String ? d : null;
            }
            if (action.data.containsKey('targetDate')) {
              final raw = action.data['targetDate'];
              g.targetDate =
                  raw is String ? DateTime.tryParse(raw) : null;
            }
            await GoalService().update(g);
            confirmation = l.aiUpdatedGoal(g.title);
          }
          break;
        case AIActionKind.deleteGoal:
          {
            final id = action.data['id'] as String?;
            if (id == null) return;
            final g = StorageService().goals.get(id);
            final name = g?.title ?? '';
            if (g == null) {
              confirmation = l.aiNotFound;
              break;
            }
            await GoalService().delete(id);
            confirmation = l.aiDeletedGoal(name);
          }
          break;
        case AIActionKind.archiveGoal:
          {
            final id = action.data['id'] as String?;
            if (id == null) return;
            final g = StorageService().goals.get(id);
            if (g == null) {
              confirmation = l.aiNotFound;
              break;
            }
            final archived = action.data['archived'] is bool
                ? action.data['archived'] as bool
                : true;
            await GoalService().archive(id, archived: archived);
            confirmation = l.aiArchivedGoal(g.title);
          }
          break;

        case AIActionKind.plan:
          {
            int goalsAdded = 0, habitsAdded = 0, tasksAdded = 0;
            String? firstGoalId = action.data['targetGoalId'] is String
                ? action.data['targetGoalId'] as String
                : null;
            final goalsRaw = action.data['goals'];
            if (goalsRaw is List) {
              for (final g in goalsRaw) {
                if (g is! Map<String, dynamic>) continue;
                final title = (g['title'] as String?)?.trim() ?? '';
                if (title.isEmpty) continue;
                final tgtRaw = g['targetDate'] as String?;
                final goalId = const Uuid().v4();
                firstGoalId ??= goalId;
                await GoalService().add(Goal(
                  id: goalId,
                  title: title,
                  description: g['description'] is String
                      ? g['description'] as String
                      : null,
                  targetDate: tgtRaw != null ? DateTime.tryParse(tgtRaw) : null,
                  createdAt: DateTime.now(),
                ));
                goalsAdded++;
              }
            }
            final habitsRaw = action.data['habits'];
            if (habitsRaw is List) {
              for (final h in habitsRaw) {
                if (h is! Map<String, dynamic>) continue;
                final name = (h['name'] as String?)?.trim() ?? '';
                if (name.isEmpty) continue;
                final weekdays = <int>[];
                if (h['weekdays'] is List) {
                  for (final v in (h['weekdays'] as List)) {
                    if (v is int && v >= 1 && v <= 7) weekdays.add(v);
                  }
                }
                await HabitService().add(Habit(
                  id: const Uuid().v4(),
                  name: name,
                  frequencyType:
                      h['frequencyType'] is int ? h['frequencyType'] as int : 0,
                  weekdays: weekdays,
                  reminderHour:
                      h['reminderHour'] is int ? h['reminderHour'] as int : 8,
                  reminderMinute: h['reminderMinute'] is int
                      ? h['reminderMinute'] as int
                      : 0,
                  createdAt: DateTime.now(),
                ));
                habitsAdded++;
              }
            }
            final tasksRaw = action.data['tasks'];
            if (tasksRaw is List) {
              for (final t in tasksRaw) {
                if (t is! Map<String, dynamic>) continue;
                final title = (t['title'] as String?)?.trim() ?? '';
                if (title.isEmpty) continue;
                final sRaw = t['scheduledStart'] as String?;
                final start = sRaw != null ? DateTime.tryParse(sRaw) : null;
                await TaskService().add(Task(
                  id: const Uuid().v4(),
                  title: title,
                  createdAt: DateTime.now(),
                  scheduledStart: start,
                  durationMinutes: t['durationMinutes'] is int
                      ? t['durationMinutes'] as int
                      : (start != null ? 30 : null),
                  iconKey: kIconKeys.contains(t['iconKey'])
                      ? t['iconKey'] as String
                      : null,
                  colorValue: kPaletteColors.first,
                  notes: t['notes'] is String ? t['notes'] as String : null,
                  subtasks: _stringList(t['subtasks']),
                  reminderEnabled: start != null,
                  reminderLeadMinutes: 10,
                  goalId: firstGoalId,
                ));
                tasksAdded++;
              }
            }
            confirmation =
                l.aiCreatedPlan(goalsAdded, habitsAdded, tasksAdded);
          }
          break;

        default:
          return;
      }
    } catch (e) {
      debugPrint('AI action execution failed: $e');
      return;
    }
    if (confirmation.isEmpty || !mounted) return;
    setState(() {
      _history.add(ConversationTurn.system(confirmation));
    });
    await AIChatService().add('system', confirmation);
    _scrollToBottom();
  }

  String _buildStateSnapshot() {
    String iso(DateTime d) => d.toIso8601String();
    final now = DateTime.now();
    final inbox = TaskService().inbox();
    final todaysTasks = TaskService().scheduledForDay(now);
    final todaysEvents = EventService().eventsForDay(now);
    // Habits are no longer shown in the app; exclude from state snapshot.
    final goals = GoalService().all();

    final data = {
      'now': iso(now),
      'inbox': inbox
          .map((t) => {
                'id': t.id,
                'title': t.title,
                'priority': t.priority,
                if (t.notes != null) 'notes': t.notes,
              })
          .toList(),
      'todayScheduled': todaysTasks
          .where((t) => t.scheduledStart != null)
          .map((t) => {
                'id': t.id,
                'title': t.title,
                'start': iso(t.scheduledStart!),
                'durationMinutes': t.durationMinutes ?? 30,
                if (t.completed) 'completed': true,
              })
          .toList(),
      'todayEvents': todaysEvents
          .map((e) => {
                'id': e.id,
                'title': e.title,
                'start': iso(e.startAt),
                'end': iso(e.endAt),
                if (e.location != null) 'location': e.location,
              })
          .toList(),
      'goals': goals
          .map((g) => {
                'id': g.id,
                'title': g.title,
                if (g.description != null) 'description': g.description,
                if (g.targetDate != null) 'targetDate': iso(g.targetDate!),
              })
          .toList(),
    };
    return const JsonEncoder.withIndent('  ').convert(data);
  }

  List<String>? _stringList(dynamic raw) {
    if (raw is! List) return null;
    final list = <String>[];
    for (final v in raw) {
      if (v is String && v.trim().isNotEmpty) list.add('[ ] ${v.trim()}');
    }
    return list.isEmpty ? null : list;
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final List<String> suggestions = [
      l.aiSuggestPlanDay,
      l.aiSuggestItinerary,
      l.aiSuggestBrainstorm,
    ];

    return Scaffold(
      appBar: AppBar(
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
        title: ValueListenableBuilder<String?>(
          valueListenable: AIChatService().activeSessionId,
          builder: (context, _, __) => Text(
            AIChatService().active()?.title ?? l.aiGreeting,
            style: const TextStyle(fontSize: 16),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_comment_outlined),
            tooltip: l.newChat,
            onPressed: () async {
              await AIChatService().newSession();
            },
          ),
          IconButton(
            icon: const Icon(Icons.tune),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const AISettingsScreen()),
            ),
          ),
        ],
      ),
      drawer: _SessionsDrawer(),
      body: ValueListenableBuilder<bool>(
        valueListenable: AIConfig().enabled,
        builder: (context, enabled, _) {
          if (!enabled) return _disabledState(context, cs, l);
          return Column(
            children: [
              Expanded(
                child: _history.isEmpty
                    ? _welcome(context, cs, l, suggestions)
                    : ListView.builder(
                        controller: _scroll,
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                        itemCount: _history.length + (_loading ? 1 : 0),
                        itemBuilder: (ctx, i) {
                          if (i == _history.length) return _TypingDots();
                          return _Bubble(turn: _history[i]);
                        },
                      ),
              ),
              _quickReplies(l, cs),
              _convertToPlanBar(l, cs),
              _inputBar(l, cs),
            ],
          );
        },
      ),
    );
  }

  Widget _welcome(BuildContext context, ColorScheme cs, AppLocalizations l,
      List<String> suggestions) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l.aiGreeting,
            style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                color: cs.primary),
          ),
          const SizedBox(height: 4),
          Text(
            l.aiGreetingQuestion,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 24),
          Text(
            l.aiSuggestionsLabel,
            style: TextStyle(
                color: cs.onSurfaceVariant,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.1),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: suggestions
                .map((s) => ActionChip(
                      label: Text(s),
                      backgroundColor: cs.surface,
                      side: BorderSide.none,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18)),
                      onPressed: () => _send(s),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _disabledState(BuildContext context, ColorScheme cs, AppLocalizations l) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.auto_awesome, color: cs.primary, size: 52),
            const SizedBox(height: 16),
            Text(l.aiDisabledHint,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AISettingsScreen()),
              ),
              child: Text(l.aiAssistant),
            ),
          ],
        ),
      ),
    );
  }

  final Set<String> _multiSelected = {};

  Widget _quickReplies(AppLocalizations l, ColorScheme cs) {
    if (_loading || _history.isEmpty) return const SizedBox.shrink();
    final last = _history.last;
    if (last.role != 'assistant' || last.options.isEmpty) {
      return const SizedBox.shrink();
    }
    if (last.multiselect) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: last.options.map((o) {
                final selected = _multiSelected.contains(o.label);
                return FilterChip(
                  label: Text(o.label),
                  selected: selected,
                  onSelected: (v) {
                    setState(() {
                      if (v) {
                        _multiSelected.add(o.label);
                      } else {
                        _multiSelected.remove(o.label);
                      }
                    });
                  },
                  showCheckmark: true,
                  selectedColor: cs.primary.withValues(alpha: 0.25),
                  backgroundColor:
                      cs.primaryContainer.withValues(alpha: 0.4),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                      side: BorderSide.none),
                );
              }).toList(),
            ),
            const SizedBox(height: 8),
            FilledButton.icon(
              icon: const Icon(Icons.check, size: 16),
              label: Text(l.submit),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 10),
                backgroundColor: cs.primary,
              ),
              onPressed: _multiSelected.isEmpty
                  ? null
                  : () {
                      final joined = _multiSelected.join(', ');
                      setState(_multiSelected.clear);
                      _send(joined);
                    },
            ),
          ],
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 4),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: last.options
              .map((o) => ActionChip(
                    label: Text(o.label),
                    backgroundColor: cs.primaryContainer.withValues(alpha: 0.5),
                    side: BorderSide.none,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18)),
                    avatar: o.picker == null
                        ? null
                        : Icon(
                            o.picker == 'date'
                                ? Icons.calendar_today
                                : o.picker == 'time'
                                    ? Icons.access_time
                                    : Icons.timer_outlined,
                            size: 14,
                            color: cs.primary,
                          ),
                    onPressed: () => _onOptionTap(o),
                  ))
              .toList(),
        ),
      ),
    );
  }

  Future<void> _onOptionTap(AIQuickOption option) async {
    if (option.picker == null) {
      await _send(option.label);
      return;
    }
    switch (option.picker) {
      case 'date':
        final picked = await showDatePicker(
          context: context,
          initialDate: DateTime.now(),
          firstDate: DateTime.now().subtract(const Duration(days: 365)),
          lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
        );
        if (picked != null) {
          await _send(
              '${picked.year}-${picked.month.toString().padLeft(2, "0")}-${picked.day.toString().padLeft(2, "0")}');
        }
        break;
      case 'time':
        final picked = await showTimePicker(
          context: context,
          initialTime: TimeOfDay.now(),
        );
        if (picked != null) {
          await _send(
              '${picked.hour.toString().padLeft(2, "0")}:${picked.minute.toString().padLeft(2, "0")}');
        }
        break;
      case 'duration':
        final picked = await _pickDuration();
        if (picked != null) await _send('$picked min');
        break;
    }
  }

  Future<int?> _pickDuration() async {
    final l = AppLocalizations.of(context)!;
    return showModalBottomSheet<int>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: const [15, 30, 45, 60, 90, 120, 180]
                .map((m) => ActionChip(
                      label: Text('$m ${l.duration.toLowerCase()}'),
                      onPressed: () => Navigator.pop(ctx, m),
                    ))
                .toList(),
          ),
        ),
      ),
    );
  }

  Widget _convertToPlanBar(AppLocalizations l, ColorScheme cs) {
    if (_history.length < 2) return const SizedBox.shrink();
    final pendingState = PendingPlanService().state.value;
    final isGenerating = _loading || pendingState == 'generating';
    final label = pendingState == 'generating'
        ? l.planGenerating
        : l.convertChatToPlan;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 4),
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          icon: isGenerating
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : Icon(Icons.playlist_add_check, color: cs.primary),
          label: Text(label),
          style: OutlinedButton.styleFrom(
            foregroundColor: cs.primary,
            side: BorderSide(color: cs.primary.withValues(alpha: 0.5)),
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
          onPressed: isGenerating ? null : _convertChatToPlan,
        ),
      ),
    );
  }

  Future<void> _convertChatToPlan() async {
    final l = AppLocalizations.of(context)!;
    // Mark pending so the result survives if the user backgrounds the app
    // while the local LLM is chewing.
    await PendingPlanService().markGenerating(
        sessionId: AIChatService().activeSessionId.value);
    setState(() => _loading = true);
    final action = await AIService().extractPlan(_history);
    setState(() => _loading = false);
    if (action == null) {
      await PendingPlanService().clear();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.aiUnavailable)),
      );
      return;
    }
    await PendingPlanService().saveResult(action);
    // Fire notification if backgrounded; _onPendingStateChanged will also pick
    // this up and present the sheet on next resume. _presenting flag below
    // prevents a double-open race.
    if (!mounted) {
      final taskCount = (action.data['tasks'] is List)
          ? (action.data['tasks'] as List).length
          : 0;
      await NotificationService().notifyPlanReady(taskCount: taskCount);
    }
    // The state listener (_onPendingStateChanged) will open the sheet. Do not
    // call _presentPendingPlan here directly — that caused duplicate commits.
  }

  /// Show the review sheet for whatever result is currently stored. Called on
  /// screen init and on app resume, so a plan that finished in the background
  /// auto-opens when the user returns. Guarded by [_presenting] to prevent
  /// concurrent dialogs when state-changes + lifecycle events race.
  Future<void> _presentPendingPlan() async {
    if (_presenting) return;
    if (PendingPlanService().state.value != 'ready') return;
    final action = await PendingPlanService().readResult();
    if (action == null) {
      await PendingPlanService().clear();
      return;
    }
    if (!mounted) return;
    _presenting = true;
    try {
      // Clear the pending state FIRST so listeners can't retrigger while the
      // sheet is open.
      await PendingPlanService().clear();
      if (!mounted) return;
      final committed = await showPlanPreviewSheet(context, action);
      if (committed != null) {
        await _executeAction(committed);
      }
    } finally {
      _presenting = false;
    }
  }

  Widget _inputBar(AppLocalizations l, ColorScheme cs) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 6, 12, 10),
        child: Container(
          decoration: BoxDecoration(
            color: cs.primaryContainer.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(28),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: Row(
            children: [
              ValueListenableBuilder<bool>(
                valueListenable: SpeechService().listening,
                builder: (context, listening, _) => IconButton(
                  icon: Icon(
                    listening ? Icons.stop_circle : Icons.mic,
                    color: listening ? cs.error : cs.primary,
                  ),
                  tooltip: listening ? l.stopListening : l.startListening,
                  onPressed: _loading ? null : _toggleListening,
                ),
              ),
              Expanded(
                child: TextField(
                  controller: _input,
                  enabled: !_loading,
                  decoration: InputDecoration(
                    hintText: l.aiInputHint,
                    border: InputBorder.none,
                    filled: false,
                    isDense: true,
                  ),
                  onSubmitted: _send,
                ),
              ),
              IconButton(
                icon: Icon(_loading ? Icons.hourglass_top : Icons.send,
                    color: cs.primary),
                onPressed: _loading ? null : () => _send(_input.text),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _toggleListening() async {
    final l = AppLocalizations.of(context)!;
    if (SpeechService().listening.value) {
      await SpeechService().stop();
      return;
    }
    final lang = Localizations.localeOf(context).languageCode;
    final localeId = lang == 'ar' ? 'ar-SA' : 'en-US';
    final ok = await SpeechService().start(
      localeId: localeId,
      onPartial: (p) {
        if (!mounted) return;
        _input.text = p;
        _input.selection =
            TextSelection.collapsed(offset: _input.text.length);
      },
      onFinal: (f) {
        if (!mounted) return;
        _input.text = f;
        _input.selection =
            TextSelection.collapsed(offset: _input.text.length);
      },
    );
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.speechUnavailable)),
      );
    }
  }
}

class _Bubble extends StatelessWidget {
  final ConversationTurn turn;
  const _Bubble({required this.turn});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isUser = turn.role == 'user';
    final isSystem = turn.role == 'system';
    if (isSystem) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: cs.primaryContainer.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle, color: cs.primary, size: 14),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(turn.text,
                      style: TextStyle(
                          color: cs.onSurface,
                          fontSize: 13,
                          fontWeight: FontWeight.w500)),
                ),
              ],
            ),
          ),
        ),
      );
    }
    final fg = isUser ? Colors.white : cs.onSurface;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: EdgeInsets.symmetric(
            horizontal: 14, vertical: isUser ? 10 : 12),
        constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width *
                (isUser ? 0.78 : 0.94)),
        decoration: BoxDecoration(
          color: isUser ? cs.primary : cs.surface,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isUser ? 16 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 16),
          ),
        ),
        child: isUser
            ? Text(
                turn.text,
                style: TextStyle(fontSize: 15, color: fg),
              )
            : MarkdownBody(
                data: turn.text,
                selectable: true,
                onTapLink: (text, href, title) async {
                  if (href == null) return;
                  final uri = Uri.tryParse(href);
                  if (uri == null) return;
                  if (uri.scheme != 'http' && uri.scheme != 'https') return;
                  if (!context.mounted) return;
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Open external link?'),
                      content: Text(uri.toString()),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text('Open'),
                        ),
                      ],
                    ),
                  );
                  if (confirmed != true) return;
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                },
                styleSheet: MarkdownStyleSheet(
                  p: TextStyle(fontSize: 14, color: fg, height: 1.4),
                  h1: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: fg),
                  h2: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: fg),
                  h3: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: fg),
                  listBullet: TextStyle(fontSize: 14, color: fg),
                  strong: TextStyle(
                      fontWeight: FontWeight.w700, color: fg),
                  code: TextStyle(
                      fontFamily: 'monospace',
                      backgroundColor:
                          cs.surfaceContainerHighest.withValues(alpha: 0.5),
                      color: fg),
                  a: TextStyle(
                      color: cs.primary,
                      decoration: TextDecoration.underline),
                  blockquote: TextStyle(
                      color: cs.onSurfaceVariant,
                      fontStyle: FontStyle.italic),
                  tableBody: TextStyle(fontSize: 13, color: fg),
                  tableHead: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: fg),
                ),
              ),
      ),
    );
  }
}

class _TypingDots extends StatefulWidget {
  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(seconds: 1))
        ..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, _) {
            final phase = _c.value;
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (i) {
                final t = (phase + i * 0.15) % 1.0;
                final opacity = 0.3 + 0.7 * (t < 0.5 ? t * 2 : (1 - t) * 2);
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Opacity(
                    opacity: opacity,
                    child: Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: cs.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                );
              }),
            );
          },
        ),
      ),
    );
  }
}

class _SessionsDrawer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Row(
                children: [
                  Icon(Icons.auto_awesome, color: cs.primary),
                  const SizedBox(width: 10),
                  Text(l.aiAssistant,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w700)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () async {
                    await AIChatService().newSession();
                    if (context.mounted) Navigator.of(context).pop();
                  },
                  icon: const Icon(Icons.add),
                  label: Text(l.newChat),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ValueListenableBuilder<Box<ChatSession>>(
                valueListenable: AIChatService().sessionsListenable(),
                builder: (context, _, __) {
                  final items = AIChatService().sessions();
                  final activeId = AIChatService().activeSessionId.value;
                  if (items.isEmpty) {
                    return const SizedBox.shrink();
                  }
                  return ListView.builder(
                    itemCount: items.length,
                    itemBuilder: (context, i) {
                      final s = items[i];
                      final isActive = s.id == activeId;
                      return ListTile(
                        leading: Icon(
                          isActive ? Icons.chat_bubble : Icons.chat_bubble_outline,
                          color: isActive ? cs.primary : cs.onSurfaceVariant,
                        ),
                        title: Text(
                          s.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontWeight:
                                  isActive ? FontWeight.w700 : FontWeight.w500),
                        ),
                        selected: isActive,
                        selectedTileColor:
                            cs.primaryContainer.withValues(alpha: 0.4),
                        onTap: () async {
                          await AIChatService().setActive(s.id);
                          if (context.mounted) Navigator.of(context).pop();
                        },
                        trailing: PopupMenuButton<String>(
                          icon: const Icon(Icons.more_horiz),
                          onSelected: (v) async {
                            if (v == 'rename') {
                              final controller =
                                  TextEditingController(text: s.title);
                              final newTitle = await showDialog<String>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: Text(l.renameChat),
                                  content: TextField(
                                    controller: controller,
                                    autofocus: true,
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(ctx, null),
                                      child: Text(l.cancel),
                                    ),
                                    FilledButton(
                                      onPressed: () => Navigator.pop(
                                          ctx, controller.text),
                                      child: Text(l.save),
                                    ),
                                  ],
                                ),
                              );
                              if (newTitle != null && newTitle.trim().isNotEmpty) {
                                await AIChatService()
                                    .renameSession(s.id, newTitle.trim());
                              }
                            } else if (v == 'delete') {
                              final ok = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: Text(l.confirmDelete),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(ctx, false),
                                      child: Text(l.no),
                                    ),
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(ctx, true),
                                      child: Text(l.yes),
                                    ),
                                  ],
                                ),
                              );
                              if (ok == true) {
                                await AIChatService().deleteSession(s.id);
                              }
                            }
                          },
                          itemBuilder: (_) => [
                            PopupMenuItem(
                                value: 'rename', child: Text(l.renameChat)),
                            PopupMenuItem(
                                value: 'delete', child: Text(l.delete)),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

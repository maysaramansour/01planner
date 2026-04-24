import 'package:flutter/material.dart';
import 'package:dabab_planner/l10n/app_localizations.dart';
import 'package:intl/intl.dart' as intl;

import '../services/ai_service.dart';
import '../services/scheduling_service.dart';
import 'task_icons.dart';

class DraftGoal {
  bool enabled;
  String title;
  String? description;
  DateTime? targetDate;
  DraftGoal({
    required this.title,
    this.description,
    this.targetDate,
    this.enabled = true,
  });
}

class DraftHabit {
  bool enabled;
  String name;
  int frequencyType;
  List<int> weekdays;
  int reminderHour;
  int reminderMinute;
  DraftHabit({
    required this.name,
    this.frequencyType = 0,
    List<int>? weekdays,
    this.reminderHour = 8,
    this.reminderMinute = 0,
    this.enabled = true,
  }) : weekdays = weekdays ?? const [];
}

class DraftTask {
  bool enabled;
  String title;
  DateTime? scheduledStart;
  int? durationMinutes;
  String? iconKey;
  String? notes;
  List<String> subtasks;
  DraftTask({
    required this.title,
    this.scheduledStart,
    this.durationMinutes,
    this.iconKey,
    this.notes,
    List<String>? subtasks,
    this.enabled = true,
  }) : subtasks = subtasks ?? const [];
}

class _Drafts {
  final List<DraftGoal> goals;
  final List<DraftHabit> habits;
  final List<DraftTask> tasks;
  _Drafts(this.goals, this.habits, this.tasks);

  factory _Drafts.fromAction(AIAction action) {
    List<DraftGoal> goals = [];
    List<DraftHabit> habits = [];
    List<DraftTask> tasks = [];

    final gRaw = action.data['goals'];
    if (gRaw is List) {
      for (final g in gRaw) {
        if (g is! Map<String, dynamic>) continue;
        final title = (g['title'] as String?)?.trim() ?? '';
        if (title.isEmpty) continue;
        final tgt = g['targetDate'];
        goals.add(DraftGoal(
          title: title,
          description: g['description'] is String ? g['description'] as String : null,
          targetDate: tgt is String ? DateTime.tryParse(tgt) : null,
        ));
      }
    }

    final hRaw = action.data['habits'];
    if (hRaw is List) {
      for (final h in hRaw) {
        if (h is! Map<String, dynamic>) continue;
        final name = (h['name'] as String?)?.trim() ?? '';
        if (name.isEmpty) continue;
        final weekdays = <int>[];
        if (h['weekdays'] is List) {
          for (final v in (h['weekdays'] as List)) {
            if (v is int && v >= 1 && v <= 7) weekdays.add(v);
          }
        }
        habits.add(DraftHabit(
          name: name,
          frequencyType: h['frequencyType'] is int ? h['frequencyType'] as int : 0,
          weekdays: weekdays,
          reminderHour: h['reminderHour'] is int ? h['reminderHour'] as int : 8,
          reminderMinute: h['reminderMinute'] is int ? h['reminderMinute'] as int : 0,
        ));
      }
    }

    final tRaw = action.data['tasks'];
    if (tRaw is List) {
      for (final t in tRaw) {
        if (t is! Map<String, dynamic>) continue;
        final title = (t['title'] as String?)?.trim() ?? '';
        if (title.isEmpty) continue;
        final sRaw = t['scheduledStart'];
        final subtasks = <String>[];
        if (t['subtasks'] is List) {
          for (final v in (t['subtasks'] as List)) {
            if (v is String && v.trim().isNotEmpty) subtasks.add(v);
          }
        }
        tasks.add(DraftTask(
          title: title,
          scheduledStart: sRaw is String ? DateTime.tryParse(sRaw) : null,
          durationMinutes: t['durationMinutes'] is int ? t['durationMinutes'] as int : null,
          iconKey: t['iconKey'] is String ? t['iconKey'] as String : null,
          notes: t['notes'] is String ? t['notes'] as String : null,
          subtasks: subtasks,
        ));
      }
    }

    return _Drafts(goals, habits, tasks);
  }

  AIAction toAction() {
    String iso(DateTime d) => d.toIso8601String();
    final data = <String, dynamic>{
      'goals': [
        for (final g in goals)
          if (g.enabled)
            {
              'title': g.title,
              if (g.description != null) 'description': g.description,
              if (g.targetDate != null) 'targetDate': iso(g.targetDate!),
            }
      ],
      'habits': [
        for (final h in habits)
          if (h.enabled)
            {
              'name': h.name,
              'frequencyType': h.frequencyType,
              if (h.frequencyType == 1) 'weekdays': h.weekdays,
              'reminderHour': h.reminderHour,
              'reminderMinute': h.reminderMinute,
            }
      ],
      'tasks': [
        for (final t in tasks)
          if (t.enabled)
            {
              'title': t.title,
              if (t.scheduledStart != null) 'scheduledStart': iso(t.scheduledStart!),
              if (t.durationMinutes != null) 'durationMinutes': t.durationMinutes,
              if (t.iconKey != null) 'iconKey': t.iconKey,
              if (t.notes != null) 'notes': t.notes,
              if (t.subtasks.isNotEmpty) 'subtasks': t.subtasks,
            }
      ],
    };
    return AIAction(AIActionKind.plan, data);
  }

  int get enabledCount =>
      goals.where((g) => g.enabled).length +
      habits.where((h) => h.enabled).length +
      tasks.where((t) => t.enabled).length;
}

Future<AIAction?> showPlanPreviewSheet(
    BuildContext context, AIAction action) {
  return showModalBottomSheet<AIAction>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) => FractionallySizedBox(
      heightFactor: 0.95,
      child: _PlanPreviewSheet(action: action),
    ),
  );
}

class _PlanPreviewSheet extends StatefulWidget {
  final AIAction action;
  const _PlanPreviewSheet({required this.action});

  @override
  State<_PlanPreviewSheet> createState() => _PlanPreviewSheetState();
}

class _PlanPreviewSheetState extends State<_PlanPreviewSheet> {
  late final _Drafts _drafts;

  @override
  void initState() {
    super.initState();
    _drafts = _Drafts.fromAction(widget.action);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final enabledCount = _drafts.enabledCount;

    return Column(
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l.reviewPlan,
                  style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  _countChip(cs, l.planGoalsCount(_drafts.goals.length)),
                  _countChip(cs, l.planHabitsCount(_drafts.habits.length)),
                  _countChip(cs, l.planTasksCount(_drafts.tasks.length)),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: (_drafts.goals.isEmpty &&
                  _drafts.habits.isEmpty &&
                  _drafts.tasks.isEmpty)
              ? Center(
                  child: Text(l.emptyPlan,
                      style: TextStyle(color: cs.onSurfaceVariant)),
                )
              : ListView(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
                  children: [
                    if (_drafts.goals.isNotEmpty) ...[
                      _section(cs, l.goals),
                      for (var i = 0; i < _drafts.goals.length; i++)
                        _goalRow(_drafts.goals[i], cs, l),
                    ],
                    if (_drafts.habits.isNotEmpty) ...[
                      _section(cs, l.habits),
                      for (var i = 0; i < _drafts.habits.length; i++)
                        _habitRow(_drafts.habits[i], cs, l),
                    ],
                    if (_drafts.tasks.isNotEmpty) ...[
                      _section(cs, l.tasksToday),
                      for (var i = 0; i < _drafts.tasks.length; i++)
                        _taskRow(_drafts.tasks[i], cs, l),
                    ],
                  ],
                ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(null),
                    child: Text(l.cancel),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: FilledButton.icon(
                    onPressed: enabledCount == 0
                        ? null
                        : () =>
                            Navigator.of(context).pop(_drafts.toAction()),
                    icon: const Icon(Icons.check),
                    label: Text(l.commitItems(enabledCount)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _countChip(ColorScheme cs, String label) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: cs.primaryContainer.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(label,
            style: TextStyle(
                color: cs.onSurface,
                fontSize: 12,
                fontWeight: FontWeight.w600)),
      );

  Widget _section(ColorScheme cs, String label) => Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
        child: Text(
          label.toUpperCase(),
          style: TextStyle(
              color: cs.onSurfaceVariant,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.1),
        ),
      );

  Widget _card({required Widget child, required bool enabled}) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      color: enabled ? null : Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: child,
      ),
    );
  }

  Widget _goalRow(DraftGoal g, ColorScheme cs, AppLocalizations l) {
    final lang = Localizations.localeOf(context).languageCode;
    final tgt = g.targetDate == null
        ? l.targetDate
        : intl.DateFormat.yMMMd(lang).format(g.targetDate!);
    return _card(
      enabled: g.enabled,
      child: Row(
        children: [
          Checkbox(
            value: g.enabled,
            onChanged: (v) => setState(() => g.enabled = v ?? true),
          ),
          Icon(Icons.flag_outlined, color: cs.tertiary, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(g.title,
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w600)),
                if (g.description != null && g.description!.isNotEmpty)
                  Text(g.description!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          color: cs.onSurfaceVariant, fontSize: 12)),
              ],
            ),
          ),
          _editChip(
            icon: Icons.calendar_today_outlined,
            label: tgt,
            cs: cs,
            onTap: () async {
              final d = await showDatePicker(
                context: context,
                initialDate: g.targetDate ?? DateTime.now().add(const Duration(days: 90)),
                firstDate: DateTime.now().subtract(const Duration(days: 30)),
                lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
              );
              if (d != null) setState(() => g.targetDate = d);
            },
          ),
        ],
      ),
    );
  }

  Widget _habitRow(DraftHabit h, ColorScheme cs, AppLocalizations l) {
    final time =
        '${h.reminderHour.toString().padLeft(2, '0')}:${h.reminderMinute.toString().padLeft(2, '0')}';
    final freqLabel = h.frequencyType == 0
        ? l.frequencyDaily
        : (h.weekdays.isEmpty ? l.frequencySpecificDays : _weekdaysLabel(h.weekdays, l));
    return _card(
      enabled: h.enabled,
      child: Row(
        children: [
          Checkbox(
            value: h.enabled,
            onChanged: (v) => setState(() => h.enabled = v ?? true),
          ),
          Icon(Icons.repeat, color: cs.secondary, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(h.name,
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w600)),
                Text(freqLabel,
                    style: TextStyle(
                        color: cs.onSurfaceVariant, fontSize: 12)),
              ],
            ),
          ),
          _editChip(
            icon: Icons.access_time,
            label: time,
            cs: cs,
            onTap: () async {
              final t = await showTimePicker(
                context: context,
                initialTime: TimeOfDay(hour: h.reminderHour, minute: h.reminderMinute),
              );
              if (t != null) {
                setState(() {
                  h.reminderHour = t.hour;
                  h.reminderMinute = t.minute;
                });
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _taskRow(DraftTask t, ColorScheme cs, AppLocalizations l) {
    final lang = Localizations.localeOf(context).languageCode;
    final when = t.scheduledStart == null
        ? l.inbox
        : intl.DateFormat.MMMd(lang).add_jm().format(t.scheduledStart!);
    final conflicts = t.scheduledStart == null || !t.enabled
        ? const []
        : SchedulingService().conflictsFor(
            start: t.scheduledStart!,
            durationMinutes: t.durationMinutes ?? 30,
          );
    return _card(
      enabled: t.enabled,
      child: Column(
        children: [
          Row(
            children: [
              Checkbox(
                value: t.enabled,
                onChanged: (v) => setState(() => t.enabled = v ?? true),
              ),
              Icon(TaskIcons.iconFor(t.iconKey), color: cs.primary, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(t.title,
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w600)),
              ),
              if (conflicts.isNotEmpty)
                Tooltip(
                  message: l.conflictsWith(conflicts.length),
                  child: Icon(Icons.warning_amber_rounded,
                      color: cs.error, size: 18),
                ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(left: 48, top: 4, bottom: 4),
            child: Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                _editChip(
                  icon: Icons.calendar_today_outlined,
                  label: when,
                  cs: cs,
                  onTap: () async {
                    final d = await showDatePicker(
                      context: context,
                      initialDate: t.scheduledStart ?? DateTime.now(),
                      firstDate: DateTime.now().subtract(const Duration(days: 1)),
                      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
                    );
                    if (d == null || !mounted) return;
                    final tm = await showTimePicker(
                      context: context,
                      initialTime: t.scheduledStart != null
                          ? TimeOfDay.fromDateTime(t.scheduledStart!)
                          : const TimeOfDay(hour: 19, minute: 0),
                    );
                    if (tm != null) {
                      setState(() {
                        t.scheduledStart =
                            DateTime(d.year, d.month, d.day, tm.hour, tm.minute);
                      });
                    }
                  },
                ),
                _durationChip(t, cs, l),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _editChip({
    required IconData icon,
    required String label,
    required ColorScheme cs,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: cs.onSurfaceVariant),
            const SizedBox(width: 4),
            Text(label,
                style: TextStyle(
                    fontSize: 12, color: cs.onSurface, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  Widget _durationChip(DraftTask t, ColorScheme cs, AppLocalizations l) {
    const options = [15, 30, 45, 60, 90, 120, 180];
    final current = options.contains(t.durationMinutes) ? t.durationMinutes : (t.durationMinutes ?? 30);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
      ),
      child: DropdownButton<int>(
        value: options.contains(current) ? current : 30,
        underline: const SizedBox.shrink(),
        isDense: true,
        icon: Icon(Icons.timer_outlined, size: 14, color: cs.onSurfaceVariant),
        items: [
          for (final m in options)
            DropdownMenuItem(
                value: m,
                child: Text('$m ${l.duration.toLowerCase()}',
                    style: const TextStyle(fontSize: 12))),
        ],
        onChanged: (v) => setState(() => t.durationMinutes = v),
      ),
    );
  }

  String _weekdaysLabel(List<int> days, AppLocalizations l) {
    final names = {
      1: l.monday,
      2: l.tuesday,
      3: l.wednesday,
      4: l.thursday,
      5: l.friday,
      6: l.saturday,
      7: l.sunday,
    };
    return days.map((d) => names[d] ?? '').where((s) => s.isNotEmpty).join(' · ');
  }
}

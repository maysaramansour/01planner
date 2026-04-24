import 'package:flutter/material.dart';
import 'package:one_planner/l10n/app_localizations.dart';
import 'package:intl/intl.dart' as intl;
import 'package:uuid/uuid.dart';

import '../models/task.dart';
import '../services/goal_service.dart';
import '../services/scheduling_service.dart';
import '../services/task_service.dart';
import '../widgets/icon_picker_sheet.dart';
import '../widgets/subtask_editor.dart';
import '../widgets/task_icons.dart';

enum _ConflictChoice { cancel, saveAnyway, moveToNextFree }

class TaskEditScreen extends StatefulWidget {
  final Task? existing;
  final String? prefillGoalId;
  const TaskEditScreen({super.key, this.existing, this.prefillGoalId});

  @override
  State<TaskEditScreen> createState() => _TaskEditScreenState();
}

class _TaskEditScreenState extends State<TaskEditScreen> {
  late final TextEditingController _title;
  late final TextEditingController _description;
  late final TextEditingController _notes;
  DateTime? _dueAt;
  DateTime? _scheduledStart;
  int? _durationMinutes;
  String? _iconKey;
  int? _colorValue;
  List<String> _subtasks = const [];
  int _priority = 1;
  bool _reminderEnabled = false;
  int _leadMinutes = 15;
  String? _goalId;
  int _recurrence = 0;

  static const _durationOptions = [15, 30, 45, 60, 90, 120, 180];

  @override
  void initState() {
    super.initState();
    final t = widget.existing;
    _title = TextEditingController(text: t?.title ?? '');
    _description = TextEditingController(text: t?.description ?? '');
    _notes = TextEditingController(text: t?.notes ?? '');
    _dueAt = t?.dueAt;
    _scheduledStart = t?.scheduledStart;
    _durationMinutes = t?.durationMinutes;
    _iconKey = t?.iconKey;
    _colorValue = t?.colorValue;
    _subtasks = List<String>.from(t?.subtasks ?? const []);
    _priority = t?.priority ?? 1;
    _reminderEnabled = t?.reminderEnabled ?? false;
    _leadMinutes = t?.reminderLeadMinutes ?? 15;
    _goalId = t?.goalId ?? widget.prefillGoalId;
    _recurrence = t?.recurrence ?? 0;
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _pickDueDateTime() async {
    final lang = Localizations.localeOf(context).languageCode;
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _dueAt ?? now,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now.add(const Duration(days: 365 * 5)),
      locale: Locale(lang),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_dueAt ?? now),
    );
    if (time == null) return;
    setState(() {
      _dueAt = DateTime(
          date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  Future<void> _pickScheduledStart() async {
    final lang = Localizations.localeOf(context).languageCode;
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _scheduledStart ?? now,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now.add(const Duration(days: 365 * 5)),
      locale: Locale(lang),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_scheduledStart ?? now),
    );
    if (time == null) return;
    setState(() {
      _scheduledStart = DateTime(
          date.year, date.month, date.day, time.hour, time.minute);
      _durationMinutes ??= 30;
    });
  }

  Future<void> _pickIconColor() async {
    final pick = await showIconPickerSheet(
      context,
      initialIconKey: _iconKey,
      initialColorValue: _colorValue,
    );
    if (pick == null) return;
    setState(() {
      _iconKey = pick.iconKey;
      _colorValue = pick.colorValue;
    });
  }

  Future<void> _save() async {
    final l = AppLocalizations.of(context)!;
    if (_title.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.title)),
      );
      return;
    }

    // Conflict check: only when task is actually scheduled.
    if (_scheduledStart != null) {
      final duration = _durationMinutes ?? 30;
      final conflicts = SchedulingService().conflictsFor(
        start: _scheduledStart!,
        durationMinutes: duration,
        excludeTaskId: widget.existing?.id,
      );
      if (conflicts.isNotEmpty) {
        final resolution = await _showConflictDialog(conflicts, duration);
        if (resolution == _ConflictChoice.cancel) return;
        if (resolution == _ConflictChoice.moveToNextFree) {
          final next = SchedulingService().nextFreeSlot(
            after: _scheduledStart!,
            durationMinutes: duration,
            excludeTaskId: widget.existing?.id,
          );
          if (next == null) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(l.noFreeSlotFound)),
              );
            }
            return;
          }
          _scheduledStart = next;
        }
      }
    }

    final existing = widget.existing;
    final task = existing ??
        Task(id: const Uuid().v4(), title: '', createdAt: DateTime.now());
    task.title = _title.text.trim();
    task.description =
        _description.text.trim().isEmpty ? null : _description.text.trim();
    task.notes = _notes.text.trim().isEmpty ? null : _notes.text.trim();
    task.dueAt = _dueAt;
    task.scheduledStart = _scheduledStart;
    task.durationMinutes = _durationMinutes;
    task.iconKey = _iconKey;
    task.colorValue = _colorValue;
    task.subtasks = _subtasks.isEmpty ? null : _subtasks;
    task.priority = _priority;
    task.reminderEnabled = _reminderEnabled &&
        (_scheduledStart != null || _dueAt != null);
    task.reminderLeadMinutes = _leadMinutes;
    task.goalId = _goalId;
    task.recurrence = _recurrence == 0 ? null : _recurrence;
    if (existing == null) {
      await TaskService().add(task);
    } else {
      await TaskService().update(task);
    }
    if (mounted) Navigator.of(context).pop();
  }

  Future<_ConflictChoice> _showConflictDialog(
      List<BusyBlock> conflicts, int duration) async {
    final l = AppLocalizations.of(context)!;
    final lang = Localizations.localeOf(context).languageCode;
    final fmt = intl.DateFormat.Hm(lang);
    final result = await showDialog<_ConflictChoice>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning_amber, color: Theme.of(ctx).colorScheme.error),
            const SizedBox(width: 8),
            Expanded(child: Text(l.timelineConflictTitle)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l.timelineConflictBody),
            const SizedBox(height: 12),
            for (final c in conflicts.take(4))
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  '• ${fmt.format(c.start)}–${fmt.format(c.end)}  ${c.title}',
                  style: const TextStyle(fontSize: 13),
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, _ConflictChoice.cancel),
            child: Text(l.cancel),
          ),
          TextButton(
            onPressed: () =>
                Navigator.pop(ctx, _ConflictChoice.saveAnyway),
            child: Text(l.saveAnyway),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(ctx, _ConflictChoice.moveToNextFree),
            child: Text(l.moveToNextFree),
          ),
        ],
      ),
    );
    return result ?? _ConflictChoice.cancel;
  }

  Future<void> _delete() async {
    final l = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.confirmDelete),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false), child: Text(l.no)),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true), child: Text(l.yes)),
        ],
      ),
    );
    if (confirmed != true) return;
    await TaskService().delete(widget.existing!.id);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final lang = Localizations.localeOf(context).languageCode;
    final cs = Theme.of(context).colorScheme;
    final dueLabel = _dueAt == null
        ? l.noDueDate
        : intl.DateFormat.yMMMd(lang).add_jm().format(_dueAt!);
    final scheduledLabel = _scheduledStart == null
        ? l.inbox
        : intl.DateFormat.yMMMd(lang).add_jm().format(_scheduledStart!);
    final goals = GoalService().all();
    final iconColor = _colorValue != null ? Color(_colorValue!) : cs.primary;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existing == null ? l.addTask : l.editTask),
        actions: [
          if (widget.existing != null)
            IconButton(
                icon: const Icon(Icons.delete_outline), onPressed: _delete),
          IconButton(icon: const Icon(Icons.check), onPressed: _save),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: _pickIconColor,
                child: Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: iconColor, width: 2),
                  ),
                  child: Icon(TaskIcons.iconFor(_iconKey), color: iconColor),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _title,
                  decoration: InputDecoration(labelText: l.title),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _description,
            maxLines: 2,
            decoration: InputDecoration(labelText: l.description),
          ),
          const SizedBox(height: 16),
          _tile(
            icon: Icons.schedule_outlined,
            title: l.startTime,
            subtitle: scheduledLabel,
            trailing: _scheduledStart == null
                ? null
                : IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () => setState(() => _scheduledStart = null),
                  ),
            onTap: _pickScheduledStart,
          ),
          if (_scheduledStart != null) ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: [
                  Expanded(child: Text(l.duration)),
                  DropdownButton<int>(
                    value: _durationOptions.contains(_durationMinutes)
                        ? _durationMinutes
                        : 30,
                    items: _durationOptions
                        .map((m) => DropdownMenuItem(
                            value: m, child: Text('$m min')))
                        .toList(),
                    onChanged: (v) =>
                        setState(() => _durationMinutes = v ?? 30),
                  ),
                ],
              ),
            ),
            _conflictBanner(context, l),
          ],
          const SizedBox(height: 12),
          _tile(
            icon: Icons.event_outlined,
            title: l.dueDate,
            subtitle: dueLabel,
            trailing: _dueAt == null
                ? null
                : IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () => setState(() => _dueAt = null),
                  ),
            onTap: _pickDueDateTime,
          ),
          const SizedBox(height: 16),
          Text(l.priority,
              style: TextStyle(
                  color: cs.onSurfaceVariant, fontSize: 13)),
          const SizedBox(height: 8),
          SegmentedButton<int>(
            segments: [
              ButtonSegment(value: 0, label: Text(l.priorityLow)),
              ButtonSegment(value: 1, label: Text(l.priorityMedium)),
              ButtonSegment(value: 2, label: Text(l.priorityHigh)),
            ],
            selected: {_priority},
            onSelectionChanged: (s) => setState(() => _priority = s.first),
          ),
          const SizedBox(height: 16),
          Text(l.recurrence,
              style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13)),
          const SizedBox(height: 8),
          DropdownButtonFormField<int>(
            value: _recurrence,
            items: [
              DropdownMenuItem(value: 0, child: Text(l.recurrenceNone)),
              DropdownMenuItem(value: 1, child: Text(l.recurrenceDaily)),
              DropdownMenuItem(value: 2, child: Text(l.recurrenceWeekly)),
              DropdownMenuItem(value: 3, child: Text(l.recurrenceMonthly)),
            ],
            onChanged: (v) => setState(() => _recurrence = v ?? 0),
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            tileColor: cs.surfaceContainerHighest,
            title: Text(l.reminderEnabled),
            value: _reminderEnabled,
            onChanged: (_scheduledStart == null && _dueAt == null)
                ? null
                : (v) => setState(() => _reminderEnabled = v),
          ),
          if (_reminderEnabled) ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: [
                  Expanded(child: Text(l.reminderLeadMinutes)),
                  DropdownButton<int>(
                    value: _leadMinutes,
                    items: const [0, 5, 10, 15, 30, 60, 120]
                        .map((m) =>
                            DropdownMenuItem(value: m, child: Text('$m')))
                        .toList(),
                    onChanged: (v) =>
                        setState(() => _leadMinutes = v ?? 15),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          Text(l.subtasks,
              style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13)),
          const SizedBox(height: 4),
          Container(
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: SubtaskEditor(
              initial: _subtasks,
              onChanged: (list) => _subtasks = list,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _notes,
            maxLines: 4,
            decoration: InputDecoration(labelText: l.notes),
          ),
          const SizedBox(height: 16),
          if (goals.isNotEmpty)
            DropdownButtonFormField<String?>(
              value: _goalId,
              decoration: InputDecoration(labelText: l.linkToGoal),
              items: [
                DropdownMenuItem<String?>(value: null, child: Text(l.noGoal)),
                ...goals.map((g) => DropdownMenuItem<String?>(
                      value: g.id,
                      child: Text(g.title, overflow: TextOverflow.ellipsis),
                    )),
              ],
              onChanged: (v) => setState(() => _goalId = v),
            ),
        ],
      ),
    );
  }

  Widget _conflictBanner(BuildContext context, AppLocalizations l) {
    final start = _scheduledStart;
    if (start == null) return const SizedBox.shrink();
    final conflicts = SchedulingService().conflictsFor(
      start: start,
      durationMinutes: _durationMinutes ?? 30,
      excludeTaskId: widget.existing?.id,
    );
    if (conflicts.isEmpty) return const SizedBox.shrink();
    final cs = Theme.of(context).colorScheme;
    final lang = Localizations.localeOf(context).languageCode;
    final fmt = intl.DateFormat.Hm(lang);
    final summary = conflicts
        .take(2)
        .map((b) => '${fmt.format(b.start)} ${b.title}')
        .join(' · ');
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: cs.error.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: cs.error.withValues(alpha: 0.4)),
        ),
        child: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: cs.error, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l.conflictsWith(conflicts.length),
                    style: TextStyle(
                        color: cs.error,
                        fontSize: 13,
                        fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 2),
                  Text(summary,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          color: cs.onSurface, fontSize: 12)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            TextButton(
              onPressed: _findNextFreeSlot,
              child: Text(l.findNextFree),
            ),
          ],
        ),
      ),
    );
  }

  void _findNextFreeSlot() {
    final start = _scheduledStart ?? DateTime.now();
    final slot = SchedulingService().nextFreeSlot(
      after: start,
      durationMinutes: _durationMinutes ?? 30,
      excludeTaskId: widget.existing?.id,
    );
    if (slot != null) {
      setState(() => _scheduledStart = slot);
    }
  }

  Widget _tile({
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return ListTile(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      tileColor: Theme.of(context).colorScheme.surfaceContainerHighest,
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: trailing,
      onTap: onTap,
    );
  }
}

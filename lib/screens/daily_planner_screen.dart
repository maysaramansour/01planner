import 'package:flutter/material.dart';
import 'package:one_planner/l10n/app_localizations.dart';
import 'package:intl/intl.dart' as intl;

import '../models/task.dart';
import '../services/ai_config.dart';
import '../services/ai_service.dart';
import '../services/event_service.dart';
import '../services/task_service.dart';

class DailyPlannerScreen extends StatefulWidget {
  const DailyPlannerScreen({super.key});

  @override
  State<DailyPlannerScreen> createState() => _DailyPlannerScreenState();
}

class _DailyPlannerScreenState extends State<DailyPlannerScreen> {
  TimeOfDay _wake = const TimeOfDay(hour: 7, minute: 0);
  TimeOfDay _sleep = const TimeOfDay(hour: 23, minute: 0);
  bool _loading = false;
  List<ScheduleChange>? _proposal;
  String? _error;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final now = DateTime.now();
    final inbox = TaskService().inbox();
    final scheduled = TaskService().scheduledForDay(now);
    final events = EventService().eventsForDay(now);
    final aiEnabled = AIConfig().enabled.value;

    return Scaffold(
      appBar: AppBar(title: Text(l.dailyPlan)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (!aiEnabled)
            _info(cs, Icons.info_outline, l.aiDisabledHint),
          Row(
            children: [
              Expanded(
                child: _timeTile(l.wakeTime, _wake, (t) {
                  if (t != null) setState(() => _wake = t);
                }),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _timeTile(l.sleepTime, _sleep, (t) {
                  if (t != null) setState(() => _sleep = t);
                }),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _sectionLabel(cs, l.inbox),
          if (inbox.isEmpty)
            _muted(cs, l.noTasks)
          else
            ...inbox.map((t) => _taskRow(t)),
          const SizedBox(height: 8),
          _sectionLabel(cs, l.tasksToday),
          if (scheduled.isEmpty && events.isEmpty)
            _muted(cs, l.noTasks)
          else ...[
            for (final e in events)
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.event_outlined, color: cs.tertiary),
                title: Text(e.title),
                subtitle: Text(
                    '${intl.DateFormat.jm().format(e.startAt)} — ${intl.DateFormat.jm().format(e.endAt)}'),
              ),
            for (final t in scheduled)
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.schedule, color: cs.primary),
                title: Text(t.title),
                subtitle: Text(intl.DateFormat.jm().format(t.scheduledStart!)),
              ),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              icon: _loading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.auto_awesome),
              label: Text(l.generatePlan),
              onPressed: _loading || !aiEnabled || inbox.isEmpty
                  ? null
                  : () => _generate(inbox, scheduled, events),
            ),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(_error!,
                  style: TextStyle(color: cs.error, fontSize: 13)),
            ),
          if (_proposal != null) ...[
            const SizedBox(height: 16),
            _sectionLabel(cs, l.proposedPlan),
            for (final change in _proposal!)
              _proposalRow(change, inbox),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => setState(() => _proposal = null),
                    child: Text(l.rejectPlan),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () => _accept(inbox),
                    child: Text(l.acceptPlan),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _timeTile(String label, TimeOfDay time, ValueChanged<TimeOfDay?> onPick) {
    return InkWell(
      onTap: () async {
        final picked = await showTimePicker(context: context, initialTime: time);
        onPick(picked);
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 11)),
            const SizedBox(height: 4),
            Text(time.format(context),
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(ColorScheme cs, String text) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Text(text.toUpperCase(),
            style: TextStyle(
                color: cs.onSurfaceVariant,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.1)),
      );

  Widget _muted(ColorScheme cs, String text) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(text, style: TextStyle(color: cs.onSurfaceVariant)),
      );

  Widget _info(ColorScheme cs, IconData icon, String text) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: cs.onSurfaceVariant, size: 18),
            const SizedBox(width: 8),
            Expanded(child: Text(text, style: const TextStyle(fontSize: 13))),
          ],
        ),
      );

  Widget _taskRow(Task t) {
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: Icon(Icons.inbox_outlined,
          color: Theme.of(context).colorScheme.onSurfaceVariant),
      title: Text(t.title),
      subtitle: Text('${t.durationMinutes ?? 30} min'),
    );
  }

  Widget _proposalRow(ScheduleChange change, List<Task> inbox) {
    final task = inbox.firstWhere(
      (t) => t.id == change.taskId,
      orElse: () => Task(id: change.taskId, title: '?', createdAt: DateTime.now()),
    );
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.arrow_forward, size: 18),
      title: Text(task.title),
      subtitle: Text(
          '${intl.DateFormat.jm().format(change.scheduledStart)} · ${change.durationMinutes} min${change.reason != null ? " · ${change.reason}" : ""}'),
    );
  }

  Future<void> _generate(
      List<Task> inbox, List<Task> scheduled, List events) async {
    final l = AppLocalizations.of(context)!;
    setState(() {
      _loading = true;
      _error = null;
    });
    final proposal = await AIService().proposeSchedule(
      inbox: inbox,
      scheduled: scheduled,
      events: events.cast(),
      wake: _wake,
      sleep: _sleep,
      day: DateTime.now(),
    );
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (proposal == null) {
        _error = l.aiUnavailable;
        _proposal = null;
      } else {
        _proposal = proposal;
      }
    });
  }

  Future<void> _accept(List<Task> inbox) async {
    if (_proposal == null) return;
    final changes = _proposal!;
    for (final c in changes) {
      final t = inbox.firstWhere(
        (x) => x.id == c.taskId,
        orElse: () => Task(id: '', title: '', createdAt: DateTime.now()),
      );
      if (t.id.isEmpty) continue;
      t.scheduledStart = c.scheduledStart;
      t.durationMinutes = c.durationMinutes;
      await TaskService().update(t);
    }
    if (mounted) {
      setState(() => _proposal = null);
      Navigator.of(context).pop();
    }
  }
}

import 'package:flutter/material.dart';
import 'package:dabab_planner/l10n/app_localizations.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart' as intl;

import '../models/task.dart';
import '../services/event_service.dart';
import '../services/task_service.dart';
import '../widgets/timeline_view.dart';
import 'event_edit_screen.dart';
import 'task_edit_screen.dart';

class TodayScreen extends StatefulWidget {
  const TodayScreen({super.key});

  @override
  State<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends State<TodayScreen> {
  DateTime _day = DateTime.now();

  Future<void> _rescheduleTask(Task t) async {
    final base = t.scheduledStart ?? DateTime.now();
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(base),
    );
    if (time == null) return;
    t.scheduledStart = DateTime(_day.year, _day.month, _day.day,
        time.hour, time.minute);
    t.durationMinutes ??= 30;
    await TaskService().update(t);
  }

  Future<void> _showLongPressMenu(Task t) async {
    final l = AppLocalizations.of(context)!;
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.schedule),
              title: Text(l.reschedule),
              onTap: () {
                Navigator.pop(ctx);
                _rescheduleTask(t);
              },
            ),
            ListTile(
              leading: Icon(
                  t.completed ? Icons.radio_button_unchecked : Icons.check),
              title: Text(t.completed ? l.markUndone : l.markDone),
              onTap: () {
                Navigator.pop(ctx);
                TaskService().toggleComplete(t.id);
              },
            ),
            ListTile(
              leading: const Icon(Icons.inbox_outlined),
              title: Text(l.moveToInbox),
              onTap: () async {
                Navigator.pop(ctx);
                t.scheduledStart = null;
                t.durationMinutes = null;
                await TaskService().update(t);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: Text(l.delete),
              onTap: () async {
                Navigator.pop(ctx);
                await TaskService().delete(t.id);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _day,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (picked != null) setState(() => _day = picked);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final lang = Localizations.localeOf(context).languageCode;
    final monthFmt = intl.DateFormat.yMMMM(lang);

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 20,
        toolbarHeight: 64,
        title: GestureDetector(
          onTap: _pickDate,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${monthFmt.format(_day).split(' ').first} ',
                style: const TextStyle(
                    fontSize: 28, fontWeight: FontWeight.w800),
              ),
              Text(
                '${_day.year}',
                style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: cs.primary),
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today_outlined),
            onPressed: _pickDate,
          ),
        ],
      ),
      body: Column(
        children: [
          _DayStrip(
            selected: _day,
            onSelect: (d) => setState(() => _day = d),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: ValueListenableBuilder(
              valueListenable: TaskService().watchAll(),
              builder: (context, Box<Task> _, __) {
                return ValueListenableBuilder(
                  valueListenable: EventService().watchAll(),
                  builder: (context, _, __) {
                    final scheduled = TaskService().scheduledForDay(_day);
                    final events = EventService().eventsForDay(_day);
                    final dueOnly = TaskService()
                        .tasksDueOn(_day)
                        .where((t) => t.scheduledStart == null)
                        .toList();
                    return TimelineView(
                      scheduledTasks: scheduled,
                      events: events,
                      day: _day,
                      onTapTask: (t) => Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) => TaskEditScreen(existing: t)),
                      ),
                      onLongPressTask: _showLongPressMenu,
                      onTapEvent: (e) => Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) => EventEditScreen(existing: e)),
                      ),
                      onAddTask: () => Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) => const TaskEditScreen()),
                      ),
                      footer: dueOnly.isEmpty
                          ? null
                          : _DueStrip(tasks: dueOnly),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _DayStrip extends StatefulWidget {
  final DateTime selected;
  final ValueChanged<DateTime> onSelect;
  const _DayStrip({required this.selected, required this.onSelect});

  @override
  State<_DayStrip> createState() => _DayStripState();
}

class _DayStripState extends State<_DayStrip> {
  late final ScrollController _ctl;
  static const _cellWidth = 60.0;

  @override
  void initState() {
    super.initState();
    _ctl = ScrollController(
      initialScrollOffset:
          (_dayDiff(DateTime.now(), widget.selected) + 7) * _cellWidth,
    );
  }

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  int _dayDiff(DateTime a, DateTime b) {
    final da = DateTime(a.year, a.month, a.day);
    final db = DateTime(b.year, b.month, b.day);
    return db.difference(da).inDays;
  }

  Widget _dot(Color color) => Container(
        width: 6,
        height: 6,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      );

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final lang = Localizations.localeOf(context).languageCode;
    final today = DateTime.now();
    return SizedBox(
      height: 84,
      child: ListView.builder(
        controller: _ctl,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        itemCount: 60,
        itemBuilder: (context, i) {
          final date = DateTime(today.year, today.month, today.day)
              .add(Duration(days: i - 7));
          final isSelected = date.year == widget.selected.year &&
              date.month == widget.selected.month &&
              date.day == widget.selected.day;
          final weekday = intl.DateFormat.E(lang).format(date);
          final hasTask = TaskService().scheduledForDay(date).isNotEmpty;
          final hasEvent = EventService().eventsForDay(date).isNotEmpty;
          return GestureDetector(
            onTap: () => widget.onSelect(date),
            child: Container(
              width: _cellWidth,
              margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? Colors.black : Colors.transparent,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    weekday,
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? Colors.white70 : cs.onSurfaceVariant),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${date.day}',
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: isSelected ? Colors.white : cs.onSurface),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (hasTask)
                        _dot(isSelected ? Colors.white : cs.primary),
                      if (hasTask && hasEvent) const SizedBox(width: 3),
                      if (hasEvent)
                        _dot(isSelected ? Colors.white70 : cs.tertiary),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _DueStrip extends StatelessWidget {
  final List<Task> tasks;
  const _DueStrip({required this.tasks});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l.tasksToday.toUpperCase(),
              style: TextStyle(
                  color: cs.onSurfaceVariant,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.1)),
          const SizedBox(height: 4),
          for (final t in tasks)
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: Checkbox(
                value: t.completed,
                onChanged: (_) => TaskService().toggleComplete(t.id),
              ),
              title: Text(t.title,
                  style: TextStyle(
                    decoration: t.completed
                        ? TextDecoration.lineThrough
                        : null,
                  )),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                    builder: (_) => TaskEditScreen(existing: t)),
              ),
            ),
        ],
      ),
    );
  }
}

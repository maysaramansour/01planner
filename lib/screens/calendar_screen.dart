import 'package:flutter/material.dart';
import 'package:one_planner/l10n/app_localizations.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:table_calendar/table_calendar.dart';

import '../models/event.dart';
import '../services/event_service.dart';
import '../services/task_service.dart';
import '../widgets/empty_state.dart';
import '../widgets/event_tile.dart';
import '../widgets/task_tile.dart';
import 'event_edit_screen.dart';
import 'task_edit_screen.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  CalendarFormat _format = CalendarFormat.month;
  DateTime _focused = DateTime.now();
  DateTime _selected = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final lang = Localizations.localeOf(context).languageCode;

    return Scaffold(
      body: ValueListenableBuilder(
        valueListenable: EventService().watchAll(),
        builder: (context, Box<Event> _, __) {
          return ValueListenableBuilder(
            valueListenable: TaskService().watchAll(),
            builder: (context, _, __) {
              final dayEvents = EventService().eventsForDay(_selected);
              final dayTasks = TaskService().tasksDueOn(_selected);
              return Column(
                children: [
                  TableCalendar(
                    locale: lang,
                    firstDay: DateTime.utc(2020, 1, 1),
                    lastDay: DateTime.utc(2035, 12, 31),
                    focusedDay: _focused,
                    selectedDayPredicate: (d) => isSameDay(d, _selected),
                    calendarFormat: _format,
                    eventLoader: (d) => EventService().eventsForDay(d),
                    onDaySelected: (selected, focused) => setState(() {
                      _selected = selected;
                      _focused = focused;
                    }),
                    onFormatChanged: (f) => setState(() => _format = f),
                    onPageChanged: (f) => _focused = f,
                    calendarStyle: CalendarStyle(
                      todayDecoration: BoxDecoration(
                        color: cs.primary.withValues(alpha: 0.3),
                        shape: BoxShape.circle,
                      ),
                      selectedDecoration: BoxDecoration(
                        color: cs.primary,
                        shape: BoxShape.circle,
                      ),
                      markerDecoration: BoxDecoration(
                        color: cs.tertiary,
                        shape: BoxShape.circle,
                      ),
                      defaultTextStyle: TextStyle(color: cs.onSurface),
                      weekendTextStyle: TextStyle(color: cs.onSurfaceVariant),
                      outsideTextStyle: TextStyle(
                          color: cs.onSurfaceVariant.withValues(alpha: 0.5)),
                    ),
                    daysOfWeekStyle: DaysOfWeekStyle(
                      weekdayStyle: TextStyle(color: cs.onSurfaceVariant),
                      weekendStyle: TextStyle(color: cs.onSurfaceVariant),
                    ),
                    headerStyle: HeaderStyle(
                      formatButtonVisible: false,
                      titleCentered: true,
                      titleTextStyle: TextStyle(
                          color: cs.onSurface,
                          fontSize: 16,
                          fontWeight: FontWeight.w600),
                      leftChevronIcon:
                          Icon(Icons.chevron_left, color: cs.onSurface),
                      rightChevronIcon:
                          Icon(Icons.chevron_right, color: cs.onSurface),
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: dayEvents.isEmpty && dayTasks.isEmpty
                        ? EmptyState(
                            icon: Icons.event_note_outlined,
                            message: l.noEvents,
                          )
                        : ListView(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            children: [
                              ...dayEvents.map((e) => EventTile(
                                    event: e,
                                    onTap: () => Navigator.of(context).push(
                                      MaterialPageRoute(
                                          builder: (_) =>
                                              EventEditScreen(existing: e)),
                                    ),
                                    onLongPress: () =>
                                        _confirmDeleteEvent(context, e),
                                  )),
                              ...dayTasks.map((t) => TaskTile(
                                    task: t,
                                    onTap: () => Navigator.of(context).push(
                                      MaterialPageRoute(
                                          builder: (_) =>
                                              TaskEditScreen(existing: t)),
                                    ),
                                  )),
                            ],
                          ),
                  ),
                ],
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(
              builder: (_) => EventEditScreen(initialDate: _selected)),
        ),
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _confirmDeleteEvent(BuildContext context, Event e) async {
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
    if (confirmed == true) await EventService().delete(e.id);
  }
}

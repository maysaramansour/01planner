import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';
import 'package:intl/intl.dart' as intl;

import 'event_service.dart';
import 'goal_service.dart';
import 'task_service.dart';

class WidgetService {
  WidgetService._internal();
  static final WidgetService _instance = WidgetService._internal();
  factory WidgetService() => _instance;

  static const _androidName = 'TodayWidgetProvider';
  static const _appGroup = 'group.com.oneplanner.app';

  bool _wired = false;

  Future<void> init() async {
    if (_wired) return;
    HomeWidget.setAppGroupId(_appGroup);
    await refresh();
    _wired = true;
  }

  Future<void> refresh() async {
    try {
      final today = DateTime.now();
      final tasks = TaskService().tasksToday();
      final scheduled = TaskService().scheduledForDay(today);
      final events = EventService().eventsForDay(today);
      final goals = GoalService().all();

      final lines = <String>[];
      final timeFmt = intl.DateFormat.jm();
      for (final e in events.take(2)) {
        lines.add('• ${timeFmt.format(e.startAt)}  ${e.title}');
      }
      for (final t in scheduled.take(4 - lines.length.clamp(0, 4))) {
        final mark = t.completed ? '✓' : '◦';
        final when = t.scheduledStart != null
            ? timeFmt.format(t.scheduledStart!)
            : '';
        lines.add('$mark  $when  ${t.title}'.trim());
      }
      if (lines.isEmpty) lines.add('No plans today');

      // Top goal line
      String goalsLine = '';
      if (goals.isNotEmpty) {
        final top = goals.first;
        final p = GoalService().progressFor(top.id);
        final pct = (p.fraction * 100).round();
        goalsLine =
            '🎯 ${top.title} · $pct%${goals.length > 1 ? ' · +${goals.length - 1}' : ''}';
      }

      final taskCount = tasks.length + scheduled.length;
      final summary =
          '$taskCount task${taskCount == 1 ? '' : 's'} · ${events.length} event${events.length == 1 ? '' : 's'}';

      await HomeWidget.saveWidgetData<String>(
          'widget_date', intl.DateFormat('EEE, MMM d').format(today));
      await HomeWidget.saveWidgetData<String>('widget_content', lines.join('\n'));
      await HomeWidget.saveWidgetData<String>('widget_summary', summary);
      await HomeWidget.saveWidgetData<String>('widget_goal', goalsLine);
      await HomeWidget.updateWidget(
        name: _androidName,
        androidName: _androidName,
      );
    } catch (e) {
      debugPrint('WidgetService.refresh failed: $e');
    }
  }
}

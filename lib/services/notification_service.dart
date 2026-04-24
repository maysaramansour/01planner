import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../models/event.dart';
import '../models/habit.dart';
import '../models/task.dart';
import 'app_prefs.dart';
import 'goal_service.dart';

typedef NotificationTapHandler = void Function(Map<String, dynamic> payload);

class NotificationService {
  NotificationService._internal();
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;
  NotificationTapHandler? onTap;

  static const _tasksChannel = 'tasks';
  static const _eventsChannel = 'events';
  static const _habitsChannel = 'habits';
  static const _goalsChannel = 'goals';

  /// 3-hour slots used by `scheduleGoalPulses`. Avoids night hours.
  static const List<int> _goalPulseHours = [9, 12, 15, 18, 21];
  static int _goalPulseId(int hour) => 0x1000_0000 | hour;

  Future<void> init() async {
    if (_initialized) return;

    tzdata.initializeTimeZones();
    try {
      final name = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(name));
    } catch (_) {
      // Fall back to UTC if zone lookup fails.
    }

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const macos = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios, macOS: macos),
      onDidReceiveNotificationResponse: _handleResponse,
    );

    if (Platform.isAndroid) {
      final androidImpl = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      await androidImpl?.requestNotificationsPermission();
      const channels = [
        AndroidNotificationChannel(_tasksChannel, 'Tasks',
            importance: Importance.high),
        AndroidNotificationChannel(_eventsChannel, 'Events',
            importance: Importance.high),
        AndroidNotificationChannel(_habitsChannel, 'Habits',
            importance: Importance.defaultImportance),
        AndroidNotificationChannel(_goalsChannel, 'Goal reminders',
            description: 'Periodic check-ins on your goals',
            importance: Importance.defaultImportance),
      ];
      for (final c in channels) {
        await androidImpl?.createNotificationChannel(c);
      }
    }

    _initialized = true;
  }

  void _handleResponse(NotificationResponse response) {
    final raw = response.payload;
    if (raw == null || raw.isEmpty) return;
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      onTap?.call(decoded);
    } catch (e) {
      debugPrint('Notification payload parse failed: $e');
    }
  }

  AndroidNotificationDetails _androidDetails(String channel, String title) {
    final importance = channel == _habitsChannel
        ? Importance.defaultImportance
        : Importance.high;
    return AndroidNotificationDetails(
      channel,
      title,
      importance: importance,
      priority: importance == Importance.high ? Priority.high : Priority.defaultPriority,
    );
  }

  NotificationDetails _details(String channel, String name) =>
      NotificationDetails(
        android: _androidDetails(channel, name),
        iOS: const DarwinNotificationDetails(),
        macOS: const DarwinNotificationDetails(),
      );

  int _idFor(String s) => s.hashCode & 0x7fffffff;

  Future<void> scheduleTask(Task task) async {
    if (!_initialized) return;
    try {
      await cancel(task.notificationId ?? _idFor(task.id));
      if (task.completed || !task.reminderEnabled) return;
      final anchor = task.scheduledStart ?? task.dueAt;
      if (anchor == null) return;
      final lead = Duration(minutes: task.reminderLeadMinutes ?? 0);
      final fireAt = anchor.subtract(lead);
      if (fireAt.isBefore(DateTime.now())) return;
      final id = _idFor(task.id);
      task.notificationId = id;
      DateTimeComponents? match;
      switch (task.recurrence ?? 0) {
        case 1:
          match = DateTimeComponents.time;
          break;
        case 2:
          match = DateTimeComponents.dayOfWeekAndTime;
          break;
        case 3:
          match = DateTimeComponents.dayOfMonthAndTime;
          break;
      }
      await _plugin.zonedSchedule(
        id,
        task.title,
        task.notes ?? task.description ?? '',
        tz.TZDateTime.from(fireAt, tz.local),
        _details(_tasksChannel, 'Tasks'),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: match,
        payload: jsonEncode({'type': 'task', 'id': task.id}),
      );
    } catch (e, st) {
      debugPrint('scheduleTask failed: $e\n$st');
    }
  }

  Future<void> scheduleEvent(Event event) async {
    if (!_initialized) return;
    try {
      await cancel(event.notificationId ?? _idFor(event.id));
      final fireAt = event.startAt
          .subtract(Duration(minutes: event.reminderLeadMinutes));
      if (event.recurrence == 0 && fireAt.isBefore(DateTime.now())) return;
      final id = _idFor(event.id);
      event.notificationId = id;
      DateTimeComponents? match;
      switch (event.recurrence) {
        case 1:
          match = DateTimeComponents.time;
          break;
        case 2:
          match = DateTimeComponents.dayOfWeekAndTime;
          break;
        case 3:
          match = DateTimeComponents.dayOfMonthAndTime;
          break;
      }
      await _plugin.zonedSchedule(
        id,
        event.title,
        event.location ?? '',
        tz.TZDateTime.from(fireAt, tz.local),
        _details(_eventsChannel, 'Events'),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: match,
        payload: jsonEncode({'type': 'event', 'id': event.id}),
      );
    } catch (e, st) {
      debugPrint('scheduleEvent failed: $e\n$st');
    }
  }

  Future<void> scheduleHabit(Habit habit) async {
    if (!_initialized) return;
    try {
      await cancelAllForHabit(habit.id);
      final now = DateTime.now();
      final daysToSchedule =
          habit.frequencyType == 0 ? <int>[0] : habit.weekdays;
      for (final wd in daysToSchedule) {
        final id = habit.frequencyType == 0
            ? _idFor('habit:${habit.id}')
            : _idFor('habit:${habit.id}:$wd');
        var fire = DateTime(now.year, now.month, now.day, habit.reminderHour,
            habit.reminderMinute);
        if (habit.frequencyType == 1) {
          while (fire.weekday != wd) {
            fire = fire.add(const Duration(days: 1));
          }
        }
        if (!fire.isAfter(now)) {
          fire = fire.add(const Duration(days: 1));
          if (habit.frequencyType == 1) {
            while (fire.weekday != wd) {
              fire = fire.add(const Duration(days: 1));
            }
          }
        }
        final match = habit.frequencyType == 0
            ? DateTimeComponents.time
            : DateTimeComponents.dayOfWeekAndTime;
        await _plugin.zonedSchedule(
          id,
          habit.name,
          '',
          tz.TZDateTime.from(fire, tz.local),
          _details(_habitsChannel, 'Habits'),
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents: match,
          payload: jsonEncode({'type': 'habit', 'id': habit.id}),
        );
      }
    } catch (e, st) {
      debugPrint('scheduleHabit failed: $e\n$st');
    }
  }

  /// Schedule 5 daily goal-pulse notifications at [_goalPulseHours]
  /// (approximately every 3 hours during the day). Each pulse shows a brief
  /// summary of current goals + their progress.
  /// Call on boot and whenever goals change.
  Future<void> scheduleGoalPulses() async {
    if (!_initialized) return;
    await cancelGoalPulses();
    if (!AppPrefs().goalPulsesEnabled.value) return;
    final goals = GoalService().all();
    if (goals.isEmpty) return;

    // Build a consistent body: top 3 goals with %, plus overall count.
    final lines = <String>[];
    for (final g in goals.take(3)) {
      final p = GoalService().progressFor(g.id);
      final pct = (p.fraction * 100).round();
      lines.add('• ${g.title} — $pct%');
    }
    final title = goals.length == 1
        ? '${goals.length} active goal'
        : '${goals.length} active goals';
    final body = lines.join('\n');

    for (final hour in _goalPulseHours) {
      try {
        final now = tz.TZDateTime.now(tz.local);
        var fire = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour);
        if (fire.isBefore(now)) {
          fire = fire.add(const Duration(days: 1));
        }
        await _plugin.zonedSchedule(
          _goalPulseId(hour),
          title,
          body,
          fire,
          _details(_goalsChannel, 'Goal reminders'),
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents: DateTimeComponents.time,
          payload: jsonEncode({'type': 'goalPulse'}),
        );
      } catch (e, st) {
        debugPrint('scheduleGoalPulses[$hour] failed: $e\n$st');
      }
    }
  }

  Future<void> cancelGoalPulses() async {
    if (!_initialized) return;
    for (final h in _goalPulseHours) {
      await _plugin.cancel(_goalPulseId(h));
    }
  }

  /// Fire a one-shot notification letting the user know the AI plan is ready
  /// to review. Triggered from `_convertChatToPlan` when the extraction
  /// completes while the app is in the background.
  Future<void> notifyPlanReady({int taskCount = 0}) async {
    if (!_initialized) return;
    try {
      final body = taskCount > 0
          ? 'Your AI plan is ready — $taskCount tasks to review and commit.'
          : 'Your AI plan is ready to review.';
      await _plugin.show(
        0x2000_0001,
        'Plan ready',
        body,
        _details(_goalsChannel, 'Goal reminders'),
        payload: jsonEncode({'type': 'planReady'}),
      );
    } catch (e) {
      debugPrint('notifyPlanReady failed: $e');
    }
  }

  Future<void> cancel(int id) async {
    if (!_initialized) return;
    await _plugin.cancel(id);
  }

  Future<void> cancelAllForHabit(String habitId) async {
    if (!_initialized) return;
    await _plugin.cancel(_idFor('habit:$habitId'));
    for (var wd = 1; wd <= 7; wd++) {
      await _plugin.cancel(_idFor('habit:$habitId:$wd'));
    }
  }

  Future<bool> areEnabled() async {
    if (!_initialized) return false;
    if (Platform.isAndroid) {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      return await android?.areNotificationsEnabled() ?? false;
    }
    return true;
  }

  Future<void> requestPermissions() async {
    if (!_initialized) return;
    if (Platform.isAndroid) {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      await android?.requestNotificationsPermission();
    } else {
      final ios = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      await ios?.requestPermissions(alert: true, badge: true, sound: true);
    }
  }
}

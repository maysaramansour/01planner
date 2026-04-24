import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/habit.dart';
import '../models/habit_completion.dart';
import 'notification_service.dart';
import 'storage_service.dart';

class HabitService {
  HabitService._internal();
  static final HabitService _instance = HabitService._internal();
  factory HabitService() => _instance;

  Box<Habit> get _habits => StorageService().habits;
  Box<HabitCompletion> get _completions => StorageService().completions;

  ValueListenable<Box<Habit>> watchAll() => _habits.listenable();
  ValueListenable<Box<HabitCompletion>> watchCompletions() =>
      _completions.listenable();

  List<Habit> all() => _habits.values.toList()
    ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

  List<Habit> habitsFor(DateTime day) =>
      all().where((h) => isScheduledOn(h, day)).toList()
        ..sort((a, b) {
          final at = a.reminderHour * 60 + a.reminderMinute;
          final bt = b.reminderHour * 60 + b.reminderMinute;
          return at.compareTo(bt);
        });

  String dateIso(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }

  bool isDoneOn(String habitId, DateTime date) {
    final key = HabitCompletion.keyFor(habitId, dateIso(date));
    return _completions.containsKey(key);
  }

  bool isScheduledOn(Habit habit, DateTime date) {
    if (habit.frequencyType == 0) return true;
    return habit.weekdays.contains(date.weekday);
  }

  Future<void> markDone(String habitId, DateTime date) async {
    final iso = dateIso(date);
    final key = HabitCompletion.keyFor(habitId, iso);
    if (_completions.containsKey(key)) return;
    await _completions.put(
      key,
      HabitCompletion(
        habitId: habitId,
        dateIso: iso,
        completedAt: DateTime.now(),
      ),
    );
  }

  Future<void> unmarkDone(String habitId, DateTime date) async {
    final key = HabitCompletion.keyFor(habitId, dateIso(date));
    await _completions.delete(key);
  }

  int streakFor(String habitId) {
    final habit = _habits.get(habitId);
    if (habit == null) return 0;
    var streak = 0;
    var cursor = DateTime.now();
    cursor = DateTime(cursor.year, cursor.month, cursor.day);
    while (true) {
      if (!isScheduledOn(habit, cursor)) {
        cursor = cursor.subtract(const Duration(days: 1));
        continue;
      }
      if (isDoneOn(habitId, cursor)) {
        streak++;
        cursor = cursor.subtract(const Duration(days: 1));
      } else {
        break;
      }
      if (streak > 365 * 5) break;
    }
    return streak;
  }

  List<DateTime> completionsInRange(
      String habitId, DateTime start, DateTime end) {
    final out = <DateTime>[];
    var cursor = DateTime(start.year, start.month, start.day);
    final last = DateTime(end.year, end.month, end.day);
    while (!cursor.isAfter(last)) {
      if (isDoneOn(habitId, cursor)) out.add(cursor);
      cursor = cursor.add(const Duration(days: 1));
    }
    return out;
  }

  Future<void> add(Habit habit) async {
    await _habits.put(habit.id, habit);
    await NotificationService().scheduleHabit(habit);
  }

  Future<void> update(Habit habit) async {
    await _habits.put(habit.id, habit);
    await NotificationService().scheduleHabit(habit);
  }

  Future<void> delete(String id) async {
    await NotificationService().cancelAllForHabit(id);
    await _habits.delete(id);
    final keysToDelete =
        _completions.keys.where((k) => k.toString().startsWith('$id|')).toList();
    await _completions.deleteAll(keysToDelete);
  }
}

import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/task.dart';
import 'notification_service.dart';
import 'storage_service.dart';
import 'widget_service.dart';

class TaskService {
  TaskService._internal();
  static final TaskService _instance = TaskService._internal();
  factory TaskService() => _instance;

  Box<Task> get _box => StorageService().tasks;

  ValueListenable<Box<Task>> watchAll() => _box.listenable();

  DateTime? _anchor(Task t) => t.scheduledStart ?? t.dueAt;

  List<Task> all() {
    final list = _box.values.toList()
      ..sort((a, b) {
        if (a.completed != b.completed) return a.completed ? 1 : -1;
        final ad = _anchor(a);
        final bd = _anchor(b);
        if (ad == null && bd == null) return b.priority.compareTo(a.priority);
        if (ad == null) return 1;
        if (bd == null) return -1;
        return ad.compareTo(bd);
      });
    return list;
  }

  bool _withinDay(DateTime? dt, DateTime day) {
    if (dt == null) return false;
    final start = DateTime(day.year, day.month, day.day);
    final end = start.add(const Duration(days: 1));
    return !dt.isBefore(start) && dt.isBefore(end);
  }

  List<Task> tasksDueOn(DateTime day) =>
      all().where((t) => _withinDay(t.dueAt, day)).toList();

  List<Task> tasksToday() => tasksDueOn(DateTime.now());

  List<Task> scheduledForDay(DateTime day) =>
      all().where((t) => _withinDay(t.scheduledStart, day)).toList();

  List<Task> inbox() => all()
      .where((t) =>
          t.scheduledStart == null && t.dueAt == null && !t.completed)
      .toList();

  List<Task> tasksForGoal(String goalId) =>
      all().where((t) => t.goalId == goalId).toList();

  Future<void> add(Task task) async {
    await _box.put(task.id, task);
    await NotificationService().scheduleTask(task);
    await WidgetService().refresh();
  }

  Future<void> update(Task task) async {
    await _box.put(task.id, task);
    await NotificationService().scheduleTask(task);
    await WidgetService().refresh();
  }

  Future<void> delete(String id) async {
    final t = _box.get(id);
    if (t?.notificationId != null) {
      await NotificationService().cancel(t!.notificationId!);
    }
    await _box.delete(id);
    await WidgetService().refresh();
  }

  Future<void> toggleComplete(String id) async {
    final t = _box.get(id);
    if (t == null) return;
    t.completed = !t.completed;
    t.completedAt = t.completed ? DateTime.now() : null;
    await t.save();
    await NotificationService().scheduleTask(t);
    await WidgetService().refresh();
  }
}

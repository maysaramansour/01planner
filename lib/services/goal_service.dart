import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/goal.dart';
import 'notification_service.dart';
import 'storage_service.dart';
import 'task_service.dart';
import 'widget_service.dart';

class GoalProgress {
  final int total;
  final int completed;
  const GoalProgress(this.total, this.completed);
  double get fraction => total == 0 ? 0 : completed / total;
}

class GoalService {
  GoalService._internal();
  static final GoalService _instance = GoalService._internal();
  factory GoalService() => _instance;

  Box<Goal> get _box => StorageService().goals;

  ValueListenable<Box<Goal>> watchAll() => _box.listenable();

  List<Goal> all({bool includeArchived = false}) {
    final list = _box.values
        .where((g) => includeArchived || !g.archived)
        .toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return list;
  }

  GoalProgress progressFor(String goalId) {
    final tasks = TaskService().tasksForGoal(goalId);
    final done = tasks.where((t) => t.completed).length;
    return GoalProgress(tasks.length, done);
  }

  Future<void> add(Goal goal) async {
    await _box.put(goal.id, goal);
    await _afterChange();
  }

  Future<void> update(Goal goal) async {
    await _box.put(goal.id, goal);
    await _afterChange();
  }

  Future<void> archive(String id, {bool archived = true}) async {
    final g = _box.get(id);
    if (g == null) return;
    g.archived = archived;
    await g.save();
    await _afterChange();
  }

  Future<void> delete(String id) async {
    final tasks = TaskService().tasksForGoal(id);
    for (final t in tasks) {
      t.goalId = null;
      await t.save();
    }
    await _box.delete(id);
    await _afterChange();
  }

  Future<void> _afterChange() async {
    await NotificationService().scheduleGoalPulses();
    await WidgetService().refresh();
  }
}

import 'dart:io';

import 'package:one_planner/models/event.dart';
import 'package:one_planner/models/goal.dart';
import 'package:one_planner/models/habit.dart';
import 'package:one_planner/models/habit_completion.dart';
import 'package:one_planner/models/task.dart';
import 'package:one_planner/services/event_service.dart';
import 'package:one_planner/services/goal_service.dart';
import 'package:one_planner/services/habit_service.dart';
import 'package:one_planner/services/task_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

void main() {
  late Directory tempDir;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('one_planner_test');
    Hive.init(tempDir.path);
    Hive.registerAdapter(TaskAdapter());
    Hive.registerAdapter(EventAdapter());
    Hive.registerAdapter(HabitAdapter());
    Hive.registerAdapter(HabitCompletionAdapter());
    Hive.registerAdapter(GoalAdapter());
    await Hive.openBox<Task>('tasks');
    await Hive.openBox<Event>('events');
    await Hive.openBox<Habit>('habits');
    await Hive.openBox<HabitCompletion>('habit_completions');
    await Hive.openBox<Goal>('goals');
  });

  tearDownAll(() async {
    await Hive.deleteFromDisk();
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  setUp(() async {
    await Hive.box<Task>('tasks').clear();
    await Hive.box<Event>('events').clear();
    await Hive.box<Habit>('habits').clear();
    await Hive.box<HabitCompletion>('habit_completions').clear();
    await Hive.box<Goal>('goals').clear();
  });

  group('Habit streak', () {
    test('three consecutive days = streak 3', () async {
      final habit = Habit(
        id: 'h1',
        name: 'Read',
        createdAt: DateTime.now(),
      );
      await Hive.box<Habit>('habits').put(habit.id, habit);
      final today = DateTime.now();
      for (var i = 0; i < 3; i++) {
        await HabitService()
            .markDone('h1', today.subtract(Duration(days: i)));
      }
      expect(HabitService().streakFor('h1'), 3);
    });

    test('gap breaks streak', () async {
      final habit = Habit(id: 'h2', name: 'Walk', createdAt: DateTime.now());
      await Hive.box<Habit>('habits').put(habit.id, habit);
      final today = DateTime.now();
      await HabitService().markDone('h2', today);
      await HabitService()
          .markDone('h2', today.subtract(const Duration(days: 2)));
      expect(HabitService().streakFor('h2'), 1);
    });

    test('zero when never completed', () async {
      final habit = Habit(id: 'h3', name: 'Yoga', createdAt: DateTime.now());
      await Hive.box<Habit>('habits').put(habit.id, habit);
      expect(HabitService().streakFor('h3'), 0);
    });

    test('specific-day habit skips off-days', () async {
      final today = DateTime.now();
      final habit = Habit(
        id: 'h4',
        name: 'Gym',
        frequencyType: 1,
        weekdays: [today.weekday],
        createdAt: DateTime.now(),
      );
      await Hive.box<Habit>('habits').put(habit.id, habit);
      await HabitService().markDone('h4', today);
      await HabitService()
          .markDone('h4', today.subtract(const Duration(days: 7)));
      expect(HabitService().streakFor('h4'), 2);
    });
  });

  group('Event recurrence', () {
    test('none: only on the start date', () {
      final start = DateTime(2026, 5, 1, 10);
      final e = Event(
        id: 'e1',
        title: 'One-off',
        startAt: start,
        endAt: start.add(const Duration(hours: 1)),
        recurrence: 0,
        createdAt: DateTime.now(),
      );
      Hive.box<Event>('events').put(e.id, e);
      expect(EventService().eventsForDay(start).length, 1);
      expect(
          EventService().eventsForDay(start.add(const Duration(days: 1))).length,
          0);
    });

    test('weekly: same weekday, future weeks only', () {
      final start = DateTime(2026, 5, 1, 10); // Friday
      final e = Event(
        id: 'e2',
        title: 'Weekly',
        startAt: start,
        endAt: start.add(const Duration(hours: 1)),
        recurrence: 2,
        createdAt: DateTime.now(),
      );
      Hive.box<Event>('events').put(e.id, e);
      expect(EventService().eventsForDay(start).length, 1);
      expect(
          EventService().eventsForDay(start.add(const Duration(days: 7))).length,
          1);
      expect(
          EventService().eventsForDay(start.add(const Duration(days: 1))).length,
          0);
    });

    test('daily: every day from start', () {
      final start = DateTime(2026, 5, 1, 10);
      final e = Event(
        id: 'e3',
        title: 'Daily',
        startAt: start,
        endAt: start.add(const Duration(hours: 1)),
        recurrence: 1,
        createdAt: DateTime.now(),
      );
      Hive.box<Event>('events').put(e.id, e);
      expect(EventService().eventsForDay(start).length, 1);
      expect(
          EventService().eventsForDay(start.add(const Duration(days: 5))).length,
          1);
      expect(
          EventService()
              .eventsForDay(start.subtract(const Duration(days: 1)))
              .length,
          0);
    });
  });

  group('Goal progress', () {
    test('two of four completed = 50%', () async {
      final goal = Goal(id: 'g1', title: 'Ship', createdAt: DateTime.now());
      await Hive.box<Goal>('goals').put(goal.id, goal);
      final created = DateTime.now();
      for (var i = 0; i < 4; i++) {
        final t = Task(
          id: 't$i',
          title: 'sub $i',
          goalId: 'g1',
          completed: i < 2,
          createdAt: created,
        );
        await Hive.box<Task>('tasks').put(t.id, t);
      }
      final p = GoalService().progressFor('g1');
      expect(p.total, 4);
      expect(p.completed, 2);
      expect(p.fraction, 0.5);
    });

    test('zero tasks = zero progress', () {
      final p = GoalService().progressFor('missing');
      expect(p.total, 0);
      expect(p.fraction, 0);
    });

    test('delete cascade detaches tasks', () async {
      final goal = Goal(id: 'g2', title: 'X', createdAt: DateTime.now());
      await Hive.box<Goal>('goals').put(goal.id, goal);
      final t = Task(
        id: 't10',
        title: 'sub',
        goalId: 'g2',
        createdAt: DateTime.now(),
      );
      await Hive.box<Task>('tasks').put(t.id, t);
      await GoalService().delete('g2');
      expect(Hive.box<Goal>('goals').get('g2'), isNull);
      expect(Hive.box<Task>('tasks').get('t10')!.goalId, isNull);
    });
  });

  group('Task service', () {
    test('toggleComplete flips state and timestamp', () async {
      final t = Task(id: 'tt', title: 'Test', createdAt: DateTime.now());
      await Hive.box<Task>('tasks').put(t.id, t);
      await TaskService().toggleComplete('tt');
      final after = Hive.box<Task>('tasks').get('tt')!;
      expect(after.completed, isTrue);
      expect(after.completedAt, isNotNull);
      await TaskService().toggleComplete('tt');
      final after2 = Hive.box<Task>('tasks').get('tt')!;
      expect(after2.completed, isFalse);
      expect(after2.completedAt, isNull);
    });
  });
}

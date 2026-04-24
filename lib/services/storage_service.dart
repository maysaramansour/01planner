import 'package:hive_flutter/hive_flutter.dart';

import '../models/ai_message.dart';
import '../models/chat_session.dart';
import '../models/event.dart';
import '../models/goal.dart';
import '../models/habit.dart';
import '../models/habit_completion.dart';
import '../models/task.dart';

class StorageService {
  StorageService._internal();
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;

  static const _tasksBox = 'tasks';
  static const _eventsBox = 'events';
  static const _habitsBox = 'habits';
  static const _completionsBox = 'habit_completions';
  static const _goalsBox = 'goals';
  static const _aiMessagesBox = 'ai_messages';
  static const _chatSessionsBox = 'chat_sessions';

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    await Hive.initFlutter();
    Hive.registerAdapter(TaskAdapter());
    Hive.registerAdapter(EventAdapter());
    Hive.registerAdapter(HabitAdapter());
    Hive.registerAdapter(HabitCompletionAdapter());
    Hive.registerAdapter(GoalAdapter());
    Hive.registerAdapter(AIMessageAdapter());
    Hive.registerAdapter(ChatSessionAdapter());

    await Future.wait<void>([
      Hive.openBox<Task>(_tasksBox),
      Hive.openBox<Event>(_eventsBox),
      Hive.openBox<Habit>(_habitsBox),
      Hive.openBox<HabitCompletion>(_completionsBox),
      Hive.openBox<Goal>(_goalsBox),
      Hive.openBox<AIMessage>(_aiMessagesBox),
      Hive.openBox<ChatSession>(_chatSessionsBox),
    ]);
    _initialized = true;
  }

  Box<Task> get tasks => Hive.box<Task>(_tasksBox);
  Box<Event> get events => Hive.box<Event>(_eventsBox);
  Box<Habit> get habits => Hive.box<Habit>(_habitsBox);
  Box<HabitCompletion> get completions =>
      Hive.box<HabitCompletion>(_completionsBox);
  Box<Goal> get goals => Hive.box<Goal>(_goalsBox);
  Box<AIMessage> get aiMessages => Hive.box<AIMessage>(_aiMessagesBox);
  Box<ChatSession> get chatSessions =>
      Hive.box<ChatSession>(_chatSessionsBox);
}

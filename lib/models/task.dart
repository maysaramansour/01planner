import 'package:hive/hive.dart';

part 'task.g.dart';

@HiveType(typeId: 0)
class Task extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  String? description;

  @HiveField(3)
  DateTime? dueAt;

  @HiveField(4)
  int priority;

  @HiveField(5)
  bool reminderEnabled;

  @HiveField(6)
  int? reminderLeadMinutes;

  @HiveField(7)
  bool completed;

  @HiveField(8)
  DateTime? completedAt;

  @HiveField(9)
  String? goalId;

  @HiveField(10)
  DateTime createdAt;

  @HiveField(11)
  int? notificationId;

  @HiveField(12)
  DateTime? scheduledStart;

  @HiveField(13)
  int? durationMinutes;

  @HiveField(14)
  String? iconKey;

  @HiveField(15)
  int? colorValue;

  @HiveField(16)
  List<String>? subtasks;

  @HiveField(17)
  String? notes;

  @HiveField(18)
  int? recurrence;

  Task({
    required this.id,
    required this.title,
    this.description,
    this.dueAt,
    this.priority = 1,
    this.reminderEnabled = false,
    this.reminderLeadMinutes,
    this.completed = false,
    this.completedAt,
    this.goalId,
    required this.createdAt,
    this.notificationId,
    this.scheduledStart,
    this.durationMinutes,
    this.iconKey,
    this.colorValue,
    this.subtasks,
    this.notes,
    this.recurrence,
  });
}

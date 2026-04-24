import 'package:hive/hive.dart';

part 'habit.g.dart';

@HiveType(typeId: 2)
class Habit extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  int frequencyType;

  @HiveField(3)
  List<int> weekdays;

  @HiveField(4)
  int reminderHour;

  @HiveField(5)
  int reminderMinute;

  @HiveField(6)
  DateTime createdAt;

  @HiveField(7)
  String? notes;

  Habit({
    required this.id,
    required this.name,
    this.frequencyType = 0,
    this.weekdays = const [],
    this.reminderHour = 9,
    this.reminderMinute = 0,
    required this.createdAt,
    this.notes,
  });
}

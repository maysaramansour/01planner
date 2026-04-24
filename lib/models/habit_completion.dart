import 'package:hive/hive.dart';

part 'habit_completion.g.dart';

@HiveType(typeId: 3)
class HabitCompletion extends HiveObject {
  @HiveField(0)
  String habitId;

  @HiveField(1)
  String dateIso;

  @HiveField(2)
  DateTime completedAt;

  HabitCompletion({
    required this.habitId,
    required this.dateIso,
    required this.completedAt,
  });

  static String keyFor(String habitId, String dateIso) => '$habitId|$dateIso';
}

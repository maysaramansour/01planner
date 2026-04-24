import 'package:hive/hive.dart';

part 'goal.g.dart';

@HiveType(typeId: 4)
class Goal extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  String? description;

  @HiveField(3)
  DateTime? targetDate;

  @HiveField(4)
  DateTime createdAt;

  @HiveField(5)
  bool archived;

  Goal({
    required this.id,
    required this.title,
    this.description,
    this.targetDate,
    required this.createdAt,
    this.archived = false,
  });
}

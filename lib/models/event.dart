import 'package:hive/hive.dart';

part 'event.g.dart';

@HiveType(typeId: 1)
class Event extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  String? location;

  @HiveField(3)
  DateTime startAt;

  @HiveField(4)
  DateTime endAt;

  @HiveField(5)
  int reminderLeadMinutes;

  @HiveField(6)
  int recurrence;

  @HiveField(7)
  DateTime createdAt;

  @HiveField(8)
  int? notificationId;

  Event({
    required this.id,
    required this.title,
    this.location,
    required this.startAt,
    required this.endAt,
    this.reminderLeadMinutes = 15,
    this.recurrence = 0,
    required this.createdAt,
    this.notificationId,
  });
}

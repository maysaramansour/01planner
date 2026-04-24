import 'package:hive/hive.dart';

part 'ai_message.g.dart';

@HiveType(typeId: 5)
class AIMessage extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String role; // 'user' | 'assistant' | 'system'

  @HiveField(2)
  String text;

  @HiveField(3)
  DateTime createdAt;

  @HiveField(4)
  String? sessionId;

  AIMessage({
    required this.id,
    required this.role,
    required this.text,
    required this.createdAt,
    this.sessionId,
  });
}

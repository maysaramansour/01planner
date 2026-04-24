// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'task.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TaskAdapter extends TypeAdapter<Task> {
  @override
  final int typeId = 0;

  @override
  Task read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Task(
      id: fields[0] as String,
      title: fields[1] as String,
      description: fields[2] as String?,
      dueAt: fields[3] as DateTime?,
      priority: fields[4] as int,
      reminderEnabled: fields[5] as bool,
      reminderLeadMinutes: fields[6] as int?,
      completed: fields[7] as bool,
      completedAt: fields[8] as DateTime?,
      goalId: fields[9] as String?,
      createdAt: fields[10] as DateTime,
      notificationId: fields[11] as int?,
      scheduledStart: fields[12] as DateTime?,
      durationMinutes: fields[13] as int?,
      iconKey: fields[14] as String?,
      colorValue: fields[15] as int?,
      subtasks: (fields[16] as List?)?.cast<String>(),
      notes: fields[17] as String?,
      recurrence: fields[18] as int?,
    );
  }

  @override
  void write(BinaryWriter writer, Task obj) {
    writer
      ..writeByte(19)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.dueAt)
      ..writeByte(4)
      ..write(obj.priority)
      ..writeByte(5)
      ..write(obj.reminderEnabled)
      ..writeByte(6)
      ..write(obj.reminderLeadMinutes)
      ..writeByte(7)
      ..write(obj.completed)
      ..writeByte(8)
      ..write(obj.completedAt)
      ..writeByte(9)
      ..write(obj.goalId)
      ..writeByte(10)
      ..write(obj.createdAt)
      ..writeByte(11)
      ..write(obj.notificationId)
      ..writeByte(12)
      ..write(obj.scheduledStart)
      ..writeByte(13)
      ..write(obj.durationMinutes)
      ..writeByte(14)
      ..write(obj.iconKey)
      ..writeByte(15)
      ..write(obj.colorValue)
      ..writeByte(16)
      ..write(obj.subtasks)
      ..writeByte(17)
      ..write(obj.notes)
      ..writeByte(18)
      ..write(obj.recurrence);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TaskAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

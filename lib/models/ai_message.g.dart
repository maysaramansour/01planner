// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ai_message.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AIMessageAdapter extends TypeAdapter<AIMessage> {
  @override
  final int typeId = 5;

  @override
  AIMessage read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AIMessage(
      id: fields[0] as String,
      role: fields[1] as String,
      text: fields[2] as String,
      createdAt: fields[3] as DateTime,
      sessionId: fields[4] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, AIMessage obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.role)
      ..writeByte(2)
      ..write(obj.text)
      ..writeByte(3)
      ..write(obj.createdAt)
      ..writeByte(4)
      ..write(obj.sessionId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AIMessageAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

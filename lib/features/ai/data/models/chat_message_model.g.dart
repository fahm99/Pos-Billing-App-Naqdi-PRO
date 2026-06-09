part of 'chat_message_model.dart';

class ChatMessageModelAdapter extends TypeAdapter<ChatMessageModel> {
  @override
  final int typeId = 14;

  @override
  ChatMessageModel read(BinaryReader reader) {
    final numFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numFields; i++) reader.readByte(): reader.read(),
    };
    return ChatMessageModel(
      id: fields[0] as String,
      sessionId: fields[1] as String,
      content: fields[2] as String,
      role: fields[3] as String,
      timestamp: fields[4] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, ChatMessageModel obj) {
    writer.writeByte(5);
    writer.writeByte(0); writer.write(obj.id);
    writer.writeByte(1); writer.write(obj.sessionId);
    writer.writeByte(2); writer.write(obj.content);
    writer.writeByte(3); writer.write(obj.role);
    writer.writeByte(4); writer.write(obj.timestamp);
  }
}

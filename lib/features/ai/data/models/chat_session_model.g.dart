part of 'chat_session_model.dart';

class ChatSessionModelAdapter extends TypeAdapter<ChatSessionModel> {
  @override
  final int typeId = 15;

  @override
  ChatSessionModel read(BinaryReader reader) {
    final numFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numFields; i++) reader.readByte(): reader.read(),
    };
    return ChatSessionModel(
      id: fields[0] as String,
      title: fields[1] as String,
      createdAt: fields[2] as DateTime,
      updatedAt: fields[3] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, ChatSessionModel obj) {
    writer.writeByte(4);
    writer.writeByte(0); writer.write(obj.id);
    writer.writeByte(1); writer.write(obj.title);
    writer.writeByte(2); writer.write(obj.createdAt);
    writer.writeByte(3); writer.write(obj.updatedAt);
  }
}

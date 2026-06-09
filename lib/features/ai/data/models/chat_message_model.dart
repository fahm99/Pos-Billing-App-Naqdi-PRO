import 'package:hive/hive.dart';
import '../../domain/entities/chat_message.dart';

part 'chat_message_model.g.dart';

@HiveType(typeId: 14)
class ChatMessageModel extends HiveObject {
  @HiveField(0)
  String id;
  @HiveField(1)
  String sessionId;
  @HiveField(2)
  String content;
  @HiveField(3)
  String role;
  @HiveField(4)
  DateTime timestamp;

  ChatMessageModel({
    required this.id,
    required this.sessionId,
    required this.content,
    required this.role,
    required this.timestamp,
  });

  ChatMessage toEntity() => ChatMessage(
        id: id,
        sessionId: sessionId,
        content: content,
        role: role,
        timestamp: timestamp,
      );

  factory ChatMessageModel.fromEntity(ChatMessage entity) => ChatMessageModel(
        id: entity.id,
        sessionId: entity.sessionId,
        content: entity.content,
        role: entity.role,
        timestamp: entity.timestamp,
      );
}

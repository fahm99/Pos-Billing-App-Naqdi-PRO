import 'package:hive/hive.dart';
import '../../domain/entities/chat_session.dart';

part 'chat_session_model.g.dart';

@HiveType(typeId: 15)
class ChatSessionModel extends HiveObject {
  @HiveField(0)
  String id;
  @HiveField(1)
  String title;
  @HiveField(2)
  DateTime createdAt;
  @HiveField(3)
  DateTime updatedAt;

  ChatSessionModel({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
  });

  ChatSession toEntity() => ChatSession(
        id: id,
        title: title,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );

  factory ChatSessionModel.fromEntity(ChatSession entity) => ChatSessionModel(
        id: entity.id,
        title: entity.title,
        createdAt: entity.createdAt,
        updatedAt: entity.updatedAt,
      );
}

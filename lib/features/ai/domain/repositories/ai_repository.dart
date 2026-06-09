import '../entities/ai_provider.dart';
import '../entities/chat_message.dart';
import '../entities/chat_session.dart';

abstract class AiRepository {
  // Providers
  List<AiProvider> getAllProviders();
  AiProvider? getProvider(String id);
  AiProvider? getDefaultProvider();
  Future<void> saveProvider(AiProvider provider);
  Future<void> deleteProvider(String id);
  Future<bool> testProviderConnection(AiProvider provider);

  // Chat
  Future<String> sendMessage({
    required AiProvider provider,
    required String sessionId,
    required String message,
    String? systemPrompt,
  });

  // Sessions
  List<ChatSession> getAllSessions();
  ChatSession? getSession(String id);
  Future<void> saveSession(ChatSession session);
  Future<void> deleteSession(String id);

  // Messages
  List<ChatMessage> getSessionMessages(String sessionId);
  Future<void> saveMessage(ChatMessage message);
}

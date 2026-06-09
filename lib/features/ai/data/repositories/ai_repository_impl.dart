import '../../domain/entities/ai_provider.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/entities/chat_session.dart';
import '../../domain/repositories/ai_repository.dart';
import '../datasources/ai_local_datasource.dart';
import '../datasources/ai_remote_datasource.dart';
import '../models/ai_provider_model.dart';
import '../models/chat_message_model.dart';
import '../models/chat_session_model.dart';

class AiRepositoryImpl implements AiRepository {
  final AiLocalDataSource _local;
  final AiRemoteDataSource _remote;

  AiRepositoryImpl(this._local, this._remote);

  @override
  List<AiProvider> getAllProviders() =>
      _local.getAllProviders().map((m) => m.toEntity()).toList();

  @override
  AiProvider? getProvider(String id) => _local.getProvider(id)?.toEntity();

  @override
  AiProvider? getDefaultProvider() => _local.getDefaultProvider()?.toEntity();

  @override
  Future<void> saveProvider(AiProvider provider) async {
    if (provider.isDefault) await _local.clearDefaultFlag();
    await _local.saveProvider(AiProviderModel.fromEntity(provider));
  }

  @override
  Future<void> deleteProvider(String id) async {
    await _local.deleteProvider(id);
  }

  @override
  Future<bool> testProviderConnection(AiProvider provider) async {
    return _remote.testConnection(provider);
  }

  @override
  Future<String> sendMessage({
    required AiProvider provider,
    required String sessionId,
    required String message,
    String? systemPrompt,
  }) async {
    final history = getSessionMessages(sessionId);
    final response = await _remote.sendChatMessage(
      provider: provider,
      history: history,
      userMessage: message,
      systemPrompt: systemPrompt,
    );
    return response;
  }

  @override
  List<ChatSession> getAllSessions() =>
      _local.getAllSessions().map((m) => m.toEntity()).toList();

  @override
  ChatSession? getSession(String id) => _local.getSession(id)?.toEntity();

  @override
  Future<void> saveSession(ChatSession session) async {
    await _local.saveSession(ChatSessionModel.fromEntity(session));
  }

  @override
  Future<void> deleteSession(String id) async {
    await _local.deleteSession(id);
  }

  @override
  List<ChatMessage> getSessionMessages(String sessionId) =>
      _local.getSessionMessages(sessionId).map((m) => m.toEntity()).toList();

  @override
  Future<void> saveMessage(ChatMessage message) async {
    await _local.saveMessage(ChatMessageModel.fromEntity(message));
  }
}

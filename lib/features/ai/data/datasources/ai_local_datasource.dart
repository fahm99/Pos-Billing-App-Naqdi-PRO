import 'package:hive_flutter/hive_flutter.dart';
import '../models/ai_provider_model.dart';
import '../models/chat_message_model.dart';
import '../models/chat_session_model.dart';

class AiLocalDataSource {
  static const String providerBoxName = 'ai_providers';
  static const String sessionBoxName = 'ai_sessions';
  static const String messageBoxName = 'ai_messages';

  Box<AiProviderModel> get _providerBox => Hive.box<AiProviderModel>(providerBoxName);
  Box<ChatSessionModel> get _sessionBox => Hive.box<ChatSessionModel>(sessionBoxName);
  Box<ChatMessageModel> get _messageBox => Hive.box<ChatMessageModel>(messageBoxName);

  Future<void> init() async {
    if (!Hive.isAdapterRegistered(13)) Hive.registerAdapter(AiProviderModelAdapter());
    if (!Hive.isAdapterRegistered(14)) Hive.registerAdapter(ChatMessageModelAdapter());
    if (!Hive.isAdapterRegistered(15)) Hive.registerAdapter(ChatSessionModelAdapter());
    await Hive.openBox<AiProviderModel>(providerBoxName);
    await Hive.openBox<ChatSessionModel>(sessionBoxName);
    await Hive.openBox<ChatMessageModel>(messageBoxName);
  }

  // ── Providers ──

  List<AiProviderModel> getAllProviders() => _providerBox.values.toList();

  AiProviderModel? getProvider(String id) => _providerBox.get(id);

  AiProviderModel? getDefaultProvider() {
    final providers = _providerBox.values.where((p) => p.isDefault).toList();
    if (providers.isNotEmpty) return providers.first;
    final enabled = _providerBox.values.where((p) => p.isEnabled).toList();
    return enabled.isNotEmpty ? enabled.first : null;
  }

  Future<void> saveProvider(AiProviderModel provider) async {
    await _providerBox.put(provider.id, provider);
  }

  Future<void> deleteProvider(String id) async {
    await _providerBox.delete(id);
  }

  Future<void> clearDefaultFlag() async {
    for (final p in _providerBox.values.where((p) => p.isDefault)) {
      p.isDefault = false;
      await p.save();
    }
  }

  // ── Sessions ──

  List<ChatSessionModel> getAllSessions() {
    final sessions = _sessionBox.values.toList();
    sessions.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return sessions;
  }

  ChatSessionModel? getSession(String id) => _sessionBox.get(id);

  Future<void> saveSession(ChatSessionModel session) async {
    await _sessionBox.put(session.id, session);
  }

  Future<void> deleteSession(String id) async {
    final messages = _messageBox.values.where((m) => m.sessionId == id).toList();
    for (final m in messages) {
      await m.delete();
    }
    await _sessionBox.delete(id);
  }

  // ── Messages ──

  List<ChatMessageModel> getSessionMessages(String sessionId) {
    final messages = _messageBox.values.where((m) => m.sessionId == sessionId).toList();
    messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return messages;
  }

  Future<void> saveMessage(ChatMessageModel message) async {
    await _messageBox.put(message.id, message);
  }

  Future<void> clearSessionMessages(String sessionId) async {
    final messages = _messageBox.values.where((m) => m.sessionId == sessionId).toList();
    for (final m in messages) {
      await m.delete();
    }
  }
}

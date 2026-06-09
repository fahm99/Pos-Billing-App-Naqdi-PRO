import '../../domain/entities/ai_provider.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/entities/chat_session.dart';

enum AiStatus { initial, loading, ready, sending, error }

class AiState {
  final AiStatus status;
  final String? error;
  final List<AiProvider> providers;
  final AiProvider? selectedProvider;
  final List<ChatSession> sessions;
  final ChatSession? currentSession;
  final List<ChatMessage> messages;
  final bool isTesting;

  const AiState({
    this.status = AiStatus.initial,
    this.error,
    this.providers = const [],
    this.selectedProvider,
    this.sessions = const [],
    this.currentSession,
    this.messages = const [],
    this.isTesting = false,
  });

  AiState copyWith({
    AiStatus? status,
    String? error,
    List<AiProvider>? providers,
    AiProvider? selectedProvider,
    List<ChatSession>? sessions,
    ChatSession? currentSession,
    List<ChatMessage>? messages,
    bool? isTesting,
  }) {
    return AiState(
      status: status ?? this.status,
      error: error,
      providers: providers ?? this.providers,
      selectedProvider: selectedProvider ?? this.selectedProvider,
      sessions: sessions ?? this.sessions,
      currentSession: currentSession ?? this.currentSession,
      messages: messages ?? this.messages,
      isTesting: isTesting ?? this.isTesting,
    );
  }
}

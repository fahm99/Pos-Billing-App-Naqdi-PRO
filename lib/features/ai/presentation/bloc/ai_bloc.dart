import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import '../../data/repositories/ai_repository_impl.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/entities/chat_session.dart';
import '../bloc/ai_event.dart';
import '../bloc/ai_state.dart';

class AiBloc extends Bloc<AiEvent, AiState> {
  final AiRepositoryImpl _repository;
  final Uuid _uuid = const Uuid();

  AiBloc(this._repository)
      : super(const AiState()) {
    on<LoadProviders>(_onLoadProviders);
    on<AddProvider>(_onAddProvider);
    on<UpdateProvider>(_onUpdateProvider);
    on<DeleteProvider>(_onDeleteProvider);
    on<SetDefaultProvider>(_onSetDefaultProvider);
    on<TestProvider>(_onTestProvider);
    on<LoadSessions>(_onLoadSessions);
    on<SelectSession>(_onSelectSession);
    on<NewSession>(_onNewSession);
    on<DeleteSession>(_onDeleteSession);
    on<SendMessage>(_onSendMessage);
  }

  void _onLoadProviders(LoadProviders event, Emitter<AiState> emit) {
    final providers = _repository.getAllProviders();
    final selected = _repository.getDefaultProvider();
    emit(state.copyWith(
      status: AiStatus.ready,
      providers: providers,
      selectedProvider: selected,
    ));
  }

  Future<void> _onAddProvider(AddProvider event, Emitter<AiState> emit) async {
    await _repository.saveProvider(event.provider);
    final providers = _repository.getAllProviders();
    emit(state.copyWith(providers: providers, status: AiStatus.ready));
  }

  Future<void> _onUpdateProvider(UpdateProvider event, Emitter<AiState> emit) async {
    await _repository.saveProvider(event.provider);
    final providers = _repository.getAllProviders();
    final selected = _repository.getDefaultProvider();
    emit(state.copyWith(providers: providers, selectedProvider: selected));
  }

  Future<void> _onDeleteProvider(DeleteProvider event, Emitter<AiState> emit) async {
    await _repository.deleteProvider(event.id);
    final providers = _repository.getAllProviders();
    emit(state.copyWith(providers: providers));
  }

  Future<void> _onSetDefaultProvider(SetDefaultProvider event, Emitter<AiState> emit) async {
    final current = _repository.getProvider(event.id);
    if (current == null) return;
    final updated = current.copyWith(isDefault: true);
    await _repository.saveProvider(updated);
    final providers = _repository.getAllProviders();
    emit(state.copyWith(providers: providers, selectedProvider: updated));
  }

  Future<void> _onTestProvider(TestProvider event, Emitter<AiState> emit) async {
    emit(state.copyWith(isTesting: true));
    final ok = await _repository.testProviderConnection(event.provider);
    emit(state.copyWith(isTesting: false));
    if (!ok) {
      emit(state.copyWith(error: 'فشل الاتصال بالمزود'));
    }
  }

  void _onLoadSessions(LoadSessions event, Emitter<AiState> emit) {
    final sessions = _repository.getAllSessions();
    emit(state.copyWith(sessions: sessions));
  }

  void _onSelectSession(SelectSession event, Emitter<AiState> emit) {
    final session = _repository.getSession(event.sessionId);
    final messages = session != null ? _repository.getSessionMessages(event.sessionId) : <ChatMessage>[];
    emit(state.copyWith(currentSession: session, messages: messages));
  }

  Future<void> _onNewSession(NewSession event, Emitter<AiState> emit) async {
    final session = ChatSession(
      id: _uuid.v4(),
      title: 'محادثة جديدة',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    await _repository.saveSession(session);
    final sessions = _repository.getAllSessions();
    emit(state.copyWith(
      currentSession: session,
      sessions: sessions,
      messages: [],
    ));
  }

  Future<void> _onDeleteSession(DeleteSession event, Emitter<AiState> emit) async {
    await _repository.deleteSession(event.sessionId);
    final sessions = _repository.getAllSessions();
    final removed = state.currentSession?.id == event.sessionId;
    emit(state.copyWith(
      sessions: sessions,
      currentSession: removed ? null : state.currentSession,
      messages: removed ? [] : state.messages,
    ));
  }

  Future<void> _onSendMessage(SendMessage event, Emitter<AiState> emit) async {
    if (state.selectedProvider == null) {
      emit(state.copyWith(error: 'الرجاء تحديد مزود الذكاء الاصطناعي أولاً'));
      return;
    }

    final sessionId = state.currentSession?.id ?? _uuid.v4();
    final isNewSession = state.currentSession == null;
    final title = isNewSession ? event.text : state.currentSession!.title;

    final userMsg = ChatMessage(
      id: _uuid.v4(),
      sessionId: sessionId,
      role: 'user',
      content: event.text,
      timestamp: DateTime.now(),
    );

    final updatedMessages = [...state.messages, userMsg];
    emit(state.copyWith(
      status: AiStatus.sending,
      messages: updatedMessages,
    ));

    await _repository.saveMessage(userMsg);

    try {
      final response = await _repository.sendMessage(
        provider: state.selectedProvider!,
        sessionId: sessionId,
        message: event.text,
        systemPrompt: event.systemPrompt,
      );

      final aiMsg = ChatMessage(
        id: _uuid.v4(),
        sessionId: sessionId,
        role: 'assistant',
        content: response,
        timestamp: DateTime.now(),
      );
      await _repository.saveMessage(aiMsg);

      final session = ChatSession(
        id: sessionId,
        title: title.length > 50 ? '${title.substring(0, 50)}...' : title,
        createdAt: state.currentSession?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await _repository.saveSession(session);

      final sessions = _repository.getAllSessions();
      emit(state.copyWith(
        status: AiStatus.ready,
        messages: [...updatedMessages, aiMsg],
        currentSession: session,
        sessions: sessions,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: AiStatus.error,
        error: 'فشل إرسال الرسالة: ${e.toString()}',
      ));
    }
  }
}

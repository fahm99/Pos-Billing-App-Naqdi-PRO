import '../../domain/entities/ai_provider.dart';

abstract class AiEvent {}

class LoadProviders extends AiEvent {}

class AddProvider extends AiEvent {
  final AiProvider provider;
  AddProvider(this.provider);
}

class UpdateProvider extends AiEvent {
  final AiProvider provider;
  UpdateProvider(this.provider);
}

class DeleteProvider extends AiEvent {
  final String id;
  DeleteProvider(this.id);
}

class SetDefaultProvider extends AiEvent {
  final String id;
  SetDefaultProvider(this.id);
}

class TestProvider extends AiEvent {
  final AiProvider provider;
  TestProvider(this.provider);
}

class LoadSessions extends AiEvent {}

class SelectSession extends AiEvent {
  final String sessionId;
  SelectSession(this.sessionId);
}

class NewSession extends AiEvent {}

class DeleteSession extends AiEvent {
  final String sessionId;
  DeleteSession(this.sessionId);
}

class SendMessage extends AiEvent {
  final String text;
  final String? systemPrompt;
  SendMessage(this.text, {this.systemPrompt});
}

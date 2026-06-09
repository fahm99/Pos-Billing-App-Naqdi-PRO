import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../domain/entities/ai_provider.dart';
import '../../domain/entities/chat_message.dart';

class AiRemoteDataSource {
  Future<String> sendChatMessage({
    required AiProvider provider,
    required List<ChatMessage> history,
    required String userMessage,
    String? systemPrompt,
  }) async {
    final baseUrl = provider.baseUrl.isNotEmpty
        ? provider.baseUrl
        : _defaultBaseUrl(provider.name);

    switch (provider.name.toLowerCase()) {
      case 'gemini':
        return _sendGemini(provider, baseUrl, history, userMessage, systemPrompt);
      case 'claude':
        return _sendClaude(provider, baseUrl, history, userMessage, systemPrompt);
      case 'ollama':
        return _sendOllama(provider, baseUrl, history, userMessage, systemPrompt);
      default:
        return _sendOpenAICompatible(provider, baseUrl, history, userMessage, systemPrompt);
    }
  }

  Future<bool> testConnection(AiProvider provider) async {
    try {
      final baseUrl = provider.baseUrl.isNotEmpty
          ? provider.baseUrl
          : _defaultBaseUrl(provider.name);
      final client = http.Client();
      try {
        final uri = Uri.parse('$baseUrl/models').replace(queryParameters: {
          if (provider.name.toLowerCase() != 'ollama') 'key': provider.apiKey,
        });
        final response = await client.get(uri).timeout(Duration(seconds: provider.timeoutSeconds));
        return response.statusCode == 200;
      } finally {
        client.close();
      }
    } catch (_) {
      return false;
    }
  }

  String _defaultBaseUrl(String name) {
    switch (name.toLowerCase()) {
      case 'gemini':
        return 'https://generativelanguage.googleapis.com/v1beta';
      case 'openai':
        return 'https://api.openai.com/v1';
      case 'claude':
        return 'https://api.anthropic.com/v1';
      case 'openrouter':
        return 'https://openrouter.ai/api/v1';
      case 'deepseek':
        return 'https://api.deepseek.com/v1';
      case 'grok':
        return 'https://api.x.ai/v1';
      case 'ollama':
        return 'http://localhost:11434';
      default:
        return 'https://api.openai.com/v1';
    }
  }

  String _defaultModel(String name) {
    switch (name.toLowerCase()) {
      case 'gemini':
        return 'gemini-2.0-flash';
      case 'openai':
        return 'gpt-4o-mini';
      case 'claude':
        return 'claude-3-5-haiku-latest';
      case 'openrouter':
        return 'openai/gpt-4o-mini';
      case 'deepseek':
        return 'deepseek-chat';
      case 'grok':
        return 'grok-2-latest';
      case 'ollama':
        return 'llama3';
      default:
        return 'gpt-4o-mini';
    }
  }

  Future<String> _sendOpenAICompatible(
    AiProvider provider,
    String baseUrl,
    List<ChatMessage> history,
    String userMessage,
    String? systemPrompt,
  ) async {
    final model = provider.modelName.isNotEmpty ? provider.modelName : _defaultModel(provider.name);
    final messages = <Map<String, dynamic>>[];
    if (systemPrompt != null && systemPrompt.isNotEmpty) {
      messages.add({'role': 'system', 'content': systemPrompt});
    }
    for (final msg in history) {
      messages.add({'role': msg.role, 'content': msg.content});
    }
    messages.add({'role': 'user', 'content': userMessage});

    final response = await http
        .post(
          Uri.parse('$baseUrl/chat/completions'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer ${provider.apiKey}',
          },
          body: jsonEncode({
            'model': model,
            'messages': messages,
            'temperature': provider.temperature,
            'max_tokens': provider.maxTokens,
          }),
        )
        .timeout(Duration(seconds: provider.timeoutSeconds));

    if (response.statusCode != 200) {
      throw Exception('خطأ ${response.statusCode}: ${response.body}');
    }
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return data['choices']?[0]?['message']?['content'] as String? ?? '';
  }

  Future<String> _sendGemini(
    AiProvider provider,
    String baseUrl,
    List<ChatMessage> history,
    String userMessage,
    String? systemPrompt,
  ) async {
    final model = provider.modelName.isNotEmpty ? provider.modelName : _defaultModel('gemini');
    final contents = <Map<String, dynamic>>[];
    if (systemPrompt != null && systemPrompt.isNotEmpty) {
      contents.add({'role': 'user', 'parts': [{'text': '_system: $systemPrompt'}]});
      contents.add({'role': 'model', 'parts': [{'text': 'تم استلام التعليمات.'}]});
    }
    for (final msg in history) {
      contents.add({
        'role': msg.role == 'assistant' ? 'model' : 'user',
        'parts': [{'text': msg.content}],
      });
    }
    contents.add({'role': 'user', 'parts': [{'text': userMessage}]});

    final response = await http
        .post(
          Uri.parse('$baseUrl/models/$model:generateContent?key=${provider.apiKey}'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'contents': contents}),
        )
        .timeout(Duration(seconds: provider.timeoutSeconds));

    if (response.statusCode != 200) {
      throw Exception('خطأ ${response.statusCode}: ${response.body}');
    }
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final candidates = data['candidates'] as List?;
    if (candidates == null || candidates.isEmpty) return '';
    final parts = candidates[0]['content']?['parts'] as List?;
    if (parts == null || parts.isEmpty) return '';
    return parts[0]['text'] as String? ?? '';
  }

  Future<String> _sendClaude(
    AiProvider provider,
    String baseUrl,
    List<ChatMessage> history,
    String userMessage,
    String? systemPrompt,
  ) async {
    final model = provider.modelName.isNotEmpty ? provider.modelName : _defaultModel('claude');
    final messages = <Map<String, dynamic>>[];
    for (final msg in history) {
      messages.add({'role': msg.role, 'content': msg.content});
    }
    messages.add({'role': 'user', 'content': userMessage});

    final body = <String, dynamic>{
      'model': model,
      'max_tokens': provider.maxTokens,
      'messages': messages,
    };
    if (systemPrompt != null && systemPrompt.isNotEmpty) {
      body['system'] = systemPrompt;
    }

    final response = await http
        .post(
          Uri.parse('$baseUrl/messages'),
          headers: {
            'Content-Type': 'application/json',
            'x-api-key': provider.apiKey,
            'anthropic-version': '2023-06-01',
          },
          body: jsonEncode(body),
        )
        .timeout(Duration(seconds: provider.timeoutSeconds));

    if (response.statusCode != 200) {
      throw Exception('خطأ ${response.statusCode}: ${response.body}');
    }
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return data['content']?[0]?['text'] as String? ?? '';
  }

  Future<String> _sendOllama(
    AiProvider provider,
    String baseUrl,
    List<ChatMessage> history,
    String userMessage,
    String? systemPrompt,
  ) async {
    final model = provider.modelName.isNotEmpty ? provider.modelName : _defaultModel('ollama');
    final messages = <Map<String, dynamic>>[];
    if (systemPrompt != null && systemPrompt.isNotEmpty) {
      messages.add({'role': 'system', 'content': systemPrompt});
    }
    for (final msg in history) {
      messages.add({'role': msg.role, 'content': msg.content});
    }
    messages.add({'role': 'user', 'content': userMessage});

    final response = await http
        .post(
          Uri.parse('$baseUrl/api/chat'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'model': model,
            'messages': messages,
            'stream': false,
          }),
        )
        .timeout(Duration(seconds: provider.timeoutSeconds));

    if (response.statusCode != 200) {
      throw Exception('خطأ ${response.statusCode}: ${response.body}');
    }
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return data['message']?['content'] as String? ?? '';
  }
}

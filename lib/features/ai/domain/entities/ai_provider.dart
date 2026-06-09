class AiProvider {
  final String id;
  final String name;
  final String label;
  final String apiKey;
  final String baseUrl;
  final String modelName;
  final double temperature;
  final int maxTokens;
  final int timeoutSeconds;
  final bool isDefault;
  final bool isEnabled;

  const AiProvider({
    required this.id,
    required this.name,
    required this.label,
    required this.apiKey,
    this.baseUrl = '',
    this.modelName = '',
    this.temperature = 0.7,
    this.maxTokens = 2048,
    this.timeoutSeconds = 60,
    this.isDefault = false,
    this.isEnabled = true,
  });

  AiProvider copyWith({
    String? id,
    String? name,
    String? label,
    String? apiKey,
    String? baseUrl,
    String? modelName,
    double? temperature,
    int? maxTokens,
    int? timeoutSeconds,
    bool? isDefault,
    bool? isEnabled,
  }) {
    return AiProvider(
      id: id ?? this.id,
      name: name ?? this.name,
      label: label ?? this.label,
      apiKey: apiKey ?? this.apiKey,
      baseUrl: baseUrl ?? this.baseUrl,
      modelName: modelName ?? this.modelName,
      temperature: temperature ?? this.temperature,
      maxTokens: maxTokens ?? this.maxTokens,
      timeoutSeconds: timeoutSeconds ?? this.timeoutSeconds,
      isDefault: isDefault ?? this.isDefault,
      isEnabled: isEnabled ?? this.isEnabled,
    );
  }
}

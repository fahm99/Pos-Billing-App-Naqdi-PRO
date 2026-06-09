import 'package:hive/hive.dart';
import '../../domain/entities/ai_provider.dart';

part 'ai_provider_model.g.dart';

@HiveType(typeId: 13)
class AiProviderModel extends HiveObject {
  @HiveField(0)
  String id;
  @HiveField(1)
  String name;
  @HiveField(2)
  String label;
  @HiveField(3)
  String apiKey;
  @HiveField(4)
  String baseUrl;
  @HiveField(5)
  String modelName;
  @HiveField(6)
  double temperature;
  @HiveField(7)
  int maxTokens;
  @HiveField(8)
  int timeoutSeconds;
  @HiveField(9)
  bool isDefault;
  @HiveField(10)
  bool isEnabled;

  AiProviderModel({
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

  AiProvider toEntity() => AiProvider(
        id: id,
        name: name,
        label: label,
        apiKey: apiKey,
        baseUrl: baseUrl,
        modelName: modelName,
        temperature: temperature,
        maxTokens: maxTokens,
        timeoutSeconds: timeoutSeconds,
        isDefault: isDefault,
        isEnabled: isEnabled,
      );

  factory AiProviderModel.fromEntity(AiProvider entity) => AiProviderModel(
        id: entity.id,
        name: entity.name,
        label: entity.label,
        apiKey: entity.apiKey,
        baseUrl: entity.baseUrl,
        modelName: entity.modelName,
        temperature: entity.temperature,
        maxTokens: entity.maxTokens,
        timeoutSeconds: entity.timeoutSeconds,
        isDefault: entity.isDefault,
        isEnabled: entity.isEnabled,
      );
}

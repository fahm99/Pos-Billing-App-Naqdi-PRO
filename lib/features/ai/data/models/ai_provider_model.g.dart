part of 'ai_provider_model.dart';

class AiProviderModelAdapter extends TypeAdapter<AiProviderModel> {
  @override
  final int typeId = 13;

  @override
  AiProviderModel read(BinaryReader reader) {
    final numFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numFields; i++) reader.readByte(): reader.read(),
    };
    return AiProviderModel(
      id: fields[0] as String,
      name: fields[1] as String,
      label: fields[2] as String? ?? fields[1] as String,
      apiKey: fields[3] as String,
      baseUrl: fields[4] as String? ?? '',
      modelName: fields[5] as String? ?? '',
      temperature: fields[6] as double? ?? 0.7,
      maxTokens: fields[7] as int? ?? 2048,
      timeoutSeconds: fields[8] as int? ?? 60,
      isDefault: fields[9] as bool? ?? false,
      isEnabled: fields[10] as bool? ?? true,
    );
  }

  @override
  void write(BinaryWriter writer, AiProviderModel obj) {
    writer.writeByte(11);
    writer.writeByte(0); writer.write(obj.id);
    writer.writeByte(1); writer.write(obj.name);
    writer.writeByte(2); writer.write(obj.label);
    writer.writeByte(3); writer.write(obj.apiKey);
    writer.writeByte(4); writer.write(obj.baseUrl);
    writer.writeByte(5); writer.write(obj.modelName);
    writer.writeByte(6); writer.write(obj.temperature);
    writer.writeByte(7); writer.write(obj.maxTokens);
    writer.writeByte(8); writer.write(obj.timeoutSeconds);
    writer.writeByte(9); writer.write(obj.isDefault);
    writer.writeByte(10); writer.write(obj.isEnabled);
  }
}

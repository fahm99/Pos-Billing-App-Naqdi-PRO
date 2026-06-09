import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:billing_app/features/ai/domain/entities/ai_provider.dart';
import 'package:billing_app/features/ai/presentation/bloc/ai_bloc.dart';
import 'package:billing_app/features/ai/presentation/bloc/ai_event.dart';
import 'package:billing_app/features/ai/presentation/bloc/ai_state.dart';

class AiSettingsPage extends StatefulWidget {
  static const routeName = '/ai-settings';
  const AiSettingsPage({super.key});
  @override
  State<AiSettingsPage> createState() => _AiSettingsPageState();
}

class _AiSettingsPageState extends State<AiSettingsPage> {
  final _nameCtl = TextEditingController();
  final _apiKeyCtl = TextEditingController();
  final _baseUrlCtl = TextEditingController();
  final _modelCtl = TextEditingController();
  double _temperature = 0.7;
  int _maxTokens = 2048;
  int _timeout = 30;
  String _selectedName = 'openai';
  bool _isDefault = false;
  bool _isEnabled = true;

  static const providerNames = [
    'openai', 'gemini', 'claude', 'openrouter', 'deepseek', 'grok', 'ollama',
  ];

  static const providerLabels = {
    'openai': 'OpenAI',
    'gemini': 'Google Gemini',
    'claude': 'Anthropic Claude',
    'openrouter': 'OpenRouter',
    'deepseek': 'DeepSeek',
    'grok': 'xAI Grok',
    'ollama': 'Ollama (محلي)',
  };

  @override
  void dispose() {
    _nameCtl.dispose();
    _apiKeyCtl.dispose();
    _baseUrlCtl.dispose();
    _modelCtl.dispose();
    super.dispose();
  }

  void _clearFields() {
    _nameCtl.clear();
    _apiKeyCtl.clear();
    _baseUrlCtl.clear();
    _modelCtl.clear();
    _temperature = 0.7;
    _maxTokens = 2048;
    _timeout = 30;
    _isDefault = false;
    _isEnabled = true;
  }

  void _saveProvider() {
    if (_nameCtl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء إدخال اسم المزود')),
      );
      return;
    }
    final provider = AiProvider(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: _selectedName,
      label: _nameCtl.text,
      apiKey: _apiKeyCtl.text,
      baseUrl: _baseUrlCtl.text,
      modelName: _modelCtl.text,
      temperature: _temperature,
      maxTokens: _maxTokens,
      timeoutSeconds: _timeout,
      isDefault: _isDefault,
      isEnabled: _isEnabled,
    );
    context.read<AiBloc>().add(AddProvider(provider));
    _clearFields();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم إضافة المزود بنجاح')),
    );
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('إعدادات المساعد الذكي')),
        body: BlocConsumer<AiBloc, AiState>(
          listener: (context, state) {
            if (state.error != null && state.isTesting == false) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.error!)),
              );
            }
          },
          builder: (context, state) {
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // ── Existing Providers ──
                if (state.providers.isNotEmpty) ...[
                  Text('المزودون الحاليون', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  ...state.providers.map((p) => Card(
                    child: ListTile(
                      leading: Icon(
                        p.isEnabled ? Icons.check_circle : Icons.cancel,
                        color: p.isEnabled ? Colors.green : Colors.red,
                      ),
                      title: Text(p.label),
                      subtitle: Text(p.name),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (p.isDefault)
                            const Chip(label: Text('افتراضي', style: TextStyle(fontSize: 11))),
                          IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () {
                              context.read<AiBloc>().add(DeleteProvider(p.id));
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.check),
                            onPressed: () {
                              context.read<AiBloc>().add(SetDefaultProvider(p.id));
                            },
                          ),
                        ],
                      ),
                    ),
                  )),
                  const Divider(height: 32),
                ],
                // ── Add New Provider ──
                Text('إضافة مزود جديد', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),

                DropdownButtonFormField<String>(
                  value: _selectedName,
                  decoration: const InputDecoration(labelText: 'المزود', border: OutlineInputBorder()),
                  items: providerNames.map((n) => DropdownMenuItem(
                    value: n,
                    child: Text(providerLabels[n] ?? n),
                  )).toList(),
                  onChanged: (v) {
                    setState(() {
                      _selectedName = v!;
                      if (v == 'ollama') {
                        _baseUrlCtl.text = 'http://localhost:11434';
                      } else if (_baseUrlCtl.text == 'http://localhost:11434') {
                        _baseUrlCtl.clear();
                      }
                    });
                  },
                ),
                const SizedBox(height: 12),

                TextField(
                  controller: _nameCtl,
                  decoration: const InputDecoration(
                    labelText: 'اسم مخصص',
                    hintText: 'مثلاً: مزودي الرئيسي',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),

                TextField(
                  controller: _apiKeyCtl,
                  decoration: const InputDecoration(
                    labelText: 'مفتاح API',
                    hintText: 'sk-...',
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true,
                ),
                const SizedBox(height: 12),

                TextField(
                  controller: _baseUrlCtl,
                  decoration: const InputDecoration(
                    labelText: 'رابط API (اختياري)',
                    hintText: 'اترك فارغاً للافتراضي',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),

                TextField(
                  controller: _modelCtl,
                  decoration: const InputDecoration(
                    labelText: 'الموديل (اختياري)',
                    hintText: 'اترك فارغاً للافتراضي',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),

                Text('الحرارة: ${_temperature.toStringAsFixed(1)}'),
                Slider(
                  value: _temperature,
                  min: 0,
                  max: 2,
                  divisions: 20,
                  onChanged: (v) => setState(() => _temperature = v),
                ),
                const SizedBox(height: 8),

                Text('الحد الأقصى للرموز: $_maxTokens'),
                Slider(
                  value: _maxTokens.toDouble(),
                  min: 256,
                  max: 8192,
                  divisions: 31,
                  onChanged: (v) => setState(() => _maxTokens = v.toInt()),
                ),
                const SizedBox(height: 8),

                Text('مهلة الاتصال: $_timeout ثانية'),
                Slider(
                  value: _timeout.toDouble(),
                  min: 10,
                  max: 120,
                  divisions: 11,
                  onChanged: (v) => setState(() => _timeout = v.toInt()),
                ),
                const SizedBox(height: 12),

                CheckboxListTile(
                  title: const Text('مزود افتراضي'),
                  value: _isDefault,
                  onChanged: (v) => setState(() => _isDefault = v ?? false),
                ),
                CheckboxListTile(
                  title: const Text('مفعل'),
                  value: _isEnabled,
                  onChanged: (v) => setState(() => _isEnabled = v ?? true),
                ),
                const SizedBox(height: 16),

                ElevatedButton.icon(
                  onPressed: _saveProvider,
                  icon: const Icon(Icons.save),
                  label: const Text('حفظ المزود'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
                const SizedBox(height: 8),

                OutlinedButton.icon(
                  onPressed: () {
                    if (_selectedName.isEmpty) return;
                    final provider = AiProvider(
                      id: 'test',
                      name: _selectedName,
                      label: 'اختبار',
                      apiKey: _apiKeyCtl.text,
                      baseUrl: _baseUrlCtl.text,
                      modelName: _modelCtl.text,
                      temperature: _temperature,
                      maxTokens: _maxTokens,
                      timeoutSeconds: _timeout,
                      isDefault: false,
                      isEnabled: true,
                    );
                    context.read<AiBloc>().add(TestProvider(provider));
                  },
                  icon: state.isTesting
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.wifi_tethering),
                  label: Text(state.isTesting ? 'جارِ الاختبار...' : 'اختبار الاتصال'),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

import 'package:flutter/foundation.dart';

enum LlmProvider {
  geraet('Auf diesem Gerät'),
  ollama('Ollama (lokal)'),
  openAiCompatible('OpenAI-kompatibler Endpunkt');

  const LlmProvider(this.label);
  final String label;
}

/// Einstellungen für das Sprachmodell.
///
/// Standard ist ein offenes Modell, das direkt auf dem Gerät läuft
/// (Qwen3-4B-Instruct, Apache-2.0-Lizenz): kostenlos, offline, ohne Konto
/// und ohne dass Schülerdaten das Gerät verlassen. Im Browser, wo das nicht
/// zuverlässig geht, ist ein lokales Ollama mit Mistral NeMo voreingestellt.
class LlmSettings {
  const LlmSettings({
    this.provider = LlmProvider.ollama,
    this.baseUrl = defaultOllamaUrl,
    this.model = defaultModel,
    this.apiKey = '',
    this.temperature = 0.4,
    this.anonymisieren = true,
  });

  /// Modell direkt auf dem Gerät.
  const LlmSettings.geraet()
    : this(provider: LlmProvider.geraet, model: defaultGeraeteModell);

  /// Voreinstellung für die aktuelle Plattform.
  factory LlmSettings.standard() =>
      kIsWeb ? const LlmSettings() : const LlmSettings.geraet();

  factory LlmSettings.fromJson(Map<String, dynamic> json) {
    final providerName = json['provider'] as String?;
    return LlmSettings(
      provider: LlmProvider.values.firstWhere(
        (p) => p.name == providerName,
        orElse: () => LlmProvider.ollama,
      ),
      baseUrl: json['baseUrl'] as String? ?? defaultOllamaUrl,
      model: json['model'] as String? ?? defaultModel,
      apiKey: json['apiKey'] as String? ?? '',
      temperature: (json['temperature'] as num?)?.toDouble() ?? 0.4,
      anonymisieren: json['anonymisieren'] as bool? ?? true,
    );
  }

  static const defaultOllamaUrl = 'http://localhost:11434';
  static const defaultModel = 'mistral-nemo';

  /// Qwen3-4B-Instruct-2507 (Apache 2.0), 4-Bit-quantisiert, ca. 2,5 GB.
  static const defaultGeraeteModell =
      'hf://unsloth/Qwen3-4B-Instruct-2507-GGUF/'
      'Qwen3-4B-Instruct-2507-Q4_K_M.gguf';

  final LlmProvider provider;
  final String baseUrl;
  final String model;
  final String apiKey;
  final double temperature;
  final bool anonymisieren;

  LlmSettings copyWith({
    LlmProvider? provider,
    String? baseUrl,
    String? model,
    String? apiKey,
    double? temperature,
    bool? anonymisieren,
  }) => LlmSettings(
    provider: provider ?? this.provider,
    baseUrl: baseUrl ?? this.baseUrl,
    model: model ?? this.model,
    apiKey: apiKey ?? this.apiKey,
    temperature: temperature ?? this.temperature,
    anonymisieren: anonymisieren ?? this.anonymisieren,
  );

  /// Version des gespeicherten Formats; ältere Einstellungen ohne Version
  /// stammen aus der Zeit vor dem Modell auf dem Gerät.
  static const formatVersion = 2;

  Map<String, dynamic> toJson() => {
    'v': formatVersion,
    'provider': provider.name,
    'baseUrl': baseUrl,
    'model': model,
    'apiKey': apiKey,
    'temperature': temperature,
    'anonymisieren': anonymisieren,
  };
}

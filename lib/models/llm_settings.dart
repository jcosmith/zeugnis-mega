enum LlmProvider {
  ollama('Ollama (lokal)'),
  openAiCompatible('OpenAI-kompatibler Endpunkt');

  const LlmProvider(this.label);
  final String label;
}

/// Einstellungen für das Sprachmodell.
///
/// Standard ist ein lokal über Ollama laufendes, offenes Modell
/// (Mistral NeMo, Apache-2.0-Lizenz): kostenlos, ohne Konto und ohne dass
/// Schülerdaten den Rechner verlassen.
class LlmSettings {
  const LlmSettings({
    this.provider = LlmProvider.ollama,
    this.baseUrl = defaultOllamaUrl,
    this.model = defaultModel,
    this.apiKey = '',
    this.temperature = 0.4,
    this.anonymisieren = true,
  });

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

  Map<String, dynamic> toJson() => {
    'provider': provider.name,
    'baseUrl': baseUrl,
    'model': model,
    'apiKey': apiKey,
    'temperature': temperature,
    'anonymisieren': anonymisieren,
  };
}

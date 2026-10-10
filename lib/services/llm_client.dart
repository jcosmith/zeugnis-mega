import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/llm_settings.dart';
import 'on_device_llm.dart';

class LlmException implements Exception {
  LlmException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Schnittstelle zu einem Chat-Sprachmodell.
abstract class LlmClient {
  Future<String> complete({required String system, required String user});

  /// Liefert die verfügbaren Modelle, sofern der Endpunkt das unterstützt.
  Future<List<String>> listModels();

  factory LlmClient.fromSettings(LlmSettings settings, {http.Client? http}) {
    switch (settings.provider) {
      case LlmProvider.geraet:
        return GeraeteClient(settings);
      case LlmProvider.ollama:
        return OllamaClient(settings, httpClient: http);
      case LlmProvider.openAiCompatible:
        return OpenAiCompatibleClient(settings, httpClient: http);
    }
  }
}

/// Entfernt Denkprozess-Blöcke (z. B. `<think>…</think>` bei Qwen oder
/// DeepSeek) und überflüssige Leerzeichen aus einer Modellantwort.
String bereinigeAntwort(String text) {
  return text
      .replaceAll(RegExp(r'<think>[\s\S]*?</think>', caseSensitive: false), '')
      .trim();
}

Uri _join(String base, String path) {
  final b = base.endsWith('/') ? base.substring(0, base.length - 1) : base;
  return Uri.parse('$b$path');
}

Never _fehler(http.Response r) {
  var detail = r.body;
  try {
    final json = jsonDecode(r.body);
    if (json is Map && json['error'] != null) {
      final e = json['error'];
      detail = e is Map ? (e['message'] ?? e).toString() : e.toString();
    }
  } catch (_) {}
  throw LlmException(
    'Das Sprachmodell antwortete mit ${r.statusCode}: $detail',
  );
}

class OllamaClient implements LlmClient {
  OllamaClient(this.settings, {http.Client? httpClient})
    : _http = httpClient ?? http.Client();

  final LlmSettings settings;
  final http.Client _http;

  @override
  Future<String> complete({
    required String system,
    required String user,
  }) async {
    final http.Response r;
    try {
      r = await _http.post(
        _join(settings.baseUrl, '/api/chat'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'model': settings.model,
          'stream': false,
          'messages': [
            {'role': 'system', 'content': system},
            {'role': 'user', 'content': user},
          ],
          'options': {'temperature': settings.temperature},
        }),
      );
    } catch (e) {
      throw LlmException(
        'Ollama unter ${settings.baseUrl} ist nicht erreichbar. '
        'Läuft Ollama und ist das Modell „${settings.model}“ geladen '
        '(ollama pull ${settings.model})? Details: $e',
      );
    }
    if (r.statusCode != 200) _fehler(r);
    final json = jsonDecode(utf8.decode(r.bodyBytes)) as Map<String, dynamic>;
    final content = (json['message'] as Map?)?['content'] as String? ?? '';
    return bereinigeAntwort(content);
  }

  @override
  Future<List<String>> listModels() async {
    final r = await _http.get(_join(settings.baseUrl, '/api/tags'));
    if (r.statusCode != 200) _fehler(r);
    final json = jsonDecode(utf8.decode(r.bodyBytes)) as Map<String, dynamic>;
    return [
      for (final m in json['models'] as List? ?? [])
        (m as Map)['name'] as String,
    ];
  }
}

/// Für jeden Endpunkt mit OpenAI-kompatibler Chat-API, z. B. LM Studio,
/// llama.cpp-Server, vLLM oder gehostete Anbieter offener Modelle.
class OpenAiCompatibleClient implements LlmClient {
  OpenAiCompatibleClient(this.settings, {http.Client? httpClient})
    : _http = httpClient ?? http.Client();

  final LlmSettings settings;
  final http.Client _http;

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (settings.apiKey.isNotEmpty)
      'Authorization': 'Bearer ${settings.apiKey}',
  };

  @override
  Future<String> complete({
    required String system,
    required String user,
  }) async {
    final http.Response r;
    try {
      r = await _http.post(
        _join(settings.baseUrl, '/chat/completions'),
        headers: _headers,
        body: jsonEncode({
          'model': settings.model,
          'temperature': settings.temperature,
          'messages': [
            {'role': 'system', 'content': system},
            {'role': 'user', 'content': user},
          ],
        }),
      );
    } catch (e) {
      throw LlmException('${settings.baseUrl} ist nicht erreichbar: $e');
    }
    if (r.statusCode != 200) _fehler(r);
    final json = jsonDecode(utf8.decode(r.bodyBytes)) as Map<String, dynamic>;
    final choices = json['choices'] as List? ?? [];
    if (choices.isEmpty) throw LlmException('Leere Antwort vom Sprachmodell.');
    final content =
        ((choices.first as Map)['message'] as Map?)?['content'] as String? ??
        '';
    return bereinigeAntwort(content);
  }

  @override
  Future<List<String>> listModels() async {
    final r = await _http.get(
      _join(settings.baseUrl, '/models'),
      headers: _headers,
    );
    if (r.statusCode != 200) _fehler(r);
    final json = jsonDecode(utf8.decode(r.bodyBytes)) as Map<String, dynamic>;
    return [
      for (final m in json['data'] as List? ?? []) (m as Map)['id'] as String,
    ];
  }
}

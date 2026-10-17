import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zeugnis_mega/models/llm_settings.dart';
import 'package:zeugnis_mega/services/llm_client.dart';
import 'package:zeugnis_mega/services/on_device_llm.dart';
import 'package:zeugnis_mega/services/storage.dart';

void main() {
  test(
    'Ohne gespeicherte Einstellungen läuft das Modell auf dem Gerät',
    () async {
      SharedPreferences.setMockInitialValues({});
      final state = AppState(await SharedPreferences.getInstance());
      expect(state.settings.provider, LlmProvider.geraet);
      expect(state.settings.model, LlmSettings.defaultGeraeteModell);
      expect(LlmClient.fromSettings(state.settings), isA<GeraeteClient>());
    },
  );

  test('Alte Ollama-Voreinstellung wird auf das Gerät umgestellt', () async {
    SharedPreferences.setMockInitialValues({
      'llm_settings': jsonEncode({
        'provider': 'ollama',
        'baseUrl': LlmSettings.defaultOllamaUrl,
        'model': 'mistral-nemo',
        'anonymisieren': false,
      }),
    });
    final state = AppState(await SharedPreferences.getInstance());
    expect(state.settings.provider, LlmProvider.geraet);
    expect(state.settings.anonymisieren, isFalse);
  });

  test('Bewusst eingerichtetes Ollama bleibt erhalten', () async {
    SharedPreferences.setMockInitialValues({
      'llm_settings': jsonEncode({
        'provider': 'ollama',
        'baseUrl': 'http://192.168.1.20:11434',
        'model': 'mistral-nemo',
      }),
    });
    final state = AppState(await SharedPreferences.getInstance());
    expect(state.settings.provider, LlmProvider.ollama);
    expect(state.settings.baseUrl, 'http://192.168.1.20:11434');
  });

  test('Gespeicherte Einstellungen tragen die Formatversion', () {
    final json = const LlmSettings.geraet().toJson();
    expect(json['v'], LlmSettings.formatVersion);
    expect(LlmSettings.fromJson(json).provider, LlmProvider.geraet);
  });
}

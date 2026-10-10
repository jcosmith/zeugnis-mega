import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:zeugnis_mega/models/llm_settings.dart';
import 'package:zeugnis_mega/models/zeugnis.dart';
import 'package:zeugnis_mega/services/llm_client.dart';
import 'package:zeugnis_mega/services/zeugnis_generator.dart';

http.Response _json(Object body, [int status = 200]) => http.Response.bytes(
  utf8.encode(jsonEncode(body)),
  status,
  headers: {'content-type': 'application/json; charset=utf-8'},
);

void main() {
  test('Ollama-Client ruft /api/chat auf und entfernt Denkblöcke', () async {
    late Map<String, dynamic> gesendet;
    final mock = MockClient((req) async {
      expect(req.url.toString(), 'http://localhost:11434/api/chat');
      gesendet = jsonDecode(req.body) as Map<String, dynamic>;
      return _json({
        'message': {
          'role': 'assistant',
          'content': '<think>hm</think>\nDu liest schön.',
        },
      });
    });
    final client = LlmClient.fromSettings(const LlmSettings(), http: mock);
    final text = await client.complete(system: 'S', user: 'U');

    expect(text, 'Du liest schön.');
    expect(gesendet['model'], 'mistral-nemo');
    expect(gesendet['stream'], false);
    expect((gesendet['messages'] as List).first['content'], 'S');
  });

  test(
    'OpenAI-kompatibler Client nutzt /chat/completions und API-Schlüssel',
    () async {
      final mock = MockClient((req) async {
        expect(req.url.toString(), 'https://example.org/v1/chat/completions');
        expect(req.headers['Authorization'], 'Bearer geheim');
        return _json({
          'choices': [
            {
              'message': {'role': 'assistant', 'content': 'Text'},
            },
          ],
        });
      });
      final client = LlmClient.fromSettings(
        const LlmSettings(
          provider: LlmProvider.openAiCompatible,
          baseUrl: 'https://example.org/v1/',
          apiKey: 'geheim',
          model: 'm',
        ),
        http: mock,
      );
      expect(await client.complete(system: 'S', user: 'U'), 'Text');
    },
  );

  test(
    'Fehlermeldungen des Servers werden verständlich weitergegeben',
    () async {
      final mock = MockClient(
        (_) async => _json({'error': 'model "x" not found'}, 404),
      );
      final client = LlmClient.fromSettings(
        const LlmSettings(model: 'x'),
        http: mock,
      );
      expect(
        () => client.complete(system: 'S', user: 'U'),
        throwsA(
          isA<LlmException>().having(
            (e) => e.message,
            'message',
            contains('not found'),
          ),
        ),
      );
    },
  );

  test(
    'Generator setzt den Vornamen nach anonymer Anfrage wieder ein',
    () async {
      String? userPrompt;
      final mock = MockClient((req) async {
        final body = jsonDecode(req.body) as Map<String, dynamic>;
        userPrompt = (body['messages'] as List)[1]['content'] as String;
        return _json({
          'message': {'content': '[NAME] erkennt Bildkarten.'},
        });
      });
      const settings = LlmSettings(anonymisieren: true);
      final generator = ZeugnisGenerator(
        settings,
        client: LlmClient.fromSettings(settings, http: mock),
      );
      final z = Zeugnis.neu(id: '1')..vorname = 'Lena';
      final fach = z.faecher.first;
      fach.bereiche.first.stichworte = 'Lena zeigt auf Bildkarten';

      final text = await generator.fachText(z, fach);
      expect(text, 'Lena erkennt Bildkarten.');
      expect(userPrompt, isNot(contains('Lena')));
    },
  );

  test('Generator verweigert Fächer ohne Stichworte', () {
    final generator = ZeugnisGenerator(
      const LlmSettings(),
      client: LlmClient.fromSettings(
        const LlmSettings(),
        http: MockClient((_) async => fail('kein Aufruf erwartet')),
      ),
    );
    final z = Zeugnis.neu(id: '1');
    expect(
      () => generator.fachText(z, z.faecher.first),
      throwsA(isA<LlmException>()),
    );
  });
}

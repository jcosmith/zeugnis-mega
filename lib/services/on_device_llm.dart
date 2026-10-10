import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:llamadart/llamadart.dart';

import '../models/llm_settings.dart';
import 'llm_client.dart';

enum GeraeteModellStatus { nichtGeladen, laedt, bereit, fehler }

/// Hält das Sprachmodell, das direkt auf dem Gerät läuft (llama.cpp über
/// llamadart). Das Modell wird beim ersten Laden einmalig heruntergeladen
/// und liegt danach im App-Cache; Texte entstehen dann offline.
class GeraeteModell extends ChangeNotifier {
  GeraeteModell._();

  static final instance = GeraeteModell._();

  LlamaEngine? _engine;
  String? _geladeneQuelle;
  Future<void>? _laden;
  bool _generiert = false;

  GeraeteModellStatus status = GeraeteModellStatus.nichtGeladen;

  /// Fortschritt des Downloads (0–1) oder `null`, solange er unbekannt ist.
  double? fortschritt;
  int empfangeneBytes = 0;
  int? gesamtBytes;
  String? fehler;

  bool istBereitFuer(String quelle) =>
      status == GeraeteModellStatus.bereit && _geladeneQuelle == quelle;

  /// Lädt das Modell aus [quelle] (lokaler Pfad, URL oder `hf://…`).
  /// Mehrfache Aufrufe während des Ladens teilen sich einen Vorgang.
  Future<void> laden(String quelle) {
    if (istBereitFuer(quelle)) return Future.value();
    if (_laden != null && _geladeneQuelle == quelle) return _laden!;
    _geladeneQuelle = quelle;
    return _laden = _ladenIntern(quelle).whenComplete(() => _laden = null);
  }

  Future<void> _ladenIntern(String quelle) async {
    status = GeraeteModellStatus.laedt;
    fortschritt = null;
    empfangeneBytes = 0;
    gesamtBytes = null;
    fehler = null;
    notifyListeners();
    try {
      final engine = _engine ??= LlamaEngine(LlamaBackend());
      await engine.setModel(
        LlamaModel(ModelSource.parse(quelle)),
        params: const ModelParams(contextSize: 4096),
        onProgress: (p) {
          fortschritt = p.fraction;
          empfangeneBytes = p.receivedBytes;
          gesamtBytes = p.totalBytes;
          notifyListeners();
        },
      );
      status = GeraeteModellStatus.bereit;
    } catch (e) {
      status = GeraeteModellStatus.fehler;
      fehler = e is LlamaException ? e.message : e.toString();
      rethrow;
    } finally {
      notifyListeners();
    }
  }

  Future<String> complete({
    required String quelle,
    required String system,
    required String user,
    required double temperature,
  }) async {
    try {
      await laden(quelle);
    } catch (_) {
      throw LlmException(
        'Das Sprachmodell konnte nicht geladen werden: $fehler',
      );
    }
    if (_generiert) {
      throw LlmException('Es wird bereits ein Text formuliert.');
    }
    _generiert = true;
    try {
      final text = await _engine!
          .create(
            [
              LlamaChatMessage.fromText(
                role: LlamaChatRole.system,
                text: system,
              ),
              LlamaChatMessage.fromText(role: LlamaChatRole.user, text: user),
            ],
            params: GenerationParams(maxTokens: 900, temp: temperature),
            enableThinking: false,
          )
          .text();
      return bereinigeAntwort(text);
    } on LlamaException catch (e) {
      throw LlmException('Fehler im Sprachmodell: ${e.message}');
    } finally {
      _generiert = false;
    }
  }
}

/// [LlmClient] für das Modell auf dem Gerät.
class GeraeteClient implements LlmClient {
  GeraeteClient(this.settings, {GeraeteModell? modell})
    : modell = modell ?? GeraeteModell.instance;

  final LlmSettings settings;
  final GeraeteModell modell;

  @override
  Future<String> complete({required String system, required String user}) {
    return modell.complete(
      quelle: settings.model,
      system: system,
      user: user,
      temperature: settings.temperature,
    );
  }

  @override
  Future<List<String>> listModels() async => [settings.model];
}

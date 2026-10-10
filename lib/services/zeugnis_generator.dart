import '../models/llm_settings.dart';
import '../models/zeugnis.dart';
import 'llm_client.dart';
import 'prompt_builder.dart';

/// Erzeugt mit Hilfe des Sprachmodells die Texte eines Zeugnisses.
class ZeugnisGenerator {
  ZeugnisGenerator(this.settings, {LlmClient? client})
    : client = client ?? LlmClient.fromSettings(settings);

  final LlmSettings settings;
  final LlmClient client;

  Future<String> _frage(Zeugnis z, String Function(PromptBuilder) user) async {
    final pb = PromptBuilder(z, anonym: settings.anonymisieren);
    final antwort = await client.complete(system: pb.system, user: user(pb));
    // Den Platzhalter immer ersetzen: Auch ohne Anonymisierung wird er
    // genutzt, wenn kein Vorname eingetragen ist.
    return deanonymisiere(antwort, z.vorname);
  }

  Future<String> fachText(Zeugnis z, FachEintrag fach) {
    if (!fach.hatStichworte) {
      throw LlmException(
        'Für „${fach.name}“ sind noch keine Stichworte oder Schwerpunkte eingetragen.',
      );
    }
    return _frage(z, (pb) => pb.fach(fach));
  }

  Future<String> bemerkungText(Zeugnis z) {
    if (z.bemerkungStichworte.trim().isEmpty) {
      throw LlmException(
        'Für die Bemerkungen sind noch keine Stichworte eingetragen.',
      );
    }
    return _frage(z, (pb) => pb.bemerkung());
  }
}

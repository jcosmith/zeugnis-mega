import 'package:flutter_test/flutter_test.dart';
import 'package:zeugnis_mega/models/zeugnis.dart';
import 'package:zeugnis_mega/services/prompt_builder.dart';

Zeugnis _beispiel() {
  final z = Zeugnis.neu(id: '1', schuljahr: '2026/27')
    ..vorname = 'Mia'
    ..geschlecht = Geschlecht.weiblich;
  final deutsch = z.faecher.firstWhere((f) => f.fachId == 'deutsch');
  final lesen = deutsch.bereiche.firstWhere((b) => b.name.startsWith('Lesen'));
  lesen
    ..gewaehlteSchwerpunkte.add('Über Lesefähigkeiten verfügen')
    ..aneignungsebene = 'bildlich-darstellend'
    ..unterstuetzung = 'mit wenig Unterstützung'
    ..stichworte = 'Mia erkennt ihren Namen, liest Piktogramme im Stundenplan';
  return z;
}

void main() {
  test('Fachprompt enthält nur ausgefüllte Bereiche', () {
    final z = _beispiel();
    final deutsch = z.faecher.firstWhere((f) => f.fachId == 'deutsch');
    final prompt = PromptBuilder(z, anonym: false).fach(deutsch);

    expect(prompt, contains('Sprache und Kommunikation'));
    expect(prompt, contains('Bereich: Lesen – mit Texten und Medien umgehen'));
    expect(prompt, contains('Über Lesefähigkeiten verfügen'));
    expect(prompt, contains('bildlich-darstellend'));
    expect(prompt, contains('mit wenig Unterstützung'));
    expect(prompt, isNot(contains('Bereich: Schreiben')));
  });

  test(
    'Anonymisierung ersetzt den Vornamen in Stichworten und Systemprompt',
    () {
      final z = _beispiel();
      final deutsch = z.faecher.firstWhere((f) => f.fachId == 'deutsch');
      final pb = PromptBuilder(z, anonym: true);

      expect(pb.fach(deutsch), isNot(contains('Mia')));
      expect(pb.fach(deutsch), contains(namePlatzhalter));
      expect(pb.system, isNot(contains('Mia')));
    },
  );

  test('Systemprompt bildet NRW-Rahmen, Anrede und Pronomen ab', () {
    final z = _beispiel()..anrede = Anrede.dritte;
    final system = PromptBuilder(z, anonym: false).system;

    expect(system, contains('Geistige Entwicklung'));
    expect(system, contains('individuelle Bezugsnorm'));
    expect(system, contains('kompetenzorientiert'));
    expect(system, contains('„sie“'));
    expect(system, contains('3. Person'));
    expect(system, contains('Erfinde keine'));
  });

  test('Einfache Sprache wird angefordert', () {
    final z = _beispiel()..einfacheSprache = true;
    expect(
      PromptBuilder(z, anonym: false).system,
      contains('Einfacher Sprache'),
    );
  });

  test('anonymisiere und deanonymisiere sind umkehrbar', () {
    const text = 'Mia liest gern. MIA lacht. Miami bleibt.';
    final anonym = anonymisiere(text, 'Mia');
    expect(
      anonym,
      '$namePlatzhalter liest gern. $namePlatzhalter lacht. Miami bleibt.',
    );
    expect(
      deanonymisiere(anonym, 'Mia'),
      'Mia liest gern. Mia lacht. Miami bleibt.',
    );
  });
}

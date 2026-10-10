import 'package:flutter_test/flutter_test.dart';
import 'package:zeugnis_mega/data/curriculum_nrw_ge.dart';
import 'package:zeugnis_mega/models/zeugnis.dart';
import 'package:zeugnis_mega/services/export.dart';

void main() {
  test('Neues Zeugnis enthält alle Standardfächer', () {
    final z = Zeugnis.neu(id: 'x');
    expect(z.faecher.length, standardFaecher.length);
    expect(z.aktiveFaecher.map((f) => f.fachId), contains('mathematik'));
    expect(
      z.aktiveFaecher.map((f) => f.fachId),
      isNot(contains('arbeitswelt')),
    );
  });

  test('JSON-Rundreise erhält alle Eingaben', () {
    final z = Zeugnis.neu(id: 'x', schuljahr: '2026/27')
      ..vorname = 'Ben'
      ..geschlecht = Geschlecht.maennlich
      ..stufe = Stufe.mittelstufe
      ..anrede = Anrede.dritte
      ..einfacheSprache = true
      ..bemerkungStichworte = 'hilfsbereit';
    final mathe = z.faecher.firstWhere((f) => f.fachId == 'mathematik');
    mathe.bereiche[1]
      ..gewaehlteSchwerpunkte.add('Zahlverständnis')
      ..stichworte = 'zählt bis 20'
      ..aneignungsebene = 'aktiv-handelnd';
    mathe.text = 'Ben zählt sicher bis 20.';

    final kopie = Zeugnis.fromJson(z.toJson());
    expect(kopie.vorname, 'Ben');
    expect(kopie.geschlecht, Geschlecht.maennlich);
    expect(kopie.stufe, Stufe.mittelstufe);
    expect(kopie.anrede, Anrede.dritte);
    expect(kopie.einfacheSprache, isTrue);
    final m = kopie.faecher.firstWhere((f) => f.fachId == 'mathematik');
    expect(m.bereiche[1].gewaehlteSchwerpunkte, {'Zahlverständnis'});
    expect(m.bereiche[1].aneignungsebene, 'aktiv-handelnd');
    expect(m.text, 'Ben zählt sicher bis 20.');
  });

  test('Textexport enthält nur aktive Fächer mit Text', () {
    final z = Zeugnis.neu(id: 'x', schuljahr: '2026/27')..vorname = 'Ben';
    z.faecher.firstWhere((f) => f.fachId == 'mathematik').text = 'Mathe-Text';
    z.faecher.firstWhere((f) => f.fachId == 'arbeitswelt').text = 'inaktiv';
    final text = zeugnisAlsText(z);
    expect(text, contains('Zeugnis für Ben'));
    expect(text, contains('Mathematik\nMathe-Text'));
    expect(text, isNot(contains('inaktiv')));
    expect(text, isNot(contains('Sport')));
  });

  test('PDF wird erzeugt', () async {
    final z = Zeugnis.neu(id: 'x')..vorname = 'Jörg';
    z.faecher.first.text = 'Du erkennst „Wörter“ – prima.\n\nZweiter Absatz.';
    final bytes = await zeugnisAlsPdf(z);
    expect(bytes.length, greaterThan(500));
  });
}

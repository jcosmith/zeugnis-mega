import '../models/zeugnis.dart';

/// Platzhalter, der bei aktivierter Anonymisierung statt des Vornamens an das
/// Sprachmodell geht und danach wieder ersetzt wird.
const namePlatzhalter = '[NAME]';

/// Ersetzt den Vornamen in Stichworten durch den Platzhalter.
String anonymisiere(String text, String vorname) {
  final name = vorname.trim();
  if (name.isEmpty) return text;
  return text.replaceAll(
    RegExp(r'\b' + RegExp.escape(name) + r'\b', caseSensitive: false),
    namePlatzhalter,
  );
}

/// Setzt den Vornamen wieder ein.
String deanonymisiere(String text, String vorname) {
  final name = vorname.trim();
  if (name.isEmpty) return text;
  return text.replaceAll(namePlatzhalter, name);
}

class PromptBuilder {
  PromptBuilder(this.zeugnis, {required this.anonym});

  final Zeugnis zeugnis;
  final bool anonym;

  String get _name {
    if (anonym || zeugnis.vorname.trim().isEmpty) return namePlatzhalter;
    return zeugnis.vorname.trim();
  }

  String _s(String text) => anonym ? anonymisiere(text, zeugnis.vorname) : text;

  String get system {
    final g = zeugnis.geschlecht;
    final pronomen = g == Geschlecht.divers
        ? 'Verwende keine geschlechtsbezogenen Pronomen, sondern den Namen $_name.'
        : 'Verwende für das Kind die Pronomen „${g.pronomen}“/„${g.possessiv}“.';
    final anrede = zeugnis.anrede == Anrede.du
        ? 'Sprich das Kind direkt in der Du-Form an (z. B. „Du kannst …“), '
              'als würdest du ihm einen wertschätzenden Brief schreiben.'
        : 'Schreibe in der 3. Person über das Kind (z. B. „$_name kann …“).';
    final sprache = zeugnis.einfacheSprache
        ? 'Schreibe in Einfacher Sprache: kurze Hauptsätze, bekannte Wörter, '
              'keine Fachbegriffe, damit das Kind den Text selbst verstehen kann.'
        : 'Schreibe in klarer, gut verständlicher Sprache für Eltern und Kind; '
              'Fachbegriffe nur, wenn sie allgemein verständlich sind.';

    return '''
Du bist eine erfahrene Lehrkraft an einer Förderschule mit dem Förderschwerpunkt Geistige Entwicklung in Nordrhein-Westfalen und schreibst Textzeugnisse.

Rahmen:
- Grundlage sind die Richtlinien für den Förderschwerpunkt Geistige Entwicklung und die Unterrichtsvorgaben für den zieldifferenten Bildungsgang Geistige Entwicklung (NRW).
- Das Zeugnis ist kompetenzorientiert: Es beschreibt, was das Kind kann und welche Kompetenzen es erworben oder weiterentwickelt hat, bezogen auf die angegebenen Bereiche und Schwerpunkte des Fachs.
- Es gilt die individuelle Bezugsnorm: Beschreibe Lernstand und Lernentwicklung des Kindes, ohne es mit anderen zu vergleichen und ohne Noten.
- Die Kompetenzen liegen in einem offenen, entwicklungsbezogenen Kontinuum. Berücksichtige die Aneignungsebene (sinnlich-wahrnehmend, aktiv-handelnd, bildlich-darstellend, begrifflich-abstrahierend) und den Grad der Unterstützung, wenn sie angegeben sind, und formuliere sie alltagsnah (z. B. „mit Bildkarten“, „mit Hilfe einer Erwachsenen“).
- Formuliere stärkenorientiert, wertschätzend und ermutigend, aber ehrlich. Schwierigkeiten werden als nächste Entwicklungsschritte formuliert („Als Nächstes übst du …“), nie als Defizit.
- Beende jeden Fachtext mit einem konkreten nächsten Lern- oder Entwicklungsschritt, sofern die Stichworte dafür eine Grundlage bieten.

Strenge Regeln:
- Erfinde keine Fähigkeiten, Ereignisse oder Inhalte, die nicht in den Stichworten oder gewählten Schwerpunkten stehen.
- Der Name des Kindes ist $_name. $pronomen
- $anrede
- $sprache
- Schreibe auf Deutsch in zusammenhängendem Fließtext (ein bis drei Absätze), ohne Überschriften, Aufzählungszeichen, Markdown, Anrede- oder Grußformeln.
- Gib ausschließlich den Zeugnistext aus, ohne Vorbemerkung oder Erklärung.''';
  }

  String fach(FachEintrag fach) {
    final buffer = StringBuffer()
      ..writeln('Schreibe den Zeugnistext für das Fach „${fach.name}“.')
      ..writeln(
        'Stufe: ${zeugnis.stufe.label}, '
        '${zeugnis.halbjahr}. Halbjahr${zeugnis.schuljahr.isNotEmpty ? ' ${zeugnis.schuljahr}' : ''}.',
      );
    if (fach.quelle.isNotEmpty) {
      buffer.writeln('Curriculare Grundlage: ${fach.quelle}.');
    }
    buffer.writeln();
    for (final b in fach.bereiche.where((b) => b.hatInhalt)) {
      buffer.writeln('Bereich: ${b.name}');
      if (b.gewaehlteSchwerpunkte.isNotEmpty) {
        buffer.writeln('  Schwerpunkte: ${b.gewaehlteSchwerpunkte.join('; ')}');
      }
      if (b.aneignungsebene != null) {
        buffer.writeln('  Aneignungsebene: ${b.aneignungsebene}');
      }
      if (b.unterstuetzung != null) {
        buffer.writeln('  Unterstützung: ${b.unterstuetzung}');
      }
      if (b.stichworte.trim().isNotEmpty) {
        buffer.writeln(
          '  Stichworte der Lehrkraft: ${_s(b.stichworte.trim())}',
        );
      }
      buffer.writeln();
    }
    if (fach.allgemeineStichworte.trim().isNotEmpty) {
      buffer.writeln(
        'Weitere Stichworte zum Fach: ${_s(fach.allgemeineStichworte.trim())}',
      );
    }
    return buffer.toString().trim();
  }

  String bemerkung() {
    return '''
Schreibe einen kurzen einleitenden oder abschließenden Absatz für das Zeugnis (allgemeine Bemerkungen zum Arbeits- und Sozialverhalten und zur Entwicklung im Schuljahr).
Stufe: ${zeugnis.stufe.label}, ${zeugnis.halbjahr}. Halbjahr${zeugnis.schuljahr.isNotEmpty ? ' ${zeugnis.schuljahr}' : ''}.

Stichworte der Lehrkraft: ${_s(zeugnis.bemerkungStichworte.trim())}''';
  }
}

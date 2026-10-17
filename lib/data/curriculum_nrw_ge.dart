/// Fächer- und Kompetenzkatalog für den zieldifferenten Bildungsgang
/// Geistige Entwicklung in Nordrhein-Westfalen.
///
/// Quellen (Lehrplannavigator NRW, QUA-LiS):
/// * Unterrichtsvorgaben für die Entwicklungsbereiche (2022)
/// * Unterrichtsvorgaben für das Aufgabenfeld Sprache und Kommunikation (2022)
/// * Unterrichtsvorgaben für das Aufgabenfeld Mathematik (2022)
/// * Unterrichtsvorgaben für die Aufgabenfelder Gesellschaftswissenschaftlicher
///   Unterricht, Naturwissenschaftlicher Unterricht sowie Wirtschaft und
///   Arbeitswelt (in Kraft seit 01.08.2024)
/// * Richtlinien für den Förderschwerpunkt Geistige Entwicklung
///
/// Für Fächer ohne eigene GE-Unterrichtsvorgaben (Kunst, Musik, Sport,
/// Religion) orientieren sich die Bereiche an den allgemeinen Lehrplänen der
/// Primarstufe; sie sind in der App frei anpassbar.
library;

import '../models/curriculum.dart';

const List<String> aneignungsebenen = [
  'sinnlich-wahrnehmend',
  'aktiv-handelnd',
  'bildlich-darstellend',
  'begrifflich-abstrahierend',
];

const List<String> unterstuetzungsgrade = [
  'selbstständig',
  'mit wenig Unterstützung',
  'mit Unterstützung',
  'mit umfassender Unterstützung',
];

const List<FachVorlage> standardFaecher = [
  FachVorlage(
    id: 'deutsch',
    name: 'Sprache und Kommunikation (Deutsch)',
    quelle: 'Unterrichtsvorgaben Aufgabenfeld Sprache und Kommunikation',
    bereiche: [
      Bereich(
        name: 'Kommunizieren – Sprechen und Zuhören',
        schwerpunkte: [
          'Verstehend Zuhören und Zuhörstrategien nutzen',
          'Mit anderen kommunizieren',
          'Vor anderen sprechen und etwas (szenisch) darstellen',
        ],
        beispiele: [
          'kommuniziert intentional über körpereigene verbale und nonverbale Kommunikationsformen',
          'hält einfache Gesprächsregeln ein (u.a. Blickkontakt, Zuhören, Ausreden lassen)',
        ],
      ),
      Bereich(
        name: 'Schreiben',
        schwerpunkte: [
          'Über Schreibfertigkeiten verfügen',
          'Schreibstrategien nutzen und Texte verfassen',
          'Rechtschreibstrategien nutzen und richtig schreiben',
        ],
        beispiele: [
          'verursacht Spuren als persönlichen Ausdruck',
          'verfasst Texte kriteriengeleitet in analoger / digitaler Form',
        ],
      ),
      Bereich(
        name: 'Lesen – mit Texten und Medien umgehen',
        schwerpunkte: [
          'Über Lesefähigkeiten verfügen',
          'Lesestrategien nutzen',
          'Sich mit Texten und Medien auseinandersetzen',
          'Über Leseerfahrungen verfügen',
        ],
        beispiele: [
          'erkennt Gegenstände, Personen und Situationen auf Abbildungen (wieder)',
          'liest einen Text sinnentnehmend',
        ],
      ),
      Bereich(
        name: 'Sprache und Sprachgebrauch untersuchen',
        schwerpunkte: [
          'Sprachliche Verständigung erforschen',
          'An Wörtern, Sätzen und Texten arbeiten',
          'Gemeinsamkeiten und Unterschiede von Sprache entdecken',
        ],
        beispiele: [
          'erkennt Satzgrenzen bei einfachen Hauptsätzen',
          'unterscheidet Satzarten (Aussagesatz, Fragesatz, Ausrufesatz)',
        ],
      ),
    ],
  ),
  FachVorlage(
    id: 'mathematik',
    name: 'Mathematik',
    quelle: 'Unterrichtsvorgaben Aufgabenfeld Mathematik',
    bereiche: [
      Bereich(
        name: 'Prozessbezogene Kompetenzen',
        schwerpunkte: [
          'Problemlösen',
          'Modellieren',
          'Kommunizieren',
          'Argumentieren',
          'Darstellen und Arbeiten mit Werkzeugen',
        ],
        beispiele: [
          'löst mathematische Problemstellungen durch Ausprobieren (Versuch-Irrtum)',
          'beschreibt die eigene Vorgehensweise (handlungsbegleitendes Sprechen)',
          'nutzt konkrete Materialien, um mathematische Sachzusammenhänge darzustellen (enaktiv)',
        ],
      ),
      Bereich(
        name: 'Zahlen und Operationen',
        schwerpunkte: [
          'Kategorienbildung und Mengenverständnis',
          'Zahlverständnis',
          'Operationsverständnis',
          'Zahlenrechnen',
        ],
        beispiele: [
          'sortiert Gegenstände und strukturierte Materialien nach Vergleichsmerkmalen',
          'bildet und löst Verdopplungsaufgaben',
        ],
      ),
      Bereich(
        name: 'Raum und Form',
        schwerpunkte: [
          'Raumorientierung und Raumvorstellung',
          'Geometrische Formen und Körper',
          'Operationen mit ebenen Figuren und Körpern',
        ],
        beispiele: [
          'bewegt sich entlang eines markierten Weges',
          'erkennt geometrische Grundformen in der Umwelt wieder und benennt diese',
        ],
      ),
      Bereich(
        name: 'Größen und Messen',
        schwerpunkte: [
          'Zeit',
          'Geld',
          'Gewichte',
          'Rauminhalte',
          'Längen',
          'Digitale Daten',
        ],
        beispiele: [
          'kennt die Wochentage und gibt deren Ablauf an',
          'stellt halbe Stunden auf einer analogen Anzeige ein und liest die Uhrzeit ab',
        ],
      ),
      Bereich(
        name: 'Daten, Häufigkeiten und Wahrscheinlichkeiten',
        schwerpunkte: ['Daten und Häufigkeiten', 'Wahrscheinlichkeiten'],
      ),
    ],
  ),
  FachVorlage(
    id: 'sachunterricht',
    name: 'Sachunterricht',
    quelle: 'orientiert am Lehrplan Sachunterricht (Primarstufe)',
    bereiche: [
      Bereich(name: 'Natur und Leben'),
      Bereich(name: 'Technik, digitale Technologie und Arbeit'),
      Bereich(name: 'Raum, Umwelt und Mobilität'),
      Bereich(name: 'Mensch und Gemeinschaft'),
      Bereich(name: 'Zeit und Wandel'),
    ],
  ),
  FachVorlage(
    id: 'gesellschaft',
    name: 'Gesellschaftswissenschaftlicher Unterricht',
    quelle: 'Unterrichtsvorgaben Aufgabenfeld Gesellschaftswissenschaftlicher Unterricht (2024)',
    bereiche: [
      Bereich(name: 'Erdkunde'),
      Bereich(name: 'Geschichte'),
      Bereich(name: 'Politik'),
    ],
  ),
  FachVorlage(
    id: 'naturwissenschaften',
    name: 'Naturwissenschaftlicher Unterricht',
    quelle: 'Unterrichtsvorgaben Aufgabenfeld Naturwissenschaftlicher Unterricht (2024)',
    bereiche: [
      Bereich(name: 'Biologie'),
      Bereich(name: 'Chemie'),
      Bereich(name: 'Physik'),
    ],
  ),
  FachVorlage(
    id: 'arbeitswelt',
    name: 'Wirtschaft und Arbeitswelt',
    quelle:
        'Unterrichtsvorgaben Aufgabenfeld Wirtschaft und Arbeitswelt (2024)',
    bereiche: [
      Bereich(name: 'Wirtschaft'),
      Bereich(name: 'Hauswirtschaft'),
      Bereich(name: 'Technik'),
    ],
  ),
  FachVorlage(
    id: 'kunst',
    name: 'Kunst',
    quelle: 'orientiert am Lehrplan Kunst (Primarstufe)',
    bereiche: [
      Bereich(name: 'Bilder gestalten und betrachten'),
      Bereich(name: 'Plastisch gestalten'),
      Bereich(name: 'Spielen und Darstellen'),
    ],
  ),
  FachVorlage(
    id: 'musik',
    name: 'Musik',
    quelle: 'orientiert am Lehrplan Musik (Primarstufe)',
    bereiche: [
      Bereich(name: 'Musik machen'),
      Bereich(name: 'Musik hören'),
      Bereich(name: 'Musik umsetzen'),
    ],
  ),
  FachVorlage(
    id: 'sport',
    name: 'Sport',
    quelle: 'orientiert am Lehrplan Sport (Bewegungsfelder)',
    bereiche: [
      Bereich(name: 'Den Körper wahrnehmen und Bewegungsfähigkeiten ausprägen'),
      Bereich(name: 'Laufen, Springen, Werfen'),
      Bereich(name: 'Bewegen im Wasser – Schwimmen'),
      Bereich(name: 'Spielen in und mit Regelstrukturen'),
      Bereich(name: 'Gleiten, Fahren, Rollen'),
    ],
  ),
  FachVorlage(
    id: 'religion',
    name: 'Religionslehre / Praktische Philosophie',
    quelle: 'orientiert an den Lehrplänen der Primarstufe',
    bereiche: [
      Bereich(name: 'Ich und die Gemeinschaft'),
      Bereich(name: 'Fragen nach dem Leben und nach Gott'),
      Bereich(name: 'Feste und Rituale'),
    ],
  ),
  FachVorlage(
    id: 'entwicklung',
    name: 'Entwicklungsbereiche',
    quelle: 'Unterrichtsvorgaben für die Entwicklungsbereiche',
    bereiche: [
      Bereich(
        name: 'Motorik',
        schwerpunkte: [
          'die Körperposition ändern und aufrecht halten',
          'Gegenstände tragen, bewegen und handhaben',
          'Sich fortbewegen und Gehen',
          'die Zungen- und Mundmotorik gebrauchen',
          'die Kopf-, Augen- und Gesichtsmotorik gebrauchen',
        ],
      ),
      Bereich(
        name: 'Wahrnehmung',
        schwerpunkte: [
          'Vibratorische Wahrnehmung',
          'Vestibuläre Wahrnehmung',
          'Kinästhetische Wahrnehmung',
          'Taktile Wahrnehmung',
          'Gustatorische Wahrnehmung',
          'Olfaktorische Wahrnehmung',
          'Auditive Wahrnehmung',
          'Visuelle Wahrnehmung',
        ],
      ),
      Bereich(
        name: 'Kognition',
        schwerpunkte: [
          'Sensomotorische Entwicklung',
          'Gedächtnis',
          'Begriffsbildung und Vorstellung von der Welt',
          'Planvolles Handeln',
          'Beurteilen, Problemlösen, Bewerten',
          'Lernstrategien',
        ],
      ),
      Bereich(
        name: 'Sozialisation',
        schwerpunkte: [
          'Emotionalität – Wahrnehmung der eigenen Person und Biografie',
          'Emotionalität – emotionale Kompetenzen',
          'Emotionalität – soziomoralisches Handeln',
          'Soziabilität – soziales Handeln',
          'Soziabilität – interpersonale Kompetenzen',
          'Soziabilität – Gemeinschaftsleben und soziales Leben',
          'Soziabilität – Leben in der Demokratie',
        ],
      ),
      Bereich(
        name: 'Kommunikation',
        schwerpunkte: [
          'Funktionen der Stimme und des Sprechens',
          'Äußerungen produzieren',
          'Äußerungen aufnehmen',
          'Miteinander kommunizieren',
        ],
      ),
    ],
  ),
];

FachVorlage? fachVorlageById(String id) {
  for (final f in standardFaecher) {
    if (f.id == id) return f;
  }
  return null;
}

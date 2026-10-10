import '../data/curriculum_nrw_ge.dart';
import 'curriculum.dart';

enum Geschlecht {
  weiblich('weiblich', 'sie', 'ihr'),
  maennlich('männlich', 'er', 'sein'),
  divers('keine (nur Name)', '', '');

  const Geschlecht(this.label, this.pronomen, this.possessiv);

  final String label;
  final String pronomen;
  final String possessiv;
}

enum Anrede {
  du('Du-Form'),
  dritte('3. Person');

  const Anrede(this.label);
  final String label;
}

enum Stufe {
  unterstufe('Unterstufe / Primarstufe'),
  mittelstufe('Mittelstufe'),
  oberstufe('Oberstufe / Sekundarstufe I'),
  berufspraxis('Berufspraxisstufe');

  const Stufe(this.label);
  final String label;
}

T _enumByName<T extends Enum>(List<T> values, Object? name, T fallback) {
  for (final v in values) {
    if (v.name == name) return v;
  }
  return fallback;
}

/// Stichworte und Einschätzung der Lehrkraft zu einem Bereich eines Fachs.
class BereichEintrag {
  BereichEintrag({
    required this.name,
    List<String>? schwerpunkte,
    List<String>? beispiele,
    Set<String>? gewaehlteSchwerpunkte,
    this.stichworte = '',
    this.aneignungsebene,
    this.unterstuetzung,
  }) : schwerpunkte = schwerpunkte ?? [],
       beispiele = beispiele ?? [],
       gewaehlteSchwerpunkte = gewaehlteSchwerpunkte ?? {};

  factory BereichEintrag.fromVorlage(Bereich b) => BereichEintrag(
    name: b.name,
    schwerpunkte: List.of(b.schwerpunkte),
    beispiele: List.of(b.beispiele),
  );

  factory BereichEintrag.fromJson(Map<String, dynamic> json) => BereichEintrag(
    name: json['name'] as String? ?? '',
    schwerpunkte: _strings(json['schwerpunkte']),
    beispiele: _strings(json['beispiele']),
    gewaehlteSchwerpunkte: _strings(json['gewaehlteSchwerpunkte']).toSet(),
    stichworte: json['stichworte'] as String? ?? '',
    aneignungsebene: json['aneignungsebene'] as String?,
    unterstuetzung: json['unterstuetzung'] as String?,
  );

  String name;
  List<String> schwerpunkte;
  List<String> beispiele;
  Set<String> gewaehlteSchwerpunkte;
  String stichworte;
  String? aneignungsebene;
  String? unterstuetzung;

  /// Ein Bereich fließt nur in den Text ein, wenn die Lehrkraft etwas
  /// dazu angegeben hat.
  bool get hatInhalt =>
      stichworte.trim().isNotEmpty || gewaehlteSchwerpunkte.isNotEmpty;

  Map<String, dynamic> toJson() => {
    'name': name,
    'schwerpunkte': schwerpunkte,
    'beispiele': beispiele,
    'gewaehlteSchwerpunkte': gewaehlteSchwerpunkte.toList(),
    'stichworte': stichworte,
    'aneignungsebene': aneignungsebene,
    'unterstuetzung': unterstuetzung,
  };
}

/// Ein Fach im Zeugnis mit seinen Bereichen und dem erzeugten Text.
class FachEintrag {
  FachEintrag({
    required this.fachId,
    required this.name,
    this.quelle = '',
    this.aktiv = true,
    List<BereichEintrag>? bereiche,
    this.allgemeineStichworte = '',
    this.text = '',
  }) : bereiche = bereiche ?? [];

  factory FachEintrag.fromVorlage(FachVorlage v, {bool aktiv = true}) =>
      FachEintrag(
        fachId: v.id,
        name: v.name,
        quelle: v.quelle,
        aktiv: aktiv,
        bereiche: v.bereiche.map(BereichEintrag.fromVorlage).toList(),
      );

  factory FachEintrag.fromJson(Map<String, dynamic> json) => FachEintrag(
    fachId: json['fachId'] as String? ?? '',
    name: json['name'] as String? ?? '',
    quelle: json['quelle'] as String? ?? '',
    aktiv: json['aktiv'] as bool? ?? true,
    bereiche: (json['bereiche'] as List? ?? [])
        .map((e) => BereichEintrag.fromJson(Map<String, dynamic>.from(e)))
        .toList(),
    allgemeineStichworte: json['allgemeineStichworte'] as String? ?? '',
    text: json['text'] as String? ?? '',
  );

  String fachId;
  String name;
  String quelle;
  bool aktiv;
  List<BereichEintrag> bereiche;
  String allgemeineStichworte;
  String text;

  bool get hatStichworte =>
      allgemeineStichworte.trim().isNotEmpty ||
      bereiche.any((b) => b.hatInhalt);

  Map<String, dynamic> toJson() => {
    'fachId': fachId,
    'name': name,
    'quelle': quelle,
    'aktiv': aktiv,
    'bereiche': bereiche.map((b) => b.toJson()).toList(),
    'allgemeineStichworte': allgemeineStichworte,
    'text': text,
  };
}

class Zeugnis {
  Zeugnis({
    required this.id,
    this.vorname = '',
    this.geschlecht = Geschlecht.divers,
    this.klasse = '',
    this.schuljahr = '',
    this.halbjahr = 1,
    this.stufe = Stufe.unterstufe,
    this.anrede = Anrede.du,
    this.einfacheSprache = false,
    List<FachEintrag>? faecher,
    this.bemerkungStichworte = '',
    this.bemerkungText = '',
    DateTime? geaendert,
  }) : faecher = faecher ?? [],
       geaendert = geaendert ?? DateTime.now();

  /// Neues Zeugnis mit allen Standardfächern; Fächer der Sekundarstufe
  /// sind zunächst inaktiv, Sachunterricht ist es in höheren Stufen.
  factory Zeugnis.neu({required String id, String schuljahr = ''}) {
    return Zeugnis(
      id: id,
      schuljahr: schuljahr,
      faecher: [
        for (final v in standardFaecher)
          FachEintrag.fromVorlage(v, aktiv: _standardAktiv.contains(v.id)),
      ],
    );
  }

  factory Zeugnis.fromJson(Map<String, dynamic> json) => Zeugnis(
    id: json['id'] as String,
    vorname: json['vorname'] as String? ?? '',
    geschlecht: _enumByName(
      Geschlecht.values,
      json['geschlecht'],
      Geschlecht.divers,
    ),
    klasse: json['klasse'] as String? ?? '',
    schuljahr: json['schuljahr'] as String? ?? '',
    halbjahr: json['halbjahr'] as int? ?? 1,
    stufe: _enumByName(Stufe.values, json['stufe'], Stufe.unterstufe),
    anrede: _enumByName(Anrede.values, json['anrede'], Anrede.du),
    einfacheSprache: json['einfacheSprache'] as bool? ?? false,
    faecher: (json['faecher'] as List? ?? [])
        .map((e) => FachEintrag.fromJson(Map<String, dynamic>.from(e)))
        .toList(),
    bemerkungStichworte: json['bemerkungStichworte'] as String? ?? '',
    bemerkungText: json['bemerkungText'] as String? ?? '',
    geaendert: DateTime.tryParse(json['geaendert'] as String? ?? ''),
  );

  static const _standardAktiv = {
    'deutsch',
    'mathematik',
    'sachunterricht',
    'kunst',
    'musik',
    'sport',
    'religion',
    'entwicklung',
  };

  final String id;
  String vorname;
  Geschlecht geschlecht;
  String klasse;
  String schuljahr;
  int halbjahr;
  Stufe stufe;
  Anrede anrede;
  bool einfacheSprache;
  List<FachEintrag> faecher;
  String bemerkungStichworte;
  String bemerkungText;
  DateTime geaendert;

  List<FachEintrag> get aktiveFaecher => faecher.where((f) => f.aktiv).toList();

  String get titel => vorname.trim().isEmpty ? 'Neues Zeugnis' : vorname.trim();

  Map<String, dynamic> toJson() => {
    'id': id,
    'vorname': vorname,
    'geschlecht': geschlecht.name,
    'klasse': klasse,
    'schuljahr': schuljahr,
    'halbjahr': halbjahr,
    'stufe': stufe.name,
    'anrede': anrede.name,
    'einfacheSprache': einfacheSprache,
    'faecher': faecher.map((f) => f.toJson()).toList(),
    'bemerkungStichworte': bemerkungStichworte,
    'bemerkungText': bemerkungText,
    'geaendert': geaendert.toIso8601String(),
  };
}

List<String> _strings(Object? value) =>
    (value as List? ?? []).map((e) => e.toString()).toList();

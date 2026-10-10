/// Ein Bereich eines Fachs bzw. Aufgabenfelds mit seinen Schwerpunkten und
/// optionalen Beispiel-Kompetenzerwartungen aus den Unterrichtsvorgaben.
class Bereich {
  const Bereich({
    required this.name,
    this.schwerpunkte = const [],
    this.beispiele = const [],
  });

  final String name;
  final List<String> schwerpunkte;
  final List<String> beispiele;
}

/// Vorlage für ein Fach, aus der ein [FachEintrag] im Zeugnis entsteht.
class FachVorlage {
  const FachVorlage({
    required this.id,
    required this.name,
    required this.quelle,
    required this.bereiche,
  });

  final String id;
  final String name;
  final String quelle;
  final List<Bereich> bereiche;
}

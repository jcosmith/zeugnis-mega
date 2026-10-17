import 'dart:async';

import 'package:flutter/material.dart';

import '../data/curriculum_nrw_ge.dart';
import '../models/llm_settings.dart';
import '../models/zeugnis.dart';
import '../services/llm_client.dart';
import '../services/storage.dart';
import '../services/zeugnis_generator.dart';
import '../widgets/geraete_modell_karte.dart';
import '../widgets/synced_text_field.dart';
import 'preview_screen.dart';

class EditorScreen extends StatefulWidget {
  const EditorScreen({super.key, required this.state, required this.zeugnis});

  final AppState state;
  final Zeugnis zeugnis;

  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen> {
  Zeugnis get z => widget.zeugnis;

  /// Fächer (bzw. `null` für die Bemerkungen), für die gerade ein Text
  /// erzeugt wird.
  final Set<Object?> _laeuft = {};
  bool _alleLaufen = false;
  Timer? _speichernTimer;

  @override
  void dispose() {
    _speichernTimer?.cancel();
    widget.state.speichern(z);
    super.dispose();
  }

  /// Speichert verzögert, damit nicht bei jedem Tastendruck geschrieben wird.
  void _geaendert({bool neuZeichnen = false}) {
    if (neuZeichnen) setState(() {});
    _speichernTimer?.cancel();
    _speichernTimer = Timer(
      const Duration(milliseconds: 600),
      () => widget.state.speichern(z),
    );
  }

  ZeugnisGenerator get _generator => ZeugnisGenerator(widget.state.settings);

  void _zeigeFehler(Object e) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(e is LlmException ? e.message : 'Fehler: $e'),
        duration: const Duration(seconds: 8),
      ),
    );
  }

  /// Stellt sicher, dass ein Modell auf dem Gerät geladen ist, bevor
  /// formuliert wird; beim ersten Mal mit sichtbarem Download.
  Future<bool> _modellBereit() async {
    final s = widget.state.settings;
    if (s.provider != LlmProvider.geraet) return true;
    return stelleGeraeteModellBereit(context, s.model);
  }

  Future<bool> _fachErzeugen(FachEintrag fach, {bool geprueft = false}) async {
    if (!geprueft && !await _modellBereit()) return false;
    setState(() => _laeuft.add(fach));
    try {
      final text = await _generator.fachText(z, fach);
      fach.text = text;
      widget.state.speichern(z);
      return true;
    } catch (e) {
      _zeigeFehler(e);
      return false;
    } finally {
      if (mounted) setState(() => _laeuft.remove(fach));
    }
  }

  Future<void> _bemerkungErzeugen({bool geprueft = false}) async {
    if (!geprueft && !await _modellBereit()) return;
    setState(() => _laeuft.add(null));
    try {
      z.bemerkungText = await _generator.bemerkungText(z);
      widget.state.speichern(z);
    } catch (e) {
      _zeigeFehler(e);
    } finally {
      if (mounted) setState(() => _laeuft.remove(null));
    }
  }

  Future<void> _alleErzeugen() async {
    final offen = z.aktiveFaecher.where((f) => f.hatStichworte).toList();
    if (offen.isEmpty && z.bemerkungStichworte.trim().isEmpty) {
      _zeigeFehler(
        LlmException('Trage zuerst Stichworte zu mindestens einem Fach ein.'),
      );
      return;
    }
    final ueberschreiben = offen.any((f) => f.text.trim().isNotEmpty);
    if (ueberschreiben) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Alle Texte neu formulieren?'),
          content: const Text(
            'Bereits vorhandene Fachtexte werden durch neu formulierte ersetzt.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Abbrechen'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Neu formulieren'),
            ),
          ],
        ),
      );
      if (ok != true) return;
    }
    if (!mounted || !await _modellBereit()) return;
    setState(() => _alleLaufen = true);
    if (z.bemerkungStichworte.trim().isNotEmpty) {
      await _bemerkungErzeugen(geprueft: true);
    }
    // Nacheinander, damit ein lokales Modell nicht überlastet wird.
    for (final f in offen) {
      if (!mounted) return;
      if (!await _fachErzeugen(f, geprueft: true)) break;
    }
    if (mounted) setState(() => _alleLaufen = false);
  }

  Future<void> _fachHinzufuegen() async {
    final ergebnis = await showDialog<FachEintrag>(
      context: context,
      builder: (_) => const _NeuesFachDialog(),
    );
    if (ergebnis == null) return;
    z.faecher.add(ergebnis);
    _geaendert(neuZeichnen: true);
  }

  @override
  Widget build(BuildContext context) {
    final beschaeftigt = _alleLaufen || _laeuft.isNotEmpty;
    return Scaffold(
      appBar: AppBar(
        title: Text(z.titel),
        actions: [
          IconButton(
            tooltip: 'Alle Fächer formulieren',
            onPressed: beschaeftigt ? null : _alleErzeugen,
            icon: _alleLaufen
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.auto_awesome),
          ),
          IconButton(
            tooltip: 'Vorschau und Export',
            icon: const Icon(Icons.visibility_outlined),
            onPressed: () {
              widget.state.speichern(z);
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => PreviewScreen(zeugnis: z)),
              );
            },
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 48),
            children: [
              _KopfdatenKarte(zeugnis: z, onChanged: _geaendert),
              _BemerkungKarte(
                zeugnis: z,
                laeuft: _laeuft.contains(null),
                onChanged: _geaendert,
                onErzeugen: beschaeftigt ? null : _bemerkungErzeugen,
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                child: Text(
                  'Fächer',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              for (final fach in z.faecher)
                _FachKarte(
                  key: ObjectKey(fach),
                  fach: fach,
                  laeuft: _laeuft.contains(fach),
                  onChanged: _geaendert,
                  onErzeugen: beschaeftigt ? null : () => _fachErzeugen(fach),
                  onEntfernen: fachVorlageById(fach.fachId) == null
                      ? () {
                          z.faecher.remove(fach);
                          _geaendert(neuZeichnen: true);
                        }
                      : null,
                ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton.icon(
                  onPressed: _fachHinzufuegen,
                  icon: const Icon(Icons.add),
                  label: const Text('Eigenes Fach hinzufügen'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

typedef _OnChanged = void Function({bool neuZeichnen});

class _KopfdatenKarte extends StatelessWidget {
  const _KopfdatenKarte({required this.zeugnis, required this.onChanged});

  final Zeugnis zeugnis;
  final _OnChanged onChanged;

  @override
  Widget build(BuildContext context) {
    final z = zeugnis;
    Widget feld(Widget child, {double breite = 200}) =>
        SizedBox(width: breite, child: child);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Schülerin / Schüler',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                feld(
                  SyncedTextField(
                    value: z.vorname,
                    decoration: const InputDecoration(
                      labelText: 'Vorname',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (v) {
                      z.vorname = v;
                      onChanged();
                    },
                  ),
                ),
                feld(
                  DropdownButtonFormField<Geschlecht>(
                    initialValue: z.geschlecht,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Pronomen',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      for (final g in Geschlecht.values)
                        DropdownMenuItem(value: g, child: Text(g.label)),
                    ],
                    onChanged: (g) {
                      z.geschlecht = g!;
                      onChanged();
                    },
                  ),
                ),
                feld(
                  SyncedTextField(
                    value: z.klasse,
                    decoration: const InputDecoration(
                      labelText: 'Klasse',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (v) {
                      z.klasse = v;
                      onChanged();
                    },
                  ),
                  breite: 160,
                ),
                feld(
                  SyncedTextField(
                    value: z.schuljahr,
                    decoration: const InputDecoration(
                      labelText: 'Schuljahr',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (v) {
                      z.schuljahr = v;
                      onChanged();
                    },
                  ),
                  breite: 140,
                ),
                feld(
                  DropdownButtonFormField<int>(
                    initialValue: z.halbjahr,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Halbjahr',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 1, child: Text('1. Halbjahr')),
                      DropdownMenuItem(value: 2, child: Text('2. Halbjahr')),
                    ],
                    onChanged: (h) {
                      z.halbjahr = h!;
                      onChanged();
                    },
                  ),
                  breite: 160,
                ),
                feld(
                  DropdownButtonFormField<Stufe>(
                    initialValue: z.stufe,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Stufe',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      for (final s in Stufe.values)
                        DropdownMenuItem(value: s, child: Text(s.label)),
                    ],
                    onChanged: (s) {
                      z.stufe = s!;
                      onChanged();
                    },
                  ),
                  breite: 260,
                ),
                feld(
                  DropdownButtonFormField<Anrede>(
                    initialValue: z.anrede,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Anrede im Text',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      for (final a in Anrede.values)
                        DropdownMenuItem(value: a, child: Text(a.label)),
                    ],
                    onChanged: (a) {
                      z.anrede = a!;
                      onChanged();
                    },
                  ),
                  breite: 160,
                ),
              ],
            ),
            const SizedBox(height: 4),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Einfache Sprache'),
              subtitle: const Text(
                'Kurze Sätze, damit das Kind den Text selbst versteht',
              ),
              value: z.einfacheSprache,
              onChanged: (v) {
                z.einfacheSprache = v;
                onChanged(neuZeichnen: true);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _BemerkungKarte extends StatelessWidget {
  const _BemerkungKarte({
    required this.zeugnis,
    required this.laeuft,
    required this.onChanged,
    required this.onErzeugen,
  });

  final Zeugnis zeugnis;
  final bool laeuft;
  final _OnChanged onChanged;
  final VoidCallback? onErzeugen;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ExpansionTile(
        shape: const Border(),
        title: const Text('Allgemeine Bemerkungen'),
        subtitle: Text(
          zeugnis.bemerkungText.trim().isNotEmpty ? 'Text formuliert' : 'Arbeits- und Sozialverhalten, Entwicklung im Schuljahr (optional)',
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          SyncedTextField(
            value: zeugnis.bemerkungStichworte,
            minLines: 2,
            maxLines: 6,
            decoration: const InputDecoration(
              labelText: 'Stichworte',
              hintText:
                  'z. B. kommt gern zur Schule, hilft anderen, braucht Pausen',
              border: OutlineInputBorder(),
            ),
            onChanged: (v) {
              zeugnis.bemerkungStichworte = v;
              onChanged();
            },
          ),
          const SizedBox(height: 12),
          _ErzeugenZeile(laeuft: laeuft, onErzeugen: onErzeugen),
          const SizedBox(height: 12),
          SyncedTextField(
            value: zeugnis.bemerkungText,
            minLines: 3,
            maxLines: null,
            decoration: const InputDecoration(
              labelText: 'Text (bearbeitbar)',
              border: OutlineInputBorder(),
            ),
            onChanged: (v) {
              zeugnis.bemerkungText = v;
              onChanged();
            },
          ),
        ],
      ),
    );
  }
}

class _ErzeugenZeile extends StatelessWidget {
  const _ErzeugenZeile({required this.laeuft, required this.onErzeugen});

  final bool laeuft;
  final VoidCallback? onErzeugen;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        FilledButton.tonalIcon(
          onPressed: laeuft ? null : onErzeugen,
          icon: laeuft
              ? const SizedBox.square(
                  dimension: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.auto_awesome),
          label: Text(laeuft ? 'Wird formuliert …' : 'Text formulieren'),
        ),
      ],
    );
  }
}

class _FachKarte extends StatelessWidget {
  const _FachKarte({
    super.key,
    required this.fach,
    required this.laeuft,
    required this.onChanged,
    required this.onErzeugen,
    required this.onEntfernen,
  });

  final FachEintrag fach;
  final bool laeuft;
  final _OnChanged onChanged;
  final VoidCallback? onErzeugen;
  final VoidCallback? onEntfernen;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final status = !fach.aktiv
        ? 'Nicht im Zeugnis'
        : fach.text.trim().isNotEmpty
        ? 'Text formuliert'
        : fach.hatStichworte
        ? 'Stichworte eingetragen'
        : 'Noch leer';
    return Card(
      color: fach.aktiv ? null : theme.colorScheme.surfaceContainerLow,
      child: ExpansionTile(
        shape: const Border(),
        leading: Switch(
          value: fach.aktiv,
          onChanged: (v) {
            fach.aktiv = v;
            onChanged(neuZeichnen: true);
          },
        ),
        title: Text(fach.name),
        subtitle: Text(status),
        enabled: fach.aktiv,
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (fach.quelle.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                'Grundlage: ${fach.quelle}',
                style: theme.textTheme.bodySmall,
              ),
            ),
          for (final b in fach.bereiche)
            _BereichEditor(key: ObjectKey(b), bereich: b, onChanged: onChanged),
          const SizedBox(height: 8),
          SyncedTextField(
            value: fach.allgemeineStichworte,
            minLines: 1,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Weitere Stichworte zum Fach (optional)',
              hintText: 'z. B. Lieblingsthema, Lernweg, Interessen',
              border: OutlineInputBorder(),
            ),
            onChanged: (v) {
              final warLeer = fach.allgemeineStichworte.trim().isEmpty;
              fach.allgemeineStichworte = v;
              onChanged(neuZeichnen: warLeer != v.trim().isEmpty);
            },
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _ErzeugenZeile(laeuft: laeuft, onErzeugen: onErzeugen),
              const Spacer(),
              if (onEntfernen != null)
                TextButton.icon(
                  onPressed: onEntfernen,
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Fach entfernen'),
                ),
            ],
          ),
          const SizedBox(height: 12),
          SyncedTextField(
            value: fach.text,
            minLines: 4,
            maxLines: null,
            decoration: const InputDecoration(
              labelText: 'Zeugnistext (bearbeitbar)',
              alignLabelWithHint: true,
              border: OutlineInputBorder(),
            ),
            onChanged: (v) {
              final warLeer = fach.text.trim().isEmpty;
              fach.text = v;
              onChanged(neuZeichnen: warLeer != v.trim().isEmpty);
            },
          ),
        ],
      ),
    );
  }
}

class _BereichEditor extends StatefulWidget {
  const _BereichEditor({
    super.key,
    required this.bereich,
    required this.onChanged,
  });

  final BereichEintrag bereich;
  final _OnChanged onChanged;

  @override
  State<_BereichEditor> createState() => _BereichEditorState();
}

class _BereichEditorState extends State<_BereichEditor> {
  BereichEintrag get b => widget.bereich;

  void _aendern(VoidCallback f) {
    setState(f);
    widget.onChanged(neuZeichnen: true);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(b.name, style: theme.textTheme.titleSmall),
          if (b.schwerpunkte.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text('Schwerpunkte', style: theme.textTheme.labelMedium),
            const SizedBox(height: 4),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final s in b.schwerpunkte)
                  FilterChip(
                    label: Text(s),
                    selected: b.gewaehlteSchwerpunkte.contains(s),
                    onSelected: (sel) => _aendern(() {
                      sel
                          ? b.gewaehlteSchwerpunkte.add(s)
                          : b.gewaehlteSchwerpunkte.remove(s);
                    }),
                  ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              SizedBox(
                width: 250,
                child: DropdownButtonFormField<String?>(
                  initialValue: b.aneignungsebene,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Aneignungsebene',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('–')),
                    for (final e in aneignungsebenen)
                      DropdownMenuItem(value: e, child: Text(e)),
                  ],
                  onChanged: (v) => _aendern(() => b.aneignungsebene = v),
                ),
              ),
              SizedBox(
                width: 250,
                child: DropdownButtonFormField<String?>(
                  initialValue: b.unterstuetzung,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Unterstützung',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('–')),
                    for (final u in unterstuetzungsgrade)
                      DropdownMenuItem(value: u, child: Text(u)),
                  ],
                  onChanged: (v) => _aendern(() => b.unterstuetzung = v),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SyncedTextField(
            value: b.stichworte,
            minLines: 2,
            maxLines: 6,
            decoration: const InputDecoration(
              labelText:
                  'Stichworte: Was kann das Kind? Was hat sich entwickelt?',
              border: OutlineInputBorder(),
            ),
            onChanged: (v) {
              final warLeer = b.stichworte.trim().isEmpty;
              b.stichworte = v;
              widget.onChanged(neuZeichnen: warLeer != v.trim().isEmpty);
            },
          ),
          if (b.beispiele.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Kompetenzerwartungen aus den Unterrichtsvorgaben übernehmen:',
              style: theme.textTheme.labelMedium,
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final bsp in b.beispiele)
                  ActionChip(
                    avatar: const Icon(Icons.add, size: 16),
                    label: Text(bsp),
                    onPressed: () => _aendern(() {
                      final t = b.stichworte.trim();
                      b.stichworte = t.isEmpty ? bsp : '$t; $bsp';
                    }),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _NeuesFachDialog extends StatefulWidget {
  const _NeuesFachDialog();

  @override
  State<_NeuesFachDialog> createState() => _NeuesFachDialogState();
}

class _NeuesFachDialogState extends State<_NeuesFachDialog> {
  final _name = TextEditingController();
  final _bereiche = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _bereiche.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Eigenes Fach'),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _name,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Name des Fachs'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _bereiche,
              minLines: 3,
              maxLines: 8,
              decoration: const InputDecoration(
                labelText: 'Bereiche (einer pro Zeile)',
                hintText: 'z. B. Englisch\nHören und Sprechen\nWortschatz',
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Abbrechen'),
        ),
        FilledButton(
          onPressed: () {
            final name = _name.text.trim();
            if (name.isEmpty) return;
            var bereiche = _bereiche.text
                .split('\n')
                .map((e) => e.trim())
                .where((e) => e.isNotEmpty)
                .toList();
            if (bereiche.isEmpty) bereiche = [name];
            Navigator.pop(
              context,
              FachEintrag(
                fachId: 'eigen-${DateTime.now().microsecondsSinceEpoch}',
                name: name,
                bereiche: [for (final b in bereiche) BereichEintrag(name: b)],
              ),
            );
          },
          child: const Text('Hinzufügen'),
        ),
      ],
    );
  }
}

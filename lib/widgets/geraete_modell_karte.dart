import 'package:flutter/material.dart';

import '../services/on_device_llm.dart';

String _mb(int bytes) => (bytes / (1024 * 1024)).toStringAsFixed(0);

/// Zeigt den Zustand des Modells auf dem Gerät mit Download-Fortschritt und
/// einem Knopf zum Herunterladen bzw. Laden.
class GeraeteModellKarte extends StatelessWidget {
  const GeraeteModellKarte({super.key, required this.quelle, this.modell});

  final String quelle;
  final GeraeteModell? modell;

  @override
  Widget build(BuildContext context) {
    final m = modell ?? GeraeteModell.instance;
    final theme = Theme.of(context);
    return ListenableBuilder(
      listenable: m,
      builder: (context, _) {
        final bereit = m.istBereitFuer(quelle);
        final laedt = m.status == GeraeteModellStatus.laedt;
        final String text;
        if (bereit) {
          text = 'Das Modell ist geladen. Texte entstehen jetzt offline.';
        } else if (laedt) {
          text = m.empfangeneBytes > 0
              ? 'Wird heruntergeladen: ${_mb(m.empfangeneBytes)}'
                    '${m.gesamtBytes != null ? ' von ${_mb(m.gesamtBytes!)}' : ''} MB'
              : 'Modell wird geladen …';
        } else if (m.status == GeraeteModellStatus.fehler) {
          text = 'Fehler: ${m.fehler}';
        } else {
          text =
              'Beim ersten Mal wird das Modell einmalig heruntergeladen '
              '(ca. 2,5 GB, am besten im WLAN). Danach funktioniert alles '
              'ohne Internet.';
        }
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      bereit ? Icons.check_circle : Icons.download_for_offline,
                      color: bereit
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Modell auf diesem Gerät',
                      style: theme.textTheme.titleSmall,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(text),
                if (laedt) ...[
                  const SizedBox(height: 12),
                  LinearProgressIndicator(value: m.fortschritt),
                ],
                if (!bereit && !laedt) ...[
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: () => m.laden(quelle).catchError((_) {}),
                    icon: const Icon(Icons.download),
                    label: const Text('Modell laden'),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Dialog, der das Modell lädt und sich schließt, sobald es bereit ist.
/// Liefert `true`, wenn das Modell danach bereit ist.
Future<bool> stelleGeraeteModellBereit(
  BuildContext context,
  String quelle,
) async {
  final m = GeraeteModell.instance;
  if (m.istBereitFuer(quelle)) return true;
  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _ModellDialog(quelle: quelle, modell: m),
  );
  return m.istBereitFuer(quelle);
}

class _ModellDialog extends StatefulWidget {
  const _ModellDialog({required this.quelle, required this.modell});

  final String quelle;
  final GeraeteModell modell;

  @override
  State<_ModellDialog> createState() => _ModellDialogState();
}

class _ModellDialogState extends State<_ModellDialog> {
  @override
  void initState() {
    super.initState();
    widget.modell.addListener(_pruefen);
    widget.modell.laden(widget.quelle).catchError((_) {});
  }

  @override
  void dispose() {
    widget.modell.removeListener(_pruefen);
    super.dispose();
  }

  void _pruefen() {
    if (widget.modell.istBereitFuer(widget.quelle) && mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Sprachmodell vorbereiten'),
      content: SizedBox(
        width: 420,
        child: GeraeteModellKarte(quelle: widget.quelle, modell: widget.modell),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Im Hintergrund weiter'),
        ),
      ],
    );
  }
}

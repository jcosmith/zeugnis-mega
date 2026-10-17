import 'package:flutter/material.dart';

import '../models/zeugnis.dart';
import '../services/storage.dart';
import 'editor_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.state});

  final AppState state;

  void _oeffnen(BuildContext context, Zeugnis z) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => EditorScreen(state: state, zeugnis: z),
      ),
    );
  }

  Future<void> _loeschen(BuildContext context, Zeugnis z) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Zeugnis löschen?'),
        content: Text('Das Zeugnis für ${z.titel} wird endgültig gelöscht.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Löschen'),
          ),
        ],
      ),
    );
    if (ok == true) state.loeschen(z);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Zeugnis-Assistent'),
        actions: [
          IconButton(
            tooltip: 'Sprachmodell einstellen',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => SettingsScreen(state: state)),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _oeffnen(context, state.neuesZeugnis()),
        icon: const Icon(Icons.add),
        label: const Text('Neues Zeugnis'),
      ),
      body: ListenableBuilder(
        listenable: state,
        builder: (context, _) {
          final liste = state.zeugnisse;
          if (liste.isEmpty) {
            return const _LeererZustand();
          }
          return ListView.separated(
            padding: const EdgeInsets.only(bottom: 96, top: 8),
            itemCount: liste.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final z = liste[i];
              final fertig = z.aktiveFaecher
                  .where((f) => f.text.trim().isNotEmpty)
                  .length;
              return ListTile(
                leading: CircleAvatar(
                  child: Text(z.titel.characters.first.toUpperCase()),
                ),
                title: Text(z.titel),
                subtitle: Text(
                  [
                    if (z.klasse.isNotEmpty) 'Klasse ${z.klasse}',
                    if (z.schuljahr.isNotEmpty) z.schuljahr,
                    '${z.halbjahr}. Hj.',
                    '$fertig/${z.aktiveFaecher.length} Fächer formuliert',
                  ].join(' · '),
                ),
                onTap: () => _oeffnen(context, z),
                trailing: PopupMenuButton<String>(
                  onSelected: (aktion) {
                    if (aktion == 'kopie') {
                      _oeffnen(context, state.duplizieren(z));
                    } else if (aktion == 'loeschen') {
                      _loeschen(context, z);
                    }
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(
                      value: 'kopie',
                      child: Text('Als Vorlage für neues Zeugnis'),
                    ),
                    PopupMenuItem(value: 'loeschen', child: Text('Löschen')),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _LeererZustand extends StatelessWidget {
  const _LeererZustand();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.description_outlined,
                size: 64,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text('Noch keine Zeugnisse', style: theme.textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(
                'Lege ein Zeugnis an, trage je Fach Stichworte zu den Bereichen '
                'der NRW-Unterrichtsvorgaben (Förderschwerpunkt Geistige '
                'Entwicklung) ein und lass ein offenes Sprachmodell daraus einen '
                'kompetenzorientierten Text formulieren.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

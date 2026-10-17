import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:printing/printing.dart';

import '../models/zeugnis.dart';
import '../services/export.dart';

class PreviewScreen extends StatelessWidget {
  const PreviewScreen({super.key, required this.zeugnis});

  final Zeugnis zeugnis;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final faecher = zeugnisFaecher(zeugnis);
    final dateiname =
        'Zeugnis_${zeugnis.titel.replaceAll(RegExp(r'\s+'), '_')}.pdf';
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vorschau'),
        actions: [
          IconButton(
            tooltip: 'Als Text kopieren',
            icon: const Icon(Icons.copy),
            onPressed: () async {
              await Clipboard.setData(
                ClipboardData(text: zeugnisAlsText(zeugnis)),
              );
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Zeugnistext kopiert')),
                );
              }
            },
          ),
          IconButton(
            tooltip: 'PDF teilen',
            icon: const Icon(Icons.share_outlined),
            onPressed: () async => Printing.sharePdf(
              bytes: await zeugnisAlsPdf(zeugnis),
              filename: dateiname,
            ),
          ),
          IconButton(
            tooltip: 'Drucken',
            icon: const Icon(Icons.print_outlined),
            onPressed: () => Printing.layoutPdf(
              name: dateiname,
              onLayout: (_) => zeugnisAlsPdf(zeugnis),
            ),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text('Zeugnis', style: theme.textTheme.headlineMedium),
              Text(zeugnis.titel, style: theme.textTheme.titleLarge),
              Text(zeugnisKopfzeile(zeugnis), style: theme.textTheme.bodySmall),
              const SizedBox(height: 24),
              if (zeugnis.bemerkungText.trim().isNotEmpty) ...[
                SelectableText(
                  zeugnis.bemerkungText.trim(),
                  style: theme.textTheme.bodyLarge,
                ),
                const SizedBox(height: 24),
              ],
              if (faecher.isEmpty && zeugnis.bemerkungText.trim().isEmpty)
                const Text('Noch keine Texte formuliert.'),
              for (final f in faecher) ...[
                Text(f.name, style: theme.textTheme.titleMedium),
                const SizedBox(height: 6),
                SelectableText(f.text.trim(), style: theme.textTheme.bodyLarge),
                const SizedBox(height: 24),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

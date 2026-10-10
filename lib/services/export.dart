import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/zeugnis.dart';

String zeugnisKopfzeile(Zeugnis z) {
  final teile = [
    if (z.klasse.isNotEmpty) 'Klasse ${z.klasse}',
    if (z.schuljahr.isNotEmpty) 'Schuljahr ${z.schuljahr}',
    '${z.halbjahr}. Halbjahr',
  ];
  return teile.join(' · ');
}

/// Fächer, die im fertigen Zeugnis erscheinen.
List<FachEintrag> zeugnisFaecher(Zeugnis z) =>
    z.aktiveFaecher.where((f) => f.text.trim().isNotEmpty).toList();

/// Das Zeugnis als reiner Text, z. B. zum Einfügen in das Schulformular.
String zeugnisAlsText(Zeugnis z) {
  final b = StringBuffer()
    ..writeln('Zeugnis für ${z.titel}')
    ..writeln(zeugnisKopfzeile(z))
    ..writeln();
  if (z.bemerkungText.trim().isNotEmpty) {
    b
      ..writeln(z.bemerkungText.trim())
      ..writeln();
  }
  for (final f in zeugnisFaecher(z)) {
    b
      ..writeln(f.name)
      ..writeln(f.text.trim())
      ..writeln();
  }
  return b.toString().trim();
}

Future<Uint8List> zeugnisAlsPdf(Zeugnis z) async {
  // Roboto statt der PDF-Standardschrift, damit „“, – und Umlaute sicher
  // dargestellt werden.
  final theme = pw.ThemeData.withFont(
    base: pw.Font.ttf(await rootBundle.load('assets/fonts/Roboto-Regular.ttf')),
    bold: pw.Font.ttf(await rootBundle.load('assets/fonts/Roboto-Bold.ttf')),
  );
  final doc = pw.Document(title: 'Zeugnis ${z.titel}', theme: theme);
  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(56),
      build: (context) => [
        pw.Text(
          'Zeugnis',
          style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 4),
        pw.Text(z.titel, style: const pw.TextStyle(fontSize: 16)),
        pw.Text(zeugnisKopfzeile(z), style: const pw.TextStyle(fontSize: 11)),
        pw.SizedBox(height: 18),
        if (z.bemerkungText.trim().isNotEmpty) ...[
          pw.Paragraph(text: z.bemerkungText.trim()),
          pw.SizedBox(height: 8),
        ],
        for (final f in zeugnisFaecher(z)) ...[
          pw.Header(level: 2, text: f.name),
          for (final absatz in f.text.trim().split(RegExp(r'\n\s*\n')))
            pw.Paragraph(text: absatz.trim()),
        ],
      ],
    ),
  );
  return doc.save();
}

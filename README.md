# Zeugnis-Assistent

Flutter-App, die aus Stichworten der Lehrkraft **kompetenzorientierte Textzeugnisse**
für den **zieldifferenten Bildungsgang Geistige Entwicklung in NRW** formuliert –
nach Fächern gegliedert und mit Hilfe eines **offenen, kostenlosen Sprachmodells**.

## So funktioniert es

1. Zeugnis anlegen: Vorname, Pronomen, Klasse, Schuljahr, Halbjahr, Stufe,
   Du-Form oder 3. Person, optional Einfache Sprache.
2. Je Fach die Bereiche und Schwerpunkte der NRW-Unterrichtsvorgaben auswählen,
   Aneignungsebene und Unterstützungsgrad angeben und Stichworte notieren.
   Beispiel-Kompetenzerwartungen aus den Vorgaben lassen sich per Klick übernehmen.
3. „Text formulieren“ (je Fach) oder ✨ (alle Fächer): Das Sprachmodell schreibt
   einen stärkenorientierten Text nach individueller Bezugsnorm, der mit einem
   nächsten Entwicklungsschritt endet. Jeder Text bleibt frei bearbeitbar.
4. Vorschau: Text kopieren (z. B. in das Schulverwaltungsprogramm), als PDF
   teilen oder drucken.

Alle Daten bleiben lokal auf dem Gerät.

## Curriculare Grundlage

Der Katalog steht in [`lib/data/curriculum_nrw_ge.dart`](lib/data/curriculum_nrw_ge.dart):

| Fach in der App | Grundlage |
| --- | --- |
| Sprache und Kommunikation (Deutsch) | Unterrichtsvorgaben Aufgabenfeld Sprache und Kommunikation (2022): 4 Bereiche, 13 Schwerpunkte |
| Mathematik | Unterrichtsvorgaben Aufgabenfeld Mathematik (2022): prozessbezogene Kompetenzen und 4 Inhaltsbereiche |
| Gesellschaftswissenschaftlicher Unterricht | Unterrichtsvorgaben (in Kraft seit 01.08.2024): Erdkunde, Geschichte, Politik |
| Naturwissenschaftlicher Unterricht | Unterrichtsvorgaben (seit 01.08.2024): Biologie, Chemie, Physik |
| Wirtschaft und Arbeitswelt | Unterrichtsvorgaben (seit 01.08.2024): Wirtschaft, Hauswirtschaft, Technik |
| Entwicklungsbereiche | Unterrichtsvorgaben für die Entwicklungsbereiche (2022): Motorik, Wahrnehmung, Kognition, Sozialisation, Kommunikation mit allen Entwicklungsschwerpunkten |
| Sachunterricht, Kunst, Musik, Sport, Religion | keine eigenen GE-Vorgaben; Bereiche orientiert an den Lehrplänen der Primarstufe |

Die Aneignungsebenen (sinnlich-wahrnehmend, aktiv-handelnd, bildlich-darstellend,
begrifflich-abstrahierend) stammen aus den Unterrichtsvorgaben. Eigene Fächer
(z. B. Englisch, Förderunterricht) lassen sich im Zeugnis ergänzen.

Quellen: [Lehrplannavigator NRW – Geistige Entwicklung](https://www.schulentwicklung.nrw.de/lehrplaene/),
[BASS 20058](https://bass.schule.nrw/20058.htm).

## Sprachmodell

**Standard: Qwen3-4B-Instruct direkt auf dem Gerät** (über
[llamadart](https://pub.dev/packages/llamadart) / llama.cpp).

- *Offen und kostenlos:* Qwen3-4B-Instruct-2507 steht unter Apache-2.0-Lizenz.
  Kein Server, kein Konto, keine Kosten pro Anfrage.
- *Datenschutz:* Das Modell läuft offline auf dem Handy oder Rechner;
  Schülerdaten verlassen das Gerät nicht.
- *Einmaliger Download:* ca. 2,5 GB (4-Bit-GGUF von Hugging Face), danach im
  App-Cache. Empfohlen sind Geräte mit mindestens 6 GB Arbeitsspeicher; ein
  Fachtext dauert auf dem Handy etwa eine Minute.

Andere GGUF-Modelle lassen sich in den Einstellungen als `hf://…`, URL oder
Dateipfad eintragen.

Alternativ (z. B. im Browser, wo das Modell auf dem Gerät nicht zuverlässig
läuft): **[Ollama](https://ollama.com)** mit `mistral-nemo` (Apache 2.0) oder
jeder **OpenAI-kompatible Endpunkt** (LM Studio, llama.cpp-Server, vLLM oder ein
gehosteter Anbieter offener Modelle). Die Option „Vornamen nicht an das Modell
senden“ ist standardmäßig an: Der Name wird durch `[NAME]` ersetzt und erst in
der App wieder eingesetzt.

Hinweise für Ollama:

- **Web:** Ollama muss Anfragen aus dem Browser erlauben, z. B.
  `OLLAMA_ORIGINS="*" ollama serve`.
- **Android:** Adresse des Rechners eintragen und Ollama mit
  `OLLAMA_HOST=0.0.0.0` starten.

## Android-APK

Ein Tag `v*` (z. B. `v0.1.0`) oder ein manueller Start des Workflows baut über GitHub Actions eine APK und hängt sie an
ein GitHub-Release (Workflow `release-apk.yml`). Die APK ist mit dem
Debug-Schlüssel signiert: Sie lässt sich direkt installieren, ist aber nicht für
den Play Store gedacht. Gebaut wird für arm64 (praktisch alle aktuellen
Android-Handys, ab Android 10).

## Entwicklung

```sh
flutter pub get
flutter analyze
flutter test
flutter run -d chrome   # oder linux, macos, windows, android, ios
```

Aufbau:

- `lib/data/` – Fächer- und Kompetenzkatalog NRW GE
- `lib/models/` – Zeugnis, Fächer, Bereiche, LLM-Einstellungen
- `lib/services/` – Prompt-Aufbau, LLM-Clients (Ollama, OpenAI-kompatibel), Speicherung, Text-/PDF-Export
- `lib/screens/` – Übersicht, Zeugnis-Editor, Vorschau, Einstellungen

import 'package:flutter/material.dart';

import '../models/llm_settings.dart';
import '../services/llm_client.dart';
import '../services/storage.dart';
import '../widgets/geraete_modell_karte.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key, required this.state});

  final AppState state;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late LlmSettings _s = widget.state.settings;
  late final _url = TextEditingController(text: _s.baseUrl);
  late final _model = TextEditingController(text: _s.model);
  late final _key = TextEditingController(text: _s.apiKey);
  List<String> _modelle = [];
  String? _testErgebnis;
  bool _testLaeuft = false;

  @override
  void dispose() {
    _url.dispose();
    _model.dispose();
    _key.dispose();
    super.dispose();
  }

  void _setze(LlmSettings s) {
    setState(() => _s = s);
    widget.state.setSettings(s);
  }

  void _providerWechseln(LlmProvider p) {
    final url = switch (p) {
      LlmProvider.geraet => _s.baseUrl,
      LlmProvider.ollama => LlmSettings.defaultOllamaUrl,
      LlmProvider.openAiCompatible => 'http://localhost:1234/v1',
    };
    final model = switch (p) {
      LlmProvider.geraet => LlmSettings.defaultGeraeteModell,
      _ when _s.provider == LlmProvider.geraet => LlmSettings.defaultModel,
      _ => _s.model,
    };
    _url.text = url;
    _model.text = model;
    _modelle = [];
    _testErgebnis = null;
    _setze(_s.copyWith(provider: p, baseUrl: url, model: model));
  }

  Future<void> _testen() async {
    setState(() {
      _testLaeuft = true;
      _testErgebnis = null;
    });
    final client = LlmClient.fromSettings(_s);
    try {
      final modelle = await client.listModels();
      final vorhanden = modelle.any(
        (m) => m == _s.model || m.split(':').first == _s.model,
      );
      setState(() {
        _modelle = modelle;
        _testErgebnis = vorhanden || modelle.isEmpty
            ? 'Verbindung steht. ${modelle.length} Modell(e) verfügbar.'
            : 'Verbindung steht, aber „${_s.model}“ ist nicht installiert. '
                  'Wähle ein Modell aus der Liste oder lade es mit „ollama pull ${_s.model}“.';
      });
    } catch (e) {
      setState(() => _testErgebnis = 'Keine Verbindung: $e');
    } finally {
      if (mounted) setState(() => _testLaeuft = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final geraet = _s.provider == LlmProvider.geraet;
    return Scaffold(
      appBar: AppBar(title: const Text('Sprachmodell')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                color: theme.colorScheme.secondaryContainer,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    geraet
                        ? 'Empfohlen: Das offene Modell Qwen3-4B-Instruct '
                              '(Apache-2.0-Lizenz, gutes Deutsch) läuft direkt '
                              'auf diesem Gerät. Das ist kostenlos, braucht kein '
                              'Konto und die Schülerdaten verlassen das Gerät '
                              'nicht. Ein Text dauert auf dem Handy etwa eine '
                              'Minute; empfohlen sind Geräte mit mindestens '
                              '6 GB Arbeitsspeicher.'
                        : 'Ollama oder ein OpenAI-kompatibler Endpunkt mit einem '
                              'offenen Modell, z. B. „mistral-nemo“. Einrichtung: '
                              'Ollama von ollama.com installieren und einmalig '
                              '„ollama pull mistral-nemo“ ausführen.',
                  ),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<LlmProvider>(
                initialValue: _s.provider,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Wo läuft das Sprachmodell?',
                  border: OutlineInputBorder(),
                ),
                items: [
                  for (final p in LlmProvider.values)
                    DropdownMenuItem(value: p, child: Text(p.label)),
                ],
                onChanged: (p) => _providerWechseln(p!),
              ),
              if (geraet) ...[
                const SizedBox(height: 16),
                GeraeteModellKarte(quelle: _s.model),
              ] else ...[
                const SizedBox(height: 16),
                TextField(
                  controller: _url,
                  decoration: InputDecoration(
                    labelText: 'Adresse',
                    helperText: _s.provider == LlmProvider.ollama
                        ? 'Standard: ${LlmSettings.defaultOllamaUrl}'
                        : 'Basis-URL inkl. /v1, z. B. LM Studio: http://localhost:1234/v1',
                    border: const OutlineInputBorder(),
                  ),
                  onChanged: (v) => _setze(_s.copyWith(baseUrl: v.trim())),
                ),
              ],
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _model,
                      decoration: InputDecoration(
                        labelText: geraet ? 'Modellquelle (GGUF)' : 'Modell',
                        helperText: geraet
                            ? 'hf://…, URL oder Dateipfad; nur bei Bedarf ändern'
                            : null,
                        border: const OutlineInputBorder(),
                      ),
                      onChanged: (v) => _setze(_s.copyWith(model: v.trim())),
                    ),
                  ),
                  if (_modelle.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    PopupMenuButton<String>(
                      tooltip: 'Installierte Modelle',
                      icon: const Icon(Icons.arrow_drop_down_circle_outlined),
                      onSelected: (m) {
                        _model.text = m;
                        _setze(_s.copyWith(model: m));
                      },
                      itemBuilder: (_) => [
                        for (final m in _modelle)
                          PopupMenuItem(value: m, child: Text(m)),
                      ],
                    ),
                  ],
                ],
              ),
              if (_s.provider == LlmProvider.openAiCompatible) ...[
                const SizedBox(height: 16),
                TextField(
                  controller: _key,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'API-Schlüssel (falls nötig)',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (v) => _setze(_s.copyWith(apiKey: v.trim())),
                ),
              ],
              const SizedBox(height: 16),
              Text(
                'Kreativität (Temperatur): ${_s.temperature.toStringAsFixed(1)}',
              ),
              Slider(
                value: _s.temperature,
                max: 1.0,
                divisions: 10,
                label: _s.temperature.toStringAsFixed(1),
                onChanged: (v) => _setze(_s.copyWith(temperature: v)),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Vornamen nicht an das Modell senden'),
                subtitle: const Text(
                  'Der Name wird durch einen Platzhalter ersetzt und erst in der '
                  'App wieder eingesetzt. Wichtig bei Endpunkten außerhalb des '
                  'eigenen Rechners.',
                ),
                value: _s.anonymisieren,
                onChanged: (v) => _setze(_s.copyWith(anonymisieren: v)),
              ),
              const SizedBox(height: 8),
              if (!geraet)
                Row(
                  children: [
                    FilledButton.icon(
                      onPressed: _testLaeuft ? null : _testen,
                      icon: _testLaeuft
                          ? const SizedBox.square(
                              dimension: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.wifi_tethering),
                      label: const Text('Verbindung testen'),
                    ),
                  ],
                ),
              if (!geraet && _testErgebnis != null) ...[
                const SizedBox(height: 12),
                Text(_testErgebnis!),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

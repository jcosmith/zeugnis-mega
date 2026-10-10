import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/llm_settings.dart';
import '../models/zeugnis.dart';

/// Hält Zeugnisse und Einstellungen und speichert sie lokal auf dem Gerät.
class AppState extends ChangeNotifier {
  AppState(this._prefs) {
    _laden();
  }

  static const _zeugnisseKey = 'zeugnisse';
  static const _settingsKey = 'llm_settings';

  final SharedPreferences _prefs;
  final List<Zeugnis> _zeugnisse = [];
  LlmSettings _settings = LlmSettings.standard();

  List<Zeugnis> get zeugnisse {
    final list = List.of(_zeugnisse)
      ..sort((a, b) => b.geaendert.compareTo(a.geaendert));
    return List.unmodifiable(list);
  }

  LlmSettings get settings => _settings;

  void _laden() {
    final raw = _prefs.getString(_zeugnisseKey);
    if (raw != null) {
      try {
        _zeugnisse.addAll(
          (jsonDecode(raw) as List).map(
            (e) => Zeugnis.fromJson(Map<String, dynamic>.from(e)),
          ),
        );
      } catch (e) {
        debugPrint('Zeugnisse konnten nicht geladen werden: $e');
      }
    }
    final s = _prefs.getString(_settingsKey);
    if (s != null) {
      try {
        final json = jsonDecode(s) as Map<String, dynamic>;
        // Vor Version 2 war Ollama voreingestellt; auf das Modell auf dem
        // Gerät umstellen, sofern Ollama nicht bewusst eingerichtet wurde.
        final alteVoreinstellung =
            json['v'] == null &&
            json['provider'] == LlmProvider.ollama.name &&
            json['baseUrl'] == LlmSettings.defaultOllamaUrl;
        _settings = alteVoreinstellung
            ? LlmSettings.standard().copyWith(
                anonymisieren: json['anonymisieren'] as bool?,
              )
            : LlmSettings.fromJson(json);
      } catch (e) {
        debugPrint('Einstellungen konnten nicht geladen werden: $e');
      }
    }
  }

  Zeugnis neuesZeugnis() {
    final now = DateTime.now();
    final jahr = now.month >= 8 ? now.year : now.year - 1;
    final z = Zeugnis.neu(
      id: now.microsecondsSinceEpoch.toString(),
      schuljahr: '$jahr/${((jahr + 1) % 100).toString().padLeft(2, '0')}',
    );
    _zeugnisse.add(z);
    speichern(z);
    return z;
  }

  Zeugnis duplizieren(Zeugnis original) {
    final kopie = Zeugnis.fromJson({
      ...original.toJson(),
      'id': DateTime.now().microsecondsSinceEpoch.toString(),
      'vorname': '',
    });
    for (final f in kopie.faecher) {
      f.text = '';
      f.allgemeineStichworte = '';
      for (final b in f.bereiche) {
        b.stichworte = '';
        b.gewaehlteSchwerpunkte.clear();
        b.aneignungsebene = null;
        b.unterstuetzung = null;
      }
    }
    kopie
      ..bemerkungStichworte = ''
      ..bemerkungText = '';
    _zeugnisse.add(kopie);
    speichern(kopie);
    return kopie;
  }

  void loeschen(Zeugnis z) {
    _zeugnisse.removeWhere((e) => e.id == z.id);
    _persist();
  }

  void speichern([Zeugnis? geaendert]) {
    geaendert?.geaendert = DateTime.now();
    _persist();
  }

  void _persist() {
    _prefs.setString(
      _zeugnisseKey,
      jsonEncode(_zeugnisse.map((z) => z.toJson()).toList()),
    );
    notifyListeners();
  }

  void setSettings(LlmSettings s) {
    _settings = s;
    _prefs.setString(_settingsKey, jsonEncode(s.toJson()));
    notifyListeners();
  }
}

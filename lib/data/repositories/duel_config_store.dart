import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/duel_config.dart';

/// Persistiert die zuletzt **verwendete** Duell-Lobby-Konfiguration
/// (gespeichert beim Eröffnen einer Lobby, nicht bei jedem Tippen).
/// Die Lobby startet damit beim nächsten Mal mit den gewohnten
/// Einstellungen statt mit dem Standard.
class DuelConfigStore {
  const DuelConfigStore(this._prefs);

  static const _key = 'duel_config_v1';
  final SharedPreferences _prefs;

  /// `null` wenn noch nie gespeichert oder der Blob defekt ist —
  /// der Aufrufer fällt dann auf [DuelConfig.standard] zurück.
  DuelConfig? load() {
    final raw = _prefs.getString(_key);
    if (raw == null || raw.isEmpty) return null;
    try {
      return DuelConfig.tryFromJson(
        Map<String, dynamic>.from(jsonDecode(raw) as Map),
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> save(DuelConfig config) =>
      _prefs.setString(_key, jsonEncode(config.toJson()));
}

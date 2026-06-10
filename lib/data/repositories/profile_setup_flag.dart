import 'package:shared_preferences/shared_preferences.dart';

/// Lokales "Profil-Setup ist abgeschlossen"-Flag.
///
/// Wird gesetzt, sobald diese Installation je ein Remote-Profil gesehen hat
/// (App-Start mit Server-Kontakt oder erfolgreiches Setup). Das ProfileGate
/// nutzt es, um wiederkehrende Nutzer bei Netzwerkfehlern nicht hinter dem
/// Retry-Screen auszusperren — der blockiert nur noch den allerersten Start
/// (Pre-Launch-Audit A1, Apple Guideline 2.1).
class ProfileSetupFlag {
  const ProfileSetupFlag(this._prefs);

  static const _key = 'profile_setup_done_v1';
  final SharedPreferences _prefs;

  bool get isDone => _prefs.getBool(_key) ?? false;

  Future<void> markDone() => _prefs.setBool(_key, true);

  /// Für Account-Löschung: danach soll das Gate wieder wie beim Erststart
  /// verhalten (Setup-Screen statt Offline-Durchwinken).
  Future<void> reset() => _prefs.remove(_key);
}

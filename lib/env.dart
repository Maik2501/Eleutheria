/// Environment configuration provided via `--dart-define-from-file=.env`.
///
/// Setup:
///   1. Kopiere `.env.example` zu `.env` (gitignored)
///   2. Trag SUPABASE_URL und SUPABASE_ANON_KEY ein
///   3. Run via VSCode-Launch-Config oder:
///      flutter run --dart-define-from-file=.env
class Env {
  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  /// App-Version, wird in Feedback-Submissions mitgeschickt, damit du im
  /// Backend siehst, gegen welchen Build sich eine Rückmeldung richtet.
  /// Manuell mit `pubspec.yaml: version` synchron halten (zusammen mit dem
  /// Build-Code-Bump vor TestFlight).
  static const appVersion = '0.1.0+5';

  /// True wenn beide Werte gesetzt sind und Supabase initialisiert werden kann.
  static bool get hasSupabase =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
}

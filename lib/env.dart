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

  /// PayPal.me-Link für die "Unterstützung"-Karte in den Einstellungen.
  /// Leerstring → die Karte wird ausgeblendet. Format: `https://paypal.me/<name>`.
  ///
  /// Für die App-Store-Erst-Einreichung bewusst leer (Apple 3.1.1-Grauzone,
  /// siehe docs/CODE_REVIEW_2026-06-10.md A3). Nach dem Approval per Update
  /// wieder aktivieren bzw. durch IAP-Tip ersetzen.
  static const donatePayPalUrl = '';

  /// True wenn beide Werte gesetzt sind und Supabase initialisiert werden kann.
  static bool get hasSupabase =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
}

/// Environment configuration provided via `--dart-define`.
///
/// Build with:
/// ```
/// flutter run \
///   --dart-define=SUPABASE_URL=https://YOUR.supabase.co \
///   --dart-define=SUPABASE_ANON_KEY=YOUR_ANON_KEY
/// ```
class Env {
  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
}

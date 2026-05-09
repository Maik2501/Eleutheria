/// Helpers for letterbox/crossword input handling.
library;

/// Strips parentheticals, leading ellipses and trailing punctuation from
/// an answer. Keeps spaces, hyphens and German umlauts intact.
///
/// Examples:
///   "Das andere Geschlecht (1949)" → "Das andere Geschlecht"
///   "...bin ich."                  → "bin ich"
///   "Ist die Existenz!"            → "Ist die Existenz"
String normalizeForLetterbox(String raw) {
  var s = raw.trim();
  s = s.replaceAll(RegExp(r'\s*\([^)]*\)'), '').trim();
  s = s.replaceAll(RegExp(r'^[…\.…]+\s*'), '').trim();
  s = s.replaceAll(RegExp(r'^["„«»„“]+'), '').trim();
  s = s.replaceAll(RegExp(r'["„«»„“]+$'), '').trim();
  s = s.replaceAll(RegExp(r'[\.…!?,;…]+$'), '').trim();
  return s;
}

/// Returns the canonical comparison form: lowercase, umlauts unfolded,
/// non-letter characters dropped. Used to compare typed answer to target.
String canonicalize(String s) {
  final lower = s.toLowerCase();
  final unfolded = lower
      .replaceAll('ä', 'ae')
      .replaceAll('ö', 'oe')
      .replaceAll('ü', 'ue')
      .replaceAll('ß', 'ss');
  return unfolded.replaceAll(RegExp(r'[^a-z0-9]'), '');
}

/// True if the typed input matches the target answer, ignoring case,
/// umlaut form, whitespace, and trailing punctuation.
bool answersMatch(String typed, String target) =>
    canonicalize(typed) == canonicalize(target);

/// Whether a question's correct answer is suitable for letterbox input.
/// Filters out long answers, multi-line ones, or answers with awkward chars.
bool isLetterboxFriendly(String correctAnswer) {
  final normalized = normalizeForLetterbox(correctAnswer);
  if (normalized.isEmpty) return false;
  if (normalized.length > 24) return false;

  // Allow letters, digits, spaces, hyphens, German umlauts.
  final allowed = RegExp(r'^[A-Za-zÄÖÜäöüß0-9 \-]+$');
  if (!allowed.hasMatch(normalized)) return false;
  return true;
}

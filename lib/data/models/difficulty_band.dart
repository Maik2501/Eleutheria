/// Three pre-configured difficulty ranges the player picks at the
/// home screen. Maps directly onto [Question.difficulty] (1–5).
enum DifficultyBand {
  einstieg(1, 2, 'Einstieg', 'Stufen 1–2'),
  salon(1, 5, 'Salon', 'Alle Stufen'),
  meisterpruefung(3, 5, 'Meisterprüfung', 'Stufen 3–5');

  const DifficultyBand(this.min, this.max, this.label, this.subtitle);

  final int min;
  final int max;
  final String label;
  final String subtitle;

  /// Server-side leaderboard key (matches the `scores.difficulty_band`
  /// check constraint in migration 0002).
  String get serverKey => name;

  /// Best-fit band for an arbitrary range (loaded from a legacy profile).
  static DifficultyBand fromRange(int min, int max) {
    if (min >= 3) return DifficultyBand.meisterpruefung;
    if (max <= 2) return DifficultyBand.einstieg;
    return DifficultyBand.salon;
  }
}

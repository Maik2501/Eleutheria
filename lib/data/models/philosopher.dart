/// A philosopher entry — short, factual data we control entirely.
///
/// Kept as a plain Dart class (no Freezed/JSON codegen) so the seed data file
/// stays editable without running build_runner.
class Philosopher {
  const Philosopher({
    required this.id,
    required this.name,
    required this.years,
    required this.era,
    required this.school,
    required this.tagline,
    required this.imageAsset,
    this.aliases = const [],
  });

  /// Stable kebab-case id, e.g. `nietzsche`.
  final String id;

  /// Display name, e.g. `Friedrich Nietzsche`.
  final String name;

  /// Lifespan label, e.g. `1844 – 1900`.
  final String years;

  /// Era key — see [Era].
  final Era era;

  /// School / movement, e.g. `Existenzphilosophie`.
  final String school;

  /// One-line summary used on profile pop-ups.
  final String tagline;

  /// Asset path to the (user-generated) portrait, e.g.
  /// `assets/images/philosophers/nietzsche.webp`.
  final String imageAsset;

  /// Alternate spellings accepted in fuzzy answers, e.g. `Nietzsche`.
  final List<String> aliases;
}

enum Era {
  antike('Antike'),
  mittelalter('Mittelalter'),
  renaissance('Renaissance'),
  aufklaerung('Aufklärung'),
  neunzehntes('19. Jahrhundert'),
  modernePostmoderne('Moderne / Postmoderne'),
  zeitgenoessisch('Zeitgenössisch');

  const Era(this.label);
  final String label;
}

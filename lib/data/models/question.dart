/// Quiz question.
///
/// All question types share the same shape: a prompt, four options, the index
/// of the correct option, an optional educational note, and a difficulty.
///
/// We support multiple [QuestionCategory] values; the category dictates what
/// the prompt and options *represent* (a quote, a work title, an era, …) but
/// the rendering is unified through [QuestionCard].
class Question {
  const Question({
    required this.id,
    required this.category,
    required this.prompt,
    required this.options,
    required this.correctIndex,
    required this.difficulty,
    this.attribution,
    this.explanation,
    this.philosopherId,
    this.topicKey,
  });

  final String id;
  final QuestionCategory category;

  /// The prompt text. May be a quote (with surrounding quotation marks already
  /// included), a work title, or a question.
  final String prompt;

  /// Four answer options.
  final List<String> options;
  final int correctIndex;

  /// 1 (Anfänger) … 5 (Meister).
  final int difficulty;

  /// Optional source attribution for quotes — e.g., "Also sprach Zarathustra".
  /// Shown after answering, never before.
  final String? attribution;

  /// 1–2 sentences expanding on the answer. Shown on reveal — this is what
  /// makes the app *educational*, not just a guessing game.
  final String? explanation;

  /// Philosopher associated with the correct answer, if any. Used for the
  /// post-answer "Erfahre mehr"-link to the philosopher detail sheet.
  final String? philosopherId;

  /// Spoiler-grouping key. Two questions that would reveal each other's
  /// answer (e.g., a "name the philosopher of this quote" pair with a
  /// "complete this quote" pair on the *same* quote) should share a topicKey,
  /// so the session builder won't pick both at once. `null` = no grouping.
  final String? topicKey;

  String get correctAnswer => options[correctIndex];

  /// JSON-Repräsentation für den Supabase-Roundtrip. Spaltennamen sind
  /// in snake_case, da die DB-Konvention das so vorschreibt.
  Map<String, dynamic> toJson() => {
        'id': id,
        'category': category.name,
        'prompt': prompt,
        'options': options,
        'correct_index': correctIndex,
        'difficulty': difficulty,
        'attribution': attribution,
        'explanation': explanation,
        'philosopher_id': philosopherId,
        'topic_key': topicKey,
      };

  /// Defensiv: fehlende oder unbekannte Felder degradieren zu sinnvollen
  /// Defaults, damit ein älterer Client neuere DB-Zeilen nicht crasht.
  /// Liefert `null`, wenn Pflichtfelder fehlen oder die Kategorie
  /// unbekannt ist (z. B. neue Kategorie in der DB, alter Client).
  static Question? tryFromJson(Map<String, dynamic> json) {
    try {
      final id = json['id'] as String?;
      final categoryName = json['category'] as String?;
      final prompt = json['prompt'] as String?;
      final optionsRaw = json['options'] as List?;
      final correctIndex = (json['correct_index'] as num?)?.toInt();
      final difficulty = (json['difficulty'] as num?)?.toInt();
      if (id == null ||
          categoryName == null ||
          prompt == null ||
          optionsRaw == null ||
          correctIndex == null ||
          difficulty == null) {
        return null;
      }
      final category = QuestionCategory.values
          .where((c) => c.name == categoryName)
          .firstOrNull;
      if (category == null) return null;
      final options = optionsRaw.map((e) => e.toString()).toList();
      if (options.length < 2 ||
          correctIndex < 0 ||
          correctIndex >= options.length) {
        return null;
      }
      return Question(
        id: id,
        category: category,
        prompt: prompt,
        options: options,
        correctIndex: correctIndex,
        difficulty: difficulty,
        attribution: json['attribution'] as String?,
        explanation: json['explanation'] as String?,
        philosopherId: json['philosopher_id'] as String?,
        topicKey: json['topic_key'] as String?,
      );
    } catch (_) {
      return null;
    }
  }
}

enum QuestionCategory {
  quoteToPhilosopher(
    label: 'Zitat → Philosoph',
    eyebrow: 'Wer hat das gesagt?',
    icon: '"',
  ),
  workToAuthor(
    label: 'Werk → Autor',
    eyebrow: 'Wer schrieb dieses Werk?',
    icon: '◆',
  ),
  philosopherToEra(
    label: 'Philosoph → Epoche',
    eyebrow: 'In welcher Epoche?',
    icon: '⌛',
  ),
  conceptToSchool(
    label: 'Begriff → Schule',
    eyebrow: 'Welcher Strömung gehört dies an?',
    icon: '✦',
  ),
  completeQuote(
    label: 'Zitat vervollständigen',
    eyebrow: 'Setze fort:',
    icon: '…',
  ),
  whoCriticizedWhom(
    label: 'Kritik & Streit',
    eyebrow: 'Wer kritisierte wen?',
    icon: '⚔',
  );

  const QuestionCategory({
    required this.label,
    required this.eyebrow,
    required this.icon,
  });

  final String label;
  final String eyebrow;
  final String icon;
}

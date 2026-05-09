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

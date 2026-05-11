/// How the player answers a prompt.
enum AnswerInputStyle {
  /// Tap one of several visible choices.
  multipleChoice('multipleChoice'),

  /// Type the answer directly.
  letterbox('letterbox');

  const AnswerInputStyle(this.key);

  final String key;

  String get label => switch (this) {
        AnswerInputStyle.multipleChoice => 'Multiple Choice',
        AnswerInputStyle.letterbox => 'Eingabe',
      };

  String get shortLabel => switch (this) {
        AnswerInputStyle.multipleChoice => 'Auswahl',
        AnswerInputStyle.letterbox => 'Eingabe',
      };

  static AnswerInputStyle fromKey(String? key) =>
      AnswerInputStyle.values.firstWhere(
        (value) => value.key == key,
        orElse: () => AnswerInputStyle.multipleChoice,
      );
}

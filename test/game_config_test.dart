import 'package:flutter_test/flutter_test.dart';
import 'package:philosophie_quiz/data/models/answer_input_style.dart';
import 'package:philosophie_quiz/data/models/player_profile.dart';
import 'package:philosophie_quiz/features/quiz/game_session_controller.dart';

void main() {
  test('classic configs are untimed', () {
    expect(GameConfig.classicDefault.perQuestionTimeLimit, Duration.zero);
    expect(GameConfig.letterboxDefault.perQuestionTimeLimit, Duration.zero);
  });

  test('joker availability defaults to three but supports off', () {
    expect(JokerAvailability.fromKey(null), JokerAvailability.three);
    expect(JokerAvailability.fromKey('off'), JokerAvailability.disabled);
    expect(JokerAvailability.disabled.sessionLimit, 0);
  });

  test('input style defaults to multiple choice but supports letterbox', () {
    expect(AnswerInputStyle.fromKey(null), AnswerInputStyle.multipleChoice);
    expect(AnswerInputStyle.fromKey('letterbox'), AnswerInputStyle.letterbox);
  });
}

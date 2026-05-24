import 'dart:developer' as dev;
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../env.dart';

/// Welche Art von Rückmeldung wird eingereicht.
///
/// * [questionReport] — kontextbezogen aus dem Reveal-Panel; `questionId`
///   und `category` sind hier i. d. R. gesetzt.
/// * [generalFeedback] — aus den Einstellungen ("Feedback geben").
/// * [questionSuggestion] — aus den Einstellungen ("Frage vorschlagen"),
///   Freitext mit Zitat/Quelle/Begründung.
enum FeedbackType {
  questionReport('question_report'),
  generalFeedback('general_feedback'),
  questionSuggestion('question_suggestion');

  const FeedbackType(this.key);
  final String key;
}

/// Vordefinierte Kategorien für die beiden Sheets. Die Tabelle erlaubt
/// jeden String, aber im Client beschränken wir uns auf diese Liste, damit
/// die Auswertung clean bleibt.
enum FeedbackCategory {
  // Question report
  contentError('content_error', 'Inhaltlicher Fehler'),
  typo('typo', 'Tippfehler'),
  wrongAttribution('wrong_attribution', 'Falsche Zuschreibung'),
  sourceDoubtful('source_doubtful', 'Quelle fragwürdig'),
  // General
  idea('idea', 'Idee oder Wunsch'),
  bug('bug', 'Fehler / Bug'),
  praise('praise', 'Lob'),
  // Shared
  other('other', 'Sonstiges');

  const FeedbackCategory(this.key, this.label);
  final String key;
  final String label;

  static List<FeedbackCategory> get questionReportOptions => const [
        contentError,
        typo,
        wrongAttribution,
        sourceDoubtful,
        other,
      ];

  static List<FeedbackCategory> get generalOptions => const [
        idea,
        bug,
        praise,
        other,
      ];
}

/// Schreibt strukturierte Rückmeldungen in die Supabase-`feedback`-Tabelle.
///
/// Bewusst minimal: ein einziger `submit`-Eingang, der für alle drei
/// Touchpoints (Antwortkarte, Settings-Feedback, Settings-Frage-Vorschlag)
/// dient. Fehler werden geschluckt und als `false` signalisiert — die UI
/// zeigt dann eine sanfte Fallback-Meldung; der User soll nicht mit
/// rohen Netzwerkfehlern konfrontiert werden.
class FeedbackRepository {
  FeedbackRepository(this._client);

  final SupabaseClient _client;

  Future<bool> submit({
    required FeedbackType type,
    required String message,
    FeedbackCategory? category,
    String? questionId,
    String? contactEmail,
  }) async {
    final trimmed = message.trim();
    // Leerer Text ist erlaubt — bei Frage-Reports reicht die Kategorie als
    // Signal. Ob eine Submission ohne Text sinnvoll ist, entscheidet das
    // aufrufende Sheet (siehe [FeedbackSheet.messageOptional]).
    final uid = _client.auth.currentUser?.id;
    final email = contactEmail?.trim();

    final payload = <String, dynamic>{
      'profile_id': uid,
      'type': type.key,
      'category': category?.key,
      'question_id': questionId,
      'message': trimmed,
      'contact_email': (email == null || email.isEmpty) ? null : email,
      'app_version': Env.appVersion,
      'platform': _platformKey(),
    };

    try {
      await _client.from('feedback').insert(payload);
      return true;
    } on PostgrestException catch (e) {
      dev.log(
        'feedback insert PostgrestException: code=${e.code} msg=${e.message}',
        name: 'FeedbackRepository',
      );
      return false;
    } catch (e, st) {
      dev.log(
        'feedback insert failed: $e',
        name: 'FeedbackRepository',
        stackTrace: st,
      );
      return false;
    }
  }

  static String _platformKey() {
    if (kIsWeb) return 'web';
    try {
      if (Platform.isIOS) return 'ios';
      if (Platform.isAndroid) return 'android';
      if (Platform.isMacOS) return 'macos';
      if (Platform.isWindows) return 'windows';
      if (Platform.isLinux) return 'linux';
    } catch (_) {
      // Platform throws on Web — kIsWeb-Pfad oben fängt das ab, aber
      // defensiv lassen wir den Catch hier stehen.
    }
    return 'unknown';
  }
}

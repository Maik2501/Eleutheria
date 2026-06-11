import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../data/repositories/feedback_repository.dart';
import '../../core/haptics.dart';

/// Modal-Bottom-Sheet für Rückmeldungen aus allen drei Touchpoints:
///   * Antwortkarte → "Frage melden"   (mit Kategorien, optional Freitext)
///   * Einstellungen → "Feedback geben" (mit Kategorien + Freitext + Mail)
///   * Einstellungen → "Frage vorschlagen" (nur Freitext + Mail)
///
/// Der eigentliche Insert läuft anonym über die Supabase-Session. Wenn
/// kein Repo verfügbar ist (Offline-Modus / Env nicht gesetzt), schließt
/// das Sheet still und zeigt eine sanfte Hinweis-SnackBar.
class FeedbackSheet extends ConsumerStatefulWidget {
  const FeedbackSheet({
    super.key,
    required this.type,
    required this.title,
    required this.intro,
    this.categories = const [],
    this.questionId,
    this.questionPreview,
    this.showEmailField = false,
    this.messageHint = 'Was möchtest du uns sagen?',
    this.messageOptional = false,
  });

  final FeedbackType type;
  final String title;
  final String intro;

  /// Wenn leer → keine Kategorie-Pflicht (z. B. Frage-Vorschlag).
  final List<FeedbackCategory> categories;

  /// Setzen für [FeedbackType.questionReport]. Wird mitgeschickt und
  /// als kleine Kontext-Zeile oben angezeigt.
  final String? questionId;
  final String? questionPreview;

  final bool showEmailField;
  final String messageHint;

  /// `true` → Freitext ist grundsätzlich optional; allein die gewählte
  /// Kategorie reicht zum Absenden. Ausnahme: Wenn die Kategorie
  /// [FeedbackCategory.other] gewählt ist, bleibt der Text Pflicht, weil
  /// "Sonstiges" ohne Erklärung nichts aussagt.
  final bool messageOptional;

  static Future<bool?> show(
    BuildContext context, {
    required FeedbackType type,
    required String title,
    required String intro,
    List<FeedbackCategory> categories = const [],
    String? questionId,
    String? questionPreview,
    bool showEmailField = false,
    String messageHint = 'Was möchtest du uns sagen?',
    bool messageOptional = false,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: FeedbackSheet(
          type: type,
          title: title,
          intro: intro,
          categories: categories,
          questionId: questionId,
          questionPreview: questionPreview,
          showEmailField: showEmailField,
          messageHint: messageHint,
          messageOptional: messageOptional,
        ),
      ),
    );
  }

  @override
  ConsumerState<FeedbackSheet> createState() => _FeedbackSheetState();
}

class _FeedbackSheetState extends ConsumerState<FeedbackSheet> {
  FeedbackCategory? _selectedCategory;
  final _messageCtl = TextEditingController();
  final _emailCtl = TextEditingController();
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    if (widget.categories.isNotEmpty) {
      _selectedCategory = widget.categories.first;
    }
  }

  @override
  void dispose() {
    _messageCtl.dispose();
    _emailCtl.dispose();
    super.dispose();
  }

  String get _messageEyebrow {
    if (!widget.messageOptional) return 'NACHRICHT';
    if (_selectedCategory == FeedbackCategory.other) return 'NACHRICHT';
    return 'NACHRICHT (OPTIONAL)';
  }

  String get _effectiveMessageHint {
    // Wenn Freitext bei "Sonstiges" plötzlich Pflicht wird, soll der
    // Hint das auch sagen — sonst stehen dort weiter die alten
    // "Optional: …"-Worte und der disabled Submit-Button wirkt wie ein Bug.
    if (widget.messageOptional &&
        _selectedCategory == FeedbackCategory.other) {
      return 'Beschreib bitte kurz, was du meldest.';
    }
    return widget.messageHint;
  }

  bool get _canSubmit {
    if (_submitting) return false;
    if (widget.categories.isNotEmpty && _selectedCategory == null) return false;
    final hasText = _messageCtl.text.trim().isNotEmpty;
    if (widget.messageOptional) {
      // "Sonstiges" ohne Erklärung wäre nutzlos — also dort doch verlangen.
      if (_selectedCategory == FeedbackCategory.other) return hasText;
      return true;
    }
    return hasText;
  }

  Future<void> _submit() async {
    if (!_canSubmit) return;
    final repo = ref.read(feedbackRepositoryProvider);
    if (repo == null) {
      _showSnack(
        'Online-Verbindung nicht verfügbar — bitte später erneut versuchen.',
      );
      return;
    }

    setState(() => _submitting = true);
    Haptics.selection();

    final ok = await repo.submit(
      type: widget.type,
      message: _messageCtl.text,
      category: _selectedCategory,
      questionId: widget.questionId,
      contactEmail: widget.showEmailField ? _emailCtl.text : null,
    );

    if (!mounted) return;
    setState(() => _submitting = false);

    if (ok) {
      Navigator.of(context).pop(true);
      _showSnack('Danke — deine Rückmeldung ist angekommen.');
    } else {
      _showSnack(
        'Übertragung fehlgeschlagen. Bitte versuche es gleich noch einmal.',
      );
    }
  }

  void _showSnack(String text) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    messenger?.showSnackBar(
      SnackBar(
        content: Text(text),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Container(
      decoration: BoxDecoration(
        color: palette.page,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(top: BorderSide(color: palette.divider)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 14, 22, 18),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 14),
                    decoration: BoxDecoration(
                      color: palette.divider,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Text(
                  widget.title,
                  style: AppTypography.serif(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: palette.ink,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  widget.intro,
                  style: TextStyle(
                    fontSize: 13.5,
                    height: 1.45,
                    color: palette.inkSoft,
                  ),
                ),
                if (widget.questionPreview != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: palette.parchment,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: palette.divider),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '✦',
                          style: TextStyle(color: palette.gold, fontSize: 14),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            widget.questionPreview!,
                            style: TextStyle(
                              fontSize: 12.5,
                              color: palette.inkSoft,
                              height: 1.4,
                              fontStyle: FontStyle.italic,
                            ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                if (widget.categories.isNotEmpty) ...[
                  const SizedBox(height: 18),
                  Text(
                    'KATEGORIE',
                    style: AppTypography.eyebrow(palette.inkMuted),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: widget.categories.map((cat) {
                      final selected = cat == _selectedCategory;
                      return _CategoryChip(
                        label: cat.label,
                        selected: selected,
                        onTap: () => setState(() => _selectedCategory = cat),
                      );
                    }).toList(),
                  ),
                ],
                const SizedBox(height: 18),
                Text(
                  _messageEyebrow,
                  style: AppTypography.eyebrow(palette.inkMuted),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _messageCtl,
                  maxLines: 5,
                  minLines: 3,
                  maxLength: 2000,
                  onChanged: (_) => setState(() {}),
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    hintText: _effectiveMessageHint,
                    filled: true,
                    fillColor: palette.parchment,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: palette.divider),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: palette.divider),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: palette.burgundy, width: 1.4),
                    ),
                  ),
                ),
                if (widget.showEmailField) ...[
                  const SizedBox(height: 10),
                  Text(
                    'E-MAIL FÜR RÜCKFRAGEN (OPTIONAL)',
                    style: AppTypography.eyebrow(palette.inkMuted),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _emailCtl,
                    keyboardType: TextInputType.emailAddress,
                    autocorrect: false,
                    decoration: InputDecoration(
                      hintText: 'du@beispiel.de',
                      filled: true,
                      fillColor: palette.parchment,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: palette.divider),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: palette.divider),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide:
                            BorderSide(color: palette.burgundy, width: 1.4),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Ohne Mail bleibt deine Einreichung anonym.',
                    style: TextStyle(fontSize: 11.5, color: palette.inkMuted),
                  ),
                ],
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _canSubmit ? _submit : null,
                    icon: _submitting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.page,
                            ),
                          )
                        : const Icon(Icons.send_rounded, size: 18),
                    label: Text(_submitting ? 'Sende …' : 'Absenden'),
                  ),
                ),
                const SizedBox(height: 4),
                Center(
                  child: TextButton(
                    onPressed: _submitting
                        ? null
                        : () => Navigator.of(context).pop(false),
                    child: Text(
                      'Abbrechen',
                      style: TextStyle(color: palette.inkMuted),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? palette.burgundy : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? palette.burgundy : palette.divider,
          ),
        ),
        child: Text(
          label,
          style: AppTypography.sans(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: selected ? AppColors.page : palette.ink,
            letterSpacing: 0.1,
          ),
        ),
      ),
    );
  }
}

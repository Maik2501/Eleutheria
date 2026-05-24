import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../data/models/answer_input_style.dart';
import '../../data/models/difficulty_band.dart';
import '../../data/repositories/feedback_repository.dart';
import '../../shared/widgets/parchment_background.dart';
import '../feedback/feedback_sheet.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.palette;
    final p = ref.watch(profileNotifierProvider).value;
    final notifier = ref.read(profileNotifierProvider.notifier);
    if (p == null) return const SizedBox.shrink();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: const Text('Einstellungen'),
      ),
      body: ParchmentBackground(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          children: [
            Text('GAMEPLAY', style: AppTypography.eyebrow(palette.inkMuted)),
            const SizedBox(height: 10),
            _GameplaySetting(
              label: 'Antwortart',
              description:
                  'Multiple Choice zeigt vier Optionen zur Auswahl. Eingabe lässt dich die Antwort über die Tastatur tippen. Schwieriger, für eine echte Herausforderung.',
              child: _SegmentedRow(
                value: p.preferredInputStyle.key,
                entries: const {
                  'multipleChoice': 'Multiple Choice',
                  'letterbox': 'Eingabe',
                },
                onChanged: (key) => notifier.setPreferredInputStyle(
                  AnswerInputStyle.fromKey(key),
                ),
              ),
            ),
            const SizedBox(height: 18),
            _GameplaySetting(
              label: 'Schwierigkeit',
              description:
                  'Einstieg sind die leichten Fragen, Salon mischt alles, Meisterprüfung nur die anspruchsvollen.',
              child: _SegmentedRow(
                value: DifficultyBand.fromRange(
                  p.preferredDifficulty.$1,
                  p.preferredDifficulty.$2,
                ).name,
                entries: const {
                  'einstieg': 'Einstieg',
                  'salon': 'Salon',
                  'meisterpruefung': 'Meister',
                },
                onChanged: (key) {
                  final band = DifficultyBand.values
                      .firstWhere((b) => b.name == key);
                  notifier.setDifficultyBand(band);
                },
              ),
            ),
            const SizedBox(height: 18),
            _GameplaySetting(
              label: 'Joker',
              description:
                  'Joker geben pro Frage einen Tipp. Eingesetzte Joker halbieren die Punkte dieser Frage. Nur mit „Aus" landest du auf der reinen Pure-Bestenliste — sonst zählt der Lauf in Casual.',
              child: _SegmentedRow(
                value: p.jokerAvailability.key,
                entries: const {
                  'off': 'Aus',
                  'one': '1',
                  'three': '3',
                  'always': 'Immer',
                },
                onChanged: notifier.setJokerAvailability,
              ),
            ),
            const SizedBox(height: 32),
            Text('DARSTELLUNG', style: AppTypography.eyebrow(palette.inkMuted)),
            const SizedBox(height: 10),
            _SegmentedRow(
              value: p.themeMode,
              entries: const {
                'system': 'System',
                'light': 'Hell',
                'dark': 'Dunkel',
              },
              onChanged: notifier.setThemeMode,
            ),
            const SizedBox(height: 32),
            Text('SPRACHE', style: AppTypography.eyebrow(palette.inkMuted)),
            const SizedBox(height: 10),
            _SegmentedRow(
              value: p.locale == 'de' ? p.locale : 'de',
              entries: const {
                'de': 'Deutsch',
                'en': 'English',
              },
              disabledEntries: const {'en'},
              onChanged: notifier.setLocale,
            ),
            const SizedBox(height: 32),
            _ToggleTile(
              label: 'Vibrations-Feedback',
              value: p.hapticsEnabled,
              onChanged: notifier.setHaptics,
            ),
            _ToggleTile(
              label: 'Geräusche',
              value: p.soundsEnabled,
              onChanged: notifier.setSounds,
            ),
            const SizedBox(height: 32),
            Text('RÜCKMELDUNG',
                style: AppTypography.eyebrow(palette.inkMuted),),
            const SizedBox(height: 10),
            _FeedbackTile(
              icon: Icons.chat_bubble_outline_rounded,
              label: 'Feedback geben',
              subtitle: 'Idee, Lob oder Fehler — wir lesen alles.',
              onTap: () => FeedbackSheet.show(
                context,
                type: FeedbackType.generalFeedback,
                title: 'Feedback an Eleutheria',
                intro:
                    'Was läuft gut, was holpert, was fehlt? Erzähl es uns — kurz oder ausführlich.',
                categories: FeedbackCategory.generalOptions,
                showEmailField: true,
              ),
            ),
            _FeedbackTile(
              icon: Icons.menu_book_outlined,
              label: 'Frage vorschlagen',
              subtitle: 'Ein Zitat, eine Idee — schick es uns vor.',
              onTap: () => FeedbackSheet.show(
                context,
                type: FeedbackType.questionSuggestion,
                title: 'Frage vorschlagen',
                intro:
                    'Schreib uns das Zitat oder die Frage, die Quelle und kurz, warum du sie passend findest.',
                showEmailField: true,
                messageHint:
                    'Zitat / Frage \nQuelle (Werk, Kapitel, Jahr) \nWarum eine schöne Frage?',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Bist du gerade über TestFlight unterwegs? Ein Screenshot innerhalb der TestFlight-App schickt zusätzlich Bildkontext direkt an Apple.',
              style: TextStyle(
                fontSize: 11.5,
                color: palette.inkMuted,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 32),
            Text('ÜBER ELEUTHERIA',
                style: AppTypography.eyebrow(palette.inkMuted),),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: palette.page,
                border: Border.all(color: palette.divider),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                'Eleutheria ist ein liebevoll handgepflegtes Quiz für die Freundinnen und Freunde der Philosophie. '
                'Die Fragen wurden kuratiert; Quellen und Erläuterungen finden sich nach jeder Antwort.',
                style: TextStyle(
                    color: palette.inkSoft, height: 1.55, fontSize: 14,),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GameplaySetting extends StatelessWidget {
  const _GameplaySetting({
    required this.label,
    required this.description,
    required this.child,
  });

  final String label;
  final String description;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 0, 4, 6),
          child: Text(
            label,
            style: AppTypography.serif(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: palette.ink,
            ),
          ),
        ),
        child,
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 8, 4, 0),
          child: Text(
            description,
            style: TextStyle(
              fontSize: 12.5,
              height: 1.45,
              color: palette.inkMuted,
            ),
          ),
        ),
      ],
    );
  }
}

class _FeedbackTile extends StatelessWidget {
  const _FeedbackTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: palette.page,
        border: Border.all(color: palette.divider),
        borderRadius: BorderRadius.circular(14),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: palette.burgundy),
        title: Text(
          label,
          style: AppTypography.sans(
            fontWeight: FontWeight.w600,
            fontSize: 15,
            color: palette.ink,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 12.5,
            color: palette.inkMuted,
            height: 1.35,
          ),
        ),
        trailing: Icon(
          Icons.chevron_right_rounded,
          color: palette.inkMuted,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}

class _SegmentedRow extends StatelessWidget {
  const _SegmentedRow({
    required this.value,
    required this.entries,
    required this.onChanged,
    this.disabledEntries = const {},
  });

  final String value;
  final Map<String, String> entries;
  final ValueChanged<String> onChanged;
  final Set<String> disabledEntries;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      decoration: BoxDecoration(
        color: palette.page,
        border: Border.all(color: palette.divider),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: entries.entries.map((e) {
          final disabled = disabledEntries.contains(e.key);
          final selected = e.key == value;
          return Expanded(
            child: GestureDetector(
              onTap: disabled ? null : () => onChanged(e.key),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: selected && !disabled
                      ? palette.burgundy
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  e.value,
                  textAlign: TextAlign.center,
                  style: AppTypography.sans(
                    fontWeight: FontWeight.w600,
                    fontSize: 14.5,
                    letterSpacing: 0.1,
                    color: disabled
                        ? palette.inkMuted.withValues(alpha: 0.42)
                        : selected
                            ? AppColors.page
                            : palette.ink,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _ToggleTile extends StatelessWidget {
  const _ToggleTile({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: palette.page,
        border: Border.all(color: palette.divider),
        borderRadius: BorderRadius.circular(14),
      ),
      child: SwitchListTile(
        contentPadding: EdgeInsets.zero,
        value: value,
        onChanged: onChanged,
        activeThumbColor: palette.gold,
        title: Text(
          label,
          style: AppTypography.sans(
            fontWeight: FontWeight.w500,
            fontSize: 15,
            color: palette.ink,
          ),
        ),
      ),
    );
  }
}

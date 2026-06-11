import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../data/models/answer_input_style.dart';
import '../../data/models/difficulty_band.dart';
import '../../data/repositories/feedback_repository.dart';
import '../../env.dart';
import '../../shared/widgets/parchment_background.dart';
import '../feedback/feedback_sheet.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _refreshing = false;
  bool _deletingAccount = false;

  /// Konto-Löschung (Apple 5.1.1(v)): Server-RPC räumt alles ab, danach
  /// lokale Session + Spielstand zurücksetzen und eine frische anonyme
  /// Identität starten — die App landet wie beim Erststart im Setup.
  Future<void> _deleteAccount() async {
    if (_deletingAccount) return;
    final messenger = ScaffoldMessenger.of(context);
    final repo = ref.read(supabaseProfileRepositoryProvider);
    if (repo == null) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Dafür wird eine Internetverbindung benötigt.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final palette = context.palette;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Konto löschen?'),
        content: const Text(
          'Dein Anzeigename wird freigegeben, deine Bestenlisten-Einträge '
          'und Duell-Daten werden endgültig vom Server gelöscht. Auch der '
          'lokale Spielfortschritt (XP, Erfolge, Lesezeichen) wird '
          'zurückgesetzt.\n\n'
          'Das kann nicht rückgängig gemacht werden.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: palette.incorrect,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Endgültig löschen'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _deletingAccount = true);
    final ok = await repo.deleteAccount();
    if (!mounted) return;

    if (!ok) {
      setState(() => _deletingAccount = false);
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            'Löschen fehlgeschlagen. Prüfe deine Verbindung und versuch es erneut.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // Tote Session loswerden und direkt eine neue anonyme Identität holen,
    // damit Setup/Online-Features ohne App-Neustart funktionieren.
    final auth = Supabase.instance.client.auth;
    try {
      await auth.signOut();
    } catch (_) {}
    try {
      await auth.signInAnonymously();
    } catch (_) {}
    await ref.read(profileSetupFlagProvider).reset();
    await ref.read(profileNotifierProvider.notifier).resetToFresh();
    ref.invalidate(remoteProfileProvider);

    if (!mounted) return;
    messenger.showSnackBar(
      const SnackBar(
        content: Text('Dein Konto wurde gelöscht.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
    context.go('/');
  }

  Future<void> _refreshContent() async {
    if (_refreshing) return;
    setState(() => _refreshing = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await refreshRemoteContent(ref);
      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Inhalte aktualisiert.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text('Aktualisierung fehlgeschlagen: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _refreshing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final p = ref.watch(profileNotifierProvider).value;
    final notifier = ref.read(profileNotifierProvider.notifier);
    final lastSyncedAt = ref.watch(contentCacheProvider).lastSyncedAt;
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
            // Geräusche-Toggle entfernt: Es gibt (noch) keine Sounds in der
            // App — ein Schalter ohne Wirkung verwirrt nur (Launch-Bug 2).
            // profile.soundsEnabled bleibt persistiert für später.
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
                title: 'Feedback an Griphos',
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
            const SizedBox(height: 32),
            Text('INHALTE',
                style: AppTypography.eyebrow(palette.inkMuted),),
            const SizedBox(height: 10),
            _FeedbackTile(
              icon: _refreshing
                  ? Icons.hourglass_top_rounded
                  : Icons.cloud_download_outlined,
              label: _refreshing
                  ? 'Aktualisiere …'
                  : 'Fragen & Rätsel aktualisieren',
              subtitle: lastSyncedAt == null
                  ? 'Noch nicht synchronisiert. Bundle wird verwendet.'
                  : 'Zuletzt synchronisiert: ${_formatSyncTime(lastSyncedAt)}',
              onTap: _refreshing ? () {} : _refreshContent,
            ),
            if (Env.donatePayPalUrl.isNotEmpty) ...[
              const SizedBox(height: 32),
              Text('UNTERSTÜTZUNG',
                  style: AppTypography.eyebrow(palette.inkMuted),),
              const SizedBox(height: 10),
              const _DonationCard(),
            ],
            const SizedBox(height: 32),
            Text('ÜBER GRIPHOS',
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
                'Griphos ist eine liebevoll handgepflegte Sammlung philosophischer Rätsel und Denkspiele '
                'für die Freundinnen und Freunde der Philosophie. '
                'Die Fragen wurden kuratiert; Quellen und Erläuterungen finden sich nach jeder Antwort.',
                style: TextStyle(
                    color: palette.inkSoft, height: 1.55, fontSize: 14,),
              ),
            ),
            const SizedBox(height: 32),
            Text('KONTO', style: AppTypography.eyebrow(palette.inkMuted)),
            const SizedBox(height: 10),
            _FeedbackTile(
              icon: _deletingAccount
                  ? Icons.hourglass_top_rounded
                  : Icons.delete_outline_rounded,
              iconColor: palette.incorrect,
              label: _deletingAccount ? 'Lösche …' : 'Konto löschen',
              subtitle:
                  'Anzeigename, Bestenlisten- und Duell-Daten endgültig löschen.',
              onTap: _deletingAccount ? () {} : _deleteAccount,
            ),
          ],
        ),
      ),
    );
  }
}

/// Formatiert einen Sync-Zeitstempel als "heute, 14:23" / "gestern, 09:15"
/// / "vor 3 Tagen" — nicht kalendarisch exakt, aber für den User
/// nachvollziehbar.
String _formatSyncTime(DateTime when) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final whenDay = DateTime(when.year, when.month, when.day);
  final daysAgo = today.difference(whenDay).inDays;
  final hh = when.hour.toString().padLeft(2, '0');
  final mm = when.minute.toString().padLeft(2, '0');
  if (daysAgo == 0) return 'heute, $hh:$mm';
  if (daysAgo == 1) return 'gestern, $hh:$mm';
  if (daysAgo < 7) return 'vor $daysAgo Tagen';
  return '${when.day}.${when.month}.${when.year}';
}

/// "Unterstützung"-Karte mit warmer Akademie-Optik: kurzer Dank-Text +
/// PayPal-Button. Tap öffnet den Link über [url_launcher] in der externen
/// App/Browser-Sitzung. Der Aufrufer rendert die Karte nur, wenn ein
/// echter PayPal-Link konfiguriert ist (siehe [Env.donatePayPalUrl]).
class _DonationCard extends StatelessWidget {
  const _DonationCard();

  Future<void> _openPayPal(BuildContext context) async {
    final uri = Uri.parse(Env.donatePayPalUrl);
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('PayPal konnte nicht geöffnet werden.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: BoxDecoration(
        color: palette.page,
        border: Border.all(color: palette.gold.withValues(alpha: 0.45)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: palette.gold.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.favorite_rounded,
                  color: palette.gold,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Spende einen Kaffee',
                  style: AppTypography.serif(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: palette.ink,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Ich hoffe, du hast Freude an Griphos. Das Erstellen und '
            'die Pflege der App kosten viel Zeit — wenn du mich '
            'unterstützen möchtest, würde ich mich über eine kleine Spende '
            'sehr freuen.',
            style: TextStyle(
              color: palette.inkSoft,
              fontSize: 13.5,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => _openPayPal(context),
              icon: const Icon(Icons.open_in_new_rounded, size: 18),
              label: const Text('Mit PayPal unterstützen'),
            ),
          ),
        ],
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
    this.iconColor,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  /// Default: burgundy. Destruktive Aktionen übergeben palette.incorrect.
  final Color? iconColor;

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
        leading: Icon(icon, color: iconColor ?? palette.burgundy),
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

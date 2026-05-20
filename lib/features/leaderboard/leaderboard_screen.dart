import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../data/models/difficulty_band.dart';
import '../../data/repositories/score_repository.dart';
import '../../shared/widgets/chapter_heading.dart';
import '../../shared/widgets/parchment_background.dart';

/// Reads from the Supabase `scores` table.
/// Two leaderboards live side-by-side via the `is_pure` flag:
/// - **Pure**: nur Sessions ohne Joker (`is_pure = true`)
/// - **Casual**: alle, Joker-Fragen mit 50 % gewertet
class LeaderboardScreen extends ConsumerStatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  ConsumerState<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends ConsumerState<LeaderboardScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;

  // Filter-State
  _ModeGroup _modeGroup = _ModeGroup.all;
  _VariantOption? _variant;
  _InputStyleFilter _inputStyle = _InputStyleFilter.all;
  _BandFilter _band = _BandFilter.all;
  _RangeFilter _range = _RangeFilter.allTime;

  /// Zeigt die Modifier-Zeilen (Variant + Antwortart) unterhalb des
  /// aktiven Modus. Klick auf einen anderen Modus expandiert
  /// automatisch, Klick auf den **bereits aktiven** Modus toggelt nur
  /// die Sichtbarkeit — die aktuell gewählten Modifier bleiben aktiv.
  bool _modifiersExpanded = false;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _tab.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  bool get _isPureTab => _tab.index == 0;

  Future<List<ScoreEntry>> _load() async {
    final repo = ref.read(scoreRepositoryProvider);
    if (repo == null) return const [];
    return repo.topScores(
      pure: _isPureTab,
      mode: _modeGroup.serverKey,
      variant: _variant?.key,
      band: _band.serverKey,
      inputStyle: _inputStyle.serverKey,
      since: _range.since(),
      onlyMine: _range == _RangeFilter.myBest,
      orderByCorrect: _variant?.metricIsCorrect ?? false,
      limit: 50,
    );
  }

  void _onModeTap(_ModeGroup g) {
    setState(() {
      if (_modeGroup == g) {
        // Klick auf den aktiven Modus = Modifier ein-/ausklappen.
        // Bisherige Variant/InputStyle-Auswahl bleibt erhalten und
        // filtert weiter — sie ist nur unsichtbar.
        _modifiersExpanded = !_modifiersExpanded;
      } else {
        _modeGroup = g;
        // Bei Modus-Wechsel: Variant zurücksetzen (sie ist mode-spezifisch),
        // InputStyle bleibt (orthogonal). Modifier automatisch öffnen,
        // sofern es welche zu zeigen gibt.
        _variant = null;
        _modifiersExpanded = g.hasModifiers;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: const Text('Rangliste'),
      ),
      body: ParchmentBackground(
        child: SafeArea(
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(24, 8, 24, 12),
                child: ChapterHeading(
                  eyebrow: 'Bestenliste',
                  title: 'Pure & Casual',
                  subtitle:
                      'Pure: Sessions ohne Joker. Casual: Joker-Fragen werden mit 50 % gewertet.',
                ),
              ),
              TabBar(
                controller: _tab,
                labelColor: palette.burgundy,
                unselectedLabelColor: palette.inkMuted,
                indicatorColor: palette.gold,
                labelStyle: AppTypography.button(),
                tabs: const [
                  Tab(text: 'Pure'),
                  Tab(text: 'Casual'),
                ],
              ),
              const SizedBox(height: 12),
              _FilterRow(
                label: 'Modus',
                children: [
                  for (final g in _ModeGroup.values)
                    _Chip(
                      label: g.label,
                      active: _modeGroup == g,
                      // Pfeil-Indikator nur am aktiven Modus mit
                      // Modifiern, damit klar ist: zweiter Klick toggelt.
                      trailingIcon: (_modeGroup == g && g.hasModifiers)
                          ? (_modifiersExpanded
                              ? Icons.expand_less_rounded
                              : Icons.expand_more_rounded)
                          : null,
                      onTap: () => _onModeTap(g),
                    ),
                ],
              ),
              if (_modifiersExpanded && _modeGroup.hasModifiers) ...[
                if (_modeGroup.variants.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _FilterRow(
                    label: 'Variante',
                    children: [
                      _Chip(
                        label: 'Alle',
                        active: _variant == null,
                        onTap: () => setState(() => _variant = null),
                      ),
                      for (final v in _modeGroup.variants)
                        _Chip(
                          label: v.label,
                          active: _variant?.key == v.key,
                          onTap: () => setState(() => _variant = v),
                        ),
                    ],
                  ),
                ],
                const SizedBox(height: 8),
                _FilterRow(
                  label: 'Antwortart',
                  children: [
                    for (final s in _InputStyleFilter.values)
                      _Chip(
                        label: s.label,
                        active: _inputStyle == s,
                        onTap: () => setState(() => _inputStyle = s),
                      ),
                  ],
                ),
              ],
              const SizedBox(height: 8),
              _FilterRow(
                label: 'Schwierigkeit',
                children: [
                  for (final b in _BandFilter.values)
                    _Chip(
                      label: b.label,
                      active: _band == b,
                      onTap: () => setState(() => _band = b),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              _FilterRow(
                label: 'Zeitraum',
                children: [
                  for (final r in _RangeFilter.values)
                    _Chip(
                      label: r.label,
                      active: _range == r,
                      onTap: () => setState(() => _range = r),
                    ),
                ],
              ),
              const SizedBox(height: 14),
              Expanded(
                child: FutureBuilder<List<ScoreEntry>>(
                  // Re-fetch when tab/filter change — Future ist hier idiomatisch
                  // einfacher als ein Provider, weil Filter-State lokal liegt.
                  future: _load(),
                  builder: (context, snap) {
                    if (snap.connectionState != ConnectionState.done) {
                      return Center(
                        child: CircularProgressIndicator(color: palette.gold),
                      );
                    }
                    if (snap.hasError) {
                      return _EmptyState(
                        title: 'Konnte Liste nicht laden.',
                        subtitle: '${snap.error}',
                      );
                    }
                    final list = snap.data ?? const <ScoreEntry>[];
                    if (list.isEmpty) {
                      return _EmptyState(
                        title: 'Noch keine Einträge',
                        subtitle: _isPureTab
                            ? 'Sei die Erste, die einen Joker-freien Lauf einreicht.'
                            : 'Spiel ein paar Runden, dann erscheint hier was.',
                      );
                    }
                    return ListView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 6, 20, 24),
                      itemCount: list.length,
                      itemBuilder: (ctx, i) => _Row(
                        rank: i + 1,
                        entry: list[i],
                        metricIsCorrect: _variant?.metricIsCorrect ?? false,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ───────────────────────── Filters ─────────────────────────

/// Oberster Filter — entspricht den Modi-Tiles auf dem Home-Screen.
/// `serverKey` = `mode`-Spalte in `scores`. `null` heißt „alle".
enum _ModeGroup {
  all('Alle', null),
  classic('Klassisch', 'classic'),
  quizRush('Quiz-Rush', 'quizRush');

  const _ModeGroup(this.label, this.serverKey);
  final String label;
  final String? serverKey;

  /// Sub-Varianten, die in der Variant-Modifier-Zeile erscheinen, sobald
  /// dieser Modus aktiv ist und die Modifier expandiert sind. `all`
  /// liefert eine leere Liste — keine Variant-Zeile.
  List<_VariantOption> get variants {
    switch (this) {
      case _ModeGroup.classic:
        return const [
          _VariantOption('10 Fragen', '10', false),
          _VariantOption('15 Fragen', '15', false),
          _VariantOption('20 Fragen', '20', false),
        ];
      case _ModeGroup.quizRush:
        return const [
          _VariantOption('1 min', '1min', false),
          _VariantOption('3 min', '3min', false),
          _VariantOption('5 min', '5min', false),
          _VariantOption('Endless', 'endless', true),
        ];
      case _ModeGroup.all:
        return const [];
    }
  }

  /// Hat dieser Modus überhaupt Modifier zum Aus-/Einklappen?
  /// `Alle` hat keine — Klick darauf macht nichts Besonderes.
  bool get hasModifiers => this != _ModeGroup.all;
}

/// Antwortart-Filter (`input_style` in `scores`). Orthogonal zum
/// GameMode — eine Klassik-Runde kann Multiple Choice **oder**
/// Letterbox sein, beide landen unter mode='classic'.
enum _InputStyleFilter {
  all('Alle', null),
  multipleChoice('Auswahl', 'multipleChoice'),
  letterbox('Eingabe', 'letterbox');

  const _InputStyleFilter(this.label, this.serverKey);
  final String label;
  final String? serverKey;
}

/// Eine Sub-Variante des aktiven Modus.
/// `metricIsCorrect = true` → Bestenliste sortiert nach Anzahl richtiger
/// Antworten statt Punkten (Endless).
class _VariantOption {
  const _VariantOption(this.label, this.key, this.metricIsCorrect);
  final String label;
  final String key;
  final bool metricIsCorrect;
}

/// Schwierigkeitsband-Filter, `null` = alle Bänder.
enum _BandFilter {
  all('Alle', null),
  einstieg('Einstieg', DifficultyBand.einstieg),
  salon('Salon', DifficultyBand.salon),
  meisterpruefung('Meisterprüfung', DifficultyBand.meisterpruefung);

  const _BandFilter(this.label, this.band);
  final String label;
  final DifficultyBand? band;

  String? get serverKey => band?.serverKey;
}

enum _RangeFilter {
  today('Heute'),
  week('Diese Woche'),
  allTime('All-Time'),
  myBest('Mein Bestes');

  const _RangeFilter(this.label);
  final String label;

  DateTime? since() {
    final now = DateTime.now().toUtc();
    switch (this) {
      case _RangeFilter.today:
        return DateTime.utc(now.year, now.month, now.day);
      case _RangeFilter.week:
        return now.subtract(const Duration(days: 7));
      case _RangeFilter.allTime:
      case _RangeFilter.myBest:
        return null;
    }
  }
}

// ───────────────────────── UI bits ─────────────────────────

class _FilterRow extends StatelessWidget {
  const _FilterRow({required this.label, required this.children});
  final String label;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 6),
            child: Text(
              label.toUpperCase(),
              style: AppTypography.eyebrow(palette.gold),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final c in children) ...[c, const SizedBox(width: 8)],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.active,
    required this.onTap,
    this.trailingIcon,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  /// Optionales Icon rechts neben dem Label — wird z. B. genutzt, um
  /// am aktiven Modus den Expand/Collapse-Zustand seiner Modifier
  /// anzuzeigen.
  final IconData? trailingIcon;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: active
                ? palette.burgundy.withValues(alpha: 0.16)
                : palette.page,
            border: Border.all(
              color: active
                  ? palette.burgundy.withValues(alpha: 0.55)
                  : palette.divider,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: AppTypography.sans(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: active ? palette.burgundy : palette.ink,
                ),
              ),
              if (trailingIcon != null) ...[
                const SizedBox(width: 4),
                Icon(
                  trailingIcon,
                  size: 16,
                  color: active ? palette.burgundy : palette.ink,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.rank,
    required this.entry,
    required this.metricIsCorrect,
  });
  final int rank;
  final ScoreEntry entry;

  /// Im Endless-Modus zählt die Anzahl richtiger Antworten, nicht Punkte.
  final bool metricIsCorrect;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final podium = rank <= 3;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: palette.page,
        border: Border.all(
          color: podium
              ? palette.gold.withValues(alpha: 0.5)
              : palette.divider,
          width: podium ? 1.4 : 1,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 32,
            child: Text(
              '#$rank',
              style: AppTypography.serif(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: podium ? palette.gold : palette.inkMuted,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  entry.displayName,
                  style: AppTypography.serif(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: palette.ink,
                    letterSpacing: -0.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  metricIsCorrect
                      // Endless: die richtige-Antworten-Zahl ist die
                      // Hauptmetrik (steht rechts), Sub-Text zeigt nur
                      // noch Band + optional Joker an.
                      ? '${_bandLabel(entry.difficultyBand)}'
                          '${entry.jokersUsed > 0 ? ' · ${entry.jokersUsed} Joker' : ''}'
                      : '${entry.correct}/${entry.answered} · ${_bandLabel(entry.difficultyBand)}'
                          '${entry.jokersUsed > 0 ? ' · ${entry.jokersUsed} Joker' : ''}',
                  style: AppTypography.sans(
                    fontSize: 11.5,
                    color: palette.inkMuted,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                metricIsCorrect ? '${entry.correct}' : '${entry.score}',
                style: AppTypography.serif(
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                  color: palette.ink,
                ),
              ),
              Text(
                metricIsCorrect ? 'Fragen' : 'Punkte',
                style: AppTypography.sans(
                  fontSize: 10,
                  color: palette.inkMuted,
                  letterSpacing: 0.4,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _bandLabel(String key) => switch (key) {
        'einstieg' => 'Einstieg',
        'meisterpruefung' => 'Meisterprüfung',
        _ => 'Salon',
      };
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.title, required this.subtitle});
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title, style: AppTypography.eyebrow(palette.gold)),
            const SizedBox(height: 10),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(color: palette.inkMuted, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

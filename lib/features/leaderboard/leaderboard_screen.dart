import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../data/models/difficulty_band.dart';
import '../../data/repositories/score_repository.dart';
import '../../shared/widgets/parchment_background.dart';

/// Reads from the Supabase `scores` table.
/// Two leaderboards live side-by-side via the `is_pure` flag:
/// - **Pure**: nur Sessions, die mit ausgeschalteten Jokern angetreten
///   sind (`is_pure = true`, definiert in Migration 0009 als
///   `joker_setting = 'off'`)
/// - **Casual**: alles andere; Fragen mit Joker-Einsatz mit 50 % gewertet
class LeaderboardScreen extends ConsumerStatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  ConsumerState<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends ConsumerState<LeaderboardScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;
  int _lastTabIndex = 0;

  // Filter-State
  _ModeGroup _modeGroup = _ModeGroup.all;
  _VariantOption? _variant;
  _InputStyleFilter _inputStyle = _InputStyleFilter.all;
  _BandFilter _band = _BandFilter.all;
  _RangeFilter _range = _RangeFilter.allTime;

  /// Gehaltener Future statt `_load()` direkt im build: Rebuilds (Ticker,
  /// Menü-Toggles, Tab-Animation) lösen so keine Re-Queries mehr aus —
  /// neu gefetcht wird nur bei echter Filter-/Tab-Änderung (F19).
  late Future<List<ScoreEntry>> _future;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    // Der TabController notified pro Wechsel mehrfach (Animationsstart/-ende).
    // Dedupe über den Index statt über indexIsChanging: genau ein Refetch
    // pro echtem Tab-Wechsel, gefeuert ab der ersten Notification (F19).
    _tab.addListener(() {
      if (_tab.index == _lastTabIndex) return;
      _lastTabIndex = _tab.index;
      setState(() => _future = _load());
    });
    _future = _load();
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

  /// Filter ändern + genau einen Refetch auslösen.
  void _applyFilter(VoidCallback mutate) {
    setState(() {
      mutate();
      _future = _load();
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
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 10),
                child: Text(
                  _isPureTab
                      ? 'Nur Läufe mit ausgeschalteten Jokern.'
                      : 'Joker-Fragen zählen zur Hälfte.',
                  textAlign: TextAlign.center,
                  style: AppTypography.sans(
                    fontSize: 12,
                    color: palette.inkMuted,
                  ),
                ),
              ),
              // Eine Zeile Menü-Chips statt fünf gestapelter Filter-Reihen:
              // Default-Zustand zeigt den Kategorienamen (neutral), eine
              // aktive Auswahl den gewählten Wert (burgund).
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _MenuChip<_ModeGroup>(
                        placeholder: 'Modus',
                        valueLabel: _modeGroup == _ModeGroup.all
                            ? null
                            : _modeGroup.label,
                        selected: _modeGroup,
                        entries: [
                          for (final g in _ModeGroup.values)
                            (value: g, label: g.label),
                        ],
                        onSelected: (g) => _applyFilter(() {
                          if (_modeGroup != g) _variant = null;
                          _modeGroup = g;
                        }),
                      ),
                      if (_modeGroup.variants.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        _MenuChip<_VariantOption?>(
                          placeholder: 'Variante',
                          valueLabel: _variant?.label,
                          selected: _variant,
                          entries: [
                            (value: null, label: 'Alle'),
                            for (final v in _modeGroup.variants)
                              (value: v, label: v.label),
                          ],
                          onSelected: (v) =>
                              _applyFilter(() => _variant = v),
                        ),
                      ],
                      const SizedBox(width: 8),
                      _MenuChip<_InputStyleFilter>(
                        placeholder: 'Antwortart',
                        valueLabel: _inputStyle == _InputStyleFilter.all
                            ? null
                            : _inputStyle.label,
                        selected: _inputStyle,
                        entries: [
                          for (final s in _InputStyleFilter.values)
                            (value: s, label: s.label),
                        ],
                        onSelected: (s) =>
                            _applyFilter(() => _inputStyle = s),
                      ),
                      const SizedBox(width: 8),
                      _MenuChip<_BandFilter>(
                        placeholder: 'Schwierigkeit',
                        valueLabel:
                            _band == _BandFilter.all ? null : _band.label,
                        selected: _band,
                        entries: [
                          for (final b in _BandFilter.values)
                            (value: b, label: b.label),
                        ],
                        onSelected: (b) => _applyFilter(() => _band = b),
                      ),
                      const SizedBox(width: 8),
                      _MenuChip<_RangeFilter>(
                        placeholder: 'Zeitraum',
                        valueLabel: _range == _RangeFilter.allTime
                            ? null
                            : _range.label,
                        selected: _range,
                        entries: [
                          for (final r in _RangeFilter.values)
                            (value: r, label: r.label),
                        ],
                        onSelected: (r) => _applyFilter(() => _range = r),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: FutureBuilder<List<ScoreEntry>>(
                  future: _future,
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

/// Kompakter Filter-Chip, der beim Tippen ein verankertes Auswahlmenü
/// öffnet. Im Default-Zustand ([valueLabel] == null) zeigt er neutral den
/// [placeholder]; mit aktiver Auswahl den gewählten Wert in Burgund —
/// aktive Filter sind so auf einen Blick erkennbar.
class _MenuChip<T> extends StatelessWidget {
  const _MenuChip({
    required this.placeholder,
    required this.valueLabel,
    required this.selected,
    required this.entries,
    required this.onSelected,
  });

  final String placeholder;
  final String? valueLabel;
  final T selected;
  final List<({T value, String label})> entries;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final active = valueLabel != null;
    return PopupMenuButton<T>(
      tooltip: placeholder,
      position: PopupMenuPosition.under,
      color: palette.page,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: palette.divider),
      ),
      itemBuilder: (_) => [
        for (final e in entries)
          PopupMenuItem<T>(
            value: e.value,
            height: 42,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    e.label,
                    style: AppTypography.sans(
                      fontSize: 13.5,
                      fontWeight: e.value == selected
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: e.value == selected
                          ? palette.burgundy
                          : palette.ink,
                    ),
                  ),
                ),
                if (e.value == selected)
                  Icon(
                    Icons.check_rounded,
                    size: 16,
                    color: palette.burgundy,
                  ),
              ],
            ),
          ),
      ],
      onSelected: onSelected,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.fromLTRB(14, 8, 10, 8),
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
              valueLabel ?? placeholder,
              style: AppTypography.sans(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: active ? palette.burgundy : palette.ink,
              ),
            ),
            const SizedBox(width: 2),
            Icon(
              Icons.expand_more_rounded,
              size: 17,
              color: active ? palette.burgundy : palette.inkMuted,
            ),
          ],
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

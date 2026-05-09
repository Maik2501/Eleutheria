import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../shared/widgets/chapter_heading.dart';
import '../../shared/widgets/parchment_background.dart';

/// Daily leaderboard, fed by a Supabase view:
///
/// ```sql
/// create table daily_scores (
///   day date not null,
///   player_id uuid not null,
///   display_name text not null,
///   score int not null,
///   correct int not null,
///   submitted_at timestamptz default now(),
///   primary key (day, player_id)
/// );
/// ```
class LeaderboardScreen extends ConsumerStatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  ConsumerState<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends ConsumerState<LeaderboardScreen> {
  Future<List<_Entry>>? _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<_Entry>> _load() async {
    try {
      final today = DateTime.now().toUtc();
      final dayKey =
          '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
      final rows = await Supabase.instance.client
          .from('daily_scores')
          .select()
          .eq('day', dayKey)
          .order('score', ascending: false)
          .limit(50);
      return (rows as List)
          .map((r) => _Entry(
                name: r['display_name'] as String,
                score: (r['score'] as num).toInt(),
                correct: (r['correct'] as num).toInt(),
              ))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  @override
  Widget build(BuildContext context) {
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
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            child: FutureBuilder<List<_Entry>>(
              future: _future,
              builder: (context, snap) {
                final palette = context.palette;
                if (snap.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                final list = snap.data ?? const [];
                if (list.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Noch keine Werte heute',
                            style: AppTypography.eyebrow(palette.gold)),
                        const SizedBox(height: 12),
                        Text(
                          'Sei die Erste, die heute spielt.',
                          style: TextStyle(color: palette.inkMuted),
                        ),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  itemCount: list.length + 1,
                  itemBuilder: (ctx, i) {
                    if (i == 0) {
                      return const Padding(
                        padding: EdgeInsets.only(bottom: 16),
                        child: ChapterHeading(
                          eyebrow: 'Heute',
                          title: 'Tagesrangliste',
                        ),
                      );
                    }
                    final e = list[i - 1];
                    return _Row(rank: i, entry: e);
                  },
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _Entry {
  const _Entry({required this.name, required this.score, required this.correct});
  final String name;
  final int score;
  final int correct;
}

class _Row extends StatelessWidget {
  const _Row({required this.rank, required this.entry});
  final int rank;
  final _Entry entry;

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
          color: podium ? palette.gold.withValues(alpha: 0.5) : palette.divider,
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
            child: Text(
              entry.name,
              style: AppTypography.serif(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: palette.ink,
                letterSpacing: -0.2,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            '${entry.score} P',
            style: AppTypography.serif(
              fontWeight: FontWeight.w700,
              fontSize: 15,
              color: palette.ink,
            ),
          ),
        ],
      ),
    );
  }
}

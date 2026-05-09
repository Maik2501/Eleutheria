import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../shared/widgets/parchment_background.dart';
import '../../shared/widgets/wax_seal.dart';
import 'crossword_controller.dart';
import 'models/crossword_puzzle.dart';
import 'models/puzzle_seed.dart';
import 'widgets/active_clue_strip.dart';
import 'widgets/crossword_grid.dart';
import 'widgets/crossword_keyboard.dart';

/// Real crossword mode. Picks the first puzzle from the seed for now;
/// later we'll add a puzzle-of-the-day rotation.
class CrosswordScreen extends ConsumerWidget {
  const CrosswordScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final puzzle = kCrosswordPuzzles.first;
    final state = ref.watch(crosswordProvider(puzzle));
    final ctrl = ref.read(crosswordProvider(puzzle).notifier);
    final palette = context.palette;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: Text(puzzle.title),
        actions: [
          IconButton(
            onPressed: ctrl.toggleDirection,
            icon: const Icon(Icons.swap_horiz_rounded),
            tooltip: 'Richtung wechseln',
          ),
        ],
      ),
      body: ParchmentBackground(
        child: SafeArea(
          child: state.completed
              ? _Solved(puzzle: puzzle)
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      child: Center(
                        child: CrosswordGrid(
                          state: state,
                          onTapCell: (r, c) => ctrl.focusCell(r, c),
                        ),
                      ),
                    ),
                    Builder(
                      builder: (_) {
                        final cell = puzzle.grid[state.focusRow][state.focusCol];
                        if (cell == null) return const SizedBox.shrink();
                        final word = cell.words.firstWhere(
                          (w) => w.direction == state.focusDirection,
                          orElse: () => cell.words.first,
                        );
                        final numbered = puzzle.numberedWords
                            .firstWhere((nw) => nw.word == word);
                        return ActiveClueStrip(
                          activeWord: word,
                          activeNumber: numbered.number,
                          onPrev: ctrl.focusPrevWord,
                          onNext: ctrl.focusNextWord,
                        );
                      },
                    ),
                    Expanded(
                      child: _CluesList(
                        puzzle: puzzle,
                        state: state,
                        onPick: ctrl.focusWord,
                      ),
                    ),
                    CrosswordKeyboard(
                      onLetter: ctrl.typeLetter,
                      onBackspace: ctrl.backspace,
                      onReveal: () => _confirmReveal(context, ctrl),
                    ),
                  ],
                ),
        ),
      ),
      backgroundColor: palette.parchment,
    );
  }

  Future<void> _confirmReveal(
    BuildContext context,
    CrosswordController ctrl,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ctx.palette.page,
        title: const Text('Wort aufgeben?'),
        content: const Text(
          'Das aktive Wort wird mit der korrekten Lösung gefüllt.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Doch nicht'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Aufgeben'),
          ),
        ],
      ),
    );
    if (confirm == true) ctrl.revealActiveWord();
  }
}

class _CluesList extends StatelessWidget {
  const _CluesList({
    required this.puzzle,
    required this.state,
    required this.onPick,
  });

  final CrosswordPuzzle puzzle;
  final CrosswordState state;
  final ValueChanged<CrosswordWord> onPick;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final across =
        puzzle.numberedWords.where((nw) => nw.word.direction == WordDirection.across).toList();
    final down =
        puzzle.numberedWords.where((nw) => nw.word.direction == WordDirection.down).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (across.isNotEmpty) ...[
            _SectionHeader(title: 'Waagerecht', palette: palette),
            for (final nw in across)
              _ClueRow(
                numberedWord: nw,
                puzzle: puzzle,
                state: state,
                isFocus: _isFocus(state, nw.word),
                onTap: () => onPick(nw.word),
              ),
            const SizedBox(height: 12),
          ],
          if (down.isNotEmpty) ...[
            _SectionHeader(title: 'Senkrecht', palette: palette),
            for (final nw in down)
              _ClueRow(
                numberedWord: nw,
                puzzle: puzzle,
                state: state,
                isFocus: _isFocus(state, nw.word),
                onTap: () => onPick(nw.word),
              ),
          ],
        ],
      ),
    );
  }

  bool _isFocus(CrosswordState s, CrosswordWord w) {
    final cell = s.puzzle.grid[s.focusRow][s.focusCol];
    if (cell == null) return false;
    return cell.words.contains(w) && s.focusDirection == w.direction;
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.palette});
  final String title;
  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 0, 6),
      child: Text(
        title.toUpperCase(),
        style: AppTypography.eyebrow(palette.gold),
      ),
    );
  }
}

class _ClueRow extends StatelessWidget {
  const _ClueRow({
    required this.numberedWord,
    required this.puzzle,
    required this.state,
    required this.isFocus,
    required this.onTap,
  });

  final NumberedWord numberedWord;
  final CrosswordPuzzle puzzle;
  final CrosswordState state;
  final bool isFocus;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final solved = puzzle.isWordSolved(numberedWord.word, state.typed);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: isFocus
                ? palette.gold.withValues(alpha: 0.16)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 28,
                child: Text(
                  '${numberedWord.number}',
                  style: AppTypography.serif(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: solved ? palette.correct : palette.ink,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  numberedWord.word.clue,
                  style: AppTypography.sans(
                    fontSize: 14,
                    height: 1.4,
                    color: solved ? palette.inkMuted : palette.ink,
                  ).copyWith(
                    decoration:
                        solved ? TextDecoration.lineThrough : TextDecoration.none,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 8, top: 1),
                child: Text(
                  '(${numberedWord.word.answer.length})',
                  style: AppTypography.sans(
                    fontSize: 12,
                    color: palette.inkMuted,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Solved extends StatelessWidget {
  const _Solved({required this.puzzle});
  final CrosswordPuzzle puzzle;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const WaxSeal(symbol: '✪', size: 86)
              .animate()
              .scale(
                duration: 520.ms,
                curve: Curves.elasticOut,
                begin: const Offset(0.6, 0.6),
                end: const Offset(1, 1),
              ),
          const SizedBox(height: 22),
          Text(
            'Tabula perfecta.',
            style: AppTypography.serif(
              fontSize: 30,
              fontWeight: FontWeight.w600,
              color: palette.ink,
              letterSpacing: -0.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Du hast „${puzzle.title}" gelöst.',
            textAlign: TextAlign.center,
            style: AppTypography.sans(
              color: palette.inkMuted,
              fontSize: 14,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 32),
          FilledButton(
            onPressed: () => context.go('/'),
            child: const Text('Zurück zum Menü'),
          ),
        ],
      ),
    );
  }
}

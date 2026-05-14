import 'dart:math' as math;

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

/// Real crossword mode with native Flutter grid, central input and puzzle
/// selection. The Builder demos are compiled as static, offline-ready seeds.
class CrosswordScreen extends ConsumerStatefulWidget {
  const CrosswordScreen({super.key});

  @override
  ConsumerState<CrosswordScreen> createState() => _CrosswordScreenState();
}

class _CrosswordScreenState extends ConsumerState<CrosswordScreen> {
  int _puzzleIndex = 0;
  bool _showLetterFeedback = false;

  int get _safePuzzleIndex =>
      _puzzleIndex.clamp(0, kCrosswordPuzzles.length - 1).toInt();

  @override
  Widget build(BuildContext context) {
    final selectedIndex = _safePuzzleIndex;
    final puzzle = kCrosswordPuzzles[selectedIndex];
    final state = ref.watch(crosswordProvider(puzzle));
    final ctrl = ref.read(crosswordProvider(puzzle).notifier);
    final palette = context.palette;
    final activeWord = _activeWord(puzzle, state);
    final activeNumber = activeWord == null
        ? 0
        : puzzle.numberedWords.firstWhere((nw) => nw.word == activeWord).number;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: const Text('Kreuzworträtsel'),
        actions: [
          IconButton(
            isSelected: _showLetterFeedback,
            selectedIcon: const Icon(Icons.check_circle_rounded),
            icon: const Icon(Icons.check_circle_outline_rounded),
            onPressed: () => setState(
              () => _showLetterFeedback = !_showLetterFeedback,
            ),
            tooltip: _showLetterFeedback
                ? 'Prüfmodus ausschalten'
                : 'Prüfmodus einschalten',
          ),
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
              : LayoutBuilder(
                  builder: (context, constraints) {
                    final compact = constraints.maxHeight < 760;
                    final bottomPanelExtent = _bottomPanelExtent(compact);

                    return Stack(
                      children: [
                        Positioned.fill(
                          child: SingleChildScrollView(
                            physics: const BouncingScrollPhysics(),
                            padding: EdgeInsets.only(
                              bottom: bottomPanelExtent + 14,
                            ),
                            child: Column(
                              children: [
                                _PuzzleHeader(
                                  puzzle: puzzle,
                                  progress: puzzle.progress(state.typed),
                                  selectedIndex: selectedIndex,
                                  compact: compact,
                                  showLetterFeedback: _showLetterFeedback,
                                  onPuzzleChanged: (index) {
                                    if (index == _puzzleIndex) return;
                                    setState(() => _puzzleIndex = index);
                                  },
                                ),
                                Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: compact ? 4 : 8,
                                  ),
                                  child: Center(
                                    child: RepaintBoundary(
                                      child: CrosswordGrid(
                                        state: state,
                                        maxSide: _gridSideFor(
                                          constraints,
                                          compact,
                                        ),
                                        showLetterFeedback: _showLetterFeedback,
                                        onTapCell: ctrl.focusCell,
                                      ),
                                    ),
                                  ),
                                ),
                                if (activeWord != null)
                                  ActiveClueStrip(
                                    activeWord: activeWord,
                                    activeNumber: activeNumber,
                                    onPrev: ctrl.focusPrevWord,
                                    onNext: ctrl.focusNextWord,
                                  ),
                                _CluesList(
                                  puzzle: puzzle,
                                  state: state,
                                  onPick: ctrl.focusWord,
                                ),
                              ],
                            ),
                          ),
                        ),
                        Align(
                          alignment: Alignment.bottomCenter,
                          child: RepaintBoundary(
                            child: CrosswordKeyboard(
                              compact: compact,
                              onLetter: ctrl.typeLetter,
                              onBackspace: ctrl.backspace,
                              onReveal: () => _confirmReveal(context, ctrl),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
        ),
      ),
      backgroundColor: palette.parchment,
    );
  }

  double _gridSideFor(BoxConstraints constraints, bool compact) {
    final widthCap = math.max(0.0, constraints.maxWidth - 24);
    final heightCap = constraints.maxHeight * (compact ? 0.50 : 0.58);
    final cap = math.min(widthCap, heightCap);
    if (cap <= 0) return compact ? 360 : 440;
    return math.min(cap, compact ? 370 : 480);
  }

  double _bottomPanelExtent(bool compact) => compact ? 162 : 204;

  CrosswordWord? _activeWord(CrosswordPuzzle puzzle, CrosswordState state) {
    final cell = puzzle.grid[state.focusRow][state.focusCol];
    if (cell == null) return null;
    return cell.words.firstWhere(
      (w) => w.direction == state.focusDirection,
      orElse: () => cell.words.first,
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

class _PuzzleHeader extends StatelessWidget {
  const _PuzzleHeader({
    required this.puzzle,
    required this.progress,
    required this.selectedIndex,
    required this.compact,
    required this.showLetterFeedback,
    required this.onPuzzleChanged,
  });

  final CrosswordPuzzle puzzle;
  final double progress;
  final int selectedIndex;
  final bool compact;
  final bool showLetterFeedback;
  final ValueChanged<int> onPuzzleChanged;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      width: double.infinity,
      margin: EdgeInsets.fromLTRB(14, compact ? 2 : 4, 14, compact ? 6 : 8),
      padding: EdgeInsets.all(compact ? 12 : 14),
      decoration: BoxDecoration(
        color: palette.page,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: palette.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      puzzle.sourceLabel.toUpperCase(),
                      style: AppTypography.eyebrow(palette.gold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      puzzle.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.serif(
                        fontSize: compact ? 20 : 22,
                        fontWeight: FontWeight.w600,
                        color: palette.ink,
                        height: 1.1,
                      ),
                    ),
                  ],
                ),
              ),
              DropdownButtonHideUnderline(
                child: DropdownButton<int>(
                  value: selectedIndex,
                  borderRadius: BorderRadius.circular(8),
                  icon: const Icon(Icons.expand_more_rounded),
                  items: [
                    for (var i = 0; i < kCrosswordPuzzles.length; i++)
                      DropdownMenuItem(
                        value: i,
                        child: Text(kCrosswordPuzzles[i].title),
                      ),
                  ],
                  onChanged: (value) {
                    if (value != null) onPuzzleChanged(value);
                  },
                ),
              ),
            ],
          ),
          SizedBox(height: compact ? 6 : 8),
          Text(
            puzzle.theme,
            maxLines: compact ? 1 : 2,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.sans(
              fontSize: compact ? 12.5 : 13,
              height: 1.35,
              color: palette.inkMuted,
            ),
          ),
          SizedBox(height: compact ? 9 : 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              minHeight: 5,
              value: progress.clamp(0, 1).toDouble(),
              backgroundColor: palette.parchment,
              color: palette.gold,
            ),
          ),
          SizedBox(height: compact ? 8 : 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _InfoChip(
                icon: Icons.grid_4x4_rounded,
                label: '${puzzle.gridRows}×${puzzle.gridCols}',
              ),
              _InfoChip(
                icon: Icons.lightbulb_rounded,
                label: '${puzzle.words.length} Hinweise',
              ),
              _InfoChip(
                icon: Icons.speed_rounded,
                label: puzzle.difficulty,
              ),
              _InfoChip(
                icon: Icons.schedule_rounded,
                label: '${puzzle.estimatedMinutes} Min.',
              ),
              const _InfoChip(
                icon: Icons.keyboard_alt_rounded,
                label: 'Eingabe',
              ),
              _InfoChip(
                icon: showLetterFeedback
                    ? Icons.check_circle_rounded
                    : Icons.check_circle_outline_rounded,
                label: 'Prüfmodus',
                active: showLetterFeedback,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip(
      {required this.icon, required this.label, this.active = false,});

  final IconData icon;
  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: active
            ? palette.correct.withValues(alpha: 0.14)
            : palette.parchment.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: active
              ? palette.correct.withValues(alpha: 0.45)
              : palette.divider,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon,
              size: 14, color: active ? palette.correct : palette.burgundy,),
          const SizedBox(width: 5),
          Text(
            label,
            style: AppTypography.sans(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: palette.ink,
            ),
          ),
        ],
      ),
    );
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
    final across = puzzle.numberedWords
        .where((nw) => nw.word.direction == WordDirection.across)
        .toList();
    final down = puzzle.numberedWords
        .where((nw) => nw.word.direction == WordDirection.down)
        .toList();

    return Padding(
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
                    decoration: solved
                        ? TextDecoration.lineThrough
                        : TextDecoration.none,
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
          const WaxSeal(symbol: '✪', size: 86).animate().scale(
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

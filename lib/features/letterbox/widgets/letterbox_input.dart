import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../answer_normalization.dart';
import '../letterbox_joker.dart';
import '../letterbox_hyphenation.dart';

/// One row of letter boxes whose count matches the target answer's length.
/// Multi-word answers render with a small gap between word groups.
///
/// A hidden, focused TextField captures keystrokes and drives the visible
/// boxes. The keyboard pops up when the field has focus.
class LetterboxInput extends StatefulWidget {
  const LetterboxInput({
    super.key,
    required this.target,
    required this.revealed,
    required this.wasCorrect,
    required this.onChanged,
    required this.onSubmitted,
    this.revealedIndices = const {},
  });

  /// Raw correct answer from the question. Internally normalized.
  final String target;

  /// True after submit — locks input and tints boxes by correctness.
  final bool revealed;
  final bool wasCorrect;

  final ValueChanged<String> onChanged;
  final Set<int> revealedIndices;

  /// Triggered by Enter on hardware keyboard or by the consumer-controlled
  /// submit button.
  final ValueChanged<String> onSubmitted;

  @override
  State<LetterboxInput> createState() => LetterboxInputState();
}

class LetterboxInputState extends State<LetterboxInput> {
  late final TextEditingController _controller;
  late final FocusNode _focus;

  String get _normalizedTarget => normalizeForLetterbox(widget.target);

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _focus = FocusNode();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!widget.revealed) _focus.requestFocus();
    });
    _controller.addListener(_emitChanged);
  }

  @override
  void didUpdateWidget(covariant LetterboxInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.target != widget.target) {
      _controller.text = '';
      return;
    }
    if (!setEquals(oldWidget.revealedIndices, widget.revealedIndices)) {
      final limit = letterboxTypingLimit(widget.target, widget.revealedIndices);
      if (_controller.text.length > limit) {
        _controller.text = _controller.text.substring(0, limit);
      } else {
        _emitChanged();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  /// Allows external code (the screen) to reset the field at the start of
  /// each new question without recreating the widget.
  void reset() {
    _controller.text = '';
    if (!widget.revealed) _focus.requestFocus();
  }

  /// Public submit hook used by the screen's "Lösen" button.
  String get value => mergeLetterboxReveals(
        widget.target,
        _controller.text,
        widget.revealedIndices,
      );

  void _emitChanged() => widget.onChanged(value);

  @override
  Widget build(BuildContext context) {
    final target = _normalizedTarget;
    final words = target.split(' ');
    final typed = _controller.text;
    final typingLimit = letterboxTypingLimit(
      widget.target,
      widget.revealedIndices,
    );

    return Column(
      children: [
        // Hidden text field — captures keystrokes and shows the soft keyboard.
        Opacity(
          opacity: 0,
          child: SizedBox(
            height: 1,
            child: TextField(
              controller: _controller,
              focusNode: _focus,
              autocorrect: false,
              enableSuggestions: false,
              textCapitalization: TextCapitalization.characters,
              keyboardType: TextInputType.text,
              maxLength: typingLimit,
              inputFormatters: [
                FilteringTextInputFormatter.allow(
                  RegExp(r'[A-Za-zÄÖÜäöüß0-9\-]'),
                ),
                LengthLimitingTextInputFormatter(
                  typingLimit,
                ),
              ],
              onSubmitted: (_) => widget.onSubmitted(value),
            ),
          ),
        ),
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.revealed ? null : _focus.requestFocus,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 16,
                  runSpacing: 12,
                  children: [
                    for (var w = 0; w < words.length; w++)
                      _WordRow(
                        indexOffset: _wordOffset(words, w),
                        maxWidth: constraints.maxWidth,
                        length: words[w].length,
                        typedRange: _typedSliceForWord(
                          typed,
                          words,
                          w,
                          widget.revealedIndices,
                        ),
                        targetSlice: words[w],
                        revealedIndices: widget.revealedIndices,
                        revealed: widget.revealed,
                        wasCorrect: widget.wasCorrect,
                      ),
                  ],
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  /// Maps the compact user input onto this word's non-revealed boxes.
  String _typedSliceForWord(
    String typed,
    List<String> words,
    int wordIndex,
    Set<int> revealedIndices,
  ) {
    final globalOffset = _wordOffset(words, wordIndex);
    var rawStart = 0;
    for (var i = 0; i < wordIndex; i++) {
      for (var c = 0; c < words[i].length; c++) {
        if (!revealedIndices.contains(_wordOffset(words, i) + c) &&
            isLetterboxTypedCharacter(words[i][c])) {
          rawStart++;
        }
      }
    }

    var rawLength = 0;
    for (var i = 0; i < words[wordIndex].length; i++) {
      if (!revealedIndices.contains(globalOffset + i) &&
          isLetterboxTypedCharacter(words[wordIndex][i])) {
        rawLength++;
      }
    }

    if (rawStart >= typed.length) return '';
    final end = (rawStart + rawLength).clamp(0, typed.length);
    return typed.substring(rawStart, end);
  }

  int _wordOffset(List<String> words, int wordIndex) {
    var offset = 0;
    for (var i = 0; i < wordIndex; i++) {
      offset += words[i].length;
    }
    return offset;
  }
}

class _WordRow extends StatelessWidget {
  const _WordRow({
    required this.indexOffset,
    required this.maxWidth,
    required this.length,
    required this.typedRange,
    required this.targetSlice,
    required this.revealedIndices,
    required this.revealed,
    required this.wasCorrect,
  });

  final int indexOffset;
  final double maxWidth;
  final int length;
  final String typedRange;
  final String targetSlice;
  final Set<int> revealedIndices;
  final bool revealed;
  final bool wasCorrect;

  @override
  Widget build(BuildContext context) {
    const preferredWidth = 36.0;
    const preferredHeight = 46.0;
    const minWidth = 24.0;
    const hyphenMarkerWidth = 10.0;
    final safeWidth = maxWidth.isFinite && maxWidth > 0 ? maxWidth : 360.0;
    final gap = length > 10 ? 4.0 : 6.0;
    final preferredTotal =
        length * preferredWidth + math.max(0, length - 1) * gap;

    if (preferredTotal <= safeWidth) {
      return _LetterRun(
        start: 0,
        end: length,
        cellWidth: preferredWidth,
        cellHeight: preferredHeight,
        gap: gap,
        trailingHyphen: false,
        hyphenMarkerWidth: hyphenMarkerWidth,
        indexOffset: indexOffset,
        typedRange: typedRange,
        targetSlice: targetSlice,
        revealedIndices: revealedIndices,
        revealed: revealed,
        wasCorrect: wasCorrect,
      );
    }

    final compressedWidth =
        ((safeWidth - math.max(0, length - 1) * gap) / length)
            .clamp(minWidth, preferredWidth)
            .toDouble();
    final compressedTotal =
        length * compressedWidth + math.max(0, length - 1) * gap;

    if (compressedTotal <= safeWidth || length <= 3) {
      return _LetterRun(
        start: 0,
        end: length,
        cellWidth: compressedWidth,
        cellHeight: preferredHeight - (preferredWidth - compressedWidth) * 0.35,
        gap: gap,
        trailingHyphen: false,
        hyphenMarkerWidth: hyphenMarkerWidth,
        indexOffset: indexOffset,
        typedRange: typedRange,
        targetSlice: targetSlice,
        revealedIndices: revealedIndices,
        revealed: revealed,
        wasCorrect: wasCorrect,
      );
    }

    final maxCellsPerLine = math.max(
      1,
      ((safeWidth - (gap / 2) - hyphenMarkerWidth + gap) / (minWidth + gap))
          .floor(),
    );
    final segments = splitWordForLetterbox(
      word: targetSlice,
      maxCellsPerLine: maxCellsPerLine,
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        for (var i = 0; i < segments.length; i++)
          Padding(
            padding: EdgeInsets.only(
              bottom: i < segments.length - 1 ? 6 : 0,
            ),
            child: _LetterRun(
              start: segments[i].start,
              end: segments[i].end,
              cellWidth: minWidth,
              cellHeight: 38,
              gap: gap,
              trailingHyphen: segments[i].showTrailingHyphen,
              hyphenMarkerWidth: hyphenMarkerWidth,
              indexOffset: indexOffset,
              typedRange: typedRange,
              targetSlice: targetSlice,
              revealedIndices: revealedIndices,
              revealed: revealed,
              wasCorrect: wasCorrect,
            ),
          ),
      ],
    );
  }
}

class _LetterRun extends StatelessWidget {
  const _LetterRun({
    required this.start,
    required this.end,
    required this.cellWidth,
    required this.cellHeight,
    required this.gap,
    required this.trailingHyphen,
    required this.hyphenMarkerWidth,
    required this.indexOffset,
    required this.typedRange,
    required this.targetSlice,
    required this.revealedIndices,
    required this.revealed,
    required this.wasCorrect,
  });

  final int start;
  final int end;
  final double cellWidth;
  final double cellHeight;
  final double gap;
  final bool trailingHyphen;
  final double hyphenMarkerWidth;
  final int indexOffset;
  final String typedRange;
  final String targetSlice;
  final Set<int> revealedIndices;
  final bool revealed;
  final bool wasCorrect;

  @override
  Widget build(BuildContext context) {
    final cells = <Widget>[];
    var typedIndex = 0;
    for (var i = 0; i < start; i++) {
      if (!revealedIndices.contains(indexOffset + i) &&
          isLetterboxTypedCharacter(targetSlice[i])) {
        typedIndex++;
      }
    }

    for (var i = start; i < end; i++) {
      if (cells.isNotEmpty) cells.add(SizedBox(width: gap));
      final isFixed = !isLetterboxTypedCharacter(targetSlice[i]);
      final isHinted = isFixed || revealedIndices.contains(indexOffset + i);
      final typedChar = !isHinted && typedIndex < typedRange.length
          ? typedRange[typedIndex]
          : null;
      cells.add(
        _LetterCell(
          width: cellWidth,
          height: cellHeight,
          char: typedChar ?? (isHinted ? targetSlice[i] : null),
          isActive: !revealed && !isHinted && typedIndex == typedRange.length,
          isHinted: !revealed && typedChar == null && isHinted,
          revealed: revealed,
          isCorrectChar: revealed && typedChar != null
              ? canonicalize(typedChar) == canonicalize(targetSlice[i])
              : null,
          wasCorrectOverall: wasCorrect,
        ),
      );
      if (!isHinted) typedIndex++;
    }
    if (trailingHyphen) {
      cells.add(SizedBox(width: gap / 2));
      cells.add(_LineBreakHyphen(width: hyphenMarkerWidth, height: cellHeight));
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: cells,
    );
  }
}

class _LineBreakHyphen extends StatelessWidget {
  const _LineBreakHyphen({required this.width, required this.height});

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return SizedBox(
      width: width,
      height: height,
      child: Align(
        alignment: Alignment.center,
        child: Text(
          '-',
          style: AppTypography.serif(
            fontSize: (height * 0.58).clamp(16.0, 22.0),
            fontWeight: FontWeight.w700,
            color: palette.inkMuted,
            height: 1.0,
          ),
        ),
      ),
    );
  }
}

class _LetterCell extends StatelessWidget {
  const _LetterCell({
    required this.width,
    required this.height,
    required this.char,
    required this.isActive,
    required this.isHinted,
    required this.revealed,
    required this.isCorrectChar,
    required this.wasCorrectOverall,
  });

  final double width;
  final double height;
  final String? char;
  final bool isActive;
  final bool isHinted;
  final bool revealed;

  /// null = ungeklärt; true/false nach Reveal pro Buchstabe.
  final bool? isCorrectChar;

  /// Whether the player got the whole answer right.
  final bool wasCorrectOverall;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    final Color borderColor;
    final Color bgColor;
    final Color textColor;

    if (revealed) {
      if (wasCorrectOverall) {
        borderColor = palette.correct;
        bgColor = palette.correct.withValues(alpha: 0.10);
        textColor = palette.correct;
      } else {
        borderColor = palette.incorrect;
        bgColor = palette.incorrect.withValues(alpha: 0.06);
        textColor = palette.incorrect;
      }
    } else if (isActive) {
      borderColor = palette.burgundy;
      bgColor = palette.page;
      textColor = palette.ink;
    } else if (isHinted) {
      borderColor = palette.hint;
      bgColor = palette.hint.withValues(alpha: 0.10);
      textColor = palette.hint;
    } else {
      borderColor = palette.divider;
      bgColor = palette.page;
      textColor = palette.ink;
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      width: width,
      height: height,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: bgColor,
        border: Border.all(
          color: borderColor,
          width: isActive ? 2 : 1.2,
        ),
        borderRadius: BorderRadius.circular(8),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: palette.burgundy.withValues(alpha: 0.18),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Text(
        (char ?? '').toUpperCase(),
        style: AppTypography.serif(
          fontSize: (width * 0.62).clamp(15.0, 22.0),
          fontWeight: FontWeight.w700,
          color: textColor,
          height: 1.0,
        ),
      ),
    );
  }
}

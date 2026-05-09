import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../answer_normalization.dart';

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
  });

  /// Raw correct answer from the question. Internally normalized.
  final String target;

  /// True after submit — locks input and tints boxes by correctness.
  final bool revealed;
  final bool wasCorrect;

  final ValueChanged<String> onChanged;

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
    _controller.addListener(() {
      widget.onChanged(_controller.text);
    });
  }

  @override
  void didUpdateWidget(covariant LetterboxInput old) {
    super.didUpdateWidget(old);
    if (old.target != widget.target) {
      _controller.text = '';
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
  String get value => _controller.text;

  @override
  Widget build(BuildContext context) {
    final target = _normalizedTarget;
    final words = target.split(' ');
    final typed = _controller.text;

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
              maxLength: target.replaceAll(' ', '').length,
              inputFormatters: [
                FilteringTextInputFormatter.allow(
                  RegExp(r'[A-Za-zÄÖÜäöüß0-9\-]'),
                ),
                LengthLimitingTextInputFormatter(
                  target.replaceAll(' ', '').length,
                ),
              ],
              onSubmitted: widget.onSubmitted,
            ),
          ),
        ),
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.revealed ? null : _focus.requestFocus,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: 18,
              runSpacing: 12,
              children: [
                for (var w = 0; w < words.length; w++)
                  _WordRow(
                    length: words[w].length,
                    typedRange: _typedSliceForWord(typed, words, w),
                    targetSlice: words[w],
                    revealed: widget.revealed,
                    wasCorrect: widget.wasCorrect,
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Maps the contiguous typed string onto the per-word boxes. Spaces in the
  /// target answer are skipped — the user just types letters.
  String _typedSliceForWord(String typed, List<String> words, int wordIndex) {
    var offset = 0;
    for (var i = 0; i < wordIndex; i++) {
      offset += words[i].length;
    }
    final end = (offset + words[wordIndex].length).clamp(0, typed.length);
    if (offset >= typed.length) return '';
    return typed.substring(offset, end);
  }
}

class _WordRow extends StatelessWidget {
  const _WordRow({
    required this.length,
    required this.typedRange,
    required this.targetSlice,
    required this.revealed,
    required this.wasCorrect,
  });

  final int length;
  final String typedRange;
  final String targetSlice;
  final bool revealed;
  final bool wasCorrect;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < length; i++)
          _LetterCell(
            char: i < typedRange.length ? typedRange[i] : null,
            isActive: !revealed && i == typedRange.length,
            revealed: revealed,
            isCorrectChar:
                revealed && i < targetSlice.length && i < typedRange.length
                    ? canonicalize(typedRange[i]) ==
                        canonicalize(targetSlice[i])
                    : null,
            wasCorrectOverall: wasCorrect,
          ),
      ].expand((w) sync* {
        yield w;
        yield const SizedBox(width: 6);
      }).toList()
        ..removeLast(),
    );
  }
}

class _LetterCell extends StatelessWidget {
  const _LetterCell({
    required this.char,
    required this.isActive,
    required this.revealed,
    required this.isCorrectChar,
    required this.wasCorrectOverall,
  });

  final String? char;
  final bool isActive;
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
    } else {
      borderColor = palette.divider;
      bgColor = palette.page;
      textColor = palette.ink;
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      width: 36,
      height: 46,
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
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: textColor,
          height: 1.0,
        ),
      ),
    );
  }
}

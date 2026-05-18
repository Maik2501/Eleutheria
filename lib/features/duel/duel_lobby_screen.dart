import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../app/providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../data/models/answer_input_style.dart';
import '../../data/models/difficulty_band.dart';
import '../../data/models/duel_config.dart';
import '../../shared/widgets/chapter_heading.dart';
import '../../shared/widgets/parchment_background.dart';
import '../../shared/widgets/primary_button.dart';
import '../../shared/widgets/wax_seal.dart';
import 'duel_repository.dart';

final duelRepositoryProvider = Provider<DuelRepository?>((ref) {
  try {
    return DuelRepository(Supabase.instance.client);
  } on AssertionError {
    return null;
  } catch (_) {
    return null;
  }
});

class DuelLobbyScreen extends ConsumerStatefulWidget {
  const DuelLobbyScreen({super.key});

  @override
  ConsumerState<DuelLobbyScreen> createState() => _DuelLobbyScreenState();
}

class _DuelLobbyScreenState extends ConsumerState<DuelLobbyScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;
  final _codeCtrl = TextEditingController();

  DuelConfig _config = DuelConfig.threeMinutes;
  bool _busy = false;
  String? _error;

  // Custom-Switches per Feld — false = aus dem Preset-Chip, true = eigener Wert
  bool _customTime = false;
  bool _customLives = false;
  // Custom-Werte als Text, damit „∞" ohne Hacks geht
  int _customTimeSeconds = 600;
  int _customLivesValue = 5;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    _codeCtrl.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    final repo = ref.read(duelRepositoryProvider);
    final profile = ref.read(profileNotifierProvider).value;
    if (repo == null || profile == null) {
      setState(() => _error = 'Backend nicht erreichbar.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final match = await repo.createDuel(hostId: profile.id, config: _config);
      if (!mounted) return;
      context.push('/duel/${match.code}');
    } catch (e) {
      setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _join() async {
    final code = _codeCtrl.text.trim().toUpperCase();
    if (code.length != 6) {
      setState(() => _error = 'Sechsstelliger Code, bitte.');
      return;
    }
    final repo = ref.read(duelRepositoryProvider);
    final profile = ref.read(profileNotifierProvider).value;
    if (repo == null || profile == null) {
      setState(() => _error = 'Backend nicht erreichbar.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await repo.joinDuel(code: code, guestId: profile.id);
      if (!mounted) return;
      context.push('/duel/$code');
    } catch (e) {
      setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
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
        title: const Text('Duell'),
      ),
      body: ParchmentBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            child: Column(
              children: [
                const SizedBox(height: 8),
                const Center(child: WaxSeal(symbol: '⚔', size: 70)),
                const SizedBox(height: 18),
                const ChapterHeading(
                  eyebrow: 'Eristik',
                  title: 'Duell mit\neiner Freundin',
                  alignment: CrossAxisAlignment.center,
                ),
                const SizedBox(height: 22),
                TabBar(
                  controller: _tab,
                  labelColor: palette.burgundy,
                  unselectedLabelColor: palette.inkMuted,
                  indicatorColor: palette.gold,
                  labelStyle: AppTypography.button(),
                  tabs: const [
                    Tab(text: 'Lobby eröffnen'),
                    Tab(text: 'Beitreten'),
                  ],
                ),
                const SizedBox(height: 18),
                AnimatedBuilder(
                  animation: _tab,
                  builder: (_, __) => _tab.index == 0 ? _createPanel() : _joinPanel(),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: palette.incorrect, fontSize: 13),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── Create-Panel ───────────────────────────────────────────────────────

  Widget _createPanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ConfigBlock(
          label: 'Modus',
          hint: _config.mode == DuelMode.race
              ? 'Erste richtige Antwort gewinnt. Falsch = Frage für dich vorbei.'
              : 'Beide spielen unabhängig dieselben Fragen, Summe entscheidet.',
          child: SegmentedButton<DuelMode>(
            showSelectedIcon: false,
            selected: {_config.mode},
            onSelectionChanged: (s) =>
                setState(() => _config = _config.copyWith(mode: s.single)),
            segments: const [
              ButtonSegment(value: DuelMode.race, label: Text('Race')),
              ButtonSegment(value: DuelMode.parallel, label: Text('Parallel')),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _TimeChips(
          customActive: _customTime,
          currentSeconds: _customTime ? _customTimeSeconds : _config.timeLimitSeconds,
          onPreset: (sec) => setState(() {
            _customTime = false;
            _config = _config.copyWith(timeLimitSeconds: sec);
          }),
          onUnlimited: () => setState(() {
            _customTime = false;
            _config = _config.copyWith(clearTimeLimit: true);
          }),
          onCustomToggle: () => setState(() {
            _customTime = true;
            _config = _config.copyWith(timeLimitSeconds: _customTimeSeconds);
          }),
          onCustomChange: (sec) => setState(() {
            _customTimeSeconds = sec;
            _config = _config.copyWith(timeLimitSeconds: sec);
          }),
        ),
        const SizedBox(height: 16),
        _LivesChips(
          customActive: _customLives,
          current: _customLives ? _customLivesValue : _config.livesPerPlayer,
          onPreset: (n) => setState(() {
            _customLives = false;
            _config = _config.copyWith(livesPerPlayer: n);
          }),
          onUnlimited: () => setState(() {
            _customLives = false;
            _config = _config.copyWith(clearLives: true);
          }),
          onCustomToggle: () => setState(() {
            _customLives = true;
            _config = _config.copyWith(livesPerPlayer: _customLivesValue);
          }),
          onCustomChange: (n) => setState(() {
            _customLivesValue = n;
            _config = _config.copyWith(livesPerPlayer: n);
          }),
        ),
        const SizedBox(height: 16),
        _ConfigBlock(
          label: 'Eingabe',
          child: SegmentedButton<AnswerInputStyle>(
            showSelectedIcon: false,
            selected: {_config.inputStyle},
            onSelectionChanged: (s) =>
                setState(() => _config = _config.copyWith(inputStyle: s.single)),
            segments: const [
              ButtonSegment(
                value: AnswerInputStyle.multipleChoice,
                icon: Icon(Icons.checklist_rounded),
                label: Text('Multiple Choice'),
              ),
              ButtonSegment(
                value: AnswerInputStyle.letterbox,
                icon: Icon(Icons.keyboard_alt_rounded),
                label: Text('Eingabe'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _ConfigBlock(
          label: 'Schwierigkeit',
          child: SegmentedButton<DifficultyBand>(
            showSelectedIcon: false,
            selected: {_config.difficultyBand},
            onSelectionChanged: (s) => setState(
              () => _config = _config.copyWith(difficultyBand: s.single),
            ),
            segments: const [
              ButtonSegment(value: DifficultyBand.einstieg, label: Text('Einstieg')),
              ButtonSegment(value: DifficultyBand.salon, label: Text('Salon')),
              ButtonSegment(value: DifficultyBand.meisterpruefung, label: Text('Meister')),
            ],
          ),
        ),
        const SizedBox(height: 22),
        PrimaryButton(
          label: 'Lobby eröffnen',
          icon: Icons.add_rounded,
          loading: _busy,
          onPressed: _busy ? null : _create,
        ),
      ],
    );
  }

  // ─── Join-Panel ─────────────────────────────────────────────────────────

  Widget _joinPanel() {
    final palette = context.palette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Trag den Code ein, den die Host-Spielerin geteilt hat.',
          textAlign: TextAlign.center,
          style: TextStyle(color: palette.inkSoft, fontSize: 13.5),
        ),
        const SizedBox(height: 18),
        TextField(
          controller: _codeCtrl,
          autocorrect: false,
          enableSuggestions: false,
          textCapitalization: TextCapitalization.characters,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[A-Z0-9]')),
            LengthLimitingTextInputFormatter(6),
            TextInputFormatter.withFunction(
              (_, n) => TextEditingValue(
                text: n.text.toUpperCase(),
                selection: n.selection,
              ),
            ),
          ],
          style: AppTypography.serif(
            fontSize: 26,
            letterSpacing: 6,
            fontWeight: FontWeight.w600,
            color: palette.ink,
          ),
          textAlign: TextAlign.center,
          decoration: InputDecoration(
            filled: true,
            fillColor: palette.page,
            hintText: 'ABCDEF',
            hintStyle: TextStyle(
              color: palette.inkMuted.withValues(alpha: 0.4),
              letterSpacing: 6,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: palette.divider),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: palette.divider),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: palette.gold, width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 18),
          ),
        ),
        const SizedBox(height: 18),
        SecondaryButton(
          label: 'Lobby beitreten',
          icon: Icons.login_rounded,
          onPressed: _busy ? null : _join,
        ),
      ],
    );
  }
}

// ─── Config building blocks ────────────────────────────────────────────────

class _ConfigBlock extends StatelessWidget {
  const _ConfigBlock({required this.label, required this.child, this.hint});
  final String label;
  final Widget child;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: palette.page,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: palette.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: AppTypography.eyebrow(palette.inkMuted),
          ),
          const SizedBox(height: 10),
          SizedBox(width: double.infinity, child: child),
          if (hint != null) ...[
            const SizedBox(height: 8),
            Text(
              hint!,
              style: TextStyle(color: palette.inkMuted, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }
}

class _TimeChips extends StatelessWidget {
  const _TimeChips({
    required this.customActive,
    required this.currentSeconds,
    required this.onPreset,
    required this.onUnlimited,
    required this.onCustomToggle,
    required this.onCustomChange,
  });

  final bool customActive;
  final int? currentSeconds;
  final ValueChanged<int> onPreset;
  final VoidCallback onUnlimited;
  final VoidCallback onCustomToggle;
  final ValueChanged<int> onCustomChange;

  static const _presets = <int, String>{
    60: '1 min',
    180: '3 min',
    300: '5 min',
  };

  @override
  Widget build(BuildContext context) {
    return _ConfigBlock(
      label: 'Dauer',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final e in _presets.entries)
                _Chip(
                  label: e.value,
                  active: !customActive && currentSeconds == e.key,
                  onTap: () => onPreset(e.key),
                ),
              _Chip(
                label: '∞ ohne Limit',
                active: !customActive && currentSeconds == null,
                onTap: onUnlimited,
              ),
              _Chip(
                label: 'Eigene …',
                active: customActive,
                onTap: onCustomToggle,
              ),
            ],
          ),
          if (customActive) ...[
            const SizedBox(height: 12),
            _MinuteSlider(
              valueSeconds: currentSeconds ?? 600,
              onChanged: onCustomChange,
            ),
          ],
        ],
      ),
    );
  }
}

class _LivesChips extends StatelessWidget {
  const _LivesChips({
    required this.customActive,
    required this.current,
    required this.onPreset,
    required this.onUnlimited,
    required this.onCustomToggle,
    required this.onCustomChange,
  });

  final bool customActive;
  final int? current;
  final ValueChanged<int> onPreset;
  final VoidCallback onUnlimited;
  final VoidCallback onCustomToggle;
  final ValueChanged<int> onCustomChange;

  static const _presets = [3, 5, 10];

  @override
  Widget build(BuildContext context) {
    return _ConfigBlock(
      label: 'Leben pro Spielerin',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final n in _presets)
                _Chip(
                  label: '$n',
                  active: !customActive && current == n,
                  onTap: () => onPreset(n),
                ),
              _Chip(
                label: '∞ ohne Limit',
                active: !customActive && current == null,
                onTap: onUnlimited,
              ),
              _Chip(
                label: 'Eigene …',
                active: customActive,
                onTap: onCustomToggle,
              ),
            ],
          ),
          if (customActive) ...[
            const SizedBox(height: 12),
            _LivesSlider(
              value: current ?? 5,
              onChanged: onCustomChange,
            ),
          ],
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.active, required this.onTap});
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: active
                ? palette.burgundy.withValues(alpha: 0.18)
                : palette.parchment,
            border: Border.all(
              color: active
                  ? palette.burgundy.withValues(alpha: 0.55)
                  : palette.divider,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            label,
            style: AppTypography.sans(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: active ? palette.burgundy : palette.ink,
            ),
          ),
        ),
      ),
    );
  }
}

class _MinuteSlider extends StatelessWidget {
  const _MinuteSlider({required this.valueSeconds, required this.onChanged});
  final int valueSeconds;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final minutes = (valueSeconds / 60).round().clamp(1, 60);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '$minutes min',
          textAlign: TextAlign.center,
          style: AppTypography.serif(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: palette.ink,
          ),
        ),
        Slider(
          value: minutes.toDouble(),
          min: 1,
          max: 60,
          divisions: 59,
          activeColor: palette.burgundy,
          inactiveColor: palette.divider,
          onChanged: (v) => onChanged((v.round() * 60)),
        ),
      ],
    );
  }
}

class _LivesSlider extends StatelessWidget {
  const _LivesSlider({required this.value, required this.onChanged});
  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final v = value.clamp(1, 50);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '$v Leben',
          textAlign: TextAlign.center,
          style: AppTypography.serif(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: palette.ink,
          ),
        ),
        Slider(
          value: v.toDouble(),
          min: 1,
          max: 50,
          divisions: 49,
          activeColor: palette.burgundy,
          inactiveColor: palette.divider,
          onChanged: (val) => onChanged(val.round()),
        ),
      ],
    );
  }
}

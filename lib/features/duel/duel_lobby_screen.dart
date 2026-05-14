import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../app/providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../data/models/answer_input_style.dart';
import '../../shared/widgets/chapter_heading.dart';
import '../../shared/widgets/parchment_background.dart';
import '../../shared/widgets/primary_button.dart';
import '../../shared/widgets/wax_seal.dart';
import 'duel_repository.dart';

final duelRepositoryProvider = Provider<DuelRepository?>((ref) {
  try {
    return DuelRepository(Supabase.instance.client);
  } on AssertionError {
    // Supabase not configured
    return null;
  } catch (_) {
    return null;
  }
});

class DuelLobbyScreen extends ConsumerStatefulWidget {
  const DuelLobbyScreen({
    super.key,
    this.inputStyle = AnswerInputStyle.multipleChoice,
  });

  final AnswerInputStyle inputStyle;

  @override
  ConsumerState<DuelLobbyScreen> createState() => _DuelLobbyScreenState();
}

class _DuelLobbyScreenState extends ConsumerState<DuelLobbyScreen> {
  bool _busy = false;
  String? _error;
  final _codeCtrl = TextEditingController();

  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    final repo = ref.read(duelRepositoryProvider);
    final profile = ref.read(profileNotifierProvider).value;
    if (repo == null || profile == null) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final match = await repo.createDuel(hostId: profile.id);
      if (!mounted) return;
      context.push('/duel/${match.code}', extra: widget.inputStyle);
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
    if (repo == null || profile == null) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await repo.joinDuel(code: code, guestId: profile.id);
      if (!mounted) return;
      context.push('/duel/$code', extra: widget.inputStyle);
    } catch (e) {
      setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final hasBackend = ref.watch(duelRepositoryProvider) != null;

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
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 12),
                const Center(child: WaxSeal(symbol: '⚔', size: 76)),
                const SizedBox(height: 22),
                ChapterHeading(
                  eyebrow: 'Eristik',
                  title: 'Duell mit einer\nFreundin',
                  subtitle:
                      'Fünf Fragen. ${widget.inputStyle.label} ist für dich aktiv.',
                  alignment: CrossAxisAlignment.center,
                ),
                const SizedBox(height: 28),
                if (!hasBackend)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: palette.page,
                      border: Border.all(color: palette.divider),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.cloud_off_rounded, color: palette.inkMuted),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Online-Duelle benötigen einen Supabase-Schlüssel. Siehe README.',
                            style: TextStyle(color: palette.inkSoft, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  )
                else ...[
                  PrimaryButton(
                    label: 'Lobby eröffnen',
                    icon: Icons.add_rounded,
                    loading: _busy,
                    onPressed: _busy ? null : _create,
                  ),
                  const SizedBox(height: 22),
                  Row(
                    children: [
                      Expanded(child: Divider(color: palette.divider)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        child: Text(
                          'ODER',
                          style: AppTypography.eyebrow(palette.inkMuted),
                        ),
                      ),
                      Expanded(child: Divider(color: palette.divider)),
                    ],
                  ),
                  const SizedBox(height: 22),
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
                  const SizedBox(height: 14),
                  SecondaryButton(
                    label: 'Lobby beitreten',
                    icon: Icons.login_rounded,
                    onPressed: _busy ? null : _join,
                  ),
                ],
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
}

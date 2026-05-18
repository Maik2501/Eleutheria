import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../data/repositories/supabase_profile_repository.dart';
import '../../shared/widgets/chapter_heading.dart';
import '../../shared/widgets/parchment_background.dart';
import '../../shared/widgets/primary_button.dart';
import '../../shared/widgets/wax_seal.dart';

/// First-time profile setup. Asked once after anonymous sign-in succeeded
/// and before the player can reach the home screen. Reserves a globally
/// unique `display_name` in the `profiles` table.
class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  late final TextEditingController _ctrl;
  bool _busy = false;
  String? _errorMessage;
  List<String> _suggestions = const [];

  static const _defaultName = 'Schülerin der Philosophie';

  @override
  void initState() {
    super.initState();
    // Vorbelegen mit dem lokalen Namen, sofern der nicht der Default ist.
    final local = ref.read(profileNotifierProvider).value;
    final prefill = (local != null && local.displayName != _defaultName)
        ? local.displayName
        : '';
    _ctrl = TextEditingController(text: prefill);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _submit([String? override]) async {
    final input = (override ?? _ctrl.text).trim();
    final repo = ref.read(supabaseProfileRepositoryProvider);
    if (repo == null) {
      setState(
        () => _errorMessage =
            'Online-Verbindung fehlt. Versuch es gleich nochmal.',
      );
      return;
    }
    setState(() {
      _busy = true;
      _errorMessage = null;
      _suggestions = const [];
    });

    final result = await repo.reserve(input);
    if (!mounted) return;

    switch (result) {
      case ReservationOk():
        // Lokales Profil mit neuem Namen aktualisieren …
        await ref.read(profileNotifierProvider.notifier).renameTo(input);
        // … und das Gate aufmerken lassen, dass Remote jetzt existiert.
        ref.invalidate(remoteProfileProvider);
        // Kein manuelles Navigieren — das Gate switcht automatisch auf Home.
      case ReservationTaken(suggestions: final s):
        setState(() {
          _errorMessage = 'Der Name ist schon vergeben.';
          _suggestions = s;
          _busy = false;
        });
      case ReservationInvalid(reason: final r):
        setState(() {
          _errorMessage = r;
          _busy = false;
        });
      case ReservationOffline():
        setState(() {
          _errorMessage = 'Keine Verbindung. Versuch es nochmal.';
          _busy = false;
        });
      case ReservationError(message: final m):
        setState(() {
          _errorMessage = 'Fehler: $m';
          _busy = false;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Scaffold(
      body: ParchmentBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(28, 32, 28, 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Center(child: WaxSeal(symbol: 'Σ', size: 76)),
                  const SizedBox(height: 28),
                  const ChapterHeading(
                    eyebrow: 'Willkommen',
                    title: 'Wähle deinen\nAnzeigenamen',
                    subtitle:
                        'Dieser Name erscheint in Ranglisten und Duellen. '
                        'Er ist eindeutig und kannst du später in den '
                        'Einstellungen wechseln.',
                    alignment: CrossAxisAlignment.center,
                  ),
                  const SizedBox(height: 28),
                  _NameField(
                    controller: _ctrl,
                    enabled: !_busy,
                    onSubmitted: (_) => _submit(),
                  ),
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      _errorMessage!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: palette.incorrect,
                        fontSize: 13,
                      ),
                    ),
                  ],
                  if (_suggestions.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    Text(
                      'Vorschläge:',
                      textAlign: TextAlign.center,
                      style: AppTypography.eyebrow(palette.gold),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        for (final s in _suggestions)
                          _SuggestionChip(
                            label: s,
                            onTap: _busy
                                ? null
                                : () {
                                    _ctrl.text = s;
                                    _submit(s);
                                  },
                          ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 24),
                  PrimaryButton(
                    label: 'Reservieren',
                    icon: Icons.check_rounded,
                    loading: _busy,
                    onPressed: _busy ? null : () => _submit(),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '2–24 Zeichen · Buchstaben, Zahlen, Leerzeichen, _ . -',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: palette.inkMuted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NameField extends StatelessWidget {
  const _NameField({
    required this.controller,
    required this.enabled,
    required this.onSubmitted,
  });

  final TextEditingController controller;
  final bool enabled;
  final ValueChanged<String> onSubmitted;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return TextField(
      controller: controller,
      enabled: enabled,
      autofocus: true,
      autocorrect: false,
      enableSuggestions: false,
      textInputAction: TextInputAction.done,
      onSubmitted: onSubmitted,
      maxLength: 24,
      style: AppTypography.serif(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: palette.ink,
        letterSpacing: -0.2,
      ),
      textAlign: TextAlign.center,
      decoration: InputDecoration(
        filled: true,
        fillColor: palette.page,
        hintText: 'Hypatia',
        counterText: '',
        hintStyle: TextStyle(
          color: palette.inkMuted.withValues(alpha: 0.5),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 18),
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
      ),
    );
  }
}

class _SuggestionChip extends StatelessWidget {
  const _SuggestionChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: palette.gold.withValues(alpha: 0.14),
            border: Border.all(color: palette.gold.withValues(alpha: 0.5)),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            label,
            style: AppTypography.serif(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: palette.ink,
            ),
          ),
        ),
      ),
    );
  }
}

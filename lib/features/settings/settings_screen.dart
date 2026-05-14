import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../shared/widgets/parchment_background.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.palette;
    final p = ref.watch(profileNotifierProvider).value;
    final notifier = ref.read(profileNotifierProvider.notifier);
    if (p == null) return const SizedBox.shrink();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: const Text('Einstellungen'),
      ),
      body: ParchmentBackground(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          children: [
            Text('DARSTELLUNG', style: AppTypography.eyebrow(palette.inkMuted)),
            const SizedBox(height: 10),
            _SegmentedRow(
              value: p.themeMode,
              entries: const {
                'system': 'System',
                'light': 'Hell',
                'dark': 'Dunkel',
              },
              onChanged: notifier.setThemeMode,
            ),
            const SizedBox(height: 32),
            Text('SPRACHE', style: AppTypography.eyebrow(palette.inkMuted)),
            const SizedBox(height: 10),
            _SegmentedRow(
              value: p.locale == 'de' ? p.locale : 'de',
              entries: const {
                'de': 'Deutsch',
                'en': 'English',
              },
              disabledEntries: const {'en'},
              onChanged: notifier.setLocale,
            ),
            const SizedBox(height: 32),
            _ToggleTile(
              label: 'Vibrations-Feedback',
              value: p.hapticsEnabled,
              onChanged: notifier.setHaptics,
            ),
            _ToggleTile(
              label: 'Geräusche',
              value: p.soundsEnabled,
              onChanged: notifier.setSounds,
            ),
            const SizedBox(height: 32),
            Text('JOKER', style: AppTypography.eyebrow(palette.inkMuted)),
            const SizedBox(height: 10),
            _SegmentedRow(
              value: p.jokerAvailability.key,
              entries: const {
                'off': 'Aus',
                'one': '1 Joker',
                'three': '3 Joker',
                'always': 'Immer',
              },
              onChanged: notifier.setJokerAvailability,
            ),
            const SizedBox(height: 32),
            Text('ÜBER ELEUTHERIA',
                style: AppTypography.eyebrow(palette.inkMuted),),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: palette.page,
                border: Border.all(color: palette.divider),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                'Eleutheria ist ein liebevoll handgepflegtes Quiz für die Freundinnen und Freunde der Philosophie. '
                'Die Fragen wurden kuratiert; Quellen und Erläuterungen finden sich nach jeder Antwort.',
                style: TextStyle(
                    color: palette.inkSoft, height: 1.55, fontSize: 14,),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SegmentedRow extends StatelessWidget {
  const _SegmentedRow({
    required this.value,
    required this.entries,
    required this.onChanged,
    this.disabledEntries = const {},
  });

  final String value;
  final Map<String, String> entries;
  final ValueChanged<String> onChanged;
  final Set<String> disabledEntries;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      decoration: BoxDecoration(
        color: palette.page,
        border: Border.all(color: palette.divider),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: entries.entries.map((e) {
          final disabled = disabledEntries.contains(e.key);
          final selected = e.key == value;
          return Expanded(
            child: GestureDetector(
              onTap: disabled ? null : () => onChanged(e.key),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: selected && !disabled
                      ? palette.burgundy
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  e.value,
                  textAlign: TextAlign.center,
                  style: AppTypography.sans(
                    fontWeight: FontWeight.w600,
                    fontSize: 14.5,
                    letterSpacing: 0.1,
                    color: disabled
                        ? palette.inkMuted.withValues(alpha: 0.42)
                        : selected
                            ? AppColors.page
                            : palette.ink,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _ToggleTile extends StatelessWidget {
  const _ToggleTile({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: palette.page,
        border: Border.all(color: palette.divider),
        borderRadius: BorderRadius.circular(14),
      ),
      child: SwitchListTile(
        contentPadding: EdgeInsets.zero,
        value: value,
        onChanged: onChanged,
        activeThumbColor: palette.gold,
        title: Text(
          label,
          style: AppTypography.sans(
            fontWeight: FontWeight.w500,
            fontSize: 15,
            color: palette.ink,
          ),
        ),
      ),
    );
  }
}

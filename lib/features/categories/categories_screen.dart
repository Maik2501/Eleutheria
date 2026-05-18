// ARCHIVED 2026-05-16: Categories menu removed from the UI (Roadmap Block F).
// Datei bleibt liegen — eventuelle spätere Umwidmung als inhaltliche
// Sammlungen (Antike, Stoa, Feministische Philosophie etc.) wird neu
// gestaltet, nicht 1:1 wiederhergestellt. QuestionCategory-Enum bleibt
// unverändert, weil es weiterhin den Fragentyp markiert.
// ignore_for_file: unused_element

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../data/models/question.dart';
import '../../shared/widgets/chapter_heading.dart';
import '../../shared/widgets/parchment_background.dart';

class CategoriesScreen extends ConsumerWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: const Text('Sammlung'),
      ),
      body: ParchmentBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
            children: [
              const ChapterHeading(
                eyebrow: 'Wähle ein Thema',
                title: 'Kategorien',
                subtitle: 'Eine Sammlung von zehn Fragen aus deinem gewählten Bereich.',
              ),
              const SizedBox(height: 18),
              for (final c in QuestionCategory.values)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _CategoryTile(
                    category: c,
                    onTap: () => context.push('/play/category/${c.name}'),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({required this.category, required this.onTap});
  final QuestionCategory category;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: palette.page,
            border: Border.all(color: palette.divider),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: palette.gold.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  category.icon,
                  style: AppTypography.serif(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: palette.gold,
                    height: 1.0,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category.label,
                      style: AppTypography.serif(
                        fontWeight: FontWeight.w600,
                        fontSize: 17,
                        color: palette.ink,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      category.eyebrow,
                      style: AppTypography.sans(
                        fontSize: 12.5,
                        color: palette.inkMuted,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_rounded, color: palette.inkMuted),
            ],
          ),
        ),
      ),
    );
  }
}

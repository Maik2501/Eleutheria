import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import 'chapter_heading.dart';
import 'parchment_background.dart';

class ComingSoonScreen extends StatelessWidget {
  const ComingSoonScreen({
    super.key,
    required this.title,
    required this.message,
    this.icon = Icons.hourglass_empty_rounded,
  });

  final String title;
  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/');
            }
          },
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: Text(title),
      ),
      body: ParchmentBackground(
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: palette.gold.withValues(alpha: 0.14),
                      border: Border.all(color: palette.gold),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, color: palette.gold, size: 34),
                  ),
                  const SizedBox(height: 24),
                  ChapterHeading(
                    eyebrow: 'Bald verfügbar',
                    title: title,
                    subtitle: message,
                    alignment: CrossAxisAlignment.center,
                  ),
                  const SizedBox(height: 28),
                  FilledButton.icon(
                    onPressed: () => context.go('/'),
                    icon: const Icon(Icons.home_rounded),
                    label: const Text('Zur Startseite'),
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

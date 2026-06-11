import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../data/models/achievement.dart';
import '../../data/services/achievement_engine.dart';
import 'wax_seal.dart';

/// Modal celebration that announces freshly-unlocked achievement tiers.
///
/// One sheet per [UnlockedTier]; tap-to-dismiss advances to the next one.
/// The seal springs in with an elastic scale, then a gold sweep shimmers
/// across the wax — heavy haptic on appearance, light haptic on each advance.
class AchievementUnlockOverlay {
  AchievementUnlockOverlay._();

  /// Walk through every [unlocks] entry as its own modal. Returns when the
  /// player has dismissed the last one (or immediately if the list is empty).
  /// Safe to call with widgets that may have been unmounted in the meantime:
  /// the routine bails out as soon as the [context] no longer has a navigator.
  static Future<void> show(
    BuildContext context,
    List<UnlockedTier> unlocks,
  ) async {
    for (final unlock in unlocks) {
      if (!context.mounted) return;
      await _showOne(context, unlock);
    }
  }

  static Future<void> _showOne(BuildContext context, UnlockedTier unlock) {
    return showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Errungenschaft schließen',
      barrierColor: Colors.black.withValues(alpha: 0.62),
      transitionDuration: const Duration(milliseconds: 280),
      pageBuilder: (_, __, ___) => _UnlockSheet(unlock: unlock),
      transitionBuilder: (_, anim, __, child) => FadeTransition(
        opacity: CurvedAnimation(parent: anim, curve: Curves.easeOutCubic),
        child: child,
      ),
    );
  }
}

class _UnlockSheet extends StatefulWidget {
  const _UnlockSheet({required this.unlock});
  final UnlockedTier unlock;

  @override
  State<_UnlockSheet> createState() => _UnlockSheetState();
}

class _UnlockSheetState extends State<_UnlockSheet> {
  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final tint = widget.unlock.tier.level.tint;
    final isMultiTier = widget.unlock.achievement.isMultiTier;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 60),
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => Navigator.of(context).pop(),
        child: Container(
          padding: const EdgeInsets.fromLTRB(28, 30, 28, 24),
          decoration: BoxDecoration(
            color: palette.page,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: tint.withValues(alpha: 0.55), width: 1.4),
            boxShadow: [
              BoxShadow(
                color: tint.withValues(alpha: 0.28),
                blurRadius: 32,
                spreadRadius: 2,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'ERRUNGENSCHAFT FREIGESCHALTET',
                textAlign: TextAlign.center,
                style: AppTypography.eyebrow(tint),
              )
                  .animate()
                  .fadeIn(duration: 240.ms, delay: 380.ms)
                  .slideY(begin: -0.2, end: 0),
              const SizedBox(height: 22),
              WaxSeal(
                symbol: widget.unlock.tier.symbol,
                size: 132,
                color: tint,
                assetPath:
                    widget.unlock.achievement.assetPathOf(widget.unlock.tier),
              )
                  .animate()
                  .scale(
                    begin: const Offset(0.4, 0.4),
                    end: const Offset(1, 1),
                    duration: 620.ms,
                    curve: Curves.elasticOut,
                  )
                  .shimmer(
                    color: Colors.white.withValues(alpha: 0.7),
                    duration: 1100.ms,
                    delay: 320.ms,
                  ),
              const SizedBox(height: 22),
              Text(
                widget.unlock.title,
                textAlign: TextAlign.center,
                style: AppTypography.serif(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: palette.ink,
                  letterSpacing: -0.4,
                  height: 1.15,
                ),
              )
                  .animate()
                  .fadeIn(duration: 320.ms, delay: 460.ms)
                  .slideY(begin: 0.18, end: 0, curve: Curves.easeOutCubic),
              if (isMultiTier) ...[
                const SizedBox(height: 8),
                _TierChip(level: widget.unlock.tier.level)
                    .animate()
                    .fadeIn(duration: 260.ms, delay: 560.ms),
              ],
              const SizedBox(height: 14),
              Text(
                widget.unlock.achievement.description,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: palette.inkMuted,
                  fontSize: 14,
                  height: 1.4,
                ),
              )
                  .animate()
                  .fadeIn(duration: 320.ms, delay: 640.ms),
              const SizedBox(height: 22),
              Text(
                'Tippen, um fortzufahren',
                style: TextStyle(
                  color: palette.inkMuted.withValues(alpha: 0.7),
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              )
                  .animate(onPlay: (c) => c.repeat(reverse: true))
                  .fadeIn(duration: 800.ms, delay: 900.ms)
                  .then(delay: 800.ms)
                  .fadeOut(duration: 800.ms),
            ],
          ),
        ),
      ),
    );
  }
}

class _TierChip extends StatelessWidget {
  const _TierChip({required this.level});
  final TierLevel level;

  @override
  Widget build(BuildContext context) {
    final tint = level.tint;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: tint.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: tint.withValues(alpha: 0.55), width: 1),
      ),
      child: Text(
        level.label.toUpperCase(),
        style: TextStyle(
          color: tint,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 2,
        ),
      ),
    );
  }
}

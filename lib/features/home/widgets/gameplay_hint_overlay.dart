import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

/// Einmaliger Onboarding-Coachmark, der nach dem Update auf die neue
/// Gameplay-Sektion in den Einstellungen aufmerksam macht. Erscheint genau
/// einmal pro Profil — sobald [onDismiss] gefeuert hat, schreibt der
/// Aufrufer `hasSeenGameplayHint = true` und das Overlay verschwindet.
///
/// Layout: dezenter Backdrop (tap-to-dismiss) + Bubble unterhalb des
/// Settings-Icons in der oberen rechten Ecke. Die Bubble trägt einen
/// kleinen Dreieckspfeil nach oben, der visuell auf das Zahnrad zeigt.
class GameplayHintOverlay extends StatelessWidget {
  const GameplayHintOverlay({super.key, required this.onDismiss});

  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Positioned.fill(
      child: Stack(
        children: [
          // Backdrop — sanft, nicht voll-blockierend; Tap dismissed.
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onDismiss,
              child: ColoredBox(
                // Etwas heller als ein klassisches Modal-Backdrop, damit der
                // pulsierende Glow am Settings-Icon (HomeHeader) noch klar
                // durchscheint.
                color: AppColors.ink.withValues(alpha: 0.22),
              )
                  .animate()
                  .fadeIn(duration: 220.ms, curve: Curves.easeOut),
            ),
          ),
          SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              // Pixel-Werte abgestimmt auf den _HomeHeader: Settings-Icon
              // sitzt ungefähr bei top: 24, right: 8. Die Bubble landet
              // mit ihrem Pfeil knapp darunter.
              child: Padding(
                padding: const EdgeInsets.only(top: 78, right: 12),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 296),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 16),
                        child: CustomPaint(
                          size: const Size(18, 10),
                          painter: _ArrowPainter(
                            fill: palette.page,
                            border: palette.gold.withValues(alpha: 0.78),
                          ),
                        ),
                      ),
                      Container(
                        padding:
                            const EdgeInsets.fromLTRB(18, 14, 14, 12),
                        decoration: BoxDecoration(
                          color: palette.page,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: palette.gold.withValues(alpha: 0.78),
                            width: 1.4,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.ink.withValues(alpha: 0.22),
                              blurRadius: 26,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              children: [
                                Text(
                                  '✦',
                                  style: TextStyle(
                                    color: palette.gold,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'TIPP',
                                  style: AppTypography.eyebrow(palette.gold),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Hier findest du weitere Gameplay-Einstellungen: Joker, Schwierigkeit und Antwortart.',
                              style: AppTypography.serif(
                                fontSize: 14.5,
                                color: palette.ink,
                                height: 1.4,
                                letterSpacing: -0.1,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Align(
                              alignment: Alignment.centerRight,
                              child: FilledButton(
                                style: FilledButton.styleFrom(
                                  visualDensity: VisualDensity.compact,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                ),
                                onPressed: onDismiss,
                                child: const Text('Verstanden'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  )
                      .animate()
                      .fadeIn(duration: 360.ms, delay: 180.ms)
                      .moveY(
                        begin: -12,
                        end: 0,
                        duration: 420.ms,
                        delay: 180.ms,
                        curve: Curves.easeOutCubic,
                      ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Kleiner Sprechblasen-Pfeil. Zeichnet ein gefülltes Dreieck mit Spitze
/// nach oben und überlagert nur die beiden oberen Kanten als Border —
/// die Unterkante bleibt offen, weil sie an die Bubble anschließt.
class _ArrowPainter extends CustomPainter {
  _ArrowPainter({required this.fill, required this.border});
  final Color fill;
  final Color border;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(size.width / 2, 0)
      ..lineTo(0, size.height)
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(path, Paint()..color = fill);

    final borderPath = Path()
      ..moveTo(0, size.height)
      ..lineTo(size.width / 2, 0)
      ..lineTo(size.width, size.height);
    canvas.drawPath(
      borderPath,
      Paint()
        ..color = border
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..strokeJoin = StrokeJoin.miter,
    );
  }

  @override
  bool shouldRepaint(_ArrowPainter old) =>
      old.fill != fill || old.border != border;
}

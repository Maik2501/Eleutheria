import 'package:flutter/services.dart';

/// Zentrales Haptik-Gate (Launch-Bug 1): Die Einstellung `hapticsEnabled`
/// hatte keine Wirkung, weil alle Aufrufer [HapticFeedback] direkt riefen.
/// Sämtliche Vibrations-Aufrufe laufen jetzt hier durch; [enabled] wird vom
/// ProfileNotifier beim Laden des Profils und bei jeder Änderung gespiegelt.
class Haptics {
  Haptics._();

  static bool enabled = true;

  static void selection() {
    if (enabled) HapticFeedback.selectionClick();
  }

  static void light() {
    if (enabled) HapticFeedback.lightImpact();
  }

  static void medium() {
    if (enabled) HapticFeedback.mediumImpact();
  }

  static void heavy() {
    if (enabled) HapticFeedback.heavyImpact();
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../app/providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../shared/widgets/brand_seal.dart';
import '../../shared/widgets/parchment_background.dart';
import '../../shared/widgets/primary_button.dart';
import '../home/home_screen.dart';
import 'profile_setup_screen.dart';

/// Session-lokaler Notausgang: Nutzer hat im Retry-Screen "Offline
/// weiterspielen" gewählt. Resettet beim nächsten App-Start.
final _offlineBypassProvider = StateProvider<bool>((_) => false);

/// Decides what the root route shows:
/// * Splash while the remote profile is being fetched
/// * Retry screen on network errors — but only on the very first launch;
///   returning users (setup flag set) fall through to [HomeScreen] so a
///   server outage never locks them out of the offline modes
/// * [ProfileSetupScreen] when no remote profile exists for this user
/// * [HomeScreen] otherwise — and syncs the local display name from server
class ProfileGate extends ConsumerWidget {
  const ProfileGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Wenn Supabase nicht konfiguriert ist, geht es direkt zum Home
    // (Offline-Modus, Online-Features sind sowieso aus).
    final repo = ref.watch(supabaseProfileRepositoryProvider);
    if (repo == null) return const HomeScreen();
    if (!_hasSupabaseSession()) return const HomeScreen();

    final remote = ref.watch(remoteProfileProvider);

    // Wenn Remote-Profil da ist und vom lokalen abweicht: lokal nachziehen.
    // Server ist Quelle der Wahrheit für den Display-Name.
    ref.listen(remoteProfileProvider, (prev, next) {
      final profile = next.value;
      if (profile == null) return;
      final local = ref.read(profileNotifierProvider).value;
      if (local != null && local.displayName != profile.displayName) {
        ref
            .read(profileNotifierProvider.notifier)
            .renameTo(profile.displayName);
      }
    });

    return remote.when(
      loading: () => const _Splash(),
      error: (err, _) {
        // Wiederkehrende Nutzer nicht aussperren: Setup war schon mal
        // erfolgreich, also direkt ins Home — Offline-Modi funktionieren
        // ohne Server, Online-Features degradieren einzeln.
        if (ref.read(profileSetupFlagProvider).isDone) {
          return const HomeScreen();
        }
        if (ref.watch(_offlineBypassProvider)) return const HomeScreen();
        return _RetryScreen(
          message: 'Verbindung zum Server fehlgeschlagen.',
          onRetry: () => ref.invalidate(remoteProfileProvider),
          onPlayOffline: () =>
              ref.read(_offlineBypassProvider.notifier).state = true,
        );
      },
      data: (profile) =>
          profile == null ? const ProfileSetupScreen() : const HomeScreen(),
    );
  }

  bool _hasSupabaseSession() {
    try {
      return Supabase.instance.client.auth.currentUser != null;
    } catch (_) {
      return false;
    }
  }
}

class _Splash extends StatelessWidget {
  const _Splash();

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Scaffold(
      body: ParchmentBackground(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const BrandSeal(size: 92),
              const SizedBox(height: 22),
              Text(
                'Griphos',
                style: AppTypography.serif(
                  fontSize: 28,
                  fontWeight: FontWeight.w600,
                  color: palette.ink,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'philosophische Rätsel und Denkspiele',
                textAlign: TextAlign.center,
                style: AppTypography.sans(
                  fontSize: 13.5,
                  height: 1.4,
                  color: palette.inkMuted,
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  color: palette.gold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RetryScreen extends StatelessWidget {
  const _RetryScreen({
    required this.message,
    required this.onRetry,
    required this.onPlayOffline,
  });

  final String message;
  final VoidCallback onRetry;
  final VoidCallback onPlayOffline;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Scaffold(
      body: ParchmentBackground(
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.cloud_off_rounded,
                    size: 48,
                    color: palette.inkMuted,
                  ),
                  const SizedBox(height: 18),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: AppTypography.serif(
                      fontSize: 17,
                      color: palette.ink,
                    ),
                  ),
                  const SizedBox(height: 24),
                  PrimaryButton(
                    label: 'Erneut versuchen',
                    icon: Icons.refresh_rounded,
                    onPressed: onRetry,
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: onPlayOffline,
                    child: Text(
                      'Offline weiterspielen',
                      style: AppTypography.sans(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: palette.inkMuted,
                      ),
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

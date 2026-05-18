import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/eleutheria_app.dart';
import 'app/providers.dart';
import 'env.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  final prefs = await SharedPreferences.getInstance();

  if (Env.hasSupabase) {
    await Supabase.initialize(
      url: Env.supabaseUrl,
      anonKey: Env.supabaseAnonKey,
    );
    await _ensureAnonymousSession();
  }

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const EleutheriaApp(),
    ),
  );
}

/// Signs the player in anonymously if no session exists. This gives every
/// player a stable Supabase-UID that RLS-Policies can pin writes against.
///
/// Errors are swallowed: the app still runs offline if Supabase is reachable
/// at config-level but the network is currently down. UI-Code that depends
/// on auth should defensively check `Supabase.instance.client.auth.currentUser`.
Future<void> _ensureAnonymousSession() async {
  final auth = Supabase.instance.client.auth;
  if (auth.currentUser != null) return;
  try {
    await auth.signInAnonymously();
  } catch (_) {
    // Offline / Backend down — solo-Modus läuft weiter, Online-Features
    // sind deaktiviert bis zur nächsten App-Öffnung mit Internet.
  }
}

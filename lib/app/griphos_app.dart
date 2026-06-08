import 'dart:developer' as dev;

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/app_theme.dart';
import 'providers.dart';
import 'router.dart';

class GriphosApp extends ConsumerStatefulWidget {
  const GriphosApp({super.key});

  @override
  ConsumerState<GriphosApp> createState() => _GriphosAppState();
}

class _GriphosAppState extends ConsumerState<GriphosApp>
    with WidgetsBindingObserver {
  /// Mindestabstand zwischen zwei automatischen Refreshes beim Resume.
  /// Verhindert, dass jeder kurze Tab-Wechsel einen API-Call feuert.
  static const _staleAfter = Duration(minutes: 30);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _maybeRefresh();
    }
  }

  /// Pull-Refresh, wenn der letzte Sync länger als [_staleAfter] her ist.
  /// Erster Start (Cache leer) wird ausgelassen — den übernimmt der
  /// [contentBootstrapProvider] sowieso.
  Future<void> _maybeRefresh() async {
    final cache = ref.read(contentCacheProvider);
    final last = cache.lastSyncedAt;
    if (last == null) return;
    if (DateTime.now().difference(last) < _staleAfter) return;
    try {
      await refreshRemoteContent(ref);
    } catch (e) {
      dev.log(
        'background refresh on resume failed: $e',
        name: 'GriphosApp',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Einmaliger Inhalts-Bootstrap (Cache hydraten + Remote-Pull). Result
    // ist void — wir interessieren uns nur für den Side-Effect (Pool-State
    // wird aktualisiert). Fehler werden im Provider geschluckt.
    ref.watch(contentBootstrapProvider);

    final router = ref.watch(routerProvider);
    final mode = ref.watch(themeModeProvider);
    final storedLocale =
        ref.watch(profileNotifierProvider).value?.locale ?? 'de';
    final locale = storedLocale == 'de' ? storedLocale : 'de';

    return MaterialApp.router(
      title: 'Griphos',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: mode,
      routerConfig: router,
      locale: Locale(locale),
      supportedLocales: const [Locale('de'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
    );
  }
}

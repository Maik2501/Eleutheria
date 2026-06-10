# Code-Review Griphos — Pre-Launch-Audit (2026-06-10)

**Stand:** Commit `8aa21af` (Rebrand Eleutheria → Griphos), pubspec `0.1.0+7`.
**Methodik:** Multi-Agent-Audit über 8 Dimensionen (Secrets/Config, Supabase-RLS, Anti-Cheat,
Auth-Lifecycle, Flutter-Qualität in 4 Bereichen, App-Store-Compliance, Tooling, Robustheit).
Backend-Funde wurden adversarial gegenverifiziert, die Top-Flutter-Funde zusätzlich manuell
im Code bzw. empirisch (Dart-Probes) bestätigt. Zeilenangaben beziehen sich auf den o. g. Stand.

**Severity:** 🔴 High (vor Release fixen) · 🟡 Medium (zeitnah) · ⚪ Low (Gelegenheit) · ℹ️ Info

---

## 1. App-Store-Einreichung (Apple-Review-Risiken)

- [ ] 🔴 **A1 — Offline-Aussperrung wiederkehrender Nutzer.**
  `lib/features/onboarding/profile_gate.dart:45-53` blockiert die App hinter einem Retry-Screen,
  wenn der Profil-Fetch fehlschlägt; `fetchMine()` (`supabase_profile_repository.dart:16-26`)
  fängt Netzwerkfehler nicht. Neue Nutzer ohne Session kommen offline durch, **wiederkehrende
  Nutzer mit persistierter Session sind bei Funkloch/Server-Ausfall komplett ausgesperrt** —
  auch von allen Offline-Modi. Der einzelne Self-Hosted-Server ist damit Single Point of Failure
  fürs Öffnen der App; trifft das den Apple-Reviewer, droht Rejection (Guideline 2.1).
  **Fix:** Im Error-Fall "Offline weiterspielen"-Button zum HomeScreen anbieten, oder ein lokales
  "Setup abgeschlossen"-Flag cachen und den Retry-Screen nur beim allerersten Start zeigen.

- [ ] 🔴 **A2 — Keine Account-Löschung (Apple 5.1.1(v), DSGVO).**
  Die App legt serverseitig Profil, Scores und Feedback an, bietet aber weder Sign-out noch
  Löschung (Settings durchsucht: nichts). Apple verlangt bei Apps mit Account-Erstellung eine
  In-App-Löschfunktion — auch bei anonymen Accounts mit Profildaten ein realistischer
  Rejection-Grund. **Fix:** Settings-Eintrag + SECURITY-DEFINER-RPC, die die `auth.users`-Row
  des Callers löscht (profiles/scores cascaden), danach lokal aussignieren.

- [x] 🟡 **A3 — PayPal-Spendenlink (Apple 3.1.1 / 3.2.1-Grauzone).** *(erledigt: Leerstring für v1; nach Approval als IAP-Tip neu bewerten)*
  `lib/env.dart:21` + Settings-Karte. Persönliche Spendenlinks an den Entwickler sind ein
  bekannter Rejection-Trigger. Der Ausweg ist schon gebaut: Leerstring blendet die Karte aus.
  **Empfehlung:** Für die Erst-Einreichung `donatePayPalUrl = ''`, nach Approval per Update erneut probieren.

- [ ] 🟡 **A4 — iOS-Privacy-Pflichten.**
  Kein `ios/Runner/PrivacyInfo.xcprivacy` (App-Level-Manifest empfohlen; die Plugin-Manifeste
  decken nur die Plugin-eigenen Required-Reason-APIs ab). Kein `ITSAppUsesNonExemptEncryption`
  in der Info.plist (sonst Export-Compliance-Frage bei jedem Upload). Privacy-Label in App Store
  Connect muss deklarieren: anonyme User-ID, Display-Name, Scores, Feedback-Texte, optionale
  Kontakt-E-Mail. Datenschutzerklärungs-URL wird ohnehin benötigt.

- [x] 🟡 **A5 — Versions-Drift `Env.appVersion`.** *(erledigt: package_info_plus zur Laufzeit, Konstante entfernt)*
  `lib/env.dart:16` meldet `0.1.0+5`, pubspec ist bei `0.1.0+7` — alle Feedback-Submissions
  taggen den falschen Build; der manuelle Sync ist bereits zweimal gerissen.
  **Fix:** `package_info_plus` zur Laufzeit oder Version als `--dart-define` durchreichen.

- [ ] ⚪ **A6 — Orientierungs-Inkonsistenz.**
  `main.dart` erzwingt Portrait, `ios/Runner/Info.plist` deklariert zusätzlich Landscape
  (inkl. iPad-Sektion). Auf iPad prüft Apple das deklarierte Verhalten gern. Deklaration angleichen.

---

## 2. Backend & Spiel-Integrität (Supabase)

- [ ] 🔴 **B1 — Leaderboard ist vollständig fälschbar.** *(adversarial verifiziert)*
  `lib/data/repositories/score_repository.dart:61-79` sendet rein clientberechnete Werte;
  serverseitig existieren nur `>= 0`-Checks und Enum-Membership (`0002_app_tables.sql:78-83`)
  plus die Identitäts-Policy aus 0006. Keine Plausibilitätsprüfung, keine Relation
  `score`/`correct`/`answered`, kein Rate-Limit. Mit Anon-Key + anonymer Session kann jeder
  per `curl` `score = 2147483647` posten — landet wegen `is_pure = (joker_setting='off')`
  (Migration 0009) auch auf dem Pure-Board.
  **Fix (minimal):** Migration mit CHECKs `correct <= answered`, `score <= raw_score`,
  `raw_score <= answered * MAX_PUNKTE`, modusabhängige Caps + Insert-Rate-Limit.
  **Fix (sauber):** SECURITY-DEFINER-RPC, die den Score serverseitig nachrechnet.

- [ ] 🔴 **B2 — Duell-Spieler können unterschiedliche Fragen sehen.**
  Beide Clients lösen die Fragen lokal aus `question_seed` auf
  (`duel_match_screen.dart:127-135` → `question_repository.dart:randomBatch`). Deterministisch
  ist das nur bei identischem Pool in identischer Reihenfolge — seit der Content-Pipeline gilt
  beides nicht: `RemoteContentRepository.fetchQuestions()` hat kein `ORDER BY` (Zeilenreihenfolge
  instabil) und Geräte können verschiedene Content-Stände gecacht haben. Punkte werden aber pro
  `question_index` verglichen. Bricht ebenso das "alle spielen dieselben Daily-Fragen"-Versprechen
  von `dailyBatch`.
  **Fix:** (a) sofort `.order('id')` im Fetch + Kandidaten vor seeded Sampling nach `q.id`
  sortieren; (b) sauber: Host schreibt die aufgelösten Frage-IDs beim Erstellen in die Duel-Row.

- [ ] 🟡 **B3 — `duels` und `duel_answers` sind weltlesbar.**
  `for select using (true)` (`0002_app_tables.sql:142-161`): Jeder kann alle Duelle samt Codes
  enumerieren und die Antworten des Gegners (`selected_index`, `was_correct`) live mitlesen,
  bevor er selbst antwortet. **Fix:** SELECT auf Teilnehmer einschränken
  (`host_id = auth.uid() or guest_id = auth.uid() or (status = 'waiting' and guest_id is null)`).

- [ ] 🟡 **B4 — `submit_duel_answer` vertraut dem Client.**
  `0006_duel_and_score_hardening.sql:134-220`: `p_was_correct` und `p_points` sind self-reported
  (nur `>= 0` geclampt, keine Obergrenze). Bei Friend-Duellen verkraftbar (Ergebnisse landen in
  keinem Leaderboard), aber **vor Elo/Auto-Pairing muss die Antwort serverseitig validiert werden**.

- [ ] 🟡 **B5 — `feedback` ohne Rate-Limit.** *(adversarial verifiziert)*
  Anonyme Sessions sind gratis mintbar; unbegrenzte 4-KB-Inserts gegen den Self-Hosted-Postgres
  (`0008_feedback.sql:49-55`). **Fix:** Insert-RPC oder Trigger mit N Zeilen pro UID/Stunde.

- [x] 🔴 **B6 — Android-Release-Builds haben kein Internet.** *(erledigt: INTERNET-Permission im Main-Manifest)*
  Die `INTERNET`-Permission steht nur in den debug-/profile-Manifesten;
  `android/app/src/main/AndroidManifest.xml` hat keine. Jeder Release-Build läuft komplett
  offline (Supabase, Duelle, Leaderboard, Content-Sync tot). Für iOS irrelevant, für jeden
  Android-Release ein Blocker. **Fix:** `<uses-permission android:name="android.permission.INTERNET"/>`.

- [ ] ⚪ **B7 — Legacy-Tabelle `daily_scores` droppen.** *(verifiziert)*
  Weltlesbar, mit freiem `display_name` beschreibbar (`0002:165-172`), von keinem Code-Pfad
  genutzt — latente Missbrauchsfläche.

- [ ] ⚪ **B8 — `.gitignore` um Credential-Patterns ergänzen.** *(verifiziert)*
  `.env.*`-Varianten, `*.pem/.p8/.p12/.mobileprovision`, Root-Level-Keystores,
  `google-services.json`/`GoogleService-Info.plist` würden aktuell committet (Exposure heute: null,
  rein präventiv — gerade `.p8`-ASC-Keys im App-Store-Workflow relevant).

- [ ] ⚪ **B9 — Android-Release-Signing ist Template-TODO.** *(verifiziert)*
  `android/app/build.gradle.kts` signiert Release mit Debug-Keys. Vor Play-Store-Release
  Upload-Keystore + `key.properties`-Flow einrichten. Für iOS kein Handlungsbedarf.

- [ ] ℹ️ **B10 — Duell-Integrität hängt an genau einem Trigger.** *(verifiziert)*
  `duels_update_allowed` (0006:35-45) prüft nur Teilnehmerschaft; alle Immutabilität/Transitionen
  erzwingt allein der BEFORE-UPDATE-Trigger. Für Launch okay; optional Test/Kommentar, der die
  Trigger-Existenz absichert, und `set search_path = public` auch in `set_updated_at()` (0002:41-47).

- [ ] ⚪ **B11 — `reserve()` Check-then-Insert-Race** (`supabase_profile_repository.dart:40-52`):
  schlimmstenfalls falsche "Name vergeben"-Meldung bei Selbst-Kollision. Upsert verwenden.

- [ ] ⚪ **B12 — Kein Profanity-/Reserved-Word-Filter** für Display-Names auf einem öffentlichen
  Leaderboard (Zeichen-Whitelist und Unicode-Härtung sind dagegen solide).

---

## 3. Flutter — High-Funde

- [ ] 🔴 **F1 — Duelle vergeben nie XP, zwei Achievements unerreichbar.** *(manuell verifiziert)*
  `applySessionResult` wird im Duell-Code nie aufgerufen (einziger Aufrufer:
  `quiz_screen.dart:380`, läuft nie mit `vsOnline`). `duelsWon`/`bestDuelStreak` bleiben 0 →
  Achievements `first_duel_won` ("Erster Sieg") und `duel_streak` ("Eristik") sind unerreichbar;
  Duelle zählen nicht für XP/`totalGamesPlayed`/Tages-Streak.
  **Fix:** Im Duell-Summary einmalig (Once-Flag) `GameSession(mode: vsOnline)` bauen und
  `applySessionResult(wonDuel: iWin)` aufrufen.

- [x] 🔴 **F2 — Rematch-Kette bricht ab der zweiten Revanche.** *(erledigt: ValueKey(code) im Route-Builder)*
  `router.dart:108-112` gibt `DuelMatchScreen` keinen Key; bei `context.go('/duel/NEU')` aus
  einem Match heraus behält go_router den Page-Key des Pfad-Patterns → State wird wiederverwendet,
  `initState` läuft nicht, kein `didUpdateWidget` vorhanden — Subscriptions/Presence hängen am
  alten Duell-Code. Beide Spieler bleiben auf dem alten Summary; das neue Duell wird serverseitig
  auf `playing` geflippt, läuft aber mit niemandem und hängt für immer.
  **Fix (eine Zeile):** `DuelMatchScreen(key: ValueKey(code), code: code)` im Route-Builder.

- [ ] 🔴 **F3 — Ausgeschiedene Duell-Spieler können weiter antworten und punkten.**
  Letterbox-Submit `duel_match_screen.dart:728-737` prüft nur `_alreadyAnsweredCurrent` —
  nicht Leben/Lock (das tut nur der FAB); die Server-RPC validiert Leben nie. Ein Spieler ohne
  Leben spielt per Return-Taste weiter und nimmt im Race-Modus dem Überlebenden Runden weg.
  Zusätzlich submittet Return mit leerem Feld eine falsche Antwort (= verbranntes Leben).
  **Fix:** In `_submit` die FAB-Bedingungen spiegeln: `!alive || locked || _typed.trim().isEmpty → return`.

- [x] 🔴 **F4 — Quiz: `submit()` und `next()` ohne `revealed`-Guard.** *(erledigt: Early-Returns in beiden Methoden)*
  `game_session_controller.dart:322` / `:367`. Doppel-Tap/Timeout-Race erzeugt doppelte
  AnswerRecords (doppelte Punkte; in Endless zwei Herzen für eine falsche Antwort; aufgeblähte
  Leaderboard-Werte). Doppel-Tap auf "Weiter" überspringt still eine Frage ("9 von 10",
  Flawless unerreichbar). **Fix:** je ein Early-Return als erste Zeile beider Methoden
  (`if (state.revealed) …` bzw. `if (!state.revealed) return;`).

- [ ] 🔴 **F5 — Defekte Crossword-Remote-Row → gecachter Crash-Loop.** *(empirisch bestätigt)*
  `crossword_puzzle.dart:124,130-154`: `tryFromJson` validiert keine Grid-Grenzen; das Grid wird
  lazy gebaut (`late final`), der RangeError entkommt dem try/catch und fliegt erst beim Öffnen
  des Modus. Der Cache wird **vor** dem ersten Grid-Bau geschrieben (`providers.dart:104-107`)
  → App crasht danach bei jedem Öffnen des Kreuzworträtsels, bis die Row remote gefixt ist.
  Auch akzeptiert: negative Koordinaten, leere Antworten, `grid_rows <= 0`, Konflikt-Letter
  (Assert-Crash im Debug, stilles Falsch-Verhalten im Release).
  **Fix:** Validierung in `tryFromJson` (Bounds, leere Antworten, Konflikte) + dort einmal
  `puzzle.grid;` forcieren, damit Restfehler gefangen werden und die Row verworfen wird.

- [ ] 🔴 **F6 — Crossword-Fortschritt wird bei Content-Refresh gewischt.**
  `crosswordProvider` ist auf die Puzzle-**Instanz** gekeyt (kein `==`/`hashCode`); der
  30-Minuten-Refresh bei App-Resume (`griphos_app.dart:37-41`) und der Bootstrap-Pull ersetzen
  den Pool mit neuen Instanzen → neuer Controller, leeres Grid — selbst bei identischem Content.
  **Fix:** Family auf `puzzle.id` keyen oder die gewählte Instanz im Screen-State halten.

---

## 4. Flutter — Medium

- [x] 🟡 **F7 — Korruptes Profil-JSON brickt die App permanent.** *(erledigt: try/catch + Quarantäne-Key + Fallback auf fresh)*
  `profile_repository.dart:40-41` parst ohne try/catch → `ProfileNotifier.build` wirft →
  `AsyncError` für immer: leere Settings-/Profil-Screens, alle Mutationen (inkl. XP nach jedem
  Spiel) werden still verworfen, nichts überschreibt den kaputten Blob je. Seltener Trigger
  (abgebrochener Write), katastrophale Wirkung. **Fix:** try/catch mit Fallback auf
  `PlayerProfile.fresh` (defekten Blob optional unter Quarantäne-Key sichern).

- [ ] 🟡 **F8 — Remote-Frage mit >4 Optionen crasht das Quiz — und wird gecacht.**
  `question.dart:97` prüft nur Untergrenze, DB-Check (`0010:43`) ebenso; die UI indexiert
  `['A','B','C','D']` hart (`quiz_screen.dart:50,262-267`). Eine 5-Optionen-Row aus
  Studio/CMS crasht jeden Client beim Sampling, auch offline aus dem Cache.
  **Fix:** `options.length > 4` in `tryFromJson` ablehnen (+ optional DB-Obergrenze).

- [ ] 🟡 **F9 — iOS-Suspension zählt als Spielzeit (Quiz).**
  `quiz_screen.dart:80-96` rechnet mit Wall-Clock, kein `WidgetsBindingObserver`: Nach einem
  Anruf ist die Sudden-Death-/Daily-Frage sofort als falsch gewertet bzw. die
  Quiz-Rush-Session tot. **Fix:** `AppLifecycleState` beobachten, Hintergrund-Dauer wie die
  Reveal-Pause auf `_pausedTotal` buchen.

- [ ] 🟡 **F10 — Duell: Backgrounding → Disconnect-Timeout, beide sehen "Gewonnen".**
  supabase_flutter trennt den Realtime-Socket beim Pausieren; nach >30 s Hintergrund erklärt
  der Gegner per Presence-Timeout lokal den Sieg (`duel_match_screen.dart:774-781`), der
  Zurückkehrende rendert den Score-basierten Sieger — der Ausgang wird nie persistiert, beide
  Seiten können sich als Gewinner sehen. **Fix:** `winner_id`/`finish_reason` serverseitig
  schreiben (Trigger-validiert) und beide Summaries daraus rendern.

- [ ] 🟡 **F11 — Duell: Realtime-Streams ohne `onError`/`onDone`.**
  `duel_match_screen.dart:120,144`: Schlägt der automatische Re-Fetch nach einem Reconnect fehl,
  schließt der Stream permanent — das Match friert still ein ("warte auf Mitspielerin" für
  immer). Ungültiger/abgelaufener Duell-Code → unhandled Error + Endlos-Spinner ohne Exit
  (`watchDuel` wirft in den Stream). **Fix:** onError/onDone mit Resubscribe-Backoff bzw.
  Fehler-Scaffold mit Exit-Button.

- [ ] 🟡 **F12 — Beidseitiges "Revanche"-Tippen strandet beide Spieler.**
  `duel_repository.dart:141-148`: Attach ohne `.select()`-Erfolgskontrolle — der Verlierer des
  Races merkt nichts, beide erzeugen eigene Lobbys und warten allein. **Fix:**
  `.select().maybeSingle()`; bei `null` eigenes Duell canceln und dem `rematch_code` des
  Originals beitreten.

- [ ] 🟡 **F13 — Letterbox: Joker nach begonnenem Tippen verschiebt Buchstaben.** *(empirisch bestätigt)*
  `letterbox_input.dart:71-78`: Reveal einer bereits getippten Position entfernt das getippte
  Zeichen nicht — alles dahinter rutscht eine Box nach rechts (`KANT` → `KAAN`).
  **Fix:** In `didUpdateWidget` die getippten Zeichen an neu revealten Positionen löschen statt
  nur am Ende zu truncaten.

- [ ] 🟡 **F14 — Letterbox: Return-Taste submittet leere Eingabe als falsche Antwort.**
  `letterbox_input.dart:137` + `quiz_screen.dart:141-147` + Duell-Pfad: Der "Lösen"-Button ist
  bei leerer Eingabe disabled, Soft-Keyboard-Return umgeht das — Tastatur-Wegtippen kostet die
  Frage (im Duell die Runde/das Leben). **Fix:** `if (_typed.trim().isEmpty) return;` in den
  onSubmitted-Handlern.

- [ ] 🟡 **F15 — Letterbox: Bindestrich ist tippbar und korrumpiert das Mapping.**
  `letterbox_input.dart:129-132` erlaubt `-` im Formatter, obwohl Target-Bindestriche als fixe
  Zellen gerendert werden: Wer "A-PRIORI" natürlich tippt, scort falsch.
  **Fix:** `\-` aus der Allow-Regex entfernen.

- [ ] 🟡 **F16 — System-Back/iOS-Swipe umgeht den "Quiz beenden?"-Dialog; Score kann verloren gehen.**
  Kein `PopScope` im Projekt; der Dialog hängt nur am In-App-Pfeil (`quiz_screen.dart:342-369`).
  Zusätzlich: Score-Submit lebt erst in `ResultScreen.initState` — wer während des
  Achievement-Overlays zurückgeht, behält XP, verliert aber den Leaderboard-Eintrag
  (`quiz_screen.dart:390-393`). **Fix:** `PopScope` um das Quiz-Scaffold; Submit nach
  `_finishSession` vorziehen (vor das Overlay).

- [ ] 🟡 **F17 — Bookmarks zu Remote-Fragen verschwinden aus der Liste.**
  `bookmarks_screen.dart:26` löst IDs gegen das gebundelte `kQuestions` auf statt gegen den
  Live-Pool — Bookmarks auf Pipeline-Fragen werden still gedroppt (Zähler im Profil stimmt,
  Liste nicht). **Fix:** `byId` aus `ref.watch(questionPoolProvider)` bauen.

- [ ] 🟡 **F18 — Feedback: ungültige E-Mail scheitert erst am Server-CHECK.**
  Client validiert nicht (`feedback_sheet.dart:161`), Server-Constraint lehnt ab, Repository
  meldet generisch "versuche es gleich noch einmal" — Retry kann nie klappen, Feedback geht
  verloren. **Fix:** Server-Regex client-seitig spiegeln, Inline-Fehler.

- [ ] 🟡 **F19 — Leaderboard: Re-Query bei jedem Rebuild + doppelte Requests pro Tab-Wechsel.**
  `leaderboard_screen.dart:205-210` erzeugt den Future im `build()`; Tab-Listener feuert
  doppelt; rein kosmetische Toggles refetchen — Spinner-Flackern und unnötige Last auf dem
  Self-Hosted-Server. **Fix:** Future in Feld halten, nur bei echten Filter-Änderungen neu erzeugen.

- [ ] 🟡 **F20 — Crossword: Puzzle-Wechsel im Dropdown verwirft Fortschritt.**
  autoDispose-Family: Wechsel zu Puzzle B disposed Controller A; zurückwechseln → leeres Grid.
  **Fix:** `ref.keepAlive()` für die Session bzw. explizite Invalidierung beim Verlassen.

- [ ] 🟡 **F21 — Duell: gesamtes Shared-Timing vertraut der lokalen Uhr.**
  `duel_match_screen.dart:270-272` u. a. vergleichen Server-Timestamps mit lokalem `now()`:
  Clock-Skew beendet Sessions einseitig zu früh (Gegners letzte Antwort wird mit "duel is not
  active" abgelehnt), dehnt/überspringt Runden-Pausen. **Fix:** einmaligen Server-Offset
  bestimmen und auf alle Vergleiche anwenden.

- [ ] 🟡 **F22 — Duell: Presence-Logik angreifbar/fehlanfällig.**
  Kein Cross-Check gegen den Antwort-Stream (Timeout-Sieg, während Antworten sichtbar
  eintreffen); schlägt `_setupPresence` initial fehl, wird der Gegner immer nach 30 s
  ausgetimet; der Presence-Channel ist öffentlich und vertraut dem client-gelieferten
  `user_id`-Payload (mit bekanntem Code kann ein Dritter Timeout-Siege blockieren).
  **Fix:** jüngste Gegner-Antwort als Anwesenheit werten; Presence-Setup retryen; Countdown erst
  armen, wenn der Gegner einmal präsent war.

- [ ] 🟡 **F23 — Duell: `finish()` fire-and-forget, kein Server-Timeout für hängende Duelle.**
  `_finalized` wird vor dem Erfolg gesetzt, Fehlschlag wird nie retried; es gibt keinen
  `playing → cancelled/expired`-Pfad — hängende Rows akzeptieren `submit_duel_answer` unbegrenzt
  und sind nie rematch-fähig. **Fix:** finish awaiten + bei Fehler zurücksetzen; Server-Cron,
  der alte `playing`-Duelle cancelt.

- [ ] 🟡 **F24 — Duell Parallel-Modus: der Schnellere beendet das Duell für beide.**
  `duel_match_screen.dart:517-525`: eigener Antwort-Count am Pool-Ende triggert `finish()` —
  der Langsamere wird mit Restzeit mitten in der Frage abgeschnitten (In-Flight-Submit wirft).
  **Fix:** am Ende lokal locken ("Fertig — warte…") und erst beenden, wenn beide fertig/Zeit um.

---

## 5. Flutter — Low (kompakt)

- [ ] ⚪ Letterbox: stale `_typed` nach "Weiter" — Reihenfolge `notifier.next(); _typed=''` vs.
  `reset()` lässt bei revealtem Index 0 den alten Prefix stehen ("Lösen" enabled bei leeren
  Boxen). Fix: erst `reset()`, dann `_typed = ''` (`quiz_screen.dart:327-329`).
- [ ] ⚪ Leerer Fragen-Batch → sofortiges "Ergebnis" mit +50-Flawless-XP, Confetti, gezähltem
  Spiel + Streak-Tag (`game_session_controller.dart:420-425`, `quiz_screen.dart:161-166`).
  Fix: `questions.isEmpty` als Fehlerzustand behandeln, `total > 0`-Guard beim Bonus.
- [ ] ⚪ `_finishSession` Post-Frame-Callback ohne `mounted`-Check → ref-after-dispose möglich
  (`quiz_screen.dart:371-373`).
- [ ] ⚪ 50/50 lässt eine bereits gewählte, dann eliminierte Option submittbar
  (`game_session_controller.dart:294-297`): `selectedIndex` beim Eliminieren zurücksetzen.
- [ ] ⚪ Falsche Letterbox-Antworten werden in der Frage-History nie als falsch markiert
  (`-1`-Overload, `game_session_controller.dart:316,349-356`) — Sampler-Bias, kein Score-Effekt.
- [ ] ⚪ `GameConfig` ohne `==`/`hashCode` als autoDispose-Family-Key — Falle bei Reaktivierung
  der Kategorien-Route (Session-Reset mid-game bei Router-Rebuild), aktuell nicht erreichbar.
- [ ] ⚪ Untimed-Modi rendern permanent das Timer-Overlay mit Flacker pro Reveal
  (`quiz_screen.dart:73-75` → `quiz_progress_bar.dart:46-61`): `null` statt `0` durchreichen.
- [ ] ⚪ Duell: `submitAnswer` ohne try/catch — Antworten verschwinden bei Netzfehler still
  (`duel_match_screen.dart:752-760`).
- [ ] ⚪ Duell-Lobby: Cancel-Race — Host landet im Menü, obwohl der Gast gerade gejoint ist
  (`duel_match_screen.dart:192-199`); `setState` nach `await` ohne mounted in catch-Blöcken
  (`duel_lobby_screen.dart:87-88,113-115`); QR-Scanner ohne `errorBuilder` bei Kamera-Verweigerung.
- [ ] ⚪ Crossword/Letterbox: mehrere gleichzeitig "aktive" Cursor-Zellen bei Mehrwort-Antworten;
  `requestFocus` im Post-Frame ohne mounted; `maxLength: 0`-Assert bei Antworten ohne tippbare
  Zeichen (Letter/Digit-Pflicht in `isLetterboxFriendly` ergänzen).
- [ ] ⚪ DST-Frühjahrstag unterschlägt einen Streak-Increment (`providers.dart:371-373`,
  23h-Differenz → `inDays == 0`): auf gerundete Stunden/24 umstellen.
- [ ] ⚪ Leaderboard "Heute" beginnt um UTC-Mitternacht statt lokal (`leaderboard_screen.dart:340-341`).
- [ ] ⚪ "Casual"-Board enthält Pure-Läufe — Implementierung (kein Filter) widerspricht der
  dokumentierten Partition (`score_repository.dart:152`): entscheiden und angleichen.
- [ ] ⚪ "Erneut spielen" landet im Menü und dupliziert Home im Stack
  (`result_screen.dart:146-150`): `context.go('/')` oder echtes Replay.
- [ ] ⚪ PayPal-`launchUrl` ohne try/catch → unhandled `PlatformException`
  (`settings_screen.dart:278`).
- [ ] ⚪ `_editName` disposed den TextEditingController während der Dialog-Exit-Animation
  (`profile_screen.dart:115,139`) — flaky "used after being disposed".
- [ ] ⚪ `ProfileSetupScreen._submit` ohne Re-Entry-Guard: Doppel-Submit endet als irreführendes
  "Name schon vergeben" (`profile_setup_screen.dart:48`).

---

## 6. Positiv geprüft (kein Handlungsbedarf)

- **Secrets-Hygiene:** `.env` nie committet (alle 26 Commits geprüft); einziger JWT im Repo ist
  der öffentliche Supabase-Demo-Key in `scripts/run.ps1` (localhost, kryptographisch verifiziert
  ≠ Produktions-Secret); Service-Role-Key nur aus Env-Vars, wird nie geloggt; CMS/Builder ohne
  Credentials; `cms/serve.py` bindet nur `127.0.0.1` mit Routen-Whitelist, kein Path-Traversal;
  SUPABASE_SETUP.md dokumentiert saubere Server-Praxis.
- **RLS-Basis:** RLS auf allen 9 Tabellen; `*_write_all`-Policies aus 0001 entfernt; SECURITY-
  DEFINER-Funktionen pinnen `search_path` und validieren den Caller; Content-Tabellen und
  `duel_ratings` client-seitig read-only; Feedback nicht zurücklesbar; Profil-Constraints
  (citext-unique, Länge, Zeichen-Whitelist) in SQL und Client gespiegelt.
- **Duell-Server-Protokoll:** Join/Cancel/Finish/Rematch-Transitionen Trigger-validiert,
  Doppel-Join sauber serialisiert, Race-Wertung per Row-Lock, `on conflict do nothing` macht
  Antwort-Submits idempotent, simultanes Finish konvergiert.
- **Quiz-Kern:** Finish-Pfade single-shot, Reveal-Pausen-Arithmetik konsistent, Joker-Abrechnung
  deckungsgleich mit `_computeBreakdown` (Joker zählt Fragen, nicht Klicks), Achievement-Engine
  idempotent, Result-Screen div/0-sicher, Score-Insert idempotent über `(player_id, session_id)`.
- **Content-Pipeline:** Cache→Remote→Bundle-Fallback robust; einzelne defekte Frage-Rows werden
  gefiltert (Ausnahme F5/F8); korrupter Cache → Bundle.
- **Crossword/Letterbox-Korrektheit:** ß/Umlaut-Vergleich durchgängig konsistent (empirisch
  geprüft, `'ß'.toUpperCase()` bleibt `ß`), Hyphenation-Edge-Cases sauber, Win-Condition prüft
  Inhalte (nicht Längen), Eingabe-Races und Disposal sauber.
- **Profil-Persistenz:** Serialisierung vollständig round-trip-sicher, Migrations-Pfad seit
  v1 geprüft (`git show 46c8fdb`), History-Repository auf 500 Einträge gedeckelt; Riverpod-
  2.6.1-Notify-Verhalten für In-Place-Mutationen verifiziert (Vorsicht bei künftigem
  `.select()` auf dem Profil-Provider oder Riverpod-Downgrade).

---

## Empfohlene Reihenfolge

1. **Vor der Einreichung:** A1, A2, A4, A5 (A3 per Leerstring entschärfen) — plus F4 und F7
   (kleine Diffs, hohes Nutzer-Risiko).
2. **Direkt danach:** B1, B2 (je eine Migration / kleiner Diff), F1–F3, F5, F6, F8.
3. **Vor dem Android-/Play-Store-Release:** B6, B9.
4. **Vor Elo/Auto-Pairing:** B4 zwingend.
5. Rest nach Gelegenheit (Abschnitt 4/5).

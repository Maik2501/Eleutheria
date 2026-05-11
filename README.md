# Eleutheria

Eine warme, akademische iOS-App für ein Quiz rund um Philosophie. Built with Flutter.

> *„Die Liebe zur Weisheit beginnt mit dem Staunen."* — frei nach Aristoteles

---

## Features

### Spielmodi
- **Klassisch** — 10 gemischte Fragen, voller Score
- **Sudden Death** — bis zum ersten Fehler, Bestleistungen werden festgehalten
- **Tägliche Frage** — fünf Fragen, dieselben für alle Spielerinnen weltweit am gleichen Tag, mit Tagesrangliste *(coming soon)*
- **Duell (online, live)** — sechsstelliger Code, beide spielen dieselben Fragen, schnellere richtige Antwort gewinnt *(coming soon)*
- **Studierkammer** — Übungsmodus ohne Zeitdruck, mit allen Erläuterungen
- **Sammlung** — eine bestimmte Kategorie üben

### Fragetypen
1. Zitat → Philosoph
2. Werk → Autor
3. Philosoph → Epoche
4. Begriff → Schule
5. Zitat vervollständigen
6. Wer kritisierte wen?

### Modern features
- **Streaks** mit Tageszählung und stoischen Errungenschaften (3, 7, 30 Tage)
- **XP & Stufen** mit philosophischen Rangtiteln (Lehrling → Weiser)
- **Errungenschaften** als Wachssiegel-Badges (Sokrates' Schüler, Nachtwanderer, Tabula perfecta, Phönix, …)
- **Power-Ups** — 50/50 (zwei falsche Antworten entfernen)
- **Bookmarks** für Lieblingszitate
- **Haptisches Feedback** auf iOS
- **Hell- / Dunkel-Modus** (warmer „Salon" am Abend, Pergament am Tag)
- **Lokalisierung** Deutsch; Englisch ist vorbereitet, aber für den ersten Test ausgegraut
- **Erläuterungen** nach jeder Antwort — die App ist auch zum Lernen gemacht
- **Animierter Konfetti-Regen** bei Tabula perfecta

### Visuelle Identität — *Warm Academia*
- Pergament-Hintergrund mit feiner Körnung
- Burgunder-Akzente, Antik-Gold
- **Fraunces** (Display, italic für Zitate) + **Inter** (Body)
- Wachssiegel-Motiv für Avatare und Errungenschaften
- Sanfte Spring-Animationen, iOS-typische Übergänge

---

## Voraussetzungen

| Tool | Version | Quelle |
|---|---|---|
| Flutter SDK | 3.22+ | <https://docs.flutter.dev/get-started/install/windows> |
| Dart | 3.4+ | (kommt mit Flutter) |
| Apple Developer Account | aktiv | <https://developer.apple.com/programs/> ($99/Jahr) |
| Codemagic Account | kostenlos | <https://codemagic.io> (für iOS-Build aus der Cloud) |
| Supabase Projekt | kostenlos | <https://supabase.com> (für Online-Duelle und Tagesrangliste) |

> Du arbeitest auf Windows — du brauchst **keinen Mac**. iOS-Builds laufen über Codemagic in der Cloud.

---

## Erst-Setup (einmalig)

### 1. Flutter installieren
```powershell
# Windows: Flutter SDK herunterladen und entpacken nach z.B. C:\src\flutter
# Dann zu PATH hinzufügen:
[Environment]::SetEnvironmentVariable("Path", "$env:Path;C:\src\flutter\bin", "User")
flutter doctor
```

### 2. Plattform-Ordner generieren
Im Projektverzeichnis:
```powershell
flutter create . --project-name philosophie_quiz --org de.deinname.eleutheria --platforms=ios,android
flutter pub get
```
> `flutter create .` legt nur die fehlenden `ios/`, `android/` und `web/` Ordner an, ohne `lib/` zu überschreiben.

### 3. Schriften herunterladen
Die App nutzt **Fraunces** (Google Fonts) und **Inter**. Lege diese Dateien in `assets/fonts/`:
- `Fraunces-Regular.ttf`, `-Medium.ttf`, `-SemiBold.ttf`, `-Bold.ttf`, `-Italic.ttf`
- `Inter-Regular.ttf`, `-Medium.ttf`, `-SemiBold.ttf`, `-Bold.ttf`

Beide sind kostenlos auf Google Fonts:
- <https://fonts.google.com/specimen/Fraunces>
- <https://fonts.google.com/specimen/Inter>

> Alternativ: Wenn du nur die `google_fonts`-Pakete nutzen willst, lassen sich die `fonts:`-Einträge in `pubspec.yaml` entfernen — die App lädt sie dann beim ersten Start aus dem Netz.

### 4. Supabase einrichten (für Duelle & Rangliste)
1. Auf supabase.com ein Projekt anlegen.
2. SQL-Editor öffnen und das Schema ausführen:

```sql
create table duels (
  code text primary key,
  host_id uuid not null,
  guest_id uuid,
  question_seed bigint not null,
  question_count int not null default 5,
  status text not null default 'waiting',
  created_at timestamptz default now()
);

create table duel_answers (
  duel_code text references duels(code) on delete cascade,
  player_id uuid not null,
  question_index int not null,
  selected_index int not null,
  was_correct boolean not null,
  time_taken_ms int not null,
  points int not null,
  submitted_at timestamptz default now(),
  primary key (duel_code, player_id, question_index)
);

create table daily_scores (
  day date not null,
  player_id uuid not null,
  display_name text not null,
  score int not null,
  correct int not null,
  submitted_at timestamptz default now(),
  primary key (day, player_id)
);

-- Realtime einschalten
alter publication supabase_realtime add table duels;
alter publication supabase_realtime add table duel_answers;

-- Row-Level-Security (für Produktion: anpassen!)
alter table duels enable row level security;
create policy "anyone can read duels" on duels for select using (true);
create policy "anyone can write duels" on duels for all using (true);
alter table duel_answers enable row level security;
create policy "anyone can read duel_answers" on duel_answers for select using (true);
create policy "anyone can write duel_answers" on duel_answers for all using (true);
alter table daily_scores enable row level security;
create policy "anyone can read scores" on daily_scores for select using (true);
create policy "anyone can write scores" on daily_scores for all using (true);
```

3. URL und Anon-Key kopieren (Settings → API).

### 5. Bilder hinzufügen
Siehe `IMAGE_PROMPTS.md` für die Liste aller Bilder, die du generieren musst (Philosophen-Porträts und App-Icon).

---

## Lokal starten

Solange noch keine echten Geräte angeschlossen sind, lässt sich die App im iOS-Simulator nicht von Windows aus starten. Aber: **du kannst sie als Android-App auf einem Android-Emulator (Windows) testen** — Layout und Logik sind identisch.

```powershell
# Android-Emulator starten (Android Studio nötig)
flutter emulators --launch <emulator-id>

# App starten mit Supabase-Konfiguration
flutter run `
  --dart-define=SUPABASE_URL=https://YOUR.supabase.co `
  --dart-define=SUPABASE_ANON_KEY=YOUR_ANON_KEY
```

Für **iOS-Live-Preview auf einem echten iPhone von Windows aus** brauchst du **Expo-Go**-ähnliche Tools — Flutter unterstützt das leider nicht direkt. Empfehlung: Codemagic für TestFlight-Builds, dann auf dem iPhone via TestFlight installieren.

---

## iOS-Build & App-Store-Veröffentlichung (von Windows aus, via Codemagic)

### A. Codemagic-Setup
1. Auf <https://codemagic.io> mit GitHub anmelden.
2. Repo verbinden (oder lokal mit `git init`, dann zu GitHub pushen).
3. „New app" → „iOS App" → Workflow „Flutter App".
4. Settings:
   - **Build for platforms**: iOS
   - **Mode**: Release
   - **Build arguments**: 
     ```
     --dart-define=SUPABASE_URL=https://YOUR.supabase.co
     --dart-define=SUPABASE_ANON_KEY=YOUR_ANON_KEY
     ```
5. **Code signing** (App Store Connect):
   - Apple Developer Login eingeben (App-spezifisches Passwort)
   - Codemagic generiert/verwaltet Profile automatisch
6. **Distribution**: TestFlight aktivieren.
7. „Start new build" → nach ~12 Minuten landet die App in TestFlight.
8. Auf dem iPhone: TestFlight-App installieren, Eleutheria testen.

### B. App Store Connect (für die echte Veröffentlichung)
1. <https://appstoreconnect.apple.com> → „Mein Apps" → „+" → Neue App.
2. Bundle-ID: eine eindeutige ID aus deinem Developer-Account, z. B. `de.deinname.eleutheria`.
3. Metadaten ausfüllen (Beschreibung, Screenshots, Datenschutz).
4. In Codemagic „Submit to App Store Review" aktivieren.

> Faustregel: Erste TestFlight-Builds pro Tag sind kostenlos. Reicht locker fürs Entwickeln.

---

## Projektstruktur

```
lib/
├── main.dart              # Bootstrap
├── env.dart               # Environment via --dart-define
├── app/
│   ├── eleutheria_app.dart # MaterialApp + Router
│   ├── providers.dart     # Riverpod-Provider, ProfileNotifier
│   └── router.dart        # GoRouter-Konfiguration
├── core/theme/            # Warm-Academia-Designsystem
├── data/
│   ├── models/            # Philosopher, Question, GameSession, etc.
│   ├── repositories/      # ProfileRepository, QuestionRepository
│   └── seed/              # Hand-kuratierte Philosophen & Fragen
├── features/
│   ├── home/              # Hauptmenü
│   ├── quiz/              # Solo-Quiz, GameSessionController
│   ├── duel/              # Online-Duell mit Supabase-Realtime
│   ├── result/            # Score-Screen mit Konfetti
│   ├── profile/           # Spielerprofil + Errungenschaften
│   ├── leaderboard/       # Tagesrangliste
│   ├── categories/        # Kategorie-Übersicht
│   └── settings/          # Theme, Sprache, Haptik
└── shared/widgets/        # ParchmentBackground, WaxSeal, ChapterHeading, …

assets/
├── fonts/                 # (manuell hinzufügen)
├── images/philosophers/   # (von dir generieren)
└── textures/              # optional
```

---

## Wie ergänze ich Fragen?

In `lib/data/seed/questions_seed.dart` einfach einen neuen `Question(...)` ans Ende der Liste hängen. IDs müssen eindeutig sein (`q_quote_024`, …). Bei `philosopherId` einen der Einträge aus `philosophers_seed.dart` referenzieren — die Reveal-Ansicht zeigt dann automatisch das Mini-Profil.

Für eine produktive App: später Fragen aus Supabase laden statt aus dem Seed.

---

## Roadmap (Ideen für später)

- [ ] **Persönliche Bibliothek** — alle Lieblingszitate exportieren als PDF (Pergament-Stil)
- [ ] **Wochenchallenge** — eine Schule, eine Epoche, sechs Tage
- [ ] **Geteiltes Quiz erstellen** — eigene Fragen für Freundinnen entwerfen
- [ ] **Lese-Empfehlungen** nach jedem Quiz, basierend auf den verfehlten Themen
- [ ] **Apple Watch Companion** — Frage des Tages als Komplikation
- [ ] **Spaced-Repetition-Modus** — falsch beantwortete Fragen tauchen klug verteilt wieder auf
- [ ] **Audio-Zitate** — eingelesen, in der Studierkammer abspielbar
- [ ] **Game Center** Leaderboards & Achievements (statt Supabase) für noch nativeres iOS-Gefühl

---

## Lizenz & Credits

Code: dein eigener Code. Schriften: **Fraunces** (SIL OFL), **Inter** (SIL OFL).

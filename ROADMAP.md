# Griphos — Roadmap

Stand: 2026-05-15

Dieses Dokument hält die ursprüngliche Planung (Blöcke A–F) zusammen mit dem aktuellen Implementierungs-Status. Für die Schritt-für-Schritt-Supabase-Einrichtung siehe [SUPABASE_SETUP.md](SUPABASE_SETUP.md).

## Statuslegende

- ✅ Fertig
- 🟡 Teilweise / läuft gerade
- ⏳ Geplant, noch nicht angefangen
- ⏸ Geparkt / aufgeschoben

---

## Block A — Highscore-System (Pure + Casual)

### Datenmodell

```sql
create table scores (
  id uuid primary key default gen_random_uuid(),
  player_id uuid not null,
  display_name text not null,
  mode text not null,           -- 'classic' | 'quizRush' | 'suddenDeath' | 'daily' | 'letterbox'
  variant text,                 -- '1min' | '3min' | '5min' | 'endless' | null
  difficulty_band text not null,-- 'einstieg' | 'salon' | 'meisterpruefung'
  raw_score int not null,       -- vor Joker-Abzug
  score int not null,           -- effektiver Score nach Abzug
  correct int not null,
  answered int not null,
  jokers_used int not null,     -- Anzahl Fragen, in denen Joker gezogen wurde
  joker_setting text not null,  -- 'off' | 'one' | 'three' | 'always'
  is_pure boolean generated always as (jokers_used = 0) stored,
  session_id text not null,
  played_at timestamptz default now(),
  unique (player_id, session_id)
);
```

### Scoring-Logik

- Basis pro Frage: `100 + (difficulty-1) * 25` (unverändert)
- Joker pro Frage → diese Frage zählt nur mit 50 %. Nicht der ganze Session-Score wird halbiert, nur die Punkte der Fragen, in denen Joker eingesetzt wurden.
- `jokers_used` zählt **Fragen mit Joker**, nicht einzelne Joker-Klicks. 50/50 + Hinweis auf eine Frage = 1 Joker-Frage.
- Sessions mit `jokers_used = 0` → **Pure**-Liste. Alles andere → **Casual**.

### Bestenlisten-UI

- Tabs: *Pure* / *Casual*
- Filter: Modus + Zeitraum (Heute / Diese Woche / All-Time / Mein Bestes)
- Sub-Filter: Schwierigkeitsband (lebt von Block B)

### Write-Pfad

`GameSessionController.finish()` → `ScoreRepository.submit(...)` → Supabase-Insert mit `session_id = GameSession.id`. Idempotent dank `unique(player_id, session_id)`.

### RLS

- `select`: alle dürfen lesen
- `insert`: nur eigene Reihe (`player_id = auth.uid()`)
- `update/delete`: niemand außer Service-Role

### Status

- ✅ Tabelle `scores` angelegt (Migration 0002)
- ✅ RLS-Policies: read_all + insert_own
- ✅ Indizes für Pure/Casual-Queries
- ⏳ App-seitiger `ScoreRepository` + Score-Berechnung
- ⏳ Submit-Aufruf in `GameSessionController.finish()`
- ⏳ Leaderboard-Screen umschreiben (Pure/Casual-Tabs, Modus-Filter, Zeitraum-Filter)

---

## Block B — Schwierigkeitsbänder

### Konzept

Drei Bänder im UI statt Slider:

| Band | difficulty | Score-Schlüssel |
|---|---|---|
| Einstieg | 1–2 | `einstieg` |
| Salon | 1–5 (alle) | `salon` |
| Meisterprüfung | 3–5 | `meisterpruefung` |

- Chip im Home-Screen direkt unter Modus-Picker
- Setting in Profil (`preferredDifficulty: (int, int)` ist im Modell schon da)
- Vor Roll-out: Recherche-Charge laufen lassen, damit Meisterprüfung genug Material hat (heute nur 13× D4 + 3× D5)

### Status

- ✅ Datenmodell `Question.difficulty: int` (1–5) vorhanden
- ✅ `PlayerProfile.preferredDifficulty: (int, int)` vorhanden
- ✅ `GameConfig.difficultyMin/Max` werden bereits ausgewertet
- ⏳ UI: Chip im Home-Screen
- ⏳ UI: Settings-Eintrag
- ⏳ Recherche-Charge (siehe [RESEARCH_PROMPT.md](RESEARCH_PROMPT.md)) ausführen für mehr D4/D5

---

## Block C — Duell-Modus

### Teil 1: Friend-vs-Friend (Code-basiert)

Lobby + Match existieren schon ([duel_lobby_screen.dart](lib/features/duel/duel_lobby_screen.dart), [duel_match_screen.dart](lib/features/duel/duel_match_screen.dart), [duel_repository.dart](lib/features/duel/duel_repository.dart)).

**Polish-Liste:**
- Rematch-Button am Match-Ende
- Klares „Gegnerin verbunden"-Feedback (Realtime-Subscription)
- Timeout wenn Lobby > 5 min leer bleibt
- Default: Joker aus, Difficulty-Band aus Host wählbar
- Nach Match-Ende: Score-Submit nur als Solo-Wertung, kein Duell-Score in den Leaderboards

### Teil 2: Auto-Pairing mit Elo (Stufe 2, später)

```sql
create table duel_ratings (
  player_id uuid primary key,
  rating int default 1000,
  games int,
  wins int,
  losses int,
  last_played timestamptz
);

create table duel_queue (
  player_id uuid primary key,
  rating int not null,
  joined_at timestamptz default now(),
  difficulty_band text not null
);
```

- Cloud-Function / Realtime-Subscription matched zwei Spielerinnen mit nahem Rating (±50 → ±200 mit Wartezeit-Aufweichung) und passendem Band.
- Nach Match-Ende: Elo-Update **per Server-Trigger oder Edge-Function** — Clients dürfen nicht selbst manipulieren.
- UI: dritter Tab im Duell-Screen „Gegnerin finden".

**Reihenfolge:** erst Friend polieren + Rematch, dann Auto-Pairing. Auto-Pairing ist sinnlos, solange die Spielerbasis klein ist.

### Status

- ✅ Tabellen `duels`, `duel_answers` (aus 0001) mit gehärteter RLS (0002)
- ✅ Tabelle `duel_ratings` (Schema in 0002, noch leer)
- ✅ Realtime-Publication für `duels` + `duel_answers`
- ✅ Friend-Lobby + Match-Screen + Repository existieren
- ⏳ Friend-Polish (Rematch, Timeout, Connect-Feedback)
- ⏳ `duel_queue`-Tabelle anlegen (für Stufe 2)
- ⏳ Edge-Function für Matchmaking + Elo-Update
- ⏳ UI-Tab „Gegnerin finden"

---

## Block D — Lokales CMS

### Konzept

Editor läuft auf dem Entwickler-Rechner, schreibt direkt in [lib/data/seed/questions_seed.dart](lib/data/seed/questions_seed.dart) — kein Server-Roundtrip, kein Auth.

### Konkret

- Neuer Ordner `cms/` neben `crossword-builder/`: reines HTML/CSS/JS oder kleine Flutter-Desktop-App
- Liest aktuelle `questions_seed.dart` via Python-Skript (analog zu `scripts/extract_answers.py`), das das Dart-Literal nach JSON parst
- UI: Tabelle aller Fragen, Filter nach Kategorie/Difficulty/Philosoph, Bearbeiten in einer Maske, Neuanlage, „Topic-Key-Konflikt"-Warnung, Vorschau wie die Frage in der App aussieht
- Speichern → schreibt neue `questions_seed.dart` zurück + JSON-Backup
- Bonus: „Bulk-Import"-Modus für Deep-Research-Output, validiert pro Frage (4 Optionen, korrekte Indexe, ID-Kollision, erlaubte `philosopherId`)

### CMS-Loop

Recherche → Bulk-Import-Validierung → manueller Spot-Check → Save → Commit

### Status

- ✅ Parser `scripts/extract_questions.py` (seed → JSON, alle Felder)
- ✅ Writer `scripts/write_questions.py` (JSON → seed, mit Validation + Backup)
- ✅ Lokaler HTTP-Server `cms/serve.py` (Port 8765)
- ✅ UI `cms/index.html` + `style.css` + `app.js` mit Filter, Edit-Drawer, Live-Validation
- ✅ Bulk-Import: paste Dart-Block-Liste → validieren → akzeptierte einfügen
- ✅ Round-Trip-Garantie: extract → write produziert lauffähigen, identisch interpretierten Dart

---

## Block E — Crossword online

### Konzept

- Tabelle `crossword_puzzles` in Supabase (`id, title, theme, grid_json, available_from, difficulty`)
- Builder-Tool ([crossword-builder/](crossword-builder/)) bekommt einen „Push to Supabase"-Knopf
- App lädt Puzzles online, lokaler Cache, Fallback auf die zwei Demo-Puzzles in [puzzle_seed.dart](lib/features/crossword/models/puzzle_seed.dart)
- Liefer-Rhythmus: 1 Rätsel/Woche

### Status

- ✅ App-seitige Crossword-Logik funktioniert mit Demo-Puzzles
- ✅ Builder-Tool kuratiert Puzzles als JSON
- ⏳ `crossword_puzzles`-Tabelle in Supabase
- ⏳ Push-Mechanismus vom Builder-Tool
- ⏳ App-seitiger `CrosswordRepository` (online + Fallback)

---

## Block F — Kategorien wegwerfen

### Konzept

- Route `/categories` aus dem Router entfernen
- Menü-Eintrag im Home raus
- Code bleibt liegen ([categories_screen.dart](lib/features/categories/categories_screen.dart)) — entweder `// ignore: unused`-Marker oder nach `lib/_attic/` verschieben mit kurzer README
- `QuestionCategory`-Enum **bleibt unverändert** — es kennzeichnet den Fragentyp, das brauchen wir weiter

### Status

- ⏳ Kleine, schnelle Aktion (~30 min)

---

## Reihenfolge / Abarbeitung

| # | Block | Status |
|---|---|---|
| 1 | Supabase einrichten | ✅ Fertig (siehe [SUPABASE_SETUP.md](SUPABASE_SETUP.md)) |
| 2 | Highscore (Block A) | 🟡 Schema fertig, App-Code & UI ausstehend |
| 3 | Schwierigkeitsbänder UI (Block B) | ⏳ Klein, kann parallel zu 2 laufen |
| 4 | Kategorien archivieren (Block F) | ⏳ ~30 Minuten |
| 5 | Lokales CMS (Block D) | ✅ Fertig (siehe [cms/README.md](cms/README.md)) |
| 6 | Duell-Friend polieren (Block C, Teil 1) | ⏳ |
| 7 | Crossword online (Block E) | ⏳ |
| 8 | Duell Auto-Pairing + Elo (Block C, Teil 2) | ⏳ Erst wenn Spielerbasis wächst |

---

## Aktueller Schritt

**Wir sind bei Punkt 2** — App-seitige Highscore-Integration.

Im Detail (siehe Todo-Liste in der laufenden Session):
- ✅ Anonymous-Auth-Bootstrap + `.env`-Workflow + `ProfileRepository` auf `auth.uid()` umgestellt (Schritt 11a)
- ⏳ **Schritt 11b**: Profile-Reservation (`profiles`-Insert mit unique `display_name`, Konflikt-Vorschlag)
- ⏳ **Schritt 11c**: `ScoreRepository.submit(...)` mit Pure/Casual-Berechnung
- ⏳ **Schritt 11d**: Leaderboard-Screen auf `scores`-Tabelle umbauen (Pure/Casual-Tabs)

---

## Memory-Referenzen

Die wichtigsten Entscheidungen aus der Planung sind als Memory-Notizen abgelegt unter `C:\Users\maikp\.claude\projects\c--Projekte-Griphos\memory\`:

- `feedback_leaderboard_scoring.md` — Pure/Casual + 50 %-Joker-Abzug
- `project_duel_modes.md` — Friend Pflicht, Auto-Pairing später
- `project_categories_parked.md` — UI raus, Code bleibt
- `feedback_cms_local_first.md` — Lokales CMS zuerst
- `project_supabase_hosting.md` — Self-Hosted Supabase
- `project_server_environment.md` — Ubuntu 24.04 + Caddy, sicherheitsbewusst
- `project_auth_model.md` — Anonymous Auth + profiles-Tabelle
- `project_eleutheria_overview.md` — Was ist Griphos, Stack, aktueller Stand

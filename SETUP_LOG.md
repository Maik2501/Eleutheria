# Setup-Protokoll

Was bisher getan wurde:

## 1. Flutter SDK
- Geklont nach `C:\src\flutter` (Stable, Flutter 3.41.9 / Dart 3.11.5)
- In `User`-PATH eingetragen (kein Admin nötig)
- `--disable-analytics` gesetzt
- Web-Target aktiviert (`flutter config --enable-web`)
- Plattformen generiert: iOS, Android, Web

## 2. Projekt
- 36 Dart-Dateien, alle Static-Analysis-Errors behoben
- Web-Index aufgehübscht: warmes Pergament-Loading-Sigel statt Default-Splash
- Manifest auf "Sophia — Philosophie Quiz" mit Burgunder-Theme

## 3. Lokales Supabase (Self-hosted, Docker)
- Repo geklont nach `C:\src\supabase`
- `.env` aus `.env.example` kopiert (Demo-Keys, nur lokal verwenden)
- **Windows-Falle gefixt**: CRLF-Zeilenumbrüche in `volumes/api/kong-entrypoint.sh`,
  `kong.yml`, `vector.yml`, `envoy/docker-entrypoint.sh` auf LF konvertiert —
  ohne diesen Schritt blieb Kong beim Start hängen ("no such file or directory").
- 14 Container laufen: db, kong (API-GW), rest (PostgREST), realtime, auth,
  meta, vector, imgproxy, pooler, plus storage/analytics/studio (für uns
  nicht-kritisch).
- Schema migriert: `supabase/migrations/0001_init.sql` mit Tabellen
  `duels`, `duel_answers`, `daily_scores` + Realtime-Publication + RLS-Policies.
- Verifikation: `GET /rest/v1/duels` antwortet `200 []`.

## 4. App-Logik-Fix: Spoiler-Bug
**Problem (vom Benutzer gemeldet):** Mehrere Fragen im Seed teilten sich den
selben Stoff (z.B. q_quote_002 "Cogito, ergo sum" → Descartes UND
q_complete_001 "Ich denke, also …" → "bin ich"). Wenn beide in einer Session
landeten, verriet die erste die zweite.

**Lösung:**
- `Question.topicKey` (optional) hinzugefügt
- `QuestionRepository.randomBatch` dedupliziert: pro Session höchstens
  *eine* Frage pro `topicKey`
- Bekannte Spoiler-Pärchen markiert:
  - `cogito` (q_quote_002, q_complete_001)
  - `sapere_aude` (q_quote_008, q_complete_004)
  - `sartre_existenzialismus` (q_quote_004, q_complete_006)
  - `tractatus` (q_quote_007, q_quote_023, q_work_010)
  - `heidegger_dasein` (q_quote_017, q_concept_007)
  - `marx_kritik` (q_quote_006, q_critique_001)

## Aktuelle Zugänge
- App: <http://localhost:8080>
- Supabase Studio (DB-UI): <http://localhost:8000>  
  Login: `supabase` / `this_password_is_insecure_and_should_be_updated`
- Supabase REST: <http://localhost:8000/rest/v1/>
- Supabase Realtime WS: `ws://localhost:8000/realtime/v1/websocket`

## Helper-Skripte
- `.\scripts\run.ps1` — App starten (mit Supabase-URL/Key vorgesetzt)
- `.\scripts\supabase-up.ps1` — Container hochfahren + Schema migrieren
- `.\scripts\supabase-down.ps1` — Container stoppen (Daten bleiben)

## Auf Linux-Server umziehen — was zu tun ist
1. Auf dem Server: `git clone --depth 1 https://github.com/supabase/supabase.git`
2. `cd supabase/docker && cp .env.example .env`
3. **Wichtig**: Bei nicht-x86_64 Architektur Image-Tags prüfen.
4. **Auch wichtig**: Falls per `git` mit Windows-Mediator geclont, `find ./volumes
   -type f -exec dos2unix {} \;` ausführen (oder direkt auf Linux klonen).
5. `docker compose up -d`
6. Schema migrieren: `cat path/to/0001_init.sql | docker exec -i supabase-db
   psql -U postgres -d postgres`
7. Auf dem Windows-Dev-Rechner in `scripts\run.ps1`:
   `$env:SUPABASE_URL = 'http://DEIN-SERVER:8000'`

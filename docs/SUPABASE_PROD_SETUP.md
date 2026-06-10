# Supabase PROD — Griphos-eigene Instanz (hal-9002)

Eingerichtet 2026-06-10. Zweite, saubere Supabase-Instanz **nur für Griphos**,
parallel zur geteilten Dev-Instanz (`/opt/supabase-eleutheria`, die weiter für
lokale Entwicklung und andere Apps läuft).

## Eckdaten

| Was | Wert |
|---|---|
| Public URL | `https://api.griphos.maikpickl.de` (CNAME → maik-server.ddns.net) |
| Pfad | `/opt/supabase-griphos/` (Owner `supabase`, 750) |
| Supabase-Commit | `640869da470b41e240554a16f1aaba035f582765` (2026-05-15, identisch mit Dev; siehe `installed-commit.txt`) |
| Compose-Projekt | `griphos` (`name:` in docker-compose.yml) |
| Container-Präfix | `griphos-*` bzw. `realtime-dev.griphos-realtime` |
| Kong (Loopback) | `127.0.0.1:8100` (HTTP), `127.0.0.1:8543` (HTTPS) |
| Supavisor (Loopback) | `127.0.0.1:54422` (Session), `127.0.0.1:6643` (Transaction) |
| Migrationen | 0001–0011 angewendet (als `postgres`-Rolle, 2026-06-10) |
| Backup | täglich 03:30 via Cron (supabase-User), 14 Tage Retention, `/opt/supabase-griphos/backups/` |
| Studio | nicht öffentlich; SSH-Tunnel auf Kong 8100 + Dashboard-Login |

## Abweichungen vom Upstream-Checkout (bei Upgrade erneut anwenden!)

Der Stack ist auf den o. g. Commit gepinnt. **Kein blindes `git pull`** — bei
einem Upgrade: neuen Commit auschecken und diese sed-Anpassungen wiederholen:

```bash
D=/opt/supabase-griphos/supabase/docker
sed -i 's/^name: supabase$/name: griphos/' $D/docker-compose.yml
sed -i '/container_name:/s/supabase-/griphos-/' $D/docker-compose.yml
sed -i 's/realtime-dev\.supabase-realtime/realtime-dev.griphos-realtime/g' $D/volumes/api/kong.yml
sed -i 's/supabase-/griphos-/g' $D/volumes/logs/vector.yml
```

Grund: Die Dev-Instanz belegt die Default-Container-Namen (`supabase-db` …);
Kong und Vector referenzieren Container-Namen in ihren Configs.

Dazu kommt `docker-compose.override.yml` (überlebt Upgrades, nicht im Git des
Upstream-Repos): alle Host-Ports auf Loopback, `db` ganz ohne Host-Port.

## .env (Secrets)

`/opt/supabase-griphos/supabase/docker/.env`, mode 600, Owner `supabase`.
Generiert am 2026-06-10 (Python-Generator, HS256-JWTs mit 10 Jahren Laufzeit).
Wichtige Nicht-Secret-Werte: `ENABLE_ANONYMOUS_USERS=true`,
`PGRST_DB_SCHEMAS=public,storage,graphql_public`, `POOLER_TENANT_ID=griphos-prod`,
URLs auf `https://api.griphos.maikpickl.de`.

**In den PW-Manager übernehmen** (auf dem Server auslesen):

```bash
sudo grep -E '^(POSTGRES_PASSWORD|JWT_SECRET|ANON_KEY|SERVICE_ROLE_KEY|DASHBOARD_USERNAME|DASHBOARD_PASSWORD)=' \
  /opt/supabase-griphos/supabase/docker/.env
```

Der `ANON_KEY` ist öffentlich (steckt im App-Bundle, `.env.prod`);
`SERVICE_ROLE_KEY`, `JWT_SECRET` und `POSTGRES_PASSWORD` niemals in den Client.

## App-Anbindung

- Lokale Entwicklung: `.env` → Dev-Instanz (unverändert)
- Release/TestFlight: `.env.prod` → Prod (gitignored; Werte auch als
  Codemagic-Env-Vars hinterlegen)
- Build: `flutter build ipa --dart-define-from-file=.env.prod`

## Betrieb

```bash
# Status
sudo docker ps --filter name=griphos

# Stack neu starten
sudo docker compose --project-directory /opt/supabase-griphos/supabase/docker up -d

# Logs eines Dienstes
sudo docker logs griphos-auth --tail 50

# Migration einspielen (neue Datei aus supabase/migrations/ des App-Repos)
sudo docker exec -i griphos-db psql -U postgres -d postgres -v ON_ERROR_STOP=1 < 00XX_name.sql
```

Smoke-Test von außen:

```bash
curl -H "apikey: $ANON_KEY" https://api.griphos.maikpickl.de/auth/v1/health
```

## Backup & Restore

- Cron (User `supabase`): `30 3 * * *` → `scripts/backup.sh` → `pg_dump | gzip`,
  **inklusive `auth`-Schema** — anonyme User + Refresh-Tokens überleben damit
  einen Server-/Cloud-Umzug (Refresh-Tokens sind DB-Rows, keine JWTs).
- Restore: frischen Stack hochziehen, dann
  `gunzip -c griphos-X.sql.gz | sudo docker exec -i griphos-db psql -U postgres -d postgres`
- **TODO:** Off-Site-Kopie der Dumps (restic/rclone) — aktuell liegen Backups
  nur lokal auf demselben Server.

## Cloud-Migrationspfad (falls nötig)

1. Schema: Migrationen 0001–00XX auf der Ziel-Instanz anwenden (am 2026-06-10
   von Null verifiziert — läuft in einem Rutsch durch).
2. Daten: letzten Dump einspielen (public-Schema-Daten + `auth.users` +
   `auth.refresh_tokens`).
3. App: `SUPABASE_URL`/`SUPABASE_ANON_KEY` per Update umstellen. Achtung:
   neuer JWT_SECRET beim Anbieter heißt neue Anon/Service-Keys; bestehende
   Sessions refreshen sich über die migrierten Refresh-Tokens.

## Sicherheits-Status (wie Dev)

- Nur Caddy exponiert die API; alle Container-Ports auf `127.0.0.1`.
- Postgres ohne Host-Port (nativer Postgres auf 5432 unberührt).
- `.env` 600/supabase; `/opt/supabase-griphos` 750.
- `maik` nicht in der docker-Gruppe; Stack-Betrieb über `sudo` bzw. supabase-User.

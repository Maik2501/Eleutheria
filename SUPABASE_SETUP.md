# Supabase Self-Hosting Setup für Eleutheria

Stand: 2026-05-15. Dieses Dokument hält den Fortschritt der Einrichtung fest, damit wir bei Chat-/Session-Abbrüchen nahtlos weitermachen können.

## Architektur

```
Internet ─┐
          │
       Caddy (Port 80/443, bestehende Konfig auf maikpickl.de-Server)
          │
          ├── maikpickl.de + weitere bestehende Apps (unverändert)
          │
          └── api.eleutheria.maikpickl.de  →  http://127.0.0.1:8000 (Kong)
                                                  │
                                                  └── Docker-Netz "supabase"
                                                        ├─ Postgres   (intern, kein Host-Port)
                                                        ├─ Auth/GoTrue
                                                        ├─ PostgREST
                                                        ├─ Realtime
                                                        ├─ Storage
                                                        ├─ Studio (Admin-UI, intern, via SSH-Tunnel zugänglich)
                                                        └─ Supavisor (Pooler, 127.0.0.1:6543)
```

Prinzipien:
- Nur Kong-HTTP-Port nach außen, und auch nur über Caddy auf eigener Subdomain.
- Alle Container-Ports werden auf `127.0.0.1` gebunden, nicht `0.0.0.0`.
- Postgres ist nicht vom Host aus erreichbar (auch nicht via Loopback) — der bestehende native Postgres auf 5432 läuft unangetastet weiter.
- Studio (Admin-UI) nicht öffentlich — Zugriff per SSH-Tunnel.
- Dedizierter `supabase`-Service-User besitzt den Stack; `maik` ist nicht in der `docker`-Gruppe.

## Entscheidungen

| Thema | Entscheidung |
|---|---|
| Hosting | Self-hosted auf maiks Linux-Server (Ubuntu 24.04 LTS), Glasfaser |
| Subdomain | `api.eleutheria.maikpickl.de` (CNAME → `maik-server.ddns.net`) |
| Pfad | `/opt/supabase-eleutheria/` |
| Owner | dedizierter System-User `supabase`, kein Login, kein sudo |
| Auth | Anonymous Auth + `profiles`-Tabelle mit unique `display_name` |
| Reverse-Proxy | Host-Caddy v2.10.2 (bestehend), nicht Compose-Caddy |
| Secrets | Lokal generiert per Python-Skript, im User-PW-Manager gespeichert |

## Fortschritt

- [x] DNS: CNAME `api.eleutheria.maikpickl.de` → `maik-server.ddns.net`
- [x] Schritt 1 — DNS-Record gesetzt (CNAME)
- [x] Schritt 2 — Docker CE 29.5.0 + Compose v5.1.3 aus offiziellem Repo installiert
- [x] Schritt 3 — System-User `supabase` (UID 994, GID 984), in `docker`-Gruppe; `/opt/supabase-eleutheria` mit `chmod 750`
- [x] Schritt 4 — Supabase-Repo geklont nach `/opt/supabase-eleutheria/supabase` (Commit-Hash `640869da`, `--depth 1`)
- [x] Schritt 5 — Secrets generiert und in `.env` eingetragen:
  - `POSTGRES_PASSWORD` (40), `JWT_SECRET` (64), `SECRET_KEY_BASE` (64), `VAULT_ENC_KEY` (32)
  - `DASHBOARD_USERNAME=maik`, `DASHBOARD_PASSWORD` (28)
  - `ANON_KEY`, `SERVICE_ROLE_KEY` (HS256 JWTs, 10 Jahre Laufzeit)
  - URLs auf `https://api.eleutheria.maikpickl.de` gesetzt
  - User hat sechs Werte in seinen PW-Manager übernommen
- [x] Schritt 6 — Compose-Härtung: alle exposed Ports auf `127.0.0.1` (Kong 8000+8443, Supavisor 54322+6543), db-Mapping ganz raus per Override
- [x] Schritt 7 — Caddy-Block für `api.eleutheria.maikpickl.de` aktiv, Let's-Encrypt-Cert geholt, von außen erreichbar (502 erwartet bis Stack läuft)
- [x] Schritt 8 — Stack läuft (13/13 Container, alle healthy), Endpoints von außen erreichbar (`/auth/v1/health` → 200, `/rest/v1/` → 200)
- [x] Schritt 9 — Backup-Cronjob: täglich 03:00 Uhr, `pg_dump | gzip`, 14 Tage Aufbewahrung, lokal in `/opt/supabase-eleutheria/backups/`
- [x] Schritt 10 — Migration 0001 + 0002 angewendet: 6 Tabellen (daily_scores, duel_answers, duel_ratings, duels, profiles, scores), 13 strikte RLS-Policies
- [ ] Schritt 11 — Flutter-App-Integration: Anonymous Auth, Profile-Reservation, Score-Submit

## Aktueller Schritt 6 — Compose härten

Aus 6.1 wissen wir: 

- Kong: 8000 (HTTP) + 8443 (HTTPS)
- db (Postgres): 5432
- supavisor: 6543

### 6.2 — `.env` patchen (drei Ports auf Loopback)

```bash
cd /opt/supabase-eleutheria/supabase/docker

sed -i 's/^KONG_HTTP_PORT=.*/KONG_HTTP_PORT=127.0.0.1:8000/' .env
sed -i 's/^KONG_HTTPS_PORT=.*/KONG_HTTPS_PORT=127.0.0.1:8443/' .env
sed -i 's/^POOLER_PROXY_PORT_TRANSACTION=.*/POOLER_PROXY_PORT_TRANSACTION=127.0.0.1:6543/' .env

grep -E "^(KONG_HTTP_PORT|KONG_HTTPS_PORT|POOLER_PROXY_PORT_TRANSACTION)=" .env
```

Erwartung:
```
KONG_HTTP_PORT=127.0.0.1:8000
KONG_HTTPS_PORT=127.0.0.1:8443
POOLER_PROXY_PORT_TRANSACTION=127.0.0.1:6543
```

### 6.3 — Override-Datei für die db schreiben

```bash
cat > docker-compose.override.yml << 'YAMLEOF'
# Eleutheria-spezifische Hardening-Overrides.
# Wird automatisch mit docker-compose.yml gemerged.
services:
  # Postgres niemals an den Host exposen — auf dem System
  # läuft bereits ein nativer Postgres auf Port 5432.
  # Container-intern erreichen die anderen Services die DB
  # weiterhin über den Docker-DNS-Namen "db:5432".
  db:
    ports: !reset null
YAMLEOF

chmod 640 docker-compose.override.yml
ls -l docker-compose.override.yml
cat docker-compose.override.yml
```

### 6.4 — Verifizieren

```bash
docker compose config | grep -B 5 "127.0.0.1\|published" | head -60
```

Erwartet: Drei Services (`kong`, `supavisor`) mit `published: "127.0.0.1:..."`. Kein `db` mit `ports:`.

## Schritt 7 (kommt danach) — Caddy

```caddy
api.eleutheria.maikpickl.de {
    reverse_proxy 127.0.0.1:8000
    encode zstd gzip
    log {
        output file /var/log/caddy/eleutheria-api.log
    }
}
```

Einfügen in `/etc/caddy/Caddyfile`, dann:
```bash
sudo caddy fmt --overwrite /etc/caddy/Caddyfile
sudo caddy validate --config /etc/caddy/Caddyfile
sudo systemctl reload caddy
```

## Wichtige Pfade

| Was | Wo |
|---|---|
| Stack | `/opt/supabase-eleutheria/supabase/docker/` |
| Compose-Datei | `docker-compose.yml` (nicht editieren — wird durch `git pull` überschrieben) |
| Override | `docker-compose.override.yml` (unsere Härtung) |
| Secrets | `.env` (mode 600, nur supabase-User lesbar) |
| Volumes | `volumes/` (Postgres-Daten landen hier) |
| Installations-Commit | `/opt/supabase-eleutheria/installed-commit.txt` |
| Caddy-Konfig | `/etc/caddy/Caddyfile` |

## Wiederherstellung bei Total-Verlust

Falls der Server stirbt und keine Backups da sind:
1. Server neu aufsetzen, Schritte 2–4 wiederholen.
2. `.env` aus PW-Manager-Werten rekonstruieren (alle sechs gespeicherten Werte ausreichend; `SECRET_KEY_BASE`/`VAULT_ENC_KEY` neu generieren ist okay, bricht aber Vault-Daten).
3. Postgres-Volume aus letztem `pg_dump`-Backup wiederherstellen.

## Sicherheits-Notizen

- `maik`-User ist NICHT in `docker`-Gruppe (Docker-Group = effektiv root).
- `.env` mit Secrets ist `chmod 600`, Owner `supabase`.
- `/opt/supabase-eleutheria/` ist `chmod 750`, nur `supabase` + Root können reinschauen.
- Kong, Studio, Postgres, Supavisor: keine offenen Ports nach außen.
- Cockpit auf 9090 ist öffentlich — separates Thema, sollte später hinter Tailscale.
- Pending: Kernel-Upgrade auf 6.8.0-111 wartet (Reboot wenn alles läuft).

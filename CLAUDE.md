# Griphos (ehem. Eleutheria) — Hinweise für Claude

Flutter-App (iOS-first): philosophische Rätsel und Denkspiele. Quiz, Letterbox,
Kreuzworträtsel, Live-Duelle (Supabase Realtime), Bestenlisten (Pure/Casual).

## Befehle

- Prüfen: `flutter analyze && flutter test`
- Lokal ausführen (Web, gegen Dev-Backend): `flutter run -d web-server --web-port=8123 --dart-define-from-file=.env`
- Release-Build: via Codemagic-Web-UI (kein YAML im Repo); vorher pubspec-Build-Code bumpen

## Backend (Self-Hosted Supabase auf hal-9002)

| Instanz | URL | Zweck | Konfig |
|---|---|---|---|
| Dev (geteilt mit anderen Apps) | `https://api.eleutheria.maikpickl.de` | lokale Entwicklung | `.env` |
| **Prod (nur Griphos)** | `https://api.griphos.maikpickl.de` | TestFlight/App Store | `.env.prod` (gitignored) |

- **Vollständige Server-Doku: [docs/SUPABASE_PROD_SETUP.md](docs/SUPABASE_PROD_SETUP.md)**
  (Pfade, Ports, Container-Namen `griphos-*`, Upgrade-Prozedur, Backup/Restore)
- Server-Zugang: SSH als `maik` über Tailscale (`hal-9002` / 100.118.107.7);
  sudo nur nach Absprache via temporärem Sudoers-Drop-in
- Schema lebt ausschließlich in `supabase/migrations/` (0001–0013 sind auf Prod).
  Neue Migration anwenden: `sudo docker exec -i griphos-db psql -U postgres -d postgres -v ON_ERROR_STOP=1 < datei.sql`
- Secrets: nie ins Repo — Bitwarden (User) bzw. `.env`-Dateien auf dem Server (600)

## Wichtige Dokumente

- [docs/CODE_REVIEW_2026-06-10.md](docs/CODE_REVIEW_2026-06-10.md) — Pre-Launch-Audit als Checkliste (Highs alle erledigt; offene Mediums/Lows)
- [docs/APP_STORE_CHECKLIST.md](docs/APP_STORE_CHECKLIST.md) — manuelle App-Store-Connect-Schritte
- `store_screenshots/` — finale Store-Assets (iPhone 1242×2688, iPad 2048×2732; Screenshots ohne Alphakanal halten!)

## Konventionen

- Commits auf `main`, deutsch, conventional-commit-artig (`fix(duel): …`); Push nur nach User-Freigabe
- UI-Texte deutsch, weibliche Anrede ("Mitspielerin", "Schülerin der Philosophie")
- Defensive JSON-Parser: `tryFromJson` gibt `null` zurück statt zu werfen; Remote-Content wird gecacht — Validierung MUSS vor dem Cache greifen

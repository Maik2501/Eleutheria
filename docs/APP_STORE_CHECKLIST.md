# App Store Connect — manuelle Schritte vor der Einreichung

Ergänzt die Code-Fixes aus `CODE_REVIEW_2026-06-10.md` (A2/A4). Stand: 2026-06-10.

## 1. Privacy-Label ("App-Datenschutz" in App Store Connect)

Deklarieren unter **Daten, die mit dem Nutzer verknüpft sind** (alle Zwecke:
**App-Funktionalität**, kein Tracking):

| App-Store-Kategorie | Was konkret | Quelle |
|---|---|---|
| Benutzer-ID | anonyme Supabase-UID + eindeutiger Anzeigename | `profiles` |
| Gameplay-Inhalte | Leaderboard-Scores, Duell-Antworten | `scores`, `duel_answers` |
| Andere nutzergenerierte Inhalte | Feedback-Texte, Frage-Vorschläge | `feedback` |
| E-Mail-Adresse | optionale Kontakt-E-Mail im Feedback-Sheet | `feedback.contact_email` |

Nicht deklarieren: Standort, Kontakte, Identifier für Tracking — wird nichts
davon erhoben. Die Kamera (QR-Scan) erhebt keine Daten, die die App speichert
oder versendet → kein Label-Eintrag nötig.

## 2. Datenschutzerklärungs-URL

Pflichtfeld in App Store Connect. Muss abdecken: anonyme Konten,
gespeicherte Daten (siehe Tabelle oben), Self-Hosted-Server als
Verarbeitungsort, Löschweg (In-App unter Einstellungen → Konto), Kontakt.
**TODO: URL anlegen und eintragen** (z. B. statische Seite auf dem eigenen
Server hinter Caddy).

## 3. Account-Löschung (Review-Notes)

In den App-Review-Notes erwähnen: "Account deletion is available in-app
under Einstellungen → Konto → Konto löschen. Accounts are anonymous
(Sign in with Apple / email is not used)."

## 4. Export-Compliance

`ITSAppUsesNonExemptEncryption = false` steht jetzt in der Info.plist —
die Frage beim Upload entfällt damit. Die App nutzt nur Standard-TLS (exempt).

## 5. Server-Seite vor dem Build

- [x] ~~Migration 0011 anwenden~~ — erledigt: Eigene **Prod-Instanz**
      `https://api.griphos.maikpickl.de` steht (2026-06-10), Migrationen
      0001–0011 angewendet, `delete_account()`-RPC end-to-end verifiziert
      (anonymer Signup → Profil → RPC → User + Profil weg).
      Details: `docs/SUPABASE_PROD_SETUP.md`.
- [ ] In der App (TestFlight, Prod-Build) testen: Einstellungen → Konto
      löschen → App landet im Profil-Setup, Anzeigename wieder reservierbar.

## 6. Build-Hinweise (Codemagic)

- **Release-Builds gegen PROD bauen:** `SUPABASE_URL` + `SUPABASE_ANON_KEY`
  aus `.env.prod` als Codemagic-Env-Vars setzen (bzw.
  `--dart-define-from-file=.env.prod`). Lokale Entwicklung bleibt auf der
  Dev-Instanz (`.env`).
- pubspec-Build-Code bumpen (aktuell `0.1.0+7`) — die App-Version im
  Feedback kommt jetzt automatisch aus dem Bundle, kein `env.dart`-Sync mehr.
- Nach diesem Stand einmal `flutter pub get` auf dem Build-Server
  (neue Dependency `package_info_plus`).

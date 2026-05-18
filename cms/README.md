# Sophia · Fragen-Editor (lokales CMS)

Internes Entwicklungswerkzeug zum Bearbeiten der Eleutheria-Fragen-Datenbank
([`lib/data/seed/questions_seed.dart`](../lib/data/seed/questions_seed.dart)).
Pure HTML/CSS/JS plus ein winziger Python-Server, kein Build, keine
Abhängigkeiten außer Python 3.10+.

## Start

```powershell
python cms\serve.py
```

Öffnet auf [http://localhost:8765/](http://localhost:8765/). Der Server:

1. Liest die aktuelle `questions_seed.dart` per [`scripts/extract_questions.py`](../scripts/extract_questions.py) und legt das Ergebnis als `cms/data/questions.json` und `philosophers.json` ab.
2. Serviert die HTML-UI an `localhost:8765`.
3. Auf **„Speichern"** schreibt er die geänderte JSON zurück und ruft [`scripts/write_questions.py`](../scripts/write_questions.py), das eine frische `questions_seed.dart` rendert. **Eine timestamped Backup-Datei wird automatisch daneben angelegt** (`questions_seed.dart.bak.YYYYMMDD-HHMMSS`).

> **Nicht ins Internet stellen.** Der Server hat keine Auth und schreibt Dateien.

## Workflow

| Aktion | Wie |
|---|---|
| Frage bearbeiten | Zeile in der Tabelle anklicken → Drawer öffnet → Felder ändern → **Übernehmen** |
| Neue Frage | **+ Neue Frage** → Felder ausfüllen → **Übernehmen**. ID wird automatisch vorgeschlagen passend zur Kategorie. |
| Mehrere auf einmal | **Bulk-Import** → Dart-Output (`Question(...)`-Block-Liste) reinpasten → **Validieren** → **Einfügen** |
| Speichern | **Speichern** (oder Ctrl+S) — schreibt `questions_seed.dart` und legt Backup an |
| Aus Quelle neu laden | **Neu laden** — verwirft lokale Edits, holt frische Version aus `questions_seed.dart` |

## Validierungen

Pro Frage:
- 4 nicht-leere Antworten
- `correctIndex` ∈ {0,1,2,3}
- `difficulty` ∈ {1..5}
- Eindeutige `id`
- `philosopherId` muss in [`philosophers_seed.dart`](../lib/data/seed/philosophers_seed.dart) vorkommen
- `topicKey`-Konflikte werden als Warnung angezeigt (manchmal gewollt für Spoiler-Gruppen)

Vor dem Schreiben prüft `write_questions.py` nochmal alles und bricht ab,
wenn ein Validation-Issue durchgerutscht ist (Verteidigung in zwei Linien).

## Round-Trip-Garantie

Wenn man die UI öffnet, **nichts ändert** und auf Speichern klickt, sollte der `git diff` auf `questions_seed.dart` nur formale Änderungen zeigen (sortierte Reihenfolge der optionalen Felder, einheitliche Quoting-Regel). Inhaltlich bleibt alles gleich.

## Filter

- **Suche**: durchsucht ID, Prompt, alle Antworten, Attribution, Erklärung
- **Kategorie**: einer der sechs Fragentypen
- **Schwierigkeit**: Mehrfachauswahl 1–5
- **Philosoph**: filtert nach `philosopherId`

## ID-Konvention

Die Auto-ID hängt sich an die aktuelle Kategorie:

| Kategorie | Präfix |
|---|---|
| Zitat → Philosoph | `q_quote_NNN` |
| Werk → Autor | `q_work_NNN` |
| Philosoph → Epoche | `q_era_NNN` |
| Begriff → Schule | `q_concept_NNN` |
| Zitat vervollständigen | `q_complete_NNN` |
| Kritik & Streit | `q_critique_NNN` |

Bei „Neue Frage" wird die nächste freie Nummer pro Präfix gewählt.

## Tastenkürzel

- **Ctrl+S** (Cmd+S auf Mac): Speichern
- **Esc**: Drawer / Bulk-Dialog schließen

## Wiederherstellung

Falls etwas schiefgeht, finden sich die letzten Backups in
[`lib/data/seed/`](../lib/data/seed/) als `questions_seed.dart.bak.*`.
Restore:

```powershell
copy lib\data\seed\questions_seed.dart.bak.20260516-165720 lib\data\seed\questions_seed.dart
```

## Dateistruktur

```
cms/
├── README.md            (dieses Dokument)
├── index.html
├── style.css
├── app.js
├── serve.py             (lokaler HTTP-Server)
└── data/                (generiert, gitignored empfohlen)
    ├── questions.json
    ├── questions.js
    ├── philosophers.json
    └── philosophers.js

scripts/
├── extract_questions.py (seed -> JSON)
└── write_questions.py   (JSON -> seed)
```

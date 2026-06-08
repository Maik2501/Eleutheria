# Griphos · Kreuzworträtsel-Werkstatt

Internes Entwicklungswerkzeug zum Konstruieren von Kreuzworträtseln für Griphos. Reines HTML/CSS/JS, kein Build, keine Abhängigkeiten — `index.html` per Doppelklick im Browser öffnen.

## Was drin ist

- **Wortbank** mit den 78 Antworten aus [`lib/data/seed/questions_seed.dart`](../lib/data/seed/questions_seed.dart) (sortier- und filterbar nach Kategorie, Länge, Suche).
- **Kreuzwort-Begriffe** als kuratierte Zusatzkategorie mit kurzen, gut platzierbaren Philosophiebegriffen.
- **Eigene Wörter** lassen sich hinzufügen (mit optionalem Hinweis und Kategorie).
- **Scrabble-artiges Gitter** mit Tile-Schatten, Light Mode in Pergament-/Burgunder-Palette.
- **Optionaler Symmetrie-Modus** für 180°-rotationssymmetrische Sperrfelder (standardmäßig aus).
- **Hinweisliste** wird live aus dem Gitter generiert (waagerecht / senkrecht), Hinweise sind direkt editierbar.
- **Speichern/Laden** als manueller Browser-Speicherstand; zusätzlich JSON-Export/-Import und Auto-Save in `localStorage` (`sophia_crossword_state_v1`).
- **Drucken**: `@media print` blendet UI-Chrome aus, übrig bleiben Gitter + Hinweise.
- **Info-Tab** mit kompakter Best-Practice-Sammlung zur Kreuzworträtsel-Konstruktion.

## Bedienung in einem Satz pro Aktion

| Aktion | Wie |
|---|---|
| Buchstabe setzen | Feld klicken, tippen |
| Cursor bewegen | Pfeiltasten |
| Richtung wechseln | Rechtsklick auf Gitter oder Wortbank, auch während eines Drags; außerdem Tab, Pfeil quer zur aktuellen Richtung oder Buttons oben rechts |
| Sperrfeld | Doppelklick auf Feld oder Leertaste auf ausgewählter Zelle |
| Wort aus Bank platzieren | Wort ins Gitter ziehen oder Wort klicken (wird orange) → Startfeld klicken; Esc bricht ab |
| Platziertes Wort verschieben | Wort im Gitter an einem Buchstaben greifen und an eine neue Stelle ziehen |
| Eigenes Wort | „+ Eigenes Wort" in der Wortbank ausklappen |
| Symmetrie an/aus | Toolbar-Button; standardmäßig aus |
| Speichern | „Speichern" legt einen Browser-Speicherstand ab |
| Laden | „Laden" stellt den Browser-Speicherstand wieder her |
| JSON exportieren | Lädt eine Sicherungsdatei herunter |
| Kategorien filtern | Kategorien per Klick additiv ein- und ausschalten; „Alle" setzt die Auswahl zurück |
| Vorschläge | „Vorschläge" aktivieren, Startfeld im Gitter klicken; links bleiben nur passende Wörter für die aktuelle Richtung |
| JSON importieren | Wählt eine zuvor exportierte JSON-Datei aus; die App-Wortbank bleibt erhalten |
| Drucken | „Drucken" — nutzt Print-CSS |

## Daten neu aus der App ziehen

Wenn neue Fragen ergänzt wurden:

```powershell
python ..\scripts\extract_answers.py
```

erzeugt `data/answers.json` und `data/data.js` neu. `data.js` ist die Form, die das Tool im Browser einlädt — `answers.json` dient zur Inspektion und ist gleichwertig.

## Status

Reines Entwicklungstool. Nicht für Produktion, kein Build, kein Hosting nötig.

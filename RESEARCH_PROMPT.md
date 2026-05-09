# Deep-Research-Prompt: 60 neue Fragen für „Sophia"

> Kopiere den kompletten Block unter `--- BEGIN PROMPT ---` in dein Deep-Research-Tool. Das Output ist Dart-Code, den du direkt unten in `lib/data/seed/questions_seed.dart` einfügen kannst.

---

## Tipps zum Tool

- **Perplexity Deep Research** oder **OpenAI Deep Research** sind ideal — sie können Quellen prüfen.
- **Claude Research / Projects** mit aktivierter Web-Suche geht auch.
- Wenn das Tool eine Themen-/Tiefen-Slider hat: maximale Recherche-Tiefe, „akademisch / scholarly".
- Bei Output-Längen-Limits: einfach „weitere 30 Fragen, gleiches Format" nachschicken.

---

--- BEGIN PROMPT ---

# Aufgabe

Du bist ein Philosophie-Lehrer, der für ein deutschsprachiges Quiz-Spiel **60 neue, faktisch korrekte, gut recherchierte Quiz-Fragen** erstellt. Das Spiel heißt **Sophia** und richtet sich an Philosophie-Studierende. Output muss **kompilierbarer Dart-Code** sein.

## Stilrichtlinien

- **Sprache: Deutsch.** Auch Zitate werden in der gängigen deutschen Übersetzung wiedergegeben (lateinische Originalfloskeln wie „Cogito, ergo sum" oder „Sapere aude!" dürfen stehen bleiben).
- **Akademische Genauigkeit**: Belege jedes Zitat mit Werk und (idealerweise) Stellenangabe in `attribution`.
- **Bildende Erklärung** (`explanation`): 1–2 Sätze, die nicht nur die richtige Antwort wiederholen, sondern den philosophischen Hintergrund erhellen. Tonfall: warm, erwachsen, nicht herablassend.
- **Vier plausible Optionen pro Frage**. Falsche Optionen müssen *plausibel* sein — andere Philosophen ähnlicher Epoche oder verwandter Schule.
- **Schwierigkeit (`difficulty`)**: 1 (Anfänger:in) bis 5 (Master). Verteilung über die 60 Fragen ungefähr: 15× D1, 18× D2, 15× D3, 8× D4, 4× D5.

## Output-Format (sehr wichtig)

Liefere **eine einzige Dart-Liste** mit 60 `Question(...)`-Literalen. **Direkt einfügbar** ans Ende von `kQuestions` in `lib/data/seed/questions_seed.dart`. Keine Prosa, keine Markdown-Codeblöcke, keine Nummerierung — nur die Liste.

Beispiel-Eintrag (Format):

```dart
Question(
  id: 'q_quote_101',
  category: QuestionCategory.quoteToPhilosopher,
  prompt: '„Der Wille zur Macht."',
  options: ['Schopenhauer', 'Nietzsche', 'Heidegger', 'Kierkegaard'],
  correctIndex: 1,
  difficulty: 2,
  attribution: 'Aus dem Nachlass — postum hg. von Elisabeth Förster-Nietzsche',
  explanation:
      'Der Begriff durchzieht Nietzsches Spätwerk; das gleichnamige Buch ist allerdings keine autorisierte Schrift, sondern eine umstrittene Nachlasskompilation.',
  philosopherId: 'nietzsche',
  topicKey: 'wille_zur_macht',
),
```

## Field-Regeln

- `id`: eindeutig, kebab-style mit Kategorie-Präfix. **Beginne bei `q_quote_101`** und zähle hoch — bestehende IDs `q_quote_001..023`, `q_work_001..014`, `q_era_001..005`, `q_concept_001..007`, `q_complete_001..006`, `q_critique_001..005` dürfen nicht kollidieren.
- `category`: einer von:
  - `QuestionCategory.quoteToPhilosopher` — Zitat → Philosoph (~15 Fragen)
  - `QuestionCategory.workToAuthor` — Werk → Autor (~10)
  - `QuestionCategory.philosopherToEra` — Philosoph → Epoche (~8)
  - `QuestionCategory.conceptToSchool` — Begriff → Schule/Strömung (~10)
  - `QuestionCategory.completeQuote` — Lücke vervollständigen (~9)
  - `QuestionCategory.whoCriticizedWhom` — wer hat wen kritisiert/widerlegt (~8)
- `options`: Liste aus genau **4 Strings**. Reihenfolge frei — der Code mischt zur Laufzeit. `correctIndex` muss auf die korrekte Position zeigen.
- `attribution`: nur bei Zitaten (Quellen-Werk, ggf. Abschnitt). Bei `philosopherToEra` und `conceptToSchool` weglassen.
- `explanation`: **Pflicht** für jede Frage. Etwa 12–35 Wörter.
- `philosopherId`: **muss** zu einem Eintrag der unten gelisteten ID-Tabelle passen. Bei Fragen ohne klare Person-Zuordnung (z.B. eine reine Schul-Begriff-Frage) `null` lassen (Feld weglassen).
- `topicKey`: **optional, aber wichtig**. Setze denselben `topicKey` für Fragen, die einander beim Zufallsziehen verraten würden. Beispiele: zwei Fragen zum gleichen Zitat, eine Quote-Frage und ihr Complete-Pendant, eine Begriff-Frage und die Werk-Frage zum gleichen Buch. Snake-Case-String, sprechend (z.B. `wille_zur_macht`, `categorical_imperative_kant`).

## Erlaubte `philosopherId`-Werte

Antike & Spätantike:
`sokrates`, `platon`, `aristoteles`, `epikur`, `seneca`, `marcus_aurelius`

Mittelalter & Renaissance:
`augustinus`, `aquin`, `occam`, `machiavelli`

Aufklärung:
`descartes`, `spinoza`, `leibniz`, `locke`, `hume`, `rousseau`, `kant`

19. Jahrhundert:
`hegel`, `schopenhauer`, `kierkegaard`, `marx`, `mill`, `nietzsche`

Moderne / Postmoderne:
`freud`, `wittgenstein`, `heidegger`, `arendt`, `sartre`, `beauvoir`, `camus`, `foucault`, `derrida`, `adorno`, `benjamin`, `popper`, `rawls`

Zeitgenössisch:
`habermas`, `butler`, `singer`, `nussbaum`

> **Wichtig**: Wenn du einen Philosophen brauchst, der nicht in dieser Liste steht (z.B. Levinas, Bergson, Cassirer, Bourdieu, Frege, Russell, Quine, Putnam, Davidson, Anscombe, Korsgaard, Honneth, Han, Sloterdijk, MacIntyre, Sandel, Walzer, Taylor, Apel, Gadamer, Lévi-Strauss, Lacan, Lyotard, Deleuze, Žižek, Agamben, Latour, Boethius, Maimonides, Erasmus, Bacon, Pascal, Berkeley, Schelling, Fichte, Feuerbach, Stirner, Bentham, Tugendhat, Plessner, Ricœur, Cavell, Bloch, Marcuse, Horkheimer, Fromm, Husserl, Brentano, Hartmann, Jaspers, Plotin, Diogenes, Heraklit, Parmenides, Anaxagoras, Empedokles, Demokrit, Pythagoras, Zenon, Plotin, Cicero, Boethius, Dilthey, Rorty, Searle, Strawson, Nagel, Kripke, Frankfurt, Williams, Dworkin, Korsgaard, Foot, Murdoch, Hadot, Ricœur, Rancière, Hooks, Spivak), dann **lasse `philosopherId` weg** und bilde die Frage trotzdem korrekt — wir tragen den Philosophen später nach.

## Themenmischung

Nicht nur westlicher Kanon. Achte besonders auf:
- **Frauen-Philosophinnen**: nicht nur Arendt/Beauvoir/Butler, sondern auch Hypatia (Antike), Astell, Wollstonecraft, Conway, Élisabeth von der Pfalz, Stein, Weil, Murdoch, Anscombe, Foot, Korsgaard. (Falls jemand davon nicht in der erlaubten Liste ist: ohne `philosopherId`.)
- **Nicht-westliche Stimmen** dürfen vorkommen, müssen aber sehr klar gekennzeichnet sein (Konfuzius, Laozi, Nāgārjuna, Avicenna, Averroes, Maimonides, Al-Ghazali). Wieder: ohne `philosopherId`, falls nicht in der Liste.
- **20.-/21.-Jahrhundert-Strömungen**: analytische Philosophie (Sprach-/Geist-Philosophie), Pragmatismus, Phänomenologie, Hermeneutik, Strukturalismus/Poststrukturalismus, Frankfurter Schule, Critical Theory, Bioethik, Tierethik, Umweltethik, KI-/Tech-Ethik.

## Anti-Spoiler-Pärchen

Vermeide es, zwei Fragen zu *demselben* Zitat oder Werk zu produzieren, ohne sie mit identischem `topicKey` zu verbinden. Vergib `topicKey` aktiv — lieber zu viele als zu wenige.

Beispiele bestehender Topic-Keys (nicht überschreiben):
`cogito`, `sapere_aude`, `sartre_existenzialismus`, `tractatus`, `heidegger_dasein`, `marx_kritik`.

Neue topicKeys denkbar z.B. für:
`wille_zur_macht`, `kategorischer_imperativ`, `tabula_rasa`, `naturzustand_hobbes`, `eternal_return`, `okhams_razor`, `mensch_als_ende`, `prinzip_des_zureichenden_grundes`, `naturalistic_fallacy`, `verdacht_des_ressentiments`, `dialektik_der_aufklaerung`, ...

## Beispielfragen pro Kategorie (zur Orientierung — NICHT in der Antwort wiederholen)

```dart
// quoteToPhilosopher
Question(id: 'q_quote_101', category: QuestionCategory.quoteToPhilosopher,
  prompt: '„Wer einen Abgrund zu lange anschaut, in den schaut auch der Abgrund hinein."',
  options: ['Kafka', 'Nietzsche', 'Dostojewski', 'Kierkegaard'],
  correctIndex: 1, difficulty: 2,
  attribution: 'Jenseits von Gut und Böse, Aphorismus 146',
  explanation: 'Nietzsches Bild für die Gefahr, sich beim Kampf gegen das Böse selbst zu verformen.',
  philosopherId: 'nietzsche'),

// workToAuthor
Question(id: 'q_work_101', category: QuestionCategory.workToAuthor,
  prompt: '„Negative Dialektik"',
  options: ['Adorno', 'Horkheimer', 'Marcuse', 'Habermas'],
  correctIndex: 0, difficulty: 3,
  explanation: 'Adornos Spätwerk (1966) — Versuch, das Nicht-Identische gegen die identifizierende Vernunft zu retten.',
  philosopherId: 'adorno'),

// philosopherToEra
Question(id: 'q_era_101', category: QuestionCategory.philosopherToEra,
  prompt: 'Foucault',
  options: ['Aufklärung', '19. Jahrhundert', 'Moderne / Postmoderne', 'Zeitgenössisch'],
  correctIndex: 2, difficulty: 1,
  explanation: 'Michel Foucault (1926–1984) — zentrale Figur des französischen Poststrukturalismus.',
  philosopherId: 'foucault'),

// conceptToSchool
Question(id: 'q_concept_101', category: QuestionCategory.conceptToSchool,
  prompt: 'Hermeneutischer Zirkel',
  options: ['Phänomenologie', 'Hermeneutik', 'Strukturalismus', 'Pragmatismus'],
  correctIndex: 1, difficulty: 2,
  explanation: 'Der Begriff für das wechselseitige Verstehen von Teil und Ganzem ist Kerngedanke der Hermeneutik (Schleiermacher, Dilthey, Gadamer).'),

// completeQuote
Question(id: 'q_complete_101', category: QuestionCategory.completeQuote,
  prompt: '„Wir können den Wind nicht ändern, aber …"',
  options: ['…wir können warten.', '…die Segel anders setzen.', '…den Hafen wechseln.', '…den Kurs halten.'],
  correctIndex: 1, difficulty: 2,
  attribution: 'Aristoteles zugeschrieben (apokryph)',
  explanation: 'Eine im Stoizismus rezipierte Maxime — die Trennung des Beeinflussbaren vom Nicht-Beeinflussbaren.'),

// whoCriticizedWhom
Question(id: 'q_critique_101', category: QuestionCategory.whoCriticizedWhom,
  prompt: 'Wer kritisierte Sartres frühen Existenzialismus aus marxistisch-strukturalistischer Sicht?',
  options: ['Camus', 'Lévi-Strauss', 'Foucault', 'Merleau-Ponty'],
  correctIndex: 1, difficulty: 4,
  explanation: 'Lévi-Strauss\' „Das wilde Denken" (1962) endet mit einer scharfen Polemik gegen Sartres geschichtsphilosophische Ansprüche.'),
```

## Letzter Hinweis

Liefere **nur die 60 Fragen-Literale**, getrennt durch Kommas. Kein Kommentar, kein Markdown, keine erklärende Prosa drumherum. Eine pseudo-leere Liste der Form `[Question(...), Question(...), ...]` reicht — keine `kQuestions =`-Zuweisung, kein abschließendes Semikolon.

--- END PROMPT ---

---

## Nach dem Research

1. Output ist eine Liste von `Question(...)` getrennt durch Kommas.
2. Öffne `lib/data/seed/questions_seed.dart`.
3. Suche das Zeilenende `];` am Schluss von `kQuestions`.
4. Füge die neuen Einträge **vor** dem `];` ein, mit Komma davor.
5. Speichere — Flutter-Hot-Reload (`r` im Terminal) zieht die neuen Fragen automatisch.

Falls das Tool an einer Stelle Halluziniert (falsches Werk, falsches Datum), markiere die betroffene Frage und schick sie nochmal mit „Quelle bitte angeben" durch ein zweites Tool. Faktencheck > schiere Menge.

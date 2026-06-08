# Deep-Research-Prompt: ausgewogene Fragen-Erweiterung fuer Griphos

Kopiere den kompletten Block unter `--- BEGIN PROMPT ---` in dein Deep-Research-Tool. Das Ziel ist eine neue Fragencharge, die den aktuellen stark maennlich gepraegten Kanon ausgleicht und zugleich faktenfest bleibt.

## Aktueller Stand im Projekt

- Aktuelle Seed-Fragen: 109.
- Aktuell per `philosopherId` stark vertreten: Kant (8), Nietzsche (6), Wittgenstein (6), Heidegger/Butler/Descartes/Sartre (je 4).
- Aktuell explizit weiblich/nicht-maennlich vertreten: Arendt, Beauvoir, Butler, Nussbaum sowie ohne `philosopherId` Hypatia, Mary Wollstonecraft und Elisabeth von der Pfalz.
- Ziel der naechsten Runde: Frauen und nicht-maennliche Philosoph:innen deutlich aufholen lassen, ohne reine Token-Fragen zu produzieren.

## Empfohlenes Tool-Setup

- Perplexity Deep Research, OpenAI Deep Research oder ein vergleichbares Tool mit Web-Suche nutzen.
- Recherche-Tiefe: maximal / scholarly / academic.
- Wenn Output-Limits greifen: erst 40 Fragen generieren lassen, danach mit „weitere 40, gleiche Regeln" fortsetzen.

--- BEGIN PROMPT ---

# Aufgabe

Du bist ein Philosophie-Lehrer und erstellst fuer ein deutschsprachiges Quiz-Spiel namens **Griphos** gut recherchierte neue Philosophiefragen. Das Spiel hat bereits viele Fragen zu maennlichen kanonischen Philosophen. Deine Aufgabe ist, die Datenbasis in Richtung **ungefaehr ausgeglichener Sichtbarkeit von maennlichen und weiblichen/nicht-maennlichen Philosoph:innen** zu erweitern.

Erstelle **80 neue, faktisch korrekte, quellenstarke Quiz-Fragen** als direkt kompilierbaren Dart-Code.

## Prioritaet: Balance

Von den 80 Fragen muessen mindestens **50 Fragen** eine Philosophin oder nicht-maennliche Person als richtige Antwort, zentrales Thema oder Hauptbezug haben.

Besonders gewuenschte Zielpersonen:

- Antike / Spaetantike: Hypatia, Diotima (als literarisch-philosophische Figur klar kennzeichnen), Aesara von Lucania, Makrina die Juengere.
- Mittelalter / Renaissance: Hildegard von Bingen, Christine de Pizan, Tullia d'Aragona.
- Fruehe Neuzeit / Aufklaerung: Elisabeth von der Pfalz, Margaret Cavendish, Anne Conway, Damaris Cudworth Masham, Mary Astell, Emilie du Chatelet, Olympe de Gouges, Mary Wollstonecraft.
- 19. Jahrhundert: Harriet Taylor Mill, Harriet Martineau, Anna Julia Cooper.
- 20. Jahrhundert: Edith Stein, Simone Weil, Susanne Langer, Elizabeth Anscombe, Philippa Foot, Iris Murdoch, Hannah Arendt, Simone de Beauvoir, Angela Davis, bell hooks, Gayatri Chakravorty Spivak, Donna Haraway, Luce Irigaray, Julia Kristeva, Nancy Fraser.
- Gegenwart: Judith Butler, Martha Nussbaum, Christine Korsgaard, Onora O'Neill, Seyla Benhabib, Susan Haack, Sally Haslanger, Miranda Fricker, Rahel Jaeggi, Chantal Mouffe.

Zusaetzlich sollen mindestens **12 Fragen** nicht-westliche Philosophie oder transkulturelle Rezeption abdecken: Konfuzius, Laozi, Zhuangzi, Mengzi/Mencius, Mozi, Xunzi, Nagarjuna, Vasubandhu, Shankara, Avicenna/Ibn Sina, Averroes/Ibn Rushd, Maimonides, Al-Ghazali, Wang Yangming, Nishida Kitaro.

Vermeide, die naechste Charge wieder mit Kant, Nietzsche, Heidegger, Wittgenstein, Sartre, Rawls oder Popper zu fuellen. Diese Namen duerfen als falsche Optionen vorkommen, aber hoechstens 8 der 80 Fragen sollen sie als Hauptbezug haben.

## Sprache und Stil

- Sprache: Deutsch.
- Zitate: etablierte deutsche Uebersetzung verwenden; bei Unsicherheit lieber Werk-/Begriffsfragen statt zweifelhafter Zitate.
- Jede Frage braucht vier plausible Antwortoptionen.
- Falsche Optionen muessen plausibel sein: gleiche Epoche, gleiche Debatte, verwandte Schule.
- `explanation`: 1-2 Saetze, warm, praezise, bildend, nicht herablassend.
- `attribution`: bei Zitaten immer Werk und moeglichst Abschnitt/Kapitel/Paragraph angeben. Keine erfundenen Stellenangaben.
- Schwierigkeit `difficulty`: 1 bis 5. Zielverteilung: ca. 18x D1, 24x D2, 22x D3, 12x D4, 4x D5.

## Output-Format

Liefere **eine einzige Dart-Liste** mit 80 `Question(...)`-Literalen. Direkt einfuegbar ans Ende von `kQuestions` in `lib/data/seed/questions_seed.dart`.

Keine Markdown-Codebloecke, keine Prosa, keine Nummerierung. Nur:

[
  Question(...),
  Question(...),
]

Kein `kQuestions =`, kein Semikolon.

## Dart-Format

Beispiel:

Question(
  id: 'q_quote_201',
  category: QuestionCategory.quoteToPhilosopher,
  prompt: '„Ich wuensche nicht, dass Frauen Macht ueber Maenner haben, sondern ueber sich selbst."',
  options: ['Mary Astell', 'Mary Wollstonecraft', 'Harriet Taylor Mill', 'Olympe de Gouges'],
  correctIndex: 1,
  difficulty: 3,
  attribution: 'Mary Wollstonecraft, A Vindication of the Rights of Woman, Kap. 4',
  explanation:
      'Wollstonecraft fordert keine Umkehrung der Herrschaft, sondern Selbstregierung durch Bildung und Vernunft. Genau darin liegt die politische Pointe ihres fruehen Feminismus.',
  topicKey: 'wollstonecraft_self_government',
),

## ID-Regeln

Die Datei enthaelt bereits IDs bis etwa:

- `q_quote_115`
- `q_work_109`
- `q_era_108`
- `q_concept_109`
- `q_complete_109`
- `q_critique_108`

Starte neue IDs daher bei:

- `q_quote_201`
- `q_work_201`
- `q_era_201`
- `q_concept_201`
- `q_complete_201`
- `q_critique_201`

Keine bestehenden IDs wiederverwenden.

## Kategorien und Mengen

Erzeuge ungefaehr:

- 20x `QuestionCategory.quoteToPhilosopher`
- 14x `QuestionCategory.workToAuthor`
- 10x `QuestionCategory.philosopherToEra`
- 14x `QuestionCategory.conceptToSchool`
- 10x `QuestionCategory.completeQuote`
- 12x `QuestionCategory.whoCriticizedWhom`

## Erlaubte `philosopherId`-Werte

Setze `philosopherId` nur, wenn die Person in dieser Liste vorkommt:

`sokrates`, `platon`, `aristoteles`, `epikur`, `seneca`, `marcus_aurelius`, `augustinus`, `aquin`, `occam`, `machiavelli`, `descartes`, `spinoza`, `leibniz`, `locke`, `hume`, `rousseau`, `kant`, `hegel`, `schopenhauer`, `kierkegaard`, `marx`, `mill`, `nietzsche`, `freud`, `wittgenstein`, `heidegger`, `arendt`, `sartre`, `beauvoir`, `camus`, `foucault`, `derrida`, `habermas`, `rawls`, `butler`, `singer`, `nussbaum`, `adorno`, `benjamin`, `popper`.

Wenn die richtige Antwort oder Hauptperson nicht in dieser Liste steht, lasse `philosopherId` komplett weg. Nicht `null` schreiben.

## Vorhandene topicKeys vermeiden

Nutze neue sprechende `topicKey`s und vermeide diese vorhandenen Keys:

`adorno_wrong_life`, `aristotle_political_animal`, `augustine_restless_heart`, `avicenna_era`, `beauvoir_second_sex`, `butler_gender_performativity`, `camus_suicide`, `cogito`, `confucius_learning`, `confucius_self_discipline`, `dao_ineffable`, `daoist_wu_wei`, `derrida_differance`, `descartes_good_head`, `elisabeth_descartes_interaction`, `epoche_phenomenology`, `hegel_kant_formalism`, `heidegger_dasein`, `heidegger_language_house`, `hobbes_leviathan`, `hume_reason_passions`, `hypatia_era`, `kant_humanity_formula`, `kant_starry_sky`, `levi_strauss_vs_sartre`, `madhyamaka_nagarjuna`, `marcus_aurelius_era`, `marx_kritik`, `marx_praxis`, `mill_liberty`, `nietzsche_socrates_tragedy`, `nussbaum_era`, `popper_open_society`, `rawls_theory_of_justice`, `sapere_aude`, `sartre_existenzialismus`, `schopenhauer_gegen_hegel`, `seneca_dare_difficult`, `social_contract_rousseau`, `spinoza_free_man_death`, `tractatus`, `utilitarian_principle`, `wittgenstein_language_games`, `wollstonecraft_rights_of_woman`.

Wenn zwei neue Fragen dasselbe Werk, Zitat oder dieselbe Debatte beruehren, gib ihnen denselben neuen `topicKey`, damit die App sie nicht direkt gegeneinander ausspielt.

## Qualitaetsregeln

- Keine apokryphen oder zweifelhaften Zitate, ausser sie werden klar als zugeschrieben/apokryph markiert. Lieber vermeiden.
- Keine reinen Trivia-Fragen ohne philosophischen Gehalt.
- Keine Fragen, deren falsche Optionen offensichtlich absurd sind.
- Keine Wiederholungen bestehender Fragen zu Cogito, Sapere aude, Tractatus, Sein und Zeit, Social Contract, Zweite Geschlecht, Gender Trouble, Rawls' Theory of Justice, Daodejing Kap. 1, Mary Wollstonecrafts Selbstregierung-Zitat.
- Bei historischen Frauen nicht nur Biografie abfragen, sondern Werke, Argumente, Kritiken und Begriffe.
- Bei nicht-westlicher Philosophie keine exotisierende Sprache; Schulen und Begriffe sachlich einordnen.

## Endkontrolle vor Ausgabe

Pruefe vor der finalen Antwort:

1. Genau 80 `Question(...)`-Eintraege.
2. Mindestens 50 Fragen mit Philosophinnen/nicht-maennlichen Hauptbezug.
3. Mindestens 12 Fragen zu nicht-westlicher oder transkultureller Philosophie.
4. Jede Frage hat genau 4 Optionen und einen korrekten `correctIndex` von 0 bis 3.
5. Jede Frage hat eine `explanation`.
6. Zitatfragen haben `attribution`.
7. Keine ID-Kollisionen mit bestehenden IDs.
8. `philosopherId` nur aus der erlaubten Liste.

--- END PROMPT ---

## Nach dem Research

1. Output in `lib/data/seed/questions_seed.dart` vor dem abschliessenden `];` einfuegen.
2. `flutter test` laufen lassen.
3. Stichprobenartig 10-15 Fragen faktenchecken, besonders Zitate und Werkzuordnungen.
4. Neue haeufig auftretende Personen spaeter in `philosophers_seed.dart` aufnehmen und passende Bilder aus `IMAGE_PROMPTS.md` erzeugen.

# Bilder für Griphos

Dies ist die Liste aller Bilder, die für die App generiert werden müssen. Das Designkonzept ist **Warm Academia** — Pergament, Burgunder, Antik-Gold, weiches Licht.

## Globaler Stil-Prompt (für jedes Bild anhängen)

> *„… in the style of a soft, warm, painterly portrait. Aged parchment background (#F5EFE6). Muted burgundy and antique gold accents. Hand-drawn ink linework with watercolor wash. No photographic realism — gentle illustrative quality. Square crop, centered subject, even soft lighting. Slight grain texture. Avoid harsh shadows or modern colors."*

Format: **PNG oder WebP, 1024×1024 px**, transparent oder pergament-cremefarbener Hintergrund.

---

## App-Icon

**Datei:** `assets/icons/app_icon.png`

> *„An ornate wax seal stamped onto warm parchment. The seal shows the Greek letter Σ (Sigma), embossed in deep burgundy with a subtle antique-gold rim. Soft drop shadow. The seal sits centered on the parchment with no other elements. Painterly, illustrative, no photorealism. Warm, scholarly atmosphere."*

> Alternativ: ein offenes altes Buch, ein Gänsekiel, oder eine stilisierte Eule (Athene-Symbol).

Größen: iOS verlangt zusätzlich `20×20` bis `1024×1024` — Codemagic generiert die Größen automatisch aus dem 1024er.

---

## Splash-Screen

**Datei:** `assets/images/splash.png` (1242×2688 px)

> *„A vertical illustration: a single wax seal with the letter Σ glowing softly in the center of cream-colored parchment paper. Subtle paper texture. Below it, very faint hand-drawn ink ornaments and a thin gold rule. Mostly empty space — the seal is the focal point. Warm, contemplative, no people."*

---

## Spielmodus-Bilder und Icons

**Dateien:** `assets/images/modes/*.webp` und `assets/icons/modes/*.webp`

Alle neuen Mode-Assets folgen dem globalen Warm-Academia-Stil: weiche watercolor-and-ink Illustration, Pergamentgrund, Burgunder, Antik-Gold, ruhiges Licht, kein Text.

| Modus | Bildmotiv | Iconmotiv |
|---|---|---|
| Quiz-Rush | Stunde, Stoppuhr, Notizen und dezente Timer-Kreisform | Stundenglas + Stoppuhr im Pergament-Medaillon |
| Klassik | Antiker Studienplatz mit Säule, Schriftrolle, Lorbeer und Stylus | Schriftrolle + Säulenkapitell + Lorbeer |
| Duell | Gekreuzte Schreibfedern, Waage und Lorbeer als fairer Wettbewerb | Gekreuzte Schreibfedern + Waage |
| Kreuzworträtsel | Frau am Schreibtisch beim Lösen eines Kreuzworträtsels | Kreuzworträtselraster + Schreibfeder + Schreibtischlampe |

---

## Basis-Philosoph:innen-Porträts (Stil-Referenz, 40 historische Erstgenerationen)

Alle in den Ordner `assets/images/philosophers/` legen. Dateiname = `id` aus `philosophers_seed.dart` mit Endung `.webp` (oder `.png`).

Status: Diese 40 Basisbilder sind im Asset-Ordner vorhanden und dienen als **Stil-Anker** für alle weiteren Porträts. Ab 2026-05-19 sind alle weiteren im Seed enthaltenen Philosoph:innen ebenfalls erzeugt — siehe Lückenstand-Sektion unten für die einzige verbliebene Pflicht-Lücke.

**Stil-Hinweis pro Porträt:**
> *„Half-length portrait of {NAME}, the {SCHOOL} philosopher who lived {YEARS}. Three-quarter view, contemplative gaze, subtle smile or serious thoughtful expression. Period-appropriate clothing. Soft warm lighting from the upper left. Aged parchment background with very faint architectural or symbolic motifs (e.g. columns, scrolls, an open book). Painterly watercolor-and-ink style, muted earth tones with hints of burgundy and antique gold. Centered composition, square 1024×1024. Avoid photorealism — keep an illustrated, scholarly book-cover quality."*

### Liste

| Datei | Subjekt | Hint |
|---|---|---|
| `sokrates.webp` | Sokrates | bald older Greek man, snub nose, robe, bare feet |
| `platon.webp` | Platon | broad-shouldered Greek, flowing white robe, scroll in hand |
| `aristoteles.webp` | Aristoteles | Greek scholar with neatly trimmed beard, holding a stylus and tablet |
| `epikur.webp` | Epikur | gentle smile, short beard, simple Greek tunic, garden in background |
| `seneca.webp` | Seneca | older Roman, balding, wearing toga, parchment scroll |
| `marcus_aurelius.webp` | Marcus Aurelius | Roman emperor in armor with philosopher's contemplation, beard |
| `augustinus.webp` | Augustinus | medieval bishop's robe, mitre or simple cloak, holding a book |
| `aquin.webp` | Thomas von Aquin | white Dominican habit with black mantle, tonsure, plump scholarly figure |
| `occam.webp` | Wilhelm von Ockham | Franciscan brown robe with rope belt, tonsure, sharp gaze |
| `machiavelli.webp` | Machiavelli | Renaissance Florentine, dark cap, sharp smile, fur-collared robe |
| `descartes.webp` | René Descartes | long dark wavy hair, lace collar, 17th-century French nobleman attire |
| `spinoza.webp` | Spinoza | dark long hair, white shirt, lens-grinder's modest dress, gentle eyes |
| `leibniz.webp` | Leibniz | flowing baroque wig, rich coat, holding compasses or papers |
| `locke.webp` | John Locke | long wig of the period, modest dark coat, contemplative |
| `hume.webp` | David Hume | round face, plump, period Scottish/English coat, friendly skeptical look |
| `rousseau.webp` | Rousseau | fur cap or hat, thoughtful melancholy, leaning on a tree or by water |
| `kant.webp` | Immanuel Kant | small thin frame, neat 18th c. attire, glasses, sharp eyes |
| `hegel.webp` | Hegel | tall forehead, stiff white collar, Romantic-era dark coat, serious |
| `schopenhauer.webp` | Schopenhauer | white wild hair on the sides, bald top, intense gaze, dark cravat |
| `kierkegaard.webp` | Kierkegaard | tousled hair, large forehead, melancholy tilt of head, dark coat |
| `marx.webp` | Karl Marx | thick bushy beard, full hair, 19th-century suit, intense eyes |
| `mill.webp` | John Stuart Mill | tall forehead, sideburns, Victorian dress, kind expression |
| `nietzsche.webp` | Nietzsche | iconic bushy moustache, deep-set eyes, dark suit, intense look |
| `freud.webp` | Sigmund Freud | beard, glasses, dark suit, holding a cigar, slight smile |
| `wittgenstein.webp` | Wittgenstein | high cheekbones, intense eyes, simple jacket, 20th-century |
| `heidegger.webp` | Heidegger | small moustache, traditional Black Forest jacket, mountain background hint |
| `arendt.webp` | Hannah Arendt | dark hair pinned back, cigarette in hand, mid-century blouse, thoughtful |
| `sartre.webp` | Sartre | strabismus (one eye slightly off), short hair, pipe, mid-century French intellectual look |
| `beauvoir.webp` | Beauvoir | dark hair in a twist, turtleneck or simple blouse, sharp gaze |
| `camus.webp` | Albert Camus | dark hair, melancholic gaze, cigarette, trench coat, looks like a 1950s film noir hero |
| `foucault.webp` | Foucault | bald head, glasses, slight smile, turtleneck |
| `derrida.webp` | Derrida | white hair, intense expression, contemporary academic dress |
| `habermas.webp` | Habermas | white hair, glasses, gentle face, blazer |
| `rawls.webp` | John Rawls | gray hair, glasses, kind face, simple sweater or blazer |
| `butler.webp` | Judith Butler | short curly hair, contemporary, contemplative neutral expression |
| `singer.webp` | Peter Singer | warm smile, glasses, casual contemporary dress |
| `nussbaum.webp` | Martha Nussbaum | shoulder-length hair, gentle confident smile, modern professional dress |
| `adorno.webp` | Adorno | balding, glasses, suit and tie, mid-20th century German intellectual |
| `benjamin.webp` | Walter Benjamin | round glasses, dark moustache, contemplative, 1930s suit |
| `popper.webp` | Karl Popper | white hair, kind eyes, glasses, mid-20th century academic dress |

---

## Aktueller Seed-Lückenstand (Stand 2026-05-21)

Cross-Check zwischen [`lib/data/seed/philosophers_seed.dart`](lib/data/seed/philosophers_seed.dart) (79 Einträge) und [`assets/images/philosophers/`](assets/images/philosophers/) zeigt **eine** echte Pflicht-Lücke: Tullia d'Aragona ist im Seed referenziert, aber die Bild-Datei fehlt.

Frühere FEHLT-Sektionen (Stand 2026-05-19 sowie die Tabellen unter „Fehlende Porträts für Fragen- und Balance-Erweiterung") sind durch die zwischenzeitlich erfolgten Codex-Generationen abgearbeitet — siehe die niedrig-priore Liste unten für die noch offenen Optionsnamen.

**Dateinamen folgen exakt der `imageAsset`-Angabe im Seed — nicht umbenennen.**

**Generierungs-Regel**: pro Eintrag **eine** Bild-Anfrage. Niemals Batch / Multi-Image-Calls — bei größeren Schwüngen kommt es zu Stream-Abbrüchen. Workflow für Codex siehe „Codex IMAGEGEN — einzeln" weiter unten.

---

### 1. `assets/images/philosophers/tullia.webp` — Tullia d'Aragona

> *„Half-length portrait of Tullia d'Aragona, 16th-century Italian Renaissance poet and dialogue-author of love philosophy (ca. 1510–1556). Three-quarter view, composed intelligent gaze with a faint Renaissance smile, elegant Italian cinquecento dress in deep burgundy bodice over cream undergarments with antique-gold embroidery, hair styled in soft waves with a thin pearl band. A small open dialogue manuscript and a quill on a writing slope beside her, faint background of a Roman or Florentine humanist studiolo with a hint of a marble window arch. Soft warm lighting from the upper left. Aged parchment background (#F5EFE6) with burgundy and antique-gold accents. Painterly watercolor-and-ink style, muted earth tones, no photorealism — illustrated scholarly book-cover quality. Square 1024×1024, centered."*

---

## Codex IMAGEGEN — einzeln, niemals Batch

**Warum einzeln**: Multi-Image-Calls neigen bei Codex zu Stream-Abbrüchen mitten in der Antwort. Die Folge sind halbfertige Dateien und ein verworrener History-State. Eine Bild-Anfrage = eine Codex-Runde.

### Workflow pro Bild

1. **Codex-Panel in VSCode öffnen** (`Strg+Shift+P` → „Codex: Open Chat" o. ä.).
2. **Eine** Anfrage absetzen, Formulierung etwa:

   > „Bitte generiere ein einzelnes Bild für Griphos mit der Image-Gen-Funktion (IMAGEGEN). Output-Pfad: `assets/images/philosophers/<id>.webp`. Format: 1024×1024 WebP. Hier ist der Prompt: <kompletter Prompt-Block aus diesem Dokument einkopieren>. **Erzeuge nur dieses eine Bild. Keine weiteren Anfragen, keine Variationen.** Bestätige danach mit ✓."

3. **Warten bis fertig** und das WebP an der erwarteten Stelle liegt. `git status` zeigt eine neue Datei.
4. Erst dann zum nächsten Eintrag aus der Liste oben weitergehen — Schritt 2 mit dem nächsten Prompt-Block wiederholen.

### Sanity-Check zwischendurch

Nach 5–6 generierten Bildern App lokal starten und zur Frage-Erklärung navigieren, in der ein Philosoph mit neuem Bild als Antwort vorkommt — so siehst du, ob die Stil-Konsistenz mit den 40 Bestands-Porträts hält. Falls ein Bild aus der Reihe tanzt (Photorealismus, falsche Epoche), neu generieren mit dem expliziten Hinweis „match the style of the existing 40 philosopher portraits — watercolor-and-ink, parchment background, no photorealism".

### Reihenfolge-Empfehlung

Antike → Mittelalter → Aufklärung → 19. Jh. → Moderne → Zeitgenössisch — also #1 → #19 wie oben gelistet. So bleibt die Stil-Iteration mental konsistent (eine Epoche „im Kopf" zu behalten ist leichter).

### Wenn ein Bild misslingt

Komplett neu erzeugen. Nicht versuchen, ein schiefes Bild mit „mach das jetzt besser" zu reparieren — die Generator-Konsistenz leidet. Statt dessen: ggf. dem Prompt einen Negativ-Hinweis hinzufügen („avoid modern photographic look", „avoid neon colors", „avoid cartoonish features") und neu starten.

---

## Fehlende Optionsnamen, niedrige Priorität

Diese Personen kommen aktuell als Antwortoptionen, Co-Autor:innen oder plausible Distraktoren vor, sind aber **nicht** im `philosophers_seed.dart`. Bilder sind erst nötig, wenn sie als eigene Philosoph:innen ins Seed aufgenommen werden — bis dahin reine Wunschliste.

**Prompt-Schema für diese Porträts:**
> *„Half-length portrait of {NAME}, the {SCHOOL_OR_CONTEXT} thinker who lived {YEARS}. Three-quarter view, contemplative gaze, period-appropriate clothing, subtle historical context in the background without text. Soft warm lighting from the upper left. Aged parchment background with very faint symbolic motifs. Painterly watercolor-and-ink style, muted earth tones with hints of burgundy and antique gold. Centered square 1024×1024 composition. Avoid photorealism — keep an illustrated, scholarly book-cover quality."*

| Datei | Status | Subjekt |
|---|---|---|
| `russell.webp` | FEHLT | Bertrand Russell |
| `sandel.webp` | FEHLT | Michael Sandel |
| `schelling.webp` | FEHLT | Friedrich Schelling |
| `schleiermacher.webp` | FEHLT | Friedrich Schleiermacher |
| `searle.webp` | FEHLT | John Searle |
| `sen.webp` | FEHLT | Amartya Sen |
| `shaftesbury.webp` | FEHLT | Shaftesbury |
| `sidgwick.webp` | FEHLT | Henry Sidgwick |
| `stirner.webp` | FEHLT | Max Stirner |
| `tocqueville.webp` | FEHLT | Alexis de Tocqueville |
| `trendelenburg.webp` | FEHLT | Friedrich Adolf Trendelenburg |
| `voltaire.webp` | FEHLT | Voltaire |
| `walzer.webp` | FEHLT | Michael Walzer |
| `wilhelm_von_humboldt.webp` | FEHLT | Wilhelm von Humboldt |
| `zenon_von_kition.webp` | FEHLT | Zenon von Kition |

---

## Achievement-Icons

**Zielordner:** `assets/icons/achievements/`
**Format:** WebP oder PNG, 1024×1024 px, runder Medaillon-Aufbau, Pergament-Hintergrund mit cremefarbenem Rand.

Visuelle Vorlage: die Mode-Icons unter `assets/icons/modes/` — kreisförmiges Medaillon mit feinem Doppelrand (innen schmal, außen breiter), zentriertes Motiv aus 1–3 handgemalten Objekten, Lorbeerblättchen oder Schnörkel als Filler, warmes erdiges Licht.

### Farb-Richtung — *gesättigter als die Mode-Icons*

Tester-Feedback war, dass die App insgesamt zu farbarm wirkt. Die Achievements sind der natürliche Ort, um Farbe einzuführen — sie sind Belohnungen, sollen also herausstechen, ohne den Warm-Academia-Look zu brechen.

Grundregel: **Pergament + Goldring bleiben** (Identität), aber das **zentrale Motiv darf richtig farbig sein**. Wir greifen die existierende Tertiär-Palette aus der App auf:

| Token | Hex | Anwendung im Motiv |
|---|---|---|
| `sage` | `#7A8B6F` | Lorbeer, Olivenzweige, Evergreen, ruhige Naturtöne |
| `terracotta` | `#C97B4A` | Feuer, Phönix, Lampenglühen, Wärme |
| `dustyTeal` | `#4F7E80` | Nachthimmel, Wasser, Wind, Bewegung |
| `plum` | `#7B4C68` | Dämmerung, Bändchen, Würde, Disput |
| `mustard` | `#B89248` | Sonne, Messing, klassisches Gold |
| `burgundy` | `#6B2737` | Wachssiegel, Lederbände, Schwerpunkt-Akzente |

Jede Errungenschaft hat eine **eigene Farb-Signatur** (2 Hauptfarben + 1 Akzent), siehe pro Eintrag. So entsteht Wiedererkennung pro Achievement und gleichzeitig Vielfalt über die Galerie hinweg.

### Stil-Suffix (an jeden Prompt anhängen)

> *„… rendered as a circular medallion icon in warm-academia style. Cream parchment background (#F5EFE6) with a subtle double rim — narrow inner line in muted burgundy (#6B2737), thicker outer ring in antique gold (#C9A961). Centered composition, 1024×1024 square, the medallion fills most of the frame. Hand-drawn ink linework with rich watercolor wash — the central motif is meaningfully saturated and colorful, not muted, while the rim and supporting flourishes stay in the warm parchment / burgundy / gold register. Soft warm lighting from upper left, very faint paper grain. No text, no letters, no numbers anywhere in the image. Painterly, illustrative, scholarly book-plate quality with the boldness of an illuminated manuscript. Avoid photorealism, neon or modern fluorescent colors, harsh black shadows."*

### Tier-Differenzierung — *am Rahmen, nicht im Motiv*

Damit das Motiv farblich konsistent über alle drei Stufen bleibt, wird der **Tier-Unterschied an Rahmen und Ehrenwerk** ausgespielt, nicht in der Hauptfarbpalette. Konkret:

- **Bronze** — Inner-Rim-Linie in `#A97142`, einfacher Lorbeerzweig unten, kein zusätzlicher Schmuck im Hintergrund.
- **Silber** — Inner-Rim in `#C2BBA8`, halber Lorbeerkranz, ein dezenter Strahlenfächer hinter dem Motiv.
- **Gold** — Inner-Rim in `#D4A24C`, geschlossener Lorbeerkranz mit Bändchen, voller Strahlenkranz, evtl. zwei kleine Sterne oder Schnörkel.

Das Motiv selbst wird pro Stufe **inhaltlich reicher**, behält aber seine Farb-Signatur. Bronze ≠ entsättigte Version von Gold — alle drei sind voll farbig, nur eben mit anderem Detailgrad.

### Dateinamen-Konvention

- Einstufige Errungenschaft: `<id>.webp` (z. B. `first_steps.webp`)
- Mehrstufig: `<id>_<tier>.webp` (z. B. `correct_answers_bronze.webp`)

Die IDs stammen 1:1 aus `lib/data/models/achievement.dart`.

---

### 1. `first_steps.webp` — Erste Schritte *(einstufig)*

**Farbsignatur:** burgundy + mustard + warm cream

> *„An open, ancient leather-bound book lying flat on a study desk. The leather cover is a saturated burgundy with golden embossing along the spine. The first page is freshly inked with a single decorative drop-cap flourish in deep blue and gold. A quill with a creamy-white feather rests across the page. A small brass oil lamp in the upper corner glows with a warm mustard-yellow halo. Faint sage olive sprig below the book."*

---

### 2. `correct_answers_{tier}.webp` — Sammler der Wahrheiten *(3 Stufen)*

**Farbsignatur:** terracotta + sage + warm cream marble · gemeinsame Bildwelt: wachsende Sammlung philosophischer Schriften, Antike-Atelier.

**`correct_answers_bronze.webp` — Schüler des Sokrates**
> *„A single rolled parchment scroll, tied with a saturated burgundy ribbon and sealed with a small burgundy wax stamp, resting on a warm terracotta-toned stone slab. A snub-nosed bust of Socrates peers from the right side, half in profile, painted in cream-white marble with sage-shadowed crevices. A single sage olive twig at the lower edge."*

**`correct_answers_silver.webp` — Platons Geselle**
> *„An open scroll unfurled across the medallion, its parchment a warm cream with terracotta-tinted edges, showing faint hand-drawn geometric diagrams in deep blue ink (a circle, a triangle, soft lines). A marble bust of Plato with a flowing beard sits behind the scroll, robed in sage green with cream-white drapery folds. Two olive sprigs frame the lower edge, leaves in saturated sage."*

**`correct_answers_gold.webp` — Aristoteles' Logiker**
> *„A heavy open codex on a lectern, pages a warm cream filled with faint diagrammatic sketches in burgundy and deep teal ink (branching trees, tiny squares of opposition — completely abstract and indecipherable). A stylized bust of Aristotle with a neatly trimmed beard above the lectern, draped in a rich plum-purple toga with golden trim. A full laurel wreath in saturated sage green, tied at the bottom with a burgundy ribbon, framing the medallion."*

---

### 3. `streaks_{tier}.webp` — Beharrlichkeit *(3 Stufen)*

**Farbsignatur:** sage + dustyTeal + mustard sun · gemeinsame Bildwelt: tägliche Disziplin, wiederkehrendes Licht und Natur.

**`streaks_bronze.webp` — Kontinuität (3 Tage)**
> *„A small bronze sundial standing on weathered stone, casting a soft shadow. The sky behind shifts from soft mustard-yellow morning gold at the top to dustyTeal at the horizon. A single sage olive sprig beside it. Calm sunrise atmosphere."*

**`streaks_silver.webp` — Wöchentliche Disziplin (7 Tage)**
> *„A stone tablet engraved with seven small moon phases in a gentle arc, from a sliver crescent in deep dustyTeal night to a full silver-cream moon, back to crescent. To the side, a tall beeswax candle with a warm terracotta flame burns steadily. The background is a deep dustyTeal twilight with one bright sage-tinted star. A laurel sprig at the base in saturated sage."*

**`streaks_gold.webp` — Stoische Beharrlichkeit (30 Tage)**
> *„An evergreen cypress tree growing from rocky ground, foliage in rich sage and deep forest green, trunk in warm umber. Branches form a soft halo around a small antique sun-and-moon dial at its base — sun in mustard gold, moon in cool silver-blue. The sky behind glows from a warm mustard horizon up to a saturated dustyTeal evening. A full sage laurel wreath frames the medallion, tied with a burgundy ribbon."*

---

### 4. `sudden_death_{tier}.webp` — Im Angesicht des Fehlers *(3 Stufen)*

**Farbsignatur:** terracotta flames + burgundy + dustyTeal stormy sky · gemeinsame Bildwelt: Wiederauferstehung, Standhaftigkeit gegen die Elemente.

**`sudden_death_bronze.webp` — Phönix (10)**
> *„A small phoenix bird rising from glowing amber-and-terracotta embers, wings opening, feathers blending burgundy, terracotta orange and warm mustard gold. Soft smoke curls upward in cool dustyTeal grey, contrasting with the warm flames. A single sage olive sprig at the lower edge."*

**`sudden_death_silver.webp` — Unbeirrbar (25)**
> *„A solitary lit candle in a brass holder on a stone pedestal, its flame a vivid terracotta-orange with a mustard core, standing tall against a stormy night. The storm background is rendered in deep dustyTeal and plum, with faint wind-streaks as ink lines. A silver-cream moon glows behind the candle. Olive twigs at base in saturated sage."*

**`sudden_death_gold.webp` — Stoische Härte (50)**
> *„An ancient stone column standing alone on a hilltop, partially weathered but unbroken, the stone showing warm cream and ochre veining. A small burning ember of mustard-gold light glows at its capital. The sky behind is a dramatic burgundy-and-plum storm broken by a shaft of warm gold sunlight from the upper left. Closed laurel wreath in saturated sage at the bottom, tied with a burgundy ribbon."*

---

### 5. `flawless_classic_{tier}.webp` — Tabula Perfecta *(3 Stufen)*

**Farbsignatur:** mustard gold + cream + plum highlight · gemeinsame Bildwelt: makellose Schreibtafel, wird kostbarer pro Stufe.

**`flawless_classic_bronze.webp`**
> *„A pristine empty Roman wax writing tablet — wooden frame in warm honey-umber, the wax surface a soft cream-gold with a subtle sheen. A bronze stylus rests diagonally across it, its tip glinting in warm light. A small sage olive sprig in the corner. The surrounding parchment carries a faint plum wash like a calm twilight."*

**`flawless_classic_silver.webp`**
> *„A polished cream-and-pale-sage marble tablet, edges chamfered with subtle blue-grey veining, a silver stylus laid across its center. The marble reflects warm mustard light from the upper left. A half-circle of saturated sage laurel leaves arches over the top, tied with a thin plum ribbon."*

**`flawless_classic_gold.webp`**
> *„An ornate gilded wooden tablet inlaid with faint geometric patterns in deep plum and dustyTeal, a gold-tipped stylus resting on it. Rays of warm mustard-gold light radiate from behind the tablet in a fan, contrasting against a soft burgundy backdrop. A full saturated-sage laurel wreath with a flowing burgundy ribbon knot frames the medallion."*

---

### 6. `speed_demon_{tier}.webp` — Schnelldenker *(3 Stufen)*

**Farbsignatur:** dustyTeal motion + mustard sparks + burgundy ink · gemeinsame Bildwelt: kinetische Energie, geflügelter Geist.

**`speed_demon_bronze.webp`**
> *„A quill pen with a creamy white feather caught mid-stroke, painted with soft dustyTeal motion-streaks trailing behind it, hovering above an open page covered in flowing burgundy ink marks. A small lightning-bolt-shaped flourish drawn as a manuscript decoration in saturated mustard gold. Sage olive sprig at base."*

**`speed_demon_silver.webp`**
> *„A small winged sandal (Hermes style) in cream-white leather with brass mustard buckles, resting on an open scroll. Wind lines around it rendered in dustyTeal. A silver-cream feather drifts above with a faint terracotta shadow. Light sage laurel frame at the bottom."*

**`speed_demon_gold.webp`**
> *„A streaking comet drawn as a vivid watercolor flourish across the medallion — head in saturated mustard-gold, tail blending into dustyTeal and a touch of plum, with tiny mustard sparks scattered along the trail. A small open book on a desk below, pages caught by the comet's wind, ink swirls in burgundy. Closed sage laurel wreath at the base, gold ribbon knot."*

---

### 7. `all_eras.webp` — Reise durch die Zeit *(einstufig)*

**Farbsignatur:** ein Regenbogen der Tertiärpalette — *jede Epoche bekommt eine Farbe*.

> *„An antique hourglass at the center with a warm brass frame. The sand inside forms a vivid vertical gradient through seven warm earth tones: terracotta at the very top, mustard, sage, dustyTeal, plum, burgundy, ending in deep umber at the bottom — each band visible but blended like a watercolor wash. Around the hourglass, a faint circular arrangement of seven tiny symbolic motifs etched into the medallion's inner ring, each tinted with its corresponding sand color: a Greek column (terracotta), a Gothic arch (mustard), an open Renaissance book (sage), a Cartesian compass (dustyTeal), a 19th-century pocket watch (plum), a typewriter key (burgundy), and a modern abstract spiral (umber). Antique-gold ring frames the whole composition."*

---

### 8. `bookmarks_{tier}.webp` — Sammler der Worte *(3 Stufen)*

**Farbsignatur:** plum + dustyTeal + mustard lamp · gemeinsame Bildwelt: gemütliche Privat-Bibliothek mit bunten Bandeinbänden.

**`bookmarks_bronze.webp`**
> *„A single leather-bound book lying open, the cover a saturated plum with mustard-gold lettering on the spine (kept abstract), a burgundy silk bookmark ribbon trailing from between the pages. A small sage olive sprig beside it. Warm mustard desk-lamp light spilling from above."*

**`bookmarks_silver.webp`**
> *„A small stack of three leather books — bottom spine in dustyTeal, middle in burgundy, top in mustard — each with a different colored ribbon trailing from the top (sage, plum, terracotta). The stack sits on a warm wooden surface. A saturated sage laurel sprig at the base. Faint cozy library shelf hint in the background in plum and burgundy."*

**`bookmarks_gold.webp`**
> *„A small ornate bookshelf rendered medallion-style: rows of leather-bound books with gilded spines in saturated colors — burgundy, plum, dustyTeal, sage, terracotta — a few books pulled slightly forward with bright ribbons cascading. A glowing brass reading lamp at the top corner casts a warm mustard halo. Full sage laurel wreath wrapping the medallion, tied with a plum ribbon."*

---

### 9. `first_duel_won.webp` — Erster Sieg *(einstufig)*

**Farbsignatur:** burgundy + cream + sage laurel

> *„Two crossed quills meeting at their tips behind a small saturated-sage laurel wreath — one quill with a creamy white feather, one in a rich saturated burgundy. A modest victory ribbon in deep burgundy with golden tassels hangs below the wreath. A faint mustard-gold glow radiates softly from behind the crossing point."*

---

### 10. `duel_streak_{tier}.webp` — Eristik *(3 Stufen)*

**Farbsignatur:** plum + mustard brass + burgundy ribbons · gemeinsame Bildwelt: wiederholter Sieg im philosophischen Streitgespräch.

**`duel_streak_bronze.webp` (3 Siege)**
> *„Three small quills arranged like a fan — feathers in cream, burgundy, and plum — their tips meeting at a small bronze coin embossed with a simple star pattern in mustard-gold. A saturated burgundy ribbon ties them at the base. Sage olive sprig in the corner."*

**`duel_streak_silver.webp` (5 Siege)**
> *„A pair of crossed quills (burgundy and dustyTeal feathers) behind a small set of antique brass scales painted in saturated mustard, one pan slightly higher than the other. A silver-cream laurel sprig curves beneath. Soft moon-like glow behind in cool plum-blue."*

**`duel_streak_gold.webp` (10 Siege)**
> *„An ornate philosopher's lectern in deep plum and gold, with a small open book on top showing burgundy script. Flanked by two tall standing quills like banners — feathers in saturated burgundy and mustard. A closed sage laurel wreath rests at the foot of the lectern with a flowing burgundy ribbon. Rays of warm mustard-gold light radiate from behind, against a soft plum twilight backdrop."*

---

### 11. `midnight_thinker_{tier}.webp` — Nachtwanderer *(3 Stufen, **hidden**)*

**Farbsignatur:** deep dustyTeal night + plum sky + mustard-orange candle warmth · gemeinsame Bildwelt: nächtliches Studium, der dramatischste Farbkontrast der Sammlung. Diese Bilder werden in der App erst sichtbar, sobald die Bronze-Stufe fällt — bis dahin bleibt nur die Silhouette.

**`midnight_thinker_bronze.webp`**
> *„A small arched window at night, deep dustyTeal night sky visible outside with a slim cream-silver crescent moon and a few warm mustard stars. On the windowsill, a single candle with a vivid terracotta-orange flame illuminates an open book just visible by its glow, pages in warm cream tinged by the candle. The window frame is in saturated plum-purple wood. Sage olive sprig in the lower corner."*

**`midnight_thinker_silver.webp`**
> *„A brass scholar's lantern on a wooden table, casting a warm mustard-gold circle of light onto an open manuscript with faint marginal notes in burgundy ink. The light fades dramatically into deep plum-and-dustyTeal night surrounding the desk. A constellation faintly inked in saturated mustard stars across the upper half of the medallion."*

**`midnight_thinker_gold.webp`**
> *„A nighttime study scene seen from above: a desk with an open book (pages warm cream, ink in burgundy), a quill, a half-melted beeswax candle with a vivid terracotta flame in a brass holder, and a small brass celestial globe. The desk surface is rich plum-stained wood. Saturated mustard-gold constellations etched across the deep dustyTeal upper half of the medallion, including a small Orion-like figure with three bright stars. A closed saturated-sage laurel wreath at the base with a gold-and-burgundy ribbon knot."*

---

### Hinweise zur Generierung

- **Konsistenz vor Vielfalt** — bei den 27 Bildern hilft es enorm, sie in einem Batch mit identischem Stil-Suffix zu erzeugen. Variiere nur das Motiv und die Tier-Differenzierung am Rahmen.
- **Farb-Signaturen einhalten** — wenn du das Motiv pro Tier reicher machst, behalte die 2–3 Hauptfarben der Errungenschaft. Sonst wirken Bronze / Silber / Gold wie drei verschiedene Achievements.
- **Tier-Erkennbarkeit** — die 3 Stufen einer Errungenschaft sollten auf den ersten Blick auseinanderhaltbar sein: Inner-Rim-Farbe + Lorbeer-Ausarbeitung (Zweig / halber Kranz / voller Kranz mit Bändchen) sind die zuverlässigste Signale.
- **„Saturated" heißt nicht „neon"** — Watercolor-Sättigung, nicht digital-leuchtend. Wenn dein Generator zu fluoreszent kippt, schreib „muted but rich", „illuminated manuscript palette", oder „like a painted book plate".
- **Keine Zahlen, kein Text** — die Schwellwerte (10, 25, 50 …) stehen in der UI; im Bild würden sie unscharf werden.
- **Quadrat & zentriert** — die Galerie zeigt die Icons rund maskiert (durch das WaxSeal-Widget), aber das größere Detail-Sheet zeigt sie quadratisch. Beides muss funktionieren.
- **Optimieren**: PNG → <https://squoosh.app> → WebP Q80 spart ~70 % Speicher.

---

## Optionale Texturen

**Datei:** `assets/textures/parchment.webp` (optional, 1080×2400)

> *„Seamless aged parchment paper texture. Cream and warm beige tones (#F5EFE6 to #EFE7D8). Very subtle natural fiber grain, faint stains and creases at edges. No tears, no holes. Calm, contemplative, suitable as a background that won't compete with foreground text. Soft, even lighting."*

> *Nicht zwingend nötig — die App hat einen prozedural gemalten Pergament-Hintergrund. Aber falls du ein Bild willst, hier der Prompt.*

---

## Tipps zur Erzeugung

- **Konsistenz schlägt Detail.** Generiere alle Porträts in einem einzigen Schwung mit demselben Stil-Prompt, dann fühlt sich die App wie aus einem Guss an.
- **Quadratisch & zentriert** — die App croppt rund / quadratisch.
- **Kein Text in den Bildern** — das macht die App selbst.
- **Optimieren**: lade die generierten PNGs hoch zu <https://squoosh.app> und exportiere als WebP, Quality 80. Spart pro Bild ~70% Speicher.

---

## Quick-Start ohne Bilder

Die App **funktioniert auch ohne die Porträts** — wenn ein Asset fehlt, wird einfach das Anfangsbuchstaben-Avatar mit Pergament-Hintergrund gezeigt. Du kannst also sofort entwickeln und Bilder Stück für Stück nachreichen.

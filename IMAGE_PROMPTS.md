# Bilder für Eleutheria

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

## Basis-Philosoph:innen-Porträts (40 Bilder, vorhanden)

Alle in den Ordner `assets/images/philosophers/` legen. Dateiname = `id` aus `philosophers_seed.dart` mit Endung `.webp` (oder `.png`).

Status: Diese 40 Basisbilder sind aktuell im Asset-Ordner vorhanden.

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

## Fehlende Porträts für Fragen- und Balance-Erweiterung

Alle folgenden Einträge sind als **FEHLT** markiert: Für diese Personen gibt es aktuell noch keine Datei unter `assets/images/philosophers/`. Die Priorität A enthält Personen, die in den bestehenden Fragen bereits als richtige Antwort, Hauptfigur oder wiederkehrende Option vorkommen. Priorität B ergänzt die nächsten sinnvollen Kandidat:innen für eine ausgeglichenere Fragenbasis.

**Prompt-Schema für diese Porträts:**
> *„Half-length portrait of {NAME}, the {SCHOOL_OR_CONTEXT} thinker who lived {YEARS}. Three-quarter view, contemplative gaze, period-appropriate clothing, subtle historical context in the background without text. Soft warm lighting from the upper left. Aged parchment background with very faint symbolic motifs. Painterly watercolor-and-ink style, muted earth tones with hints of burgundy and antique gold. Centered square 1024×1024 composition. Avoid photorealism — keep an illustrated, scholarly book-cover quality."*

| Datei | Status | Subjekt | Priorität | Hint |
|---|---|---|---|---|
| `hypatia.webp` | FEHLT | Hypatia | A | late antique Alexandrian scholar, simple philosopher's robe, astronomical diagram or scroll hint |
| `mary_wollstonecraft.webp` | FEHLT | Mary Wollstonecraft | A | late 18th-century writer, composed direct gaze, quill and manuscript, early feminist Enlightenment context |
| `elisabeth_von_der_pfalz.webp` | FEHLT | Élisabeth von der Pfalz | A | 17th-century princess-scholar, sober court dress, correspondence papers, Cartesian mind-body debate hint |
| `hobbes.webp` | FEHLT | Thomas Hobbes | A | 17th-century English philosopher, dark coat, sharp eyes, Leviathan/state symbolism very faint |
| `confucius.webp` | FEHLT | Konfuzius | A | ancient Chinese teacher, layered robes, calm elder, bamboo slips and ritual hall hint |
| `laozi.webp` | FEHLT | Laozi | A | ancient Daoist sage, flowing robe, quiet mountain pass, soft mist, no fantasy elements |
| `nagarjuna.webp` | FEHLT | Nāgārjuna | A | Buddhist philosopher-monk, serene posture, manuscript leaves, subtle empty-circle motif |
| `avicenna.webp` | FEHLT | Avicenna / Ibn Sīnā | A | medieval Persian polymath, scholar's robe and turban, medical/philosophical manuscript hint |
| `protagoras.webp` | FEHLT | Protagoras | A | Greek sophist, travelling teacher, scroll in hand, agora background hint |
| `quine.webp` | FEHLT | W. V. O. Quine | A | 20th-century analytic philosopher, academic suit, chalkboard logic marks very faint |
| `nozick.webp` | FEHLT | Robert Nozick | A | late 20th-century political philosopher, thoughtful professor, minimal-state diagram hint |
| `levi_strauss.webp` | FEHLT | Claude Lévi-Strauss | A | French anthropologist-philosopher, glasses, field notes, structural pattern motif |
| `horkheimer.webp` | FEHLT | Max Horkheimer | A | mid-century Frankfurt School thinker, suit and glasses, radio/library background hint |
| `mary_astell.webp` | FEHLT | Mary Astell | A | early modern English philosopher, modest 17th-century dress, book and education motif |
| `harriet_taylor_mill.webp` | FEHLT | Harriet Taylor Mill | A | Victorian feminist philosopher, poised portrait, manuscript and reform pamphlet hint |
| `olympe_de_gouges.webp` | FEHLT | Olympe de Gouges | A | French revolutionary writer, 18th-century dress, declaration manuscript motif |
| `margaret_cavendish.webp` | FEHLT | Margaret Cavendish | A | 17th-century natural philosopher, elaborate period dress, manuscript and atomist/nature motif |
| `anne_conway.webp` | FEHLT | Anne Conway | A | early modern metaphysician, restrained aristocratic dress, monad-like light motif |
| `damaris_masham.webp` | FEHLT | Damaris Cudworth Masham | A | early Enlightenment philosopher, correspondence desk, Locke-era study setting |
| `luce_irigaray.webp` | FEHLT | Luce Irigaray | A | contemporary feminist philosopher, neutral academic portrait, language/body motif abstractly |
| `nancy_fraser.webp` | FEHLT | Nancy Fraser | A | contemporary critical theorist, confident professor, public-sphere/capitalism motif faint |
| `diotima.webp` | FEHLT | Diotima | B | ancient Greek priestess-philosopher as Symposium figure, dignified robe, no eroticized depiction |
| `hildegard_von_bingen.webp` | FEHLT | Hildegard von Bingen | B | medieval abbess and thinker, manuscript illumination colors, visionary cosmology motif |
| `christine_de_pizan.webp` | FEHLT | Christine de Pizan | B | medieval author at writing desk, blue robe, city/book motif |
| `emilie_du_chatelet.webp` | FEHLT | Émilie du Châtelet | B | Enlightenment mathematician-philosopher, elegant study, Newtonian prism or manuscript hint |
| `edith_stein.webp` | FEHLT | Edith Stein | B | phenomenologist, early 20th-century scholar, simple blouse or Carmelite habit variant, contemplative |
| `simone_weil.webp` | FEHLT | Simone Weil | B | intense early 20th-century philosopher, simple work clothes, notebooks, austere light |
| `susanne_langer.webp` | FEHLT | Susanne Langer | B | 20th-century philosopher of symbols, academic portrait, symbolic form motif |
| `elizabeth_anscombe.webp` | FEHLT | Elizabeth Anscombe | B | analytic philosopher, mid-century Oxford look, pipe optional, manuscript and logic hint |
| `philippa_foot.webp` | FEHLT | Philippa Foot | B | moral philosopher, composed academic portrait, trolley/virtue motif only extremely subtle |
| `iris_murdoch.webp` | FEHLT | Iris Murdoch | B | novelist-philosopher, thoughtful gaze, book-lined study, moral attention motif |
| `christine_korsgaard.webp` | FEHLT | Christine Korsgaard | B | contemporary Kantian ethicist, clean academic portrait, autonomy/agency motif |
| `onora_oneill.webp` | FEHLT | Onora O'Neill | B | contemporary political philosopher, dignified academic portrait, trust/justice motif |
| `seyla_benhabib.webp` | FEHLT | Seyla Benhabib | B | contemporary political theorist, cosmopolitan public-sphere motif, warm professional portrait |
| `sally_haslanger.webp` | FEHLT | Sally Haslanger | B | contemporary feminist metaphysician, academic portrait, social construction motif |
| `miranda_fricker.webp` | FEHLT | Miranda Fricker | B | contemporary epistemologist, testimonial justice motif, calm modern academic portrait |
| `rahel_jaeggi.webp` | FEHLT | Rahel Jaeggi | B | contemporary critical theorist, modern academic look, alienation/social critique motif |
| `chantal_mouffe.webp` | FEHLT | Chantal Mouffe | B | political theorist, agonistic democracy motif, confident contemporary portrait |
| `bell_hooks.webp` | FEHLT | bell hooks | B | Black feminist theorist, warm direct gaze, books and classroom/community motif |
| `gayatri_spivak.webp` | FEHLT | Gayatri Chakravorty Spivak | B | postcolonial theorist, sari or academic dress, text/voice motif, dignified portrait |
| `donna_haraway.webp` | FEHLT | Donna Haraway | B | science studies philosopher, contemporary portrait, cyborg/companion-species motif kept subtle |
| `zhuangzi.webp` | FEHLT | Zhuangzi | B | ancient Daoist philosopher, relaxed scholar, butterfly dream motif very subtle |
| `mengzi.webp` | FEHLT | Mengzi / Mencius | B | Confucian thinker, scholar robe, humane governance motif |
| `mozi.webp` | FEHLT | Mozi | B | ancient Chinese philosopher, plain robe, universal care and defensive engineering motif |
| `xunzi.webp` | FEHLT | Xunzi | B | Confucian philosopher, stern teacher, ritual and education motif |
| `vasubandhu.webp` | FEHLT | Vasubandhu | B | Buddhist philosopher-monk, manuscript leaves, Yogācāra consciousness motif |
| `shankara.webp` | FEHLT | Śaṅkara | B | Advaita Vedānta philosopher, saffron robe, nondual awareness motif |
| `averroes.webp` | FEHLT | Averroes / Ibn Rushd | B | Andalusian philosopher, judge-scholar robe, Aristotle commentary manuscript hint |
| `maimonides.webp` | FEHLT | Maimonides | B | medieval Jewish philosopher, physician-scholar, manuscript and guide motif |
| `al_ghazali.webp` | FEHLT | Al-Ghazali | B | Islamic theologian-philosopher, scholar robe, lamp and manuscript motif |
| `wang_yangming.webp` | FEHLT | Wang Yangming | B | Neo-Confucian philosopher, Ming scholar robe, unity of knowledge/action motif |
| `nishida_kitaro.webp` | FEHLT | Nishida Kitarō | B | modern Japanese philosopher, early 20th-century academic, Kyoto path/absolute nothingness motif |

### Weitere fehlende Optionsnamen, niedrigere Priorität

Diese Personen kommen aktuell vor allem als Antwortoptionen, Co-Autor:innen oder plausible Distraktoren vor. Bilder sind erst nötig, wenn sie als eigene Philosoph:innen in `philosophers_seed.dart` aufgenommen oder häufiger als Hauptbezug genutzt werden.

| Datei | Status | Subjekt |
|---|---|---|
| `althusser.webp` | FEHLT | Louis Althusser |
| `anselm.webp` | FEHLT | Anselm von Canterbury |
| `apel.webp` | FEHLT | Karl-Otto Apel |
| `bacon.webp` | FEHLT | Francis Bacon |
| `bataille.webp` | FEHLT | Georges Bataille |
| `bentham.webp` | FEHLT | Jeremy Bentham |
| `benjamin_constant.webp` | FEHLT | Benjamin Constant |
| `berger.webp` | FEHLT | Peter L. Berger |
| `bloch.webp` | FEHLT | Ernst Bloch |
| `bodin.webp` | FEHLT | Jean Bodin |
| `boethius.webp` | FEHLT | Boethius |
| `bourdieu.webp` | FEHLT | Pierre Bourdieu |
| `burckhardt.webp` | FEHLT | Jacob Burckhardt |
| `carnap.webp` | FEHLT | Rudolf Carnap |
| `cicero.webp` | FEHLT | Cicero |
| `cioran.webp` | FEHLT | E. M. Cioran |
| `dignaga.webp` | FEHLT | Dignāga |
| `diogenes.webp` | FEHLT | Diogenes |
| `dworkin.webp` | FEHLT | Ronald Dworkin |
| `engels.webp` | FEHLT | Friedrich Engels |
| `epiktet.webp` | FEHLT | Epiktet |
| `feuerbach.webp` | FEHLT | Ludwig Feuerbach |
| `feyerabend.webp` | FEHLT | Paul Feyerabend |
| `fichte.webp` | FEHLT | Johann Gottlieb Fichte |
| `frankl.webp` | FEHLT | Viktor Frankl |
| `frege.webp` | FEHLT | Gottlob Frege |
| `fromm.webp` | FEHLT | Erich Fromm |
| `gadamer.webp` | FEHLT | Hans-Georg Gadamer |
| `hartmann.webp` | FEHLT | Nicolai Hartmann |
| `hayek.webp` | FEHLT | Friedrich Hayek |
| `heraklit.webp` | FEHLT | Heraklit |
| `husserl.webp` | FEHLT | Edmund Husserl |
| `hutcheson.webp` | FEHLT | Francis Hutcheson |
| `isaiah_berlin.webp` | FEHLT | Isaiah Berlin |
| `jaspers.webp` | FEHLT | Karl Jaspers |
| `kuhn.webp` | FEHLT | Thomas Kuhn |
| `lessing.webp` | FEHLT | Gotthold Ephraim Lessing |
| `levinas.webp` | FEHLT | Emmanuel Levinas |
| `luckmann.webp` | FEHLT | Thomas Luckmann |
| `macintyre.webp` | FEHLT | Alasdair MacIntyre |
| `marcuse.webp` | FEHLT | Herbert Marcuse |
| `merleau_ponty.webp` | FEHLT | Maurice Merleau-Ponty |
| `montaigne.webp` | FEHLT | Michel de Montaigne |
| `parmenides.webp` | FEHLT | Parmenides |
| `pascal.webp` | FEHLT | Blaise Pascal |
| `plotin.webp` | FEHLT | Plotin |
| `plutarch.webp` | FEHLT | Plutarch |
| `pythagoras.webp` | FEHLT | Pythagoras |
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

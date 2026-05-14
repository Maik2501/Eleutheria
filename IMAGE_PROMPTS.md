# Bilder für Sophia

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

## Philosophen-Porträts (40 Bilder)

Alle in den Ordner `assets/images/philosophers/` legen. Dateiname = `id` aus `philosophers_seed.dart` mit Endung `.webp` (oder `.png`).

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

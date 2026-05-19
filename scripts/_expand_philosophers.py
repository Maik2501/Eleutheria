"""One-shot script: expand the philosopher seed with frequently-referenced
figures and back-fill philosopherId on questions whose correct answer points
at one of them.

Run order:
  python scripts/extract_questions.py     # JSON ← Dart (already current)
  python scripts/_expand_philosophers.py  # mutate the JSONs
  python scripts/write_philosophers.py    # Dart ← JSON
  python scripts/write_questions.py       # Dart ← JSON

The script is idempotent: running it twice is safe.
"""
import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
PHS_JSON = ROOT / "cms" / "data" / "philosophers.json"
QS_JSON  = ROOT / "cms" / "data" / "questions.json"

# ── Step 1 — normalize "still alive" lifespans ────────────────────────────
LIVING_NORMALIZE = {
    "habermas": "1929 – heute",
    "butler":   "1956 – heute",
    "singer":   "1946 – heute",
    "nussbaum": "1947 – heute",
}

# ── Step 2 — new philosopher entries to add ───────────────────────────────
# Bio data verified from common encyclopedic sources. Era enum:
# antike, mittelalter, renaissance, aufklaerung, neunzehntes,
# modernePostmoderne, zeitgenoessisch.
NEW_PHILOSOPHERS = [
    # ── Antike (Greek/Roman + Chinese classical + Indian classical) ──
    {"id": "hypatia", "name": "Hypatia",
     "years": "ca. 360 – 415", "era": "antike",
     "school": "Neuplatonismus",
     "tagline": "Mathematikerin und Philosophin im spätantiken Alexandria.",
     "aliases": ["Hypatia von Alexandria"]},

    {"id": "diotima", "name": "Diotima von Mantineia",
     "years": "5. Jh. v. Chr.", "era": "antike",
     "school": "Platonische Tradition",
     "tagline": "Philosophin im platonischen Symposion, Lehrerin des Eros.",
     "aliases": ["Diotima"]},

    {"id": "aesara", "name": "Aesara von Lukanien",
     "years": "4./3. Jh. v. Chr.", "era": "antike",
     "school": "Pythagoreismus",
     "tagline": "Pythagoreische Philosophin über Seele und Gerechtigkeit.",
     "aliases": ["Aesara", "Aesara von Lucania"]},

    {"id": "protagoras", "name": "Protagoras",
     "years": "ca. 490 – 420 v. Chr.", "era": "antike",
     "school": "Sophistik",
     "tagline": "„Der Mensch ist das Maß aller Dinge.\"",
     "aliases": []},

    {"id": "konfuzius", "name": "Konfuzius",
     "years": "551 – 479 v. Chr.", "era": "antike",
     "school": "Konfuzianismus",
     "tagline": "Lehrer der Tugendethik und ritualisierten Mitmenschlichkeit.",
     "aliases": ["Kong Fuzi", "Kongzi"]},

    {"id": "laozi", "name": "Laozi",
     "years": "6. Jh. v. Chr. (legendär)", "era": "antike",
     "school": "Daoismus",
     "tagline": "Zugeschriebener Verfasser des Daodejing.",
     "aliases": ["Laotse", "Lao-tse"]},

    {"id": "zhuangzi", "name": "Zhuangzi",
     "years": "ca. 369 – 286 v. Chr.", "era": "antike",
     "school": "Daoismus",
     "tagline": "Meister des philosophischen Gleichnisses und Skeptikers Witz.",
     "aliases": ["Dschuang Dsi", "Zhuang Zhou"]},

    {"id": "mengzi", "name": "Mengzi",
     "years": "ca. 372 – 289 v. Chr.", "era": "antike",
     "school": "Konfuzianismus",
     "tagline": "Vertreter der angeborenen Gutartigkeit des Menschen.",
     "aliases": ["Mencius", "Meng Ke"]},

    {"id": "xunzi", "name": "Xunzi",
     "years": "ca. 313 – 238 v. Chr.", "era": "antike",
     "school": "Konfuzianismus",
     "tagline": "Konfuzianer der menschlichen Natur als ritualbedürftig.",
     "aliases": ["Xun Kuang"]},

    {"id": "nagarjuna", "name": "Nāgārjuna",
     "years": "ca. 150 – 250", "era": "antike",
     "school": "Madhyamaka-Buddhismus",
     "tagline": "Begründer der Leerheits-Philosophie (śūnyatā).",
     "aliases": ["Nagarjuna"]},

    # ── Mittelalter ──
    {"id": "hildegard", "name": "Hildegard von Bingen",
     "years": "1098 – 1179", "era": "mittelalter",
     "school": "Christliche Mystik",
     "tagline": "Visionärin, Naturforscherin und Komponistin der Viriditas.",
     "aliases": []},

    {"id": "avicenna", "name": "Avicenna",
     "years": "980 – 1037", "era": "mittelalter",
     "school": "Islamische Philosophie",
     "tagline": "Persischer Universalgelehrter, Vermittler des Aristotelismus.",
     "aliases": ["Ibn Sina", "Ibn Sīnā"]},

    {"id": "shankara", "name": "Śaṅkara",
     "years": "ca. 788 – 820", "era": "mittelalter",
     "school": "Advaita Vedānta",
     "tagline": "Großer Systematiker der nondualen Bewusstseinslehre.",
     "aliases": ["Shankara", "Adi Shankara"]},

    # ── Renaissance / Spätmittelalter ──
    {"id": "christine_de_pizan", "name": "Christine de Pizan",
     "years": "1364 – ca. 1430", "era": "renaissance",
     "school": "Frühe Frauenphilosophie",
     "tagline": "Verfasserin der „Stadt der Frauen\", erste Berufsautorin.",
     "aliases": []},

    {"id": "tullia", "name": "Tullia d'Aragona",
     "years": "ca. 1510 – 1556", "era": "renaissance",
     "school": "Italienischer Humanismus",
     "tagline": "Dichterin und Dialogautorin der Renaissance-Liebesphilosophie.",
     "aliases": []},

    {"id": "wang_yangming", "name": "Wang Yangming",
     "years": "1472 – 1529", "era": "renaissance",
     "school": "Neukonfuzianismus",
     "tagline": "Einheit von Wissen und Handeln in der Ming-zeitlichen Schule.",
     "aliases": []},

    # ── Aufklärung / Frühe Neuzeit ──
    {"id": "hobbes", "name": "Thomas Hobbes",
     "years": "1588 – 1679", "era": "aufklaerung",
     "school": "Vertragstheorie",
     "tagline": "Theoretiker des Leviathan und des Naturzustands.",
     "aliases": ["Hobbes"]},

    {"id": "cavendish", "name": "Margaret Cavendish",
     "years": "1623 – 1673", "era": "aufklaerung",
     "school": "Naturphilosophie",
     "tagline": "Materialistin und Vorreiterin der Spekulativen Fiktion.",
     "aliases": []},

    {"id": "anne_conway", "name": "Anne Conway",
     "years": "1631 – 1679", "era": "aufklaerung",
     "school": "Cambridge-Platonismus",
     "tagline": "Monistin, Einfluss auf Leibniz' Monadenlehre.",
     "aliases": []},

    {"id": "astell", "name": "Mary Astell",
     "years": "1666 – 1731", "era": "aufklaerung",
     "school": "Frühe Frauenphilosophie",
     "tagline": "Pionierin der weiblichen Bildungsphilosophie in England.",
     "aliases": []},

    {"id": "du_chatelet", "name": "Émilie du Châtelet",
     "years": "1706 – 1749", "era": "aufklaerung",
     "school": "Aufklärung",
     "tagline": "Newton-Übersetzerin und Naturphilosophin der Aufklärung.",
     "aliases": ["Emilie du Chatelet", "Émilie du Chatelet"]},

    {"id": "de_gouges", "name": "Olympe de Gouges",
     "years": "1748 – 1793", "era": "aufklaerung",
     "school": "Revolutionäre Aufklärung",
     "tagline": "Verfasserin der Erklärung der Rechte der Frau und Bürgerin.",
     "aliases": []},

    {"id": "wollstonecraft", "name": "Mary Wollstonecraft",
     "years": "1759 – 1797", "era": "aufklaerung",
     "school": "Frühe Frauenphilosophie",
     "tagline": "Mitbegründerin des modernen feministischen Denkens.",
     "aliases": []},

    # ── 19. Jahrhundert ──
    {"id": "martineau", "name": "Harriet Martineau",
     "years": "1802 – 1876", "era": "neunzehntes",
     "school": "Soziologie / Utilitarismus",
     "tagline": "Frühe Soziologin und Übersetzerin Comtes ins Englische.",
     "aliases": []},

    {"id": "harriet_taylor_mill", "name": "Harriet Taylor Mill",
     "years": "1807 – 1858", "era": "neunzehntes",
     "school": "Liberalismus",
     "tagline": "Mitdenkerin und Co-Autorin J. S. Mills zur Frauenfrage.",
     "aliases": []},

    # ── Moderne / Postmoderne ──
    {"id": "cooper", "name": "Anna Julia Cooper",
     "years": "1858 – 1964", "era": "modernePostmoderne",
     "school": "Schwarzer Feminismus",
     "tagline": "Pionierin der intersektionalen Bildungs- und Rassetheorie.",
     "aliases": []},

    {"id": "langer", "name": "Susanne Langer",
     "years": "1895 – 1985", "era": "modernePostmoderne",
     "school": "Symbol-Philosophie",
     "tagline": "Philosophin der symbolischen Form und der Kunst.",
     "aliases": ["Susanne K. Langer"]},

    {"id": "weil", "name": "Simone Weil",
     "years": "1909 – 1943", "era": "modernePostmoderne",
     "school": "Politische Mystik",
     "tagline": "Mystikerin der Aufmerksamkeit und Anwältin der Entwurzelten.",
     "aliases": []},

    {"id": "murdoch", "name": "Iris Murdoch",
     "years": "1919 – 1999", "era": "modernePostmoderne",
     "school": "Moralphilosophie",
     "tagline": "Erneuerin der platonischen Ethik der moralischen Aufmerksamkeit.",
     "aliases": []},

    {"id": "berger", "name": "Peter L. Berger",
     "years": "1929 – 2017", "era": "modernePostmoderne",
     "school": "Wissenssoziologie",
     "tagline": "Co-Autor der „Gesellschaftlichen Konstruktion der Wirklichkeit\".",
     "aliases": []},

    {"id": "luckmann", "name": "Thomas Luckmann",
     "years": "1927 – 2016", "era": "modernePostmoderne",
     "school": "Wissenssoziologie",
     "tagline": "Co-Autor der „Gesellschaftlichen Konstruktion der Wirklichkeit\".",
     "aliases": []},

    # ── Zeitgenössisch ──
    {"id": "haraway", "name": "Donna Haraway",
     "years": "1944 – heute", "era": "zeitgenoessisch",
     "school": "Science Studies",
     "tagline": "Theoretikerin des Cyborgs und der Companion Species.",
     "aliases": []},

    {"id": "bell_hooks", "name": "bell hooks",
     "years": "1952 – 2021", "era": "zeitgenoessisch",
     "school": "Schwarzer Feminismus",
     "tagline": "Theoretikerin von Klasse, Race und Liebe als Praxis.",
     "aliases": []},

    {"id": "fricker", "name": "Miranda Fricker",
     "years": "1966 – heute", "era": "zeitgenoessisch",
     "school": "Soziale Erkenntnistheorie",
     "tagline": "Begründerin des Konzepts der epistemischen Ungerechtigkeit.",
     "aliases": []},

    {"id": "jaeggi", "name": "Rahel Jaeggi",
     "years": "1967 – heute", "era": "zeitgenoessisch",
     "school": "Kritische Theorie",
     "tagline": "Erneuerin der Entfremdungstheorie für die Gegenwart.",
     "aliases": []},

    # ── Plus a handful named in single questions, to close remaining gaps ──
    {"id": "makrina", "name": "Makrina die Jüngere",
     "years": "ca. 327 – 379", "era": "antike",
     "school": "Kappadokische Theologie",
     "tagline": "Lehrerin ihres Bruders Gregor von Nyssa, Begründerin einer Frauen-Asketengemeinschaft.",
     "aliases": []},

    {"id": "elisabeth_pfalz", "name": "Elisabeth von der Pfalz",
     "years": "1618 – 1680", "era": "aufklaerung",
     "school": "Cartesianismus",
     "tagline": "Korrespondentin Descartes', kritische Stimme zur Leib-Seele-Problematik.",
     "aliases": ["Elisabeth von Böhmen"]},

    {"id": "edith_stein", "name": "Edith Stein",
     "years": "1891 – 1942", "era": "modernePostmoderne",
     "school": "Phänomenologie",
     "tagline": "Phänomenologin und Schülerin Husserls, später Karmelitin.",
     "aliases": []},

    {"id": "nishida", "name": "Nishida Kitarō",
     "years": "1870 – 1945", "era": "modernePostmoderne",
     "school": "Kyoto-Schule",
     "tagline": "Begründer der Kyoto-Schule und Denker des absoluten Nichts.",
     "aliases": ["Nishida Kitaro"]},
]

# ── Step 3 — manual question → philosopherId overrides ───────────────────
# For each unmatched question whose answer points at a newly-added (or
# already-present) philosopher, set the mapping here. The script also runs
# an automatic name-match pass; this dict is for cases name matching would
# get wrong or where the answer string is a multi-name compound.
MANUAL_QID_OVERRIDES = {
    # philosopherToEra: prompt names the philosopher, answer is the era —
    # we want the mini-profile to show the philosopher from the prompt.
    "q_era_101": "hypatia",
    "q_era_201": "hypatia",
    "q_era_102": "avicenna",
    "q_era_202": "diotima",
    "q_era_203": "aesara",

    # completeQuote: attribution names the author.
    "q_complete_003": "protagoras",

    # whoCriticizedWhom in this set tends to point at concept-vs-concept; we
    # don't add philosopherIds there to avoid misleading mini-profiles.

    # Berger & Luckmann: the answer is a joint authorship. Use Berger (first
    # author of the canonical work).
    "q_work_012": "berger",
}


def build_name_map(philosophers: list[dict]) -> dict[str, str]:
    """Map lowercase full-name / alias / unambiguous-last-name → philosopher id."""
    full: dict[str, str] = {}
    aliases: dict[str, str] = {}
    last_counts: dict[str, int] = {}
    last_first: dict[str, str] = {}
    for p in philosophers:
        full[p["name"].lower()] = p["id"]
        ln = p["name"].split()[-1].lower()
        last_counts[ln] = last_counts.get(ln, 0) + 1
        last_first.setdefault(ln, p["id"])
        for a in p.get("aliases", []):
            aliases[a.lower()] = p["id"]
    # Keep only unambiguous last names.
    last = {ln: pid for ln, pid in last_first.items() if last_counts[ln] == 1}
    # Composite map: full overrides last; aliases override last; full wins all.
    merged: dict[str, str] = {**last, **aliases, **full}
    return merged


def find_id_from_answer(answer: str, name_map: dict[str, str]) -> str | None:
    a = answer.strip().lower()
    if a in name_map:
        return name_map[a]
    parts = a.split()
    if parts and parts[-1] in name_map:
        return name_map[parts[-1]]
    return None


def find_id_in_text(text: str, name_map: dict[str, str]) -> str | None:
    """Scan free-form text (attribution / prompt) for a known name/alias.

    Walks longest names first so multi-word matches win over single-word ones,
    and pads the haystack so word-boundary matching catches names at the edge.
    """
    if not text:
        return None
    low = " " + text.lower() + " "
    for key in sorted(name_map.keys(), key=len, reverse=True):
        # Skip very short keys (e.g. "mao") to avoid false positives. We
        # demand at least 4 characters or that the key contains whitespace.
        if len(key) < 4 and " " not in key:
            continue
        if re.search(r"(?<![a-zäöüß])" + re.escape(key) + r"(?![a-zäöüß])", low):
            return name_map[key]
    return None


def main() -> int:
    # Read current data
    phs = json.loads(PHS_JSON.read_text(encoding="utf-8"))
    qs_payload = json.loads(QS_JSON.read_text(encoding="utf-8"))
    qs = qs_payload["questions"]

    # ── Apply "still alive" normalization ──
    living_fixed = 0
    for p in phs:
        if p["id"] in LIVING_NORMALIZE and p["years"] != LIVING_NORMALIZE[p["id"]]:
            p["years"] = LIVING_NORMALIZE[p["id"]]
            living_fixed += 1

    # ── Append new philosophers (skip if id already present) ──
    existing_ids = {p["id"] for p in phs}
    added = 0
    for new in NEW_PHILOSOPHERS:
        if new["id"] in existing_ids:
            continue
        # Provide imageAsset if missing — writer defaults to the conventional
        # path so we don't strictly need to, but being explicit avoids surprise.
        new = dict(new)
        new.setdefault("imageAsset", f"assets/images/philosophers/{new['id']}.webp")
        phs.append(new)
        existing_ids.add(new["id"])
        added += 1

    # ── Back-fill philosopherId on unmatched questions ──
    name_map = build_name_map(phs)
    person_cats = {"quoteToPhilosopher", "workToAuthor",
                   "philosopherToEra", "completeQuote"}
    auto_set = 0
    manual_set = 0
    still_unmatched: list[tuple[str, str, str]] = []

    for q in qs:
        if q.get("philosopherId"):
            continue
        if q["id"] in MANUAL_QID_OVERRIDES:
            pid = MANUAL_QID_OVERRIDES[q["id"]]
            if pid not in existing_ids:
                print(f"  ! manual override for {q['id']} points to unknown {pid!r}", file=sys.stderr)
                continue
            q["philosopherId"] = pid
            manual_set += 1
            continue
        if q["category"] not in person_cats:
            continue
        ans = q["options"][q["correctIndex"]]
        pid = find_id_from_answer(ans, name_map)
        # For completeQuote and philosopherToEra the answer is a fragment /
        # an era, so the philosopher is in the attribution or prompt instead.
        if not pid and q["category"] in ("completeQuote", "philosopherToEra"):
            pid = find_id_in_text(q.get("attribution", ""), name_map) \
               or find_id_in_text(q.get("prompt", ""), name_map)
        if pid:
            q["philosopherId"] = pid
            auto_set += 1
        else:
            still_unmatched.append((q["id"], q["category"], ans))

    # ── Persist ──
    PHS_JSON.write_text(
        json.dumps(phs, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )
    QS_JSON.write_text(
        json.dumps(qs_payload, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )

    print(f"living-philosopher years normalized: {living_fixed}")
    print(f"new philosophers appended:           {added}")
    print(f"philosopherId set automatically:     {auto_set}")
    print(f"philosopherId set via manual map:    {manual_set}")
    print(f"still without philosopherId:         {len(still_unmatched)} (person-typed)")
    for qid, cat, ans in still_unmatched[:40]:
        print(f"   - {qid:22s}  {cat:20s}  {ans[:50]}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

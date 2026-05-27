"""Push curated content (questions + crossword puzzles) to Supabase.

Source of truth bleibt der Dart-Code:
- lib/data/seed/questions_seed.dart
- lib/features/crossword/models/puzzle_seed.dart

Dieses Skript parst die Seed-Dateien, normalisiert sie ins DB-Schema
(siehe migration 0010) und upsertet via PostgREST. Idempotent — der
`Prefer: resolution=merge-duplicates`-Header lässt die DB pro Primary-
Key entscheiden, ob INSERT oder UPDATE.

Voraussetzung: Environment-Variablen müssen gesetzt sein:
    SUPABASE_URL              z. B. https://supabase.deine-domain
    SUPABASE_SERVICE_ROLE_KEY (aus supabase/.env auf dem Server,
                               NICHT der anon key — der hat keine
                               write-Rechte auf den Content-Tabellen)

Aufruf (lokal):
    SUPABASE_URL=... SUPABASE_SERVICE_ROLE_KEY=... \\
        python scripts/push_content_to_supabase.py

Auf Windows PowerShell:
    $env:SUPABASE_URL = '...'
    $env:SUPABASE_SERVICE_ROLE_KEY = '...'
    python scripts/push_content_to_supabase.py
"""
from __future__ import annotations

import json
import os
import re
import sys
import urllib.request
from pathlib import Path

ROOT          = Path(__file__).resolve().parent.parent
QUESTIONS_SEED = ROOT / "lib" / "data" / "seed" / "questions_seed.dart"
CROSSWORD_SEED = ROOT / "lib" / "features" / "crossword" / "models" / "puzzle_seed.dart"


# ─────────────────────────── Dart-Parser-Helpers ───────────────────────────

def _unescape_dart(s: str) -> str:
    return (s.replace("\\'", "'")
             .replace('\\"', '"')
             .replace("\\n", "\n")
             .replace("\\\\", "\\"))


def _find_quoted(name: str, block: str) -> str | None:
    m = re.search(rf"{name}:\s*'((?:[^'\\]|\\.)*)'", block)
    if m:
        return _unescape_dart(m.group(1))
    m = re.search(rf'{name}:\s*"((?:[^"\\]|\\.)*)"', block)
    if m:
        return _unescape_dart(m.group(1))
    return None


def _find_int(name: str, block: str) -> int | None:
    m = re.search(rf"{name}:\s*(\d+)", block)
    return int(m.group(1)) if m else None


def _find_enum(name: str, enum_prefix: str, block: str) -> str | None:
    m = re.search(rf"{name}:\s*{re.escape(enum_prefix)}\.(\w+)", block)
    return m.group(1) if m else None


def _find_options(block: str) -> list[str]:
    m = re.search(r"options:\s*\[(.+?)\]", block, re.DOTALL)
    if not m:
        return []
    raw = m.group(1)
    out: list[str] = []
    for s in re.finditer(r"'((?:[^'\\]|\\.)*)'|\"((?:[^\"\\]|\\.)*)\"", raw):
        s_val = s.group(1) if s.group(1) is not None else s.group(2)
        out.append(_unescape_dart(s_val))
    return out


# ─────────────────────────── Questions ───────────────────────────

def extract_questions() -> list[dict]:
    text = QUESTIONS_SEED.read_text(encoding="utf-8")
    blocks = text.split("Question(")[1:]
    out: list[dict] = []
    for block in blocks:
        qid       = _find_quoted("id", block)
        category  = _find_enum("category", "QuestionCategory", block)
        prompt    = _find_quoted("prompt", block)
        options   = _find_options(block)
        correct   = _find_int("correctIndex", block)
        difficulty = _find_int("difficulty", block)
        if not all([qid, category, prompt, options, correct is not None, difficulty]):
            continue
        out.append({
            "id":             qid,
            "category":       category,
            "prompt":         prompt,
            "options":        options,
            "correct_index":  correct,
            "difficulty":     difficulty,
            "attribution":    _find_quoted("attribution", block),
            "explanation":    _find_quoted("explanation", block),
            "philosopher_id": _find_quoted("philosopherId", block),
            "topic_key":      _find_quoted("topicKey", block),
        })
    return out


# ─────────────────────────── Crossword Puzzles ───────────────────────────
# Die Puzzles werden als `final puzzleXyz = CrosswordPuzzle(...)` deklariert.
# Innerhalb gibt es eine words-Liste mit CrosswordWord(...)-Einträgen.

_PUZZLE_RE = re.compile(
    r"final\s+\w+\s*=\s*CrosswordPuzzle\((?P<body>.*?)\);\s*$",
    re.MULTILINE | re.DOTALL,
)


def _extract_word_blocks(words_section: str) -> list[str]:
    """Return one body-string per CrosswordWord( … ) call in [words_section]."""
    out: list[str] = []
    needle = "CrosswordWord("
    idx = 0
    while True:
        start = words_section.find(needle, idx)
        if start < 0:
            break
        # Find matching close paren by counting depth.
        depth = 0
        i = start + len(needle)
        body_start = i
        while i < len(words_section):
            ch = words_section[i]
            if ch == "(":
                depth += 1
            elif ch == ")":
                if depth == 0:
                    out.append(words_section[body_start:i])
                    idx = i + 1
                    break
                depth -= 1
            i += 1
        else:
            break  # unbalanced — bail
    return out


def extract_crossword_puzzles() -> list[dict]:
    text = CROSSWORD_SEED.read_text(encoding="utf-8")
    out: list[dict] = []
    for m in _PUZZLE_RE.finditer(text):
        body = m.group("body")
        pid       = _find_quoted("id", body)
        title     = _find_quoted("title", body)
        theme     = _find_quoted("theme", body)
        grid_rows = _find_int("gridRows", body)
        grid_cols = _find_int("gridCols", body)
        difficulty = _find_quoted("difficulty", body) or "Mittel"
        est_min   = _find_int("estimatedMinutes", body) or 8
        source    = _find_quoted("sourceLabel", body) or "Eleutheria"

        # Words-Liste extrahieren
        words_m = re.search(r"words:\s*\[(.+)\]", body, re.DOTALL)
        if not words_m:
            continue
        word_blocks = _extract_word_blocks(words_m.group(1))
        words: list[dict] = []
        for wb in word_blocks:
            wid       = _find_quoted("id", wb)
            answer    = _find_quoted("answer", wb)
            clue      = _find_quoted("clue", wb)
            row       = _find_int("row", wb)
            col       = _find_int("col", wb)
            direction = _find_enum("direction", "WordDirection", wb)
            if not all([wid, answer, clue, row is not None, col is not None, direction]):
                continue
            words.append({
                "id":          wid,
                "answer":      answer,
                "clue":        clue,
                "row":         row,
                "col":         col,
                "direction":   direction,
                "attribution": _find_quoted("attribution", wb),
                "explanation": _find_quoted("explanation", wb),
            })
        if not all([pid, title, theme, grid_rows, grid_cols]) or not words:
            continue
        out.append({
            "id":                pid,
            "title":             title,
            "theme":             theme,
            "grid_rows":         grid_rows,
            "grid_cols":         grid_cols,
            "difficulty":        difficulty,
            "estimated_minutes": est_min,
            "source_label":      source,
            "words":             words,
        })
    return out


# ─────────────────────────── Supabase Upsert ───────────────────────────

def upsert(table: str, rows: list[dict], url: str, key: str) -> None:
    if not rows:
        print(f"  · {table}: keine Zeilen – übersprungen")
        return
    endpoint = f"{url.rstrip('/')}/rest/v1/{table}"
    body = json.dumps(rows, ensure_ascii=False).encode("utf-8")
    req = urllib.request.Request(
        endpoint,
        data=body,
        method="POST",
        headers={
            "apikey":        key,
            "Authorization": f"Bearer {key}",
            "Content-Type":  "application/json",
            "Prefer":        "resolution=merge-duplicates,return=minimal",
        },
    )
    try:
        with urllib.request.urlopen(req) as resp:  # noqa: S310 (controlled URL)
            status = resp.status
        print(f"  · {table}: {len(rows)} Zeilen upserted (HTTP {status})")
    except urllib.error.HTTPError as e:  # type: ignore[attr-defined]
        body = e.read().decode("utf-8", errors="replace")
        print(f"  ! {table}: FEHLER HTTP {e.code} — {body}", file=sys.stderr)
        sys.exit(1)


def main() -> None:
    url = os.environ.get("SUPABASE_URL", "").strip()
    key = os.environ.get("SUPABASE_SERVICE_ROLE_KEY", "").strip()
    if not url or not key:
        print(
            "SUPABASE_URL und SUPABASE_SERVICE_ROLE_KEY müssen gesetzt sein.\n"
            "Siehe Header dieses Skripts.",
            file=sys.stderr,
        )
        sys.exit(2)

    questions = extract_questions()
    puzzles   = extract_crossword_puzzles()
    print(f"-> {len(questions)} Fragen aus {QUESTIONS_SEED.name} extrahiert")
    print(f"-> {len(puzzles)} Crossword-Puzzles aus {CROSSWORD_SEED.name} extrahiert")

    print("-> Push nach Supabase…")
    upsert("questions",         questions, url, key)
    upsert("crossword_puzzles", puzzles,   url, key)
    print("Fertig.")


if __name__ == "__main__":
    main()

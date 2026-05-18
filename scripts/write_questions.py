"""Write a JSON question pool back to questions_seed.dart.

Reads cms/data/questions.json (the CMS-edited version) and emits a
fresh, well-formatted lib/data/seed/questions_seed.dart.

A timestamped backup of the existing seed is created next to it.

CLI:
    python scripts/write_questions.py
    python scripts/write_questions.py --input some/other.json
"""
import argparse
import json
import shutil
from datetime import datetime
from pathlib import Path

ROOT     = Path(__file__).resolve().parent.parent
SEED     = ROOT / "lib" / "data" / "seed" / "questions_seed.dart"
JSON_IN  = ROOT / "cms" / "data" / "questions.json"
PHIL_JSON = ROOT / "cms" / "data" / "philosophers.json"

CATEGORY_ORDER = [
    "quoteToPhilosopher",
    "workToAuthor",
    "philosopherToEra",
    "conceptToSchool",
    "completeQuote",
    "whoCriticizedWhom",
]

CATEGORY_HEADERS = {
    "quoteToPhilosopher": "ZITAT -> PHILOSOPH",
    "workToAuthor":       "WERK -> AUTOR",
    "philosopherToEra":   "PHILOSOPH -> EPOCHE",
    "conceptToSchool":    "BEGRIFF -> SCHULE",
    "completeQuote":      "ZITAT VERVOLLSTAENDIGEN",
    "whoCriticizedWhom":  "KRITIK & STREIT",
}

FILE_HEADER = '''import '../models/question.dart';

/// Hand-curated MVP question pool.
///
/// Difficulty: 1 (Anfaenger) ... 5 (Meister).
/// Categories cover the six gameplay variants.
///
/// EDITING NOTE: do NOT hand-edit this file when possible. Use the local
/// CMS in `cms/` and re-export. The CMS round-trips this file via
/// scripts/extract_questions.py and scripts/write_questions.py.
const kQuestions = <Question>[
'''

FILE_FOOTER = '''];

/// Total questions in the seed pool - useful for the splash counter.
int get kTotalSeedQuestions => kQuestions.length;
'''


def dart_string(s: str) -> str:
    """Render a Python str as a Dart string literal.

    Prefers single quotes; switches to double quotes if the string
    contains an unescaped single quote and no double quote — cuts down
    on backslash noise. As a last resort, falls back to single quotes
    with explicit \' escapes.
    """
    has_single = "'" in s
    has_double = '"' in s
    if has_single and not has_double:
        body = s.replace("\\", "\\\\").replace("\n", "\\n").replace('"', '\\"')
        return f'"{body}"'
    body = (s.replace("\\", "\\\\")
             .replace("'", "\\'")
             .replace("\n", "\\n"))
    return f"'{body}'"


def render_question(q: dict) -> str:
    indent = "  "
    inner  = "    "
    lines = [f"{indent}Question("]
    lines.append(f"{inner}id: {dart_string(q['id'])},")
    lines.append(f"{inner}category: QuestionCategory.{q['category']},")
    lines.append(f"{inner}prompt: {dart_string(q['prompt'])},")
    opts = ", ".join(dart_string(o) for o in q["options"])
    lines.append(f"{inner}options: [{opts}],")
    lines.append(f"{inner}correctIndex: {q['correctIndex']},")
    lines.append(f"{inner}difficulty: {q['difficulty']},")
    if q.get("attribution"):
        lines.append(f"{inner}attribution: {dart_string(q['attribution'])},")
    if q.get("explanation"):
        lines.append(f"{inner}explanation: {dart_string(q['explanation'])},")
    if q.get("philosopherId"):
        lines.append(f"{inner}philosopherId: {dart_string(q['philosopherId'])},")
    if q.get("topicKey"):
        lines.append(f"{inner}topicKey: {dart_string(q['topicKey'])},")
    lines.append(f"{indent}),")
    return "\n".join(lines)


def render_section_header(label: str) -> str:
    bar = "-" * 13
    return f"  // {bar} {label} {bar}"


def load_philosopher_ids() -> set[str] | None:
    if not PHIL_JSON.exists():
        return None
    payload = json.loads(PHIL_JSON.read_text(encoding="utf-8"))
    items = payload if isinstance(payload, list) else payload.get("philosophers", [])
    return {p["id"] for p in items if p.get("id")}


def validate(
    questions: list[dict],
    philosopher_ids: set[str] | None = None,
) -> list[str]:
    """Return a list of human-readable problems. Empty = all good."""
    problems: list[str] = []
    seen_ids: set[str] = set()
    for i, q in enumerate(questions):
        prefix = f"#{i} (id={q.get('id') or '<missing>'})"
        if not q.get("id"):
            problems.append(f"{prefix}: missing id")
        elif q["id"] in seen_ids:
            problems.append(f"{prefix}: duplicate id {q['id']}")
        else:
            seen_ids.add(q["id"])
        if q.get("category") not in CATEGORY_ORDER:
            problems.append(f"{prefix}: invalid category {q.get('category')!r}")
        opts = q.get("options") or []
        if len(opts) != 4:
            problems.append(f"{prefix}: needs 4 options, got {len(opts)}")
        ci = q.get("correctIndex")
        if ci is None or ci < 0 or ci > 3:
            problems.append(f"{prefix}: correctIndex must be 0..3, got {ci}")
        d = q.get("difficulty")
        if d is None or d < 1 or d > 5:
            problems.append(f"{prefix}: difficulty must be 1..5, got {d}")
        if not q.get("prompt"):
            problems.append(f"{prefix}: empty prompt")
        pid = q.get("philosopherId")
        if pid and philosopher_ids is not None and pid not in philosopher_ids:
            problems.append(f"{prefix}: unknown philosopherId {pid!r}")
    return problems


def render(questions: list[dict]) -> str:
    by_cat: dict[str, list[dict]] = {c: [] for c in CATEGORY_ORDER}
    for q in questions:
        by_cat.setdefault(q["category"], []).append(q)
    body_parts = [FILE_HEADER]
    for cat in CATEGORY_ORDER:
        bucket = by_cat.get(cat, [])
        if not bucket:
            continue
        body_parts.append(render_section_header(CATEGORY_HEADERS[cat]))
        for q in bucket:
            body_parts.append(render_question(q))
    body_parts.append(FILE_FOOTER)
    return "\n".join(body_parts)


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--input", type=Path, default=JSON_IN)
    parser.add_argument(
        "--no-backup", action="store_true",
        help="skip the timestamped backup (use only in CI)",
    )
    args = parser.parse_args()

    payload = json.loads(args.input.read_text(encoding="utf-8"))
    questions = payload["questions"] if isinstance(payload, dict) else payload

    problems = validate(questions, philosopher_ids=load_philosopher_ids())
    if problems:
        print(f"Validation failed ({len(problems)} problems):")
        for p in problems:
            print(f"  - {p}")
        raise SystemExit(1)

    if SEED.exists() and not args.no_backup:
        stamp = datetime.now().strftime("%Y%m%d-%H%M%S")
        backup = SEED.with_suffix(f".dart.bak.{stamp}")
        shutil.copy2(SEED, backup)
        print(f"Backup: {backup.name}")

    SEED.write_text(render(questions), encoding="utf-8")
    print(f"Wrote {len(questions)} questions -> {SEED}")


if __name__ == "__main__":
    main()

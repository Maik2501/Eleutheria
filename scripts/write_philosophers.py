"""Write a JSON philosopher list back to philosophers_seed.dart.

Reads cms/data/philosophers.json (the CMS-edited version) and emits a
fresh, well-formatted lib/data/seed/philosophers_seed.dart.

A timestamped backup of the existing seed is created next to it.

CLI:
    python scripts/write_philosophers.py
    python scripts/write_philosophers.py --input some/other.json
"""
import argparse
import json
import shutil
from datetime import datetime
from pathlib import Path

ROOT     = Path(__file__).resolve().parent.parent
SEED     = ROOT / "lib" / "data" / "seed" / "philosophers_seed.dart"
JSON_IN  = ROOT / "cms" / "data" / "philosophers.json"

VALID_ERAS = {
    "antike",
    "mittelalter",
    "renaissance",
    "aufklaerung",
    "neunzehntes",
    "modernePostmoderne",
    "zeitgenoessisch",
}

FILE_HEADER = '''import '../models/philosopher.dart';

/// Curated set of philosophers covering the canonical Western tradition plus
/// influential 20th/21st-century voices. Extend freely via the CMS.
///
/// EDITING NOTE: prefer the local CMS in `cms/`. Round-trips via
/// scripts/extract_questions.py and scripts/write_philosophers.py.
const kPhilosophers = <Philosopher>[
'''

FILE_FOOTER = '''];

/// Quick lookup helper.
Map<String, Philosopher> philosopherById = {
  for (final p in kPhilosophers) p.id: p,
};
'''


def dart_string(s: str) -> str:
    has_single = "'" in s
    has_double = '"' in s
    if has_single and not has_double:
        body = s.replace("\\", "\\\\").replace("\n", "\\n").replace('"', '\\"')
        return f'"{body}"'
    body = (s.replace("\\", "\\\\")
             .replace("'", "\\'")
             .replace("\n", "\\n"))
    return f"'{body}'"


def render_philosopher(p: dict) -> str:
    indent = "  "
    inner  = "    "
    lines = [f"{indent}Philosopher("]
    lines.append(f"{inner}id: {dart_string(p['id'])},")
    lines.append(f"{inner}name: {dart_string(p['name'])},")
    lines.append(f"{inner}years: {dart_string(p.get('years') or '')},")
    lines.append(f"{inner}era: Era.{p['era']},")
    lines.append(f"{inner}school: {dart_string(p.get('school') or '')},")
    lines.append(f"{inner}tagline: {dart_string(p.get('tagline') or '')},")
    img = p.get("imageAsset") or f"assets/images/philosophers/{p['id']}.webp"
    lines.append(f"{inner}imageAsset: {dart_string(img)},")
    aliases = p.get("aliases") or []
    if aliases:
        joined = ", ".join(dart_string(a) for a in aliases)
        lines.append(f"{inner}aliases: [{joined}],")
    lines.append(f"{indent}),")
    return "\n".join(lines)


def validate(items: list[dict]) -> list[str]:
    problems: list[str] = []
    seen_ids: set[str] = set()
    for i, p in enumerate(items):
        prefix = f"#{i} (id={p.get('id') or '<missing>'})"
        if not p.get("id"):
            problems.append(f"{prefix}: missing id")
        elif p["id"] in seen_ids:
            problems.append(f"{prefix}: duplicate id {p['id']}")
        else:
            seen_ids.add(p["id"])
        if not p.get("name"):
            problems.append(f"{prefix}: missing name")
        if p.get("era") not in VALID_ERAS:
            problems.append(
                f"{prefix}: invalid era {p.get('era')!r}, "
                f"expected one of {sorted(VALID_ERAS)}"
            )
    return problems


def render(items: list[dict]) -> str:
    parts = [FILE_HEADER]
    for p in items:
        parts.append(render_philosopher(p))
    parts.append(FILE_FOOTER)
    return "\n".join(parts)


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--input", type=Path, default=JSON_IN)
    parser.add_argument("--no-backup", action="store_true")
    args = parser.parse_args()

    payload = json.loads(args.input.read_text(encoding="utf-8"))
    items = payload if isinstance(payload, list) else payload.get("philosophers", [])

    problems = validate(items)
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

    SEED.write_text(render(items), encoding="utf-8")
    print(f"Wrote {len(items)} philosophers -> {SEED}")


if __name__ == "__main__":
    main()

"""Tiny dev-only HTTP server for the Eleutheria question CMS.

Workflow:
  1. python cms/serve.py
  2. Open http://localhost:8765/
  3. Edit questions in the browser
  4. Click "Speichern" -> server writes back to questions_seed.dart
     (with a timestamped backup next to it).

Do NOT expose this to the internet. No auth, full file-write access.
"""
import json
import subprocess
import sys
from http.server import BaseHTTPRequestHandler, HTTPServer
from pathlib import Path
from urllib.parse import urlparse

ROOT     = Path(__file__).resolve().parent.parent
CMS_DIR  = ROOT / "cms"
DATA_DIR = CMS_DIR / "data"
SCRIPTS  = ROOT / "scripts"
JSON_QUESTIONS    = DATA_DIR / "questions.json"
JSON_PHILOSOPHERS = DATA_DIR / "philosophers.json"
PORT              = 8765

CONTENT_TYPES = {
    ".html": "text/html; charset=utf-8",
    ".css":  "text/css; charset=utf-8",
    ".js":   "application/javascript; charset=utf-8",
    ".json": "application/json; charset=utf-8",
    ".png":  "image/png",
    ".webp": "image/webp",
    ".svg":  "image/svg+xml",
}


def run_script(name: str, *extra: str) -> tuple[int, str]:
    proc = subprocess.run(
        [sys.executable, str(SCRIPTS / name), *extra],
        capture_output=True, text=True, encoding="utf-8",
    )
    return proc.returncode, (proc.stdout or "") + (proc.stderr or "")


def extract_now() -> None:
    rc, out = run_script("extract_questions.py")
    print(out.rstrip())
    if rc != 0:
        raise SystemExit(f"extract_questions.py failed (rc={rc})")


class Handler(BaseHTTPRequestHandler):
    # Override default logging — quieter and prefixed.
    def log_message(self, fmt: str, *args) -> None:  # noqa: ANN001
        sys.stderr.write(f"[cms] {self.address_string()} - {fmt % args}\n")

    def _send_json(self, status: int, payload: dict) -> None:
        body = json.dumps(payload, ensure_ascii=False).encode("utf-8")
        self.send_response(status)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def _send_file(self, path: Path) -> None:
        if not path.exists() or not path.is_file():
            self.send_error(404, f"Not found: {path.name}")
            return
        ctype = CONTENT_TYPES.get(path.suffix, "application/octet-stream")
        data = path.read_bytes()
        self.send_response(200)
        self.send_header("Content-Type", ctype)
        self.send_header("Content-Length", str(len(data)))
        self.send_header("Cache-Control", "no-store")
        self.end_headers()
        self.wfile.write(data)

    # ───── GET ─────
    def do_GET(self) -> None:  # noqa: N802
        url = urlparse(self.path)
        path = url.path
        if path == "/" or path == "/index.html":
            self._send_file(CMS_DIR / "index.html")
            return
        if path == "/style.css":
            self._send_file(CMS_DIR / "style.css")
            return
        if path == "/app.js":
            self._send_file(CMS_DIR / "app.js")
            return
        if path.startswith("/data/"):
            self._send_file(DATA_DIR / Path(path).name)
            return
        self.send_error(404, f"No route for {path}")

    # ───── POST ─────
    def do_POST(self) -> None:  # noqa: N802
        url = urlparse(self.path)
        path = url.path
        length = int(self.headers.get("Content-Length", "0") or "0")
        body = self.rfile.read(length).decode("utf-8") if length else ""

        if path == "/save":
            self._handle_save_questions(body)
            return
        if path == "/save-philosophers":
            self._handle_save_philosophers(body)
            return
        if path == "/reload":
            try:
                extract_now()
                self._send_json(200, {"ok": True})
            except SystemExit as e:
                self._send_json(500, {"ok": False, "error": str(e)})
            return
        self.send_error(404, f"No route for {path}")

    def _handle_save_questions(self, body: str) -> None:
        try:
            payload = json.loads(body)
        except json.JSONDecodeError as e:
            self._send_json(400, {"ok": False, "error": f"invalid JSON: {e}"})
            return
        if "questions" not in payload:
            self._send_json(400, {"ok": False, "error": "missing 'questions'"})
            return

        # Persist the incoming state to JSON first — file on disk matches what
        # the user saw, even if the writer fails.
        JSON_QUESTIONS.parent.mkdir(parents=True, exist_ok=True)
        JSON_QUESTIONS.write_text(
            json.dumps(payload, ensure_ascii=False, indent=2),
            encoding="utf-8",
        )

        rc, out = run_script("write_questions.py")
        if rc != 0:
            self._send_json(500, {"ok": False, "error": out})
            return
        self._send_json(200, {
            "ok": True,
            "count": len(payload["questions"]),
            "log": out.strip(),
        })

    def _handle_save_philosophers(self, body: str) -> None:
        try:
            payload = json.loads(body)
        except json.JSONDecodeError as e:
            self._send_json(400, {"ok": False, "error": f"invalid JSON: {e}"})
            return
        items = (
            payload.get("philosophers", []) if isinstance(payload, dict)
            else payload
        )

        JSON_PHILOSOPHERS.parent.mkdir(parents=True, exist_ok=True)
        JSON_PHILOSOPHERS.write_text(
            json.dumps(items, ensure_ascii=False, indent=2),
            encoding="utf-8",
        )

        rc, out = run_script("write_philosophers.py")
        if rc != 0:
            self._send_json(500, {"ok": False, "error": out})
            return
        # Re-extract so the questions.json/philosophers.js the UI loads on
        # next reload reflects the new state.
        extract_now()
        self._send_json(200, {
            "ok": True,
            "count": len(items),
            "log": out.strip(),
        })


def main() -> None:
    print(f"[cms] extracting fresh state from seed...")
    extract_now()
    print(f"[cms] http://localhost:{PORT}/")
    print(f"[cms] Ctrl+C to stop")
    HTTPServer(("127.0.0.1", PORT), Handler).serve_forever()


if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        print("\n[cms] bye")

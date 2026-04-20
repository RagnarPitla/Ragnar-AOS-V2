#!/usr/bin/env python3
"""RAOS V2 Dashboard Server — Pure Python 3, no dependencies."""

import argparse
import json
import os
import signal
import sys
import time
import webbrowser
from datetime import datetime, timezone
from http.server import HTTPServer, SimpleHTTPRequestHandler
from pathlib import Path
from urllib.parse import parse_qs

START_TIME = time.time()
DASHBOARD_DIR = Path(__file__).parent.resolve()
THEMES_DIR = DASHBOARD_DIR / "themes"

# Hardcoded fallback theme if no theme files exist
DEFAULT_THEME = {
    "name": "Default",
    "colors": {
        "primary": "#00d4ff", "secondary": "#a78bfa", "bg": "#0a0a1a",
        "text": "#e0e0e0", "accent": "#00d4ff", "success": "#00ff88",
        "warning": "#ffd60a", "error": "#ff4757"
    },
    "fonts": {
        "heading": "-apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif",
        "body": "-apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif"
    },
    "logo_text": "RAOS V3"
}


def load_themes() -> list[dict]:
    """Load all theme JSON files from themes/ directory."""
    themes = []
    if THEMES_DIR.is_dir():
        for tf in sorted(THEMES_DIR.glob("*.json")):
            try:
                themes.append(json.loads(tf.read_text()))
            except Exception:
                pass
    if not themes:
        themes = [DEFAULT_THEME]
    return themes


def get_theme(name: str | None = None) -> dict:
    """Get a specific theme by name, or the first available."""
    themes = load_themes()
    if name:
        for t in themes:
            if t.get("name", "").lower() == name.lower():
                return t
    return themes[0]


def detect_runtime(project_root: Path) -> str:
    if (project_root / ".github").is_dir():
        return "GitHub Copilot CLI"
    if (project_root / ".claude").is_dir():
        return "Claude Code"
    return "Unknown"


def find_tasks_json(project_root: Path) -> Path | None:
    for p in [project_root / ".github" / "tasks.json", project_root / ".claude" / "tasks.json"]:
        if p.is_file():
            return p
    return None


def list_agents(project_root: Path) -> list[str]:
    for d in [project_root / ".github" / "agents", project_root / ".claude" / "agents"]:
        if d.is_dir():
            return sorted(p.stem for p in d.glob("*.md"))
    return []


def get_os_name(project_root: Path) -> str:
    for cfg_path in [project_root / ".github" / "config.json", project_root / ".claude" / "config.json"]:
        if cfg_path.is_file():
            try:
                return json.loads(cfg_path.read_text()).get("os_name", "")
            except Exception:
                pass
    onboard = DASHBOARD_DIR / "onboard-result.json"
    if onboard.is_file():
        try:
            return json.loads(onboard.read_text()).get("os_name", "")
        except Exception:
            pass
    return ""


class DashboardHandler(SimpleHTTPRequestHandler):
    project_root: Path = Path(".")

    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=str(DASHBOARD_DIR), **kwargs)

    def end_headers(self):
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Access-Control-Allow-Methods", "GET, POST, OPTIONS")
        self.send_header("Access-Control-Allow-Headers", "Content-Type")
        super().end_headers()

    def do_OPTIONS(self):
        self.send_response(200)
        self.end_headers()

    def _json_response(self, data, status=200):
        body = json.dumps(data, indent=2).encode()
        self.send_response(status)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def do_GET(self):
        pr = self.__class__.project_root
        if self.path == "/api/tasks":
            tf = find_tasks_json(pr)
            if tf:
                try:
                    self._json_response(json.loads(tf.read_text()))
                except Exception as e:
                    self._json_response({"error": str(e)}, 500)
            else:
                self._json_response({"objective": None, "tasks": []})
        elif self.path == "/api/config":
            self._json_response({
                "os_name": get_os_name(pr),
                "specialists": list_agents(pr),
                "runtime": detect_runtime(pr),
            })
        elif self.path == "/api/status":
            self._json_response({
                "uptime_seconds": round(time.time() - START_TIME, 1),
                "project_root": str(pr),
                "runtime": detect_runtime(pr),
                "started": datetime.fromtimestamp(START_TIME, tz=timezone.utc).isoformat(),
            })
        elif self.path == "/api/themes":
            self._json_response(load_themes())
        elif self.path.startswith("/api/theme"):
            # /api/theme or /api/theme?name=Dark
            from urllib.parse import urlparse, parse_qs as pqs
            qs = pqs(urlparse(self.path).query)
            name = qs.get("name", [None])[0]
            self._json_response(get_theme(name))
        else:
            super().do_GET()

    def do_POST(self):
        if self.path == "/api/onboard":
            length = int(self.headers.get("Content-Length", 0))
            body = self.rfile.read(length)
            try:
                data = json.loads(body)
            except Exception:
                data = dict(parse_qs(body.decode()))
            data["onboarded_at"] = datetime.now(tz=timezone.utc).isoformat()
            out = DASHBOARD_DIR / "onboard-result.json"
            out.write_text(json.dumps(data, indent=2))
            self._json_response({"ok": True, "saved": str(out)})
        else:
            self.send_error(404)

    def log_message(self, fmt, *args):
        sys.stderr.write(f"\033[90m[dashboard] {fmt % args}\033[0m\n")


def main():
    ap = argparse.ArgumentParser(description="RAOS V2 Dashboard Server")
    ap.add_argument("--port", type=int, default=9200)
    ap.add_argument("--project", type=str, default=str(DASHBOARD_DIR.parent))
    ap.add_argument("--no-browser", action="store_true")
    args = ap.parse_args()

    DashboardHandler.project_root = Path(args.project).resolve()
    server = HTTPServer(("127.0.0.1", args.port), DashboardHandler)

    def shutdown(sig, frame):
        print("\n\033[36m[RAOS] Shutting down dashboard server...\033[0m")
        server.shutdown()
        sys.exit(0)

    signal.signal(signal.SIGINT, shutdown)
    signal.signal(signal.SIGTERM, shutdown)

    url = f"http://127.0.0.1:{args.port}"
    rt = detect_runtime(DashboardHandler.project_root)
    print(f"\033[36m╔══════════════════════════════════════════╗\033[0m")
    print(f"\033[36m║  RAOS V2 — Mission Control Dashboard     ║\033[0m")
    print(f"\033[36m╠══════════════════════════════════════════╣\033[0m")
    print(f"\033[36m║\033[0m  URL:     \033[1m{url:<30}\033[0m\033[36m║\033[0m")
    print(f"\033[36m║\033[0m  Project: \033[90m{str(DashboardHandler.project_root)[:30]:<30}\033[0m\033[36m║\033[0m")
    print(f"\033[36m║\033[0m  Runtime: {rt:<30}\033[36m║\033[0m")
    print(f"\033[36m╚══════════════════════════════════════════╝\033[0m")

    if not args.no_browser:
        webbrowser.open(url)

    server.serve_forever()


if __name__ == "__main__":
    main()

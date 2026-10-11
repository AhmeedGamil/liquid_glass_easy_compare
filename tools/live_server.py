#!/usr/bin/env python3
"""Live tuning for side_by_side: keeps `flutter run` up on the simulator and
serves it over HTTP, so a tweak is a hot reload instead of a rebuild.

    live_server.py --udid <sim> --port 8787 --key <secret>

Every request needs the header `X-Key: <secret>`.

    POST /file?path=lib/apple_match/x.dart   body = new file; hot reloads
    POST /reload            hot reload       POST /restart   hot restart
    GET  /shot?scene=<name>&look=light|dark&settle=1.5     PNG of the screen
    GET  /log?lines=200     tail of the flutter run output
    POST /stop              end the session (the job then finishes)

    GET  /                  the tuner page (tools/tuner.html), no key needed
    GET  /api/tune          every apple_match knob with its value
    POST /api/tune          {id: value} changes knobs   POST /api/tune/reset
    GET  /api/shot          like /shot; fmt=jpg&w=<px> shrinks it

The key may also come as `?k=<secret>`.
"""

import argparse
import hmac
import os
import subprocess
import threading
import time
import urllib.request
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from urllib.parse import parse_qs, urlparse

TUNER_PAGE = os.path.join(os.path.dirname(os.path.abspath(__file__)), "tuner.html")
APP = "http://127.0.0.1:8790"
APP_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "side_by_side"))
LIB_DIR = os.path.join(APP_DIR, "lib")


class Flutter:
    """One `flutter run`, driven through its stdin."""

    def __init__(self, udid):
        self.lines = []
        self.lock = threading.Lock()
        self.cond = threading.Condition(self.lock)
        self.proc = subprocess.Popen(
            ["flutter", "run", "-d", udid, "--debug"],
            cwd=APP_DIR, stdin=subprocess.PIPE, stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT, text=True, bufsize=1)
        threading.Thread(target=self._pump, daemon=True).start()

    def _pump(self):
        for line in self.proc.stdout:
            print("[flutter] " + line, end="", flush=True)
            with self.cond:
                self.lines.append(line.rstrip("\n"))
                self.cond.notify_all()

    def wait_for(self, needles, start, timeout):
        """First line after index [start] holding any of [needles]."""
        end = time.time() + timeout
        with self.cond:
            while True:
                for line in self.lines[start:]:
                    if any(n in line for n in needles):
                        return line
                left = end - time.time()
                if left <= 0 or self.proc.poll() is not None:
                    return None
                self.cond.wait(left)

    def send(self, key, needles, timeout=90):
        with self.lock:
            start = len(self.lines)
        self.proc.stdin.write(key)
        self.proc.stdin.flush()
        hit = self.wait_for(needles, start, timeout)
        with self.lock:
            out = self.lines[start:]
        return hit, "\n".join(out[-60:])

    def tail(self, n):
        with self.lock:
            return "\n".join(self.lines[-n:])


RELOADED = ["Reloaded ", "Restarted application", "Error", "error:", "Try again after fixing"]


def make_handler(flutter, udid, key, state):
    class Handler(BaseHTTPRequestHandler):
        def log_message(self, fmt, *args):
            print("[http] " + fmt % args, flush=True)

        def _reply(self, code, body, ctype="text/plain; charset=utf-8"):
            data = body if isinstance(body, bytes) else body.encode()
            self.send_response(code)
            self.send_header("Content-Type", ctype)
            self.send_header("Content-Length", str(len(data)))
            self.end_headers()
            self.wfile.write(data)

        def _authed(self):
            given = self.headers.get("X-Key") or parse_qs(urlparse(self.path).query).get("k", [""])[0]
            if hmac.compare_digest(given, key):
                return True
            self._reply(403, "bad key")
            return False

        def _app(self, method, path, body=None):
            req = urllib.request.Request(APP + path, data=body, method=method,
                                         headers={"Content-Type": "application/json"})
            try:
                with urllib.request.urlopen(req, timeout=30) as r:
                    self._reply(200, r.read(), r.headers.get("Content-Type", "text/plain"))
            except Exception as e:  # noqa: BLE001
                self._reply(502, f"app: {e}")

        def do_GET(self):
            u = urlparse(self.path)
            if u.path in ("/", "/tuner"):
                with open(TUNER_PAGE, "rb") as f:
                    self._reply(200, f.read(), "text/html; charset=utf-8")
                return
            if not self._authed():
                return
            q = {k: v[0] for k, v in parse_qs(u.query).items()}
            if u.path == "/api/tune":
                self._app("GET", "/tune")
            elif u.path in ("/shot", "/api/shot"):
                self._shot(q)
            elif u.path == "/log":
                self._reply(200, flutter.tail(int(q.get("lines", 200))))
            else:
                self._reply(404, "unknown")

        def _shot(self, q):
            # One screenshot at a time: each one switches theme and scene.
            with state["shot_lock"]:
                self._shot_locked(q)

        def _shot_locked(self, q):
            look = q.get("look")
            if look in ("light", "dark") and look != state.get("look"):
                subprocess.run(["xcrun", "simctl", "ui", udid, "appearance", look])
                state["look"] = look
                # The native views pick up a theme change late.
                time.sleep(3)
            scene = q.get("scene")
            if scene:
                try:
                    with urllib.request.urlopen(
                            f"http://127.0.0.1:8790/scene?name={scene}", timeout=20) as r:
                        r.read()
                except Exception as e:  # noqa: BLE001
                    self._reply(500, f"scene switch failed: {e}")
                    return
            time.sleep(float(q.get("settle", 1.5)))
            path = f"/tmp/shot-{time.time_ns()}.png"
            subprocess.run(["xcrun", "simctl", "io", udid, "screenshot", path],
                           capture_output=True)
            ctype = "image/png"
            if q.get("fmt") == "jpg":
                jpg = path[:-4] + ".jpg"
                subprocess.run(["sips", "-s", "format", "jpeg", "-s", "formatOptions", "80",
                                "--resampleWidth", q.get("w", "800"), path, "--out", jpg],
                               capture_output=True)
                os.remove(path)
                path, ctype = jpg, "image/jpeg"
            with open(path, "rb") as f:
                data = f.read()
            os.remove(path)
            self._reply(200, data, ctype)

        def do_POST(self):
            if not self._authed():
                return
            u = urlparse(self.path)
            q = {k: v[0] for k, v in parse_qs(u.query).items()}
            body = self.rfile.read(int(self.headers.get("Content-Length", 0)))
            if u.path == "/api/tune":
                self._app("POST", "/tune", body)
            elif u.path == "/api/tune/reset":
                self._app("POST", "/tune/reset", b"")
            elif u.path == "/file":
                target = os.path.abspath(os.path.join(APP_DIR, q.get("path", "")))
                if not target.startswith(LIB_DIR + os.sep) or not target.endswith(".dart"):
                    self._reply(400, "only .dart files under lib/")
                    return
                os.makedirs(os.path.dirname(target), exist_ok=True)
                with open(target, "wb") as f:
                    f.write(body)
                if q.get("reload", "1") == "0":
                    self._reply(200, "written")
                    return
                hit, out = flutter.send("r", RELOADED)
                self._reply(200 if hit and "Reloaded" in hit else 500, out)
            elif u.path == "/reload":
                hit, out = flutter.send("r", RELOADED)
                self._reply(200 if hit and "Reloaded" in hit else 500, out)
            elif u.path == "/restart":
                hit, out = flutter.send("R", RELOADED)
                self._reply(200 if hit and "Restarted" in hit else 500, out)
            elif u.path == "/stop":
                self._reply(200, "stopping")
                state["stop"].set()
            else:
                self._reply(404, "unknown")

    return Handler


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--udid", required=True)
    ap.add_argument("--port", type=int, default=8787)
    ap.add_argument("--key", required=True)
    ap.add_argument("--minutes", type=float, default=120)
    args = ap.parse_args()

    flutter = Flutter(args.udid)
    state = {"stop": threading.Event(), "look": None, "shot_lock": threading.Lock()}
    # Served from the start, so /log shows the first build as it goes.
    server = ThreadingHTTPServer(("127.0.0.1", args.port),
                                 make_handler(flutter, args.udid, args.key, state))
    threading.Thread(target=server.serve_forever, daemon=True).start()
    print(f"serving on {args.port}", flush=True)
    ready = flutter.wait_for(["Flutter run key commands", "Error launching", "Could not"], 0, 1500)
    print(f"flutter run: {ready}", flush=True)
    state["stop"].wait(args.minutes * 60)
    flutter.proc.stdin.write("q")
    flutter.proc.stdin.flush()
    time.sleep(3)
    server.shutdown()


if __name__ == "__main__":
    main()

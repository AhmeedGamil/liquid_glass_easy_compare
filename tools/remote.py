#!/usr/bin/env python3
"""The iPhone in a browser: serves tools/remote.html and proxies WebDriverAgent.

    remote.py [--port 8080]

/wda/<path> goes to WebDriverAgent's HTTP API (127.0.0.1:8100) and /stream
to its MJPEG screen stream (127.0.0.1:9100), so the page needs one origin.
Both read the simulator directly, so the Mac's own screen can be locked.
"""

import argparse
import http.client
import http.server
import os
import socketserver

HERE = os.path.dirname(os.path.abspath(__file__))
WDA = ("127.0.0.1", 8100)
MJPEG = ("127.0.0.1", 9100)


class Handler(http.server.BaseHTTPRequestHandler):
    protocol_version = "HTTP/1.1"

    def log_message(self, fmt, *args):
        pass

    def do_GET(self):
        if self.path in ("/", "/index.html"):
            with open(os.path.join(HERE, "remote.html"), "rb") as f:
                body = f.read()
            self._send(200, "text/html; charset=utf-8", body)
        elif self.path.startswith("/stream"):
            self._stream()
        elif self.path.startswith("/wda/"):
            self._proxy("GET")
        else:
            self._send(404, "text/plain", b"not found")

    def do_POST(self):
        if self.path.startswith("/wda/"):
            self._proxy("POST")
        else:
            self._send(404, "text/plain", b"not found")

    def do_DELETE(self):
        if self.path.startswith("/wda/"):
            self._proxy("DELETE")
        else:
            self._send(404, "text/plain", b"not found")

    def _send(self, code, ctype, body):
        self.send_response(code)
        self.send_header("Content-Type", ctype)
        self.send_header("Content-Length", str(len(body)))
        self.send_header("Cache-Control", "no-store")
        self.end_headers()
        self.wfile.write(body)

    def _proxy(self, method):
        length = int(self.headers.get("Content-Length") or 0)
        body = self.rfile.read(length) if length else None
        conn = http.client.HTTPConnection(*WDA, timeout=120)
        try:
            conn.request(method, self.path[len("/wda"):], body=body,
                         headers={"Content-Type": "application/json"})
            res = conn.getresponse()
            data = res.read()
            self._send(res.status, res.getheader("Content-Type", "application/json"), data)
        except OSError as e:
            self._send(502, "text/plain", str(e).encode())
        finally:
            conn.close()

    def _stream(self):
        conn = http.client.HTTPConnection(*MJPEG, timeout=30)
        try:
            conn.request("GET", "/")
            res = conn.getresponse()
            self.send_response(200)
            self.send_header("Content-Type", res.getheader("Content-Type"))
            self.send_header("Cache-Control", "no-store")
            self.send_header("Connection", "close")
            self.end_headers()
            while True:
                chunk = res.read1(65536)
                if not chunk:
                    break
                self.wfile.write(chunk)
        except OSError:
            pass
        finally:
            conn.close()
            self.close_connection = True


class Server(socketserver.ThreadingMixIn, http.server.HTTPServer):
    daemon_threads = True
    allow_reuse_address = True


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--port", type=int, default=8080)
    args = ap.parse_args()
    Server(("0.0.0.0", args.port), Handler).serve_forever()


if __name__ == "__main__":
    main()

"""Receive Grafana notifications from the local HTTPS reverse proxy."""

import hmac
from http.server import BaseHTTPRequestHandler, HTTPServer
import json
import os
from pathlib import Path
import subprocess
import sys

WEBHOOK_PATH = "/grafana/alerts"
MAX_BODY = 1024 * 1024
ENQUEUE_TIMEOUT_SECONDS = 5


def serve(port, enqueue):
    token_file = Path(os.environ["CREDENTIALS_DIRECTORY"]) / "grafana-token"
    token = token_file.read_bytes().strip()
    if not token or any(not 33 <= byte <= 126 for byte in token):
        raise ValueError("Invalid Grafana bearer token")
    authorization = b"Bearer " + token

    class Receiver(BaseHTTPRequestHandler):
        def setup(self):
            self.request.settimeout(10)
            super().setup()

        def reply(self, status):
            self.send_response(status)
            self.send_header("Content-Length", "0")
            self.end_headers()

        def do_POST(self):
            if self.path != WEBHOOK_PATH:
                return self.reply(404)
            headers = self.headers.get_all("Authorization", [])
            if len(headers) != 1 or not hmac.compare_digest(
                headers[0].encode("latin-1"), authorization
            ):
                return self.reply(401)
            if self.headers.get_content_type() != "application/json":
                return self.reply(415)

            lengths = self.headers.get_all("Content-Length", [])
            if len(lengths) != 1 or "Transfer-Encoding" in self.headers:
                return self.reply(400)
            try:
                length = int(lengths[0])
            except ValueError:
                return self.reply(400)
            if length <= 0:
                return self.reply(400)
            if length > MAX_BODY:
                return self.reply(413)

            try:
                body = self.rfile.read(length)
                if len(body) != length:
                    return self.reply(400)
                enqueue(json.loads(body), timeout=ENQUEUE_TIMEOUT_SECONDS)
            except TimeoutError:
                return self.reply(408)
            except (ValueError, RecursionError):
                return self.reply(400)
            except (OSError, subprocess.SubprocessError) as error:
                print(
                    f"Grafana webhook could not queue alert: {error}", file=sys.stderr
                )
                return self.reply(503)
            return self.reply(204)

    # Serialize deliveries so a retry cannot race another delivery into Kanban.
    with HTTPServer(("127.0.0.1", port), Receiver) as server:
        print(
            f"Grafana webhook listening on {server.server_address}{WEBHOOK_PATH}",
            flush=True,
        )
        server.serve_forever()

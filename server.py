#!/usr/bin/env python3
"""Small bounded TCP launcher for the Bash request handler."""

from __future__ import annotations

import argparse
import re
import socketserver
import subprocess
from pathlib import Path


ROOT = Path(__file__).resolve().parent
HEADER_LIMIT = 64 * 1024
BODY_LIMIT = 1024 * 1024
CONTENT_LENGTH = re.compile(br"(?im)^content-length:\s*([0-9]+)\s*$")


def error_response(status: str) -> bytes:
    return (
        f"HTTP/1.0 {status}\r\n"
        "Content-Type: text/plain; charset=utf-8\r\n"
        "Connection: close\r\n\r\n"
        f"{status}\n"
    ).encode()


class Handler(socketserver.BaseRequestHandler):
    def handle(self) -> None:
        self.request.settimeout(10)
        data = b""
        try:
            while b"\r\n\r\n" not in data:
                chunk = self.request.recv(4096)
                if not chunk:
                    return
                data += chunk
                if len(data) > HEADER_LIMIT:
                    self.request.sendall(error_response("431 Request Header Fields Too Large"))
                    return

            header, body = data.split(b"\r\n\r\n", 1)
            match = CONTENT_LENGTH.search(header)
            length = int(match.group(1)) if match else 0
            if length > BODY_LIMIT:
                self.request.sendall(error_response("413 Payload Too Large"))
                return
            while len(body) < length:
                chunk = self.request.recv(min(65536, length - len(body)))
                if not chunk:
                    self.request.sendall(error_response("400 Bad Request"))
                    return
                body += chunk

            result = subprocess.run(
                ["/bin/bash", str(ROOT / "app.sh")],
                cwd=ROOT,
                input=header + b"\r\n\r\n" + body[:length],
                stdout=subprocess.PIPE,
                stderr=subprocess.DEVNULL,
                timeout=15,
                check=False,
            )
            if result.returncode == 0 and result.stdout.startswith(b"HTTP/"):
                self.request.sendall(result.stdout)
            else:
                self.request.sendall(error_response("500 Internal Server Error"))
        except (OSError, subprocess.TimeoutExpired, ValueError):
            try:
                self.request.sendall(error_response("400 Bad Request"))
            except OSError:
                pass


class Server(socketserver.ThreadingTCPServer):
    allow_reuse_address = True
    daemon_threads = True


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--bind", default="127.0.0.1")
    parser.add_argument("--port", default=8080, type=int)
    args = parser.parse_args()
    if not 1 <= args.port <= 65535:
        parser.error("port must be between 1 and 65535")
    with Server((args.bind, args.port), Handler) as server:
        print(f"listening on {args.bind}:{args.port}")
        try:
            server.serve_forever()
        except KeyboardInterrupt:
            pass


if __name__ == "__main__":
    main()

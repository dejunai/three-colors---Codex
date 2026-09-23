"""Local HTTP dev server for Godot Web export with Cross-Origin headers and clean connection handling.
"""
from __future__ import annotations

import argparse
import os
import sys
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer

class GodotWebHandler(SimpleHTTPRequestHandler):
    def end_headers(self) -> None:
        # Cross-origin isolation required for SharedArrayBuffer, high-precision timers, and audio worklets
        self.send_header("Cross-Origin-Opener-Policy", "same-origin")
        self.send_header("Cross-Origin-Embedder-Policy", "require-corp")
        self.send_header("Access-Control-Allow-Origin", "*")
        super().end_headers()

    def copyfile(self, source, outputfile) -> None:
        try:
            super().copyfile(source, outputfile)
        except (ConnectionResetError, ConnectionAbortedError, BrokenPipeError):
            # Client closed connection (e.g. browser refreshed or navigated away before download completed)
            pass

    def log_message(self, format: str, *args) -> None:
        # Standard clean log output
        sys.stderr.write(f"[{self.log_date_time_string()}] {format % args}\n")

def run(port: int = 5173, directory: str = "build/web") -> None:
    handler = lambda *args, **kwargs: GodotWebHandler(*args, directory=directory, **kwargs)
    server = ThreadingHTTPServer(("0.0.0.0", port), handler)
    print(f"Serving {os.path.abspath(directory)} at http://localhost:{port} ...")
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("\nServer stopped.")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Serve Godot Web export")
    parser.add_argument("--port", type=int, default=5173, help="Port to listen on (default 5173)")
    parser.add_argument("--dir", type=str, default="build/web", help="Directory to serve (default build/web)")
    args = parser.parse_args()
    run(port=args.port, directory=args.dir)

"""Local HTTP dev server for Godot Web export.
Prefers Node.js for maximum performance and native Windows async I/O compatibility;
falls back to Python http.server if Node is unavailable.
"""
from __future__ import annotations

import argparse
import os
import shutil
import subprocess
import sys

def run_node_server(port: int, directory: str) -> bool:
    node_bin = shutil.which("node")
    if not node_bin:
        return False
    serve_js = os.path.join(os.path.dirname(__file__), "serve.js")
    if not os.path.exists(serve_js):
        return False
    try:
        subprocess.run([node_bin, serve_js, "--port", str(port), "--dir", directory], check=True)
        return True
    except KeyboardInterrupt:
        return True
    except Exception as e:
        sys.stderr.write(f"Node server failed ({e}), falling back to Python server...\n")
        return False

def run_python_server(port: int, directory: str) -> None:
    from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer

    class GodotWebHandler(SimpleHTTPRequestHandler):
        extensions_map = {
            **SimpleHTTPRequestHandler.extensions_map,
            ".wasm": "application/wasm",
            ".pck": "application/octet-stream",
            ".js": "application/javascript",
            ".json": "application/json",
            ".png": "image/png",
            ".jpg": "image/jpeg",
            ".jpeg": "image/jpeg",
            ".svg": "image/svg+xml",
            ".ico": "image/x-icon",
            ".mp3": "audio/mpeg",
            ".ogg": "audio/ogg",
            ".wav": "audio/wav",
            ".css": "text/css",
            ".ttf": "font/ttf",
        }

        def end_headers(self) -> None:
            self.send_header("Access-Control-Allow-Origin", "*")
            self.send_header("Cross-Origin-Resource-Policy", "cross-origin")
            self.send_header("Cache-Control", "no-cache")
            super().end_headers()

        def copyfile(self, source, outputfile) -> None:
            try:
                super().copyfile(source, outputfile)
            except (ConnectionResetError, ConnectionAbortedError, BrokenPipeError):
                pass

        def log_message(self, format: str, *args) -> None:
            sys.stderr.write(f"[{self.log_date_time_string()}] {format % args}\n")

    handler = lambda *args, **kwargs: GodotWebHandler(*args, directory=directory, **kwargs)
    server = ThreadingHTTPServer(("0.0.0.0", port), handler)
    print(f"Serving {os.path.abspath(directory)} at http://localhost:{port} ...", flush=True)
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("\nServer stopped.")

def run(port: int = 5173, directory: str = "build/web") -> None:
    if not run_node_server(port, directory):
        run_python_server(port, directory)

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Serve Godot Web export")
    parser.add_argument("--port", type=int, default=5173, help="Port to listen on (default 5173)")
    parser.add_argument("--dir", type=str, default="build/web", help="Directory to serve (default build/web)")
    args = parser.parse_args()
    run(port=args.port, directory=args.dir)

"""
Local dev server for BetaUp demo.
Adds COOP + COEP headers so Flutter CanvasKit works inside the iframe.

Usage:  python serve.py
Then open:  http://localhost:8000/demo.html
"""
import os
from http.server import HTTPServer, SimpleHTTPRequestHandler

class Handler(SimpleHTTPRequestHandler):
    def end_headers(self):
        self.send_header("Cross-Origin-Opener-Policy",   "same-origin")
        self.send_header("Cross-Origin-Embedder-Policy", "require-corp")
        self.send_header("Cross-Origin-Resource-Policy", "cross-origin")
        super().end_headers()

    def log_message(self, fmt, *args):
        pass  # silence per-request logs; remove this line for verbose output

os.chdir(os.path.dirname(os.path.abspath(__file__)))
port = 8000
print(f"  BetaUp demo server → http://localhost:{port}/demo.html")
print(f"  Portfolio          → http://localhost:{port}/index.html")
print(f"  Press Ctrl+C to stop.\n")
HTTPServer(("", port), Handler).serve_forever()

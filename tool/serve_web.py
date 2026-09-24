"""Serve build/web com fallback para index.html (necessário sem o '#' na URL).

Uso: python3 tool/serve_web.py [porta]
"""
import http.server
import os
import sys

ROOT = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), 'build', 'web')


class SpaHandler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=ROOT, **kwargs)

    def send_head(self):
        path = self.translate_path(self.path.split('?')[0])
        if not os.path.exists(path):
            self.path = '/index.html'
        return super().send_head()


if __name__ == '__main__':
    port = int(sys.argv[1]) if len(sys.argv) > 1 else 8765
    http.server.ThreadingHTTPServer(('localhost', port), SpaHandler).serve_forever()

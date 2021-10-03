# Python 2

import http.server

class WasmHandler(http.server.SimpleHTTPRequestHandler):
    def end_headers(self):        
        self.send_header("Cross-Origin-Opener-Policy", "same-origin")
        self.send_header("Cross-Origin-Embedder-Policy", "require-corp")
        http.server.SimpleHTTPRequestHandler.end_headers(self)


if __name__ == '__main__':
    server_address = ('', 8000)
    server_class = http.server.HTTPServer
    httpd = server_class(server_address, WasmHandler)
    print("Listening on port {}. Press Ctrl+C to stop.".format(8000))
    httpd.serve_forever()
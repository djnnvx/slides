#!/usr/bin/env bash
set -e
cd "$(dirname "$0")"

PORT=8000
URL="http://localhost:$PORT"

# free the port if a previous run is still holding it (mac + linux)
PIDS=$(lsof -ti "tcp:$PORT" 2>/dev/null || true)
[ -n "$PIDS" ] && { echo "freeing port $PORT (killing $PIDS)"; kill $PIDS 2>/dev/null || true; sleep 1; }
(command -v open >/dev/null && open "$URL" || command -v xdg-open >/dev/null && xdg-open "$URL") &
# no-store so the browser never serves a stale slide while iterating

exec python3 -c '
import sys, http.server
class H(http.server.SimpleHTTPRequestHandler):
    def end_headers(self):
        self.send_header("Cache-Control", "no-store")
        super().end_headers()
http.server.test(HandlerClass=H, port=int(sys.argv[1]))
' "$PORT"

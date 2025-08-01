#!/usr/bin/env bash
set -euo pipefail

# IP della Wyze Cam su hotspot macOS
IP="192.168.2.2"

echo "Eseguo nbstat su ${IP} (UDP/137)…"
nmap -Pn -sU \
     -p 137 \
     --script nbstat \
     "${IP}"


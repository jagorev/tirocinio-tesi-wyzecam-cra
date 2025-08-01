#!/usr/bin/env bash
set -euo pipefail

# IP della Wyze Cam su hotspot macOS
IP="192.168.2.2"

echo "Eseguo smb2-security-mode su ${IP} (TCP/445)…"
nmap -Pn -p 445 \
     --script smb2-security-mode \
     "${IP}"


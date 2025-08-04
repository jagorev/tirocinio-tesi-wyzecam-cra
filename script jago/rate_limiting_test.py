#!/usr/bin/env python3
import os
import time
import json
import requests

# Parametri
URL = "https://auth-prod.api.wyze.com/api/user/login"
EMAIL    = 'asgsdfgasgf@example.com'
PASSWORD = '£$WTGJQ$£TJG£sdagsdfh'
KEY_ID   = '042609823048602'
API_KEY  = '439680234986034'

MAX_ATTEMPTS = 200
DELAY        = 0.2  # secondi

headers = {
    "Content-Type": "application/json",
    "Accept":       "application/json",
}

payload = {
    "email":    EMAIL,
    "password": PASSWORD,
    "key_id":   KEY_ID,
    "api_key":  API_KEY
}

print(f"Flooding {URL} for rate-limit test (max {MAX_ATTEMPTS} attempts)\n")

for i in range(1, MAX_ATTEMPTS + 1):
    resp = requests.post(URL, headers=headers, json=payload)
    code = resp.status_code

    # Ferma al 429
    if code == 429:
        print(f"[{i:03d}] RATE LIMITED → HTTP {code}")
        break

    # Logga gli altri errori (400, 401, 403, 500, ecc.)
    if code != 200:
        print(f"[{i:03d}] HTTP {code} {resp.reason}")
    else:
        print(f"[{i:03d}] Unexpected success (200 OK)")

    time.sleep(DELAY)
else:
    print(f"\nNessun 429 rilevato dopo {MAX_ATTEMPTS} tentativi")


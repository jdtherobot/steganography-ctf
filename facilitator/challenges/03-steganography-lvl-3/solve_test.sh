#!/usr/bin/env bash
# Black-box solve of Steganography lvl 3 from the participant Honey.jpeg only.
# Carve -> reason-crack secret.enc -> derive 386(=3,6,8) key -> qtbl AES key -> nested AES -> flag.
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/../../.." && pwd)"
HONEY="$ROOT/participant/challenges/03-steganography-lvl-3/Honey.jpeg"
EXPECT="Flag{Y0u haVe EnCouNTeR3d a w!Ld s1eEP p@RA1y\$!S DEm0n}"
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
cd "$TMP"

# 1) Carve the concatenated payloads out of the carrier (magic-byte scan).
python3 - "$HONEY" <<'PY'
import sys
d = open(sys.argv[1], "rb").read()
salted = [i for i in range(len(d)) if d[i:i+8] == b"Salted__"]          # secret.enc, payload.enc, decoy
ffd8   = [i for i in range(len(d)) if d[i:i+2] == b"\xff\xd8"]           # cover + inner JPEG starts
inner_start = ffd8[1]
inner_end   = d.index(b"\xff\xd9", inner_start) + 2
open("nothingtoseehere.jpg","wb").write(d[inner_start:inner_end])
open("secret.enc","wb").write(d[salted[0]:d.index(b"better luck next time")])
open("payload.enc","wb").write(d[salted[1]:salted[2]])
print("carved secret.enc, nothingtoseehere.jpg, payload.enc")
PY

# 2) Reason out the weak password from the challenge narration (codename + # + 82pLm), crack the bundle.
openssl enc -d -aes-256-cbc -pbkdf2 -pass pass:'DesertStorm#82pLm' -in secret.enc -out secret_bundle.zip
unzip -oqq secret_bundle.zip           # -> qtbl.py, STEGO_KEY_386.txt, passwords.enc, iv.bin

# 3) Derive the stego key: digits of "386" -> records 3,6,8 of STEGO_KEY_386.txt, ascending.
KEY="$(python3 -c "s=open('STEGO_KEY_386.txt').read().strip(); r=[s[i:i+24] for i in range(0,len(s),24)]; print(r[2]+r[5]+r[7])")"

# 4) Pull the raw AES key from the inner JPEG's quantization tables.
python3 qtbl.py extract -i nothingtoseehere.jpg -o aeskey.bin -k "$KEY" >/dev/null

# 5) Decrypt passwords.enc (raw key + IV, no pbkdf2), grab the payload password.
KEYHEX="$(python3 -c "print(open('aeskey.bin','rb').read().hex())")"
IVHEX="$(python3 -c "print(open('iv.bin','rb').read().hex())")"
openssl enc -d -aes-256-cbc -in passwords.enc -out passwords.txt -K "$KEYHEX" -iv "$IVHEX"
# the line after the "payload.enc" label is its password
PW="$(awk '/^payload\.enc$/{getline; print; exit}' passwords.txt)"
printf '%s' "$PW" > pw.txt

# 6) Decrypt the real payload and read the flag.
openssl enc -d -aes-256-cbc -pbkdf2 -pass file:pw.txt -in payload.enc -out payload.zip
GOT="$(unzip -p payload.zip flag.txt)"

if [ "$GOT" = "$EXPECT" ]; then echo "C3 PASS  ($GOT)"; else echo "C3 FAIL  got [$GOT]"; exit 1; fi

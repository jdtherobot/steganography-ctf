#!/usr/bin/env bash
# Black-box solve of Steganography lvl 1 from the participant email only. Asserts the flag.
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/../../.." && pwd)"
EML="$ROOT/participant/challenges/01-steganography-lvl-1/email.eml"
EXPECT="Flag{H0NeyB4d6er10OKinG0OD!!!}"
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT

# Pull the JPEG attachment and harvest the leaked password from the body.
python3 - "$EML" "$TMP" <<'PY'
import sys, email
from email import policy
msg = email.message_from_binary_file(open(sys.argv[1], "rb"), policy=policy.default)
out = sys.argv[2]
for p in msg.walk():
    if p.get_content_type() == "image/jpeg":
        open(out + "/a.jpeg", "wb").write(p.get_payload(decode=True))
for p in msg.walk():
    if p.get_content_type() == "text/plain":
        for ln in p.get_content().splitlines():
            if "password:" in ln.lower():
                open(out + "/pw.txt", "w").write(ln.split(":", 1)[1].strip())
PY

PW="$(cat "$TMP/pw.txt")"
exiftool -b -Comment "$TMP/a.jpeg" > "$TMP/c.b64"
GOT="$(openssl enc -aes-256-cbc -d -pbkdf2 -a -k "$PW" -in "$TMP/c.b64")"
if [ "$GOT" = "$EXPECT" ]; then echo "C1 PASS  ($GOT)"; else echo "C1 FAIL  got [$GOT]"; exit 1; fi

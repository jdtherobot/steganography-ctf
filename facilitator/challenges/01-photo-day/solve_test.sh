#!/usr/bin/env bash
# Challenge 1 (Photo Day lvl 2) — automated black-box solver test.
#
# Solves ONLY from the participant distribution
# (participant/challenges/01-photo-day/email.eml) — never from facilitator/
# or the archive — exactly the way a player would:
#   1. parse the .eml, read the body, harvest the "Definitely not the
#      password:" clue (so a body/password mismatch fails the test),
#   2. extract the image/jpeg attachment,
#   3. read its EXIF Comment (base64 OpenSSL blob),
#   4. openssl aes-256-cbc -pbkdf2 decrypt with the harvested password,
#   5. assert the exact flag.
# Prints "C1 PASS" and exits 0 on success; exits non-zero otherwise.
#
# Usage (any cwd): bash facilitator/challenges/01-photo-day/solve_test.sh
# Requires: python3, exiftool, openssl.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"

EML="$REPO_ROOT/participant/challenges/01-photo-day/email.eml"
WORK="$REPO_ROOT/build/scratch/c1/solve_test"
EXPECTED_FLAG='Flag{H0NeyB4d6er10OKinG0OD!!!}'

fail() { echo "C1 FAIL: $*" >&2; exit 1; }

[ -f "$EML" ] || fail "participant distributable missing: $EML"
rm -rf "$WORK" && mkdir -p "$WORK"

# Steps 1+2: body-password harvest + attachment extraction (player-style).
python3 - "$EML" "$WORK" <<'PYEOF' || fail "eml parse/extract failed"
import email, email.policy, re, sys
eml, work = sys.argv[1], sys.argv[2]
msg = email.message_from_binary_file(open(eml, "rb"), policy=email.policy.default)
body = att = None
for part in msg.walk():
    if part.get_content_type() == "text/plain" and body is None:
        body = part.get_content()
    elif part.get_content_type() == "image/jpeg" and att is None:
        att = part.get_payload(decode=True)
assert body is not None, "no text/plain body part"
assert att is not None, "no image/jpeg attachment"
m = re.search(r"[Nn]ot the password:\s*(\S+)", body)
assert m, 'body lacks the "not the password:" clue'
open(f"{work}/password.txt", "w").write(m.group(1))
open(f"{work}/attachment.jpeg", "wb").write(att)
PYEOF

PASSWORD="$(cat "$WORK/password.txt")"
[ -n "$PASSWORD" ] || fail "empty password harvested from body"

# Step 3: EXIF Comment.
exiftool -Comment -b "$WORK/attachment.jpeg" > "$WORK/c.b64"
[ -s "$WORK/c.b64" ] || fail "attachment has no EXIF Comment"

# Step 4: decrypt with the password the email itself leaked.
flag="$(openssl enc -aes-256-cbc -d -pbkdf2 -k "$PASSWORD" -a -in "$WORK/c.b64")" \
  || fail "openssl decrypt failed (password harvested: $PASSWORD)"

# Step 5: assert.
[ "$flag" = "$EXPECTED_FLAG" ] || fail "wrong flag: $flag"

echo "C1 PASS"

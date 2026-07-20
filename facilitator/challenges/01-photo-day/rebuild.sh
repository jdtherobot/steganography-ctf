#!/usr/bin/env bash
# Challenge 1 (Photo Day lvl 2) — deterministic rebuild.
#
# Reads the immutable archive (ARCHIVE_DIR), verifies the canonical email.eml
# solves end-to-end (attachment -> EXIF Comment -> openssl decrypt -> flag,
# plus the body-password sanity check), then installs the canonical bytes as
# the participant distributable. Idempotent — safe to re-run any time.
#
# Run from the repo root:
#   source build/config.sh    # or: export ARCHIVE_DIR=/path/to/archive
#   bash facilitator/challenges/01-photo-day/rebuild.sh
#
# Requires: python3, exiftool, openssl (all native on macOS + brew exiftool).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"

# Pick up ARCHIVE_DIR from build/config.sh when not already exported.
if [ -z "${ARCHIVE_DIR:-}" ]; then
  # shellcheck source=/dev/null
  source "$REPO_ROOT/build/config.sh"
fi

SRC="$ARCHIVE_DIR/main/Challenge 1/email.eml"
DST_DIR="$REPO_ROOT/participant/challenges/01-photo-day"
DST="$DST_DIR/email.eml"
SCRATCH="$REPO_ROOT/build/scratch/c1/rebuild"

# Ground truth (see PROVENANCE.md)
EXPECTED_EML_SHA="366b8767f647cd5df0ded2384e9e0feaa61b7cc4279b822be4679c660a20ab7b"
EXPECTED_ATT_SHA="01c388e88a17f3b9bc4c75aa56608d749ce10bf28fc525b624e8787770c6c859"
EXPECTED_FLAG='Flag{H0NeyB4d6er10OKinG0OD!!!}'
PASSWORD='honeybadger4lyfe'   # body clue == working password (no apostrophe)

fail() { echo "C1 rebuild FAIL: $*" >&2; exit 1; }

[ -f "$SRC" ] || fail "canonical email not found: $SRC"
mkdir -p "$SCRATCH" "$DST_DIR"

# --- 1. Canonical bytes check -------------------------------------------------
src_sha="$(shasum -a 256 "$SRC" | awk '{print $1}')"
[ "$src_sha" = "$EXPECTED_EML_SHA" ] || fail "archive email.eml SHA-256 drifted: $src_sha"

# --- 2. Extract attachment + verify the body password clue --------------------
ATT="$SCRATCH/attachment.jpeg"
python3 - "$SRC" "$ATT" "$PASSWORD" <<'PYEOF' || fail "attachment/body verification failed"
import email, email.policy, sys
eml, out, password = sys.argv[1], sys.argv[2], sys.argv[3]
msg = email.message_from_binary_file(open(eml, "rb"), policy=email.policy.default)
body = att = None
for part in msg.walk():
    if part.get_content_type() == "text/plain" and body is None:
        body = part.get_content()
    elif part.get_content_type() == "image/jpeg" and att is None:
        att = part.get_payload(decode=True)
assert body is not None, "no text/plain body"
assert att is not None, "no image/jpeg attachment"
assert password in body, "body is missing the intended password clue"
assert "honeybadger4l'yfe" not in body and "honeybadger4l’yfe" not in body, \
    "apostrophe-form password present in body"
open(out, "wb").write(att)
PYEOF

att_sha="$(shasum -a 256 "$ATT" | awk '{print $1}')"
[ "$att_sha" = "$EXPECTED_ATT_SHA" ] || fail "attachment SHA-256 drifted: $att_sha"

# --- 3. Solve: EXIF Comment -> openssl decrypt -> flag ------------------------
exiftool -Comment -b "$ATT" > "$SCRATCH/c.b64"
[ -s "$SCRATCH/c.b64" ] || fail "attachment has no EXIF Comment"
flag="$(openssl enc -aes-256-cbc -d -pbkdf2 -k "$PASSWORD" -a -in "$SCRATCH/c.b64")" \
  || fail "openssl decrypt failed"
[ "$flag" = "$EXPECTED_FLAG" ] || fail "decrypted wrong flag: $flag"

# --- 4. Install participant distributable (byte-identical copy) ---------------
cp "$SRC" "$DST"
dst_sha="$(shasum -a 256 "$DST" | awk '{print $1}')"
[ "$dst_sha" = "$EXPECTED_EML_SHA" ] || fail "installed copy SHA mismatch"

echo "C1 rebuild OK: canonical email verified (flag decrypts) and installed at"
echo "  $DST"
echo "  SHA-256 $dst_sha"

#!/usr/bin/env bash
# Challenge 2 (Stegosaurus 1) — deterministic rebuild.
#
# Distributes the canonical stego carrier from the immutable archive into the
# participant bundle. The archive's stego_badger.jpeg was produced by an UNSEEDED
# generator (main/Challenge 2/genstring.py), so it cannot be reproduced bit-for-bit;
# we therefore re-use the canonical archived bytes rather than regenerating.
# See PROVENANCE.md for the full rationale.
#
# Idempotent: re-running yields the identical participant file and re-verifies its
# SHA-256. Reads ARCHIVE_DIR only; writes only under participant/.
set -euo pipefail

# Load shared config (defines/validates ARCHIVE_DIR, REPO_ROOT).
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)/build/config.sh"

SRC="$ARCHIVE_DIR/main/Challenge 2/stego_badger.jpeg"
DST_DIR="$REPO_ROOT/participant/challenges/02-stegosaurus-1"
DST="$DST_DIR/stego_badger.jpeg"

# Canonical fingerprint (a hash is not a secret; asserting it guards against drift).
CANONICAL_SHA="244e2a18e488ff165d3bf5f5422cc7d4c4f5ff655c010c9ea97aad54bb6a436c"

[ -f "$SRC" ] || { echo "C2 rebuild: missing canonical carrier: $SRC" >&2; exit 1; }

# Verify the source archive bytes are the ones we expect before copying.
src_sha="$(shasum -a 256 "$SRC" | cut -d' ' -f1)"
if [ "$src_sha" != "$CANONICAL_SHA" ]; then
  echo "C2 rebuild: FAIL — archive carrier SHA-256 mismatch" >&2
  echo "  expected: $CANONICAL_SHA" >&2
  echo "  got:      $src_sha" >&2
  exit 1
fi

mkdir -p "$DST_DIR"
cp -f "$SRC" "$DST"

dst_sha="$(shasum -a 256 "$DST" | cut -d' ' -f1)"
if [ "$dst_sha" != "$CANONICAL_SHA" ]; then
  echo "C2 rebuild: FAIL — distributed carrier SHA-256 mismatch" >&2
  echo "  expected: $CANONICAL_SHA" >&2
  echo "  got:      $dst_sha" >&2
  exit 1
fi

echo "C2 rebuild: OK"
echo "  wrote:  ${DST#$REPO_ROOT/}"
echo "  sha256: $dst_sha"

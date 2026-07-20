#!/usr/bin/env bash
# Challenge 3 (Stegosaurus 2 — Warehouse) — automated solver test.
#
# Replays the intended solve end-to-end and asserts the known answers:
#   1. Reads the VA out of the participant distribution (BRIEF.md — C3 ships no
#      binary; the brief is the puzzle) and asserts the page-table decomposition
#      [PML4 9|PDPT 9|PD 9|PT 9|offset 12] equals 2,1,2,1,5.
#   2. Decrypts the four-square ciphertext (line 9 of the Challenge 2 payload)
#      with the note's configuration and asserts the archived plaintext.
#
# Inputs used, mapped to how a player obtains them:
#   * VA                      -> participant/challenges/03-.../BRIEF.md
#   * ciphertext              -> line 9 of the document extracted in Challenge 2
#                                (constant below; cross-checked against
#                                build/out/c2_extracted.txt when present)
#   * HONEY/BADGER/HECK/YEAH  -> the physical note earned at the warehouse
#                                location (facilitator-held clue/warehouse_note.svg)
#
# Prints "C3 PASS" and exits 0 on success; non-zero otherwise.
set -euo pipefail
export PYTHONDONTWRITEBYTECODE=1   # keep the challenge dir free of __pycache__

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$HERE/../../.." && pwd)"

BRIEF="$REPO_ROOT/participant/challenges/03-stegosaurus-2-warehouse/BRIEF.md"
C2_EXTRACT="$REPO_ROOT/build/out/c2_extracted.txt"
CIPHERTEXT="UPNAHLNSIBESOLTUEBUPDNEY"          # line 9 of the C2 payload
EXPECT_PT="TOMHANKSAINTGOTSHITONME"            # archived answer (before Z pad strip: +Z)
EXPECT_FLAG='Flag{TOMHANKSAINTGOTSHITONME}'    # pinned canonical form (reconstructed default)

fail() { echo "C3 FAIL — $*" >&2; exit 1; }

echo "== C3 solve test =="

# --- 1) VA from the participant distribution --------------------------------
[ -f "$BRIEF" ] || fail "participant BRIEF.md not found: $BRIEF"
VA_STR="$(grep -oE '0x[0-9a-fA-F_]{6,}' "$BRIEF" | head -n1)"
[ -n "$VA_STR" ] || fail "no VA found in participant BRIEF.md"
echo "   VA from BRIEF.md: $VA_STR"

# --- 2) Cross-check the ciphertext against the C2 extraction (when present) --
if [ -f "$C2_EXTRACT" ]; then
  l9="$(awk 'NR==9' "$C2_EXTRACT" | tr -d '\r\n')"
  [ "$l9" = "$CIPHERTEXT" ] || fail "line 9 of c2_extracted.txt is '$l9', expected '$CIPHERTEXT'"
  echo "   ciphertext == line 9 of C2 extraction: OK"
else
  echo "   (build/out/c2_extracted.txt absent — using pinned ciphertext)"
fi

# --- 3) Walk + four-square decode -------------------------------------------
VA_STR="$VA_STR" CIPHERTEXT="$CIPHERTEXT" EXPECT_PT="$EXPECT_PT" \
python3 - "$HERE" <<'PY' || fail "assertions failed"
import os, sys
sys.path.insert(0, sys.argv[1])
from foursquare import build_square, decrypt, CANONICAL_KEYS, PAD

# 3a. page-table decomposition of the VA shipped to players
va = int(os.environ["VA_STR"].replace("_", ""), 16)
assert va >> 48 == 0, "VA must be a canonical 48-bit address"
walk = ((va >> 39) & 0x1FF,   # PML4  -> row
        (va >> 30) & 0x1FF,   # PDPT  -> shelf level
        (va >> 21) & 0x1FF,   # PD    -> front/back bay
        (va >> 12) & 0x1FF,   # PT    -> sub-section
         va        & 0xFFF)   # offset-> box
assert walk == (2, 1, 2, 1, 5), f"unexpected walk {walk}"
print(f"   walk: PML4={walk[0]} PDPT={walk[1]} PD={walk[2]} PT={walk[3]} offset={walk[4]}  "
      "(row 2 / shelf 1 / back bay / sub-section 1 / box 5)")

# 3b. four-square decode with the note's configuration:
#     all four squares keyed, corner word -> corner square (TL=HONEY, TR=BADGER,
#     BL=HECK, BR=YEAH), I/J merged, trailing Z pad.
sq = {c: build_square(k) for c, k in CANONICAL_KEYS.items()}
pt = decrypt(os.environ["CIPHERTEXT"], sq["tl"], sq["tr"], sq["bl"], sq["br"])
expected = os.environ["EXPECT_PT"]
assert pt == expected + PAD, f"decode mismatch: {pt!r}"
assert pt.rstrip(PAD) == expected
print(f"   four-square: {os.environ['CIPHERTEXT']} -> {pt} (strip pad -> {expected})")
PY

echo "   plaintext: $EXPECT_PT  (\"TOM HANKS AINT GOT SHIT ON ME\")"
echo "   canonical flag: $EXPECT_FLAG"
echo "C3 PASS"

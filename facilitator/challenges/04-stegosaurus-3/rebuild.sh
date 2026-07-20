#!/usr/bin/env bash
# Challenge 4 (Stegosaurus 3) — deterministic v3 rebuild with the three fixes.
#
# Reads creator inputs from the immutable archive (Challenge 4v2), applies:
#   FIX 1: re-embed aeskey.bin with keyblock records ordered 3,8,6 (so "386" clue is correct)
#   FIX 2: re-encrypt the weak bundle with crackable `desertstorm`
#   FIX 3: drop the loose 21-byte secret.txt gap from the carrier
# Writes the ONLY player artifact -> participant/challenges/04-stegosaurus-3/Honey.jpeg
# All creator-only intermediates stay in build/scratch/c4/ (gitignored).
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
: "${ARCHIVE_DIR:=/Users/jdtherobot/Documents/GitHub/CTF Challenges/archive}"
SRC="$ARCHIVE_DIR/main/Challenge 4v2"
SCR="$REPO_ROOT/build/scratch/c4"
OUT="$REPO_ROOT/participant/challenges/04-stegosaurus-3"
mkdir -p "$SCR" "$OUT"

echo "== C4 rebuild =="
[ -d "$SRC" ] || { echo "missing source: $SRC" >&2; exit 1; }

# --- FIX 1: derive the corrected keyblock (records 3, 8, 6) --------------------
python3 - "$SRC" "$SCR" <<'PY'
import sys, pathlib
src, scr = pathlib.Path(sys.argv[1]), pathlib.Path(sys.argv[2])
data = (src/"STEGO_KEY_386.txt").read_bytes().rstrip(b"\n")
assert len(data) % 24 == 0, f"STEGO_KEY_386 length {len(data)} not a multiple of 24"
recs = [data[i*24:(i+1)*24] for i in range(len(data)//24)]
R3, R6, R8 = recs[2], recs[5], recs[7]
old = (src/"keyblock.txt").read_bytes().rstrip(b"\n")
assert old == R3+R6+R8, f"archive keyblock != R3+R6+R8\n old={old!r}\n exp={R3+R6+R8!r}"
new = R3 + R8 + R6                     # "386" order
(scr/"keyblock_new.txt").write_bytes(new)
print(f"  R3={R3.decode()}")
print(f"  R6={R6.decode()}")
print(f"  R8={R8.decode()}")
print(f"  OLD keyblock (3,6,8): {old.decode()}")
print(f"  NEW keyblock (3,8,6): {new.decode()}")
print(f"  first-32 changed:     {old[:32]!=new[:32]}  (only first 32 bytes XOR a 32-byte key)")
PY
NEWKEY="$(cat "$SCR/keyblock_new.txt")"

# --- FIX 1 cont.: re-embed the raw AES key into the inner JPEG -----------------
python3 "$SRC/qtbl_stego.py" embed -i "$SRC/inner.jpeg" -o "$SCR/nothingtoseehere.jpg" \
  -m "$SRC/aeskey.bin" -k "$NEWKEY"

# roundtrip: extracting with the SAME new keyblock must recover aeskey.bin
python3 "$SRC/qtbl.py" extract -i "$SCR/nothingtoseehere.jpg" -o "$SCR/aeskey_rec.bin" -k "$NEWKEY"
if cmp -s "$SCR/aeskey_rec.bin" "$SRC/aeskey.bin"; then
  echo "  roundtrip: OK (extracted key == original aeskey.bin)"
else
  echo "  roundtrip: FAIL" >&2; exit 1
fi

# --- rebuild the player bundle (unchanged 4 files) ----------------------------
rm -f "$SCR/secret_bundle.zip"
( cd "$SCR"
  cp "$SRC/qtbl.py" "$SRC/STEGO_KEY_386.txt" "$SRC/passwords.enc" "$SRC/iv.bin" .
  zip -j -q secret_bundle.zip qtbl.py STEGO_KEY_386.txt passwords.enc iv.bin )

# --- FIX 2: weakly encrypt with a crackable password --------------------------
openssl enc -aes-256-cbc -pbkdf2 -salt -pass pass:desertstorm \
  -in "$SCR/secret_bundle.zip" -out "$SCR/secret.enc"

# --- FIX 3: assemble carrier WITHOUT the loose secret.txt gap ------------------
cat "$SRC/Honey_orig.jpeg" "$SCR/secret.enc" "$SRC/mid.zip" "$SCR/nothingtoseehere.jpg" \
    "$SRC/payload.enc" "$SRC/decoy_random.enc" > "$OUT/Honey.jpeg"

rm -f "$OUT/.gitkeep"
echo "  wrote $OUT/Honey.jpeg ($(wc -c < "$OUT/Honey.jpeg") bytes)"
echo "== C4 rebuild done =="

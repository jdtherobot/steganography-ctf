#!/usr/bin/env bash
# Challenge 3 (Stegosaurus 2 — Warehouse) — deterministic rebuild + verification.
#
# What this does (idempotent; safe to re-run):
#   1. Pins provenance: asserts the canonical creator doc ARCHIVE_DIR/main/CTF Stego.md
#      is present, unmodified (SHA-256), and contains the puzzle VA.
#   2. Verifies the page-table walk: decomposes VA 0x0000_0100_4040_1005 into
#      [PML4 9|PDPT 9|PD 9|PT 9|offset 12] and asserts the indices are 2,1,2,1,5
#      (row 2 / shelf level 1 / back bay / sub-section 1 / box 5).
#   3. Checks the participant artifact: participant/challenges/03-.../BRIEF.md must
#      carry the exact VA (C3 ships no binary — the brief IS the distribution).
#   4. (Re)emits the physical clue asset: clue/warehouse_note.svg (canonical) and,
#      best-effort, clue/warehouse_note.png. The clue stays under facilitator/ —
#      it is the EARNED reward at the warehouse location, never shipped openly.
#      Its text (Honey/Badger/Heck/Yeah, "dCode" + 4 boxes, "Line #9") is the
#      source of truth that the warehouse game mirrors.
#
# Run from the repo root:  bash facilitator/challenges/03-stegosaurus-2-warehouse/rebuild.sh
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$HERE/../../.." && pwd)"
# shellcheck source=/dev/null
source "$REPO_ROOT/build/config.sh"

C3_PART="$REPO_ROOT/participant/challenges/03-stegosaurus-2-warehouse"
CLUE_DIR="$HERE/clue"
DOC="$ARCHIVE_DIR/main/CTF Stego.md"
DOC_SHA_EXPECTED="592e2a12bcdffffc3fb6aa32b4898482b057df65125b243979d8b4adbda61d30"
VA_STR="0x0000_0100_4040_1005"

fail() { echo "C3 rebuild: FAIL — $*" >&2; exit 1; }

echo "== C3 rebuild =="

# --- 1) Provenance pin -------------------------------------------------------
[ -f "$DOC" ] || fail "canonical doc missing: $DOC"
doc_sha="$(shasum -a 256 "$DOC" | awk '{print $1}')"
[ "$doc_sha" = "$DOC_SHA_EXPECTED" ] || fail "archive doc SHA mismatch ($doc_sha) — archive must be immutable"
grep -qF "VA = $VA_STR" "$DOC" || fail "VA not found in canonical doc"
echo "   archive doc pinned: main/CTF Stego.md ($doc_sha)"

# --- 2) Page-table walk verification ----------------------------------------
python3 - <<'PY' || fail "page-table walk verification failed"
va = 0x0000_0100_4040_1005
assert va >> 48 == 0, "VA must fit in 48 bits (canonical, upper bits zero)"
offset =  va         & 0xFFF   # bits 11..0
pt     = (va >> 12)  & 0x1FF   # bits 20..12
pd     = (va >> 21)  & 0x1FF   # bits 29..21
pdpt   = (va >> 30)  & 0x1FF   # bits 38..30
pml4   = (va >> 39)  & 0x1FF   # bits 47..39
walk = (pml4, pdpt, pd, pt, offset)
assert walk == (2, 1, 2, 1, 5), f"unexpected walk: {walk}"
print(f"   walk OK: PML4={pml4} PDPT={pdpt} PD={pd} PT={pt} offset={offset}")
print( "   location: row 2 / shelf level 1 (bottom) / back bay (2) / sub-section 1 / box 5")
PY

# --- 3) Participant artifact consistency ------------------------------------
[ -f "$C3_PART/BRIEF.md" ] || fail "participant BRIEF.md missing: $C3_PART/BRIEF.md"
grep -qF "$VA_STR" "$C3_PART/BRIEF.md" || fail "participant BRIEF.md does not carry the VA"
echo "   participant BRIEF.md carries the VA: OK"

# --- 4) Emit the physical clue asset ----------------------------------------
mkdir -p "$CLUE_DIR"
cat > "$CLUE_DIR/warehouse_note.svg" <<'SVG'
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1000 620" width="1000" height="620">
  <title>Warehouse note (Challenge 3 physical clue)</title>
  <desc>2x2 note found at row 2, shelf 1, back bay, sub-section 1, box 5. Print at 5x3 inches.</desc>
  <!-- index card -->
  <rect x="8" y="8" width="984" height="604" rx="18" fill="#fdfbf2" stroke="#b9b09a" stroke-width="3"/>
  <!-- 2x2 fold creases -->
  <line x1="500" y1="34" x2="500" y2="586" stroke="#ddd5c2" stroke-width="2" stroke-dasharray="12 9"/>
  <line x1="34" y1="310" x2="966" y2="310" stroke="#ddd5c2" stroke-width="2" stroke-dasharray="12 9"/>
  <!-- corner words: one per quadrant, exactly as on the original note -->
  <g fill="#20303c" font-family="'Marker Felt','Comic Sans MS','Segoe Print','Bradley Hand',cursive,sans-serif" font-size="76" text-anchor="middle">
    <text x="205" y="155" transform="rotate(-2 205 155)">Honey</text>
    <text x="795" y="155" transform="rotate(1.5 795 155)">Badger</text>
    <text x="205" y="525" transform="rotate(1.5 205 525)">Heck</text>
    <text x="795" y="525" transform="rotate(-2 795 525)">Yeah</text>
  </g>
  <!-- clear patch so the creases do not run through the center writing -->
  <rect x="250" y="262" width="500" height="196" fill="#fdfbf2"/>
  <!-- center line: dCode followed by four empty squares -->
  <g fill="#20303c" font-family="'Marker Felt','Comic Sans MS','Segoe Print','Bradley Hand',cursive,sans-serif">
    <text x="450" y="341" font-size="62" text-anchor="end">dCode</text>
    <g fill="none" stroke="#20303c" stroke-width="4">
      <rect x="480" y="293" width="52" height="52" rx="6"/>
      <rect x="544" y="293" width="52" height="52" rx="6"/>
      <rect x="608" y="293" width="52" height="52" rx="6"/>
      <rect x="672" y="293" width="52" height="52" rx="6"/>
    </g>
    <!-- below center -->
    <text x="500" y="432" font-size="52" text-anchor="middle">Line #9</text>
  </g>
</svg>
SVG
echo "   wrote $(basename "$CLUE_DIR")/warehouse_note.svg"

# Best-effort PNG (the SVG is canonical; PNG is a print convenience).
# NOTE: do not use qlmanage here — it letterboxes SVGs onto a square canvas and
# crops the right edge. rsvg-convert and macOS sips both honor the aspect ratio.
png_out="$CLUE_DIR/warehouse_note.png"
png_done=0
if command -v rsvg-convert >/dev/null 2>&1; then
  rsvg-convert -w 2000 -o "$png_out" "$CLUE_DIR/warehouse_note.svg" && png_done=1
fi
if [ "$png_done" -eq 0 ] && command -v sips >/dev/null 2>&1; then
  # sips rasterizes at the SVG's declared width/height, so scale a temp copy 2x
  # (2000x1240, ~400 dpi at 5x3 in) for print quality.
  tmp="$(mktemp -d)"
  sed 's/width="1000" height="620"/width="2000" height="1240"/' \
    "$CLUE_DIR/warehouse_note.svg" > "$tmp/note2x.svg"
  if sips -s format png "$tmp/note2x.svg" --out "$tmp/note2x.png" >/dev/null 2>&1 \
     && [ -f "$tmp/note2x.png" ]; then
    mv "$tmp/note2x.png" "$png_out"
    png_done=1
  fi
  rm -rf "$tmp"
fi
if [ "$png_done" -eq 1 ]; then
  echo "   wrote $(basename "$CLUE_DIR")/warehouse_note.png"
else
  echo "   note: no SVG rasterizer available — skipped PNG (SVG is canonical)"
fi

echo "C3 rebuild: OK"

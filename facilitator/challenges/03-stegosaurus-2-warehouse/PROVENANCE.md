# Challenge 3 — Provenance

Challenge 3 has **no surviving build artifacts** in the archive — it is specified
entirely by the creator's notes. This file records exactly which archive revision
is canonical, what was rejected, and which facts are reconstructed.

## Canonical source

| Item | Value |
|---|---|
| File | `ARCHIVE_DIR/main/CTF Stego.md` — "Challenge 3 / Stegosaurus 2" section |
| SHA-256 | `592e2a12bcdffffc3fb6aa32b4898482b057df65125b243979d8b4adbda61d30` |
| Supplies | the memo text + `VA = 0x0000_0100_4040_1005`, the 9/9/9/9/12 split hint, the final warehouse geometry (rows 1–10; shelf bottom=1→top=3; front=1/back=2; 56 spoke-holes per grate as 8 sub-sections of 7; offset = box #), the note contents (corner words, `dCode ▢▢▢▢`, `Line #9`), and the pointer to the Challenge 2 document's line 9 |

`ARCHIVE_DIR/virtualbox share original/CTF Stego.md` is **byte-identical** to the
canonical copy (same SHA-256) — a consistent duplicate, not independently used.

## Rejected revision

| Item | Value |
|---|---|
| File | `ARCHIVE_DIR/CTF Stego.md` (archive root) |
| SHA-256 | `a6279589aa2e61babe363dbea50da0e8f014ce3db647aa311434b99bbe7faf38` |
| Why rejected | Earlier draft: stale warehouse geometry (L3 "front→back 1..4" and L4 "sub-section 1..4" vs the final front/back = 1..2 and 8 sub-sections of 7) and **missing the "Line #9" clue** on the note |
| Still useful | Its draft answer column reads `2 / 1 / 2 / 1 / box #5` — independently corroborating the walk derived from the VA |

Note the canonical `main/` copy's answer column reads `99` at every level — those
are placeholders, not answers. That is fine and expected: **the answers are not
data, they are derived** — the VA decomposes to `2,1,2,1,5` by arithmetic, which
`rebuild.sh` and `solve_test.sh` assert on every run.

## Cross-references

| Fact | Evidence |
|---|---|
| Ciphertext = line 9 of the C2 payload | `ARCHIVE_DIR/main/Challenge 2/Flag 2.txt` (SHA-256 `ddebc7dbefa5e11b35c066a551d9ab08addb6d39df2bc5d46e70eb14d52c11a5`) line 9 = `UPNAHLNSIBESOLTUEBUPDNEY`; byte-identical to the actual steghide extraction in `build/out/c2_extracted.txt` |
| Empty challenge dir | `ARCHIVE_DIR/main/Challenge 3/` contains **zero files** — no flag file, no assets survived |

## Interpretations of creator-note typos (pinned)

1. The note description lists `TL: "Honey"  TR: "Badger"` … `BL: "Heck"  TR: "Yeah"`.
   The second `TR` is a typo for **BR** (TR is already assigned "Badger"). Pinned
   layout: TL=Honey, TR=Badger, BL=Heck, BR=Yeah — confirmed independently by the
   cipher solve below, which only works under exactly that corner assignment.
2. "56 **apokes** per grate" = "spokes". Geometry pinned as: each bay (front/back)
   is a grate of 56 spoke-holes arranged as 8 sub-sections × 7 boxes.

## Reconstructed facts (not verbatim in the archive)

1. **Four-square configuration.** The notes name the tool ("dCode", and
   "Four-Square" appears in the Challenge 4 section) and give the note contents,
   but not the grid setup. Derivation: exhaustive sweep of every corner/keyword
   assignment — each of the four squares tried as plain, `HONEY`, `BADGER`,
   `HECK`, `YEAH`, `HONEYBADGER`, `HECKYEAH` (7⁴ = 2401 configurations, classic
   digraph rules, I/J merged). **Exactly one** configuration decodes
   `UPNAHLNSIBESOLTUEBUPDNEY` to `TOMHANKSAINTGOTSHITONME(Z)`: all four squares
   keyed, corner word → corner square (TL=HONEY, TR=BADGER, BL=HECK, BR=YEAH).
   Sweep script preserved at `build/scratch/c3/fs_explore.py`; the pinned
   configuration is implemented in `foursquare.py` and asserted by `solve_test.sh`.
2. **The flag string.** Because `main/Challenge 3/` is empty, no original flag
   file exists. `Flag{TOMHANKSAINTGOTSHITONME}` is a **pinned reconstructed
   default** (plaintext is verified ground truth; wrapper matches the other
   challenges' `Flag{...}` convention). Marked as such in `WRITEUP.md`, with
   accepted equivalents listed for graders.
3. **The clue asset.** `clue/warehouse_note.svg` (+ best-effort PNG) is authored
   from the note description above; no original physical note survived. Its text
   is the source of truth that the warehouse game mirrors.

## Outputs of this challenge's build

| Path | Role |
|---|---|
| `participant/challenges/03-stegosaurus-2-warehouse/BRIEF.md` | player distribution (C3 ships no binary — the brief is the puzzle) |
| `facilitator/challenges/03-stegosaurus-2-warehouse/clue/warehouse_note.svg` | printable physical clue (earned at the location; never shipped openly) |
| `facilitator/challenges/03-stegosaurus-2-warehouse/clue/warehouse_note.png` | print convenience raster (regenerable; SVG is canonical) |

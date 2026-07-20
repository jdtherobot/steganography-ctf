# Archive Provenance (FACILITATOR ONLY)

How the immutable evidence archive maps to the clean `participant/` distributions. Every canonical
selection and every rejected revision is traced by SHA-256. Per-challenge detail lives in each
`facilitator/challenges/NN/PROVENANCE.md`; this file is the index.

## The immutable archive

- Location (outside this repo, `.gitignore`d): `ARCHIVE_DIR = /Users/jdtherobot/Documents/GitHub/CTF Challenges/archive`
- **Never** modified, moved, renamed, or deleted. Rebuild scripts read it; nothing writes to it.
- Inventory (`build/inventory/`): **280 files, 85 unique SHA-256, 61 duplicate groups, 158,586,716 bytes.**
- **Archive fingerprint:** `1f90c817321e8b584154abde4ae1b45d76d67997917e8edad78f9465415a4781`
  — `make verify-archive` recomputes it and fails on any drift. Confirmed unchanged after this build.

## Canonicalization method

The archive holds finished files, intermediate builds, duplicated working trees, and conflicting
revisions. Selection was done by: (1) hash-inventory everything; (2) group byte-identical duplicates;
(3) compare remaining variants by embedded payload, notes, and solvability; (4) reproduce each
solution with real tools; (5) accept the revision that solves and matches the author's answer, and
record why each other revision was rejected. The newest-looking folder was not assumed correct.

## Canonical selections (shipped to `participant/`)

| Ch | Canonical archive source | SHA-256 | Ships as |
|---|---|---|---|
| 1 | `main/Challenge 1/email.eml` | `366b8767…a20ab7b` | `participant/challenges/01-photo-day/email.eml` (verbatim) |
| 2 | `main/Challenge 2/stego_badger.jpeg` | `244e2a18…bb6a436c` | `participant/challenges/02-stegosaurus-1/stego_badger.jpeg` (verbatim) |
| 3 | `main/CTF Stego.md` (C3 section) | `592e2a12…bda61d30` | `participant/challenges/03-stegosaurus-2-warehouse/BRIEF.md` (no binary; puzzle is text) |
| 4 | `main/Challenge 4v2/` (all inputs) | see C4 PROVENANCE | `participant/challenges/04-stegosaurus-3/Honey.jpeg` (**rebuilt v3**, `daa452ec…936e19a3`) |

C4 is the only challenge whose distributable is regenerated rather than copied: the v3 carrier
applies three documented fixes (see `facilitator/challenges/04-stegosaurus-3/PROVENANCE.md`).

## Key rejected revisions (full lists in per-challenge PROVENANCE.md)

| Rejected | Reason |
|---|---|
| `main/Challenge 4/Honey.jpeg` (`9b37e261…`) | **Dead** — byte-identical to its own cover; carries no payload. `Challenge 4v2/` is canonical. |
| `main/Challenge 1/email_test_1.eml` | Earlier draft; attachment is the comment-less original photo → unsolvable. |
| `main/Challenge 2/stego_badger_orig.{jpg,png}` | Pre-embed originals; no steghide payload. |
| `CTF Stego.md` (archive root) | Stale C3 geometry, missing the "Line #9" clue. `main/` copy is canonical. |
| Old C4 keyblock order 3,6,8 / weak pw `DesertStorm#82pLm` | Clue mismatch / uncrackable; corrected to 3,8,6 and `desertstorm` in v3. |
| Apostrophe password `honeybadger4l'yfe` | Never in any archived file — a shell-quoting artifact in out-of-archive notes only. |

## Reconstructed facts (documented as such, not archive-verbatim)

- **C3 four-square configuration** — derived by exhaustive 2,401-config sweep to the unique setup
  that reproduces the known plaintext (all four squares keyed, corner-word→corner-square, I/J merged).
- **C3 flag** `Flag{TOMHANKSAINTGOTSHITONME}` — reconstructed default; the archive's `Challenge 3/`
  dir is empty. Plaintext is verified ground truth; the `Flag{…}` wrapper matches the other challenges.
- **C3 physical clue asset** — authored from the note description; no original note survived.

## Verification at build end

- All four solver tests pass from the participant distributions (`make test-challenges`): C1–C4 PASS.
- `make scan-secrets` PASS — no flags/creator-only material under `participant/`.
- `make verify-archive` PASS — archive fingerprint `1f90c817…4781` unchanged.

# Execution Plan — Stego CTF reconstruction

Streamlined plan of record for finishing the four-challenge stego CTF as a clean,
secret-free, one-private-repo project split into `participant/` and `facilitator/`.

## Locked decisions

- **One private repo**, two top-level folders: `participant/` (spoiler-free, distributable) and
  `facilitator/` (answers, walkthroughs, build scripts). Publishing = sanitized copy of
  `participant/` only, gated by `make scan-secrets`.
- Admin folder is named **`facilitator/`**.
- **Build the entire project** (challenges + warehouse game + docs + browser lab + deploy),
  always advancing to the next available step. Not stopping at an MVP.
- Archive stays immutable and outside the repo (`ARCHIVE_DIR`); fingerprint
  `1f90c817321e8b584154abde4ae1b45d76d67997917e8edad78f9465415a4781` must be unchanged at the end.
- Subagents run on **Fable 5**. Independent work runs in parallel with disjoint write paths;
  dependent work is sequenced.

## Ground-truth facts (verified against archive + canonical notes)

| Challenge | Flag | Key secret(s) |
|---|---|---|
| C1 Photo Day | `Flag{H0NeyB4d6er10OKinG0OD!!!}` | body password `honeybadger4lyfe` (no apostrophe) |
| C2 Stegosaurus 1 | `Flag{DanG 7hat'S @ cUTe HOnEY b@D9eR}` | steghide passphrase `password123`; line 9 of payload = C3 ciphertext |
| C3 Warehouse | plaintext `TOMHANKSAINTGOTSHITONME` (+Z pad) | VA `0x0000_0100_4040_1005` → row2/shelf1/bay2/subsection1/box5 |
| C4 Stegosaurus 3 | `Flag{Y0u haVe EnCouNTeR3d a w!Ld s1eEP p@RA1y$!S DEm0n}` | strong payload pw in `pw.txt`; keyblock records; `desertstorm` weak pw |

Full details live in `EXECUTION_HANDOFF.md` (creator-only, in the working folder outside this repo)
and in each `facilitator/challenges/NN/WRITEUP.md` once built.

## C4 fixes to apply (three authoring defects)

1. Re-embed `aeskey.bin` into the inner JPEG with keyblock records ordered **3, 8, 6** (so the
   `STEGO_KEY_386.txt` "386" clue is correct), and document the 24-char-record derivation.
2. Re-encrypt `secret.enc` with clue-derived **`desertstorm`** (crackable in rockyou), not
   `DesertStorm#82pLm` (0 rockyou hits).
3. Remove the loose 21-byte `secret.txt` gap between `secret.enc` and `mid.zip`.

Then rebuild `secret_bundle.zip → secret.enc`, inner JPEG, and final `Honey.jpeg` (v3) outside the
archive, and re-run the full chain + a black-box secret-leak scan.

## Wave plan

- **Wave 1 — foundation (DONE, this commit):** participant/ + facilitator/ trees, top-level README,
  Makefile harness, `build/DIRECTORY_CONTRACT.md`, secret-scan gate (`build/secret-scan/`),
  execution plan, academic-use statement. Harness self-tested: verify-archive PASS, scan PASS.
- **Wave 2 — parallel Fable 5 subagents (disjoint paths):**
  - C1 rebuild + participant dist + facilitator writeup/test (fix apostrophe/password).
  - C2 deterministic rebuild + trimmed wordlist + stegseek validation (Docker).
  - C3 page-table + four-square worked solution + physical clue asset for the game.
  - C4 v3 rebuild with the three fixes + full-chain solver test + leak scan.
  - Warehouse game (static, to spec).
  - Doc set (participant README/toolkit + facilitator ADMIN_SETUP/GUIDEBOOK).
- **Wave 3 — integration (orchestrator):** aggregate `ARCHIVE_PROVENANCE.md`, run all solver tests +
  `scan-secrets` over participant/ + `verify-archive`, assemble `VALIDATION_REPORT.md`, commit.
- **Wave 4 — browser lab + deploy:** CheerpX/v86 feasibility spike, pick engine+host, build the
  chooser + GUI + terminal shipping only sanitized files; write `deploy/pages` + `deploy/lab`.
- **Final (gated):** create the PRIVATE GitHub repo and push — only after explicit user confirmation.

## Boundary invariant (never violate)

`participant/` contains zero final answers. Intended in-story clues (the "leaked" C1 password, the
crackable C2/C4 passphrases inside the shipped wordlist, puzzle ciphertexts) are allowed. Final
flags, the strong C4 payload password, four-square plaintext, `keyblock.txt` contents, and
creator-only helper/key files live only under `facilitator/`. Enforced by `make scan-secrets`.

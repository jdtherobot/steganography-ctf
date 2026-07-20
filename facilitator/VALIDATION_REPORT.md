# Validation Report (FACILITATOR ONLY)

Date: 2026-07-19. Environment: macOS (Apple Silicon / arm64), Darwin 24.1.0; Docker Desktop
(amd64 emulation) for steghide/stegseek; Python 3, OpenSSL 3.x, binwalk, exiftool native.

## Result: PASS — all four challenges solve from their participant distributions; no secrets leak; archive unchanged.

## Challenge solver tests (`make test-challenges`)

Each test solves **only** from the `participant/` distribution (plus the shipped trimmed wordlist
for C2) and asserts the exact flag. Run captured 2026-07-19.

| Ch | Test | Result | Asserted flag |
|---|---|---|---|
| 1 | `facilitator/challenges/01-photo-day/solve_test.sh` | **C1 PASS** | `Flag{H0NeyB4d6er10OKinG0OD!!!}` |
| 2 | `facilitator/challenges/02-stegosaurus-1/solve_test.sh` | **C2 PASS** | `Flag{DanG 7hat'S @ cUTe HOnEY b@D9eR}` |
| 3 | `facilitator/challenges/03-stegosaurus-2-warehouse/solve_test.sh` | **C3 PASS** | `Flag{TOMHANKSAINTGOTSHITONME}` (reconstructed default) |
| 4 | `facilitator/challenges/04-stegosaurus-3/solve_test.sh` | **C4 PASS** | `Flag{Y0u haVe EnCouNTeR3d a w!Ld s1eEP p@RA1y$!S DEm0n}` |

Notes:
- **C2** verifies both paths: deterministic `steghide extract -p password123` (asserts the extracted
  payload SHA-256 `ddebc7db…11a5` and the line-1 flag) **and** a `stegseek --crack` against the
  921-word trimmed wordlist recovering `password123`. Runs in Docker (`linux/amd64 debian:stable-slim`).
- **C3** asserts VA `0x0000_0100_4040_1005` → PML4/PDPT/PD/PT/offset = 2/1/2/1/5, cross-checks that
  the four-square ciphertext is byte-for-byte line 9 of the real C2 extraction, and decodes
  `UPNAHLNSIBESOLTUEBUPDNEY` → `TOMHANKSAINTGOTSHITONME`.
- **C4** solves the full chain from the rebuilt v3 `Honey.jpeg`: carve → crack `secret.enc`
  (`desertstorm`) → derive keyblock from `STEGO_KEY_386.txt` via the "386" rule → `qtbl.py` extract
  AES key → decrypt `passwords.enc` (raw key+IV) → decrypt `payload.enc` → flag. The three authoring
  fixes are applied and the AES-key re-embed round-trips.

## Warehouse game

- `participant/warehouse-game/index.html` (54 KB) — fully self-contained (verified: zero external
  `src`/`href`/URLs; system fonts; data-URI favicon). Plain static hosting; no COOP/COEP headers needed.
- 27-assertion headless-Chrome (CDP) end-to-end test passed: keyboard walk + collision, inspect,
  wrong-box "Nothing here.", click-to-move pathfinding, near-miss rejection, correct-box reveal with
  exact note content, SVG download, inventory, reload persistence, reset, reduced-motion. Zero console errors.
- Correct location (row2/shelf1/bay2/subsection1/box5) stored only as an FNV-1a hash (`0xdc4a4420`,
  collision-free across all 3,360 locations). Documented as an immersion layer, not an enforcing gate.

## Secret-scan gate (`make scan-secrets`)

- **PASS** — no denied strings or creator-only filenames anywhere under `participant/` (including the game).
- Belt-and-suspenders: a direct grep for all four flag fragments across `participant/` returns nothing.
- Intended in-story clues verified allowed: `honeybadger4lyfe` in C1's email body; `password123` /
  `desertstorm` only inside the shipped trimmed wordlist; puzzle ciphertexts.

## Archive integrity (`make verify-archive`)

- **PASS** — recomputed fingerprint equals the baseline
  `1f90c817321e8b584154abde4ae1b45d76d67997917e8edad78f9465415a4781`. The immutable archive was not modified.

## Determinism / idempotency

- All four `rebuild.sh` scripts are idempotent (re-run safe). C1/C2 copy canonical bytes; C3 verifies
  arithmetic + regenerates the clue asset; C4 regenerates the v3 carrier (its `secret.enc`/`payload`
  layers use random OpenSSL salts, so carrier bytes differ per run by design — solvability is invariant).

## Pending (later waves)

- **Browser lab** (`browser-lab/`) — CheerpX/v86 feasibility spike + GUI/terminal build. Not yet run;
  this report will be updated with the chosen engine, measured cold-load time, and image size.
- **Deploy** (`deploy/`) — pages (guide + game) and lab configs; repo push gated on explicit approval.

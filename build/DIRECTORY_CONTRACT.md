# Directory Contract (read before building any challenge)

Every challenge builder — human or subagent — MUST follow these conventions so that parallel
work never collides and the participant/facilitator boundary is never violated.

## Repo root

`/Users/jdtherobot/Documents/GitHub/stego-ctf`

## The immutable archive (source of truth, READ-ONLY)

```
ARCHIVE_DIR = /Users/jdtherobot/Documents/GitHub/CTF Challenges/archive
```

- **Never** modify, move, rename, or delete anything under `ARCHIVE_DIR`.
- Rebuild scripts READ creator inputs from `ARCHIVE_DIR` and WRITE outputs into the repo.
- Canonical archive locations per challenge:
  - C1: `ARCHIVE_DIR/main/Challenge 1/` (email.eml, badger_photo.jpeg, Flag.enc.b64, emailScript.txt)
  - C2: `ARCHIVE_DIR/main/Challenge 2/` (stego_badger.jpeg, Flag.txt, Flag 2.txt, genstring.py)
  - C3: values in `ARCHIVE_DIR/main/CTF Stego.md` (the copy under `main/` has the REAL warehouse
    values; root and `virtualbox share original` copies contain `99` placeholders — do NOT use those)
  - C4: `ARCHIVE_DIR/main/Challenge 4v2/` (canonical carrier + all build inputs, incl. keyblock.txt,
    qtbl_stego.py, aeskey.bin, iv.bin, passwords.txt, pw.txt, inner.jpeg, Honey_orig.jpeg)

## Where each challenge writes (disjoint paths — no two builders share a file)

For challenge `NN` in `{01-photo-day, 02-stegosaurus-1, 03-stegosaurus-2-warehouse, 04-stegosaurus-3}`:

```
participant/challenges/NN/          # SPOILER-FREE. Player-facing only.
  <distributable files>             #   e.g. email.eml, stego_badger.jpeg, Honey.jpeg
  BRIEF.md                          #   the player's briefing/prompt (no answers, no hints beyond in-story)

facilitator/challenges/NN/          # Answers + how it was built. Spoilers — not handed to participants.
  WRITEUP.md                        #   full worked solution incl. the flag
  PROVENANCE.md                     #   canonical files chosen (archive path + SHA-256) + rejected revisions + why
  rebuild.sh                        #   deterministic: reads ARCHIVE_DIR, writes participant/ artifact(s)
  solve_test.sh                     #   automated: solves from the participant distribution, asserts the flag, exit 0/1
  HINT_LADDER.md                    #   staged hints (used by the aggregated FACILITATOR_GUIDEBOOK)
```

- Secret INTERMEDIATE artifacts (raw keys, plaintext password lists, un-encrypted zips) go in
  `build/scratch/` (gitignored). Do NOT commit them. Regenerate from `ARCHIVE_DIR` when needed.
- The only binaries committed are: (a) the player distributables under `participant/`, and
  (b) any small fixture a solver test needs that is not itself a secret.

## Participant/facilitator boundary — the hard rules

1. **`participant/` must contain zero final answers.** No flag strings, no plaintext of a
   creator-only password, no creator-only helper/key files. See
   `build/secret-scan/denylist.txt` for the exact forbidden strings and filenames.
2. **Intended in-story clues ARE allowed in `participant/`** and are NOT leaks:
   - C1: the password `honeybadger4lyfe` appears in the email body *by design* (the gimmick is a
     "leaked" password). Allowed.
   - C2/C4: the crackable passphrases `password123` and `desertstorm` appear only inside the
     shipped **trimmed wordlist** (players are meant to crack them). Allowed *in the wordlist file only*.
   - Ciphertexts (e.g. the four-square ciphertext `UPNAHLNSIBESOLTUEBUPDNEY`, which is line 9 of the
     shipped Challenge 2 payload) are allowed — they are puzzles, not answers.
3. **The final flags, the strong C4 payload password, `keyblock.txt` contents, the four-square
   *plaintext*, and creator-only filenames** (`pw.txt`, `keyblock.txt`, `aeskey.bin`,
   `passwords.txt`, `qtbl_stego.py`, C4's `flag.txt`) must appear ONLY under `facilitator/`.
4. Every `rebuild.sh` must be runnable from the repo root as `bash facilitator/challenges/NN/rebuild.sh`
   after `source build/config.sh`, and must be idempotent (safe to re-run).
5. Every `solve_test.sh` must solve **only** from files present in `participant/` (plus the shipped
   trimmed wordlist for C2), never from `facilitator/` or `ARCHIVE_DIR`, then assert the expected flag.

## Determinism & validation

- Prefer deterministic rebuilds (seeded RNG, pinned inputs). Where the archive used an unseeded
  generator (C2 `genstring.py`), rebuild by re-using the archived canonical bytes rather than
  regenerating, and say so in `PROVENANCE.md`.
- A solver test that cannot assert the exact archived flag is a failure — fix the build, not the test.
- After all challenges build, `make verify-archive` must show the archive fingerprint unchanged:
  `1f90c817321e8b584154abde4ae1b45d76d67997917e8edad78f9465415a4781`.

## Tooling availability (macOS, Apple Silicon)

- Native: `python3`, `openssl`, `binwalk`, `exiftool`, `zip`/`unzip`, `file`, `xxd`, `dd`, `git`, `docker`.
- NOT native (use Docker `--platform linux/amd64 debian:stable-slim`): `steghide`, `stegseek`.
  Working recipe in `build/crack_c2.sh`. Only C2 needs these; C1/C3/C4 use native tools only.

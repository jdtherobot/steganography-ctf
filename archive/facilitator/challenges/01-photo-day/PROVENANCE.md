# Challenge 1 — Photo Day (lvl 2) — Provenance

Immutable source archive: `ARCHIVE_DIR = /Users/jdtherobot/Documents/GitHub/CTF Challenges/archive`
(fingerprint `1f90c817321e8b584154abde4ae1b45d76d67997917e8edad78f9465415a4781`, never modified).

## Canonical artifact (shipped to participants)

| File | SHA-256 | Size |
|---|---|---|
| `ARCHIVE_DIR/main/Challenge 1/email.eml` | `366b8767f647cd5df0ded2384e9e0feaa61b7cc4279b822be4679c660a20ab7b` | 102,452 B |

Chosen because it is the complete, working, player-facing artifact and it
solves end-to-end (verified 2026-07-19: attachment → EXIF Comment →
`openssl enc -aes-256-cbc -d -pbkdf2 -k honeybadger4lyfe -a` →
`Flag{H0NeyB4d6er10OKinG0OD!!!}`), and its **body already contains the correct
no-apostrophe password** `honeybadger4lyfe` ("Definitely not the password:
honeybadger4lyfe"). No correction of the distributable was needed; the
participant copy is byte-identical to the archive.

Identical copies of the same bytes exist at three other archive locations
(all SHA `366b8767...ab7b`), confirming this revision as the one actually
deployed to the original event VM:

- `ARCHIVE_DIR/main/email.eml`
- `ARCHIVE_DIR/virtualbox share original/Challenge 1/email.eml`
- `ARCHIVE_DIR/Kali Virtual Box Files/downloads/pd2/email.eml` (the "pd2" =
  Photo Day lvl 2 folder the player VM saw)

### Embedded/companion ground truth

| File | SHA-256 | Size | Role |
|---|---|---|---|
| `ARCHIVE_DIR/main/Challenge 1/badger_photo.jpeg` | `01c388e88a17f3b9bc4c75aa56608d749ce10bf28fc525b624e8787770c6c859` | 74,825 B | Working attachment; byte-identical to the `image/jpeg` MIME part of the canonical email. EXIF `Comment` = the encrypted flag blob. |
| `ARCHIVE_DIR/main/Challenge 1/Flag.enc.b64` | `c30ef39ff39ed68ef8767c1b5de7866444904a4e86704c161cd36abc86c200e1` | 65 B | `U2FsdGVkX18KFhm4mZ2SwRS7J9jOm2EuecqdadiwCqDFFfA+VIKlg88xIJ/A0l+l` — equals the attachment's EXIF Comment (verified byte-equal). |
| `ARCHIVE_DIR/main/Challenge 1/Flag.txt` | (creator plaintext) | 30 B | `Flag{H0NeyB4d6er10OKinG0OD!!!}` — matches the decryption output exactly. |
| `ARCHIVE_DIR/main/Challenge 1/badger_photo_orig.jpg` | `0b95e87084e0c55be09a1ef6d6e89e137f3d40d8278bf4c522f77b4ef920770c` | 74,756 B | Pre-embed original photo (no EXIF Comment). Creator input only — never shipped. |

## Rejected revisions

| File | SHA-256 | Reason rejected |
|---|---|---|
| `ARCHIVE_DIR/main/Challenge 1/email_test_1.eml` | `2312ddbeaf6950cfcd1fc9b4de7e7be7094c6e8c94c5b56c0b5e79f9e9d6de58` | Earlier draft (Date 15:14:09, six minutes before canonical). Its attachment is `badger_photo.jpg` = the **original** photo (SHA `0b95e870...770c`, 74,756 B) with **no EXIF Comment** — there is nothing to decrypt; the challenge is unsolvable from it. |
| `ARCHIVE_DIR/main/Challenge 1/emailScript.txt` | `fc1d9bbc611892d2ed4398d2e04905eaa9fc1159ea931d10331cc61929571439` | Creator's original heredoc generator (identical copy under `virtualbox share original/`). Not shipped, and not used as the reproducer because `Date: $(date -R)` makes every run non-deterministic. Superseded by the pinned, self-validating `email_gen.py` in this directory. |
| Apostrophe-form password `honeybadger4l'yfe` | n/a (no archived file contains it) | Appeared only in a creator settings note **outside the archive**; it was a shell single-quoting artifact of the generator's `PASSWORD='...'` line, never the real password. Every archived artifact — body text, `emailScript.txt`, and the ciphertext itself — uses/decrypts with the no-apostrophe form `honeybadger4lyfe`, which is pinned everywhere in this rebuild (generator constant, rebuild verification, solve test). |

## Rebuild determinism statement

- `rebuild.sh` never regenerates: it verifies the canonical archive bytes
  still solve, then copies them verbatim to
  `participant/challenges/01-photo-day/email.eml`. Idempotent.
- `email_gen.py` is the repaired reproducer (pinned Date
  `Sun, 28 Sep 2025 15:20:17 +0300`, pinned password, canonical attachment
  embedded verbatim, 64-column base64 like `openssl base64`). Its output was
  verified **byte-identical** to the canonical email (SHA `366b8767...ab7b`)
  and to solve to the flag via its built-in self-check.
- The ciphertext is never re-encrypted: `openssl enc` salts randomly, so a
  re-encryption would change bytes. The canonical blob (with its baked-in
  salt) is preserved inside the canonical attachment.

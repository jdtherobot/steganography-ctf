# Challenge 4 — Stegosaurus 3 — Full Walkthrough (FACILITATOR ONLY)

**Flag:** `Flag{Y0u haVe EnCouNTeR3d a w!Ld s1eEP p@RA1y$!S DEm0n}`

One JPEG (`Honey.jpeg`) is a stack of concatenated files: the cover image, a weakly-encrypted
bundle, a decoy zip, an inner JPEG hiding a raw AES key in its quantization tables, the real
encrypted payload, and a random decoy. The solve is a three-stage key-recovery chain.

## Carrier layout (this v3 rebuild)

```
Honey_orig.jpeg | secret.enc | mid.zip | nothingtoseehere.jpg | payload.enc | decoy_random.enc
```
`binwalk Honey.jpeg` reports (offsets for this build): OpenSSL @ 0x39991 (`secret.enc`),
ZIP @ 0x3C491 (`mid.zip`), JPEG @ 0x3C57E (`nothingtoseehere.jpg`, 25,731 B),
OpenSSL @ 0x42A01 (`payload.enc`), OpenSSL @ 0x42AF1 (`decoy_random.enc`).

## Solve chain

1. **Carve.** `binwalk` (or a magic-byte scan) → carve `secret.enc` (from the first `Salted__`
   to the ZIP), the inner JPEG (the second `FFD8` up to the next `Salted__`), and `payload.enc`.
2. **Crack `secret.enc`** (AES-256-CBC, pbkdf2). Weak password **`desertstorm`** — recoverable
   with the shipped trimmed wordlist or rockyou:
   `openssl enc -d -aes-256-cbc -pbkdf2 -pass pass:desertstorm -in secret.enc -out bundle.zip`
   → unzip → **`qtbl.py`, `STEGO_KEY_386.txt`, `passwords.enc`, `iv.bin`** (the player bundle).
3. **Derive the stego key from `STEGO_KEY_386.txt`.** This is the crux. Split the file into
   **24-character records**; the **"386"** in the filename selects records **3, 8, 6**;
   concatenate them → the `-k` value for `qtbl.py`:
   `R3‖R8‖R6 = QZFCUPBAFMCKZSHSKOSQURRJ‖UPNAHLNSIBESOLTUEBUPDNEY‖PAXUFABOGAZEJEQANIZEYABO`
   (Only the first 32 bytes matter — `qtbl.py` XORs a 32-byte key against the repeating `-k`.)
4. **Extract the raw AES key** from the inner JPEG's quantization tables (2 LSBs/entry):
   `python3 qtbl.py extract -i nothingtoseehere.jpg -k "<R3R8R6>" -o aeskey.bin`
5. **Decrypt `passwords.enc`** with the raw key + IV (AES-256-CBC, **no pbkdf2**):
   `openssl enc -d -aes-256-cbc -in passwords.enc -out passwords.txt -K $(xxd -p aeskey.bin|tr -d '\n') -iv $(xxd -p iv.bin|tr -d '\n')`
6. **Decrypt `payload.enc`** with the strong password listed for it in `passwords.txt`
   (`payload.enc` → `L35f#t8w2&(X$MK8:` + backtick + `SPXa=WV{F%L1G7u8@[>6yI;<N=]=e5#5`):
   `openssl enc -d -aes-256-cbc -pbkdf2 -pass file:pw.txt -in payload.enc -out payload.zip`
   → `unzip -p payload.zip flag.txt` → **the flag.**

`facilitator/challenges/04-stegosaurus-3/solve_test.sh` runs this entire chain from the
participant `Honey.jpeg` and asserts the flag (`C4 PASS`).

## The three authoring fixes applied in this v3 rebuild

1. **"386" clue now matches the key order.** The old archive `keyblock.txt` concatenated records
   **3,6,8**, but the filename `STEGO_KEY_386.txt` implies **3,8,6**. We re-embedded `aeskey.bin`
   into the inner JPEG with the corrected **R3‖R8‖R6** order, so a player who reads "386" literally
   succeeds. (This changes only the QTABLE XOR key; `aeskey.bin`, `iv.bin`, `passwords.enc`,
   `payload.enc` are untouched. Round-trip verified: extracting with R3‖R8‖R6 recovers the original
   `aeskey.bin`.) **Teach this explicitly** — without the 24-char-record / "386" derivation, C4 is
   effectively unsolvable. It's in the hint ladder.
2. **Weak password is now crackable.** The old decoy password `DesertStorm#82pLm` has 0 hits in
   rockyou. We re-encrypted `secret.enc` with **`desertstorm`** (present in rockyou and the shipped
   trimmed wordlist), preserving the intended "crack the weak layer first" path.
3. **Removed the loose 21-byte gap.** The old carrier concatenated a stray `secret.txt`
   ("better luck next time") between `secret.enc` and `mid.zip`, muddying carving. The v3 carrier
   drops it (277,265 B vs the old 277,286 B).

## Red herrings (expect players to chase these)

- **`mid.zip` → `do_not_open.txt`** — a four-square decoy. Its corner "keys" literally spell the
  meme *Honey Badger Don't Care* (TL Honey / TR Badger / BL Dont / BR Care); ciphertext
  `EMVVBFGIATMDATUGEO` decodes to nothing useful. Pure bait.
- **`decoy_random.enc`** — 4,096 random bytes encrypted with `P@$$w0rd1!`; decrypts to noise.
- **`passwords.txt`** lists passwords for every blob (real and decoy), and its decoy labels are
  deliberately scrambled — only the `payload.enc` entry matters.

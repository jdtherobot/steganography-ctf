# Challenge 2 — Stegosaurus 1 — Full Solution (FACILITATOR ONLY)

> **Spoilers below.** This file lives under `facilitator/` and must never be
> distributed to players. It contains the flag and both intended solve paths.

## Flag

```
Flag{DanG 7hat'S @ cUTe HOnEY b@D9eR}
```

## One-line summary

A JPEG (`stego_badger.jpeg`) has a document embedded with **steghide** under the
passphrase **`password123`**. The passphrase is a common `rockyou` entry, so the
image is crackable. Extracting the payload yields a 202-line text file whose
**first line is the flag**.

- Carrier: `stego_badger.jpeg` — 130,623 bytes, SHA-256 `244e2a18…436c`
- Payload: `Flag.txt` (embedded name) → 202 lines / 5,063 bytes, SHA-256 `ddebc7db…11a5`
- Steghide passphrase: `password123`

## In-story clue

The `BRIEF.md` note **"WE WILL, WE WILL…"** completes to *"We will, we will **rock
you**"* — i.e. use the **`rockyou.txt`** wordlist. `password123` sits early in
rockyou, so a dictionary/brute crack lands quickly.

---

## Solve path A — crack it (no passphrase known)

This is the intended player path: they don't know the passphrase, so they crack it
with a wordlist. `stegseek` is the fast steghide cracker.

```bash
# against real rockyou:
stegseek --crack stego_badger.jpeg rockyou.txt out.txt
# against the trimmed wordlist we ship with the CTF:
stegseek --crack stego_badger.jpeg trimmed.txt out.txt
```

Output:

```
[i] Found passphrase: "password123"
[i] Original filename: "Flag.txt".
[i] Extracting to "out.txt".
```

Then:

```bash
head -n1 out.txt
# Flag{DanG 7hat'S @ cUTe HOnEY b@D9eR}
```

(Classic `steghide` has no built-in cracker, so a pure-steghide crack means a
shell loop feeding each wordlist line to `steghide extract -p`. `stegseek` does
the same thing far faster and is the recommended tool.)

## Solve path B — extract with the known passphrase (verification)

Once the passphrase is known (from cracking, or as a facilitator), extraction is
deterministic:

```bash
steghide extract -sf stego_badger.jpeg -p password123 -xf out.txt
head -n1 out.txt
# Flag{DanG 7hat'S @ cUTe HOnEY b@D9eR}
```

On macOS/Apple-Silicon neither tool is native — run them in a Debian
`linux/amd64` container (see `solve_test.sh` and `build/crack_c2.sh` for the exact
recipe). `solve_test.sh` performs **both** checks and asserts the payload hash and
the flag.

---

## The payload, and the cross-challenge tie to Challenge 3

The extracted `Flag.txt` is 202 lines:

- **Line 1** — the flag: `Flag{DanG 7hat'S @ cUTe HOnEY b@D9eR}`
- **Lines 2–202** — 201 pseudo-random 24-character uppercase strings, produced by
  the archive's `genstring.py` (an *unseeded* generator — see `PROVENANCE.md`).
  They are camouflage… with one exception.

> **Deliberate cross-challenge planting — Line 9:**
> ```
> UPNAHLNSIBESOLTUEBUPDNEY
> ```
> This is **not** noise. It is the **Challenge 3 (Stegosaurus 2 / Warehouse)
> four-square ciphertext**. A sharp player who keeps the whole extracted file (not
> just line 1) is holding the input to Challenge 3 before they even start it.
>
> Do **not** point this out in participant materials — the reveal is that C3's
> ciphertext was hiding in plain sight inside C2's payload all along. The C3
> facilitator materials own the decryption (plaintext `TOMHANKSAINTGOTSHITONME`);
> keep that plaintext out of anything C2 ships.

## Facilitator gotchas

- **Don't hand out the payload.** `Flag.txt` / `Flag 2.txt` must never be a static
  file under `participant/` — the flag (line 1) *is* the answer, and line 9 is a
  live puzzle input. Players recover the payload by solving. (`Flag.txt` and
  `Flag 2.txt` are on the secret-scan denied-filenames list for exactly this reason.)
- **The wordlist is allowed to contain `password123`.** It's crackable-by-design;
  that's the whole challenge. It ships only inside `build/wordlists/trimmed.txt`.
- **Real rockyou is ~139 MB** — never commit it. The shipped `trimmed.txt` is a
  small stand-in that still contains `password123` and cracks the image.

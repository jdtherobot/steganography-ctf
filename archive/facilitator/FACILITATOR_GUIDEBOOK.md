# Facilitator Guidebook

Your at-the-table reference while the event is running: the flags, the checkpoints
players should hit, how to release hints, what they'll get wrong, and how to
unstick them. For **setup** (workstations, distribution, the warehouse build,
resets), see [`ADMIN_SETUP.md`](ADMIN_SETUP.md).

This guidebook **links** each challenge's full worked solution and hint ladder
rather than duplicating them — open the `WRITEUP.md` when you need the exact
commands.

> **Private.** Everything below (flags, passwords, the four-square plaintext, the
> "386" trick) stays in `facilitator/` and in your head. Never show it to players
> or put it on a shared screen.

---

## Flags at a glance

| # | Title | Flag |
|---|---|---|
| 1 | Photo Day lvl 2 | `Flag{H0NeyB4d6er10OKinG0OD!!!}` |
| 2 | Stegosaurus 1 | `Flag{DanG 7hat'S @ cUTe HOnEY b@D9eR}` |
| 3 | Stegosaurus 2 (Warehouse) | `Flag{TOMHANKSAINTGOTSHITONME}` |
| 4 | Stegosaurus 3 | `Flag{Y0u haVe EnCouNTeR3d a w!Ld s1eEP p@RA1y$!S DEm0n}` |

Notes:
- Flags are **case- and symbol-sensitive**. Accept them exactly as printed
  (spaces and apostrophes included, e.g. the space and `'` in the C2 flag).
- The **C3 flag is a reconstructed default** — no original C3 flag survived in the
  archive, so it wraps the recovered four-square plaintext:
  `Flag{TOMHANKSAINTGOTSHITONME}`. If your event wants a different C3 flag, change
  it in the challenge's `rebuild.sh`/`WRITEUP.md` and re-test; the *solve path*
  (address walk → note → four-square) is unchanged.

---

## Challenge 1 — Photo Day lvl 2

- **Flag:** `Flag{H0NeyB4d6er10OKinG0OD!!!}`
- **Technique:** EXIF comment extraction → OpenSSL AES-256-CBC decrypt.
- **Full solution:** [`challenges/01-photo-day/WRITEUP.md`](challenges/01-photo-day/WRITEUP.md)
- **Hint ladder:** [`challenges/01-photo-day/HINT_LADDER.md`](challenges/01-photo-day/HINT_LADDER.md)

**The gimmick:** the decrypt password `honeybadger4lyfe` is "leaked" in the email
body **by design** (Pete all but writes "totally not the password" next to it).
That's intended, not a mistake.

**Checkpoints (what a solver should produce, in order):**
1. Opens `email.eml`; reads the body → notes the "definitely not the password"
   line = `honeybadger4lyfe`; saves the photo attachment (`badger_photo.jpeg`).
2. `exiftool badger_photo.jpeg` → spots a suspicious base64 blob in the **Comment**
   field.
3. Extracts it: `exiftool -b -Comment badger_photo.jpeg > flag.enc.b64`.
4. Decrypts:
   `openssl enc -aes-256-cbc -d -pbkdf2 -k honeybadger4lyfe -a -in flag.enc.b64 -out flag.txt`.
5. `flag.txt` → the flag.

---

## Challenge 2 — Stegosaurus 1

- **Flag:** `Flag{DanG 7hat'S @ cUTe HOnEY b@D9eR}`
- **Technique:** steghide with a crackable passphrase (`password123`).
- **Full solution:** [`challenges/02-stegosaurus-1/WRITEUP.md`](challenges/02-stegosaurus-1/WRITEUP.md)
- **Hint ladder:** [`challenges/02-stegosaurus-1/HINT_LADDER.md`](challenges/02-stegosaurus-1/HINT_LADDER.md)

**Checkpoints:**
1. Recognizes `stego_badger.jpeg` as a steghide carrier (a plain `exiftool`/EXIF
   pass won't reveal the payload — this one needs steghide).
2. Cracks the passphrase with a wordlist:
   `stegseek stego_badger.jpeg /tmp/rockyou.txt` (or `stegcracker`). Passphrase =
   `password123`.
3. Extracts the payload:
   `steghide extract -sf stego_badger.jpeg -p password123`.
4. Reads the extracted document → finds the flag.
5. **Downstream link:** **line 9** of that extracted payload is
   `UPNAHLNSIBESOLTUEBUPDNEY` — the ciphertext Challenge 3 needs. Players don't
   need to notice this yet, but it's why C2 must be solved before C3.

---

## Challenge 3 — Stegosaurus 2 (Warehouse)

- **Flag:** `Flag{TOMHANKSAINTGOTSHITONME}` (reconstructed default; see note above)
- **Technique:** x86-64 four-level page-table walk → locate a note → four-square
  cipher decode.
- **Full solution:** [`challenges/03-stegosaurus-2-warehouse/WRITEUP.md`](challenges/03-stegosaurus-2-warehouse/WRITEUP.md)
- **Hint ladder:** [`challenges/03-stegosaurus-2-warehouse/HINT_LADDER.md`](challenges/03-stegosaurus-2-warehouse/HINT_LADDER.md)

**The walk (facilitator eyes only):** split the 48-bit virtual address
`0x0000_0100_4040_1005` into `[L1 9][L2 9][L3 9][L4 9][offset 12]` and walk it:

- **VA `0x0000_0100_4040_1005`** → **row 2 / shelf 1 / bay 2 / sub-section 1 /
  box 5** (L1→row 2, L2→shelf 1, L3→bay 2, L4→sub-section 1, offset→box 5).

**Checkpoints:**
1. Decomposes the VA into 9/9/9/9/12-bit fields (binary is easiest) and walks
   L1→L2→L3→L4→offset to the resolved box.
2. Goes to that location in the warehouse (physical or the game) and finds the
   **note**: corners `Honey` / `Badger` / `Heck` / `Yeah`, center `dCode ▢▢▢▢`,
   and `Line #9`.
3. Reads the four corner words as **four-square keywords**, and `Line #9` as
   "line 9 of the Challenge 2 payload" → `UPNAHLNSIBESOLTUEBUPDNEY`.
4. Runs that ciphertext through a four-square decoder (dCode) with those keywords
   → plaintext `TOMHANKSAINTGOTSHITONME`.
5. Wraps it as the flag.

**Warehouse supervision — physical:**
- Watch for players who get the *right* physical spot by luck but a *wrong*
  address walk — ask them to show their bit-field breakdown before you confirm.
- Keep the note secured at **row 2 / shelf 1 / bay 2 / sub-section 1 / box 5**;
  re-file it after each team. Reset decoys too.
- The corner words must be legible on the printed note — a smudged `Heck`/`Yeah`
  breaks the cipher step.

**Warehouse supervision — virtual (browser game):**
- Confirm the game URL is reachable before the session (serve `warehouse-game/`
  from the [`jd-ctf-environment`](https://github.com/jdtherobot/jd-ctf-environment)
  repo locally, or use <https://britt.gg/ctf/warehouse/>).
- The game is stateless — a stuck player can just reload. Navigation in the game
  mirrors the physical rows/shelves/bays/sub-sections/boxes, so the same hint text
  works for both.
- Remote players will paste the ciphertext into an online four-square tool; that's
  expected and fine (it's a puzzle, not a secret).

---

## Challenge 4 — Stegosaurus 3

- **Flag:** `Flag{Y0u haVe EnCouNTeR3d a w!Ld s1eEP p@RA1y$!S DEm0n}`
- **Technique:** multi-payload carve → crack a weak bundle → JPEG
  quantization-table stego (recover a raw AES key) → chained AES decrypts.
- **Full solution:** [`challenges/04-stegosaurus-3/WRITEUP.md`](challenges/04-stegosaurus-3/WRITEUP.md)
- **Hint ladder:** [`challenges/04-stegosaurus-3/HINT_LADDER.md`](challenges/04-stegosaurus-3/HINT_LADDER.md)

This is the hardest challenge and the one where you'll spend the most facilitation
time. It's **three stages**; players routinely stall at the "386" step (stage 2).

**Stage 0 — recon.** `binwalk Honey.jpeg` reveals several concatenated payloads at
different offsets: a ZIP (`mid.zip`, a red herring), an OpenSSL blob
(`secret.enc`, the weakly-encrypted bundle), an **inner JPEG**
(`nothingtoseehere.jpg`), and two more OpenSSL blobs (`payload.enc` — the real
flag, strong; `decoy_random.enc` — a decoy). Players carve these with `dd` using
the binwalk offsets.

**Stage 1 — crack the weak bundle.** `secret.enc` is AES-256-CBC + PBKDF2 with the
**weak** password `desertstorm` (in `rockyou` and the shipped trimmed wordlist).
Crack it (e.g. a small OpenSSL loop over the wordlist), decrypt to
`secret_bundle.zip`, and unzip → you get `qtbl.py` (a stego helper),
`STEGO_KEY_386.txt`, `iv.bin`, `passwords.enc`, plus decoys.

**Stage 2 — the "386" step (the crux).** See the dedicated section below.

**Stage 3 — final decrypt.** The recovered `passwords.txt` lists the **strong**
payload password; use it to decrypt the carved `payload.enc`
(AES-256-CBC + PBKDF2) → `payload.zip` → unzip → `flag.txt` → the flag.

**Checkpoints:**
1. `binwalk Honey.jpeg` → an offset map of 4–5 payloads.
2. Carves each payload with `dd` (correct `skip=` offsets).
3. Cracks `secret.enc` → `secret_bundle.zip` → `qtbl.py` + `STEGO_KEY_386.txt` +
   `iv.bin` + `passwords.enc`.
4. Derives the **72-char keyblock** from `STEGO_KEY_386.txt` (the "386" trick).
5. `qtbl.py extract` on the carved inner JPEG with that keyblock → the **raw
   32-byte AES key**.
6. Decrypts `passwords.enc` with that raw key + `iv.bin` → `passwords.txt`.
7. Uses the strong password from `passwords.txt` → decrypts `payload.enc` → flag.

### The C4 "386" derivation — spell this out (only when a player has earned it)

This is the single step that makes Challenge 4 solvable, and the step players most
often miss. **The clue is the filename: `STEGO_KEY_386.txt`.**

`STEGO_KEY_386.txt` is one long stream of characters (no line breaks) —
**4824 characters = 201 records of 24 characters each.** The digits **3, 8, 6** in
the filename are record indices:

1. Split the file into **24-character records** (record 1 = chars 1–24, record 2 =
   chars 25–48, and so on).
2. Take records **3, 8, and 6** — **in that order** (the order of the digits in
   "386").
3. Concatenate them → a **72-character keyblock** (3 × 24).

That 72-char keyblock is the `-k` key `qtbl.py` needs to extract the AES key from
the inner JPEG's quantization tables:

```bash
# after carving the inner JPEG (nothingtoseehere.jpg) from Honey.jpeg:
KEYBLOCK="<record3><record8><record6>"     # 72 chars, derived as above
python3 qtbl.py extract -i nothingtoseehere.jpg -k "$KEYBLOCK" -o aeskey.bin
# then decrypt passwords.enc with the raw key + iv.bin:
KEYHEX=$(xxd -p aeskey.bin | tr -d '\n'); IVHEX=$(xxd -p iv.bin | tr -d '\n')
openssl enc -aes-256-cbc -d -in passwords.enc -out passwords.txt -K "$KEYHEX" -iv "$IVHEX"
```

Without the right records **in the right order**, `qtbl.py` returns garbage and
the `openssl` decrypt fails with a bad-decrypt/padding error. If a player is
staring at that error, they almost certainly have the records wrong or in the
wrong order — point them back at the **filename**. (Exact byte values and the full
command sequence are in the C4 `WRITEUP.md`.)

---

## Staged hint-release guidance

Give **one rung at a time**, and only the *next* rung — never skip ahead, and
never name a downstream stage. Each challenge's `HINT_LADDER.md` (linked above) has
the exact wording; the general shape:

1. **Nudge the mindset** — "what kind of file is this really? what haven't you
   looked at yet?"
2. **Name the tool class** — "this is a metadata problem," "this needs a steghide
   cracker," "walk the address before you look for anything."
3. **Point at the artifact** — "check the Comment field," "line 9 of what you
   pulled out of Challenge 2," "the filename is telling you the recipe."
4. **Give the mechanic** — the actual command shape or the exact derivation — last
   resort, and only for a genuinely stuck player who's done the earlier steps.

Hard **do-not-reveal-early** items:
- C1: don't quote the password until they've at least opened the email.
- C3: don't mention "four-square" or "line 9" until they've resolved the address
  and found the note.
- C4: don't mention the inner JPEG, `qtbl.py`, or the "386" record trick until
  they're holding `STEGO_KEY_386.txt` from the cracked bundle.

---

## Common mistakes & targeted interventions

**Challenge 1**
- *Decrypts with the wrong string.* They grab a nearby word instead of
  `honeybadger4lyfe`, or include stray punctuation. → "Read the 'definitely not
  the password' line exactly, no extra characters."
- *Forgets `-pbkdf2`.* OpenSSL then derives the key the old way and fails. → "Match
  the encryption options: it's `-aes-256-cbc -pbkdf2`."
- *Feeds the raw image to openssl.* → "Extract the Comment field first, then
  decrypt that."

**Challenge 2**
- *Tries EXIF/binwalk and concludes "nothing's there."* Steghide payloads don't
  show up that way. → "This is a steghide carrier — you need steghide (and a
  passphrase)."
- *Cracker can't find the wordlist.* → point them at
  `zcat /usr/share/wordlists/rockyou.txt.gz > /tmp/rockyou.txt`.
- *Finds the flag, ignores the rest of the document.* Fine for C2 — but remind
  them later that C3 needs a specific line from this same payload.

**Challenge 3**
- *Guesses the location instead of walking the address.* → require the 9/9/9/9/12
  bit-field breakdown before you confirm a location.
- *Off-by-one on the fields* (e.g., forgetting the 12-bit offset, or miscounting
  rows). → "Convert the hex to binary and slice it into 9,9,9,9,12 from the left."
- *Has the note but doesn't recognize four-square.* → "The corner words are
  keywords; 'dCode' is the tool; feed it line 9."
- *Uses the wrong ciphertext.* It must be **line 9** of the Challenge 2 payload,
  not a line they invented.

**Challenge 4**
- *Stops after the first decoy.* `mid.zip`/`do_not_open.txt`, `decoy_random.enc`,
  and the "better luck next time" text are all red herrings. → "How many payloads
  did binwalk show? You've only opened one."
- *Wrong carving offsets* (off-by-one on `dd skip=`, or grabbing trailing bytes).
  → "Re-read the binwalk offsets; carve from the exact byte, and don't over-run
  into the next payload."
- *Cracks `secret.enc` but can't use `qtbl.py`.* Almost always the keyblock. →
  the "386" section above.
- *Bad decrypt on `passwords.enc`.* Wrong AES key (bad keyblock) or wrong IV. →
  "Re-derive the keyblock from the filename; make sure you're using the `iv.bin`
  from the bundle, in hex."
- *Bad decrypt on `payload.enc`.* Wrong password from `passwords.txt`, or missing
  `-pbkdf2`. → "It's the *strong* one in that list, and it's `-pbkdf2` like the
  others."

---

## Troubleshooting quick table

| Symptom | Likely cause | What to check |
|---|---|---|
| **"Nothing found"** (EXIF/binwalk empty) | Wrong tool for the hiding method | C2 needs **steghide**, not EXIF/binwalk. C1's payload is in the **Comment** field specifically. |
| **"could not extract any data" / wrong passphrase** (steghide) | Passphrase not cracked yet, or a typo | C2 passphrase is `password123`; make sure the cracker actually finished and they copied it exactly. |
| **"bad decrypt" / "bad magic number"** (OpenSSL) | Wrong password/key, wrong IV, or missing `-pbkdf2` | Match cipher + KDF options; verify the key/password source; for C4 `passwords.enc` it's a **raw key + IV**, not a passphrase. |
| **`qtbl.py` outputs garbage** (C4) | Keyblock wrong or records out of order | Re-derive from `STEGO_KEY_386.txt`: 24-char records, take **3, 8, 6** in that order → 72 chars. |
| **Carve produces a broken/short file** (C4) | Wrong `dd` offset or length | Re-read binwalk; `skip=` the exact start byte; don't run past the next signature. |
| **Unzip fails after decrypt** (C1/C4) | Decrypt actually failed but they didn't notice | If the decrypt was wrong, the "zip" is garbage — fix the decrypt first. |
| **C3 location "works" but flag is wrong** | Lucky location, wrong ciphertext/keywords | Confirm the address walk *and* that they used **line 9** with the four corner keywords. |
| **Warehouse game won't load** | URL/server not up | Serve `warehouse-game/` from the [`jd-ctf-environment`](https://github.com/jdtherobot/jd-ctf-environment) repo locally, or use <https://britt.gg/ctf/warehouse/>. |

---

## If you need to prove the bundle still solves

Run `make test-challenges` from the repo root (see [`ADMIN_SETUP.md`](ADMIN_SETUP.md)
§6). Each challenge's `solve_test.sh` solves from the **participant** files only and
asserts the exact flag in the table above. A green run means the challenges are
intact and the flags match.

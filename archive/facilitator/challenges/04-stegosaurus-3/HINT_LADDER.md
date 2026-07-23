# Challenge 4 — Staged Hint Ladder (FACILITATOR ONLY)

Release in order, only when a team is genuinely stuck. This is the hardest challenge; the
key-derivation step (Hint 6) is the one most teams need.

1. **Getting started.** "One file can be several files glued together. What does `binwalk` say?"
2. **Carving.** "Those offsets are real embedded files. Carve them out with `dd` (or binwalk's
   extraction). You should get an OpenSSL blob, a zip, another JPEG, and two more OpenSSL blobs."
3. **First lock.** "The first OpenSSL blob is a *weakly* encrypted zip — the kind a wordlist can
   open. Point rockyou (or the provided wordlist) at it. Think military/theme." (→ `desertstorm`)
4. **The bundle.** "Cracking it gives you `qtbl.py`, `STEGO_KEY_386.txt`, `passwords.enc`, and
   `iv.bin`. `qtbl.py` extracts data hidden in a JPEG's quantization tables — but it needs a key."
5. **Which JPEG.** "The key hides in the *inner* JPEG you carved (`nothingtoseehere.jpg`), not the
   cover. `qtbl.py extract` recovers a raw 32-byte AES key — once you give it the right `-k`."
6. **The key derivation (the crux).** "Look at the filename: `STEGO_KEY_386.txt`. The file is a
   long run of fixed-length **24-character records**. The **3-8-6** tells you *which* records and
   *in what order*: take record 3, then record 8, then record 6, and concatenate them. That string
   is the `-k` for `qtbl.py`."
7. **Two more crypto steps.** "Use the extracted AES key **with `iv.bin`** (raw key, `-K`/`-iv`,
   no `-pbkdf2`) to decrypt `passwords.enc` → a password list. One of those passwords opens the
   real payload (`payload.enc`, this time *with* `-pbkdf2`). Ignore the decoy blob and the meme zip."
8. **Home stretch.** "Decrypt `payload.enc` with the password labelled for it, unzip, read
   `flag.txt`." (Flag: `Flag{Y0u haVe EnCouNTeR3d a w!Ld s1eEP p@RA1y$!S DEm0n}`.)

**Common wrong turns:** cracking `decoy_random.enc` (random noise), opening `mid.zip`'s
`do_not_open.txt` (a four-square joke — "Honey Badger Don't Care"), forgetting `-pbkdf2` on the
final payload, or using pbkdf2 on `passwords.enc` (that one uses the raw key + IV, no pbkdf2).

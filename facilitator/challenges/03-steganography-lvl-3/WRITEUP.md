# Challenge 3 · Steganography lvl 3 — Facilitator Writeup

**FACILITATOR ONLY — contains the flag and every secret. Never hand to players.**

Verified end-to-end against the author's original `Challenge 4v2` carrier (see **Verification**).

| | |
|---|---|
| Technique | one JPEG = several concatenated payloads → carve → *reasoned* crack → QTABLE-stego AES key → nested AES |
| Distributable | `Honey.jpeg` (author's original carrier, 277,286 B — includes the `secret.txt` marker) |
| Flag | `Flag{Y0u haVe EnCouNTeR3d a w!Ld s1eEP p@RA1y$!S DEm0n}` |
| Tools | `binwalk`, `dd`, `openssl`, `unzip`, `xxd`, `python3`, `awk`, `file` |

## Passwords & key material (creator-only)

```
strong payload password (pw.txt):  L35f#t8w2&(X$MK8:`SPXa=WV{F%L1G7u8@[>6yI;<N=]=e5#5
weak layer  (secret.enc):          DesertStorm#82pLm      ← reasoned, NOT brute-forced
random decoy (decoy_random.enc):   P@$$w0rd1!
stego key   (keyblock.txt):        records 3·6·8 of STEGO_KEY_386.txt (see below)
```

## Carrier layout (author's assembly)

```
cat Honey_orig.jpeg  secret.enc  secret.txt  mid.zip  nothingtoseehere.jpg  payload.enc  decoy_random.enc  > Honey.jpeg
```
`binwalk Honey.jpeg` shows: OpenSSL (`secret.enc`), the `secret.txt` marker, ZIP (`mid.zip`),
JPEG (`nothingtoseehere.jpg`), OpenSSL (`payload.enc`), OpenSSL (`decoy_random.enc`). Carve with `dd`.

## The weak layer — reasoned, not brute-forced (the crux)

The player brief (the "John / Desert Storm" narration) teaches the player to **construct** the
password for `secret.enc`, not wordlist-crack it:

- codename → **DesertStorm**
- add `#`
- two digits + a three-letter mixed-case tag → mask **`?d?d?l?u?l`** → **82pLm**
- Aho · Weinberger · Kernighan → **`awk`** = "stitch a word and a tail into one rope" (concatenate prefix + suffix)

→ **`DesertStorm#82pLm`**:
```
openssl enc -d -aes-256-cbc -pbkdf2 -pass pass:'DesertStorm#82pLm' -in secret.enc -out secret_bundle.zip
unzip secret_bundle.zip     # → qtbl.py, STEGO_KEY_386.txt, passwords.enc, iv.bin
```
> This reason-it-out design is the author's intent; it replaces the earlier reconstruction's
> `desertstorm` + rockyou, which broke the clue chain.

## The stego key — "386" (ties back to lvl 2)

`STEGO_KEY_386.txt` is a single 4,824-char line = **201 × 24-char records, and they are exactly the
201 filler lines the player already saw in lvl 2** (verified equal). That is why the Warehouse hint
asks "beat lvl 2 first."

The **digits of `386` are the record numbers {3, 6, 8}**; concatenate those three records **in
ascending order**:
```
record 3 = QZFCUPBAFMCKZSHSKOSQURRJ
record 6 = PAXUFABOGAZEJEQANIZEYABO
record 8 = UPNAHLNSIBESOLTUEBUPDNEY        (also the Warehouse ciphertext)
key = R3‖R6‖R8 = QZFCUPBAFMCKZSHSKOSQURRJPAXUFABOGAZEJEQANIZEYABOUPNAHLNSIBESOLTUEBUPDNEY
```
This equals the creator-only `keyblock.txt` byte-for-byte. (`qtbl.py` XORs the first 32 bytes against
the payload.)

> **Naming note for the author:** the file is `STEGO_KEY_386.txt` but the key concatenates the records
> in **ascending** order (3, 6, 8), not the literal digit order 3-8-6. It solves either way only if a
> player sorts; a player who reads "386" as a literal order and tries 3-8-6 first will get a wrong key
> and have to reorder. Kept exactly as you authored it — flagging in case you'd rather rename it
> `STEGO_KEY_368.txt` (or add a word to the clue). No change made without your say-so.

## Recover the AES key and unwind

```
# 1) carve the inner JPEG, then pull the raw 32-byte AES key from its quantization tables
python3 qtbl.py extract -i nothingtoseehere.jpg -o aeskey.bin -k "<R3‖R6‖R8 above>"

# 2) decrypt passwords.enc with the raw key + IV (no pbkdf2)
openssl enc -d -aes-256-cbc -in passwords.enc -out passwords.txt \
  -K "$(xxd -p aeskey.bin | tr -d '\n')" -iv "$(xxd -p iv.bin | tr -d '\n')"

# 3) use the payload password from passwords.txt to decrypt payload.enc (pbkdf2)
openssl enc -d -aes-256-cbc -pbkdf2 -pass file:pw.txt -in payload.enc -out payload.zip
unzip -p payload.zip flag.txt        # → the flag
```

`passwords.txt` (recovered) maps each blob to its password: `secret.enc → DesertStorm#82pLm`,
`decoy_random.enc → P@$$w0rd1!`, `payload.enc →` the strong `pw.txt` password.

## Decoys (expect players to chase them)

- `mid.zip` → `do_not_open.txt` — a four-square joke, not the path.
- `decoy_random.enc` → random bytes (`P@$$w0rd1!`).
- a stray `secret.txt` → "better luck next time."

## Player-vs-creator files

- **Players obtain** (only after cracking `secret.enc`): `qtbl.py`, `STEGO_KEY_386.txt`,
  `passwords.enc`, `iv.bin`.
- **Creator-only, never shipped:** `keyblock.txt`, `qtbl_stego.py`, `passwords.txt` (plaintext),
  `aeskey.bin`, `pw.txt`, `flag.txt`.

## Verification (done, in-sandbox, from the author's originals)

1. `secret.enc` decrypts with the reasoned `DesertStorm#82pLm` → the four-file bundle. ✅
2. `STEGO_KEY_386.txt` records == lvl-2's 201 filler records. ✅
3. `keyblock.txt` == `R3‖R6‖R8` (records 3·6·8 ascending). ✅
4. `qtbl.py extract` on the inner JPEG with that key recovers `aeskey.bin` byte-for-byte
   (`a1f88de3…342160`). ✅
5. `aeskey.bin` + `iv.bin` decrypt `passwords.enc`; `pw.txt` decrypts `payload.enc` →
   `Flag{Y0u haVe EnCouNTeR3d a w!Ld s1eEP p@RA1y$!S DEm0n}`. ✅

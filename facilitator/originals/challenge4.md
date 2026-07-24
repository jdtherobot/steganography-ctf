# Challenge 4 — Stegosaurus 3 (Admin SOP)

**Goal:** Distribute one JPEG (`Honey.jpeg`) containing multiple embedded payloads (decoys + inner image + the *only* way to recover the AES key).  
**High-level player flow:** `binwalk` → note offsets → `dd` carve → crack `secret.enc` → obtain `qtbl.py` + `STEGO_KEY_368.txt` + `passwords.enc` + `iv.bin` → extract AES key from `nothingtoseehere.jpg` (QTABLEs) using `qtbl.py` + `STEGO_KEY_368.txt` → decrypt `passwords.enc` → use recovered passwords to decrypt `payload.enc` → obtain `flag.txt`.

---

## Variables / canonical filenames
Use these exact filenames in commands. Do not rename without updating commands.

- `flag.txt` → zipped → `payload.zip` → encrypted → `payload.enc`  
  - payload password file: `pw.txt` (contains the long PASSWORD)
- `secret.txt` (decoy text)
- `do_not_open.txt` → zipped → `mid.zip` (innocuous zip decoy)
- `passwords.txt` (plaintext list that will be encrypted into `passwords.enc`)
- `random.bin` → used to create `decoy_random.enc`
- `keyblock.txt` (creator-only STEGO_KEY used for XOR obfuscation during QTABLE embed)
- `STEGO_KEY_368.txt` (hint file included in player bundle; players obtain this via cracking `secret.enc`)
- `qtbl_stego.py` (creator-only full helper; must support 2-LSB + raw-32 mode)
- `qtbl.py` (player copy of helper; same functional behavior, comments removed)
- `aeskey.bin` (raw 32-byte AES key — **only embedded** in QTABLEs of `nothingtoseehere.jpg`)
- `inner.jpeg` (cover image used for embedding)
- `nothingtoseehere.jpg` (inner image after embedding `aeskey.bin`, carved by players)
- `iv.bin` (16-byte IV; public; included in player bundle)
- `passwords.enc` (`passwords.txt` encrypted with `aeskey.bin` + `iv.bin`; included in player bundle)
- `secret_bundle.zip` (contains: `qtbl.py`, `STEGO_KEY_368.txt`, `passwords.enc`, `iv.bin`)
- `secret.enc` (weakly-encrypted `secret_bundle.zip`; players crack this)
- `Honey_orig.jpeg` (carrier base image)
- `Honey.jpeg` (final concatenated distribution file)


**Security rule:** `aeskey.bin` must exist **only** locally and embedded in the QTABLEs. Do not include `aeskey.bin` in any distributed bundle.

---

## Preconditions
- `qtbl_stego.py` performs the following:
- embedding/extracting using **2 LSBs** per 8-bit QTable entry,
- embedding/extracting a **raw 32-byte** payload without the 8-byte header (raw-key mode),
- optional XOR obfuscation with a STEGO key (`-k`).
- `qtbl.py` given to players must be functionally equivalent for extraction (may have comments removed).
- `keyblock.txt` is creator-only. `STEGO_KEY_368.txt` is included in `secret_bundle.zip` and provided to players after cracking.
- `iv.bin` is public and included in the bundle.
- Test full player flow locally before release.

---

## Creator build walkthrough (complete step-by-step commands)

> Pre-reqs: `python3`, updated `qtbl_stego.py`, `qtbl.py`, `zip`, `openssl`, `xxd`, `binwalk`, `dd`.


# 0. Create initial files (if not already present)
## (Skip creation lines for files already made)
echo 'FLAG{example_flag_here}' > flag.txt
echo 'better luck next time'        > secret.txt
cat > do_not_open.txt <<'EOF'
DO NOT OPEN
Four-Square decoy
EOF
## Create decoy random bytes
openssl rand -out random.bin 4096

## Ensure creator-only items exist:
## - keyblock.txt         (creator STEGO_KEY)
## - STEGO_KEY_368.txt    (player hint to place in the bundle later)
## - qtbl_stego.py        (creator copy, updated)
## - qtbl.py              (player copy, functional)

# 1. Create zip artifacts
zip -j payload.zip flag.txt
zip -j mid.zip do_not_open.txt
## passwords.txt must NOT be zipped — it will be encrypted to passwords.enc

# 2. Prepare payload.enc (strongly encrypted flag bundle)
## Create pw.txt containing the exact long PASSWORD (no trailing newline)
printf '%s' 'L35f#t8w2&(X$MK8:`SPXa=WV{F%L1G7u8@[>6yI;<N=]=e5#5' > pw.txt
chmod 600 pw.txt

## Encrypt payload.zip using password from file
openssl enc -aes-256-cbc -pbkdf2 -salt -pass file:./pw.txt -in payload.zip -out payload.enc

# 3. Create decoy encrypted blob
## Encrypt random.bin with decoy password (P@$$w0rd1!)
openssl enc -aes-256-cbc -pbkdf2 -salt -pass pass:'P@$$w0rd1!' -in random.bin -out decoy_random.enc

# 4. Generate AES key and embed into inner image (critical secret)
## 4.1 Generate raw 32-byte AES key (binary)
openssl rand -out aeskey.bin 32

## 4.2 Embed the raw key into QTABLEs of the cover image (produces nothingtoseehere.jpg)
## Use creator-only keyblock.txt for XOR obfuscation (do not distribute keyblock.txt)
python3 qtbl_stego.py embed -i inner.jpeg -o nothingtoseehere.jpg -m aeskey.bin -k "$(cat keyblock.txt)"

## After embedding, keep aeskey.bin only until verification; then securely remove local copy


# 5. Create IV and encrypt passwords.txt with the raw AES key
## 5.1 Create public IV file (16 bytes)
openssl rand -out iv.bin 16

## 5.2 Convert aeskey.bin to hex for OpenSSL; this must be done BEFORE shredding aeskey.bin
KEYHEX=$(xxd -p aeskey.bin | tr -d '\n')
IVHEX=$(xxd -p iv.bin    | tr -d '\n')

## 5.3 Encrypt passwords.txt using raw AES key + IV (produces passwords.enc)
openssl enc -aes-256-cbc -in passwords.txt -out passwords.enc -K "$KEYHEX" -iv "$IVHEX"
## passwords.enc and iv.bin are safe to include in player bundle

## (Do not add aeskey.bin to any distributed file)
shred -u aeskey.bin || rm -f aeskey.bin

# 6. Build the secret bundle (player will recover this after cracking secret.enc)
## The bundle includes the player helper, the hint, the encrypted passwords, and the IV
zip -j secret_bundle.zip qtbl.py STEGO_KEY_368.txt passwords.enc iv.bin

# 7. Weakly encrypt the bundle to produce secret.enc (players must crack this)
## Use DECOYPASSWORD = DesertStorm#82pLm (as provided)
openssl enc -aes-256-cbc -pbkdf2 -salt -pass pass:'DesertStorm#82pLm' -in secret_bundle.zip -out secret.enc

# 8. Assemble final carrier Honey.jpeg
## Order example: base image, weak bundle, innocuous zip, inner stego image, strong payload.enc, random decoy
cat Honey_orig.jpeg secret.enc secret.txt mid.zip nothingtoseehere.jpg payload.enc decoy_random.enc > Honey.jpeg

# 9. Local sanity check (simulate player flow)
mkdir -p rb && rm -f rb/*
## 9.1 Crack secret.enc (simulate player cracking)
openssl enc -d -aes-256-cbc -pbkdf2 -pass pass:'DesertStorm#82pLm' -in secret.enc -out rb/secret_bundle.zip
unzip -qq rb/secret_bundle.zip -d rb

## 9.2 Extract AES key from the inner stego image using recovered STEGO_KEY_368.txt and player helper
###This needs to be the actual stego key used. The player has STEGO_KEY_368.txt - but they will need to solve to get the same string as we have in keyblock.txt
python3 rb/qtbl.py extract -i nothingtoseehere.jpg -o rb/aeskey_rec.bin -k "$(cat rb/keyblock.txt)"

## 9.3 Decrypt passwords.enc using recovered AES key + iv included in the bundle
KEYHEX_REC=$(xxd -p rb/aeskey_rec.bin | tr -d '\n')
IVHEX_REC=$(xxd -p rb/iv.bin | tr -d '\n')
openssl enc -d -aes-256-cbc -in rb/passwords.enc -out rb/passwords.dec -K "$KEYHEX_REC" -iv "$IVHEX_REC"

## 9.4 Verify roundtrip
cmp -s rb/passwords.dec passwords.txt && echo "Roundtrip OK" || echo "Roundtrip FAIL"

## 9.5 Bing Bang Boom the pw is there
cp rb/passwords.dec passwords.txt

## 9.6 test the password (assume pw.txt) on the payload to uncover the flag
openssl enc -d -aes-256-cbc -pbkdf2 -pass file:./pw.txt -in payload.enc -out /tmp/payload.zip && unzip -p /tmp/payload.zip flag.txt

## If verification fails:
## - Confirm rb/aeskey_rec.bin hex matches original aeskey.bin hex (before shredding)
## - Confirm rb/iv.bin is same IV used to encrypt passwords.enc
## - Confirm rb/qtbl.py supports 2-LSB + raw-32 extraction and STEGO_KEY_368.txt matches creator's keyblock.txt used during embed

---
## Player Steps

## 1) Inspect the distribution
binwalk Honey.jpeg

## 2) Carve inner image (replace OFFSET_INNER with the offset from binwalk)
dd if=Honey.jpeg of=inner_decoy.jpg bs=1 skip=OFFSET_INNER

## 3) Crack secret.enc (easy) to recover the bundle (qtbl.py, STEGO_KEY_368.txt, passwords.enc, iv.bin)
openssl enc -d -aes-256-cbc -pbkdf2 -pass pass:'DesertStorm#82pLm' -in secret.enc -out secret_bundle.zip
unzip secret_bundle.zip

## 4) Extract the AES key from carved inner image using helper + hint
python3 qtbl.py extract -i inner_decoy.jpg -o aeskey.bin -k "$(cat STEGO_KEY_368.txt)"

## 5) Convert AES key to hex and decrypt passwords.enc using included iv.bin
KEYHEX=$(xxd -p aeskey.bin | tr -d '\n')
IVHEX=$(xxd -p iv.bin | tr -d '\n')
openssl enc -d -aes-256-cbc -in passwords.enc -out passwords.txt -K "$KEYHEX" -iv "$IVHEX"

## 6) Manually open passwords.txt, find the correct password, and save it into pw.txt

## 7) Use the password in pw.txt to decrypt payload.enc 
openssl enc -d -aes-256-cbc -pbkdf2 -pass file:./pw.txt -in payload.enc -out /tmp/payload.zip

## 8) Print the flag from the decrypted zip
unzip -p /tmp/payload.zip flag.txt


---
## Admin notes & best practices
- aeskey.bin secrecy: aeskey.bin is the only thing that decrypts passwords.enc. Ensure it exists only locally and is embedded in the QTABLEs. Do not distribute it.
- STEGO_KEY handling: keyblock.txt (creator-only) is used to XOR payload before embedding. Provide STEGO_KEY_368.txt to players inside secret_bundle.zip after weak encryption is cracked.
- Script compatibility: qtbl.py (player copy) must support 2-LSB and raw-32 extraction. Remove comments for player copy if desired but keep functionality intact.
- IV: iv.bin is public and included in secret_bundle.zip.
- Testing: perform full player flow locally and confirm "Roundtrip OK" in the sanity check before releasing.
- Decoys: include mid.zip, payload.enc, decoy_random.enc to create noise and multiple offsets for players to analyze. Ensure decoys have correct headers so binwalk recognizes them.
- Cleanup: shred local sensitive files after successful embedding: shred -u aeskey.bin pw.txt

---

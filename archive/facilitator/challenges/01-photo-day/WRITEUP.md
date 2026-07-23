# Challenge 1 — Photo Day (lvl 2) — Facilitator Writeup

**SPOILERS. Facilitator eyes only.**

| | |
|---|---|
| Distributable | `participant/challenges/01-photo-day/email.eml` (102,452 bytes) |
| Technique | EXIF `Comment` tag carrying an OpenSSL-encrypted blob; password leaked in the email body |
| Password | `honeybadger4lyfe` — **no apostrophe** (body line: "Definitely not the password: honeybadger4lyfe") |
| Cipher | AES-256-CBC, PBKDF2 key derivation, base64-armored (`openssl enc`) |
| **Flag** | `Flag{H0NeyB4d6er10OKinG0OD!!!}` |
| Tools | any mail client or `python3` (extract), `exiftool`, `openssl` |

## Intended solve path

### 1. Open the intercepted email and actually read it

`email.eml` is a plain MIME multipart message (open in a mail client, a text
editor, or parse it). The body is comedy, but it hands the player two clues:

- "**Definitely not the password: honeybadger4lyfe**" — the password.
- The signature "**256 Air Expeditionary Squadron (256 AES)**" — the cipher
  (AES-256).

### 2. Extract the attachment

The attachment is `badger_photo.jpeg` (74,825 bytes), base64-encoded in the
second MIME part. Drag it out of a mail client, or:

```bash
python3 - <<'EOF'
import email, email.policy
msg = email.message_from_binary_file(open("email.eml", "rb"),
                                     policy=email.policy.default)
for part in msg.walk():
    if part.get_content_type() == "image/jpeg":
        open(part.get_filename(), "wb").write(part.get_payload(decode=True))
        print("wrote", part.get_filename())
EOF
```

### 3. Inspect the photo's metadata

The picture itself is clean — the payload is in the EXIF/JPEG **Comment** tag:

```bash
exiftool badger_photo.jpeg          # spot the odd Comment field
exiftool -Comment -b badger_photo.jpeg > c.b64
cat c.b64
# U2FsdGVkX18KFhm4mZ2SwRS7J9jOm2EuecqdadiwCqDFFfA+VIKlg88xIJ/A0l+l
```

`U2FsdGVkX1...` base64-decodes to bytes beginning `Salted__` — the classic
`openssl enc` salted-ciphertext header. Combined with the "256 AES" signature
gag, that spells `openssl enc -aes-256-cbc`.

### 4. Decrypt with the leaked password

```bash
openssl enc -aes-256-cbc -d -pbkdf2 -k honeybadger4lyfe -a -in c.b64
```

Output:

```
Flag{H0NeyB4d6er10OKinG0OD!!!}
```

One-liner from the attachment alone:

```bash
exiftool -Comment -b badger_photo.jpeg | \
  openssl enc -aes-256-cbc -d -pbkdf2 -k honeybadger4lyfe -a
```

## Common player pitfalls

- **Omitting `-pbkdf2`.** The blob was encrypted with PBKDF2 key derivation.
  Modern OpenSSL 3.x defaults still differ (EVP_BytesToKey + digest) unless
  `-pbkdf2` is passed, so decryption without it yields `bad decrypt`. Players
  who see `bad decrypt` with the right password need this switch (hint 4
  territory).
- **Omitting `-a`.** The ciphertext is base64-armored; without `-a` (or a
  manual `base64 -d` first) openssl reads garbage and fails.
- **Typing the password with an apostrophe.** The working password has no
  apostrophe; the body text is authoritative. (Historical note: one creator
  settings revision displayed `honeybadger4l'yfe` — a shell-quoting artifact,
  never the real password. See `PROVENANCE.md`.)
- **Staring at the pixels.** `strings`, LSB tools, etc. find nothing; the
  payload is pure metadata. `exiftool` (or even `strings` on the first 1 KB,
  which does reveal the comment) is the move.

## How the artifact was built (creator pipeline)

1. `Flag.txt` (`Flag{H0NeyB4d6er10OKinG0OD!!!}`, 30 bytes) encrypted:
   `openssl enc -aes-256-cbc -pbkdf2 -k honeybadger4lyfe -a` →
   `Flag.enc.b64` = `U2FsdGVkX18KFhm4...0l+l` (the salt is baked into that
   blob, which is why rebuilds reuse the canonical ciphertext rather than
   re-encrypting).
2. `exiftool -Comment="<blob>" badger_photo_orig.jpg` → `badger_photo.jpeg`
   (74,756 → 74,825 bytes).
3. A shell heredoc script (archived as `emailScript.txt`) wrapped body +
   base64 attachment into `email.eml`.

The repaired, deterministic reproducer is
`facilitator/challenges/01-photo-day/email_gen.py` — it pins the Date header
and the no-apostrophe password, embeds the canonical attachment, self-solves
its output, and regenerates the canonical `email.eml` **byte-identically**
(SHA-256 `366b8767...ab7b`):

```bash
source build/config.sh
python3 facilitator/challenges/01-photo-day/email_gen.py \
    --out build/scratch/c1/email_regen.eml
```

## Verification

- `bash facilitator/challenges/01-photo-day/rebuild.sh` — verifies the
  archived canonical email solves, installs it into `participant/`.
- `bash facilitator/challenges/01-photo-day/solve_test.sh` — black-box solve
  from the participant file only (it even harvests the password from the body
  text, so a body/password mismatch fails); prints `C1 PASS`.

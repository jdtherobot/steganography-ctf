# Challenge 1 · Steganography lvl 1 — Facilitator Writeup

**FACILITATOR ONLY — contains the flag and setup. Never hand to players.**

| | |
|---|---|
| Technique | EXIF `Comment` carrying an OpenSSL-encrypted blob; password leaked in the email body |
| Distributable | `email.eml` (with the badger photo attached) |
| Password | `honeybadger4lyfe` — leaked in the body **by design** |
| Flag | `Flag{H0NeyB4d6er10OKinG0OD!!!}` |
| Tools | `exiftool`, `openssl` (+ any mail client / `python3` to pull the attachment) |

## My steps (how it was built)

1. **Encrypt the flag** (base64 so it's safe for a text field):
   ```
   openssl enc -aes-256-cbc -pbkdf2 -salt -k passphraseToEncrypt -a -in flagFile -out encryptedFlagOutput.enc.b64
   ```
2. **Embed the encrypted text** into a JPEG Comment field (new output image):
   ```
   exiftool '-Comment<=encryptedFlagOutput.enc.b64' -o outputImage.jpeg inputImage.jpg
   ```
3. **Verify the comment is present:**
   ```
   exiftool outputImage.jpeg | grep -i comment
   ```
4. **Wrap it in an email** whose body leaks the password. Generator: the
   `# --- settings you can change ---` script — FROM *"Secretary of Watermelon
   \<Peter@military.signal\>"*, TO *"Mr. Tema"*, SUBJECT *"Photo Message!"*, the
   password leaked as *"Definitely not the password: …"*, photo base64-attached.

## Player steps (intended solve)

1. **Standard metadata check** — the Comment is clearly an encrypted string:
   ```
   exiftool outputImage.jpeg
   ```
2. **Recover + decrypt** with the password from the body:
   ```
   exiftool -b -Comment outputImage.jpeg > encryptedFlagOutput.enc.b64
   openssl enc -aes-256-cbc -d -pbkdf2 -k honeybadger4lyfe -a -in encryptedFlagOutput.enc.b64
   ```
   → `Flag{H0NeyB4d6er10OKinG0OD!!!}`

## Notes

- The password is leaked in the body on purpose: *"Definitely not the password:
  honeybadger4lyfe."* The signature *"256 Air Expeditionary Squadron (256 AES)"* is
  the nudge toward AES-256.
- The generator line `PASSWORD='honeybadger4l'yfe` renders in the shell as
  `honeybadger4lyfe` (the apostrophe closes the quote); the shipped body and the
  working decrypt both use `honeybadger4lyfe`. Verified end-to-end.
- Common pitfalls: forgetting `-pbkdf2` (→ `bad decrypt`) or `-a` (base64 input).

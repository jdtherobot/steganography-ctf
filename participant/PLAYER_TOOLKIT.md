# Player Toolkit — Environment Checklist

Before you start, make sure your machine has the standard file-forensics toolkit.
This is a **general** kit — the same handful of tools that show up in almost every
steganography and file-carving challenge. Nothing here is tied to a specific
puzzle; think of it as your workbench, not a hint sheet.

The smoothest environment is **Kali Linux** (most of this is preinstalled), but any
Linux distro, WSL2 on Windows, or macOS with Homebrew will work fine. Back to the
handbook: [`README.md`](README.md).

---

## How to use this page

For each tool below there's a **one-line check**. Run it in your terminal:

- If you get a **version number or a path**, you're good.
- If you get **"command not found"** (or similar), install it — a suggested
  install command is included for Debian/Kali (`apt`) and macOS (`brew`).

You don't need to understand what each tool *does* yet. You just need it present
and runnable.

---

## The checklist

### 1. ExifTool — metadata reader/writer

```bash
exiftool -ver
```

Install: `sudo apt install libimage-exiftool-perl` · macOS: `brew install exiftool`

### 2. OpenSSL — encryption / decryption toolkit

```bash
openssl version
```

Install: `sudo apt install openssl` · macOS: preinstalled (or `brew install openssl`)

### 3. Binwalk — firmware/file carving & signature scan

```bash
binwalk --help >/dev/null && echo "binwalk OK"
```

Install: `sudo apt install binwalk` · macOS: `brew install binwalk`

### 4. Steghide — image/audio steganography

```bash
steghide --version
```

Install: `sudo apt install steghide` · macOS: `brew install steghide`
(If your package manager can't find it, an Ubuntu/Debian container works:
`docker run --rm -it debian:stable-slim` then `apt update && apt install -y steghide`.)

### 5. A steghide cracker — Stegseek (fast) and/or StegCracker

```bash
stegseek --version        # preferred: very fast
stegcracker --help        # alternative
```

Install (Stegseek): download the `.deb` from the Stegseek releases page and
`sudo apt install ./stegseek_*.deb`.
Install (StegCracker): `pip install stegcracker` (needs `steghide` present too).
Having **either one** is enough.

### 6. `file` — identify a file by its contents

```bash
file --version
```

Install: `sudo apt install file` · macOS: preinstalled

### 7. `dd` — byte-precise copy / carve

```bash
dd --version 2>/dev/null || echo "dd present (BSD/macOS build)"
```

Install: part of coreutils, essentially always present on Linux and macOS.

### 8. `xxd` — hex dump / hex viewer

```bash
xxd -v
```

Install: ships with `vim-common` on Debian/Kali (`sudo apt install xxd` or
`vim-common`) · macOS: preinstalled

### 9. zip / unzip — archive tools

```bash
zip -v >/dev/null && unzip -v >/dev/null && echo "zip + unzip OK"
```

Install: `sudo apt install zip unzip` · macOS: preinstalled

### 10. Python 3 — scripting & helper scripts

```bash
python3 --version
```

Install: `sudo apt install python3` · macOS: `brew install python`
(Python 3.8+ is plenty.)

### 11. A wordlist — `rockyou.txt`

Many crackers expect a password list. The classic is **rockyou**, which ships with
Kali (gzipped). Confirm you have it, and unzip a working copy:

```bash
ls -l /usr/share/wordlists/rockyou.txt.gz    # Kali: present by default
zcat /usr/share/wordlists/rockyou.txt.gz > /tmp/rockyou.txt   # make a usable copy
wc -l /tmp/rockyou.txt                        # ~14 million lines if it worked
```

Not on Kali? Grab `rockyou.txt` from the well-known SecLists collection, or use
any wordlist your facilitator provides with the event bundle.

---

## Quick "am I ready?" sweep

Paste this to check the core tools in one shot (it just reports what's missing):

```bash
for t in exiftool openssl binwalk steghide file dd xxd zip unzip python3; do
  if command -v "$t" >/dev/null 2>&1; then
    printf '  ok   %s\n' "$t"
  else
    printf '  MISSING  %s\n' "$t"
  fi
done
# a cracker (either is fine):
command -v stegseek >/dev/null || command -v stegcracker >/dev/null \
  && echo "  ok   stego cracker" || echo "  MISSING  stego cracker (stegseek or stegcracker)"
```

If every line says `ok`, your workbench is ready. Head back to the
[`README.md`](README.md) and open your first challenge briefing.

---

## A few working habits

- **Always keep the original file untouched.** Copy it into a scratch folder and
  experiment on the copy.
- **When a tool says "nothing found," try a different tool or a different
  assumption** — the file type on the label isn't always the file type inside.
- **Read error messages literally.** "bad decrypt," "incorrect passphrase," and
  "not a valid archive" each point you somewhere specific.
- **Nothing here needs the internet** (beyond installing the tools and, optionally,
  downloading a wordlist). If a step seems to require a remote server, re-read the
  briefing — you're off the intended path.

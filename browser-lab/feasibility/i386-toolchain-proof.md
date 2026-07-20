# i386 toolchain proof — the real de-risk

**Result: PASS.** In a genuine 32-bit i386 Linux container, the player toolchain installs and
**solves Challenge 2 and Challenge 4 from the sanitized participant files**, recovering both exact
flags. This proves the userland a v86/CheerpX image would contain.

Everything below is copied from a run captured this session
(`build/scratch/lab/i386_proof.log`, `DOCKER_RC=0`). Nothing is reconstructed.

## Method

- Host: macOS (Apple Silicon / arm64), Docker Desktop with qemu **linux/386** emulation.
- Container: `docker run --platform linux/386 debian:stable-slim` — a real 32-bit guest.
- Inputs mounted **read-only**: `participant/challenges/02-stegosaurus-1/stego_badger.jpeg`,
  `participant/challenges/04-stegosaurus-3/Honey.jpeg`, and the shipped
  `build/wordlists/trimmed.txt` (921 words). No `facilitator/` file and no archive file was used.

### Two gotchas found and handled (both matter for the image build)
1. **`docker build --platform linux/386` with the classic builder silently builds the host arch.**
   An image I first built this way inspected as `Architecture=amd64` with `steghide` = `ELF 64-bit`.
   The proof above therefore runs via `docker run --platform linux/386` (which genuinely emulates
   i386) — confirmed by the ELF classes below. `image/build-image.sh` uses buildx (or a
   `run`+`commit` fallback) and asserts `Architecture == 386`.
2. **A bulk `apt-get install` of the whole list *with* recommends stalls emulated dpkg.** Grouped
   installs with `--no-install-recommends` are reliable.

## Genuine 32-bit — ELF class of the actual tool binaries

```
uname -a : Linux ... 6.12.76-linuxkit ... i686 GNU/Linux
getconf LONG_BIT = 32
Debian GNU/Linux 13 (trixie)

/usr/bin/steghide: ELF 32-bit LSB pie executable, Intel i386, ... interpreter /lib/ld-linux.so.2
/usr/bin/openssl:  ELF 32-bit LSB pie executable, Intel i386, ... interpreter /lib/ld-linux.so.2
/usr/bin/python3:  ELF 32-bit LSB executable,     Intel i386, ... interpreter /lib/ld-linux.so.2
```

## Toolchain that works in 32-bit (exact versions)

Installed from the **Debian 13 (trixie) i386 apt repo**:

| Tool | Package | Version (i386) |
|---|---|---|
| steghide | `steghide` | `0.5.1-15` |
| exiftool | `libimage-exiftool-perl` | `13.25+dfsg-1` (exiftool 13.25) |
| openssl | `openssl` | `3.5.6` |
| binwalk | `binwalk` | `2.4.3+dfsg1-2` |
| python3 | `python3` | `3.13.5` |
| file | `file` | `5.46` |
| xxd | `xxd` | `2:9.1.1230-2` |
| unzip | `unzip` | `6.00` |
| zip | `zip` | `3.0` |
| dd | `coreutils` | `9.7` |

Install groups (this exact order installs cleanly under emulation):

```
apt-get install -y --no-install-recommends openssl file coreutils xxd unzip zip ca-certificates
apt-get install -y --no-install-recommends steghide
apt-get install -y --no-install-recommends libimage-exiftool-perl
apt-get install -y --no-install-recommends python3 binwalk
apt-get install -y --no-install-recommends python3-pip
```

### Cracker: stegcracker needs a one-line fix on Python 3.13 (found + fixed)

`stegcracker` 2.1.0 (the preferred pure-python wrapper) **crashes out-of-the-box** on Debian 13
because Python 3.13 removed `distutils` (PEP 632):

```
File ".../stegcracker/__main__.py", line 4, in <module>
    from distutils.spawn import find_executable
ModuleNotFoundError: No module named 'distutils'
```

Fix: install `setuptools` (it re-provides the `distutils` shim), so stegcracker imports and runs:

```
pip install --break-system-packages setuptools stegcracker
```

**Verified in i386 this session** (`build/scratch/lab/stegcracker_fix.log`):

```
[*] import distutils works now? yes
[*] stegcracker version: 2.1.0
[*] crack the C2 carrier over the trimmed wordlist:
    ... Your file has been written to: /tmp/s.jpeg.out
    password123
STEGCRACKER_RECOVERED=password123
```

So with `setuptools` installed, the preferred `stegcracker` runs in 32-bit and recovers `password123`.

The proof's C2 crack was recovered by the equivalent **steghide loop** over the trimmed wordlist
(the mechanism stegcracker wraps), so C2 crackability is proven independently of that tool bug.
The image recipe installs `setuptools` so the shipped lab has a working `stegcracker`.

## Challenge 2 — crack + extract (captured)

```
[*] cracking passphrase with the trimmed wordlist (921 words)...
[*] recovered passphrase: 'password123'
[*] payload sha256: ddebc7dbefa5e11b35c066a551d9ab08addb6d39df2bc5d46e70eb14d52c11a5
[*] payload line 1: Flag{DanG 7hat'S @ cUTe HOnEY b@D9eR}
    sha256 MATCHES canonical
    flag   MATCHES canonical
```

- Passphrase `password123` recovered from the shipped 921-word trimmed wordlist.
- Extracted payload SHA-256 equals the canonical `ddebc7db…c11a5`.
- Flag: **`Flag{DanG 7hat'S @ cUTe HOnEY b@D9eR}`**.

## Challenge 4 — full chain (captured)

```
/in/Honey.jpeg: JPEG image data, Exif standard: ... 1024x1024, components 3
-- binwalk signature scan --
0        0x0      JPEG image data, EXIF standard
235921   0x39991  OpenSSL encryption, salted, salt: 0xF93D37A2B2E9C6E5
246929   0x3C491  Zip archive data, ... name: do_not_open.txt
247166   0x3C57E  JPEG image data, JFIF standard 1.01
272897   0x42A01  OpenSSL encryption, salted, salt: 0xCEBB0C23B9EB9F1
273137   0x42AF1  OpenSSL encryption, salted, salt: 0x935A1741FA39105C

[carve] secret.enc=11008B inner_jpeg=25731B payload.enc=240B
[bundle] ['STEGO_KEY_386.txt', 'iv.bin', 'passwords.enc', 'qtbl.py']
[qtbl] extracted 32-byte AES key via pure-stdlib qtbl.py
[flag] Flag{Y0u haVe EnCouNTeR3d a w!Ld s1eEP p@RA1y$!S DEm0n}
C4 CHAIN OK
```

Chain, all in 32-bit: `binwalk` recon → structural carve → `openssl` crack of `secret.enc` with the
weak clue password **`desertstorm`** (present in the shipped wordlist) → unzip the inner bundle →
derive the keyblock from `STEGO_KEY_386.txt` via the "386" rule → **`python3 qtbl.py`** (pure stdlib)
extracts the 32-byte AES key from the inner JPEG's quantization tables → `openssl` decrypts
`passwords.enc` (raw key+IV) → the recovered password decrypts `payload.enc` → flag.

- Flag: **`Flag{Y0u haVe EnCouNTeR3d a w!Ld s1eEP p@RA1y$!S DEm0n}`**.

## Bottom line

```
I386_PROOF_RESULT: PASS  (C2 + C4 both solved in 32-bit userland)
```

The 32-bit userland the lab image must contain is proven. See `../image/` for the recipe that bakes
this exact toolchain + the sanitized files into a v86 image, and `../ENGINE_DECISION.md` for the
engine/host choice.

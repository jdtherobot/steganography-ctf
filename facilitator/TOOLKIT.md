# Toolkit (facilitator reference)

> **Facilitator-only.** Don't hand this to players — part of each challenge is working
> out *which* tools fit what they were given. Use it to help a stuck team, or to set up
> the environment.

The standard file-forensics kit. **Kali Linux** has almost all of it preinstalled;
any Linux, WSL2 on Windows, or macOS with Homebrew works too. Run each one-line
check — if you get a version or a path you're good; if it's "command not found,"
install it.

## Tools

| Tool | What it's for | Check |
|---|---|---|
| **exiftool** | read/write file metadata | `exiftool -ver` |
| **openssl** | encryption / decryption | `openssl version` |
| **steghide** | hide/extract a file inside a JPEG behind a passphrase | `steghide --version` |
| **stegcracker** *(or **stegseek**)* | crack a weak steghide passphrase with a wordlist | `stegcracker --help` |
| **a wordlist** | `rockyou.txt` — standard, on Kali under `/usr/share/wordlists/`. **Players supply their own — it is not shipped in `participant/`.** | `wc -l rockyou.txt` |
| **binwalk** | scan a file for embedded files and their offsets | `binwalk --help` |
| **dd** | byte-precise carving | `dd --version` |
| **zip / unzip** | archive tools | `unzip -v` |
| **xxd** | hex view / hex ↔ binary | `xxd -v` |
| **python3** | helper scripts (incl. the quantization-table stego helper) | `python3 --version` |
| **awk** | text processing / stitching strings together | `awk --version` |
| **file** | identify a file by its contents | `file --version` |
| **a four-square cipher tool** | an online tool such as dcode.fr, or an offline script | — |

## Which tools each challenge wants

- **Steganography lvl 1** — `exiftool`, `openssl`
- **Steganography lvl 2** — `steghide` + a cracker (`stegcracker`/`stegseek`) + a wordlist
- **Steganography lvl 3** — `binwalk`, `dd`, `openssl`, `unzip`, `xxd`, `python3`, `awk`, `file`
- **Computer Architecture Warehouse** — pen, paper, and a four-square cipher tool

## Quick "am I ready?" sweep

```bash
for t in exiftool openssl steghide binwalk dd unzip xxd python3 awk file; do
  command -v "$t" >/dev/null 2>&1 && printf '  ok   %s\n' "$t" || printf '  MISSING  %s\n' "$t"
done
command -v stegcracker >/dev/null 2>&1 || command -v stegseek >/dev/null 2>&1 \
  && echo "  ok   stego cracker" || echo "  MISSING  stego cracker (stegcracker or stegseek)"
```

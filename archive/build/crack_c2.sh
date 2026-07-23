#!/usr/bin/env bash
# Milestone 0: recover the Challenge 2 steghide passphrase and confirm the
# intended crack path works. Uses a throwaway Debian container with steghide +
# stegseek (fast cracker). Archive is mounted READ-ONLY.
#
# Output: prints the recovered passphrase and the first lines of the extracted
# document, and writes the extracted file + passphrase to build/out/.
set -euo pipefail
source "$(dirname "$0")/config.sh"

STEGO="$ARCHIVE_DIR/main/Challenge 2/stego_badger.jpeg"
WORDLIST="$ARCHIVE_DIR/Kali Virtual Box Files/documents/rockyou.txt"

[ -f "$STEGO" ] || { echo "missing: $STEGO" >&2; exit 1; }
[ -f "$WORDLIST" ] || { echo "missing wordlist: $WORDLIST" >&2; exit 1; }

docker run --rm --platform linux/amd64 \
  -v "$ARCHIVE_DIR":/archive:ro \
  -v "$OUT_DIR":/out \
  debian:stable-slim bash -euc '
    export DEBIAN_FRONTEND=noninteractive
    apt-get update -qq >/dev/null
    apt-get install -y -qq steghide wget ca-certificates >/dev/null
    wget -q https://github.com/RickdeJager/stegseek/releases/download/v0.6/stegseek_0.6-1.deb -O /tmp/ss.deb
    apt-get install -y -qq /tmp/ss.deb >/dev/null 2>&1 || dpkg -i /tmp/ss.deb >/dev/null 2>&1
    echo "=== stegseek crack ==="
    stegseek --crack "/archive/main/Challenge 2/stego_badger.jpeg" /archive/"Kali Virtual Box Files"/documents/rockyou.txt /out/c2_extracted.txt 2>&1 | tee /out/c2_stegseek.log
    echo "=== first lines of extracted document ==="
    head -3 /out/c2_extracted.txt
  '

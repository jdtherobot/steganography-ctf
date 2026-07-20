#!/usr/bin/env bash
# Challenge 2 (Stegosaurus 1) — automated solver test.
#
# Solves ONLY from the participant distribution:
#     participant/challenges/02-stegosaurus-1/stego_badger.jpeg
#     build/wordlists/trimmed.txt              (the shipped trimmed wordlist)
# It never reads facilitator/ or the archive, so a green result proves a player
# can solve with what they are handed.
#
# steghide + stegseek are not native on macOS/arm64, so both checks run inside a
# throwaway linux/amd64 debian:stable-slim container (first run pulls the image and
# installs the tools — allow a few minutes).
#
# Two assertions:
#   (a) DETERMINISTIC — `steghide extract -p password123` yields a file whose
#       SHA-256 equals the canonical payload hash AND whose line 1 is the flag.
#   (b) CRACKABILITY  — `stegseek --crack` against the trimmed wordlist recovers
#       the passphrase `password123`.
# All extractions are written to build/scratch/c2/ (gitignored) — never into participant/.
#
# Prints "C2 PASS" and exits 0 on success; prints "C2 FAIL ..." and exits 1 otherwise.
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$HERE/../../.." && pwd)"

STEGO="$REPO_ROOT/participant/challenges/02-stegosaurus-1/stego_badger.jpeg"
WORDLIST="$REPO_ROOT/build/wordlists/trimmed.txt"
SCRATCH="$REPO_ROOT/build/scratch/c2"

# Canonical payload fingerprint + flag (hashes/ciphertext-free facts, not secrets).
EXPECTED_SHA="ddebc7dbefa5e11b35c066a551d9ab08addb6d39df2bc5d46e70eb14d52c11a5"
EXPECTED_FLAG="Flag{DanG 7hat'S @ cUTe HOnEY b@D9eR}"
EXPECTED_PW="password123"

fail() { echo "C2 FAIL — $1" >&2; exit 1; }

[ -f "$STEGO" ]    || fail "missing participant carrier: ${STEGO#$REPO_ROOT/}"
[ -f "$WORDLIST" ] || fail "missing trimmed wordlist: ${WORDLIST#$REPO_ROOT/}"
command -v docker >/dev/null 2>&1 || fail "docker not available (needed for steghide/stegseek)"

mkdir -p "$SCRATCH"

echo "== C2 solve_test =="
echo "   carrier:  ${STEGO#$REPO_ROOT/}"
echo "   wordlist: ${WORDLIST#$REPO_ROOT/} ($(wc -l < "$WORDLIST" | tr -d ' ') entries)"

# Mount the two inputs read-only and the scratch dir read-write. The container
# gets steghide (apt) + stegseek (pinned .deb release), then runs both checks.
docker run --rm --platform linux/amd64 \
  -e EXPECTED_SHA="$EXPECTED_SHA" \
  -e EXPECTED_FLAG="$EXPECTED_FLAG" \
  -e EXPECTED_PW="$EXPECTED_PW" \
  -v "$STEGO":/in/stego_badger.jpeg:ro \
  -v "$WORDLIST":/wl/trimmed.txt:ro \
  -v "$SCRATCH":/out \
  debian:stable-slim bash -euc '
    export DEBIAN_FRONTEND=noninteractive
    echo "[*] installing steghide + stegseek ..."
    apt-get update -qq >/dev/null
    apt-get install -y -qq steghide wget ca-certificates >/dev/null
    wget -q https://github.com/RickdeJager/stegseek/releases/download/v0.6/stegseek_0.6-1.deb -O /tmp/ss.deb
    apt-get install -y -qq /tmp/ss.deb >/dev/null 2>&1 || dpkg -i /tmp/ss.deb >/dev/null 2>&1
    command -v steghide >/dev/null || { echo "C2 FAIL — steghide install failed" >&2; exit 1; }
    command -v stegseek >/dev/null || { echo "C2 FAIL — stegseek install failed" >&2; exit 1; }

    rm -f /out/c2_deterministic.txt /out/c2_cracked.txt

    # --- (a) DETERMINISTIC: known passphrase -> exact payload -----------------
    echo "[*] (a) steghide extract with known passphrase ..."
    steghide extract -sf /in/stego_badger.jpeg -p "$EXPECTED_PW" -xf /out/c2_deterministic.txt -f >/dev/null 2>&1 \
      || { echo "C2 FAIL — steghide extract failed" >&2; exit 1; }

    got_sha="$(sha256sum /out/c2_deterministic.txt | cut -d" " -f1)"
    if [ "$got_sha" != "$EXPECTED_SHA" ]; then
      echo "C2 FAIL — payload SHA-256 mismatch" >&2
      echo "  expected: $EXPECTED_SHA" >&2
      echo "  got:      $got_sha" >&2
      exit 1
    fi
    echo "    payload sha256 OK ($got_sha)"

    line1="$(head -n1 /out/c2_deterministic.txt)"
    if [ "$line1" != "$EXPECTED_FLAG" ]; then
      echo "C2 FAIL — line 1 is not the expected flag" >&2
      echo "  expected: $EXPECTED_FLAG" >&2
      echo "  got:      $line1" >&2
      exit 1
    fi
    echo "    flag (line 1) OK: $line1"

    # --- (b) CRACKABILITY: stegseek recovers the passphrase from trimmed.txt --
    echo "[*] (b) stegseek --crack against the trimmed wordlist ..."
    ss_out="$(stegseek --crack /in/stego_badger.jpeg /wl/trimmed.txt /out/c2_cracked.txt -f 2>&1)" \
      || { echo "$ss_out"; echo "C2 FAIL — stegseek did not crack the carrier" >&2; exit 1; }

    if ! printf "%s\n" "$ss_out" | grep -qF "$EXPECTED_PW"; then
      printf "%s\n" "$ss_out" >&2
      echo "C2 FAIL — stegseek output did not report passphrase \"$EXPECTED_PW\"" >&2
      exit 1
    fi
    echo "    stegseek recovered passphrase: $EXPECTED_PW"

    # cross-check: the cracked payload equals the deterministic payload
    crack_sha="$(sha256sum /out/c2_cracked.txt | cut -d" " -f1)"
    if [ "$crack_sha" != "$EXPECTED_SHA" ]; then
      echo "C2 FAIL — cracked payload SHA-256 mismatch ($crack_sha)" >&2
      exit 1
    fi
    echo "    cracked payload sha256 OK"
  '

echo "C2 PASS"

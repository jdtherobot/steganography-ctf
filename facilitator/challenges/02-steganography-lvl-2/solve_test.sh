#!/usr/bin/env bash
# Black-box solve of Steganography lvl 2 from the participant image only.
# Asserts the flag (line 1) and the cross-challenge tie (line 9 = the Warehouse ciphertext).
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/../../.." && pwd)"
JPEG="$ROOT/participant/challenges/02-steganography-lvl-2/stego_badger.jpeg"
EXPECT="Flag{DanG 7hat'S @ cUTe HOnEY b@D9eR}"
CIPHER="UPNAHLNSIBESOLTUEBUPDNEY"
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT

# Intended path is a wordlist crack to passphrase "password123"; extraction is deterministic once known.
steghide extract -sf "$JPEG" -p password123 -xf "$TMP/doc.txt" -f >/dev/null 2>&1

L1="$(sed -n '1p' "$TMP/doc.txt")"
L9="$(sed -n '9p' "$TMP/doc.txt")"
[ "$L1" = "$EXPECT" ] || { echo "C2 FAIL  flag line [$L1]"; exit 1; }
[ "$L9" = "$CIPHER" ] || { echo "C2 FAIL  line 9 [$L9]"; exit 1; }
echo "C2 PASS  ($L1 ; line 9 = $L9)"

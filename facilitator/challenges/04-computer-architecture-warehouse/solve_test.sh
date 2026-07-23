#!/usr/bin/env bash
# Solve of the Computer Architecture Warehouse: page-table walk + four-square decode.
# Uses line 9 of the lvl-2 document as the ciphertext (recover it via lvl 2 first), else falls back
# to the known ciphertext so this test is self-contained.
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/../../.." && pwd)"
JPEG="$ROOT/participant/challenges/02-steganography-lvl-2/stego_badger.jpeg"
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT

CIPHER="UPNAHLNSIBESOLTUEBUPDNEY"
if command -v steghide >/dev/null 2>&1 && [ -f "$JPEG" ]; then
  if steghide extract -sf "$JPEG" -p password123 -xf "$TMP/doc.txt" -f >/dev/null 2>&1; then
    CIPHER="$(sed -n '9p' "$TMP/doc.txt")"
  fi
fi

CIPHER="$CIPHER" python3 - <<'PY'
import os
va = 0x0000_0100_4040_1005
walk = ((va>>39)&0x1ff, (va>>30)&0x1ff, (va>>21)&0x1ff, (va>>12)&0x1ff, va & 0xfff)
assert walk == (2,1,2,1,5), f"walk {walk}"

ALPHA = "ABCDEFGHIKLMNOPQRSTUVWXYZ"  # I/J merged
def sq(k):
    k = k.upper().replace("J","I"); s=[]
    for c in k+ALPHA:
        if c in ALPHA and c not in s: s.append(c)
    return [s[i*5:(i+1)*5] for i in range(5)]
def pos(s): return {s[r][c]:(r,c) for r in range(5) for c in range(5)}
TL,TR,BL,BR = sq("HONEY"),sq("BADGER"),sq("HECK"),sq("YEAH")
pTR,pBL = pos(TR),pos(BL)
ct = os.environ["CIPHER"].upper().replace("J","I")
pt = ""
for i in range(0,len(ct),2):
    r1,c1 = pTR[ct[i]]; r2,c2 = pBL[ct[i+1]]
    pt += TL[r1][c2] + BR[r2][c1]
flag = "Flag{%s}" % pt.rstrip("Z")
assert flag == "Flag{TOMHANKSAINTGOTSHITONME}", flag
print(f"C4 PASS  (walk={walk} ; {flag})")
PY

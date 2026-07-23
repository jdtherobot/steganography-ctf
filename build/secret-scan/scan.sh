#!/usr/bin/env bash
# Gate: fail if any final answer / creator-only secret (or creator-only filename) appears under a
# target dir (default: participant/). Intended in-story leaks are allowlisted via denylist comments.
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET="${1:-$HERE/../../participant}"
DENY="$HERE/denylist.txt"
rc=0

while IFS= read -r s; do
  case "$s" in ""|\#*) continue;; esac
  if grep -rIiF -- "$s" "$TARGET" >/dev/null 2>&1; then
    echo "LEAK: '$s' found under $TARGET"; rc=1
  fi
done < "$DENY"

for f in keyblock.txt qtbl_stego.py passwords.txt passwords.enc aeskey.bin pw.txt flag.txt "Flag.txt" "Flag 2.txt"; do
  if find "$TARGET" -name "$f" 2>/dev/null | grep -q .; then
    echo "LEAK FILE: $f under $TARGET"; rc=1
  fi
done

if [ $rc -eq 0 ]; then echo "secret-scan: PASS"; else echo "secret-scan: FAIL"; fi
exit $rc

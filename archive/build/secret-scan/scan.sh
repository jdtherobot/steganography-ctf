#!/usr/bin/env bash
# Pre-publish secret-scan gate.
#
# Fails (exit 1) if any final answer, creator-only password, or creator-only file
# leaks into the participant/ bundle (or any directory passed as $1).
# See build/DIRECTORY_CONTRACT.md for the boundary rules this enforces.
set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$HERE/../.." && pwd)"

SCAN_DIR="${1:-$REPO_ROOT/participant}"
DENY_STRINGS="$HERE/denylist.txt"
DENY_NAMES="$HERE/denied_filenames.txt"
ALLOW="$HERE/allowlist.txt"

if [ ! -d "$SCAN_DIR" ]; then
  echo "secret-scan: nothing to scan (missing $SCAN_DIR)"; exit 0
fi

fail=0
echo "== secret-scan =="
echo "   target: $SCAN_DIR"

# --- 1) Denied filenames ------------------------------------------------------
while IFS= read -r name; do
  [[ -z "$name" || "$name" == \#* ]] && continue
  while IFS= read -r hit; do
    [ -n "$hit" ] || continue
    echo "  LEAK (filename '$name'): ${hit#$REPO_ROOT/}"
    fail=1
  done < <(find "$SCAN_DIR" -type f -name "$name" 2>/dev/null)
done < "$DENY_NAMES"

# --- 2) Allowlisted files (exempt from the content scan) ----------------------
# bash 3.2-safe (no associative arrays / globstar): expand each allow glob with
# find (translating ** -> *) into a newline list of absolute paths.
ALLOWED_LIST="$(mktemp)"; trap 'rm -f "$ALLOWED_LIST" "$CLEAN"' EXIT
CLEAN="$(mktemp)"
while IFS= read -r g; do
  [ -z "$g" ] && continue
  case "$g" in \#*) continue;; esac
  fp="${g//\*\*/\*}"                      # ** -> * for find -path
  find "$SCAN_DIR" -type f -path "$REPO_ROOT/$fp" 2>/dev/null >> "$ALLOWED_LIST"
done < "$ALLOW"

# --- 3) Denied strings in text content ----------------------------------------
grep -vE '^[[:space:]]*(#|$)' "$DENY_STRINGS" > "$CLEAN"

# grep: -r recursive, -I skip binary, -n line no, -H filename, -F fixed strings, -f patterns file
while IFS= read -r line; do
  [ -n "$line" ] || continue
  file="${line%%:*}"
  if grep -qxF "$file" "$ALLOWED_LIST" 2>/dev/null; then continue; fi
  echo "  LEAK (string): ${line#$REPO_ROOT/}"
  fail=1
done < <(grep -rInHF -f "$CLEAN" "$SCAN_DIR" 2>/dev/null)

echo "----------------------------------------"
if [ "$fail" -eq 0 ]; then
  echo "secret-scan: PASS — no secrets found in $(basename "$SCAN_DIR")/"
else
  echo "secret-scan: FAIL — see LEAK lines above"
fi
exit "$fail"

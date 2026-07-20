#!/usr/bin/env bash
# Assemble the PUBLIC GitHub Pages bundle (guide + challenges + warehouse game) for britt.gg/ctf/.
#
# Publishes ONLY participant/ content, and refuses to build unless the secret-scan gate passes.
# Output: deploy/pages/dist/  — pure static (.nojekyll), host-agnostic (GH Pages, Cloudflare, etc.).
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$HERE/../.." && pwd)"
PART="$REPO_ROOT/participant"
DIST="$HERE/dist"

echo "== deploy/pages build =="

# 1) HARD GATE: never publish if a secret could leak into the bundle.
echo "-- secret-scan gate --"
if ! bash "$REPO_ROOT/build/secret-scan/scan.sh" "$PART" >/dev/null; then
  echo "ABORT: secret-scan failed on participant/ — refusing to build the public bundle." >&2
  bash "$REPO_ROOT/build/secret-scan/scan.sh" "$PART" || true
  exit 1
fi
echo "   secret-scan: PASS"

# 2) Stage the bundle from participant/ + the landing page.
rm -rf "$DIST"; mkdir -p "$DIST"
cp "$HERE/index.html" "$DIST/index.html"
touch "$DIST/.nojekyll"                       # pure static; do not let Jekyll reprocess
# copy participant content (guide md + challenge files + game)
cp -R "$PART/." "$DIST/"
# drop any stray placeholder
find "$DIST" -name '.gitkeep' -delete 2>/dev/null || true

# 3) Render every Markdown file to a sibling .html (best tool available; always produces output).
python3 "$HERE/mdstatic.py" "$DIST"

# 4) Belt-and-suspenders: scan the assembled bundle too.
echo "-- secret-scan on assembled dist/ --"
bash "$REPO_ROOT/build/secret-scan/scan.sh" "$DIST" >/dev/null && echo "   dist secret-scan: PASS"

BYTES=$(find "$DIST" -type f -exec cat {} + | wc -c | tr -d ' ')
echo "== built $DIST ($(find "$DIST" -type f | wc -l | tr -d ' ') files, ~$((BYTES/1024)) KB) =="
echo "Publish: copy the CONTENTS of dist/ to your Pages repo under /ctf/ (see deploy/pages/README.md)."

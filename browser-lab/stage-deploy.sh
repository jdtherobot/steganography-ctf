#!/usr/bin/env bash
# Assemble the PUBLISHABLE subset of browser-lab/ into a staging dir, then secret-scan it.
#
# Publishable  = what the player's browser loads: the landing, the harness, the boot blobs,
#                the built lab image (image/dist), and _headers.
# NOT published = facilitator/build docs that legitimately contain flags or build detail:
#                 feasibility/ (the proof transcript has both flags), *.md docs, and the
#                 image recipe (Dockerfile/build scripts/tools). Keep these in the repo only.
#
# Usage: bash stage-deploy.sh [dest]   (default: build/scratch/lab/deploy)
set -euo pipefail
cd "$(dirname "$0")"
HERE="$(pwd)"; REPO_ROOT="$(cd .. && pwd)"     # browser-lab/ -> repo root
DEST="${1:-$REPO_ROOT/build/scratch/lab/deploy}"

rm -rf "$DEST"; mkdir -p "$DEST"
cp index.html terminal.html "$DEST"/
[ -f _headers ] && cp _headers "$DEST"/                       # harmless on GH Pages, needed on Cloudflare
if [ -d vendor ]; then mkdir -p "$DEST/vendor"; cp vendor/*.bin "$DEST/vendor/" 2>/dev/null || true; fi
if [ -d image/dist ]; then                                    # the built lab image, if present
  mkdir -p "$DEST/image/dist"
  cp image/dist/fs.json "$DEST/image/dist/" 2>/dev/null || true
  [ -d image/dist/flat ] && cp -r image/dist/flat "$DEST/image/dist/flat"
fi

echo "staged publishable bundle -> $DEST"
find "$DEST" -maxdepth 2 -type f | sed "s#$DEST/##" | sort | sed 's/^/  /'

echo
echo "== secret-scan the bundle =="
bash "$REPO_ROOT/build/secret-scan/scan.sh" "$DEST"

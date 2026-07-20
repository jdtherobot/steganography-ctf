#!/usr/bin/env bash
# ============================================================================
#  Build the Badger Lab v86 image: sanitized files -> 32-bit Debian image ->
#  9p filesystem (fs.json + flat/) that terminal.html boots as ACTIVE="lab".
# ============================================================================
# Verified this session:  payload assembly, secret-scan, the i386 toolchain
#   (see ../feasibility/i386-toolchain-proof.md), and the docker-export -> fs2json
#   -> copy-to-sha256 packaging pipeline (sizes printed at the end).
# Integration step to verify on deploy:  the Debian 9p-root boot in-browser
#   (kernel + initramfs are baked by the Dockerfile; the base-image terminal is
#   already verified live). See README.md "What's verified vs pending".
# ----------------------------------------------------------------------------
set -euo pipefail
cd "$(dirname "$0")"
HERE="$(pwd)"
REPO_ROOT="$(cd ../.. && pwd)"
DIST="$HERE/dist"
TAG="badger-lab:i386"
PLATFORM="linux/386"

# Bypass the slow macOS docker credential helper for anonymous Hub pulls.
if [ -z "${DOCKER_CONFIG:-}" ] && docker info 2>/dev/null | grep -qi 'desktop'; then
  TMPCFG="$(mktemp -d)"; printf '{}' > "$TMPCFG/config.json"; export DOCKER_CONFIG="$TMPCFG"
fi

echo "== 1) assemble sanitized payload (player files only) =="
PAY="$HERE/payload"; rm -rf "$PAY"; mkdir -p "$PAY"
cp "$REPO_ROOT/participant/challenges/01-photo-day/email.eml"                 "$PAY/email.eml"
cp "$REPO_ROOT/participant/challenges/02-stegosaurus-1/stego_badger.jpeg"     "$PAY/stego_badger.jpeg"
cp "$REPO_ROOT/participant/challenges/04-stegosaurus-3/Honey.jpeg"            "$PAY/Honey.jpeg"
cp "$REPO_ROOT/participant/challenges/01-photo-day/BRIEF.md"                  "$PAY/BRIEF-01-photo-day.md"
cp "$REPO_ROOT/participant/challenges/02-stegosaurus-1/BRIEF.md"              "$PAY/BRIEF-02-stegosaurus-1.md"
cp "$REPO_ROOT/participant/challenges/03-stegosaurus-2-warehouse/BRIEF.md"    "$PAY/BRIEF-03-warehouse.md"
cp "$REPO_ROOT/participant/challenges/04-stegosaurus-3/BRIEF.md"             "$PAY/BRIEF-04-stegosaurus-3.md"
cp "$REPO_ROOT/build/wordlists/trimmed.txt"                                  "$PAY/wordlist.txt"
ls -la "$PAY"

echo "== 2) secret-scan the payload (must PASS before it goes in an image) =="
bash "$REPO_ROOT/build/secret-scan/scan.sh" "$PAY"

echo "== 3) build the 32-bit image =="
# IMPORTANT: the classic docker builder SILENTLY IGNORES --platform and builds the
# host arch. Only buildx/BuildKit builds a real i386 image from a Dockerfile.
if docker buildx version >/dev/null 2>&1; then
  echo "   using buildx (--platform $PLATFORM --load)"
  docker buildx build --platform "$PLATFORM" --load -t "$TAG" "$HERE"
else
  echo "   buildx not found -> reliable fallback: provision a real i386 container, then commit"
  bash "$HERE/build-image-fallback.sh" "$TAG" "$PLATFORM" "$PAY"
fi

echo "== 3b) verify the built image is genuinely 32-bit =="
ARCH="$(docker image inspect "$TAG" --format '{{.Architecture}}')"
echo "   image Architecture=$ARCH"
[ "$ARCH" = "386" ] || { echo "!! image is $ARCH, not 386 — install buildx or use the fallback"; exit 1; }

echo "== 4) export rootfs =="
mkdir -p "$DIST"
CN=badger-lab-export
docker rm -f "$CN" >/dev/null 2>&1 || true
docker create --platform "$PLATFORM" --name "$CN" "$TAG" >/dev/null
docker export "$CN" -o "$DIST/rootfs.tar"
docker rm "$CN" >/dev/null
tar -f "$DIST/rootfs.tar" --delete ".dockerenv" 2>/dev/null || true

echo "== 5) package to a v86 9p filesystem (fs.json + flat/) =="
python3 "$HERE/tools/fs2json.py" --out "$DIST/fs.json" "$DIST/rootfs.tar"
rm -rf "$DIST/flat"; mkdir -p "$DIST/flat"
python3 "$HERE/tools/copy-to-sha256.py" "$DIST/rootfs.tar" "$DIST/flat"

echo "== 6) vendor the base-OS kernel (same-origin; i.copy.sh hotlink-blocks browsers) =="
mkdir -p "$REPO_ROOT/browser-lab/vendor"
if [ ! -f "$REPO_ROOT/browser-lab/vendor/buildroot-bzimage68.bin" ]; then
  curl -fsSL -o "$REPO_ROOT/browser-lab/vendor/buildroot-bzimage68.bin" https://i.copy.sh/buildroot-bzimage68.bin || \
    echo "   (could not fetch buildroot kernel now; fetch it into vendor/ at deploy time)"
fi

echo "== DONE — sizes =="
du -sh "$DIST/rootfs.tar" "$DIST/fs.json" "$DIST/flat" 2>/dev/null
echo
echo "Next: set ACTIVE=\"lab\" in ../terminal.html, serve browser-lab/ so ./image/dist is reachable,"
echo "and open terminal.html. (Base-image terminal already verified; this is the lab-image swap-in.)"

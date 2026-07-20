#!/usr/bin/env bash
# Shared build configuration for the stego-ctf reconstruction.
#
# ARCHIVE_DIR points at the immutable evidence archive. It lives OUTSIDE this
# repo and is never modified. Override by exporting ARCHIVE_DIR before running
# any build script if you relocate either directory.
set -euo pipefail

# Directory of this repo (build/ -> repo root)
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export REPO_ROOT

# Default archive location (sibling checkout of the original "CTF Challenges" folder).
: "${ARCHIVE_DIR:=/Users/jdtherobot/Documents/GitHub/CTF Challenges/archive}"
export ARCHIVE_DIR

export BUILD_DIR="$REPO_ROOT/build"
export SCRATCH_DIR="$BUILD_DIR/scratch"
export OUT_DIR="$BUILD_DIR/out"
export INVENTORY_DIR="$BUILD_DIR/inventory"

mkdir -p "$SCRATCH_DIR" "$OUT_DIR" "$INVENTORY_DIR"

if [ ! -d "$ARCHIVE_DIR" ]; then
  echo "ERROR: ARCHIVE_DIR not found: $ARCHIVE_DIR" >&2
  echo "Set ARCHIVE_DIR to the path of the immutable archive/ folder." >&2
  exit 1
fi

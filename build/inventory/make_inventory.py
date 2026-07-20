#!/usr/bin/env python3
"""Generate a reproducible SHA-256 inventory of the immutable archive.

Outputs (into build/inventory/):
  - archive_inventory.json   full records: path, size, mtime, sha256, type
  - archive_inventory.tsv    same, tab-separated, sorted by path
  - archive_duplicates.md    byte-identical file groups (hash -> paths)
  - archive_inventory.sha256 single hash-of-hashes fingerprint for verify-archive

Usage:
  ARCHIVE_DIR=/path/to/archive python3 make_inventory.py [output_dir]

The archive is only ever READ. This script never writes into ARCHIVE_DIR.
"""
from __future__ import annotations

import hashlib
import json
import os
import subprocess
import sys
from collections import defaultdict
from pathlib import Path


def sha256_file(path: Path, chunk: int = 1 << 20) -> str:
    h = hashlib.sha256()
    with path.open("rb") as f:
        for block in iter(lambda: f.read(chunk), b""):
            h.update(block)
    return h.hexdigest()


def file_type(path: Path) -> str:
    try:
        out = subprocess.run(
            ["file", "-b", str(path)],
            capture_output=True, text=True, timeout=30,
        )
        return out.stdout.strip()
    except Exception:
        return "unknown"


def main() -> int:
    archive_dir = os.environ.get("ARCHIVE_DIR")
    if not archive_dir:
        print("ERROR: set ARCHIVE_DIR", file=sys.stderr)
        return 2
    archive = Path(archive_dir).resolve()
    if not archive.is_dir():
        print(f"ERROR: not a directory: {archive}", file=sys.stderr)
        return 2

    out_dir = Path(sys.argv[1]) if len(sys.argv) > 1 else Path(__file__).resolve().parent
    out_dir.mkdir(parents=True, exist_ok=True)

    records = []
    for root, _dirs, files in os.walk(archive):
        for name in files:
            p = Path(root) / name
            if not p.is_file() or p.is_symlink():
                continue
            rel = p.relative_to(archive).as_posix()
            st = p.stat()
            records.append({
                "path": rel,
                "size": st.st_size,
                "mtime": int(st.st_mtime),
                "sha256": sha256_file(p),
                "type": file_type(p),
            })

    records.sort(key=lambda r: r["path"])

    # duplicate groups (byte-identical => same sha256)
    by_hash: dict[str, list[str]] = defaultdict(list)
    for r in records:
        by_hash[r["sha256"]].append(r["path"])
    dup_groups = {h: paths for h, paths in by_hash.items() if len(paths) > 1}

    total_bytes = sum(r["size"] for r in records)
    summary = {
        "archive_dir": str(archive),
        "file_count": len(records),
        "unique_sha256": len(by_hash),
        "duplicate_groups": len(dup_groups),
        "total_bytes": total_bytes,
    }

    # JSON
    (out_dir / "archive_inventory.json").write_text(
        json.dumps({"summary": summary, "files": records}, indent=2) + "\n"
    )

    # TSV
    lines = ["sha256\tsize\tmtime\tpath\ttype"]
    for r in records:
        lines.append(f'{r["sha256"]}\t{r["size"]}\t{r["mtime"]}\t{r["path"]}\t{r["type"]}')
    (out_dir / "archive_inventory.tsv").write_text("\n".join(lines) + "\n")

    # Duplicates markdown
    dl = ["# Archive Duplicate Groups (byte-identical)", ""]
    dl.append(f"- Files: **{summary['file_count']}**")
    dl.append(f"- Unique SHA-256: **{summary['unique_sha256']}**")
    dl.append(f"- Duplicate groups (hash shared by >1 path): **{summary['duplicate_groups']}**")
    dl.append("")
    for h, paths in sorted(dup_groups.items(), key=lambda kv: -len(kv[1])):
        dl.append(f"### `{h[:16]}…` ({len(paths)} copies)")
        for p in sorted(paths):
            dl.append(f"- `{p}`")
        dl.append("")
    (out_dir / "archive_duplicates.md").write_text("\n".join(dl) + "\n")

    # Fingerprint: hash of the sorted (sha256, size, path) tuples.
    fp = hashlib.sha256()
    for r in records:
        fp.update(f'{r["sha256"]}:{r["size"]}:{r["path"]}\n'.encode())
    fingerprint = fp.hexdigest()
    (out_dir / "archive_inventory.sha256").write_text(fingerprint + "\n")

    print(json.dumps(summary, indent=2))
    print(f"fingerprint: {fingerprint}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

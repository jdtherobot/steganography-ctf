# Stego CTF — Authoring Repository

A four-challenge steganography / cryptography / computer-architecture capture-the-flag
exercise. All materials are author-created and author-owned; see
[`facilitator/ACADEMIC_USE.md`](facilitator/ACADEMIC_USE.md).

> **This repository is PRIVATE.** It contains flags, passwords, walkthroughs, and build
> scripts. Only the sanitized [`participant/`](participant/) folder is ever distributed to
> players or published publicly, and only after the secret-scan gate passes
> (`make scan-secrets`). Never publish the repository root, `facilitator/`, or `build/`.

## The two-folder split

| Folder | Audience | Contents | Ever published? |
|---|---|---|---|
| [`participant/`](participant/) | Players | Challenge distributables (the actual files players download), spoiler-free briefings, the player toolkit, the playable warehouse game. | **Yes** — this folder *is* the public/distributable bundle. |
| [`facilitator/`](facilitator/) | Admins / facilitators | Flags, full walkthroughs, hint ladders, deterministic rebuild scripts, solver tests, provenance, validation. | **No.** |

Everything else is private infrastructure:

- `build/` — shared tooling: archive inventory, rebuild harness, the secret-scan gate, the
  directory contract, and the execution plan. Reads the immutable archive via `ARCHIVE_DIR`.
- `browser-lab/` — in-browser Kali-style lab (CheerpX / v86). Ships only sanitized player files.
- `deploy/` — deployment configs: `pages/` (guide + game → GitHub Pages) and `lab/` (header-capable host).

## The four challenges

| # | Title | Techniques |
|---|---|---|
| 1 | Photo Day lvl 2 | EXIF comment + OpenSSL AES (password leaked in email body) |
| 2 | Stegosaurus 1 | steghide with a crackable passphrase (`rockyou`) |
| 3 | Stegosaurus 2 — Warehouse | x86-64 page-table walk → four-square cipher |
| 4 | Stegosaurus 3 | multi-payload carve + JPEG quantization-table stego + AES |

Challenge 3 depends on Challenge 2 (its ciphertext is line 9 of the Challenge 2 payload);
Challenge 4 is self-contained but thematically ties back to Challenge 2.

## Source of truth: the archive

The original working materials live in an **immutable archive** OUTSIDE this repo, referenced
via `ARCHIVE_DIR` (default set in [`build/config.sh`](build/config.sh)). The archive is never
modified, and is `.gitignore`d. Every canonical file selected into `participant/` is traced
back to its archive path + SHA-256 in
[`facilitator/ARCHIVE_PROVENANCE.md`](facilitator/ARCHIVE_PROVENANCE.md). A start/end archive
fingerprint (`make verify-archive`) guarantees the archive was not touched.

## Build & validate

```bash
export ARCHIVE_DIR="/Users/jdtherobot/Documents/GitHub/CTF Challenges/archive"
make inventory          # regenerate the archive SHA-256 inventory + fingerprint
make build-challenges   # rebuild all four challenge distributions from the archive
make test-challenges    # run every automated solver test (asserts each flag)
make warehouse-game     # build the static warehouse game
make scan-secrets       # PRE-PUBLISH GATE: prove no secret leaks into participant/
make verify-archive     # confirm the archive fingerprint is unchanged
```

See [`build/EXECUTION_PLAN.md`](build/EXECUTION_PLAN.md) for the full plan and
[`build/DIRECTORY_CONTRACT.md`](build/DIRECTORY_CONTRACT.md) for the exact directory conventions.

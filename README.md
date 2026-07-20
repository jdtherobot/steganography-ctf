# Steganography CTF

A four-challenge capture-the-flag exercise covering steganography, cryptography, file carving,
metadata forensics, and x86-64 virtual memory. Every challenge, image, payload, and puzzle here is
author-created and author-owned. Built to be run as a real exercise — and validated end-to-end:
all four challenges have automated solver tests that solve them from the player files alone.

> ### ⚠️ Spoilers
> This repository contains **both** the challenge material and the answers.
> - **Playing?** Stay in [`participant/`](participant/). Nothing there spoils anything.
> - **Running the event?** [`facilitator/`](facilitator/) has every flag, password, and full walkthrough.
>
> Don't browse `facilitator/` if you intend to solve these yourself.

## The two folders

| Folder | Who it's for | What's in it |
|---|---|---|
| **[`participant/`](participant/)** | Players | The four challenge files + spoiler-free briefings, a tool checklist, and the playable warehouse game. **This is the folder you hand to participants** — download or copy it as-is. |
| **[`facilitator/`](facilitator/)** | Whoever runs it | Flags, complete walkthroughs, staged hint ladders, admin/room setup, deterministic rebuild scripts, automated solver tests, archive provenance, and the validation report. |

The workflow it was designed around: **the facilitator gives the participant the contents of
`participant/`**, then uses `facilitator/` to run the session — releasing hints in stages,
troubleshooting dead ends, and checking answers.

## The challenges

| # | Title | What you'll do | Depends on |
|---|---|---|---|
| 1 | Photo Day lvl 2 | Pull an encrypted blob out of a JPEG's EXIF comment; the password was leaked in the email body. | — |
| 2 | Stegosaurus 1 | Crack a steghide passphrase with a wordlist and extract the hidden document. | — |
| 3 | Stegosaurus 2 — Warehouse | Walk a virtual address through x86-64 page tables to a physical shelf, then break a four-square cipher. | Challenge 2 |
| 4 | Stegosaurus 3 | Carve a multi-payload JPEG, crack a bundle, recover an AES key hidden in quantization tables, and peel back three layers of encryption. | — |

Challenge 3's cipher input is line 9 of the document you recover in Challenge 2, so **solve 2 before 3**.

## Quick start

**Playing:** download [`participant/`](participant/), open `participant/README.md`, and check your
tools with `participant/PLAYER_TOOLKIT.md`. You'll want `exiftool`, `openssl`, `binwalk`, `steghide`,
`python3`, and the usual `file`/`dd`/`xxd`/`unzip`.

**Running the site locally** (the guide + warehouse game, exactly as it would be published):

```bash
bash deploy/pages/build.sh                       # builds deploy/pages/dist/
cd deploy/pages/dist && python3 -m http.server 8000
# → http://localhost:8000
```

**The in-browser lab** (optional — a 32-bit Linux terminal that runs in the browser, no install):

```bash
cd browser-lab && python3 -m http.server 8001    # → http://localhost:8001
```

Use a real server rather than opening the HTML directly; the game and lab rely on browser APIs
that `file://` blocks.

## Verifying it works

```bash
make test-challenges    # solves all four from the participant files and asserts each flag
make scan-secrets       # checks no answers leaked into participant/
make build-challenges   # deterministically rebuilds the challenge distributions
```

All four solver tests pass, the warehouse game has a 27-assertion browser test, and the browser
lab's toolchain was proven in a real 32-bit container by solving challenges 2 and 4 inside it.
Details in [`facilitator/VALIDATION_REPORT.md`](facilitator/VALIDATION_REPORT.md).

## Repository layout

```
participant/    what players get — challenges, briefings, toolkit, warehouse game
facilitator/    answers, walkthroughs, hint ladders, rebuild + solver tests, provenance
browser-lab/    in-browser 32-bit Linux lab (v86) + image build recipe + feasibility proof
deploy/         static-site bundle for publishing, and lab hosting configs
build/          archive inventory, secret-scan gate, shared build config
```

These challenges were reconstructed from an original run's working archive. That archive is
immutable and kept outside this repo; every canonical file is traced back to it by SHA-256 in
[`facilitator/ARCHIVE_PROVENANCE.md`](facilitator/ARCHIVE_PROVENANCE.md), including which
revisions were rejected and why.

## Academic use

An authorized, self-contained educational exercise operating only on supplied local files. It does
not touch third-party systems, live services, or real credentials; password recovery applies solely
to deliberately embedded CTF secrets using author-provided wordlists. Full statement:
[`facilitator/ACADEMIC_USE.md`](facilitator/ACADEMIC_USE.md).

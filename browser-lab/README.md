# Browser Lab — in-browser Kali-style workbench

A client-side x86 Linux environment where players solve the stego CTF in the browser. No server,
no install. The engine is **v86** (BSD-2, no special headers → runs on GitHub Pages). A graphical
**CheerpX** desktop is the documented upgrade for a header-capable host.

## What's here

| Path | What |
|---|---|
| `index.html` | Landing + discreet chooser (Launch Terminal ready · Launch Desktop = honest upgrade explainer) |
| `terminal.html` | The terminal lab harness — v86 + xterm.js, serial console, browser-local snapshot + Reset |
| `ENGINE_DECISION.md` | Engine + host decision, with the measurements taken this session |
| `feasibility/i386-toolchain-proof.md` | The de-risk: toolchain solves C2 + C4 in genuine 32-bit i386 (captured transcript) |
| `image/` | Reproducible recipe that bakes the proven toolchain + sanitized files into a v86 image |
| `_headers` | COOP/COEP for the CheerpX desktop on Cloudflare Pages |
| `vendor/` | Same-origin boot blobs (git-ignored, large; fetched at deploy time) |

## Run locally

```bash
cd browser-lab
# vendor the base kernel once (same-origin; i.copy.sh 403s cross-origin browser requests)
mkdir -p vendor && curl -fsSL -o vendor/buildroot-bzimage68.bin https://i.copy.sh/buildroot-bzimage68.bin
python3 -m http.server 8791
# open http://localhost:8791/index.html
```

## Deploy

- **GitHub Pages (terminal, ready now):** publish this folder. No headers needed. The harness loads the
  v86 engine from jsdelivr and the boot image from `./vendor/` (same-origin). $0, no infra change.
- **Cloudflare Pages (adds the CheerpX desktop):** publish this folder *with* `_headers` to get
  cross-origin isolation, then wire the Desktop button to CheerpX. See `ENGINE_DECISION.md`.

## Status (verified this session)

- ✅ **i386 toolchain solves C2 + C4** in genuine 32-bit — `feasibility/i386-toolchain-proof.md`.
- ✅ **Terminal boots a real interactive 32-bit Linux shell in-browser** (verified live: `uname -m → i686`).
- ✅ **Landing + chooser** work; the Desktop button is an honest "not on this host" explainer, not a dead boot.
- ✅ **Image packaging pipeline** (`docker export → fs2json → copy-to-sha256`) verified; sizes in `ENGINE_DECISION.md`.
- ⏳ **Lab-image (Debian-i386 + toolkit) boot over 9p** is the documented integration step — the base-image
  terminal is verified; flip `ACTIVE="lab"` in `terminal.html` after `image/build-image.sh`. See `image/README.md`.

Ships only the sanitized player files (`build/secret-scan/scan.sh browser-lab` → PASS). No answers, no
`facilitator/` content.

# Engine + host decision — in-browser lab

**Decision: ship the lab on v86 running on GitHub Pages now; document CheerpX on
Cloudflare Pages as the graphical-desktop upgrade path.**

This matches the default recommendation in the tasking, and nothing I measured argues against it.
Every number below is labelled either **measured** (I ran it this session) or **estimate**.

---

## The constraint that drives everything: cross-origin isolation

A browser only exposes `SharedArrayBuffer` when the page is **cross-origin isolated**, which requires
two response headers on the HTML document:

```
Cross-Origin-Opener-Policy:   same-origin
Cross-Origin-Embedder-Policy: require-corp
```

- **CheerpX / WebVM need `SharedArrayBuffer`** (their block device + threads ride on it), so they
  need those headers.
- **GitHub Pages cannot set custom response headers.** There is no `_headers` file, no `.htaccess`,
  no config knob. So a plain GH Pages origin is **not** cross-origin isolated, and CheerpX will not run.
- **v86 does not require `SharedArrayBuffer`.** It runs its x86-to-wasm JIT on the main thread (or an
  ordinary worker) and works on any static host with no special headers.

The site is GitHub Pages (britt.gg). That single fact selects **v86** for the shipping lab.

### Ways to get the headers (for the desktop upgrade)
1. **Cloudflare Pages** — drop a `_headers` file with the two lines above. Free tier, custom domain. This
   is the clean home for the CheerpX desktop.
2. **coi-serviceworker shim** — a service worker (Guido Zuidhof's `coi-serviceworker`) that re-fetches
   resources and synthesizes COOP/COEP client-side, making even GH Pages report as isolated. Works, but
   adds a service worker, a reload dance on first visit, and CORP caveats for third-party assets. Fine as
   a fallback; a header-capable host is tidier.

---

## Engine comparison

| | **v86** | **CheerpX / WebVM** |
|---|---|---|
| License | BSD-2-Clause (vendorable) | Proprietary runtime; free for use, **not** redistributable — load from their CDN |
| Needs COOP/COEP headers | **No** | **Yes** (`SharedArrayBuffer`) |
| Runs on plain GitHub Pages | **Yes** | No (needs a header-capable host / shim) |
| CPU | x86 → wasm JIT, 32-bit guest | x86 → wasm JIT, can run 32-bit userland incl. glibc |
| Best at | Serial **terminal**, small footprint | Full **GUI** desktop (X11/Wayland apps, file manager) |
| Image supply | You build a rootfs (9p / disk); on-demand HTTP fetch | Ext2 disk image over their block backend |
| Boot feel | Fast to a shell; heavier for a GUI | Heavier boot; smooth GUI once up |

Both are honest x86 emulators that can run the **exact 32-bit Debian userland proved in
`feasibility/i386-toolchain-proof.md`**. The split is host capability and use-case, not "can it run the tools."

### Why v86 for the terminal (the thing we ship today)
- Zero-header hosting → works on the existing GH Pages site, **$0**, no infra change.
- BSD-licensed → the engine can be vendored for a fully offline/pinned deploy if desired.
- A serial console to a 32-bit Linux is exactly what the toolkit needs: `exiftool`, `binwalk`,
  `steghide`, `openssl`, `python3` are all CLI. No GUI required to solve any challenge.
- Proven-bootable base: `buildroot-bzimage68.bin` (~9.6 MB, CORS-open at i.copy.sh) boots a real Linux
  shell in-page — used to verify the harness end-to-end this session (see measurements).

### Why CheerpX is the documented GUI upgrade, not the ship-now choice
- It genuinely gives a nicer experience (view the badger JPEGs in an actual image viewer, drag files),
  which is pleasant for a stego CTF.
- But it needs the headers GH Pages can't provide, and its runtime can't be vendored. Standing up
  Cloudflare Pages (or the coi shim) is a deploy-time decision for the facilitator, not a blocker for
  having a working lab. So it's wired as an **honest "not on this host yet"** button on the landing page,
  linking here — never a dead control pretending to boot.

---

## Host decision

| Host | v86 terminal | CheerpX desktop | Cost | Notes |
|---|---|---|---|---|
| **GitHub Pages** (current) | ✅ works | ❌ no headers | $0 | Ship the terminal here now |
| **Cloudflare Pages** | ✅ works | ✅ `_headers` | $0 (free tier) | Home for the desktop upgrade |
| GH Pages + coi-serviceworker | ✅ | ⚠️ works with caveats | $0 | Fallback if staying on GH Pages |

**Recommendation:** keep the terminal on GitHub Pages (britt.gg). When the graphical desktop is wanted,
publish the same `browser-lab/` folder to Cloudflare Pages with the `_headers` file and enable the
CheerpX desktop there. No rework of the challenge content or the landing page is required — only the
`ACTIVE`/engine wiring changes.

---

## Measurements (this session)

Environment: macOS (Apple Silicon / arm64), Docker Desktop with qemu **linux/386** emulation;
in-app Chromium for the browser boot.

### i386 userland (what any image would contain) — MEASURED, PASS
See `feasibility/i386-toolchain-proof.md` for the full captured transcript. Summary:

- Base: **Debian 13 (trixie), i686 / 32-bit** — verified `getconf LONG_BIT = 32`, `uname -m = i686`,
  and `steghide`/`openssl`/`python3` are all `ELF 32-bit … Intel i386`.
- Versions (i386 apt): steghide `0.5.1-15`, exiftool `13.25`, openssl `3.5.6`, binwalk `2.4.3`,
  python3 `3.13.5`, file `5.46`, xxd `9.1.1230`, unzip `6.00`, zip `3.0`, coreutils `9.7`.
- **Solved C2** (crack `password123` → `Flag{DanG 7hat'S @ cUTe HOnEY b@D9eR}`, payload SHA matches)
  and **C4** (full carve→qtbl.py→openssl chain → `Flag{Y0u haVe EnCouNTeR3d a w!Ld s1eEP p@RA1y$!S DEm0n}`).
- Note: `stegcracker` needs `pip install setuptools` on Python 3.13 (distutils was removed); the recipe
  installs it. C2's crack is proven via the steghide loop stegcracker wraps.

### v86 engine + boot (browser) — MEASURED, live
- Verified **live in-app Chromium**: the harness boots the base image to an **interactive 32-bit shell**
  (`uname -m → i686`, shell arithmetic runs). Screenshot-confirmed this session.
- Base kernel `buildroot-bzimage68.bin`: **9.6 MB** (`content-length: 10068480`). ⚠️ i.copy.sh returns
  **403 to cross-origin browser requests** (curl with no Origin gets 200), so boot images must be served
  **same-origin** — the harness loads `./vendor/buildroot-bzimage68.bin` and `build-image.sh` vendors it.
- Engine assets: `libv86.js` + `v86.wasm` from **jsdelivr npm v86@0.5.424**; `seabios.bin` (128 KB) +
  `vgabios.bin` pinned to v86 commit `2f1346b` via jsdelivr-gh (npm package ships no BIOS; the tag
  `v0.5.424` does not exist — use a commit SHA).
- Cold boot to shell: **~10–15 s** in-session (kernel fetch + boot); warm boot is near-instant
  (browser-cached). Approximate — not precisely timed.

### Lab image (Debian i386 + toolkit + challenge files) — packaging MEASURED
- Packaging pipeline verified end-to-end on the real toolchain rootfs
  (`docker export` → `fs2json.py` → `copy-to-sha256.py`):
  - `rootfs.tar` (toolchain userland): **216 MB**
  - `fs.json` (loaded upfront by v86): **508 KB**
  - `flat/` content-addressed store (fetched **on-demand**): **211 MB across 6,668 objects**
- Because v86's 9p store is fetched lazily, the effective cold-boot transfer is a small fraction of
  211 MB (only files the guest touches). Adding the boot kernel (`linux-image-686`, ~50–80 MB) and
  baking the player files is the production image; that i386 build + browser boot is the documented
  integration step in `image/README.md`.

---

## Bottom line

- **Now:** v86 + GitHub Pages → a working terminal lab with the full toolkit, no new hosting, no headers, $0.
- **Upgrade:** CheerpX + Cloudflare Pages (or the coi shim) → a graphical Kali-style desktop, when wanted.
- The userland is identical either way and is the part that was de-risked first (the i386 proof).

# Badger Lab image — build recipe

Bakes the **proven 32-bit toolchain** + the **sanitized player files** into a bootable
v86 image (a 9p filesystem: `dist/fs.json` + `dist/flat/`). `../terminal.html` boots it
when `ACTIVE="lab"`.

## Files

| File | Role |
|---|---|
| `Dockerfile` | The lab image: Debian i386 + toolkit + kernel + serial-autologin + 9p initramfs + player files |
| `build-image.sh` | Assemble sanitized payload → secret-scan → build i386 image → export → `fs2json` → `copy-to-sha256` |
| `build-image-fallback.sh` | Buildx-free path: provision a real i386 container and `docker commit` (see the platform gotcha) |
| `overlay/.../local-top/9proot` | initramfs hook: load virtio+9p so `root=host9p` mounts under v86 |
| `tools/fs2json.py`, `tools/copy-to-sha256.py` | v86's packagers (BSD-2, vendored from v86 @ `2f1346b`) |
| `dist/` | Build output (gitignored): `rootfs.tar`, `fs.json`, `flat/` |

## Build

```bash
cd browser-lab/image
bash build-image.sh          # needs Docker with linux/386 emulation
```

Then flip `ACTIVE="lab"` in `../terminal.html`, serve `browser-lab/` over HTTP, open `terminal.html`.

## ⚠️ The 32-bit build gotcha (important, verified this session)

`docker build --platform linux/386` with the **classic** builder **silently ignores the platform
and builds your host architecture.** I hit exactly this: a `-t badger-proof:i386`-tagged image
inspected as `Architecture=amd64`, and its `steghide` was `ELF 64-bit`. Two correct ways:

1. **buildx / BuildKit** — `docker buildx build --platform linux/386 --load` produces a real
   `Architecture=386` image. `build-image.sh` uses this when `docker buildx` is present.
2. **`docker run --platform linux/386` + `docker commit`** — running (not building) genuinely emulates
   i386 (verified: `getconf LONG_BIT = 32`, `uname -m = i686`). `build-image-fallback.sh` does this.

`build-image.sh` asserts `Architecture == 386` after building and aborts otherwise.

## The toolchain (proven)

Installed from the **Debian i386 apt repo** (Debian 13 / trixie), grouped with
`--no-install-recommends` (a bulk install of the whole list *with* recommends stalls emulated dpkg —
grouped installs are reliable). Exact packages and versions, plus both recovered flags, are in
`../feasibility/i386-toolchain-proof.md`. Cracker: **stegcracker** (pure-python wrapper around
steghide) via pip.

## Player files baked in (`~/challenges`)

`email.eml`, `stego_badger.jpeg`, `Honey.jpeg`, the four `BRIEF-*.md`, and `wordlist.txt`
(the shipped trimmed list). **Nothing from `facilitator/` or the archive.** `build-image.sh`
runs `build/secret-scan/scan.sh` over the staged payload and refuses to build if it doesn't PASS.
C3 (the Memory Warehouse) has no file — it's solved with the companion warehouse game.

## What's verified vs pending

**Verified live this session**
- The i386 toolchain installs and **solves C2 + C4** in a genuine 32-bit container
  (`../feasibility/i386-toolchain-proof.md`).
- The **base-OS terminal boots and is interactive in-browser** via v86 (busybox, `uname -m = i686`) —
  this proves the engine + harness + serial console end-to-end.
- The **packaging pipeline** (`docker export` → `fs2json.py` → `copy-to-sha256.py`) runs and produces
  `fs.json` + `flat/`; sizes are printed by `build-image.sh` and recorded in `../ENGINE_DECISION.md`.

**Pending on-deploy verification (documented, not yet booted in a browser here)**
- The **Debian lab image booting root-over-9p in v86.** Kernel (`linux-image-686`), the 9p initramfs
  hook, and serial autologin are baked by the Dockerfile, mirroring v86's working `alpine.html`
  mechanism — but Debian's initramfs mounting `root=host9p` is the one piece not yet booted in-browser
  in this session. Verify by building, setting `ACTIVE="lab"`, and opening `terminal.html`.
  - If the 9p-root mount needs tuning, the robust alternative is a **raw ext2 disk image** booted as
    `hda` (kernel + extlinux inside the image), which sidesteps initramfs-9p entirely; v86 boots such
    disk images directly (see v86 `docs/archlinux.md`).

## Sizes

Recorded by the last `build-image.sh` run — see the "Measurements" section of `../ENGINE_DECISION.md`.
The 9p `flat/` store is fetched by the browser **on-demand** (only files the guest touches are
downloaded), so the effective cold-boot transfer is far smaller than the full rootfs.

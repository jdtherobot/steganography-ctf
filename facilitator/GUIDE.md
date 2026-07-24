# Facilitator Guide

Everything you need to run the session. Hand players the **`participant/`** folder only;
keep **`facilitator/`** to yourself.

## Flags at a glance

*(case-, space-, and symbol-sensitive)*

| # | Title | Flag |
|---|---|---|
| 1 | Steganography lvl 1 | `Flag{H0NeyB4d6er10OKinG0OD!!!}` |
| 2 | Steganography lvl 2 | `Flag{DanG 7hat'S @ cUTe HOnEY b@D9eR}` |
| 3 | Steganography lvl 3 | `Flag{Y0u haVe EnCouNTeR3d a w!Ld s1eEP p@RA1y$!S DEm0n}` |
| 4 | Computer Architecture Warehouse | `Flag{TOMHANKSAINTGOTSHITONME}` |

Full solves: `facilitator/challenges/NN/WRITEUP.md`. Each has a `solve_test.sh` that
solves from the player files and asserts the flag.

## Order & dependencies

Run **lvl 1 → lvl 2 → lvl 3 → Warehouse.** The Warehouse's ciphertext is **line 9 of the
document players recover in lvl 2**, and lvl 3's key material is the same document's filler
lines — so make sure lvl 2 is solved first (the Warehouse's own hint says as much).

## The Warehouse — in-person vs game

The puzzle resolves a virtual address to one physical box. Two ways to run it:

- **In-person:** place the note (`challenges/04-computer-architecture-warehouse/assets/warehouse_note.png`)
  in the correct box — **Row 2 / Shelf 1 (bottom) / Section 2 (back) / Sub-section 1 / Box 5**.
- **Remote:** players use the companion warehouse game (the `jd-ctf-environment` repo / site);
  it mirrors the same note and geometry.

### Warehouse geometry (kept out of the player brief on purpose)

The player brief is **only the memo + VA**. This mapping is your reference — and what the
physical space / game embeds:

| Level | Meaning |
|---|---|
| L1 / PML4 | Row (1–10) |
| L2 / PDPT | Shelf level (bottom = 1 → top = 3) |
| L3 / PD | Section (front = 1, back = 2) |
| L4 / PT | Sub-section of the grate (8 sub-sections of 7; 56 spokes per grate) |
| Offset | Box within the sub-section (the page frame) |

`VA = 0x0000_0100_4040_1005` → **Row 2 / Shelf 1 / Section 2 / Sub-section 1 / Box 5.**
Full walk + the four-square decode in the Warehouse WRITEUP.

## Hints

- **lvl 1 & lvl 3** — hints are woven into the challenge itself (the email body; the lvl-3
  narration). No separate hint files.
- **lvl 2** — two optional hints in `participant/…/02-…/hints/` (release in order): (1) *"WE WILL,
  WE WILL…"* — a nudge toward the right wordlist (*We Will Rock You* → `rockyou`); then (2) *"try
  common password lists / stego tools."* The wordlist is **not** shipped — players supply their own
  (e.g. `rockyou`) or simply guess `password123`.
- **Warehouse** — two optional hints ship in `participant/…/04-…/hints/` (release in order):
  (1) *"have you beaten lvl 2?"*, then (2) the VA bit-split.

## Provenance

Every challenge, image, payload, password, and flag here is author-created and author-owned.
The player-facing text is exactly what participants received in the original event; the
setup/solve walkthroughs are the author's own.

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
  in the correct box — **Row 1 / Bay 2 (back) / Shelf 1 (bottom) / Sub-section 2 / Box 5**.
- **Remote:** players use the companion warehouse game (the `jd-ctf-environment` repo / site);
  it mirrors the same note and geometry.

### Warehouse geometry (kept out of the player brief on purpose)

The player brief is **only the memo + VA**. This mapping is your reference — and what the
physical space / game embeds:

| Level | Meaning |
|---|---|
| L1 / PT | Row (1–10) |
| L2 / PD | Bay (front = 1, back = 2) |
| L3 / PDPT | Shelf level (bottom = 1 → top = 3) |
| L4 / PML4 | Sub-section of the grate (8 sub-sections of 7; 56 spokes per grate) |
| Offset | Box within the sub-section (the page frame) |

Level numbers follow the page-table document (Level 4 = the top 9 bits — what the MMU
walks first); on the floor you walk them L1 → L4, big structure to small.

`VA = 0x0000_0100_4040_1005` → **Row 1 / Bay 2 (back) / Shelf 1 (bottom) / Sub-section 2 / Box 5.**
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

## Origin

I created and own every challenge, image, payload, password, and flag here. The player-facing
text is what participants received when I ran this; the setup and solve walkthroughs are mine.
These four challenges are my own work, updated and revised from a live CTF I co-designed and
ran in October 2025 (originally hosted on CTFd).

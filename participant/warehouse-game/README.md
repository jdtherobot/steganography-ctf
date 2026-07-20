# HBHY Logistics — Memory Warehouse

A top-down, navigable warehouse: the immersion layer for **Challenge 3 (Stegosaurus 2)**.
Your page-table walk resolves the virtual address in the briefing to a physical location —
row, shelf level, bay, subsection, box. Walk the floor, find the face, open the box.
The right box holds a field note you can view in-game and download; every other box is
"Nothing here."

## Running it

One file, zero dependencies. Either:

- open `index.html` directly in a browser, or
- serve the folder from any static host (target deploy: `britt.gg/ctf/warehouse/`).

It is plain static content — no build step, no special response headers, no network
requests at runtime (all CSS/JS/art is inline; the world and sprites are drawn
procedurally on a canvas).

## Controls

| Input | Action |
|---|---|
| `W A S D` / arrow keys | walk |
| `E` / `Enter` / `Space` | inspect the shelf face you are standing at |
| Click / tap a floor tile | walk there |
| Click / tap a shelf | walk to it, then open that face |
| `Esc` | close a panel |
| On-screen pad + INSPECT button | touch controls (appear on touch screens) |

The header has Inventory (records the recovered note), Help, Settings, and Reset
(returns you to receiving and clears the inventory; progress otherwise persists in
`localStorage`).

## Layout key

- **ROW 1–10**: shelf units, numbered from receiving (the spawn area).
- **BAY 1 (front)** faces receiving; **BAY 2 (back)** faces the north walkway.
- **SUBSECTION 1–8**: west → east, stenciled on the floor along each face.
- **SHELF LEVEL 1 (bottom) – 3 (top)** and **BOX 1–7**: visible when you inspect a face.

## Accessibility

- No timer, no combat, no fail state.
- Reduced-motion mode (defaults to the system preference; toggle in Settings) — camera
  snaps instead of gliding, panel/stamp animations removed.
- Sound is **off by default** (small synth blips if enabled).
- Visible keyboard focus throughout; dialogs manage focus and close on `Esc`; state
  changes are announced via a polite live region.
- Designed for ~1024×768 and up; smaller screens get a notice and can continue anyway.

## Honesty note (read this before treating the game as a gate)

This is a **client-side static page**. It cannot actually *enforce* the puzzle: the
logic that decides which box is correct ships to the player's browser, and anyone who
opens devtools can read it, brute-force all 3,360 locations in a loop, or lift the note
text out of the source.

What it does instead:

- The verified coordinates are **not stored in the clear** — the entered location is
  hashed (FNV-1a over the coordinate string) and compared against a constant, so the
  answer does not appear in a casual text search of the source.
- The note's words are base64-encoded for the same reason.

That is *light obfuscation*, not security. Treat the game as flavor and confirmation
for participants who solved the page-table walk on paper — the actual verification of
Challenge 3 answers happens outside this page. The note contains only the intermediate
clue for the next step; no flag or final answer ships in this folder.

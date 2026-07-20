# Challenge 3 — Hint Ladder

Staged hints, mildest first. Give one tier at a time and let it sink in.
Tiers 4+ are **location/answer spoilers** — use sparingly.

## Tier 1 — What language is this memo speaking?

MMU, TLB, page-table walk, VA — these are real x86-64 memory-management terms,
and the puzzle plays them straight. An MMU turns a *virtual* address into a
*physical* location by walking a tree of tables. Your job is to be the MMU.

## Tier 2 — Split the address

Only the low 48 bits of an x86-64 virtual address matter here. Write
`0x0000_0100_4040_1005` out in binary (48 bits, keep leading zeros!) and slice
it left-to-right into `9 + 9 + 9 + 9 + 12` bits — PML4, PDPT, PD, PT, offset.
Converting to binary first is easier than mask-and-shift by hand.

## Tier 3 — Read the slices as coordinates

Each 9-bit slice is just a small number, and the brief's table says what each
one means in the warehouse: row, shelf level, front/back bay, sub-section —
and the 12-bit offset is the box number. All five values here are single-digit.
Walk them in order: L1 → L2 → L3 → L4 → offset.

## Tier 4 — SPOILER: the location

Row **2**, shelf level **1** (bottom), **back** bay (2), sub-section **1**,
box **5**. The box contains a note — everything on it matters.

## Tier 5 — Reading the note

Three observations unlock it:

* "dCode" is a website — dcode.fr. Which of its cipher tools uses a 2×2
  arrangement of **four** 5×5 squares? Count the empty boxes after "dCode".
* The note has exactly four corner words. Four squares... four keywords...
  and the note's own layout shows **which word goes in which corner**.
* "Line #9" — where in this CTF have you already seen a numbered wall of
  24-letter lines? Check what Challenge 2 gave you. Line 9 is your ciphertext.

## Tier 6 — SPOILER: the cipher settings

Four-square cipher, and **all four** grids are keyed (not just the usual two):
TL=HONEY, TR=BADGER, BL=HECK, BR=YEAH — corner word into that same corner's
grid, keyword letters first, then the rest of the alphabet with I/J merged
(J→I). Decrypt line 9 of the Challenge 2 document:
`UPNAHLNSIBESOLTUEBUPDNEY`. If you get garbage, a grid is in the wrong corner
or a "plain" grid is still unkeyed.

## Tier 7 — FULL SPOILER: the answer

The decode is `TOMHANKSAINTGOTSHITONMEZ`; drop the trailing `Z` pad:
**TOM HANKS AINT GOT SHIT ON ME**. Submit as `Flag{TOMHANKSAINTGOTSHITONME}`
(graders also accept the bare/spaced plaintext — see WRITEUP.md).

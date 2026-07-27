# Challenge 4 · Computer Architecture Warehouse — Facilitator Writeup

**FACILITATOR ONLY — contains the flag and every secret. Never hand to players.**

| | |
|---|---|
| Puzzle | x86-64 page-table walk → physical warehouse box → four-square cipher |
| Input | `VA = 0x0000_0100_4040_1005` (in the player memo) |
| Location | Row 1 / Bay 2 (back) / Shelf 1 (bottom) / Sub-section 2 / Box 5 |
| Ciphertext | line 9 of the lvl-2 document: `UPNAHLNSIBESOLTUEBUPDNEY` |
| Flag | `Flag{TOMHANKSAINTGOTSHITONME}` |

## The walk

Split the low 48 bits, most-significant first, into `[PML4 9][PDPT 9][PD 9][PT 9][OFFSET 12]`:

```
0x0000_0100_4040_1005 → PML4=2  PDPT=1  PD=2  PT=1  OFFSET=5
```
Equivalent mask/shift: `(VA>>39)&0x1FF=2`, `(VA>>30)&0x1FF=1`, `(VA>>21)&0x1FF=2`,
`(VA>>12)&0x1FF=1`, `VA&0xFFF=5`.

## The warehouse mapping (the answer)

| Level | Value | Coordinate |
|---|---|---|
| L1 / PT | 1 | **Row 1** |
| L2 / PD | 2 | **Bay 2** (front=1, back=2) |
| L3 / PDPT | 1 | **Shelf level 1** (bottom) |
| L4 / PML4 | 2 | **Sub-section 2** |
| Offset | 5 | **Box 5** |

Level numbers are the document's (Level 4 = the top 9 bits — what the MMU walks first);
on the floor you walk them L1 → L4 (row → bay → shelf → sub-section), big structure to small.

Geometry: 10 rows × 3 shelf levels × 2 bays × 8 sub-sections × 7 boxes = **3,360 boxes**
(56 spokes per grate = 8 sub-sections of 7).

## The note (earned at the box)

Printable asset: [`assets/warehouse_note.svg`](assets/warehouse_note.svg) (+ `.png`).

```
Honey                 Badger
        dCode ▢ ▢ ▢ ▢
           Line #9
Heck                  Yeah
```
- **dCode ▢▢▢▢** → the dcode.fr **Four-Square Cipher** tool; four blanks = four keywords.
- **Line #9** → line 9 of the Steganography lvl 2 document: `UPNAHLNSIBESOLTUEBUPDNEY`.
- The 2×2 layout *is* the grid diagram — each corner word keys the square in that corner.

## The four-square (working configuration)

All four 5×5 squares are keyed (I/J merged, `J→I`), corner word → corner square:

```
TL  key=HONEY        TR  key=BADGER
  H O N E Y            B A D G E
  A B C D F            R C F H I
  G I K L M            K L M N O
  P Q R S T            P Q S T U
  U V W X Z            V W X Y Z

BL  key=HECK         BR  key=YEAH
  H E C K A            Y E A H B
  B D F G I            C D F G I
  L M N O P            K L M N O
  Q R S T U            P Q R S T
  V W X Y Z            U V W X Z
```

Decrypt each digraph `c1 c2`: find `c1` in **TR** and `c2` in **BL**; then
`p1 = TL[row(c1), col(c2)]` and `p2 = BR[row(c2), col(c1)]`.

```
CT:  UP NA HL NS IB ES OL TU EB UP DN EY
PT:  TO MH AN KS AI NT GO TS HI TO NM EZ
```

`UPNAHLNSIBESOLTUEBUPDNEY` → `TOMHANKSAINTGOTSHITONMEZ` → strip the `Z` pad →
`TOMHANKSAINTGOTSHITONME`.

**Flag:** `Flag{TOMHANKSAINTGOTSHITONME}` — "TOM HANKS AINT GOT SHIT ON ME".
Graders may also accept the bare/spaced plaintext.

> This is the configuration that decodes the ciphertext: the standard two-keyed-square
> four-square does **not**; the note's four corner words are the tell that all four squares
> are keyed.

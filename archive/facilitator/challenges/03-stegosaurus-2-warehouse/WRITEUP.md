# Challenge 3 — Stegosaurus 2 (Warehouse): Full Solution

**FACILITATOR ONLY — contains every answer including the flag.**

| | |
|---|---|
| Puzzle | x86-64 page-table walk → physical warehouse location → four-square cipher |
| Input | `VA = 0x0000_0100_4040_1005` (in the participant brief) |
| Location | row 2 / shelf level 1 (bottom) / back bay (2) / sub-section 1 / box 5 |
| Ciphertext | line 9 of the Challenge 2 payload: `UPNAHLNSIBESOLTUEBUPDNEY` |
| Plaintext | `TOMHANKSAINTGOTSHITONME` (+ trailing `Z` pad) — "TOM HANKS AINT GOT SHIT ON ME" |
| Canonical flag | `Flag{TOMHANKSAINTGOTSHITONME}` (**reconstructed default** — see [Flag](#step-6--the-flag)) |

## Step 1 — Decompose the virtual address

The memo gives a canonical 48-bit x86-64 virtual address (upper 16 bits zero):

```
VA = 0x0000_0100_4040_1005        low 48 bits = 0x0100_4040_1005
```

Split the 48 bits, most-significant first, into `[PML4 9][PDPT 9][PD 9][PT 9][OFFSET 12]`:

```
0x0100_4040_1005 = 000000010 000000001 000000010 000000001 000000000101
                     PML4=2    PDPT=1     PD=2      PT=1     OFFSET=5
```

Equivalent mask-and-shift:

| Field  | Expression            | Value |
|--------|-----------------------|-------|
| PML4   | `(VA >> 39) & 0x1FF`  | **2** |
| PDPT   | `(VA >> 30) & 0x1FF`  | **1** |
| PD     | `(VA >> 21) & 0x1FF`  | **2** |
| PT     | `(VA >> 12) & 0x1FF`  | **1** |
| OFFSET | `VA & 0xFFF`          | **5** |

## Step 2 — Walk the warehouse

Applying the brief's mapping (10 rows × 3 shelf levels × 2 bays × 8 sub-sections × 7 boxes):

| Level  | Value | Physical coordinate            |
|--------|-------|--------------------------------|
| PML4   | 2     | **Row 2**                      |
| PDPT   | 1     | **Shelf level 1** (bottom)     |
| PD     | 2     | **Back bay** (front=1, back=2) |
| PT     | 1     | **Sub-section 1** of the grate |
| OFFSET | 5     | **Box 5** (the page frame)     |

## Step 3 — The note in the box

The box holds a 2×2 note (printable asset: [`clue/warehouse_note.svg`](clue/warehouse_note.svg);
the warehouse game mirrors this exact text):

```
Honey                    Badger

        dCode ▢ ▢ ▢ ▢
           Line #9

Heck                     Yeah
```

Reading the note:

* **"dCode ▢ ▢ ▢ ▢"** — the dcode.fr **Four-Square Cipher** tool, with four blanks
  to fill: the four corner words are the four keywords.
* **"Line #9"** — line 9 of the document extracted from the photo in Challenge 2.
* The 2×2 layout is not decoration: **the note itself is the four-square grid
  diagram**. Each corner word keys the 5×5 square in that same corner.

## Step 4 — Fetch the ciphertext

Line 9 of the Challenge 2 payload (`Flag 2.txt` as extracted by steghide/stegseek):

```
UPNAHLNSIBESOLTUEBUPDNEY        (24 letters = 12 digraphs)
```

## Step 5 — Four-square decode (exact configuration)

This is the **only** configuration that decodes the ciphertext — verified by an
exhaustive sweep of every corner/keyword assignment (see `PROVENANCE.md`):

* **All four 5×5 squares are keyed** — corner word → corner square, exactly as
  printed on the note: TL=`HONEY`, TR=`BADGER`, BL=`HECK`, BR=`YEAH`.
  (The textbook four-square keeps TL/BR as plain alphabets. That standard
  configuration — TR=`BADGER`, BL=`HECK` only — does **not** decode this
  ciphertext. The note showing four words in four corners is the tell.)
* **Square construction:** keyword letters first (deduplicated, in order), then
  the remaining letters of the 25-letter alphabet in order.
* **Alphabet / I-J rule:** `ABCDEFGHIKLMNOPQRSTUVWXYZ` — I and J merged, `J → I`.
* **Digraph rule (classic four-square):** to decrypt pair `c1 c2`: find `c1` in
  TR and `c2` in BL; then `p1 = TL[row(c1), col(c2)]` and `p2 = BR[row(c2), col(c1)]`.
* **Padding:** odd-length plaintext padded with a trailing `Z`.

The four grids:

```
TL key=HONEY          TR key=BADGER
  H O N E Y             B A D G E
  A B C D F             R C F H I
  G I K L M             K L M N O
  P Q R S T             P Q S T U
  U V W X Z             V W X Y Z

BL key=HECK           BR key=YEAH
  H E C K A             Y E A H B
  B D F G I             C D F G I
  L M N O P             K L M N O
  Q R S T U             P Q R S T
  V W X Y Z             U V W X Z
```

Worked first digraph `UP`: `U` is at TR row 3, col 4; `P` is at BL row 2, col 4
(0-indexed). So `p1 = TL[3,4] = T` and `p2 = BR[2,4] = O` → `TO`. Continuing:

```
CT:  UP NA HL NS IB ES OL TU EB UP DN EY
PT:  TO MH AN KS AI NT GO TS HI TO NM EZ
```

Result:

```
TOMHANKSAINTGOTSHITONMEZ  →  strip pad  →  TOMHANKSAINTGOTSHITONME
                                            "TOM HANKS AINT GOT SHIT ON ME"
```

Tool notes for facilitators:

* On dcode.fr's four-square page, make sure **all four** grids end up keyed with
  the corner words in their corner positions (the note's layout). Any tool that
  only keys the two cipher squares (TR/BL) will produce garbage.
* Offline reference: `python3 foursquare.py decrypt UPNAHLNSIBESOLTUEBUPDNEY`
  (defaults to the canonical keys) prints `TOMHANKSAINTGOTSHITONMEZ`.
* Equivalence trick if a tool only has an *encrypt* mode: swapping TL↔TR and
  BL↔BR turns encryption into decryption — encrypting the ciphertext with
  TL=`BADGER`, TR=`HONEY`, BL=`YEAH`, BR=`HECK` yields the same plaintext.

## Step 6 — The flag

> **Reconstructed default — read before grading.** The archive's
> `main/Challenge 3/` directory is **empty**: no Challenge-3 flag file survived,
> so the original submission string is unrecoverable. The four-square
> *plaintext* is fully verified ground truth; the `Flag{...}` wrapper below is
> pinned by us for consistency with the other three challenges' flag convention.

**Canonical flag:**

```
Flag{TOMHANKSAINTGOTSHITONME}
```

Facilitators should also accept these equivalents as correct solves:

* `TOMHANKSAINTGOTSHITONME` (bare plaintext)
* `TOMHANKSAINTGOTSHITONMEZ` (pad not stripped)
* `TOM HANKS AINT GOT SHIT ON ME` (spaced, human-readable)

## Verification

```sh
bash facilitator/challenges/03-stegosaurus-2-warehouse/rebuild.sh     # pins archive doc, checks walk, emits clue asset
bash facilitator/challenges/03-stegosaurus-2-warehouse/solve_test.sh  # replays solve; prints "C3 PASS"
```

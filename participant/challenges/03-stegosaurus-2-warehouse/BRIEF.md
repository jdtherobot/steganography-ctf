# Challenge 3 — Stegosaurus 2: The Memory Warehouse

> A computer-architecture puzzle, for the real nerds.

**Suggested requirement:** complete Challenge 2 (Stegosaurus 1) first, and keep
everything it gave you. This challenge stars the exact same photo you already
have — but this time the answer is not inside the pixels.

## The memo

```
TO: MMU

Your TLB is empty. You must perform a page-table walk to resolve a
virtual address into a physical location in our memory warehouse.

VA = 0x0000_0100_4040_1005
```

## How a page-table walk works

x86-64 resolves a 48-bit virtual address in four levels plus a page offset.
Split the low 48 bits of the VA, most-significant bits first, into:

```
[ PML4 : 9 ][ PDPT : 9 ][ PD : 9 ][ PT : 9 ][ OFFSET : 12 ]
```

| Level  | Long name                        | Walk order |
|--------|----------------------------------|------------|
| PML4   | Page-Map Level 4                 | L1         |
| PDPT   | Page-Directory-Pointer Table     | L2         |
| PD     | Page Directory                   | L3         |
| PT     | Page Table                       | L4         |
| OFFSET | byte within the page frame       | last       |

Mask-and-shift works fine, but converting the address to binary first and
slicing the bit-string may be easiest. Walk level by level
(L1 → L2 → L3 → L4), then use the offset to pick the exact spot.

## The warehouse mapping

Our memory is a physical warehouse. Each level of your walk is one coordinate:

| Level       | Warehouse meaning                                                        |
|-------------|--------------------------------------------------------------------------|
| PML4 (L1)   | **Row** (1–10)                                                            |
| PDPT (L2)   | **Shelf level** (bottom = 1 → top = 3)                                    |
| PD (L3)     | **Bay depth** (front = 1, back = 2)                                       |
| PT (L4)     | **Sub-section** of that bay's grate — 56 spoke-holes per grate, arranged as 8 sub-sections of 7 |
| OFFSET      | **Box number** inside that sub-section (the page frame)                   |

The value you decode at each level is the coordinate itself.

## Your goal

Resolve the VA and go to that exact box — one box in the whole warehouse is
yours. Inside it is a note. The note tells you the rest.

How you visit the warehouse depends on your event: in-person events use the
physical warehouse; remote players use the companion warehouse game. Ask your
facilitator which applies.

Flag format: `Flag{...}` — when the trail ends, wrap what you found.

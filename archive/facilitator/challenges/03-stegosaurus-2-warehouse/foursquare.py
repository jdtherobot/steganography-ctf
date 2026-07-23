#!/usr/bin/env python3
"""Four-square cipher — reference implementation for Challenge 3 (Stegosaurus 2).

Canonical Challenge-3 configuration (verified unique against the archived
plaintext; see WRITEUP.md and PROVENANCE.md):

  * ALL FOUR 5x5 squares are keyed — one corner word per square, exactly as
    the corner words are laid out on the physical warehouse note:
        top-left  = HONEY      top-right    = BADGER
        bottom-left = HECK     bottom-right = YEAH
    (The classic four-square keeps TL/BR as plain alphabets; this challenge
    does NOT. With only TR=BADGER / BL=HECK keyed, the ciphertext does not
    decode.)
  * Square construction: keyword letters first (deduplicated, in order),
    then the remaining letters of the 25-letter alphabet.
  * Alphabet: ABCDEFGHIKLMNOPQRSTUVWXYZ  (I/J merged; J maps to I).
  * Digraph rules (classic four-square):
      encrypt p1p2 : locate p1 in TL, p2 in BR;
                     c1 = TR[row(p1), col(p2)],  c2 = BL[row(p2), col(p1)]
      decrypt c1c2 : locate c1 in TR, c2 in BL;
                     p1 = TL[row(c1), col(c2)],  p2 = BR[row(c2), col(c1)]
  * Padding: odd-length plaintext is padded with a trailing 'Z'.

Stdlib only. Usage examples:
  python3 foursquare.py decrypt UPNAHLNSIBESOLTUEBUPDNEY
  python3 foursquare.py encrypt TOMHANKSAINTGOTSHITONME
  python3 foursquare.py grids
Keys default to the canonical HONEY/BADGER/HECK/YEAH; override with
--tl/--tr/--bl/--br (use the literal word "plain" for an unkeyed square).
"""

import argparse
import sys

ALPHABET = "ABCDEFGHIKLMNOPQRSTUVWXYZ"  # 25 letters, no J (I/J merged)
PAD = "Z"

CANONICAL_KEYS = {"tl": "HONEY", "tr": "BADGER", "bl": "HECK", "br": "YEAH"}


def normalize(text: str) -> str:
    """Uppercase, keep letters only, merge J into I."""
    return "".join("I" if c == "J" else c for c in text.upper() if c.isalpha())


def build_square(key: str | None) -> str:
    """25-char square: deduped keyword letters, then the rest of ALPHABET."""
    seen: set[str] = set()
    out: list[str] = []
    for ch in normalize(key or "") + ALPHABET:
        if ch not in seen:
            seen.add(ch)
            out.append(ch)
    assert len(out) == 25, f"bad square for key {key!r}"
    return "".join(out)


def _pos(square: str, ch: str) -> tuple[int, int]:
    i = square.index(ch)
    return i // 5, i % 5


def _pairs(text: str):
    if len(text) % 2:
        raise ValueError(f"digraph input must have even length, got {len(text)}")
    return zip(text[0::2], text[1::2])


def encrypt(plaintext: str, tl: str, tr: str, bl: str, br: str) -> str:
    pt = normalize(plaintext)
    if len(pt) % 2:
        pt += PAD
    out = []
    for p1, p2 in _pairs(pt):
        r1, c1 = _pos(tl, p1)
        r2, c2 = _pos(br, p2)
        out.append(tr[r1 * 5 + c2])
        out.append(bl[r2 * 5 + c1])
    return "".join(out)


def decrypt(ciphertext: str, tl: str, tr: str, bl: str, br: str) -> str:
    ct = normalize(ciphertext)
    out = []
    for c1, c2 in _pairs(ct):
        r1, c1col = _pos(tr, c1)
        r2, c2col = _pos(bl, c2)
        out.append(tl[r1 * 5 + c2col])
        out.append(br[r2 * 5 + c1col])
    return "".join(out)


def canonical_squares() -> dict[str, str]:
    return {corner: build_square(key) for corner, key in CANONICAL_KEYS.items()}


def format_grids(squares: dict[str, str]) -> str:
    lines = []
    for corner in ("tl", "tr", "bl", "br"):
        sq = squares[corner]
        key = CANONICAL_KEYS.get(corner, "?")
        lines.append(f"{corner.upper()} (key: {key})")
        for r in range(5):
            lines.append("  " + " ".join(sq[r * 5:(r + 1) * 5]))
    return "\n".join(lines)


def main(argv: list[str]) -> int:
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("mode", choices=["encrypt", "decrypt", "grids"])
    ap.add_argument("text", nargs="?", default="")
    for corner in ("tl", "tr", "bl", "br"):
        ap.add_argument(
            f"--{corner}",
            default=CANONICAL_KEYS[corner],
            help=f"key for the {corner.upper()} square "
                 f"(default {CANONICAL_KEYS[corner]}; 'plain' = unkeyed)",
        )
    args = ap.parse_args(argv)

    keys = {c: (None if getattr(args, c).lower() == "plain" else getattr(args, c))
            for c in ("tl", "tr", "bl", "br")}
    squares = {c: build_square(k) for c, k in keys.items()}

    if args.mode == "grids":
        print(format_grids(squares))
        return 0
    if not args.text:
        ap.error("text required for encrypt/decrypt")
    fn = encrypt if args.mode == "encrypt" else decrypt
    print(fn(args.text, squares["tl"], squares["tr"], squares["bl"], squares["br"]))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))

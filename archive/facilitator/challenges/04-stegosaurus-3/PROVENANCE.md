# Challenge 4 — Provenance (FACILITATOR ONLY)

The player-facing `Honey.jpeg` is a **corrected v3 carrier** rebuilt deterministically by
`rebuild.sh` from canonical inputs in `archive/main/Challenge 4v2/`. The archive is never modified.

## Canonical inputs accepted (from `archive/main/Challenge 4v2/`)

| File | SHA-256 | Role |
|---|---|---|
| `Honey_orig.jpeg` | `9b37e26110a3c20bbbcdb2a54e3221b71b42b99721fe27f2ccb6c376ea1f6b55` | cover base image |
| `inner.jpeg` | `4c9b30640d360ea49c54a74e75b483481948459b3a18b2c4e526dabce1172503` | QTABLE stego cover |
| `aeskey.bin` | `192d3b44b8e44787dfe62700e5a73869a2bf2a3c5646a6b83075121d82379fa2` | raw 32-byte AES key (re-embedded) |
| `iv.bin` | `aaeacb702bdff3a53b3bcb60a0d35e7ce9b1bd4a8a2390b4932322680710963b` | AES-CBC IV (public, in bundle) |
| `keyblock.txt` | `29b2f8c21eb4fd196632760cb86be03b6308673332468ebaf43df3de2d581560` | OLD creator XOR key (records 3,6,8) — used only to verify record derivation |
| `STEGO_KEY_386.txt` | `a30e8b38f41f153733acbd6092a0bc4e63f5f2ae540f0b06b69921e683d7ede0` | 201×24 records; player derives key via "386" |
| `passwords.enc` | `39e88a1cd2cd3a8949bd0c85e905d95fb2eea46ea5e97c05ffa21e58eabaed1c` | passwords encrypted with aeskey+iv (unchanged) |
| `payload.enc` | `0145bddfa18f840759e96bf33167f1ff2dc1e8d4803354c8b7c52660bde8429c` | real flag zip, strong-encrypted (unchanged) |
| `mid.zip` | `17ea009ec0a3e8f07ae7b482f8b2f32bac5336c626f0dd06889fbcc943ff4845` | red-herring zip (unchanged) |
| `decoy_random.enc` | `79c64dd738c612ef335ec229798f790020fd73d2c26cb60438f98b2ed9d929b7` | random decoy (unchanged) |

Also used from the archive: `qtbl.py` (player helper, shipped inside the bundle) and
`qtbl_stego.py` (creator embed helper, used at build time, never distributed).

## Produced artifact

- `participant/challenges/04-stegosaurus-3/Honey.jpeg` — v3 carrier,
  SHA-256 `daa452eca276b86fc6220b78cdb56d118d8175784c3033dd79f3a1b5936e19a3` (277,265 B).
  Rebuilt from the inputs above with the three fixes (see WRITEUP §"three authoring fixes").
  `nothingtoseehere.jpg` and `secret.enc` are regenerated at build time (new keyblock / new weak
  password), so their bytes differ from any archived copy by design.

## Rejected revisions

- **`archive/main/Challenge 4/Honey.jpeg` — REJECTED (dead).** Byte-identical to its own cover
  `archive/main/Challenge 4/Honey_orig.jpeg` (both SHA-256 `9b37e261…6b55`) → it carries no
  payload and cannot be solved. `Challenge 4v2/` is the canonical build.
- **`archive/main/Challenge 4 copy/` — REJECTED (working scratch).** A near-duplicate of v1 with
  extra recovered/decrypted files (`aeskey_rec.bin`, `passwords.dec`, `secret_bundle.ok.zip`);
  not a clean carrier.
- **Old `keyblock.txt` order (3,6,8) — REJECTED (clue mismatch).** Contradicts the `STEGO_KEY_386`
  filename; corrected to 3,8,6 in v3.
- **Old weak password `DesertStorm#82pLm` — REJECTED (uncrackable).** 0 rockyou hits; replaced with
  `desertstorm`.

## Verification

- Round-trip: `qtbl.py extract` with the "386"-derived key recovers `aeskey.bin` exactly.
- `solve_test.sh` reproduces `Flag{Y0u haVe EnCouNTeR3d a w!Ld s1eEP p@RA1y$!S DEm0n}` from the
  participant `Honey.jpeg` alone (`C4 PASS`).
- `build/secret-scan/scan.sh` PASS: no creator-only material (`pw.txt`, `keyblock.txt`,
  `aeskey.bin`, `passwords.txt`, `qtbl_stego.py`, `flag.txt`) in `participant/`.

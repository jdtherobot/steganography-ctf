# Facilitator — Admin Setup

Everything you need to **stand up, run, and reset** this four-challenge stego CTF.
This document is platform-neutral: it covers files, workstations, the physical (and
virtual) warehouse, dry runs, resets, timing, safety, and backups. It does **not**
prescribe a scoring platform, a website, or a hosting stack — plug the sanitized
`participant/` bundle into whatever delivery method your event already uses.

> **Boundary reminder.** This folder (`facilitator/`) is **private**. It holds
> flags, passwords, walkthroughs, and answer keys. Never hand `facilitator/`,
> `build/`, or the repo root to a player. Only the sanitized `../participant/`
> bundle is ever distributed, and only after the secret-scan gate passes (see
> [`../build/DIRECTORY_CONTRACT.md`](../build/DIRECTORY_CONTRACT.md)).

Companion documents:
- [`FACILITATOR_GUIDEBOOK.md`](FACILITATOR_GUIDEBOOK.md) — flags, checkpoints,
  hint ladders, and troubleshooting during the event.
- [`ACADEMIC_USE.md`](ACADEMIC_USE.md) — the authorization statement; keep a copy
  on hand.

---

## 1. What each challenge consists of

Each challenge has a **player-facing** side (distributed) and a **facilitator**
side (private answer key + build scripts). The private side lives in
`facilitator/challenges/NN/` (`WRITEUP.md`, `HINT_LADDER.md`, `PROVENANCE.md`,
`rebuild.sh`, `solve_test.sh`). The player-facing files are rebuilt from the
immutable archive by each challenge's `rebuild.sh` and land in
`participant/challenges/NN/`.

### What participants actually receive

| # | Title | Distributed to players | Notes |
|---|---|---|---|
| 1 | Photo Day lvl 2 | `email.eml` | Self-contained: the photo attachment and the "leaked" password are inside the email. |
| 2 | Stegosaurus 1 | `stego_badger.jpeg` (+ shipped trimmed wordlist, if you use it) | The passphrase is crackable with `rockyou` or the trimmed list. |
| 3 | Stegosaurus 2 (Warehouse) | The briefing (the virtual address puzzle) **plus** access to the warehouse — physical layout **or** the browser game | Needs a result recovered in Challenge 2. |
| 4 | Stegosaurus 3 | `Honey.jpeg` (+ shipped trimmed wordlist, if you use it) | Every later payload is carved out of this one file. |

### What players must NEVER receive (kept only in `facilitator/` / the archive)

- Any **flag** plaintext, any **answer-key** file (`Flag.txt`, `flag.txt`,
  `Flag 2.txt`).
- Creator-only key material: `keyblock.txt`, `aeskey.bin`, `iv.bin` (as a
  standalone), `pw.txt`, `passwords.txt`, `qtbl_stego.py` (the *documented*
  helper — players get the stripped `qtbl.py` **only** by cracking their way into
  it), `genstring.py`, `emailScript.txt`.
- The four-square **plaintext**, and the strong Challenge 4 payload password.

The pre-publish scanner enforces this. Before you distribute anything, run it (see
§8).

---

## 2. Build the distributable bundle

You build the player bundle once, from the immutable archive, then distribute the
resulting `participant/` folder.

```bash
cd <repo root>
export ARCHIVE_DIR="/Users/jdtherobot/Documents/GitHub/CTF Challenges/archive"
make build-challenges     # runs each facilitator/challenges/NN/rebuild.sh
make test-challenges      # solver tests assert every flag from the player files
make warehouse-game       # builds the static warehouse game
make scan-secrets         # PRE-PUBLISH GATE — must say: secret-scan: PASS
make verify-archive       # confirms the archive fingerprint is unchanged
```

Only after `make scan-secrets` reports **PASS** should you copy `participant/`
out for distribution. Distribute a **copy** — never share your working repo.

---

## 3. Room, workstations & prerequisites

### Workstation image

- **Recommended:** Kali Linux (VM or bare metal). Nearly the whole toolkit is
  preinstalled. Ubuntu/Debian, WSL2, or macOS + Homebrew also work.
- Give each player (or team) a shell with the tools from
  [`../participant/PLAYER_TOOLKIT.md`](../participant/PLAYER_TOOLKIT.md):
  ExifTool, OpenSSL, Binwalk, Steghide, a steghide cracker (Stegseek or
  StegCracker), `file`, `dd`, `xxd`, zip/unzip, Python 3, and a wordlist
  (`rockyou`).
- Offline is fine and preferred. The only thing that may need the network is the
  initial tool install and (optionally) downloading `rockyou`. Pre-image the box
  so players don't need the internet during play.

### Pre-event tool check (run on each workstation image)

```bash
for t in exiftool openssl binwalk steghide file dd xxd zip unzip python3; do
  command -v "$t" >/dev/null 2>&1 && echo "ok   $t" || echo "MISSING  $t"
done
command -v stegseek >/dev/null || command -v stegcracker >/dev/null \
  && echo "ok   cracker" || echo "MISSING  cracker"
ls /usr/share/wordlists/rockyou.txt.gz 2>/dev/null && echo "ok   rockyou" || echo "note: provide a wordlist"
```

Fix any `MISSING` line before the event. Note that on macOS/Apple-Silicon build
machines, `steghide` and `stegseek` are easiest via a Debian container — but on a
**Kali player image they're native**, so players don't need Docker.

### File distribution

- Put each challenge's distributed file(s) in a clearly named folder
  (`01-photo-day/`, `02-stegosaurus-1/`, …) mirroring
  `participant/challenges/NN/`, plus the shared `PLAYER_TOOLKIT.md` and the
  warehouse game.
- Distribute read-only copies (shared drive, USB, per-seat folder, or your usual
  delivery channel). Players should copy files into a personal scratch directory
  before working, so the master stays clean.
- Keep the wordlist out of the "answers" mental model: `password123` and
  `desertstorm` are *supposed* to be crackable, and they appear only inside the
  shipped trimmed wordlist (or `rockyou`). That's by design, not a leak.

---

## 4. The warehouse (Challenge 3) — physical setup

Challenge 3 resolves the virtual address `0x0000_0100_4040_1005` through a 4-level
page-table walk to a **physical location** in a "memory warehouse," where players
find a note. The mapping (facilitator eyes only):

- **Resolved location:** row **2** / shelf **1** / bay **2** / sub-section **1** /
  box **5** (i.e., L1→row 2, L2→shelf 1, L3→bay 2, L4→sub-section 1, offset→box 5).
- **The note placed at that box** reads:
  - Top-left: **Honey** · Top-right: **Badger**
  - Center: **dCode ▢ ▢ ▢ ▢**
  - Below center: **Line #9**
  - Bottom-left: **Heck** · Bottom-right: **Yeah**

Those four corner words are the four-square cipher keywords; "Line #9" points at
line 9 of the Challenge 2 payload. (Full solve in
[`challenges/03-stegosaurus-2-warehouse/WRITEUP.md`](challenges/03-stegosaurus-2-warehouse/WRITEUP.md).)

**To build the physical version:**

1. Create a shelving layout that plausibly maps to *rows → shelves → bays →
   sub-sections → boxes*. It doesn't need to be huge; it needs to be
   *navigable* and consistent with the mapping above. A labeled bookshelf, a set
   of numbered bins, or a printed grid on a wall all work.
2. Print the note asset (from the challenge's game/asset folder) and place it at
   the resolved box (**row 2 / shelf 1 / bay 2 / sub-section 1 / box 5**).
3. Optionally seed one or two **decoy notes** at wrong locations so a mis-walked
   address doesn't accidentally succeed. Keep decoys obviously "not it" (blank,
   or a joke), never a partial answer.
4. Post the puzzle introduction (the MMU / page-table-walk prompt) where players
   start.

Keep the mapping key and the note plaintext with you, not on the shelves.

---

## 5. The warehouse (Challenge 3) — remote / browser alternative

If you can't build a physical warehouse, or you're running the event remotely,
use the **browser warehouse game**. It simulates the same navigation: players walk
the resolved location and find the same note.

- **Local:** serve `../participant/warehouse-game/` (open its `index.html`, or
  serve the folder with any static file server) and give players the address.
- **Hosted:** the deployed build lives at <https://britt.gg/ctf/warehouse/>.

Either way, the *puzzle* is unchanged — only the medium differs. Decide up front
which one you're running so your hints match (a physical hint like "check the
second row" should map cleanly to the game's navigation, and vice-versa). You can
also run **both**: physical for on-site players, the game for anyone remote.

---

## 6. Facilitator dry runs

Do a full dry run **before** the event, on a clean workstation image, using only
the files players will have:

1. Solve all four challenges end-to-end yourself, from the distributed files
   only. Confirm each flag matches the guidebook's table.
2. For an automated sanity check, run `make test-challenges` — every
   `solve_test.sh` solves from the participant distribution and asserts the exact
   flag. A green run means the bundle is internally consistent.
3. Walk the warehouse (physical and/or game) as a player would: resolve the
   address, find the note, decode the cipher.
4. Time yourself and note where you hesitated — those are the spots players will
   need hints (see the guidebook's hint ladders).

If a dry-run solve fails, fix the **build**, not the test — rebuild from the
archive and re-scan. Never patch a distributed file by hand.

---

## 7. Timing, difficulty & sequencing

- **Suggested order:** 1 → 2 → 3 → 4. Difficulty ramps, and Challenge 3 depends on
  a result recovered in Challenge 2 (so 2 must come before 3). Challenge 4 is
  self-contained and can be attempted any time after players are warmed up.
- **Rough time budget** (varies widely with experience):
  - C1 Photo Day: 15–40 min.
  - C2 Stegosaurus 1: 20–60 min (mostly cracking time).
  - C3 Warehouse: 30–90 min (the page-table walk + cipher is the "for the nerds"
    challenge).
  - C4 Stegosaurus 3: 60–150 min (multi-stage; the "386" step is the wall — see
    the guidebook).
- Gate Challenge 3 behind Challenge 2 if your delivery method supports
  prerequisites; otherwise tell players plainly to do 2 first.
- Budget staff time for **C3 warehouse supervision** and **C4 hint delivery** —
  those two consume the most facilitator attention.

---

## 8. Reset procedures

Between sessions or cohorts:

1. **Player files:** wipe each player's scratch directory and re-copy clean
   masters. Because the challenge files are static and stateless, "reset" is just
   "restore the original files."
2. **Rebuild from source if in doubt:** `make build-challenges && make scan-secrets`
   regenerates the whole bundle deterministically from the archive and re-proves
   no secrets leaked. Use this if any master file might have been altered.
3. **Physical warehouse:** collect and re-file the note(s); verify the note is at
   **row 2 / shelf 1 / bay 2 / sub-section 1 / box 5** and any decoys are back in
   place.
4. **Browser game:** it's stateless — just reload. If you host it, confirm the URL
   still serves.
5. **Confirm the archive is untouched:** `make verify-archive` should report the
   fingerprint unchanged
   (`1f90c817321e8b584154abde4ae1b45d76d67997917e8edad78f9465415a4781`).

---

## 9. Safety & scope

- Keep the [`ACADEMIC_USE.md`](ACADEMIC_USE.md) statement visible. This is an
  authorized, self-contained exercise; all targets are supplied local files.
- Make clear to players that the cracking/carving techniques are for **these
  planted secrets only** — not for any real system, account, or third-party file.
- Nothing in the exercise requires network access to a live service. If a player
  claims they need to reach a remote host, they've wandered off the intended path;
  redirect them.
- The humor in the flags and story is intentionally silly and PG-13 — preview it
  and confirm it fits your audience before the event.

---

## 10. Backups

- **Master copies:** keep an offline, read-only backup of the built
  `participant/` bundle *and* the private `facilitator/` folder. If a workstation
  eats a file mid-event, you restore from the master, not from a player's copy.
- **The archive is the source of truth.** As long as
  `ARCHIVE_DIR` is intact (fingerprint above), you can rebuild the entire bundle
  from scratch with `make build-challenges`. Back the archive up too, separately.
- **Print backups for the warehouse:** keep a couple of spare printed note assets
  and a printed copy of the resolved-location mapping in your facilitator kit.

---

## 11. Presenting clues without spoiling later stages

- **Lead with the story.** Each `BRIEF.md` already contains the in-world clues
  (the "leaked" password gag, the warehouse note, the filename hints). Point
  players back to the briefing before you give a real hint.
- **Release hints in stages.** Use the per-challenge ladders in
  [`FACILITATOR_GUIDEBOOK.md`](FACILITATOR_GUIDEBOOK.md) (which link each
  challenge's `HINT_LADDER.md`). Give the *next* rung only, never a rung two ahead.
- **Never reveal a downstream stage.** In particular:
  - For C3, don't mention the four-square cipher or "line 9" until the player has
    actually resolved the address and found the note.
  - For C4, don't mention the "386" record trick, the inner JPEG, or the
    quantization-table key until the player has cracked the outer bundle and is
    holding `STEGO_KEY_386.txt`. Revealing it early collapses the whole challenge.
- **Keep answer material off the floor.** Flags, passwords, the four-square
  plaintext, and the keyblock stay in this folder and in your head — not on a
  whiteboard, a shared screen, or a sticky note.

# Stego CTF — Player Handbook

Welcome, analyst. You've been handed a small stack of intercepted files and a
puzzle warehouse. Somewhere inside each one is a hidden flag. Your job is to pull
it out.

This is a **steganography and cryptography capture-the-flag** built around four
self-contained challenges. It rewards curiosity, patience, and a willingness to
read a file byte-by-byte when it refuses to give up its secret. No prior CTF
experience is required — just the toolkit listed in
[`PLAYER_TOOLKIT.md`](PLAYER_TOOLKIT.md) and a habit of asking "what *else* is in
this file?"

---

## Academic-use note (read me first)

This is an **authorized, academic exercise** created and owned by the event
author. It exists to teach steganography, cryptography, file analysis, metadata
inspection, data carving, and a little computer architecture — in a controlled,
consent-based setting.

- Everything you need is a **local file** supplied with this bundle (plus an
  optional warehouse game). Nothing here asks you to touch a third-party system,
  a live service, someone else's account, or any real security control.
- The tools you'll use (ExifTool, OpenSSL, Binwalk, Steghide/Stegseek, and
  standard Linux forensics utilities) are being used for their ordinary
  educational and forensic purposes.
- Any password cracking is limited to the **deliberately weak, planted secrets**
  in these challenge files and the wordlists shipped with the exercise. Do not
  point these techniques at anything you were not given here.

Play locally, have fun, and keep it inside the sandbox.

---

## The four challenges

Work through them roughly in order — the difficulty ramps, and a couple of them
reference each other.

| # | Title | What you're up against |
|---|---|---|
| 1 | **Photo Day lvl 2** | An intercepted email with a photo attachment; metadata + basic crypto. |
| 2 | **Stegosaurus 1** | A hidden message inside an image; a password stands between you and it. |
| 3 | **Stegosaurus 2 (Warehouse)** | A computer-architecture puzzle: resolve an address to a physical location, then decode a cipher. A browser warehouse game accompanies it. |
| 4 | **Stegosaurus 3** | One JPEG, many secrets: carve, crack, and dig through nested payloads. |

Each challenge has its own briefing with the story, the files you get, and the
in-world clues:

- [`challenges/01-photo-day/BRIEF.md`](challenges/01-photo-day/BRIEF.md)
- [`challenges/02-stegosaurus-1/BRIEF.md`](challenges/02-stegosaurus-1/BRIEF.md)
- [`challenges/03-stegosaurus-2-warehouse/BRIEF.md`](challenges/03-stegosaurus-2-warehouse/BRIEF.md)
- [`challenges/04-stegosaurus-3/BRIEF.md`](challenges/04-stegosaurus-3/BRIEF.md)

> **Order matters for #3.** Challenge 3 needs something you'll uncover while
> solving Challenge 2, so tackle 2 before 3. Challenge 4 stands on its own but
> shares the same mischievous sense of humor as the rest.

---

## The warehouse game

Challenge 3 sends you into a memory warehouse. There's a playable browser version
you can walk through instead of (or alongside) a physical setup:

- **Locally:** open [`warehouse-game/`](warehouse-game/) (start at its
  `index.html`).
- **Online:** <https://britt.gg/ctf/warehouse/>

Your facilitator will tell you which one you're using.

---

## Getting started

1. **Set up your toolkit.** Open [`PLAYER_TOOLKIT.md`](PLAYER_TOOLKIT.md) and run
   the one-line "is it installed?" check for each tool. Install anything that's
   missing before you start. A Kali Linux box (or any Linux/WSL/macOS shell) has
   nearly all of it already.
2. **Copy the challenge files somewhere you can work.** Make a scratch folder per
   challenge and copy the distributed files into it, so you always have a clean
   original to fall back to.
3. **Read the briefing** for the challenge you're attacking
   (`challenges/NN/BRIEF.md`). The story usually *is* the hint.
4. **Poke at the file.** Identify what it really is, look at its metadata, and ask
   what might be hidden inside. Then follow the trail.

---

## Rules & conventions

- **Work locally.** Every challenge is solvable entirely offline with the files
  you were given and the tools in the toolkit. You never need to attack a remote
  host, and you shouldn't.
- **Flags look like `Flag{...}`.** When you find one, that whole string —
  including the `Flag{` and `}` — is the answer. Submit it exactly as it appears,
  respecting capitalization, spaces, and symbols.
- **Keep an original copy** of each file. Steganography work is destructive to
  the unwary; carving and extraction go a lot smoother when you can start over.
- **In-story clues are fair game.** If a file's contents, an email body, or a
  note in the warehouse seems to be *telling* you something — a password, a line
  number, a keyword — that's intentional. Use it.
- **Don't brute-force the flag format.** Guessing `Flag{...}` strings isn't the
  game; recovering them from the files is.
- **Stuck?** Ask your facilitator for a hint. Hints are released in stages so you
  get just enough of a nudge without spoiling the solve.

---

## Where to go next

- **[`PLAYER_TOOLKIT.md`](PLAYER_TOOLKIT.md)** — the environment checklist and
  install checks. Do this first.
- **Each `challenges/NN/BRIEF.md`** — the per-challenge briefings linked above.

Good hunting. Rock on. 🦡

# Steganography CTF — Player Guide

A four-challenge capture-the-flag covering steganography, cryptography, file
carving, metadata forensics, and a little computer architecture. Everything is
solvable offline with the files in this folder and a standard forensics toolkit.

## Before you start

- This is an authorized, self-contained exercise. Everything you need is a local
  file supplied here (plus, for the Warehouse, a companion game your facilitator
  will point you to). Nothing here asks you to touch a third-party system, a live
  service, or a real account. Any password cracking applies only to the
  deliberately weak, planted secrets in these files.
- **Bring a standard Linux file-forensics environment** (Kali is ideal). Part of
  each challenge is working out *which* tools fit what you were handed.
- **Keep an untouched original** of every file and work on copies; carving and
  extraction are unforgiving.

## The challenges

| # | Title | What you'll do |
|---|---|---|
| 1 | **Steganography lvl 1** | Read an intercepted email and recover a flag hidden in a photo's metadata. |
| 2 | **Steganography lvl 2** | Crack a passphrase and extract a file hidden inside an image. |
| 3 | **Steganography lvl 3** | Take apart one JPEG that's hiding far more than it shows. |
| 4 | **Computer Architecture Warehouse** | Walk a virtual address through the page tables to a physical box, then read the note you find. |

**Order matters for the Warehouse.** Challenge 4 uses something you recover while
solving Challenge 2, so do **lvl 2 before the Warehouse**. The rest stand on their own.

## Flags & rules

- Flags look like `Flag{...}`. Submit the whole string exactly — capitalization,
  spaces, and symbols all matter.
- **Work locally.** Every challenge is solvable offline with the files you were given.
- **In-story clues are fair game.** If an email body, a file, or a note seems to be
  *telling* you something — a password, a line number, a keyword — that's intentional.
- **Don't brute-force the flag format.** Recover flags from the files, not by guessing.
- **Stuck?** Some challenges include optional hints in a `hints/` folder, and your
  facilitator can give you more.

Good hunting.

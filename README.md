# Steganography CTF

A four-challenge capture-the-flag covering steganography, cryptography, file carving,
metadata forensics, and a little computer architecture. I created and own every challenge,
image, payload, password, and flag here, and everything runs on supplied local files.

> ### ⚠️ Spoilers
> - **Playing?** Stay in [`participant/`](participant/) — nothing there spoils anything.
> - **Running the event?** [`facilitator/`](facilitator/) has every flag, password, and full walkthrough.

## The two folders

| Folder | Who it's for | What's in it |
|---|---|---|
| **[`participant/`](participant/)** | Players | The challenge files, a spoiler-free brief per challenge, and optional hints. **Hand this folder to participants as-is.** |
| **[`facilitator/`](facilitator/)** | Whoever runs it | Flags, full walkthroughs (my setup + solve steps), the printable warehouse note, per-challenge solver tests, a tool checklist, and run-day logistics. |

## The challenges

| # | Title | What you'll do | Depends on |
|---|---|---|---|
| 1 | **Steganography lvl 1** | Recover a flag encrypted in a photo's EXIF metadata; the password is leaked in the email. | — |
| 2 | **Steganography lvl 2** | Crack a steghide passphrase and extract the hidden document. | — |
| 3 | **Steganography lvl 3** | Carve one JPEG into stacked payloads, reason out a password, and peel back the encryption. | — |
| 4 | **Computer Architecture Warehouse** | Walk a virtual address through the page tables to a physical box, then break a four-square cipher. | lvl 2 |

The Warehouse's cipher input is **line 9 of the document you recover in lvl 2**, so
**solve lvl 2 before the Warehouse.**

## Companion

- **[WRITEUP.md](WRITEUP.md)** — the full illustrated writeup, all four challenges end to end *(spoilers)*.
- **[jd-ctf-environment](https://github.com/jdtherobot/jd-ctf-environment)** — the runnable
  environment: an in-browser lab and the playable warehouse game.

## Academic use

An authorized, self-contained educational exercise operating only on supplied local files. It
does not touch third-party systems, live services, or real credentials; password recovery
applies solely to deliberately planted CTF secrets using standard, publicly available wordlists.

# Challenge 2 — Stegosaurus 1

**Category:** Steganography
**Difficulty:** Easy
**Flag format:** `Flag{...}`

---

## Briefing

The honey badger is back — and this time it isn't hiding *behind* a message, it's
hiding something *inside* a picture.

You've recovered a single souvenir from the badger's den:

```
stego_badger.jpeg
```

It looks like an ordinary photo. It opens fine, it's the right size, the metadata
is boring. But the badger doesn't keep ordinary photos. Somewhere in those pixels
a payload is stashed, and the first line of that payload is your flag.

Your job: pull the hidden data back out of the image and read the flag.

## What you have

- `stego_badger.jpeg` — the carrier image (everything you need is in here)

## Objective

Recover the hidden document embedded in `stego_badger.jpeg` and submit the flag on
its first line (it looks like `Flag{...}`).

## The badger's note

Scrawled on the back of the photo, in the badger's own claw-writing:

> ***"WE WILL, WE WILL…"***

The badger swears it's the most important part. Hum the rest of the line — it's
telling you exactly which list to throw at the lock.

---

*Hints are available from your facilitator if you get stuck. Try to earn the flag
before asking — the note above is a bigger clue than it looks.*

# Challenge 2 — Stegosaurus 1 — Hint Ladder (FACILITATOR ONLY)

Staged hints, cheapest first. Hand them out one at a time; each one should cost the
player something (time, points) so they try before they ask. The final rung gives
the answer outright — only for a fully stuck player.

---

### Hint 0 — nudge (free, restates the brief)
The whole flag is *inside* the image file, not next to it. The picture opens
normally on purpose. "Stegosaurus" = **stego**graphy. Something is embedded.

### Hint 1 — the technique
This isn't metadata (EXIF) and it isn't appended junk you can just `strings` out.
The data was **embedded with a steganography tool that hides a whole file inside a
JPEG behind a passphrase**. On Linux the classic tool for this is **`steghide`**;
`steghide info stego_badger.jpeg` will confirm it detects embedded data.

### Hint 2 — you need a passphrase, and you can guess it
`steghide` won't extract without the passphrase — but the passphrase is a weak,
common one. This is a **cracking** challenge: throw a password **wordlist** at it.
The purpose-built cracker is **`stegseek`** (much faster than looping `steghide`):
```bash
stegseek --crack stego_badger.jpeg <wordlist> out.txt
```

### Hint 3 — which wordlist? (decode the badger's note)
Re-read the note in the brief: **"WE WILL, WE WILL…"**. Finish the lyric —
*"We will, we will **ROCK YOU**."* That's the classic **`rockyou.txt`** wordlist.
Point `stegseek` at rockyou (or the trimmed wordlist you were given) and let it run.

### Hint 4 — where the flag is
When it cracks, `stegseek` extracts a text file. **The flag is line 1.** Keep the
*whole* file though — there's more going on in it than the flag (relevant later).

### Hint 5 — the answer (last resort)
- Passphrase: **`password123`** (an early `rockyou` entry).
- Extract directly:
  ```bash
  steghide extract -sf stego_badger.jpeg -p password123 -xf out.txt
  head -n1 out.txt
  ```
- Flag: **`Flag{DanG 7hat'S @ cUTe HOnEY b@D9eR}`**

---

**Facilitator note (do NOT read aloud):** the extracted payload's **line 9**
(`UPNAHLNSIBESOLTUEBUPDNEY`) is the Challenge 3 four-square ciphertext, planted here
on purpose. If a player notices "weird strings" below the flag, that's a *good*
sign — but don't confirm the C3 link or hand over the plaintext. Let C3 stand on
its own.

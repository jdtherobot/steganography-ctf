# Challenge 1 — Photo Day (lvl 2) — Hint Ladder

Staged hints for facilitators. Give one at a time, lowest first; each hint
assumes the player has the previous ones. Hint 4 is nearly the solution —
hold it until a player is truly stuck.

## Hint 1 — gentle nudge (read the intercept)

> Treat the email like evidence, not scenery. Read every word Pete wrote —
> he protests a little too much about one thing — and remember an email is
> more than its visible text: it *carries* things.

(Gets the player to notice "Definitely not the password: honeybadger4lyfe"
and to pull out the attachment instead of only skimming the body.)

## Hint 2 — the photo is more than pixels

> You extracted the badger photo? Good. The secret isn't in how it looks —
> it's in what the file *says about itself*. Photos carry metadata; this one
> is carrying more than shutter speeds. List all of it and look for a field
> that doesn't belong.

(Points at EXIF inspection — `exiftool badger_photo.jpeg` — where the odd
`Comment` tag full of base64 stands out.)

## Hint 3 — name that blob

> That strange comment is base64. Decode it and look at the first eight
> bytes: `Salted__`. That's the signature of one very common command-line
> encryption tool's output. Pete's email signature even brags about which
> cipher his squadron flies with — and he already handed you the key, back
> when he swore it wasn't one.

(Player should now connect: OpenSSL salted format + "256 Air Expeditionary
Squadron (256 AES)" → `openssl enc -aes-256-cbc`, password
`honeybadger4lyfe` from the body.)

## Hint 4 — near-solution (exact recipe)

> Pull the comment and feed it back through OpenSSL — AES-256-CBC, base64
> input, PBKDF2 key derivation (that flag matters: without `-pbkdf2` you'll
> get `bad decrypt` even with the right password):
>
> ```bash
> exiftool -Comment -b badger_photo.jpeg > c.b64
> openssl enc -aes-256-cbc -d -pbkdf2 -a -in c.b64 -k <the password Pete "didn't" send>
> ```
>
> The password is exactly as written in the email body — all lowercase, no
> punctuation.

(Everything but the final string. The output is the flag, submitted verbatim.)

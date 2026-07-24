# Wordlist

**This is a modified `rockyou.txt`, trimmed specifically for this repository.** The real RockYou
list is ~140 MB, which exceeds GitHub's 100 MB per-file limit, so the copy here is **capped just
under 100 MB**. It keeps the most-common entries — including `password123`, the Steganography lvl 2
passphrase — so the intended `stegcracker`/`stegseek` crack still works offline against the files in
this repo.

For the unmodified list, use the full `rockyou.txt` (on Kali: `/usr/share/wordlists/rockyou.txt.gz`).

> **Lab note (planned):** the runnable lab
> ([jd-ctf-environment](https://github.com/jdtherobot/jd-ctf-environment)) will ship the *full*,
> unmodified `rockyou.txt` alongside the other standard Kali wordlists, so players get the authentic
> experience of picking a wordlist themselves rather than being handed one.

#!/usr/bin/env python3
"""Challenge 1 (Photo Day lvl 2) — fixed, deterministic email generator.

Repaired reproducer for the archived creator script
`ARCHIVE_DIR/main/Challenge 1/emailScript.txt`. Two defects are fixed here:

1. **Apostrophe bug (the reason this file exists).** One revision of the
   creator settings rendered the body password as `honeybadger4l'yfe`; the
   apostrophe was a shell single-quoting artifact, and the working encryption
   password never contained it. This generator pins a single PASSWORD constant
   (no apostrophe) used for the body text, so body clue == working password ==
   `honeybadger4lyfe` by construction.
2. **Non-determinism.** The shell script stamped `Date: $(date -R)`, so every
   run produced different bytes. The Date header is pinned to the canonical
   value below; given the canonical attachment, the output is byte-identical
   to the archived `email.eml` (SHA-256 366b8767...ab7b) on every run.

The attachment is NOT rebuilt here: the encrypted flag lives in the JPEG's
EXIF Comment tag, and re-running `openssl enc` would pick a fresh random salt
and change the ciphertext. The canonical working attachment
(`badger_photo.jpeg`, SHA-256 01c388e8...c859 — `badger_photo_orig.jpg` plus
`exiftool -Comment="<base64 openssl blob>"`) is read from the archive and
embedded verbatim, keeping the ciphertext byte-identical.

Usage (from the stego-ctf repo root):
    export ARCHIVE_DIR="/path/to/CTF Challenges/archive"   # or: source build/config.sh
    python3 facilitator/challenges/01-photo-day/email_gen.py \
        --out build/scratch/c1/email_regen.eml

The generator always self-checks its output end-to-end (extract attachment ->
exiftool Comment -> openssl decrypt -> assert flag) and exits non-zero if the
regenerated email does not solve. Requires: python3, exiftool, openssl.
"""

import argparse
import base64
import email
import email.policy
import hashlib
import os
import subprocess
import sys
import tempfile

# --- pinned settings (creator-only; keep in sync with WRITEUP.md) -----------
FROM_ = "Secretary of Watermelon <Peter@military.signal>"
TO = "Mr. Tema <team@military.signal>"
SUBJECT = "Photo Message!"
DATE = "Sun, 28 Sep 2025 15:20:17 +0300"  # pinned (canonical); was `date -R`
BOUNDARY = "----ctf-boundary-001"
PASSWORD = "honeybadger4lyfe"  # NO apostrophe — the single source of truth
EXPECTED_FLAG = "Flag{H0NeyB4d6er10OKinG0OD!!!}"
CANONICAL_EML_SHA256 = "366b8767f647cd5df0ded2384e9e0feaa61b7cc4279b822be4679c660a20ab7b"
CANONICAL_PHOTO_SHA256 = "01c388e88a17f3b9bc4c75aa56608d749ce10bf28fc525b624e8787770c6c859"
# ---------------------------------------------------------------------------

# Body reproduced byte-for-byte from the canonical email. Note the two
# intentional oddities preserved from the original compose: a U+2019 curly
# apostrophe in "he's", and two U+2028 LINE SEPARATOR characters after
# "Anywho." (a copy-paste artifact in the original body text).
BODY = (
    "Hi Mr. Tem,\n"
    "\n"
    "Heres that secret photo I was telling you about. Some nerd from the "
    "intelligence agency showed me how to do this - now we can send whatever "
    "we want in Signal!  Below is the password. I mean uhh.. totally not the "
    "password ;)\n"
    "\n"
    "On an unrelated note, my doctor keeps telling me I should stop trying to "
    "make my brain stronger by hitting it with a hammer, but I think "
    "he\u2019s a dummy.  My brains like twice as big as his probably.  "
    "Anywho.\u2028\u2028Definitely not the password: " + PASSWORD + "\n"
    "\n"
    "Rock on,\n"
    "\n"
    "Pete\n"
    "256 Air Expeditionary Squadron (256 AES)\n"
    "\n"
    "\n"
    "I am legally required to say that this is not a Signal sponsored message.\n"
)


def b64_wrap64(data: bytes) -> str:
    """Base64-encode with 64-column wrapping (matches `openssl base64`)."""
    enc = base64.b64encode(data).decode("ascii")
    return "\n".join(enc[i : i + 64] for i in range(0, len(enc), 64))


def build_eml(photo_path: str) -> bytes:
    with open(photo_path, "rb") as f:
        img = f.read()
    name = os.path.basename(photo_path)
    eml = (
        f"From: {FROM_}\n"
        f"To: {TO}\n"
        f"Subject: {SUBJECT}\n"
        f"Date: {DATE}\n"
        "MIME-Version: 1.0\n"
        f'Content-Type: multipart/mixed; boundary="{BOUNDARY}"\n'
        "\n"
        f"--{BOUNDARY}\n"
        "Content-Type: text/plain; charset=UTF-8\n"
        "\n"
        f"{BODY}"
        "\n"
        f"--{BOUNDARY}\n"
        f'Content-Type: image/jpeg; name="{name}"\n'
        "Content-Transfer-Encoding: base64\n"
        f'Content-Disposition: attachment; filename="{name}"\n'
        "\n"
        f"{b64_wrap64(img)}\n"
        f"--{BOUNDARY}--\n"
    )
    return eml.encode("utf-8")


def selfcheck(eml_bytes: bytes) -> None:
    """Solve the generated email exactly the way a player would; die loudly if it fails."""
    msg = email.message_from_bytes(eml_bytes, policy=email.policy.default)

    body = attachment = None
    for part in msg.walk():
        if part.get_content_type() == "text/plain" and body is None:
            body = part.get_content()
        elif part.get_content_type() == "image/jpeg" and attachment is None:
            attachment = part.get_payload(decode=True)
    if body is None or attachment is None:
        sys.exit("selfcheck FAIL: body or image/jpeg attachment missing")

    if PASSWORD not in body:
        sys.exit("selfcheck FAIL: body does not contain the working password")
    for bad in ("honeybadger4l'yfe", "honeybadger4l’yfe"):
        if bad in body:
            sys.exit("selfcheck FAIL: apostrophe-form password leaked into body")

    with tempfile.TemporaryDirectory() as td:
        jpg = os.path.join(td, "attachment.jpeg")
        with open(jpg, "wb") as f:
            f.write(attachment)
        comment = subprocess.run(
            ["exiftool", "-Comment", "-b", jpg],
            capture_output=True, check=True,
        ).stdout
        if not comment.strip():
            sys.exit("selfcheck FAIL: attachment has no EXIF Comment")
        dec = subprocess.run(
            ["openssl", "enc", "-aes-256-cbc", "-d", "-pbkdf2", "-k", PASSWORD, "-a"],
            input=comment.strip() + b"\n",
            capture_output=True,
        )
        if dec.returncode != 0:
            sys.exit(f"selfcheck FAIL: openssl decrypt error: {dec.stderr.decode()}")
        flag = dec.stdout.decode("utf-8").rstrip("\n")
    if flag != EXPECTED_FLAG:
        sys.exit(f"selfcheck FAIL: decrypted {flag!r}, expected {EXPECTED_FLAG!r}")
    print(f"selfcheck PASS: regenerated email solves to {EXPECTED_FLAG}")


def main() -> None:
    default_photo = None
    if os.environ.get("ARCHIVE_DIR"):
        default_photo = os.path.join(
            os.environ["ARCHIVE_DIR"], "main", "Challenge 1", "badger_photo.jpeg"
        )
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument(
        "--photo",
        default=default_photo,
        required=default_photo is None,
        help="working attachment JPEG (default: $ARCHIVE_DIR/main/Challenge 1/badger_photo.jpeg)",
    )
    ap.add_argument("--out", default="email_regen.eml", help="output .eml path")
    args = ap.parse_args()

    if not os.path.isfile(args.photo):
        sys.exit(f"photo not found: {args.photo}")
    photo_sha = hashlib.sha256(open(args.photo, "rb").read()).hexdigest()
    if photo_sha != CANONICAL_PHOTO_SHA256:
        print(f"WARNING: photo SHA-256 {photo_sha} is not the canonical working attachment", file=sys.stderr)

    eml = build_eml(args.photo)
    os.makedirs(os.path.dirname(os.path.abspath(args.out)), exist_ok=True)
    with open(args.out, "wb") as f:
        f.write(eml)

    sha = hashlib.sha256(eml).hexdigest()
    print(f"wrote {args.out} ({len(eml)} bytes)")
    print(f"SHA-256: {sha}")
    print(
        "byte-identical to canonical archived email.eml: "
        + ("YES" if sha == CANONICAL_EML_SHA256 else "no (expected when --photo is non-canonical)")
    )
    selfcheck(eml)


if __name__ == "__main__":
    main()

# Deploy — GitHub Pages (guide + challenges)

Publishes the **public, spoiler-free** bundle to `britt.gg/ctf/`. Pure static, `$0`,
no special headers required.

## Build the bundle

```bash
cd /Users/jdtherobot/Documents/GitHub/stego-ctf
bash deploy/pages/build.sh
# -> deploy/pages/dist/   (regenerable; gitignored)
```

`build.sh` **refuses to build unless `make scan-secrets` passes**, then assembles `dist/` from
`participant/` only: the landing `index.html`, the challenge briefs + downloadable files, and
the player docs (Markdown rendered to static `.html`, `.nojekyll` so no host reprocesses them).
It scans the assembled bundle again as a second gate.

## Publish to britt.gg/ctf/

Your site is served by `github.com/jdtherobot/jdtherobot.github.io` (GitHub Pages). To publish:

1. In that repo, create a `ctf/` directory.
2. Copy the **contents** of `deploy/pages/dist/` into `ctf/`:
   ```bash
   rsync -a --delete deploy/pages/dist/ /path/to/jdtherobot.github.io/ctf/
   ```
3. Commit + push that repo. Pages serves it at `https://britt.gg/ctf/`.

(Everything is relative-linked, so the bundle also works from any subpath or from a different
static host unchanged.)

## What is NOT published here

The **browser lab** and the **warehouse game** live in the
[`jd-ctf-environment`](https://github.com/jdtherobot/jd-ctf-environment) repo and are deployed
separately. Nothing from `facilitator/` or any creator-only file is ever included — the
secret-scan gate enforces this on every build.

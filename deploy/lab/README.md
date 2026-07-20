# Deploy — Browser lab (header-capable host)

The in-browser lab lives in `browser-lab/`. **How it must be hosted depends on the engine chosen
in `browser-lab/ENGINE_DECISION.md`:**

## If the lab uses v86 (pure-JS x86 emulator)
No special headers are needed. Host it exactly like the guide — copy the lab's static output into
your Pages repo under e.g. `ctf/lab/`, served at `britt.gg/ctf/lab/`. `$0`, same as the guide.
The `_headers` file here is unused in this case.

## If the lab uses CheerpX / WebVM
CheerpX needs `SharedArrayBuffer`, which requires cross-origin-isolation headers that **GitHub
Pages cannot set**. Two options:

1. **Cloudflare Pages (recommended for CheerpX)** — free, header-capable.
   - Deploy the lab as its own Cloudflare Pages project; the `_headers` file in this directory sets
     `Cross-Origin-Opener-Policy: same-origin` + `Cross-Origin-Embedder-Policy: require-corp`.
   - Point a subdomain (e.g. `lab.britt.gg`) at it via CNAME; keep `britt.gg` on GitHub Pages.
   - Net cost stays within the existing domain (`~$0`).

2. **`coi-serviceworker` shim on GitHub Pages** — no second host, but weaker (one-reload behavior,
   weaker Safari story). Add `coi-serviceworker.js` (MIT, from
   https://github.com/gzuidhof/coi-serviceworker) next to the lab's `index.html` and register it
   first; it synthesizes the isolation headers client-side. Use only if a second host is undesirable.

## Load budget
Whichever engine, record the measured cold-load time + image size in
`facilitator/VALIDATION_REPORT.md` (target: usable within ~30 s on a 25 Mbps connection). Ship only
sanitized player files + the trimmed wordlist in the image — never anything from `facilitator/`.

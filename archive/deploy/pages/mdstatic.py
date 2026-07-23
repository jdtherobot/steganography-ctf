#!/usr/bin/env python3
"""Render every *.md under a directory to a sibling styled *.html (host-agnostic static site).

Uses the `markdown` library if importable, else `pandoc` if on PATH, else a compact built-in
converter covering the constructs used in the participant docs (headings, lists, tables, code,
blockquotes, inline emphasis/links). Always produces readable output.
"""
from __future__ import annotations
import html as _html, re, shutil, subprocess, sys
from pathlib import Path

CSS = """
:root{--bg:#12140f;--panel:#1b1e17;--line:#2c3126;--ink:#e7e9df;--dim:#a2a892;--amber:#e0a83a;--olive:#8a9a5b;--slate:#7c8aa0}
@media(prefers-color-scheme:light){:root{--bg:#eceadf;--panel:#f6f4ea;--line:#d6d3c2;--ink:#22241c;--dim:#5c6150;--amber:#9a6c12;--olive:#5f6e35;--slate:#41506a}}
*{box-sizing:border-box}body{margin:0;background:var(--bg);color:var(--ink);font:16px/1.65 ui-sans-serif,system-ui,-apple-system,"Segoe UI",Roboto,sans-serif}
.wrap{max-width:820px;margin:0 auto;padding:1.6rem 1.25rem 4rem}
.back{font-family:ui-monospace,monospace;font-size:.8rem;color:var(--amber);text-decoration:none}
.back:hover{text-decoration:underline}
h1,h2,h3,h4{line-height:1.25;margin:1.6rem 0 .6rem}h1{font-size:1.9rem}h2{font-size:1.35rem;border-bottom:1px solid var(--line);padding-bottom:.3rem}h3{font-size:1.1rem}
p{margin:.7rem 0}a{color:var(--slate)}
code{font-family:ui-monospace,Menlo,Consolas,monospace;background:var(--panel);border:1px solid var(--line);border-radius:5px;padding:.08em .35em;font-size:.9em}
pre{background:var(--panel);border:1px solid var(--line);border-radius:8px;padding:.9rem 1rem;overflow-x:auto}
pre code{background:none;border:none;padding:0}
blockquote{margin:.8rem 0;padding:.4rem 1rem;border-left:3px solid var(--olive);color:var(--dim);background:var(--panel);border-radius:0 8px 8px 0}
ul,ol{padding-left:1.4rem}li{margin:.25rem 0}
table{border-collapse:collapse;width:100%;margin:1rem 0;font-size:.92rem;display:block;overflow-x:auto}
th,td{border:1px solid var(--line);padding:.4rem .6rem;text-align:left}th{background:var(--panel)}
hr{border:none;border-top:1px solid var(--line);margin:1.6rem 0}
"""

def wrap(title: str, body: str, back_href: str) -> str:
    return (f"<!doctype html><html lang=en><head><meta charset=utf-8>"
            f"<meta name=viewport content='width=device-width,initial-scale=1'>"
            f"<title>{_html.escape(title)}</title><style>{CSS}</style></head>"
            f"<body><div class=wrap><a class=back href='{back_href}'>&larr; Stego CTF</a>\n{body}\n</div></body></html>")

def via_lib(md: str):
    try:
        import markdown  # type: ignore
    except Exception:
        return None
    return markdown.markdown(md, extensions=["extra", "sane_lists", "nl2br"])

def via_pandoc(md: str):
    if not shutil.which("pandoc"):
        return None
    try:
        r = subprocess.run(["pandoc", "-f", "gfm", "-t", "html"], input=md,
                           capture_output=True, text=True, timeout=30)
        return r.stdout if r.returncode == 0 else None
    except Exception:
        return None

def inline(t: str) -> str:
    t = _html.escape(t)
    t = re.sub(r"`([^`]+)`", lambda m: f"<code>{m.group(1)}</code>", t)
    t = re.sub(r"\[([^\]]+)\]\(([^)]+)\)", r'<a href="\2">\1</a>', t)
    t = re.sub(r"\*\*([^*]+)\*\*", r"<strong>\1</strong>", t)
    t = re.sub(r"(?<!\*)\*([^*]+)\*(?!\*)", r"<em>\1</em>", t)
    return t

def via_builtin(md: str) -> str:
    out, i, lines = [], 0, md.replace("\r\n", "\n").split("\n")
    def flush_p(buf):
        if buf:
            out.append("<p>" + inline(" ".join(buf)) + "</p>"); buf.clear()
    para: list[str] = []
    while i < len(lines):
        ln = lines[i]
        if ln.strip().startswith("```"):
            flush_p(para); i += 1; code = []
            while i < len(lines) and not lines[i].strip().startswith("```"):
                code.append(_html.escape(lines[i])); i += 1
            i += 1; out.append("<pre><code>" + "\n".join(code) + "</code></pre>"); continue
        m = re.match(r"^(#{1,6})\s+(.*)$", ln)
        if m:
            flush_p(para); lvl = len(m.group(1)); out.append(f"<h{lvl}>{inline(m.group(2))}</h{lvl}>"); i += 1; continue
        if re.match(r"^\s*([-*_])\1?\1?\s*$", ln) and set(ln.strip()) <= {"-", "*", "_"} and len(ln.strip()) >= 3:
            flush_p(para); out.append("<hr>"); i += 1; continue
        if "|" in ln and i + 1 < len(lines) and re.match(r"^\s*\|?[:\- |]+\|?\s*$", lines[i+1]) and "-" in lines[i+1]:
            flush_p(para)
            def cells(r): return [c.strip() for c in r.strip().strip("|").split("|")]
            head = cells(ln); i += 2; rows = []
            while i < len(lines) and "|" in lines[i] and lines[i].strip():
                rows.append(cells(lines[i])); i += 1
            th = "".join(f"<th>{inline(c)}</th>" for c in head)
            trs = "".join("<tr>" + "".join(f"<td>{inline(c)}</td>" for c in r) + "</tr>" for r in rows)
            out.append(f"<table><thead><tr>{th}</tr></thead><tbody>{trs}</tbody></table>"); continue
        if re.match(r"^\s*>\s?", ln):
            flush_p(para); q = []
            while i < len(lines) and re.match(r"^\s*>\s?", lines[i]):
                q.append(inline(re.sub(r"^\s*>\s?", "", lines[i]))); i += 1
            out.append("<blockquote>" + "<br>".join(q) + "</blockquote>"); continue
        m = re.match(r"^\s*[-*+]\s+(.*)$", ln)
        if m:
            flush_p(para); items = []
            while i < len(lines) and re.match(r"^\s*[-*+]\s+", lines[i]):
                items.append("<li>" + inline(re.sub(r"^\s*[-*+]\s+", "", lines[i])) + "</li>"); i += 1
            out.append("<ul>" + "".join(items) + "</ul>"); continue
        m = re.match(r"^\s*\d+\.\s+(.*)$", ln)
        if m:
            flush_p(para); items = []
            while i < len(lines) and re.match(r"^\s*\d+\.\s+", lines[i]):
                items.append("<li>" + inline(re.sub(r"^\s*\d+\.\s+", "", lines[i])) + "</li>"); i += 1
            out.append("<ol>" + "".join(items) + "</ol>"); continue
        if not ln.strip():
            flush_p(para); i += 1; continue
        para.append(ln.strip()); i += 1
    flush_p(para)
    return "\n".join(out)

def convert(md: str) -> str:
    return via_lib(md) or via_pandoc(md) or via_builtin(md)

def main() -> int:
    root = Path(sys.argv[1])
    n = 0
    for md_path in root.rglob("*.md"):
        md = md_path.read_text(encoding="utf-8", errors="replace")
        title = next((l.lstrip("# ").strip() for l in md.splitlines() if l.strip()), md_path.stem)
        depth = len(md_path.parent.relative_to(root).parts)   # 0 at dist root
        back_href = ("../" * depth) + "index.html"
        md_path.with_suffix(".html").write_text(wrap(title, convert(md), back_href), encoding="utf-8")
        n += 1
    print(f"   rendered {n} markdown file(s) to html")
    return 0

if __name__ == "__main__":
    raise SystemExit(main())

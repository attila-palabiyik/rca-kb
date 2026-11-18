"""Prints the written deliverables.

    python scripts/build_report_pdf.py

docs/slides.html -> docs/slides.pdf

The report's style is docs/report.css. A figure named in an <img> as an SVG
file is placed in the page itself, so that its text is set in the page's type.
The PDFs are printed by a headless Chrome or Edge, which fetches the typefaces
from Google Fonts; without a network the fallbacks named in the CSS are used.
If no browser is found, the HTML is still written and can be printed by hand.
"""

from __future__ import annotations

import re
import shutil
import subprocess
from pathlib import Path

import markdown

DOCS = Path(__file__).resolve().parents[1] / "docs"
FONTS = ('<link rel="preconnect" href="https://fonts.googleapis.com">'
         '<link rel="stylesheet" href="https://fonts.googleapis.com/css2?'
         'family=Source+Serif+4:ital,opsz,wght@0,8..60,400;0,8..60,600;1,8..60,400;1,8..60,600'
         '&family=Figtree:ital,wght@0,400;0,500;0,600;0,700;1,400'
         '&family=JetBrains+Mono:wght@400;500&display=block">')

BROWSERS = [
    "chromium", "chromium-browser", "google-chrome", "msedge",
    "/mnt/c/Program Files/Google/Chrome/Application/chrome.exe",
    "/mnt/c/Program Files (x86)/Microsoft/Edge/Application/msedge.exe",
    "C:/Program Files/Google/Chrome/Application/chrome.exe",
    "C:/Program Files (x86)/Microsoft/Edge/Application/msedge.exe",
]


def inline_figures(html: str, base: Path) -> str:
    """Put each SVG file named by an <img> into the page in its place."""
    count = 0

    def swap(match: re.Match) -> str:
        nonlocal count
        file = (base / match.group("src")).resolve()
        if not file.is_file():
            return match.group(0)
        count += 1
        svg = file.read_text(encoding="utf-8")
        svg = svg[svg.index("<svg"):]
        svg = re.sub(r"<metadata>.*?</metadata>", "", svg, count=1, flags=re.DOTALL)
        # The page sets the size; the viewBox keeps the proportions.
        head, rest = svg.split(">", 1)
        head = re.sub(r'\s(?:width|height)="[^"]*"', "", head)
        svg = f"{head}>{rest}"
        # Two figures in one page must not share ids.
        prefix = f"fig{count}-"
        svg = re.sub(r'\bid="([^"]+)"', rf'id="{prefix}\1"', svg)
        svg = re.sub(r"url\(#([^)]+)\)", rf"url(#{prefix}\1)", svg)
        svg = re.sub(r'href="#([^"]+)"', rf'href="#{prefix}\1"', svg)
        alt = re.search(r'alt="([^"]*)"', match.group(0))
        label = f' aria-label="{alt.group(1)}"' if alt else ""
        classes = re.search(r'class="([^"]*)"', match.group(0))
        return f'<div class="chart {classes.group(1) if classes else ""}" role="img"{label}>{svg}</div>'

    return re.sub(r'<img\b[^>]*?\bsrc="(?P<src>[^"]+\.svg)"[^>]*>', swap, html)


def _for_browser(path: Path, browser: str) -> str:
    """A Windows browser started from WSL needs Windows paths."""
    if browser.startswith("/mnt/") and shutil.which("wslpath"):
        return subprocess.run(["wslpath", "-w", str(path)], capture_output=True, text=True).stdout.strip()
    return str(path)


def print_pdf(html_file: Path, pdf_file: Path, browser: str | None) -> None:
    if browser is None:
        print(f"no browser found to print {pdf_file.name}")
        return
    pdf_file.unlink(missing_ok=True)
    # A profile of its own, so that a browser the user already has open does not take the job.
    profile = DOCS.parent / ".cache" / f"print-profile-{pdf_file.stem}"
    profile.mkdir(parents=True, exist_ok=True)
    command = [browser, "--headless", "--disable-gpu", "--no-pdf-header-footer", "--no-first-run",
               "--virtual-time-budget=20000", f"--user-data-dir={_for_browser(profile, browser)}",
               f"--print-to-pdf={_for_browser(pdf_file, browser)}", _for_browser(html_file, browser)]
    for _ in range(3):
        done = subprocess.run(command, capture_output=True, text=True, timeout=240, stdin=subprocess.DEVNULL)
        if pdf_file.is_file():
            print(f"wrote {pdf_file}")
            return
    errors = [line for line in (done.stderr or "").splitlines() if "registry" not in line]
    print(f"printing {pdf_file.name} failed (exit {done.returncode}): {' | '.join(errors[-3:])}")


def main() -> None:
    browser = next((b for b in BROWSERS if shutil.which(b) or Path(b).is_file()), None)
    slides = DOCS / "slides.html"
    printable = DOCS / ".slides.print.html"
    printable.write_text(inline_figures(slides.read_text(encoding="utf-8"), DOCS), encoding="utf-8", newline="\n")
    try:
        print_pdf(printable, DOCS / "slides.pdf", browser)
    finally:
        printable.unlink(missing_ok=True)


if __name__ == "__main__":
    main()

"""Turns docs/report.md into docs/report.html and docs/report.pdf, and prints
docs/slides.html to docs/slides.pdf.

    python scripts/build_report_pdf.py

The PDFs are printed by a headless Chrome or Edge. If none is found, the HTML
is still written and can be printed from any browser.
"""

from __future__ import annotations

import shutil
import subprocess
from pathlib import Path

import markdown

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "docs" / "report.md"
SLIDES = ROOT / "docs" / "slides.html"

CSS = """
@page { size: A4; margin: 22mm 22mm 24mm;
        @bottom-center { content: counter(page); font: 9pt Cambria, Georgia, serif; color: #555; } }
body { font-family: Cambria, Georgia, 'Times New Roman', serif; font-size: 10.5pt; line-height: 1.45; color: #111;
       max-width: 166mm; margin: 0 auto; }
h1 { font-size: 21pt; font-weight: 600; margin: 0 0 4pt; line-height: 1.2; }
h2 { font-size: 13pt; font-weight: 600; margin: 20pt 0 6pt; break-after: avoid; }
p, li { orphans: 3; widows: 3; }
p { margin: 0 0 8pt; }
li { margin-bottom: 3pt; }
a { color: inherit; text-decoration: none; }
table { border-collapse: collapse; width: 100%; margin: 0 0 12pt; font-family: 'Segoe UI', Arial, Helvetica, sans-serif;
        font-size: 8pt; line-height: 1.35; border-top: 1pt solid #111; border-bottom: 1pt solid #111;
        break-inside: avoid; }
th, td { padding: 3.5pt 8pt 3.5pt 0; text-align: left; vertical-align: top; }
th:last-child, td:last-child { padding-right: 0; }
th { border-bottom: 0.5pt solid #111; font-weight: 600; vertical-align: bottom; }
code { font-family: Consolas, 'Courier New', monospace; font-size: 9pt; }
.byline { color: #555; margin: 0 0 14pt; }
.caption, figcaption { font-size: 9pt; line-height: 1.35; color: #222; text-align: left; }
.caption { margin: 12pt 0 4pt; break-after: avoid; }
figure { margin: 12pt 0 10pt; break-inside: avoid; text-align: center; }
figure img { width: 80%; }
figcaption { margin-top: 4pt; }
"""

BROWSERS = [
    "chromium", "chromium-browser", "google-chrome", "msedge",
    "/mnt/c/Program Files/Google/Chrome/Application/chrome.exe",
    "/mnt/c/Program Files (x86)/Microsoft/Edge/Application/msedge.exe",
    "C:/Program Files/Google/Chrome/Application/chrome.exe",
    "C:/Program Files (x86)/Microsoft/Edge/Application/msedge.exe",
]


def _for_browser(path: Path, browser: str) -> str:
    """A Windows browser started from WSL needs Windows paths."""
    if browser.startswith("/mnt/") and shutil.which("wslpath"):
        return subprocess.run(["wslpath", "-w", str(path)], capture_output=True, text=True).stdout.strip()
    return str(path)


def _print(html_file: Path, browser: str | None) -> None:
    pdf_file = html_file.with_suffix(".pdf")
    if browser is None:
        print(f"wrote {html_file}; no browser found to print the PDF")
        return
    pdf_file.unlink(missing_ok=True)
    subprocess.run([browser, "--headless", "--disable-gpu", "--no-pdf-header-footer",
                    f"--print-to-pdf={_for_browser(pdf_file, browser)}",
                    _for_browser(html_file, browser)], capture_output=True, timeout=120,
                   stdin=subprocess.DEVNULL)
    print(f"wrote {pdf_file}" if pdf_file.is_file() else f"wrote {html_file}; printing the PDF failed")


def main() -> None:
    body = markdown.markdown(SOURCE.read_text(encoding="utf-8"),
                             extensions=["tables", "fenced_code", "sane_lists"])
    html = (f"<!doctype html><html lang='en'><head><meta charset='utf-8'><title>Report</title>"
            f"<style>{CSS}</style></head><body>{body}</body></html>")
    html_file = SOURCE.with_suffix(".html")
    html_file.write_text(html, encoding="utf-8")
    browser = next((b for b in BROWSERS if shutil.which(b) or Path(b).is_file()), None)
    _print(html_file, browser)
    if SLIDES.is_file():
        _print(SLIDES, browser)


if __name__ == "__main__":
    main()

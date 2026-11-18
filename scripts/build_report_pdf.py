"""Turns docs/report.md into docs/report.html and docs/report.pdf.

    python scripts/build_report_pdf.py

The PDF is printed by a headless Chrome or Edge. If none is found, the HTML is
still written and can be printed from any browser.
"""

from __future__ import annotations

import shutil
import subprocess
from pathlib import Path

import markdown

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "docs" / "report.md"

CSS = """
@page { size: A4; margin: 20mm 18mm; }
body { font-family: Georgia, 'Times New Roman', serif; font-size: 10.5pt; line-height: 1.45; color: #111;
       max-width: 170mm; margin: 0 auto; }
h1 { font-size: 20pt; margin: 0 0 4pt; line-height: 1.2; }
h2 { font-size: 13.5pt; margin: 20pt 0 6pt; border-bottom: 0.5pt solid #999; padding-bottom: 2pt;
     page-break-after: avoid; }
h3 { font-size: 11pt; margin: 14pt 0 4pt; page-break-after: avoid; }
p, li { orphans: 3; widows: 3; }
table { border-collapse: collapse; width: 100%; margin: 8pt 0 10pt; font-family: Arial, Helvetica, sans-serif;
        font-size: 8pt; page-break-inside: avoid; }
th, td { border: 0.5pt solid #bbb; padding: 3pt 5pt; text-align: left; vertical-align: top; }
th { background: #f0f0f0; }
code { font-family: Consolas, 'Courier New', monospace; font-size: 9pt; }
pre { background: #f6f6f6; padding: 6pt 8pt; font-size: 8.5pt; overflow-wrap: anywhere; white-space: pre-wrap; }
img { max-width: 100%; }
.byline { color: #555; margin: 0 0 14pt; }
em { color: #333; }
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


def main() -> None:
    body = markdown.markdown(SOURCE.read_text(encoding="utf-8"),
                             extensions=["tables", "fenced_code", "sane_lists"])
    html = (f"<!doctype html><html lang='en'><head><meta charset='utf-8'><title>Report</title>"
            f"<style>{CSS}</style></head><body>{body}</body></html>")
    html_file, pdf_file = SOURCE.with_suffix(".html"), SOURCE.with_suffix(".pdf")
    html_file.write_text(html, encoding="utf-8")
    browser = next((b for b in BROWSERS if shutil.which(b) or Path(b).is_file()), None)
    if browser is None:
        print(f"wrote {html_file}; no browser found to print the PDF")
        return
    subprocess.run([browser, "--headless", "--disable-gpu", "--no-pdf-header-footer",
                    f"--print-to-pdf={_for_browser(pdf_file, browser)}",
                    _for_browser(html_file, browser)], capture_output=True, timeout=120,
                   stdin=subprocess.DEVNULL)
    print(f"wrote {pdf_file}" if pdf_file.is_file() else f"wrote {html_file}; printing the PDF failed")


if __name__ == "__main__":
    main()

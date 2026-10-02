"""Prints an HTML file to PDF with headless Microsoft Edge and waits until the PDF is complete.

Edge hands the print job to a background process and can return before the PDF is written,
so the old PDF is removed first and the new one is awaited until its size stops changing.
"""
import subprocess
import time
from pathlib import Path

EDGE = r"C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"


def print_pdf(html: Path, pdf: Path, timeout: float = 120.0) -> None:
    pdf = Path(pdf)
    if pdf.exists():
        pdf.unlink()
    subprocess.run([EDGE, "--headless=new", "--disable-gpu", "--no-pdf-header-footer",
                    "--virtual-time-budget=15000", f"--print-to-pdf={pdf}", Path(html).as_uri()],
                   check=True, timeout=180)
    t_end = time.time() + timeout
    last = -1
    while time.time() < t_end:
        if pdf.exists():
            size = pdf.stat().st_size
            if size > 0 and size == last:
                return
            last = size
        time.sleep(0.5)
    raise TimeoutError(f"Edge did not finish writing {pdf}")

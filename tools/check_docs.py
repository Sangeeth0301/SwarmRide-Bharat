"""Checks every Markdown document in the repository for broken local links and images.

Looks at Markdown links/images  [text](path)  ![alt](path)  and HTML  <img src="path">.
Web links (http, https, mailto) and in-page anchors (#...) are skipped.
Exit code 1 if anything is missing.   Usage:  python tools/check_docs.py
"""
import re
import sys
from pathlib import Path
from urllib.parse import unquote

ROOT = Path(__file__).resolve().parent.parent
MD_LINK = re.compile(r"!?\[[^\]]*\]\(([^)\s]+)(?:\s+\"[^\"]*\")?\)")
HTML_SRC = re.compile(r"<img[^>]+src=\"([^\"]+)\"", re.IGNORECASE)
SKIP_DIRS = {".git", "work", "slprj", "__pycache__"}


def targets(text):
    in_code = False
    for line in text.splitlines():
        if line.strip().startswith("```"):
            in_code = not in_code
            continue
        if in_code:
            continue
        for m in MD_LINK.finditer(line):
            yield m.group(1)
        for m in HTML_SRC.finditer(line):
            yield m.group(1)


def main():
    missing, checked = [], 0
    for md in sorted(ROOT.rglob("*.md")):
        if SKIP_DIRS & set(md.relative_to(ROOT).parts):
            continue
        for t in targets(md.read_text(encoding="utf-8")):
            if t.startswith(("http://", "https://", "mailto:", "#")):
                continue
            path = unquote(t.split("#")[0])
            if not path:
                continue
            checked += 1
            if not (md.parent / path).exists():
                missing.append(f"{md.relative_to(ROOT)}: {t}")
    print(f"Checked {checked} local links and images in Markdown files.")
    if missing:
        print("Missing:")
        print("\n".join("  " + m for m in missing))
        return 1
    print("All present.")
    return 0


if __name__ == "__main__":
    sys.exit(main())

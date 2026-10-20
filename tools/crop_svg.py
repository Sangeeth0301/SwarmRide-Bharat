"""Crops the top of an SVG (for example its title) by shifting the viewBox, for slides that carry their own title.
Usage, from the repository root:
    python tools/crop_svg.py images/architecture.svg images/architecture_slide.svg 88
(PNG: render the output SVG in a browser)
"""
import re
import sys

src, out, top = sys.argv[1], sys.argv[2], float(sys.argv[3])
s = open(src, encoding='utf-8').read()
m = re.search(r'viewBox="0 0 ([\d.]+) ([\d.]+)" width="([\d.]+)" height="([\d.]+)"', s)
if not m:
    sys.exit('expected an SVG that starts with viewBox="0 0 W H" width="W" height="H"')
w, h = float(m.group(1)), float(m.group(2))
s = s.replace(m.group(0), f'viewBox="0 {top:g} {w:g} {h - top:g}" width="{w:g}" height="{h - top:g}"', 1)
open(out, 'w', encoding='utf-8').write(s)
print(f'wrote {out}: {w:g} x {h - top:g}')

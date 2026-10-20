"""Draws images/physical_model.svg: the SwarmRide physical model (LHB half-coach, 4 DOF) showing the smart
electromagnetic damper in parallel with the air spring, in place of today's oil damper.
Numbers: SwarmRide_Sim/functions/sr_trains.m (LHB) and results/stage2_report.txt (design C).
Run from the repository root:  python tools/draw_physical_model.py   (PNG: render the SVG in a browser)
"""
import sys
from xml.sax.saxutils import escape

OUT = sys.argv[1] if len(sys.argv) > 1 else "images/physical_model.svg"
W, H = 900, 580
INK, MUT, ORG, ORGF, BLU, BLUF, GRY = '#2D3748', '#718096', '#DD6B20', '#FFF3E6', '#2B6CB0', '#EBF4FF', '#A0AEC0'
o = []


def t(x, y, s, cls, anchor='start'):
    o.append(f'<text x="{x}" y="{y}" class="{cls}" text-anchor="{anchor}">{escape(s)}</text>')


def spring(x, y1, y2, w=16, n=6, color=INK, width=2):
    step = (y2 - y1 - 12) / (2 * n)
    pts = [(x, y1), (x, y1 + 6)]
    for k in range(2 * n):
        pts.append((x + (w if k % 2 == 0 else -w), y1 + 6 + step * (k + 0.5)))
    pts += [(x, y2 - 6), (x, y2)]
    o.append(f'<polyline points="{" ".join(f"{a:.1f},{b:.1f}" for a, b in pts)}" fill="none" stroke="{color}" stroke-width="{width}" stroke-linejoin="round"/>')


def air_spring(cx, y1, y2):
    o.append(f'<line x1="{cx}" y1="{y1}" x2="{cx}" y2="{y1+8}" stroke="{INK}" stroke-width="2.5"/>')
    h = (y2 - y1 - 16) / 3
    for k in range(3):
        o.append(f'<rect x="{cx-30}" y="{y1+8+k*h:.1f}" width="60" height="{h:.1f}" rx="{h/2:.1f}" fill="{BLUF}" stroke="{BLU}" stroke-width="2"/>')
    o.append(f'<line x1="{cx}" y1="{y2-8}" x2="{cx}" y2="{y2}" stroke="{INK}" stroke-width="2.5"/>')


def smart_damper(cx, y1, y2):
    # outer tube on the body, ball screw inside, rod to the bogie, generator on the side
    o.append(f'<rect x="{cx-17}" y="{y1}" width="34" height="56" rx="5" fill="{ORGF}" stroke="{ORG}" stroke-width="2.2"/>')
    for k in range(5):
        yy = y1 + 10 + k * 9
        o.append(f'<line x1="{cx-9}" y1="{yy}" x2="{cx+9}" y2="{yy+5}" stroke="{ORG}" stroke-width="1.6"/>')
    o.append(f'<line x1="{cx}" y1="{y1+56}" x2="{cx}" y2="{y2}" stroke="{INK}" stroke-width="3"/>')
    o.append(f'<line x1="{cx+17}" y1="{y1+16}" x2="{cx+27}" y2="{y1+16}" stroke="{ORG}" stroke-width="2"/>')
    o.append(f'<circle cx="{cx+40}" cy="{y1+16}" r="13" fill="#FFFFFF" stroke="{ORG}" stroke-width="2.2"/>')
    t(cx + 40, y1 + 21, 'G', 'gl', 'middle')


# ---------------- header ----------------
t(40, 34, 'Physical model · LHB half-coach, 4 degrees of freedom', 'hd')

# ---------------- coach body ----------------
o.append(f'<rect x="70" y="54" width="780" height="78" rx="8" fill="#F7FAFC" stroke="{INK}" stroke-width="2"/>')
t(460, 87, 'Coach body', 'big', 'middle')
t(460, 113, '28 t empty → 40 t crowded  ·  bounce zb + pitch θ', 'sub', 'middle')
o.append(f'<line x1="48" y1="118" x2="48" y2="68" stroke="{INK}" stroke-width="2" marker-end="url(#a)"/>')
t(42, 62, 'zb', 'dof', 'end')

bog = [235, 685]
for cx in bog:
    air_spring(cx - 50, 132, 236)
    smart_damper(cx + 40, 132, 236)
    o.append(f'<rect x="{cx-110}" y="236" width="220" height="44" rx="6" fill="#F7FAFC" stroke="{INK}" stroke-width="2"/>')
    for wx in (cx - 62, cx + 62):
        spring(wx, 280, 330, w=11, n=5)
        o.append(f'<circle cx="{wx}" cy="356" r="25" fill="#FFFFFF" stroke="{INK}" stroke-width="2.2"/>')
        o.append(f'<circle cx="{wx}" cy="356" r="5" fill="{INK}"/>')
t(235, 264, 'Front bogie · z1', 'bt', 'middle')
t(685, 264, 'Rear bogie · z2', 'bt', 'middle')

# key between the bogies
t(460, 160, 'Secondary suspension', 'bt', 'middle')
o.append(f'<rect x="388" y="176" width="24" height="14" rx="7" fill="{BLUF}" stroke="{BLU}" stroke-width="1.8"/>')
t(420, 188, 'Air spring', 'sub')
o.append(f'<rect x="388" y="200" width="24" height="14" rx="3" fill="{ORGF}" stroke="{ORG}" stroke-width="1.8"/>')
t(420, 212, 'Smart EM damper (G)', 'sub')
t(460, 234, 'side by side, same mounts', 'cap', 'middle')
t(460, 312, 'Primary suspension', 'bt', 'middle')

# rail
d = 'M50,382 C110,377 150,388 210,382 S320,376 380,383 S500,389 560,381 S680,376 740,383 S820,388 850,382'
o.append(f'<path d="{d}" fill="none" stroke="{INK}" stroke-width="3"/>')
o.append(f'<rect x="50" y="386" width="800" height="10" fill="#E2E8F0"/>')
t(460, 420, 'Rail irregularity w(t) under each of the 4 wheels  ·  160 km/h', 'sub', 'middle')
# dimension: bogie centres
o.append(f'<line x1="235" y1="440" x2="685" y2="440" stroke="{MUT}" stroke-width="1.4" marker-start="url(#g)" marker-end="url(#g)"/>')
o.append(f'<line x1="235" y1="432" x2="235" y2="448" stroke="{MUT}" stroke-width="1.4"/><line x1="685" y1="432" x2="685" y2="448" stroke="{MUT}" stroke-width="1.4"/>')
t(460, 462, 'bogie centres 14.9 m', 'dim', 'middle')

# ---------------- today vs SwarmRide ----------------
o.append(f'<rect x="50" y="484" width="390" height="80" rx="10" fill="#F7FAFC" stroke="{GRY}" stroke-width="1.6"/>')
t(70, 512, 'Today', 'bt')
t(70, 536, 'Air spring + oil damper', 'sub')
t(70, 555, 'one fixed setting · energy → heat', 'sub')
o.append(f'<rect x="460" y="484" width="390" height="80" rx="10" fill="{ORGF}" stroke="{ORG}" stroke-width="2"/>')
t(480, 512, 'SwarmRide', 'btO')
t(480, 536, 'Air spring + smart EM damper', 'sub')
t(480, 555, 'same mounts · tunable · energy → bank', 'sub')
o.append(f'<line x1="443" y1="524" x2="457" y2="524" stroke="{ORG}" stroke-width="2.4" marker-end="url(#o)"/>')

css = """
.hd{font-size:17px;font-weight:700;fill:#2D3748;letter-spacing:0.3px}
.big{font-size:22px;font-weight:700;fill:#1A202C}.bt{font-size:17px;font-weight:700;fill:#1A202C}
.btO{font-size:17px;font-weight:700;fill:#C05621}.sub{font-size:15px;fill:#4A5568}
.dof{font-size:15px;font-weight:700;fill:#2D3748;font-style:italic}.gl{font-size:13px;font-weight:700;fill:#C05621}
.dim{font-size:14px;fill:#718096}.cap{font-size:13.5px;fill:#718096;font-style:italic}.ct{font-size:19px;font-weight:700;fill:#C05621}.cs{font-size:13.5px;fill:#718096}
.ch{font-size:12.5px;font-weight:700;fill:#C05621;letter-spacing:0.8px}.cl{font-size:15px;fill:#2D3748}
"""
mk = (f'<marker id="a" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="7" markerHeight="7" orient="auto-start-reverse"><path d="M0,0 L10,5 L0,10 z" fill="{INK}"/></marker>'
      f'<marker id="g" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="6" markerHeight="6" orient="auto-start-reverse"><path d="M0,0 L10,5 L0,10 z" fill="{MUT}"/></marker>'
      f'<marker id="o" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="5" markerHeight="5" orient="auto-start-reverse"><path d="M0,0 L10,5 L0,10 z" fill="{ORG}"/></marker>')
svg = (f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {W} {H}" width="{W}" height="{H}" '
       f'font-family="\'Segoe UI\', Helvetica, Arial, sans-serif">\n<defs>{mk}<style>{css}</style></defs>\n'
       f'<rect width="{W}" height="{H}" fill="#FFFFFF"/>\n' + '\n'.join(o) + '\n</svg>\n')
open(OUT, 'w', encoding='utf-8').write(svg)
print('wrote', OUT)

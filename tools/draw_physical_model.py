"""Draws images/physical_model.svg: the SwarmRide physical model (LHB half-coach, 4 DOF) showing the smart
electromagnetic damper in parallel with the air spring, in place of today's oil damper.
Numbers: SwarmRide_Sim/functions/sr_trains.m (LHB) and results/stage2_report.txt (design C).
Run from the repository root:  python tools/draw_physical_model.py   (PNG: render the SVG in a browser)
"""
import sys
from xml.sax.saxutils import escape

OUT = sys.argv[1] if len(sys.argv) > 1 else "images/physical_model.svg"
W, H = 900, 610
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
o.append(f'<rect x="60" y="54" width="560" height="78" rx="8" fill="#F7FAFC" stroke="{INK}" stroke-width="2"/>')
t(340, 87, 'Coach body', 'big', 'middle')
t(340, 113, '28 t empty → 40 t crowded  ·  bounce zb + pitch θ', 'sub', 'middle')
o.append(f'<line x1="40" y1="118" x2="40" y2="68" stroke="{INK}" stroke-width="2" marker-end="url(#a)"/>')
t(34, 62, 'zb', 'dof', 'end')

bog = [175, 505]
for cx in bog:
    air_spring(cx - 42, 132, 236)
    smart_damper(cx + 38, 132, 236)
    o.append(f'<rect x="{cx-95}" y="236" width="190" height="44" rx="6" fill="#F7FAFC" stroke="{INK}" stroke-width="2"/>')
    for wx in (cx - 55, cx + 55):
        spring(wx, 280, 330, w=11, n=5)
        o.append(f'<circle cx="{wx}" cy="356" r="25" fill="#FFFFFF" stroke="{INK}" stroke-width="2.2"/>')
        o.append(f'<circle cx="{wx}" cy="356" r="5" fill="{INK}"/>')
t(175, 264, 'Front bogie · z1', 'bt', 'middle')
t(505, 264, 'Rear bogie · z2', 'bt', 'middle')

# labels between the bogies
t(345, 160, 'Secondary', 'bt', 'middle')
t(345, 180, 'suspension', 'bt', 'middle')
t(345, 202, 'air spring +', 'sub', 'middle')
t(345, 220, 'smart damper,', 'sub', 'middle')
t(345, 238, 'in parallel', 'sub', 'middle')
t(340, 312, 'Primary suspension', 'bt', 'middle')

# rail
d = 'M40,382 C90,377 120,388 170,382 S250,376 300,383 S390,389 430,381 S520,376 560,383 S620,388 640,382'
o.append(f'<path d="{d}" fill="none" stroke="{INK}" stroke-width="3"/>')
o.append(f'<rect x="40" y="386" width="600" height="10" fill="#E2E8F0"/>')
t(340, 420, 'Rail irregularity w(t) under each of the 4 wheels  ·  160 km/h', 'sub', 'middle')
# dimension: bogie centres
o.append(f'<line x1="175" y1="440" x2="505" y2="440" stroke="{MUT}" stroke-width="1.4" marker-start="url(#g)" marker-end="url(#g)"/>')
o.append(f'<line x1="175" y1="432" x2="175" y2="448" stroke="{MUT}" stroke-width="1.4"/><line x1="505" y1="432" x2="505" y2="448" stroke="{MUT}" stroke-width="1.4"/>')
t(340, 462, 'bogie centres 14.9 m', 'dim', 'middle')

# ---------------- smart damper callout ----------------
o.append(f'<rect x="650" y="54" width="226" height="408" rx="10" fill="#FFFFFF" stroke="{ORG}" stroke-width="2"/>')
o.append(f'<rect x="651" y="55" width="224" height="6" rx="2" fill="{ORG}"/>')
o.append(f'<line x1="650" y1="148" x2="599" y2="148" stroke="{ORG}" stroke-width="1.6" stroke-dasharray="5 4"/>')
t(666, 90, 'Smart EM damper', 'ct')
t(666, 111, 'replaces today\'s oil damper', 'cs')
t(666, 128, '2 per bogie · design C', 'cs')
items = [('How it is built', None), ('Ball screw + magnet', 'b'), ('generator (G)', 'b'),
         ('How it works', None), ('Speed → voltage', 'b'), ('Current → force', 'b'), ('So the current sets', 'b'), ('the damping', 'b'),
         ('What it gives', None), ('Damping 0–246 kN·s/m', 'b'), ('Harvests 33–38 W', 'b'), ('Fail-safe = today\'s', 'b'), ('35 kN·s/m damper', 'b')]
yy = 160
for s_, kind in items:
    if kind is None:
        yy += 8
        t(666, yy, s_, 'ch'); yy += 22
    else:
        t(666, yy, s_, 'cl'); yy += 20

# ---------------- today vs SwarmRide ----------------
o.append(f'<rect x="40" y="490" width="410" height="96" rx="10" fill="#F7FAFC" stroke="{GRY}" stroke-width="1.6"/>')
t(60, 522, 'Today', 'bt')
t(60, 548, 'Air spring + oil damper', 'sub')
t(60, 570, 'one fixed setting · energy → heat', 'sub')
o.append(f'<rect x="466" y="490" width="410" height="96" rx="10" fill="{ORGF}" stroke="{ORG}" stroke-width="2"/>')
t(486, 522, 'SwarmRide', 'btO')
t(486, 548, 'Air spring + smart EM damper', 'sub')
t(486, 570, 'same mounts · tunable · energy → bank', 'sub')
o.append(f'<line x1="452" y1="538" x2="462" y2="538" stroke="{ORG}" stroke-width="2.4" marker-end="url(#o)"/>')

css = """
.hd{font-size:17px;font-weight:700;fill:#2D3748;letter-spacing:0.3px}
.big{font-size:22px;font-weight:700;fill:#1A202C}.bt{font-size:17px;font-weight:700;fill:#1A202C}
.btO{font-size:17px;font-weight:700;fill:#C05621}.sub{font-size:15px;fill:#4A5568}
.dof{font-size:15px;font-weight:700;fill:#2D3748;font-style:italic}.gl{font-size:13px;font-weight:700;fill:#C05621}
.dim{font-size:14px;fill:#718096}.ct{font-size:19px;font-weight:700;fill:#C05621}.cs{font-size:13.5px;fill:#718096}
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

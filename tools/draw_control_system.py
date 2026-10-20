"""Draws images/control_system_design.svg: the SwarmRide control system as a clean block diagram
(element names only, no equations). Same design as SwarmRide_Sim/scripts/build_control_diagram.m.
Run from the repository root:  python tools/draw_control_system.py   (PNG: render the SVG in a browser)
"""
import sys
from xml.sax.saxutils import escape

# --no-title: crop the title off (for slides that carry their own title)
NO_TITLE = "--no-title" in sys.argv
args = [a for a in sys.argv[1:] if not a.startswith("--")]
OUT = args[0] if args else "images/control_system_design.svg"
W, H = 1800, 962
o = []

C = {  # fill, stroke
    'ctl': ('#E6F4F1', '#2A9D8F'), 'drv': ('#FFF6DA', '#C9921A'), 'plt': ('#E8F0FB', '#3A6FB0'),
    'pwr': ('#FFF0E0', '#E07A1F'), 'safe': ('#FDECEA', '#D64541'), 'gry': ('#F1F3F5', '#7A8594'),
}
INK, ORG, RED, BLU, TEAL = '#2D3748', '#DD6B20', '#C53030', '#2B6CB0', '#2C7A7B'


def t(x, y, s, cls, anchor='middle'):
    o.append(f'<text x="{x}" y="{y}" class="{cls}" text-anchor="{anchor}">{escape(s)}</text>')


def block(x, cy, w, kind, name, sub=None, h=64, dash=False):
    f, s = C[kind]
    y = cy - h / 2
    da = ' stroke-dasharray="7 4"' if dash else ''
    o.append(f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="6" fill="#FFFFFF" stroke="#A0AEC0" stroke-width="1.4"{da}/>')
    o.append(f'<rect x="{x+1}" y="{y+1}" width="{w-2}" height="5" rx="2" fill="{s}"/>')
    if sub:
        t(x + w / 2, cy - 3, name, 'bt'); t(x + w / 2, cy + 16, sub, 'bs')
    else:
        t(x + w / 2, cy + 6, name, 'bt')


def summ(cx, cy, signs):
    o.append(f'<circle cx="{cx}" cy="{cy}" r="16" fill="#FFFFFF" stroke="{INK}" stroke-width="1.6"/>')
    t(cx, cy + 6, 'Σ', 'sig')
    off = {'l': (-25, -9), 't': (-13, -23), 'b': (-13, 34)}
    for side, sg in signs.items():
        dx, dy = off[side]
        t(cx + dx, cy + dy, sg, 'sgn')


def pill(x, cy, label, kind='gry'):
    f, s = C[kind]
    w = 22 + 7.4 * len(label)
    o.append(f'<rect x="{x}" y="{cy-13}" width="{w}" height="26" rx="13" fill="#F7FAFC" stroke="#A0AEC0" stroke-width="1.2"/>')
    t(x + w / 2, cy + 5, label, 'pl')
    return x + w


def wire(pts, color=INK, dash=None, width=1.7, arrow=True):
    d = 'M' + ' L'.join(f'{a},{b}' for a, b in pts)
    da = f' stroke-dasharray="{dash}"' if dash else ''
    mk = f' marker-end="url(#m{color[1:]})"' if arrow else ''
    o.append(f'<path d="{d}" fill="none" stroke="{color}" stroke-width="{width}" stroke-linejoin="round"{da}{mk}/>')


def dot(x, y, color=INK):
    o.append(f'<circle cx="{x}" cy="{y}" r="4.5" fill="{color}"/>')


def sig(x, y, s, anchor='middle', color=None):
    t(x, y, s, 'sl" fill="' + color if color else 'sl', anchor)


def band(y, h, kind, title, tx=40):
    f, s = C[kind]
    o.append(f'<rect x="16" y="{y}" width="{W-32}" height="{h}" rx="8" fill="#F7F8FA" stroke="#E2E8F0" stroke-width="1.2"/>')
    o.append(f'<rect x="{tx}" y="{y+13}" width="4" height="17" rx="1" fill="{s}"/>')
    t(tx + 14, y + 27, title, 'band', 'start')


# ---------------- title ----------------
t(40, 48, 'SwarmRide Bharat — Control System Architecture', 'ttl', 'start')
t(40, 76, 'Cascaded control of the regenerative smart damper: vehicle-level outer loop, damper-drive inner loop, self-powered bogie with hardware fail-safe.', 'sub', 'start')

# ---------------- ① vehicle controller ----------------
band(98, 282, 'ctl', 'VEHICLE CONTROLLER  —  OUTER LOOP  (100 Hz)')
block(40, 190, 150, 'ctl', 'Track map', 'known bumps ahead')
block(240, 190, 180, 'ctl', 'Train Brain', 'preview of the rail')
wire([(190, 190), (238, 190)])
block(470, 190, 190, 'ctl', 'Preview feed-forward')
wire([(420, 190), (468, 190)])
block(470, 332, 190, 'ctl', 'State feedback', 'LPV-LQR')
block(40, 270, 150, 'gry', 'Load estimate', 'air-spring pressure')
wire([(190, 270), (565, 270), (565, 224)], BLU, '7 4'); wire([(565, 270), (565, 298)], BLU, '7 4')
t(378, 262, 'gain scheduling by load', 'sch')
summ(720, 256, {'t': '−', 'b': '−'})
wire([(660, 190), (720, 190), (720, 237)]); wire([(660, 332), (720, 332), (720, 275)])
wire([(737, 256), (790, 256)]); dot(760, 256)
block(800, 256, 230, 'ctl', 'Semi-active conversion', 'resist only, within limits')
sig(764, 300, 'force', 'middle'); sig(764, 316, 'command', 'middle')
block(1100, 256, 190, 'ctl', 'Damping law')
wire([(1030, 256), (1098, 256)])
wire([(760, 256), (760, 150), (1098, 150)], ORG)
block(1100, 150, 190, 'pwr', 'Push command', 'known bad spot')
o.append(f'<rect x="1370" y="118" width="62" height="170" rx="6" fill="#FFFFFF" stroke="#A0AEC0" stroke-width="1.4"/><rect x="1371" y="119" width="60" height="5" rx="2" fill="{C["pwr"][1]}"/>')
o.append(f'<path d="M1380,150 L1420,206" stroke="{INK}" stroke-width="2.2"/><circle cx="1420" cy="206" r="3.5" fill="{INK}"/>')
t(1401, 308, 'C4 push switch', 'cap')
wire([(1290, 150), (1368, 150)], ORG); wire([(1290, 256), (1368, 256)])
block(1500, 206, 170, 'gry', 'Current limit')
wire([(1432, 206), (1498, 206)])
t(800, 389, 'current command  →  damper drive', 'flow')

# ---------------- ② damper drive + smart damper + coach ----------------
band(420, 262, 'drv', 'DAMPER DRIVE  —  INNER LOOP  (10 kHz)   ·   SMART DAMPER AND VEHICLE', tx=96)
wire([(1670, 206), (1730, 206), (1730, 395), (70, 395), (70, 548), (89, 548)])
cy = 548
summ(108, cy, {'l': '+', 'b': '−'})
block(160, cy, 170, 'drv', 'Current controller', 'PI')
wire([(125, cy), (158, cy)])
summ(380, cy, {'l': '+', 't': '+'})
wire([(330, cy), (362, cy)])
block(300, 478, 160, 'drv', 'Back-EMF', 'feed-forward', h=50)
pill(160, 478, 'damper speed', 'plt'); wire([(278, 478), (298, 478)])
wire([(380, 503), (380, 530)])
block(430, cy, 140, 'drv', 'Voltage limit')
wire([(397, cy), (428, cy)])
o.append(f'<rect x="612" y="{cy-50}" width="70" height="104" rx="6" fill="#FFFFFF" stroke="#A0AEC0" stroke-width="1.4"/><rect x="613" y="{cy-49}" width="68" height="5" rx="2" fill="{C["safe"][1]}"/>')
o.append(f'<path d="M622,{cy-26} L670,{cy}" stroke="{INK}" stroke-width="2.2"/><circle cx="670" cy="{cy}" r="3.5" fill="{INK}"/>')
t(647, cy - 60, 'Contactor', 'cap')
wire([(570, cy), (590, cy), (590, cy - 26), (610, cy - 26)]); sig(590, cy - 34, 'voltage')
block(430, 638, 160, 'safe', 'Fail-safe resistors', h=48)
wire([(590, 638), (600, 638), (600, cy + 28), (610, cy + 28)], RED)
summ(735, cy, {'l': '+', 't': '−'})
wire([(682, cy), (716, cy)])
block(760, 478, 130, 'gry', 'Back-EMF', h=50)
pill(912, 478, 'damper speed', 'plt'); wire([(912, 478), (892, 478)])
wire([(760, 478), (735, 478), (735, 529)])
block(790, cy, 140, 'plt', 'Coil')
wire([(752, cy), (788, cy)])
wire([(930, cy), (998, cy)]); dot(958, cy)
block(1000, cy, 205, 'plt', 'Electromagnetic damper', 'magnets + coil')
summ(1245, cy, {'l': '+', 'b': '+'})
wire([(1205, cy), (1226, cy)])
block(1175, 638, 140, 'gry', 'Ball screw', 'friction + inertia', h=52)
wire([(1245, 612), (1245, 567)])
block(1310, cy, 200, 'plt', 'Half-coach vehicle', 'body + 2 bogies', h=90)
wire([(1262, cy), (1308, cy)]); sig(1285, cy - 12, 'force')
pill(1335, 458, 'track bumps', 'gry'); wire([(1405, 472), (1405, 501)])
block(1595, cy, 175, 'plt', 'Ride comfort', 'Sperling index')
wire([(1510, cy), (1593, cy)]); sig(1552, cy - 12, 'motion')
# coil current feedback
wire([(958, cy), (958, 664), (108, 664), (108, 567)]); sig(260, 657, 'measured coil current', 'start')

# ---------------- ③ power, safety, sensing ----------------
band(704, 216, 'safe', 'POWER, FAIL-SAFE AND SENSING')
block(40, 800, 150, 'safe', 'Fault detection')
block(240, 800, 200, 'safe', 'Fail-safe supervisor', 'latched')
wire([(190, 800), (238, 800)], RED)
wire([(440, 800), (647, 800), (647, cy + 56)], RED, '7 4'); sig(655, 786, 'relay', 'start', RED)
block(760, 800, 210, 'pwr', 'Power electronics', 'rectifier + DC-DC')
wire([(860, cy + 32), (860, 766)], ORG); sig(870, 735, 'harvested energy', 'start', ORG)
block(1020, 800, 200, 'pwr', 'Power bank', 'supercap + LiFePO4')
wire([(970, 800), (1018, 800)], ORG)
wire([(1120, 832), (1120, 880), (340, 880), (340, 834)], RED); sig(730, 874, 'bank OK', 'middle', RED)
block(1300, 800, 200, 'ctl', 'Sensors', 'accelerometers + encoder')
wire([(1405, 593), (1405, 766)]); sig(1415, 735, 'coach motion', 'start')
block(1560, 800, 200, 'ctl', 'State estimator', 'ideal in the sim today', dash=True)
wire([(1500, 800), (1558, 800)])
wire([(1760, 800), (1784, 800), (1784, 942), (24, 942), (24, 332), (468, 332)], TEAL, width=2.6)
t(900, 936, 'estimated state  →  state feedback', 'flowT')


css = """
.ttl{font-size:28px;font-weight:700;fill:#1A202C;letter-spacing:0.2px}.sub{font-size:15px;fill:#718096}
.band{font-size:13px;font-weight:700;letter-spacing:1.4px;fill:#2D3748}
.bt{font-size:15px;font-weight:600;fill:#1A202C}.bs{font-size:12px;fill:#718096}
.cap{font-size:13px;font-weight:600;fill:#4A5568}.capS{font-size:12px;fill:#6B7686;font-style:italic}
.sig{font-size:16px;font-weight:600;fill:#2D3748}.sgn{font-size:14px;font-weight:700;fill:#2D3748}
.pl{font-size:12.5px;font-weight:600;fill:#4A5568}.sl{font-size:12px;fill:#718096;font-style:italic}
.sch{font-size:12.5px;fill:#3A6FB0;font-style:italic}.flow{font-size:13px;fill:#6B7686;font-style:italic}
.flowT{font-size:12.5px;fill:#2C7A7B;font-weight:600;font-style:italic}
.cH{font-size:12.5px;font-weight:700;letter-spacing:1.2px;fill:#2A9D8F}.cS{font-size:13.5px;font-weight:700;fill:#13233A}
.cL{font-size:13px;fill:#4A5568}.lg{font-size:13.5px;fill:#3D4A5C}
"""
mk = ''.join(f'<marker id="m{c[1:]}" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="7" markerHeight="7" '
             f'orient="auto-start-reverse"><path d="M0,0 L10,5 L0,10 z" fill="{c}"/></marker>' for c in (INK, ORG, RED, BLU, TEAL))
Y0 = 92 if NO_TITLE else 0
svg = (f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 {Y0} {W} {H-Y0}" width="{W}" height="{H-Y0}" '
       f'font-family="\'Segoe UI\', Helvetica, Arial, sans-serif">\n<defs>{mk}<style>{css}</style></defs>\n'
       f'<rect y="{Y0}" width="{W}" height="{H}" fill="#FFFFFF"/>\n' + '\n'.join(o) + '\n</svg>\n')
open(OUT, 'w', encoding='utf-8').write(svg)
print('wrote', OUT)
